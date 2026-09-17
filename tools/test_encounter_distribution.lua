-- Hundreds of full production encounter plans on independently generated mazes.
-- Only Source clearance/ceiling traces are doubled; native collision is a runtime gate.
dofile('tools/test_enemy_roster.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_rng.lua');dofile(root..'sv_maze_generator.lua');dofile(root..'sv_progression_director.lua')
dofile(root..'sv_m3_run_integration.lua')
local D,E,Run=LOD.EncounterDirector,LOD.EnemyRoster,LOD.RunManager
local party=1;Run._ActiveCount=function() return party end
D.Entities={}
util.TraceHull=function(t) return {Hit=false,StartSolid=false,HitPos=t.endpos} end
util.TraceLine=function(t)
 local delta=t.endpos-t.start
 if delta.z>200 then return {Hit=true,HitPos=t.start+Vector(0,0,250),HitNormal=Vector(0,0,-1),Fraction=.5} end
 local n=delta:Length();local f=n>320 and 320/n or 1
 return {Hit=f<1,HitPos=t.start+delta*f,HitNormal=Vector(0,0,1),Fraction=f,StartSolid=false}
end
local counts,viable,early,plans,total={},{},{},0,0
for seed=1,32 do
 local graph
 for attempt=1,64 do
  local candidate=assert(LOD.MazeGenerator:Generate(seed*7919+attempt))
  if LOD.ProgressionDirector:Plan(candidate,seed*7919+attempt) then graph=candidate;break end
 end
 assert(graph,'No solvable progression after canonical retries')
 Run.State.Graph=graph;Run.State.GatesOpen={}
 for i in ipairs(graph.Progression.Gates) do Run.State.GatesOpen[i]=true end
 local distances=D:_PlanningDistances(graph,graph.Start)
 for x=1,4 do
  local c=graph.Cells[LOD.MazeGenerator.CellKey(x,1,0)]
  if c then assert((distances[LOD.MazeGenerator.CellKey(x,1,0)] or math.huge)==LOD.MazeNavigator:Distance(graph,graph.Start,c),'BFS planner changed path distances') end
 end
 for variant=1,16 do
  party=variant%4+1;Run.State.Level=variant%5+1
  graph.MasterLevelSeed=seed*7919+variant*104729
  local ok,plan=D:BuildPlan(graph);assert(ok,plan);plans=plans+1
  for _,enc in ipairs(plan.encounters) do
   total=total+1
   for id,count in pairs(enc.composition) do
    counts[id]=(counts[id] or 0)+count
    if E.Definitions[id] then
     local p=E:Placement(graph,graph.Cells[enc.cellKey],id,enc.role)
     if p then viable[id]=(viable[id] or 0)+count;if enc.sector<=2 then early[id]=(early[id] or 0)+count end end
    end
   end
  end
 end
end
assert(plans==512 and total>2000)
for _,id in ipairs({'climber','razor','lurker','beamsweeper','flamer','arccaster','sentry','bigcrab','nodule'}) do
 assert((counts[id] or 0)>=25,id..' effectively absent from normal encounter generation')
 assert((viable[id] or 0)>=20,id..' always rejected by placement policy')
 assert((early[id] or 0)>=5,id..' unavailable in early/mid sectors')
 print(string.format('DISTRIBUTION %s planned=%d legal=%d early=%d',id,counts[id],viable[id],early[id]))
end
print('ENCOUNTER_DISTRIBUTION_PASS: '..plans..' deterministic plans / '..total..' encounters, 32 generated mazes, party 1–4, dungeon 1–5')
