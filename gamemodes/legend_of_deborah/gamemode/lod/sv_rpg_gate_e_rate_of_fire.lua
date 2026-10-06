LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
if not Feats or not Effects or not Rules then return end

local FAMILY = "dex_rate_of_fire"
local CHAIN = {"DEX_RATE_OF_FIRE_1"}
local RANK = {DEX_RATE_OF_FIRE_1 = 1}
local MULTIPLIER = {[1] = 1.55}
local MAX_MULTIPLIER = MULTIPLIER[1]
local SOURCE_REVISION = "ANLCKQmUlHpIXlUgqqjCRjeDq_RX5wfx7ceBkFwsdpnj5ZxQkzwWH2SxmdIiMnmRGrSLjqw2kDKEAZWGg9e2Cg8ohbKLMunfHqqeJwdRdA"
local EPSILON = 0.002
local ORDINARY_FIREARMS = {
    weapon_pistol = true,
    weapon_shotgun = true,
    weapon_smg1 = true,
    weapon_ar2 = true,
    weapon_357 = true
}
local ORDINARY_MELEE = {}

Effects.RateOfFireConfig = {
    family = FAMILY,
    chain = CHAIN,
    rankById = RANK,
    multiplierByRank = MULTIPLIER,
    maximumMultiplier = MAX_MULTIPLIER,
    sourceRevision = SOURCE_REVISION,
    epsilon = EPSILON,
    ordinaryFirearms = ORDINARY_FIREARMS,
    ordinaryMelee = ORDINARY_MELEE
}

local function definition(id, name, dex, prerequisite, rank, multiplier)
    return {
        featId = id,
        displayName = name,
        featFamilyId = FAMILY,
        rankIndex = rank,
        replacesLowerRank = rank > 1,
        repeatableFallback = false,
        governingAbilities = {"dex"},
        abilityRequirements = {dex = dex},
        prerequisiteFeatIds = prerequisite and {prerequisite} or {},
        requiredCapabilityTags = {},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {"attack_rate", "firearm_cadence"},
        oneRank = true,
        effectHandlerId = "dex_rate_of_fire",
        effectParams = {
            rateOfFireMultiplier = multiplier,
            description = string.format(
                "Sets RateOfFireMultiplier = %.2f total. Eligible firearm firing intervals, including AR2 burst spacing and completed-cycle cadence, are divided by this multiplier. Reloads, Magic cooldowns, SMG cooling/overheat lockout, targeting-laser duration, Magnum free-projectile burst spacing, and enemy telegraphs are unchanged.",
                multiplier)
        },
        directorBaseWeight = 1.0,
        eligibilityText = string.format("DEX %d%s", dex,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Heroes, human Soldiers, and AI whose equipped/authored ordinary firearm uses the shared attack-cadence authority"
    }
end

-- These assignments intentionally replace the stale Gate-B catalog placeholders.
-- The live GDD is authoritative: Hair Trigger begins at DEX 13, not DEX 12.
Feats.DEX_RATE_OF_FIRE_1 = definition("DEX_RATE_OF_FIRE_1", "Hair Trigger", 13, nil, 1, MULTIPLIER[1])
Feats.DEX_RATE_OF_FIRE_2 = nil
Feats.DEX_RATE_OF_FIRE_3 = nil
Catalog.OrdinaryFeats = Feats
Catalog.GateERateOfFireSourceRevisionId = SOURCE_REVISION

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

function Effects:RateOfFireProfile(state)
    local rank = 0
    for id, value in pairs(RANK) do
        if value > rank and owns(state, id) then rank = value end
    end
    return {
        rank = rank,
        featId = rank > 0 and CHAIN[rank] or nil,
        rateOfFireMultiplier = MULTIPLIER[rank] or 1.0
    }
end

if not Effects.LODDexRateOfFireApplyDerivedWrapped then
    Effects.LODDexRateOfFireApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:RateOfFireProfile(state)
        derived.rateOfFireMultiplier = profile.rateOfFireMultiplier
        derived.rateOfFireFeatId = profile.featId
    end
end

function Rules:RateOfFireMultiplier(actor)
    local derived = self:Derived(actor)
    return math.Clamp(tonumber(derived and derived.rateOfFireMultiplier) or 1, 1.00, MAX_MULTIPLIER)
end

-- This helper is intentionally expressed in deadlines so stock Source weapons can
-- join the same authority without rewriting their SWEPs. Only an interval authored
-- by a confirmed attack is divided. A deadline that already existed before the
-- attack remains an absolute floor and can never be shortened by this feat family.
function Rules:ScaleAttackDeadline(now, priorDeadline, authoredDeadline, multiplier)
    now = tonumber(now) or 0
    priorDeadline = tonumber(priorDeadline) or now
    authoredDeadline = tonumber(authoredDeadline) or priorDeadline
    multiplier = math.Clamp(tonumber(multiplier) or 1, 1.00, MAX_MULTIPLIER)
    if multiplier <= 1.00 + EPSILON
        or authoredDeadline <= now + EPSILON
        or authoredDeadline <= priorDeadline + EPSILON
    then
        return authoredDeadline, false
    end
    local scaled = now + (authoredDeadline - now) / multiplier
    return math.max(priorDeadline, scaled), true
end

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_6_dex_rate_of_fire"
return Effects
