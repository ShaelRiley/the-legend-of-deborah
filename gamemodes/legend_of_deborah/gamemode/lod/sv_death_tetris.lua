LOD = LOD or {}
LOD.DeathTetris = LOD.DeathTetris or {}

local DeathTetris = LOD.DeathTetris
local RunManager = LOD.RunManager
local Tetris = LOD.Tetris

util.AddNetworkString("LOD_TetrisState")
util.AddNetworkString("LOD_TetrisInput")

local ACTION_LEFT = 1
local ACTION_RIGHT = 2
local ACTION_ROTATE = 3
local ACTION_SOFT_DROP = 4
local ACTION_HARD_DROP = 5

local sessions = DeathTetris.Sessions or {}
DeathTetris.Sessions = sessions

local function connectedPlayerForIdentity(identity)
    for _, ply in ipairs(player.GetAll()) do
        if RunManager:IdentityOf(ply) == identity then return ply end
    end
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

    local ply = connectedPlayerForIdentity(session.identity)
    if IsValid(ply) then
        ply:SetNW2Int("LOD_TetrisNextLifeBonus", ps and ps.nextLifeHPBonus or session.bonus)
    end
end

local function handleLockResult(session, lines)
    if lines and lines > 0 then addLineReward(session, lines) end
end

function DeathTetris:StartSession(ply, kind, endsAt)
    if not IsValid(ply) then return nil end
    local identity = RunManager:IdentityOf(ply)
    local ps = identity and RunManager:GetPlayerState(identity)
    if not identity or not ps then return nil end

    ps.tetrisSessionOrdinal = (ps.tetrisSessionOrdinal or 0) + 1
    local levelSeed = RunManager.State and RunManager.State.LevelSeed or 1
    local playerSeed = LOD.Seeds.Derive(levelSeed, "tetris:" .. tostring(identity))
    local sessionSeed = LOD.Seeds.Derive(playerSeed,
        tostring(kind or "death") .. ":" .. tostring(ps.tetrisSessionOrdinal))

    local session = {
        identity = identity,
        kind = kind or "death",
        endsAt = endsAt,
        game = Tetris.NewGame(sessionSeed),
        bonus = 0,
        firstClear = false,
        clearSerial = 0,
        lastClearLines = 0,
        nextFallAt = CurTime() + Tetris.FallInterval,
        nextSync = 0,
        inputWindowAt = 0,
        inputCount = 0
    }
    sessions[identity] = session
    ply:SetNW2Int("LOD_TetrisNextLifeBonus", ps.nextLifeHPBonus or 0)
    syncSession(session, true)
    return session
end

function DeathTetris:EndSession(identity)
    local session = sessions[identity]
    if not session then return end
    local ply = connectedPlayerForIdentity(identity)
    if IsValid(ply) then writeSnapshot(ply, session, false) end
    sessions[identity] = nil
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

net.Receive("LOD_TetrisInput", function(_, ply)
    if not IsValid(ply) or ply:Alive() then return end
    local identity = RunManager:IdentityOf(ply)
    local session = identity and sessions[identity]
    if not session or session.kind ~= "death" or not permitInput(session) then return end

    local ps = RunManager:GetPlayerState(identity)
    if not ps or ps.eliminated or ps.lives <= 0 or not ps.respawnAt or CurTime() >= ps.respawnAt then return end

    local action = net.ReadUInt(3)
    local changed = false
    local lines = 0

    if action == ACTION_LEFT then
        changed = Tetris.Move(session.game, -1, 0)
    elseif action == ACTION_RIGHT then
        changed = Tetris.Move(session.game, 1, 0)
    elseif action == ACTION_ROTATE then
        changed = Tetris.Rotate(session.game, 1)
    elseif action == ACTION_SOFT_DROP then
        local moved
        moved, lines = Tetris.StepDown(session.game)
        changed = moved or lines > 0
        if not moved then changed = true end
    elseif action == ACTION_HARD_DROP then
        local distance
        distance, lines = Tetris.HardDrop(session.game)
        changed = distance >= 0
    end

    handleLockResult(session, lines)
    if changed then syncSession(session, true) end
end)

hook.Add("PlayerDeath", "LOD_DeathTetrisStart", function(victim)
    timer.Simple(0, function()
        if not IsValid(victim) then return end
        local ps = RunManager:GetPlayerState(victim)
        if not ps or ps.eliminated or ps.lives <= 0 or not ps.respawnAt then return end
        DeathTetris:StartSession(victim, "death", ps.respawnAt)
    end)
end)

hook.Add("PlayerSpawn", "LOD_DeathTetrisApplyNextLifeBonus", function(ply)
    local identity = RunManager:IdentityOf(ply)
    if identity and sessions[identity] then DeathTetris:EndSession(identity) end

    timer.Simple(0.05, function()
        if not IsValid(ply) or not ply:Alive() then return end
        local ps = RunManager:GetPlayerState(ply)
        local bonus = ps and math.max(0, math.floor(tonumber(ps.nextLifeHPBonus) or 0)) or 0
        if bonus <= 0 then return end

        ps.nextLifeHPBonus = 0
        ply:SetHealth(100 + bonus)
        ply:SetNW2Int("LOD_TetrisNextLifeBonus", 0)
        print(string.format("[LOD:TETRIS] %s spawned with +%d next-life HP (%d total)", ply:Nick(), bonus, 100 + bonus))
    end)
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

    for identity, session in pairs(sessions) do
        if session.wasFrozen then
            session.wasFrozen = nil
            session.nextFallAt = now + Tetris.FallInterval
            session.nextSync = 0
        end
        local ps = RunManager:GetPlayerState(identity)
        local ply = connectedPlayerForIdentity(identity)
        local expired = not ps or ps.eliminated or ps.lives <= 0 or not ps.respawnAt or now >= ps.respawnAt
        if expired or (IsValid(ply) and ply:Alive()) then
            DeathTetris:EndSession(identity)
        else
            local changed = false
            local safety = 0
            while now >= session.nextFallAt and safety < 8 do
                local _, lines = Tetris.StepDown(session.game)
                handleLockResult(session, lines)
                session.nextFallAt = session.nextFallAt + Tetris.FallInterval
                safety = safety + 1
                changed = true
            end
            syncSession(session, changed)
        end
    end
end)
