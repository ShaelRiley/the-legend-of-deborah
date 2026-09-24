-- Paired real production plans: 32 successive 20-dungeon campaigns. The paired
-- control keeps the same motif schedule and disables only template memory.
local reportLines={}
local function emit(line) reportLines[#reportLines+1]=line;print(line) end
local H=dofile('tools/test_bestiary_b20.lua')
local D,E,Run=H.D,H.E,H.Run
local sampled={'climber','razor','lurker','beamsweeper','flamer','arccaster','sentry','bigcrab','nodule','gaoler','silencer','repulsor','stitcher','bulwark','cantor','pincer','harrier','waylayer','pavise','repriser','redliner','caromer','reeler','forker','wirewright','snarer','cordon','reaper','drubber','fencer','afterburst','carrion','towline','screenwright','censer','trailmaker','listener','shy','absolver','exactor','outrider','conductor','siphoner','accumulator','fusilier','bombardier','halter','pacer','interposer','mourner','censor','surveyor','relay','lacemaker'}
local wanted={};for _,id in ipairs(sampled) do wanted[id]=true end
local function size(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function add(t,k,n) t[k]=(t[k] or 0)+(n or 1) end
local function stats() return {planned={},legal={},early={},themes={},templates={},families={},coverage={},repeatedTemplates=0,consecutiveOverlap=0,overlapPairs=0,encounters=0,exactLevelRepeats=0,crossLevelTemplateReturns=0} end
local full,control=stats(),stats()
local spatial={checked=0,preferred=0,rejected=0,fit={}}
local function observe(s,plan,graph,seen,prior)
 local roster,templates={},{}
 add(s.themes,plan.ecology.theme)
 for _,enc in ipairs(plan.encounters) do
  s.encounters=s.encounters+1
  if not enc.objective then
   local distances=D:_PlanningDistances(graph,enc.cell)
   for _,other in ipairs(plan.encounters) do
    if other~=enc then assert((distances[other.cellKey] or math.huge)>=LOD.Config.Encounter.MajorSpacingCells,'B21 spacing violated') end
   end
   assert(D:TemplateFitsCell(enc.templateId,graph,graph.Cells[enc.cellKey],enc.role),'B21 selected physically inadmissible squad')
   if s==full then
    local decision=assert(enc.ecologyDecision)
    spatial.checked=spatial.checked+1;spatial.rejected=spatial.rejected+decision.rejected
    if decision.preference>1 then spatial.preferred=spatial.preferred+1 end
    add(spatial.fit,decision.fit)
   end
  end
  if not enc.objective then
   add(s.templates,enc.templateId);add(templates,enc.templateId)
   if templates[enc.templateId]>1 then s.repeatedTemplates=s.repeatedTemplates+1 end
  end
  for id,n in pairs(enc.composition) do
   assert(LOD.Config.Encounter.Archetypes[id],'unsupported archetype '..id)
   add(s.planned,id,n);add(s.families,D.EcologyCatalog.families[id] or id,n)
   if wanted[id] then seen[id]=true end
   if not enc.objective then roster[id]=true end
   if E.Definitions[id] and E:Placement(graph,graph.Cells[enc.cellKey],id,enc.role) then
    add(s.legal,id,n);if enc.sector<=2 then add(s.early,id,n) end
   end
  end
 end
 if prior then
  for id,n in pairs(templates) do
   if prior.templates[id] then s.crossLevelTemplateReturns=s.crossLevelTemplateReturns+n end
  end
  local union,intersection=0,0
  for id in pairs(roster) do union=union+1;if prior.roster[id] then intersection=intersection+1 end end
  for id in pairs(prior.roster) do if not roster[id] then union=union+1 end end
  s.consecutiveOverlap=s.consecutiveOverlap+(union>0 and intersection/union or 0)
  s.overlapPairs=s.overlapPairs+1
  if H.serial(templates)==H.serial(prior.templates) then s.exactLevelRepeats=s.exactLevelRepeats+1 end
 end
 return {roster=roster,templates=templates}
end
local minimum=math.huge
local selectWithMemory=D.SelectEcologyTemplate
for campaign=1,32 do
 local campaignSeed=campaign*7919
 Run.State={CampaignSeed=campaignSeed,Level=1}
 local seen,controlSeen,previous,controlPrevious={},{},nil,nil
 for level=1,20 do
  H.setParty((campaign+level-2)%4+1)
  local graph=H.prepare(campaignSeed,level)
  local baselineHistory=H.serial(Run.State.EncounterEcology)
  local plan=H.build(graph);H.bounds(plan)
  for i=math.max(1,#plan.ecology.before.recent-1),#plan.ecology.before.recent do
   assert(plan.ecology.before.recent[i].theme~=plan.ecology.theme,'theme repeated in campaign '..campaign..' level '..level)
  end
  local actual=H.signature(plan)
  -- Disable template scoring memory only; retain theme selection and the same
  -- bounded within-level suppression. Production lifecycle is otherwise intact.
  D.SelectEcologyTemplate=function(self,p,choices,rng,sector,graph,cell)
   local before=p.ecology.before
   p.ecology.before={themes={},templates={},enemies={},families={},recent={}}
   local id=selectWithMemory(self,p,choices,rng,sector,graph,cell)
   p.ecology.before=before;return id
  end
  local paired=H.build(graph);H.bounds(paired)
  D.SelectEcologyTemplate=selectWithMemory
  assert(paired.ecology.theme==plan.ecology.theme,'control changed motif schedule')
  assert(H.signature(paired,true)==H.signature(plan,true),'ecology changed guaranteed objective content')
  assert(H.serial(Run.State.EncounterEcology)==baselineHistory,'control changed committed history')
  previous=observe(full,plan,graph,seen,previous)
  controlPrevious=observe(control,paired,graph,controlSeen,controlPrevious)
  -- Replay one populated-history level per campaign (plus the focused unit
  -- cases), rather than regenerating all 640 already-tested pure plans.
  if level==10 then
   local replay=H.build(graph)
   assert(H.signature(replay)==actual and replay.ecology.theme==plan.ecology.theme,
    'paired control perturbed production randomness')
  end
  -- The comparison never committed history or changed run/graph/seed identity.
  -- Restore the captured actual plan and commit its exact original receipt.
  -- This removes a redundant full plan; it does not model or copy any receipt.
  assert(H.serial(Run.State.EncounterEcology)==baselineHistory,'replay advanced campaign memory')
  D.Plan=plan;graph.EncounterPlan=plan;graph.CellTags=plan.tags
  assert(D:CommitEcologyPlan(graph),'campaign commit rejected')
  assert(#Run.State.EncounterEcology.after.recent<=3,'campaign memory grew unbounded')
 end
 full.coverage[#full.coverage+1]=size(seen);control.coverage[#control.coverage+1]=size(controlSeen)
 minimum=math.min(minimum,size(seen))
 emit(string.format('B20_CAMPAIGN id=%d coverage=%d controlCoverage=%d',campaign,size(seen),size(controlSeen)))
end
local function report(label,s)
 local total,min=0,math.huge;for _,n in ipairs(s.coverage) do total=total+n;min=math.min(min,n) end
 emit(string.format('B20_COMPARISON mode=%s campaigns=32 plans=640 encounters=%d meanCoverage=%.3f minCoverage=%d meanConsecutiveJaccard=%.6f withinLevelTemplateRepeats=%d exactConsecutiveTemplateSets=%d crossLevelTemplateReturns=%d',label,s.encounters,total/32,min,s.consecutiveOverlap/s.overlapPairs,s.repeatedTemplates,s.exactLevelRepeats,s.crossLevelTemplateReturns))
 emit('B20_THEMES '..label..' '..H.serial(s.themes))
 emit('B20_TEMPLATES '..label..' '..H.serial(s.templates))
 emit('B20_FAMILIES '..label..' '..H.serial(s.families))
end
report('memory',full);report('control',control)
emit('B21_SPATIAL '..H.serial(spatial))
local aggregate,controlAggregate=0,0
for i,n in ipairs(full.coverage) do aggregate=aggregate+n;controlAggregate=controlAggregate+control.coverage[i] end
print(string.format('B20_NOVELTY aggregate=%d controlAggregate=%d coverageLift=%.6f',aggregate,controlAggregate,aggregate/controlAggregate-1))
for _,id in ipairs(sampled) do emit(string.format('B20_EXPOSURE %s planned=%d legal=%d early=%d',id,full.planned[id] or 0,full.legal[id] or 0,full.early[id] or 0)) end
assert(aggregate>controlAggregate,'campaign memory failed to improve aggregate specialist coverage')
local reportPath=os.getenv('LOD_B20_REPORT_PATH')
if reportPath then
 local file=assert(io.open(reportPath,'w'));file:write(table.concat(reportLines,'\n')..'\n');file:close()
end
assert(size(full.themes)==6,'not all six motifs selected')
assert(minimum>=36,'campaign coverage below 36/54: '..minimum)
for _,id in ipairs(sampled) do
 assert((full.planned[id] or 0)>=25,id..' planned exposure below25')
 assert((full.legal[id] or 0)>=20,id..' legal exposure below20')
 assert((full.early[id] or 0)>=5,id..' early exposure below5')
end
print('BESTIARY_B20_CAMPAIGN_PASS: 32x20 actual sequential plans, six motifs, no two-level repeats, >=36/54 each campaign, 54 exposure floors, paired memory control, objectives/admissions invariant')
