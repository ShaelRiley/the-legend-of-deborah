LOD = LOD or {}

local RPG = LOD.RPG
local Rules = LOD.RPGAbilityRules
local Effects = RPG and RPG.FeatEffectSystem
if not Rules or not Effects then return end

-- This module is loaded at the AR2 integration seam, before the Magnum modules
-- later in init.lua. Installation is deferred to the next server tick so it wraps
-- the final authored Magnum cylinder hook (including Aim-State inheritance) rather
-- than duplicating that weapon authority.

local function installBurstWrapper()
    local Magnum = LOD.MagnumSuperExplosive
    if not Magnum then return false end

    if not isfunction(Magnum.BursterAuthoredBurstCount) then
        -- Pure authored-state classifier. Chamber 5 is an authored 2-projectile
        -- burst and chamber 6 is an authored 3-projectile burst. Other triggers
        -- remain single-fire even if an unrelated low-health proc adds a projectile.
        function Magnum:BursterAuthoredBurstCount(maximum, clipAfterTrigger)
            maximum = math.max(1, math.floor(tonumber(maximum) or 6))
            clipAfterTrigger = math.Clamp(
                math.floor(tonumber(clipAfterTrigger) or maximum), 0, maximum)
            local shotIndex = math.Clamp(maximum - clipAfterTrigger, 1, maximum)
            if maximum >= 2 and shotIndex == maximum - 1 and clipAfterTrigger == 1 then
                return 2
            elseif shotIndex == maximum and clipAfterTrigger == 0 then
                return 3
            end
            return 1
        end
    end

    Magnum.Stats = Magnum.Stats or {}
    Magnum.Stats.bursterEligibleTriggers = Magnum.Stats.bursterEligibleTriggers or 0
    Magnum.Stats.bursterAddedProjectiles = Magnum.Stats.bursterAddedProjectiles or 0

    local fireHooks = hook.GetTable().EntityFireBullets
    local current = fireHooks and fireHooks["LOD_MagnumCylinderBurst"] or nil
    if not isfunction(current) then return false end
    if current == Magnum.LODBurstSizeBurstWrapper then
        Magnum.LODBurstSizeIntegrationInstalled = true
        return true
    end

    local baseBurstHook = current
    local wrapper
    wrapper = function(shooter, bullet)
        local weapon = IsValid(shooter) and shooter:IsPlayer()
            and shooter:Alive() and shooter:GetActiveWeapon() or nil
        if not IsValid(weapon) or weapon:GetClass() ~= "weapon_357"
            or weapon.LODMagnumInjectedBurst == true
        then
            return baseBurstHook(shooter, bullet)
        end

        local maximum = weapon.GetMaxClip1 and weapon:GetMaxClip1() or 6
        if not maximum or maximum <= 0 then maximum = 6 end
        local clipAfterTrigger = math.Clamp(
            math.floor(tonumber(weapon:Clip1()) or 0), 0, maximum)
        local authoredBurstCount =
            Magnum:BursterAuthoredBurstCount(maximum, clipAfterTrigger)
        local eligible = authoredBurstCount >= 2
        local burstBonusRounds = eligible and Rules:BurstBonusRounds(shooter) or 0

        local result = baseBurstHook(shooter, bullet)

        -- The base Magnum authority already created its free-projectile burst and
        -- the Aim-State wrapper already attached inheritance by the time it returns.
        -- Burster extends only that authored chamber-5/chamber-6 burst. It never
        -- touches Clip1 and never promotes a single shot or low-health proc into a
        -- multiFireBurst event.
        if eligible and burstBonusRounds > 0 then
            local burst = Magnum.Bursts and Magnum.Bursts[shooter] or nil
            if burst and burst.weapon == weapon then
                burst.remaining = math.max(0, math.floor(tonumber(burst.remaining) or 0))
                    + burstBonusRounds
                burst.burstBonusRounds = burstBonusRounds
                burst.authoredBurstCount = authoredBurstCount
                burst.finalBurstCount = isfunction(Rules.ResolveBurstCount)
                    and Rules:ResolveBurstCount(authoredBurstCount, burstBonusRounds)
                    or authoredBurstCount + burstBonusRounds
                Magnum.Stats.bursterEligibleTriggers =
                    (Magnum.Stats.bursterEligibleTriggers or 0) + 1
                Magnum.Stats.bursterAddedProjectiles =
                    (Magnum.Stats.bursterAddedProjectiles or 0) + burstBonusRounds

                if LOD.RPGTestLog and isfunction(LOD.RPGTestLog.Write) then
                    LOD.RPGTestLog:Write("BURST_SIZE_MAGNUM_COMMIT", {
                        player = tostring(shooter),
                        authored = authoredBurstCount,
                        final = authoredBurstCount + burstBonusRounds,
                        bonus = burstBonusRounds,
                        clipAfterTrigger = weapon:Clip1()
                    })
                end
            end
        end

        return result
    end

    Magnum.LODBurstSizeBurstBase = baseBurstHook
    Magnum.LODBurstSizeBurstWrapper = wrapper
    hook.Add("EntityFireBullets", "LOD_MagnumCylinderBurst", wrapper)
    Magnum.LODBurstSizeIntegrationInstalled = true
    print("[LOD:RPG-E] Magnum authored-burst Burst-Size bridge wrapped")
    return true
end

Effects.InstallMagnumBurstSizeBridge = installBurstWrapper

timer.Simple(0, installBurstWrapper)
hook.Add("InitPostEntity", "LOD_RPG_GateE_MagnumBurstSizeLateBind", function()
    timer.Simple(0, installBurstWrapper)
end)
hook.Add("OnReloaded", "LOD_RPG_GateE_MagnumBurstSizeRebind", function()
    timer.Simple(0, installBurstWrapper)
end)

return Effects
