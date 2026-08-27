LOD = LOD or {}
LOD.MultiplayerHardening = LOD.MultiplayerHardening or {}

local Multiplayer = LOD.MultiplayerHardening
local RunManager = LOD.RunManager
local Loot = LOD.LootDirector
local DeathTetris = LOD.DeathTetris
local Intermission = LOD.IntermissionTetris
local CC = LOD.Config

if not RunManager or not CC then return end

local MAX_ACTIVE = CC.MaxActivePlayers or 4
local DEATH_ACTION_ENTER_TETRIS = 1
local DEATH_ACTION_RESPAWN = 2

Multiplayer.Stats = Multiplayer.Stats or {
    revives = 0,
    reviveActive = 0,
    reviveWaiting = 0,
    deathReconnects = 0,
    deathSessionsSuspended = 0,
    intermissionSessionsSuspended = 0,
    timelineShifts = 0
}

local function connectedPlayerForIdentity(identity)
    if not identity then return nil end
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and RunManager:IdentityOf(ply) == identity then return ply end
    end
end

function RunManager:ConnectedPlayerForIdentity(identity)
    return connectedPlayerForIdentity(identity)
end

-- Cross-system revival must never write ActiveIdentity directly. RunManager alone
-- owns the four active slots. A revived identity becomes campaign-eligible first;
-- if a slot is available it activates immediately, otherwise it remains a normal
-- waiting spectator until PromoteWaitingSpectators can admit it.
function RunManager:ReviveIdentity(identity)
    local ps = identity and self:GetPlayerState(identity)
    if not ps or not ps.eliminated or (ps.lives or 0) > 0 then
        return false, "identity is not eliminated"
    end

    ps.lives = 1
    ps.eliminated = false
    ps.eliminatedSince = nil
    ps.respawnAt = nil
    ps.armor = 0

    local ply = connectedPlayerForIdentity(identity)
    local activated = false
    if IsValid(ply) then
        activated = self:TryActivatePlayer(ply) == true
        self:_SyncPlayerVars(ply)
        if activated then
            timer.Simple(0, function()
                if not IsValid(ply) or self.State.Failed or not self.State.BuildReady then return end
                if self:IsActivePlayer(ply) and not ply:Alive() then
                    ply:UnSpectate()
                    ply:Spawn()
                end
            end)
        else
            self.State.WaitingSince[identity] = self.State.WaitingSince[identity] or CurTime()
            self:PutInRestrictedSpectator(ply)
        end
    end

    Multiplayer.Stats.revives = Multiplayer.Stats.revives + 1
    if activated then
        Multiplayer.Stats.reviveActive = Multiplayer.Stats.reviveActive + 1
        return true, "active"
    end
    Multiplayer.Stats.reviveWaiting = Multiplayer.Stats.reviveWaiting + 1
    return true, "waiting"
end

-- Preserve the existing extra-life rules while routing teammate revival through
-- RunManager's slot authority instead of mutating ActiveIdentity from LootDirector.
if Loot and not Loot.LODMultiplayerReviveAuthorityInstalled then
    Loot.LODMultiplayerReviveAuthorityInstalled = true

    function Loot:_GrantExtraLife(ply)
        local ps = RunManager:GetPlayerState(ply)
        if not ps then return false end
        local cap = CC.Lives.MaxLives or 4

        if (ps.lives or 0) < cap then
            ps.lives = ps.lives + 1
            RunManager:_SyncPlayerVars(ply)
            self.Stats.extraLives = (self.Stats.extraLives or 0) + 1
            return true, "EXTRA LIFE"
        end

        local ownerId = RunManager:IdentityOf(ply)
        local revivedId = self:_OldestEliminatedTeammate(ownerId)
        if not revivedId then return false end

        local revived, disposition = RunManager:ReviveIdentity(revivedId)
        if not revived then return false end

        self.Stats.extraLives = (self.Stats.extraLives or 0) + 1
        if disposition == "active" then
            return true, "EXTRA LIFE REVIVED A TEAMMATE"
        end
        return true, "EXTRA LIFE REVIVED A TEAMMATE — WAITING FOR AN ACTIVE SLOT"
    end
end

local function fixedDeathMandatoryEnd(state)
    if not state then return nil end
    local authored = (state.startedAt or CurTime()) + (CC.Lives.RespawnDelay or 20)
    state.fixedMandatoryEndsAt = state.fixedMandatoryEndsAt or authored
    return state.fixedMandatoryEndsAt
end

-- Death-Tetris line clears award next-life HP only. The GDD's mandatory death
-- wait is a fixed twenty seconds. Keep the old mutable mandatoryEndsAt field
-- harmless until DeathTetris is later consolidated by making this public query
-- and the authoritative respawn receiver use the immutable deadline instead.
if DeathTetris then
    function DeathTetris:GetMandatoryRemaining(plyOrIdentity)
        local identity = isstring(plyOrIdentity) and plyOrIdentity
            or (IsValid(plyOrIdentity) and RunManager:IdentityOf(plyOrIdentity) or nil)
        local state = identity and self.Deaths and self.Deaths[identity]
        local endsAt = fixedDeathMandatoryEnd(state)
        if not endsAt then return nil end
        return math.max(0, endsAt - CurTime())
    end

    -- Replace the original receiver so the obsolete line-clear wait reduction can
    -- never authorize an early respawn. Session input remains owned by DeathTetris.
    net.Receive("LOD_DeathTetrisAction", function(_, ply)
        if not IsValid(ply) or ply:Alive() then return end
        local identity = RunManager:IdentityOf(ply)
        local ps = identity and RunManager:GetPlayerState(identity)
        local deathState = identity and DeathTetris.Deaths and DeathTetris.Deaths[identity]
        if not identity or not ps or not deathState or ps.eliminated or ps.lives <= 0
            or not RunManager:IsActivePlayer(ply)
        then
            return
        end

        local action = net.ReadUInt(2)
        local now = CurTime()
        local mandatoryEndsAt = fixedDeathMandatoryEnd(deathState) or now
        local remaining = math.max(0, mandatoryEndsAt - now)

        if action == DEATH_ACTION_ENTER_TETRIS then
            if remaining <= 0 or deathState.tetrisStarted or now >= (deathState.hardCapAt or 0) then return end
            DeathTetris:StartSession(ply, "death", deathState.hardCapAt)
        elseif action == DEATH_ACTION_RESPAWN then
            if remaining > 0 then return end
            ps.respawnAt = nil
            DeathTetris:EndDeath(identity)
            ply:UnSpectate()
            ply:Spawn()
        end
    end)

    -- A network disconnect destroys only the live UI/game session, not the
    -- identity's death eligibility. Reconnecting before the hard cap can restart
    -- Tetris and/or respawn once the fixed mandatory wait has elapsed.
    hook.Remove("PlayerDisconnected", "LOD_DeathTetrisDisconnectCleanup")
    hook.Add("PlayerDisconnected", "LOD_DeathTetrisSuspendDisconnectedIdentity", function(ply)
        local identity = RunManager:IdentityOf(ply)
        if not identity then return end
        local session = DeathTetris.Sessions and DeathTetris.Sessions[identity]
        local deathState = DeathTetris.Deaths and DeathTetris.Deaths[identity]
        if session then
            DeathTetris:EndSession(identity)
            Multiplayer.Stats.deathSessionsSuspended = Multiplayer.Stats.deathSessionsSuspended + 1
        end
        if deathState then
            deathState.tetrisStarted = false
            deathState.tetrisStartedAt = nil
        end
    end)

    hook.Add("PlayerInitialSpawn", "LOD_DeathTetrisRestoreIdentity", function(ply)
        timer.Simple(0.65, function()
            if not IsValid(ply) then return end
            local identity = RunManager:IdentityOf(ply)
            local ps = identity and RunManager:GetPlayerState(identity)
            local deathState = identity and DeathTetris.Deaths and DeathTetris.Deaths[identity]
            if not ps or not deathState or ps.eliminated or ps.lives <= 0 or ply:Alive()
                or not RunManager:IsActivePlayer(ply)
            then
                return
            end
            if CurTime() >= (deathState.hardCapAt or 0) then return end

            deathState.tetrisStarted = false
            deathState.tetrisStartedAt = nil
            ply:SetNW2Bool("LOD_DeathInteraction", true)
            ply:SetNW2Bool("LOD_DeathTetrisActive", false)
            ply:SetNW2Float("LOD_DeathStartedAt", deathState.startedAt or CurTime())
            ply:SetNW2Float("LOD_DeathHardCapAt", deathState.hardCapAt or CurTime())
            ply:SetNW2Float("LOD_RespawnRemaining", DeathTetris:GetMandatoryRemaining(identity) or 0)
            ply:SetNW2Int("LOD_TetrisNextLifeBonus", ps.nextLifeHPBonus or 0)
            Multiplayer.Stats.deathReconnects = Multiplayer.Stats.deathReconnects + 1
        end)
    end)

    local nextDeathOwnershipSync = 0
    hook.Add("Think", "LOD_DeathTetrisActiveSlotOwnership", function()
        if CurTime() < nextDeathOwnershipSync then return end
        nextDeathOwnershipSync = CurTime() + 0.25
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and not ply:Alive() then
                local identity = RunManager:IdentityOf(ply)
                local ps = identity and RunManager:GetPlayerState(identity)
                local deathState = identity and DeathTetris.Deaths and DeathTetris.Deaths[identity]
                local eligible = ps and deathState and not ps.eliminated and ps.lives > 0
                    and RunManager:IsActivePlayer(ply) and CurTime() < (deathState.hardCapAt or 0)
                ply:SetNW2Bool("LOD_DeathInteraction", eligible == true)
                if not eligible then ply:SetNW2Bool("LOD_DeathTetrisActive", false) end
            end
        end
    end)
end

if Intermission then
    -- Every admitted campaign identity present in PlayerState at level clear owns
    -- the same optional twenty-second intermission opportunity. This includes an
    -- identity that happens to be disconnected when Deborah is rescued and then
    -- reconnects before the window closes.
    local WINDOW_SECONDS = 20
    function Intermission:OpenWindow()
        self:EndAll()
        local endsAt = CurTime() + WINDOW_SECONDS
        for identity, ps in pairs(RunManager.State.PlayerState or {}) do
            if ps and RunManager.State.PlayedIdentities[identity] then
                self.Pending[identity] = {endsAt = endsAt, started = false}
                local ply = connectedPlayerForIdentity(identity)
                if IsValid(ply) then
                    ply:SetNW2Bool("LOD_IntermissionTetrisAvailable", true)
                end
            end
        end
    end

    -- Preserve Pending across disconnect. An active board is discarded because
    -- no player can legally provide input while disconnected; reconnecting during
    -- the same window may start a fresh session from the still-valid opportunity.
    hook.Remove("PlayerDisconnected", "LOD_IntermissionTetrisDisconnectCleanup")
    hook.Add("PlayerDisconnected", "LOD_IntermissionTetrisSuspendDisconnectedIdentity", function(ply)
        local identity = RunManager:IdentityOf(ply)
        if not identity then return end
        if Intermission.Sessions and Intermission.Sessions[identity] then
            Intermission.Sessions[identity] = nil
            Multiplayer.Stats.intermissionSessionsSuspended = Multiplayer.Stats.intermissionSessionsSuspended + 1
        end
    end)
end

local function shiftDeadline(value, delta)
    return value and (value + delta) or nil
end

function Multiplayer:ShiftIdentityDeadlines(delta)
    if not delta or delta <= 0 then return end

    if DeathTetris then
        for _, state in pairs(DeathTetris.Deaths or {}) do
            state.startedAt = shiftDeadline(state.startedAt, delta)
            state.mandatoryEndsAt = shiftDeadline(state.mandatoryEndsAt, delta)
            state.fixedMandatoryEndsAt = shiftDeadline(state.fixedMandatoryEndsAt, delta)
            state.hardCapAt = shiftDeadline(state.hardCapAt, delta)
            state.tetrisStartedAt = shiftDeadline(state.tetrisStartedAt, delta)
        end
        for _, session in pairs(DeathTetris.Sessions or {}) do
            session.startedAt = shiftDeadline(session.startedAt, delta)
            session.endsAt = shiftDeadline(session.endsAt, delta)
            session.nextFallAt = shiftDeadline(session.nextFallAt, delta)
            session.nextSync = shiftDeadline(session.nextSync, delta)
            session.inputWindowAt = shiftDeadline(session.inputWindowAt, delta)
            session.lockDeadline = shiftDeadline(session.lockDeadline, delta)
        end
    end

    if Intermission then
        for _, pending in pairs(Intermission.Pending or {}) do
            pending.endsAt = shiftDeadline(pending.endsAt, delta)
            pending.nextSync = shiftDeadline(pending.nextSync, delta)
        end
        for _, session in pairs(Intermission.Sessions or {}) do
            session.endsAt = shiftDeadline(session.endsAt, delta)
            session.nextFallAt = shiftDeadline(session.nextFallAt, delta)
            session.nextSync = shiftDeadline(session.nextSync, delta)
            session.inputWindowAt = shiftDeadline(session.inputWindowAt, delta)
            session.lockDeadline = shiftDeadline(session.lockDeadline, delta)
        end
    end

    self.Stats.timelineShifts = self.Stats.timelineShifts + 1
end

-- RunManager already freezes the campaign clock when every played identity is
-- disconnected. Extend that same pause to Tetris module-local deadlines so a
-- full-party disconnect/reconnect cannot consume death or intermission time.
if not RunManager.LODMultiplayerTimelineWrapped then
    RunManager.LODMultiplayerTimelineWrapped = true
    local baseUpdateFreezeState = RunManager.UpdateFreezeState
    function RunManager:UpdateFreezeState()
        local wasFrozen = self.State and self.State.SimulationFrozen == true
        local freezeStarted = wasFrozen and self.State.FreezeStarted or nil
        local result = baseUpdateFreezeState(self)
        if wasFrozen and freezeStarted and self.State and not self.State.SimulationFrozen then
            Multiplayer:ShiftIdentityDeadlines(math.max(0, CurTime() - freezeStarted))
        end
        return result
    end
end

local function activeCount(state)
    local count = 0
    for _, active in pairs(state.ActiveIdentity or {}) do
        if active then count = count + 1 end
    end
    return count
end

local function auditMultiplayerState()
    local state = RunManager.State or {}
    local failures = {}
    local warnings = {}
    local connected = player.GetAll()
    local connectedIdentity = {}
    local livingActive = 0
    local waiting = 0

    for _, ply in ipairs(connected) do
        if IsValid(ply) then
            local identity = RunManager:IdentityOf(ply)
            if identity then
                if connectedIdentity[identity] and connectedIdentity[identity] ~= ply then
                    failures[#failures + 1] = "duplicate connected identity " .. tostring(identity)
                end
                connectedIdentity[identity] = ply
            end
            if RunManager:IsActivePlayer(ply) and ply:Alive() then livingActive = livingActive + 1 end
            if identity and state.WaitingSince and state.WaitingSince[identity] then waiting = waiting + 1 end
        end
    end

    local active = activeCount(state)
    if active > MAX_ACTIVE then
        failures[#failures + 1] = string.format("active slots %d > cap %d", active, MAX_ACTIVE)
    end

    for identity, enabled in pairs(state.ActiveIdentity or {}) do
        if enabled then
            local ps = state.PlayerState and state.PlayerState[identity]
            if not ps then
                failures[#failures + 1] = "active identity missing PlayerState " .. tostring(identity)
            elseif ps.eliminated or (ps.lives or 0) <= 0 then
                failures[#failures + 1] = "eliminated identity occupies active slot " .. tostring(identity)
            end
            if not connectedIdentity[identity] then
                failures[#failures + 1] = "disconnected identity occupies active slot " .. tostring(identity)
            end
        end
    end

    for identity in pairs(state.WaitingSince or {}) do
        if state.ActiveIdentity and state.ActiveIdentity[identity] then
            failures[#failures + 1] = "identity is both active and waiting " .. tostring(identity)
        end
    end

    local hostileTargetFailures = 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and not hostile.LODDead and IsValid(hostile.LODTarget) then
            local target = hostile.LODTarget
            if target:IsPlayer() and (not target:Alive() or not RunManager:IsActivePlayer(target)) then
                hostileTargetFailures = hostileTargetFailures + 1
            end
        end
    end
    if hostileTargetFailures > 0 then
        failures[#failures + 1] = string.format("%d hostile target(s) point at non-active/dead players", hostileTargetFailures)
    end

    local orphanLoot = 0
    if Loot then
        for _, ent in ipairs(Loot.Entities or {}) do
            if IsValid(ent) then
                local owner = ent.LODLootOwnerIdentity
                if not owner or not state.PlayerState or not state.PlayerState[owner] then orphanLoot = orphanLoot + 1 end
            end
        end
    end
    if orphanLoot > 0 then failures[#failures + 1] = string.format("%d loot entity owner(s) lack PlayerState", orphanLoot) end

    local orphanDeaths = 0
    if DeathTetris then
        for identity in pairs(DeathTetris.Deaths or {}) do
            if not state.PlayerState or not state.PlayerState[identity] then orphanDeaths = orphanDeaths + 1 end
        end
    end
    if orphanDeaths > 0 then failures[#failures + 1] = string.format("%d death interaction(s) lack PlayerState", orphanDeaths) end

    local orphanIntermission = 0
    if Intermission then
        for identity in pairs(Intermission.Pending or {}) do
            if not state.PlayerState or not state.PlayerState[identity] then orphanIntermission = orphanIntermission + 1 end
        end
    end
    if orphanIntermission > 0 then failures[#failures + 1] = string.format("%d intermission identity(s) lack PlayerState", orphanIntermission) end

    if #connected < 2 then warnings[#warnings + 1] = "fewer than two connected clients; multiplayer interaction not yet exercised" end
    if active < math.min(#connected, MAX_ACTIVE) and not state.LevelCleared and not state.Failed then
        warnings[#warnings + 1] = "some connected clients are not active (may be intentional waiting/elimination)"
    end

    return {
        connected = #connected,
        played = table.Count(state.PlayedIdentities or {}),
        active = active,
        livingActive = livingActive,
        waiting = waiting,
        failures = failures,
        warnings = warnings,
        result = #failures == 0 and "PASS" or "FAIL"
    }
end

concommand.Add("lod_multiplayer_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local report = auditMultiplayerState()
    local line = string.format(
        "connected=%d played=%d active=%d/%d living=%d waiting=%d failures=%d warnings=%d result=%s",
        report.connected, report.played, report.active, MAX_ACTIVE, report.livingActive,
        report.waiting, #report.failures, #report.warnings, report.result)
    print("[LOD:MULTIPLAYER] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
    for _, text in ipairs(report.failures) do
        print("[LOD:MULTIPLAYER] FAIL " .. text)
        if IsValid(ply) then ply:ChatPrint("FAIL: " .. text) end
    end
    for _, text in ipairs(report.warnings) do
        print("[LOD:MULTIPLAYER] WARN " .. text)
        if IsValid(ply) then ply:ChatPrint("WARN: " .. text) end
    end
end)

concommand.Add("lod_multiplayer_lifecycle_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local s = Multiplayer.Stats
    local line = string.format(
        "revives=%d active=%d waiting=%d deathReconnects=%d deathSuspends=%d intermissionSuspends=%d timelineShifts=%d",
        s.revives or 0, s.reviveActive or 0, s.reviveWaiting or 0,
        s.deathReconnects or 0, s.deathSessionsSuspended or 0,
        s.intermissionSessionsSuspended or 0, s.timelineShifts or 0)
    print("[LOD:MULTIPLAYER-LIFECYCLE] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
