-- A real, previously failing campaign must reach BuildReady and staging.
-- Unlike the smaller event fixture, load the production progression safety,
-- Neil/Black Gate, Warden arena and arrival reservations together.
local F=dofile('tools/event_expansion_fixture.lua')
local R,D,Run=F.R,F.D,F.Run
local root=F.root
dofile(root..'sv_m2_progression_safety.lua')
dofile(root..'sv_neil_brute.lua')
dofile(root..'sv_warden_arena.lua')
dofile(root..'sv_entry_safety.lua')
dofile(root..'sv_staging_deployment.lua')
for _,cv in pairs(F.convars) do
 function cv:GetInt() return tonumber(self.value) or 0 end
end
util.IsValidModel=function() return true end
local errors={}
ErrorNoHalt=function(message) errors[#errors+1]=message end

-- Native room discovery/presentation has its own engine gate. Execute its real
-- BuildCurrentLevel wrapper here and require it only after the complete build.
local huts=0
LOD.StagingDeployment.EnsureHut=function()
 assert(Run.State.BuildReady and Run.State.Graph and D.Context,'Staging preceded the complete maze')
 assert(#LOD.MazeBuilder.Entities>0,'No physical maze floors at staging handoff')
 huts=huts+1
 return true
end
dofile(root..'sv_campaign_bootstrap_reliability.lua')
local B=LOD.CampaignBootstrapReliability
local originalSelect,originalPlan=R.Select,D.Plan
local selections,plans,failedResources=0,{},{}
R.Select=function(self,...)
 selections=selections+1
 return originalSelect(self,...)
end
D.Plan=function(self,g,options)
 for _,entity in ipairs(failedResources) do assert(not IsValid(entity),'Rejected layout leaked physical resources') end
 assert(not Run.State.BuildReady,'Players released while the layout was still being validated')
 local before=WalletJSONEncode(Run.State.EventEcology)
 local ok,result,retry=originalPlan(self,g,options)
 assert(before==WalletJSONEncode(Run.State.EventEcology),'Planning advanced event history')
 local diag=D.LastPlanDiagnostics
 plans[#plans+1]={ok=ok,attempt=g.ProgressionLayoutAttempt,seed=g.LevelSeed,
  selected=table.concat(diag.selected,','),count=diag.count,reason=not ok and result or nil}
 if not ok then
  failedResources={}
  for _,entity in ipairs(LOD.MazeBuilder.Entities) do failedResources[#failedResources+1]=entity end
 end
 return ok,result,retry
end
local function clearObservations() selections=0;plans={};failedResources={} end
local function resourcesRemoved(from)
 for i=from,#F.created do assert(not IsValid(F.created[i]),'Failed build left a native resource') end
end
local function drain()
 while #F.timers>0 do
  local fn=table.remove(F.timers,1);fn()
 end
end
local function key(c) return F.G.CellKey(c.x,c.y,c.z) end
local function prove(g,plan)
 assert(LOD.GraphIntegrity:Audit(g).valid and D:ValidateRoutes(g))
 assert(g.Progression.Warden and g.Progression.Hunt and g.EntrySafety)
 local instances,blocked={},{}
 for _,instance in ipairs(plan.instances) do
  instances[instance.archetype]=true
  if instance.contract=='BLOCKADE' then blocked[instance.placement.edgeKey]=true end
 end
 for _,id in ipairs(plan.selected) do assert(instances[id],'Selected event was silently dropped') end
 local skeleton
 for _,instance in ipairs(plan.instances) do if instance.archetype=='skeleton_blockade' then skeleton=instance end end
 assert(skeleton and IsValid(skeleton.hostile) and IsValid(skeleton.barrier))
 local reach=F.walk(g,key(g.Start),blocked)
 assert(reach[skeleton.cellKey] and not reach[key(g.Progression.DeborahCell)],'Skeleton not approachable on required route')
 blocked[skeleton.placement.edgeKey]=nil
 assert(F.walk(g,key(g.Start),blocked)[key(g.Progression.DeborahCell)],'Skeleton resolution cannot restore rescue route')
 assert(D:ValidatePlacement(g,R.Definitions.skeleton_blockade,skeleton.placement))
end

-- This exact seed failed with "skeleton_blockade: nil" on main. It has zero
-- legal blockade candidates on its first progression-safe layout, not merely
-- an unlucky 64-cell search. Exercise real InitPostEntity -> bootstrap ->
-- NewCampaign -> physical build -> staging, not a replacement startup method.
F.convars.lod_campaign_seed.value='31676'
Run.State={}
local from=#F.created+1
F.hooks.LOD_BeginCampaign()
drain()
assert(Run.State.BuildReady,'Known empty-map campaign did not build: '..tostring(B.LastError))
assert(B.Recoveries==1 and #errors==0 and huts==1,'Startup/staging did not complete cleanly')
assert(Run.State.LevelSeed==1939356277,'Reproduction seed changed')
assert(#plans==2 and not plans[1].ok and plans[2].ok,'Expected real failed layout followed by successful layout')
assert(plans[1].reason:find('skeleton_blockade',1,true) and not plans[1].reason:find(': nil',1,true))
assert(plans[2].attempt>plans[1].attempt and plans[2].attempt<=LOD.Config.Progression.LayoutAttempts)
assert(selections==1 and plans[1].selected==plans[2].selected and plans[1].count==plans[2].count,
 'Layout recovery rerolled event identities/count')
local graph,plan=Run.State.Graph,D.Context.plan
prove(graph,plan)
assert(Run.State.BuildReport.eventPlacementRetries==1)
assert(Run.State.EventEcology.after.totalLevels==1,'Failed layout consumed a successful history level')
assert(D.BuildOptions==nil,'Frozen selection escaped the logical build')
local firstAttempt=plans[1].attempt
local expected=F.signature(plan)
local expectedSeed=graph.LevelSeed
local history=WalletJSONEncode(Run.State.EventEcology)
local count=F.nativeBuilds
assert(B:Ensure('already live',true) and F.nativeBuilds==count,'Recovery replaced a live campaign')
print('EVENT_BOOTSTRAP_RECOVERED seed=1939356277 failedLayout='..firstAttempt..' acceptedLayout='..graph.ProgressionLayoutAttempt
 ..' events='..table.concat(plan.selected,',')..' staging=ready')

-- Same-level regeneration deterministically repeats the same two layouts and
-- event selection, replaces old entities, and never advances drought history.
clearObservations()
assert(Run:BuildCurrentLevel())
drain()
assert(selections==1 and #plans==2 and Run.State.Graph.LevelSeed==expectedSeed)
assert(F.signature(D.Context.plan)==expected and WalletJSONEncode(Run.State.EventEcology)==history)
assert(huts==2 and not D:IsCurrent(plan.instances[1]))

-- The existing layout ceiling is global, including prior progression rejects.
-- Do not start a second 64-attempt budget after an event rejects a late layout.
local ceiling=LOD.Config.Progression.LayoutAttempts
LOD.Config.Progression.LayoutAttempts=firstAttempt
clearObservations();from=#F.created+1
local ok,reason=Run:BuildCurrentLevel()
LOD.Config.Progression.LayoutAttempts=ceiling
assert(not ok and reason:find('event-safe level',1,true) and reason:find('skeleton_blockade',1,true))
assert(#plans==1 and selections==1 and not D.Context and not Run.State.BuildReady and huts==2)
assert(WalletJSONEncode(Run.State.EventEcology)==history)
resourcesRemoved(from)

-- Native creation and broken authored callbacks are genuine failures, never
-- excuses to cycle through different layouts or substitute easier events.
local definition=R.Definitions.skeleton_blockade
local create,place=definition.Create,definition.Place
local nativeCalls=0
definition.Create=function(...) nativeCalls=nativeCalls+1;return nil,'injected native failure' end
clearObservations();from=#F.created+1
D.NextPreview='skeleton_blockade'
ok,reason=Run:BuildCurrentLevel(126835140)
definition.Create=create
assert(not ok and reason:find('event creation failed',1,true) and nativeCalls==1 and #plans==1)
assert(not Run.State.BuildReady and not D.Context and huts==2)
assert(WalletJSONEncode(Run.State.EventEcology)==history);resourcesRemoved(from)
definition.Place=function() error('injected authored callback failure') end
clearObservations();from=#F.created+1
D.NextPreview='skeleton_blockade'
ok,reason=Run:BuildCurrentLevel(126835140)
definition.Place=place
assert(not ok and reason:find('event callback failed',1,true) and #plans==1)
assert(not Run.State.BuildReady and not D.Context and huts==2)
assert(WalletJSONEncode(Run.State.EventEcology)==history);resourcesRemoved(from)

-- An explicit operator opt-out still builds immediately with no event draws.
clearObservations()
F.convars.lod_events_enabled.value='0'
assert(Run:BuildCurrentLevel(1939356277))
drain()
assert(selections==0 and #plans==1 and D.Context.plan.mode=='disabled' and huts==3)
assert(Run.State.BuildReport.eventPlacementRetries==0 and WalletJSONEncode(Run.State.EventEcology)==history)
F.convars.lod_events_enabled.value='1'
D:Cleanup('bootstrap regression complete');LOD.MazeBuilder:Cleanup()
R.Select,D.Plan=originalSelect,originalPlan
print('PASS event-aware startup: real failing seed, staging handoff, frozen count/identities, independent route proof, deterministic regeneration, bounded retries, cleanup/history, fatal failure classification and operator opt-out')
