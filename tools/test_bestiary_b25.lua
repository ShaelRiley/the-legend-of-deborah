-- Production plans, population and service; only Source boundaries are doubled.
local T=dofile('tools/test_bestiary_b23.lua')
local H,W=T.H,T.W
local D,Run=H.D,H.Run
local lines={};local output=print
local function report(s) lines[#lines+1]=s;output(s) end
local function size(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function bodies() local n=0;for _,e in ipairs(W.Entities) do if IsValid(e) and not e.LODDead then n=n+1 end end;return n end
local profile=D.IntensityProfile
local stats={}
local begin=D.BeginEcology
local serviceOnly=arg and arg[1]=='service'
if not serviceOnly then
for seed=1,32 do
 H.setParty((seed-1)%4+1)
 Run.State={CampaignSeed=seed*7919,CampaignEpoch=1,RunId=1,Level=8}
 local graph=H.prepare(seed*7919,8)
 Run.State.BuildReady=true
 for _,motif in ipairs({"corruption","crossfire","hunting","occupation","quarantine","retinue"}) do
 D.BeginEcology=function(self,p,g) begin(self,p,g);p.ecology.theme=motif;p.ecology.name=self.EcologyCatalog.themes[motif].name end
 local plan=H.build(graph)
 H.bounds(plan)
 local theme=plan.ecology.theme
 local row=stats[theme] or {pairs=0,pacing=0,homes=0,increased=0,bodies=0,control=0,phrases={}}
 stats[theme]=row;row.pairs=row.pairs+1
 for _,s in ipairs(plan.pacing.sectors) do row.phrases[s.phrase]=(row.phrases[s.phrase] or 0)+1 end
 local sig=H.signature(plan);local pacing=H.serial(plan.pacing)
 local receipt=H.serial(Run.State.EncounterEcology)
 local replay=H.build(graph)
 assert(H.signature(replay)==sig and H.serial(replay.pacing)==pacing,'intensity replay')
 D.IntensityProfile=function(self) return self.EcologyCatalog.legacyIntensity end
 local control=H.build(graph);H.bounds(control)
 D.IntensityProfile=profile
 assert(control.ecology.theme==theme,'intensity changed theme RNG')
 assert(H.signature(control,true)==H.signature(plan,true),'intensity changed objectives')
 if H.serial(control.pacing)~=pacing then row.pacing=row.pacing+1 end
 if H.signature(control,false)~=H.signature(plan,false) then row.homes=row.homes+1 end
 -- Population comparison uses IDENTICAL plan/pacing/pools and only changes target.
 graph.EncounterPlan=plan;graph.CellTags=plan.tags;D.Plan=plan
 T.init(graph);T.bounds(graph)
 local n=bodies();row.bodies=row.bodies+n
 local first=T.signature();T.init(graph);assert(T.signature()==first,'initial intensity replay')
 assert(W:GetTargetPopulation(graph)==W:GetFloorTarget(graph)*(graph.WanderLayers or graph.Layers))
 local wp=W.IntensityProfile
 W.IntensityProfile=function() return D.EcologyCatalog.legacyIntensity end
 T.init(graph);T.bounds(graph);local baseline=bodies();row.control=row.control+baseline
 W.IntensityProfile=wp
 assert(n>=baseline,'raised target lost bodies')
 if n>baseline then row.increased=row.increased+1 end
 assert(H.serial(Run.State.EncounterEcology)==receipt and H.signature(plan)==sig,'intensity consumed history/plan')
 end
end
D.BeginEcology=begin
assert(size(stats)==6,'fixed sample missed a motif')
for theme,row in pairs(stats) do
 report('B25_PAIRED '..theme..' '..H.serial(row))
 assert(row.pacing>0 and row.homes>0,'motif has no actual pacing/home effect '..theme)
 assert(row.increased>0,'B27 raised density has no actual effect '..theme)
end
end

local graph,plan=T.prepare(191919,8)
plan.ecology.theme='retinue'
assert(D:CommitEcologyPlan(graph))
local receipt=H.serial(Run.State.EncounterEcology)
T.setTime(0);T.init(graph)
local floor=W.Entities[1].LODWanderFloor
for _,e in ipairs(W.Entities) do if e.LODWanderFloor==floor then e:Remove() end end
local target=W:GetFloorTarget(graph)
assert(target==math.min(18,math.floor(64/(graph.WanderLayers or graph.Layers))) and W:GetDeficitReservation(graph)>=target,'target/reservation mismatch')
local rejected,accepted
for ordinal=1,100 do
 if W:ReplacementAllowed(graph,floor,ordinal) then accepted=accepted or ordinal else rejected=rejected or ordinal end
end
assert(rejected and accepted,'fixture needs both outcomes')
W.ReplacementOrdinal[floor]=rejected-1
local before=W.SpawnOrdinal[floor]
T.quiet(function() W:Think() end)
local due=W.NextRespawn[floor];assert(due==20,'changed opportunity cadence')
T.setTime(19);T.quiet(function() W:Think() end)
assert(W.SpawnOrdinal[floor]==before,'early replacement')
T.setTime(20);T.quiet(function() W:Think() end)
assert(W.Diagnostics[floor]=='motif_wait' and W.SpawnOrdinal[floor]==before,'rejection consumed spawn ordinal')
assert(W:_LivingOnFloor(floor)==0 and W.NextRespawn[floor]==40,'rejection did not wait')
for _,flag in ipairs({'SimulationFrozen','Failed','LevelCleared','BuildReady'}) do
 local old=Run.State[flag];Run.State[flag]=flag~='BuildReady'
 T.setTime(100);T.quiet(function() W:Think() end)
 assert(W.ReplacementOrdinal[floor]==rejected,'inactive service consumed opportunity')
 Run.State[flag]=old
end
W.ReplacementOrdinal[floor]=accepted-1
T.setTime(1000);T.quiet(function() W:Think() end)
assert(W:_LivingOnFloor(floor)==1 and W.ReplacementOrdinal[floor]==accepted,'late service caught up or failed to spawn')
assert(W.NextRespawn[floor]==1020,'late service failed to reschedule')
assert(W:_LivingOnFloor(floor)<=target and D:GetActiveCount()<=96,'service exceeded cap')
local count=W.SpawnOrdinal[floor]
-- A permitted replacement still has to pass the real physical boundary.
util.TraceHull=function() return {Hit=true} end
W.ReplacementOrdinal[floor]=accepted-1;T.setTime(1020);T.quiet(function() W:Think() end)
util.TraceHull=T.traceHull
assert(W.Diagnostics[floor]=='no_legal_home' and W.SpawnOrdinal[floor]==count+1,'physical defer bypassed')
assert(W:_LivingOnFloor(floor)==1 and W.NextRespawn[floor]==1040)
assert(H.serial(Run.State.EncounterEcology)==receipt,'replacement mutated receipt')
-- Native reset during Think must not reinstall a deadline/ordinal on the retired owner.
W.ReplacementOrdinal[floor]=accepted-1;T.setMode('reset');T.setTime(1040)
T.quiet(function() W:Think() end);T.setMode(nil)
assert(W.Owner==nil and next(W.ReplacementOrdinal)==nil and next(W.NextRespawn)==nil,'retired service resurrected')
plan.ecology.theme='unknown';T.init(graph)
assert(W:GetFloorTarget(graph)==16 and W:ReplacementAllowed(graph,0,1),'legacy fallback changed')
plan.ecology=nil;assert(W:GetFloorTarget(graph)==16,'missing ecology fallback changed')
T.init(graph);D:Cleanup();assert(next(W.ReplacementOrdinal)==nil,'cleanup retained opportunity RNG')
report('B25_LIFECYCLE_PASS targets/reservations; real due service; reject/no-spawn-ordinal; frozen/inactive; no catch-up; physical defer; reentrant reset; legacy fallback; receipt')

-- Fixed opportunity sampling is not a native-spawn sample. Capture production
-- gate outcomes before loading the independent real progression harness.
plan.ecology={theme='retinue'};graph.EncounterPlan=plan
local samples={};Run.State.LevelSeed=7919
local random=math.random;math.random=function() error('global RNG consumed') end
for theme,p in pairs(D.EcologyCatalog.intensity) do
 plan.ecology.theme=theme
 local row={chance=p.replacementChance,accepted={},count=0};samples[theme]=row
 for ordinal=1,4096 do
  local allowed=W:ReplacementAllowed(graph,0,ordinal)
  assert(allowed==W:ReplacementAllowed(graph,0,ordinal),'opportunity replay')
  row.accepted[ordinal]=allowed
  if allowed then row.count=row.count+1 end
 end
 assert(math.abs(row.count/4096-row.chance)<.03,'replacement rate '..theme..':'..row.count)
end
math.random=random
dofile('tools/test_actor_progression.lua')
local C=LOD.CharacterProgressionSystem
local tiers={typical=0,elite=0,champion=0}
for roll=1,100 do local tier=C:TierForRoll(roll);tiers[tier]=tiers[tier]+1 end
assert(tiers.typical==60 and tiers.elite==30 and tiers.champion==10,'tier law changed')
for id,expected in pairs({neil='typical',brute='elite',warden='champion',hector='champion'}) do
 local level,tier=C:ResolveMonsterSpawnLevel(123,12,id)
 assert(tier==expected and level==16+(tier=='typical' and 0 or tier=='elite' and 1 or 2),'named/depth grade changed')
end
local rates={}
for theme,row in pairs(samples) do
 local counts={typical=0,elite=0,champion=0};local n=0
 for ordinal=1,4096 do
  if row.accepted[ordinal] then
   n=n+1
   -- The conditional law is tested through its real authority on independent
   -- actor seeds; native instance identity/HP/XP remain inherited regressions.
   local seed=LOD.Seeds.Derive(7919,'b25:actor:'..ordinal)
   local level,tier=C:ResolveMonsterSpawnLevel(seed,12,'shambler')
   local _,replay=C:ResolveMonsterSpawnLevel(seed,12,'shambler');assert(tier==replay)
   assert(level>=16 and level<=18,'ordinary depth grade changed')
   counts[tier]=counts[tier]+1
  end
 end
 for tier,p in pairs({typical=.6,elite=.3,champion=.1}) do assert(math.abs(counts[tier]/n-p)<.03,'conditional tier rate '..theme..':'..tier..':'..counts[tier]..'/'..n) end
 local rate=counts.elite/4096;rates[theme]=rate
 assert(math.abs(rate-.3*row.chance)<.03,'Elite opportunity exposure '..theme)
 report(string.format('B25_OPPORTUNITIES %s trials=4096 allowed=%d rate=%.6f tiers=%d/%d/%d eliteArrivalRate=%.6f design=%.3f',theme,n,n/4096,counts.typical,counts.elite,counts.champion,rate,.3*row.chance))
end
assert(rates.retinue<rates.crossfire and rates.crossfire<rates.corruption and rates.corruption<rates.hunting and rates.hunting<rates.occupation,'Elite opportunity exposure ordering')
report((serviceOnly and 'BESTIARY_B25_SERVICE_PASS' or 'BESTIARY_B25_PASS 32x6 paired production plans; actual density/pacing;')..' bounded live replacement; 4096 opportunities/motif; canonical conditional tiers and named grades; Source acceptance pending')
local path=os.getenv('LOD_B25_REPORT_PATH')
if path then local f=assert(io.open(path,'w'));f:write(table.concat(lines,'\n')..'\n');f:close() end
