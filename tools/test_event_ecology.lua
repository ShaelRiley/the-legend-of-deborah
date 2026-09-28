-- Real registry/director and RunManager build lifecycle; Source entities alone
-- are doubled by the established event fixture. No mirrored selector/planner.
local F=dofile('tools/dungeon_event_fixture.lua')()
local R,D,Run=F.R,F.D,F.Run
local function native(_,instance)
 local e=ents.Create('fixture_event');e:SetPos(LOD.MazeBuilder:CellCenter(instance.cell));return e
end
for index=1,9 do
 R:Register({id='ecology_fixture_'..index,name='Ecology '..index,contract=index%2==0 and 'REWARD' or 'UTILITY',
  production=true,nonblocking=true,family=index<=3 and 'fixtures_a' or index<=6 and 'fixtures_b' or 'fixtures_c',
  role=index%2==0 and 'source' or 'recovery',topology=index%2==0 and 'dead_end' or 'respite',
  rare=index>=8,Create=native,Interact=function() return true end,
  themeAffinities={hunting=.7,quarantine=1.5}})
end
local function signature(plan)
 local out={tostring(plan.selectedCount)}
 for _,i in ipairs(plan.instances) do out[#out+1]=i.id..'/'..i.seed..'/'..i.cellKey end
 return table.concat(out,';')
end
local seen,rareSeen,pairSeen={},{},{}
for seed=1,768 do
 local a,n,diag=R:Select(seed,5,{history=R:NewHistory(),theme='hunting'})
 local b,m=R:Select(seed,5,{history=R:NewHistory(),theme='hunting'})
 assert(n==m and n==#a and table.concat(a,',')==table.concat(b,','))
 assert(n==LOD.RNG.New(LOD.Seeds.Derive(seed,'dungeon-events:count:v1')):Int(1,4),'Count stream changed')
 local unique={}
 for slot,id in ipairs(a) do
  assert(not unique[id]);unique[id]=true
  assert((R.Definitions[id].rare==true)==(slot==4),'Rare identity outside fourth slot')
  if slot==4 then rareSeen[id]=true end
 end
 for ai=1,#a do for bi=ai+1,#a do
  local left,right=a[ai],a[bi];if right<left then left,right=right,left end
  pairSeen[left..'|'..right]=true
 end end
 assert(#diag.decisions==n and diag.theme=='hunting')
 seen[n]=true
end
assert(seen[1] and seen[2] and seen[3] and seen[4] and rareSeen.ecology_fixture_8 and rareSeen.ecology_fixture_9)
-- All legal pairings must have support: distinct family/identity labels alone
-- do not decorrelate equal-position first draws of the affine shared generator.
local catalog=R:Catalog()
for ai=1,#catalog do for bi=ai+1,#catalog do
 local a,b=catalog[ai],catalog[bi]
 if not (R.Definitions[a].rare and R.Definitions[b].rare) then
  assert(pairSeen[a..'|'..b],'Correlated selector hid legal pair '..a..' / '..b)
 end
end end
local one=R:Select(901,5,{})
local definitions=R.Definitions;R.Definitions={}
local ids=R:Catalog() -- empty registry is deliberate; registration order is irrelevant.
for id in pairs(definitions) do ids[#ids+1]=id end;table.sort(ids)
for index=#ids,1,-1 do R:Register(definitions[ids[index]]) end
assert(table.concat(one,',')==table.concat(R:Select(901,5,{}),','),'Registration order changed ecology')
-- Real completed build records one exposure per archetype, never one per child.
assert(Run:BuildCurrentLevel(19))
local plan=D.Context.plan
local receipt=assert(Run.State.EventEcology)
assert(receipt.after.totalLevels==1 and plan.ecology.committed==true and not plan.ecologyReceipt)
for _,id in ipairs(plan.selected) do assert(receipt.after.appearances[id]==1) end
assert(not D:CommitEcologyPlan(Run.State.Graph),'Same receipt committed twice')
local first=signature(plan)
assert(Run:BuildCurrentLevel(19))
assert(signature(D.Context.plan)==first and Run.State.EventEcology.after.totalLevels==1,'Regeneration fed its own history')
assert(WalletJSONEncode(receipt.after)==WalletJSONEncode(Run.State.EventEcology.after))
-- Prospective planning is read-only, even for another level; a native failure
-- after selection cannot publish exposure or prevent a deterministic retry.
Run.State.Level=2
local previous=Run.State.EventEcology
local before=WalletJSONEncode(previous)
local selected=R:Select(47,2,D:SelectionContext(nil,2))
local definition=R.Definitions[selected[1]]
local create=definition.Create
local priorCreated=#F.created
definition.Create=function(d,i,g) local entity=native(d,i,g);assert(d:Track(i,entity));error('ecology native creation failure') end
assert(not Run:BuildCurrentLevel(47))
assert(Run.State.EventEcology==previous and WalletJSONEncode(previous)==before and not Run.State.BuildReady)
for index=priorCreated+1,#F.created do assert(not IsValid(F.created[index]),'Partial native event leaked after failed build') end
definition.Create=create
assert(Run:BuildCurrentLevel(47))
assert(Run.State.EventEcology.after.totalLevels==2)
local after=Run.State.EventEcology
D.NextPreview=selected[1]
assert(Run:BuildCurrentLevel(47) and D.Context.plan.mode=='preview')
assert(Run.State.EventEcology==after,'Developer preview polluted campaign history')
-- Failed bounded placement has inspectable rejection reasons and no exposure.
local graph=Run.State.Graph
local rejected=R.Definitions.ecology_fixture_1
local calls=0
rejected.Place=function() calls=calls+1;return {cellKey='missing'} end
assert(not D:Plan(graph,{preview=rejected.id}))
assert(calls==D.MaxPlacementAttempts and D.LastPlanDiagnostics.failure:find('placement exhausted'))
assert(D.LastPlanDiagnostics.placements[1].attempts==D.MaxPlacementAttempts)
assert(D.LastPlanDiagnostics.placements[1].rejections['missing event cell']==D.MaxPlacementAttempts)
assert(Run.State.EventEcology==after)
rejected.Place=nil
-- Graph topology observations do not add routes, alter locks, or claim native
-- line of sight. Preferred cells still need the ordinary contract proof.
local graphBefore=F.graphSignature(graph)
local facts=D:EventTopology(graph)
local found=false
for k,row in pairs(facts) do
 if row.deadEnd and row.optional and not row.protected then
  local value,reason=D:PlacementPreference(R.Definitions.ecology_fixture_2,row)
  assert(value>0 and reason=='optional_dead_end');found=true
 end
end
assert(found and F.graphSignature(graph)==graphBefore and D:ValidateRoutes(graph))
assert(D:PlacementPreference(R.Definitions.ecology_fixture_2,{protected=true})<0)
-- Stale state/campaign history is ignored; a fresh campaign starts empty.
Run.State.CampaignEpoch=Run.State.CampaignEpoch+1
assert(D:SelectionContext(graph,3).history.totalLevels==0)
-- Bounded long-running history and new campaign receipts contain only plain
-- identifiers, counts and level numbers, never native entities or graph owners.
local memory=R:NewHistory()
for level=1,100 do
 local s=R:Select(LOD.Seeds.DeriveLevel(332211,level),level,{history=memory})
 memory=R:HistoryAfter(memory,s,level,'hunting')
end
assert(memory.totalLevels==100 and #memory.recent==R.HistoryLimit)
assert(table.Count(memory.appearances)<=#R:Catalog() and table.Count(memory.lastSeen)<=#R:Catalog())
D:Cleanup('ecology test')
print('EVENT_ECOLOGY_PASS: exact d4/rare fourth slot, weighted deterministic registration-order isolation, successful-build history, no regen/preview/failed-creation feedback, bounded history and placement diagnostics, graph-preserving topology preferences')
