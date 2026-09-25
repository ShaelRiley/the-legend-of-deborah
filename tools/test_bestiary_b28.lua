-- B28: exercise the documented ray/BBOX disagreement, not a floor-always-hit
-- fake. Source calls are still doubled; this is NOT native GMod acceptance.
local T=dofile('tools/test_bestiary_b23.lua')
local H,W=T.H,T.W;local D,R=H.D,H.Run
local root='gamemodes/legend_of_deborah/gamemode/lod/'
istable=istable or function(v) return type(v)=='table' end
MASK_SOLID=33570827;MASK_NPCSOLID=33701899;COLLISION_GROUP_PLAYER_MOVEMENT=8
local c={x=8,y=8,z=0};local center=LOD.MazeNavigator:CellCenter(c)
local mode='supported';local hits=0
util.TraceLine=function(t) return {Hit=false,StartSolid=false,HitPos=t.endpos,Fraction=1} end
util.TraceHull=function(t)
 if t.start==t.endpos then
  return {Hit=mode=='blocked',StartSolid=mode=='blocked',HitPos=t.start,Fraction=0}
 end
 assert(t.mins.x==-2 and t.maxs.z==2 and t.mask==MASK_SOLID and t.collisiongroup==8,'not movement support')
 assert(t.endpos.z-t.start.z==-28,'support reach widened')
 hits=hits+1
 local floorZ=center.z+(mode=='wrong_height' and -16 or 0)
 return {Hit=mode~='missing',StartSolid=mode=='inside',AllSolid=mode=='allsolid',
  HitPos=Vector(center.x,center.y,floorZ),HitNormal=Vector(0,0,mode=='steep' and .5 or 1),Fraction=.5}
end
W.SupportProbeStats=nil
local pos,reason=W:_SupportedSpawn(c)
assert(pos and pos.z==center.z+2,'B28: legal BBOX floor rejected because its thin ray missed: '..tostring(reason))
assert(W.SupportProbeStats.samples==1 and W.SupportProbeStats.lineMisses==1,'native disagreement not disclosed')
for _,case in ipairs({'missing','inside','allsolid','steep','wrong_height','blocked'}) do
 mode=case;local got=W:_SupportedSpawn(c);assert(not got,'unsafe support admitted: '..case)
end
mode='supported';for i=1,20 do assert(W:_SupportedSpawn(c)) end
assert(W.SupportProbeStats.samples==8,'unbounded control rays')
-- Start-visibility keeps ordinary ray cover and open sight lines. Only known
-- generated solids can correct the ray: no arbitrary prop/world grazing cover.
local graph={Start={x=1,y=1,z=0}};local candidate={x=5,y=5,z=0}
local lineBlocked=false;local kind='lod_static_box';local startSolid=false
util.TraceLine=function(t) return {Hit=lineBlocked,StartSolid=false,HitPos=t.endpos,Fraction=lineBlocked and .3 or 1} end
util.TraceHull=function(t)
 assert(t.mins.x==-1 and t.maxs.z==1 and t.mask==MASK_SOLID,'visibility bypasses physical probe')
 return {Hit=kind~=nil,StartSolid=startSolid,Fraction=.4,Entity=kind and {valid=true,GetClass=function() return kind end}}
end
D.VisibilityProbeStats=nil
assert(not D:_VisibleFromStart(graph,candidate),'B28: generated wall is transparent to encounter start visibility')
kind='lod_gate';assert(not D:_VisibleFromStart(graph,candidate))
kind='lod_jail_door';assert(not D:_VisibleFromStart(graph,candidate))
kind='prop_physics';assert(D:_VisibleFromStart(graph,candidate),'grazing unrelated prop manufactured cover')
kind=nil;assert(D:_VisibleFromStart(graph,candidate),'open sight line admitted a spawn')
kind='lod_static_box';startSolid=true;assert(D:_VisibleFromStart(graph,candidate),'ambiguous inside-solid trace hid initial sight')
lineBlocked=true;assert(not D:_VisibleFromStart(graph,candidate),'ordinary world/prop ray cover lost')
assert(D.VisibilityProbeStats.bboxBlocked==3 and D.VisibilityProbeStats.visible==3 and D.VisibilityProbeStats.lineBlocked==1)
print('B28_BOUNDARY_PASS supported-ray-miss recovery; missing/steep/embedded/wrong-height/blocked rejection; generated-only visibility; bounded8 control rays')

-- Load the actual production progression wrappers omitted by prior B26/B27
-- fixtures. This reproduces the uploaded campaign/layout/maze attempt exactly.
util.TraceHull=T.traceHull;util.TraceLine=T.traceLine
for _,name in ipairs({'sv_graph_integrity.lua','sv_m2_progression_safety.lua','sv_neil_brute.lua','sv_warden_arena.lua'}) do dofile(root..name) end
R.State={CampaignSeed=1515962883,CampaignEpoch=1,RunId=66,Level=1}
local g=H.prepare(1515962883,1);R.State.GatesOpen={false,false,false,false}
assert(g.MasterLevelSeed==163197061 and g.LevelSeed==1756475100 and g.ProgressionLayoutAttempt==3 and g.Attempt==2,'not uploaded native layout')
assert(g.Validation.cellCount==520 and table.Count(g.Cells)==539 and g.WanderLayers==2,'base maze versus reserved court confused')
-- Compile real floors and merged wall bounds at the actual negative world
-- height. No fake solid is inferred from a planner tag or expected spawn count.
local oldCreate=ents.Create
local B=LOD.MazeBuilder
for _,name in ipairs({'sv_maze_builder.lua','sv_maze_builder_static_walls.lua','sv_maze_builder_floor_anchor.lua'}) do dofile(root..name) end
LOD.Config.Maze.Origin=Vector(0,0,-12271.97)
LOD.WallVisuals={SetSegments=function() return true end}
local boxes={}
ents.Create=function(class)
 if class~='lod_static_box' then return oldCreate(class) end
 local e={valid=true,class=class}
 for _,field in ipairs({'Pos','Angles','BoxMins','BoxMaxs','BoxKind'}) do
  e['Set'..field]=function(self,v) self[field]=v end;e['Get'..field]=function(self) return self[field] end
 end
 function e:GetClass() return self.class end
 function e:IsPlayer() return false end
 function e:Spawn() boxes[#boxes+1]=self end
 function e:Activate() end
 function e:Remove() self.valid=false end
 function e:IsLODCollisionReady() return true end
 function e:SetNW2Bool() end
 return e
end
angle_zero=Angle(0,0,0)
B.Entities={};B.BuildFailures=0;B:_BuildFloors(g);B:_BuildWalls(g)
assert(#boxes>500 and B.BuildFailures==0,'physical compiler was not exercised')
-- AABB slab intersection. Finite feet/volume sweeps hit the compiled bounds;
-- rayMiss=true models the documented absent-physics-mesh failure boundary.
local function boxTrace(t)
 local best=1;local entity,normal,inside
 for _,e in ipairs(boxes) do if IsValid(e) then
  local lo=e.Pos+e.BoxMins-(t.maxs or Vector(0,0,0))
  local hi=e.Pos+e.BoxMaxs-(t.mins or Vector(0,0,0))
  local enter,leave=0,1;local n=Vector(0,0,1);local contained=true
  for _,axis in ipairs({'x','y','z'}) do
   local start,delta=t.start[axis],t.endpos[axis]-t.start[axis]
   if start<=lo[axis] or start>=hi[axis] then contained=false end
   if math.abs(delta)<.000001 then
    if start<=lo[axis] or start>=hi[axis] then enter=2;break end
   else
    local a,b=(lo[axis]-start)/delta,(hi[axis]-start)/delta
    local sign=-1;if a>b then a,b=b,a;sign=1 end
    if a>enter then enter=a;n=Vector(0,0,0);n[axis]=sign end
    leave=math.min(leave,b)
   end
  end
  if enter<=leave and leave>0 and enter<best then best=enter;entity=e;normal=n;inside=contained end
 end end
 return {Hit=entity~=nil,StartSolid=inside==true,AllSolid=false,Fraction=best,Entity=entity,
  HitPos=t.start+(t.endpos-t.start)*best,HitNormal=normal or Vector(0,0,1)}
end
util.TraceHull=boxTrace
util.TraceLine=function(t) return {Hit=false,StartSolid=false,Fraction=1,HitPos=t.endpos,HitNormal=Vector(0,0,1)} end
local plan=H.build(g);H.bounds(plan);R.State.BuildReady=true
local optional=0
for _,enc in ipairs(plan.encounters) do if not enc.objective then optional=optional+1 end end
assert(optional>0 and plan.visibilityProbe.bboxBlocked>0,'real compiled walls still suppress all discretionary fights')
T.init(g);T.bounds(g)
local actual=#W.Entities
assert(actual>0 and actual<=40,'legal compiled floors did not create roaming actors')
assert(W.SupportProbeStats.lineMisses>0,'ray/hull discrepancy not reproduced')
-- Every admitted actor has actual swept support at the same deck elevation.
for _,e in ipairs(W.Entities) do assert(W:_SupportedSpawn(g.Cells[e.LODHomeCellKey]),'registered unsupported actor') end
print(string.format('B28_COMPILED_REPLAY_PASS campaign=1515962883 master=163197061 layout=1756475100 attempt=3 mazeAttempt=2 baseCells=520 courtCells=19 boxes=%d directed=%d wanderers=%d/%d rayMisses=%d',#boxes,optional,actual,W:GetTargetPopulation(g),W.SupportProbeStats.lineMisses))

-- Release telemetry is independent of developer logging and cannot consume
-- population RNG, create actors, alter the plan or reset the dungeon.
local memory,reads,writes={},0,0
local watched={
 'gamemodes/legend_of_deborah/gamemode/init.lua',
 'gamemodes/legend_of_deborah/gamemode/lod/sh_config.lua',
 'gamemodes/legend_of_deborah/gamemode/lod/sv_encounter_director.lua',
 'gamemodes/legend_of_deborah/gamemode/lod/sv_m3_run_integration.lua',
 'gamemodes/legend_of_deborah/gamemode/lod/sv_wandering_director.lua',
 'gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_roster_placement.lua',
 'gamemodes/legend_of_deborah/gamemode/lod/sv_encounter_ecology.lua',
 'lua/autorun/server/lod_population_observability.lua'}
local manifest={};for _,p in ipairs(watched) do manifest[#manifest+1]=string.rep('a',64)..'  '..p;memory['GAME:'..p]='exact' end
memory['DATA:legend_of_deborah/dev_population_sources.txt']=table.concat(manifest,'\n')
memory['DATA:legend_of_deborah/dev_build.txt']='test-checkout clean'
file={Read=function(p,realm) reads=reads+1;return memory[realm..':'..p] end,
 CreateDir=function() end,Write=function(p,s) writes=writes+1;memory['DATA:'..p]=s end}
util.SHA256=function(s) return string.rep(s=='exact' and 'a' or 'b',64) end
util.TableToJSON=H.serial
game=game or {};game.GetMap=function() return 'gm_flatgrass' end
GetConVar=function() return {GetBool=function() return false end} end
local timers,shutdown={},nil
timer.Create=function(id,seconds,reps,fn) assert(seconds==10 and reps==0);timers[id]=fn end
hook.Add=function(event,id,fn) if event=='ShutDown' then shutdown=fn end end
local before=H.serial({W.SpawnOrdinal,W.InitialRemaining,T.signature(),H.signature(plan)})
dofile('lua/autorun/server/lod_population_observability.lua')
local A=LOD.PopulationObservability
local snap=A:Snapshot('test');assert(snap.source.verified and snap.source.checked==8 and not snap.developerMode)
assert(snap.nativeProbes.supportBound and snap.nativeProbes.visibilityBound and snap.revision=='b28')
local lastReads=reads;A:Snapshot('repeat');assert(reads==lastReads,'source files rehashed on every heartbeat')
T.setTime(2000);T.quiet(function() timers.LOD_PopulationEvidence() end)
assert(writes==1 and memory['DATA:legend_of_deborah/population_latest.txt'],'release capture missing')
T.setTime(2001);T.quiet(function() A:Poll() end);assert(writes==1,'heartbeat unbounded')
R.State.GatesOpen[1]=true;T.quiet(function() A:Poll() end);assert(writes==2,'gate receipt missing');R.State.GatesOpen[1]=false
for i=1,70 do T.setTime(2100+i*30);T.quiet(function() A:Poll() end) end
assert(#A.Records==64,'evidence ring not bounded')
assert(H.serial({W.SpawnOrdinal,W.InitialRemaining,T.signature(),H.signature(plan)})==before,'observer mutated gameplay')
A.Source=nil;memory['GAME:'..watched[3]]='stale workshop bytes'
assert(not A:SourceIdentity().verified and A.Source.mismatches==1,'mixed mount certified by install label')
A.Source=nil;memory['DATA:legend_of_deborah/dev_population_sources.txt']=''
assert(not A:SourceIdentity().verified and A.Source.missing==8,'absent manifest claimed verified')
T.quiet(function() shutdown() end);assert(#A.Records==64 and A.Records[64]:find('shutdown'),'shutdown evidence missing')
print('B28_OBSERVER_PASS developer-off capture; exact eight-file mount fingerprints; absent/mixed source disclosure; cached hashing; gate/shutdown receipts; bounded64 records; no gameplay mutation')
