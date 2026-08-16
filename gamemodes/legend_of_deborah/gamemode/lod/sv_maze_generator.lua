LOD = LOD or {}
LOD.MazeGenerator = LOD.MazeGenerator or {}

local MazeGenerator = LOD.MazeGenerator
local MC = LOD.Config.Maze

local DIRS = {
    {dx = 1, dy = 0, dz = 0, name = "E"},
    {dx = -1, dy = 0, dz = 0, name = "W"},
    {dx = 0, dy = 1, dz = 0, name = "N"},
    {dx = 0, dy = -1, dz = 0, name = "S"}
}

local function key(x, y, z)
    return x .. ":" .. y .. ":" .. z
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    return keys
end

local function copyCell(cell)
    return {x = cell.x, y = cell.y, z = cell.z}
end

local function edgeKey(a, b)
    local ka = key(a.x, a.y, a.z)
    local kb = key(b.x, b.y, b.z)
    if ka < kb then return ka .. "|" .. kb end
    return kb .. "|" .. ka
end

local function adjacent(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z) == 1
end

local function makeUnion(keys)
    local parent = {}
    local rank = {}
    for _, k in ipairs(keys) do
        parent[k] = k
        rank[k] = 0
    end

    local function find(k)
        local p = parent[k]
        if p ~= k then
            parent[k] = find(p)
        end
        return parent[k]
    end

    local function union(a, b)
        local ra, rb = find(a), find(b)
        if ra == rb then return false end
        if rank[ra] < rank[rb] then
            parent[ra] = rb
        elseif rank[ra] > rank[rb] then
            parent[rb] = ra
        else
            parent[rb] = ra
            rank[ra] = rank[ra] + 1
        end
        return true
    end

    return find, union
end

local function addNeighbor(graph, a, b)
    local ka = key(a.x, a.y, a.z)
    local kb = key(b.x, b.y, b.z)
    graph.Cells[ka].neighbors[kb] = true
    graph.Cells[kb].neighbors[ka] = true
    graph.Edges[edgeKey(a, b)] = {a = copyCell(a), b = copyCell(b)}
end

local function addSpineCell(spine, x, y, z)
    local nextCell = {x = x, y = y, z = z}
    local prev = spine[#spine]
    if prev and prev.x == x and prev.y == y and prev.z == z then return end
    if prev and not adjacent(prev, nextCell) then
        error("LOD spine attempted non-adjacent step")
    end
    spine[#spine + 1] = nextCell
end

local function layerSequence(layerCount, transitionCount)
    local seq = {0}
    local z = 0
    local direction = 1
    for _ = 1, transitionCount do
        z = z + direction
        if z >= layerCount - 1 then
            z = layerCount - 1
            direction = -1
        elseif z <= 0 then
            z = 0
            direction = 1
        end
        seq[#seq + 1] = z
    end
    return seq
end

function MazeGenerator:_BuildSpine(rng, layerCount, transitionCount)
    local spine = {}
    local vertical = {}
    local seq = layerSequence(layerCount, transitionCount)
    local currentX = 1
    local currentY = rng:Int(4, MC.Height - 3)
    local currentZ = seq[1]
    addSpineCell(spine, currentX, currentY, currentZ)

    for transitionIndex = 1, transitionCount do
        local anchorX = math.floor(1 + transitionIndex * (MC.Width - 1) / (transitionCount + 1))
        anchorX = math.max(currentX + 1, math.min(MC.Width - 1, anchorX))
        local targetY = rng:Int(3, MC.Height - 2)

        while currentY ~= targetY do
            currentY = currentY + (targetY > currentY and 1 or -1)
            addSpineCell(spine, currentX, currentY, currentZ)
        end
        while currentX < anchorX do
            currentX = currentX + 1
            addSpineCell(spine, currentX, currentY, currentZ)
        end

        local before = copyCell(spine[#spine])
        currentZ = seq[transitionIndex + 1]
        addSpineCell(spine, currentX, currentY, currentZ)
        local after = copyCell(spine[#spine])
        vertical[#vertical + 1] = {a = before, b = after}
    end

    local finalY = rng:Int(4, MC.Height - 3)
    while currentY ~= finalY do
        currentY = currentY + (finalY > currentY and 1 or -1)
        addSpineCell(spine, currentX, currentY, currentZ)
    end
    while currentX < MC.Width do
        currentX = currentX + 1
        addSpineCell(spine, currentX, currentY, currentZ)
    end

    return spine, vertical
end

local function chooseLayerCount(rng)
    if rng:Chance(MC.RareFourthLayerChance) then return 4 end
    return rng:Chance(0.52) and 2 or 3
end

function MazeGenerator:_FillOccupancy(rng, spine, layerCount)
    local occupied = {}
    local perLayer = {}

    for z = 0, layerCount - 1 do
        perLayer[z] = {}
    end

    local function occupy(x, y, z)
        local k = key(x, y, z)
        if occupied[k] then return false end
        occupied[k] = {x = x, y = y, z = z}
        perLayer[z][k] = occupied[k]
        return true
    end

    for _, cell in ipairs(spine) do
        occupy(cell.x, cell.y, cell.z)
    end

    local total2D = MC.Width * MC.Height
    local targets = {}
    for z = 0, layerCount - 1 do
        local range = MC.LayerOccupancy[z + 1]
        targets[z] = math.floor(total2D * rng:Float(range[1], range[2]) + 0.5)
        local current = table.Count(perLayer[z])
        targets[z] = math.max(targets[z], current)
    end

    for z = 0, layerCount - 1 do
        local frontier = {}
        local frontierSet = {}
        local function offer(x, y)
            if x < 1 or x > MC.Width or y < 1 or y > MC.Height then return end
            local k = key(x, y, z)
            if occupied[k] or frontierSet[k] then return end
            frontierSet[k] = true
            frontier[#frontier + 1] = {x = x, y = y, z = z}
        end
        local function offerAround(cell)
            for _, d in ipairs(DIRS) do
                offer(cell.x + d.dx, cell.y + d.dy)
            end
        end

        for _, cellKeyValue in ipairs(sortedKeys(perLayer[z])) do
            offerAround(perLayer[z][cellKeyValue])
        end

        local count = table.Count(perLayer[z])
        while count < targets[z] and #frontier > 0 do
            local index = rng:Int(1, #frontier)
            local chosen = frontier[index]
            frontier[index] = frontier[#frontier]
            frontier[#frontier] = nil
            frontierSet[key(chosen.x, chosen.y, z)] = nil
            if occupy(chosen.x, chosen.y, z) then
                count = count + 1
                offerAround(chosen)
            end
        end
    end

    return occupied, targets
end

function MazeGenerator:_BuildGraph(rng, occupied, spine, verticalEdges, layerCount, levelSeed, attempt)
    local graph = {
        Width = MC.Width,
        Height = MC.Height,
        Layers = layerCount,
        LevelSeed = levelSeed,
        Attempt = attempt,
        Cells = {},
        Edges = {},
        VerticalEdges = {},
        Spine = spine,
        Start = copyCell(spine[1]),
        Goal = copyCell(spine[#spine]),
        Validation = {}
    }

    local allKeys = sortedKeys(occupied)
    for _, k in ipairs(allKeys) do
        local cell = occupied[k]
        graph.Cells[k] = {x = cell.x, y = cell.y, z = cell.z, neighbors = {}}
    end

    local find, union = makeUnion(allKeys)
    local spineEdgeSet = {}

    for i = 1, #spine - 1 do
        local a, b = spine[i], spine[i + 1]
        local ek = edgeKey(a, b)
        if not spineEdgeSet[ek] then
            spineEdgeSet[ek] = true
            addNeighbor(graph, a, b)
            union(key(a.x, a.y, a.z), key(b.x, b.y, b.z))
        end
    end

    for _, e in ipairs(verticalEdges) do
        graph.VerticalEdges[#graph.VerticalEdges + 1] = {a = copyCell(e.a), b = copyCell(e.b)}
    end

    local candidates = {}
    local candidateSet = {}
    for _, occupiedKey in ipairs(allKeys) do
        local cell = occupied[occupiedKey]
        for _, d in ipairs(DIRS) do
            local nx, ny = cell.x + d.dx, cell.y + d.dy
            local nk = key(nx, ny, cell.z)
            if occupied[nk] then
                local other = occupied[nk]
                local ek = edgeKey(cell, other)
                if not spineEdgeSet[ek] and not candidateSet[ek] then
                    candidateSet[ek] = true
                    candidates[#candidates + 1] = {a = copyCell(cell), b = copyCell(other)}
                end
            end
        end
    end

    rng:Shuffle(candidates)
    for _, e in ipairs(candidates) do
        local ka = key(e.a.x, e.a.y, e.a.z)
        local kb = key(e.b.x, e.b.y, e.b.z)
        if find(ka) ~= find(kb) then
            addNeighbor(graph, e.a, e.b)
            union(ka, kb)
        end
    end

    local closed = {}
    for _, e in ipairs(candidates) do
        if not graph.Edges[edgeKey(e.a, e.b)] then
            closed[#closed + 1] = e
        end
    end
    rng:Shuffle(closed)
    local loopFraction = rng:Float(MC.LoopFractionMin, MC.LoopFractionMax)
    local loopCount = math.floor(#closed * loopFraction + 0.5)
    for i = 1, math.min(loopCount, #closed) do
        addNeighbor(graph, closed[i].a, closed[i].b)
    end

    return graph
end

local function bfs(graph, startCell)
    local startKey = key(startCell.x, startCell.y, startCell.z)
    local queue = {startKey}
    local head = 1
    local distance = {[startKey] = 0}
    local previous = {}

    while head <= #queue do
        local current = queue[head]
        head = head + 1
        local cell = graph.Cells[current]
        for _, nk in ipairs(sortedKeys(cell.neighbors)) do
            if distance[nk] == nil then
                distance[nk] = distance[current] + 1
                previous[nk] = current
                queue[#queue + 1] = nk
            end
        end
    end
    return distance, previous
end

local function reconstructPath(graph, previous, startCell, goalCell)
    local startKey = key(startCell.x, startCell.y, startCell.z)
    local goalKey = key(goalCell.x, goalCell.y, goalCell.z)
    if startKey == goalKey then return {graph.Cells[startKey]} end
    if not previous[goalKey] then return nil end
    local reverse = {}
    local cursor = goalKey
    while cursor do
        reverse[#reverse + 1] = graph.Cells[cursor]
        if cursor == startKey then break end
        cursor = previous[cursor]
    end
    local path = {}
    for i = #reverse, 1, -1 do path[#path + 1] = reverse[i] end
    return path
end

function MazeGenerator:Validate(graph)
    local errors = {}
    local distances, previous = bfs(graph, graph.Start)
    local cellCount = table.Count(graph.Cells)
    local reachableCount = table.Count(distances)
    if reachableCount ~= cellCount then
        errors[#errors + 1] = "isolated playable cells"
    end

    local path = reconstructPath(graph, previous, graph.Start, graph.Goal)
    if not path then
        errors[#errors + 1] = "goal unreachable"
    end

    local verticalCount = 0
    if path then
        for i = 1, #path - 1 do
            if path[i].z ~= path[i + 1].z then verticalCount = verticalCount + 1 end
        end
    end
    if verticalCount < MC.MandatoryVerticalMin then
        errors[#errors + 1] = "critical route has only " .. verticalCount .. " vertical transitions"
    end

    for _, e in pairs(graph.Edges) do
        if not adjacent(e.a, e.b) then
            errors[#errors + 1] = "non-adjacent graph edge"
            break
        end
    end

    local occupancy = {}
    for z = 0, graph.Layers - 1 do occupancy[z] = 0 end
    for _, cell in pairs(graph.Cells) do occupancy[cell.z] = occupancy[cell.z] + 1 end

    graph.CriticalPath = path or {}
    graph.Validation = {
        valid = #errors == 0,
        errors = errors,
        cellCount = cellCount,
        reachableCount = reachableCount,
        criticalPathLength = path and #path or 0,
        criticalVerticalTransitions = verticalCount,
        occupancy = occupancy
    }
    return graph.Validation.valid, graph.Validation
end

function MazeGenerator:Generate(levelSeed)
    levelSeed = LOD.Seeds.Normalize(levelSeed)

    for attempt = 1, MC.GenerationAttempts do
        local attemptSeed = LOD.Seeds.Derive(levelSeed, "maze-attempt:" .. attempt)
        local rootRng = LOD.RNG.New(attemptSeed)
        local structureRng = rootRng:Derive("structure")
        local occupancyRng = rootRng:Derive("occupancy")
        local edgeRng = rootRng:Derive("edges")

        local layerCount = chooseLayerCount(structureRng)
        local transitionCount = structureRng:Int(MC.MandatoryVerticalMin, MC.MandatoryVerticalMax)
        local spine, verticalEdges = self:_BuildSpine(structureRng, layerCount, transitionCount)
        local occupied = self:_FillOccupancy(occupancyRng, spine, layerCount)
        local graph = self:_BuildGraph(edgeRng, occupied, spine, verticalEdges, layerCount, levelSeed, attempt)
        local valid = self:Validate(graph)
        if valid then
            graph.AttemptSeed = attemptSeed
            return graph
        end
    end

    return nil, "failed to generate a valid maze after " .. MC.GenerationAttempts .. " deterministic attempts"
end

function MazeGenerator.CellKey(x, y, z)
    return key(x, y, z)
end
