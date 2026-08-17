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
    FloorThickness = 16,
    -- Keep the rendered/collision floor one full floor thickness above the
    -- Flatgrass surface. This avoids z-fighting while leaving the generated
    -- floor resting directly on the map surface when the fallback Z is exact.
    GroundFloorOffset = 16,
    StairWidth = 192,
    -- Mandatory stairs run from an open lower approach corridor to the center
    -- of the upper logical cell. Ending at cell center provides a full landing
    -- with enough room to turn toward whichever upper corridor the graph owns.
    StairRun = 320,
    StairTopOffset = 0,
    StairSteps = 24,
    FloorColor = Color(58, 62, 64),
    StairColor = Color(76, 79, 80),
    DebugColor = Color(225, 145, 48),
    Skin = 0
}

C.Progression = {
    LayoutAttempts = 16,
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
