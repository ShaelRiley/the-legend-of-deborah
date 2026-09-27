LOD = LOD or {}
LOD.MinimapServer = LOD.MinimapServer or {}

local Minimap = LOD.MinimapServer
local MC = LOD.Config.Maze
local CHUNK_SIZE = 128
local REQUEST_INTERVAL = 0.35
local requests = setmetatable({}, {__mode = "k"})
local encodedGraph = setmetatable({}, {__mode = "v"})

util.AddNetworkString("LOD_MapRequest")
util.AddNetworkString("LOD_MapBegin")
util.AddNetworkString("LOD_MapChunk")
util.AddNetworkString("LOD_MapDenied")

local DIRS = {
    {dx = 0, dy = 1, dz = 0, bit = 0, gateShift = 0}, -- N
    {dx = 1, dy = 0, dz = 0, bit = 1, gateShift = 3}, -- E
    {dx = 0, dy = -1, dz = 0, bit = 2, gateShift = 6}, -- S
    {dx = -1, dy = 0, dz = 0, bit = 3, gateShift = 9}, -- W
    {dx = 0, dy = 0, dz = 1, bit = 4},                 -- UP
    {dx = 0, dy = 0, dz = -1, bit = 5}                 -- DOWN
}

local STAIR_DIRECTION_CODE = {
    N = 0,
    E = 1,
    S = 2,
    W = 3
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

local function developerMode()
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() or false
end

local function currentLevel()
    local state = LOD.RunManager and LOD.RunManager.State
    return state and tonumber(state.Level) or 0
end

function Minimap:CanUse(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    if developerMode() then return true end
    if not ply:GetNW2Bool("LOD_MapUnlocked", false) then return false end
    local level = currentLevel()
    return level > 0 and ply:GetNW2Int("LOD_MapUnlockedLevel", 0) == level
end

-- Map entitlement is current-level-only without a per-tick reset hook. The level
-- stamp makes an old Map automatically invalid as soon as RunManager advances.
function Minimap:Grant(ply)
    if not IsValid(ply) then return false end
    local level = currentLevel()
    if level <= 0 then return false end
    ply:SetNW2Bool("LOD_MapUnlocked", true)
    ply:SetNW2Int("LOD_MapUnlockedLevel", level)
    return true
end

function Minimap:Revoke(ply)
    if not IsValid(ply) then return end
    ply:SetNW2Bool("LOD_MapUnlocked", false)
    ply:SetNW2Int("LOD_MapUnlockedLevel", 0)
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

local function stairDirectionByCell(graph)
    local out = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        local code = STAIR_DIRECTION_CODE[edge.LODStairDirection] or 0
        out[key(edge.a.x, edge.a.y, edge.a.z)] = code
        out[key(edge.b.x, edge.b.y, edge.b.z)] = code
    end
    return out
end

-- Serialize topology once per immutable generated graph. Opening/closing the map
-- does not rebuild this representation, and the client no longer asks for it on
-- same-level reopens.
local function encodeCanonicalCells(graph)
    local cells = {}
    local gates = gateIndexByEdge(graph)
    local stairs = stairDirectionByCell(graph)

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
                            bit.lshift(math.Clamp(gateIndex, 0, 4), dir.gateShift))
                    end
                end
            end
        end

        cells[#cells + 1] = {
            x = cell.x,
            y = cell.y,
            z = cell.z,
            openings = openings,
            gates = gateCodes,
            stairDirection = stairs[cellKey] or 0
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
    local epoch = tonumber(state.CampaignEpoch) or 0
    local levelSeed = tonumber(state.LevelSeed) or 0
    local build = LOD.TopologySyncSafety and LOD.TopologySyncSafety.BuildSerial
    if encodedGraph[1] == graph and Minimap.EncodedBuild == build
        and Minimap.EncodedEpoch == epoch and Minimap.EncodedLevel == state.Level
        and Minimap.EncodedLevelSeed == levelSeed and Minimap.EncodedCells
    then
        Minimap.EncodeCacheHits = (Minimap.EncodeCacheHits or 0) + 1
        return Minimap.EncodedCells, Minimap.EncodedChunks
    end

    local cells = encodeCanonicalCells(graph)
    local chunks = math.max(1, math.ceil(#cells / CHUNK_SIZE))
    -- A seed is not a build identity. Keep only a weak graph reference so a
    -- same-seed replacement invalidates the cache without retaining old worlds.
    encodedGraph[1] = graph
    Minimap.EncodedBuild = build
    Minimap.EncodedEpoch = epoch
    Minimap.EncodedLevel = state.Level
    Minimap.EncodedLevelSeed = levelSeed
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

    local cells, chunks = cachedCanonicalCells(state, graph)

    net.Start("LOD_MapBegin")
    net.WriteDouble(state.Level or 1)
    net.WriteUInt(math.Clamp(graph.Layers or 1, 1, 7), 3)
    net.WriteUInt(math.min(#cells, 65535), 16)
    net.WriteUInt(math.min(chunks, 255), 8)

    -- Send the resolved runtime origin once with topology. This replaces three
    -- NW2 reads and comparisons in a client Think hook that previously ran for
    -- every rendered frame of the entire session.
    net.WriteFloat(MC.Origin.x)
    net.WriteFloat(MC.Origin.y)
    net.WriteFloat(MC.Origin.z)

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
        net.WriteDouble(state.Level or 1)
        net.WriteUInt(chunkIndex, 8)
        net.WriteUInt(count, 8)
        for i = first, last do
            local cell = cells[i]
            net.WriteUInt(math.Clamp(cell.x or 0, 0, 127), 7)
            net.WriteUInt(math.Clamp(cell.y or 0, 0, 127), 7)
            net.WriteUInt(math.Clamp(cell.z or 0, 0, 7), 3)
            net.WriteUInt(cell.openings or 0, 6)
            net.WriteUInt(cell.gates or 0, 12)
            net.WriteUInt(cell.stairDirection or 0, 2)
        end
        net.Send(ply)
    end
    return true
end

net.Receive("LOD_MapRequest", function(bits, ply)
    if bits > 8 or not IsValid(ply) or not ply:IsPlayer() then return end
    local request = requests[ply]
    if not request then request = {nextAt=0}; requests[ply] = request end
    local now = CurTime()
    if now >= request.nextAt and not request.pending then
        request.nextAt = now + REQUEST_INTERVAL
        Minimap:Send(ply)
    elseif not request.pending then
        request.pending = true
        timer.Simple(math.max(0, request.nextAt - now), function()
            if requests[ply] ~= request or not IsValid(ply) then return end
            request.pending = false
            request.nextAt = CurTime() + REQUEST_INTERVAL
            -- Resolve at dispatch: a rebuild arriving during this window must
            -- recover the current topology rather than lose its only request.
            Minimap:Send(ply)
        end)
    end
end)

hook.Add("PlayerDisconnected", "LOD_MinimapRequestDisconnect", function(ply)
    requests[ply] = nil
end)

hook.Add("PlayerInitialSpawn", "LOD_MinimapInitialEntitlement", function(ply)
    Minimap:Revoke(ply)
end)
