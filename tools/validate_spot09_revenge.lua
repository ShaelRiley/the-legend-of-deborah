-- SPOT-09 uses real inventory, procedural generation, dice, defenses, faction,
-- Warden ownership, exact-cell geometry, rescue and LootDirector collection.
-- Source engine entities, collision observations, networking and time are doubles.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R,Rules,Status,Rolls=LOD.Equipment,env.Run,LOD.RPGAbilityRules,LOD.RPGStatusElements,LOD.CombatRolls
local checks=0
local function check(v,m) checks=checks+1;assert(v,'SPOT09 check '..checks..': '..(m or '')) end
local noop=function() end
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) if type(a)=='number' then a,b=b,a end;return Vector(a.x*b,a.y*b,a.z*b) end
V.__div=function(a,b) return a*(1/b) end
function V:LengthSqr() return self:DistToSqr(Vector()) end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:GetNormalized() return self/math.max(.001,self:Length()) end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:Angle() return Angle() end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
angle_zero=Angle();vector_origin=Vector()
local mc=LOD.Config.Maze;mc.Origin=Vector(mc.Origin.x,mc.Origin.y,mc.Origin.z)
local now=1000;CurTime=function() return now end;SysTime=CurTime;RealTime=CurTime
local commands={};concommand.Add=function(id,fn) commands[id]=fn end
CreateConVar=function() return {GetInt=function() return 0 end,GetBool=function() return false end} end
for _,name in ipairs({'WriteString','WriteVector','WriteBool','Broadcast'}) do net[name]=noop end
util.Effect=noop;util.IsValidModel=function() return true end
function EffectData() return {SetStart=noop,SetOrigin=noop} end
game={GetWorld=function() return nil end}
local heroes={};player.GetAll=function() return heroes end
ents={FindByClass=function() return {} end}
LOD.WanderingDirector={GetDeficitReservation=function() return 0 end}
LOD.Audio=LOD.Audio or {};LOD.Audio.ToPlayer=noop;LOD.Audio.Emit=noop
LOD.RPGTestLog={Write=function(_,event,fields) if fields and fields.error then print(event,fields.error) end end}
dofile(root..'sv_run_manager.lua');dofile(root..'sv_maze_generator.lua');dofile(root..'sv_maze_builder.lua')
dofile(root..'sv_maze_navigator.lua');dofile(root..'sv_progression_director.lua');dofile(root..'sv_entry_safety.lua')
dofile(root..'sv_faction_manager.lua');dofile(root..'sv_warden.lua');dofile(root..'sv_equipment_moves.lua')
dofile(root..'sv_staging_deployment.lua');dofile(root..'sh_tetris.lua');dofile(root..'sv_intermission_tetris.lua')
local P,N,W=LOD.ProgressionDirector,LOD.MazeNavigator,LOD.Warden
P.Announce=noop;P.SyncAll=noop -- transport only
-- Restore the production dice and feed methods overwritten by the base fixture.
dofile(root..'sv_combat_rolls.lua');dofile(root..'sv_combat_feed_semantics.lua')
local serial=10;local creationMode,created,nativeMutation
local feed={};local originalSend=Rolls._Send
-- The authoritative feed encoder is exercised in retained Die Logger suites;
-- this test records its actual semantic call, without requiring clients.
Rolls._Send=function(_,actor,kind,text,family,fields) feed[#feed+1]={actor=actor,kind=kind,text=text,fields=fields} end
local function actor(id,class,hostile)
 local p=env.actor(id,hostile);serial=serial+1;p.index=serial;p.class=class or 'player';p.pos=Vector()
 function p:IsPlayer() return self.class=='player' end
 function p:IsNPC() return false end
 function p:GetClass() return self.class end
 function p:SteamID64() return self.id end
 function p:Nick() return self.id end
 function p:GetOwner() return self.owner end
 function p:GetPos() return self.pos end
 function p:SetPos(v) self.pos=Vector(v.x,v.y,v.z) end
 function p:WorldSpaceCenter() return self.pos+Vector(0,0,36) end
 function p:EyePos() return self.pos+Vector(0,0,64) end
 function p:EntIndex() return self.index end
 function p:GetNW2String(k,d) return self.nw[k] or d end
 p.GetNW2Int,p.GetNW2Vector,p.GetNW2Entity=p.GetNW2String,p.GetNW2String,p.GetNW2String
 p.SetNW2Vector,p.SetNW2Entity=p.SetNW2String,p.SetNW2String
 function p:GetDoorAxis() return self.axis or 0 end
 function p:GetOpened() return self.opened==true end
 function p:SetAngles(v) self.ang=v end
 function p:GetAngles() return self.ang or angle_zero end
 function p:IsAdmin() return true end
 function p:IsDormant() return false end
 function p:Spawn() end
 function p:Remove() self.valid=false;self.removed=true end
 function p:SetPreventTransmit() end
 function p:GetWeapons() local a={} for _,w in pairs(self.weapons) do a[#a+1]=w end;return a end
 p.LODRunInventoryReady=false -- no native backpack snapshot in this engine double
 return p
end
local packetSerial=0
function DamageInfo()
 local info={damage=0,type=0};packetSerial=packetSerial+1
 for _,name in ipairs({'Damage','DamageType','DamagePosition','DamageForce','Attacker','Inflictor'}) do
  info['Set'..name]=function(self,v) self[name]=v end;info['Get'..name]=function(self) return self[name] or 0 end
 end
 function info:ScaleDamage(n) self.Damage=self:GetDamage()*n end
 function info:IsDamageType(t) return self.DamageType==t end
 return info
end
local engineCalls=0
local function take(e,info)
 engineCalls=engineCalls+1
 local stopped=false
 for _,id in ipairs({'LOD_HostileFactionDamage','LOD_WardenAlcove','LOD_DamselRevengePacket'}) do
  local fn=env.hooks[id];if fn and fn(e,info)==true then stopped=true;break end
 end
 if nativeMutation then nativeMutation(e,info) end
 if not stopped and GM:EntityTakeDamage(e,info)~=true then
  e.hp=math.max(0,e.hp-info:GetDamage())
  if e.hp==0 then e.LODDead=true;if R.State.Level==20 then R.State.Warden.combatDeath=e end;W:Killed(e) end
 end
 Rolls:ReportResolvedDamage(info)
 GM:PostEntityTakeDamage(e,info,not stopped)
end
local D=LOD.DamselRevenge
dofile(root..'sv_damsel_revenge.lua')
local key=LOD.MazeGenerator.CellKey
local state,s,w,boss,damsel,jail,p,friend,a
local function setup(level)
 if D.current then D:Retire(D.current,'test reset');D:FlushCleanup() end
 now=now+2;nativeMutation=nil;creationMode=nil;created=0;feed={}
 p,friend=actor('owner'),actor('friend');heroes={p,friend}
 local c={x=4,y=5,z=0,neighbors={}};local dc={x=5,y=5,z=0,neighbors={}}
 local ec={x=3,y=5,z=0,neighbors={}};local side={x=4,y=6,z=0,neighbors={}}
 local cells={[key(4,5,0)]=c,[key(5,5,0)]=dc,[key(3,5,0)]=ec,[key(4,6,0)]=side}
 a={court={[key(4,5,0)]=true,[key(4,6,0)]=true},cells=cells,center=c,entry=ec,lock={}}
 local graph={Cells=cells,Width=mc.Width,Height=mc.Height,Layers=1,Progression={Warden=a,DeborahCell=dc,JailEdge={}}}
 s={RunId='spot09',CampaignEpoch=2,CampaignSeed=73,LevelSeed=31,Level=level or 1,BuildReady=true,
  Graph=graph,PlayerState={},ActiveIdentity={},PlayedIdentities={},RescuedDamsels={},GatesOpen={true,true,true,true},
  ObjectiveStage=P.Stages.DEFEAT_WARDEN,CampaignClock={deadline=now+1000},RescueTarget=LOD.Damsels:Target(level or 1)}
 R.State=s
 for _,h in ipairs(heroes) do
  h.ps.lives=3;h.ps.eliminated=false;h.ps.deploymentComplete=true;h.ps.equipmentLifeSerial=1
  s.PlayerState[h.id]=h.ps;s.ActiveIdentity[h.id]=true
  h:SetPos(N:CellCenter(c));E:ClearTransient(h);E.NextUse[h]=nil
 end
 state=E:Ensure(p.ps);assert(E:Grant(p,'damsel_revenge',3));assert(E:Equip(state,'damsel_revenge','throwable'));assert(E:Activate(p))
 boss=actor('gordon','lod_hostile',true);boss:SetPos(N:CellCenter(c));boss.hp=10000;boss.max=10000
 boss.LODArchetypeId='warden';boss.TakeDamageInfo=take
 -- No fake progression/class/HP is added to the native protected rescue prop.
 damsel=actor('damsel','lod_deborah');damsel.LODProgressionState=nil;damsel.ps=nil;damsel.hp=0
 damsel:SetPos(N:CellCenter(dc)+Vector(0,0,1));damsel.LODRescueTarget=s.RescueTarget;s.RescueEntity=damsel
 jail=actor('jail','lod_jail_door');jail.ps=nil;jail.LODProgressionState=nil
 jail:SetPos((N:CellCenter(c)+N:CellCenter(dc))*.5+Vector(0,0,LOD.Config.Progression.GateBlockerHeight*.5))
 graph.Progression.JailEdge.entity=jail
 w={state=s,graph=graph,epoch=s.CampaignEpoch,campaignSeed=s.CampaignSeed,runId=s.RunId,level=s.Level,seed=s.LevelSeed,
  actor=boss,started=true,clones={},cloneStates={},hazards={}}
 s.Warden=w;s.WardenStarted=true;boss.LODWardenOwner=w
 util.TraceLine=function(t) return {Hit=true,Entity=boss,HitPos=t.endpos} end
 ents.Create=function(class)
  created=created+1;if creationMode=='nil' then return nil end
  if creationMode=='throw' then error('injected native creation failure') end
  return actor('pickup'..created,class)
 end
 return s
end
local function count(h) local st=E:Ensure(R:GetPlayerState(h or p));local i=st.items.damsel_revenge;return i and i.count or 0 end
local function arm() check(E:Use(p,'throw'),'actual consumable dispatcher accepts');local r=D.current;check(r and D:Scope(r),'bound exact encounter');return r end
setup();local r=arm();check(count()==2,'one debit');check(E.NextUse[p]==now+.6,'canonical cooldown')
check(D:Ready(r),'ready uses production owner/faction/court');check(D:Path(r),'actual jail port path')
now=now+.7;local hp=boss.hp;D:Service();check(boss.hp<hp,'real physical dice/defense/native damage')
check(r.shots==1 and #feed>0,'one shot and semantic die report')
print('SPOT09_INITIAL_PATH_PASS '..checks..' assertions')
-- Admission and synchronous transaction boundaries.
local function noSpend(message)
 local before=count();local old=D.current;local cd=E.NextUse[p]
 check(not E:Use(p,'drink'),message);check(count()==before and D.current==old and E.NextUse[p]==cd,'rejection has no payment/ownership')
end
for _,blocked in ipairs({'dead','inactive','staging','eliminated','zero_lives','unheld','unequipped','wrong_owner',
 'failed','cleared','frozen','building','no_graph','paused','expired','scene','not_started','dead_gordon','wrong_boss_owner',
 'wrong_target','wrong_damsel','owned_damsel','hostile_damsel','missing_jail','open_jail','entry','void','cash'}) do
 setup(blocked=='cash' and 21 or 1)
 if blocked=='dead' then p.hp=0 elseif blocked=='inactive' then s.ActiveIdentity[p.id]=nil
 elseif blocked=='staging' then p.ps.deploymentComplete=false elseif blocked=='eliminated' then p.ps.eliminated=true
 elseif blocked=='zero_lives' then p.ps.lives=0 elseif blocked=='unheld' then p.activeClass='none'
 elseif blocked=='unequipped' then E:Unequip(state,'throwable') elseif blocked=='wrong_owner' then p:GetActiveWeapon().owner=friend
 elseif blocked=='failed' then s.Failed=true elseif blocked=='cleared' then s.LevelCleared=true
 elseif blocked=='frozen' then s.SimulationFrozen=true elseif blocked=='building' then s.BuildReady=false
 elseif blocked=='no_graph' then s.Graph=nil elseif blocked=='paused' then s.CampaignClock.deadline=nil
 elseif blocked=='expired' then s.CampaignClock.deadline=now elseif blocked=='scene' then s.CampaignClock.scene={}
 elseif blocked=='not_started' then w.started=false elseif blocked=='dead_gordon' then boss.LODDead=true;boss.hp=0
 elseif blocked=='wrong_boss_owner' then boss.LODWardenOwner={} elseif blocked=='wrong_target' then s.RescueTarget={type='damsel',definition=2}
 elseif blocked=='wrong_damsel' then s.RescueEntity=friend elseif blocked=='owned_damsel' then damsel.owner=p
 elseif blocked=='hostile_damsel' then damsel.LODHostile=true elseif blocked=='missing_jail' then jail.valid=false
 elseif blocked=='open_jail' then jail.opened=true elseif blocked=='entry' then p:SetPos(N:CellCenter(a.entry))
 elseif blocked=='void' then p:SetPos(N:CellCenter(a.center)+Vector(0,0,mc.LevelHeight)) end
 noSpend(blocked)
end
setup();local consume=E.Consume;E.Consume=function() return false end
noSpend('failed canonical debit');local frozen=w.revengeChoice;check(frozen and frozen.item,'choice frozen before debit')
E.Consume=consume;r=arm();check(r.item.id==frozen.item.id and r.spec==frozen.spec,'retry never rerolls')
noSpend('duplicate activation');now=now+10;noSpend('no repeat after cooldown')
local friendState=E:Ensure(friend.ps);assert(E:Grant(friend,'damsel_revenge',3));assert(E:Equip(friendState,'damsel_revenge','throwable'));assert(E:Activate(friend))
check(not E:Use(friend,'throw') and count(friend)==3 and D.current==r,'one party-wide activation')
-- Reentry inside debit cannot arm a second user or charge twice.
setup();friendState=E:Ensure(friend.ps);assert(E:Grant(friend,'damsel_revenge',3));assert(E:Equip(friendState,'damsel_revenge','throwable'));assert(E:Activate(friend))
E.Consume=function(self,st,id) check(not self:Use(friend,'drink'),'global synchronous admission lock');return consume(self,st,id) end
r=arm();E.Consume=consume;check(count()==2 and count(friend)==3,'single debit under cooperative reentry')
-- The generation adapter is fallible; no committed item exists before success.
setup();local generate=E.Generate;local seeds={}
E.Generate=function(_,seed) seeds[#seeds+1]=seed;return nil end
noSpend('generation unavailable');noSpend('same unavailable generation')
E.Generate=generate;check(seeds[1]==seeds[2],'failed generation retains deterministic context');arm()
setup();E.Generate=function() error('injected generation exception') end;noSpend('generation exception');E.Generate=generate
-- Mutations inside debit, not merely before the dispatcher, must fail closed.
for _,change in ipairs({
 function() p.ps.equipmentLifeSerial=2 end,
 function() s.CampaignClock={} end,
 function() s.CampaignClock.deadline=s.CampaignClock.deadline+1 end,
 function() s.Graph={} end,
 function() s.LevelSeed=s.LevelSeed+1 end,
 function() s.Warden={} end,
 function() s.RescueEntity=friend end,
 function() s.RescueTarget={type='damsel',definition=s.Level} end,
 function() s.Graph.Progression.JailEdge.entity=friend end,
 function() p:GetActiveWeapon().owner=friend end,
 function() s.SimulationFrozen=true end,
}) do
 setup();local originalItem=state.items.damsel_revenge
 E.Consume=function(self,st,id) local ok=consume(self,st,id);change();return ok end
 check(not E:Use(p,'throw') and originalItem.count==3 and not D.current,'stale staged debit is discarded')
 E.Consume=consume
end
setup();local logger=LOD.RPGTestLog.Write;LOD.RPGTestLog.Write=function() error('injected diagnostic failure') end
r=arm();LOD.RPGTestLog.Write=logger;check(count()==2,'diagnostic exception cannot falsify successful payment')
setup();state.items.damsel_revenge.count=1;r=arm();check(count()==0 and not state.slots.throwable and not E:IsActive(p),'depletion restores normal controls')
-- All three actual procedural choices and source-independent canonical dice.
local seen={}
for seed=1,64 do
 setup();s.LevelSeed=seed;w.seed=seed
 local choice=D:PrepareGun(s,w)
 if not seen[choice.spec.class] then
  local q=arm();local hp=boss.hp;now=now+1;D:Service()
  check(q.spec==choice.spec and q.shots==1 and boss.hp<hp,'actual firing for '..choice.spec.class)
 end
 seen[choice.spec.class]=true
 check(choice and E:ValidateWearable(choice.item) and choice.item.definitionId==choice.spec.class,'canonical frozen firearm record')
end
check(table.Count(seen)==3,'fixed sample covers all eligible choices')
setup();r=arm();local gun=r.spec.class
local rollActor=Rolls.RollActorDamage;local rolledContract
Rolls.RollActorDamage=function(self,...) local c=rollActor(self,...);rolledContract=c;return c end
local realRng=Rolls._RNG
Rolls._RNG=function() return {Int=function(_,lo,hi) return hi end,Float=function() return 1 end} end
now=now+1;local before=boss.hp;D:Service()
check(rolledContract.profile.sides==Rolls.PlayerDamageProfiles[gun].sides and #rolledContract.values==1,'selected canonical single damage die')
check(not rolledContract.profile.rpgDerived and not rolledContract.equipmentSnapshot,'no player class/feat/item inheritance')
check(rolledContract.attackEvent.damselRevenge==true,'attack event does not capture a graph')
check(p.ps.magic==100 and next(p.ammo)==nil,'no player Magic or ammunition spent')
Rolls.RollActorDamage=rollActor;Rolls._RNG=realRng
-- Physical body/cover and slit bounds: the filter never includes the target,
-- Heroes, another door or the whole world. No authoritative collision is changed.
for _,obstacle in ipairs({'wall','hero','clone','turret','other_door','start_solid','all_solid','none'}) do
 setup();r=arm();local body=actor(obstacle,'lod_hostile',true)
 util.TraceLine=function(t)
  check(#t.filter==2 and t.filter[1]==damsel and t.filter[2]==jail,'only exact Damsel and gun port are filtered')
  if obstacle=='none' then return nil end
  return {Hit=true,Entity=body,StartSolid=obstacle=='start_solid',AllSolid=obstacle=='all_solid'}
 end
 local n=engineCalls;now=now+1;D:Service();check(engineCalls==n and r.shots==0,'blocked trace does not damage '..obstacle)
end
setup();r=arm();local from,to=D:Path(r);check(from and D:ThroughPort(r,from,to),'central port accepted')
check(not D:ThroughPort(r,from+Vector(0,200,0),to+Vector(0,200,0)),'side cannot bypass whole door')
check(not D:ThroughPort(r,from+Vector(0,0,80),to+Vector(0,0,80)),'header cannot be filtered')
check(not D:ThroughPort(r,from,from+Vector(1,0,0)),'ray must cross both slab faces')
-- A grazing diagonal can enter the near face inside and leave the far face outside.
local width=D:PortSize();local bound=width*.5-D.Config.inset
local x=jail.pos.x;local z=from.z;local thick=LOD.Config.Progression.GateThickness
check(not D:ThroughPort(r,Vector(x+thick, jail.pos.y+bound-2,z),Vector(x-thick,jail.pos.y+bound+8,z)),'both slab faces are checked')
-- Real independent support persists through user death/disconnect but never fires alone.
setup();r=arm();p.hp=0;p.valid=false;heroes={friend};now=now+1;before=boss.hp;D:Service()
check(boss.hp<before and D.current==r,'activation is encounter-owned after user disconnect')
heroes={};now=now+1;before=boss.hp;D:Service();check(boss.hp==before and not r.retired,'no Hero means waiting, not retirement')
heroes={friend};s.SimulationFrozen=true;now=now+20;D:Service();check(boss.hp==before,'freeze pauses attacks')
s.SimulationFrozen=false;now=now+.21;D:Service();check(r.shots==2,'resumption emits one shot, no catch-up')
-- Hostile cloak or a move outside the exact court disables acquisition.
for _,change in ipairs({function() boss.nw.LOD_WardenHidden=true end,function() boss:SetPos(N:CellCenter(a.entry)) end,
 function() boss:SetPos(boss:GetPos()+Vector(0,0,mc.LevelHeight)) end}) do
 setup();r=arm();change();now=now+1;before=boss.hp;D:Service();check(boss.hp==before and not r.retired,'ineligible real Gordon is not acquired')
end
-- Exact source/run/Gordon ownership is rechecked at service, after the first
-- native hook, and after actual defender mitigation (the final GM seam).
local changes={
 function() R.State={} end,function() s.Graph={} end,function() s.Graph.Progression={} end,
 function() s.CampaignEpoch=3 end,function() s.CampaignSeed=1 end,function() s.RunId='new' end,
 function() s.Level=2 end,function() s.LevelSeed=99 end,function() s.Warden={} end,
 function() w.actor=friend end,function() w.graph={} end,function() w.revenge={} end,
 function() s.RescueEntity=friend end,function() damsel.LODRevengeOwner={} end,
 function() damsel.LODRescueTarget={} end,function() damsel.LODProgressionState={} end,
 function() Status.ActorLives[damsel]={} end,function() damsel:SetPos(damsel.pos+Vector(5,0,0)) end,
 function() jail.LODRevengeOwner={} end,function() jail.axis=1 end,
 function() s.Graph.Progression.JailEdge={} end,function() jail:SetPos(jail.pos+Vector(2,0,0)) end,
 function() boss.LODProgressionState={} end,function() Status.ActorLives[boss]={} end,
 function() s.Failed=true end,function() s.BuildReady=false end,
}
for _,change in ipairs(changes) do
 setup();r=arm();change();now=now+1;D:Service();check(r.retired and not D.current,'service retires exact stale binding')
end
for _,change in ipairs({function() boss.LODWardenOwner={} end,function() w.actor=friend end,
 function() Status.ActorLives[boss]={} end,function() s.Graph={} end,
 function() s.SimulationFrozen=true end,function() boss:SetPos(boss.pos+Vector(5,0,0)) end,
 function() damsel.LODRevengeOwner={} end}) do
 setup();r=arm();nativeMutation=change;before=boss.hp;now=now+1;D:Service()
 check(boss.hp==before,'post-hook native owner mutation rejects packet')
end
setup();r=arm();before=boss.hp;local defense=Rules.ApplyPlayerDefense
Rules.ApplyPlayerDefense=function(self,target,info) local v=defense(self,target,info);w.actor=friend;return v end
now=now+1;D:Service();Rules.ApplyPlayerDefense=defense
check(boss.hp==before,'ownership replacement during real mitigation cannot hit')
setup();r=arm();before=boss.hp;local reentered=false
nativeMutation=function(e,info) if not reentered then reentered=true;check(GM:EntityTakeDamage(e,info)~=true,'first native admission') end end
now=now+1;D:Service();check(boss.hp==before,'replayed packet is admitted at most once')
-- Independent parent damage-info cleanup cannot leave a borrowed receipt live.
setup();r=arm();before=boss.hp
nativeMutation=function(_,info) LOD.ReleaseDamageInfo(info) end
now=now+1;D:Service();check(boss.hp==before,'borrowed packet release invalidates the open commitment')
-- Legal kill is not rescue. The D20 handoff sees fire stopped before Hector.
local function defeat()
 boss.hp=0;boss.LODDead=true;if s.Level==20 then w.combatDeath=boss end
 W:Killed(boss);check(w.dead and r.defeated and not r.active,'real Gordon lethal ordering')
 check(not s.LevelCleared and not r.dropped and created==0,'Gordon death grants no gun or rescue')
end
local function rescue()
 s.JailKey=true;s.JailDoorOpen=true;jail.opened=true;s.ObjectiveStage=P.Stages.RESCUE_TARGET
 p:SetPos(damsel.pos)
 check(P:OnRescueTargetTouched(p,damsel),'normal progression-to-CompleteLevel rescue succeeds')
 check(s.LevelCleared and s.RescuedDamsels[s.Level] and r.rescued,'accepted canonical rescue record')
 check(created==0,'no native creation inside Touch/Use settlement')
 now=now+.21;D:Service()
 return r.drop
end
setup();r=arm();check(not P:OnRescueTargetTouched(p,damsel) and not r.rescued,'early rescue cannot drop gun')
defeat();local itemId=r.item.id;local drop=rescue()
check(IsValid(drop) and created==1 and drop.LODLootRegistered,'actual individualized LootDirector drop created')
check(drop:GetPos():DistToSqr(r.origin+Vector(0,0,6))==0 and drop.LODLootPayload.item.id==itemId,'same frozen gun at her feet')
check(not LOD.LootDirector:Collect(drop,friend,false),'non-owner cannot collect')
local capacity=E.MaximumStoredEquipment;E.MaximumStoredEquipment=0
check(not LOD.LootDirector:Collect(drop,p,false) and not drop.LODCollected,'full bag leaves pickup')
E.MaximumStoredEquipment=capacity
check(LOD.LootDirector:Collect(drop,p,false),'owner collects during exact victory window')
check(state.items[itemId] and not E:Equipped(state,r.spec.class) and next(p.ammo)==nil,'bag record only: no ammo or equipped effects')
check(not LOD.LootDirector:Collect(drop,p,false),'duplicate collection rejected')
check(not P:OnRescueTargetTouched(p,damsel) and created==1,'rescue cannot repeat')
now=now+1;D:Service();check(created==1,'service cannot duplicate pickup')
D:Retire(r,'transition');D:FlushCleanup();check(not IsValid(drop) and state.items[itemId],'cleanup preserves collected inventory only')
-- The Damsel's own solid hull can occlude a pickup at her feet. Native Touch/Use
-- forward to the SAME deferred loot transaction, never a separate inventory grant.
local oldInclude,oldENT=include,ENT
include=noop;ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_deborah/init.lua');local rescueENT=ENT
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_loot_pickup/init.lua');local lootENT=ENT
include,ENT=oldInclude,oldENT
setup();r=arm();defeat();drop=rescue();drop._TryCollect=lootENT._TryCollect;drop.LODLootReady=true
local queued=#env.timers;itemId=r.item.id
rescueENT.Touch(damsel,friend);check(#env.timers==queued,'non-owner native touch cannot claim')
rescueENT.Touch(damsel,p);rescueENT.Use(damsel,p)
check(#env.timers==queued+1 and not state.items[itemId],'touch and use coalesce outside native callbacks')
env.timers[queued+1]()
check(state.items[itemId] and not IsValid(drop),'deferred at-feet collection passes actual loot and inventory')
check(rescueENT.OnTakeDamage(damsel)==0,'Damsel protection remains unchanged')
setup();r=arm();defeat();drop=rescue();drop._TryCollect=lootENT._TryCollect;drop.LODLootReady=true
queued=#env.timers;itemId=r.item.id;rescueENT.Touch(damsel,p)
D:Retire(r,'reset before collection');D:FlushCleanup();env.timers[queued+1]()
check(not state.items[itemId] and not IsValid(drop),'deferred native pickup cannot cross reset')
-- Other loot never inherits the accepted rescue exception.
setup();r=arm();defeat();drop=rescue()
local other=LOD.LootDirector:SpawnPickup(p.id,drop.pos,'wearable',{item=r.item},{})
check(not LOD.LootDirector:Collect(other,p,false),'ordinary loot remains closed during victory')
local realPayload=drop.LODLootPayload.item;drop.LODLootPayload.item=table.Copy(realPayload)
check(not LOD.LootDirector:Collect(drop,p,false),'payload identity cannot be swapped');drop.LODLootPayload.item=realPayload
p:SetPos(drop.pos+Vector(97,0,0));check(not LOD.LootDirector:Collect(drop,p,false),'collection distance is bounded')
p:SetPos(drop.pos);now=s.IntermissionEnd;check(not LOD.LootDirector:Collect(drop,p,false),'expired victory window cannot collect')
-- Finite retry on unavailable creation keeps the item exactly unchanged.
setup();r=arm();defeat();creationMode='nil';rescue();check(r.dropTries==1 and not r.dropped,'first creation denial')
now=now+.21;D:Service();check(r.dropTries==2,'second fixed retry')
creationMode=nil;now=now+.21;D:Service();check(r.dropTries==3 and r.dropped and created==3,'third attempt succeeds once')
setup();r=arm();defeat();creationMode='nil';rescue()
for i=1,5 do now=now+.21;D:Service() end
check(r.dropTries==3 and not r.dropped and created==3,'creation failure is finite; no re-roll or grant')
setup();r=arm();defeat();creationMode='throw';rescue();check(r.dropTries==3 and not r.dropped,'throwing native adapter terminates retries')
-- Wipe/reset stops work and cleans only exact-owned resources.
setup();r=arm();defeat();drop=rescue();s.Failed=true;now=now+1;D:Service()
check(r.retired and not IsValid(drop) and not state.items[r.pickupItem.id],'failure does not mint inventory')
setup(20);r=arm();local transferred=false
LOD.Hector={OnGordonDefeated=function(_,ss,ww,aa,e)
 check(ss==s and ww==w and aa==a and e==boss and r.defeated and not r.active,'D20 support retires before Hector reveal');transferred=true;return true end,
 RescueAllowed=function() return false end}
defeat();check(transferred and not P:CanRescueTarget(),'Hector remains progression authority')
boss.valid=false;now=now+1;D:Service();check(not r.retired and not r.dropped,'legitimate corpse removal preserves frozen gun')
check(not P:OnRescueTargetTouched(p,damsel),'Hector cannot be bypassed')
LOD.Hector.RescueAllowed=function() return true end;drop=rescue();check(IsValid(drop),'D20 normal post-Hector rescue drops the gun')
LOD.Hector=nil
print('SPOT09_SERVER_PATH_PASS '..checks..' assertions')
-- Distribution preserves every earlier conversion, and never converts a fixed potion.
setup();local converted,preserved=0,0
for i=1,512 do
 local source='revenge-proof-'..i;local options={staticId=source,equipmentEligible=true}
 local seed=LOD.Seeds.Derive(s.CampaignSeed,E:RewardKey(p.id,source))
 local rng=LOD.RNG.New(LOD.Seeds.Derive(seed,'equipment-conversion-v2'))
 local expected
 if LOD.RNG.New(LOD.Seeds.Derive(seed,'summon-card-v1')):Chance(1/8) then expected='summon_card'
 elseif LOD.RNG.New(LOD.Seeds.Derive(seed,'resurrection-feather-v1')):Chance(1/8) then expected='resurrection_feather'
 elseif LOD.RNG.New(LOD.Seeds.Derive(seed,'magic-hourglass-v1')):Chance(1/16) then expected='magic_hourglass'
 elseif rng:Chance(.35) then expected=(not E.BombTypes or rng:Chance(.35)) and 'stink_bomb' or rng:Pick(E.BombTypes)
 elseif LOD.RNG.New(LOD.Seeds.Derive(seed,'chest-key-v1')):Chance(1/16) then expected='chest_key' end
 local kind,payload=E:PrepareReward(p.id,'consumable',{itemId='healing_potion'},options)
 if expected then assert(payload.itemId==expected);preserved=preserved+1
 else
  local revenge=LOD.RNG.New(LOD.Seeds.Derive(seed,'damsel-revenge-v1')):Chance(1/16)
  assert(payload.itemId==(revenge and 'damsel_revenge' or 'healing_potion'))
  if revenge then converted=converted+1 end
 end
 local _,same=E:PrepareReward(p.id,'consumable',{itemId='healing_potion'},options)
 assert(same.itemId==payload.itemId and LOD.LootDirector:_PreparedRewardValid(kind,payload))
 local _,fixed=E:PrepareReward(p.id,'consumable',{itemId='healing_potion'},{staticId=source})
 assert(fixed.itemId=='healing_potion')
end
check(converted>0 and preserved>0,'512-source deterministic conversion including old outcome preservation')
check(E.Definitions.damsel_revenge.maxStack==3 and not E:AddConsumable(state,'damsel_revenge',1),'finite stack')
-- Creation failing AFTER native entity allocation is also retired outside the callback.
setup();r=arm();defeat();local partial
ents.Create=function(class) created=created+1;partial=actor('partial',class);partial.Spawn=function() error('injected Spawn failure') end;return partial end
rescue();check(partial.removed and r.dropTries==3 and not r.dropped,'partial native drop cleaned after throwing Spawn')
-- A callback may reset the campaign during allocation. CaptureCandidate prevents
-- orphaned native loot; nothing can acquire a receipt in the replacement world.
setup();r=arm();defeat()
ents.Create=function(class) created=created+1;partial=actor('stale',class);partial.Spawn=function() s.Failed=true end;return partial end
rescue();check(not IsValid(partial) and not r.dropped,'mid-Spawn ownership loss removes exact candidate')
-- Native packet exception has no retained callbacks; ordinary packets remain ordinary.
setup();r=arm();boss.TakeDamageInfo=function() error('injected native HP adapter failure') end
now=now+1;D:Service();check(r.retired and next(D.Packets)==nil and next(Rolls.PendingDamageReports)==nil,'packet exception retires all callbacks')
setup();local plain=LOD.NewDamageInfo();plain:SetAttacker(p);plain:SetInflictor(p);plain:SetDamage(5);plain:SetDamageType(DMG_BULLET)
check(not D:IsSupportPacket(plain),'ordinary Hero packet is not intercepted')
-- Testkit is deliberately unranked, with no progression shortcuts.
local kit=commands.lod_damsel_revenge_testkit;check(type(kit)=='function','diagnostic kit registered')
setup();state.items.damsel_revenge.count=1;local deadline=s.CampaignClock.deadline
kit(p);check(count()==3 and s.Ranked==false and not w.dead and not s.JailKey and not s.JailDoorOpen and s.CampaignClock.deadline==deadline,'testkit only supplies normal utility')
-- Client-only ownership lease, pose cleanup, finite gun reuse and matching slit.
setup();r=arm();D:Service()
local AM={};AM.__index=AM
function AM:Forward() return Vector(1,0,0) end
AM.__eq=function(x,y) return x.p==y.p and x.y==y.y and x.r==y.r end
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},AM) end
angle_zero=Angle()
local models,boxes={},{}
local boneIds={};local boneAngles={}
function damsel:LookupBone(name) if not boneIds[name] then boneIds[name]=table.Count(boneIds)+1 end;return boneIds[name] end
function damsel:GetManipulateBoneAngles(i) return boneAngles[i] or Angle() end
function damsel:ManipulateBoneAngles(i,a) boneAngles[i]=a end
function damsel:GetBoneMatrix() return {GetTranslation=function() return self.pos+Vector(12,-6,48) end} end
function damsel:GetForward() return Vector(-1,0,0) end
function damsel:LocalToWorld(v) return self.pos+v end
ClientsideModel=function(model)
 local m=actor(model,'client_model');m.SetNoDraw=noop;m.DrawModel=function(self) self.draws=(self.draws or 0)+1 end
 models[#models+1]=m;return m
end
render={DrawBox=function(origin,ang,lo,hi,color) boxes[#boxes+1]={lo=lo,hi=hi} end}
dofile(root..'cl_damsel_revenge.lua')
check(D:VisualCurrent(damsel),'matching current server leases admit client visual')
D:Pose(damsel);D:Pose(damsel);D:DrawGun(damsel)
check(#models==1 and models[1].draws==1 and table.Count(D.visual.bones)==4,'one native client model and four owned arm edits')
local pc=LOD.Config.Progression
local mins,maxs=Vector(-pc.GateThickness/2,-pc.GateWidth/2,-pc.GateBlockerHeight/2),Vector(pc.GateThickness/2,pc.GateWidth/2,pc.GateBlockerHeight/2)
check(D:DrawPort(jail,jail.pos,mins,maxs,Color(1,1,1)) and #boxes==4,'visible port is four bounded surrounding panels')
local vol=0
for _,b in ipairs(boxes) do vol=vol+(b.hi.x-b.lo.x)*(b.hi.y-b.lo.y)*(b.hi.z-b.lo.z) end
local width,height=D:PortSize()
check(math.abs(vol-pc.GateThickness*(pc.GateWidth*pc.GateBlockerHeight-width*height))<.001,'only matching slit volume omitted')
check(not jail.opened and D:ThroughPort(r,r.origin+Vector(0,0,52),boss:WorldSpaceCenter()),'client slit does not open lock or collision')
local foreign=Angle(8,9,10);local index=next(D.visual.bones);damsel:ManipulateBoneAngles(index,foreign)
local model=D.visual.model;now=now+.61;env.hooks.LOD_DamselRevengeVisualLifetime()
check(model.removed and not D.visual and boneAngles[index]==foreign,'expired lease removes model and preserves foreign pose edits')
now=now+1;D:Service();D:Pose(damsel);check(#models==2,'current late observer recreates one visual without a discovery cache')
damsel.nw.LOD_CashTarget=true;env.hooks.LOD_DamselRevengeVisualLifetime();check(not D:VisualCurrent(damsel),'cash mode excludes client gun')
damsel.nw.LOD_CashTarget=false;D:ReleaseVisual();check(models[2].removed,'explicit client cleanup removes exact owned model')
D:Retire(r,'test end');D:FlushCleanup()
print('SPOT09_FOCUSED_PASS '..checks..' assertions; plus 512 seeded reward cases')
