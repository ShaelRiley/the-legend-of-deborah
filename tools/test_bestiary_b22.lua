-- Actual pacing/BuildPlan authorities; native collision remains a boundary double.
local H=dofile('tools/test_bestiary_b20.lua')
local D,Run=H.D,H.Run
local key=LOD.MazeGenerator.CellKey
local function corridor(seed)
 local g={Cells={},Progression={Gates={},Keycards={}},MasterLevelSeed=seed,LevelSeed=seed}
 local p={seed=seed,tags={},encounters={}}
 local function cell(x,y,sector)
  local k=key(x,y,0);g.Cells[k]={x=x,y=y,z=0,neighbors={}};p.tags[k]={sector=sector or 1,role='travel'}
  return g.Cells[k]
 end
 local function join(a,b) a.neighbors[key(b.x,b.y,b.z)]=true;b.neighbors[key(a.x,a.y,a.z)]=true end
 for x=0,100 do local c=cell(x,0);if x>0 then join(c,g.Cells[key(x-1,0,0)]) end end
 for y=1,6 do local c=cell(50,y);join(c,g.Cells[key(50,y-1,0)]) end
 g.Start=g.Cells[key(0,0,0)];g.Progression.Keycards={{cell=g.Cells[key(100,0,0)]}}
 g.CellTags=p.tags
 return g,p,cell,join
end
local profiles={surge={.10,.35,.80},ambush={.20,.45,.85},gauntlet={.10,.25,.85}}
local seen={}
for seed=1,30 do
 local g,p=corridor(seed);D:BeginPacing(p,g)
 local row=p.pacing.sectors[1];seen[row.phrase]=true
 assert(row.status=='ready' and row.length==100)
 local cuts=profiles[row.phrase]
 for x=0,100 do
  local expected=x<cuts[1]*100 and 'quiet' or x<cuts[2]*100 and 'probe'
   or x<cuts[3]*100 and 'pressure' or 'recovery'
  local pace=p.tags[key(x,0,0)].pacing
  assert(pace.beat==expected and pace.progress==x/100 and pace.detour==0,'ordered route bands')
  assert(D:PacingAllows(p,g.Cells[key(x,0,0)])==(expected=='probe' or expected=='pressure'))
 end
 assert(p.tags[key(50,3,0)].pacing.beat=='pressure')
 assert(p.tags[key(50,4,0)].pacing.beat=='spike','branch threshold')
 assert(p.tags[key(50,6,0)].pacing.detour==6 and p.tags[key(50,6,0)].pacing.progress==.5)
 local signature=H.serial(p.pacing)..H.serial(p.tags)
 D:BeginPacing(p,g);assert(signature==H.serial(p.pacing)..H.serial(p.tags),'phrase replay changed')
end
for id in pairs(profiles) do assert(seen[id],'phrase inaccessible: '..id) end
-- Real same-sector traversal: a shortcut through a different sector cannot
-- change the route, and closed gates/event edges cannot supply phantom progress.
local g,p,newCell,join=corridor(37)
local outside=newCell(0,1,2);join(g.Start,outside);join(outside,g.Cells[key(100,0,0)])
D:BeginPacing(p,g);assert(p.pacing.sectors[1].length==100,'cross-sector shortcut')
assert(next(D:_PlanningDistances(g,outside,p.tags,1))==nil,'foreign entrance supplied a route')
local edge=LOD.MazeNavigator:EdgeKey(key(40,0,0),key(41,0,0))
g.Progression.Gates={{edgeKey=edge}};Run.State.GatesOpen={false}
D:BeginPacing(p,g);assert(p.pacing.sectors[1].status=='disconnected')
assert(not D:PacingAllows(p,g.Cells[key(22,0,0)]) and not D:PacingAllows(p,g.Cells[key(50,4,0)]))
Run.State.GatesOpen={true};D:BeginPacing(p,g);assert(p.pacing.sectors[1].status=='ready')
local events=LOD.EventDirector
LOD.EventDirector={BlocksEdge=function(_,_,ek) return ek==edge end}
D:BeginPacing(p,g);assert(p.pacing.sectors[1].status=='disconnected');LOD.EventDirector=events
-- An entrance coincident with its goal has no phrase span, not a broken path.
g.Progression.Keycards={{cell=g.Start}}
D:BeginPacing(p,g);assert(p.pacing.sectors[1].status=='coincident' and not D:PacingAllows(p,g.Start))
-- A missing goal is a diagnosed developer/legacy fallback, not a permanent ban.
g.Progression.Keycards={};p.tags={};for k in pairs(g.Cells) do p.tags[k]={sector=1} end
D:BeginPacing(p,g);assert(p.pacing.sectors[1].status=='unavailable' and D:PacingAllows(p,g.Start))
-- Full production plans, enriched parties/depth: probes really shrink squads,
-- never strip their authored specialist/companions, and reservations affect homes.
local changed,shrunk,probes,pressure=0,0,0,0
local begin=D.BeginPacing
for seed=1,12 do
 Run.State={CampaignSeed=seed*7919,Level=20};H.setParty(4)
 local graph=H.prepare(seed*7919,20);local plan=H.build(graph);H.bounds(plan)
 local allPace=H.serial(plan.pacing)
 for _,enc in ipairs(plan.encounters) do
  if not enc.objective then
   assert(D:PacingAllows(plan,graph.Cells[enc.cellKey]),'reserved encounter home')
   local pace=enc.pacing
   assert(pace.beat==plan.tags[enc.cellKey].pacing.beat)
   if pace.beat=='probe' then
    probes=probes+1;assert(pace.scale==1)
    -- Same template and RNG; only enrichment differs. Current shared composition
    -- resolver still enforces the live singleton/companion rules.
    local richer=D:_TemplateComposition(enc.templateId,LOD.RNG.New(11),D:_ThreatScale())
    local count,full=0,0
    for id,n in pairs(enc.composition) do count=count+n;assert((richer[id] or 0)>=n) end
    for _,n in pairs(richer) do full=full+n end
    if full>count then shrunk=shrunk+1 end
    for id,n in pairs(LOD.Config.Encounter.Templates[enc.templateId].composition) do
     assert((enc.composition[id] or 0)>=n,'probe removed authored companion')
    end
   else pressure=pressure+1;assert(pace.scale==D:_ThreatScale()) end
  end
 end
 local replay=H.build(graph)
 assert(H.signature(plan)==H.signature(replay) and H.serial(replay.pacing)==allPace)
 D.BeginPacing=function(_,p)
  p.pacing={sectors={}}
  for s=1,4 do p.pacing.sectors[s]={status='unavailable',placed={},threat={}} end
 end
 local control=H.build(graph);D.BeginPacing=begin;H.bounds(control)
 assert(H.signature(control,true)==H.signature(plan,true),'pacing changed objectives')
 assert(control.ecology.theme==plan.ecology.theme,'pacing changed motif RNG')
 if H.signature(control,false)~=H.signature(plan,false) then changed=changed+1 end
end
assert(changed>=10 and shrunk>=10 and probes>=10 and pressure>=10,'metadata-only pacing')
print(string.format('BESTIARY_B22_PASS: three ordered phrases, exact branches, same-sector/gate/event isolation, fail-closed paths, deterministic plans, unchanged objectives/motif; changed=%d shrunk=%d probes=%d pressure=%d',changed,shrunk,probes,pressure))
