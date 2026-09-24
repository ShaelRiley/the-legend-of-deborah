-- Actual topology/selection/plan methods; only native traces/entities doubled.
local H=dofile('tools/test_bestiary_b20.lua')
local D,E,Run=H.D,H.E,H.Run
local N=LOD.MazeNavigator
local key=LOD.MazeGenerator.CellKey
local EC=LOD.Config.Encounter
local function fixture(points,edges)
 local g={Cells={},Progression={Gates={},Keycards={}},VerticalEdges={}}
 local p={tags={},encounters={}}
 for _,a in ipairs(points) do
  local c={x=a[1],y=a[2],z=a[3] or 0,neighbors={}};local k=key(c.x,c.y,c.z)
  g.Cells[k]=c;p.tags[k]={sector=2,role='ambush'}
 end
 for _,pair in ipairs(edges) do
  local a,b=points[pair[1]],points[pair[2]]
  local ak,bk=key(a[1],a[2],a[3] or 0),key(b[1],b[2],b[3] or 0)
  g.Cells[ak].neighbors[bk]=true;g.Cells[bk].neighbors[ak]=true
 end
 g.CellTags=p.tags
 return g,p,g.Cells[key(points[1][1],points[1][2],points[1][3] or 0)]
end
local g,p,c=fixture({{0,0},{1,0},{2,0},{3,0},{-1,0}},{{1,2},{2,3},{3,4},{1,5}})
local t=D:EncounterTopology(g,p,c)
assert(t.approaches==2 and t.corridor==3 and not t.corner and not t.junction and not t.alternate and not t.vertical)
assert(t.firingLane and D:TopologyPreference('sniper_firing_line',t)==2)
assert(D:TopologyPreference('nodule_gas',t)==1.5)
local oldLine=util.TraceLine
util.TraceLine=function(q) return {Hit=true,StartSolid=false,HitPos=q.start} end
local occluded=D:EncounterTopology(g,p,c)
assert(not occluded.firingLane and D:TopologyPreference('sniper_firing_line',occluded)==1)
util.TraceLine=oldLine
-- A declared but closed gate is not an approach, lane, retreat or alternate.
g.Progression.Gates={{edgeKey=N:EdgeKey(key(0,0,0),key(1,0,0))}}
Run.State.GatesOpen={false}
t=D:EncounterTopology(g,p,c);assert(t.approaches==1 and t.corridor==1)
Run.State.GatesOpen={true};t=D:EncounterTopology(g,p,c);assert(t.approaches==2 and t.corridor==3)
-- Blocking an event edge uses the same navigation authority.
local oldEvent=LOD.EventDirector
LOD.EventDirector={BlocksEdge=function(_,_,edge) return edge==N:EdgeKey(key(0,0,0),key(1,0,0)) end}
assert(D:EncounterTopology(g,p,c).approaches==1);LOD.EventDirector=oldEvent
-- A square supplies a real alternate, unlike the two disconnected branches.
g,p,c=fixture({{0,0},{1,0},{0,1},{1,1}},{{1,2},{1,3},{2,4},{4,3}})
t=D:EncounterTopology(g,p,c)
assert(t.corner and t.alternate and not t.junction)
assert(D:TopologyPreference('listener_detail',t)==2 and D:TopologyPreference('pincer_detail',t)==2)
g.Cells[key(1,1,0)].neighbors[key(0,1,0)]=nil;g.Cells[key(0,1,0)].neighbors[key(1,1,0)]=nil
assert(not D:EncounterTopology(g,p,c).alternate)
-- A junction is not automatically a loop. A reachable upper edge counts;
-- merely having an upper cell with no connecting edge does not.
g,p,c=fixture({{0,0},{1,0},{-1,0},{0,1},{1,0,1}},{{1,2},{1,3},{1,4}})
t=D:EncounterTopology(g,p,c);assert(t.junction and not t.alternate and not t.vertical)
g.Cells[key(1,0,0)].neighbors[key(1,0,1)]=true;g.Cells[key(1,0,1)].neighbors[key(1,0,0)]=true
t=D:EncounterTopology(g,p,c);assert(t.vertical)
assert(D:TopologyPreference('climber_wall',t)==2 and D:TopologyPreference('stitcher_detail',t)==1.5)
p.tags[key(1,0,1)].sector=3;assert(not D:EncounterTopology(g,p,c).vertical)
-- Actual objective path distance, not Euclidean/XY proximity.
g,p,c=fixture({{0,0},{1,0},{2,0},{3,0},{4,0}},{{1,2},{2,3},{3,4},{4,5}})
p.encounters={{objective=true,cell=g.Cells[key(4,0,0)]}}
t=D:EncounterTopology(g,p,c);assert(t.objectiveDistance==4 and D:TopologyPreference('relay_detail',t)==1.5)
-- Selection must actually consume the preference. Same motif, history and RNG
-- draw: a real corner changes the outcome versus a straight two-exit corridor.
local function selectAt(graph,cell,plan,choices,theme)
 plan.ecology={theme=theme,before={templates={},earlyTemplates={},enemies={},families={},recent={}},templates={},decisions={},fallbacks=0}
 return D:SelectEcologyTemplate(plan,choices,{Float=function(_,lo,hi) return hi*.6 end},2,graph,cell)
end
local straight,sp,sc=fixture({{0,0},{1,0},{-1,0}},{{1,2},{1,3}})
local corner,cp,cc=fixture({{0,0},{1,0},{0,1}},{{1,2},{1,3}})
local choices={'listener_detail','outrider_detail','patrol'}
assert(selectAt(straight,sc,sp,choices,'hunting')=='outrider_detail')
assert(selectAt(corner,cc,cp,choices,'hunting')=='listener_detail')
assert(cp.ecology.decisions[1].fit=='corner')
-- Denial never becomes a statistical weight: an unsafe specialist is removed.
local oldHull=util.TraceHull
util.TraceHull=function(q) return {Hit=true,StartSolid=true,HitPos=q.start} end
assert(selectAt(corner,cc,cp,choices,'hunting')=='patrol')
assert(cp.ecology.decisions[1].fallback and cp.ecology.decisions[1].rejected==2)
util.TraceHull=oldHull
assert(selectAt(corner,cc,cp,choices,'hunting')=='listener_detail','physical rejection leaked beyond selection')
-- Production spawn rechecks changing geometry and substitutes ordinary bodies.
local enc={id=1,cell=cc,cellKey=key(0,0,0),role='ambush',composition={listener=1,soldier=1},entities={}}
Run.State.Graph=corner
util.TraceHull=function(q) return {Hit=true,StartSolid=true,HitPos=q.start} end
D:_SpawnEncounter(enc)
assert(not enc.composition.listener and enc.composition.shambler==1 and enc.composition.soldier==1)
util.TraceHull=oldHull
-- Force all precomputed candidates into a short corridor. Two fit old budgets,
-- but every pair is <4 apart, so exactly one can survive sequential admission.
local points,edges={},{}
for x=0,8 do points[#points+1]={x,0};if x>0 then edges[#edges+1]={x,x+1} end end
local sg,_,_=fixture(points,edges);sg.Start=sg.Cells[key(0,0,0)];sg.LevelSeed=987
local sectorMap,tags,visible=D._BuildSectorMap,D._BuildCellTags,D._VisibleFromStart
D._BuildSectorMap=function(_,graph) local out={};for k in pairs(graph.Cells) do out[k]=2 end;return out end
D._BuildCellTags=function(_,graph) local out={};for k in pairs(graph.Cells) do out[k]={sector=2,role='travel'} end;graph.CellTags=out;return out end
D._VisibleFromStart=function() return false end
Run.State={Level=1,Graph=sg};H.setParty(1)
local eligible=D._EligibleTemplates
D._EligibleTemplates=function() return {'patrol'} end
local ok,plan=D:BuildPlan(sg);assert(ok)
assert(#plan.encounters==1,'stale candidate list admitted adjacent encounters')
local currentSpacing=D._FarEnough
D._FarEnough=function() return true end
local controlOK,stale=D:BuildPlan(sg)
D._FarEnough=currentSpacing
D._EligibleTemplates=eligible
D._BuildSectorMap,D._BuildCellTags,D._VisibleFromStart=sectorMap,tags,visible
assert(controlOK and #stale.encounters==2,'spacing fixture did not exercise a second affordable candidate')
-- A full generated plan with closed native gates remains deterministic and safe.
Run.State={CampaignSeed=739,Level=1}
local graph=H.prepare(739,1);Run.State.GatesOpen={false,false,false,false}
local a=H.build(graph);H.bounds(a)
local b=H.build(graph);assert(H.signature(a)==H.signature(b))
for _,e in ipairs(a.encounters) do
 if not e.objective then
  assert(D:TemplateFitsCell(e.templateId,graph,graph.Cells[e.cellKey],e.role))
  for _,other in ipairs(a.encounters) do
   if other~=e then assert(N:Distance(graph,e.cell,other.cell)>=EC.MajorSpacingCells,'closed-gate spacing') end
  end
 end
end
print('BESTIARY_B21_PASS: real graph topology/gates/events, actual preference selection, physical filtering/fallback/revalidation, stale-candidate regression, closed-gate production replay')
