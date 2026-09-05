LOD = LOD or {}
local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
if not Effects or not isfunction(Effects.ValidateRateOfFireCadence)
    or not isfunction(Effects.RateOfFireConfirmedDeadlineReady)
    or not isfunction(Effects.RateOfFireCanObserveAttackState)
then
    return
end
if Effects.LODRateOfFireDelayedDeadlineValidationWrapped then return Effects end

Effects.LODRateOfFireDelayedDeadlineValidationWrapped = true
local baseValidate = Effects.ValidateRateOfFireCadence

function Effects:ValidateRateOfFireCadence()
    local ok, errors = baseValidate(self)
    errors = errors or {}
    local function expect(condition, message)
        if not condition then errors[#errors + 1] = message end
    end

    -- Stock Source firearms may publish shot proof one server tick before their
    -- post-shot primary deadline. Keep that transaction alive until the genuine
    -- post-shot deadline appears; never infer cadence from a pre-shot lock.
    expect(self:RateOfFireCanObserveAttackState("weapon_pistol", false, 18, 100.8, 100.0),
        "ordinary firearm observation may begin while a pre-shot deadline is active")
    expect(not self:RateOfFireCanObserveAttackState("weapon_pistol", true, 18, 100.8, 100.0),
        "firearm reload blocks attack-rate observation")
    expect(not self:RateOfFireCanObserveAttackState("weapon_pistol", false, 0, 100.8, 100.0),
        "empty firearm blocks attack-rate observation")
    expect(not self:RateOfFireCanObserveAttackState("weapon_lod_crowbar", false, -1, 100.0, 100.0),
        "Crowbar is excluded because the live GDD family is ordinary-firearm-only")

    local earlyReady, earlyFloor = self:RateOfFireConfirmedDeadlineReady(
        100.0, 100.8, 100.8, 100.6)
    expect(not earlyReady and math.abs(earlyFloor - 100.8) < 0.0001,
        "confirmed stock shot waits for delayed post-shot deadline")

    local delayedReady, delayedFloor = self:RateOfFireConfirmedDeadlineReady(
        100.0, 100.8, 101.4, 100.81)
    expect(delayedReady and math.abs(delayedFloor - 100.8) < 0.0001,
        "delayed post-shot deadline clears protected pre-shot floor")

    local scaled, changed = LOD.RPGAbilityRules:ScaleAttackDeadline(
        100.81, delayedFloor, 101.4, 1.30)
    expect(changed and scaled >= delayedFloor and scaled < 101.4,
        "delayed stock deadline scales only after shot proof")

    expect(isfunction(self.RateOfFireAR2ReadyAt),
        "custom AR2 cadence timing helper is installed")
    expect(isfunction(self.BeginAR2RateOfFirePlan),
        "canonical AR2 activation transaction bridge is installed")
    if isfunction(self.RateOfFireAR2ReadyAt) then
        local ar2Ready, ar2Changed = self:RateOfFireAR2ReadyAt(100.0, 100.88, 100.63, 1.30)
        local expected = 100.0 + 0.88 / 1.30
        expect(ar2Changed and math.abs(ar2Ready - expected) < 0.0001,
            "AR2 total next-trigger interval is divided by Lead Storm")

        local delayedCompletion, delayedChanged = self:RateOfFireAR2ReadyAt(
            100.0, 100.88, 100.70, 1.30)
        expect(delayedChanged and math.abs(delayedCompletion - 100.70) < 0.0001,
            "AR2 completed burst is an absolute floor for laser/internal spacing")

        local tooLate, tooLateChanged = self:RateOfFireAR2ReadyAt(
            100.0, 100.88, 100.90, 1.30)
        expect(not tooLateChanged and math.abs(tooLate - 100.90) < 0.0001,
            "late completion never fabricates a cadence gain")

        local baselineReady, baselineChanged = self:RateOfFireAR2ReadyAt(
            100.0, 100.88, 100.63, 1.00)
        expect(not baselineChanged and math.abs(baselineReady - 100.88) < 0.0001,
            "AR2 baseline cadence remains unchanged at rank zero")
    end

    return ok and #errors == 0, errors
end

return Effects
