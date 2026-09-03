LOD = LOD or {}
local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
local Config = Effects and Effects.ReloadConfig
if not Effects or not Config or not isfunction(Effects.ProcessReloadObservation) then return end
if Effects.LODReloadDeadlineConfirmationWrapped then return Effects end

Effects.LODReloadDeadlineConfirmationWrapped = true

local EPSILON = Config.epsilon or 0.002
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

local function deadlineAdvanced(raw, prior)
    raw = tonumber(raw) or 0
    prior = tonumber(prior) or 0
    return raw > prior + EPSILON
end

local function confirmByAuthoredDeadline(ply, session, now)
    if not session or session.sawReload then return false end
    if now > (tonumber(session.probeUntil) or 0) then return false end

    local weapon = session.weapon
    if not IsValid(ply) or not IsValid(weapon) then return false end

    -- Some stock Source weapons (notably the AR2 on the tested Linux build) do
    -- not expose m_bInReload reliably enough for the generic observer. A genuine
    -- reload still authors a new attack lock immediately after reload input.
    -- Because the observation session can begin only from valid IN_RELOAD input
    -- with a non-full clip and reserve ammo, and attack input cancels the session
    -- before firing cooldowns are authored, a newly extended primary/player
    -- deadline is a safe positive confirmation of the stock reload transaction.
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
    confirmByAuthoredDeadline(ply, session, now)
    return baseProcessReloadObservation(self, ply, session, now)
end

return Effects
