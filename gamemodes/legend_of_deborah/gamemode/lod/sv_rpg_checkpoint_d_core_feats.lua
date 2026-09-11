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
    effectParams = {successfulSaveFraction = 0.50}, directorBaseWeight = 1.0,
    eligibilityText = "STR 17 / requires an authored push-capable attack or effect",
    actorText = "Heroes, human Soldiers, and AI with an authored push-capable attack or effect"
})

register({
    featId = "CON_BIG_GUY", displayName = "Big Guy",
    featFamilyId = "con_big_guy", rankIndex = 1, replacesLowerRank = false,
    governingAbilities = {"con", "str"}, abilityRequirements = {con = 15, str = 13},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {"DEX_SHRINK"},
    allowedActorTypes = {"hero", "human_soldier"}, requiredSubsystemTags = {},
    synergyTags = {"melee_reach", "physical_push", "body_size"}, oneRank = true,
    repeatableFallback = false, effectHandlerId = "big_guy_body_scale",
    effectParams = {playerTargetScale = 1.30, meleeReachMultiplier = 1.15,
        physicalPushMultiplier = 1.20}, directorBaseWeight = 1.0,
    eligibilityText = "CON 15 and STR 13", actorText = "Player-controlled Heroes and human Soldiers"
})

register({
    featId = "CON_NOT_YET", displayName = "Not Yet",
    featFamilyId = "con_not_yet", rankIndex = 1, replacesLowerRank = false,
    governingAbilities = {"con"}, abilityRequirements = {con = 15},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
    allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {},
    synergyTags = {"survival", "damage_immunity"}, oneRank = true,
    repeatableFallback = false, effectHandlerId = "not_yet_death_prevention",
    effectParams = {remainingHP = 1, immunitySeconds = 0.50}, directorBaseWeight = 1.0,
    eligibilityText = "CON 15", actorText = "Heroes, human Soldiers, and AI"
})

if not Effects.LODCheckpointDCoreFeatDerivedWrapped then
    Effects.LODCheckpointDCoreFeatDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local steamroller = owns(state, "STR_STEAMROLLER")
        local bigGuy = owns(state, "CON_BIG_GUY")
        local notYet = owns(state, "CON_NOT_YET")
        derived.steamrollerSuccessfulSaveFraction = steamroller and 0.50 or 0
        derived.bigGuyEnabled = bigGuy
        derived.playerTargetScale = bigGuy and 1.30 or 1
        derived.meleeReachMultiplier = (tonumber(derived.meleeReachMultiplier) or 1)
            * (bigGuy and 1.15 or 1)
        derived.bigGuyPhysicalPushMultiplier = bigGuy and 1.20 or 1
        derived.notYetEnabled = notYet
        derived.notYetRemainingHP = notYet and 1 or 0
        derived.notYetImmunitySeconds = notYet and 0.50 or 0
    end
end

local Rules = assert(LOD.RPGAbilityRules, "core feat runtime requires AbilityRules")

function Rules:ApplyNotYetDefense(target, dmginfo)
    if not IsValid(target) or not dmginfo then return false end
    local derived = self:Derived(target)
    if not derived or derived.notYetEnabled ~= true then return false end
    local state = self:ProgressionState(target)
    if not state then return false end
    local run = LOD.RunManager and LOD.RunManager.State
    local dungeonLevel = math.max(1, math.floor(tonumber(run and run.Level) or 1))
    if state.notYetConsumedDungeonLevel == dungeonLevel then
        if CurTime() < (tonumber(target.LODRPGNotYetImmuneUntil) or 0) then
            dmginfo:SetDamage(0)
            return true
        end
        return false
    end
    local current = math.max(0, tonumber(target:Health()) or 0)
    local incoming = math.max(0, tonumber(dmginfo:GetDamage()) or 0)
    if current <= 1 or incoming < current then return false end
    state.notYetConsumedDungeonLevel = dungeonLevel
    target.LODRPGNotYetImmuneUntil = CurTime() + 0.50
    dmginfo:SetDamage(math.max(0, current - 1))
    target.LODRPGNotYetTriggeredAt = CurTime()
    return true
end

local baseSync = Rules.SyncPlayer
function Rules:SyncPlayer(ply)
    baseSync(ply)
    if not IsValid(ply) then return end
    local derived = self:Derived(ply)
    local scale = tonumber(derived and derived.playerTargetScale) or 1
    ply:SetNW2Float("LOD_PlayerTargetScale", scale)
    ply:SetModelScale(scale, 0)
end

function Rules:ValidateCheckpointDCoreFeats()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for _, id in ipairs({"STR_STEAMROLLER", "CON_BIG_GUY", "CON_NOT_YET"}) do
        local definition = Feats[id]
        expect(definition and definition.effectHandlerId, "core feat definition " .. id)
    end
    local derived = {}
    Effects:ApplyDerived({featIds = {"STR_STEAMROLLER", "CON_BIG_GUY", "CON_NOT_YET"}}, derived)
    expect(derived.steamrollerSuccessfulSaveFraction == 0.50, "Steamroller save fraction")
    expect(derived.playerTargetScale == 1.30 and derived.meleeReachMultiplier >= 1.15,
        "Big Guy derived body/reach")
    expect(derived.bigGuyPhysicalPushMultiplier == 1.20, "Big Guy physical push")
    expect(derived.notYetEnabled and derived.notYetImmunitySeconds == 0.50, "Not Yet derived")
    return #errors == 0, errors
end
