LOD = LOD or {}
LOD.Config = LOD.Config or {}

local C = LOD.Config

C.PlayerTeam = 1
C.MaxActivePlayers = 4

C.Maze = {
    Width = 21,
    Height = 21,
    CellSize = 384,
    LevelHeight = 256,
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
    FloorThickness = 16,
    StairWidth = 192,
    StairRun = 160,
    StairSteps = 16,
    FloorColor = Color(58, 62, 64),
    StairColor = Color(76, 79, 80),
    DebugColor = Color(225, 145, 48),
    Skin = 0
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
