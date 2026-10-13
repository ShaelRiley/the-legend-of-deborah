-- Cached production routes must honor the late-installed arena/jail policy.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
ents.FindByClass=function() return {} end
LOD.ProgressionDirector={ResetLevelState=function() end}
dofile(root..'sv_phase_zero_runtime_optimization.lua')
dofile(root..'sv_warden_arena.lua')
local N,R=LOD.MazeNavigator,LOD.RunManager
local cells={};local key=LOD.MazeGenerator.CellKey
local g={Cells={},Progression={Gates={}},Layers=1}
for x=1,5 do local c={x=x,y=1,z=0,neighbors={}};cells[x]=c;g.Cells[key(x,1,0)]=c end
for x=1,4 do cells[x].neighbors[key(x+1,1,0)]=true;cells[x+1].neighbors[key(x,1,0)]=true end
g.Progression.Warden={lock={edgeKey=N:EdgeKey(cells[2],cells[3])}}
g.Progression.JailEdge={edgeKey=N:EdgeKey(cells[4],cells[5])}
R.State={Graph=g,Level=1,GatesOpen={},JailDoorOpen=false,WardenStarted=false}
assert(not N:FindPath(g,cells[1],cells[5]),'cached path bypassed the closed jail')
local old=g.LODPhaseZeroNavCache
R.State.JailDoorOpen=true
assert(#N:FindPath(g,cells[1],cells[5])==5 and g.LODPhaseZeroNavCache~=old,'jail opening did not invalidate immediately')
old=g.LODPhaseZeroNavCache;R.State.WardenStarted=true;R.State.Boss={dead=false}
assert(not N:FindPath(g,cells[1],cells[5]) and g.LODPhaseZeroNavCache~=old,'arena closure reused an open tree')
R.State.Boss.dead=true;assert(#N:FindPath(g,cells[1],cells[5])==5,'boss death did not reopen its entry route')
R.State.Level=20;LOD.Hector={allowed=false,RescueAllowed=function(self) return self.allowed end}
assert(not N:FindPath(g,cells[1],cells[5]),'Hector gate bypassed succession')
LOD.Hector.allowed=true;assert(#N:FindPath(g,cells[1],cells[5])==5,'Hector resolution did not invalidate the cache')
print('NAVIGATION_DOOR_CACHE_PASS: actual include order; closed jail/arena/Hector; same-tick opening/closing/death/succession cache invalidation')
