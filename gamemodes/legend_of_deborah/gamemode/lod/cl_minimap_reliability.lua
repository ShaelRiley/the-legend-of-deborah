LOD = LOD or {}

local Map = LOD.Minimap
local MC = LOD.Config and LOD.Config.Maze
if not Map or not MC then return end

-- Reliability layer for the accepted cached minimap architecture.
--
-- Two rare client-side failure modes are closed here without adding recurring
-- graph work:
--   1. receivedChunks used to mean "highest chunk index seen" rather than the
--      number of unique chunks actually received. An out-of-order final chunk
--      could therefore freeze an incomplete adjacency graph permanently.
--   2. the client rounded the player's world position to one grid coordinate but
--      did not mirror MazeNavigator's nearest-real-cell fallback. Standing on a
--      stair / sparse upper-layer boundary could therefore produce NO LEGAL ROUTE
--      despite a valid server route.
--
-- Topology is still indexed once per complete transfer. Route BFS remains owned
-- by cl_minimap.lua and stays cached by player cell + progression state.

local transferRevision = -1
local seenChunks = {}
local uniqueChunks = 0
local aliasKey
local aliasCell

local function cellKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function bitOpen(mask, index)
    return bit.band(mask or 0, bit.lshift(1, index)) ~= 0
end

local function gateCode(codes, shift)
    return bit.band(bit.rshift(codes or 0, shift), 3)
end

local ROUTE_DIRS = {
    {dx = 0, dy = 1, dz = 0, bit = 0, gateShift = 0},
    {dx = 1, dy = 0, dz = 0, bit = 1, gateShift = 2},
    {dx = 0, dy = -1, dz = 0, bit = 2, gateShift = 4},
    {dx = -1, dy = 0, dz = 0, bit = 3, gateShift = 6},
    {dx = 0, dy = 0, dz = 1, bit = 4},
    {dx = 0, dy = 0, dz = -1, bit = 5}
}

local function sameEdge(aKey, bKey, edgeA, edgeB)
    if not edgeA or not edgeB then return false end
    return (aKey == edgeA and bKey == edgeB) or (aKey == edgeB and bKey == edgeA)
end

local function sortedEdgeKey(aKey, bKey)
    return aKey < bKey and (aKey .. "|" .. bKey) or (bKey .. "|" .. aKey)
end

local function clearPlayerAlias()
    if not aliasKey then return end
    if Map.byKey and Map.byKey[aliasKey] == aliasCell then
        Map.byKey[aliasKey] = nil
    end
    if Map.cache and Map.cache.adjacency then
        Map.cache.adjacency[aliasKey] = nil
        Map.cache.reach = nil
    end
    aliasKey = nil
    aliasCell = nil
end

local function resetTransferState()
    transferRevision = Map.cache and Map.cache.revision or -1
    seenChunks = {}
    uniqueChunks = 0
    clearPlayerAlias()
end

local function rebuildGraphIndex()
    if not Map.cache then return end

    local floorCells = {}
    local floorStairs = {}
    local floorGates = {}
    local floorJail = {}
    local adjacency = {}
    local seenGates = {}
    local seenJail = {}
    local jailA = Map.jailAKey
    local jailB = Map.jailBKey

    for _, cell in ipairs(Map.cells or {}) do
        floorCells[cell.z] = floorCells[cell.z] or {}
        floorCells[cell.z][#floorCells[cell.z] + 1] = cell
        adjacency[cell.key] = adjacency[cell.key] or {}

        local up = bitOpen(cell.openings, 4)
        local down = bitOpen(cell.openings, 5)
        if up or down then
            floorStairs[cell.z] = floorStairs[cell.z] or {}
            floorStairs[cell.z][#floorStairs[cell.z] + 1] = {
                cell = cell,
                key = cell.key,
                up = up,
                down = down
            }
        end

        for _, dir in ipairs(ROUTE_DIRS) do
            if bitOpen(cell.openings, dir.bit) then
                local neighborKey = cellKey(cell.x + dir.dx, cell.y + dir.dy, cell.z + dir.dz)
                local neighbor = Map.byKey and Map.byKey[neighborKey]
                if neighbor then
                    local gateIndex = dir.gateShift ~= nil and gateCode(cell.gates, dir.gateShift) or 0
                    local isJail = sameEdge(cell.key, neighborKey, jailA, jailB)
                    adjacency[cell.key][#adjacency[cell.key] + 1] = {
                        key = neighborKey,
                        gate = gateIndex,
                        jail = isJail
                    }

                    if dir.gateShift ~= nil and gateIndex > 0 then
                        local edgeKey = sortedEdgeKey(cell.key, neighborKey)
                        if not seenGates[edgeKey] then
                            seenGates[edgeKey] = true
                            floorGates[cell.z] = floorGates[cell.z] or {}
                            floorGates[cell.z][#floorGates[cell.z] + 1] = {
                                gate = gateIndex,
                                x = cell.x,
                                y = cell.y,
                                dx = dir.dx,
                                dy = dir.dy
                            }
                        end
                    end

                    if isJail and dir.gateShift ~= nil then
                        local edgeKey = sortedEdgeKey(cell.key, neighborKey)
                        if not seenJail[edgeKey] then
                            seenJail[edgeKey] = true
                            floorJail[cell.z] = floorJail[cell.z] or {}
                            floorJail[cell.z][#floorJail[cell.z] + 1] = {
                                x = cell.x,
                                y = cell.y,
                                dx = dir.dx,
                                dy = dir.dy
                            }
                        end
                    end
                end
            end
        end
    end

    Map.cache.floorCells = floorCells
    Map.cache.floorStairs = floorStairs
    Map.cache.floorGates = floorGates
    Map.cache.floorJail = floorJail
    Map.cache.adjacency = adjacency
    Map.cache.indexedRevision = Map.cache.revision
    Map.cache.reach = nil
    Map.cache.topologyRevision = -1
    Map.cache.topologyFloor = -1
    Map.stats = Map.stats or {}
    Map.stats.floorIndexBuilds = (Map.stats.floorIndexBuilds or 0) + 1
end

-- cl_minimap.lua installs the original receiver first. Registering the same net
-- message after it replaces that callback with this exact-count receiver.
net.Receive("LOD_MapChunk", function()
    local level = net.ReadUInt(20)
    local chunkIndex = net.ReadUInt(8)
    local count = net.ReadUInt(8)
    local payload = {}

    -- Always consume the complete payload before deciding whether it belongs to
    -- the current transfer.
    for i = 1, count do
        local cell = {
            x = net.ReadUInt(7),
            y = net.ReadUInt(7),
            z = net.ReadUInt(3),
            openings = net.ReadUInt(6),
            gates = net.ReadUInt(8),
            stairDirection = net.ReadUInt(2)
        }
        cell.key = cellKey(cell.x, cell.y, cell.z)
        payload[i] = cell
    end

    if Map.level ~= level or not Map.cache then return end
    if transferRevision ~= Map.cache.revision then resetTransferState() end
    if seenChunks[chunkIndex] then return end

    seenChunks[chunkIndex] = true
    uniqueChunks = uniqueChunks + 1

    for _, cell in ipairs(payload) do
        -- A repeated request for the same level can overlap at the network edge.
        -- Keep one canonical copy of every cell rather than inflating Map.cells.
        if not Map.byKey[cell.key] then
            Map.cells[#Map.cells + 1] = cell
        end
        Map.byKey[cell.key] = cell
    end

    Map.receivedChunks = uniqueChunks

    local enoughChunks = uniqueChunks >= (Map.expectedChunks or 0)
    local enoughCells = #Map.cells >= (Map.expectedCells or 0)
    if enoughChunks and enoughCells then
        rebuildGraphIndex()
    end
end)

local function cellCenter(cell)
    local halfW = (MC.Width + 1) * 0.5
    local halfH = (MC.Height + 1) * 0.5
    return Vector(
        MC.Origin.x + (cell.x - halfW) * MC.CellSize,
        MC.Origin.y + (cell.y - halfH) * MC.CellSize,
        MC.Origin.z + cell.z * MC.LevelHeight
    )
end

local function nearestRealCell(pos, gx, gy, gz)
    local best
    local bestDist

    -- Match MazeNavigator's cheap neighborhood fallback first.
    for dz = -1, 1 do
        for dy = -2, 2 do
            for dx = -2, 2 do
                local candidate = Map.byKey[cellKey(gx + dx, gy + dy, gz + dz)]
                if candidate then
                    local dist = cellCenter(candidate):DistToSqr(pos)
                    if not bestDist or dist < bestDist then
                        best = candidate
                        bestDist = dist
                    end
                end
            end
        end
    end
    if best then return best end

    -- This only runs when the player rounds into a coordinate not represented by
    -- the sparse generated graph, so the full fallback is exceptional rather
    -- than per-frame work.
    for _, candidate in ipairs(Map.cells or {}) do
        local dist = cellCenter(candidate):DistToSqr(pos)
        if not bestDist or dist < bestDist then
            best = candidate
            bestDist = dist
        end
    end
    return best
end

local lastProbeKey
local lastProbeRevision = -1

hook.Add("PreDrawHUD", "LOD_MinimapNearestRealCell", function()
    if not Map.open or not Map.cache or Map.cache.indexedRevision ~= Map.cache.revision then
        clearPlayerAlias()
        lastProbeKey = nil
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if lastProbeRevision ~= Map.cache.revision then
        clearPlayerAlias()
        lastProbeRevision = Map.cache.revision
        lastProbeKey = nil
    end

    local pos = ply:GetPos()
    local gx = math.Clamp(math.floor(((pos.x - MC.Origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5), 1, MC.Width)
    local gy = math.Clamp(math.floor(((pos.y - MC.Origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5), 1, MC.Height)
    local gz = math.max(0, math.floor(((pos.z - MC.Origin.z) / MC.LevelHeight) + 0.5))
    local directKey = cellKey(gx, gy, gz)

    if Map.byKey[directKey] and directKey ~= aliasKey then
        clearPlayerAlias()
        lastProbeKey = directKey
        return
    end

    if directKey == aliasKey or directKey == lastProbeKey then return end
    clearPlayerAlias()
    lastProbeKey = directKey

    local nearest = nearestRealCell(pos, gx, gy, gz)
    if not nearest then return end

    -- Give the existing cached route code a one-edge bridge from the rounded
    -- physical coordinate to the same logical cell the server would resolve.
    -- floorCells/topology are untouched, so this alias never draws fake maze
    -- geometry and never changes authoritative progression.
    aliasKey = directKey
    aliasCell = nearest
    Map.byKey[aliasKey] = nearest
    Map.cache.adjacency[aliasKey] = {{key = nearest.key, gate = 0, jail = false}}
    Map.cache.reach = nil
end)
