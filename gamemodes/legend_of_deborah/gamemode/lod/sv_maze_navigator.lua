LOD = LOD or {}
LOD.MazeNavigator = LOD.MazeNavigator or {}

local MazeNavigator = LOD.MazeNavigator
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local cellKey = LOD.MazeGenerator.CellKey

local DIR_VECTOR = {
    E = Vector(1, 0, 0),
    W = Vector(-1, 0, 0),
    N = Vector(0, 1, 0),
    S = Vector(0, -1, 0)
}

local function sortedKeys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end

local function edgeKeyFromKeys(a, b)
    if a < b then return a .. "|" .. b end
    return b .. "|" .. a
end

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

function MazeNavigator:EdgeKey(a, b)
    local ka = isstring(a) and a or keyOf(a)
    local kb = isstring(b) and b or keyOf(b)
    if not ka or not kb then return nil end
    return edgeKeyFromKeys(ka, kb)
end

function MazeNavigator:CellCenter(cell)
    return LOD.MazeBuilder:CellCenter(cell)
end

function MazeNavigator:WorldToCell(graph, pos)
    if not graph or not pos then return nil end

    local x = math.floor(((pos.x - MC.Origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local y = math.floor(((pos.y - MC.Origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local z = math.floor(((pos.z - MC.Origin.z) / MC.LevelHeight) + 0.5)

    x = math.Clamp(x, 1, MC.Width)
    y = math.Clamp(y, 1, MC.Height)
    z = math.Clamp(z, 0, math.max(0, (graph.Layers or 1) - 1))

    local direct = graph.Cells[cellKey(x, y, z)]
    if direct then return direct end

    -- Partial upper layers can leave the geometrically nearest grid coordinate
    -- unoccupied. Search a small deterministic neighborhood before falling back
    -- to a full nearest-cell scan.
    local best, bestDist
    for dz = -1, 1 do
        for dy = -2, 2 do
            for dx = -2, 2 do
                local candidate = graph.Cells[cellKey(x + dx, y + dy, z + dz)]
                if candidate then
                    local center = self:CellCenter(candidate)
                    local dist = center:DistToSqr(pos)
                    if not bestDist or dist < bestDist then
                        best, bestDist = candidate, dist
                    end
                end
            end
        end
    end
    if best then return best end

    for _, candidate in pairs(graph.Cells) do
        local center = self:CellCenter(candidate)
        local dist = center:DistToSqr(pos)
        if not bestDist or dist < bestDist then
            best, bestDist = candidate, dist
        end
    end
    return best
end

function MazeNavigator:_GateIndexForEdge(graph, aKey, bKey)
    local progression = graph and graph.Progression
    if not progression then return nil end
    local ek = edgeKeyFromKeys(aKey, bKey)
    for i, gate in ipairs(progression.Gates or {}) do
        if gate.edgeKey == ek then return i end
    end
    return nil
end

function MazeNavigator:CanTraverse(graph, aKey, bKey)
    local gateIndex = self:_GateIndexForEdge(graph, aKey, bKey)
    if not gateIndex then return true end
    local state = LOD.RunManager and LOD.RunManager.State
    return state and state.GatesOpen and state.GatesOpen[gateIndex] == true
end

function MazeNavigator:FindPath(graph, startCell, goalCell)
    if not graph or not startCell or not goalCell then return nil end
    local startKey = keyOf(startCell)
    local goalKey = keyOf(goalCell)
    if not graph.Cells[startKey] or not graph.Cells[goalKey] then return nil end
    if startKey == goalKey then return {graph.Cells[startKey]} end

    local queue = {startKey}
    local head = 1
    local visited = {[startKey] = true}
    local previous = {}

    while head <= #queue do
        local currentKey = queue[head]
        head = head + 1
        local current = graph.Cells[currentKey]
        for _, neighborKey in ipairs(sortedKeys(current.neighbors)) do
            if not visited[neighborKey] and self:CanTraverse(graph, currentKey, neighborKey) then
                visited[neighborKey] = true
                previous[neighborKey] = currentKey
                if neighborKey == goalKey then
                    local reverse = {goalKey}
                    local cursor = goalKey
                    while cursor ~= startKey do
                        cursor = previous[cursor]
                        if not cursor then return nil end
                        reverse[#reverse + 1] = cursor
                    end
                    local path = {}
                    for i = #reverse, 1, -1 do path[#path + 1] = graph.Cells[reverse[i]] end
                    return path
                end
                queue[#queue + 1] = neighborKey
            end
        end
    end

    return nil
end

function MazeNavigator:Distance(graph, startCell, goalCell)
    local path = self:FindPath(graph, startCell, goalCell)
    return path and math.max(0, #path - 1) or math.huge
end

function MazeNavigator:_VerticalEdge(graph, a, b)
    local wanted = self:EdgeKey(a, b)
    if not wanted then return nil end
    graph.LODVerticalEdgeByKey = graph.LODVerticalEdgeByKey or {}
    if not graph.LODVerticalEdgeIndexBuilt then
        for _, edge in ipairs(graph.VerticalEdges or {}) do
            graph.LODVerticalEdgeByKey[self:EdgeKey(edge.a, edge.b)] = edge
        end
        graph.LODVerticalEdgeIndexBuilt = true
    end
    return graph.LODVerticalEdgeByKey[wanted]
end

local function append(out, pos, tolerance, stair)
    out[#out + 1] = {
        pos = pos,
        tolerance = tolerance or 34,
        stair = stair == true
    }
end

function MazeNavigator:_AppendVerticalWaypoints(graph, fromCell, toCell, out)
    local edge = self:_VerticalEdge(graph, fromCell, toCell)
    local lower = fromCell.z < toCell.z and fromCell or toCell
    local ascending = toCell.z > fromCell.z
    local dirName = edge and edge.LODStairDirection or "E"
    local dir = DIR_VECTOR[dirName] or DIR_VECTOR.E
    local lowerCenter = self:CellCenter(lower)
    local run = GC.StairRun
    local totalRise = MC.LevelHeight
    local steps = math.max(1, GC.StairSteps or 24)
    local tread = run / steps
    local rise = totalRise / steps

    -- The generated stair is a stack of 24 physical box treads. Routing to a
    -- coarse point inside that volume makes locomotion fight the first riser.
    -- Instead, target the CENTER/TOP of every physical tread, exactly matching
    -- sv_m1_stair_geometry.lua. A short floor approach and upper landing keep
    -- the hostile centered before entering and after leaving the flight.
    local approach = lowerCenter - dir * (run + 40) + Vector(0, 0, 8)
    local upperLanding = lowerCenter + dir * 52 + Vector(0, 0, totalRise + 8)

    local function treadPoint(i)
        local along = -run + (i - 0.5) * tread
        return lowerCenter + dir * along + Vector(0, 0, i * rise + 3)
    end

    if ascending then
        append(out, approach, 34, true)
        for i = 1, steps do
            append(out, treadPoint(i), 22, true)
        end
        append(out, upperLanding, 36, true)
    else
        append(out, upperLanding, 36, true)
        for i = steps, 1, -1 do
            append(out, treadPoint(i), 22, true)
        end
        append(out, approach, 36, true)
    end
end

function MazeNavigator:PathToWaypoints(graph, path)
    local out = {}
    if not graph or not path or #path <= 1 then return out end

    for i = 2, #path do
        local previous = path[i - 1]
        local current = path[i]
        if previous.z ~= current.z then
            self:_AppendVerticalWaypoints(graph, previous, current, out)
        else
            -- If the next graph edge rises vertically, do not drive the enemy
            -- underneath the stair's top tread at the lower cell center. The
            -- vertical waypoint sequence deliberately routes through the actual
            -- tread centers instead.
            local nextCell = path[i + 1]
            local leadsUp = nextCell and current.z < nextCell.z and current.x == nextCell.x and current.y == nextCell.y
            if not leadsUp then
                append(out, self:CellCenter(current) + Vector(0, 0, 8), 44, false)
            end
        end
    end

    return out
end
