-- Production roster/state/placement/animation tests with only engine boundaries doubled.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sv_hostile_motion_v2.lua')
GM=GM or {};dofile(root.."sv_damage_info.lua")
local noop=function() end
local v=getmetatable(Vector())
v.__div=function(a,b) return a*(1/b) end
v.__unm=function(a) return a*-1 end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function v:Normalize() local n=self:GetNormalized();self.x,self.y,self.z=n.x,n.y,n.z end
local am={};am.__index=am
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},am) end
function am:Forward() local y=math.rad(self.y);return Vector(math.cos(y),math.sin(y),0) end
function v:Angle() return Angle(0,math.deg(math.atan(self.y,self.x)),0) end
function math.AngleDifference(a,b) return (a-b+180)%360-180 end
function table.Count(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
ACT_IDLE,ACT_RUN_AIM_RIFLE,ACT_IDLE_ANGRY_SMG1,ACT_RANGE_ATTACK1,ACT_FLY=4,5,6,7,8
MASK_SOLID=3;NULL={valid=false};DMG_ENERGYBEAM,DMG_BURN,DMG_POISON,DMG_SLASH=4,5,6,7
net.WriteUInt=noop;net.WriteVector=noop;net.WriteBool=noop;net.Broadcast=noop
local motion=LOD.HostileMotionV2
motion.FaceToward=noop
motion.Stop=function(_,e) e.stopped=true end
motion.HoldHitStun=function(_,e,now) return now<(e.LODHitStunUntil or 0) end
motion.MoveToward=function(_,e,wp) e.waypoint=wp end
LOD.WanderingDirector={Config={ArchetypeWeights={}},GetDeficitReservation=function() return 0 end}
local context,rolls,damage={},0,0
LOD.RPGStatusElements={CanInitiateAttack=function(_,e) return not e.disabled end,CanMoveVoluntarily=function(_,e) return not e.held end,
    Has=function(_,e) return e.fleeing end,HandleAIFlee=function() return false end,ConditionDC=function() return 13 end,
    AttachDamageContext=function(_,info,tags) context[#context+1]=tags end}
LOD.RPGStatusElements.ActorLives={}
LOD.RPGStatusElements.BindActorLife=function(self,e) self.ActorLives[e]=self.ActorLives[e] or {} end
LOD.RPGAbilityRules={RateOfFireMultiplier=function() return 1 end,ProgressionState=function(_,e) return e.LODProgressionState end}
function DamageInfo() return {SetAttacker=noop,SetInflictor=noop,SetDamageType=noop,SetDamagePosition=noop,SetDamage=function(self,n) self.amount=n end} end
LOD.CombatRolls.RollHostileAttack=function(_,e,p,amount) rolls=rolls+1;return {total=amount,scale=1,attackEvent={}} end
LOD.CombatRolls.ResolveActorDamage=function(_,c) return c.total end
LOD.CombatRolls.QueueDamageReport=noop
local time=100
local function at(n) time=n;env.setTime(n) end
at(time)
local function actor(id,pos)
    local e=env.actor(1);e.LODArchetypeId=id;e:SetPos(pos or Vector())
    e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[id] or {})
    e.SetNW2Int=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool;e.SetNW2Entity=e.SetNW2Bool;e.SetNW2String=e.SetNW2Bool
    e.SetColor=noop;e.GetAngles=function() return Angle() end
    e.GetNW2Float=function(_,_,default) return default end
    e.GetNW2Entity=function(self,k,default) return self.nw[k] or default end
    e.GetNW2Int=function(self,k,default) return self.nw[k] or default end
    e.EyePos=function(self) return self:GetPos()+Vector(0,0,64) end;e.EyeAngles=function() return Angle() end
    e.WorldSpaceAABB=function(self) return self:GetPos(),self:GetPos()+Vector(0,0,self.crouched and 36 or 72) end
    e.TakeDamageInfo=function(self,info) damage=damage+1;self.hits=(self.hits or 0)+1 end
    return e
end
local p=actor('hero',Vector(120,0,0));p.player=true;p.LODHostile=false
player.GetAll=function() return {p} end
util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end
util.DistanceToLine=function(a,b,p) local d=b-a;local f=math.Clamp((p-a):Dot(d)/math.max(.01,d:LengthSqr()),0,1);return (p-(a+d*f)):Length() end
util.Effect=noop;function EffectData() return {SetOrigin=noop} end
local s=LOD.RunManager.State;s.BuildReady=true;s.Failed=false;s.LevelCleared=false;s.LevelSeed=123;s.SimulationFrozen=false
-- Test all model/activity failures without ever invoking an invalid native sequence.
dofile(root..'sv_hostile_animation.lua')
local A=LOD.HostileAnimation
local names={[0]='reference',[1]='run_all',[2]='idle',[3]='walk',[4]='ragdoll'}
local e={model='combine',seq=0,rate=0,lookups=0}
function e:GetModel() return self.model end
function e:GetSequenceName(i) return names[i] or '' end
function e:GetSequence() return self.seq end
function e:GetPlaybackRate() return self.rate end
function e:SetPlaybackRate(r) self.rate=r end
function e:ResetSequence(i) assert(A:Valid(self,i));self.seq=i;self.resets=(self.resets or 0)+1 end
function e:SelectWeightedSequence(act) self.lookups=self.lookups+1;return act==ACT_RUN_AIM_RIFLE and 1 or (act==ACT_WALK and 3 or -1) end
function e:LookupSequence(name) return name=='idle' and 2 or -1 end
assert(A:Apply(e,ACT_RUN) and e.seq==1,'Sniper unsupported ACT_RUN must resolve Combine run')
local checks=e.lookups;A:Apply(e,ACT_RUN);assert(e.lookups==checks and e.resets==1,'no per-frame lookup/reset')
e.model='zombie';e.SelectWeightedSequence=function(_,act) return act==ACT_WALK and 3 or -1 end
assert(A:Apply(e,ACT_RUN) and e.seq==3,'zombie unsupported run resolves walk')
e.rate=0;A:Apply(e,ACT_RUN);assert(e.rate==1,'retreat must unfreeze flinch playback')
e.LODConfig={activity=ACT_WALK};e._SetActivity=function(self,act) self.moveActivity=act end
A:Move(e);assert(e.moveActivity==ACT_WALK,'retreat selects model locomotion')
assert(not A:Valid(e,-1) and not A:Valid(e,0) and not A:Valid(e,4))
-- Load real roster and every specialized behavior.
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_patterns.lua');dofile(root..'sv_enemy_traps.lua');dofile(root..'sv_climber.lua');dofile(root..'sv_enemy_pursuit.lua');dofile(root..'sv_enemy_roster_placement.lua')
local E,C=LOD.EnemyRoster,LOD.Climber
for id,d in pairs(E.Definitions) do
    assert(LOD.Config.Encounter.Archetypes[id] and LOD.CombatRolls.HostileDamageProfiles[id])
    local e=actor(id);e.LODTarget=p
    if id~='climber' and id~='nodule' and not d.trap and not d.melee and not d.tactical and not d.mobile and not d.condition and not d.resource and not d.spacing and not d.crossfire and not d.discipline and not d.companion and not d.edict and not d.link then E:Prepare(e);E:Begin(e,p,time);assert(e.LODRosterAttack and e.nw.LOD_RosterAttack==1);E:Interrupt(e);assert(not e.LODRosterAttack) end
end
local f=actor('flamer');f.LODTarget=p;E:Prepare(f);E:Begin(f,p,time)
at(102);local a=f.LODRosterAttack;E:Attack(f,a,time);local n=damage;local r=rolls
E:Attack(f,a,time+.2);assert(damage==n and rolls==r,'flame one packet and roll per target/commitment')
assert(context[#context].riderStatusId=='immolated' and context[#context].riderDC==13)
local b=actor('bigcrab');E:Damage(b,p,{},'flame');assert(context[#context].riderStatusId=='immolated')
local l=actor('lurker');E:Damage(l,p,{},'venom');assert(context[#context].riderStatusId=='poisoned')
-- Charge interruption, frozen area and no damage behind cover.
local arc=actor('arccaster');E:Begin(arc,p,time);local mark=arc.LODRosterAttack.aim;local beforeArc=damage
p:SetPos(Vector(900,0,0));at(104);E:Attack(arc,arc.LODRosterAttack,time);assert(arc.nw.LOD_RosterAim==mark)
assert(damage==beforeArc);n=damage;E:Cancel(arc)
p:SetPos(Vector(120,0,0));E:Begin(arc,p,time);util.TraceLine=function(t) return {Hit=true,HitPos=t.start} end
at(106);E:Attack(arc,arc.LODRosterAttack,time);assert(damage==n and not arc.LODRosterAttack,'occlusion cancels charged eruption')
util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
-- Sweep is committed, bounded and stance-sensitive, one hit regardless of service count.
local beam=actor('beamsweeper');E:Begin(beam,p,time);at(108);E:Attack(beam,beam.LODRosterAttack,time)
a=beam.LODRosterAttack;assert(a.released);E:Interrupt(beam);assert(beam.LODRosterAttack==a)
p.crouched=true;E:Attack(beam,a,108.6);assert(damage==n,'crouched Hero below fixed beam')
p.crouched=false;a.previous=-1;E:Attack(beam,a,108.6);assert(damage==n+1)
E:Attack(beam,a,108.7);assert(damage==n+1,'repeat service must not repeat sweep damage')
assert(context[#context].magic and context[#context].element=='raw' and not context[#context].riderStatusId)
-- Create a square graph with a true alternate approach and closed wall lanes.
local graph={Cells={},CellTags={},VerticalEdges={},Progression={Gates={}}};local key=LOD.MazeGenerator.CellKey
for x=1,2 do for y=1,2 do graph.Cells[key(x,y,0)]={x=x,y=y,z=0,neighbors={}} end end
-- A legal branch gives the B3 interceptor a reachable three-exit junction.
graph.Cells[key(3,2,0)]={x=3,y=2,z=0,neighbors={}}
for _,cell in pairs(graph.Cells) do for _,other in pairs(graph.Cells) do if math.abs(cell.x-other.x)+math.abs(cell.y-other.y)==1 then cell.neighbors[key(other.x,other.y,0)]=true end end end
s.Graph=graph;s.GatesOpen={};local cell=graph.Cells[key(1,1,0)];local N=LOD.MazeNavigator
assert(E:HasAlternate(graph,cell))
assert(E:Placement(graph,cell,'sentry','arena'))
assert(E:Placement(graph,cell,'beamsweeper','arena'))
assert(not E:Placement(graph,cell,'lurker','arena'),'no ceiling anchor -> no Lurker')
util.TraceLine=function(t) return {Hit=true,HitPos=t.endpos,HitNormal=Vector(0,0,-1)} end
assert(E:Placement(graph,cell,'lurker','arena').ceiling)
graph.CellTags[key(1,1,0)]={safe=true};assert(not E:Placement(graph,cell,'sentry','arena'))
graph.CellTags={};graph.VerticalEdges={{a=cell,b=graph.Cells[key(1,2,0)]}};assert(not E:Placement(graph,cell,'lurker','arena'))
graph.VerticalEdges={};util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
local lane=C:NearestLane(graph,cell,N:CellCenter(cell));assert(lane and lane.pos.z>N:CellCenter(cell).z)
local climber=actor('climber',lane.pos);climber.LODHomeCellKey=key(1,1,0)
p:SetPos(N:CellCenter(graph.Cells[key(2,1,0)]));C:Route(climber,graph,p)
assert(#climber.LODWallRoute>0,'connected exterior walls create chase route')
for _,wp in ipairs(climber.LODWallRoute) do assert(wp.pos.z>=N:CellCenter(cell).z+72) end
local start=climber:GetPos();util.TraceHull=function(t) return {Hit=true,HitPos=t.start} end
assert(not C:Step(climber,start+Vector(30,0,0),205,.05,false) and climber:GetPos()==start,'wall trace blocks traversal')
util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end
climber.LODClimberVictim=p;climber.LODClimberFloor=0;climber.LODWallInitialized=true;climber.LODNextBite=0
at(110);C:Tick(climber,s,time);local victim=climber.LODClimberVictim;assert(victim==p)
C:Interrupt(climber);assert(climber.LODClimberVictim==p and climber.LODNextBite>time,'nonlethal stun preserves face latch')
p.alive=false;C:Tick(climber,s,time);assert(not climber.LODClimberVictim,'victim death detaches immediately')
p.alive=true
-- Gas is tied to exactly one graph cell and stops on exit/death; no Poisoned rider.
local gas=actor('nodule',N:CellCenter(cell));E:Prepare(gas)
p:SetPos(N:CellCenter(cell));local before=damage;at(112);E:Tick(gas);assert(damage==before+1)
assert(not context[#context].riderStatusId,'gas must not invent Poisoned')
p:SetPos(N:CellCenter(graph.Cells[key(2,1,0)]));at(113);E:Tick(gas);assert(damage==before+1)
gas.LODDead=true;p:SetPos(N:CellCenter(cell));at(114);E:Tick(gas);assert(damage==before+1)
-- Cleared/frozen lifecycle retires attacks and projectiles without delayed hits.
E.Active={};E.Projectiles={};local enemy=actor('lurker');E:Prepare(enemy);E:Begin(enemy,p,time)
E:Release(enemy,enemy.LODRosterAttack,time);assert(#E.Projectiles==1)
s.SimulationFrozen=true;at(111);env.hooks.LOD_EnemyRosterAttacks();assert(#E.Projectiles==0 and not enemy.LODRosterAttack)
assert(LOD.WanderingDirector.Config.ArchetypeWeights.flamer==3)
for _,id in ipairs({'climber','bigcrab','sentry','razor','arccaster','lurker','beamsweeper'}) do assert(not LOD.WanderingDirector.Config.ArchetypeWeights[id]) end
-- Every configured archetype reaches the production unified spawner.
s.SimulationFrozen=false;s.Failed=false;s.LevelCleared=false;s.Graph=graph
local D=LOD.EncounterDirector
D.Entities={};D.activeCount=0
ents.Create=function()
    local e=actor('shambler')
    function e:Spawn() self.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[self.LODArchetypeId]) end
    return e
end
motion.SnapSpawn=noop
util.TraceLine=function(t)
    if t.endpos.z-t.start.z>200 then return {Hit=true,HitPos=t.endpos,HitNormal=Vector(0,0,-1)} end
    return {Hit=false,HitPos=t.endpos}
end
local ordinal=0
for id in pairs(E.Definitions) do
    ordinal=ordinal+1
    local enc={id=100+ordinal,cell=cell,cellKey=key(1,1,0),role='arena',composition={[id]=1},entities={}}
    assert(D:_SpawnEncounter(enc) and #enc.entities==1 and enc.entities[1].LODArchetypeId==id,'production spawn omitted '..id)
    assert(enc.entities[1].LODEncounterOrdinal==1)
    if id=='lurker' then assert(enc.entities[1].LODRosterPlacement.ceiling) end
end
local denied={id=300,cell=cell,cellKey=key(1,1,0),role='arena',composition={flamer=1},entities={}}
D.activeCount=LOD.Config.Encounter.ActiveHostileCeiling
assert(not D:_SpawnEncounter(denied) and #denied.entities==0,'new roster obeys shared population cap')
D.activeCount=0
-- Protected placements convert to an ordinary budget-safe body, never a ceiling hazard.
graph.CellTags[key(1,1,0)]={safe=true}
local rejected={id=301,cell=cell,cellKey=key(1,1,0),role='arena',composition={lurker=1},entities={}}
assert(D:_SpawnEncounter(rejected) and rejected.entities[1].LODArchetypeId=='shambler')
graph.CellTags={}
-- A delayed record from a prior state with an identical seed cannot hit this run.
E.Projectiles={{owner=enemy,pos=Vector(),velocity=Vector(1,0,0),expires=9999,seed=s.LevelSeed,run={},kind='venom',event={}}}
at(120);env.hooks.LOD_EnemyRosterAttacks();assert(#E.Projectiles==0)
print('ENEMY_ROSTER_PASS: nine archetypes; animation fallback/cache/recovery; fire/venom riders; frozen marks/LOS; sweep stance/dedup; fair placements; legal wall routing/latch lifecycle; freeze cleanup')

-- Recovery movement, physical container clearance and rendered Nodule volume.
s.SimulationFrozen=false;s.Failed=false;s.LevelCleared=false;s.BuildReady=true
at(150);p:SetPos(Vector(600,0,0));local mobile=actor('arccaster')
mobile.LODActivated=true;mobile.LODTarget=p;mobile.LODNextAttack=155
mobile._RefreshTarget=noop;mobile._RefreshRoute=function(self) self.routeAsked=true end
mobile._AdvanceWaypoint=function() return Vector(40,0,0) end
util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
E:Tick(mobile);assert(mobile.routeAsked and mobile.waypoint,'Arc Caster must travel during recovery inside cast range')
local half=LOD.Config.Maze.CellSize*.5
local wallHalf=(LOD.Config.Geometry and LOD.Config.Geometry.ContainerWidth or 128)*.5
local center=N:CellCenter(cell)
util.TraceHull=function(t)
    local delta=t.start-center
    return {Hit=math.abs(delta.x)+14>half-wallHalf or math.abs(delta.y)+14>half-wallHalf}
end
local safeLane=C:NearestLane(graph,cell,center)
assert(safeLane,'real wall thickness rejected every Climber lane')
assert(math.max(math.abs(safeLane.pos.x-center.x),math.abs(safeLane.pos.y-center.y))+14<=half-wallHalf)
local wallSpawn=E:Placement(graph,cell,'climber','ambush')
assert(wallSpawn and wallSpawn.wallLane and wallSpawn.pos.z==safeLane.pos.z,
    'Climber must spawn directly in its validated wall lane')
util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end
local runner=actor('climber',safeLane.pos)
runner.LODHomeCellKey=key(1,1,0);runner.LODWallInitialized=true
runner.LODNextAttack=9999;runner.LODTarget=p;runner.LODWallLast=150
runner.LODWallRoute={{pos=safeLane.pos},{pos=safeLane.pos+Vector(0,40,0)}}
runner.LODWallRouteIndex=2;runner.LODWallNextRoute=0
local committed=runner.LODWallRoute
at(150.05);C:Tick(runner,s,time)
assert(runner.LODWallRoute==committed,'Timed refresh replaced a partially traversed wall route')
dofile(root..'sh_hostile_shapes.lua')
util.GetModelBounds=function() return Vector(-18,-14,-52),Vector(18,14,4) end
SOLID_BBOX=2
local nodule=actor('nodule',Vector(80,90,10));local size=.5
nodule.GetNW2Float=function() return size end;nodule.GetModel=function() return 'models/barnacle.mdl' end
nodule.SetSolid=function(_,solid) assert(solid==SOLID_BBOX) end
nodule.SetCollisionBounds=function(self,lo,hi) self.lo=lo;self.hi=hi end
for _,value in ipairs({.5,1,1.33}) do
    size=value;E:Prepare(nodule)
    local lo,hi=E:CombatBounds(nodule)
    assert(nodule.lo.z==0 and nodule.hi.z==56*size and nodule.hi.x==18*size)
    assert(lo.z==10 and hi.z==10+56*size and lo.x==80-18*size,'inverted visible body and combat hull differ')
end
print('ENEMY_REPAIRS_PASS: Arc Caster recovery travel, Climber 128-unit wall clearance, Nodule inversion/size/growth hull parity')
