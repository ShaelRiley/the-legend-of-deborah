LOD = LOD or {}
LOD.Config = LOD.Config or {}

local C = LOD.Config

C.PlayerTeam = 1
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
    -- Keep successive traversable floors vertically separated from the tops of
    -- the two-container wall stack. At 256 units the lower wall tops were flush
    -- with the next floor, creating a potential wall-top bypass.
    LevelHeight = 384,
    Origin = Vector(0, 0, 0),
    GenerationAttempts = 32,
    MandatoryVerticalMin = 3,
    MandatoryVerticalMax = 6,
    LoopFractionMin = 0.05,
    LoopFractionMax = 0.10,
    RareFourthLayerChance = 0.05,
    LayerOccupancy = {
        {0.65, 0.80},
        {0.35, 0.55},
        {0.20, 0.35},
        {0.05, 0.10}
    }
}

C.Geometry = {
    ContainerModel = "models/props_wasteland/cargo_container01.mdl",
    ContainerLength = 390,
    ContainerWidth = 128,
    ContainerHeight = 128,
    WallStack = 2,
    -- Visible walls remain two containers high. Authoritative collision extends
    -- to the next logical floor so ordinary jumping cannot turn container tops
    -- into graph/progression shortcuts.
    AntiBypassHeight = C.Maze.LevelHeight,
    -- Floors are deliberately substantial steel deck plates rather than thin
    -- abstract planes. Their top surface remains exactly at CellCenter.z; extra
    -- thickness extends downward, so navigation/stair landing elevations do not
    -- change while ceilings read as physically solid from the level below.
    FloorThickness = 32,
    FloorMaterial = "phoenix_storms/metalfloor_2-3",
    FloorMaterialFallback = "models/props_c17/FurnitureMetal001a",
    -- Keep the rendered/collision floor above the Flatgrass surface. The floor
    -- plate may extend into the map ground below; only its authored top plane is
    -- gameplay-significant.
    GroundFloorOffset = 16,
    -- Keep enough real walkable deck beside upper stair apertures. With 128-unit
    -- container walls intruding 64 units into a 384-unit cell, the former
    -- 192-unit stair left only ~26 units between handrail and wall, narrower
    -- than a Source player hull. A 128-unit stair leaves ~58 units of clearance
    -- while remaining comfortably wider than the player.
    StairWidth = 128,
    -- Mandatory stairs run from an open lower approach corridor to the center
    -- of the upper logical cell. Ending at cell center provides a full landing
    -- with enough room to turn toward whichever upper corridor the graph owns.
    StairRun = 320,
    StairTopOffset = 0,
    StairSteps = 24,
    FloorColor = Color(46, 49, 51),
    StairColor = Color(68, 72, 74),
    DebugColor = Color(225, 145, 48),
    Skin = 0
}

C.Progression = {
    -- Safety constraints can reject an otherwise valid maze late in planning.
    -- Keep deterministic retry headroom high enough that normal campaign startup
    -- does not fail merely because the first handful of layouts are unsuitable.
    LayoutAttempts = 64,
    MinimumGateSpacing = 4,
    MinimumTailEdges = 5,
    KeycardDetourMin = 4,
    -- Prevent a logically deep objective from nevertheless appearing immediately
    -- beside its own lock in physical grid space. The safety validator measures
    -- taxicab distance in logical cells and rejects/retries closer layouts.
    KeycardGateCellSeparationMin = 3,
    KeycardTopBandFraction = 0.35,
    GateThickness = 28,
    -- A gate replaces one complete logical wall edge. Match the 384-unit cell
    -- width so no player-sized lateral gap remains between the gate and the
    -- neighboring maze walls.
    GateWidth = C.Maze.CellSize,
    GateVisibleHeight = 256,
    GateBlockerHeight = C.Maze.LevelHeight,
    GateOpenSeconds = 0.75,
    KeycardTriggerRadius = 52,
    KeycardHeight = 40,
    IntermissionSeconds = 15,
    Cards = {
        {
            id = "red",
            name = "Red",
            letter = "R",
            symbol = "TRIANGLE",
            color = Color(205, 54, 54)
        },
        {
            id = "blue",
            name = "Blue",
            letter = "B",
            symbol = "CIRCLE",
            color = Color(64, 118, 210)
        },
        {
            id = "yellow",
            name = "Yellow",
            letter = "Y",
            symbol = "SQUARE",
            color = Color(224, 190, 52)
        }
    }
}

C.Encounter = {
    ActivationDistanceCells = 4,
    LeashCells = 6,
    RouteRefreshSeconds = 0.35,
    TargetRefreshSeconds = 0.25,
    MajorSpacingCells = 4,
    -- Sixteen production wanderers per floor means the rare four-floor maze
    -- owns 64 roamers before authored encounters activate. Preserve substantial
    -- encounter headroom while retaining a hard runaway-entity safety ceiling.
    ActiveHostileTarget = 80,
    ActiveHostileCeiling = 96,
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
            -- Playtest retune: the original 100 HP was reduced by roughly two
            -- thirds. The Milestone-3 test kit uses stock weapon_pistol damage;
            -- on the current runtime, 35 HP is about seven registered body hits,
            -- not the three hits previously estimated from an incorrect assumed
            -- pistol-damage value.
            baseHP = 35,
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
            -- Match the playtest-driven roughly-two-thirds HP reduction applied
            -- to the Shambler while retaining the Runner's lower durability.
            baseHP = 17,
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
            -- Match the Shambler's playtest-driven roughly-two-thirds HP cut.
            -- Soldier difficulty should come from ranged pressure and positioning,
            -- not from absorbing an excessive number of ordinary bullets.
            baseHP = 35,
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
