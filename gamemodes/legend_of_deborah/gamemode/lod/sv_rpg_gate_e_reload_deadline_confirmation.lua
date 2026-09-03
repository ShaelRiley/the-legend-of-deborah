LOD = LOD or {}
local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
local Config = Effects and Effects.ReloadConfig
if not Effects or not Config or not isfunction(Effects.ProcessReloadObservation) then return end
if Effects.LODReloadDeadlineConfirmationWrapped then return Effects end

Effects.LODReloadDeadlineConfirmationWrapped = true

local EPSILON = Config.epsilon or 0.002
local AR2_RETRY_INTERVAL = 0.05
local AR2_POST_LOCK_GRACE = 0.18
local baseProcessReloadObservation = Effects.ProcessReloadObservation

local function internal(entity, key, fallback)
    if IsValid(entity) and entity.GetInternalVariable then
        local value = tonumber(entity:GetInternalVariable(key))
        if value ~= nil then return value end
    end
    return tonumber(fallback) or 0
end

local function primaryDeadline(weapon)
    return internal(weapon, "m_flNextPrimaryAttack",
        weapon.GetNextPrimaryFire and weapon:GetNextPrimaryFire() or 0)
end

local function playerDeadline(ply)
    return internal(ply, "m_flNextAttack", 0)
end

local function primaryReserve(ply, weapon)
    if not IsValid(ply) or not IsValid(weapon) then return 0 end
    local ammoType = weapon.GetPrimaryAmmoType and weapon:GetPrimaryAmmoType() or -1
    if not ammoType or ammoType < 0 then return 0 end
    return math.max(0, ply:GetAmmoCount(ammoType))
end

local function deadlineAdvanced(raw, prior)
    raw = tonumber(raw) or 0
    prior = tonumber(prior) or 0
    return raw > prior + EPSILON
end

local function ar2SpecialState(ply)
    local specials = LOD.PlayerWeaponSpecials
    local state = specials and specials.PlayerState and specials.PlayerState[ply] or nil
    return state and state.ar2 or nil
end

local function attemptAR2DefaultReload(ply, session, now)
    if not session or session.sawReload or session.weaponClass ~= "weapon_ar2" then return false end

    local weapon = session.weapon
    if not IsValid(ply) or not IsValid(weapon) or not isfunction(weapon.DefaultReload) then return false end

    local ar2 = ar2SpecialState(ply)
    if ar2 and (ar2.active or ar2.attackHeld) then
        -- The authored laser telegraph and the burst itself are absolute exclusions.
        -- Never turn an attack transaction into reload cadence.
        return false
    end

    local clip = weapon.Clip1 and weapon:Clip1() or -1
    local maximum = weapon.GetMaxClip1 and weapon:GetMaxClip1() or -1
    local reserve = primaryReserve(ply, weapon)
    if maximum <= 0 or clip < 0 or clip >= maximum or reserve <= 0 then return false end

    local primary = primaryDeadline(weapon)
    local playerNext = playerDeadline(ply)
    local lockUntil = math.max(primary, playerNext, tonumber(ar2 and ar2.readyAt) or 0)

    if lockUntil > now + EPSILON then
        -- A reload pressed immediately after a burst is allowed to wait through the
        -- authored AR2 recovery, but the recovery itself is never shortened. Extend
        -- the observation window just far enough to retry once that lock expires.
        session.probeUntil = math.max(
            tonumber(session.probeUntil) or 0,
            math.min(tonumber(session.expiresAt) or (lockUntil + AR2_POST_LOCK_GRACE),
                lockUntil + AR2_POST_LOCK_GRACE))
        session.ar2ReloadQueuedThroughRecovery = true
        return false
    end

    if now < (tonumber(session.nextAR2DefaultReloadAttemptAt) or 0) then return false end
    session.nextAR2DefaultReloadAttemptAt = now + AR2_RETRY_INTERVAL
    session.ar2DefaultReloadAttempts = (tonumber(session.ar2DefaultReloadAttempts) or 0) + 1

    local beforePrimary = primaryDeadline(weapon)
    local beforePlayer = playerDeadline(ply)
    local didReload = weapon:DefaultReload(ACT_VM_RELOAD) == true

    Effects.ReloadStats = Effects.ReloadStats or {}
    Effects.ReloadStats.ar2DefaultReloadAttempts =
        (tonumber(Effects.ReloadStats.ar2DefaultReloadAttempts) or 0) + 1

    if didReload then
        session.sawReload = true
        session.defaultReloadConfirmed = true
        session.finishGraceUntil = nil
        Effects.ReloadStats.ar2DefaultReloadConfirmed =
            (tonumber(Effects.ReloadStats.ar2DefaultReloadConfirmed) or 0) + 1
        Effects.ReloadStats.lastConfirmation = {
            weaponClass = session.weaponClass,
            method = "DefaultReload",
            primaryBefore = beforePrimary,
            primaryAfter = primaryDeadline(weapon),
            playerBefore = beforePlayer,
            playerAfter = playerDeadline(ply)
        }
        print(string.format(
            "[LOD:RPG-E] AR2 DefaultReload confirmed clip=%d/%d reserve=%d primary=%.3f->%.3f player=%.3f->%.3f",
            clip, maximum, reserve,
            beforePrimary, primaryDeadline(weapon), beforePlayer, playerDeadline(ply)))
        return true
    end

    if session.ar2DefaultReloadAttempts == 1 then
        print(string.format(
            "[LOD:RPG-E] AR2 DefaultReload returned false clip=%d/%d reserve=%d; retrying within probe window",
            clip, maximum, reserve))
    end
    return false
end

local function confirmByAuthoredDeadline(ply, session, now)
    if not session or session.sawReload then return false end
    if now > (tonumber(session.probeUntil) or 0) then return false end

    local weapon = session.weapon
    if not IsValid(ply) or not IsValid(weapon) then return false end

    -- Some stock Source weapons do not expose m_bInReload consistently. A genuine
    -- reload still authors a new attack lock immediately after reload input, so a
    -- newly extended primary/player deadline remains a safe positive confirmation.
    local expected = session.expected or {}
    local primary = primaryDeadline(weapon)
    local playerNext = playerDeadline(ply)
    if not deadlineAdvanced(primary, expected.primary)
        and not deadlineAdvanced(playerNext, expected.player)
    then
        return false
    end

    session.sawReload = true
    session.deadlineConfirmedReload = true
    session.finishGraceUntil = nil

    Effects.ReloadStats = Effects.ReloadStats or {}
    Effects.ReloadStats.deadlineConfirmedReloads =
        (tonumber(Effects.ReloadStats.deadlineConfirmedReloads) or 0) + 1
    Effects.ReloadStats.lastConfirmation = {
        weaponClass = session.weaponClass,
        method = "authored_deadline",
        primaryBefore = tonumber(expected.primary) or 0,
        primaryAfter = primary,
        playerBefore = tonumber(expected.player) or 0,
        playerAfter = playerNext
    }
    return true
end

function Effects:ProcessReloadObservation(ply, session, now)
    attemptAR2DefaultReload(ply, session, now)
    confirmByAuthoredDeadline(ply, session, now)
    return baseProcessReloadObservation(self, ply, session, now)
end

return Effects
