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

-- A mandatory staircase must not point its low end into a closed container wall.
-- Pick an actually open horizontal edge of the lower cell as the approach side,
-- with a deterministic rotated preference order so the same graph always builds
-- the same geometry. The ascent direction is opposite the approach side.
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

    -- This should be rare and is surfaced by the traversal diagnostics. Keeping
    -- a deterministic fallback prevents an uncontrolled geometry choice.
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

-- The upper-floor aperture only needs to surround the high end of the flight.
-- The staircase now starts in the graph-approved lower approach cell and ends
-- GC.StairTopOffset units inside this transition cell, leaving a true upper
-- landing between the final tread and the perimeter container wall.
function MazeBuilder:_BuildPerforatedFloor(cell, edge)
    local center = self:CellCenter(cell)
    local half = MC.CellSize * 0.5
    local t = GC.FloorThickness
    local stairHalf = GC.StairWidth * 0.5
    local holeHalf = GC.StairTopOffset or 64
    local dir = edge.LODStairDirection or fallbackDirection(edge)
    local yaw = (dir == "N" or dir == "S") and 90 or 0
    local ang = Angle(0, yaw, 0)

    self:_Register(spawnStaticBox(center + Vector(0, 0, -t * 0.5), ang,
        Vector(-half, stairHalf, -t * 0.5), Vector(half, half, t * 0.5), 1))
    self:_Register(spawnStaticBox(center + Vector(0, 0, -t * 0.5), ang,
        Vector(-half, -half, -t * 0.5), Vector(half, -stairHalf, t * 0.5), 1))
    self:_Register(spawnStaticBox(center + Vector(0, 0, -t * 0.5), ang,
        Vector(-half, -stairHalf, -t * 0.5), Vector(-holeHalf, stairHalf, t * 0.5), 1))
    self:_Register(spawnStaticBox(center + Vector(0, 0, -t * 0.5), ang,
        Vector(holeHalf, -stairHalf, -t * 0.5), Vector(half, stairHalf, t * 0.5), 1))
end

function MazeBuilder:_BuildStair(edge)
    local lower = lowerCell(edge)
    local transitionCenter = self:CellCenter(lower)
    local steps = GC.StairSteps
    local stairRun = GC.StairRun
    local tread = stairRun / steps
    local rise = MC.LevelHeight / steps
    local stairHalf = GC.StairWidth * 0.5
    local topOffset = GC.StairTopOffset or 64
    local dir = edge.LODStairDirection or fallbackDirection(edge)
    local d = DIR_BY_NAME[dir]
    local yaw = (dir == "N" or dir == "S") and 90 or 0
    local reverse = (dir == "W" or dir == "S")
    local ang = Angle(0, yaw, 0)

    -- Local stair geometry remains centered on its own flight. Shift that flight
    -- toward the open lower approach so its high end finishes at topOffset in
    -- the transition cell: low end = topOffset - StairRun, high end = topOffset.
    local midpointOffset = topOffset - stairRun * 0.5
    local center = transitionCenter + Vector(d.dx * midpointOffset, d.dy * midpointOffset, 0)

    for i = 1, steps do
        local logicalIndex = reverse and (steps - i + 1) or i
        local x0 = -stairRun * 0.5 + (logicalIndex - 1) * tread
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
    self:_Register(spawnStaticBox(center + Vector(0, 0, MC.LevelHeight * 0.5), ang,
        Vector(-stairRun * 0.5, stairHalf, -MC.LevelHeight * 0.5),
        Vector(stairRun * 0.5, stairHalf + railThickness, MC.LevelHeight * 0.5 + railHeight), 3))
    self:_Register(spawnStaticBox(center + Vector(0, 0, MC.LevelHeight * 0.5), ang,
        Vector(-stairRun * 0.5, -stairHalf - railThickness, -MC.LevelHeight * 0.5),
        Vector(stairRun * 0.5, -stairHalf, MC.LevelHeight * 0.5 + railHeight), 3))
end
