-- Deterministic selection-only campaign sample of the actual 28 production
-- definitions. This is not physical generation or a native playthrough: graph
-- admission/lifecycle are covered by test_event_expansion_generation.lua.
local F=dofile('tools/event_expansion_fixture.lua')
local R,Run=F.R,F.Run
local Encounter=LOD.EncounterDirector
if not Encounter.EcologyCatalog then dofile(F.root..'sv_encounter_ecology_catalog.lua') end
if not Encounter.BeginEcology then dofile(F.root..'sv_encounter_ecology.lua') end
local CAMPAIGNS,LEVELS=96,20
assert(#R:Catalog()==28,'Sampler requires complete production catalog')
local function size(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function bump(t,k) t[k]=(t[k] or 0)+1 end
local function stats()
 return {selections=0,counts={},appearances={},families={},contracts={},themeAppearances={},themes={},
  rareSelections=0,rareAdjacentFloors=0,adjacentRepeatedIdentities=0,adjacentRepeatedFamilies=0,
  maxIdentityStreak=0,maxFamilyStreak=0,maxSameRareStreak=0,uniqueTotal=0,commonUniqueTotal=0,
  minUnique=100000,maxUnique=0,minCommonUnique=100000,familyCoverageTotal=0,relationSelections=0,firstSeenTotals={}}
end
local all,common,families={},{},{}
for _,id in ipairs(R:Catalog()) do
 all[id]=true;if not R.Definitions[id].rare then common[id]=true end
 families[R.Definitions[id].family]=true
end
local modes={history=stats(),control=stats()}
for campaign=1,CAMPAIGNS do
 local campaignSeed=LOD.Seeds.Derive(771293,'event-campaign:'..campaign..':sample-v1')
 Run.State={RunId='ecology-sample:'..campaign,CampaignEpoch=campaign,CampaignSeed=campaignSeed,Level=1}
 local memories,previous,streaks,covered,coveredFamilies,firstSeen={},{},{},{},{},{}
 for name in pairs(modes) do
  memories[name]=R:NewHistory();previous[name]={};streaks[name]={ids={},families={}}
  covered[name],coveredFamilies[name],firstSeen[name]={},{},{}
 end
 for level=1,LEVELS do
  local seed=LOD.Seeds.DeriveLevel(campaignSeed,level)
  Run.State.Level,Run.State.LevelSeed=level,seed
  local graph={MasterLevelSeed=seed,LevelSeed=seed}
  local encounterPlan={seed=seed}
  -- Run the existing EncounterDirector motif authority with an empty encounter
  -- composition. Only its motif scheduling is sampled here, never reinvented.
  Encounter:BeginEcology(encounterPlan,graph)
  graph.EncounterPlan=encounterPlan;Run.State.Graph=graph;Encounter.Plan=encounterPlan
  local theme=encounterPlan.ecology.theme
  assert(Encounter:CommitEcologyPlan(graph))
  local sameCount
  for _,name in ipairs({'history','control'}) do
   local s=modes[name]
   local ctx={history=memories[name],historyEnabled=name=='history',theme=theme}
   local selection,n,diag=R:Select(seed,level,ctx)
   assert(selection and #selection==n and n>=1 and n<=4)
   local repeatSelection,repeatN=R:Select(seed,level,ctx)
   assert(repeatN==n and table.concat(selection,',')==table.concat(repeatSelection,','),'Deterministic replay failed')
   if sameCount then assert(sameCount==n,'History changed event count') end;sameCount=n
   bump(s.counts,n);bump(s.themes,theme);s.themeAppearances[theme]=s.themeAppearances[theme] or {}
   local selected,selectedFamilies={},{}
   for ordinal,id in ipairs(selection) do
    local def=R.Definitions[id]
    assert(not selected[id] and (def.rare==true)==(ordinal==4))
    selected[id],selectedFamilies[def.family]=true,true
    covered[name][id],coveredFamilies[name][def.family]=true,true
    firstSeen[name][id]=firstSeen[name][id] or level
    s.selections=s.selections+1;bump(s.appearances,id);bump(s.families,def.family);bump(s.contracts,def.contract)
    bump(s.themeAppearances[theme],id)
    if diag.decisions[ordinal].relation then s.relationSelections=s.relationSelections+1 end
    if previous[name][id] then s.adjacentRepeatedIdentities=s.adjacentRepeatedIdentities+1 end
    streaks[name].ids[id]=previous[name][id] and (streaks[name].ids[id] or 0)+1 or 1
    s.maxIdentityStreak=math.max(s.maxIdentityStreak,streaks[name].ids[id])
    if def.rare then
     s.rareSelections=s.rareSelections+1
     s.maxSameRareStreak=math.max(s.maxSameRareStreak,streaks[name].ids[id])
    end
   end
   for family in pairs(selectedFamilies) do
    local priorFamily=previous[name].families and previous[name].families[family]
    if priorFamily then s.adjacentRepeatedFamilies=s.adjacentRepeatedFamilies+1 end
    streaks[name].families[family]=priorFamily and (streaks[name].families[family] or 0)+1 or 1
    s.maxFamilyStreak=math.max(s.maxFamilyStreak,streaks[name].families[family])
   end
   if n==4 and previous[name].rare then s.rareAdjacentFloors=s.rareAdjacentFloors+1 end
   selected.families,selected.rare=selectedFamilies,n==4
   previous[name]=selected
   memories[name]=R:HistoryAfter(memories[name],selection,level,theme)
  end
 end
 for name,s in pairs(modes) do
  local unique,commonUnique=size(covered[name]),0
  for id in pairs(covered[name]) do if common[id] then commonUnique=commonUnique+1 end end
  s.uniqueTotal=s.uniqueTotal+unique;s.commonUniqueTotal=s.commonUniqueTotal+commonUnique
  s.familyCoverageTotal=s.familyCoverageTotal+size(coveredFamilies[name])
  s.minUnique=math.min(s.minUnique,unique);s.maxUnique=math.max(s.maxUnique,unique)
  s.minCommonUnique=math.min(s.minCommonUnique,commonUnique)
  for id,level in pairs(firstSeen[name]) do
   local row=s.firstSeenTotals[id] or {campaigns=0,levelTotal=0};s.firstSeenTotals[id]=row
   row.campaigns,row.levelTotal=row.campaigns+1,row.levelTotal+level
  end
 end
end
for _,s in pairs(modes) do
 s.meanUnique=s.uniqueTotal/CAMPAIGNS;s.meanCommonUnique=s.commonUniqueTotal/CAMPAIGNS
 s.meanFamilyCoverage=s.familyCoverageTotal/CAMPAIGNS;s.meanEventsPerLevel=s.selections/(CAMPAIGNS*LEVELS)
 s.identityCoverage=size(s.appearances);s.familyCoverage=size(s.families)
 s.uniqueTotal,s.commonUniqueTotal,s.familyCoverageTotal=nil,nil,nil
 for _,row in pairs(s.firstSeenTotals) do row.meanFirstLevel=row.levelTotal/row.campaigns;row.levelTotal=nil end
end
local summary={catalog=size(all),common=size(common),families=size(families),campaigns=CAMPAIGNS,levels=LEVELS,
 method='Selection-only: actual catalog + EncounterDirector motif scheduler; paired equal-seed history-on/control; no physical admission or native gameplay.',
 history=modes.history,control=modes.control,
 repeatReduction=1-modes.history.adjacentRepeatedIdentities/modes.control.adjacentRepeatedIdentities}
assert(modes.history.identityCoverage==size(all),'Production identity invisible across finite campaign sample')
assert(modes.history.meanUnique>modes.control.meanUnique,'History did not improve campaign identity coverage')
assert(summary.repeatReduction>.5,'History did not substantially reduce adjacent identity overlap')
assert(modes.history.rareSelections==modes.control.rareSelections,'History changed fourth-slot frequency')
print('EVENT_ECOLOGY_SAMPLE_JSON: '..WalletJSONEncode(summary))
print(string.format('EVENT_ECOLOGY_SAMPLE_PASS: %dx%d campaigns; unique %.3f vs %.3f control; adjacent identity repeats %d vs %d; reduction %.2f%%; max streak %d vs %d; rare slots %d identical',
 CAMPAIGNS,LEVELS,modes.history.meanUnique,modes.control.meanUnique,
 modes.history.adjacentRepeatedIdentities,modes.control.adjacentRepeatedIdentities,summary.repeatReduction*100,
 modes.history.maxIdentityStreak,modes.control.maxIdentityStreak,modes.history.rareSelections))
