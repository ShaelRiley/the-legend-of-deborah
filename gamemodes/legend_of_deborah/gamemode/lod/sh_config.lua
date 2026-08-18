LOD = LOD or {}
LOD.Config = LOD.Config or {}

local C = LOD.Config

C.MaxActivePlayers = 4
C.Campaign = {
    MaxPlayedIdentities = 10
}

C.Lives = {
    StartingLives = 3,
    MaxLives = 4,
    RespawnDelay = 20
}

C.Maze = {
    Width = 21,
    Height = 21,
    CellSize = 384,
    LevelHeight = 384,
    Origin = Vector(0, 0, -12288),
    PrimaryOccupancy = {0.65, 0.80},
    SecondaryOccupancy = {0.35, 0.55},
    TertiaryOccupancy = {0.20, 0.35},
    FourthOccupancyMax = 0.10,
    MandatoryVerticalMin = 3,
    MandatoryVerticalMax = 6
}

C.Geometry = {
    ContainerModel = "models/props_wasteland/cargo_container01.mdl",
    ContainerWidth = 128,
    ContainerHeight = 128,
    WallStack = 2,
    AntiBypassHeight = 384,
    FloorThickness = 16,
    StairWidth = 128,
    StairRun = 320,
    StairSteps = 24
}

C.Progression = {
    LayoutAttempts = 64,
    KeycardDetourMin = 4,
    KeycardGateCellSeparationMin = 3,
    GateWidth = C.Maze.CellSize,
    GateVisibleHeight = 256,
    GateBlockerHeight = 384,
    GateOpenSeconds = 0.75,
    IntermissionSeconds = 15,
    Cards = {
        {name = "Red", short = "R", symbol = "TRIANGLE"},
        {name = "Blue", short = "B", symbol = "CIRCLE"},
        {name = "Yellow", short = "Y", symbol = "SQUARE"}
    }
}

C.Encounter = {
    ActivationDistanceCells = 4,
    LeashCells = 6,
    RouteRefreshSeconds = 0.35,
    TargetRefreshSeconds = 0.25,
    MajorSpacingCells = 4,
    ActiveHostileTarget = 32,
    ActiveHostileCeiling = 40,
    CampaignThreatGrowthPerLevel = 0.06,
    EnemyHPGrowthPerLevel = 0.02,
    EnemyHPLevelCap = 1.50,
    PartyThreatMultiplier = {1.00, 1.40, 1.70, 2.00},
    PartyHealthMultiplier = {1.00, 1.10, 1.20, 1.30},
    -- Keycard fights are guaranteed separately. These budgets fund the
    -- discretionary encounters that give each act its pacing profile.
    SectorBaseThreat = {4.0, 6.0, 8.0, 9.0},
    MaxDiscretionaryPerSector = {1, 2, 2, 2},
    Archetypes = {
        shambler = {
            class = "lod_hostile_shambler",
            name = "Shambler",
            model = "models/zombie/classic.mdl",
            baseHP = 100,
            speed = 90,
            meleeDamage = 20,
            meleeCooldown = 1.2,
            meleeRange = 74,
            attackSounds = {
                "npc/zombie/zo_attack1.wav",
                "npc/zombie/zo_attack2.wav"
            },
            threat = 1.0,
            activity = ACT_WALK
        },
        runner = {
            class = "lod_hostile_runner",
            name = "Runner",
            model = "models/zombie/fast.mdl",
            baseHP = 50,
            speed = 220,
            meleeDamage = 10,
            meleeCooldown = 0.9,
            meleeRange = 70,
            attackSounds = {
                "npc/fast_zombie/fz_frenzy1.wav",
                "npc/fast_zombie/fz_scream1.wav",
                "npc/fast_zombie/fz_alert_close1.wav"
            },
            threat = 1.5,
            activity = ACT_RUN
        },
        soldier = {
            class = "lod_hostile_soldier",
            name = "Soldier",
            model = "models/combine_soldier.mdl",
            baseHP = 100,
            speed = 140,
            burstDamage = 6,
            burstShots = 3,
            burstCooldown = 1.5,
            -- Soldiers no longer deal direct hitscan damage. A full one-second
            -- visible/audio tell precedes each burst, then physical energy bolts
            -- travel through the maze. Players can strafe, break LOS, or duck
            -- behind cover before the first shot is released.
            burstTelegraph = 1.00,
            burstShotInterval = 0.13,
            projectileSpeed = 950,
            projectileLifetime = 1.35,
            fireRange = 850,
            preferredRange = 480,
            threat = 2.5,
            activity = ACT_RUN
        }
    },
    Templates = {
        patrol = {name = "Patrol", composition = {shambler = 2}, variableShambler = true},
        rush = {name = "Rush", composition = {shambler = 2, runner = 1}},
        runner_ambush = {name = "Runner Ambush", composition = {runner = 2}},
        firing_line = {name = "Firing Line", composition = {soldier = 2}},
        mixed_pressure = {name = "Mixed Pressure", composition = {shambler = 2, soldier = 1}},
        arena = {name = "Arena", composition = {shambler = 3, runner = 1, soldier = 1}},
        red_keycard = {name = "Red Keycard", composition = {shambler = 3, runner = 1}, objective = true},
        blue_keycard = {name = "Blue Keycard", composition = {shambler = 2, soldier = 2}, objective = true},
        yellow_keycard = {name = "Yellow Keycard", composition = {runner = 2, soldier = 2, shambler = 2}, objective = true}
    }
}

-- Audio feedback is deliberately centralized. Character-specific pain banks are
-- attempted first; if a named HL2 character has no usable pain clip mounted on
-- the server, the runtime falls back to the gender-correct citizen voice set.
C.Audio = {
    PlayerPainCooldown = 0.65,
    MalePainFallback = {
        "vo/npc/male01/pain01.wav", "vo/npc/male01/pain02.wav", "vo/npc/male01/pain03.wav",
        "vo/npc/male01/pain04.wav", "vo/npc/male01/pain05.wav", "vo/npc/male01/pain06.wav",
        "vo/npc/male01/pain07.wav", "vo/npc/male01/pain08.wav", "vo/npc/male01/pain09.wav"
    },
    FemalePainFallback = {
        "vo/npc/female01/pain01.wav", "vo/npc/female01/pain02.wav", "vo/npc/female01/pain03.wav",
        "vo/npc/female01/pain04.wav", "vo/npc/female01/pain05.wav", "vo/npc/female01/pain06.wav",
        "vo/npc/female01/pain07.wav", "vo/npc/female01/pain08.wav", "vo/npc/female01/pain09.wav"
    },
    CharacterPain = {
        breen   = {gender = "male"},
        alyx    = {gender = "female", sounds = {
            "vo/npc/alyx/hurt04.wav", "vo/npc/alyx/hurt05.wav",
            "vo/npc/alyx/hurt06.wav", "vo/npc/alyx/hurt08.wav"
        }},
        barney  = {gender = "male", sounds = {
            "vo/npc/barney/ba_pain01.wav", "vo/npc/barney/ba_pain02.wav", "vo/npc/barney/ba_pain03.wav"
        }},
        kleiner = {gender = "male"},
        eli     = {gender = "male"},
        mossman = {gender = "female"},
        odessa  = {gender = "male"},
        grigori = {gender = "male", sounds = {
            "vo/ravenholm/monk_pain01.wav", "vo/ravenholm/monk_pain02.wav",
            "vo/ravenholm/monk_pain03.wav", "vo/ravenholm/monk_pain04.wav"
        }},
        male    = {gender = "male"},
        female  = {gender = "female"}
    }
}

-- Deborah deliberately reserves female_01 from the citizen NPC family. The
-- playable Female Citizen uses a different model variant.
C.Models = {
    Deborah = "models/Humans/Group01/Female_01.mdl",
    Characters = {
        {id = "breen",   name = "Dr. Breen",         model = "models/player/breen.mdl"},
        {id = "alyx",    name = "Alyx Vance",        model = "models/player/alyx.mdl"},
        {id = "barney",  name = "Barney Calhoun",    model = "models/player/barney.mdl"},
        {id = "kleiner", name = "Dr. Kleiner",       model = "models/player/kleiner.mdl"},
        {id = "eli",     name = "Eli Vance",         model = "models/player/eli.mdl"},
        {id = "mossman", name = "Dr. Judith Mossman",model = "models/player/mossman.mdl"},
        {id = "odessa",  name = "Odessa Cubbage",    model = "models/player/odessa.mdl"},
        {id = "grigori", name = "Father Grigori",    model = "models/player/monk.mdl"},
        {id = "male",    name = "Male Citizen",      model = "models/player/Group01/male_07.mdl"},
        {id = "female",  name = "Female Citizen",    model = "models/player/Group01/female_02.mdl"}
    }
}

C.Debug = {
    GraphChunkEdges = 80,
    SeedTestMax = 1000
}
