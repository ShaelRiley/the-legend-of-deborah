LOD = LOD or {}
local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Config = Effects and Effects.RateOfFireConfig
if not Effects or not Rules or not Config then return end

local FIREARMS = Config.ordinaryFirearms
local MELEE = Config.ordinaryMelee or {}
local EPSILON = Config.epsilon or 0.002
local OBSERVE_INTERVAL = 0.005
local SESSION_LIMIT_SECONDS = 8.0
local POST_SHOT_DEADLINE_SECONDS = 0.25

local function internalDeadline(entity, key, fallback)
    if IsValid(entity) and entity.GetInternalVariable then
        local value = tonumber(entity:GetInternalVariable(key))
        if value ~= nil then return CurTime() + value end
    end
    return tonumber(fallback) or 0
end

local function primaryDeadline(weapon)
    if not IsValid(weapon) then return 0 end
    if weapon.GetNextPrimaryFire then
        local value = tonumber(weapon:GetNextPrimaryFire())
        if value ~= nil then return value end
    end
    return internalDeadline(weapon, "m_flNextPrimaryAttack", 0)
end

local function saveFieldTime(entity, key, absoluteDeadline)
    if not IsValid(entity) or not entity.SetSaveValue then return false end
    return entity:SetSaveValue(key, (tonumber(absoluteDeadline) or CurTime()) - CurTime()) == true
end

local function setPrimaryDeadline(weapon, value)
    if not IsValid(weapon) then return end
    if weapon.SetNextPrimaryFire then weapon:SetNextPrimaryFire(value) end
    -- Native HL2 pistol timing can bypass the Lua setter on some branches.
    if weapon:GetClass() == "weapon_pistol" then
        saveFieldTime(weapon, "m_flNextPrimaryAttack", value)
    end
end

local function weaponInReload(weapon)
    if Effects.IsWeaponInReload then return Effects:IsWeaponInReload(weapon) end
    if not IsValid(weapon) or not weapon.GetInternalVariable then return false end
    local value = weapon:GetInternalVariable("m_bInReload")
    return value == true or value == 1
end

local function primaryClip(weapon)
    if not IsValid(weapon) or not weapon.Clip1 then return -1 end
    return tonumber(weapon:Clip1()) or -1
end

local function lastShootTime(weapon)
    if not IsValid(weapon) or not weapon.GetLastShootTime then return 0 end
    return tonumber(weapon:GetLastShootTime()) or 0
end

local function canObserveAttack(ply, weapon, now)
    if not IsValid(ply) or not ply:Alive() or not IsValid(weapon) then return false end
    local class = weapon:GetClass()
    if FIREARMS[class] then
        if weaponInReload(weapon) or primaryClip(weapon) <= 0 then return false end
    elseif not MELEE[class] then
        return false
    end
    return primaryDeadline(weapon) <= now + EPSILON
end

function Effects:IsRateOfFireWeaponClass(weaponClass)
    weaponClass = tostring(weaponClass or "")
    return FIREARMS[weaponClass] == true or MELEE[weaponClass] == true
end

Effects.AttackRateSessions = Effects.AttackRateSessions or setmetatable({}, {__mode = "k"})
Effects.AttackRateStats = Effects.AttackRateStats or {
    sessions = 0,
    attackIntervalsScaled = 0,
    preexistingLocksPreserved = 0,
    confirmedAttacks = 0,
    deadlineConfirmationTimeouts = 0
}
Effects.AttackRateStats.confirmedAttacks = tonumber(Effects.AttackRateStats.confirmedAttacks) or 0
Effects.AttackRateStats.deadlineConfirmationTimeouts =
    tonumber(Effects.AttackRateStats.deadlineConfirmationTimeouts) or 0

function Effects:RecordRateOfFireScale(ply, weaponClass, channel, multiplier,
    authoredSeconds, scaledSeconds, confirmation)
    authoredSeconds = math.max(0, tonumber(authoredSeconds) or 0)
    scaledSeconds = math.max(0, tonumber(scaledSeconds) or 0)
    self.AttackRateStats.attackIntervalsScaled =
        (self.AttackRateStats.attackIntervalsScaled or 0) + 1
    local count = self.AttackRateStats.attackIntervalsScaled
    local fields = {
        count = count,
        delta = 1,
        weaponClass = tostring(weaponClass or "unknown"),
        channel = tostring(channel or "primary"),
        multiplier = tonumber(multiplier) or 1,
        authoredSeconds = authoredSeconds,
        scaledSeconds = scaledSeconds,
        savedSeconds = math.max(0, authoredSeconds - scaledSeconds),
        confirmation = tostring(confirmation or "runtime")
    }
    self.AttackRateStats.lastScale = fields

    local Log = LOD.RPGTestLog
    if Log and isfunction(Log.Write) then Log:Write("RATE_OF_FIRE_SCALE", fields) end

    local Obs = LOD.RPGTestObservability
    if Obs then
        Obs.RateOfFireScaleEvents = math.max(tonumber(Obs.RateOfFireScaleEvents) or 0, count)
        Obs.LastRateOfFireScale = fields
    end
    return fields
end

local function recordDeadlineMiss(session, now, raw)
    Effects.AttackRateStats.deadlineConfirmationTimeouts =
        (Effects.AttackRateStats.deadlineConfirmationTimeouts or 0) + 1
    local count = Effects.AttackRateStats.deadlineConfirmationTimeouts
    local fields = {
        count = count,
        weaponClass = tostring(session.weaponClass or "unknown"),
        confirmation = tostring(session.confirmationKind or "unknown"),
        confirmedAt = tonumber(session.confirmedAt) or now,
        priorDeadline = tonumber(session.priorDeadline) or 0,
        protectedPreShotDeadline = tonumber(session.preShotDeadline) or 0,
        observedDeadline = tonumber(raw) or 0
    }
    Effects.AttackRateStats.lastDeadlineMiss = fields
    local Log = LOD.RPGTestLog
    if Log and isfunction(Log.Write) then Log:Write("RATE_OF_FIRE_DEADLINE_MISS", fields) end
    local Obs = LOD.RPGTestObservability
    if Obs then
        Obs.RateOfFireDeadlineMisses = math.max(tonumber(Obs.RateOfFireDeadlineMisses) or 0, count)
        Obs.LastRateOfFireDeadlineMiss = fields
    end
end

function Effects:BeginAttackRateObservation(ply, weapon)
    if not IsValid(ply) or not IsValid(weapon) then return false end
    local now = CurTime()
    local multiplier = Rules:RateOfFireMultiplier(ply)
    if multiplier <= 1.00 + EPSILON or not canObserveAttack(ply, weapon, now) then return false end

    local prior = primaryDeadline(weapon)
    self.AttackRateSessions[ply] = {
        weapon = weapon,
        weaponClass = weapon:GetClass(),
        multiplier = multiplier,
        clipBefore = primaryClip(weapon),
        lastShootBefore = lastShootTime(weapon),
        priorDeadline = prior,
        preShotDeadline = prior,
        shotConfirmed = false,
        confirmationKind = nil,
        startedAt = now,
        expiresAt = now + SESSION_LIMIT_SECONDS
    }
    self.AttackRateStats.sessions = (self.AttackRateStats.sessions or 0) + 1
    return true
end

function Effects:EndAttackRateObservation(ply)
    self.AttackRateSessions[ply] = nil
end

local function confirmFirearmShot(session, weapon, now, raw)
    if session.shotConfirmed then return true end

    local confirmation = nil
    local clip = primaryClip(weapon)
    if session.clipBefore and session.clipBefore >= 0 and clip >= 0 and clip < session.clipBefore then
        confirmation = "clip_decrement"
    else
        local shootTime = lastShootTime(weapon)
        if shootTime > (tonumber(session.lastShootBefore) or 0) + EPSILON then
            confirmation = "last_shoot_time"
        end
    end

    if not confirmation then
        -- Any deadline authored before proof of an actual shot is protected. This
        -- includes the AR2 targeting-laser/pre-fire tell and similar warm-ups.
        session.preShotDeadline = math.max(tonumber(session.preShotDeadline) or 0, raw)
        return false
    end

    session.shotConfirmed = true
    session.confirmationKind = confirmation
    session.confirmedAt = now
    session.deadlineWaitUntil = math.min(tonumber(session.expiresAt) or now,
        now + POST_SHOT_DEADLINE_SECONDS)
    Effects.AttackRateStats.confirmedAttacks = (Effects.AttackRateStats.confirmedAttacks or 0) + 1
    return true
end

function Effects:RateOfFireConfirmedDeadlineReady(priorDeadline, preShotDeadline, rawDeadline, now)
    priorDeadline = tonumber(priorDeadline) or 0
    preShotDeadline = tonumber(preShotDeadline) or priorDeadline
    rawDeadline = tonumber(rawDeadline) or 0
    now = tonumber(now) or 0
    local protectedFloor = math.max(priorDeadline, preShotDeadline)
    return rawDeadline > protectedFloor + EPSILON and rawDeadline > now + EPSILON, protectedFloor
end

function Effects:ProcessAttackRateObservation(ply, session, now)
    local weapon = session and session.weapon or nil
    if not IsValid(ply) or not ply:Alive() or not IsValid(weapon)
        or ply:GetActiveWeapon() ~= weapon or now >= (session.expiresAt or 0)
        or weaponInReload(weapon)
    then
        self:EndAttackRateObservation(ply)
        return
    end

    local multiplier = Rules:RateOfFireMultiplier(ply)
    if multiplier <= 1.00 + EPSILON then
        self:EndAttackRateObservation(ply)
        return
    end
    session.multiplier = multiplier

    local raw = primaryDeadline(weapon)
    local prior = tonumber(session.priorDeadline) or now
    local firearm = FIREARMS[session.weaponClass] == true

    if firearm then
        if not confirmFirearmShot(session, weapon, now, raw) then return end
    else
        -- The Deborah crowbar has no pre-fire warm-up. Its own PrimaryAttack
        -- authors the repeat deadline, so that extension is proof of a swing.
        if not session.shotConfirmed then
            if raw <= (tonumber(session.preShotDeadline) or prior) + EPSILON then return end
            session.shotConfirmed = true
            session.confirmationKind = "deadline_extension"
            session.confirmedAt = now
            self.AttackRateStats.confirmedAttacks = (self.AttackRateStats.confirmedAttacks or 0) + 1
        end
    end

    -- Stock Source weapons can expose shot proof (especially clip decrement) one
    -- server tick before m_flNextPrimaryAttack is advanced. Keep the confirmed
    -- observation alive briefly instead of throwing away the attack. The largest
    -- deadline seen before shot proof is an absolute floor, so AR2 laser/tell time
    -- and every other pre-shot lock remain outside Rate-of-Fire authority.
    local deadlineReady, protectedFloor = self:RateOfFireConfirmedDeadlineReady(
        prior, session.preShotDeadline, raw, now)
    if not deadlineReady then
        if firearm and now >= (tonumber(session.deadlineWaitUntil) or now) then
            recordDeadlineMiss(session, now, raw)
            self:EndAttackRateObservation(ply)
        end
        return
    end

    local scaled, eligible = Rules:ScaleAttackDeadline(now, protectedFloor, raw, multiplier)
    if eligible and scaled < raw - EPSILON then
        if scaled <= protectedFloor + EPSILON and protectedFloor > now + EPSILON then
            self.AttackRateStats.preexistingLocksPreserved =
                (self.AttackRateStats.preexistingLocksPreserved or 0) + 1
        end
        setPrimaryDeadline(weapon, scaled)
        self:RecordRateOfFireScale(ply, session.weaponClass, "primary", multiplier,
            math.max(0, raw - now), math.max(0, scaled - now), session.confirmationKind)
    end
    self:EndAttackRateObservation(ply)
end

hook.Add("StartCommand", "LOD_RPG_GateE_RateOfFireInput", function(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or (not FIREARMS[weapon:GetClass()] and not MELEE[weapon:GetClass()]) then
        Effects:EndAttackRateObservation(ply)
        return
    end

    local session = Effects.AttackRateSessions[ply]
    if session and (cmd:KeyDown(IN_RELOAD) or cmd:KeyDown(IN_ATTACK2)) then
        Effects:EndAttackRateObservation(ply)
        session = nil
    end

    if not session and cmd:KeyDown(IN_ATTACK) then
        Effects:BeginAttackRateObservation(ply, weapon)
    end
end)

local nextObserveAt = 0
hook.Add("Think", "LOD_RPG_GateE_RateOfFireObserver", function()
    local now = CurTime()
    if now < nextObserveAt then return end
    nextObserveAt = now + OBSERVE_INTERVAL
    for ply, session in pairs(Effects.AttackRateSessions) do
        Effects:ProcessAttackRateObservation(ply, session, now)
    end
end)

hook.Add("PlayerDeath", "LOD_RPG_GateE_RateOfFireDeath", function(ply)
    Effects:EndAttackRateObservation(ply)
end)

hook.Add("PlayerDisconnected", "LOD_RPG_GateE_RateOfFireDisconnect", function(ply)
    Effects:EndAttackRateObservation(ply)
end)

return Effects
