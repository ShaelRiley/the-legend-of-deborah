-- Production seven-entry catalog, actual RunManager generation and independent
-- graph/payment-access proofs. Native Source geometry/transport use the shared
-- boundaries; these checks do not claim native multiplayer acceptance.
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
for _,name in ipairs({'locked_chest','treasure_chest','vending_machine','false_floor','warp_hole','bribe_blockade'}) do
 dofile(root..'sv_event_'..name..'.lua')
end
local B,definition=LOD.EventBribeBlockade,R.Definitions.bribe_blockade
assert(B and definition and definition.contract=='BLOCKADE' and definition.production and definition.repeatable)
assert(#R:Catalog()==7 and R.PopulationReady and F.convars.lod_events_enabled:GetBool())
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
 for _,i in ipairs(plan.instances) do
  local placement=i.placement
  local cells={i.cellKey,placement.destinationCellKey,placement.cacheCellKey}
  -- Numeric iteration deliberately uses pairs: optional destinations can leave
  -- a hole before the blockade collateral cell.
  for _,k in pairs(cells) do assert(not occupied[k],'Event endpoint overlap');occupied[k]=true end
  for k in pairs(placement.blockedEdges or {}) do hazardEdges[k]=true end
  for k in pairs(placement.blockedCells or {}) do hazardCells[k]=true end
  if i.contract=='BLOCKADE' then blockades[#blockades+1]=i end
  assert(D:ValidatePlacement(g,R.Definitions[i.archetype],placement))
 end
 assert(D:ValidateRoutes(g,hazardEdges,hazardCells),'Opened blockades must preserve full ordered progression')
 for _,i in ipairs(blockades) do
  local p,placement=g.Progression,i.placement
  local blocked=table.Copy(hazardEdges)
  for _,other in ipairs(blockades) do blocked[other.placement.edgeKey]=true end
  for _,gate in ipairs(p.Gates) do blocked[gate.edgeKey]=true end
  blocked[p.JailEdge.edgeKey]=true
  if p.Warden and p.Warden.lock then blocked[p.Warden.lock.edgeKey]=true end
  local e=assert(g.Edges[placement.edgeKey]);assert(e.a.z==e.b.z,'Native blockade must occupy a flat edge')
  local reach
  for stage=0,#p.Gates do
   local visited=walk(g,key(g.Start),blocked,hazardCells)
   if visited[key(e.a)] or visited[key(e.b)] then reach=visited;break end
   local gate=p.Gates[stage+1]
   if gate and not hazardEdges[gate.edgeKey] then blocked[gate.edgeKey]=nil end
  end
  assert(reach and reach[placement.cellKey],'Obstacle approach must be accessible at the earliest stage')
  assert(placement.cacheCellKey~=key(e.a) and placement.cacheCellKey~=key(e.b))
  assert(reach[placement.cacheCellKey],'Payment collateral must be obtainable with EVERY blockade still closed')
  assert(not D:ProtectedCells(g)[placement.cacheCellKey],'Collateral cannot borrow protected objective/reward cells')
  for _,cell in ipairs(g.CriticalPath or {}) do assert(key(cell)~=placement.cacheCellKey) end
  assert(LOD.SafeTeleport:FlatCell(g,g.Cells[placement.cacheCellKey]))
  assert(i.collateral and E:ValidateWearable(i.collateral) and E:Value(i.collateral)>=B.price,'Approachable collateral cannot actually pay the toll')
  assert(B.Owned(D,i) and #i.entities==3,'Native resources must share exact dungeon ownership')
  assert(i.entities[1].LODBribeRole=='terminal' and i.entities[2].LODBribeRole=='cache')
  assert(not i.barrier:GetOpened() and i.barrier:GetSolid()==SOLID_BBOX)
  assert(i.barrier.boundsMax.z>=i.barrier.LODOverheadHeight-LOD.Config.Progression.GateBlockerHeight*.5,'Native barrier leaves a jump-over route')
  assert(not LOD.MazeNavigator:CanTraverse(g,key(e.a),key(e.b)) and not LOD.MazeNavigator:CanTraverse(g,key(e.b),key(e.a)),'Shared navigation ignored the closed native blockade')
  local openGate=LOD.ProgressionDirector.TryOpenGate
  LOD.ProgressionDirector.TryOpenGate=function() error('Bribe barrier delegated to keycard progression') end
  i.barrier:Use(F.a)
  LOD.ProgressionDirector.TryOpenGate=openGate
  local unresolved={[placement.edgeKey]=true}
  assert(not walk(g,key(g.Start),unresolved)[key(p.DeborahCell)],'Blockade must really obstruct the rescue route')
 end
 -- Independently replay the whole combined puzzle: resolve only currently
 -- affordable blockades, then the authored gate objective, core and rescue.
 local p,blocked=g.Progression,table.Copy(hazardEdges)
 for _,i in ipairs(blockades) do blocked[i.placement.edgeKey]=true end
 for _,gate in ipairs(p.Gates) do blocked[gate.edgeKey]=true end
 blocked[p.JailEdge.edgeKey]=true
 local settled={}
 local function advance()
  for _=1,#blockades+1 do
   local reach=walk(g,key(g.Start),blocked,hazardCells)
   local changed=false
   for _,i in ipairs(blockades) do
    if not settled[i] and reach[i.cellKey] then
     assert(reach[i.placement.cacheCellKey],'Combined progression demanded inaccessible payment')
     settled[i]=true;blocked[i.placement.edgeKey]=hazardEdges[i.placement.edgeKey];changed=true
    end
   end
   if not changed then return reach end
  end
  error('Combined resolution exceeded finite blockade count')
 end
 for ordinal,gate in ipairs(p.Gates) do
  local reach=advance()
  local objective=p.Keycards and p.Keycards[ordinal] and p.Keycards[ordinal].cell
   or (ordinal==4 and p.Hunt and p.Hunt.neilCell)
  assert(not objective or reach[key(objective)],'Bribe prevented an ordered progression objective')
  assert(reach[key(gate.beforeCell)] and not reach[key(gate.afterCell)],'Combined catalog bypassed a gate')
  blocked[gate.edgeKey]=hazardEdges[gate.edgeKey]
 end
 local reach=advance()
 assert(reach[key(p.CoreCell)] and not reach[key(p.DeborahCell)],'Core/jail order changed')
 blocked[p.JailEdge.edgeKey]=hazardEdges[p.JailEdge.edgeKey]
 assert(advance()[key(p.DeborahCell)],'Combined dungeon has no payable rescue route')
 return blockades[1]
end
local function build(seed,preview)
 if preview then D.NextPreview='bribe_blockade' end
 local built,why=Run:BuildCurrentLevel(seed)
 assert(built,'Production build failed for seed '..seed..': '..tostring(why))
 local g,plan=Run.State.Graph,D.Context.plan
 assert(F.G:Validate(g) and LOD.GraphIntegrity:Audit(g).valid and g.Progression.Validation.valid)
 assert(#F.online==0,'Payment feasibility must not depend on an invented Hero inventory')
 local bribe=prove(g,plan)
 for _,i in ipairs(plan.instances) do assert(i.state=='active' and D:IsCurrent(i) and IsValid(i.entities[1])) end
 if not preview then
  local selected,n=R:Select(g.MasterLevelSeed,Run.State.Level)
  assert(plan.mode=='full' and plan.selectedCount==n and Run.State.BuildReport.eventCount==n)
  local actual={};for _,i in ipairs(plan.instances) do actual[i.archetype]=true end
  assert(count(actual)==n,'A failed candidate silently dropped a selected archetype')
  for _,id in ipairs(selected) do assert(actual[id],'A selected event disappeared') end
 end
 return plan,bribe
end
local allSeen,seeds={},{}
for seed=1,256 do
 local early,n=R:Select(seed,1)
 local later,m=R:Select(seed,5)
 assert(n==m and n==LOD.RNG.New(LOD.Seeds.Derive(seed,'dungeon-events:count:v1')):Int(1,4))
 for _,id in ipairs(early) do assert(id~='warp_hole') end
 local distinct={}
 for ordinal,id in ipairs(later) do
  assert(not distinct[id]);distinct[id]=true;allSeen[id]=true
  assert(id~='treasure_chest' or ordinal==4)
 end
 assert(#later==m and (distinct.treasure_chest==true)==(m==4))
 if distinct.bribe_blockade then seeds[m]=seeds[m] or seed end
end
assert(count(allSeen)==7)
Run.State.Level=5
local builtSeeds={}
for n=1,4 do
 assert(seeds[n],'Bribe must be selectable at each exact d4 count')
 local plan,bribe=build(seeds[n]);assert(bribe and plan.selectedCount==n)
 builtSeeds[seeds[n]]=true
end
local sampled,rejected=count(builtSeeds),0
for seed=1,128 do
 local selected=R:Select(seed,5);local bribe=false
 for _,id in ipairs(selected) do if id=='bribe_blockade' then bribe=true end end
 if bribe and not builtSeeds[seed] then
  if seed==32 then
   -- This real catalog combination exhausts its finite placement budget. It
   -- must reject the entire dungeon, keeping the selected archetypes/count;
   -- dropping the false floor or borrowing inaccessible payment is forbidden.
   local selectedBefore,nBefore=R:Select(seed,5)
   local createdFrom=#F.created+1
   local built,why=Run:BuildCurrentLevel(seed)
   assert(not built and tostring(why):find('event placement exhausted:',1,true),'Known incompatible layout must fail its bounded proof')
   assert(not D.Context and not Run.State.BuildReady and Run.State.LevelSeed==seed)
   for index=createdFrom,#F.created do assert(not IsValid(F.created[index]),'Rejected combined build leaked geometry/resources') end
   local selectedAfter,nAfter=R:Select(seed,5)
   assert(nBefore==nAfter and table.concat(selectedBefore,',')==table.concat(selectedAfter,','),'Rejected layout rerolled its selected events')
   rejected=rejected+1
  else local _,instance=build(seed);assert(instance) end
  sampled=sampled+1
 end
 if sampled==12 then break end
end
assert(sampled==12 and rejected==1,'Finite mixed-catalog sample must preserve selected bribes or explicitly reject the whole layout')
local seed=seeds[4]
local plan,instance=build(seed)
local planBefore,graphBefore=signature(plan),F.graphSignature(Run.State.Graph)
local oldEntities={};for _,i in ipairs(plan.instances) do for _,e in ipairs(i.entities) do oldEntities[#oldEntities+1]=e end end
plan,instance=build(seed)
assert(signature(plan)==planBefore and F.graphSignature(Run.State.Graph)==graphBefore,'Generation retry changed deterministic plan')
for _,e in ipairs(oldEntities) do assert(not IsValid(e),'Replacement leaked an owned entity') end
local g,placement=Run.State.Graph,instance.placement
for _,k in ipairs({placement.cellKey,placement.cacheCellKey}) do
 assert(not D:ValidatePlacement(g,definition,placement,{[k]=true}),'Reservation ignored')
 assert(not D:ValidatePlacement(g,definition,placement,nil,{edges={},cells={[k]=true}}),'Combined closed-cell payment failure accepted')
 local reserved=table.Copy(g);reserved.CellTags=reserved.CellTags or {};reserved.CellTags[k]={safe=true}
 assert(not D:ValidatePlacement(reserved,definition,placement),'Safe-area reservation ignored')
 reserved=table.Copy(g);reserved.EncounterPlan={encounters={{cellKey=k}}}
 assert(not D:ValidatePlacement(reserved,definition,placement),'Encounter reservation ignored')
end
for _,k in ipairs({key(g.Goal),key(g.Start),'missing',placement.cellKey}) do
 local invalid=table.Copy(placement);invalid.cacheCellKey=k
 assert(not D:ValidatePlacement(g,definition,invalid),'Inaccessible/protected/missing collateral accepted')
end
local e=g.Edges[placement.edgeKey]
local far=key(e.a)==placement.cellKey and key(e.b) or key(e.a)
local inaccessible=table.Copy(placement);inaccessible.cacheCellKey=far
assert(not D:ValidatePlacement(g,definition,inaccessible),'Payment borrowed from the far side')
local originalPlace=definition.Place
local attempts=0
definition.Place=function() attempts=attempts+1;return {cellKey='missing'} end
assert(not D:Plan(g,{preview='bribe_blockade'}) and attempts>0 and attempts<=D.MaxPlacementAttempts,'Rejected candidates must use a finite nonzero budget')
definition.Place=originalPlace
assert(F.graphSignature(g)==graphBefore,'Rejected payment proof altered topology')
-- Force failure after the real creator has allocated all native resources.
-- Activation must tear down earlier catalog members and the partial blockade.
local originalCreate=definition.Create
local createdFrom=#F.created+1
definition.Create=function(...) originalCreate(...);return nil,'injected post-creation failure' end
D.NextPreview='bribe_blockade'
assert(not Run:BuildCurrentLevel(seed) and not D.Context and not Run.State.BuildReady)
for index=createdFrom,#F.created do assert(not IsValid(F.created[index]),'Partial native creation leaked a resource') end
definition.Create=originalCreate
local create=ents.Create
for _,role in ipairs({'cache','barrier'}) do
 local events=0
 createdFrom=#F.created+1
 ents.Create=function(class)
  if class=='lod_dungeon_event' then events=events+1 end
  if (role=='cache' and class=='lod_dungeon_event' and events==2)
   or (role=='barrier' and class=='lod_gate') then return nil end
  return create(class)
 end
 D.NextPreview='bribe_blockade'
 assert(not Run:BuildCurrentLevel(seed) and not D.Context and not Run.State.BuildReady,'Partial '..role..' failure published a dungeon')
 for index=createdFrom,#F.created do assert(not IsValid(F.created[index]),'Partial '..role..' creation leaked a resource') end
 ents.Create=create
end
local retried,replacement=build(seed)
assert(replacement and signature(retried)==planBefore,'Creation retry rerolled away a selected event')
assert(not D:IsCurrent(instance),'Old generation retained ownership')
-- Production later replaces the ordinary navigator with cached BFS. Exercise
-- that actual override and same-tick cache invalidation around shared opening.
ents.FindByClass=function(class)
 local found={}
 for _,entity in ipairs(F.created) do if IsValid(entity) and entity:GetClass()==class then found[#found+1]=entity end end
 return found
end
dofile(root..'sv_phase_zero_runtime_optimization.lua')
local nav,liveGraph=LOD.MazeNavigator,Run.State.Graph
local bridge=liveGraph.Edges[replacement.placement.edgeKey]
assert(not nav:CanTraverse(liveGraph,key(bridge.a),key(bridge.b)))
assert(not nav:FindPath(liveGraph,bridge.a,bridge.b))
assert(nav:Distance(liveGraph,bridge.a,bridge.b)==math.huge)
local cache=liveGraph.LODPhaseZeroNavCache
replacement.state='resolved'
assert(nav:CanTraverse(liveGraph,key(bridge.a),key(bridge.b)))
assert(#nav:FindPath(liveGraph,bridge.a,bridge.b)==2 and nav:Distance(liveGraph,bridge.a,bridge.b)==1)
assert(liveGraph.LODPhaseZeroNavCache~=cache,'Shared opening left the optimized cached route closed')
replacement.state='active'
assert(not nav:FindPath(liveGraph,bridge.a,bridge.b) and nav:Distance(liveGraph,bridge.a,bridge.b)==math.huge,'Reset retained a stale open cached route')
local owned={};for _,i in ipairs(retried.instances) do for _,entity in ipairs(i.entities) do owned[#owned+1]=entity end end
D:Cleanup('bribe generation suite complete')
LOD.EncounterDirector:Cleanup()
assert(not D.Context and #D:Snapshot(F.a).events==0)
for _,entity in ipairs(owned) do assert(not IsValid(entity),'Dungeon teardown leaked an owned resource') end
assert(not D:IsCurrent(replacement))
print('BRIBE_GENERATION_PASS: seven production archetypes with actual encounters; exact 1d4; 11 accepted mixed builds + seed32 bounded whole-layout rejection; no party inventory; independent approachable collateral/objective proof; deterministic retry; partial native creation rollback; optimized navigation; stale ownership and cleanup')
