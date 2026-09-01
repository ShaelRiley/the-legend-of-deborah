LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.RPG.IdentityCatalog = LOD.RPG.IdentityCatalog or {}

local Catalog = LOD.RPG.IdentityCatalog

Catalog.ClassCapstones = {
    fighter = {
        FTR_CAP_ONE_PERSON_ARMY = {
            featId = "FTR_CAP_ONE_PERSON_ARMY", displayName = "One-Person Army",
            classId = "fighter", synergyTags = {"physical_damage"},
            effectHandlerId = "fighter_capstone_physical_damage",
            effectParams = {physicalDamageMultiplier = 1.20,
                description = "Eligible STR-scaled physical attacks deal 1.20× damage after STR scaling and before elemental resolution."}
        },
        FTR_CAP_BUILT_DIFFERENT = {
            featId = "FTR_CAP_BUILT_DIFFERENT", displayName = "Built Different",
            classId = "fighter", synergyTags = {"maximum_hp"},
            effectHandlerId = "fighter_capstone_max_hp",
            effectParams = {maxHPMultiplier = 1.25,
                description = "Ordinary MaxHP is multiplied by 1.25 before temporary Tetris overfill. Selecting it raises the ceiling without healing."}
        },
        FTR_CAP_UNSTOPPABLE_FORCE = {
            featId = "FTR_CAP_UNSTOPPABLE_FORCE", displayName = "Unstoppable Force",
            classId = "fighter", synergyTags = {"push", "wall_slam"},
            effectHandlerId = "fighter_capstone_push",
            effectParams = {outgoingPushMultiplier = 1.33, incomingPushMultiplier = 0.75,
                wallSlamBonusDice = 1,
                description = "Physical push is 1.33× outgoing and 0.75× incoming; legitimate wall slams gain exactly one die."}
        }
    },
    rogue = {
        ROG_CAP_LOADED_DICE = {
            featId = "ROG_CAP_LOADED_DICE", displayName = "Loaded Dice",
            classId = "rogue", synergyTags = {"exploding_dice"},
            effectHandlerId = "rogue_capstone_threshold",
            effectParams = {boomThresholdShift = 1,
                description = "Rogue explosion qualification improves by one number while preserving every hard floor, seal, and work cap."}
        },
        ROG_CAP_NOW_YOU_SEE_ME = {
            featId = "ROG_CAP_NOW_YOU_SEE_ME", displayName = "Now You See Me",
            classId = "rogue", synergyTags = {"evasion"},
            effectHandlerId = "rogue_capstone_evasion",
            effectParams = {evasionChance = 0.20,
                description = "Each eligible incoming direct attack event receives one deterministic 20% evasion roll before diversion and control."}
        },
        ROG_CAP_ACE_IN_THE_HOLE = {
            featId = "ROG_CAP_ACE_IN_THE_HOLE", displayName = "Ace in the Hole",
            classId = "rogue", synergyTags = {"damage_die", "paced_attack"},
            effectHandlerId = "rogue_capstone_ace",
            effectParams = {primeSeconds = 3.0,
                description = "After 3.0 attack-free seconds, the next committed eligible attack adds one primary damage die and clears priming."}
        }
    },
    wizard = {
        WIZ_CAP_ARCHMAGE = {
            featId = "WIZ_CAP_ARCHMAGE", displayName = "Archmage",
            classId = "wizard", synergyTags = {"offensive_magic"},
            effectHandlerId = "wizard_capstone_archmage",
            effectParams = {magicPowerMultiplier = 1.20, magicDCBonus = 2,
                description = "WIS-scaled offensive Magic gains 1.20× power and explicitly resistible Wizard Magic gains +2 Magic DC."}
        },
        WIZ_CAP_MANA_ENGINE = {
            featId = "WIZ_CAP_MANA_ENGINE", displayName = "Mana Engine",
            classId = "wizard", synergyTags = {"magic_regeneration"},
            effectHandlerId = "wizard_capstone_mana_engine",
            effectParams = {magicRegenMultiplier = 1.50,
                description = "Permitted INT-scaled Magic regeneration is multiplied by 1.50; suppression and the fixed 100 cap remain absolute."}
        },
        WIZ_CAP_LIVING_AEGIS = {
            featId = "WIZ_CAP_LIVING_AEGIS", displayName = "Living Aegis",
            classId = "wizard", synergyTags = {"damage_diversion"},
            effectHandlerId = "wizard_capstone_living_aegis",
            effectParams = {diversionBonus = 0.10, hpPerMagic = 1.25,
                description = "Automatic damage diversion gains +0.10 fraction, capped at 1.00, and diverts 1.25 HP per Magic."}
        }
    }
}

return Catalog.ClassCapstones
