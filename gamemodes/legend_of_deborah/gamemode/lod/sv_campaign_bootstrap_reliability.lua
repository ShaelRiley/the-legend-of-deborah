LOD = LOD or {}
LOD.CampaignBootstrapReliability = LOD.CampaignBootstrapReliability or {}

local Bootstrap = LOD.CampaignBootstrapReliability
local WATCHDOG_NAME = "LOD_CampaignBootstrapReliability"

Bootstrap.Attempts = Bootstrap.Attempts or 0
Bootstrap.Recoveries = Bootstrap.Recoveries or 0
Bootstrap.LastReason = Bootstrap.LastReason or "none"
Bootstrap.LastError = Bootstrap.LastError or nil
Bootstrap.InProgress = false
Bootstrap.AutomaticAttempted = Bootstrap.AutomaticAttempted or false

local function runManager()
    return LOD.RunManager
end

local function campaignExists()
    local run = runManager()
    return run and run.State and run.State.CampaignSeed ~= nil
end

local function recoveryReady()
    return game.GetMap() == "gm_flatgrass"
        and IsValid(game.GetWorld())
        and #player.GetAll() > 0
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
    self.LastReason = tostring(reason or "recovery watchdog")

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

-- sv_run_manager's InitPostEntity hook remains the normal campaign-start authority.
-- This narrow watchdog exists only for a missed lifecycle edge, such as a late Lua
-- reload with a player already standing in gm_flatgrass. Once the canonical run
-- has any campaign seed, the watchdog removes itself and adds no recurring work.
timer.Create(WATCHDOG_NAME, 1.0, 0, function()
    if campaignExists() then
        timer.Remove(WATCHDOG_NAME)
        return
    end
    if recoveryReady() and not Bootstrap.AutomaticAttempted then
        Bootstrap:Ensure("post-load live-player watchdog", true)
    end
end)

concommand.Add("lod_campaign_bootstrap_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local run = runManager()
    local state = run and run.State or {}
    local entities = LOD.MazeBuilder and LOD.MazeBuilder.Entities or {}
    local line = string.format(
        "seed=%s buildReady=%s level=%s players=%d played=%d active=%d mazeEntities=%d attempts=%d recoveries=%d lastReason=%s lastError=%s",
        tostring(state.CampaignSeed), tostring(state.BuildReady == true), tostring(state.Level or "none"),
        #player.GetAll(), table.Count(state.PlayedIdentities or {}), table.Count(state.ActiveIdentity or {}),
        #entities, Bootstrap.Attempts or 0, Bootstrap.Recoveries or 0,
        tostring(Bootstrap.LastReason or "none"), tostring(Bootstrap.LastError or "none"))
    print("[LOD:BOOTSTRAP] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
