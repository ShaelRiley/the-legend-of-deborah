LOD = LOD or {}
LOD.DeathTetris = LOD.DeathTetris or {}

local DeathTetris = LOD.DeathTetris
local RunManager = LOD.RunManager
local Tetris = LOD.Tetris

util.AddNetworkString("LOD_TetrisState")
util.AddNetworkString("LOD_TetrisInput")
util.AddNetworkString("LOD_DeathTetrisAction")

local ACTION_LEFT = 1
local ACTION_RIGHT = 2
local ACTION_ROTATE = 3
local ACTION_SOFT_DROP = 4
local ACTION_HARD_DROP = 5

local DEATH_ACTION_ENTER_TETRIS = 1
local DEATH_ACTION_RESPAWN = 2

local EVENT_NONE = 0
local EVENT_ROTATE = 1
local EVENT_HARD_DROP = 2
local EVENT_LOCK = 3
local EVENT_LINE_CLEAR = 4
local EVENT_GAME_OVER = 5

local HARD_DEATH_CAP = 60
local LINE_WAIT_REDUCTION = 2

local sessions = DeathTetris.Sessions or {}
local deaths = DeathTetris.Deaths or {}
DeathTetris.Sessions = sessions
DeathTetris.Deaths = deaths

local function connectedPlayerForIdentity(identity)
    for _, ply in ipairs(player.GetAll()) do
        if RunManager:IdentityOf(ply) == identity then return ply end
    end
end

local function deathStateFor(plyOrIdentity)
    local identity = isstring(plyOrIdentity) and plyOrIdentity
        or (IsValid(plyOrIdentity) and RunManager:IdentityOf(plyOrIdentity) or nil)
    return identity and deaths[identity] or nil
end

function DeathTetris:GetMandatoryRemaining(plyOrIdentity)
    local state = deathStateFor(plyOrIdentity)
    if not state then return nil end
    return math.max(0, (state.mandatoryEndsAt or 0) - CurTime())
end

function DeathTetris:IsDeathInteractionFor(ply)
    return deathStateFor(ply) ~= nil
end

local function writeSnapshot(ply, session, active)
    if not IsValid(ply) then return end
    net.Start("LOD_TetrisState")
    net.WriteBool(active == true)
    if active ~= true then
        net.Send(ply)
        return
    end

    local game = session.game
    net.WriteUInt(session.kind == "death" and 1 or 2, 2)
    for y = 1, Tetris.Height do
        for x = 1, Tetris.Width do
            net.WriteUInt(game.board[y][x] or 0, 3)
        end
    end
    net.WriteUInt(game.current and game.current.id or 0, 3)
    net.WriteUInt(game.current and (game.current.rotation - 1) or 0, 2)
    net.WriteInt(game.current and game.current.x or 0, 6)
    net.WriteInt(game.current and game.current.y or 0, 6)
    net.WriteUInt(game.nextPiece or 0, 3)
    net.WriteUInt(math.Clamp(session.bonus or 0, 0, 65535), 16)
    net.WriteBool(session.firstClear == true)
    net.WriteUInt((session.clearSerial or 0) % 256, 8)
    net.WriteUInt(math.Clamp(session.lastClearLines or 0, 0, 4), 3)
    net.WriteUInt((game.resetCount or 0) % 256, 8)
    net.WriteBool(game.gameOver == true)
    net.WriteUInt((session.eventSerial or 0) % 256, 8)
    net.WriteUInt(math.Clamp(session.lastEvent or EVENT_NONE, 0, 7), 3)
    net.Send(ply)
end

local function syncSession(session, force)
    local ply = connectedPlayerForIdentity(session.identity)
    if not IsValid(ply) then return end
    local now = CurTime()
    if not force and now < (session.nextSync or 0) then return end
    session.nextSync = now + 0.25
    writeSnapshot(ply, session, true)
end

local function recordEvent(session, eventType)
    session.lastEvent = eventType or EVENT_NONE
    session.eventSerial = (session.eventSerial or 0) + 1
end

local function addLineReward(session, lines)
    if lines <= 0 then return end
    local reward = Tetris.RewardForLines(lines)
    if reward <= 0 then return end

    session.bonus = (session.bonus or 0) + reward
    session.firstClear = true
    session.lastClearLines = lines
    session.clearSerial = (session.clearSerial or 0) + 1

    local ps = RunManager:GetPlayerState(session.identity)
    if ps then
        ps.nextLifeHPBonus = (ps.nextLifeHPBonus or 0) + reward
    end

    -- Every cleared line removes two seconds from the mandatory death wait.
    -- Doubles/triples/Tetrises therefore remove 4/6/8 seconds respectively.
    local deathState = deaths[session.identity]
    if deathState and deathState.mandatoryEndsAt then
        deathState.mandatoryEndsAt = math.max(CurTime(),
            deathState.mandatoryEndsAt - lines * LINE_WAIT_REDUCTION)
    end

    local ply = connectedPlayerForIdentity(session.identity)
    if IsValid(ply) then
        ply:SetNW2Int("LOD_TetrisNextLifeBonus", ps and ps.nextLifeHPBonus or session.bonus)
        if deathState then
            ply:SetNW2Float("LOD_RespawnRemaining",
                math.max(0, (deathState.mandatoryEndsAt or 0) - CurTime()))
        end
    end
end

local function afterLock(session, lines, gameOver, normalEvent)
    session.lockDeadline = nil
    session.lockResets = 0
    if lines and lines > 0 then
        addLineReward(session, lines)
        recordEvent(session, EVENT_LINE_CLEAR)
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
        return
    end

    if resetEligible and (session.lockResets or 0) < Tetris.MaxLockResets then
        session.lockResets = (session.lockResets or 0) + 1
        session.lockDeadline = now + Tetris.LockDelay
    end
end

function DeathTetris:StartDeath(ply, mandatoryEndsAt)
    if not IsValid(ply) then return nil end
    local identity = RunManager:IdentityOf(ply)
    local ps = identity and RunManager:GetPlayerState(identity)
    if not identity or not ps or ps.eliminated or ps.lives <= 0 then return nil end

    local now = CurTime()
    local state = {
        identity = identity,
        startedAt = now,
        mandatoryEndsAt = mandatoryEndsAt or ps.respawnAt or (now + LOD.Config.Lives.RespawnDelay),
        hardCapAt = now + HARD_DEATH_CAP,
        tetrisStarted = false
    }
    deaths[identity] = state

    -- RunManager's existing auto-respawn remains our hard safety cap. The visible
    -- mandatory wait is tracked separately above, allowing zero to mean "respawn
    -- available" while Tetris may continue until one real minute after death.
    ps.respawnAt = state.hardCapAt
    ply:SetNW2Bool("LOD_DeathInteraction", true)
    ply:SetNW2Float("LOD_DeathStartedAt", state.startedAt)
    ply:SetNW2Float("LOD_DeathHardCapAt", state.hardCapAt)
    ply:SetNW2Float("LOD_RespawnRemaining", math.max(0, state.mandatoryEndsAt - now))
    return state
end

function DeathTetris:StartSession(ply, kind, endsAt)
    if not IsValid(ply) then return nil end
    local identity = RunManager:IdentityOf(ply)
    local ps = identity and RunManager:GetPlayerState(identity)
    local deathState = identity and deaths[identity]
    if not identity or not ps or not deathState then return nil end
    if sessions[identity] or deathState.tetrisStarted then return sessions[identity] end

    ps.tetrisSessionOrdinal = (ps.tetrisSessionOrdinal or 0) + 1
    local levelSeed = RunManager.State and RunManager.State.LevelSeed or 1
    local playerSeed = LOD.Seeds.Derive(levelSeed, "tetris:" .. tostring(identity))
    local sessionSeed = LOD.Seeds.Derive(playerSeed,
        tostring(kind or "death") .. ":" .. tostring(ps.tetrisSessionOrdinal))

    local now = CurTime()
    local session = {
        identity = identity,
        kind = kind or "death",
        endsAt = endsAt or deathState.hardCapAt,
        startedAt = now,
        game = Tetris.NewGame(sessionSeed),
        bonus = 0,
        firstClear = false,
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
    sessions[identity] = session
    deathState.tetrisStarted = true
    deathState.tetrisStartedAt = now
    ply:SetNW2Bool("LOD_DeathTetrisActive", true)
    ply:SetNW2Float("LOD_DeathTetrisStartedAt", now)
    ply:SetNW2Int("LOD_TetrisNextLifeBonus", ps.nextLifeHPBonus or 0)
    syncSession(session, true)
    return session
end

function DeathTetris:EndSession(identity)
    local session = sessions[identity]
    if not session then return end
    local ply = connectedPlayerForIdentity(identity)
    if IsValid(ply) then
        writeSnapshot(ply, session, false)
        ply:SetNW2Bool("LOD_DeathTetrisActive", false)
    end
    sessions[identity] = nil
end

function DeathTetris:EndDeath(identity)
    if not identity then return end
    if sessions[identity] then self:EndSession(identity) end
    local ply = connectedPlayerForIdentity(identity)
    if IsValid(ply) then
        ply:SetNW2Bool("LOD_DeathInteraction", false)
        ply:SetNW2Bool("LOD_DeathTetrisActive", false)
        ply:SetNW2Float("LOD_DeathStartedAt", 0)
        ply:SetNW2Float("LOD_DeathHardCapAt", 0)
        ply:SetNW2Float("LOD_DeathTetrisStartedAt", 0)
    end
    deaths[identity] = nil
end

function DeathTetris:IsActiveFor(ply)
    local identity = IsValid(ply) and RunManager:IdentityOf(ply) or nil
    return identity and sessions[identity] ~= nil or false
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

local function respawnPlayer(ply, identity, ps)
    if not IsValid(ply) or ply:Alive() or not identity or not ps then return false end
    ps.respawnAt = nil
    DeathTetris:EndDeath(identity)
    ply:UnSpectate()
    ply:Spawn()
    return true
end

net.Receive("LOD_DeathTetrisAction", function(_, ply)
    if not IsValid(ply) or ply:Alive() then return end
    local identity = RunManager:IdentityOf(ply)
    local ps = identity and RunManager:GetPlayerState(identity)
    local deathState = identity and deaths[identity]
    if not identity or not ps or not deathState or ps.eliminated or ps.lives <= 0 then return end

    local action = net.ReadUInt(2)
    local now = CurTime()
    local remaining = math.max(0, (deathState.mandatoryEndsAt or 0) - now)

    if action == DEATH_ACTION_ENTER_TETRIS then
        if remaining <= 0 or deathState.tetrisStarted or now >= deathState.hardCapAt then return end
        DeathTetris:StartSession(ply, "death", deathState.hardCapAt)
    elseif action == DEATH_ACTION_RESPAWN then
        if remaining > 0 then return end
        respawnPlayer(ply, identity, ps)
    end
end)

net.Receive("LOD_TetrisInput", function(_, ply)
    if not IsValid(ply) or ply:Alive() then return end
    local identity = RunManager:IdentityOf(ply)
    local session = identity and sessions[identity]
    local deathState = identity and deaths[identity]
    if not session or not deathState or session.kind ~= "death" or session.game.gameOver
        or CurTime() >= deathState.hardCapAt or not permitInput(session)
    then
        return
    end

    local ps = RunManager:GetPlayerState(identity)
    if not ps or ps.eliminated or ps.lives <= 0 then return end

    local action = net.ReadUInt(3)
    local changed = false

    if action == ACTION_LEFT then
        changed = Tetris.Move(session.game, -1, 0)
        if changed then armLockDelay(session, true) end
    elseif action == ACTION_RIGHT then
        changed = Tetris.Move(session.game, 1, 0)
        if changed then armLockDelay(session, true) end
    elseif action == ACTION_ROTATE then
        changed = Tetris.Rotate(session.game, 1)
        if changed then
            armLockDelay(session, true)
            recordEvent(session, EVENT_ROTATE)
        end
    elseif action == ACTION_SOFT_DROP then
        changed = Tetris.StepDown(session.game)
        armLockDelay(session, false)
    elseif action == ACTION_HARD_DROP then
        local _, lines, gameOver = Tetris.HardDrop(session.game)
        afterLock(session, lines, gameOver, EVENT_HARD_DROP)
        session.nextFallAt = CurTime() + Tetris.FallInterval
        changed = true
    end

    if changed then syncSession(session, true) end
end)

hook.Add("PlayerDeath", "LOD_DeathTetrisPrepare", function(victim)
    timer.Simple(0, function()
        if not IsValid(victim) then return end
        local ps = RunManager:GetPlayerState(victim)
        if not ps or ps.eliminated or ps.lives <= 0 or not ps.respawnAt then return end
        -- RunManager has now authored the normal 20-second wait. Preserve it as
        -- the mandatory timer, then extend only the hidden safety deadline to 60s.
        DeathTetris:StartDeath(victim, ps.respawnAt)
    end)
end)

hook.Add("PlayerSpawn", "LOD_DeathTetrisApplyNextLifeBonus", function(ply)
    local identity = RunManager:IdentityOf(ply)
    if identity and deaths[identity] then DeathTetris:EndDeath(identity) end

    timer.Simple(0.05, function()
        if not IsValid(ply) or not ply:Alive() then return end
        local ps = RunManager:GetPlayerState(ply)
        local bonus = ps and math.max(0, math.floor(tonumber(ps.nextLifeHPBonus) or 0)) or 0
        if bonus <= 0 then return end

        ps.nextLifeHPBonus = 0
        ply:SetHealth(100 + bonus)
        ply:SetNW2Int("LOD_TetrisNextLifeBonus", 0)
        print(string.format("[LOD:TETRIS] %s spawned with +%d next-life HP (%d total)",
            ply:Nick(), bonus, 100 + bonus))
    end)
end)

hook.Add("PlayerDisconnected", "LOD_DeathTetrisDisconnectCleanup", function(ply)
    local identity = RunManager:IdentityOf(ply)
    if identity then
        sessions[identity] = nil
        deaths[identity] = nil
    end
end)

hook.Add("StartCommand", "LOD_DeathTetrisBlockDungeonInput", function(ply, cmd)
    if not DeathTetris:IsActiveFor(ply) or ply:Alive() then return end
    cmd:ClearMovement()
    cmd:ClearButtons()
end)

hook.Add("Think", "LOD_DeathTetrisThink", function()
    local now = CurTime()
    if RunManager.State and RunManager.State.SimulationFrozen then
        for _, session in pairs(sessions) do session.wasFrozen = true end
        return
    end

    for identity, deathState in pairs(deaths) do
        local ps = RunManager:GetPlayerState(identity)
        local ply = connectedPlayerForIdentity(identity)
        if not ps or ps.eliminated or ps.lives <= 0 or (IsValid(ply) and ply:Alive()) then
            DeathTetris:EndDeath(identity)
        elseif now >= (deathState.hardCapAt or math.huge) then
            -- RunManager normally reaches the same timestamp and auto-spawns. Do
            -- it here as well so the one-minute cap remains exact regardless of
            -- Think-hook ordering.
            if IsValid(ply) then respawnPlayer(ply, identity, ps) end
        end
    end

    for identity, session in pairs(sessions) do
        local deathState = deaths[identity]
        local ps = RunManager:GetPlayerState(identity)
        local ply = connectedPlayerForIdentity(identity)

        if not deathState or not ps or ps.eliminated or ps.lives <= 0
            or (IsValid(ply) and ply:Alive()) or now >= (deathState.hardCapAt or 0)
        then
            DeathTetris:EndSession(identity)
        elseif session.wasFrozen then
            session.wasFrozen = nil
            session.nextFallAt = now + Tetris.FallInterval
            session.lockDeadline = session.game.gameOver and nil
                or (Tetris.IsGrounded(session.game) and now + Tetris.LockDelay or nil)
            session.nextSync = 0
            syncSession(session, true)
        elseif session.game.gameOver then
            syncSession(session, false)
        else
            local changed = false
            local safety = 0
            while now >= session.nextFallAt and safety < 8 do
                local moved = Tetris.StepDown(session.game)
                session.nextFallAt = session.nextFallAt + Tetris.FallInterval
                safety = safety + 1
                if moved then
                    changed = true
                    armLockDelay(session, false)
                else
                    armLockDelay(session, false)
                    session.nextFallAt = now + Tetris.FallInterval
                    break
                end
            end

            if session.lockDeadline and now >= session.lockDeadline and Tetris.IsGrounded(session.game) then
                local lines, gameOver = Tetris.Lock(session.game)
                afterLock(session, lines, gameOver, EVENT_LOCK)
                session.nextFallAt = now + Tetris.FallInterval
                changed = true
            elseif session.lockDeadline and not Tetris.IsGrounded(session.game) then
                session.lockDeadline = nil
            end

            syncSession(session, changed)
        end
    end
end)
