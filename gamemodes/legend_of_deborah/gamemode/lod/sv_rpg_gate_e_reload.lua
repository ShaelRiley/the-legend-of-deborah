LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
if not Feats or not Effects or not Rules then return end

local FAMILY = "dex_reload_cadence"
local CHAIN = {"DEX_FAST_RELOAD", "DEX_FAST_RELOAD_2", "DEX_FAST_RELOAD_3"}
local RANK = {DEX_FAST_RELOAD = 1, DEX_FAST_RELOAD_2 = 2, DEX_FAST_RELOAD_3 = 3}
local MULTIPLIER = {[1] = 0.80, [2] = 0.60, [3] = 0.40}
local SOURCE_REVISION = "ANLCKQlypm6azjpK6CFPntqCTeHdrbGj3gqHEw0WMaFrgcSu7eSm7HUSUAFdcdeUI3ZMHjp4d1773GjsBEDij7b2tiy_3WSTap-s_Ky9YQ"
local EPSILON = 0.002
local ORDINARY_RELOADABLE = {
    weapon_pistol = true,
    weapon_shotgun = true,
    weapon_smg1 = true,
    weapon_ar2 = true,
    weapon_357 = true
}

Effects.ReloadConfig = {
    family = FAMILY,
    chain = CHAIN,
    rankById = RANK,
    multiplierByRank = MULTIPLIER,
    sourceRevision = SOURCE_REVISION,
    epsilon = EPSILON,
    ordinaryReloadable = ORDINARY_RELOADABLE
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
        requiredCapabilityTags = {"reloadable_firearm"},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {"reload", "firearm_cadence"},
        oneRank = true,
        effectHandlerId = "dex_reload_cadence",
        effectParams = {
            reloadTimeMultiplier = multiplier,
            description = string.format(
                "Sets ReloadTimeMultiplier = %.2f for ordinary reloadable weapons. It changes only genuine reload timing and never shortens SMG overheat recovery, AR2 targeting-laser/burst timing, Magic cooldowns, burst-internal spacing, or enemy telegraphs.",
                multiplier)
        },
        directorBaseWeight = 1.0,
        eligibilityText = string.format("DEX %d%s", dex,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Player-controlled heroes/human Soldiers; AI only when its authored weapon uses the shared reload authority"
    }
end

Feats.DEX_FAST_RELOAD = definition("DEX_FAST_RELOAD", "Quick Reload", 12, nil, 1, 0.80)
Feats.DEX_FAST_RELOAD_2 = definition("DEX_FAST_RELOAD_2", "Lightning Reload", 16,
    "DEX_FAST_RELOAD", 2, 0.60)
Feats.DEX_FAST_RELOAD_3 = definition("DEX_FAST_RELOAD_3", "Blink Reload", 18,
    "DEX_FAST_RELOAD_2", 3, 0.40)
Catalog.OrdinaryFeats = Feats
Catalog.GateEReloadSourceRevisionId = SOURCE_REVISION

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

function Effects:ReloadProfile(state)
    local rank = 0
    for id, value in pairs(RANK) do
        if value > rank and owns(state, id) then rank = value end
    end
    return {
        rank = rank,
        featId = rank > 0 and CHAIN[rank] or nil,
        reloadTimeMultiplier = MULTIPLIER[rank] or 1.0
    }
end

if not Effects.LODDexReloadApplyDerivedWrapped then
    Effects.LODDexReloadApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        derived.reloadTimeMultiplier = self:ReloadProfile(state).reloadTimeMultiplier
    end
end

function Rules:ReloadTimeMultiplier(actor)
    local derived = self:Derived(actor)
    return math.Clamp(tonumber(derived and derived.reloadTimeMultiplier) or 1, 0.40, 1.00)
end

-- Only a deadline newly extended by a confirmed reload may be compressed. The
-- pre-existing deadline is an absolute floor, so unrelated lockouts already in
-- force can never be shortened merely because Reload was pressed.
function Rules:ScaleReloadDeadline(now, priorDeadline, authoredDeadline, multiplier)
    now = tonumber(now) or 0
    priorDeadline = tonumber(priorDeadline) or now
    authoredDeadline = tonumber(authoredDeadline) or priorDeadline
    multiplier = math.Clamp(tonumber(multiplier) or 1, 0.40, 1.00)
    if authoredDeadline <= now + EPSILON or authoredDeadline <= priorDeadline + EPSILON then
        return authoredDeadline, false
    end
    local scaled = now + (authoredDeadline - now) * multiplier
    return math.max(priorDeadline, scaled), true
end

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_5_dex_reload_cadence"
return Effects
