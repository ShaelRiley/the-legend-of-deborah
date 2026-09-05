LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
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
    multiFireBurstTag = "multiFireBurst",
    ar2AuthoredBurstCount = 3,
    magnumAuthoredBurstCounts = {chamber5 = 2, chamber6 = 3}
}
Effects.BurstSizeStats = Effects.BurstSizeStats or {
    completedBursts = 0,
    abortedBursts = 0,
    lastResult = nil
}
Effects.BurstSizeStats.completedBursts = Effects.BurstSizeStats.completedBursts or 0
Effects.BurstSizeStats.abortedBursts = Effects.BurstSizeStats.abortedBursts or 0

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
        requiredCapabilityTags = {"multi_fire_burst"},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {"burst_size", "multiFireBurst", "firearm_burst", "ar2", "magnum"},
        oneRank = true,
        effectHandlerId = "dex_burst_size",
        effectParams = {
            burstBonusRounds = bonus,
            -- Compatibility alias for already-built presentation/derived consumers.
            burstSizeBonus = bonus,
            description = string.format(
                "Sets BurstBonusRounds = +%d total for attacks already authored as multiFireBurst. Added projectiles inherit the weapon's existing burst spacing, damage, and ammunition semantics; they never create extra ammo costs or turn single-fire attacks, Shotgun pellets, penetration, exploding dice, or unrelated extra-projectile procs into bursts.",
                bonus)
        },
        directorBaseWeight = 1.0,
        eligibilityText = string.format("DEX %d%s", dex,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Heroes, human Soldiers, and AI actors with an authored weapon attack tagged multiFireBurst"
    }
end

-- Gate-B's capability seam pre-dates the live GDD correction and recognized only
-- AR2 as multi-fire. The exact GDD now names both ordinary AR2 bursts and authored
-- Magnum chamber-5/chamber-6 bursts. Preserve every other capability rule while
-- teaching the shared eligibility authority that either starter family qualifies.
if Progression and not Progression.LODDexBurstSizeCapabilityWrapped then
    Progression.LODDexBurstSizeCapabilityWrapped = true
    local baseHasCapability = Progression._HasCapability
    function Progression:_HasCapability(ps, state, tag)
        if tag == "multi_fire_burst" then
            local class = ps and ps.starterWeaponClass or nil
            if class == "weapon_357" then return true end
            return baseHasCapability(self, ps, state, tag)
        end
        return baseHasCapability(self, ps, state, tag)
    end
end

-- Replace the Gate-B ownership placeholder with the exact live-GDD family.
Feats.DEX_BURSTER_1 = definition("DEX_BURSTER_1", "Extra Round", 13, nil, 1, 1)
Feats.DEX_BURSTER_2 = definition("DEX_BURSTER_2", "Extended Volley", 15,
    "DEX_BURSTER_1", 2, 2)
Feats.DEX_BURSTER_3 = definition("DEX_BURSTER_3", "Full Barrage", 17,
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
    local bonus = BONUS[rank] or 0
    return {
        rank = rank,
        featId = rank > 0 and CHAIN[rank] or nil,
        burstBonusRounds = bonus,
        burstSizeBonus = bonus
    }
end

if not Effects.LODDexBurstSizeApplyDerivedWrapped then
    Effects.LODDexBurstSizeApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:BurstSizeProfile(state)
        derived.burstBonusRounds = profile.burstBonusRounds
        derived.burstSizeBonus = profile.burstBonusRounds
        derived.burstSizeFeatId = profile.featId
    end
end

function Rules:BurstBonusRounds(actor)
    local derived = self:Derived(actor)
    local value = derived and (derived.burstBonusRounds or derived.burstSizeBonus) or 0
    return math.Clamp(math.floor((tonumber(value) or 0) + 0.5), 0, 3)
end

-- Compatibility alias for older callers. The semantic authority is BurstBonusRounds.
function Rules:BurstSizeBonus(actor)
    return self:BurstBonusRounds(actor)
end

-- Shared pure authority for an event that is already authored as multiFireBurst.
-- Ammo is intentionally absent from this function: projectile count never infers
-- or changes a weapon's authored ammunition cost.
function Rules:ResolveBurstCount(authoredBurstCount, burstBonusRounds)
    authoredBurstCount = math.max(1, math.floor(tonumber(authoredBurstCount) or 1))
    burstBonusRounds = math.Clamp(math.floor(tonumber(burstBonusRounds) or 0), 0, 3)
    return math.max(1, authoredBurstCount + burstBonusRounds)
end

-- Compatibility alias retained for the Batch-7 call surface, now with corrected
-- two-argument semantics. Any legacy third argument is deliberately ignored by Lua.
function Rules:ResolveBurstSize(authoredBurstCount, burstBonusRounds)
    return self:ResolveBurstCount(authoredBurstCount, burstBonusRounds)
end

function Effects:RecordBurstSizeResult(ply, weaponClass, roundsResolved,
    authoredBurstCount, finalBurstCount, bonus)
    roundsResolved = math.max(0, math.floor(tonumber(roundsResolved) or 0))
    authoredBurstCount = math.max(1, math.floor(tonumber(authoredBurstCount) or 1))
    finalBurstCount = math.max(authoredBurstCount,
        math.floor(tonumber(finalBurstCount) or authoredBurstCount))
    bonus = math.Clamp(math.floor(tonumber(bonus) or 0), 0, 3)
    local complete = roundsResolved >= finalBurstCount
    local result = {
        weaponClass = tostring(weaponClass or "unknown"),
        roundsResolved = roundsResolved,
        authoredBurstCount = authoredBurstCount,
        finalBurstCount = finalBurstCount,
        burstBonusRounds = bonus,
        complete = complete
    }
    self.BurstSizeStats.lastResult = result
    if complete then
        self.BurstSizeStats.completedBursts = (self.BurstSizeStats.completedBursts or 0) + 1
    else
        self.BurstSizeStats.abortedBursts = (self.BurstSizeStats.abortedBursts or 0) + 1
    end
    if LOD.RPGTestLog and isfunction(LOD.RPGTestLog.Write) then
        LOD.RPGTestLog:Write("BURST_SIZE_RESULT", {
            player = IsValid(ply) and tostring(ply) or "unknown",
            weapon = result.weaponClass,
            rounds = roundsResolved,
            authored = authoredBurstCount,
            final = finalBurstCount,
            bonus = bonus,
            complete = complete and 1 or 0
        })
    end
    return result
end

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_7_dex_burst_size"
return Effects
