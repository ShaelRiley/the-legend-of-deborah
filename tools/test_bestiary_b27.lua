-- B27: production autonomous population, not a table-count-only roster test.
local T=dofile('tools/test_bestiary_b23.lua')
local H,W=T.H,T.W;local D,Run=H.D,H.Run
local root='gamemodes/legend_of_deborah/gamemode/lod/'
istable=istable or function(v) return type(v)=='table' end
dofile(root..'sv_neil_brute.lua');dofile(root..'sv_warden_arena.lua')
local EC=LOD.Config.Encounter
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function living() local n=0;for _,e in ipairs(W.Entities) do if IsValid(e) and not e.LODDead then n=n+1 end end;return n end
assert(count(W.Config.AutonomousTypes)==32,'autonomous repertoire drift')
-- The same four early autonomous identities may lead directed opening squads;
-- this does not relax any other specialist's existing eligibility or companions.
local early={reaper_detail=true,drubber_chase=true,caromer_screen=true,afterburst_detail=true}
for _,role in ipairs({'arena','ambush'}) do
 local offered={};for _,id in ipairs(D:_EligibleTemplates(1,role)) do offered[id]=true end
 for id in pairs(early) do assert(offered[id],'early directed identity missing '..id) end
 for _,id in ipairs({'fencer_screen','reeler_chase','forker_crossfire','carrion_feast'}) do
  assert(not offered[id],'unapproved early directed identity '..id)
 end
end
for _,role in ipairs({'travel','reward'}) do
 for _,id in ipairs(D:_EligibleTemplates(1,role)) do assert(not early[id],'early tactical restriction lost') end
end
for _,pool in pairs(W.Config.Pools) do
 assert(count(pool)==32,'motif became a narrow whitelist')
 for id,w in pairs(pool) do assert(W.Config.AutonomousTypes[id] and EC.Archetypes[id] and (w==2 or w==6),'unaudited roaming choice') end
end
for _,id in ipairs({'climber','nodule','sentry','lurker','beamsweeper','stitcher','bulwark','cantor',
 'absolver','interposer','mourner','relay','lacemaker','carrion','exactor','neil','brute','warden','hector'}) do
 assert(not W.Config.AutonomousTypes[id],'dependent/anchored/named actor made solitary '..id)
end
-- Exercise native-doubled Spawn/Activate and actual placement for EVERY audited ID.
local graph,plan=T.prepare(7919,8)
Run.State.GatesOpen={false,false,false,false}
plan=H.build(graph);Run.State.BuildReady=true
local originalPool=W._Pool
local admitted={}
local types={};for id in pairs(W.Config.AutonomousTypes) do types[#types+1]=id end;table.sort(types)
for _,id in ipairs(types) do
 W._Pool=function() return {[id]=1},'test-explicit-id' end
 T.init(graph)
 for _,e in ipairs(W.Entities) do
  assert(e.LODArchetypeId==id and e.spawned and e.activated and e.LODWanderer,'spawn dropped archetype')
  admitted[id]=true
  -- Existing patrol compiler remains installed for every mobile type.
  e.LODTarget=nil;e.LODNextRouteRefresh=0;e.LODWaypoints={}
  T.class._RefreshRoute(e,graph)
  assert(#e.LODWaypoints>0,'autonomous patrol failed '..id..' home='..e.LODHomeCellKey..' neighbors='..H.serial(graph.Cells[e.LODHomeCellKey].neighbors))
 end
 assert(admitted[id],'no legal production spawn '..id)
end
W._Pool=originalPool
assert(count(admitted)==32)
-- Arbitrary config entries cannot turn a boss/hazard into a roamer.
local pool=W.Config.Pools[plan.ecology.theme];pool.hector=99999;pool.lurker=99999
T.init(graph)
for _,e in ipairs(W.Entities) do assert(e.LODArchetypeId~='hector' and e.LODArchetypeId~='lurker') end
pool.hector=nil;pool.lurker=nil
-- Every motif retains its exact target, shared cap and original replacement law.
local desired={corruption=18,crossfire=18,hunting=20,occupation=20,quarantine=18,retinue=18}
for theme,target in pairs(desired) do
 local fake={Layers=3,EncounterPlan={ecology={theme=theme}}}
 assert(W:GetFloorTarget(fake)==target and W:GetTargetPopulation(fake)==3*target)
 fake.Layers=4;assert(W:GetFloorTarget(fake)==16 and W:GetTargetPopulation(fake)==64)
 fake.Layers=5;fake.WanderLayers=3;assert(W:GetTargetPopulation(fake)==3*target,'private gallery counted as roaming floor')
end
assert(EC.ActiveHostileTarget==80 and EC.ActiveHostileCeiling==96 and EC.MajorSpacingCells==4)
-- Failed initial creation accrues initial debt, NOT a random20s death replacement.
T.setTime(0);util.TraceHull=function(t) return {Hit=true,StartSolid=true,HitPos=t.start} end
T.init(graph)
assert(living()==0)
local target=W:GetFloorTarget(graph);local floors=graph.WanderLayers or graph.Layers
for floor=0,floors-1 do assert(W.InitialRemaining[floor]==target) end
util.TraceHull=T.traceHull
T.setTime(.5);T.quiet(function() W:Think() end);assert(living()==0,'early initial retry')
T.setTime(1);T.quiet(function() W:Think() end);assert(living()==floors,'initial retry did not create exactly one/floor')
T.setTime(100);T.quiet(function() W:Think() end);assert(living()==2*floors,'initial retry caught up missed time')
for floor=0,floors-1 do assert(W.InitialRemaining[floor]==target-2) end
local victim=W.Entities[1];local floor=victim.LODWanderFloor;victim.LODDead=true
local debt=W.InitialRemaining[floor]
T.setTime(100.5);T.quiet(function() W:Think() end)
assert(W.InitialRemaining[floor]==debt,'death changed initial birth ledger')
for now=101,100+target-2 do T.setTime(now);T.quiet(function() W:Think() end) end
for f=0,floors-1 do assert(W.InitialRemaining[f]==0,'initial debt failed to converge on legal geometry') end
assert(W:_LivingOnFloor(floor)==target-1,'initial fill replenished a combat death')
local now=100+target-2
T.setTime(now+1);T.quiet(function() W:Think() end)
assert(W.NextRespawn[floor]==now+21,'completed initial population bypassed20s death cadence')
local before=living();T.setTime(now+20);T.quiet(function() W:Think() end)
assert(living()==before,'early combat-death replacement')
-- All initial service is frozen/inactive and cannot revive a retired owner.
for _,flag in ipairs({'SimulationFrozen','Failed','LevelCleared','BuildReady'}) do
 local old=Run.State[flag];Run.State[flag]=flag~='BuildReady'
 local ordinal=H.serial(W.SpawnOrdinal);T.setTime(1000);T.quiet(function() W:Think() end)
 assert(H.serial(W.SpawnOrdinal)==ordinal,'inactive initial/replacement work')
 Run.State[flag]=old
end
-- Read-only release census discloses actual deficits/admission failures.
local state=H.serial({W.SpawnOrdinal,W.InitialRemaining,W.NextRespawn,W.AdmissionStats})
local snap=W:PopulationSnapshot(graph)
assert(snap.owned and #snap.floors==floors and snap.cap==64)
assert(snap.floors[floor+1].deficit==1 and snap.floors[floor+1].initialPending==0)
assert(H.serial({W.SpawnOrdinal,W.InitialRemaining,W.NextRespawn,W.AdmissionStats})==state,'observer mutated population')
T.setMode('reset');T.init(graph);T.setMode(nil)
assert(W.Owner==nil and next(W.NextInitial)==nil and next(W.InitialRemaining)==nil,'initial native reset resurrected owner')
-- Stable route distribution: all inputs once, near/branch ratio and bins intact.
local candidates,p={}, {tags={}}
local key=LOD.MazeGenerator.CellKey
for i=1,12 do
 local c={x=i,y=0,z=0};candidates[i]=c
 p.tags[key(i,0,0)]={pacing={progress=(i%4)/4+.01,detour=i%3==0 and 7 or 1}}
end
local result=D:RouteCandidates(p,candidates);local seen={}
assert(#result==#candidates)
for _,c in ipairs(result) do assert(not seen[c]);seen[c]=true end
assert(result[3].x%3==0 and result[6].x%3==0,'near-near-branch preference lost')
assert(H.serial(result)==H.serial(D:RouteCandidates(p,candidates)),'route replay changed')
D:Cleanup();assert(not W:PopulationSnapshot(graph).owned)
print('BESTIARY_B27_PASS all32 production spawn/patrol identities;6 broad weighted motifs;20/floor and64/global; initial debt,1s/no-catch-up/freeze/reset;20s death cadence; native rejection and read-only census; deterministic route distribution')
