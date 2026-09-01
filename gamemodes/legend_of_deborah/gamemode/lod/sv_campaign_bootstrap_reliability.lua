LOD = LOD or {}
LOD.CampaignBootstrapReliability = LOD.CampaignBootstrapReliability or {}

local Bootstrap = LOD.CampaignBootstrapReliability
local WATCHDOG_NAME = "LOD_CampaignBootstrapReliability"

Bootstrap.Attempts = Bootstrap.Attempts or 0
Bootstrap.Recoveries = Bootstrap.Recoveries or 0
Bootstrap.LastReason = Bootstrap.LastReason or "none"
Bootstrap.LastError = Bootstrap.LastError or nil
Bootstrap.InProgress = false
-- Re-including this reliability module during development should re-arm its one
-- automatic recovery attempt. campaignExists() still prevents duplicate campaigns.
Bootstrap.AutomaticAttempted = false

local function runManager()
    return LOD.RunManager
end

local function campaignExists()
    local run = runManager()
    return run and run.State and run.State.CampaignSeed ~= nil
end

local function recoveryReady()
    -- A connected player is a stronger readiness signal than IsValid(game.GetWorld()).
    -- Worldspawn validity semantics are not needed here and could suppress recovery
    -- even though the map/player lifecycle is already live. BuildCurrentLevel owns
    -- the authoritative gm_flatgrass/map-geometry validation.
    return game.GetMap() == "gm_flatgrass" and #player.GetAll() > 0
end

function Bootstrap:Ensure(reason, automatic)
    local run = runManager()
    if not run or not run.NewCampaign then return false, "RunManager unavailable" end
    if campaignExists() then return true end
    if self.InProgress then return false, "campaign bootstrap already in progress" end
    if not recoveryReady() then return false, "map/player state not ready" end
    if automatic and self.AutomaticAttempted then
        return false, self.LastError or "automatic recovery already attempted"
    end

    if automatic then self.AutomaticAttempted = true end
    self.InProgress = true
    self.Attempts = (self.Attempts or 0) + 1
    self.LastReason = tostring(reason or "recovery")

    print(string.format(
        "[LOD:BOOTSTRAP] campaign seed missing with live player(s); recovery start reason=%s attempt=%d",
        self.LastReason, self.Attempts))

    local ok, result = run:NewCampaign()
    self.InProgress = false

    if not ok then
        self.LastError = tostring(result)
        ErrorNoHalt("[LOD:BOOTSTRAP] recovery failed: " .. self.LastError .. "\n")
        return false, result
    end

    self.Recoveries = (self.Recoveries or 0) + 1
    self.LastError = nil
    print(string.format(
        "[LOD:BOOTSTRAP] recovery complete seed=%s buildReady=%s recoveries=%d",
        tostring(run.State and run.State.CampaignSeed),
        tostring(run.State and run.State.BuildReady == true),
        self.Recoveries))
    return true, result
end

local function ensureFromLifecycle(reason)
    if campaignExists() or not recoveryReady() then return end
    Bootstrap:Ensure(reason, true)
end

-- InitPostEntity remains the normal RunManager startup authority. These hooks are
-- synchronous recovery seams for the exact observed failure mode: a player can be
-- alive on gm_flatgrass while CampaignSeed is still nil. Unlike the old deferred
-- PlayerInitialSpawn branch, recovery creates the canonical campaign before asking
-- TryActivatePlayer to consume it.
hook.Add("PlayerInitialSpawn", "LOD_CampaignBootstrapInitialSpawn", function()
    ensureFromLifecycle("PlayerInitialSpawn")
end)

hook.Add("PlayerSpawn", "LOD_CampaignBootstrapPlayerSpawn", function()
    ensureFromLifecycle("PlayerSpawn")
end)

-- Covers a hot/late module load where both lifecycle events already happened.
-- This is supplementary only; campaign creation no longer depends on this timer.
timer.Simple(0, function()
    ensureFromLifecycle("module-load existing-player")
end)

-- Keep a bounded fallback for unusual load ordering. It removes itself as soon as
-- the canonical campaign exists and never rebuilds a live campaign.
timer.Create(WATCHDOG_NAME, 1.0, 0, function()
    if campaignExists() then
        timer.Remove(WATCHDOG_NAME)
        return
    end
    if recoveryReady() and not Bootstrap.AutomaticAttempted then
        Bootstrap:Ensure("post-load live-player watchdog", true)
    end
end)

local function commandAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return not IsValid(ply) or ply:IsAdmin()
end

-- Deterministic escape hatch for development. This invokes the same RunManager
-- NewCampaign authority directly; it is not a separate builder or regeneration path.
concommand.Add("lod_campaign_bootstrap_start", function(ply)
    if not commandAllowed(ply) then return end
    local ok, result = Bootstrap:Ensure("manual bootstrap command", false)
    local line = ok
        and "campaign bootstrap command PASS"
        or ("campaign bootstrap command FAILED: " .. tostring(result))
    print("[LOD:BOOTSTRAP] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

concommand.Add("lod_campaign_bootstrap_status", function(ply)
    if not commandAllowed(ply) then return end

    local run = runManager()
    local state = run and run.State or {}
    local entities = LOD.MazeBuilder and LOD.MazeBuilder.Entities or {}
    local line = string.format(
        "map=%s ready=%s seed=%s buildReady=%s level=%s players=%d played=%d active=%d mazeEntities=%d attempts=%d recoveries=%d autoAttempted=%s watchdog=%s worldValid=%s lastReason=%s lastError=%s",
        tostring(game.GetMap()), tostring(recoveryReady()), tostring(state.CampaignSeed),
        tostring(state.BuildReady == true), tostring(state.Level or "none"),
        #player.GetAll(), table.Count(state.PlayedIdentities or {}), table.Count(state.ActiveIdentity or {}),
        #entities, Bootstrap.Attempts or 0, Bootstrap.Recoveries or 0,
        tostring(Bootstrap.AutomaticAttempted == true), tostring(timer.Exists(WATCHDOG_NAME)),
        tostring(IsValid(game.GetWorld())), tostring(Bootstrap.LastReason or "none"),
        tostring(Bootstrap.LastError or "none"))
    print("[LOD:BOOTSTRAP] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
