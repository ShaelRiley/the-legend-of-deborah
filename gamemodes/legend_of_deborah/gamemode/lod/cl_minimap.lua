LOD = LOD or {}
LOD.Minimap = LOD.Minimap or {
    open = false,
    level = nil,
    layers = 1,
    expectedChunks = 0,
    receivedChunks = 0,
    cells = {},
    byKey = {}
}

local Map = LOD.Minimap
local MC = LOD.Config.Maze
local mapKeyWasDown = false

Map.cache = Map.cache or {
    revision = 0,
    indexedRevision = -1,
    floorCells = {},
    reach = nil
}
Map.stats = Map.stats or {
    paintFrames = 0,
    bfsBuilds = 0,
    bfsHits = 0,
    floorIndexBuilds = 0
}

local function resetCacheStats()
    Map.stats.paintFrames = 0
    Map.stats.bfsBuilds = 0
    Map.stats.bfsHits = 0
    Map.stats.floorIndexBuilds = 0
end

local function invalidateGraphCache()
    Map.cache.revision = (Map.cache.revision or 0) + 1
    Map.cache.indexedRevision = -1
    Map.cache.floorCells = {}
    Map.cache.reach = nil
    resetCacheStats()
end

local function buildFloorIndex()
    if Map.cache.indexedRevision == Map.cache.revision then return end
    local floorCells = {}
    for _, cell in ipairs(Map.cells) do
        floorCells[cell.z] = floorCells[cell.z] or {}
        floorCells[cell.z][#floorCells[cell.z] + 1] = cell
    end
    Map.cache.floorCells = floorCells
    Map.cache.indexedRevision = Map.cache.revision
    Map.cache.reach = nil
    Map.stats.floorIndexBuilds = Map.stats.floorIndexBuilds + 1
end

surface.CreateFont("LOD_Map_Title", {
    font = "DejaVu Sans",
    size = 18,
    weight = 800
})

surface.CreateFont("LOD_Map_Small", {
    font = "DejaVu Sans",
    size = 12,
    weight = 650
})

local gateColors = {
    Color(205, 54, 54),
    Color(64, 118, 210),
    Color(224, 190, 52)
}

local function cellKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function hasAccess(ply)
    if not IsValid(ply) then return false end
    return ply:GetNW2Bool("LOD_DeveloperMode", false) or ply:GetNW2Bool("LOD_MapUnlocked", false)
end

local function requestMap()
    net.Start("LOD_MapRequest")
    net.SendToServer()
end

local function currentGridPosition(ply)
    local pos = ply:GetPos()
    local x = math.floor(((pos.x - MC.Origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local y = math.floor(((pos.y - MC.Origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local z = math.floor(((pos.z - MC.Origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(x, 1, MC.Width), math.Clamp(y, 1, MC.Height), math.max(0, z)
end

net.Receive("LOD_MapBegin", function()
    Map.level = net.ReadUInt(20)
    Map.layers = net.ReadUInt(3)
    Map.expectedCells = net.ReadUInt(16)
    Map.expectedChunks = net.ReadUInt(8)
    Map.jailA = nil
    Map.jailB = nil
    Map.jailAKey = nil
    Map.jailBKey = nil
    if net.ReadBool() then
        Map.jailA = {x = net.ReadUInt(7), y = net.ReadUInt(7), z = net.ReadUInt(3)}
        Map.jailB = {x = net.ReadUInt(7), y = net.ReadUInt(7), z = net.ReadUInt(3)}
        Map.jailAKey = cellKey(Map.jailA.x, Map.jailA.y, Map.jailA.z)
        Map.jailBKey = cellKey(Map.jailB.x, Map.jailB.y, Map.jailB.z)
    end
    Map.receivedChunks = 0
    Map.cells = {}
    Map.byKey = {}
    invalidateGraphCache()
end)

net.Receive("LOD_MapChunk", function()
    local level = net.ReadUInt(20)
    local chunkIndex = net.ReadUInt(8)
    local count = net.ReadUInt(8)
    if Map.level ~= level then return end

    for _ = 1, count do
        local cell = {
            x = net.ReadUInt(7),
            y = net.ReadUInt(7),
            z = net.ReadUInt(3),
            openings = net.ReadUInt(6),
            gates = net.ReadUInt(8)
        }
        Map.cells[#Map.cells + 1] = cell
        Map.byKey[cellKey(cell.x, cell.y, cell.z)] = cell
    end
    Map.receivedChunks = math.max(Map.receivedChunks or 0, chunkIndex)
    if Map.receivedChunks >= (Map.expectedChunks or 0) then
        buildFloorIndex()
    end
end)

net.Receive("LOD_MapDenied", function()
    Map.open = false
    local text = net.ReadString()
    surface.PlaySound("buttons/button10.wav")
    notification.AddLegacy(text ~= "" and text or "NO MAP", NOTIFY_HINT, 2.5)
end)

hook.Add("Think", "LOD_MinimapToggleInput", function()
    local down = input.IsKeyDown(KEY_M)
    if not down then
        mapKeyWasDown = false
        return
    end
    if mapKeyWasDown then return end
    mapKeyWasDown = true

    if gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not hasAccess(ply) then
        surface.PlaySound("buttons/button10.wav")
        notification.AddLegacy("NO MAP — FIND ONE", NOTIFY_HINT, 2.5)
        return
    end

    Map.open = not Map.open
    surface.PlaySound(Map.open and "buttons/button15.wav" or "buttons/button19.wav")
    if Map.open then requestMap() end
end)

local function bitOpen(mask, index)
    return bit.band(mask or 0, bit.lshift(1, index)) ~= 0
end

local function gateCode(codes, shift)
    return bit.band(bit.rshift(codes or 0, shift), 3)
end

local function drawGateLine(gateIndex, x1, y1, x2, y2)
    if gateIndex <= 0 then return end
    local state = LOD.ClientState or {}
    local opened = state.gates and state.gates[gateIndex]
    local color = opened and Color(105, 185, 115, 245) or (gateColors[gateIndex] or Color(238, 194, 92))
    surface.SetDrawColor(color)
    surface.DrawLine(x1, y1, x2, y2)
    surface.DrawLine(x1 + (y1 == y2 and 0 or 1), y1 + (x1 == x2 and 0 or 1),
        x2 + (y1 == y2 and 0 or 1), y2 + (x1 == x2 and 0 or 1))
end

local function drawPlayerMarker(px, py, size)
    local yaw = math.rad(EyeAngles().y)
    local dx = math.cos(yaw)
    local dy = -math.sin(yaw)
    surface.SetDrawColor(248, 213, 105, 255)
    surface.DrawCircle(px, py, size, 248, 213, 105, 255)
    surface.DrawLine(px, py, px + dx * (size + 7), py + dy * (size + 7))
end

local ROUTE_DIRS = {
    {dx = 0, dy = 1, bit = 0, gateShift = 0},
    {dx = 1, dy = 0, bit = 1, gateShift = 2},
    {dx = 0, dy = -1, bit = 2, gateShift = 4},
    {dx = -1, dy = 0, bit = 3, gateShift = 6},
    {dx = 0, dy = 0, dz = 1, bit = 4},
    {dx = 0, dy = 0, dz = -1, bit = 5}
}

local function sameEdge(aKey, bKey, edgeA, edgeB)
    if not edgeA or not edgeB then return false end
    return (aKey == edgeA and bKey == edgeB) or (aKey == edgeB and bKey == edgeA)
end

local function jailEdgeKeys()
    return Map.jailAKey, Map.jailBKey
end

local function edgeTraversable(cell, dir)
    if not bitOpen(cell.openings, dir.bit) then return false end
    local fromKey = cellKey(cell.x, cell.y, cell.z)
    local toKey = cellKey(cell.x + dir.dx, cell.y + dir.dy, cell.z + (dir.dz or 0))
    if not Map.byKey[toKey] then return false end

    local state = LOD.ClientState or {}
    local jailA, jailB = jailEdgeKeys()
    if sameEdge(fromKey, toKey, jailA, jailB) and state.jailDoorOpen ~= true then return false end

    if dir.gateShift == nil then return true end
    local gateIndex = gateCode(cell.gates, dir.gateShift)
    if gateIndex <= 0 then return true end
    return state.gates and state.gates[gateIndex] == true or false
end

-- One cached three-dimensional BFS is the breadcrumb authority. It consumes the
-- compact canonical topology already held by the client, blocks every unopened
-- colored gate and the locked JailEdge, and traverses only encoded stair edges.
local function graphReachability(gx, gy, gz)
    local startKey = cellKey(gx, gy, gz)
    if not Map.byKey[startKey] then return {}, {}, {} end

    local queue = {startKey}
    local head = 1
    local reached = {[startKey] = true}
    local previous = {}
    local distance = {[startKey] = 0}

    while head <= #queue do
        local currentKey = queue[head]
        head = head + 1
        local current = Map.byKey[currentKey]
        if current then
            for _, dir in ipairs(ROUTE_DIRS) do
                if edgeTraversable(current, dir) then
                    local nk = cellKey(current.x + dir.dx, current.y + dir.dy, current.z + (dir.dz or 0))
                    if Map.byKey[nk] and not reached[nk] then
                        reached[nk] = true
                        previous[nk] = currentKey
                        distance[nk] = distance[currentKey] + 1
                        queue[#queue + 1] = nk
                    end
                end
            end
        end
    end

    return reached, previous, distance
end

local function routeTo(previous, startKey, goalKey)
    if not goalKey then return nil end
    local reverse = {goalKey}
    local cursor = goalKey
    while cursor ~= startKey do
        cursor = previous[cursor]
        if not cursor then return nil end
        reverse[#reverse + 1] = cursor
    end
    local route = {}
    for i = #reverse, 1, -1 do route[#route + 1] = reverse[i] end
    return route
end

local function gateStateSignature()
    local state = LOD.ClientState or {}
    local gates = state.gates or {}
    local signature = 0
    for gateIndex = 1, 3 do
        if gates[gateIndex] == true then
            signature = bit.bor(signature, bit.lshift(1, gateIndex - 1))
        end
    end
    return signature
end

local function objectiveSignature()
    local state = LOD.ClientState or {}
    local a = state.objectiveA
    local b = state.objectiveB
    return table.concat({
        tostring(state.objectiveStage or 0),
        tostring(state.objectiveKind or 0),
        a and cellKey(a.x, a.y, a.z) or "nil",
        b and cellKey(b.x, b.y, b.z) or "nil"
    }, "|")
end

local function cachedRouteData(gx, gy, gz)
    local startKey = cellKey(gx, gy, gz)
    local gateSignature = gateStateSignature()
    local objective = objectiveSignature()
    local state = LOD.ClientState or {}
    local jailOpen = state.jailDoorOpen == true
    local cached = Map.cache.reach
    if cached and cached.revision == Map.cache.revision and
        cached.startKey == startKey and cached.gateSignature == gateSignature and
        cached.jailOpen == jailOpen and cached.objective == objective then
        Map.stats.bfsHits = Map.stats.bfsHits + 1
        return cached
    end

    local reached, previous, distance = graphReachability(gx, gy, gz)
    local target = state.objectiveA
    local targetKey = target and cellKey(target.x, target.y, target.z) or nil
    cached = {
        revision = Map.cache.revision,
        startKey = startKey,
        gateSignature = gateSignature,
        jailOpen = jailOpen,
        objective = objective,
        reached = reached,
        previous = previous,
        distance = distance,
        targetKey = targetKey,
        route = targetKey and reached[targetKey] and routeTo(previous, startKey, targetKey) or nil
    }
    Map.cache.reach = cached
    Map.stats.bfsBuilds = Map.stats.bfsBuilds + 1
    return cached
end

local function mapCellCenter(cell, gridX, gridY, cellSize)
    return gridX + (cell.x - 0.5) * cellSize,
        gridY + (MC.Height - cell.y + 0.5) * cellSize
end

local function drawThickLine(x1, y1, x2, y2, color)
    surface.SetDrawColor(color)
    surface.DrawLine(x1, y1, x2, y2)
    surface.DrawLine(x1 + 1, y1, x2 + 1, y2)
    surface.DrawLine(x1, y1 + 1, x2, y2 + 1)
end

local function drawObjectiveMarker(state, x, y)
    local pulse = 6 + math.abs(math.sin(CurTime() * 4.5)) * 3
    local kind = state.objectiveKind or 0
    local color = Color(255, 224, 92, 255)
    if kind == 1 then
        local cardIndex = math.Clamp(math.floor(((state.objectiveStage or 1) + 1) / 2), 1, 3)
        color = gateColors[cardIndex] or color
    elseif kind == 5 then
        color = Color(245, 180, 225, 255)
    end
    surface.DrawCircle(x, y, pulse, color.r, color.g, color.b, color.a)
    surface.DrawCircle(x, y, pulse + 1, color.r, color.g, color.b, 180)
    local labels = {[1] = "CARD", [2] = "GATE", [3] = "KEY", [4] = "JAIL", [5] = "D"}
    draw.SimpleText(labels[kind] or "GOAL", "LOD_Map_Small", x, y - 11,
        color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end

local function drawJailEdge(cell, x0, y0, x1, y1)
    local aKey, bKey = jailEdgeKeys()
    if not aKey or not bKey then return end
    local ck = cellKey(cell.x, cell.y, cell.z)
    local state = LOD.ClientState or {}
    local color = state.jailDoorOpen and Color(105, 185, 115, 245) or Color(205, 205, 215, 245)
    local edges = {
        {cellKey(cell.x, cell.y + 1, cell.z), x0, y0, x1, y0},
        {cellKey(cell.x + 1, cell.y, cell.z), x1, y0, x1, y1},
        {cellKey(cell.x, cell.y - 1, cell.z), x0, y1, x1, y1},
        {cellKey(cell.x - 1, cell.y, cell.z), x0, y0, x0, y1}
    }
    for _, edge in ipairs(edges) do
        if sameEdge(ck, edge[1], aKey, bKey) then
            drawThickLine(edge[2], edge[3], edge[4], edge[5], color)
        end
    end
end

hook.Add("HUDPaint", "LOD_MinimapHUD", function()
    if not Map.open then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not hasAccess(ply) then
        Map.open = false
        return
    end

    local state = LOD.ClientState or {}
    if Map.level ~= state.level then
        requestMap()
        return
    end

    local panelW, panelH = 336, 392
    local panelX = ScrW() - panelW - 20
    local panelY = 96
    local gridX, gridY = panelX + 26, panelY + 68
    local gridSize = 284
    local cellSize = gridSize / math.max(MC.Width, MC.Height)
    local gx, gy, gz = currentGridPosition(ply)
    gz = math.Clamp(gz, 0, math.max(0, (Map.layers or 1) - 1))

    draw.RoundedBox(4, panelX, panelY, panelW, panelH, Color(12, 15, 17, 226))
    surface.SetDrawColor(220, 140, 48, 235)
    surface.DrawRect(panelX, panelY, 4, panelH)

    draw.SimpleText("LABYRINTH MAP", "LOD_Map_Title", panelX + 18, panelY + 12,
        Color(238, 194, 92), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(string.format("FLOOR %d / %d    M — CLOSE", gz + 1, math.max(1, Map.layers or 1)),
        "LOD_Map_Small", panelX + panelW - 16, panelY + 17,
        Color(185, 188, 190), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    local goalFloor = state.objectiveA and (state.objectiveA.z + 1) or nil
    local objectiveLine = state.objective or "EXPEDITION"
    if goalFloor then objectiveLine = objectiveLine .. string.format("  [F%d]", goalFloor) end
    draw.SimpleText(objectiveLine, "LOD_Map_Small", panelX + 18, panelY + 42,
        Color(248, 213, 105), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    if (Map.receivedChunks or 0) < (Map.expectedChunks or 0) or #Map.cells == 0 then
        draw.SimpleText("LOADING MAP...", "LOD_Map_Title", panelX + panelW * 0.5, panelY + panelH * 0.5,
            Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    Map.stats.paintFrames = Map.stats.paintFrames + 1
    local floorData = cachedRouteData(gx, gy, gz)
    local reached = floorData.reached
    local startKey = floorData.startKey

    surface.SetDrawColor(58, 62, 64, 105)
    surface.DrawRect(gridX, gridY, gridSize, gridSize)

    local wallColor = Color(180, 184, 186, 220)
    local stairReachable = Color(248, 213, 105, 255)
    local stairLockedSector = Color(118, 105, 72, 145)

    for _, cell in ipairs(Map.cache.floorCells[gz] or {}) do
        local x0 = gridX + (cell.x - 1) * cellSize
        local y0 = gridY + (MC.Height - cell.y) * cellSize
        local x1 = x0 + cellSize
        local y1 = y0 + cellSize

        surface.SetDrawColor(30, 34, 36, 195)
        surface.DrawRect(x0 + 1, y0 + 1, math.max(1, cellSize - 2), math.max(1, cellSize - 2))
        surface.SetDrawColor(wallColor)

        if not bitOpen(cell.openings, 0) then surface.DrawLine(x0, y0, x1, y0) end -- N
        if not bitOpen(cell.openings, 1) then surface.DrawLine(x1, y0, x1, y1) end -- E
        if not bitOpen(cell.openings, 2) then surface.DrawLine(x0, y1, x1, y1) end -- S
        if not bitOpen(cell.openings, 3) then surface.DrawLine(x0, y0, x0, y1) end -- W

        drawGateLine(gateCode(cell.gates, 0), x0, y0, x1, y0)
        drawGateLine(gateCode(cell.gates, 2), x1, y0, x1, y1)
        drawGateLine(gateCode(cell.gates, 4), x0, y1, x1, y1)
        drawGateLine(gateCode(cell.gates, 6), x0, y0, x0, y1)
        drawJailEdge(cell, x0, y0, x1, y1)

        local up = bitOpen(cell.openings, 4)
        local down = bitOpen(cell.openings, 5)
        if up or down then
            local ck = cellKey(cell.x, cell.y, cell.z)
            local stairText = up and down and "↕" or (up and "↑" or "↓")
            local color = reached[ck] and stairReachable or stairLockedSector
            draw.SimpleText(stairText, "LOD_Map_Small", (x0 + x1) * 0.5, (y0 + y1) * 0.5,
                color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Draw only the immediately useful contiguous segment on this floor. If the
    -- canonical route changes elevation, terminate the gold line at the exact
    -- stair and mark the required direction. Changing floors naturally rebuilds
    -- the cached route from the player's new canonical cell.
    local route = floorData.route
    local transitionCell
    local transitionDirection
    if route and #route > 0 then
        for i = 2, #route do
            local a = Map.byKey[route[i - 1]]
            local b = Map.byKey[route[i]]
            if not a or not b or a.z ~= gz then break end
            if b.z ~= gz then
                transitionCell = a
                transitionDirection = b.z > a.z and "↑" or "↓"
                break
            end
            local ax, ay = mapCellCenter(a, gridX, gridY, cellSize)
            local bx, by = mapCellCenter(b, gridX, gridY, cellSize)
            drawThickLine(ax, ay, bx, by, Color(255, 215, 58, 225))
            surface.DrawCircle(bx, by, 2, 255, 226, 100, 235)
        end
    end

    if transitionCell then
        local tx, ty = mapCellCenter(transitionCell, gridX, gridY, cellSize)
        local pulse = 7 + math.abs(math.sin(CurTime() * 4)) * 3
        surface.DrawCircle(tx, ty, pulse, 255, 226, 100, 255)
        draw.SimpleText(transitionDirection .. " NEXT", "LOD_Map_Small", tx, ty - 11,
            Color(255, 226, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end

    local objectiveA = state.objectiveA
    local objectiveB = state.objectiveB
    if objectiveA and objectiveA.z == gz then
        local markerX, markerY
        if objectiveB and objectiveB.z == gz then
            local a = Map.byKey[cellKey(objectiveA.x, objectiveA.y, objectiveA.z)]
            local b = Map.byKey[cellKey(objectiveB.x, objectiveB.y, objectiveB.z)]
            if a and b then
                local ax, ay = mapCellCenter(a, gridX, gridY, cellSize)
                local bx, by = mapCellCenter(b, gridX, gridY, cellSize)
                markerX, markerY = (ax + bx) * 0.5, (ay + by) * 0.5
            end
        else
            local a = Map.byKey[cellKey(objectiveA.x, objectiveA.y, objectiveA.z)]
            if a then markerX, markerY = mapCellCenter(a, gridX, gridY, cellSize) end
        end
        if markerX then drawObjectiveMarker(state, markerX, markerY) end
    end

    if Map.byKey[startKey] then
        local px = gridX + (gx - 0.5) * cellSize
        local py = gridY + (MC.Height - gy + 0.5) * cellSize
        drawPlayerMarker(px, py, 3)
    end

    local routeStatus = route and string.format("ROUTE READY — %d CELLS", math.max(0, #route - 1)) or "NO LEGAL ROUTE"
    draw.SimpleText(routeStatus, "LOD_Map_Small", panelX + 18, panelY + panelH - 31,
        route and Color(105, 210, 125) or Color(225, 100, 82), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

    draw.SimpleText("FOLLOW GOLD LINE • USE ↑/↓ AT RING • GREEN = OPEN", "LOD_Map_Small",
        panelX + 18, panelY + panelH - 18, Color(170, 174, 176), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end)


concommand.Add("lod_minimap_cache_status", function()
    local stats = Map.stats or {}
    local ready = Map.cache and Map.cache.indexedRevision == Map.cache.revision
    local frames = stats.paintFrames or 0
    local builds = stats.bfsBuilds or 0
    local hits = stats.bfsHits or 0
    local indexed = stats.floorIndexBuilds or 0
    local passed = ready and frames > 0 and builds > 0 and hits > 0 and builds < frames and indexed == 1
    print(string.format(
        "[LOD:MINIMAP-CACHE] frames=%d bfsBuilds=%d bfsHits=%d floorIndexBuilds=%d ready=%s result=%s",
        frames, builds, hits, indexed, tostring(ready), passed and "PASS" or "FAIL"
    ))
end)
