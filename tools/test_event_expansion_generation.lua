-- The quantitative sampler measures long-run ecology; this gate executes the
-- complete production catalog against real maze/progression/encounter plans.
local F=dofile('tools/event_expansion_fixture.lua')
local D,R,Run=F.D,F.R,F.Run
local baseline={slot_machine=true,locked_chest=true,treasure_chest=true,vending_machine=true,
 false_floor=true,warp_hole=true,skeleton_blockade=true,equipment_quiz=true}
local function read(path) local file=assert(io.open(path));local data=file:read('*a');file:close();return data end
local function encode(value) return WalletJSONEncode(value) end
local function resources(plan)
 local result={}
 for _,instance in ipairs(plan.instances) do for _,entity in ipairs(instance.entities) do result[#result+1]=entity end end
 return result
end
local function removed(entities,message)
 for _,entity in ipairs(entities) do assert(not IsValid(entity),message or 'Native resource survived teardown') end
end
local function selectionEquals(plan,expected,count)
 assert(plan.selectedCount==count and table.concat(plan.selected,',')==table.concat(expected,','),
  'Build dropped, rerolled or reordered selected event identities')
end

local catalog=R:Catalog()
assert(#catalog==28,'Actual eight-entry baseline must expand to 28 production identities')
local contracts,families,additions={},{},{}
local boot=read('gamemodes/legend_of_deborah/gamemode/init.lua')
for _,id in ipairs(catalog) do
 local definition=assert(R.Definitions[id])
 assert(definition.production and type(definition.Create)=='function' and type(definition.Interact)=='function')
 for _,field in ipairs({'name','family','scope','persistence','interactionMode','risk','role','topology'}) do
  assert(type(definition[field])=='string' and #definition[field]>0,'Missing event metadata: '..id..'/'..field)
 end
 local owner=assert(F.registrations[id],'Unowned catalog registration')
 assert(boot:find('include("lod/'..owner..'")',1,true),'Registered event is not loaded by production startup: '..id)
 contracts[definition.contract],families[definition.family]=true,true
 if not baseline[id] then
  additions[#additions+1]=id
  assert(definition.presentation and definition.presentation.model:match('^models/'),'New event requires external visual asset')
 end
end
assert(#additions==20 and F.count(contracts)==4 and F.count(families)>=8)
assert(not R.Definitions.bribe_blockade and not boot:find('include("lod/sv_event_bribe_blockade.lua")',1,true),
 'Retired Bribe event restored without authorization')
assert(boot:find('include("lod/sv_event_transactions.lua")',1,true),'Expanded transaction authority omitted at startup')

-- This explicit-seed gate must never consume the engine/global random stream.
-- Independent private streams remain live, including maze and encounter RNG.
local nativeRandom,nativeRandomSeed=math.random,math.randomseed
math.random=function() error('Event generation consumed unrelated global RNG') end
math.randomseed=function() error('Event generation reseeded unrelated global RNG') end
Run.State.Level=5
local previewSeed,graph
for seed=1,12 do
 local plan,result=F.Build(seed,'slot_machine')
 if plan then previewSeed,graph=seed,result;break end
 assert(tostring(result):find('event placement exhausted:',1,true),tostring(result))
end
assert(graph,'Unable to establish generated preview fixture')

-- Each identity receives actual feasible placement/Create, native ownership,
-- nonempty late-join details and exact cleanup. Previews reuse already generated
-- native geometry; only an infeasible topology triggers another bounded build.
local late=F.actor('76561198177100003')
late.active=false
local previewRejects,partialFailures,entityPeak=0,0,0
local function preview(id)
 D:Cleanup('next production identity')
 graph.EventPlan=nil
 local planned,plan=D:Plan(graph,{preview=id})
 if not planned then
  previewRejects=previewRejects+1
  for attempt=1,16 do
   local seed=previewSeed+attempt
   local built,result=F.Build(seed,id)
   if built then previewSeed,graph=seed,result;return built end
   previewRejects=previewRejects+1
   assert(tostring(result):find('event placement exhausted:',1,true)
    or tostring(result):find('combined event contract rejected:',1,true),tostring(result))
  end
  error('No feasible production placement after bounded topology search: '..id)
 end
 graph.EventPlan=plan
 local activated,reason=D:Activate(graph,plan)
 assert(activated,tostring(reason))
 F.Prove(graph,plan)
 return plan
end
for _,id in ipairs(catalog) do
 local beforeHistory=encode(Run.State.EventEcology)
 local plan=preview(id)
 local sig=F.signature(plan)
 assert(plan.mode=='preview' and plan.selectedCount==1 and encode(Run.State.EventEcology)==beforeHistory)
 local owned=resources(plan)
 entityPeak=math.max(entityPeak,#owned)
 assert(#owned>0 and #owned<=8,'Unbounded native entity cost for one event')
 for _,hero in ipairs({F.a,F.b,late}) do
  local definition=R.Definitions[id]
  if definition.Snapshot then
   for _,instance in ipairs(plan.instances) do
    local ok,details=pcall(definition.Snapshot,instance,hero,hero:SteamID64())
    assert(ok,'Snapshot callback failed: '..id..': '..tostring(details))
   end
  end
  D:SyncPlayer(hero)
  local packet=F.packets[#F.packets]
  assert(packet.id=='LOD_DungeonEvents' and packet.recipient==hero)
  local snapshot=packet.body
  assert(snapshot.selectedCount==1 and #snapshot.events==#plan.instances,'Late join lost members')
  for ordinal,row in ipairs(snapshot.events) do
   local instance=plan.instances[ordinal]
   assert(row.archetype==id and row.id==instance.id and row.state=='active' and not row.claimed)
   assert(not row.claimUnavailable and not (row.details and row.details.unavailable),'Snapshot boundary missing: '..id)
   assert(row.entityIndex==instance.entities[1]:EntIndex(),'Late join advertised a different native owner')
  end
 end
 local old=plan.instances[1]
 D:Cleanup('identity lifecycle verified')
 removed(owned)
 assert(not D.Context and not D:IsCurrent(old) and #D:Snapshot(late).events==0)
 local beforeCreated=#F.created
 local definition=R.Definitions[id]
 if definition.Tick then definition.Tick(D,old) end
 assert(#F.created==beforeCreated and not D:Interact(owned[1],F.a),'Stale callback revived a cleaned event')

 -- Every newly added event must own native resources before initialization.
 -- Throw after its real entity Initialize, while creation is only partial.
 if not baseline[id] then
  local nativeCreate,first,triggered,spawned=ents.Create,#F.created+1,false,0
  ents.Create=function(class)
   local entity=nativeCreate(class)
   if IsValid(entity) then
    local spawn=entity.Spawn
    function entity:Spawn()
     spawn(self)
     if self.LODEventInstance and self.LODEventInstance.archetype==id then
      spawned=spawned+1
      if spawned==#owned then triggered=true;error('injected native initialization failure') end
     end
    end
   end
   return entity
  end
  graph.EventPlan=nil
  local planned,partial=D:Plan(graph,{preview=id})
  assert(planned,tostring(partial))
  local accepted,reason=D:Activate(graph,partial)
  ents.Create=nativeCreate
  assert(triggered and not accepted and tostring(reason):find('event creation failed:',1,true),
   'Missing native fault boundary: '..id)
  assert(not D.Context and encode(Run.State.EventEcology)==beforeHistory)
  for index=first,#F.created do assert(not IsValid(F.created[index]),'Partial native Create leaked resource: '..id) end
  partialFailures=partialFailures+1
  local replacement=preview(id)
  assert(F.signature(replacement)==sig,'Native retry changed deterministic placement: '..id)
  assert(not D:IsCurrent(old),'Same-seed replacement revived old ownership')
  local replacementEntities=resources(replacement)
  D:Cleanup('fault recovery verified');removed(replacementEntities)
 end
end
assert(partialFailures==20)

-- Exhausting one selected definition rejects the entire production plan within
-- the authored search budget. Neither count nor campaign history can change.
local impossible=R.Definitions[additions[1]]
local place,attempts=impossible.Place,0
impossible.Place=function() attempts=attempts+1;return {cellKey='missing'} end
graph.EventPlan=nil
local beforeGraph,beforeHistory=F.graphSignature(graph),encode(Run.State.EventEcology)
local planned,reason=D:Plan(graph,{preview=impossible.id})
impossible.Place=place
assert(not planned and attempts>0 and attempts<=D.MaxPlacementAttempts and tostring(reason):find(impossible.id,1,true))
assert(F.graphSignature(graph)==beforeGraph and encode(Run.State.EventEcology)==beforeHistory)

-- A small actual campaign sample exercises mixed population, four contracts,
-- all d4 results, physical floors and committed history through RunManager.
-- Large catalog frequency/anti-repetition evidence lives in the separate sampler.
Run.State.RunId='expanded-events:production';Run.State.CampaignSeed=73201;Run.State.CampaignEpoch=2
Run.State.EventEcology=nil
local seenContracts,seenCounts,seenFloors,seenEventFloors,seenIDs={},{},{},{},{}
local accepted,rejected,levelSeed,lastPlan,lastGraph=0,0,nil,nil,nil
for level=1,32 do
 Run.State.Level=level
 local seed=LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,level)
 local plan,result=F.Build(seed)
 if not plan then
  rejected=rejected+1
  assert(tostring(result):find('event placement exhausted:',1,true)
   or tostring(result):find('combined event contract rejected:',1,true),tostring(result))
 else
  accepted=accepted+1
  local actualGraph=result
  local selected,count=R:Select(seed,level,D:SelectionContext(actualGraph,level))
  selectionEquals(plan,selected,count)
  assert(count==LOD.RNG.New(LOD.Seeds.Derive(seed,'dungeon-events:count:v1')):Int(1,4))
  assert(plan.ecology.committed and Run.State.EventEcology.after.totalLevels==accepted,'Successful campaign history missing')
  assert(#Run.State.EventEcology.after.recent<=R.HistoryLimit,'Campaign history grew without a bound')
  seenCounts[count]=true
  for _,instance in ipairs(plan.instances) do
   seenContracts[instance.contract],seenIDs[instance.archetype],seenEventFloors[instance.cell.z]=true,true,true
  end
  for _,cell in pairs(actualGraph.Cells) do seenFloors[cell.z]=true end
  assert(#resources(plan)<=count*5,'Full population entity cost exceeded bound')
  lastPlan,lastGraph,levelSeed=plan,actualGraph,seed
 end
 if accepted>=10 and F.count(seenContracts)==4 and F.count(seenCounts)==4
  and F.count(seenFloors)>=2 and F.count(seenEventFloors)>=2 then break end
end
assert(accepted>=10 and F.count(seenContracts)==4 and F.count(seenCounts)==4
 and F.count(seenFloors)>=2 and F.count(seenEventFloors)>=2,
 'Mixed actual campaign sample missed contracts, counts or physical floors')

-- Same-level regeneration replaces one receipt and preserves geometry, event
-- selection, placement, encounter reservation and private procedural streams.
local signature,graphSignature=F.signature(lastPlan),F.graphSignature(lastGraph)
local encounterSignature=encode(lastGraph.EncounterPlan)
local history=encode(Run.State.EventEcology)
local old,lastEntities=lastPlan.instances[1],resources(lastPlan)
local replay,replayGraph=F.Build(levelSeed)
assert(replay and F.signature(replay)==signature and F.graphSignature(replayGraph)==graphSignature)
assert(encode(replayGraph.EncounterPlan)==encounterSignature and encode(Run.State.EventEcology)==history)
removed(lastEntities,'Regeneration left old native resources')
assert(not D:IsCurrent(old),'Old instance survived same-level regeneration')

-- Turning production population off changes events alone. Exact maze,
-- progression and encounter plans prove isolation of their private RNG streams.
local enabled=F.convars.lod_events_enabled.value
F.convars.lod_events_enabled.value='0'
local empty,emptyGraph=F.Build(levelSeed)
F.convars.lod_events_enabled.value=enabled
assert(empty and empty.mode=='disabled' and empty.selectedCount==0 and #empty.instances==0)
assert(F.graphSignature(emptyGraph)==graphSignature and encode(emptyGraph.EncounterPlan)==encounterSignature,
 'Event population changed maze or encounter randomness')
assert(encode(Run.State.EventEcology)==history,'Disabled population changed event history')
replay,replayGraph=F.Build(levelSeed)
assert(replay and F.signature(replay)==signature and encode(Run.State.EventEcology)==history)

-- A fail-after-Create injection through the complete build path rejects all
-- selected members and rolls back history without reducing the chosen count.
local chosen=replay.selected[1]
local definition=R.Definitions[chosen]
local create,first=definition.Create,#F.created+1
definition.Create=function(...)
 local entity,why=create(...)
 assert(IsValid(entity),tostring(why))
 return nil,'injected complete-build native failure'
end
local failure,failureReason=F.Build(levelSeed)
definition.Create=create
assert(not failure and tostring(failureReason):find('event creation failed:',1,true))
assert(encode(Run.State.EventEcology)==history)
for index=first,#F.created do assert(not IsValid(F.created[index]),'Rejected full build leaked resource') end
local final,finalGraph=F.Build(levelSeed)
assert(final and F.signature(final)==signature and F.graphSignature(finalGraph)==graphSignature)
assert(encode(Run.State.EventEcology)==history)
local finalEntities=resources(final)
D:Cleanup('expansion production gate complete');LOD.MazeBuilder:Cleanup();LOD.EncounterDirector:Cleanup()
removed(finalEntities)
assert(not D.Context and #D:Snapshot(late).events==0)
math.random,math.randomseed=nativeRandom,nativeRandomSeed
print('EVENT_EXPANSION_GENERATION_PASS: 28 boot registrations; 20 new native fault/retry boundaries; all identities actual placement/Create/two-Hero and late-join snapshots/cleanup; '..
 accepted..' mixed campaign builds, '..rejected..' bounded rejects; all contracts/d4 counts/multiple physical floors; exact count/history/encounter/RNG preservation; entity peak '..entityPeak..'; preview rejects '..previewRejects)
