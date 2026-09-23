-- Production Gordon/Hector/progression/native death authorities. Only Source
-- entities, packet delivery, world traces and geometry construction are doubled.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
SERVER,CLIENT=true,false;GM={};NULL={valid=false};SOLID_BBOX=2
ACT_IDLE,ACT_DIESIMPLE,COLLISION_GROUP_DEBRIS=1,2,3
DMG_CLUB,DMG_BLAST,DMG_ENERGYBEAM=1,2,4
function Angle() return {} end
function math.Round(n) return math.floor(n+.5) end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
function CreateConVar(_,default) return {GetBool=function() return default=='1' end,GetInt=function() return tonumber(default) end,GetString=function() return default end} end
ErrorNoHalt=noop
local clock=100;env.setTime(clock);SysTime,RealTime=CurTime,CurTime
local function time(n) clock=n;env.setTime(n) end
local hooks,eventHooks={},{}
hook.Add=function(event,id,fn) hooks[id]=fn;eventHooks[event]=eventHooks[event] or {};eventHooks[event][id]=fn end
hook.Run=function(event,...) for _,fn in pairs(eventHooks[event] or {}) do fn(...) end end
local queued,timers={},{}
timer.Simple=function(_,fn) queued[#queued+1]=fn end
timer.Create=function(id,delay,_,fn) timers[id]={delay=delay,fn=fn} end
timer.Exists=function(id) return timers[id]~=nil end
timer.Adjust=function(id,delay) timers[id].delay=delay end
timer.Remove=function(id) timers[id]=nil end
local function flush() local q=queued;queued={};for _,fn in ipairs(q) do fn() end end
local packets,packet={},nil
local failFinaleNetwork=false
net.Start=function(id) packet={id=id,values={}};packets[#packets+1]=packet end
local function write(v)
 if failFinaleNetwork and packet.id=='LOD_DeborahFinale' then error('injected finale packet failure') end
 packet.values[#packet.values+1]=v
end
net.WriteBool,net.WriteUInt,net.WriteFloat,net.WriteVector,net.WriteEntity,net.WriteString=write,write,write,write,write,write
net.WriteInt=write;net.Receive=noop
util.IsValidModel=function() return false end
net.Broadcast=noop;net.Send=function(p) packet.recipient=p end
util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end
util.Effect=noop;sound={Play=noop}
function EffectData() return {SetOrigin=noop} end
local players,created={},{}
local nativeClass
local insideDeath=false
local failCreate,failSpawn=false,false
local function actor(class)
 local e=env.actor(1);e.class=class or 'lod_hostile';e.index=#created+1;e.hp=1000;e.maximum=1000
 e.SetNW2String,e.SetNW2Int,e.SetNW2Float,e.SetNW2Entity=e.SetNW2Bool,e.SetNW2Bool,e.SetNW2Bool,e.SetNW2Bool
 function e:GetClass() return self.class end
 function e:GetNW2Int(k,default) return self.nw[k] or default end
 e.GetNW2Float=e.GetNW2Int
 function e:GetModel() return "models/player/group01/male_01.mdl" end
 function e:GetAngles() return {y=0} end
 function e:EntIndex() return self.index end
 function e:Health() return self.hp end
 function e:GetMaxHealth() return self.maximum end
 function e:SetHealth(v) self.hp=v end
 function e:SetMaxHealth(v) self.maximum=v end
 function e:SetKeySource(v) self.source=v end
 function e:LookupSequence() return -1 end
 function e:SetOpened(v) assert(not insideDeath);self.opened=v end
 function e:OpenGate() self:SetOpened(true) end
 function e:SetNoDraw(v) self.noDraw=v end
 function e:GetNoDraw() return self.noDraw end
 function e:Remove() assert(not insideDeath,'entity removed in native lethal callback');self.valid=false end
 for _,name in ipairs({'SetModel','DrawShadow','SetColor','SetNotSolid','SetPlaybackRate','SetCycle','ResetSequence'}) do e[name]=noop end
 function e:Spawn()
  if failSpawn and self.LODHector then error('injected native Spawn failure') end
  self.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[self.LODArchetypeId] or {})
  if self.class=='lod_hostile' and nativeClass then setmetatable(self,{__index=nativeClass}) end
 end
 created[#created+1]=e;return e
end
ents.Create=function(class) if failCreate and class=='lod_hostile' then return NULL end;return actor(class) end
ents.FindByClass=function(class) local found={};for _,e in ipairs(created) do if IsValid(e) and e.class==class then found[#found+1]=e end end;return found end
LOD.MazeBuilder._Register=noop;LOD.MazeBuilder._BuildProgressionEntities=noop;LOD.MazeBuilder.Cleanup=noop
LOD.WanderingDirector={GetDeficitReservation=function() return 3 end}
LOD.DiceAmmo={GrantWardenResupply=noop};LOD.Equipment.Grant=function() return true end
LOD.RPGTestLog={Write=noop};LOD.Audio={Emit=noop,At=noop,ToPlayer=noop}
LOD.EnemyVariance={Apply=function(_,e)
 e.LODProgressionState={level=20,derivedStats={maxHP=1000}}
 e:SetMaxHealth(1000);e:SetHealth(1000)
end}
LOD.EncounterDirector.Entities={};LOD.EncounterDirector.GetActiveCount=function() return 0 end
player.GetAll=function() return players end
dofile(root..'sv_run_manager.lua')
local R=LOD.RunManager
R.CaptureInventory=noop;R.FinalizeCampaignRun=noop;R.PutInRestrictedSpectator=noop;R.RetireSoldier=noop
R.BuildCurrentLevel=function(self) LOD.ProgressionDirector:ResetLevelState(self.State.Graph);self.State.RescueTarget=LOD.Damsels:Target(self.State.Level);return true end
function R:IsActivePlayer(p) return p.active~=false end
function R:IsSoldierControl(p) return p.soldier==true end
function R:IsPlayedIdentity(p) return p.ps~=nil end
function R:IdentityOf(p) return p.id end
function R:GetPlayerState(p) return type(p)=='table' and p.ps or self.State.PlayerState[p] end
local function hero(id)
 local p=actor('player');p.player=true;p.LODHostile=false;p.id=id;p.active=true;p.LODRunSpawnSerial=1
 p.ps={identity=id,deploymentComplete=true,lives=3,equipmentLifeSerial=1,progressionState={xp=0},deployedDungeonLevel=20}
 p.SteamID64=function(self) return self.id end;p.Nick=function(self) return self.id end
 p.NearestPoint=p.GetPos;p.ChatPrint=noop
 players[#players+1]=p;return p
end
local p,q=hero('hero-a'),hero('hero-b')
dofile(root..'sh_rng.lua');dofile(root..'sh_rpg_schema.lua');dofile(root..'sh_damsels.lua')
dofile(root..'sv_maze_generator.lua');dofile(root..'sv_progression_director.lua')
dofile(root..'sv_neil_brute.lua');dofile(root..'sv_warden_arena.lua');dofile(root..'sv_warden.lua')
local P,W,N=LOD.ProgressionDirector,LOD.Warden,LOD.MazeNavigator
P.Announce=noop;P.SyncAll=noop
dofile(root..'sv_hector.lua')
local H=LOD.Hector
dofile(root..'sh_tetris.lua');dofile(root..'sv_intermission_tetris.lua');dofile(root..'sv_victory_celebration.lua')
local V=LOD.VictoryCelebration
LOD.CharacterProgressionSystem={AwardHeroXP=function(_,id,n) local ps=R:GetPlayerState(id);ps.progressionState.xp=ps.progressionState.xp+n;return true end}
dofile(root..'sv_rpg_gate_d.lua')
local Attribution=LOD.CombatAttributionSystem
local encounters=0
LOD.EncounterDirector.OnHostileKilled=function(_,e,dmg) encounters=encounters+1;e:OnKilled(dmg) end
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua');nativeClass=ENT
local graph
for seed=100,200 do local g=assert(LOD.MazeGenerator:Generate(seed));if P:Plan(g,seed) then graph=g;break end end
assert(graph,'canonical generated arena required')
local seed=12345
-- Real loot handoff and result guards; native pickup materialization is isolated
-- so exact drop-count assertions do not depend on randomized category outcomes.
dofile(root..'sv_loot_director.lua')
local Loot=LOD.LootDirector
local drops=0
Loot.TraceStage=noop;Loot._DropCategory=function() return 'health',false end
Loot.ResolveEnemyReward=function() return 'health',{amount=10} end
Loot.SpawnPickup=function() drops=drops+1;return actor('lod_loot_pickup') end
local function setup(level)
 H:Cleanup();queued={};LOD.HostileDeathPresentation.Pending={};LOD.HostileDeathPresentation.Active={}
 R.State={Level=level or 20,LevelSeed=seed,CampaignSeed=41,CampaignEpoch=2,RunId='hector:test',Graph=graph,BuildReady=true,
  PlayerState={[p.id]=p.ps,[q.id]=q.ps},RescuedDamsels={}}
 P:ResetLevelState(graph)
 if hooks.LOD_DeborahFinaleLifecycle then hooks.LOD_DeborahFinaleLifecycle() end
 local s=R.State;s.GatesOpen={true,true,true,true};s.NeilHunt={started=true};s.RescueTarget=LOD.Damsels:Target(s.Level)
 for _,v in ipairs(players) do v.alive=true;v.valid=true;v.active=true;v.soldier=false;v.ps.lives=3;v.ps.deploymentComplete=true;v:SetPos(N:CellCenter(graph.Progression.Warden.center)+Vector(200,0,0)) end
 graph.Progression.Warden.lock.entity=actor('lod_gate')
 graph.Progression.JailEdge.entity=actor('lod_jail_door');s.RescueEntity=actor('lod_deborah')
 assert(W:Prepare() and W:Commit(),'production Gordon commitment failed')
 return s,s.Warden,s.Warden.actor
end
local function damage(attacker,n)
 return {GetAttacker=function() return attacker end,GetInflictor=function() return attacker end,
 GetDamage=function(self) return self.amount or n end,SetDamage=function(self,v) self.amount=v end}
end
local function kill(e)
 e.hp=0;insideDeath=true;e:OnKilled(damage(p,1000));insideDeath=false
end
local function reveal()
 local s,w,g=setup();kill(g);assert(s.Hector and s.Hector.stage==0 and not s.JailKeyEntity)
 local h=s.Hector;flush();assert(h.stage==1 and H:Owned(h.actor));time(clock+3);H:Step(clock);assert(h.stage==2)
 return s,w,h,h.actor
end
-- Direct attempts to bypass Gordon/Hector cannot create a key or rescue.
local s,w,g=setup()
assert(not H:OnGordonDefeated(s,w,graph.Progression.Warden,g),'living Gordon revealed Hector')
assert(not P:SpawnJailKey(Vector(),'bypass') and not W:EnsureKey())
s.JailKey=true;s.JailDoorOpen=true;s.ObjectiveStage=P.Stages.RESCUE_DEBORAH
assert(not P:CanRescueTarget() and not P:CanRescueDeborah() and not R:CompleteLevel(p),'Level-20 rescue bypass')
assert(not P:TryOpenJailDoor(p,actor('door')),'pre-opened state bypass')
s.JailKey=false;s.JailDoorOpen=false
kill(g);local h=s.Hector;assert(h and h.stage==0)
local initialCreated=#created;W:Killed(g);assert(s.Hector==h and #created==initialCreated)
flush();assert(h.stage==1 and #created==initialCreated+1 and not H:CanDamage(h.actor,damage(p,1)))
assert(not H:Spawn(h),'duplicate core creation')
local core=h.actor;time(clock+2.99);H:Step(clock);assert(h.stage==1)
time(clock+.02);H:Step(clock);assert(h.stage==2 and H:CanDamage(core,damage(p,1)))
assert(not H:AcceptDeath(core),'living core receipt')
local courtPos=p:GetPos();local mc=LOD.Config.Maze
p:SetPos(courtPos+Vector(mc.CellSize*(graph.Width+10),0,0))
assert(not H:CombatCell(p,h) and not H:Hero(p,h) and not H:CanDamage(core,damage(p,10)),
 'outside coordinate borrowed nearest graph cell admission')
local center=h.arena.center
p:SetPos(N:CellCenter(center)+Vector(0,0,mc.LevelHeight+70))
assert(H:CombatCell(p,h)==graph.Cells[LOD.MazeGenerator.CellKey(center.x,center.y,center.z)]
 and H:Hero(p,h) and H:CanDamage(core,damage(p,10)),'jump over central gallery shaft lost combat membership')
p:SetPos(courtPos)
-- One second warning precedes the first four finite missiles; the global bound
-- applies even if a caller repeatedly tries to enqueue production hazards.
time(h.nextAttack);H:Step(clock);assert(h.pending and #h.hazards==0)
local pending=h.pending;assert(pending.kind=='orb' and pending.ready-clock>=1)
time(pending.ready-.01);H:Step(clock);assert(#h.hazards==0)
time(pending.ready);H:Step(clock);assert(#h.hazards==1 and h.volley)
for i=1,3 do time(clock+.25);H:Step(clock) end
assert(#h.hazards==4 and not h.volley)
for i=1,30 do H:AddHazard(h,'orb',core:GetPos(),Vector(1,0,0),p,clock) end
assert(#h.hazards==12,'Hector ordnance cap')
core.hp=600;H:Step(clock);assert(h.phase==2 and #h.hazards==0)
core.hp=250;H:Step(clock);assert(h.phase==3)
core.hp=900;H:Step(clock);assert(h.phase==3,'healing rewound phase')
-- Life, identity, deploy membership and account/party changes revoke aim before
-- release. Dead/disconnected parties retain authoritative boss HP and phase.
local function arm() H:ClearAttacks(h);h.ordinal=0;H:BeginAttack(h,{p},clock);return h.pending end
arm();p.alive=false;H:Step(clock);assert(not h.pending);p.alive=true
arm();p.LODRunSpawnSerial=p.LODRunSpawnSerial+1;H:Step(clock);assert(not h.pending)
arm();p.ps.equipmentLifeSerial=p.ps.equipmentLifeSerial+1;H:Step(clock);assert(not h.pending)
arm();p.ps.deploymentComplete=false;H:Step(clock);assert(not h.pending);p.ps.deploymentComplete=true
arm();p.soldier=true;H:Step(clock);assert(not h.pending);p.soldier=false
arm();p.valid=false;H:Step(clock);assert(not h.pending);p.valid=true
arm();p.alive=false;q.alive=false;local health=core.hp;time(clock+30);H:Step(clock)
assert(core.hp==health and h.phase==3 and #h.hazards==0 and not h.pending)
p.alive=true;q.alive=true;H:Step(clock);assert(H:CanDamage(core,damage(p,1)))
-- A newly connected client receives exact entity, stage, health, phase and the
-- bounded currently pending warning, independent of prior broadcast delivery.
arm();hooks.LOD_HectorLateJoin(q);local last=packets[#packets]
assert(last.id=='LOD_HectorState' and last.recipient==q and last.values[1]==true and last.values[2]==core)
assert(last.values[4]==2 and last.values[5]==core.hp and last.values[7]==3 and last.values[11]==1)
-- Ground attacks freeze their floor marks and share one base roll across
-- victims, while the common Warden bridge preserves distinct defenses/tags.
dofile(root..'sv_damage_info.lua')
local received,rolled,resolved={},0,0
local damageContext
local muted=false
LOD.RPGStatusElements={CanInitiateAttack=function() return true end,CanInitiateMagic=function() return not muted end,
 AttachDamageContext=function(_,info,tags) damageContext=tags end}
LOD.CombatRolls.RollHostileAttack=function(_,e,profile)
 rolled=rolled+1;return {profile=profile,scale=1,attackEvent={}}
end
LOD.CombatRolls.ResolveActorDamage=function(_,contract,attacker,target,tags)
 resolved=resolved+1;assert(attacker==core and tags.damageContract==contract);return 7
end
LOD.CombatRolls.QueueDamageReport=noop
function DamageInfo()
 local d={};for _,name in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition'}) do
  d['Set'..name]=function(self,v) self[name]=v end;d['Get'..name]=function(self) return self[name] end
 end;return d
end
for _,v in ipairs(players) do v.TakeDamageInfo=function(self,info)
 assert(damageContext.actorDamageResolved and info:GetAttacker()==core and info:GetDamage()==7)
 received[#received+1]={target=self,tags=damageContext,kind=info:GetDamageType()}
end end
H:ClearAttacks(h);h.phase=3;core.hp=250;h.ordinal=1
H:BeginAttack(h,{p,q},clock);pending=h.pending
assert(pending.kind=='bomb' and pending.ready-clock==3 and #pending.marks==2)
local frozen=pending.marks[1];local before=rolled
-- Both marks overlap deliberately: separate explosions retain separate rolls.
time(pending.ready-.01);H:Step(clock);assert(#received==0)
time(pending.ready);H:Step(clock);assert(#h.hazards==2 and #received==0)
H:Step(clock);assert(#received==4 and rolled-before==2 and resolved==4 and #h.hazards==0)
assert(received[1].tags.physical and not received[1].tags.magic)
H:ClearAttacks(h);h.ordinal=3;H:BeginAttack(h,{p},clock);pending=h.pending
assert(pending.kind=='crowbar' and pending.ready-clock==1.5)
p:SetPos(p:GetPos()+Vector(0,0,70));assert(pending.marks[1].z==frozen.z,'jump height altered warned floor')
time(pending.ready);H:Step(clock);H:Step(clock)
assert(received[#received].tags.melee and received[#received].kind==DMG_CLUB)
p:SetPos(q:GetPos());H:ClearAttacks(h)
H:Damage(core,p,'villain');assert(received[#received].tags.magic and received[#received].tags.element=='dark')
local count=#received
util.TraceLine=function(t) return {Hit=true,HitPos=t.endpos} end
H:AddHazard(h,'bomb',p:GetPos(),Vector(),nil,clock,{expires=clock})
H:Step(clock);assert(#received==count,'bomb crossed blocking geometry')
util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
H:ClearAttacks(h);H:AddHazard(h,'orb',core:GetPos(),Vector(1,0,0),p,clock)
p.LODRunSpawnSerial=p.LODRunSpawnSerial+1;H:Step(clock);assert(#h.hazards==0,'projectile followed replacement life')
-- Telegraph commitment survives ordinary hit stun, while stun and Muted
-- suppress new eligible commitments without disabling physical boss families.
H:ClearAttacks(h);h.ordinal=2;H:BeginAttack(h,{p},clock);pending=h.pending
assert(pending.kind=='orb');core.LODHitStunUntil=clock+10
time(pending.ready);H:Step(clock);assert(#h.hazards==1 and h.volley,'hit stun canceled an already announced attack')
H:ClearAttacks(h);h.nextAttack=clock;H:Step(clock);assert(not h.pending,'stunned core committed a new warning')
core.LODHitStunUntil=nil;muted=true;h.ordinal=0;H:BeginAttack(h,{p},clock)
assert(not h.pending,'Muted committed Villain of Lore')
H:BeginAttack(h,{p},clock);assert(h.pending and h.pending.kind=='bomb','Muted disabled physical attack')
muted=false;H:ClearAttacks(h)
local forbidden=damage(p,10);p.soldier=true
assert(GM:EntityTakeDamage(core,forbidden)==true and forbidden:GetDamage()==0,'shared native bridge allowed Soldier damage')
p.soldier=false
-- The canonical ledger shares rewards across actual contributors, and real
-- native death claims only once before the shared corpse service releases jail.
local baseXP=p.ps.progressionState.xp+q.ps.progressionState.xp
core.hp=100;Attribution:Record(core,damage(p,60));core.hp=40;Attribution:Record(core,damage(q,40))
kill(core);assert(core.LODDead and h.death and not H:RescueAllowed(s) and not s.JailKeyEntity)
local paid=p.ps.progressionState.xp+q.ps.progressionState.xp
assert(paid>baseXP and core.LODRPGXPSettlement.killer==q.id and H:RewardOwned(core))
core:OnKilled(damage(p,1000));Attribution:Settle(core)
assert(p.ps.progressionState.xp+q.ps.progressionState.xp==paid)
time(clock+.01);LOD.HostileDeathPresentation:_RunDue()
assert(h.stage==3 and H:RescueAllowed(s) and IsValid(s.JailKeyEntity))
local card=s.JailKeyEntity;H:ResolveDeath(core);assert(s.JailKeyEntity==card)
local dropBefore=drops;Loot:OnHostileLootHandoff(core);Loot:OnHostileLootHandoff(core)
assert(drops==dropBefore+2,'native corpse loot duplicate or missing account award')
core:Remove();assert(H:RescueAllowed(s),'normal corpse retirement revoked rescue receipt')
p:SetPos(card:GetPos());assert(P:CollectJailKey(p,card) and P:TryOpenJailDoor(p,graph.Progression.JailEdge.entity) and P:CanRescueTarget())
local rescueBaseXP=p.ps.progressionState.xp+q.ps.progressionState.xp
assert(R:CompleteLevel(p) and s.Abundance and not R:CompleteLevel(p))
assert(p.ps.progressionState.xp+q.ps.progressionState.xp==rescueBaseXP+5000,'rescue XP must settle once')
assert(s.IntermissionEnd==clock+20 and LOD.IntermissionTetris.Pending[p.id].endsAt==s.IntermissionEnd,
 'finale altered authoritative twenty-second intermission')
local finale=assert(V.Finale,'legitimate rescue did not activate finale')
assert(finale.startedAt==clock and finale.endsAt==clock+6.5 and V:FinaleCurrent(finale))
assert(finale==s.DeborahFinaleTransition and #finale.heroes==2)
local serial=finale.serial
assert(not R:CompleteLevel(p) and V.Finale==finale and finale.serial==serial,'duplicate rescue restarted finale')
assert(R:AdvanceLevel() and R.State.Level==21 and R.State.RescueTarget.type=='cash' and R.State.RescueTarget.objective=='SECURE THE BAG')
assert(h.retired and not R.State.Hector)
assert(not V:FinaleCurrent(finale),'Level21 retained finale ownership')
-- Levels 1-19 and 21+ retain ordinary Gordon's key/release path.
for _,level in ipairs({1,19,21,42}) do
 s,w,g=setup(level);kill(g);flush();assert(not s.Hector and IsValid(s.JailKeyEntity),'ordinary Gordon key changed')
 p:SetPos(s.JailKeyEntity:GetPos());assert(P:CollectJailKey(p,s.JailKeyEntity));assert(P:TryOpenJailDoor(p,actor('door')))
 assert(P:CanRescueTarget() and H:RescueAllowed(s))
 assert(R:CompleteLevel(p) and not V.Finale,'ordinary rescue or cash spawned finale')
 assert(s.IntermissionEnd==clock+20 and (level<20 and s.RescuedDamsels[level] or s.CashRecovered==1),
  'ordinary rescue/cash settlement changed')
end
-- A Level-20 Gordon retains his ownership marker after the current level
-- advances. Delayed native death cannot masquerade as ordinary cash-mode Gordon.
s,w,g=setup();assert(g.LODHectorGordon and g.LODWardenOwner==w)
g.hp=10;Attribution:Record(g,damage(p,10))
local gordonXP=p.ps.progressionState.xp+q.ps.progressionState.xp
local gordonDrops,gordonEncounters=drops,encounters
s.Level=21;kill(g);flush();Attribution:Settle(g);Loot:OnHostileLootHandoff(g)
assert(not g.LODDead and not s.Hector and encounters==gordonEncounters and drops==gordonDrops
 and p.ps.progressionState.xp+q.ps.progressionState.xp==gordonXP,
 'stale Level-20 Gordon callback settled in Level21')
-- A real death receipt is valid only in its exact Warden/state ownership. The
-- deferred corpse service, direct payout and loot result seams all reject after
-- same-seed reset, without touching the surviving stale native entity.
s,w,g=setup();g.hp=10;Attribution:Record(g,damage(p,10));kill(g)
assert(g.LODDead and H:GordonRewardOwned(g))
gordonXP=p.ps.progressionState.xp+q.ps.progressionState.xp;gordonDrops=drops
P:ResetLevelState(graph);flush();time(clock+.01);LOD.HostileDeathPresentation:_RunDue()
assert(not H:GordonRewardOwned(g) and not s.Hector and not g.LODDeathPresentationStarted)
assert(Attribution:_Award(p.id,500,g)==0 and not Attribution:Settle(g))
Loot:OnHostileLootHandoff(g);assert(not Loot:_SpawnEnemyResult(p,g,'health',LOD.RNG.New(1)))
g:_BeginDeathPresentation();g:_FinishDeathPresentation()
assert(IsValid(g) and not g.noDraw and not g.LODDeathPresentationStarted and drops==gordonDrops
 and p.ps.progressionState.xp+q.ps.progressionState.xp==gordonXP,'stale Gordon corpse changed presentation or rewards')
-- Every mutable ownership axis rejects a pending reveal, even same-seed graph
-- replacement. A replacement actor with identical numeric data is not the core.
for _,axis in ipairs({'Graph','Warden','CampaignEpoch','CampaignSeed','RunId','LevelSeed','Level','BuildReady','Failed','LevelCleared'}) do
 s,w,g=setup();kill(g);h=s.Hector;local count=#created
 if axis=='Graph' then s.Graph=table.Copy(graph)
 elseif axis=='Warden' then s.Warden={actor=g,dead=true}
 elseif axis=='RunId' then s.RunId='replacement'
 elseif axis=='BuildReady' then s.BuildReady=false
 elseif axis=='Failed' or axis=='LevelCleared' then s[axis]=true
 else s[axis]=(s[axis] or 0)+1 end
 flush();assert(#created==count and not H:Current(h),'stale reveal '..axis)
 hooks.LOD_HectorService();assert(h.retired and not s.Hector)
end
s,w,h,core=reveal();local impostor=actor();impostor.LODHector=true;impostor.LODArchetypeId='hector';impostor.LODHectorEncounter=h;impostor.hp=0
assert(not H:AcceptDeath(impostor) and not H:RewardOwned(impostor) and not H:CanDamage(impostor,damage(p,10)))
local sameGraph=R.State.Graph;local old=h
P:ResetLevelState(sameGraph);assert(old.retired and not IsValid(core) and not R.State.Hector)
assert(not H:ResolveDeath(core) and not H:RewardOwned(core),'same-seed reset retained reward/rescue')
-- A delayed corpse cannot pay in a replacement dungeon, even with the same
-- graph object, numeric seed and account roster; direct settlement also rejects.
s,w,h,core=reveal();core.hp=10;Attribution:Record(core,damage(p,10));kill(core)
local staleXP=p.ps.progressionState.xp+q.ps.progressionState.xp;local staleDrops=drops
P:ResetLevelState(graph);Attribution:Settle(core);Loot:OnHostileLootHandoff(core)
assert(not H:ResolveDeath(core) and drops==staleDrops and p.ps.progressionState.xp+q.ps.progressionState.xp==staleXP)
for _,resource in ipairs({'lock','jail','rescue'}) do
 s,w,h,core=reveal();local oldResource=h[resource]
 if resource=='lock' then h.arena.lock.entity=actor('lod_gate')
 elseif resource=='jail' then h.progression.JailEdge.entity=actor('lod_jail_door')
 else s.RescueEntity=actor('lod_deborah') end
 assert(IsValid(oldResource) and not H:CanDamage(core,damage(p,1)))
 core.hp=0;assert(not H:AcceptDeath(core) and not H:RewardOwned(core))
 H:Step(clock);assert(s.Failed and h.retired)
end
-- Partial creation and live-core disappearance use the existing failure path,
-- leaving no owned body, attacks, delayed work or encounter lock alive.
for _,failure in ipairs({'create','spawn','remove','timeout'}) do
 s,w,g=setup();kill(g);h=s.Hector
 if failure=='create' then failCreate=true elseif failure=='spawn' then failSpawn=true end
 flush();failCreate=false;failSpawn=false
 if failure=='remove' then h.actor:Remove();H:Step(clock)
 elseif failure=='timeout' then s.CampaignClock={deadline=clock-1};hooks.LOD_HectorService() end
 assert(h.retired and not s.Hector and #h.hazards==0 and (not h.actor or not IsValid(h.actor)))
 if failure~='timeout' then assert(s.Failed and not H:RescueAllowed(s)) end
end
s,w,h,core=reveal();arm=function() H:BeginAttack(h,{p},clock) end;arm();R:FailCampaign('test failure')
assert(h.retired and not IsValid(core) and not h.pending and not H:CanDamage(core,damage(p,1)))
print('HECTOR_ENCOUNTER_PASS: legitimate Gordon/native death handoff, L20-only rescue lock, canonical contributor rewards, exactly-once receipt, reveal/telegraphs/12 hazards/phases, life/deployment/disconnect/absence, late joins, exact state/graph/campaign ownership, same-seed reset, partial creation/failure/timeout cleanup, Level21 cash continuation')

-- Expanded finale uses the real Gordon/Hector receipt, accepted rescue wrapper,
-- rescue rewards and optional Tetris window; cosmetic methods never settle loot.
local function rescueFinale(expectMissing)
 local state,warden,encounter,body=reveal()
 state.RescuedDamsels={};for level=1,19 do state.RescuedDamsels[level]=true end
 body.hp=0;kill(body);time(clock+.01);LOD.HostileDeathPresentation:_RunDue()
 local key=assert(state.JailKeyEntity);p:SetPos(key:GetPos())
 assert(P:CollectJailKey(p,key) and P:TryOpenJailDoor(p,graph.Progression.JailEdge.entity))
 assert(R:CompleteLevel(p));if not expectMissing then assert(V.Finale) end;return state,V.Finale,encounter
end
s,w,g=setup()
assert(not V:CaptureFinale() and not R:CompleteLevel(p) and not V.Finale,
 'premature Level20 finale before Hector death')
local state,record,encounter=rescueFinale()
assert(#record.damsels==19 and #record.heroes==2 and record.endsAt<=state.IntermissionEnd)
assert(record.center:DistToSqr(N:CellCenter(encounter.arena.center))<.01,
 'finale tableau placed in narrow jail rather than canonical court')
for i,level in ipairs(record.damsels) do assert(level==i and level~=20,'duplicate or incorrect damsel tableau roster') end
local acceptedXP=p.ps.progressionState.xp+q.ps.progressionState.xp
assert(not V:StartFinale(record) and V.Finale==record,'direct duplicate start')
H:Cleanup();assert(V:FinaleCurrent(record),'normal Hector cleanup revoked accepted rescue finale')
local movement,buttons=0,0
local command={ClearMovement=function() movement=movement+1 end,ClearButtons=function() buttons=buttons+1 end}
hooks.LOD_VictoryCelebrationMovementLock(p,command)
assert(movement==1 and buttons==1,'participating Hero not locked during explicit interval')
local deadline=record.endsAt
for _,axis in ipairs({'dead','disconnect','spawn','life','soldier','inactive','playerState'}) do
 state,record=rescueFinale();deadline=record.endsAt
 local hp=record.heroes[1];local who=hp.entity
 local oldps=who.ps;local oldspawn=who.LODRunSpawnSerial;local oldlife=oldps.equipmentLifeSerial
 if axis=='dead' then who.alive=false elseif axis=='disconnect' then who.valid=false
 elseif axis=='spawn' then who.LODRunSpawnSerial=oldspawn+1
 elseif axis=='life' then oldps.equipmentLifeSerial=oldlife+1
 elseif axis=='soldier' then who.soldier=true elseif axis=='inactive' then who.active=false
 else who.ps=table.Copy(oldps) end
 assert(not V:HeroPresent(hp),'stale participant '..axis)
 local before=movement;hooks.LOD_VictoryCelebrationMovementLock(who,command)
 assert(movement==before,'stale Hero remained control-locked: '..axis)
 who.ps=oldps;who.alive=true;who.valid=true;who.active=true;who.soldier=false
 who.LODRunSpawnSerial=oldspawn;oldps.equipmentLifeSerial=oldlife
end
assert(not V:HeroPresent(record.heroes[1]) and record.endsAt==deadline,'retired Hero rejoined timeline')
acceptedXP=p.ps.progressionState.xp+q.ps.progressionState.xp
local newcomer=hero('late-hero');newcomer.ps.deployedDungeonLevel=20
state.PlayerState[newcomer.id]=newcomer.ps
V:SyncFinale(newcomer);local snapshot=packets[#packets]
assert(snapshot.id=='LOD_DeborahFinale' and snapshot.recipient==newcomer and snapshot.values[1])
assert(snapshot.values[2]==false and snapshot.values[3]==record.serial and snapshot.values[4]==record.startedAt and snapshot.values[5]==deadline,
 'late join reset finale timing')
assert(#record.heroes==2,'late join altered accepted participant roster')
local before=movement;hooks.LOD_VictoryCelebrationMovementLock(newcomer,command)
assert(movement==before,'new spectator inherited participant movement lock')
newcomer.valid=false;table.remove(players)
state.RescueEntity:Remove();assert(V:FinaleCurrent(record),'missing cosmetic rescue model invalidated legitimate clear')
assert(p.ps.progressionState.xp+q.ps.progressionState.xp==acceptedXP and state.Abundance)
time(deadline+.01);hooks.LOD_VictoryCelebrationMovementLock(p,command)
assert(movement==before and not V:FinaleCurrent(record),'movement remained locked beyond interval')
-- Replacing an exact ownership component invalidates only presentation; accepted
-- rewards are immutable. Same numeric seed or identical graph values do not help.
local function shallow(value) local copy={} for k,v in pairs(value) do copy[k]=v end;return copy end
for _,axis in ipairs({'state','graph','progression','epoch','campaignSeed','runId','seed','level','failed','cleared','build','transition','intermission'}) do
 state,record=rescueFinale();local xp=p.ps.progressionState.xp+q.ps.progressionState.xp
 if axis=='state' then R.State=shallow(state)
 elseif axis=='graph' then state.Graph=shallow(graph)
 elseif axis=='progression' then state.Graph.Progression=shallow(state.Graph.Progression)
 elseif axis=='epoch' then state.CampaignEpoch=state.CampaignEpoch+1
 elseif axis=='campaignSeed' then state.CampaignSeed=state.CampaignSeed+1
 elseif axis=='runId' then state.RunId='new-run'
 elseif axis=='seed' then state.LevelSeed=state.LevelSeed+1
 elseif axis=='level' then state.Level=21
 elseif axis=='failed' then state.Failed=true
 elseif axis=='cleared' then state.LevelCleared=false
 elseif axis=='build' then state.BuildReady=false
 elseif axis=='transition' then state.DeborahFinaleTransition={}
 else state.IntermissionEnd=state.IntermissionEnd+1 end
 assert(not V:FinaleCurrent(record),'stale finale ownership '..axis)
 before=movement;hooks.LOD_VictoryCelebrationMovementLock(p,command)
 assert(movement==before,'stale owner held controls '..axis)
 V:SyncFinale(q);assert(packets[#packets].values[1]==false,'stale snapshot transmitted '..axis)
 assert(p.ps.progressionState.xp+q.ps.progressionState.xp==xp,'presentation invalidation replayed rewards')
 V:EndFinale()
end
state,record=rescueFinale();P:ResetLevelState(graph)
assert(not V:FinaleCurrent(record),'same-seed regeneration retained accepted finale')
state,record=rescueFinale();R:FailCampaign('finale interrupted')
assert(not V:FinaleCurrent(record),'campaign failure retained finale')

V:EndFinale();failFinaleNetwork=true;state,record=rescueFinale(true);failFinaleNetwork=false
assert(state.LevelCleared and state.Abundance and state.RescuedDamsels[20] and not record,
 'partial finale network creation unwound legitimate rescue')
assert(R:AdvanceLevel() and R.State.Level==21 and R.State.RescueTarget.objective=='SECURE THE BAG',
 'presentation failure blocked endless progression')

-- An inactive cosmetic packet failure must never veto the real endless handoff.
state,record=rescueFinale()
local startPacket=net.Start
net.Start=function(id)
 if id=='LOD_DeborahFinale' then error('injected finale teardown net.Start failure') end
 return startPacket(id)
end
assert(R:AdvanceLevel() and R.State.Level==21 and R.State.RescueTarget.objective=='SECURE THE BAG',
 'cosmetic teardown exception blocked authoritative Level21 advancement')
net.Start=startPacket
assert(not V.Finale and p:GetNW2Float('LOD_VictoryCelebrationUntil',0)==0
 and q:GetNW2Float('LOD_VictoryCelebrationUntil',0)==0,'teardown failure retained finale/control locks')

print('DEBORAH_FINALE_SERVER_PASS: real accepted rescue and Tetris window; once-only XP/activation; exact campaign/graph/transition; canonical damsels/Hero snapshot; life/role/disconnect/late join; removed actor safety; timed controls; same-seed reset/failure; Level21 and ordinary rescues')
