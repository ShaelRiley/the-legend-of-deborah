-- Exact planned homes remain available to their dormant encounter squads.
-- Exercise the production candidate scan and native-boundary spawn service;
-- retain B23's real placement, population, lifecycle and patrol regressions.
local T=dofile('tools/test_bestiary_b23.lua')
local H,W=T.H,T.W
local D,Run=H.D,H.Run
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function reservations(plan)
 local out={}
 for _,enc in ipairs(plan and plan.encounters or {}) do out[enc.cellKey]=true end
 return out
end
local function noOverlap(graph)
 local reserved=reservations(graph.EncounterPlan)
 for _,e in ipairs(W.Entities) do
  if IsValid(e) and not e.LODDead then
   assert(not reserved[e.LODHomeCellKey],'roamer admitted at a planned encounter home')
  end
 end
end
local function candidates(graph,floor)
 local out={}
 for _,c in ipairs(W:_SpawnCandidates(graph,floor,LOD.RNG.New(240024))) do out[key(c)]=c end
 return out
end

-- An actual plan, including dormant discretionary encounters, protects both
-- initial population and replacements while leaving legal population available.
local graph,plan=T.prepare(191919,8)
assert(D:CommitEcologyPlan(graph))
local receipt=H.serial(Run.State.EncounterEcology)
local signature=H.signature(plan)
local discretionary=0
for _,enc in ipairs(plan.encounters) do
 if not enc.objective then discretionary=discretionary+1;assert(not enc.spawned) end
end
assert(discretionary>0,'fixture requires dormant discretionary homes')
T.init(graph);T.bounds(graph);noOverlap(graph)
assert(#W.Entities>0,'home exclusion removed all legal initial population')
local victim=W.Entities[1]
local floor=victim.LODWanderFloor
local before=W:_LivingOnFloor(floor)
victim:Remove()
assert(T.quiet(function() return W:_SpawnOne(graph,floor,'b24-replacement') end),
 'legal replacement was not admitted')
assert(W:_LivingOnFloor(floor)==before,'replacement changed floor population')
T.bounds(graph);noOverlap(graph)
assert(H.serial(Run.State.EncounterEcology)==receipt and H.signature(plan)==signature,
 'home reservation mutated plan or campaign receipt')

-- Two otherwise legal homes make reservation changes decisive. These rows are
-- deliberately non-objective: objective tags alone cannot satisfy the rule.
W:Cleanup()
local available=candidates(graph,floor)
local keys={};for k in pairs(available) do keys[#keys+1]=k end;table.sort(keys)
assert(#keys>=2,'fixture requires two unreserved legal homes')
local a,b=keys[1],keys[2]
local function replacement(rows)
 return {encounters=rows,tags=plan.tags,pacing=plan.pacing,ecology=plan.ecology}
end
graph.EncounterPlan=replacement({{cellKey=a,objective=false,spawned=false}})
local first=candidates(graph,floor)
assert(not first[a] and first[b],'dormant encounter home reservation missing')
graph.EncounterPlan=replacement({{cellKey=b,objective=false,spawned=false}})
local second=candidates(graph,floor)
assert(second[a] and not second[b],'replaced plan retained stale home reservations')
graph.EncounterPlan.encounters={{cellKey=a,objective=false,spawned=false}}
local changed=candidates(graph,floor)
assert(not changed[a] and changed[b],'in-place plan update retained stale reservations')

-- No plan and an older partial plan remain compatible with the spawn scanner.
graph.EncounterPlan=nil
local absent=candidates(graph,floor)
assert(absent[a] and absent[b],'missing plan retained reservations')
graph.EncounterPlan=replacement(nil)
local partial=candidates(graph,floor)
assert(partial[a] and partial[b],'missing encounter list rejected compatible graph')

-- Reserve every graph cell, without changing their geometry/roles. Initial and
-- replacement services must defer instead of using occupied encounter homes.
local all={}
for k in pairs(graph.Cells) do all[#all+1]={cellKey=k,objective=false,spawned=false} end
graph.EncounterPlan=replacement(all)
T.init(graph)
assert(#W.Entities==0,'all-reserved initialization used unsafe fallback')
for f=0,(graph.WanderLayers or graph.Layers)-1 do
 assert(next(candidates(graph,f))==nil,'all-reserved floor has spawn candidates')
 assert(not W:_SpawnOne(graph,f,'b24-all-reserved'),'reserved replacement spawned')
 assert(W.Diagnostics[f]=='no_legal_home','reservation defer not diagnosed')
end
assert(H.serial(Run.State.EncounterEcology)==receipt,'reservation defer consumed history')
graph.EncounterPlan=plan
T.init(graph);T.bounds(graph);noOverlap(graph)
assert(#W.Entities>0,'restored plan did not release temporary reservations')
assert(H.signature(plan)==signature,'reservation fixture altered original plan')
D:Cleanup()
print('BESTIARY_B24_PASS initial/replacement homes; dormant squads; all-reserved defer; fresh plan/list reservations; no-plan compatibility; immutable receipt/plan')
