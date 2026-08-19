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

local function sortedNumericKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return a < b end)
    return keys
end

local function edgeKeyFromKeys(a, b)
    if a < b then return a .. "|" .. b end
    return b .. "|" .. a
end

local function spawnWallBox(pos, mins, maxs)
    local ent = ents.Create("lod_static_box")
    if not IsValid(ent) then return nil end
    ent:SetPos(pos)
    ent:SetAngles(angle_zero)
    ent:SetBoxMins(mins)
    ent:SetBoxMaxs(maxs)
    ent:SetBoxKind(4) -- invisible merged wall collision / anti-bypass blocker
    ent:Spawn()
    ent:Activate()
    if ent.IsLODCollisionReady and not ent:IsLODCollisionReady() then
        ent:Remove()
        return nil
    end
    return ent
end

-- Override the Milestone-1 foundation's prop_physics container creation. The
-- first live gm_flatgrass attempt crashed before an audit could run; spawning
-- ~1,500 independent VPhysics cargo containers is a credible PhysCollide-pressure
-- source. Container models remain real server-networked visuals, but they own no
-- physics object. Merged wall boxes below are authoritative for collision.
function MazeBuilder:_SpawnContainer(pos, ang)
    local ent = ents.Create("lod_container_visual")
    if not IsValid(ent) then return nil end
    ent:SetModel(GC.ContainerModel)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:SetSkin(GC.Skin)
    ent:Spawn()
    ent:Activate()
    return ent
end

-- The canonical undirected graph edge table is the sole authority for whether
-- a horizontal boundary is open. Do not infer geometry independently from one
-- endpoint's neighbor table: if a future regression ever creates an asymmetric
-- neighbor relation, using graph.Edges prevents the wall builder from creating
-- a physical wall across an otherwise canonical open edge.
local function hasOpenEdge(graph, cell, nx, ny, nz)
    local ck = cellKey(cell.x, cell.y, cell.z)
    local nk = cellKey(nx, ny, nz)
    if not graph.Cells[nk] then return false end
    return graph.Edges and graph.Edges[edgeKeyFromKeys(ck, nk)] ~= nil
end

local function logicalX(index)
    return (index - (MC.Width + 1) / 2) * MC.CellSize
end

local function logicalY(index)
    return (index - (MC.Height + 1) / 2) * MC.CellSize
end

local function addGroup(groups, axis, cell, d)
    local fixed2
    local index
    if axis == "x" then
        fixed2 = cell.y * 2 + d.dy
        index = cell.x
    else
        fixed2 = cell.x * 2 + d.dx
        index = cell.y
    end

    local groupKey = string.format("%d:%s:%d", cell.z, axis, fixed2)
    local group = groups[groupKey]
    if not group then
        group = {axis = axis, z = cell.z, fixed2 = fixed2, indices = {}}
        groups[groupKey] = group
    end
    group.indices[index] = true
end

function MazeBuilder:_SpawnMergedWallRun(group, firstIndex, lastIndex)
    local count = lastIndex - firstIndex + 1
    local halfLength = count * MC.CellSize * 0.5
    local halfThickness = GC.ContainerWidth * 0.5
    local visibleWallHeight = GC.ContainerHeight * GC.WallStack
    local collisionHeight = math.max(visibleWallHeight, GC.AntiBypassHeight or MC.LevelHeight)
    local halfHeight = collisionHeight * 0.5
    local fixed = group.fixed2 * 0.5
    local pos
    local mins
    local maxs

    if group.axis == "x" then
        local centerX = (logicalX(firstIndex) + logicalX(lastIndex)) * 0.5
        pos = MC.Origin + Vector(centerX, logicalY(fixed), group.z * MC.LevelHeight + halfHeight)
        mins = Vector(-halfLength, -halfThickness, -halfHeight)
        maxs = Vector(halfLength, halfThickness, halfHeight)
    else
        local centerY = (logicalY(firstIndex) + logicalY(lastIndex)) * 0.5
        pos = MC.Origin + Vector(logicalX(fixed), centerY, group.z * MC.LevelHeight + halfHeight)
        mins = Vector(-halfThickness, -halfLength, -halfHeight)
        maxs = Vector(halfThickness, halfLength, halfHeight)
    end

    self:_Register(spawnWallBox(pos, mins, maxs))
end

function MazeBuilder:_BuildMergedWallCollision(groups)
    for _, groupKey in ipairs(sortedKeys(groups)) do
        local group = groups[groupKey]
        local indices = sortedNumericKeys(group.indices)
        local firstIndex
        local previous

        for _, index in ipairs(indices) do
            if not firstIndex then
                firstIndex = index
                previous = index
            elseif index == previous + 1 then
                previous = index
            else
                self:_SpawnMergedWallRun(group, firstIndex, previous)
                firstIndex = index
                previous = index
            end
        end

        if firstIndex then
            self:_SpawnMergedWallRun(group, firstIndex, previous)
        end
    end
end

function MazeBuilder:_BuildWalls(graph)
    local seen = {}
    local groups = {}
    local visualSegments = {}

    for _, keyValue in ipairs(sortedKeys(graph.Cells)) do
        local cell = graph.Cells[keyValue]
        local center = self:CellCenter(cell)

        for _, d in ipairs(DIRS) do
            local nx, ny, nz = cell.x + d.dx, cell.y + d.dy, cell.z
            if not hasOpenEdge(graph, cell, nx, ny, nz) then
                local a = cellKey(cell.x, cell.y, cell.z)
                local b = cellKey(nx, ny, nz)
                local wallKey = edgeKeyFromKeys(a, b)
                if not seen[wallKey] then
                    seen[wallKey] = true
                    visualSegments[#visualSegments + 1] = {
                        pos = center + Vector(d.dx * MC.CellSize * 0.5, d.dy * MC.CellSize * 0.5, 0),
                        yaw = d.yaw
                    }
                    addGroup(groups, (d.name == "N" or d.name == "S") and "x" or "y", cell, d)
                end
            end
        end
    end

    self:_BuildMergedWallCollision(groups)
    if self.BuildFailures > 0 then return end

    for _, segment in ipairs(visualSegments) do
        for stack = 0, GC.WallStack - 1 do
            local z = GC.ContainerHeight * 0.5 + stack * GC.ContainerHeight
            self:_Register(self:_SpawnContainer(segment.pos + Vector(0, 0, z), Angle(0, segment.yaw, 0)))
        end
    end
end
