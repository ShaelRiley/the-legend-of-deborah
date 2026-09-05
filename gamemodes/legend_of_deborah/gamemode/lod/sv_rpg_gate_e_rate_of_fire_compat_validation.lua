LOD = LOD or {}
local RPG = LOD.RPG
local Effects = RPG and RPG.FeatEffectSystem
if not Effects or not isfunction(Effects.ValidateRateOfFireCadence)
    or not isfunction(Effects.RateOfFireConfirmedDeadlineReady)
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

    -- Stock Source weapons may publish shot proof one server tick before their
    -- post-shot primary deadline. The compatibility bridge must retain the shot
    -- and wait for a genuinely new deadline rather than scaling the pre-shot tell.
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

    return ok and #errors == 0, errors
end

return Effects
