LOD = LOD or {}
LOD.MinimapServer = LOD.MinimapServer or {}

local Minimap = LOD.MinimapServer
local MC = LOD.Config.Maze
local CHUNK_SIZE = 128

-- The minimap must consume the exact same canonical undirected graph-edge table
-- as physical wall construction. cell.neighbors remains useful for routing, but
-- it is no longer independently trusted when serializing visible map openings.
local DIRS = {
    {dx = 0, dy = 1, dz = 0, bit = 0, gateShift = 0}, -- N
    {dx = 1, dy = 0, dz = 0, bit = 1, gateShift = 2}, -- E
    {dx = 0, dy = -1, dz = 0, bit = 2, gateShift = 4}, -- S
    {dx = -1, dy = 0, dz = 0, bit = 3, gateShift = 6}, -- W
    {dx = 0, dy = 0, dz = 1, bit = 4},                 -- UP
    {dx = 0, dy = 0, dz = -1, bit = 5}                 -- DOWN
}

local function key(x, y, z)
    return LOD.MazeGenerator.CellKey(x, y, z)
end

local function edgeKey(a, b)
    if LOD.MazeNavigator and LOD.MazeNavigator.EdgeKey then
        return LOD.MazeNavigator:EdgeKey(a, b)
    end
    return a < b and (a .. "|" .. b) or (b .. "|" .. a)
end

local function writeCell(cell)
    net.WriteUInt(math.Clamp(cell.x or 0, 0, 127), 7)
    net.WriteUInt(math.Clamp(cell.y or 0, 0, 127), 7)
    net.WriteUInt(math.Clamp(cell.z or 0, 0, 7), 3)
end

local function gateIndexByEdge(graph)
    local out = {}
    local progression = graph and graph.Progression
    for index, gate in ipairs(progression and progression.Gates or {}) do
        if gate.edgeKey then out[gate.edgeKey] = index end
    end
    return out
end

local function encodeCanonicalCells(graph)
    local cells = {}
    local gates = gateIndexByEdge(graph)

    for cellKey, cell in pairs(graph.Cells or {}) do
        local openings = 0
        local gateCodes = 0

        for _, dir in ipairs(DIRS) do
            local neighborKey = key(cell.x + dir.dx, cell.y + dir.dy, cell.z + dir.dz)
            local neighbor = graph.Cells[neighborKey]
            local ek = neighbor and edgeKey(cellKey, neighborKey) or nil
            local open = ek and graph.Edges and graph.Edges[ek] ~= nil

            if open then
                openings = bit.bor(openings, bit.lshift(1, dir.bit))
                if dir.gateShift then
                    local gateIndex = gates[ek] or 0
                    if gateIndex > 0 then
                        gateCodes = bit.bor(gateCodes,
                            bit.lshift(math.Clamp(gateIndex, 0, 3), dir.gateShift))
                    end
                end
            end
        end

        cells[#cells + 1] = {
            x = cell.x,
            y = cell.y,
            z = cell.z,
            openings = openings,
            gates = gateCodes
        }
    end

    table.sort(cells, function(a, b)
        if a.z ~= b.z then return a.z < b.z end
        if a.y ~= b.y then return a.y < b.y end
        return a.x < b.x
    end)
    return cells
end

local function cachedCanonicalCells(state, graph)
    if Minimap.EncodedGraph == graph and Minimap.EncodedLevel == state.Level and Minimap.EncodedCells then
        Minimap.EncodeCacheHits = (Minimap.EncodeCacheHits or 0) + 1
        return Minimap.EncodedCells, Minimap.EncodedChunks
    end

    local cells = encodeCanonicalCells(graph)
    local chunks = math.max(1, math.ceil(#cells / CHUNK_SIZE))
    Minimap.EncodedGraph = graph
    Minimap.EncodedLevel = state.Level
    Minimap.EncodedCells = cells
    Minimap.EncodedChunks = chunks
    Minimap.EncodeBuilds = (Minimap.EncodeBuilds or 0) + 1
    return cells, chunks
end

function Minimap:Send(ply)
    if not self:CanUse(ply) then
        net.Start("LOD_MapDenied")
        net.WriteString("NO MAP — FIND ONE")
        net.Send(ply)
        return false
    end

    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not state or not graph or not state.BuildReady then
        net.Start("LOD_MapDenied")
        net.WriteString("MAP UNAVAILABLE WHILE LABYRINTH BUILDS")
        net.Send(ply)
        return false
    end

    -- MazeBuilder resolves the real Flatgrass floor at runtime and mutates the
    -- server-side maze origin. The shared client config still contains its load-
    -- time origin unless we explicitly synchronize it; without this, a client can
    -- keep rendering Floor 1 while physically standing on another generated floor.
    ply:SetNW2Float("LOD_MazeOriginX", MC.Origin.x)
    ply:SetNW2Float("LOD_MazeOriginY", MC.Origin.y)
    ply:SetNW2Float("LOD_MazeOriginZ", MC.Origin.z)
    ply:SetNW2Bool("LOD_MazeOriginValid", true)

    local cells, chunks = cachedCanonicalCells(state, graph)

    net.Start("LOD_MapBegin")
    net.WriteUInt(state.Level or 1, 20)
    net.WriteUInt(math.Clamp(graph.Layers or 1, 1, 7), 3)
    net.WriteUInt(math.min(#cells, 65535), 16)
    net.WriteUInt(math.min(chunks, 255), 8)
    local jail = graph.Progression and graph.Progression.JailEdge
    net.WriteBool(jail ~= nil)
    if jail then
        writeCell(jail.beforeCell)
        writeCell(jail.afterCell)
    end
    net.Send(ply)

    for chunkIndex = 1, chunks do
        local first = (chunkIndex - 1) * CHUNK_SIZE + 1
        local last = math.min(#cells, first + CHUNK_SIZE - 1)
        local count = math.max(0, last - first + 1)

        net.Start("LOD_MapChunk")
        net.WriteUInt(state.Level or 1, 20)
        net.WriteUInt(chunkIndex, 8)
        net.WriteUInt(count, 8)
        for i = first, last do
            local cell = cells[i]
            net.WriteUInt(math.Clamp(cell.x or 0, 0, 127), 7)
            net.WriteUInt(math.Clamp(cell.y or 0, 0, 127), 7)
            net.WriteUInt(math.Clamp(cell.z or 0, 0, 7), 3)
            net.WriteUInt(cell.openings or 0, 6)
            net.WriteUInt(cell.gates or 0, 8)
        end
        net.Send(ply)
    end
    return true
end
