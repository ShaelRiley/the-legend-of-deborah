-- Execute the production graph selector, Sniper state machine, shared bolt,
-- hit-stun authority, encounter spawner and testkit with Source boundary doubles.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local now,blocked,visibleX=10,false,nil
local function noop() end
function CurTime() return now end
function IsValid(v) return type(v)=='table' and v.valid~=false end
function isnumber(v) return type(v)=='number' end
function isstring(v) return type(v)=='string' end
function Color(...) return {...} end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function table.Copy(t) local r={} for k,v in pairs(t) do r[k]=type(v)=='table' and table.Copy(v) or v end return r end
function table.HasValue(t,v) for _,x in ipairs(t) do if x==v then return true end end return false end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:Distance(b) return math.sqrt(self:DistToSqr(b)) end
function V:GetNormalized() local l=self:Length();return l>0 and self*(1/l) or Vector() end
function V:Angle() return {y=0,p=0} end
vector_origin=Vector()
ACT_RUN,ACT_WALK,ACT_IDLE_ANGRY=1,2,3
MASK_SHOT,MASK_NPCSOLID,MOVETYPE_NONE,SOLID_NONE,COLLISION_GROUP_PROJECTILE,DMG_BULLET=1,2,0,0,1,2
local commands,hooks={},{}
concommand={Add=function(id,f) commands[id]=f end}
hook={Add=function(_,id,f) hooks[id]=f end}
timer={Simple=noop}
scripted_ents={GetStored=function() end}
net={WriteDouble=function() end,Start=noop,Send=noop}
util={AddNetworkString=noop}
function GetConVar() return {GetBool=function() return true end} end
LOD={}
dofile(root..'sh_config.lua');dofile(root..'sv_m3_enemy_config.lua')
local EC,MC=LOD.Config.Encounter,LOD.Config.Maze
LOD.MazeGenerator={CellKey=function(x,y,z) return x..':'..y..':'..z end}
local key=LOD.MazeGenerator.CellKey
LOD.MazeBuilder={CellCenter=function(_,c) return Vector((c.x-(MC.Width+1)*.5)*MC.CellSize+MC.Origin.x,
    (c.y-(MC.Height+1)*.5)*MC.CellSize+MC.Origin.y,c.z*MC.LevelHeight+MC.Origin.z) end}
LOD.RunManager={State={BuildReady=true,LevelSeed=123,Level=1,GatesOpen={}},MarkUnranked=function(self) self.unranked=true end}
LOD.CombatRolls={HostileDamageProfiles={}}
dofile(root..'sv_faction_manager.lua')
-- Keep only the actor-membership boundary doubled; acquisition is production.
LOD.FactionManager.IsValidPlayerTarget=function(_,p) return IsValid(p) and p.player and p.alive end
LOD.Equipment={CanAct=function() return true end}
dofile(root..'sv_maze_navigator.lua');dofile(root..'sv_encounter_director.lua')
local D,N=LOD.EncounterDirector,LOD.MazeNavigator
local graph={Cells={},CellTags={},VerticalEdges={},Progression={Gates={}}}
for i=1,8 do graph.Cells[key(i,1,0)]={x=i,y=1,z=0,neighbors={}} end
for i=1,7 do graph.Cells[key(i,1,0)].neighbors[key(i+1,1,0)]=true;graph.Cells[key(i+1,1,0)].neighbors[key(i,1,0)]=true end
LOD.RunManager.State.Graph=graph
local function pos(i) return N:CellCenter(graph.Cells[key(i,1,0)]) end
local function actor(i)
    local a={valid=true,pos=pos(i),nw={},alive=true,LODActivated=true,LODHostile=true,LODConfig=table.Copy(EC.Archetypes.soldier)}
    function a:GetPos() return self.pos end
    function a:SetPos(p) self.pos=p end
    function a:WorldSpaceCenter() return self.pos+Vector(0,0,36) end
    function a:SetNW2Bool(k,v) self.nw[k]=v end
    a.SetNW2Vector=a.SetNW2Bool
    function a:GetNW2String() return self.LODArchetypeId end
    function a:SetAngles(v) self.angles=v end
    function a:GetForward() return Vector(1,0,0) end
    function a:GetParent() return nil end
    function a:GetOwner() return nil end
    function a:IsPlayer() return self.player==true end
    function a:Alive() return self.alive end
    function a:IsAdmin() return true end
    function a:Health() return 35 end
    function a:EntIndex() return 99 end
    function a:Remove() self.valid=false end
    a._RefreshTarget=noop;a._RefreshRoute=noop;a._SetActivity=noop;a.EmitSound=noop
    a.SetVelocity=noop;a.SetMoveType=noop;a.SetSolid=noop;a.SetCollisionGroup=noop;a.NextThink=noop;a.Activate=noop;a.ChatPrint=noop
    function a:_AdvanceWaypoint() return self.LODWaypoints and self.LODWaypoints[self.LODWaypointIndex or 1] end
    return a
end
_G.player={}
local player=actor(1);player.player=true;player.LODHostile=false
local h=actor(3);h.LODArchetypeId='sniper';h.LODHomeCellKey=key(3,1,0);h.LODSniperVisualReady=true;h.LODTarget=player
util.TraceLine=function(o) return {Hit=blocked or (visibleX and math.abs(o.start.x-visibleX)>.01),Fraction=blocked and 0 or 1} end
util.TraceHull=function() return {Hit=false} end
local moved,stopped=0,0
LOD.HostileMotionV2={Stop=function() stopped=stopped+1 end,FaceToward=noop,
    HoldHitStun=function(_,e,t) return t<(e.LODHitStunUntil or 0) end,
    MoveToward=function(_,e,w) moved=moved+1;e.lastWaypoint=w end,SnapSpawn=noop}
local bolttype,created={},{}
function AddCSLuaFile() end
function include() end
ENT=bolttype;dofile('gamemodes/legend_of_deborah/entities/entities/lod_soldier_bolt/init.lua')
ents={FindAlongRay=function() return {} end,Create=function(class)
    local e=actor(3);e.class=class
    if class=='lod_soldier_bolt' then setmetatable(e,{__index=bolttype}) end
    function e:Spawn() if self.Initialize then self:Initialize() end end
    created[#created+1]=e;return e
end}
dofile(root..'sv_enemy_update.lua')
local U=LOD.EnemyUpdate
h.LODConfig=table.Copy(EC.Archetypes.sniper)
local destination,path=U:SelectPosition(h,graph,player)
assert(destination==key(7,1,0) and #path==5,'maximize range inside inherited leash')
graph.CellTags[key(7,1,0)]={safe=true}
assert(U:SelectPosition(h,graph,player)==key(6,1,0),'safe cells exclude routes as well as destinations')
graph.CellTags={}
graph.Progression.Gates={{edgeKey=N:EdgeKey(graph.Cells[key(5,1,0)],graph.Cells[key(6,1,0)])}}
assert(U:SelectPosition(h,graph,player)==key(5,1,0),'closed gate is never traversed')
LOD.RunManager.State.GatesOpen[1]=true
assert(U:SelectPosition(h,graph,player)==key(7,1,0),'opened gate unlocks legal firing positions')
EC.LeashCells=2;assert(U:SelectPosition(h,graph,player)==key(5,1,0),'home pursuit cap')
EC.LeashCells=6
visibleX=pos(4).x
assert(U:SelectPosition(h,graph,player)==key(4,1,0),'lost LOS uses shortest recovery path')
visibleX=nil
h.LODWaypoints={{pos=pos(4),stair=true}};h.LODWaypointIndex=1
U:Tick(h);assert(h.lastWaypoint.stair and not h.LODSniperShot,'stair connector is committed')
h.LODWaypoints={};h.pos=pos(7);h.LODSniperNextRoute=0
U:Tick(h);assert(h.LODSniperShot and h.nw.LOD_SoldierShotTelegraph and #created==0,'windup before projectile')
local shot=h.LODSniperShot;local frozen=shot.direction
player.pos=player.pos+Vector(20,70,0);now=shot.ready-.01
U:Tick(h);assert(#created==0,'cannot fire early')
now=shot.ready;U:Tick(h)
assert(#created==1 and created[1].LODDirection:DistToSqr(frozen)<1e-12 and not h.LODSniperShot,'finite bolt follows frozen warning')
local bolt=created[1]
assert(bolt.LODDamage==25 and bolt.LODLifetime==h.LODConfig.fireRange/h.LODConfig.projectileSpeed)
assert(bolt.LODAttackEvent==shot.attackEvent and bolt.nw.LOD_SniperBolt,'shared attack and presentation identity')
local start=bolt:GetPos();now=now+.05;bolt:Think()
assert(math.abs(start:Distance(bolt:GetPos())-47.5)<.001,'finite projectile speed')
now=bolt.LODExpireAt;bolt:Think();assert(not bolt.valid,'finite maximum lifetime')
player.pos=pos(1)
local function arm() h.LODSniperNextRoute=now+10;h.LODWaypoints={};h.LODHitStunUntil=nil;h.LODNextAttack=0;U:Tick(h);assert(h.LODSniperShot) end
arm();blocked=true;U:Tick(h);assert(not h.LODSniperShot,'LOS interruption cancels');blocked=false
arm();player.alive=false;U:Tick(h);assert(not h.LODSniperShot,'dead target cancels');player.alive=true
arm();LOD.RPGPerceptionState={IsInvisible=function(_,p) return p==player end}
assert(not U:CanShoot(h,player) and LOD.FactionManager:IsValidPlayerTarget(player))
U:Tick(h);assert(not h.LODSniperShot,'cloak cancels directed windup, not faction/damage membership')
LOD.RPGPerceptionState=nil

arm();LOD.RunManager.State.SimulationFrozen=true;U:Tick(h);assert(not h.LODSniperShot,'empty-world freeze cancels');LOD.RunManager.State.SimulationFrozen=false
arm();LOD.RunManager.State.LevelSeed=124;U:Tick(h);assert(not h.LODSniperShot,'level change cancels')
arm();dofile(root..'sv_m3_hit_feedback.lua');LOD.M3HitFeedback:ApplyHitStun(h)
assert(not h.LODSniperShot and not h.nw.LOD_SoldierShotTelegraph,'synchronous hit-stun cancels before wrapper short-circuit')
now=now+1
local out=D:_EligibleTemplates(3,'arena')
assert(table.HasValue(out,'sniper_firing_line') and table.HasValue(out,'blitzer_firing_line'))
assert(not table.HasValue(D:_EligibleTemplates(1,'ambush'),'sniper_firing_line'))
local plan={encounters={}}
local e=D:_AddEncounter(plan,graph.Cells[key(3,1,0)],3,'arena','sniper_firing_line',EC.Templates.sniper_firing_line.composition,false)
assert(e.threat==EC.Archetypes.soldier.threat+EC.Archetypes.sniper.threat,'existing threat budget charges variant')
D.Entities={};D.GetActiveCount=function(self) return self.activeCount or #self.Entities end
D._SpawnOffsets=function(_,count) local a={} for i=1,count do a[i]=Vector() end return a end
dofile(root..'sv_encounter_spawn_variance.lua')
e.composition={sniper=1,blitzer=1};D.activeCount=EC.ActiveHostileCeiling-1
assert(not D:_SpawnEncounter(e) and not e.spawned,'cap prevents partial spawn')
D.activeCount=0;assert(D:_SpawnEncounter(e));assert(#e.entities==2,'both archetypes actually materialize')
assert(e.entities[1].LODArchetypeId=='blitzer' and e.entities[2].LODArchetypeId=='sniper')
assert(e.entities[1].LODEncounterOrdinal==1 and e.entities[2].LODEncounterOrdinal==2)
D.Plan={encounters={}};LOD.RunManager.State.Graph.CellTags={}
dofile(root..'sv_enemy_update_testkit.lua')
local cells=U:TestCells(player,graph);assert(#cells>=2)
graph.CellTags[key(3,1,0)]={safe=true};assert(#U:TestCells(player,graph)==0,'testkit cannot tunnel through safe zone')
graph.CellTags={};D.activeCount=EC.ActiveHostileTarget-1
commands.lod_enemy_update_testkit(player);assert(not LOD.RunManager.unranked,'kit preserves reserve and does not mutate refused run')
D.activeCount=0;commands.lod_enemy_update_testkit(player)
assert(LOD.RunManager.unranked and #D.Plan.encounters==2 and LOD.RunManager.State.Level==1,'finite unranked kit, actual dungeon unchanged')
print('enemy_update PASS: graph range/LOS/gates/safes/leash/stairs, frozen aim, finite bolt, cancellations, encounter cost/cap/spawn, testkit lifecycle')
return {actor=actor,hero=player,commands=commands,hooks=hooks,setTime=function(v) now=v end}
