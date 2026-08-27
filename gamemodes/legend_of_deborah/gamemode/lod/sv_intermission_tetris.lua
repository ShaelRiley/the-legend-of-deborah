LOD = LOD or {}
LOD.IntermissionTetris = LOD.IntermissionTetris or {}

local Intermission = LOD.IntermissionTetris
local RunManager = LOD.RunManager
local Tetris = LOD.Tetris

if not RunManager or not Tetris then return end

local WINDOW_SECONDS = 20
local ACTION_START = 1
local INPUT_LEFT = 1
local INPUT_RIGHT = 2
local INPUT_ROTATE = 3
local INPUT_SOFT_DROP = 4
local INPUT_HARD_DROP = 5

local EVENT_NONE = 0
local EVENT_ROTATE = 1
local EVENT_HARD_DROP = 2
local EVENT_LOCK = 3
local EVENT_LINE_CLEAR = 4
local EVENT_GAME_OVER = 5

util.AddNetworkString("LOD_IntermissionTetrisState")
util.AddNetworkString("LOD_IntermissionTetrisAction")
util.AddNetworkString("LOD_IntermissionTetrisInput")

Intermission.Pending = Intermission.Pending or {}
Intermission.Sessions = Intermission.Sessions or {}

-- The live production contract is now a minimum twenty-second rescue intermission.
-- Keep the shared progression constant aligned so RunManager's existing transition
-- clock, diagnostics, and later Warden celebration code all observe the same value.
LOD.Config.Progression.IntermissionSeconds = WINDOW_SECONDS

local function connectedPlayerForIdentity(identity)
    for _, ply in ipairs(player.GetAll()) do
        if RunManager:IdentityOf(ply) == identity then return ply end
    end
end

local function writeState(ply, active, available, session, endsAt)
    if not IsValid(ply) then return end
    net.Start("LOD_IntermissionTetrisState")
    net.WriteBool(active == true)
    net.WriteBool(available == true)
    net.WriteFloat(math.max(0, (endsAt or CurTime()) - CurTime()))

    if active and session then
        local game = session.game
        for y = 1, Tetris.Height do
            for x = 1, Tetris.Width do net.WriteUInt(game.board[y][x] or 0, 3) end
        end
        net.WriteUInt(game.current and game.current.id or 0, 3)
        net.WriteUInt(game.current and (game.current.rotation - 1) or 0, 2)
        net.WriteInt(game.current and game.current.x or 0, 6)
        net.WriteInt(game.current and game.current.y or 0, 6)
        net.WriteUInt(game.nextPiece or 0, 3)
        net.WriteUInt(math.Clamp(session.bonus or 0, 0, 65535), 16)
        net.WriteUInt((session.clearSerial or 0) % 256, 8)
        net.WriteUInt(math.Clamp(session.lastClearLines or 0, 0, 4), 3)
        net.WriteBool(game.gameOver == true)
        net.WriteUInt((session.eventSerial or 0) % 256, 8)
        net.WriteUInt(math.Clamp(session.lastEvent or EVENT_NONE, 0, 7), 3)
    end
    net.Send(ply)
end

local function syncSession(session, force)
    local ply = connectedPlayerForIdentity(session.identity)
    if not IsValid(ply) then return end
    local now = CurTime()
    if not force and now < (session.nextSync or 0) then return end
    session.nextSync = now + 0.20
    writeState(ply, true, true, session, session.endsAt)
end

local function syncPending(identity)
    local pending = Intermission.Pending[identity]
    local ply = connectedPlayerForIdentity(identity)
    if IsValid(ply) and pending then
        writeState(ply, false, true, nil, pending.endsAt)
    end
end

local function recordEvent(session, eventType)
    session.lastEvent = eventType or EVENT_NONE
    session.eventSerial = (session.eventSerial or 0) + 1
end

local function rewardLines(session, lines)
    if not lines or lines <= 0 then return end
    local reward = Tetris.RewardForLines(lines)
    if reward <= 0 then return end

    session.bonus = (session.bonus or 0) + reward
    session.lastClearLines = lines
    session.clearSerial = (session.clearSerial or 0) + 1
    recordEvent(session, EVENT_LINE_CLEAR)

    local ps = RunManager:GetPlayerState(session.identity)
    if ps then
        ps.nextLifeHPBonus = (ps.nextLifeHPBonus or 0) + reward
        local ply = connectedPlayerForIdentity(session.identity)
        if IsValid(ply) then ply:SetNW2Int("LOD_TetrisNextLifeBonus", ps.nextLifeHPBonus) end
    end
end

local function afterLock(session, lines, gameOver, normalEvent)
    session.lockDeadline = nil
    session.lockResets = 0
    if lines and lines > 0 then
        rewardLines(session, lines)
    elseif gameOver then
        recordEvent(session, EVENT_GAME_OVER)
    else
        recordEvent(session, normalEvent or EVENT_LOCK)
    end
end

local function armLockDelay(session, resetEligible)
    local game = session.game
    if game.gameOver or not game.current then
        session.lockDeadline = nil
        return
    end
    if not Tetris.IsGrounded(game) then
        session.lockDeadline = nil
        return
    end

    local now = CurTime()
    if not session.lockDeadline then
        session.lockDeadline = now + Tetris.LockDelay
    elseif resetEligible and (session.lockResets or 0) < Tetris.MaxLockResets then
        session.lockResets = (session.lockResets or 0) + 1
        session.lockDeadline = now + Tetris.LockDelay
    end
end

local function permitInput(session)
    local now = CurTime()
    if now >= (session.inputWindowAt or 0) then
        session.inputWindowAt = now + 1
        session.inputCount = 0
    end
    if (session.inputCount or 0) >= 30 then return false end
    session.inputCount = (session.inputCount or 0) + 1
    return true
end

function Intermission:StartSession(ply)
    if not IsValid(ply) then return nil end
    local identity = RunManager:IdentityOf(ply)
    local pending = identity and self.Pending[identity]
    local ps = identity and RunManager:GetPlayerState(identity)
    if not identity or not pending or not ps or CurTime() >= pending.endsAt then return nil end
    if self.Sessions[identity] then return self.Sessions[identity] end

    ps.intermissionTetrisOrdinal = (ps.intermissionTetrisOrdinal or 0) + 1
    local levelSeed = RunManager.State and RunManager.State.LevelSeed or 1
    local seed = LOD.Seeds.Derive(levelSeed, string.format(
        "intermission-tetris:%s:%d", tostring(identity), ps.intermissionTetrisOrdinal))
    local now = CurTime()
    local session = {
        identity = identity,
        endsAt = pending.endsAt,
        game = Tetris.NewGame(seed),
        bonus = 0,
        clearSerial = 0,
        lastClearLines = 0,
        nextFallAt = now + Tetris.FallInterval,
        nextSync = 0,
        inputWindowAt = 0,
        inputCount = 0,
        lockDeadline = nil,
        lockResets = 0,
        eventSerial = 0,
        lastEvent = EVENT_NONE
    }
    self.Sessions[identity] = session
    pending.started = true
    ply:SetNW2Bool("LOD_IntermissionTetrisActive", true)
    syncSession(session, true)
    return session
end

function Intermission:EndIdentity(identity)
    if not identity then return end
    local ply = connectedPlayerForIdentity(identity)
    if IsValid(ply) then
        ply:SetNW2Bool("LOD_IntermissionTetrisActive", false)
        writeState(ply, false, false, nil, CurTime())
    end
    self.Sessions[identity] = nil
    self.Pending[identity] = nil
end

function Intermission:EndAll()
    local identities = {}
    for identity in pairs(self.Pending) do identities[#identities + 1] = identity end
    for identity in pairs(self.Sessions) do
        local found = false
        for _, existing in ipairs(identities) do if existing == identity then found = true break end end
        if not found then identities[#identities + 1] = identity end
    end
    for _, identity in ipairs(identities) do self:EndIdentity(identity) end
end

function Intermission:OpenWindow()
    self:EndAll()
    local endsAt = CurTime() + WINDOW_SECONDS
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and RunManager:IsPlayedIdentity(ply) then
            local identity = RunManager:IdentityOf(ply)
            local ps = identity and RunManager:GetPlayerState(identity)
            if identity and ps then
                self.Pending[identity] = {endsAt = endsAt, started = false}
                ply:SetNW2Bool("LOD_IntermissionTetrisAvailable", true)
                syncPending(identity)
            end
        end
    end
end

-- Wrap the existing production rescue transition rather than creating a second
-- level-clear authority. The normal RunManager still owns progression; this layer
-- only opens the GDD-required optional twenty-second microgame window.
if not RunManager.LODIntermissionTetrisWrapped then
    RunManager.LODIntermissionTetrisWrapped = true
    local baseCompleteLevel = RunManager.CompleteLevel
    function RunManager:CompleteLevel(ply)
        local completed = baseCompleteLevel(self, ply)
        if completed then Intermission:OpenWindow() end
        return completed
    end

    local baseAdvanceLevel = RunManager.AdvanceLevel
    function RunManager:AdvanceLevel()
        Intermission:EndAll()
        return baseAdvanceLevel(self)
    end
end

net.Receive("LOD_IntermissionTetrisAction", function(_, ply)
    if not IsValid(ply) then return end
    local action = net.ReadUInt(2)
    if action ~= ACTION_START then return end
    if not RunManager.State or not RunManager.State.LevelCleared then return end
    Intermission:StartSession(ply)
end)

net.Receive("LOD_IntermissionTetrisInput", function(_, ply)
    if not IsValid(ply) or not RunManager.State or not RunManager.State.LevelCleared then return end
    local identity = RunManager:IdentityOf(ply)
    local session = identity and Intermission.Sessions[identity]
    if not session or CurTime() >= session.endsAt or session.game.gameOver or not permitInput(session) then return end

    local action = net.ReadUInt(3)
    local changed = false
    if action == INPUT_LEFT then
        changed = Tetris.Move(session.game, -1, 0)
        if changed then armLockDelay(session, true) end
    elseif action == INPUT_RIGHT then
        changed = Tetris.Move(session.game, 1, 0)
        if changed then armLockDelay(session, true) end
    elseif action == INPUT_ROTATE then
        changed = Tetris.Rotate(session.game, 1)
        if changed then
            armLockDelay(session, true)
            recordEvent(session, EVENT_ROTATE)
        end
    elseif action == INPUT_SOFT_DROP then
        changed = Tetris.StepDown(session.game)
        armLockDelay(session, false)
    elseif action == INPUT_HARD_DROP then
        local _, lines, gameOver = Tetris.HardDrop(session.game)
        afterLock(session, lines, gameOver, EVENT_HARD_DROP)
        session.nextFallAt = CurTime() + Tetris.FallInterval
        changed = true
    end

    if changed then syncSession(session, true) end
end)

hook.Add("StartCommand", "LOD_IntermissionTetrisBlockDungeonInput", function(ply, cmd)
    local identity = IsValid(ply) and RunManager:IdentityOf(ply) or nil
    if not identity or not Intermission.Sessions[identity] then return end
    cmd:ClearMovement()
    cmd:ClearButtons()
end)

hook.Add("PlayerDisconnected", "LOD_IntermissionTetrisDisconnectCleanup", function(ply)
    local identity = RunManager:IdentityOf(ply)
    if identity then
        Intermission.Sessions[identity] = nil
        Intermission.Pending[identity] = nil
    end
end)

hook.Add("Think", "LOD_IntermissionTetrisThink", function()
    local now = CurTime()

    for identity, pending in pairs(Intermission.Pending) do
        local ply = connectedPlayerForIdentity(identity)
        if now >= pending.endsAt or not RunManager.State or not RunManager.State.LevelCleared then
            Intermission:EndIdentity(identity)
        elseif IsValid(ply) and not Intermission.Sessions[identity] then
            ply:SetNW2Bool("LOD_IntermissionTetrisAvailable", true)
            if now >= (pending.nextSync or 0) then
                pending.nextSync = now + 0.5
                syncPending(identity)
            end
        end
    end

    for identity, session in pairs(Intermission.Sessions) do
        if now >= session.endsAt or not RunManager.State or not RunManager.State.LevelCleared then
            Intermission:EndIdentity(identity)
        elseif not session.game.gameOver then
            if session.lockDeadline and now >= session.lockDeadline then
                local lines, gameOver = Tetris.Lock(session.game)
                afterLock(session, lines, gameOver, EVENT_LOCK)
                session.nextFallAt = now + Tetris.FallInterval
                syncSession(session, true)
            elseif now >= (session.nextFallAt or 0) then
                session.nextFallAt = now + Tetris.FallInterval
                local moved = Tetris.StepDown(session.game)
                if moved then
                    session.lockDeadline = nil
                    session.lockResets = 0
                else
                    armLockDelay(session, false)
                end
                syncSession(session, false)
            else
                syncSession(session, false)
            end
        else
            syncSession(session, false)
        end
    end
end)

concommand.Add("lod_intermission_tetris_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local line = string.format("window=%ds pending=%d active=%d levelCleared=%s",
        WINDOW_SECONDS, table.Count(Intermission.Pending), table.Count(Intermission.Sessions),
        tostring(RunManager.State and RunManager.State.LevelCleared == true))
    print("[LOD:INTERMISSION-TETRIS] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
