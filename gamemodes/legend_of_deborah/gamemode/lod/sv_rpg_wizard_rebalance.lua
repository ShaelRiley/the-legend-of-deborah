LOD = LOD or {}
LOD.RPGWizardRules = LOD.RPGWizardRules or {}

local WizardRules = LOD.RPGWizardRules
local RPG = LOD.RPG
local Catalog = RPG and RPG.IdentityCatalog
local CPS = LOD.CharacterProgressionSystem
local AbilityRules = LOD.RPGAbilityRules

assert(Catalog and Catalog.LevelOneOrdinaryFeats,
    "Wizard rebalance requires the Gate B feat catalog")
assert(CPS and CPS._RecomputeProgressionState and CPS._FeatEligible and CPS.CommitFeat,
    "Wizard rebalance requires CharacterProgressionSystem")
assert(AbilityRules and AbilityRules.ComputeMagicDiversion and AbilityRules.ApplyPlayerDefense,
    "Wizard rebalance requires Gate D damage authority")

WizardRules.SourceDocumentId = "1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY"
WizardRules.SourceRevisionId = "ANLCKQkGupEJlFx63tAKzcdC_lYLLvY9Gs6mRh_dI4M8HHG444-tZoACMXw-jjFRTf_pf3nEstm2QbA5vcfu9tco6LuO-oOvVnlAdbA_uA"
WizardRules.WizardDiversionBase = 0.10
WizardRules.WizardDiversionPerLevelAfterFirst = 0.025
WizardRules.MagicBoomThresholdShift = -1

local feats = Catalog.LevelOneOrdinaryFeats
local rankOne = assert(feats.INT_MANA_BARRIER_1,
    "Mana Barrier rank 1 must exist before Wizard rebalance loads")
local rankTwo = assert(feats.INT_MANA_BARRIER_2,
    "Arcane Aegis must exist before Wizard rebalance loads")
local rankThree = assert(feats.INT_MANA_BARRIER_3,
    "Mystic Bastion must exist before Wizard rebalance loads")

-- The Mana Barrier family is now the non-Wizard INT route to HP->Magic defense.
rankOne.actorText = "Eligible non-Wizard heroes, human Soldiers, and Magic-using AI"
rankOne.effectParams = rankOne.effectParams or {}
rankOne.effectParams.description = "Sets ManaBarrierFeatDiversionFraction = 0.15. This feat family is unavailable to Wizard-class actors; it is the INT-gated HP-to-Magic diversion path for eligible non-Wizards. Diversion uses continuous post-mitigation HP damage and continuous Magic rather than whole-number rounding."
rankTwo.actorText = "Eligible non-Wizard heroes, human Soldiers, and Magic-using AI"
rankTwo.effectParams = rankTwo.effectParams or {}
rankTwo.effectParams.description = "Replaces Mana Barrier and sets ManaBarrierFeatDiversionFraction = 0.30. This feat is unavailable to Wizard-class actors. Diversion uses the shared continuous post-mitigation HP-to-Magic authority."
rankThree.actorText = "Eligible non-Wizard heroes, human Soldiers, and Magic-using AI"
rankThree.effectParams = rankThree.effectParams or {}
rankThree.effectParams.description = "Replaces lower Mana Barrier ranks and sets ManaBarrierFeatDiversionFraction = 0.45. This feat is unavailable to Wizard-class actors. Diversion uses the shared continuous post-mitigation HP-to-Magic authority."

-- Russian Asset keeps its stable feat ID for save compatibility; only its authored
-- qualification moves from CON to INT.
local russianAsset = assert(feats.CON_RUSSIAN_ASSET,
    "Russian Asset must exist before Wizard rebalance loads")
russianAsset.governingAbilities = {"int"}
russianAsset.abilityRequirements = {int = 12}
russianAsset.eligibilityText = "INT 12"

local function featDefinition(featId)
    return (Catalog.LevelOneOrdinaryFeats and Catalog.LevelOneOrdinaryFeats[featId])
        or (Catalog.FallbackFeats and Catalog.FallbackFeats[featId])
end

local function hasFeat(state, wanted)
    for _, featId in ipairs(state and state.featIds or {}) do
        if featId == wanted then return true end
    end
    return false
end

local function isManaBarrierDefinition(definition)
    return definition and definition.featFamilyId == WizardRules.ManaBarrierFamilyId
end

-- Keep the runtime schema truthful even before a future schema-version rollup.
if RPG and RPG.Schema and RPG.Schema.DerivedStats then
    local found = false
    for _, fieldName in ipairs(RPG.Schema.DerivedStats) do
        if fieldName == "magicBoomThresholdShift" then
            found = true
            break
        end
    end
    if not found then RPG.Schema.DerivedStats[#RPG.Schema.DerivedStats + 1] = "magicBoomThresholdShift" end
end

function WizardRules:ClassDiversionFraction(state)
    if not state or state.classId ~= "wizard" then return 0 end
    local level = math.Clamp(math.floor(tonumber(state.level) or 1), 1, 20)
    return math.Clamp(self.WizardDiversionBase
        + self.WizardDiversionPerLevelAfterFirst * (level - 1), 0, 0.575)
end

function WizardRules:ManaBarrierFeatDiversionFraction(state)
    if state and state.classId == "wizard" then return 0 end
    local best = 0
    for _, featId in ipairs(state and state.featIds or {}) do
        local definition = featDefinition(featId)
        local params = definition and definition.effectParams
        local value = tonumber(params and params.manaBarrierFeatDiversionFraction)
            or tonumber(self.ManaBarrierFractions and self.ManaBarrierFractions[featId])
            or 0
        best = math.max(best, value)
    end
    return math.Clamp(best, 0, 0.45)
end

function WizardRules:ApplyDerived(state)
    if not state or not state.derivedStats then return end
    local derived = state.derivedStats
    derived.wizardClassHpToMagicDiversionFraction = self:ClassDiversionFraction(state)
    derived.manaBarrierFeatDiversionFraction = self:ManaBarrierFeatDiversionFraction(state)
    derived.wizardCapstoneDiversionBonus = tonumber(derived.wizardCapstoneDiversionBonus) or 0
    derived.magicBoomThresholdShift = state.classId == "wizard"
        and self.MagicBoomThresholdShift or 0
    derived.hpToMagicDiversionFraction = math.min(1,
        derived.wizardClassHpToMagicDiversionFraction
        + derived.manaBarrierFeatDiversionFraction
        + derived.wizardCapstoneDiversionBonus)
end

-- Existing Gate C recomputation calls WizardRules:ApplyDerived dynamically through
-- the prior Wizard module, so replacing the method above updates every consumer.
-- Add class eligibility at the same feat-director seam without creating a second
-- draft authority.
if not CPS.LODWizardRebalanceEligibilityWrapped then
    CPS.LODWizardRebalanceEligibilityWrapped = true
    local priorFeatEligible = CPS._FeatEligible
    function CPS:_FeatEligible(ps, state, definition)
        if state and state.classId == "wizard" and isManaBarrierDefinition(definition) then
            return false
        end
        return priorFeatEligible(self, ps, state, definition)
    end
end

-- A persisted pre-rebalance Wizard draft may still contain a Mana Barrier card.
-- Reject that stale selection rather than granting a now-illegal family effect.
if not CPS.LODWizardRebalanceCommitWrapped then
    CPS.LODWizardRebalanceCommitWrapped = true
    local priorCommitFeat = CPS.CommitFeat
    function CPS:CommitFeat(ply, featId, expectedEarnedAtLevel)
        local run = LOD.RunManager
        local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState
        local definition = featDefinition(featId)
        if state and state.classId == "wizard" and isManaBarrierDefinition(definition) then
            return false, "Wizard uses innate Arcane Diversion instead of Mana Barrier feats"
        end
        return priorCommitFeat(self, ply, featId, expectedEarnedAtLevel)
    end
end

-- Continuous diversion fixes the small-hit dead zone produced by whole-number
-- rounding. Gate D remains the sole damage application seam; only its pure math
-- helper changes.
function AbilityRules:ComputeMagicDiversion(resolvedHPDamage, fraction, currentMagic, hpPerMagic)
    local resolved = math.max(0, tonumber(resolvedHPDamage) or 0)
    local authoredFraction = math.Clamp(tonumber(fraction) or 0, 0, 1)
    local available = math.max(0, tonumber(currentMagic) or 0)
    local exchange = math.max(0.01, tonumber(hpPerMagic) or 1)
    local desiredHP = resolved * authoredFraction
    local divertedHP = math.min(desiredHP, available * exchange)
    local spentMagic = divertedHP / exchange
    return divertedHP, spentMagic, math.max(0, resolved - divertedHP)
end

-- Gate D already emits the detailed ARCANE DIVERSION combat-feed line. Publish a
-- tiny serial + amounts through NW2 vars so the existing Magic HUD can visibly
-- acknowledge each actual absorption without a parallel combat message system.
if not AbilityRules.LODWizardDiversionFeedbackWrapped then
    AbilityRules.LODWizardDiversionFeedbackWrapped = true
    local priorApplyPlayerDefense = AbilityRules.ApplyPlayerDefense
    function AbilityRules:ApplyPlayerDefense(target, dmginfo)
        local result = priorApplyPlayerDefense(self, target, dmginfo)
        local diverted = tonumber(result and result.actualMagicDiversion) or 0
        if IsValid(target) and target:IsPlayer() and diverted > 0 then
            target:SetNW2Float("LOD_ArcaneDiversionHP", diverted)
            target:SetNW2Float("LOD_ArcaneDiversionMagic", tonumber(result.magicSpent) or diverted)
            target:SetNW2Int("LOD_ArcaneDiversionSerial",
                target:GetNW2Int("LOD_ArcaneDiversionSerial", 0) + 1)
        end
        return result
    end
end

local function newSyntheticState(classId, level, featIds, capstoneId)
    local state = CPS:NewProgressionState("wizard-rebalance-validation", "hero", "hero")
    state.baseAbilities = RPG.NewAbilityBlock(10)
    state.startingHP = 100
    state.classId = classId
    state.level = level
    state.progressionHitDieSides = RPG.Classes[classId].heroProgressionHitDieSides
    state.primaryAbility = RPG.Classes[classId].favoredAbilities[1]
    state.secondaryAbilities = {RPG.Classes[classId].favoredAbilities[2], "con"}
    state.featIds = table.Copy(featIds or {})
    state.classCapstoneFeatId = capstoneId
    CPS:_RecomputeProgressionState(state)
    return state
end

local function closeEnough(actual, expected)
    return math.abs((tonumber(actual) or 0) - expected) < 0.00001
end

function WizardRules:Validate(ply)
    local errors = {}
    local function expect(condition, label)
        if not condition then errors[#errors + 1] = label end
    end

    expect(rankOne.effectParams.manaBarrierFeatDiversionFraction == 0.15,
        "Mana Barrier fraction")
    expect(rankTwo.effectParams.manaBarrierFeatDiversionFraction == 0.30
        and rankTwo.prerequisiteFeatIds[1] == "INT_MANA_BARRIER_1",
        "Arcane Aegis catalog")
    expect(rankThree.effectParams.manaBarrierFeatDiversionFraction == 0.45
        and rankThree.prerequisiteFeatIds[1] == "INT_MANA_BARRIER_2",
        "Mystic Bastion catalog")
    expect(russianAsset.abilityRequirements and russianAsset.abilityRequirements.int == 12
        and russianAsset.abilityRequirements.con == nil
        and russianAsset.governingAbilities[1] == "int",
        "Russian Asset INT qualification")

    local l1 = newSyntheticState("wizard", 1)
    local l2 = newSyntheticState("wizard", 2)
    local l4 = newSyntheticState("wizard", 4)
    local l10 = newSyntheticState("wizard", 10)
    local l20 = newSyntheticState("wizard", 20)
    local staleWizardBarrier = newSyntheticState("wizard", 10, {"INT_MANA_BARRIER_1"})
    local rogueBarrier = newSyntheticState("rogue", 10, {"INT_MANA_BARRIER_1"})
    local l20LivingAegis = newSyntheticState("wizard", 20, {}, "WIZ_CAP_LIVING_AEGIS")

    expect(closeEnough(l1.derivedStats.wizardClassHpToMagicDiversionFraction, 0.10),
        "Wizard Level-1 innate diversion")
    expect(closeEnough(l2.derivedStats.wizardClassHpToMagicDiversionFraction, 0.125),
        "Wizard Level-2 innate diversion")
    expect(closeEnough(l4.derivedStats.wizardClassHpToMagicDiversionFraction, 0.175),
        "Wizard Level-4 innate diversion")
    expect(closeEnough(l10.derivedStats.wizardClassHpToMagicDiversionFraction, 0.325),
        "Wizard Level-10 innate diversion")
    expect(closeEnough(l20.derivedStats.wizardClassHpToMagicDiversionFraction, 0.575),
        "Wizard Level-20 innate diversion")
    expect(closeEnough(l1.derivedStats.magicBoomThresholdShift, -1)
        and closeEnough(rogueBarrier.derivedStats.magicBoomThresholdShift, 0),
        "Wizard-only magical Boom threshold shift")
    expect(closeEnough(staleWizardBarrier.derivedStats.manaBarrierFeatDiversionFraction, 0)
        and closeEnough(staleWizardBarrier.derivedStats.hpToMagicDiversionFraction, 0.325),
        "Wizard ignores legacy Mana Barrier ownership")
    expect(closeEnough(rogueBarrier.derivedStats.hpToMagicDiversionFraction, 0.15),
        "non-Wizard Mana Barrier diversion")
    expect(closeEnough(l20LivingAegis.derivedStats.hpToMagicDiversionFraction, 0.675)
        and closeEnough(l20LivingAegis.derivedStats.livingAegisHPPerMagic, 1.25),
        "Living Aegis Level-20 diversion/exchange")

    local eligibilityState = newSyntheticState("wizard", 10)
    eligibilityState.featQualificationAbilities.int = 18
    local fakePS = {starterWeaponClass = "weapon_pistol"}
    expect(not CPS:_FeatEligible(fakePS, eligibilityState, rankOne),
        "Wizard cannot draft Mana Barrier")

    local divertedSmall, spentSmall, remainingSmall =
        AbilityRules:ComputeMagicDiversion(3, 0.10, 100, 1)
    expect(closeEnough(divertedSmall, 0.3) and closeEnough(spentSmall, 0.3)
        and closeEnough(remainingSmall, 2.7),
        "fractional small-hit diversion")
    local divertedLimited, spentLimited, remainingLimited =
        AbilityRules:ComputeMagicDiversion(10, 0.50, 0.35, 1)
    expect(closeEnough(divertedLimited, 0.35) and closeEnough(spentLimited, 0.35)
        and closeEnough(remainingLimited, 9.65),
        "fractional CurrentMagic funding")
    local divertedAegis, spentAegis, remainingAegis =
        AbilityRules:ComputeMagicDiversion(50, 0.675, 8, 1.25)
    expect(closeEnough(divertedAegis, 10) and closeEnough(spentAegis, 8)
        and closeEnough(remainingAegis, 40),
        "Living Aegis efficient fractional exchange")

    local combat = LOD.RPGWizardCombat
    if combat and combat.Ready then
        expect(combat:ShiftThreshold(6, -1, 6) == 5,
            "Wizard Force Shout d6 threshold 5+")
        expect(combat:IsMagicDamageProfile({source = "force shout"}),
            "Force Shout classified as magical damage")
    else
        errors[#errors + 1] = "Wizard magical Boom integration not ready"
    end

    local currentState = IsValid(ply) and AbilityRules:ProgressionState(ply) or nil
    local derived = currentState and currentState.derivedStats or nil
    local ps = IsValid(ply) and LOD.Magic and LOD.Magic._EnsureState
        and LOD.Magic:_EnsureState(ply) or nil
    local currentMagic = tonumber(ps and ps.magic) or 0
    local total = tonumber(derived and derived.hpToMagicDiversionFraction) or 0
    local exchange = tonumber(derived and derived.livingAegisHPPerMagic) or 1
    local sampleDiverted, sampleSpent, sampleHP =
        AbilityRules:ComputeMagicDiversion(50, total, currentMagic, exchange)

    return #errors == 0, errors, {
        classId = currentState and currentState.classId or "none",
        level = currentState and currentState.level or 0,
        innate = tonumber(derived and derived.wizardClassHpToMagicDiversionFraction) or 0,
        feat = tonumber(derived and derived.manaBarrierFeatDiversionFraction) or 0,
        capstone = tonumber(derived and derived.wizardCapstoneDiversionBonus) or 0,
        total = total,
        boomShift = tonumber(derived and derived.magicBoomThresholdShift) or 0,
        magic = currentMagic,
        exchange = exchange,
        sampleDiverted = sampleDiverted,
        sampleSpent = sampleSpent,
        sampleHP = sampleHP
    }
end

-- The original validation concommand resolves WizardRules:Validate at execution
-- time, so the override above automatically becomes the focused runtime test.

function WizardRules:InstallMagicBoomIntegration()
    local Rolls = LOD.CombatRolls
    if not Rolls or not Rolls.RollActorDamage or not Rolls._RollExploding then return false end
    if Rolls.LODWizardMagicBoomWrapped then
        return LOD.RPGWizardCombat and LOD.RPGWizardCombat.Ready == true
    end

    LOD.RPGWizardCombat = LOD.RPGWizardCombat or {}
    local Combat = LOD.RPGWizardCombat

    function Combat:IsMagicDamageProfile(profile)
        if not profile then return false end
        if profile.magicDamage == true or profile.magic == true then return true end
        return string.lower(tostring(profile.source or "")) == "force shout"
    end

    function Combat:ShiftThreshold(baseThreshold, shift, sides)
        local dieSides = math.max(2, math.floor(tonumber(sides) or 2))
        local base = math.Clamp(math.floor(tonumber(baseThreshold) or dieSides), 2, dieSides)
        local offset = math.floor(tonumber(shift) or 0)
        return math.Clamp(base + offset, 2, dieSides)
    end

    local priorRollExploding = Rolls._RollExploding
    function Rolls:_RollExploding(profile, rng)
        local derived = profile and profile.rpgDerived
        local shift = tonumber(derived and derived.magicBoomThresholdShift) or 0
        local wizardMagic = profile and profile.magicDamage == true
            and profile.classExplosionImmune ~= true and shift < 0
        if not wizardMagic then return priorRollExploding(self, profile, rng) end

        local values = {}
        local contributions = {}
        local thresholds = {}
        local total = profile.bonus or 0
        local sides = math.max(2, math.floor(tonumber(profile.sides) or 2))
        local rules = LOD.RPGAbilityRules
        local parameters = rules and rules.ExplosionParameters
            and rules:ExplosionParameters(derived, sides, profile.classExplosionImmune) or nil
        local freshBase = parameters and (parameters.rogue or sides == 6)
            and parameters.fresh or tonumber(profile.exploding)
        freshBase = freshBase or sides
        local continuationBase = parameters and parameters.continuation or freshBase
        local freshThreshold = Combat:ShiftThreshold(freshBase, shift, sides)
        local continuationThreshold = Combat:ShiftThreshold(continuationBase, shift, sides)
        local threshold = freshThreshold
        local natural = rng:Int(1, sides)

        while natural and #values < 32 do
            values[#values + 1] = natural
            thresholds[#thresholds + 1] = threshold
            local contribution = math.max(profile.floor or natural, natural)
            contributions[#contributions + 1] = contribution
            total = total + contribution
            self.Stats.rolls = self.Stats.rolls + 1

            if natural < threshold then break end
            threshold = continuationThreshold
            natural = rng:Int(1, sides)
        end

        return total, values, contributions, #values >= 32, thresholds
    end

    local priorRollActorDamage = Rolls.RollActorDamage
    function Rolls:RollActorDamage(attacker, profile, rng, bonusDice)
        local derived = AbilityRules:Derived(attacker)
        local shift = tonumber(derived and derived.magicBoomThresholdShift) or 0
        if shift >= 0 or not Combat:IsMagicDamageProfile(profile)
            or (profile and profile.classExplosionImmune == true)
        then
            return priorRollActorDamage(self, attacker, profile, rng, bonusDice)
        end

        local magicProfile = table.Copy(profile or {})
        magicProfile.magicDamage = true
        local sides = math.max(2, math.floor(tonumber(magicProfile.sides) or 2))
        -- Mark non-universal magical dice as authored-exploding at their natural
        -- maximum; _RollExploding then applies the Wizard's -1 class threshold.
        if magicProfile.exploding == nil then magicProfile.exploding = sides end
        return priorRollActorDamage(self, attacker, magicProfile, rng, bonusDice)
    end

    Rolls.LODWizardMagicBoomWrapped = true
    Combat.Ready = true
    return true
end

local function installMagicBoom()
    if WizardRules:InstallMagicBoomIntegration() then
        hook.Remove("InitPostEntity", "LOD_WizardMagicBoomIntegration")
    end
end

-- shared.lua loads RPG rules before init.lua loads CombatRolls/Magic. A zero-delay
-- timer and InitPostEntity fallback install the wrapper only after that canonical
-- combat authority exists, without changing combat-module load order.
timer.Simple(0, installMagicBoom)
hook.Add("InitPostEntity", "LOD_WizardMagicBoomIntegration", installMagicBoom)

WizardRules.RebalanceReady = true
