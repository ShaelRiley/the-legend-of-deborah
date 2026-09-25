-- Eight-entry catalog through actual RunManager, encounter reservations and native event creation.
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
for _,name in ipairs({'locked_chest','treasure_chest','vending_machine','false_floor','warp_hole','skeleton_blockade'}) do
 dofile(root..'sv_event_'..name..'.lua')
end
local S,definition=LOD.EventSkeletonBlockade,R.Definitions.skeleton_blockade
assert(S and definition and definition.contract=='BLOCKADE' and definition.production)
assert(#R:Catalog()==7) -- established catalog, before this checkpoint's registration
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

-- The shared quiz event uses actual native methods. Only their Source boundary
-- is doubled; no test-only production methods are supplied.
local nativeCreate=ents.Create
ents.Create=function(class)
 local entity=nativeCreate(class)
 if IsValid(entity) then
  function entity:SetModel(model) self.model=model end
  function entity:GetModel() return self.model end
 end
 return entity
end
dofile(root..'sv_crypto_director.lua')
LOD.CryptoDirector.Sync=F.noop
dofile(root..'sv_event_equipment_quiz.lua')
local Q=assert(LOD.EventEquipmentQuiz)
assert(#R:Catalog()==8 and #R:Catalog(1)==7 and #R:Catalog(5)==8)
assert(not R.Definitions.bribe_blockade and not LOD.EventBribeBlockade)
-- Tie the fixture's catalog to the actual boot includes, including dormant-code
-- boundaries. Explicitly dofile-ing a retired module is not production startup.
local function read(path) local f=assert(io.open(path));local text=f:read('*a');f:close();return text end
local boot=read('gamemodes/legend_of_deborah/gamemode/init.lua')
local client=read('gamemodes/legend_of_deborah/gamemode/cl_init.lua')
local bootCount=0
for id in boot:gmatch('include%("lod/sv_event_([%w_]+)%.lua"%)') do
 if id~='director' then assert(R.Definitions[id],'Active boot/catalog drift: '..id);bootCount=bootCount+1 end
end
assert(bootCount==#R:Catalog())
assert(not boot:find('cl_event_bribe_payment.lua',1,true))
assert(not client:find('cl_event_bribe_payment.lua',1,true))
assert(not F.receivers.LOD_BribeDecision,'Retired payment receiver is live')

assert(Q.optionalAlcove and Q.contract=='REWARD' and Q.nonblocking and Q.production)
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
 local quiz
 for _,i in ipairs(plan.instances) do
  local p=i.placement
  local resources={[i.cellKey]=true}
  for _,k in pairs({p.destinationCellKey,p.cacheCellKey,p.approachCellKey}) do resources[k]=true end
  if p.edgeKey then
   local e=g.Edges[p.edgeKey];resources[key(e.a)],resources[key(e.b)],resources[p.edgeKey]=true,true,true
  end
  for k in pairs(resources) do
   assert(not occupied[k],'Event resources overlap');occupied[k]=true
   if g.Cells[k] then assert(not D:ProtectedCells(g)[k],'Encounter/progression reservation stolen') end
  end
  for k in pairs(p.blockedEdges or {}) do hazardEdges[k]=true end
  for k in pairs(p.blockedCells or {}) do hazardCells[k]=true end
  if i.contract=='BLOCKADE' then blockades[#blockades+1]=i end
  assert(D:ValidatePlacement(g,R.Definitions[i.archetype],p))
  assert(i.state=='active' and D:IsCurrent(i) and IsValid(i.entities[1]))
  if i.archetype==Q.id then
   quiz=i
   assert(#i.entities==1 and i.entities[1].LODEventInstance==i)
   assert(i.entities[1]:GetClass()=='lod_dungeon_event' and i.entities[1]:GetModel()=='models/monk.mdl')
   assert(i.entities[1]:GetPos():DistToSqr(LOD.MazeBuilder:CellCenter(i.cell))<128*128)
   assert(count(g.Cells[p.cellKey].neighbors)==1 and g.Cells[p.cellKey].neighbors[p.approachCellKey])
   assert(LOD.SafeTeleport:FlatCell(g,i.cell) and LOD.SafeTeleport:FlatCell(g,g.Cells[p.approachCellKey]))
   for _,c in ipairs(g.CriticalPath) do assert(key(c)~=p.cellKey,'Quiz occupies mandatory route') end
  end
 end
 assert(D:ValidateRoutes(g,hazardEdges,hazardCells))
 -- Replay legitimate blockade resolutions before normal ordered gates. Record
 -- an approachable quiz before the jail opens, rather than merely graph membership.
 local p,blocked=g.Progression,table.Copy(hazardEdges)
 for _,i in ipairs(blockades) do blocked[i.placement.edgeKey]=true end
 for _,gate in ipairs(p.Gates) do blocked[gate.edgeKey]=true end
 blocked[p.JailEdge.edgeKey]=true
 if p.Warden and p.Warden.lock then blocked[p.Warden.lock.edgeKey]=true end
 local settled,visitedQuiz={},false
 local function advance()
  for _=1,#blockades+1 do
   local reach,changed=walk(g,key(g.Start),blocked,hazardCells),false
   if quiz and reach[quiz.cellKey] then
    assert(reach[quiz.placement.approachCellKey]);visitedQuiz=true
   end
   for _,i in ipairs(blockades) do
    if not settled[i] and reach[i.cellKey] then
     assert(i.archetype=='skeleton_blockade','Removed blockade entered production')
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
  assert(not objective or reach[key(objective)])
  assert(reach[key(gate.beforeCell)] and not reach[key(gate.afterCell)],'Ordered gate bypass')
  blocked[gate.edgeKey]=hazardEdges[gate.edgeKey]
 end
 local reach=advance()
 assert(reach[key(p.CoreCell)] and not reach[key(p.DeborahCell)],'Boss/jail order changed')
 assert(not quiz or visitedQuiz,'Quiz inaccessible during legitimate progression')
 blocked[p.JailEdge.edgeKey]=hazardEdges[p.JailEdge.edgeKey]
 assert(advance()[key(p.DeborahCell)],'Rescue unreachable')
 return quiz
end
local function build(seed,preview)
 if preview then D.NextPreview=Q.id end
 local selected,n=R:Select(seed,Run.State.Level)
 local from=#F.created+1
 local ok,reason=Run:BuildCurrentLevel(seed)
 if not ok then
  assert(tostring(reason):find('event placement exhausted:',1,true) or tostring(reason):find('combined event contract rejected:',1,true),tostring(reason))
  assert(not D.Context and not Run.State.BuildReady and Run.State.LevelSeed==seed)
  for j=from,#F.created do assert(not IsValid(F.created[j]),'Rejected build leaked resource') end
  local after,m=R:Select(seed,Run.State.Level)
  assert(n==m and table.concat(after,',')==table.concat(selected,','),'Rejected build rerolled event count/types')
  return nil
 end
 local g,plan=Run.State.Graph,D.Context.plan
 assert(F.G:Validate(g) and LOD.GraphIntegrity:Audit(g).valid and g.Progression.Validation.valid)
 local i=prove(g,plan)
 if not preview then
  local actual={};for _,v in ipairs(plan.instances) do actual[v.archetype]=true end
  assert(plan.selectedCount==n and count(actual)==n)
  for _,id in ipairs(selected) do assert(actual[id],'Selected event silently dropped') end
 end
 return plan,i
end
Run.State.Level=5
local seen,counts,partners={}, {}, {}
local accepted,rejected,lastSeed,lastPlan,lastQuiz=0,0
for seed=1,192 do
 local selected,n=R:Select(seed,5)
 assert(n==LOD.RNG.New(LOD.Seeds.Derive(seed,'dungeon-events:count:v1')):Int(1,4))
 local chosen={};for _,id in ipairs(selected) do assert(not chosen[id]);chosen[id]=true;seen[id]=true end
 assert((chosen.treasure_chest==true)==(n==4))
 if chosen[Q.id] then
  local needed=not counts[n] or accepted<8
  for id in pairs(chosen) do if not partners[id] then needed=true end end
  if needed then
   local plan,i=build(seed)
   if plan then
    assert(i);accepted=accepted+1;counts[n]=true
    for _,v in ipairs(plan.instances) do partners[v.archetype]=true end
    lastSeed,lastPlan,lastQuiz=seed,plan,i
   else rejected=rejected+1 end
  end
 end
 if accepted>=8 and count(counts)==4 and count(partners)==8 then break end
end
assert(count(seen)==8 and accepted>=8 and count(counts)==4 and count(partners)==8,'Missing actual combined catalog/quiz coverage')
local sig,graphSig=signature(lastPlan),F.graphSignature(Run.State.Graph)
local oldEntities={};for _,i in ipairs(lastPlan.instances) do for _,e in ipairs(i.entities) do oldEntities[#oldEntities+1]=e end end
local plan,i=build(lastSeed);assert(signature(plan)==sig and F.graphSignature(Run.State.Graph)==graphSig)
for _,e in ipairs(oldEntities) do assert(not IsValid(e)) end
assert(not D:IsCurrent(lastQuiz))
local g,p=Run.State.Graph,i.placement
for _,k in ipairs({p.cellKey,p.approachCellKey}) do
 assert(not D:ValidatePlacement(g,Q,p,{[k]=true}),'Alcove reservation ignored')
 local reserved=table.Copy(g);reserved.EncounterPlan={encounters={{cellKey=k}}}
 assert(not D:ValidatePlacement(reserved,Q,p),'Encounter reservation ignored')
 assert(not D:ValidatePlacement(g,Q,p,nil,{cells={[k]=true},edges={}}),'Blocked quiz or mouth accepted')
end
local wrong=table.Copy(p);wrong.approachCellKey=p.cellKey
assert(not D:ValidatePlacement(g,Q,wrong),'Fake alcove mouth accepted')
local isolated={[edge(p.cellKey,p.approachCellKey)]=true}
assert(not D:ValidatePlacement(g,Q,p,nil,{edges=isolated,cells={}}),'Disconnected quiz accepted')
-- Selection remains exact on exhaustion; the complete dungeon is rejected.
local place,attempts=Q.Place,0
Q.Place=function() attempts=attempts+1;return {cellKey='missing'} end
local ok,reason=D:Plan(g,{preview=Q.id})
Q.Place=place
assert(not ok and attempts>0 and attempts<=D.MaxPlacementAttempts and reason:find('equipment_quiz',1,true))
assert(F.graphSignature(g)==graphSig)
-- Track before fallible native initialization; no half-published actor survives.
local create,from=Q.Create,#F.created+1
Q.Create=function(...) create(...);return nil,'injected after native creation' end
D.NextPreview=Q.id
assert(not Run:BuildCurrentLevel(lastSeed) and not D.Context and not Run.State.BuildReady)
Q.Create=create
for j=from,#F.created do assert(not IsValid(F.created[j])) end
local native=ents.Create
from=#F.created+1
ents.Create=function(class) if class=='lod_dungeon_event' then return nil end;return native(class) end
D.NextPreview=Q.id
assert(not Run:BuildCurrentLevel(lastSeed) and not D.Context and not Run.State.BuildReady)
ents.Create=native
for j=from,#F.created do assert(not IsValid(F.created[j])) end
from=#F.created+1
ents.Create=function(class)
 local entity=native(class)
 if class=='lod_dungeon_event' and IsValid(entity) then
  local spawn=entity.Spawn
  function entity:Spawn() spawn(self);error('injected native initialization failure') end
 end
 return entity
end
D.NextPreview=Q.id
assert(not Run:BuildCurrentLevel(lastSeed) and not D.Context and not Run.State.BuildReady)
ents.Create=native
for j=from,#F.created do assert(not IsValid(F.created[j]),'Native initialization ran before ownership tracking') end
plan,i=build(lastSeed);assert(signature(plan)==sig)
-- Exact actor identity is kept in native ownership and late-join snapshots.
local fresh=F.actor('76561198355667788')
local found
for _,row in ipairs(D:Snapshot(fresh).events) do
 if row.id==i.id then found=row;assert(row.archetype==Q.id and row.entityIndex==i.entities[1]:EntIndex()) end
end
assert(found and found.state=='active' and not found.claimed)
local resources={};for _,member in ipairs(plan.instances) do for _,e in ipairs(member.entities) do resources[#resources+1]=e end end
local previewOK,previewError=D:Plan(Run.State.Graph,{preview='bribe_blockade'})
assert(not previewOK and previewError=='unknown event preview','Removed event still previewable')
D:Cleanup('quiz generation suite complete');LOD.EncounterDirector:Cleanup()
assert(not D.Context and not D:IsCurrent(i) and #D:Snapshot(fresh).events==0)
for _,e in ipairs(resources) do assert(not IsValid(e),'Teardown leaked native event resource') end
print('QUIZ_GENERATION_PASS: eight-entry production catalog; '..accepted..' actual quiz builds / '..rejected..' bounded rejects; real encounter reservations; optional flat alcoves and mouths; independent ordered progression; all catalog partners; exact d4; deterministic retry; native Create failures; late joins; exact teardown')
