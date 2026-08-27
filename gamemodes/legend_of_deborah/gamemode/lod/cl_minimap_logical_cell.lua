LOD = LOD or {}

local Map = LOD.Minimap
local MC = LOD.Config and LOD.Config.Maze
if not Map or not MC then return end

-- Logical player-cell guard for the breadcrumb map.
--
-- World-space rounding is intentionally cheap, but near a cell boundary it can
-- briefly report a neighboring REAL maze cell before the player has actually
-- crossed that graph edge. If that neighbor sits beyond a closed progression
-- gate, cached BFS starts in the wrong component and shows NO LEGAL ROUTE.
--
-- Keep one lightweight logical cell while the map is open. It may advance only
-- through a canonical graph edge that is currently traversable. Vertical movement
-- therefore still happens exclusively through authored stair edges. The guard
-- intervenes only when the raw rounded coordinate is itself a real cell; the
-- existing reliability module remains responsible for missing/sparse coordinates.

local canonicalRevision = -1
local canonicalByKey = {}
local canonicalAdjacency = {}
local logicalKey
local lastResolveAt = 0
local lastStateSignature
local overrideKey
local overrideCell
local overrideAdjacency
local recoverySerial = 0

local function cellKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function cellCenter(cell)
    local halfW = (MC.Width + 1) * 0.5
    local halfH = (MC.Height + 1) * 0.5
    return Vector(
        MC.Origin.x + (cell.x - halfW) * MC.CellSize,
        MC.Origin.y + (cell.y - halfH) * MC.CellSize,
        MC.Origin.z + cell.z * MC.LevelHeight
    )
end

local function currentStateSignature()
    local state = LOD.ClientState or {}
    local gates = state.gates or {}
    local objective = state.objectiveA
    return table.concat({
        tostring(state.objectiveStage or 0),
        tostring(state.objectiveKind or 0),
        gates[1] and "1" or "0",
        gates[2] and "1" or "0",
        gates[3] and "1" or "0",
        state.jailDoorOpen and "1" or "0",
        objective and tostring(objective.x) or "-",
        objective and tostring(objective.y) or "-",
        objective and tostring(objective.z) or "-"
    }, ":")
end

local function restoreOverride()
    if not overrideKey then return end
    if Map.byKey then Map.byKey[overrideKey] = overrideCell end
    if Map.cache and Map.cache.adjacency then
        Map.cache.adjacency[overrideKey] = overrideAdjacency
        Map.cache.reach = nil
    end
    overrideKey = nil
    overrideCell = nil
    overrideAdjacency = nil
end

local function rebuildCanonicalSnapshot()
    if not Map.cache or Map.cache.indexedRevision ~= Map.cache.revision then return false end
    if canonicalRevision == Map.cache.revision then return true end

    restoreOverride()
    canonicalByKey = {}
    for _, cell in ipairs(Map.cells or {}) do canonicalByKey[cell.key] = cell end

    canonicalAdjacency = {}
    for key, edges in pairs(Map.cache.adjacency or {}) do
        local copy = {}
        for i, edge in ipairs(edges or {}) do
            copy[i] = {key = edge.key, gate = edge.gate or 0, jail = edge.jail == true}
        end
        canonicalAdjacency[key] = copy
    end

    canonicalRevision = Map.cache.revision
    logicalKey = nil
    lastStateSignature = nil
    lastResolveAt = 0
    return true
end

local function edgeTraversable(edge)
    if not edge then return false end
    local state = LOD.ClientState or {}
    if edge.jail and state.jailDoorOpen ~= true then return false end
    if (edge.gate or 0) > 0 then
        return state.gates and state.gates[edge.gate] == true or false
    end
    return true
end

local function edgeBetween(aKey, bKey)
    for _, edge in ipairs(canonicalAdjacency[aKey] or {}) do
        if edge.key == bKey then return edge end
    end
    return nil
end

local function targetKey()
    local objective = (LOD.ClientState or {}).objectiveA
    return objective and cellKey(objective.x, objective.y, objective.z) or nil
end

local function routeableFrom(startKey)
    local goalKey = targetKey()
    if not goalKey or not canonicalByKey[startKey] or not canonicalByKey[goalKey] then return true end
    if startKey == goalKey then return true end

    local seen = {[startKey] = true}
    local queue = {startKey}
    local head = 1
    while head <= #queue do
        local current = queue[head]
        head = head + 1
        for _, edge in ipairs(canonicalAdjacency[current] or {}) do
            if edgeTraversable(edge) and not seen[edge.key] then
                if edge.key == goalKey then return true end
                seen[edge.key] = true
                queue[#queue + 1] = edge.key
            end
        end
    end
    return false
end

local function rawGridPosition(pos)
    local gx = math.Clamp(math.floor(((pos.x - MC.Origin.x) / MC.CellSize)
        + ((MC.Width + 1) * 0.5) + 0.5), 1, MC.Width)
    local gy = math.Clamp(math.floor(((pos.y - MC.Origin.y) / MC.CellSize)
        + ((MC.Height + 1) * 0.5) + 0.5), 1, MC.Height)
    local maxFloor = math.max(0, (Map.layers or 1) - 1)
    local gz = math.Clamp(math.floor(((pos.z - MC.Origin.z) / MC.LevelHeight) + 0.5), 0, maxFloor)
    return gx, gy, gz, cellKey(gx, gy, gz)
end

local function nearestCanonicalOnFloor(pos, gx, gy, gz)
    local best, bestDist
    for dy = -2, 2 do
        for dx = -2, 2 do
            local candidate = canonicalByKey[cellKey(gx + dx, gy + dy, gz)]
            if candidate then
                local dist = cellCenter(candidate):DistToSqr(pos)
                if not bestDist or dist < bestDist then
                    best, bestDist = candidate, dist
                end
            end
        end
    end
    return best
end

local function recoverInitialCell(candidate, pos)
    if not candidate then return nil end
    if routeableFrom(candidate.key) then return candidate end

    -- A true current cell should be able to reach the active progression target.
    -- If the rounded candidate cannot, inspect only its canonical same-floor
    -- neighbors. This repairs a boundary alias without jumping across arbitrary
    -- walls or floors.
    local best, bestDist
    for _, edge in ipairs(canonicalAdjacency[candidate.key] or {}) do
        local neighbor = canonicalByKey[edge.key]
        if neighbor and neighbor.z == candidate.z and routeableFrom(neighbor.key) then
            local dist = cellCenter(neighbor):DistToSqr(pos)
            if not bestDist or dist < bestDist then
                best, bestDist = neighbor, dist
            end
        end
    end
    if best then
        recoverySerial = recoverySerial + 1
        print(string.format(
            "[LOD:MINIMAP-LOGICAL] recovery#%d raw=%s logical=%s reason=raw-cell-cannot-reach-objective",
            recoverySerial, tostring(candidate.key), tostring(best.key)))
        return best
    end
    return candidate
end

local function bestLegalStepToward(pos, fromKey, wantedKey)
    local from = canonicalByKey[fromKey]
    if not from then return nil end
    local wanted = canonicalByKey[wantedKey]

    local direct = edgeBetween(fromKey, wantedKey)
    if direct and edgeTraversable(direct) then return wanted end

    -- Handles a rare long render hitch without permitting graph teleportation:
    -- advance at most one legal edge toward the player's physical position.
    local currentDist = cellCenter(from):DistToSqr(pos)
    local best, bestDist = nil, currentDist
    for _, edge in ipairs(canonicalAdjacency[fromKey] or {}) do
        if edgeTraversable(edge) then
            local neighbor = canonicalByKey[edge.key]
            if neighbor then
                local dist = cellCenter(neighbor):DistToSqr(pos)
                if dist + 1 < bestDist then
                    best, bestDist = neighbor, dist
                end
            end
        end
    end
    return best
end

local function applyLogicalAlias(rawKey, rawCell, logicalCell)
    if not rawCell or not logicalCell or rawKey == logicalCell.key then
        restoreOverride()
        return
    end

    if overrideKey == rawKey and Map.byKey[rawKey] == logicalCell then return end
    restoreOverride()

    overrideKey = rawKey
    overrideCell = Map.byKey[rawKey]
    overrideAdjacency = Map.cache.adjacency[rawKey]

    -- The core renderer still asks for the rounded raw key. Present that key as
    -- a zero-cost alias of the logical cell for this HUD interval. Because both
    -- key lookups resolve to the same cell object, the synthetic first route
    -- segment has zero visual length rather than drawing through a closed wall.
    Map.byKey[rawKey] = logicalCell
    Map.cache.adjacency[rawKey] = {{key = logicalCell.key, gate = 0, jail = false}}
    Map.cache.reach = nil
end

local function resetTracking()
    restoreOverride()
    logicalKey = nil
    lastResolveAt = 0
    lastStateSignature = nil
end

hook.Add("Think", "LOD_MinimapLogicalCellGuard", function()
    if not Map.open or not Map.cache or Map.cache.indexedRevision ~= Map.cache.revision then
        resetTracking()
        return
    end
    if not rebuildCanonicalSnapshot() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        resetTracking()
        return
    end

    local now = CurTime()
    local pos = ply:GetPos()
    local gx, gy, gz, rawKey = rawGridPosition(pos)
    local rawCell = canonicalByKey[rawKey]
    local candidate = rawCell or nearestCanonicalOnFloor(pos, gx, gy, gz)
    if not candidate then
        restoreOverride()
        return
    end

    local signature = currentStateSignature()
    local stale = lastResolveAt <= 0 or (now - lastResolveAt) > 0.75
        or lastStateSignature ~= signature
        or not logicalKey or not canonicalByKey[logicalKey]

    if stale then
        logicalKey = recoverInitialCell(candidate, pos).key
    elseif candidate.key ~= logicalKey then
        local nextCell = bestLegalStepToward(pos, logicalKey, candidate.key)
        if nextCell then logicalKey = nextCell.key end
    end

    lastResolveAt = now
    lastStateSignature = signature

    -- Only override a REAL rounded cell. Sparse/missing coordinates remain owned
    -- by cl_minimap_reliability.lua's same-floor nearest-cell alias.
    if rawCell and logicalKey and rawKey ~= logicalKey then
        applyLogicalAlias(rawKey, rawCell, canonicalByKey[logicalKey])
    else
        restoreOverride()
    end
end)

concommand.Add("lod_minimap_logical_status", function()
    print(string.format(
        "[LOD:MINIMAP-LOGICAL] revision=%d logical=%s override=%s recoveries=%d",
        canonicalRevision, tostring(logicalKey or "none"), tostring(overrideKey or "none"), recoverySerial))
end)
