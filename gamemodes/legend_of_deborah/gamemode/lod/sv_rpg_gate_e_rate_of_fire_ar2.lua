LOD = LOD or {}

local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Specials = LOD.PlayerWeaponSpecials
if not Effects or not Rules or not Specials then return end
if Effects.LODRateOfFireAR2NetBridgeInstalled then return Effects end

local EPSILON = (Effects.RateOfFireConfig and Effects.RateOfFireConfig.epsilon) or 0.002
local AR2_BASE_BURST_ROUNDS = 3
local AUTHORITY_REVISION = "gate_e_ar2_one_ammo_per_burst_v2"

-- The AR2 uses a custom burst transaction rather than ordinary stock IN_ATTACK
-- cadence authority. Rate of Fire therefore owns a plan table keyed by player.
-- A plan begins immediately after the authoritative BeginAR2Burst succeeds. Each
-- successful authoritative FireAR2Round is counted on that player-local plan, and
-- a standalone Think observer commits the faster next-trigger deadline only after
-- the whole authored/feat-expanded burst has ended. Burst projectile count is
-- independent of AR2 Clip1 because one ammo unit was already paid at burst commit.
Effects.AR2RateOfFirePlans = Effects.AR2RateOfFirePlans or setmetatable({}, {__mode = "k"})

function Effects:RateOfFireAR2ReadyAt(startedAt, authoredReadyAt, completedAt, multiplier)
    startedAt = tonumber(startedAt) or 0
    authoredReadyAt = tonumber(authoredReadyAt) or startedAt
    completedAt = tonumber(completedAt) or startedAt
    multiplier = math.Clamp(tonumber(multiplier) or 1, 1.00, 1.30)

    if multiplier <= 1.00 + EPSILON or authoredReadyAt <= startedAt + EPSILON then
        return math.max(completedAt, authoredReadyAt), false
    end

    local dividedReadyAt = startedAt + (authoredReadyAt - startedAt) / multiplier
    local readyAt = math.max(completedAt, dividedReadyAt)
    return readyAt, readyAt < authoredReadyAt - EPSILON
end

function Effects:BeginAR2RateOfFirePlan(ply, weapon, startedAt)
    if not IsValid(ply) or not IsValid(weapon) or weapon:GetClass() ~= "weapon_ar2" then
        return false
    end
    if self.AR2RateOfFirePlans[ply] then return false end

    local state = Specials.PlayerState and Specials.PlayerState[ply] or nil
    local ar2 = state and state.ar2 or nil
    if not ar2 or ar2.active ~= true or ar2.weapon ~= weapon then return false end

    startedAt = tonumber(startedAt) or CurTime()
    local authoredReadyAt = tonumber(ar2.readyAt) or startedAt
    local multiplier = Rules:RateOfFireMultiplier(ply)
    local _, changed = self:RateOfFireAR2ReadyAt(
        startedAt, authoredReadyAt, startedAt, multiplier)

    if isfunction(self.EndAttackRateObservation) then
        self:EndAttackRateObservation(ply)
    end

    if not changed then
        self.AR2RateOfFirePlans[ply] = nil
        return false
    end

    self.AR2RateOfFirePlans[ply] = {
        weapon = weapon,
        startedAt = startedAt,
        authoredReadyAt = authoredReadyAt,
        multiplier = multiplier,
        targetShots = math.max(1,
            math.floor(tonumber(ar2.targetShots) or AR2_BASE_BURST_ROUNDS)),
        roundsFired = 0
    }
    self.AttackRateStats.sessions = (self.AttackRateStats.sessions or 0) + 1
    return true
end

local function clearPlan(ply)
    Effects.AR2RateOfFirePlans[ply] = nil
end

hook.Add("Think", "LOD_RPG_GateE_AR2RateOfFireCommit", function()
    local now = CurTime()
    for ply, plan in pairs(Effects.AR2RateOfFirePlans) do
        if not IsValid(ply) or not ply:Alive() or not plan or not IsValid(plan.weapon) then
            clearPlan(ply)
        else
            local state = Specials.PlayerState and Specials.PlayerState[ply] or nil
            local ar2 = state and state.ar2 or nil
            if not ar2 or ar2.weapon ~= plan.weapon then
                clearPlan(ply)
            elseif ar2.active ~= true then
                local roundsFired = math.max(0,
                    math.floor(tonumber(plan.roundsFired) or 0))
                local targetShots = math.max(1,
                    math.floor(tonumber(plan.targetShots) or AR2_BASE_BURST_ROUNDS))
                clearPlan(ply)

                -- Only completion of the authoritative projectile target earns
                -- faster cadence. Never infer projectile completion from Clip1:
                -- every AR2 trigger burst has exactly one ammo debit regardless of
                -- whether it resolves 3, 4, 5, or 6 projectiles.
                if roundsFired >= targetShots then
                    local readyAt, changed = Effects:RateOfFireAR2ReadyAt(
                        plan.startedAt, plan.authoredReadyAt, now, plan.multiplier)
                    if changed then
                        ar2.readyAt = readyAt
                        plan.weapon:SetNextPrimaryFire(readyAt)
                        Effects.AttackRateStats.confirmedAttacks =
                            (Effects.AttackRateStats.confirmedAttacks or 0) + 1
                        Effects:RecordRateOfFireScale(
                            ply,
                            "weapon_ar2",
                            "primary",
                            plan.multiplier,
                            math.max(0, plan.authoredReadyAt - plan.startedAt),
                            math.max(0, readyAt - plan.startedAt),
                            "ar2_burst_complete")
                    end
                end
            end
        end
    end
end)

hook.Add("PlayerDeath", "LOD_RPG_GateE_AR2RateOfFireDeath", clearPlan)
hook.Add("PlayerDisconnected", "LOD_RPG_GateE_AR2RateOfFireDisconnect", clearPlan)

local function burstTarget(ply)
    local bonus = isfunction(Rules.BurstBonusRounds)
        and Rules:BurstBonusRounds(ply)
        or (isfunction(Rules.BurstSizeBonus) and Rules:BurstSizeBonus(ply) or 0)
    bonus = math.Clamp(math.floor(tonumber(bonus) or 0), 0, 3)
    local target = isfunction(Rules.ResolveBurstCount)
        and Rules:ResolveBurstCount(AR2_BASE_BURST_ROUNDS, bonus)
        or (AR2_BASE_BURST_ROUNDS + bonus)
    return math.max(AR2_BASE_BURST_ROUNDS, math.floor(tonumber(target) or AR2_BASE_BURST_ROUNDS)), bonus
end

-- Compatibility adapter for a stale pre-correction PlayerWeaponSpecials file.
-- The current RecordBurstSizeResult signature begins with weaponClass; the old
-- finishAR2 helper passed rounds/target/desired/bonus. Normalize that legacy call
-- here so runtime evidence remains truthful even when an older base file wins a
-- duplicate-addon filesystem collision.
if isfunction(Effects.RecordBurstSizeResult) and not Effects.LODAR2LegacyBurstRecordAdapter then
    Effects.LODAR2LegacyBurstRecordAdapter = true
    local baseRecordBurstSizeResult = Effects.RecordBurstSizeResult
    function Effects:RecordBurstSizeResult(ply, weaponClass, roundsResolved,
        authoredBurstCount, finalBurstCount, bonus)
        if not isstring(weaponClass) then
            local legacyRounds = math.max(0, math.floor(tonumber(weaponClass) or 0))
            local legacyTarget = math.max(1, math.floor(tonumber(roundsResolved) or 1))
            local legacyDesired = math.max(legacyTarget,
                math.floor(tonumber(authoredBurstCount) or legacyTarget))
            local legacyBonus = math.Clamp(
                math.floor(tonumber(finalBurstCount) or 0), 0, 3)
            return baseRecordBurstSizeResult(self, ply, "weapon_ar2", legacyRounds,
                AR2_BASE_BURST_ROUNDS, legacyDesired, legacyBonus)
        end
        return baseRecordBurstSizeResult(self, ply, weaponClass, roundsResolved,
            authoredBurstCount, finalBurstCount, bonus)
    end
end

-- The development addon can coexist with the public Workshop package. If GMod's
-- filesystem resolves an older sv_player_weapon_specials.lua first, the mutable
-- methods below may still use the retired per-projectile ammo semantics even while
-- the new Gate-E modules are loaded. Therefore this final integration seam enforces
-- the GDD transaction as postconditions around whichever base method was resolved:
-- exactly one Clip1 debit at commit, 3+bonus committed projectiles, and zero ammo
-- mutation while those projectiles resolve. On a current base these checks are
-- idempotent; on a stale base they repair it without duplicating weapon behavior.
local function installAuthorityWrappers()
    local currentBegin = Specials.BeginAR2Burst
    if isfunction(currentBegin)
        and (not Specials.LODRateOfFireBeginWrapper or currentBegin ~= Specials.LODRateOfFireBeginWrapper)
    then
        local baseBegin = currentBegin
        local beginWrapper
        beginWrapper = function(self, ply, weapon, direction)
            local startedAt = CurTime()
            local clipBefore = IsValid(weapon) and math.max(0, weapon:Clip1()) or 0
            local ok = baseBegin(self, ply, weapon, direction)
            if not ok then return ok end

            local state = Specials.PlayerState and Specials.PlayerState[ply] or nil
            local ar2 = state and state.ar2 or nil
            if ar2 and ar2.active == true and ar2.weapon == weapon then
                local alreadyCommitted = ar2.ammoCommitted == 1
                local expectedClip = math.max(0, clipBefore - 1)
                if IsValid(weapon) and weapon:Clip1() ~= expectedClip then
                    weapon:SetClip1(expectedClip)
                end
                if not alreadyCommitted then
                    self.Stats = self.Stats or {}
                    self.Stats.ar2AmmoCommitted = (self.Stats.ar2AmmoCommitted or 0) + 1
                    ar2.ammoCommitted = 1
                    ar2.LODLegacyPerProjectileAmmo = true
                else
                    ar2.LODLegacyPerProjectileAmmo = false
                end

                local targetShots, bonus = burstTarget(ply)
                ar2.targetShots = targetShots
                ar2.desiredShots = targetShots
                ar2.burstSizeBonus = bonus

                local config = self.AR2Config or {}
                local telegraph = tonumber(config.telegraph) or 0.45
                local spacing = tonumber(config.burstSpacing) or 0.09
                local recovery = tonumber(config.recovery) or 0.25
                ar2.fireAt = tonumber(ar2.fireAt) or (startedAt + telegraph)
                ar2.nextShotAt = tonumber(ar2.nextShotAt) or ar2.fireAt
                ar2.readyAt = ar2.fireAt + (targetShots - 1) * spacing + recovery
                if IsValid(weapon) then weapon:SetNextPrimaryFire(ar2.readyAt) end

                self.AR2GateEAuthorityRevision = AUTHORITY_REVISION
                self.AR2GateEBaseMode = alreadyCommitted and "native" or "compat"
            end

            Effects:BeginAR2RateOfFirePlan(ply, weapon, startedAt)
            return ok
        end
        Specials.LODRateOfFireBeginBase = baseBegin
        Specials.LODRateOfFireBeginWrapper = beginWrapper
        Specials.BeginAR2Burst = beginWrapper
        print("[LOD:RPG-E] custom AR2 BeginAR2Burst wrapped with one-ammo burst authority")
    end

    local currentFire = Specials.FireAR2Round
    if isfunction(currentFire)
        and (not Specials.LODRateOfFireFireWrapper or currentFire ~= Specials.LODRateOfFireFireWrapper)
    then
        local baseFire = currentFire
        local fireWrapper
        fireWrapper = function(self, ply, ar2)
            local weapon = ar2 and ar2.weapon or nil
            local preserveClip = ar2 and ar2.LODLegacyPerProjectileAmmo == true
                and IsValid(weapon)
            local clipBefore = preserveClip and math.max(0, weapon:Clip1()) or nil

            -- A stale base refuses to fire at Clip1==0 and decrements Clip1 per
            -- projectile. Give only that base a temporary one-round view, then
            -- restore the already-committed clip after the projectile resolves.
            if preserveClip and clipBefore <= 0 then weapon:SetClip1(1) end
            local ok = baseFire(self, ply, ar2)
            if preserveClip and IsValid(weapon) then weapon:SetClip1(clipBefore) end

            if ok then
                local plan = Effects.AR2RateOfFirePlans[ply]
                if plan and ar2 and plan.weapon == ar2.weapon then
                    plan.roundsFired = (tonumber(plan.roundsFired) or 0) + 1
                end
            end
            return ok
        end
        Specials.LODRateOfFireFireBase = baseFire
        Specials.LODRateOfFireFireWrapper = fireWrapper
        Specials.FireAR2Round = fireWrapper
        print("[LOD:RPG-E] custom AR2 FireAR2Round wrapped with committed-ammo preservation")
    end

    local installed = Specials.BeginAR2Burst == Specials.LODRateOfFireBeginWrapper
        and Specials.FireAR2Round == Specials.LODRateOfFireFireWrapper
    if installed then
        Specials.AR2GateEAuthorityRevision = AUTHORITY_REVISION
        Specials.AR2GateEBaseMode = Specials.AR2GateEBaseMode or "unproven"
    end
    return installed
end

Effects.InstallAR2RateOfFireAuthorityWrappers = installAuthorityWrappers

timer.Simple(0, installAuthorityWrappers)
hook.Add("OnReloaded", "LOD_RPG_GateE_AR2RateOfFireRebind", function()
    timer.Simple(0, installAuthorityWrappers)
end)

Effects.LODRateOfFireAR2NetBridgeInstalled = true
print("[LOD:RPG-E] custom AR2 rate-of-fire transaction bridge armed; revision=" .. AUTHORITY_REVISION)
return Effects
