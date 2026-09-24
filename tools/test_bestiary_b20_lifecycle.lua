-- Exercise actual RunManager campaign/build/succession/regeneration ownership.
-- Geometry, encounter planning and native player release are boundary doubles;
-- ecology selection/receipt semantics are covered by the separate planner gate.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
LOD={Config={Models={Characters={}},Progression={LayoutAttempts=1}}};GM={}
FCVAR_ARCHIVE=0
local vars={}
function CreateConVar(id,default)
    local cv={value=tonumber(default)}
    function cv:GetInt() return self.value end
    vars[id]=cv;return cv
end
GetConVar=function() return nil end
hook={Add=noop};concommand={Add=noop}
SysTime=function() return 100 end
CurTime=SysTime
ErrorNoHalt=noop
local map='gm_flatgrass'
game={GetMap=function() return map end}
player={GetAll=function() return {} end}
dofile(root..'sh_rng.lua')
dofile(root..'sv_run_manager.lua')
local R=LOD.RunManager
R.HoldPlayersForBuild=noop;R.PromoteWaitingSpectators=noop
R._ValidateConfiguredModels=noop
R._SortedConnectedPlayers=function() return {} end
local generationFails,buildFails=false,false
local generated,committed,released=0,0,0
local lastGraph
LOD.MazeGenerator={Generate=function(_,seed)
    if generationFails then return nil,'injected generation failure' end
    generated=generated+1
    local g={LevelSeed=seed,Validation={cellCount=1,criticalVerticalTransitions=0},Attempt=1}
    lastGraph=g;return g
end}
LOD.ProgressionDirector={Plan=function() return true end,ResetLevelState=noop,SyncAll=noop,
    CommitBuiltLevel=function()
        assert(R.State.BuildReady,'progression must publish only a ready build')
        assert(R.State.EncounterEcology.graph==R.State.Graph,'release preceded ecology commit')
        released=released+1
    end}
LOD.MazeBuilder={Build=function(_,graph)
    assert(not R.State.BuildReady,'planning released players early')
    graph.EncounterPlan={state=R.State,previous=R.State.EncounterEcology}
    if buildFails then return false,'injected post-encounter loot/event failure' end
    return true,{entityCount=0}
end}
LOD.EncounterDirector={CommitEcologyPlan=function(_,graph)
    local s=R.State
    assert(s.Graph==graph and s.BuildReport,'commit lacks published graph/report')
    assert(not s.BuildReady,'ecology commit occurred after player release')
    assert(graph.EncounterPlan.state==s,'commit belongs to another campaign')
    committed=committed+1
    s.EncounterEcology={graph=graph,level=s.Level,seed=s.LevelSeed,
        previous=graph.EncounterPlan.previous}
    return true
end}

vars.lod_campaign_seed.value=991
assert(R:NewCampaign())
local firstState,firstReceipt=R.State,R.State.EncounterEcology
local firstSeed=R.State.LevelSeed
assert(committed==1 and released==1 and generated==1)
assert(firstReceipt.previous==nil,'new campaign inherited history')

-- A complete encounter plan can still be rejected downstream. Neither an
-- unbuilt maze nor that rejected plan is allowed to consume novelty history.
generationFails=true
assert(not R:BuildCurrentLevel())
assert(committed==1 and released==1 and R.State.EncounterEcology==firstReceipt)
generationFails=false;buildFails=true
assert(not R:BuildCurrentLevel())
assert(lastGraph.EncounterPlan and lastGraph~=R.State.Graph)
assert(committed==1 and released==1 and R.State.EncounterEcology==firstReceipt)
assert(not R.State.BuildReady)
buildFails=false

-- Regeneration passes the old receipt to the planner and commits exactly once
-- only after success. The planner owns replacing, rather than accumulating, it.
assert(R:Regenerate())
assert(committed==2 and released==2 and R.State==firstState)
assert(R.State.LevelSeed==firstSeed and R.State.EncounterEcology.previous==firstReceipt)
local rebuildReceipt=R.State.EncounterEcology
assert(R:Regenerate(771))
assert(R.State.EncounterEcology.previous==rebuildReceipt and committed==3)
assert(R.State.LevelSeed==LOD.Seeds.Normalize(771))

local predecessor=R.State.EncounterEcology
R.State.LevelCleared=true
assert(R:AdvanceLevel() and R.State.Level==2)
assert(committed==4 and R.State.EncounterEcology.previous==predecessor)
assert(R.State.LevelSeed==LOD.Seeds.Normalize(LOD.Seeds.DeriveLevel(991,2)))

-- Same fixed campaign seed does not imply same campaign identity. NewCampaign
-- creates a fresh owner before planning, even if its first build later fails.
local oldState=R.State
buildFails=true
assert(not R:NewCampaign())
assert(R.State~=oldState and R.State.CampaignSeed==991)
assert(R.State.CampaignEpoch==oldState.CampaignEpoch+1)
assert(R.State.EncounterEcology==nil and lastGraph.EncounterPlan.previous==nil)
assert(committed==4)
buildFails=false
assert(R:BuildCurrentLevel())
assert(committed==5 and R.State.EncounterEcology.previous==nil)
map='gm_construct'
local receipt=R.State.EncounterEcology
assert(not R:BuildCurrentLevel())
assert(committed==5 and R.State.EncounterEcology==receipt)
print('PASS Bestiary B20 actual campaign/build lifecycle: success, post-plan failure, rebuild, override, succession, same-seed reset')
