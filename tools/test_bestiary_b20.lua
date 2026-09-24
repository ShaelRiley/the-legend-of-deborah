-- B20 real-plan transaction boundaries. Only native Source traces are doubled.
dofile('tools/test_enemy_roster.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
-- Load every live ordinary template provider. The roster harness alone omits
-- four pre-Bestiary identities and would overstate specialist exposure.
timer.Create=function() end -- native recurring scheduling, unused during planning
for _,module in ipairs({'sv_deadcrab.lua','sv_bioblaster.lua','sv_watcher.lua','sv_seeker.lua'}) do dofile(root..module) end
dofile(root..'sh_rng.lua');dofile(root..'sv_maze_generator.lua');dofile(root..'sv_progression_director.lua')
dofile(root..'sv_m3_run_integration.lua')
dofile(root..'sv_encounter_ecology_catalog.lua');dofile(root..'sv_encounter_ecology.lua')
local D,E,Run=LOD.EncounterDirector,LOD.EnemyRoster,LOD.RunManager
local EC=LOD.Config.Encounter
local eligible={}
for sector=1,4 do
 for _,role in ipairs({'arena','ambush','reward','corridor'}) do
  for _,id in ipairs(D:_EligibleTemplates(sector,role)) do
   eligible[id]=true
   assert(EC.Templates[id] and not EC.Templates[id].objective,'invalid discretionary template '..id)
  end
 end
end
local themed,common=0,0
local allowed={}
for _,theme in pairs(D.EcologyCatalog.themes) do
 for id in pairs(theme.templates) do
  allowed[id]=true
  assert(EC.Templates[id],'unregistered themed template '..id)
  assert(eligible[id],'unreachable themed template '..id)
  for enemy in pairs(EC.Templates[id].composition) do
   assert(EC.Archetypes[enemy],'unregistered themed archetype '..enemy)
   assert(D.EcologyCatalog.families[enemy],'unmapped ordinary archetype '..enemy)
  end
  themed=themed+1
 end
end
for id in pairs(D.EcologyCatalog.common) do allowed[id]=true;assert(EC.Templates[id] and eligible[id],'unregistered/unreachable common template '..id);common=common+1 end
for _,id in ipairs({'deadcrab_nest','bio_pressure','surveillance','incoming'}) do assert(eligible[id],'missing actual legacy template '..id) end
for id in pairs(eligible) do
 assert(allowed[id],'ordinary eligible path escaped catalog (boss/event/objective): '..id)
 for enemy in pairs(EC.Templates[id].composition) do assert(D.EcologyCatalog.families[enemy],'nonordinary enemy admitted: '..enemy) end
end
print('B20_FULL_BOOTSTRAP_PASS themed='..themed..' common='..common)
local party=1;Run._ActiveCount=function() return party end
D.Entities={}
util.TraceHull=function(t) return {Hit=false,StartSolid=false,HitPos=t.endpos} end
util.TraceLine=function(t)
 local delta=t.endpos-t.start
 if delta.z>200 then return {Hit=true,HitPos=t.start+Vector(0,0,250),HitNormal=Vector(0,0,-1),Fraction=.5} end
 local n=delta:Length();local f=n>320 and 320/n or 1
 return {Hit=f<1,HitPos=t.start+delta*f,HitNormal=Vector(0,0,1),Fraction=f,StartSolid=false}
end
local function serial(t)
 if type(t)~='table' then return tostring(t) end
 local keys,rows={},{};for k in pairs(t) do keys[#keys+1]=k end
 table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
 for _,k in ipairs(keys) do rows[#rows+1]=tostring(k)..'='..serial(t[k]) end
 return '{'..table.concat(rows,',')..'}'
end
local function signature(plan,objective)
 local rows={}
 for _,enc in ipairs(plan.encounters) do
  if objective==nil or enc.objective==objective then
   rows[#rows+1]=table.concat({enc.cellKey,enc.templateId,enc.role,enc.sector,serial(enc.composition)},':')
  end
 end
 return table.concat(rows,';')
end
local function graphFor(seed)
 for attempt=1,LOD.Config.Progression.LayoutAttempts do
  local layout=attempt==1 and seed or LOD.Seeds.Derive(seed,'progression-layout:'..attempt)
  local graph=LOD.MazeGenerator:Generate(layout)
  if graph then
   graph.MasterLevelSeed=seed;graph.ProgressionLayoutAttempt=attempt
   if LOD.ProgressionDirector:Plan(graph,seed) then return graph end
  end
 end
 error('canonical layout retries exhausted for '..seed)
end
local function prepare(campaign,level)
 Run.State.Level=level;Run.State.LevelSeed=LOD.Seeds.DeriveLevel(campaign,level)
 local graph=graphFor(Run.State.LevelSeed);Run.State.Graph=graph;Run.State.GatesOpen={}
 for i in ipairs(graph.Progression.Gates) do Run.State.GatesOpen[i]=true end
 return graph
end
local function build(graph)
 local before=serial(Run.State.EncounterEcology)
 local globalRandom=math.random
 math.random=function() error('ecology/planner consumed global random stream') end
 local ok,plan=D:BuildPlan(graph);math.random=globalRandom;assert(ok,plan)
 assert(serial(Run.State.EncounterEcology)==before,'prospective plan mutated campaign memory')
 assert(plan.ecology and plan.ecologyReceipt,'production planner omitted ecology')
 return plan
end
local function bounds(plan)
 local counts,spent={},{}
 for _,enc in ipairs(plan.encounters) do
  assert(LOD.Config.Encounter.Templates[enc.templateId],'unsupported template')
  for id in pairs(enc.composition) do assert(LOD.Config.Encounter.Archetypes[id],'unsupported enemy '..id) end
  if not enc.objective then
   counts[enc.sector]=(counts[enc.sector] or 0)+1
   spent[enc.sector]=(spent[enc.sector] or 0)+enc.threat
   -- The retained planner admits a first encounter even above budget; later
   -- encounters may consume at most the existing half-point allowance.
   assert((spent[enc.sector]<=plan.sectorBudget[enc.sector]+.5) or counts[enc.sector]==1,'threat exceeded retained admission allowance')
  end
 end
 for sector,n in pairs(counts) do
  assert(n<=LOD.Config.Encounter.MaxDiscretionaryPerSector[sector],'discretionary count ceiling')
  assert(math.abs(spent[sector]-plan.sectorSpent[sector])<.00001,'budget accounting mismatch')
 end
end
Run.State={CampaignSeed=90123,CampaignEpoch=1,RunId=1,Level=1}
local graph=prepare(90123,1)
local independent=LOD.RNG.New(777);local originalState=independent.state
local plan=build(graph);bounds(plan)
assert(independent.state==originalState,'planning consumed unrelated random stream')
local a=signature(plan);local theme=plan.ecology.theme
local repeated=build(graph)
assert(signature(repeated)==a and repeated.ecology.theme==theme,'identical input changed plan')
-- An obsolete plan cannot commit over the newly planned graph receipt.
graph.EncounterPlan=plan
assert(not D:CommitEcologyPlan(graph),'accepted obsolete director plan')
graph.EncounterPlan=repeated
local state=Run.State
local replacement={};for k,v in pairs(state) do replacement[k]=v end
Run.State=replacement;assert(not D:CommitEcologyPlan(graph),'accepted different run identity');Run.State=state
local old=state.Graph;state.Graph={};assert(not D:CommitEcologyPlan(graph),'accepted different active graph');state.Graph=old
for _,field in ipairs({'Level','LevelSeed','CampaignSeed','CampaignEpoch','RunId'}) do
 local value=state[field];state[field]=value+1
 assert(not D:CommitEcologyPlan(graph),'accepted stale '..field);state[field]=value
end
for _,field in ipairs({'MasterLevelSeed','LevelSeed'}) do
 local value=graph[field];graph[field]=(value or 0)+1
 assert(not D:CommitEcologyPlan(graph),'accepted changed graph '..field);graph[field]=value
end
Run.State=nil;assert(not D:CommitEcologyPlan(graph),'accepted absent run state');Run.State=state
local prior=state.EncounterEcology;state.EncounterEcology={}
assert(not D:CommitEcologyPlan(graph),'accepted changed previous receipt');state.EncounterEcology=prior
local heldReceipt=repeated.ecologyReceipt
assert(D:CommitEcologyPlan(graph),'valid receipt failed commit')
assert(heldReceipt.graph==nil and heldReceipt.state==nil,'committed receipt retained live graph/run references')
assert(not D:CommitEcologyPlan(graph),'same receipt committed twice')
local early={}
for _,enc in ipairs(repeated.encounters) do
 if not enc.objective and enc.sector<=2 then early[enc.templateId]=1 end
end
assert(serial(state.EncounterEcology.after.earlyTemplates)==serial(early),'early introduction memory includes late-only/objective squads')
local committed=serial(state.EncounterEcology)
local rebuilt=build(graph)
assert(signature(rebuilt)==a and rebuilt.ecology.theme==theme,'same-level rebuild advanced history')
assert(D:CommitEcologyPlan(graph),'same-level rebuild failed replacement')
assert(serial(state.EncounterEcology)==committed,'same-level rebuild double counted memory')
D:Cleanup();assert(serial(state.EncounterEcology)==committed,'encounter cleanup erased campaign memory')
for level=2,21 do
 local g=prepare(90123,level);local p=build(g);bounds(p)
 local before=p.ecology.before
 for i=math.max(1,#before.recent-1),#before.recent do
  assert(before.recent[i].theme~=p.ecology.theme,'theme repeated within two successful levels')
 end
 assert(D:CommitEcologyPlan(g),'level '..level..' failed commit')
 assert(#state.EncounterEcology.after.recent==math.min(3,level),'unbounded recent history')
end
local function valueOnly(t)
 for k,v in pairs(t) do
  assert(type(k)=='number' or type(k)=='string','history key is reference')
  assert(type(v)=='number' or type(v)=='string' or type(v)=='boolean' or type(v)=='table','history retained unsupported value')
  if type(v)=='table' then assert(v~=Run.State and v~=Run.State.Graph,'history retained live authority');valueOnly(v) end
 end
end
valueOnly(state.EncounterEcology)
Run.State={CampaignSeed=90123,CampaignEpoch=1,RunId=1,Level=1};graph=prepare(90123,1)
local fresh=build(graph);assert(signature(fresh)==a and fresh.ecology.theme==theme,'same-seed new campaign inherited memory')
print('BESTIARY_B20_PASS: real-plan purity, repeatability, exact run/graph/level/seed receipt, one-time commit, rebuild, cleanup, bounded level21 history, reset, objectives/budgets retained')
return {D=D,E=E,Run=Run,serial=serial,signature=signature,prepare=prepare,build=build,bounds=bounds,setParty=function(n) party=n end}
