LOD = LOD or {}

local RunManager = LOD.RunManager

util.AddNetworkString("LOD_RestartCampaign")

local restartInProgress = false

local function canRequestRestart(ply)
    if not RunManager or not RunManager.State or not RunManager.State.Failed then return false end
    if restartInProgress then return false end
    if not IsValid(ply) then return true end

    -- Any connected player may restart a completed/failed server-session run.
    -- Only the first accepted request wins; subsequent simultaneous requests
    -- arrive after restartInProgress is set or after the fresh campaign clears Failed.
    return true
end

function RunManager:RestartFailedCampaign(requester)
    if not canRequestRestart(requester) then return false, "campaign is not awaiting restart" end

    restartInProgress = true
    local oldLevel = self.State.Level or 1
    local oldSeed = self.State.CampaignSeed

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:ChatPrint("Restarting The Legend of Deborah from Level 1...")
        end
    end

    local ok, result = self:NewCampaign()
    restartInProgress = false

    if not ok then
        self.State.Failed = true
        self.State.FailureReason = "campaign restart build failure"
        if LOD.ProgressionDirector then
            LOD.ProgressionDirector:Announce("RESTART FAILED — TRY AGAIN")
            LOD.ProgressionDirector:SyncAll()
        end
        ErrorNoHalt("[LOD] Campaign restart failed: " .. tostring(result) .. "\n")
        return false, result
    end

    print(string.format(
        "[LOD] Campaign restarted in-place after failure. previousLevel=%d previousSeed=%s newSeed=%s",
        oldLevel,
        tostring(oldSeed),
        tostring(self.State.CampaignSeed)
    ))
    return true, result
end

net.Receive("LOD_RestartCampaign", function(_, ply)
    if not canRequestRestart(ply) then return end
    RunManager:RestartFailedCampaign(ply)
end)

concommand.Add("lod_restart_campaign", function(ply)
    if IsValid(ply) and not canRequestRestart(ply) then return end
    if not IsValid(ply) and (not RunManager.State or not RunManager.State.Failed or restartInProgress) then return end
    RunManager:RestartFailedCampaign(ply)
end)
