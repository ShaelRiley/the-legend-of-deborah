LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

-- Checkpoint D: small, shared feat consumers whose exact live-GDD rules are
-- already expressed by existing combat, push and presentation authorities.
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "core feat catalog requires IdentityCatalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats,
    "core feat catalog requires ordinary feat registry")
local Effects = assert(RPG.FeatEffectSystem, "core feat catalog requires effect system")

Catalog.OrdinaryFeats = Feats

local function owns(state, featId)
    for _, owned in ipairs(state and state.featIds or {}) do
        if owned == featId then return true end
    end
    return false
end

local function register(definition)
    assert(Feats[definition.featId] == nil,
        "duplicate canonical feat " .. tostring(definition.featId))
    Feats[definition.featId] = definition
end

register({
    featId = "STR_STEAMROLLER", displayName = "Steamroller",
    featFamilyId = "str_steamroller", rankIndex = 1, replacesLowerRank = false,
    governingAbilities = {"str"}, abilityRequirements = {str = 17},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {"magic_push"},
    incompatibleFeatIds = {}, allowedActorTypes = {"hero", "human_soldier", "ai"},
    requiredSubsystemTags = {"pushback"}, synergyTags = {"physical_push", "magic_push"},
    oneRank = true, repeatableFallback = false, effectHandlerId = "steamroller_push_save",
    effectParams = {description = "Whenever a push-tagged event credited to this actor reaches the shared STR push save, a successful PushSave applies 50% of SizeAdjustedPushDistance instead of the ordinary 0%; a failed PushSave still applies 100%. Steamroller does not create push where none exists, does not alter PushDC or PushSave, does not grant extra saves, and never bypasses PushImmune. Any resulting nonzero displacement continues through ordinary defender-side post-save multipliers, LOD.Pushback collision handling, and wall-slam/wall-crush rules.", successfulSaveFraction = 0.50}, directorBaseWeight = 1.0,
    eligibilityText = "STR 17 / requires an authored push-capable attack or effect",
    actorText = "Heroes, human Soldiers, and AI with an authored push-capable attack or effect"
})

-- Glow Up deliberately has no generic "charisma damage" fallback.  A source
-- must register itself below and use AddChaModDerivedDamage while constructing
-- its own damage contract; that makes the draft gate track real, authored
-- CHA_MOD damage instead of the presence of any CHA-related feat.
register({
    featId = "CON_GLOW_UP", displayName = "Glow Up",
    featFamilyId = "con_glow_up", rankIndex = 1, replacesLowerRank = false,
    governingAbilities = {"con"}, abilityRequirements = {con = 17},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {"cha_mod_damage"},
    incompatibleFeatIds = {}, allowedActorTypes = {"hero", "human_soldier", "ai"},
    requiredSubsystemTags = {"damage_contract"},
    synergyTags = {"charisma", "damage", "flat_damage"}, oneRank = true,
    repeatableFallback = false, effectHandlerId = "glow_up_cha_damage_rider",
    effectParams = {description = "Whenever an owned rule contributes max(0, CHA_MOD) as damage to a resolved damage event, adds max(0, CON_MOD) to that same event once. Requires a currently usable explicit CHA_MOD-derived damage source."},
    directorBaseWeight = 1.0,
    eligibilityText = "CON 17 / requires a usable explicit CHA_MOD-derived damage source",
    actorText = "Heroes, human Soldiers, and AI with an authored CHA_MOD-derived damage source"
})

register({
    featId = "DEX_SHRINK", displayName = "Little Guy",
    featFamilyId = "dex_shrink", rankIndex = 1, replacesLowerRank = false,
    governingAbilities = {"dex"}, abilityRequirements = {dex = 15},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {"CON_BIG_GUY"},
    allowedActorTypes = {"hero", "human_soldier"}, requiredSubsystemTags = {"movement"},
    synergyTags = {"body_size", "presentation", "targeting"}, oneRank = true,
    repeatableFallback = false, effectHandlerId = "little_guy_body_scale",
    effectParams = {playerTargetScale = .70,
        description = "Sets PlayerTargetScale to 0.70 while preserving the ordinary authoritative collision hull, stair legality, USE reach, weapon traces, and progression interactions."},
    directorBaseWeight = 1.0, eligibilityText = "DEX 15",
    actorText = "Player-controlled Heroes and human Soldiers only"
})

register({
    featId = "CON_BIG_GUY", displayName = "Big Guy",
    featFamilyId = "con_big_guy", rankIndex = 1, replacesLowerRank = false,
    governingAbilities = {"con", "str"}, abilityRequirements = {con = 15, str = 13},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {"DEX_SHRINK"},
    allowedActorTypes = {"hero", "human_soldier"}, requiredSubsystemTags = {},
    synergyTags = {"melee_reach", "physical_push", "body_size"}, oneRank = true,
    repeatableFallback = false, effectHandlerId = "big_guy_body_scale",
    effectParams = {description = "Sets PlayerTargetScale to 1.30. Third-person/world presentation and combat hurt volume become 130% size while the authoritative movement/collision hull remains unchanged. Melee reach is multiplied by 1.15 and actor-authored physical push dealt is multiplied by 1.20. The larger hurt volume is the balancing drawback. Big Guy and Little Guy are mutually exclusive.", playerTargetScale = 1.30, meleeReachMultiplier = 1.15,
        physicalPushMultiplier = 1.20}, directorBaseWeight = 1.0,
    eligibilityText = "CON 15 and STR 13", actorText = "Player-controlled Heroes and human Soldiers"
})

register({
    featId = "CON_NOT_YET", displayName = "Not Yet",
    featFamilyId = "con_not_yet", rankIndex = 1, replacesLowerRank = false,
    governingAbilities = {"con"}, abilityRequirements = {con = 15},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
    allowedActorTypes = {"hero"}, requiredSubsystemTags = {},
    synergyTags = {"survival", "personal_lives"}, oneRank = true,
    repeatableFallback = false, effectHandlerId = "personal_life_cap",
    effectParams = {description = "Adds +1 to the personal-life cap (normally 4 to 5). Acquiring Not Yet raises the maximum only; it does not award a life. Extra-life pickups fill the current personal cap before overflow can revive a teammate.", personalLifeCapBonus = 1}, directorBaseWeight = 1.0,
    eligibilityText = "CON 15", actorText = "Cooperative Heroes with personal lives"
})

if not Effects.LODCheckpointDCoreFeatDerivedWrapped then
    Effects.LODCheckpointDCoreFeatDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local steamroller = owns(state, "STR_STEAMROLLER")
        local littleGuy = owns(state, "DEX_SHRINK")
        local bigGuy = owns(state, "CON_BIG_GUY")
        local notYet = owns(state, "CON_NOT_YET")
        derived.steamrollerSuccessfulSaveFraction = steamroller and 0.50 or 0
        derived.littleGuyEnabled = littleGuy
        derived.bigGuyEnabled = bigGuy
        derived.playerTargetScale = bigGuy and 1.30 or (littleGuy and .70 or 1)
        derived.meleeReachMultiplier = (tonumber(derived.meleeReachMultiplier) or 1)
            * (bigGuy and 1.15 or 1)
        derived.bigGuyPhysicalPushMultiplier = bigGuy and 1.20 or 1
        derived.personalLifeCapBonus = (tonumber(derived.personalLifeCapBonus) or 0) + (notYet and 1 or 0)
    end
end

local Rules = assert(LOD.RPGAbilityRules, "core feat runtime requires AbilityRules")

Effects.ChaModDamageSources = Effects.ChaModDamageSources or {}

function Effects:RegisterChaModDamageSource(sourceId, usable)
    assert(type(sourceId) == "string" and sourceId ~= "", "CHA damage source id required")
    self.ChaModDamageSources[sourceId] = usable or true
end

function Effects:HasUsableChaModDamage(state)
    for sourceId, usable in pairs(self.ChaModDamageSources or {}) do
        local active = type(usable) == "function" and usable(state, sourceId) or usable == true
        if active then return true end
    end
    return false
end

-- Authored CHA damage sources call this while preparing their existing damage
-- contract. Both the source's CHA bonus and Glow Up are therefore in the same
-- ordinary damage event, receive normal downstream resolution, and cannot
-- duplicate from multi-source contracts.
function Rules:AddChaModDerivedDamage(contract, attacker, sourceId)
    if type(contract) ~= "table" or not IsValid(attacker) then return 0, 0 end
    local derived = self:Derived(attacker) or {}
    local chaBonus = math.max(0, math.floor(tonumber(derived.chaMod) or 0))
    local conBonus = 0
    contract.bonus = math.max(0, tonumber(contract.bonus) or 0) + chaBonus
    contract.chaModDamageSources = contract.chaModDamageSources or {}
    contract.chaModDamageSources[sourceId or "authored"] = true
    local state = self:ProgressionState(attacker)
    if owns(state, "CON_GLOW_UP") and not contract.LODGlowUpApplied then
        conBonus = math.max(0, math.floor(tonumber(derived.conMod) or 0))
        contract.bonus = contract.bonus + conBonus
        contract.LODGlowUpApplied = true
    end
    return chaBonus, conBonus
end

local Progression = assert(LOD.CharacterProgressionSystem, "core feat runtime requires progression")
if not Progression.LODCheckpointDGlowUpCapabilityWrapped then
    Progression.LODCheckpointDGlowUpCapabilityWrapped = true
    local baseHasCapability = Progression._HasCapability
    function Progression:_HasCapability(ps, state, tag)
        if tag == "cha_mod_damage" then return Effects:HasUsableChaModDamage(state) end
        return baseHasCapability(self, ps, state, tag)
    end
end

-- A cap modifier never grants stock. Other additive sources may contribute to
-- personalLifeCapBonus before/after this feat's derived pass.
function Rules:ResolvePersonalLifeCap(baseCap, derived)
    return math.max(0, math.floor((tonumber(baseCap) or 4)
        + (tonumber(derived and derived.personalLifeCapBonus) or 0)))
end

-- Ordinary body presentation remains available independently of equipment.
function Rules:PlayerTargetScale(actor)
    local derived = self:Derived(actor)
    return math.Clamp(tonumber(derived and derived.playerTargetScale) or 1, .33, 3)
end
function Rules:PushSizeScale(actor) return self:PlayerTargetScale(actor) end

local baseSync = Rules.SyncPlayer
function Rules:SyncPlayer(ply)
    baseSync(self, ply)
    if not IsValid(ply) then return end
    local run=LOD.RunManager
    if run and run.PersonalLifeCap then ply:SetNW2Int("LOD_PersonalLifeCap",run:PersonalLifeCap(ply)) end
    local derived = self:Derived(ply) or {}
    ply:SetNW2Float("LOD_HasteMovementMultiplier",derived.hasteMovementMultiplier or 1)
    ply:SetNW2Float("LOD_SpringHeelAirMultiplier",derived.springHeelAirMovementMultiplier or 1)
    ply:SetNW2Float("LOD_StrafeSpeedMultiplier",derived.strafeSpeedMultiplier or 1)
    ply:SetNW2Float("LOD_BackpedalMovementMultiplier",derived.backpedalMovementMultiplier or 1)
    if self.ApplySizeShifterScale then self:ApplySizeShifterScale(ply); return end
    local scale = tonumber(derived and derived.playerTargetScale) or 1
    ply:SetNW2Float("LOD_PlayerTargetScale", scale)
    ply:SetModelScale(scale, 0)
end

function Rules:ValidateCheckpointDCoreFeats()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for _, id in ipairs({"STR_STEAMROLLER", "DEX_SHRINK", "CON_BIG_GUY", "CON_NOT_YET", "CON_GLOW_UP"}) do
        local definition = Feats[id]
        expect(definition and definition.effectHandlerId, "core feat definition " .. id)
    end
    local derived = {}
    Effects:ApplyDerived({featIds = {"STR_STEAMROLLER", "CON_BIG_GUY", "CON_NOT_YET"}}, derived)
    expect(derived.steamrollerSuccessfulSaveFraction == 0.50, "Steamroller save fraction")
    expect(derived.playerTargetScale == 1.30 and derived.meleeReachMultiplier >= 1.15,
        "Big Guy derived body/reach")
    expect(derived.bigGuyPhysicalPushMultiplier == 1.20, "Big Guy physical push")
    expect(derived.personalLifeCapBonus == 1, "Not Yet additive personal-life cap")
    expect(self:ResolvePersonalLifeCap(4, derived) == 5, "Not Yet 4 to 5")
    expect(self:ResolvePersonalLifeCap(4, {personalLifeCapBonus=3}) == 7, "additional additive life-cap source")
    local little = {}; Effects:ApplyDerived({featIds = {"DEX_SHRINK"}}, little)
    expect(little.littleGuyEnabled and little.playerTargetScale == .70, "Little Guy derived presentation scale")
    expect(not Effects:HasUsableChaModDamage({featIds = {}}), "Glow Up no invented CHA damage source")
    return #errors == 0, errors
end

