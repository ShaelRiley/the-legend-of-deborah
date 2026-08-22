LOD = LOD or {}

local RunManager = LOD.RunManager

util.AddNetworkString("LOD_RestartCampaign")

local restartInProgress = false
LOD.CampaignRestartAudit = LOD.CampaignRestartAudit or {
    requests = 0,
    scheduled = 0,
    completed = 0,
    failures = 0,
    staleCallbacksRejected = 0
}
local RestartAudit = LOD.CampaignRestartAudit

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
    RestartAudit.requests = RestartAudit.requests + 1
    RestartAudit.scheduled = RestartAudit.scheduled + 1

    local oldLevel = self.State.Level or 1
    local oldSeed = self.State.CampaignSeed
    local oldEpoch = self.State.CampaignEpoch or 0
    RestartAudit.lastOldLevel = oldLevel
    RestartAudit.lastOldSeed = oldSeed
    RestartAudit.lastOldEpoch = oldEpoch
    RestartAudit.lastStage = "scheduled"
    RestartAudit.lastError = nil

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:ChatPrint("Restarting The Legend of Deborah from Level 1...")
        end
    end

    -- The final PlayerDeath schedules spectator work for the next server tick.
    -- Rebuilding synchronously inside this net callback let that old callback
    -- run against the replacement state. Drain the death frame first, then build
    -- under a new campaign epoch.
    timer.Simple(0, function()
        if not restartInProgress then return end
        if not self:IsCampaignEpoch(oldEpoch) or not self.State.Failed then
            restartInProgress = false
            RestartAudit.staleCallbacksRejected = RestartAudit.staleCallbacksRejected + 1
            RestartAudit.lastStage = "stale-request-rejected"
            return
        end

        RestartAudit.lastStage = "building"
        local callOK, packedOrError = xpcall(function()
            return {self:NewCampaign()}
        end, debug.traceback)

        local ok = callOK and packedOrError[1] == true
        local result = callOK and packedOrError[2] or packedOrError
        restartInProgress = false

        if not ok then
            RestartAudit.failures = RestartAudit.failures + 1
            RestartAudit.lastStage = "failed"
            RestartAudit.lastError = tostring(result)
            self.State.Failed = true
            self.State.FailureReason = "campaign restart build failure"
            if LOD.ProgressionDirector then
                LOD.ProgressionDirector:Announce("RESTART FAILED — TRY AGAIN")
                LOD.ProgressionDirector:SyncAll()
            end
            ErrorNoHalt("[LOD] Campaign restart failed: " .. tostring(result) .. "\n")
            return
        end

        RestartAudit.completed = RestartAudit.completed + 1
        RestartAudit.lastStage = "complete"
        RestartAudit.lastNewSeed = self.State.CampaignSeed
        RestartAudit.lastNewEpoch = self.State.CampaignEpoch
        print(string.format(
            "[LOD] Campaign restarted in-place after failure. previousLevel=%d previousSeed=%s newSeed=%s epoch=%d",
            oldLevel,
            tostring(oldSeed),
            tostring(self.State.CampaignSeed),
            self.State.CampaignEpoch or 0
        ))
    end)

    return true, "campaign restart scheduled"
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

concommand.Add("lod_dev_force_party_wipe", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local prepared = 0
    for _, target in ipairs(player.GetAll()) do
        if IsValid(target) and RunManager:IsActivePlayer(target) then
            local ps = RunManager:GetPlayerState(target)
            if ps then
                ps.lives = 1
                ps.eliminated = false
                ps.respawnAt = nil
                RunManager:_SyncPlayerVars(target)
                prepared = prepared + 1
            end
        end
    end
    for _, target in ipairs(player.GetAll()) do
        if IsValid(target) and RunManager:IsActivePlayer(target) and target:Alive() then
            target:Kill()
        end
    end
    print(string.format("[LOD:RESTART] prepared real party wipe for %d active player(s)", prepared))
end)

concommand.Add("lod_campaign_restart_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = RunManager.State
    local seedChanged = RestartAudit.lastOldSeed ~= nil
        and RestartAudit.lastNewSeed ~= nil
        and RestartAudit.lastOldSeed ~= RestartAudit.lastNewSeed
    local passed = RestartAudit.completed > 0
        and RestartAudit.failures == 0
        and RestartAudit.lastStage == "complete"
        and not restartInProgress
        and state and state.BuildReady
        and not state.Failed
        and state.Level == 1
        and seedChanged
    local line = string.format(
        "requests=%d scheduled=%d completed=%d failures=%d stage=%s oldEpoch=%d newEpoch=%d level=%d buildReady=%s failed=%s seedChanged=%s staleRejected=%d result=%s",
        RestartAudit.requests, RestartAudit.scheduled, RestartAudit.completed, RestartAudit.failures,
        tostring(RestartAudit.lastStage or "none"), RestartAudit.lastOldEpoch or 0,
        RestartAudit.lastNewEpoch or 0, state and state.Level or 0,
        tostring(state and state.BuildReady == true), tostring(state and state.Failed == true),
        tostring(seedChanged), RestartAudit.staleCallbacksRejected,
        passed and "PASS" or "FAIL"
    )
    print("[LOD:CAMPAIGN-RESTART] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
