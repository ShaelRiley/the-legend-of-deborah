LOD = LOD or {}

local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Specials = LOD.PlayerWeaponSpecials
if not Effects or not Rules or not Specials then return end
if Effects.LODRateOfFireAR2NetBridgeInstalled then return Effects end

local EPSILON = (Effects.RateOfFireConfig and Effects.RateOfFireConfig.epsilon) or 0.002
local AR2_BURST_ROUNDS = 3

-- The AR2 uses a custom burst transaction rather than ordinary stock IN_ATTACK
-- cadence authority. Rate of Fire therefore owns a plan table keyed by player.
-- A plan begins immediately after the authoritative BeginAR2Burst succeeds. Each
-- successful authoritative FireAR2Round is counted on that player-local plan, and
-- a standalone Think observer commits the faster next-trigger deadline only after
-- the burst has ended. The targeting laser and internal three-shot spacing remain
-- outside this feat family's authority.
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
        clipBefore = weapon.Clip1 and weapon:Clip1() or -1,
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
                local clipNow = plan.weapon.Clip1 and plan.weapon:Clip1() or -1
                local clipRounds = (tonumber(plan.clipBefore) or -1) - clipNow
                local roundsFired = math.max(tonumber(plan.roundsFired) or 0, clipRounds)
                clearPlan(ply)

                -- Zero-, one-, and two-round aborts keep the authored cooldown.
                -- Only a completed three-round transaction earns faster cadence.
                if roundsFired >= AR2_BURST_ROUNDS then
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

-- Some AR2 activations originate in the server StartCommand path rather than the
-- client activation receiver. Install against the final weapon-special methods on
-- the first server tick, after all synchronous gamemode includes have completed.
-- BeginAR2Burst starts the player-local cadence plan and FireAR2Round confirms its
-- exact completed rounds. This avoids relying on clip timing or global counters and
-- remains correct when multiple players fire AR2s concurrently.
local function installAuthorityWrappers()
    local currentBegin = Specials.BeginAR2Burst
    if isfunction(currentBegin)
        and (not Specials.LODRateOfFireBeginWrapper or currentBegin ~= Specials.LODRateOfFireBeginWrapper)
    then
        local baseBegin = currentBegin
        local beginWrapper
        beginWrapper = function(self, ply, weapon, direction)
            local startedAt = CurTime()
            local ok = baseBegin(self, ply, weapon, direction)
            if ok then
                Effects:BeginAR2RateOfFirePlan(ply, weapon, startedAt)
            end
            return ok
        end
        Specials.LODRateOfFireBeginBase = baseBegin
        Specials.LODRateOfFireBeginWrapper = beginWrapper
        Specials.BeginAR2Burst = beginWrapper
        print("[LOD:RPG-E] custom AR2 rate-of-fire BeginAR2Burst authority wrapped")
    end

    local currentFire = Specials.FireAR2Round
    if isfunction(currentFire)
        and (not Specials.LODRateOfFireFireWrapper or currentFire ~= Specials.LODRateOfFireFireWrapper)
    then
        local baseFire = currentFire
        local fireWrapper
        fireWrapper = function(self, ply, ar2)
            local ok = baseFire(self, ply, ar2)
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
        print("[LOD:RPG-E] custom AR2 rate-of-fire FireAR2Round authority wrapped")
    end

    return Specials.BeginAR2Burst == Specials.LODRateOfFireBeginWrapper
        and Specials.FireAR2Round == Specials.LODRateOfFireFireWrapper
end

timer.Simple(0, installAuthorityWrappers)
hook.Add("OnReloaded", "LOD_RPG_GateE_AR2RateOfFireRebind", function()
    timer.Simple(0, installAuthorityWrappers)
end)

Effects.LODRateOfFireAR2NetBridgeInstalled = true
print("[LOD:RPG-E] custom AR2 rate-of-fire transaction bridge armed")
return Effects