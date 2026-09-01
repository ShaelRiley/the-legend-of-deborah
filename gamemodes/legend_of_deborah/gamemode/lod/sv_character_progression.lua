LOD = LOD or {}
LOD.CharacterProgressionSystem = LOD.CharacterProgressionSystem or {}

local CharacterProgressionSystem = LOD.CharacterProgressionSystem
local RPG = LOD.RPG

local function emptyArray()
    return {}
end

local function emptyMap()
    return {}
end

function CharacterProgressionSystem:NewProgressionState(actorId, archetypeId, actorType)
    actorType = actorType or "hero"
    local isHero = actorType == "hero"

    return {
        actorId = actorId,
        archetypeId = archetypeId,
        characterIdentityPackage = nil,
        level = RPG.Constants.MinLevel,
        xp = isHero and 0 or nil,
        classId = nil,
        primaryAbility = nil,
        secondaryAbilities = emptyArray(),
        baseAbilities = RPG.NewAbilityBlock(0),
        growthAbilities = RPG.NewAbilityBlock(0),
        identityAbilityDelta = RPG.NewAbilityBlock(0),
        equipmentAbilityDelta = RPG.NewAbilityBlock(0),
        featAbilityDelta = RPG.NewAbilityBlock(0),
        temporaryAbilityDelta = RPG.NewAbilityBlock(0),
        effectiveAbilities = RPG.NewAbilityBlock(0),
        startingHP = nil,
        progressionHitDieSides = nil,
        hitDieRollsByLevel = emptyMap(),
        featSlotsGranted = 0,
        featIds = emptyArray(),
        featStackCounts = emptyMap(),
        pendingFeatSlots = emptyArray(),
        classCapstoneFeatId = nil,
        pendingClassCapstoneDraft = nil,
        dungeonEntryLevel = nil,
        replacementXpEarnedThisDungeon = 0,
        capabilityTags = emptyArray()
    }
end

function CharacterProgressionSystem:ClampLevel(level)
    return math.Clamp(math.floor(tonumber(level) or RPG.Constants.MinLevel), RPG.Constants.MinLevel, RPG.Constants.MaxLevel)
end

function CharacterProgressionSystem:AbilityModifier(score)
    score = math.Clamp(tonumber(score) or 10, RPG.Constants.AbilityMin, RPG.Constants.AbilityMax)
    return math.floor((score - 10) / 2)
end

local function derive(seed, label)
    return LOD.Seeds.Derive(seed, "rpg:" .. tostring(label))
end

function CharacterProgressionSystem:HeroIdentitySeed(rosterSeed, persistentHeroIdentity)
    return derive(rosterSeed, "hero_identity:" .. tostring(persistentHeroIdentity) .. ":character_identity")
end

function CharacterProgressionSystem:HeroGrowthProfileSeed(campaignSeed, persistentHeroIdentity, classId)
    return derive(campaignSeed, "hero_growth:" .. tostring(persistentHeroIdentity) .. ":" .. tostring(classId) .. ":growth_profile")
end

function CharacterProgressionSystem:HumanSoldierGrowthProfileSeed(campaignSeed, persistentConnectionIdentity, classId)
    return derive(campaignSeed, "soldier_growth:" .. tostring(persistentConnectionIdentity) .. ":" .. tostring(classId) .. ":soldier_growth_profile")
end

function CharacterProgressionSystem:AIProgressionSeed(levelSeed, encounterOrWandererIdentity, spawnOrdinal, archetypeId)
    local label = table.concat({
        "ai_progression",
        tostring(encounterOrWandererIdentity),
        tostring(spawnOrdinal),
        tostring(archetypeId),
        "progression"
    }, ":")
    return derive(levelSeed, label)
end

-- Gate A intentionally owns no gameplay hooks. RunManager remains the player/campaign
-- lifecycle authority; later gates attach this state to its existing per-identity ledger.
CharacterProgressionSystem.GateAScaffoldReady = true
