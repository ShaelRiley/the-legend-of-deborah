-- Execute real hostile coroutine, motion kernel, filtered cached navigation and
-- initialization guard against B29's actual generated graph/full build fixture.
local oldarg=arg[1];arg[1]='--runtime'
local H=dofile('tools/test_bestiary_b29.lua');arg[1]=oldarg
local S,g,T,R=H.S,H.graph,H.X.T,H.X.R
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local N=LOD.MazeNavigator
local function read(p) local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local hero=H.actor('dispatch-hero',2)
T.setHeroes({hero});LOD.FactionManager.LivingTargets=function()return {hero}end
R.State.PlayerState={};S:Deployed(hero,R.State)
local clock=30000;H.time(clock);S:Service()
local V=getmetatable(Vector());V.__div=function(a,b)return a*(1/b) end
function V:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
LOD.RPGAbilityRules=nil;LOD.HostileAnimation=nil;LOD.MagicForms=nil
LOD.RPGStatusElements={CanMoveVoluntarily=function()return true end,LocomotionMultiplier=function()return 1 end,ObserveCell=function()end}
dofile(root..'sv_hostile_motion_v2.lua')
local M=LOD.HostileMotionV2
-- Load the actual cached-navigation section with all its production helpers.
local cache=read(root..'sv_phase_zero_runtime_optimization.lua')
assert(load(cache:sub(1,assert(cache:find('LOD.HostileRegistry =',1,true))-1),'@production-cached-navigation'))()
local k=LOD.MazeGenerator.CellKey
local function filter(c) return S:HostilePathCell(g,c) end
assert(N:FindPath(g,H.cell(4),H.cell(0)),'unfiltered Hero route changed')
assert(not N:FindPath(g,H.cell(4),H.cell(0),filter),'cached path bypassed sanctuary predicate')
for i,gate in ipairs(g.Progression.Gates) do
 R.State.GatesOpen[i]=false
 assert(not N:CanTraverse(g,gate.beforeCell and k(gate.beforeCell.x,gate.beforeCell.y,gate.beforeCell.z),
  gate.afterCell and k(gate.afterCell.x,gate.afterCell.y,gate.afterCell.z)),'closed gate traversable')
end
local src=read('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local cls={}
assert(load('local ENT=...\n'..assert(src:match('(function ENT:RunBehaviour%(%)%s.-\nend)')),'@production-hostile-loop'))(cls)
assert(load('local ENT=...\n'..assert(src:match('(function ENT:Initialize%(%)%s.-\nend)')),'@production-hostile-initialize'))(cls)
local rejected=H.actor('invalid-native-spawn',0,true)
cls.Initialize(rejected);assert(not IsValid(rejected),'native Initialize admitted protected spawn')
local function hostile(name)
 local e=H.actor(name,4,true,'shambler');e.LODSpawnSource=name=='first' and 'wanderer' or 'encounter'
 e.LODHomeCellKey=k(H.cell(4).x,H.cell(4).y,H.cell(4).z);e.LODConfig={speed=180}
 e.SetAngles=function()end;e.GetAngles=function()return {y=0}end
 e._BehaviourTick=function(self)self.nativeTicks=(self.nativeTicks or 0)+1 end
 e.LODMotionLastUpdate=clock
 return e,coroutine.create(function() cls.RunBehaviour(e) end)
end
local first,c1=hostile('first');local excess,c2=hostile('excess')
for i=1,350 do
 clock=clock+.05;H.time(clock)
 local ok,err=coroutine.resume(c1);assert(ok,err)
 ok,err=coroutine.resume(c2);assert(ok,err)
 assert(not S:Protected(excess),'withdrawal crossed sanctuary')
 assert(not excess.LODTarget,'unadmitted native target persisted')
end
local r=S.Records['dispatch-hero']
assert((first.nativeTicks or 0)>0,'admitted archetype never ran')
assert(r.active and S:MemberDistance(r,excess,g)<math.huge and S:MemberDistance(r,excess,g)>=S.Config.Locality,'unadmitted actor waited at the exit')
assert(r.wave.count==1,'coroutine re-entry refilled first contact')
-- Even a bad direct waypoint cannot drive the physical body through the boundary.
excess:SetPos(N:CellCenter(H.cell(2))+Vector(0,0,2));excess.LODEntrySuppressed=nil
excess.LODEntryPermitUntil=clock+100;excess.LODMotionLastUpdate=clock
local destination=N:CellCenter(H.cell(0))+Vector(0,0,2)
for i=1,200 do clock=clock+.05;H.time(clock);M:MoveToward(excess,{pos=destination}) end
assert(not S:Protected(excess) and S.Stats.movementDenied>0,'Motion V2 missed sanctuary sweep')
R.State.SimulationFrozen=true;local before=excess:GetPos()
S:BeforeAI(excess);assert(excess:GetPos()==before,'safety authority moved frozen actor')
R.State.SimulationFrozen=false
S:Reset();assert(hero.nw.LOD_EntryCells==0 and hero.nw.LOD_EntrySanctuary==false,'cleanup left stale sanctuary HUD')
print('B29_DISPATCH_PASS real Initialize/RunBehaviour/Motion V2; mixed-source nonrefilling first contact; outward withdrawal; swept waypoint rejection; cached path predicate/closed gates; freeze and UI cleanup')
