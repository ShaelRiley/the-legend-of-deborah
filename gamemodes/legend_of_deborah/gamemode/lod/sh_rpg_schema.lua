LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG

RPG.SchemaVersion = 9
RPG.ImplementationGate = "D"
RPG.GameplayEnabled = true

RPG.Abilities = {"str", "dex", "con", "int", "wis", "cha"}
RPG.AbilitySet = {}
for _, ability in ipairs(RPG.Abilities) do RPG.AbilitySet[ability] = true end

RPG.Elements = {"earth", "fire", "dark", "ice", "light", "electric"}
RPG.ElementOpposites = {earth="electric",electric="earth",fire="ice",ice="fire",dark="light",light="dark"}
RPG.StatusIds = {"clumsy", "immolated", "poisoned", "bleeding", "muted",
    "held", "reckless", "arcane_shattered", "intimidated", "morale_flee"}

RPG.Constants = {
    MinLevel = 1,
    HeroMaxLevel = 20,
    MonsterMaxLevel = 999,
    -- Compatibility alias for older Hero-only consumers. New actor-aware code
    -- must use HeroMaxLevel/MonsterMaxLevel through CharacterProgressionSystem.
    MaxLevel = 20,
    HeroMaxXP = 96000,
    AbilityMin = 3,
    AbilityMax = 30,
    MagicCapacity = 100,
    MaxDamageDicePerChain = 32,
    MaxDamageDicePerAttackEvent = 128,
    MaxProjectilesPerAttackEvent = 16,
    MaxPenetrationTargetsPerProjectile = 128,
    RPGThreatMultiplierMin = 0.75,
    RPGThreatMultiplierMax = 2.00
}

-- Enemy-side balance uses the same derived damage/status authorities as Heroes.
RPG.EnemyDefenseTuning = {conPerDieCap = 1, diversionCap = .30,
    feedbackChanceCap = .15, feedbackCooldown = 2,
    shatterDCBonus = 4, shatterDurationMultiplier = 1.5, shatterMinimumSeconds = 24}

RPG.OrdinaryFeatLevels = {1, 3, 6, 9, 12, 15, 18}

RPG.HeroXPThresholds = {
    [1] = 0, [2] = 300, [3] = 800, [4] = 1600, [5] = 3000,
    [6] = 5000, [7] = 7600, [8] = 10800, [9] = 14600, [10] = 19000,
    [11] = 24000, [12] = 29600, [13] = 35800, [14] = 42600,
    [15] = 50000, [16] = 58000, [17] = 66600, [18] = 75800,
    [19] = 85600, [20] = 96000
}

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
        heroProgressionHitDieSides = 4
    }
}

local function archetypeTemplate(str, dex, con, int, wis, cha,
    fighter, rogue, wizard, hitDie, baseXp, moraleBonus, usesMagic, healthProfile)
    return {
        baseAbilities = {str = str, dex = dex, con = con, int = int, wis = wis, cha = cha},
        aiClassWeights = {fighter = fighter, rogue = rogue, wizard = wizard},
        progressionHitDieSides = hitDie,
        baseXp = baseXp,
        moraleBonus = moraleBonus,
        usesMagic = usesMagic == true,
        externalHealthProfileId = healthProfile
    }
end

-- Canonical Level-0 growth templates. These are deliberately separate from the
-- external combat/health profiles: the existing archetype modules continue to
-- own attack geometry, base health dice, size and encounter behavior.
RPG.ArchetypeProgressionTemplates = {
    shambler = archetypeTemplate(14, 6, 14, 5, 8, 6, 70, 20, 10, 8, 20, 4, false, "shambler"),
    runner = archetypeTemplate(10, 15, 10, 5, 8, 7, 20, 70, 10, 6, 25, 3, false, "runner"),
    climber = archetypeTemplate(9, 16, 10, 4, 9, 5, 15, 80, 5, 6, 35, 6, false, "climber"),
    soldier = archetypeTemplate(11, 12, 11, 10, 10, 10, 50, 40, 10, 8, 35, 6, false, "soldier"),
    deadcrab = archetypeTemplate(8, 15, 8, 3, 7, 4, 20, 75, 5, 6, 20, 8, false, "deadcrab"),
    bioblaster = archetypeTemplate(10, 8, 12, 11, 13, 7, 20, 20, 60, 8, 45, 4, false, "bioblaster"),
    blitzer = archetypeTemplate(10, 14, 10, 9, 9, 10, 30, 60, 10, 8, 40, 5, false, "blitzer"),
    sniper = archetypeTemplate(9, 15, 9, 11, 12, 10, 15, 70, 15, 6, 45, 4, false, "sniper"),
    flamer = archetypeTemplate(12, 10, 12, 8, 10, 9, 55, 30, 15, 8, 45, 5, false, "flamer"),
    bigcrab = archetypeTemplate(16, 8, 16, 4, 8, 5, 80, 15, 5, 12, 80, 8, false, "bigcrab"),
    watcher = archetypeTemplate(5, 14, 8, 14, 13, 14, 5, 35, 60, 6, 35, 2, false, "watcher"),
    seeker = archetypeTemplate(12, 15, 11, 5, 9, 5, 25, 70, 5, 8, 40, 7, false, "seeker"),
    sentry = archetypeTemplate(12, 10, 14, 8, 11, 7, 55, 35, 10, 10, 50, 8, false, "sentry"),
    razor = archetypeTemplate(10, 16, 9, 5, 9, 5, 20, 75, 5, 6, 40, 6, false, "razor"),
    arccaster = archetypeTemplate(8, 9, 11, 14, 16, 10, 10, 15, 75, 8, 50, 4, true, "arccaster"),
    nodule = archetypeTemplate(8, 6, 14, 6, 10, 4, 70, 10, 20, 8, 35, 5, false, "nodule"),
    lurker = archetypeTemplate(12, 11, 12, 4, 11, 5, 45, 45, 10, 8, 40, 6, false, "lurker"),
    beamsweeper = archetypeTemplate(9, 10, 13, 13, 14, 7, 20, 30, 50, 10, 55, 7, false, "beamsweeper"),
    neil = archetypeTemplate(10, 13, 11, 12, 12, 14, 20, 40, 40, 10, 150, 8, false, "neil"),
    brute = archetypeTemplate(18, 7, 18, 4, 8, 9, 90, 5, 5, 12, 250, 10, false, "brute"),
    warden = archetypeTemplate(15, 14, 17, 13, 13, 14, 40, 30, 30, 20, 500, "immune", true, "warden"),
    hector = archetypeTemplate(15, 14, 17, 13, 13, 14, 40, 30, 30, 20, 500, "immune", true, "hector")
}

for archetypeId, template in pairs(RPG.ArchetypeProgressionTemplates) do
    template.archetypeId = archetypeId
end

RPG.ArchetypeProgressionAliases = {
    arc_caster = "arccaster",
    big_crab = "bigcrab",
    beam_sweeper = "beamsweeper",
    gordon = "warden",
    gordon_warden = "warden",
    gordon_the_warden = "warden"
}

RPG.SystemBootstrap = {
    CharacterProgressionSystem = "gate_c_levels_1_20",
    AbilityRules = "gate_d_gameplay",
    FeatDirector = "gate_c_cadence_and_capstone",
    FeatEffectSystem = "gate_e_batch_3_int_ammo_regeneration",
    IdentityGenerationSystem = "gate_b",
    IdentityPerkSystem = "three_shared_identity_handlers",
    CharacterSheetUI = "gate_c",
    PlayerCharacterText = "gate_b",
    CombatAttributionSystem = "gate_d_hero_xp",
    StatusElementSystem = "integrated_checkpoint_b",
    RPGThreatEvaluator = "schema_only"
}

RPG.Schema = {
    ProgressionState = {
        "actorId", "actorType", "archetypeId", "tierId", "dungeonLevel",
        "characterIdentityPackage", "level", "xp", "classId",
        "primaryAbility", "secondaryAbilities", "baseAbilities", "growthAbilities",
        "identityAbilityDelta", "equipmentAbilityDelta", "featAbilityDelta", "temporaryAbilityDelta",
        "effectiveAbilities", "startingHP", "progressionHitDieSides", "hitDieRollsByLevel",
        "featSlotsGranted", "featIds", "featStackCounts", "pendingFeatSlots",
        "classCapstoneFeatId", "pendingClassCapstoneDraft", "dungeonEntryLevel",
        "replacementXpEarnedThisDungeon", "capabilityTags", "contentIds",
        "moraleBonus", "usesMagic", "currentElement", "elementalWeaknesses", "monsterElementAssigned",
        "statusImmunities"
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
    StatusInstance = {
        "id", "source", "dc", "appliedAt", "expiresAt", "nextTickAt",
        "nextRecoveryAt", "lastCellKey"
    },
    ElementResolution = {
        "element", "kind", "multiplier", "index", "hitStunMultiplier", "knockback"
    },
    DerivedStats = {
        "strMod", "dexMod", "conMod", "intMod", "wisMod", "chaMod",
        "fighterTrainingLead", "fighterClassStrBonus", "fighterClassConBonus",
        "physicalDamageBonus", "fighterStrengthBypassesCon", "rogueBackstabEnabled", "fighterCapstonePhysicalDamageMultiplier",
        "fighterCapstoneMaxHPMultiplier", "fighterCapstoneOutgoingPushMultiplier",
        "fighterCapstoneIncomingPushMultiplier", "fighterCapstoneWallSlamBonusDice",
        "aimSpreadMultiplier", "movementSpeedMultiplier", "boomShift",
        "rogueAllDamageDiceExplode", "rogueBoomThresholdShift", "rogueCapstoneBoomThresholdShift",
        "dodgeChanceContribution", "rogueAcePrimed", "damageResistancePerDie", "enemyDefense",
        "rogueAcePrimeSeconds",
        "hpConBonusPerLevel", "startingHP", "progressionHitDieSides", "rolledHitPointSubtotal",
        "coreMaxHP", "maxHP", "conRegenMultiplier", "healthRegenEnabled", "healthRegenRank",
        "healthRegenCeilingFraction", "healthRegenDamageFreeDelaySeconds",
        "healthRegenBaseMaxHPPerSecond", "wizardClassHpToMagicDiversionFraction",
        "manaBarrierFeatDiversionFraction", "wizardCapstoneDiversionBonus", "livingAegisHPPerMagic",
        "hpToMagicDiversionFraction", "magicRegenMultiplier", "wizardCapstoneMagicRegenMultiplier",
        "magicDamageBonus", "wizardCapstoneMagicPowerMultiplier", "wizardCapstoneMagicDCBonus",
        "utilityMagicCostMultiplier", "breadcrumbCells", "breadcrumbFeatRank",
        "breadcrumbFeatBonusCells", "frugalMapEnabled", "mapDrainFeatMultiplier",
        "minimumMapDrainPerSecond", "chaHitStunInflictMultiplier",
        "chaHitStunResistanceMultiplier", "featHitStunMultiplier", "weaponKnockbackProcChance",
        "weaponKnockbackProcDistance", "pusherProcTargetCooldownSeconds", "wallSlamDieSides",
        "wallSlamExplodes", "wallSlamClassExplosionImmune", "ammoRegenFloorFraction",
        "ammoRegenFloorRank", "ammoRegenFloorRoundsByFamily", "rateOfFireMultiplier",
        "reloadTimeMultiplier",
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
    IdentityTraitDefinition = {"tableType", "tableIndex", "categoryName", "flavorText"},
    IdentityPerkRecord = {"traitSlot", "traitIndex", "handlerId", "targetId", "secondaryTargetId", "abilityBonuses", "targetName", "seed", "displayName", "traitName", "flavorText"},
    CharacterIdentityPackage = {
        "rosterSeed", "heroIdentityId", "originIndex", "backgroundIndex", "motiveIndex",
        "masculineOrFeminineFirstNameIndex", "surnameIndex", "nicknameIndex", "presentationSex",
        "firstName", "surname", "nickname", "fullDisplayName", "portraitCacheKey",
        "identityAbilityDelta", "resolvedIdentityPerkIds", "identityPerkRecords", "identityPerkVersion",
        "favoredWeaponStacks", "favoredEnemyStacks"
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

-- Canonical enabled direct-firearm damage sources; identity targets observe these IDs.
LOD.RPG.PlayerWeaponDamageProfiles = {
    weapon_pistol = {weaponFamilyId = "pistol", label = "PISTOL", source = "pistol", count = 1, sides = 4},
    weapon_smg1 = {weaponFamilyId = "smg", label = "SMG", source = "SMG", count = 1, sides = 8},
    weapon_ar2 = {weaponFamilyId = "ar2", label = "AR2", source = "AR2", count = 1, sides = 10},
    weapon_357 = {weaponFamilyId = "magnum", label = "MAGNUM", source = ".357 Magnum", count = 1, sides = 12, exploding = 8},
    weapon_shotgun = {weaponFamilyId = "shotgun", label = "SHOTGUN", source = "shotgun", count = 1, sides = 6, exploding = 6, floor = 3}
}
