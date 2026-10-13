-- Real maze/progression/arena planning, party policy and pickup authorities.
-- Source entities/transport are explicit native doubles, not native acceptance.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local hooks,receivers,fx,announcements={}, {}, {}, {}
hook={Add=function(event,id,f) hooks[id]=f end,GetTable=function() return {} end}
concommand={Add=noop}
timer={Simple=function(_,f) f() end}
local developer=false
GetConVar=function(name) return {GetBool=function() return name=='lod_developer_mode' and developer end} end
CreateConVar=GetConVar
bit={band=function(a,b) return a&b end,bor=function(a,b) return a|b end,lshift=function(a,b) return a<<b end}
net={Receive=function(n,f) receivers[n]=f end,Start=noop,Send=noop,WriteString=noop}
dofile(root..'sh_rng.lua');dofile(root..'sv_maze_generator.lua');dofile(root..'sv_progression_director.lua')
dofile(root..'sv_neil_brute.lua');dofile(root..'sv_warden_arena.lua')
local Run,Builder=LOD.RunManager,LOD.MazeBuilder
local originals={Build=Builder.Build,Cleanup=Builder.Cleanup}
Builder.Entities={}
function Builder:Build() self.Entities={};return true,{} end
function Builder:Cleanup() for _,e in ipairs(self.Entities) do e:Remove() end;self.Entities={} end
function Builder:_Register(e) self.Entities[#self.Entities+1]=e end
Run._SyncPlayerVars=noop
local online={}
player.GetAll=function() return online end
Run.IsActivePlayer=function(_,p) return p.active==true end
local baseActor=env.actor
local function actor()
 local p=baseActor(1);p.player=true;p.active=true;p.alive=true;p.nw={}
 p.SetNW2Int=p.SetNW2Bool
 function p:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then return d end;return v end
 p.GetNW2Int=p.GetNW2Bool
 function p:NearestPoint(pos) return self:GetPos()+Vector(0,0,36) end
 function p:ChatPrint() end
 online[#online+1]=p;return p
end
local created,failAt={},nil
ents.Create=function(class)
 if failAt and #created+1==failAt then return nil end
 local e=baseActor(1);e.class=class
 function e:SetFloorIndex(n) self.floor=n end
 function e:GetFloorIndex() return self.floor end
 function e:Spawn() end
 created[#created+1]=e;return e
end
dofile(root..'sv_minimap.lua');dofile(root..'sv_floor_maps.lua');dofile(root..'sv_multiplayer_contracts.lua')
local Map=LOD.MinimapServer
local floorBuild=Builder.Build
dofile(root..'sv_floor_maps.lua');assert(Builder.Build==floorBuild,'Lua refresh installed a duplicate map builder')
dofile(root..'sv_event_director.lua')
-- Invoke its actual reservation function without its independent event build.
Builder.Build=floorBuild
LOD.RPGPresentation={SendFX=function(_,p,kind,primary,secondary)
 assert(kind==5 and primary=='Use map with Q' and secondary=='M works too')
 fx[#fx+1]=p
end}
LOD.ProgressionDirector.Announce=function(_,text,fields)
 announcements[#announcements+1]={text=text,fields=fields}
end
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function edge(a,b) return a<b and a..'|'..b or b..'|'..a end
local graphs,floors={},0
for seed=1,48 do
 local graph
 for attempt=1,64 do
  local g=assert(LOD.MazeGenerator:Generate(seed*7919+attempt))
  if LOD.ProgressionDirector:Plan(g,seed*7919) then graph=g;break end
 end
 assert(graph,'bounded production progression planning failed')
 graph.MasterLevelSeed=seed*7919
 local ok,plan=Map:PlanFloorMaps(graph);assert(ok,plan)
 local first={}
 for _,c in ipairs(graph.CriticalPath) do first[c.z]=first[c.z] or key(c) end
 local blocked={}
 for _,gate in ipairs(graph.Progression.Gates) do blocked[gate.edgeKey]=true end
 blocked[graph.Progression.JailEdge.edgeKey]=true
 blocked[graph.Progression.Warden.lock.edgeKey]=true
 local protected=LOD.EventDirector:ProtectedCells(graph)
 for floor=0,graph.Layers-1 do
  floors=floors+1
  local row=assert(plan.maps[floor]);assert(row.cell.z==floor and row.entrance.z==floor)
  assert(row.distance<=6 and #row.path==row.distance+1)
  if first[floor] then assert(key(row.entrance)==first[floor],'not the first floor arrival') end
  assert(row.path[1]==key(row.cell) and row.path[#row.path]==key(row.entrance))
  for i,k in ipairs(row.path) do
   assert(graph.Cells[k].z==floor and protected[k],'unreserved or cross-floor map route')
   if i>1 then
    local prev=row.path[i-1]
    assert(graph.Cells[k].neighbors[prev] and not blocked[edge(k,prev)],'map needs a closed-door unlock')
   end
  end
 end
 -- Replanning is immutable, including independent loot/encounter RNG streams.
 assert(select(2,Map:PlanFloorMaps(graph))==plan)
 local chosen={};for z,row in pairs(plan.maps) do chosen[z]=key(row.cell) end
 graph.FloorMapPlan=nil;assert(Map:PlanFloorMaps(graph))
 for z,row in pairs(graph.FloorMapPlan.maps) do assert(key(row.cell)==chosen[z],'non-deterministic map placement') end
 graphs[#graphs+1]=graph
end
local p,q=actor(),actor()
local g=graphs[1]
local function build(graph,level)
 Run.State={Graph=graph,Level=level or 1,CampaignEpoch=9,LevelSeed=233,BuildReady=false}
 local ok,report=Builder:Build(graph);assert(ok,report)
 Run.State.BuildReady=true
 assert(report.floorMaps==graph.Layers and #Builder.Entities==graph.Layers,'missing required floor pickup')
 for _,member in ipairs(online) do Run:_SyncPlayerVars(member) end
 return Run.State.FloorMaps
end
local maps=build(g)
for _,mode in ipairs({false,true}) do
 developer=mode;Run:_SyncPlayerVars(p)
 assert(maps.mask==0 and not Map:CanUse(p) and not Map:Grant(p),'developer mode bypassed undiscovered floor')
 assert(p.nw.LOD_MapFloorMask==0 and not p.nw.LOD_MapUnlocked,'developer mirror revealed all floors')
end
developer=true -- installed development checkout throughout the remaining lifecycle gate
local row=maps.plan.maps[0]
p:SetPos(row.entity:GetPos()-Vector(0,0,36));q:SetPos(p:GetPos())
p.active=false;assert(not Map:CollectFloorMap(p,row.entity));p.active=true
p.alive=false;assert(not Map:CollectFloorMap(p,row.entity));p.alive=true
p:SetPos(Vector(100000,100000,0));assert(not Map:CollectFloorMap(p,row.entity),'remote forged pickup')
p:SetPos(row.entity:GetPos()-Vector(0,0,36))
local fake=ents.Create('lod_floor_map');fake.floor=0;fake.LODFloorMapState=maps
fake:SetPos(row.entity:GetPos());assert(not Map:CollectFloorMap(p,fake),'unregistered clone awarded floor')
assert(Map:CollectFloorMap(p,row.entity));assert(maps.mask==1 and maps.owned[0])
assert(Map:CanUse(p) and Map:CanUse(q) and p.nw.LOD_MapFloorMask==1 and q.nw.LOD_MapFloorMask==1)
assert(#fx==2 and #announcements==1 and announcements[1].fields.event=='floor_map_acquired')
assert(not Map:CollectFloorMap(q,row.entity) and #fx==2,'duplicate/simultaneous party award')
local late=actor();late:SetPos(p:GetPos());Run:_SyncPlayerVars(late)
assert(Map:CanUse(late) and late.nw.LOD_MapFloorMask==1,'late arrival lost party map')
q.alive=false;Run:_SyncPlayerVars(q);assert(not Map:CanUse(q) and maps.owned[0])
q.alive=true;Run:_SyncPlayerVars(q);assert(Map:CanUse(q),'respawn did not inherit party discovery')
q:SetPos(Vector(q:GetPos().x,q:GetPos().y,LOD.Config.Maze.Origin.z+LOD.Config.Maze.LevelHeight))
assert(not Map:CanUse(q),'one floor map revealed another floor')
-- Real Magic admission must obey discovery even in the installed developer mode.
-- Reject forged open heartbeats and retire a lease as soon as its floor changes.
local drains,pools={},{}
timer.Create=function(id,_,__,fn) drains[id]=fn end
local requestedOpen=true;net.ReadBool=function() return requestedOpen end
LOD.Magic={_EnsureState=function(_,member)
 pools[member]=pools[member] or {magic=100};return pools[member]
end,_Sync=noop}
dofile(root..'sv_minimap_magic.lua')
local magic=LOD.MinimapMagic
env.setTime(100)
receivers.LOD_MapMagicState(0,q)
assert(not magic.Active[q] and not magic:IsOpen(q),'unfound floor admitted a forged Magic open')
q:SetPos(p:GetPos());receivers.LOD_MapMagicState(0,q)
assert(magic:IsOpen(q),'found floor could not open its Magic lease')
local budget=pools[q].magic
q:SetPos(Vector(q:GetPos().x,q:GetPos().y,LOD.Config.Maze.Origin.z+LOD.Config.Maze.LevelHeight))
assert(not magic:IsOpen(q),'floor transition kept map movement admission')
env.setTime(100.1);drains.LOD_MinimapMagicDrain()
assert(not magic.Active[q] and pools[q].magic==budget,'unfound floor retained/drained old lease')
receivers.LOD_MapMagicState(0,q);assert(not magic.Active[q],'new heartbeat bypassed floor discovery')
receivers.LOD_MapMagicState(0,p);assert(magic:IsOpen(p))
env.setTime(100.2);drains.LOD_MinimapMagicDrain();assert(pools[p].magic<100,'found map lost normal Magic cost')
requestedOpen=false;receivers.LOD_MapMagicState(0,p)
local oldEnt=maps.plan.maps[1].entity
local serial=maps.serial
maps=build(g,21)
assert(maps.serial>serial and maps.mask==0 and not Map:CanUse(p),'same graph rebuild carried old ownership')
assert(not Map:CollectFloorMap(p,oldEnt),'old build pickup unlocked new build')
row=maps.plan.maps[0];p:SetPos(row.entity:GetPos()-Vector(0,0,36))
assert(Map:CollectFloorMap(p,row.entity) and Map:CanUse(p),'Cash dungeon map unavailable')
Run.State.CampaignEpoch=10;assert(not Map:PartyMaps() and not Map:CanUse(p),'campaign-stale map state')
-- Native creation failure is a fatal required-entity build failure, never a
-- successfully released floor without its map. All already created maps retire.
failAt=#created+2
Run.State={Graph=graphs[2],Level=1,CampaignEpoch=11,LevelSeed=233,BuildReady=false}
local ok,err=Builder:Build(graphs[2]);assert(not ok and err:find('required floor map creation failed',1,true))
assert(#Builder.Entities==0 and not Map:CanUse(p))
print('FLOOR_MAPS_PASS: '..#graphs..' production layouts / '..floors..' floor paths; all doors closed; event reservations; required spawning/failure cleanup; party touch, duplicate/remote/stale rejection; joins, death/respawn, Cash and reset isolation; developer on/off; real Magic admission/revocation/drain')
