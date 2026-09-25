-- Real plans, selection, spawn service, AI wrappers and cleanup. Only Source
-- entity/trace/clock boundaries are doubled; no copied selection algorithm.
local H=dofile('tools/test_bestiary_b20.lua')
local D,E,Run=H.D,H.E,H.Run
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local N=LOD.MazeNavigator
local oldWeights=table.Copy(LOD.WanderingDirector.Config.ArchetypeWeights)
local class={_RefreshTarget=function() end,_RefreshRoute=function() end}
scripted_ents.GetStored=function() return {t=class} end
LOD.WanderingDirector=nil
dofile(root..'sv_wandering_director.lua')
local W=LOD.WanderingDirector
for id,weight in pairs(oldWeights) do W.Config.ArchetypeWeights[id]=weight end
-- Earlier roster fixture replaces this production method for its private test;
-- restore the exact method so cap and stale registry tests execute real code.
local source=assert(io.open(root..'sv_encounter_director.lua')):read('*a')
assert(load('local EncounterDirector=LOD.EncounterDirector\n'..assert(source:match('(function EncounterDirector:GetActiveCount%(%)%s.-\nend)'))))()
local now=0;CurTime=function() return now end
local heroes={};LOD.FactionManager.LivingTargets=function() return heroes end
local made,mode=0,nil
local function entity()
 made=made+1
 local e={valid=true,LODHostile=true,index=made}
 function e:GetPos() return self.pos end
 function e:SetPos(v) self.pos=v end
 function e:Spawn() self.spawned=true;if mode=='spawn' then self.valid=false end end
 function e:Activate() self.activated=true;if mode=='activate' then self.valid=false end;if mode=='reset' then W:Cleanup() end end
 function e:Remove() self.valid=false end
 function e:EntIndex() return self.index end
 function e:Health() return self.LODDead and 0 or 100 end
 function e:IsPlayer() return false end
 return e
end
ents.Create=function() return mode=='create' and {valid=false} or entity() end
-- Model native floor geometry; real EnemyRoster.Placement remains installed.
local hullBlocked,supportMissing=false,false
local traceHull=function(t) return {Hit=hullBlocked,StartSolid=hullBlocked,HitPos=t.endpos} end
local traceLine=function(t)
 local dz=t.endpos.z-t.start.z
 if dz<0 and dz>=-40 then
  return {Hit=not supportMissing,StartSolid=false,HitPos=t.endpos+Vector(0,0,10),HitNormal=Vector(0,0,1),Fraction=.5}
 end
 if dz>200 then return {Hit=true,HitPos=t.start+Vector(0,0,250),HitNormal=Vector(0,0,-1),Fraction=.5} end
 local length=(t.endpos-t.start):Length();local fraction=length>320 and 320/length or 1
 return {Hit=fraction<1,StartSolid=false,HitPos=t.start+(t.endpos-t.start)*fraction,Fraction=fraction}
end
util.TraceHull=traceHull;util.TraceLine=traceLine
local snap=LOD.HostileMotionV2.SnapSpawn
LOD.HostileMotionV2.SnapSpawn=function(_,e) e.settled=true;if mode=='settlement' then e.valid=false end end
local function quiet(fn)
 local oldPrint=print;print=function() end
 local ok,result=pcall(fn);print=oldPrint;assert(ok,result);return result
end
local function prepare(campaign,level)
 Run.State={CampaignSeed=campaign,CampaignEpoch=1,RunId=1,Level=level}
 local graph=H.prepare(campaign,level);local plan=H.build(graph)
 Run.State.BuildReady=true;Run.State.Failed=false;Run.State.LevelCleared=false;Run.State.SimulationFrozen=false
 return graph,plan
end
local function init(graph) quiet(function() W:_InitializeForGraph(graph) end) end
local function signature()
 local rows={}
 for _,e in ipairs(W.Entities) do if IsValid(e) then rows[#rows+1]=e.LODWanderFloor..':'..e.LODArchetypeId..':'..e.LODHomeCellKey end end
 return table.concat(rows,';')
end
local basic={shambler=true,runner=true,soldier=true,deadcrab=true,bioblaster=true}
-- B27 explicit admission contract (independent of the production config).
local new={siphoner=2,caromer=1,reaper=1,redliner=2,drubber=1,afterburst=1,
 blitzer=2,sniper=2,razor=2,arccaster=2,gaoler=2,silencer=2,repulsor=2,pincer=2,
 harrier=2,waylayer=2,pavise=2,repriser=2,reeler=2,forker=2,fencer=2,listener=2,shy=2,accumulator=2}
local function bounds(graph)
 local seen={}
 local encounterHomes={}
 for _,enc in ipairs((graph.EncounterPlan or {}).encounters or {}) do encounterHomes[enc.cellKey]=true end
 for _,e in ipairs(W.Entities) do
  if IsValid(e) and not e.LODDead then
   local key=e.LODHomeCellKey;local c=assert(graph.Cells[key]);local tag=graph.CellTags[key]
   assert(not seen[key],'duplicate home');seen[key]=true
   assert(not encounterHomes[key],'B24 wandering home overlaps planned encounter')
   assert(not tag.safe and not tag.objective and tag.role~='boss' and not E:IsTransition(graph,c),'protected home')
   assert(D:PacingAllows(graph.EncounterPlan,c),'reserved pacing home')
   assert(e.spawned and e.activated and e.settled and e.LODSpawnSource=='wanderer','native spawn/settlement missing')
   assert(e.LODEncounterId==nil and e.LODWanderFloor==c.z,'encounter identity or floor contamination')
   assert(e.LODNextTargetRefresh>=now and e.LODNextTargetRefresh<=now+LOD.Config.Encounter.TargetRefreshSeconds,'target schedule')
   assert(e.LODNextRouteRefresh>=now and e.LODNextRouteRefresh<=now+LOD.Config.Encounter.RouteRefreshSeconds,'route schedule')
   local pool=W:_Pool(graph);assert(pool[e.LODArchetypeId],'unlisted pool admission')
   if new[e.LODArchetypeId] then assert(tag.sector>=new[e.LODArchetypeId] and (tag.role=='arena' or tag.role=='ambush'),'new specialist role escaped') end
   if e.LODArchetypeId=='flamer' then assert(tag.sector>=2,'early Flamer') end
   if E.Definitions[e.LODArchetypeId] then assert(e.LODRosterPlacement and E:Placement(graph,c,e.LODArchetypeId,tag.role),'placement bypass') end
  end
 end
 for floor=0,(graph.WanderLayers or graph.Layers)-1 do
  local counts,_,specialists=W:_Population(floor)
  assert(W:_LivingOnFloor(floor)<=W:GetFloorTarget(graph) and W:GetFloorTarget(graph)<=20 and specialists<=8,'population ceiling')
  for id,n in pairs(counts) do assert(basic[id] or n<=1,'specialist singleton') end
 end
 assert(D:GetActiveCount()<=96,'shared ceiling exceeded')
 assert(W:GetTargetPopulation(graph)<=64,'roaming global cap')
end
local graph,plan=prepare(191919,8)
assert(D:CommitEcologyPlan(graph))
local receipt=H.serial(Run.State.EncounterEcology);local planSig=H.signature(plan)
init(graph);bounds(graph)
assert(#W.Entities>0,'no production wanderers')
local first=signature();init(graph);bounds(graph);assert(signature()==first,'same-input spawn replay')
assert(H.serial(Run.State.EncounterEcology)==receipt and H.signature(plan)==planSig,'spawn mutated plan/history')
-- Restrict a real legally tagged cell for exhaustive selection-policy checks.
local legal
for _,c in pairs(graph.Cells) do
 local tag=graph.CellTags[E.Key(c)]
 if tag and tag.sector>=2 and (tag.role=='arena' or tag.role=='ambush') and not E:IsTransition(graph,c) and not tag.safe and not tag.objective then legal=c;break end
end
assert(legal,'fixture lacks legal specialist cell')
local savedTheme=plan.ecology.theme
W:Cleanup();W.Entities={}
local poolCount=0
for theme,pool in pairs(W.Config.Pools) do
 plan.ecology.theme=theme
 local choices=W:_Choices(graph,legal,legal.z);local found={}
 for _,v in ipairs(choices) do found[v.id]=true end
 for id in pairs(pool) do assert(found[id],'legal pool identity missing '..theme..':'..id);poolCount=poolCount+1 end
 for _,v in ipairs(choices) do assert(pool[v.id],'foreign pool identity') end
 W.LastArchetype[legal.z]=choices[1].id
 for _,v in ipairs(W:_Choices(graph,legal,legal.z)) do assert(v.id~=choices[1].id,'immediate repeat') end
 W.LastArchetype={}
end
plan.ecology.theme='occupation'
local oldTag=graph.CellTags[E.Key(legal)];graph.CellTags[E.Key(legal)]={sector=1,role='arena'}
for _,v in ipairs(W:_Choices(graph,legal,legal.z)) do assert((not new[v.id] or new[v.id]==1) and v.id~='flamer','early specialist') end
graph.CellTags[E.Key(legal)]={sector=2,role='corridor'}
for _,v in ipairs(W:_Choices(graph,legal,legal.z)) do assert(not new[v.id],'wrong-role specialist') end
graph.CellTags[E.Key(legal)]=oldTag
-- Every unlisted config injection stays excluded even in legacy fallback.
plan.ecology.theme='unknown';W.Config.ArchetypeWeights.beamsweeper=100000
for _,v in ipairs(W:_Choices(graph,legal,legal.z)) do assert(v.id~='beamsweeper') end
W.Config.ArchetypeWeights.beamsweeper=nil
plan.ecology.theme=savedTheme
init(graph)
local floor=W.Entities[1].LODWanderFloor
-- A dead native body still in the shared registry cannot hide from the ceiling.
local victim=W.Entities[1];victim.LODDead=true
local before=W:_LivingOnFloor(floor)
-- B25 retains the old20s guaranteed service for chance1 profiles; probabilistic
-- rejection is separately exercised by the B25 service fixtures.
local intensity=W.IntensityProfile
W.IntensityProfile=function(self,g)
 local p=table.Copy(intensity(self,g));p.replacementChance=1;return p
end
now=0;W.NextThink=0;W.NextRespawn={};quiet(function() W:Think() end)
now=19.9;quiet(function() W:Think() end);assert(W:_LivingOnFloor(floor)==before,'replacement too early')
now=20.2;quiet(function() W:Think() end);assert(W:_LivingOnFloor(floor)==before+1,'replacement did not occur once')
W.IntensityProfile=intensity
for _,field in ipairs({'SimulationFrozen','Failed','LevelCleared'}) do
 Run.State[field]=true;local count=made;quiet(function() W:Think() end);assert(made==count,'spawn during '..field);Run.State[field]=false
end
Run.State.BuildReady=false;assert(not W:_SpawnOne(graph,floor,'notready'));Run.State.BuildReady=true
-- Make a vacancy and prove native failures do not register or advance last-ID.
for _,e in ipairs(W.Entities) do if e.LODWanderFloor==floor and not e.LODDead then e:Remove();break end end
for _,failure in ipairs({'create','spawn','settlement','activate'}) do
 local count=#W.Entities;local last=W.LastArchetype[floor];mode=failure
 assert(not W:_SpawnOne(graph,floor,'failure'));assert(#W.Entities<=count and W.LastArchetype[floor]==last,'failed body registered')
 assert(W.Diagnostics[floor]=='native_'..failure,'native failure not diagnosed')
end
mode=nil
hullBlocked=true;assert(not W:_SpawnOne(graph,floor,'blocked'));hullBlocked=false
supportMissing=true;assert(not W:_SpawnOne(graph,floor,'unsupported'));supportMissing=false
local saveEntities=D.Entities;D.Entities={};for i=1,96 do D.Entities[i]=entity() end
assert(not W:_SpawnOne(graph,floor,'ceiling') and W.Diagnostics[floor]=='ceiling')
D.Entities=saveEntities
-- The native geometry budget is finite even if every candidate is blocked.
local traceCount=0;util.TraceHull=function(t) traceCount=traceCount+1;return {Hit=true} end
assert(not W:_SpawnOne(graph,floor,'bounded'));assert(traceCount<=24,'unbounded native admission')
util.TraceHull=traceHull
-- Candidates never fall back beside a Hero; they also exclude reserved cells.
local playerCell=graph.Cells[W.Entities[#W.Entities].LODHomeCellKey]
local hero=entity();hero:SetPos(N:CellCenter(playerCell));heroes={hero}
for _,c in ipairs(W:_SpawnCandidates(graph,playerCell.z,LOD.RNG.New(123))) do
 assert(N:Distance(graph,playerCell,c)>=4,'near-Hero fallback')
end
heroes={}
-- Specialist cap/singleton are based on live bodies, and deaths release them.
local savedW=W.Entities;W.Entities={};plan.ecology.theme='occupation'
for _,id in ipairs({'redliner','watcher','seeker','flamer','siphoner','caromer','reaper','drubber'}) do
 local e=entity();e.LODArchetypeId=id;e.LODWanderer=true;e.LODWanderFloor=legal.z;e.LODWanderAnchorCellKey=id
 W.Entities[#W.Entities+1]=e
end
for _,v in ipairs(W:_Choices(graph,legal,legal.z)) do assert(basic[v.id],'specialist cap escaped') end
W.Entities[1].LODDead=true
local admitted=false;for _,v in ipairs(W:_Choices(graph,legal,legal.z)) do if v.id=='redliner' then admitted=true end end
assert(admitted,'death failed to release specialist slot')
W.Entities=savedW;plan.ecology.theme=savedTheme
-- Ordinary patrol routing executes the real graph compiler and cannot cross a
-- closed edge or choose safe/boss/stair cells; target wrapper retains its leash.
local walker=W.Entities[#W.Entities];walker.LODNextRouteRefresh=0;walker.LODWaypoints={};walker.LODTarget=nil
class._RefreshRoute(walker,graph)
assert(#walker.LODWaypoints>0,'production patrol failed to compile')
local staleLevel=Run.State.Level;Run.State.Level=staleLevel+1
assert(not W:_SpawnOne(graph,floor,'stalelevel'));Run.State.Level=staleLevel
local staleGraph=Run.State.Graph;Run.State.Graph={}
assert(not W:_SpawnOne(graph,floor,'stalegraph'));Run.State.Graph=staleGraph
local copies={};for _,e in ipairs(W.Entities) do copies[#copies+1]=e end
Run.State=table.Copy(Run.State);Run.State.Graph=graph;Run.State.BuildReady=false
assert(not W:_SpawnOne(graph,floor,'stale'))
quiet(function() W:Think() end);assert(W.Owner==nil and #W.Entities==0,'stale owner retained')
for _,e in ipairs(copies) do assert(not IsValid(e),'stale native body retained') end
Run.State.BuildReady=true;init(graph)
for _,e in ipairs(W.Entities) do if e.LODWanderFloor==floor and not e.LODDead then e:Remove();break end end
mode='reset';assert(not W:_SpawnOne(graph,floor,'native-reset'),'native reset registered stale body');mode=nil
assert(W.Owner==nil and #W.Entities==0,'native reset retained state')
init(graph)
local retained=H.serial(Run.State.EncounterEcology)
D:Cleanup();assert(W.Owner==nil and #W.Entities==0 and next(W.SpawnOrdinal)==nil,'canonical cleanup missed wander state')
assert(H.serial(Run.State.EncounterEcology)==retained,'cleanup erased campaign receipt')
print('BESTIARY_B23_PASS pools='..poolCount..' production spawn/replay/role/caps/native failures/20s replacement/exact owner/cleanup')
return {H=H,W=W,prepare=prepare,init=init,bounds=bounds,signature=signature,new=new,
 setTime=function(t) now=t end,setHeroes=function(t) heroes=t end,entity=entity,quiet=quiet,class=class,
 setMode=function(v) mode=v end,traceHull=traceHull,traceLine=traceLine}
