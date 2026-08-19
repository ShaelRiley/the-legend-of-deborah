LOD = LOD or {}
LOD.MinimapServer = LOD.MinimapServer or {}

local Minimap = LOD.MinimapServer
local CHUNK_SIZE = 128

util.AddNetworkString("LOD_MapRequest")
util.AddNetworkString("LOD_MapBegin")
util.AddNetworkString("LOD_MapChunk")
util.AddNetworkString("LOD_MapDenied")

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

local function developerMode()
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() or false
end

function Minimap:CanUse(ply)
    if not IsValid(ply) then return false end
    return developerMode() or ply:GetNW2Bool("LOD_MapUnlocked", false)
end

-- Milestone 4's individualized rare Map drop should call this function.
-- Map entitlement is deliberately current-level-only and resets on the next maze.
function Minimap:Grant(ply)
    if not IsValid(ply) then return false end
    ply:SetNW2Bool("LOD_MapUnlocked", true)
    return true
end

function Minimap:Revoke(ply)
    if not IsValid(ply) then return end
    ply:SetNW2Bool("LOD_MapUnlocked", false)
end

local function gateIndexByEdge(graph)
    local out = {}
    local progression = graph and graph.Progression
    for index, gate in ipairs(progression and progression.Gates or {}) do
        if gate.edgeKey then out[gate.edgeKey] = index end
    end
    return out
end

local function edgeKey(aKey, bKey)
    if LOD.MazeNavigator and LOD.MazeNavigator.EdgeKey then
        return LOD.MazeNavigator:EdgeKey(aKey, bKey)
    end
    return aKey < bKey and (aKey .. "|" .. bKey) or (bKey .. "|" .. aKey)
end

local function encodeCells(graph)
    local cells = {}
    local gates = gateIndexByEdge(graph)

    for cellKey, cell in pairs(graph.Cells or {}) do
        local openings = 0
        local gateCodes = 0

        for _, dir in ipairs(DIRS) do
            local neighborKey = key(cell.x + dir.dx, cell.y + dir.dy, cell.z + dir.dz)
            if cell.neighbors and cell.neighbors[neighborKey] then
                openings = bit.bor(openings, bit.lshift(1, dir.bit))
                if dir.gateShift then
                    local gateIndex = gates[edgeKey(cellKey, neighborKey)] or 0
                    if gateIndex > 0 then
                        gateCodes = bit.bor(gateCodes, bit.lshift(math.Clamp(gateIndex, 0, 3), dir.gateShift))
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

    local cells = encodeCells(graph)
    local chunks = math.max(1, math.ceil(#cells / CHUNK_SIZE))

    net.Start("LOD_MapBegin")
    net.WriteUInt(state.Level or 1, 20)
    net.WriteUInt(math.Clamp(graph.Layers or 1, 1, 7), 3)
    net.WriteUInt(math.min(#cells, 65535), 16)
    net.WriteUInt(math.min(chunks, 255), 8)
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

net.Receive("LOD_MapRequest", function(_, ply)
    if not IsValid(ply) then return end
    Minimap:Send(ply)
end)

hook.Add("PlayerInitialSpawn", "LOD_MinimapInitialEntitlement", function(ply)
    ply:SetNW2Bool("LOD_MapUnlocked", false)
end)

-- A found map describes one generated labyrinth only. A fresh level needs a new
-- rare Map drop. Developer mode bypasses entitlement without mutating this flag.
hook.Add("Think", "LOD_MinimapLevelReset", function()
    local state = LOD.RunManager and LOD.RunManager.State
    local level = state and state.Level
    if not level or level == Minimap.LastLevel then return end
    Minimap.LastLevel = level
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then ply:SetNW2Bool("LOD_MapUnlocked", false) end
    end
end)
