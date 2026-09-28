-- Incident decisions/lifecycle against production progression, statuses,
-- Equipment, navigation, event ownership and real SQLite. Only Source methods
-- and transport are doubled; no copied interaction/settlement implementation.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run})
local root,Run,D,R,Store=F.root,F.Run,F.D,F.R,F.Store
local E,Status=LOD.Equipment,LOD.RPGStatusElements
MOVETYPE_WALK=2
IN_ATTACK,IN_ATTACK2,IN_JUMP,IN_DUCK=1,2,3,4
local vector=getmetatable(Vector())
function vector:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function vector:GetNormalized()
 local length=math.sqrt(self:LengthSqr())
 return length>0 and self*(1/length) or Vector()
end
local createEntity=ents.Create
ents.Create=function(class)
 local e=createEntity(class)
 function e:GetForward() return Vector(1,0,0) end
 return e
end
for i=#F.online,1,-1 do table.remove(F.online,i) end
local number=100
local function actor()
 number=number+1
 local p=equipment.actor('76561198000'..string.format('%06d',number))
 p.ps.deploymentComplete,p.ps.lives,p.ps.equipmentLifeSerial=true,3,1
 p.LODRunSpawnSerial=1
 p.ps.progressionState.level=1
 p.ps.progressionState.effectiveAbilities=LOD.RPG.NewAbilityBlock(10)
 p.ps.progressionState.derivedStats.magicSaveBonus=0
 function p:SteamID64() return self.id end
 function p:GetPos() return self.pos or Vector() end
 function p:SetPos(pos) self.pos=pos end
 function p:GetHull() return Vector(-16,-16,0),Vector(16,16,72) end
 function p:GetMoveType() return self.moveType or MOVETYPE_WALK end
 function p:InVehicle() return self.vehicle==true end
 function p:OnGround() return self.grounded~=false end
 function p:KeyDown(button) return self.keys and self.keys[button]==true end
 function p:Crouching() return self.duck==true end
 function p:GetAimVector() return self.aim or Vector(-1,0,0) end
 p.GetNW2Int=p.GetNW2Float
 function p:ChatPrint(text) self.lastChat=text end
 p.EyePos,p.WorldSpaceCenter=p.GetPos,p.GetPos
 E:Ensure(p.ps)
 F.online[#F.online+1]=p
 return p
end
dofile(root..'sv_maze_navigator.lua')
dofile(root..'sv_safe_teleport.lua')
dofile(root..'sv_event_transactions.lua')
dofile(root..'sv_event_incidents.lua')
local I,T=LOD.EventIncidents,LOD.EventTransactions
local ids={'steam_vent','stasis_beacon','watchful_eye','prison_surveyor','counterweight_cache',
 'relay_race','memory_terminal','nerve_clock','strength_press','silent_archive'}
assert(#R:Catalog()==11,'Exactly ten meaningful incident definitions')
local function build(id)
 F.traceBlocked=false
 Run.State.SimulationFrozen=false;Run.State.CampaignClock=nil
 Run.State.Failed=false;Run.State.LevelCleared=false;Run.State.BuildReady=true
 local ok,plan=D:Plan(F.graph,{preview=id})
 assert(ok,plan)
 assert(#plan.instances==1)
 assert(D:Activate(F.graph,plan))
 local i=plan.instances[1]
 assert(D:ValidatePlacement(F.graph,R.Definitions[id],i.placement))
 assert(not D:ProtectedCells(F.graph)[i.cellKey])
 return i
end
local function center(i) return LOD.MazeBuilder:CellCenter(i.cell) end
local function near(p,i,offset) p.pos=center(i)+(offset or Vector(0,0,0)) end
local function at(p,i,part) p.pos=i.parts[part+1]:GetPos() end
local function use(p,i,part) return D:Interact(i.parts[(part or 0)+1],p) end
local function tick(i,advance)
 F.now=F.now+(advance or .3)
 R.Definitions[i.archetype].Tick(D,i)
end
local function balance(p) return assert(Store:Read(p.id)).balance end
local function receipt(i,p) return T.Claim(i,p.id) end
local function weak(p)
 p.ps.progressionState.effectiveAbilities=LOD.RPG.NewAbilityBlock(-100)
 p.ps.progressionState.level=1;p.ps.progressionState.derivedStats.magicSaveBonus=0
end
local function freshClaim(p,i) assert(not receipt(i,p),'Uncommitted interaction minted a receipt') end
local originalGraph=F.graphSignature(F.graph)
for _,id in ipairs(ids) do
 local i=build(id)
 assert(R.Definitions[id].presentation and R.Definitions[id].repeatable)
 local p=actor();near(p,i)
 local snapshot=D:Snapshot(p).events[1]
 assert(snapshot.details.name and snapshot.details.offer and snapshot.details.kind=='incident')
 assert(#snapshot.details.endpoints==#i.parts)
 for index,e in ipairs(i.parts) do assert(e.LODEventInstance==i and e.LODIncidentPart==index-1) end
 for _,field in ipairs({'soldier','vehicle'}) do
  p[field]=true;assert(not use(p,i),id..' accepted '..field);p[field]=nil
 end
 p.hp=0;assert(not use(p,i));p.hp=100
 p.ps.inStaging=true;assert(not use(p,i));p.ps.inStaging=nil
 Run.State.SimulationFrozen=true;assert(not use(p,i));Run.State.SimulationFrozen=false
 F.traceBlocked=true;assert(not use(p,i));F.traceBlocked=false
 local owned={};for n,e in ipairs(i.parts) do owned[n]=e end
 D:Cleanup('fixture iteration')
 for _,e in ipairs(owned) do assert(not IsValid(e)) end
 assert(not I:Bind(D,i,p,p.id))
end
assert(F.graphSignature(F.graph)==originalGraph,'Incidents edited maze/progression topology')

-- Actual reversible hazards: phase telegraph, native LOS/hulls, stance/gaze,
-- saves/immunity and conservative exact-entry cleanup through Status authority.
do
 local i=build('steam_vent');local p=actor();weak(p);near(p,i)
 tick(i,4.2);assert(i.phase=='warning' and not Status:Has(p,'muted'))
 tick(i,1);assert(i.phase=='steam' and Status:Has(p,'muted'))
 local _,entry=Status:Has(p,'muted');assert(entry.expiresAt==F.now+2)
 assert(use(p,i));assert(i.disabled and not Status:Has(p,'muted'))
 tick(i,6);assert(not Status:Has(p,'muted'))
 i=build('steam_vent');near(p,i);F.traceBlocked=true
 tick(i,5.2);assert(not Status:Has(p,'muted'),'Hazard crossed solid LOS')
 F.traceBlocked=false;near(p,i,Vector(0,0,384));tick(i,.3)
 assert(not Status:Has(p,'muted'),'Hazard crossed a physical floor')
 near(p,i,Vector(75,0,0));tick(i,.3);assert(not Status:Has(p,'muted'),'Hazard exceeded radius')
 i=build('steam_vent');near(p,i)
 Status:Apply(p,'muted',p,{direct=true,duration=40})
 local _,old=Status:Has(p,'muted');local expires=old.expiresAt
 tick(i,5.2);assert(old.expiresAt==expires,'Hazard prolonged unrelated combat condition')
 D:Cleanup('cleanup');assert(Status:Has(p,'muted'),'Cleanup cured unrelated combat condition')
 Status:Clear(p,'muted','fixture')
 i=build('steam_vent');near(p,i)
 p.ps.progressionState.effectiveAbilities.wis=100
 tick(i,5.2);assert(not Status:Has(p,'muted'),'Environmental hazard bypassed WIS save')
 weak(p);i=build('steam_vent');near(p,i);p.LODStatusImmunities={'muted'}
 tick(i,5.2);assert(not Status:Has(p,'muted'),'Environmental hazard bypassed immunity')
 p.LODStatusImmunities=nil
 i=build('stasis_beacon');near(p,i);p.duck=true
 tick(i);assert(not Status:Has(p,'clumsy'))
 p.duck=false;tick(i);assert(Status:Has(p,'clumsy'))
 assert(Status:LocomotionMultiplier(p)==.5,'Stasis ignored canonical movement effects')
 D:Cleanup('cleanup');assert(not Status:Has(p,'clumsy'))
 i=build('watchful_eye');near(p,i,Vector(40,0,8));p.aim=Vector(1,0,0)
 tick(i);assert(not Status:Has(p,'reckless'),'Eye hit averted gaze')
 assert(not use(p,i),'Front approach unplugged rear socket')
 p.aim=Vector(-1,0,0);tick(i);assert(Status:Has(p,'reckless'))
 near(p,i,Vector(-40,0,8));assert(use(p,i));assert(not Status:Has(p,'reckless'))
end

-- NPC guidance calls current canonical objective/path state, without payment.
do
 local i=build('prison_surveyor');local p=actor();near(p,i)
 Run.State.ObjectiveStage=1;Run.State.GatesOpen={false,false,false,false}
 assert(use(p,i));local s=D:Snapshot(p).events[1].details
 assert(s.status:find('floor') and p.lastChat==s.status)
 assert(not receipt(i,p))
 assert(not D:Snapshot(actor()).events[1].details.status,'Private consultation leaked to another Hero')
end

-- Shared mechanical opening has a solo route and exact two-body cooperation;
-- money is personally receipted once, including across same-dungeon rebuilding.
do
 local i=build('counterweight_cache');local p,q=actor(),actor();near(p,i);near(q,i,Vector(120,0,0))
 assert(use(p,i));tick(i,5);assert(not i.opened)
 p.pos=p.pos+Vector(20,0,0);tick(i);assert(not i.sessions[p] and not i.opened)
 near(p,i);assert(use(p,i));tick(i,10.1);assert(i.opened)
 assert(use(p,i));assert(balance(p)==15 and receipt(i,p))
 assert(not use(p,i) and balance(p)==15)
 near(q,i);assert(use(q,i));assert(balance(q)==15)
 i=build('counterweight_cache');near(p,i);assert(not use(p,i));assert(balance(p)==15)
 local a,b=actor(),actor();at(a,i,1);at(b,i,2)
 tick(i);local pair=i.pair;assert(pair)
 a.LODRunSpawnSerial=a.LODRunSpawnSerial+1
 tick(i,3.1);assert(not i.opened and i.pair~=pair,'Replacement body inherited cooperation timer')
 tick(i,3.1);assert(i.opened,'Two grounded distinct Heroes could not open plates')
 assert(not receipt(i,a) and not receipt(i,b),'Plate opening paid money before personal claim')
end

-- Grounded relay progression, timeouts, exact spawn ownership and retryable SQL.
do
 local i=build('relay_race');local p=actor();at(p,i,1);tick(i)
 assert(i.sessions[p] and i.sessions[p].nextPart==2)
 at(p,i,3);tick(i);assert(i.sessions[p].nextPart==2,'Relay skipped required marker')
 at(p,i,2);tick(i);at(p,i,3);tick(i);assert(i.sessions[p].complete)
 WalletSQLFail('COMMIT');assert(not use(p,i));assert(balance(p)==0 and not receipt(i,p))
 assert(use(p,i));assert(balance(p)==15 and receipt(i,p))
 i=build('relay_race');at(p,i,1);tick(i);assert(not i.sessions[p],'Regeneration reopened paid relay')
 local q=actor();at(q,i,1);tick(i);tick(i,13);assert(i.sessions[q].nextPart==2,'Standing at start may restart after timeout')
 at(q,i,2);tick(i);q.ps.equipmentLifeSerial=2;at(q,i,3);tick(i)
 assert(not i.sessions[q] and not receipt(i,q),'Fresh Hero inherited relay completion')
end

-- Memory publishes only the presently illuminated cue, never the upcoming
-- sequence/correct markers. Mistakes reset; successful answers settle once.
do
 local i=build('memory_terminal');local p=actor();near(p,i)
 assert(use(p,i));local sequence=table.Copy(i.sessions[p].sequence)
 local s=D:Snapshot(p).events[1].details
 assert(s.phase=='watch' and s.status:find(tostring(sequence[1])))
 assert(s.visibleLight==sequence[1])
 assert(not s.sequence and not s.correct and not s.seed and not s.choices)
 assert(not use(p,i,sequence[1]),'Could answer before watching')
 tick(i,3.1)
 assert(not D:Snapshot(p).events[1].details.visibleLight,'Answer phase leaked a remembered light')
 local wrong=sequence[1]%3+1
 assert(not use(p,i,wrong) and not i.sessions[p])
 assert(use(p,i));assert(table.concat(i.sessions[p].sequence,',')==table.concat(sequence,','))
 tick(i,3.1)
 assert(use(p,i,sequence[1]));assert(use(p,i,sequence[2]))
 WalletSQLFail('COMMIT');assert(not use(p,i,sequence[3]))
 assert(i.sessions[p].complete and not receipt(i,p) and balance(p)==0)
 assert(use(p,i,1));assert(balance(p)==15)
 assert(not use(p,i,2) and balance(p)==15)
 local q=actor();near(q,i);assert(use(q,i));q.soldier=true;tick(i)
 assert(not i.sessions[q] and not receipt(i,q),'Soldier control retained memory challenge')
end

-- Timing freezes the selected outcome across storage failure; red records the
-- spent attempt before applying an ordinary resistible condition.
do
 local i=build('nerve_clock');local p=actor();weak(p);near(p,i)
 assert(use(p,i));tick(i,1)
 WalletSQLFail('COMMIT');assert(not use(p,i));assert(not receipt(i,p))
 assert(i.sessions[p].won==false and not Status:Has(p,'reckless'))
 tick(i,2.2);assert(D:Snapshot(p).events[1].details.status:find('frozen'))
 assert(use(p,i));assert(receipt(i,p).success==false and balance(p)==0)
 assert(Status:Has(p,'reckless'))
 i=build('nerve_clock');near(p,i);assert(not use(p,i),'Rebuild reopened failed timing attempt')
 local q=actor();near(q,i);assert(use(q,i));tick(i,3.2)
 assert(D:Snapshot(q).events[1].details.phase=='green')
 assert(use(q,i));assert(receipt(i,q).success and balance(q)==20)
end

-- Stat trial uses derived STR and stable named die; no explosion or regeneration
-- reroll. Even the zero-dollar failed attempt has a durable receipt.
do
 local i=build('strength_press');local p=actor();near(p,i)
 p.ps.progressionState.derivedStats.strMod=-100
 assert(use(p,i));local result=receipt(i,p)
 assert(result.success==false and result.face>=1 and result.face<=20 and result.total==result.face-100)
 assert(balance(p)==0)
 i=build('strength_press');near(p,i);assert(not use(p,i))
 local q=actor();near(q,i);q.ps.progressionState.derivedStats.strMod=100
 assert(use(q,i));assert(receipt(i,q).success and balance(q)==20)
 local a=actor();near(a,i);a.ps.progressionState.derivedStats.strMod=-100
 WalletSQLFail('COMMIT');assert(not use(a,i));local frozen=i.sessions[a].result
 a.ps.progressionState.derivedStats.strMod=100
 assert(use(a,i));assert(receipt(i,a).total==frozen.total and not receipt(i,a).success,
  'Storage retry rerolled an already admitted Strength outcome')
end

-- Silent reading is cancellable by movement/attack; Magic participates in the
-- same real SQLite commit as the one-use receipt, including rollback/stale life.
do
 local i=build('silent_archive');local p=actor();near(p,i);p.ps.magic=20
 assert(use(p,i));p.keys={[IN_ATTACK]=true};tick(i,4.2)
 assert(not i.sessions[p] and p.ps.magic==20);freshClaim(p,i);p.keys=nil
 assert(use(p,i));WalletSQLFail('COMMIT');tick(i,4.2)
 assert(p.ps.magic==20 and i.sessions[p]);freshClaim(p,i)
 tick(i);assert(p.ps.magic==45 and receipt(i,p))
 i=build('silent_archive');near(p,i);assert(not use(p,i) and p.ps.magic==45)
 local q=actor();near(q,i);q.ps.magic=90;assert(use(q,i));tick(i,4.2)
 assert(q.ps.magic==100 and receipt(i,q).magic==10)
 local a=actor();near(a,i);a.ps.magic=30;assert(use(a,i))
 a.ps.progressionState=table.Copy(a.ps.progressionState);tick(i,4.2)
 assert(a.ps.magic==30 and not i.sessions[a] and not receipt(i,a))
end

-- Native trace reentrancy, missing parts, frozen/expired campaign and partial
-- creation must not commit resources, player conditions or delayed completions.
do
 local i=build('silent_archive');local p=actor();near(p,i);p.ps.magic=10
 assert(use(p,i));local trace=util.TraceLine;local tripped=false
 util.TraceLine=function(...)
  if not tripped then tripped=true;p.LODRunSpawnSerial=p.LODRunSpawnSerial+1 end
  return trace(...)
 end
 tick(i,4.2);util.TraceLine=trace
 assert(p.ps.magic==10 and not receipt(i,p),'Trace callback replaced body during channel commit')
 i=build('silent_archive');near(p,i);assert(use(p,i))
 local current=I:Bind(D,i,p,p.id);local originalPart=i.parts[1]
 local replacement=ents.Create('lod_dungeon_event')
 replacement.LODEventInstance=i;replacement.LODIncidentPart=0
 replacement:SetPos(originalPart:GetPos());i.parts[1]=replacement;i.entities[1]=replacement
 assert(not I:Current(current),'An in-place entity replacement inherited captured event authority')
 originalPart:Remove();D:Cleanup('part replacement')
 i=build('relay_race');at(p,i,1);tick(i);i.parts[2]:Remove();at(p,i,3);tick(i)
 assert(not receipt(i,p),'Missing owned marker completed relay')
 i=build('silent_archive');near(p,i);assert(use(p,i));Run.State.SimulationFrozen=true;tick(i,5)
 assert(p.ps.magic==10 and not receipt(i,p));Run.State.SimulationFrozen=false
 Run.State.CampaignClock={expired=true};tick(i);assert(not receipt(i,p));Run.State.CampaignClock=nil
 D:Cleanup('cancel channel');assert(p.ps.magic==10)
 local original=ents.Create;local creates=0
 ents.Create=function(class) creates=creates+1;if creates==3 then error('injected partial native creation') end;return original(class) end
 local ok,plan=D:Plan(F.graph,{preview='memory_terminal'});assert(ok)
 assert(not D:Activate(F.graph,plan));ents.Create=original
 assert(not D.Context and plan.instances[1].state=='cleaned')
 for _,e in ipairs(F.created) do if e.LODEventInstance==plan.instances[1] then assert(not IsValid(e)) end end
end
print('EVENT_INCIDENTS_PASS: ten distinct real events; automatic saves/stance/gaze/LOS; NPC route information; solo/co-op plates; ordered relay; secret memory; timed/stat attempts; Magic channel; actual SQLite rollback/retry/persistence; exact body/life/parts/clock/cleanup/partial-creation gates')
