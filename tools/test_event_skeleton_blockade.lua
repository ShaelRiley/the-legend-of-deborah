-- Production eight-entry catalog through actual RunManager and encounter planning.
-- Geometry/transport use native API doubles. Only SkeletonHero:Spawn is isolated:
-- profile/combat/native death have a separate gate; no native acceptance is claimed.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run,realFloors=true})
local root,D,R,Run,E=F.root,F.D,F.R,F.Run,LOD.Equipment
for index=#F.online,1,-1 do table.remove(F.online,index) end
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
dofile(root..'sv_maze_navigator.lua')
dofile(root..'sv_safe_teleport.lua')
local fixtureBuild=LOD.MazeBuilder.Build
dofile(root..'sv_progression_builder.lua')
LOD.MazeBuilder.Build=fixtureBuild
-- Exercise the real gate initialization and tall collision bounds; only engine
-- accessors are doubled, just as for the shared lod_dungeon_event fixture.
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_gate/init.lua')
local gateClass,nativeCreate=ENT,ents.Create
SOLID_BBOX=2
ents.Create=function(class)
 local entity=nativeCreate(class)
 if class=='lod_gate' and IsValid(entity) then
  setmetatable(entity,{__index=gateClass})
  for _,field in ipairs({'GateIndex','GateAxis','Opened','OpenedAt','Solid'}) do
   entity['Set'..field]=function(self,v) self[field]=v end
   entity['Get'..field]=function(self) return self[field] end
  end
  entity.GetNotSolid=nil
  function entity:IsSolid() return self:GetSolid()~=SOLID_NONE and not self.NotSolid end
  function entity:SetCollisionBounds(lo,hi) self.boundsMin,self.boundsMax=lo,hi end
  entity.AddEFlags,entity.CollisionRulesChanged=F.noop,F.noop
  function entity:Spawn() self:Initialize() end
 end
 return entity
end
-- Generation owns the exact actor returned by the shared profile/spawn authority.
-- The separate actor suite executes that authority; this boundary isolates graph proofs.
LOD.SkeletonHero={Spawn=function(_,director,i,g)
 local actor=ents.Create('lod_hostile')
 if not IsValid(actor) then return nil end
 if not director:Track(i,actor) then actor:Remove();return nil end
 i.hostile=actor;actor.LODHostile=true;actor.LODSkeletonHero=true;actor.hp=100
 function actor:Health() return self.hp end
 actor:SetPos(LOD.MazeBuilder:CellCenter(g.Cells[i.cellKey]));actor:Spawn();actor:Activate()
 return actor
end}
for _,name in ipairs({'locked_chest','treasure_chest','vending_machine','false_floor','warp_hole','bribe_blockade','skeleton_blockade'}) do
 dofile(root..'sv_event_'..name..'.lua')
end
local B,S,definition=LOD.EventBribeBlockade,LOD.EventSkeletonBlockade,R.Definitions.skeleton_blockade
assert(S and definition and definition.contract=='BLOCKADE' and definition.production)
assert(#R:Catalog()==8 and R.PopulationReady and F.convars.lod_events_enabled:GetBool())
-- Reuse the accepted actual encounter planning seam. Geometry is already
-- built by the fixture when EventDirector requests a plan; the real m3 wrapper
-- installs LOS policy and reserves enemy/safe cells before event placement.
dofile(root..'sv_encounter_director.lua')
LOD.CombatRolls.HostileDamageProfiles=LOD.CombatRolls.HostileDamageProfiles or {}
LOD.WanderingDirector=LOD.WanderingDirector or {Config={ArchetypeWeights={}}}
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_roster_placement.lua')
Run._ActiveCount=function() return 2 end
util.TraceLine=function(t)
 local distance=math.sqrt((t.endpos-t.start):LengthSqr())
 local fraction=distance>320 and 320/distance or 1
 return {Hit=fraction<1,Fraction=fraction,StartSolid=false,HitPos=t.start+(t.endpos-t.start)*fraction}
end
local eventBuild,originalPlan=LOD.MazeBuilder.Build,D.Plan
LOD.MazeBuilder.Build=function() return true,{} end
dofile(root..'sv_m3_run_integration.lua')
local encounterBuild=LOD.MazeBuilder.Build
LOD.MazeBuilder.Build=eventBuild
D.Plan=function(self,g,options)
 assert(encounterBuild(LOD.MazeBuilder,g))
 local before=WalletJSONEncode({tags=g.CellTags,encounters=g.EncounterPlan})
 assert(#g.EncounterPlan.encounters>3,'Production encounter reservations missing')
 local accepted,result=originalPlan(self,g,options)
 assert(before==WalletJSONEncode({tags=g.CellTags,encounters=g.EncounterPlan}),'Event planning changed encounter reservations')
 return accepted,result
end
local function key(c) return F.G.CellKey(c.x,c.y,c.z) end
local function edge(a,b) return a<b and a..'|'..b or b..'|'..a end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function walk(g,start,blocked,cells)
 local seen,queue={},{}
 if g.Cells[start] and not (cells and cells[start]) then seen[start]=true;queue[1]=start end
 local at=1
 while queue[at] do
  local k=queue[at];at=at+1
  for n in pairs(g.Cells[k].neighbors) do
   if not seen[n] and not blocked[edge(k,n)] and not (cells and cells[n]) then seen[n]=true;queue[#queue+1]=n end
  end
 end
 return seen
end
local function signature(plan)
 local rows={tostring(plan.selectedCount)}
 for _,i in ipairs(plan.instances) do rows[#rows+1]=i.id..'/'..WalletJSONEncode(i.placement)..'/'..i.seed end
 return table.concat(rows,';')
end
local function prove(g,plan)
 local occupied,blockades,hazardEdges,hazardCells={},{},{},{}
 local skeleton
 for _,i in ipairs(plan.instances) do
  local p=i.placement
  for _,k in pairs({i.cellKey,p.destinationCellKey,p.cacheCellKey}) do
   assert(not occupied[k],'Event endpoint overlap');occupied[k]=true
  end
  for k in pairs(p.blockedEdges or {}) do hazardEdges[k]=true end
  for k in pairs(p.blockedCells or {}) do hazardCells[k]=true end
  if i.contract=='BLOCKADE' then blockades[#blockades+1]=i end
  assert(D:ValidatePlacement(g,R.Definitions[i.archetype],p))
 end
 assert(D:ValidateRoutes(g,hazardEdges,hazardCells),'Opened blockades changed ordered progression')
 local p,blocked=g.Progression,table.Copy(hazardEdges)
 for _,i in ipairs(blockades) do blocked[i.placement.edgeKey]=true end
 for _,gate in ipairs(p.Gates) do blocked[gate.edgeKey]=true end
 blocked[p.JailEdge.edgeKey]=true
 if p.Warden and p.Warden.lock then blocked[p.Warden.lock.edgeKey]=true end
 for _,i in ipairs(blockades) do
  local e=assert(g.Edges[i.placement.edgeKey]);assert(e.a.z==e.b.z)
  local probe=table.Copy(blocked)
  local reach
  for stage=0,#p.Gates do
   local visited=walk(g,key(g.Start),probe,hazardCells)
   if visited[key(e.a)] or visited[key(e.b)] then reach=visited;break end
   local gate=p.Gates[stage+1]
   if gate then
    local objective=p.Keycards and p.Keycards[stage+1] and p.Keycards[stage+1].cell
      or (stage+1==4 and p.Hunt and p.Hunt.neilCell)
    assert(visited[key(gate.beforeCell)] and (not objective or visited[key(objective)]),'Earlier objective inaccessible')
    probe[gate.edgeKey]=hazardEdges[gate.edgeKey]
   end
  end
  assert(reach and reach[i.cellKey],'Combat/payment endpoint inaccessible with all blockades closed')
  assert(not walk(g,key(g.Start),{[i.placement.edgeKey]=true})[key(p.DeborahCell)],'Blockade not on required route')
  if i.archetype==S.id then
   skeleton=i
   assert(S.Owned(D,i) and #i.entities==2 and i.entities[1]==i.hostile and i.entities[2]==i.barrier)
   assert(i.hostile.LODEventInstance==i and i.hostile:GetClass()=='lod_hostile')
   assert(i.hostile:GetPos():DistToSqr(LOD.MazeBuilder:CellCenter(i.cell))<128*128,'Hostile spawned beyond accessible approach')
   assert(not i.barrier:GetOpened() and i.barrier:IsSolid())
   assert(i.barrier.boundsMax.z>=i.barrier.LODOverheadHeight-LOD.Config.Progression.GateBlockerHeight*.5,'Blockade leaves jump-over route')
  else
   assert(i.archetype==B.id and reach[i.placement.cacheCellKey],'Bribe payment inaccessible in mixed catalog')
   assert(i.collateral and E:ValidateWearable(i.collateral) and E:Value(i.collateral)>=B.price)
  end
  assert(not LOD.MazeNavigator:CanTraverse(g,key(e.a),key(e.b)))
 end
 -- Independently replay only reachable resolutions before each canonical gate.
 local settled={}
 local function advance()
  for _=1,#blockades+1 do
   local reach,changed=walk(g,key(g.Start),blocked,hazardCells),false
   for _,i in ipairs(blockades) do
    if not settled[i] and reach[i.cellKey] then
     assert(i.archetype==S.id or reach[i.placement.cacheCellKey],'Circular prerequisite')
     settled[i]=true;blocked[i.placement.edgeKey]=hazardEdges[i.placement.edgeKey];changed=true
    end
   end
   if not changed then return reach end
  end
  error('Finite blockade resolution exceeded')
 end
 for ordinal,gate in ipairs(p.Gates) do
  local reach=advance()
  local objective=p.Keycards and p.Keycards[ordinal] and p.Keycards[ordinal].cell or (ordinal==4 and p.Hunt and p.Hunt.neilCell)
  assert(not objective or reach[key(objective)],'Mixed events stranded a key/Hunt objective')
  assert(reach[key(gate.beforeCell)] and not reach[key(gate.afterCell)],'Mixed events bypassed canonical gate')
  blocked[gate.edgeKey]=hazardEdges[gate.edgeKey]
 end
 local reach=advance()
 assert(reach[key(p.CoreCell)] and not reach[key(p.DeborahCell)],'Core/jail order changed')
 blocked[p.JailEdge.edgeKey]=hazardEdges[p.JailEdge.edgeKey]
 assert(advance()[key(p.DeborahCell)],'No solvable rescue route')
 return skeleton
end
local function build(seed,preview)
 if preview then D.NextPreview=S.id end
 local selected,n=R:Select(seed,Run.State.Level)
 local createdFrom=#F.created+1
 local built,why=Run:BuildCurrentLevel(seed)
 if not built then
  assert(tostring(why):find('event placement exhausted:',1,true) or tostring(why):find('combined event contract rejected:',1,true),tostring(why))
  assert(not D.Context and not Run.State.BuildReady and Run.State.LevelSeed==seed)
  for index=createdFrom,#F.created do assert(not IsValid(F.created[index]),'Rejected build leaked native resource') end
  local after,m=R:Select(seed,Run.State.Level)
  assert(n==m and table.concat(selected,',')==table.concat(after,','),'Rejection rerolled selected events')
  return nil
 end
 local g,plan=Run.State.Graph,D.Context.plan
 assert(F.G:Validate(g) and LOD.GraphIntegrity:Audit(g).valid and g.Progression.Validation.valid)
 local i=prove(g,plan)
 if not preview then
  local actual={};for _,v in ipairs(plan.instances) do actual[v.archetype]=true end
  assert(plan.selectedCount==n and Run.State.BuildReport.eventCount==n and count(actual)==n)
  for _,id in ipairs(selected) do assert(actual[id],'Selected event silently dropped') end
 end
 return plan,i
end
Run.State.Level=5
local seen,counts,seeds={}, {}, {}
for seed=1,256 do
 local selected,n=R:Select(seed,5)
 assert(n==LOD.RNG.New(LOD.Seeds.Derive(seed,'dungeon-events:count:v1')):Int(1,4))
 local distinct={}
 for ordinal,id in ipairs(selected) do
  assert(not distinct[id]);distinct[id]=true;seen[id]=true
  assert(id~='treasure_chest' or ordinal==4)
 end
 assert(#selected==n and (distinct.treasure_chest==true)==(n==4))
 if distinct[S.id] then seeds[#seeds+1]={seed=seed,n=n,mixed=distinct[B.id]} end
end
assert(count(seen)==8)
local accepted,rejected,mixed,lastSeed,lastPlan,lastInstance=0,0,0
for _,case in ipairs(seeds) do
 if accepted<10 or not counts[case.n] or mixed==0 then
  if case.mixed then mixed=mixed+1 end
  local plan,i=build(case.seed)
  if case.mixed then assert(not plan,'Two mandatory cuts cannot satisfy the conservative all-closed proof') end
  if plan then
   assert(i,'Selected Skeleton missing');accepted=accepted+1;counts[case.n]=true
   lastSeed,lastPlan,lastInstance=case.seed,plan,i
  else rejected=rejected+1 end
 end
 if accepted>=10 and count(counts)==4 and mixed>0 then break end
end
assert(accepted>=10 and count(counts)==4 and mixed>0 and rejected>0,'Finite production sample missing count or selected co-blockade coverage')
local planBefore,graphBefore=signature(lastPlan),F.graphSignature(Run.State.Graph)
local oldEntities={};for _,i in ipairs(lastPlan.instances) do for _,e in ipairs(i.entities) do oldEntities[#oldEntities+1]=e end end
local plan,instance=build(lastSeed)
assert(plan and signature(plan)==planBefore and F.graphSignature(Run.State.Graph)==graphBefore,'Retry altered deterministic plan')
for _,e in ipairs(oldEntities) do assert(not IsValid(e),'Replacement leaked owned resource') end
assert(not D:IsCurrent(lastInstance))
local g,p=Run.State.Graph,instance.placement
for _,k in ipairs({p.cellKey,p.edgeKey}) do
 assert(not D:ValidatePlacement(g,definition,p,{[k]=true}),'Reservation ignored')
end
assert(not D:ValidatePlacement(g,definition,p,nil,{edges={},cells={[p.cellKey]=true}}),'Blocked hostile approach accepted')
local reserved=table.Copy(g);reserved.CellTags=reserved.CellTags or {};reserved.CellTags[p.cellKey]={safe=true}
assert(not D:ValidatePlacement(reserved,definition,p),'Safe reservation ignored')
reserved=table.Copy(g);reserved.EncounterPlan={encounters={{cellKey=p.cellKey}}}
assert(not D:ValidatePlacement(reserved,definition,p),'Encounter reservation ignored')
local e=g.Edges[p.edgeKey]
local far=key(e.a)==p.cellKey and key(e.b) or key(e.a)
local wrong=table.Copy(p);wrong.cellKey=far
assert(not D:ValidatePlacement(g,definition,wrong),'Enemy behind its own barrier accepted')
local originalPlace,attempts=definition.Place,0
definition.Place=function() attempts=attempts+1;return {cellKey='missing'} end
assert(not D:Plan(g,{preview=S.id}) and attempts>0 and attempts<=D.MaxPlacementAttempts,'Candidate rejection not bounded')
definition.Place=originalPlace
assert(F.graphSignature(g)==graphBefore,'Failed proof changed topology')
-- Every allocated resource is tracked before any fallible later creation.
local originalCreate=definition.Create
local from=#F.created+1
definition.Create=function(...) originalCreate(...);return nil,'injected post-create failure' end
D.NextPreview=S.id
assert(not Run:BuildCurrentLevel(lastSeed) and not D.Context and not Run.State.BuildReady)
for n=from,#F.created do assert(not IsValid(F.created[n]),'Post-create failure leaked') end
definition.Create=originalCreate
local nativeCreate=ents.Create
for _,class in ipairs({'lod_hostile','lod_gate'}) do
 from=#F.created+1
 ents.Create=function(name) if name==class then return nil end;return nativeCreate(name) end
 D.NextPreview=S.id
 assert(not Run:BuildCurrentLevel(lastSeed) and not D.Context and not Run.State.BuildReady,'Partial creation published dungeon')
 for n=from,#F.created do assert(not IsValid(F.created[n]),'Partial '..class..' failure leaked resource') end
 ents.Create=nativeCreate
end
-- A still-valid actor that dies during barrier activation must never publish a
-- living blockade. Exercise the production final check after both resources exist.
from=#F.created+1
local depletedActor
ents.Create=function(name)
 local entity=nativeCreate(name)
 if name=='lod_hostile' then depletedActor=entity end
 if name=='lod_gate' and IsValid(entity) then
  local activate=entity.Activate
  function entity:Activate(...)
   activate(self,...)
   if depletedActor then depletedActor.hp=0 end
  end
 end
 return entity
end
D.NextPreview=S.id
assert(not Run:BuildCurrentLevel(lastSeed) and not D.Context and not Run.State.BuildReady,'Valid zero-HP hostile published an orphan blockade')
for n=from,#F.created do assert(not IsValid(F.created[n]),'Zero-HP partial creation leaked resource') end
ents.Create=nativeCreate
plan,instance=build(lastSeed);assert(plan and signature(plan)==planBefore)
-- Late joins use shared event state; topology refresh is driven by RouteSignature.
local function snapshotState()
 for _,row in ipairs(D:Snapshot(F.a).events) do if row.id==instance.id then return row.state end end
end
assert(snapshotState()=='active')
ents.FindByClass=function(class)
 local found={};for _,entity in ipairs(F.created) do if IsValid(entity) and entity:GetClass()==class then found[#found+1]=entity end end;return found
end
dofile(root..'sv_phase_zero_runtime_optimization.lua')
local nav,graph=LOD.MazeNavigator,Run.State.Graph
local bridge=graph.Edges[instance.placement.edgeKey]
assert(not nav:FindPath(graph,bridge.a,bridge.b) and nav:Distance(graph,bridge.a,bridge.b)==math.huge)
local cache=graph.LODPhaseZeroNavCache
assert(D:Resolve(instance))
assert(snapshotState()=='resolved' and not D:Resolve(instance),'Shared resolution not idempotent')
assert(nav:CanTraverse(graph,key(bridge.a),key(bridge.b)) and #nav:FindPath(graph,bridge.a,bridge.b)==2)
assert(nav:Distance(graph,bridge.a,bridge.b)==1 and graph.LODPhaseZeroNavCache~=cache,'Same-tick optimized cache stale')
local owned={};for _,i in ipairs(plan.instances) do for _,entity in ipairs(i.entities) do owned[#owned+1]=entity end end
D:Cleanup('Skeleton generation suite complete');LOD.EncounterDirector:Cleanup()
assert(not D.Context and not D:IsCurrent(instance) and #D:Snapshot(F.a).events==0)
for _,entity in ipairs(owned) do assert(not IsValid(entity),'Teardown leaked resource') end
print('SKELETON_GENERATION_PASS: eight real production archetypes; actual encounter reservations; exact d4; '..accepted..' accepted mixed builds / '..rejected..' bounded rejects; independent combat/payment/objective reachability; deterministic retry; partial creation rollback; late joins; shared navigation cache; exact cleanup')
