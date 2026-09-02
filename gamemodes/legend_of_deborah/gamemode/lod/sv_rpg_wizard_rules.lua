LOD = LOD or {}
LOD.RPGWizardRules = LOD.RPGWizardRules or {}

local WizardRules = LOD.RPGWizardRules
local RPG = LOD.RPG
local Catalog = RPG and RPG.IdentityCatalog
local CPS = LOD.CharacterProgressionSystem
local AbilityRules = LOD.RPGAbilityRules

assert(Catalog and Catalog.LevelOneOrdinaryFeats,
    "Wizard RPG rules require the Gate B feat catalog")
assert(CPS and CPS._RecomputeProgressionState and CPS._FeatEligible and CPS.CommitFeat,
    "Wizard RPG rules require CharacterProgressionSystem")
assert(AbilityRules and AbilityRules.ComputeMagicDiversion,
    "Wizard RPG rules require Gate D damage authority")

WizardRules.SourceDocumentId = "1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY"
WizardRules.ManaBarrierFamilyId = "mana_barrier"
WizardRules.ManaBarrierFractions = {
    INT_MANA_BARRIER_1 = 0.15,
    INT_MANA_BARRIER_2 = 0.30,
    INT_MANA_BARRIER_3 = 0.45
}

local feats = Catalog.LevelOneOrdinaryFeats
local rankOne = assert(feats.INT_MANA_BARRIER_1,
    "live-GDD Mana Barrier rank 1 must exist before Wizard rules load")
rankOne.featFamilyId = WizardRules.ManaBarrierFamilyId
rankOne.rankIndex = 1
rankOne.replacesLowerRank = false
rankOne.allowedActorTypes = {"hero", "human_soldier", "ai"}
rankOne.effectParams = rankOne.effectParams or {}
rankOne.effectParams.manaBarrierFeatDiversionFraction = 0.15

feats.INT_MANA_BARRIER_2 = {
    featId = "INT_MANA_BARRIER_2",
    displayName = "Arcane Aegis",
    governingAbilities = {"int"},
    abilityRequirements = {int = 16},
    prerequisiteFeatIds = {"INT_MANA_BARRIER_1"},
    requiredCapabilityTags = {"magic_pool"},
    incompatibleFeatIds = {},
    allowedActorTypes = {"hero", "human_soldier", "ai"},
    requiredSubsystemTags = {},
    synergyTags = {"damage_diversion"},
    oneRank = true,
    featFamilyId = WizardRules.ManaBarrierFamilyId,
    rankIndex = 2,
    replacesLowerRank = true,
    effectHandlerId = "gate_b_feat_ownership",
    effectParams = {
        manaBarrierFeatDiversionFraction = 0.30,
        description = "Replaces Mana Barrier and sets ManaBarrierFeatDiversionFraction = 0.30. HPToMagicDiversionFraction still adds the actor's WizardClassHPToMagicDiversionFraction, if any, so a Wizard receives its innate class percentage plus 30 percentage points from Arcane Aegis. The same post-mitigation calculation and 1 Magic per 1 prevented HP exchange apply; diversion is limited by current whole Magic and any unpayable remainder is taken as HP damage normally."
    },
    directorBaseWeight = 1.0,
    eligibilityText = "INT 16 / Mana Barrier",
    actorText = "Heroes, human Soldiers, Magic-using AI"
}

feats.INT_MANA_BARRIER_3 = {
    featId = "INT_MANA_BARRIER_3",
    displayName = "Mystic Bastion",
    governingAbilities = {"int"},
    abilityRequirements = {int = 18},
    prerequisiteFeatIds = {"INT_MANA_BARRIER_2"},
    requiredCapabilityTags = {"magic_pool"},
    incompatibleFeatIds = {},
    allowedActorTypes = {"hero", "human_soldier", "ai"},
    requiredSubsystemTags = {},
    synergyTags = {"damage_diversion"},
    oneRank = true,
    featFamilyId = WizardRules.ManaBarrierFamilyId,
    rankIndex = 3,
    replacesLowerRank = true,
    effectHandlerId = "gate_b_feat_ownership",
    effectParams = {
        manaBarrierFeatDiversionFraction = 0.45,
        description = "Replaces lower Mana Barrier ranks and sets ManaBarrierFeatDiversionFraction = 0.45. HPToMagicDiversionFraction still adds the actor's WizardClassHPToMagicDiversionFraction, if any; a Level-20 Wizard therefore reaches the designed maximum 0.85 total diversion (0.40 class + 0.45 feat). It never increases Magic capacity above 100, never creates fractional HP prevention, never prevents non-damage death, and remains constrained by the actor's current available Magic."
    },
    directorBaseWeight = 1.0,
    eligibilityText = "INT 18 / Arcane Aegis",
    actorText = "Heroes, human Soldiers, Magic-using AI"
}

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

function WizardRules:ClassDiversionFraction(state)
    if not state or state.classId ~= "wizard" then return 0 end
    local level = math.Clamp(math.floor(tonumber(state.level) or 1), 1, 20)
    return 0.02 * level
end

function WizardRules:ManaBarrierFeatDiversionFraction(state)
    local best = 0
    for _, featId in ipairs(state and state.featIds or {}) do
        local definition = featDefinition(featId)
        local params = definition and definition.effectParams
        local value = tonumber(params and params.manaBarrierFeatDiversionFraction)
            or tonumber(self.ManaBarrierFractions[featId])
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
    derived.hpToMagicDiversionFraction = math.min(1,
        derived.wizardClassHpToMagicDiversionFraction
        + derived.manaBarrierFeatDiversionFraction
        + derived.wizardCapstoneDiversionBonus)
end

function WizardRules:ReplaceLowerFamilyRanks(state, definition)
    if not state or not definition or not definition.replacesLowerRank
        or not definition.featFamilyId
    then
        return false
    end

    local retained = {}
    local changed = false
    local selectedRank = tonumber(definition.rankIndex) or 0
    for _, featId in ipairs(state.featIds or {}) do
        local owned = featDefinition(featId)
        local sameFamily = owned and owned.featFamilyId == definition.featFamilyId
        local ownedRank = tonumber(owned and owned.rankIndex) or 0
        if sameFamily and featId ~= definition.featId and ownedRank < selectedRank then
            state.featStackCounts[featId] = nil
            changed = true
        else
            retained[#retained + 1] = featId
        end
    end
    if changed then state.featIds = retained end
    return changed
end

-- Gate C currently centralizes every derived statistic in one recomputation method.
-- Extend that authority once, at its own seam, rather than layering a second damage
-- hook: all consumers (sheet, HUD sync, and Gate D damage) then read one derived value.
local baseRecomputeProgressionState = CPS._RecomputeProgressionState
function CPS:_RecomputeProgressionState(state)
    baseRecomputeProgressionState(self, state)
    WizardRules:ApplyDerived(state)
end

-- The current ordinary-feat director predates authored ranked families. Enforce the
-- GDD prerequisite and replacement-family eligibility here so Arcane Aegis/Mystic
-- Bastion cannot appear as independent ranks and lower ranks cannot reappear later.
local baseFeatEligible = CPS._FeatEligible
function CPS:_FeatEligible(ps, state, definition)
    if not baseFeatEligible(self, ps, state, definition) then return false end

    for _, prerequisiteId in ipairs(definition.prerequisiteFeatIds or {}) do
        if not hasFeat(state, prerequisiteId) then return false end
    end

    if definition.featFamilyId then
        local candidateRank = tonumber(definition.rankIndex) or 0
        for _, ownedId in ipairs(state.featIds or {}) do
            local owned = featDefinition(ownedId)
            if owned and owned.featFamilyId == definition.featFamilyId
                and (tonumber(owned.rankIndex) or 0) >= candidateRank
            then
                return false
            end
        end
    end
    return true
end

local baseCommitFeat = CPS.CommitFeat
function CPS:CommitFeat(ply, featId, expectedEarnedAtLevel)
    local ok, err = baseCommitFeat(self, ply, featId, expectedEarnedAtLevel)
    if not ok then return ok, err end

    local definition = featDefinition(featId)
    if definition and definition.replacesLowerRank then
        local runManager = LOD.RunManager
        local ps = runManager and runManager:GetPlayerState(ply)
        local state = ps and ps.progressionState
        if state and WizardRules:ReplaceLowerFamilyRanks(state, definition) then
            self:_RecomputeProgressionState(state)
            self:_ApplyPlayerMaxHP(ply, state)
            self:SyncPlayer(ply)
        end
    end
    return true
end

local function newSyntheticState(classId, level, featIds, capstoneId)
    local state = CPS:NewProgressionState("wizard-validation", "hero", "hero")
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

    local rank2 = feats.INT_MANA_BARRIER_2
    local rank3 = feats.INT_MANA_BARRIER_3
    expect(rankOne.effectParams.manaBarrierFeatDiversionFraction == 0.15,
        "Mana Barrier fraction")
    expect(rank2 and rank2.effectParams.manaBarrierFeatDiversionFraction == 0.30
        and rank2.prerequisiteFeatIds[1] == "INT_MANA_BARRIER_1",
        "Arcane Aegis catalog")
    expect(rank3 and rank3.effectParams.manaBarrierFeatDiversionFraction == 0.45
        and rank3.prerequisiteFeatIds[1] == "INT_MANA_BARRIER_2",
        "Mystic Bastion catalog")

    local l1 = newSyntheticState("wizard", 1)
    local l20 = newSyntheticState("wizard", 20)
    local l10Barrier = newSyntheticState("wizard", 10, {"INT_MANA_BARRIER_1"})
    local nonWizardBarrier = newSyntheticState("rogue", 10, {"INT_MANA_BARRIER_1"})
    local l20Bastion = newSyntheticState("wizard", 20, {"INT_MANA_BARRIER_3"})
    local l20Aegis = newSyntheticState("wizard", 20, {"INT_MANA_BARRIER_3"},
        "WIZ_CAP_LIVING_AEGIS")

    expect(closeEnough(l1.derivedStats.wizardClassHpToMagicDiversionFraction, 0.02),
        "Wizard Level-1 innate diversion")
    expect(closeEnough(l20.derivedStats.wizardClassHpToMagicDiversionFraction, 0.40),
        "Wizard Level-20 innate diversion")
    expect(closeEnough(l10Barrier.derivedStats.hpToMagicDiversionFraction, 0.35),
        "Wizard + Mana Barrier additive diversion")
    expect(closeEnough(nonWizardBarrier.derivedStats.hpToMagicDiversionFraction, 0.15),
        "non-Wizard Mana Barrier diversion")
    expect(closeEnough(l20Bastion.derivedStats.hpToMagicDiversionFraction, 0.85),
        "Level-20 Wizard + Mystic Bastion designed maximum")
    expect(closeEnough(l20Aegis.derivedStats.hpToMagicDiversionFraction, 0.95)
        and closeEnough(l20Aegis.derivedStats.livingAegisHPPerMagic, 1.25),
        "Living Aegis additive diversion/exchange")

    local eligibilityState = newSyntheticState("wizard", 10)
    eligibilityState.featQualificationAbilities.int = 18
    local fakePS = {starterWeaponClass = "weapon_pistol"}
    expect(not CPS:_FeatEligible(fakePS, eligibilityState, rank2),
        "Arcane Aegis requires Mana Barrier")
    eligibilityState.featIds = {"INT_MANA_BARRIER_1"}
    expect(CPS:_FeatEligible(fakePS, eligibilityState, rank2),
        "Arcane Aegis eligible after Mana Barrier")
    eligibilityState.featIds = {"INT_MANA_BARRIER_2"}
    expect(CPS:_FeatEligible(fakePS, eligibilityState, rank3),
        "Mystic Bastion eligible after Arcane Aegis")

    local replacementState = {
        featIds = {"INT_MANA_BARRIER_1", "WIS_SURVEYOR", "INT_MANA_BARRIER_2"},
        featStackCounts = {INT_MANA_BARRIER_1 = 1, WIS_SURVEYOR = 1, INT_MANA_BARRIER_2 = 1}
    }
    self:ReplaceLowerFamilyRanks(replacementState, rank2)
    expect(not hasFeat(replacementState, "INT_MANA_BARRIER_1")
        and hasFeat(replacementState, "INT_MANA_BARRIER_2")
        and hasFeat(replacementState, "WIS_SURVEYOR"),
        "rank replacement preserves unrelated feats")

    local divertedHalfUp, spentHalfUp, remainingHalfUp =
        AbilityRules:ComputeMagicDiversion(17, 0.15, 100, 1)
    expect(closeEnough(divertedHalfUp, 3) and closeEnough(spentHalfUp, 3)
        and closeEnough(remainingHalfUp, 14),
        "half-up whole-HP diversion rounding")
    local divertedLimited, spentLimited, remainingLimited =
        AbilityRules:ComputeMagicDiversion(50, 0.85, 7.9, 1)
    expect(closeEnough(divertedLimited, 7) and closeEnough(spentLimited, 7)
        and closeEnough(remainingLimited, 43),
        "ordinary diversion floors available Magic")
    local divertedAegis, spentAegis, remainingAegis =
        AbilityRules:ComputeMagicDiversion(50, 0.95, 8, 1.25)
    expect(closeEnough(divertedAegis, 10) and closeEnough(spentAegis, 8)
        and closeEnough(remainingAegis, 40),
        "Living Aegis fractional-Magic exchange")

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
        magic = currentMagic,
        exchange = exchange,
        sampleDiverted = sampleDiverted,
        sampleSpent = sampleSpent,
        sampleHP = sampleHP
    }
end

concommand.Add("lod_rpg_wizard_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local target = IsValid(ply) and ply or player.GetAll()[1]
    local ok, errors, current = WizardRules:Validate(target)
    local line = string.format(
        "Wizard validation %s - class=%s level=%d innate=%.2f feat=%.2f capstone=%.2f total=%.2f magic=%.2f exchange=%.2f sample50(divert=%.2f magicSpent=%.2f hp=%.2f)",
        ok and "PASS" or "FAILED", tostring(current.classId), tonumber(current.level) or 0,
        current.innate, current.feat, current.capstone, current.total, current.magic,
        current.exchange, current.sampleDiverted, current.sampleSpent, current.sampleHP)
    print("[LOD:RPG-WIZARD] " .. line)
    for _, err in ipairs(errors) do
        ErrorNoHalt("[LOD:RPG-WIZARD] " .. err .. "\n")
    end
    if IsValid(ply) then ply:ChatPrint(line) end
end)

WizardRules.Ready = true
