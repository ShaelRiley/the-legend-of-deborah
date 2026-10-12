-- Full 28-event catalog, real graph/floor builder and RunManager transaction.
-- SQLite/native doubles are the existing accepted event expansion fixture.
local F=dofile('tools/event_expansion_fixture.lua')
local root,Run,Map=F.root,F.Run
local nativeCreate=ents.Create
ents.Create=function(class)
 local e=nativeCreate(class)
 if class=='lod_floor_map' and IsValid(e) then
  function e:SetFloorIndex(n) self.floor=n end
  function e:GetFloorIndex() return self.floor end
 end
 return e
end
dofile(root..'sv_minimap.lua');dofile(root..'sv_floor_maps.lua')
Map=LOD.MinimapServer
net.WriteDouble,net.WriteFloat,net.WriteUInt,net.WriteBool=F.noop,F.noop,F.noop,F.noop
local builds,paths=0,0
for _,level in ipairs({1,20,21}) do
 for seed=1,4 do
  Run.State.Level=level
  local ok,report=Run:BuildCurrentLevel(level*100003+seed*7919)
  assert(ok,report)
  report=Run.State.BuildReport
  local maps=assert(Map:PartyMaps());local g=Run.State.Graph
  assert(maps.mask==0 and report.floorMaps==g.Layers and Run.State.BuildReady)
  local protected=F.D:ProtectedCells(g)
  for sector=1,4 do
   for _,cell in ipairs(LOD.LootDirector:_SectorCandidates(g,sector)) do
    assert(not maps.plan.protectedCells[F.key(cell)],'ordinary loot occupies map access path')
   end
  end
  for z,row in pairs(maps.plan.maps) do
   paths=paths+1
   assert(IsValid(row.entity) and row.entity:GetFloorIndex()==z)
   for _,k in ipairs(row.path) do assert(protected[k]) end
   for _,instance in ipairs(g.EventPlan.instances) do
    local p=instance.placement
    for _,k in ipairs(row.path) do
     assert(instance.cellKey~=k and p.destinationCellKey~=k and p.cacheCellKey~=k,'event occupies map access')
     assert(not (p.blockedCells and p.blockedCells[k]),'hazard strands map')
    end
    if p.edgeKey then
     local e=g.Edges[p.edgeKey]
     assert(not maps.plan.protectedCells[F.key(e.a)] and not maps.plan.protectedCells[F.key(e.b)],'blockade cuts first-entry map route')
    end
   end
  end
  assert(g.EventPlan.selectedCount>=1 and g.EventPlan.selectedCount<=4,'map suppressed authored event count')
  builds=builds+1
 end
end
print('FLOOR_MAPS_INTEGRATION_PASS: '..builds..' full builds / '..paths..' reserved floor paths; 28-event catalog and real SQLite; unchanged 1d4 counts; native-boundary floors and maps; Dungeons 1/20/21')
