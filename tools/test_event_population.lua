-- Combined production catalog through real RunManager generation, graph proofs,
-- native Use callbacks and SQLite. Only Source boundaries use existing doubles.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run,realFloors=true})
local root,E,Run,D,R,Store=F.root,LOD.Equipment,F.Run,F.D,F.R,F.Store
for i=#F.online,1,-1 do table.remove(F.online,i) end
local function actor(id,class)
 local p=equipment.actor(id)
 p.ps.deploymentComplete,p.ps.lives=true,3
 p.ps.progressionState.classId=class or 'fighter';p.ps.progressionState.level=20
 LOD.CharacterProgressionSystem:_RecomputeProgressionState(p.ps.progressionState)
 function p:SteamID64() return self.id end
 function p:Nick() return self.id end
 function p:IsAdmin() return true end
 function p:GetPos() return self.pos or Vector() end
 p.EyePos,p.WorldSpaceCenter=p.GetPos,p.GetPos
 function p:KeyDown() return self.pick==true end
 function p:ChatPrint(text) self.lastChat=text end
 F.online[#F.online+1]=p
 return p
end
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
dofile(root..'sv_crypto_director.lua')
LOD.CryptoDirector.Sync=function(_,p) p.walletSynced=true end
for _,file in ipairs({'locked_chest','treasure_chest','vending_machine'}) do dofile(root..'sv_event_'..file..'.lua') end
local Chest,Treasure,Vending,Slot=LOD.EventLockedChest,LOD.EventTreasureChest,LOD.EventVendingMachine,F.Slot
assert(#R:Catalog()==4 and R.PopulationReady==true and F.convars.lod_events_enabled:GetBool())
assert(R.Definitions.treasure_chest.rare==true)
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function account(p) return assert(Store:Read(p.id)) end
local function keys(p) local k=E:Ensure(p.ps).items.chest_key;return k and k.count or 0 end
local function potions(p) local k=E:Ensure(p.ps).items.healing_potion;return k and k.count or 0 end
local function credit(p,n)
 assert(Store:Transaction('population:fund:'..p.id,'fixture',{p.id},function(accounts)
  accounts[p.id].balance=accounts[p.id].balance+n;return true,{}
 end))
end
local function near(p,i) p.pos=i.entities[1]:GetPos() end
local function planSignature(plan)
 local rows={tostring(plan.selectedCount)}
 for _,i in ipairs(plan.instances) do rows[#rows+1]=i.id..'/'..i.cellKey..'/'..i.memberCount..'/'..i.seed end
 return table.concat(rows,';')
end
local function build(seed)
 assert(Run:BuildCurrentLevel(seed))
 local g,plan=Run.State.Graph,D.Context.plan
 assert(plan.mode=='full' and Run.State.BuildReport.eventMode=='full')
 assert(LOD.MazeGenerator:Validate(g) and LOD.GraphIntegrity:Audit(g).valid and D:ValidateRoutes(g))
 assert(g.Progression.Validation.valid)
 local selected,n=R:Select(seed,Run.State.Level)
 assert(plan.selectedCount==n and Run.State.BuildReport.eventCount==n)
 local archetypes,cells={},{}
 for _,i in ipairs(plan.instances) do
  archetypes[i.archetype]=true
  assert(not cells[i.cellKey] and not D:ProtectedCells(g)[i.cellKey]);cells[i.cellKey]=true
  assert(D:ValidatePlacement(g,R.Definitions[i.archetype],i.placement))
  assert(i.state=='active' and D:IsCurrent(i) and IsValid(i.entities[1]))
 end
 assert(count(archetypes)==n and #plan.instances==Run.State.BuildReport.eventInstanceCount)
 assert((archetypes.treasure_chest==true)==(n==4))
 for _,id in ipairs(selected) do assert(archetypes[id]) end
 return plan
end
-- At most 32 cheap seed probes; build just the distinct d4/member cases.
local seeds,memberSeeds={},{}
for seed=1,32 do
 local selected,n=R:Select(seed)
 seeds[n]=seeds[n] or seed
 if n==4 then
  local eventSeed=LOD.Seeds.Derive(seed,'dungeon-events:archetype:treasure_chest:v1')
  local members=LOD.RNG.New(LOD.Seeds.Derive(eventSeed,'instance-count:v1')):Int(1,2)
  memberSeeds[members]=memberSeeds[members] or seed
 end
end
for n=1,4 do assert(seeds[n],'Missing bounded d4 case');build(seeds[n]) end
for n=1,2 do
 assert(memberSeeds[n],'Missing bounded treasure member case')
 local plan=build(memberSeeds[n]);local members=0
 for _,i in ipairs(plan.instances) do if i.archetype=='treasure_chest' then members=members+1;assert(i.memberCount==n) end end
 assert(members==n and #plan.instances==3+n)
end
local seed=memberSeeds[2]
local plan=build(seed)
local signature,graphSignature=planSignature(plan),F.graphSignature(Run.State.Graph)
local oldEntities={};for _,i in ipairs(plan.instances) do oldEntities[#oldEntities+1]=i.entities[1] end
plan=build(seed)
assert(planSignature(plan)==signature and F.graphSignature(Run.State.Graph)==graphSignature)
for _,e in ipairs(oldEntities) do assert(not IsValid(e) and not D:Interact(e,actor('76561198300999999'))) end
-- An operator's saved opt-out keeps an identical maze/progression result.
F.convars.lod_events_enabled.value='0'
assert(Run:BuildCurrentLevel(seed) and D.Context.plan.mode=='disabled' and #D.Context.plan.instances==0)
assert(F.graphSignature(Run.State.Graph)==graphSignature)
R.PopulationReady=false
local ok,reason=D:Plan(Run.State.Graph,{enabled=true});assert(not ok and reason:find('gated'))
R.PopulationReady=true
-- Full preview is admin/developer only, works with saved opt-out, grants no
-- funds/items, prints each locator and consumes its request exactly once.
local admin=actor('76561198300000001')
CreateConVar('lod_developer_mode','0')
local beforeBuilds=F.nativeBuilds
F.commands.lod_event_population_preview(admin,nil,{})
assert(F.nativeBuilds==beforeBuilds)
F.convars.lod_developer_mode.value='1';admin.IsAdmin=function() return false end
F.commands.lod_event_population_preview(admin,nil,{})
assert(F.nativeBuilds==beforeBuilds)
admin.IsAdmin=function() return true end
F.commands.lod_event_population_preview(admin,nil,{'invalid'})
assert(F.nativeBuilds==beforeBuilds,'Invalid preview seed must not replace a dungeon')
R.PopulationReady=false
F.commands.lod_event_population_preview(admin,nil,{tostring(seed)})
assert(not Run.State.BuildReady and not D.Context and not D.NextPopulationPreview,'Full preview must honor explicit readiness gate')
R.PopulationReady=true
local output,printOriginal={},print
print=function(text) output[#output+1]=tostring(text) end
F.commands.lod_event_population_preview(admin,nil,{tostring(seed)})
print=printOriginal
assert(Run.State.BuildReport.eventMode=='full' and not Run.State.Ranked and not D.NextPopulationPreview)
assert(D.Context.plan.selectedCount==4 and #D.Context.plan.instances==5,'Normal seeded preview must reproduce all archetypes and both treasure members')
assert(F.convars.lod_events_enabled.value=='0' and account(admin).balance==0 and count(account(admin).tokens)==0 and keys(admin)==0)
local locators=0;for _,line in ipairs(output) do if line:find('setpos',1,true) then locators=locators+1 end end
assert(locators==#D.Context.plan.instances,'Every realized member needs a native locator')
assert(Run:BuildCurrentLevel(seed) and D.Context.plan.mode=='disabled','Preview cannot persist after one generation')
F.convars.lod_events_enabled.value='1'
plan=build(seed)
-- All four archetypes coexist and settle independently through native Use.
local a,b=actor('76561198300000002'),actor('76561198300000003')
for _,p in ipairs({a,b}) do credit(p,100);assert(E:AddConsumable(E:Ensure(p.ps),'chest_key',3)) end
local byType={}
for _,i in ipairs(plan.instances) do byType[i.archetype]=byType[i.archetype] or i end
local expected={}
for _,p in ipairs({a,b}) do
 local balance=100
 for _,i in ipairs(plan.instances) do
  near(p,i);F.now=F.now+2;i.entities[1]:Use(p)
  local claim=assert(D:Claim(i,p.id));assert(claim.state=='resolved',i.archetype)
  if i.archetype=='slot_machine' then balance=balance+claim.result.net end
  if i.archetype=='vending_machine' then balance=balance-10 end
  local wallet,inventory=WalletJSONEncode(account(p)),WalletJSONEncode(p.ps.equipment)
  assert(not D:Interact(i.entities[1],p))
  assert(WalletJSONEncode(account(p))==wallet and WalletJSONEncode(p.ps.equipment)==inventory)
 end
 assert(account(p).balance==balance and count(account(p).tokens)==2 and keys(p)==0 and potions(p)==1)
 assert(E:StoredEquipmentCount(p.ps.equipment)==1)
 expected[p.id]=WalletJSONEncode(account(p))
 local snapshot=D:Snapshot(p);assert(#snapshot.events==5 and snapshot.selectedCount==4)
 for _,row in ipairs(snapshot.events) do assert(row.claimed and row.result) end
end
local fresh=actor('76561198300000004')
for _,row in ipairs(D:Snapshot(fresh).events) do assert(not row.claimed and not row.result) end
-- Reconnect and generation replacement hydrate only each account's claims.
local stale=byType.slot_machine
for _,i in ipairs(plan.instances) do i.claims={} end
WalletSQLReconnect()
local replacement=actor(a.id)
F.hooks.LOD_DungeonEventSnapshot(replacement);table.remove(F.timers)()
assert(F.packets[#F.packets].recipient==replacement)
for _,row in ipairs(F.packets[#F.packets].body.events) do assert(row.claimed) end
plan=build(seed)
assert(not D:IsCurrent(stale))
for _,i in ipairs(plan.instances) do near(replacement,i);assert(not D:Interact(i.entities[1],replacement)) end
assert(WalletJSONEncode(account(replacement))==expected[a.id] and keys(replacement)==0 and E:StoredEquipmentCount(E:Ensure(replacement.ps))==0)
-- Creation failure after earlier native members is all-or-nothing; retry keeps
-- the exact count, plan and unrelated graph instead of rolling a smaller result.
local last=plan.instances[#plan.instances].archetype
local definition,originalCreate=R.Definitions[last],R.Definitions[last].Create
local createdFrom=#F.created+1
definition.Create=function(d,i,g) local e=originalCreate(d,i,g);assert(IsValid(e));error('injected partial event creation') end
local accepted=Run:BuildCurrentLevel(seed)
definition.Create=originalCreate
assert(not accepted and not Run.State.BuildReady and not D.Context)
for n=createdFrom,#F.created do assert(not IsValid(F.created[n]),'Partial creation leaked entity') end
plan=build(seed)
assert(planSignature(plan)==signature and F.graphSignature(Run.State.Graph)==graphSignature)
local calls=0;local place=Vending.Place
Vending.Place=function() calls=calls+1;return {cellKey='absent'} end
accepted=Run:BuildCurrentLevel(seed)
Vending.Place=place
assert(not accepted and calls==D.MaxPlacementAttempts and not Run.State.BuildReady and not D.Context)
plan=build(seed);assert(planSignature(plan)==signature)
byType={};for _,i in ipairs(plan.instances) do byType[i.archetype]=byType[i.archetype] or i end
-- SQL final-write mutation must abort even the older slot-only settlement.
local query=sql.Query
for index,mutate in ipairs({
 function(p) p.soldier=true end,
 function(p) p.ps.deploymentComplete=false end,
 function(p) p.ps.equipmentLifeSerial=(p.ps.equipmentLifeSerial or 0)+1 end,
 function(p) local copy={};for k,v in pairs(p.ps) do copy[k]=v end;p.ps=copy end,
 function(p) p.id='76561198309999999' end,
 function(_,i) i.entities[1].valid=false end,
 function(_,i) i.entities[1].LODEventInstance={} end,
 function(_,i) i.entities={} end,
 function(p,i) i.claims[p.id]={state='resolving'} end,
 function() Run.State.CampaignClock={expired=true} end,
 function() Run.State.CampaignEpoch=Run.State.CampaignEpoch+1 end
}) do
 local p=actor(string.format('76561198301%06d',index));credit(p,20)
 local i=byType.slot_machine;near(p,i)
 local id,epoch=p.id,Run.State.CampaignEpoch;local changed=false
 local entities,ps,life=i.entities,p.ps,p.ps.equipmentLifeSerial
 sql.Query=function(statement)
  local result=query(statement)
  if not changed and statement:find('INSERT INTO lod_crypto_ledger',1,true) then changed=true;mutate(p,i) end
  return result
 end
 assert(not D:Interact(i.entities[1],p),'Stale slot participant accepted: '..index)
 sql.Query=query
 assert(changed and assert(Store:Read(id)).balance==20 and not Slot.Claim(i,id),'Stale slot transaction committed: '..index)
 assert(#Store:Recent(id)==0,'Rejected slot history leaked: '..index)
 local replacedEpoch=Run.State.CampaignEpoch~=epoch
 Run.State.CampaignEpoch=epoch;Run.State.CampaignClock=nil
 i.entities=entities
 i.entities[1].valid=true;i.entities[1].LODEventInstance=i
 if not replacedEpoch then
  p.ps,p.id,p.soldier=ps,id,false;ps.equipmentLifeSerial=life;ps.deploymentComplete=true
  local accepted,result=D:Interact(i.entities[1],p)
  assert(accepted and account(p).balance==20+result.net and #Store:Recent(id)==1,'Unspent slot retry failed: '..index)
  assert(not D:Interact(i.entities[1],p) and #Store:Recent(id)==1)
 end
end
-- Shared lockpick feedback is a reentrant boundary. Removing its exact entity
-- cannot grant ordinary equipment or a DFT after that removal.
local send=LOD.CombatRolls._Send
for _,kind in ipairs({'locked_chest','treasure_chest'}) do
 local i=byType[kind];local def=R.Definitions[kind]
 local tested=false
 for suffix=1,32 do
  local id=string.format('76561198302%06d',suffix+(kind=='treasure_chest' and 100 or 0))
  if LOD.RNG.New(def.Seed(i,id,'lockpick')):Int(1,100)<=95 then
   local p=actor(id,'rogue');near(p,i)
   LOD.CombatRolls._Send=function(self,who,event,text,family,fields)
    send(self,who,event,text,family,fields)
    if who==p and fields.event=='chest_lockpick' then i.entities[1]:Remove() end
   end
   assert(not D:Interact(i.entities[1],p),'Removed '..kind..' granted reward')
   assert(E:StoredEquipmentCount(E:Ensure(p.ps))==0 and count(account(p).tokens)==0 and not def.Claim(i,id))
   LOD.CombatRolls._Send=send;i.entities[1].valid=true
   assert(D:Interact(i.entities[1],p),'Retained successful unlock must permit safe retry')
   tested=true;break
  end
 end
 assert(tested)
end
local finalEntities={};for _,i in ipairs(plan.instances) do finalEntities[#finalEntities+1]=i.entities[1] end
D:Cleanup('population suite complete')
for _,e in ipairs(finalEntities) do assert(not IsValid(e) and not D:Interact(e,a)) end
assert(#D:Snapshot(a).events==0)
-- Narrow encounter/event seam: run the real m3 planning wrapper, including its
-- LOS policy, base encounter planner and current roster template extensions.
-- Geometry has already been doubled by this fixture; collision fractions remain
-- a native boundary. No hostile spawning/AI or Source collision is claimed here.
dofile(root..'sv_maze_navigator.lua')
dofile(root..'sv_encounter_director.lua')
LOD.CombatRolls.HostileDamageProfiles=LOD.CombatRolls.HostileDamageProfiles or {}
LOD.WanderingDirector=LOD.WanderingDirector or {Config={ArchetypeWeights={}}}
dofile(root..'sv_enemy_roster.lua')
dofile(root..'sv_enemy_roster_placement.lua')
local ED,Builder=LOD.EncounterDirector,LOD.MazeBuilder
local originalBuild,originalPlan,originalTrace,originalParty=Builder.Build,D.Plan,util.TraceLine,Run._ActiveCount
Run._ActiveCount=function() return 2 end
util.TraceLine=function(t)
 local distance=math.sqrt((t.endpos-t.start):LengthSqr())
 local fraction=distance>320 and 320/distance or 1
 return {Hit=fraction<1,Fraction=fraction,StartSolid=false,HitPos=t.start+(t.endpos-t.start)*fraction}
end
-- Capture the production m3 wrapper around only its already-completed native
-- geometry step, then invoke it immediately before the existing event planner.
Builder.Build=function() return true,{} end
dofile(root..'sv_m3_run_integration.lua')
local encounterBuild=Builder.Build
Builder.Build=originalBuild
local encounterSignature,protectedCount,encounterCount
D.Plan=function(self,g,options)
 assert(encounterBuild(Builder,g))
 local before=WalletJSONEncode({tags=g.CellTags,encounters=g.EncounterPlan})
 local occupied={}
 for k,tag in pairs(g.CellTags) do
  if tag.safe or tag.objective or tag.role=='resupply' or tag.role=='boss' then occupied[k]=true end
 end
 for _,encounter in ipairs(g.EncounterPlan.encounters) do occupied[encounter.cellKey]=true end
 protectedCount,encounterCount=count(occupied),#g.EncounterPlan.encounters
 assert(encounterCount>3 and protectedCount>encounterCount,'Production discretionary encounters and safe tags must be present')
 local accepted,result=originalPlan(self,g,options)
 assert(accepted,result)
 assert(before==WalletJSONEncode({tags=g.CellTags,encounters=g.EncounterPlan}),'Event planning changed encounter reservations')
 for _,i in ipairs(result.instances) do
  assert(not occupied[i.cellKey],'Event overlapped actual encounter/safe reservation')
  assert(not occupied[i.placement.destinationCellKey],'Paired event destination overlapped actual encounter/safe reservation')
 end
 encounterSignature=before
 return accepted,result
end
local integrated=build(2)
assert(integrated.selectedCount==4 and #integrated.instances==5)
local integratedSignature,firstEncounters=planSignature(integrated),encounterSignature
integrated=build(2)
assert(planSignature(integrated)==integratedSignature and encounterSignature==firstEncounters)
-- Activate the real fifth catalog member without weakening the accepted
-- four-entry transactional regression above. Count/rare streams must remain
-- unchanged; false floor competes for one of three common slots.
dofile(root..'sv_safe_teleport.lua')
dofile(root..'sv_event_false_floor.lua')
assert(#R:Catalog()==5 and R.Definitions.false_floor.contract=='HAZARD')
local catalogSeen,countSeeds,hazardCounts={},{},{}
for currentSeed=1,128 do
 local chosen,n=R:Select(currentSeed)
 assert(n==LOD.RNG.New(LOD.Seeds.Derive(currentSeed,'dungeon-events:count:v1')):Int(1,4))
 assert(#chosen==n)
 local distinct={}
 for ordinal,id in ipairs(chosen) do
  assert(not distinct[id]);distinct[id]=true;catalogSeen[id]=true
  assert(id~='treasure_chest' or ordinal==4,'Rare treasure cannot leak into common selection')
 end
 assert((distinct.treasure_chest==true)==(n==4))
 if distinct.false_floor then countSeeds[n]=countSeeds[n] or currentSeed end
end
assert(count(catalogSeen)==5,'All five production archetypes must remain selectable')
for n=1,4 do
 assert(countSeeds[n],'False floor must participate at every d4 count')
 local combined=build(countSeeds[n]);local floor
 for _,i in ipairs(combined.instances) do if i.archetype=='false_floor' then floor=i end end
 assert(floor and floor.placement.destinationCellKey)
 assert(not D:ProtectedCells(Run.State.Graph)[floor.placement.destinationCellKey])
 for _,i in ipairs(combined.instances) do
  if i~=floor then assert(i.cellKey~=floor.placement.destinationCellKey,'Landing must be reserved from sibling events') end
 end
 hazardCounts[n]=true
end
local sampled=0
for sampleSeed=1,64 do
 local selected=R:Select(sampleSeed);local hazard=false
 for _,id in ipairs(selected) do if id=='false_floor' then hazard=true end end
 if hazard then build(sampleSeed);sampled=sampled+1 end
 if sampled==12 then break end
end
assert(sampled==12,'Bounded varied production sample must realize the selected hazard')
-- Sixth member enters the common pool only on later dungeon levels. Exercise
-- the combined real catalog, production encounters and both endpoint contracts.
dofile(root..'sv_event_warp_hole.lua')
assert(#R:Catalog()==6 and R.Definitions.warp_hole.contract=='UTILITY')
local warpSeeds,allSeen={},{}
for currentSeed=1,128 do
 local early,earlyCount=R:Select(currentSeed,4)
 local later,laterCount=R:Select(currentSeed,5)
 assert(earlyCount==laterCount,'Eligibility cannot reroll the exact d4 count')
 for _,id in ipairs(early) do assert(id~='warp_hole','Warp appeared before dungeon 5') end
 local distinct={}
 for ordinal,id in ipairs(later) do
  assert(not distinct[id]);distinct[id]=true;allSeen[id]=true
  assert(id~='treasure_chest' or ordinal==4)
 end
 assert(#later==laterCount and (distinct.treasure_chest==true)==(laterCount==4))
 if distinct.warp_hole then warpSeeds[laterCount]=warpSeeds[laterCount] or currentSeed end
end
assert(count(allSeen)==6,'All six authored archetypes must remain selectable')
Run.State.Level=5
local function checkWarp(plan)
 local occupied,warp={}
 for _,i in ipairs(plan.instances) do
  for _,k in ipairs({i.cellKey,i.placement.destinationCellKey}) do
   assert(not occupied[k],'Paired endpoints overlap sibling event');occupied[k]=true
  end
  if i.archetype=='warp_hole' then warp=i end
 end
 assert(warp and #warp.entities==2 and not warp.linked)
 assert(Run.State.Graph.Cells[warp.cellKey].z~=Run.State.Graph.Cells[warp.placement.destinationCellKey].z)
 return warp
end
for n=1,4 do assert(warpSeeds[n]);checkWarp(build(warpSeeds[n])) end
local laterSignature,laterGraph
sampled=0
for sampleSeed=1,64 do
 local selected=R:Select(sampleSeed,5);local warp=false
 for _,id in ipairs(selected) do if id=='warp_hole' then warp=true end end
 if warp then
  local combined=build(sampleSeed);checkWarp(combined);sampled=sampled+1
  if sampled==1 then
   laterSignature,laterGraph=planSignature(combined),F.graphSignature(Run.State.Graph)
   assert(planSignature(build(sampleSeed))==laterSignature and F.graphSignature(Run.State.Graph)==laterGraph)
  end
 end
 if sampled==12 then break end
end
assert(sampled==12,'Bounded actual six-entry sample must realize every selected warp pair')
print('WARP_POPULATION_PASS: early-level exclusion; six-member catalog at dungeon 5; exact 1d4 counts; 12 actual warp-selected production builds with encounter reservations and deterministic endpoint pairs')
D.Plan,util.TraceLine,Run._ActiveCount=originalPlan,originalTrace,originalParty
D:Cleanup('encounter population seam complete');ED:Cleanup()
print('EVENT_ENCOUNTER_SEAM_PASS: legacy seed 2 retained; '..sampled..' actual five-entry hazard-selected seeds realize with production encounters and both endpoints reserved')
print('EVENT_POPULATION_PASS: four-entry transactional regressions plus actual five-entry production/encounter catalog; exact 1d4, rare fourth slot, safe hazard endpoints, opt-out/preview, reconnect and rollback')
