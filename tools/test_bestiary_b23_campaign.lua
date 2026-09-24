local T=dofile('tools/test_bestiary_b23.lua')
local lines={}
local output=print
local function print(line) lines[#lines+1]=line;output(line) end
local H,W=T.H,T.W
local D,Run=H.D,H.Run
local counts,themes,changed,totals={},{},{},{spawned=0,legacy=0,fullFloors=0,floors=0}
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
   if W:_LivingOnFloor(f)==16 then totals.fullFloors=totals.fullFloors+1 end
  end
 end
end
for campaign=1,32 do
 local seed=campaign*7919
 Run.State={CampaignSeed=seed,CampaignEpoch=1,RunId=1,Level=1}
 for level=1,20 do
  H.setParty((campaign+level-2)%4+1)
  local graph=H.prepare(seed,level);local plan=H.build(graph);H.bounds(plan)
  Run.State.BuildReady=true;Run.State.Failed=false;Run.State.LevelCleared=false;Run.State.SimulationFrozen=false
  assert(D:CommitEcologyPlan(graph))
  local receipt=H.serial(Run.State.EncounterEcology);local before=H.signature(plan)
  local theme=plan.ecology.theme;themes[theme]=(themes[theme] or 0)+1
  local random=math.random;math.random=function() error('global RNG consumed') end
  T.init(graph);observe(graph,'spawned');local first=T.signature()
  if level==10 then T.init(graph);assert(T.signature()==first,'campaign spawn replay failed') end
  -- Same topology/plan/seed and safeguards; disable only motif pool selection.
  local pool=W._Pool;W._Pool=function() return W.Config.ArchetypeWeights,'legacy' end
  T.init(graph);observe(graph,'legacy')
  if T.signature()~=first then changed[theme]=(changed[theme] or 0)+1 end
  W._Pool=pool;math.random=random
  assert(H.serial(Run.State.EncounterEcology)==receipt,'wandering consumed campaign memory')
  assert(H.signature(plan)==before,'wandering changed encounter plan')
 end
 print('B23_CAMPAIGN id='..campaign..' cumulativeSpawned='..totals.spawned)
end
for id in pairs(T.new) do assert((counts[id] or 0)>=25,'new specialist exposure below25 '..id) end
for theme in pairs(W.Config.Pools) do assert((changed[theme] or 0)>0,'motif has no actual production influence '..theme) end
for _,id in ipairs((function() local a={} for id in pairs(counts) do a[#a+1]=id end table.sort(a);return a end)()) do
 print('B23_EXPOSURE '..id..' spawned='..counts[id])
end
for theme,n in pairs(themes) do print('B23_MOTIF '..theme..' dungeons='..n..' changed='..(changed[theme] or 0)) end
print('BESTIARY_B23_CAMPAIGN_PASS dungeons=640 spawned='..totals.spawned..' legacy='..totals.legacy..' fullFloors='..totals.fullFloors..' floors='..totals.floors..' safety/caps/receipt/plan/RNG/replay retained')

local report=os.getenv('LOD_B23_REPORT_PATH')
if report then local f=assert(io.open(report,'w'));f:write(table.concat(lines,'\n')..'\n');f:close() end
