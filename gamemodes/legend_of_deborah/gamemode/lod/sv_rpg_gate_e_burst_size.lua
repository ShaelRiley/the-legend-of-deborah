LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
if not Feats or not Effects or not Rules then return end

local FAMILY = "dex_burst_size"
local CHAIN = {"DEX_BURSTER_1", "DEX_BURSTER_2", "DEX_BURSTER_3"}
local RANK = {DEX_BURSTER_1 = 1, DEX_BURSTER_2 = 2, DEX_BURSTER_3 = 3}
local BONUS = {[1] = 1, [2] = 2, [3] = 3}
local SOURCE_REVISION = "ANLCKQlqd7CuK8mqO8bD6YLSczpkCCbzvF_CuSWwh7tZahxeualxoHhhteJPwzEODy4h7eRO3dVCIqKnCRDqh7Khd3tSntD1CNYK-SRLVg"

Effects.BurstSizeConfig = {
    family = FAMILY,
    chain = CHAIN,
    rankById = RANK,
    bonusByRank = BONUS,
    sourceRevision = SOURCE_REVISION,
    ar2BaseShots = 3
}
Effects.BurstSizeStats = Effects.BurstSizeStats or {
    completedBursts = 0,
    truncatedBursts = 0,
    lastResult = nil
}

local function definition(id, name, dex, prerequisite, rank, bonus)
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
        synergyTags = {"burst_size", "firearm_burst", "ar2"},
        oneRank = true,
        effectHandlerId = "dex_burst_size",
        effectParams = {
            burstSizeBonus = bonus,
            description = string.format(
                "Sets BurstSizeBonus = +%d total for authored multi-shot burst attacks. Added projectiles consume normal ammo and preserve authored between-shot timing; single-shot attacks, shotgun pellet count, reloads, AR2 targeting laser, SMG overheat, Magic cooldowns, telegraphs, and unrelated timers are unchanged.",
                bonus)
        },
        directorBaseWeight = 1.0,
        eligibilityText = string.format("DEX %d%s", dex,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Heroes, human Soldiers, and AI only when the authored attack uses the shared burst-size authority"
    }
end

-- Replace the Gate-B ownership placeholder with the exact live-GDD family.
Feats.DEX_BURSTER_1 = definition("DEX_BURSTER_1", "Extra Round", 12, nil, 1, 1)
Feats.DEX_BURSTER_2 = definition("DEX_BURSTER_2", "Extended Volley", 15,
    "DEX_BURSTER_1", 2, 2)
Feats.DEX_BURSTER_3 = definition("DEX_BURSTER_3", "Full Barrage", 18,
    "DEX_BURSTER_2", 3, 3)
Catalog.OrdinaryFeats = Feats
Catalog.GateEBurstSizeSourceRevisionId = SOURCE_REVISION

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

function Effects:BurstSizeProfile(state)
    local rank = 0
    for id, value in pairs(RANK) do
        if value > rank and owns(state, id) then rank = value end
    end
    return {
        rank = rank,
        featId = rank > 0 and CHAIN[rank] or nil,
        burstSizeBonus = BONUS[rank] or 0
    }
end

if not Effects.LODDexBurstSizeApplyDerivedWrapped then
    Effects.LODDexBurstSizeApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:BurstSizeProfile(state)
        derived.burstSizeBonus = profile.burstSizeBonus
        derived.burstSizeFeatId = profile.featId
    end
end

function Rules:BurstSizeBonus(actor)
    local derived = self:Derived(actor)
    return math.Clamp(math.floor((tonumber(derived and derived.burstSizeBonus) or 0) + 0.5), 0, 3)
end

-- Shared pure authority for authored burst size. `availableAmmo` truncates the
-- legal transaction rather than cancelling it, exactly as the GDD specifies.
function Rules:ResolveBurstSize(baseShots, burstSizeBonus, availableAmmo)
    baseShots = math.max(1, math.floor(tonumber(baseShots) or 1))
    burstSizeBonus = math.Clamp(math.floor(tonumber(burstSizeBonus) or 0), 0, 3)
    local desired = baseShots + burstSizeBonus
    if availableAmmo == nil then return desired, desired end
    local available = math.max(0, math.floor(tonumber(availableAmmo) or 0))
    return math.min(desired, available), desired
end

function Effects:RecordBurstSizeResult(ply, roundsFired, targetShots, desiredShots, bonus)
    roundsFired = math.max(0, math.floor(tonumber(roundsFired) or 0))
    targetShots = math.max(0, math.floor(tonumber(targetShots) or 0))
    desiredShots = math.max(targetShots, math.floor(tonumber(desiredShots) or targetShots))
    bonus = math.Clamp(math.floor(tonumber(bonus) or 0), 0, 3)
    local complete = targetShots > 0 and roundsFired >= targetShots
    local truncated = targetShots < desiredShots
    local result = {
        roundsFired = roundsFired,
        targetShots = targetShots,
        desiredShots = desiredShots,
        burstSizeBonus = bonus,
        complete = complete,
        truncated = truncated
    }
    self.BurstSizeStats.lastResult = result
    if complete then
        self.BurstSizeStats.completedBursts = (self.BurstSizeStats.completedBursts or 0) + 1
        if truncated then
            self.BurstSizeStats.truncatedBursts = (self.BurstSizeStats.truncatedBursts or 0) + 1
        end
    end
    if LOD.RPGTestLog and isfunction(LOD.RPGTestLog.Write) then
        LOD.RPGTestLog:Write("BURST_SIZE_RESULT", {
            player = IsValid(ply) and tostring(ply) or "unknown",
            rounds = roundsFired,
            target = targetShots,
            desired = desiredShots,
            bonus = bonus,
            complete = complete and 1 or 0,
            truncated = truncated and 1 or 0
        })
    end
    return result
end

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_7_dex_burst_size"
return Effects
