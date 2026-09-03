LOD = LOD or {}
local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Config = Effects and Effects.ReloadConfig
if not Effects or not Rules or not Config then return end

local ORDINARY_RELOADABLE = Config.ordinaryReloadable
local EPSILON = Config.epsilon or 0.002
local OBSERVE_INTERVAL = 0.01
local PROBE_SECONDS = 0.30
local SESSION_LIMIT_SECONDS = 16.0

local function internal(entity, key, fallback)
    if IsValid(entity) and entity.GetInternalVariable then
        local value = tonumber(entity:GetInternalVariable(key))
        if value ~= nil then return value end
    end
    return tonumber(fallback) or 0
end

local function weaponDeadline(weapon, key)
    if key == "primary" then
        return internal(weapon, "m_flNextPrimaryAttack",
            weapon.GetNextPrimaryFire and weapon:GetNextPrimaryFire() or 0)
    elseif key == "secondary" then
        return internal(weapon, "m_flNextSecondaryAttack",
            weapon.GetNextSecondaryFire and weapon:GetNextSecondaryFire() or 0)
    elseif key == "idle" then
        return internal(weapon, "m_flTimeWeaponIdle",
            weapon.GetWeaponIdleTime and weapon:GetWeaponIdleTime() or 0)
    end
    return 0
end

local function playerDeadline(ply)
    return internal(ply, "m_flNextAttack", 0)
end

local function setWeaponDeadline(weapon, key, value)
    if not IsValid(weapon) then return end
    if key == "primary" and weapon.SetNextPrimaryFire then weapon:SetNextPrimaryFire(value) end
    if key == "secondary" and weapon.SetNextSecondaryFire then weapon:SetNextSecondaryFire(value) end
    if key == "idle" and weapon.SetWeaponIdleTime then weapon:SetWeaponIdleTime(value) end
    if weapon.SetSaveValue then
        local saveKey = key == "primary" and "m_flNextPrimaryAttack"
            or (key == "secondary" and "m_flNextSecondaryAttack" or "m_flTimeWeaponIdle")
        weapon:SetSaveValue(saveKey, value)
    end
end

local function setPlayerDeadline(ply, value)
    if IsValid(ply) and ply.SetSaveValue then ply:SetSaveValue("m_flNextAttack", value) end
end

local function setReloadViewModelRate(ply, multiplier)
    if not IsValid(ply) or not ply.GetViewModel then return end
    local viewModel = ply:GetViewModel()
    if not IsValid(viewModel) or not viewModel.SetPlaybackRate then return end
    local rate = multiplier and multiplier < 1 and (1 / multiplier) or 1
    viewModel:SetPlaybackRate(math.Clamp(rate, 1, 2.5))
end

local function primaryReserve(ply, weapon)
    if not IsValid(ply) or not IsValid(weapon) then return 0 end
    local ammoType = weapon.GetPrimaryAmmoType and weapon:GetPrimaryAmmoType() or -1
    if not ammoType or ammoType < 0 then return 0 end
    return math.max(0, ply:GetAmmoCount(ammoType))
end

local function canReloadNow(ply, weapon)
    if not IsValid(ply) or not ply:Alive() or not IsValid(weapon) then return false end
    if not ORDINARY_RELOADABLE[weapon:GetClass()] then return false end
    local maximum = weapon.GetMaxClip1 and weapon:GetMaxClip1() or -1
    local clip = weapon.Clip1 and weapon:Clip1() or -1
    return maximum and maximum > 0 and clip >= 0 and clip < maximum
        and primaryReserve(ply, weapon) > 0
end

function Effects:IsReloadWeaponClass(weaponClass)
    return ORDINARY_RELOADABLE[tostring(weaponClass or "")] == true
end

function Effects:IsWeaponInReload(weapon)
    if not IsValid(weapon) or not weapon.GetInternalVariable then return false end
    local value = weapon:GetInternalVariable("m_bInReload")
    return value == true or value == 1
end

Effects.ReloadSessions = Effects.ReloadSessions or setmetatable({}, {__mode = "k"})
Effects.ReloadStats = Effects.ReloadStats or {
    sessions = 0,
    reloadExtensionsScaled = 0,
    preexistingLocksPreserved = 0
}

local function captureDeadlines(ply, weapon, alreadyReloading)
    local now = CurTime()
    if alreadyReloading then
        -- m_bInReload positively identifies the current engine state as reload.
        -- Using now lets auto-reload/late observation compress its first extension.
        return {primary = now, secondary = now, idle = now, player = now}
    end
    return {
        primary = weaponDeadline(weapon, "primary"),
        secondary = weaponDeadline(weapon, "secondary"),
        idle = weaponDeadline(weapon, "idle"),
        player = playerDeadline(ply)
    }
end

function Effects:BeginReloadObservation(ply, weapon, alreadyReloading)
    if not IsValid(ply) or not IsValid(weapon) then return false end
    local multiplier = Rules:ReloadTimeMultiplier(ply)
    if multiplier >= 1 or not ORDINARY_RELOADABLE[weapon:GetClass()] then return false end
    if not alreadyReloading and not canReloadNow(ply, weapon) then return false end

    local now = CurTime()
    self.ReloadSessions[ply] = {
        weapon = weapon,
        weaponClass = weapon:GetClass(),
        multiplier = multiplier,
        expected = captureDeadlines(ply, weapon, alreadyReloading == true),
        startedAt = now,
        probeUntil = now + PROBE_SECONDS,
        expiresAt = now + SESSION_LIMIT_SECONDS,
        sawReload = alreadyReloading == true,
        wasInReload = alreadyReloading == true,
        finishGraceUntil = nil
    }
    self.ReloadStats.sessions = (self.ReloadStats.sessions or 0) + 1
    return true
end

local function recordScale(session, channel, raw, scaled, now)
    Effects.ReloadStats.reloadExtensionsScaled =
        (Effects.ReloadStats.reloadExtensionsScaled or 0) + 1
    Effects.ReloadStats.lastScale = {
        weaponClass = session.weaponClass,
        channel = channel,
        multiplier = session.multiplier,
        authoredSeconds = math.max(0, raw - now),
        scaledSeconds = math.max(0, scaled - now)
    }
end

local function scaleWeaponChannel(session, key, weapon, now)
    local raw = weaponDeadline(weapon, key)
    local prior = tonumber(session.expected[key]) or now
    if raw < prior - EPSILON then
        session.expected[key] = raw
        return false
    end
    local scaled, eligible = Rules:ScaleReloadDeadline(now, prior, raw, session.multiplier)
    if not eligible then return false end
    if scaled < raw - EPSILON then
        if scaled <= prior + EPSILON and prior > now + EPSILON then
            Effects.ReloadStats.preexistingLocksPreserved =
                (Effects.ReloadStats.preexistingLocksPreserved or 0) + 1
        end
        setWeaponDeadline(weapon, key, scaled)
        session.expected[key] = scaled
        session.lastScaledAt = now
        recordScale(session, key, raw, scaled, now)
        return true
    end
    session.expected[key] = math.max(prior, raw)
    return false
end

local function scalePlayerChannel(session, ply, now)
    local raw = playerDeadline(ply)
    local prior = tonumber(session.expected.player) or now
    if raw < prior - EPSILON then
        session.expected.player = raw
        return false
    end
    local scaled, eligible = Rules:ScaleReloadDeadline(now, prior, raw, session.multiplier)
    if not eligible then return false end
    if scaled < raw - EPSILON then
        if scaled <= prior + EPSILON and prior > now + EPSILON then
            Effects.ReloadStats.preexistingLocksPreserved =
                (Effects.ReloadStats.preexistingLocksPreserved or 0) + 1
        end
        setPlayerDeadline(ply, scaled)
        session.expected.player = scaled
        session.lastScaledAt = now
        recordScale(session, "player", raw, scaled, now)
        return true
    end
    session.expected.player = math.max(prior, raw)
    return false
end

function Effects:EndReloadObservation(ply)
    local session = self.ReloadSessions[ply]
    if session and session.viewModelRateApplied then setReloadViewModelRate(ply, nil) end
    self.ReloadSessions[ply] = nil
end

function Effects:ProcessReloadObservation(ply, session, now)
    local weapon = session and session.weapon or nil
    if not IsValid(ply) or not ply:Alive() or not IsValid(weapon)
        or ply:GetActiveWeapon() ~= weapon or CurTime() >= (session.expiresAt or 0)
    then
        self:EndReloadObservation(ply)
        return
    end

    local currentMultiplier = Rules:ReloadTimeMultiplier(ply)
    if currentMultiplier >= 1 then
        self:EndReloadObservation(ply)
        return
    end
    session.multiplier = currentMultiplier

    local reloading = self:IsWeaponInReload(weapon)
    if reloading then
        session.sawReload = true
        session.finishGraceUntil = nil
    elseif session.wasInReload and session.sawReload then
        -- FinishReload can author one final post-reload deadline in the frame that
        -- clears m_bInReload, so retain one tiny grace window for that deadline.
        session.finishGraceUntil = now + 0.06
    end
    session.wasInReload = reloading

    if session.sawReload then
        setReloadViewModelRate(ply, session.multiplier)
        session.viewModelRateApplied = true
        scaleWeaponChannel(session, "primary", weapon, now)
        scaleWeaponChannel(session, "secondary", weapon, now)
        scaleWeaponChannel(session, "idle", weapon, now)
        scalePlayerChannel(session, ply, now)
    end

    if not session.sawReload and now >= (session.probeUntil or 0) then
        self:EndReloadObservation(ply)
        return
    end

    if session.sawReload and not reloading then
        local grace = session.finishGraceUntil or (now + 0.06)
        session.finishGraceUntil = grace
        if now >= grace then self:EndReloadObservation(ply) end
    end
end

hook.Add("StartCommand", "LOD_RPG_GateE_ReloadInput", function(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not ORDINARY_RELOADABLE[weapon:GetClass()] then
        Effects:EndReloadObservation(ply)
        return
    end

    local session = Effects.ReloadSessions[ply]
    if session and (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) then
        -- Firing intentionally interrupts shell reload. Stop observing before the
        -- weapon can author a firing cooldown, so this feat never changes RoF.
        Effects:EndReloadObservation(ply)
        session = nil
    end

    if not session then
        local reloading = Effects:IsWeaponInReload(weapon)
        if reloading then
            Effects:BeginReloadObservation(ply, weapon, true)
        elseif cmd:KeyDown(IN_RELOAD) then
            Effects:BeginReloadObservation(ply, weapon, false)
        end
    end
end)

local nextObserveAt = 0
hook.Add("Think", "LOD_RPG_GateE_ReloadObserver", function()
    local now = CurTime()
    if now < nextObserveAt then return end
    nextObserveAt = now + OBSERVE_INTERVAL
    for ply, session in pairs(Effects.ReloadSessions) do
        Effects:ProcessReloadObservation(ply, session, now)
    end
end)

hook.Add("PlayerDeath", "LOD_RPG_GateE_ReloadDeath", function(ply)
    Effects:EndReloadObservation(ply)
end)

return Effects
