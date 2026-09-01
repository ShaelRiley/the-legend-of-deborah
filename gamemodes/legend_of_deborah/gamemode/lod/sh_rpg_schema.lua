LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG

RPG.SchemaVersion = 1
RPG.ImplementationGate = "A"
RPG.GameplayEnabled = false

RPG.Abilities = {"str", "dex", "con", "int", "wis", "cha"}
RPG.AbilitySet = {}
for _, ability in ipairs(RPG.Abilities) do RPG.AbilitySet[ability] = true end

RPG.Constants = {
    MinLevel = 1,
    MaxLevel = 20,
    HeroMaxXP = 48000,
    AbilityMin = 3,
    AbilityMax = 30,
    MagicCapacity = 100,
    MaxDamageDicePerChain = 32,
    MaxDamageDicePerAttackEvent = 128,
    MaxProjectilesPerAttackEvent = 16,
    MaxPenetrationTargetsPerProjectile = 4,
    RPGThreatMultiplierMin = 0.75,
    RPGThreatMultiplierMax = 2.00
}

RPG.OrdinaryFeatLevels = {1, 3, 6, 9, 12, 15, 18}

RPG.Classes = {
    fighter = {
        classId = "fighter",
        displayName = "Fighter",
        favoredAbilities = {"str", "con"},
        heroProgressionHitDieSides = 10
    },
    rogue = {
        classId = "rogue",
        displayName = "Rogue",
        favoredAbilities = {"dex", "cha"},
        heroProgressionHitDieSides = 8
    },
    wizard = {
        classId = "wizard",
        displayName = "Wizard",
        favoredAbilities = {"int", "wis"},
        heroProgressionHitDieSides = 6
    }
}

RPG.SystemBootstrap = {
    CharacterProgressionSystem = "scaffold",
    AbilityRules = "schema_only",
    FeatDirector = "schema_only",
    FeatEffectSystem = "pending",
    IdentityGenerationSystem = "schema_only",
    IdentityPerkSystem = "schema_only",
    CharacterSheetUI = "pending",
    PlayerCharacterText = "pending",
    RPGThreatEvaluator = "schema_only"
}

RPG.Schema = {
    ProgressionState = {
        "actorId", "archetypeId", "characterIdentityPackage", "level", "xp", "classId",
        "primaryAbility", "secondaryAbilities", "baseAbilities", "growthAbilities",
        "identityAbilityDelta", "equipmentAbilityDelta", "featAbilityDelta", "temporaryAbilityDelta",
        "effectiveAbilities", "startingHP", "progressionHitDieSides", "hitDieRollsByLevel",
        "featSlotsGranted", "featIds", "featStackCounts", "pendingFeatSlots",
        "classCapstoneFeatId", "pendingClassCapstoneDraft", "dungeonEntryLevel",
        "replacementXpEarnedThisDungeon", "capabilityTags"
    },
    ArchetypeProgressionTemplate = {
        "archetypeId", "baseAbilities", "aiClassWeights", "progressionHitDieSides",
        "baseXp", "moraleBonus", "usesMagic", "externalHealthProfileId"
    },
    DamageContributionLedger = {
        "targetActorId", "effectiveDamageByHeroId", "killingBlowHeroId",
        "totalEligibleEffectiveDamage", "resolved"
    },
    DefensiveProcState = {
        "actorId", "blastProofReadyAtSeconds", "notYetConsumedDungeonNumber"
    },
    CombatHitResolution = {
        "attackEventId", "targetActorId", "hitConnected", "harmWasEffective", "effectiveHPDamage",
        "resolvedHPDamageBeforeDiversion", "actualMagicDiversion", "finalHPDamage",
        "targetSurvived", "pushEligible", "hitStunEligible"
    },
    DerivedStats = {
        "strMod", "dexMod", "conMod", "intMod", "wisMod", "chaMod",
        "fighterTrainingLead", "fighterClassStrBonus", "fighterClassConBonus",
        "physicalDamageMultiplier", "fighterCapstonePhysicalDamageMultiplier",
        "fighterCapstoneMaxHPMultiplier", "fighterCapstoneOutgoingPushMultiplier",
        "fighterCapstoneIncomingPushMultiplier", "fighterCapstoneWallSlamBonusDice",
        "aimSpreadMultiplier", "movementSpeedMultiplier", "boomShift",
        "rogueAllDamageDiceExplode", "rogueBoomThresholdShift", "rogueCapstoneBoomThresholdShift",
        "rogueCapstoneEvasionChance", "rogueAcePrimed", "damageResistancePerDie",
        "hpConBonusPerLevel", "startingHP", "progressionHitDieSides", "rolledHitPointSubtotal",
        "coreMaxHP", "conRegenMultiplier", "wizardClassHpToMagicDiversionFraction",
        "manaBarrierFeatDiversionFraction", "wizardCapstoneDiversionBonus", "livingAegisHPPerMagic",
        "hpToMagicDiversionFraction", "magicRegenMultiplier", "wizardCapstoneMagicRegenMultiplier",
        "magicPowerMultiplier", "wizardCapstoneMagicPowerMultiplier", "wizardCapstoneMagicDCBonus",
        "utilityMagicCostMultiplier", "breadcrumbCells", "chaHitStunInflictMultiplier",
        "chaHitStunResistanceMultiplier", "featHitStunMultiplier", "weaponKnockbackProcChance",
        "weaponKnockbackProcDistance", "pusherProcTargetCooldownSeconds", "wallSlamDieSides",
        "wallSlamExplodes", "wallSlamClassExplosionImmune", "ammoRegenFloorFraction",
        "ammoRegenFloorRoundsByFamily", "rateOfFireMultiplier", "reloadTimeMultiplier",
        "smgHeatSuppressionChance", "smgOverheatThreshold", "blastProofCooldownSeconds",
        "invisibleStatePerception", "nearbyHostileWallSenseCells", "watcherMovementSenseAudio",
        "burstBonusRounds", "heroOfLegendPulseEnabled", "heroOfLegendPulseRangeCells",
        "tetrisOverfillMultiplier", "deathTetrisMaxSeconds", "arcaneItemUseChance",
        "canActivateWandsScrolls", "spotTargetRangeCells", "spotDrawRangeCells",
        "spotDurationSeconds", "rpgThreatMultiplier", "levelProficiency"
    },
    FeatDefinition = {
        "featId", "displayName", "featFamilyId", "rankIndex", "replacesLowerRank",
        "repeatableFallback", "governingAbilities", "abilityRequirements", "prerequisiteFeatIds",
        "requiredCapabilityTags", "incompatibleFeatIds", "allowedActorTypes", "requiredSubsystemTags",
        "synergyTags", "oneRank", "effectHandlerId", "effectParams", "directorBaseWeight"
    },
    ClassCapstoneDefinition = {
        "featId", "displayName", "classId", "synergyTags", "effectHandlerId", "effectParams"
    },
    PendingFeatDraft = {
        "earnedAtLevel", "draftType", "offerFeatIds", "rngSeed", "selectedFeatId", "resolved"
    },
    IdentityPerkDefinition = {
        "tableType", "tableIndex", "categoryName", "perkDisplayName", "flavorText",
        "effectHandlerId", "effectParams", "capabilityTags"
    },
    CharacterIdentityPackage = {
        "rosterSeed", "heroIdentityId", "originIndex", "backgroundIndex", "motiveIndex",
        "masculineOrFeminineFirstNameIndex", "surnameIndex", "nicknameIndex", "presentationSex",
        "firstName", "surname", "nickname", "fullDisplayName", "portraitCacheKey",
        "identityAbilityDelta", "resolvedIdentityPerkIds"
    }
}

RPG.CombatResolutionOrder = {
    "kept_values_and_explosion_qualification",
    "continuation_generation_and_blast_proof",
    "attack_work_caps",
    "con_per_die_resistance",
    "target_aggregation",
    "source_wide_stat_and_item_modifiers",
    "elemental_weakness_resistance_immunity",
    "other_target_wide_modifiers",
    "freeze_resolved_hp_damage",
    "hp_to_magic_diversion",
    "lethal_interceptors",
    "hp_and_overfill_loss",
    "control_attribution_morale_and_death"
}

function RPG.NewAbilityBlock(defaultValue)
    local value = tonumber(defaultValue) or 0
    return {str = value, dex = value, con = value, int = value, wis = value, cha = value}
end
