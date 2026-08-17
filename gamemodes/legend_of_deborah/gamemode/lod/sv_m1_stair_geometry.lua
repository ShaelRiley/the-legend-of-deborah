LOD = LOD or {}
LOD.MazeBuilder = LOD.MazeBuilder or {}

local MazeBuilder = LOD.MazeBuilder
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local cellKey = LOD.MazeGenerator.CellKey

local DIRS = {
    {name = "N", dx = 0, dy = 1},
    {name = "E", dx = 1, dy = 0},
    {name = "S", dx = 0, dy = -1},
    {name = "W", dx = -1, dy = 0}
}

local DIR_BY_NAME = {
    N = DIRS[1], E = DIRS[2], S = DIRS[3], W = DIRS[4]
}
local OPPOSITE = {N = "S", S = "N", E = "W", W = "E"}
local YAW = {E = 0, N = 90, W = 180, S = -90}
local REAR_CROSSOVER_DEPTH = 96

local function spawnStaticBox(pos, ang, mins, maxs, kind)
    local ent = ents.Create("lod_static_box")
    if not IsValid(ent) then return nil end
    ent:SetPos(pos)
    ent:SetAngles(ang or angle_zero)
    ent:SetBoxMins(mins)
    ent:SetBoxMaxs(maxs)
    ent:SetBoxKind(kind or 1)
    ent:Spawn()
    ent:Activate()
    if ent.IsLODCollisionReady and not ent:IsLODCollisionReady() then
        ent:Remove()
        return nil
    end
    return ent
end

local function lowerCell(edge)
    return edge.a.z < edge.b.z and edge.a or edge.b
end

local function hasOpenEdge(graph, cell, d)
    local c = graph.Cells[cellKey(cell.x, cell.y, cell.z)]
    return c and c.neighbors[cellKey(cell.x + d.dx, cell.y + d.dy, cell.z)] == true
end

local function fallbackDirection(edge)
    local n = (edge.a.x * 17 + edge.a.y * 31 + edge.a.z * 13) % 4
    return ({"E", "N", "W", "S"})[n + 1]
end

-- A mandatory staircase must have a real lower approach. Choose one of the
-- lower cell's graph-open horizontal edges deterministically; ascent proceeds
-- from that approach toward the center of the vertically connected upper cell.
local function assignDirection(graph, edge)
    if edge.LODStairDirection then return edge.LODStairDirection end

    local lower = lowerCell(edge)
    local start = (lower.x * 17 + lower.y * 31 + lower.z * 13) % #DIRS
    for offset = 0, #DIRS - 1 do
        local d = DIRS[((start + offset) % #DIRS) + 1]
        if hasOpenEdge(graph, lower, d) then
            edge.LODStairEntrySide = d.name
            edge.LODStairDirection = OPPOSITE[d.name]
            return edge.LODStairDirection
        end
    end

    edge.LODStairEntrySide = nil
    edge.LODStairDirection = fallbackDirection(edge)
    return edge.LODStairDirection
end

local previousBuild = MazeBuilder.Build
function MazeBuilder:Build(graph)
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        assignDirection(graph, edge)
    end
    return previousBuild(self, graph)
end

-- Local +X points uphill. The stair reaches upper-floor height at cell center.
-- Build the upper transition cell as a real landing with walkable floor on all
-- four sides of the stair opening. The rear crossover prevents the player from
-- needing to jump the stairwell to reach a graph-open corridor behind the stairs.
function MazeBuilder:_BuildPerforatedFloor(cell, edge)
    local center = self:CellCenter(cell)
    local half = MC.CellSize * 0.5
    local t = GC.FloorThickness
    local stairHalf = GC.StairWidth * 0.5
    local dir = edge.LODStairDirection or fallbackDirection(edge)
    local ang = Angle(0, YAW[dir] or 0, 0)
    local crossoverDepth = math.min(REAR_CROSSOVER_DEPTH, half - 16)

    -- Wide left/right decks run the full cell length.
    self:_Register(spawnStaticBox(center + Vector(0, 0, -t * 0.5), ang,
        Vector(-half, stairHalf, -t * 0.5), Vector(half, half, t * 0.5), 1))
    self:_Register(spawnStaticBox(center + Vector(0, 0, -t * 0.5), ang,
        Vector(-half, -half, -t * 0.5), Vector(half, -stairHalf, t * 0.5), 1))

    -- Broad forward landing where the final tread reaches floor height.
    self:_Register(spawnStaticBox(center + Vector(0, 0, -t * 0.5), ang,
        Vector(0, -stairHalf, -t * 0.5), Vector(half, stairHalf, t * 0.5), 1))

    -- Broad rear landing/crossover. At this end of the upper cell the staircase
    -- is still far below the upper floor, so this deck safely bridges over it
    -- and provides a no-jump route between both side decks and the rear corridor.
    self:_Register(spawnStaticBox(center + Vector(0, 0, -t * 0.5), ang,
        Vector(-half, -stairHalf, -t * 0.5),
        Vector(-half + crossoverDepth, stairHalf, t * 0.5), 1))
end

local function registerRailSegment(self, center, ang, x0, x1, y0, y1, railHeight)
    if x1 <= x0 then return end
    self:_Register(spawnStaticBox(center + Vector(0, 0, MC.LevelHeight * 0.5), ang,
        Vector(x0, y0, -MC.LevelHeight * 0.5),
        Vector(x1, y1, MC.LevelHeight * 0.5 + railHeight), 3))
end

function MazeBuilder:_BuildStair(edge)
    local lower = lowerCell(edge)
    local transitionCenter = self:CellCenter(lower)
    local steps = GC.StairSteps
    local stairRun = GC.StairRun
    local tread = stairRun / steps
    local rise = MC.LevelHeight / steps
    local stairHalf = GC.StairWidth * 0.5
    local dir = edge.LODStairDirection or fallbackDirection(edge)
    local d = DIR_BY_NAME[dir]
    local ang = Angle(0, YAW[dir] or 0, 0)

    -- Local +X is uphill. The flight starts 320 units behind the transition
    -- cell center and reaches upper-floor height exactly at that center.
    local center = transitionCenter + Vector(
        d.dx * (-stairRun * 0.5),
        d.dy * (-stairRun * 0.5),
        0
    )

    for i = 1, steps do
        local x0 = -stairRun * 0.5 + (i - 1) * tread
        local x1 = x0 + tread + 0.5
        local top = i * rise
        self:_Register(spawnStaticBox(
            center,
            ang,
            Vector(x0, -stairHalf, 0),
            Vector(x1, stairHalf, top),
            2
        ))
    end

    local railHeight = 48
    local railThickness = 6

    -- Upper-cell rear edge and crossover forward edge expressed in stair-local X.
    -- The stair entity center is 160 units behind the transition-cell center.
    local upperRearX = stairRun * 0.5 - MC.CellSize * 0.5
    local crossoverForwardX = upperRearX + math.min(REAR_CROSSOVER_DEPTH, MC.CellSize * 0.5 - 16)

    -- Keep rails inside the stair envelope so they do not consume side-deck
    -- walking width. Split them around the rear crossover so the crossover is a
    -- genuinely open walking route rather than a deck bisected by railings.
    for _, side in ipairs({-1, 1}) do
        local y0, y1
        if side < 0 then
            y0, y1 = -stairHalf, -stairHalf + railThickness
        else
            y0, y1 = stairHalf - railThickness, stairHalf
        end

        registerRailSegment(self, center, ang,
            -stairRun * 0.5, upperRearX, y0, y1, railHeight)
        registerRailSegment(self, center, ang,
            crossoverForwardX, stairRun * 0.5, y0, y1, railHeight)
    end
end
