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

local FLOOR_DIRS = {
    {dx = 0, dy = 1, bit = 0, gateShift = 0},
    {dx = 1, dy = 0, bit = 1, gateShift = 2},
    {dx = 0, dy = -1, bit = 2, gateShift = 4},
    {dx = -1, dy = 0, bit = 3, gateShift = 6}
}

local function edgeTraversable(cell, dir)
    if not bitOpen(cell.openings, dir.bit) then return false end
    local gateIndex = gateCode(cell.gates, dir.gateShift)
    if gateIndex <= 0 then return true end
    local state = LOD.ClientState or {}
    return state.gates and state.gates[gateIndex] == true or false
end

-- Current-floor reachability deliberately respects the live colored-gate state.
-- The map can therefore distinguish a real staircase that is available now from
-- one that belongs to a later locked sector without revealing hidden objectives.
local function floorReachability(gx, gy, gz)
    local startKey = cellKey(gx, gy, gz)
    if not Map.byKey[startKey] then return {}, {}, {}, nil, math.huge end

    local queue = {startKey}
    local head = 1
    local reached = {[startKey] = true}
    local previous = {}
    local distance = {[startKey] = 0}
    local nearestUp
    local nearestUpDist = math.huge

    while head <= #queue do
        local currentKey = queue[head]
        head = head + 1
        local current = Map.byKey[currentKey]
        if current then
            if bitOpen(current.openings, 4) and distance[currentKey] < nearestUpDist then
                nearestUp = currentKey
                nearestUpDist = distance[currentKey]
            end
            for _, dir in ipairs(FLOOR_DIRS) do
                if edgeTraversable(current, dir) then
                    local nk = cellKey(current.x + dir.dx, current.y + dir.dy, gz)
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

    return reached, previous, distance, nearestUp, nearestUpDist
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

local function cachedFloorData(gx, gy, gz)
    local startKey = cellKey(gx, gy, gz)
    local gateSignature = gateStateSignature()
    local cached = Map.cache.reach
    if cached and cached.revision == Map.cache.revision and
        cached.startKey == startKey and cached.gateSignature == gateSignature then
        Map.stats.bfsHits = Map.stats.bfsHits + 1
        return cached
    end

    local reached, previous, distance, nearestUp, nearestUpDist = floorReachability(gx, gy, gz)
    cached = {
        revision = Map.cache.revision,
        startKey = startKey,
        gateSignature = gateSignature,
        reached = reached,
        previous = previous,
        distance = distance,
        nearestUp = nearestUp,
        nearestUpDist = nearestUpDist,
        route = routeTo(previous, startKey, nearestUp)
    }
    Map.cache.reach = cached
    Map.stats.bfsBuilds = Map.stats.bfsBuilds + 1
    return cached
end

local function mapCellCenter(cell, gridX, gridY, cellSize)
    return gridX + (cell.x - 0.5) * cellSize,
        gridY + (MC.Height - cell.y + 0.5) * cellSize
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

    local panelW, panelH = 336, 356
    local panelX = ScrW() - panelW - 20
    local panelY = 96
    local gridX, gridY = panelX + 26, panelY + 48
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

    if (Map.receivedChunks or 0) < (Map.expectedChunks or 0) or #Map.cells == 0 then
        draw.SimpleText("LOADING MAP...", "LOD_Map_Title", panelX + panelW * 0.5, panelY + panelH * 0.5,
            Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    Map.stats.paintFrames = Map.stats.paintFrames + 1
    local floorData = cachedFloorData(gx, gy, gz)
    local reached = floorData.reached
    local nearestUp = floorData.nearestUp
    local nearestUpDist = floorData.nearestUpDist
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

    -- Developer mode gets a breadcrumb to the nearest currently reachable upward
    -- stair. Production Map loot remains a topology-reading aid rather than GPS.
    if ply:GetNW2Bool("LOD_DeveloperMode", false) and nearestUp then
        local route = floorData.route
        if route and #route > 1 then
            surface.SetDrawColor(248, 213, 105, 155)
            for i = 2, #route do
                local a = Map.byKey[route[i - 1]]
                local b = Map.byKey[route[i]]
                if a and b then
                    local ax, ay = mapCellCenter(a, gridX, gridY, cellSize)
                    local bx, by = mapCellCenter(b, gridX, gridY, cellSize)
                    surface.DrawLine(ax, ay, bx, by)
                end
            end
        end
        local stairCell = Map.byKey[nearestUp]
        if stairCell then
            local sx, sy = mapCellCenter(stairCell, gridX, gridY, cellSize)
            local pulse = 5 + math.abs(math.sin(CurTime() * 4)) * 3
            surface.DrawCircle(sx, sy, pulse, 248, 213, 105, 255)
        end
    end

    if Map.byKey[startKey] then
        local px = gridX + (gx - 0.5) * cellSize
        local py = gridY + (MC.Height - gy + 0.5) * cellSize
        drawPlayerMarker(px, py, 3)
    end

    if ply:GetNW2Bool("LOD_DeveloperMode", false) then
        local text = nearestUp and string.format("DEV: nearest reachable ↑ = %d cells", nearestUpDist) or
            "DEV: no reachable ↑ with current gates"
        draw.SimpleText(text, "LOD_Map_Small", panelX + 18, panelY + panelH - 31,
            nearestUp and Color(238, 194, 92) or Color(205, 120, 90), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end

    draw.SimpleText("stairs: bright=reachable  dim=behind lock   gates: green=open", "LOD_Map_Small",
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
