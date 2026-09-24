local T=dofile('tools/test_bestiary_b23.lua')
local lines={}
local output=print
local function print(line) lines[#lines+1]=line;output(line) end
local H,W=T.H,T.W
local D,Run=H.D,H.Run
local counts,themes,changed,totals={},{},{},{spawned=0,legacy=0,fullFloors=0,floors=0,target=0}
-- B24 combines planned ordinary squads with initial native-boundary roamers.
-- This is potential population, never a simultaneous-entity or sighting count.
local basics={shambler=true,runner=true,soldier=true,deadcrab=true,bioblaster=true}
local function add(t,k,n) t[k]=(t[k] or 0)+(n or 1) end
local function size(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function arm() return {motifs={},overlap=0,pairs=0,maxBasicShare=0,minFamilies=math.huge} end
local combined={spawned=arm(),legacy=arm()}
local function observeCombined(graph,bucket)
 local s=combined[bucket];local plan=graph.EncounterPlan;local theme=plan.ecology.theme
 local motif=D.EcologyCatalog.themes[theme]
 local row=s.motifs[theme] or {identities={},families={},bodies=0};s.motifs[theme]=row
 local roster={}
 local function body(id,n)
  local family=assert(D.EcologyCatalog.families[id],'uncatalogued ordinary identity '..id)
  roster[id]=true;add(s.campaign,id,n);s.families[family]=true
  add(row.identities,id,n);add(row.families,family,n);row.bodies=row.bodies+n
 end
 for _,enc in ipairs(plan.encounters) do
  if not enc.objective then
   assert(motif.templates[enc.templateId] or D.EcologyCatalog.common[enc.templateId]
    and enc.ecologyDecision and enc.ecologyDecision.fallback,'B24 incoherent template pool')
  end
  for id,n in pairs(enc.composition) do body(id,n) end
 end
 for _,e in ipairs(W.Entities) do if IsValid(e) then body(e.LODArchetypeId,1) end end
 if s.previous then
  local union,intersection=0,0
  for id in pairs(roster) do union=union+1;if s.previous[id] then intersection=intersection+1 end end
  for id in pairs(s.previous) do if not roster[id] then union=union+1 end end
  s.overlap=s.overlap+(union>0 and intersection/union or 0);s.pairs=s.pairs+1
 end
 s.previous=roster
end
local function observe(graph,bucket)
 T.bounds(graph)
 for _,e in ipairs(W.Entities) do
  if IsValid(e) then
   totals[bucket]=totals[bucket]+1
   if bucket=='spawned' then counts[e.LODArchetypeId]=(counts[e.LODArchetypeId] or 0)+1 end
  end
 end
 if bucket=='spawned' then
  for f=0,(graph.WanderLayers or graph.Layers)-1 do
   totals.floors=totals.floors+1
   totals.target=totals.target+W:GetFloorTarget(graph)
   if W:_LivingOnFloor(f)==W:GetFloorTarget(graph) then totals.fullFloors=totals.fullFloors+1 end
  end
 end
end
for campaign=1,32 do
 local seed=campaign*7919
 for _,s in pairs(combined) do s.campaign={};s.families={};s.previous=nil end
 Run.State={CampaignSeed=seed,CampaignEpoch=1,RunId=1,Level=1}
 for level=1,20 do
  H.setParty((campaign+level-2)%4+1)
  local graph=H.prepare(seed,level);local plan=H.build(graph);H.bounds(plan)
  Run.State.BuildReady=true;Run.State.Failed=false;Run.State.LevelCleared=false;Run.State.SimulationFrozen=false
  assert(D:CommitEcologyPlan(graph))
  local receipt=H.serial(Run.State.EncounterEcology);local before=H.signature(plan)
  local theme=plan.ecology.theme;themes[theme]=(themes[theme] or 0)+1
  local random=math.random;math.random=function() error('global RNG consumed') end
  T.init(graph);observe(graph,'spawned');observeCombined(graph,'spawned');local first=T.signature()
  if level==10 then T.init(graph);assert(T.signature()==first,'campaign spawn replay failed') end
  -- Same topology/plan/seed and safeguards; disable only motif pool selection.
  local pool=W._Pool;W._Pool=function() return W.Config.ArchetypeWeights,'legacy' end
  T.init(graph);observe(graph,'legacy');observeCombined(graph,'legacy')
  if T.signature()~=first then changed[theme]=(changed[theme] or 0)+1 end
  W._Pool=pool;math.random=random
  assert(H.serial(Run.State.EncounterEcology)==receipt,'wandering consumed campaign memory')
  assert(H.signature(plan)==before,'wandering changed encounter plan')
 end
 print('B23_CAMPAIGN id='..campaign..' cumulativeSpawned='..totals.spawned)
 for _,bucket in ipairs({'spawned','legacy'}) do
  local s=combined[bucket];local total,largest,dominant=0,0,''
  for id,n in pairs(s.campaign) do
   total=total+n
   if basics[id] and n>largest then largest=n;dominant=id end
  end
  local share=largest/total;local families=size(s.families)
  s.maxBasicShare=math.max(s.maxBasicShare,share);s.minFamilies=math.min(s.minFamilies,families)
  print(string.format('B24_POPULATION campaign=%d arm=%s bodies=%d dominant=%s basicShare=%.6f families=%d',campaign,bucket,total,dominant,share,families))
  assert(share<=.5,'B24 basic identity dominates campaign '..campaign..':'..bucket)
  assert(families>=10,'B24 campaign family coverage below10 '..campaign..':'..bucket)
 end
end
for id in pairs(T.new) do assert((counts[id] or 0)>=25,'new specialist exposure below25 '..id) end
for theme in pairs(W.Config.Pools) do assert((changed[theme] or 0)>0,'motif has no actual production influence '..theme) end
for _,id in ipairs((function() local a={} for id in pairs(counts) do a[#a+1]=id end table.sort(a);return a end)()) do
 print('B23_EXPOSURE '..id..' spawned='..counts[id])
end
for theme,n in pairs(themes) do print('B23_MOTIF '..theme..' dungeons='..n..' changed='..(changed[theme] or 0)) end
print('BESTIARY_B23_CAMPAIGN_PASS dungeons=640 spawned='..totals.spawned..' legacy='..totals.legacy..' fullFloors='..totals.fullFloors..' floors='..totals.floors..' target='..totals.target..' deferred='..(totals.target-totals.spawned)..' safety/caps/receipt/plan/RNG/replay retained')
for theme in pairs(W.Config.Pools) do
 assert(H.serial(combined.spawned.motifs[theme].families)~=H.serial(combined.legacy.motifs[theme].families),'B24 combined motif has no family influence '..theme)
end
for _,bucket in ipairs({'spawned','legacy'}) do
 local s=combined[bucket]
 print(string.format('B24_COMBINED arm=%s maxCampaignBasicShare=%.6f minCampaignFamilies=%d meanConsecutiveJaccard=%.6f pairs=%d',bucket,s.maxBasicShare,s.minFamilies,s.overlap/s.pairs,s.pairs))
 for _,theme in ipairs({'corruption','crossfire','hunting','occupation','quarantine','retinue'}) do
  print('B24_MOTIF arm='..bucket..' theme='..theme..' '..H.serial(s.motifs[theme]))
 end
end
print('BESTIARY_B24_COMBINED_PASS 32x20 paired populations; no home overlap; basicShare<=0.5 families>=10; all6 motifs affect family distribution; membership/RNG/receipt/caps retained')

local report=os.getenv('LOD_B23_REPORT_PATH')
if report then local f=assert(io.open(report,'w'));f:write(table.concat(lines,'\n')..'\n');f:close() end
