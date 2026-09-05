LOD = LOD or {}

local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Specials = LOD.PlayerWeaponSpecials
if not Effects or not Rules or not Specials then return end
if not isfunction(Specials.BeginAR2Burst) or not isfunction(Specials.ProcessPlayer) then return end
if Effects.LODRateOfFireAR2BridgeInstalled then return Effects end

local EPSILON = (Effects.RateOfFireConfig and Effects.RateOfFireConfig.epsilon) or 0.002
local AR2_BURST_ROUNDS = 3

-- The AR2 owns a custom three-shot transaction instead of ordinary IN_ATTACK:
-- client prediction strips stock fire input and asks PlayerWeaponSpecials to start
-- the burst directly. Compose Rate of Fire at that authored authority. The GDD
-- says the total primary-attack opportunity interval is divided, while the laser
-- duration and internal three-shot spacing are immutable. Applying the divided
-- deadline only after the burst completes gives those internal phases an absolute
-- floor without duplicating their timing constants here.
function Effects:RateOfFireAR2ReadyAt(startedAt, authoredReadyAt, completedAt, multiplier)
    startedAt = tonumber(startedAt) or 0
    authoredReadyAt = tonumber(authoredReadyAt) or startedAt
    completedAt = tonumber(completedAt) or startedAt
    multiplier = math.Clamp(tonumber(multiplier) or 1, 1.00, 1.30)
    if multiplier <= 1.00 + EPSILON or authoredReadyAt <= startedAt + EPSILON then
        return math.max(completedAt, authoredReadyAt), false
    end

    local dividedReadyAt = startedAt + (authoredReadyAt - startedAt) / multiplier
    return math.max(completedAt, dividedReadyAt), dividedReadyAt < authoredReadyAt - EPSILON
end

Effects.LODRateOfFireAR2BridgeInstalled = true

local baseBegin = Specials.BeginAR2Burst
function Specials:BeginAR2Burst(ply, weapon, direction)
    local startedAt = CurTime()
    local clipBefore = IsValid(weapon) and weapon.Clip1 and weapon:Clip1() or -1
    local ok = baseBegin(self, ply, weapon, direction)
    if not ok then return false end

    local state = self.PlayerState and self.PlayerState[ply] or nil
    local ar2 = state and state.ar2 or nil
    if not ar2 then return true end

    -- If some server input path also opened the generic stock-fire observer,
    -- discard it. The custom AR2 transaction is the sole cadence authority here.
    if isfunction(Effects.EndAttackRateObservation) then
        Effects:EndAttackRateObservation(ply)
    end

    local multiplier = Rules:RateOfFireMultiplier(ply)
    local authoredReadyAt = tonumber(ar2.readyAt) or startedAt
    local targetReadyAt, changed = Effects:RateOfFireAR2ReadyAt(
        startedAt, authoredReadyAt, startedAt, multiplier)

    if changed then
        ar2.lodRateOfFirePlan = {
            startedAt = startedAt,
            authoredReadyAt = authoredReadyAt,
            targetReadyAt = targetReadyAt,
            multiplier = multiplier,
            clipBefore = clipBefore,
            roundsAtStart = tonumber(self.Stats and self.Stats.ar2Rounds) or 0
        }
        Effects.AttackRateStats.sessions = (Effects.AttackRateStats.sessions or 0) + 1
    else
        ar2.lodRateOfFirePlan = nil
    end
    return true
end

local baseProcess = Specials.ProcessPlayer
function Specials:ProcessPlayer(ply, state, now)
    local ar2Before = state and state.ar2 or nil
    local plan = ar2Before and ar2Before.lodRateOfFirePlan or nil
    local wasActive = ar2Before and ar2Before.active == true

    baseProcess(self, ply, state, now)

    local ar2 = state and state.ar2 or nil
    if not plan or not wasActive or not ar2 or ar2.active then return end

    ar2.lodRateOfFirePlan = nil
    local roundsNow = tonumber(self.Stats and self.Stats.ar2Rounds) or 0
    local roundsFired = roundsNow - (tonumber(plan.roundsAtStart) or roundsNow)
    local weapon = ar2.weapon

    -- Abort paths may end the transaction after zero, one, or two rounds. Only a
    -- completed authored three-shot burst earns the faster next trigger window.
    if roundsFired < AR2_BURST_ROUNDS or not IsValid(weapon) then return end

    local completedAt = tonumber(now) or CurTime()
    local readyAt, changed = Effects:RateOfFireAR2ReadyAt(
        plan.startedAt, plan.authoredReadyAt, completedAt, plan.multiplier)
    if not changed then return end

    -- PlayerWeaponSpecials has just applied its ordinary recovery. Replace only
    -- that next-trigger deadline. The burst itself has already completed, so the
    -- laser and internal shot spacing cannot be shortened by this operation.
    ar2.readyAt = readyAt
    weapon:SetNextPrimaryFire(readyAt)

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

return Effects
