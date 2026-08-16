LOD = LOD or {}
LOD.MazeBuilder = LOD.MazeBuilder or {}

local MazeBuilder = LOD.MazeBuilder
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local cellKey = LOD.MazeGenerator.CellKey

local DIRS = {
    {name = "N", dx = 0, dy = 1, yaw = 90},
    {name = "E", dx = 1, dy = 0, yaw = 0},
    {name = "S", dx = 0, dy = -1, yaw = 90},
    {name = "W", dx = -1, dy = 0, yaw = 0}
}

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    return keys
end

function MazeBuilder:CellCenter(cell)
    local ox = (cell.x - (MC.Width + 1) / 2) * MC.CellSize
    local oy = (cell.y - (MC.Height + 1) / 2) * MC.CellSize
    local oz = cell.z * MC.LevelHeight
    return MC.Origin + Vector(ox, oy, oz)
end

local function spawnBox(pos, ang, mins, maxs, kind)
    local ent = ents.Create("lod_static_box")
    if not IsValid(ent) then return nil end
    ent:SetPos(pos)
    ent:SetAngles(ang or angle_zero)
    ent:SetBoxMins(mins)
    ent:SetBoxMaxs(maxs)
    ent:SetBoxKind(kind or 1)
    ent:Spawn()
    ent:Activate()
    return ent
end

function MazeBuilder:_SpawnContainer(pos, ang)
    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return nil end
    ent:SetModel(GC.ContainerModel)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:SetSkin(GC.Skin)
    ent:Spawn()
    ent:Activate()
    ent:SetMoveType(MOVETYPE_VPHYSICS)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end
    return ent
end

function MazeBuilder:_Register(ent)
    if IsValid(ent) then
        self.Entities[#self.Entities + 1] = ent
    end
    return ent
end

function MazeBuilder:Cleanup()
    if not self.Entities then self.Entities = {} return end
    for _, ent in ipairs(self.Entities) do
        if IsValid(ent) then ent:Remove() end
    end
    self.Entities = {}
end

local function hasOpenEdge(graph, cell, nx, ny, nz)
    local ck = cellKey(cell.x, cell.y, cell.z)
    local nk = cellKey(nx, ny, nz)
    local c = graph.Cells[ck]
    return c and c.neighbors[nk] == true
end

function MazeBuilder:_BuildWalls(graph)
    local seen = {}
    for _, keyValue in ipairs(sortedKeys(graph.Cells)) do
        local cell = graph.Cells[keyValue]
        local center = self:CellCenter(cell)
        for _, d in ipairs(DIRS) do
            local nx, ny, nz = cell.x + d.dx, cell.y + d.dy, cell.z
            if not hasOpenEdge(graph, cell, nx, ny, nz) then
                local a = cellKey(cell.x, cell.y, cell.z)
                local b = cellKey(nx, ny, nz)
                local wallKey = a < b and (a .. "|" .. b) or (b .. "|" .. a)
                if not seen[wallKey] then
                    seen[wallKey] = true
                    local edgeOffset = Vector(d.dx * MC.CellSize * 0.5, d.dy * MC.CellSize * 0.5, 0)
                    for stack = 0, GC.WallStack - 1 do
                        local z = GC.ContainerHeight * 0.5 + stack * GC.ContainerHeight
                        self:_Register(self:_SpawnContainer(center + edgeOffset + Vector(0, 0, z), Angle(0, d.yaw, 0)))
                    end
                end
            end
        end
    end
end

local function transitionDirection(edge)
    local n = (edge.a.x * 17 + edge.a.y * 31 + edge.a.z * 13) % 4
    return ({"E", "N", "W", "S"})[n + 1]
end

local function isUpperTransitionCell(graph, cell)
    for _, edge in ipairs(graph.VerticalEdges) do
        local upper = edge.a.z > edge.b.z and edge.a or edge.b
        if upper.x == cell.x and upper.y == cell.y and upper.z == cell.z then
            return edge
        end
    end
    return nil
end

function MazeBuilder:_BuildFullFloor(cell)
    local center = self:CellCenter(cell)
    local half = MC.CellSize * 0.5
    local t = GC.FloorThickness
    self:_Register(spawnBox(
        center + Vector(0, 0, -t * 0.5),
        angle_zero,
        Vector(-half, -half, -t * 0.5),
        Vector(half, half, t * 0.5),
        1
    ))
end

function MazeBuilder:_BuildPerforatedFloor(cell, edge)
    local center = self:CellCenter(cell)
    local half = MC.CellSize * 0.5
    local t = GC.FloorThickness
    local stairHalf = GC.StairWidth * 0.5
    local runHalf = GC.StairRun * 0.5

    -- The aperture is centered rather than reaching a cell edge. Cargo-container
    -- walls occupy the cell perimeter; keeping end landings inside that perimeter
    -- prevents a valid vertical transition from being blocked by a closed wall.
    self:_Register(spawnBox(center + Vector(0, 0, -t * 0.5), angle_zero,
        Vector(-half, stairHalf, -t * 0.5), Vector(half, half, t * 0.5), 1))
    self:_Register(spawnBox(center + Vector(0, 0, -t * 0.5), angle_zero,
        Vector(-half, -half, -t * 0.5), Vector(half, -stairHalf, t * 0.5), 1))
    self:_Register(spawnBox(center + Vector(0, 0, -t * 0.5), angle_zero,
        Vector(-half, -stairHalf, -t * 0.5), Vector(-runHalf, stairHalf, t * 0.5), 1))
    self:_Register(spawnBox(center + Vector(0, 0, -t * 0.5), angle_zero,
        Vector(runHalf, -stairHalf, -t * 0.5), Vector(half, stairHalf, t * 0.5), 1))
end

function MazeBuilder:_BuildFloors(graph)
    for _, keyValue in ipairs(sortedKeys(graph.Cells)) do
        local cell = graph.Cells[keyValue]
        if cell.z > 0 then
            local transition = isUpperTransitionCell(graph, cell)
            if transition then
                self:_BuildPerforatedFloor(cell, transition)
            else
                self:_BuildFullFloor(cell)
            end
        end
    end
end

function MazeBuilder:_BuildStair(edge)
    local lower = edge.a.z < edge.b.z and edge.a or edge.b
    local upper = edge.a.z > edge.b.z and edge.a or edge.b
    local center = self:CellCenter(lower)
    local steps = GC.StairSteps
    local stairRun = GC.StairRun
    local run = stairRun / steps
    local rise = MC.LevelHeight / steps
    local stairHalf = GC.StairWidth * 0.5
    local dir = transitionDirection(edge)
    local yaw = (dir == "N" or dir == "S") and 90 or 0
    local reverse = (dir == "W" or dir == "S")
    local ang = Angle(0, yaw, 0)

    for i = 1, steps do
        local logicalIndex = reverse and (steps - i + 1) or i
        local x0 = -stairRun * 0.5 + (logicalIndex - 1) * run
        local x1 = x0 + run + 1
        local top = i * rise
        local mins = Vector(x0, -stairHalf, 0)
        local maxs = Vector(x1, stairHalf, top)
        self:_Register(spawnBox(center, ang, mins, maxs, 2))
    end

    -- Thin railings constrain accidental side-falls without blocking the run.
    local railHeight = 48
    local railThickness = 6
    self:_Register(spawnBox(center + Vector(0, 0, MC.LevelHeight * 0.5), ang,
        Vector(-stairRun * 0.5, stairHalf, -MC.LevelHeight * 0.5),
        Vector(stairRun * 0.5, stairHalf + railThickness, MC.LevelHeight * 0.5 + railHeight), 3))
    self:_Register(spawnBox(center + Vector(0, 0, MC.LevelHeight * 0.5), ang,
        Vector(-stairRun * 0.5, -stairHalf - railThickness, -MC.LevelHeight * 0.5),
        Vector(stairRun * 0.5, -stairHalf, MC.LevelHeight * 0.5 + railHeight), 3))
end

function MazeBuilder:_BuildVerticalTransitions(graph)
    for _, edge in ipairs(graph.VerticalEdges) do
        self:_BuildStair(edge)
    end
end

function MazeBuilder:Build(graph)
    self:Cleanup()
    self.Entities = {}

    if not util.IsValidProp(GC.ContainerModel) then
        return false, "configured cargo container is not a valid physics prop: " .. GC.ContainerModel
    end

    self:_BuildFloors(graph)
    self:_BuildWalls(graph)
    self:_BuildVerticalTransitions(graph)

    return true, {
        entityCount = #self.Entities,
        startPos = self:CellCenter(graph.Start) + Vector(0, 0, 12),
        goalPos = self:CellCenter(graph.Goal) + Vector(0, 0, 12)
    }
end
