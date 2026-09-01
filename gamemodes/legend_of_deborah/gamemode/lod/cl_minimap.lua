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
local GC = LOD.Config.Geometry
local mapKeyWasDown = false
local MAP_REQUEST_RETRY = 0.75
local MAP_RT_SIZE = 256

Map.cache = Map.cache or {
    revision = 0,
    indexedRevision = -1,
    floorCells = {},
    floorStairs = {},
    floorGates = {},
    floorJail = {},
    adjacency = {},
    reach = nil,
    topologyRevision = -1,
    topologyFloor = -1
}
Map.stats = Map.stats or {
    paintFrames = 0,
    bfsBuilds = 0,
    bfsHits = 0,
    floorIndexBuilds = 0,
    topologyBuilds = 0,
    mapRequests = 0,
    mapCacheReopens = 0
}

local topologyRT = GetRenderTarget("lod_minimap_topology_rt", MAP_RT_SIZE, MAP_RT_SIZE)
local topologyMaterial = CreateMaterial("lod_minimap_topology_rt_mat", "UnlitGeneric", {
    ["$basetexture"] = topologyRT:GetName(),
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

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

local COLORS = {
    panel = Color(12, 15, 17, 226),
    accent = Color(220, 140, 48, 235),
    title = Color(238, 194, 92),
    muted = Color(185, 188, 190),
    objective = Color(248, 213, 105),
    loading = Color(220, 220, 220),
    grid = Color(58, 62, 64, 255),
    cell = Color(30, 34, 36, 255),
    wall = Color(180, 184, 186, 220),
    stairReachable = Color(248, 213, 105, 255),
    stairLocked = Color(118, 105, 72, 145),
    route = Color(255, 215, 58, 225),
    routeBright = Color(255, 226, 100, 255),
    open = Color(105, 185, 115, 245),
    jailClosed = Color(205, 205, 215, 245),
    routeReady = Color(105, 210, 125),
    routeBlocked = Color(225, 100, 82),
    footer = Color(170, 174, 176),
    deborah = Color(245, 180, 225, 255),
    player = Color(248, 213, 105, 255)
}

local gateColors = {
    Color(205, 54, 54),
    Color(64, 118, 210),
    Color(224, 190, 52)
}
local OBJECTIVE_LABELS = {[1] = "CARD", [2] = "GATE", [3] = "KEY", [4] = "JAIL", [5] = "D"}

local function cellKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function currentClientLevel()
    local state = LOD.ClientState or {}
    return tonumber(state.level) or 0
end

local function hasAccess(ply)
    if not IsValid(ply) then return false end
    if ply:GetNW2Bool("LOD_DeveloperMode", false) then return true end
    if not ply:GetNW2Bool("LOD_MapUnlocked", false) then return false end
    local unlockedLevel = ply:GetNW2Int("LOD_MapUnlockedLevel", 0)
    local level = currentClientLevel()
    return level > 0 and unlockedLevel == level
end

local function mapReadyForLevel(level)
    return level and level > 0
        and Map.level == level
        and (Map.expectedChunks or 0) > 0
        and (Map.receivedChunks or 0) >= (Map.expectedChunks or 0)
        and #Map.cells > 0
        and Map.cache.indexedRevision == Map.cache.revision
end

local function resetCacheStats()
    Map.stats.paintFrames = 0
    Map.stats.bfsBuilds = 0
    Map.stats.bfsHits = 0
    Map.stats.floorIndexBuilds = 0
    Map.stats.topologyBuilds = 0
    Map.stats.mapRequests = 0
    Map.stats.mapCacheReopens = 0
end

local function invalidateGraphCache()
    Map.cache.revision = (Map.cache.revision or 0) + 1
    Map.cache.indexedRevision = -1
    Map.cache.floorCells = {}
    Map.cache.floorStairs = {}
    Map.cache.floorGates = {}
    Map.cache.floorJail = {}
    Map.cache.adjacency = {}
    Map.cache.reach = nil
    Map.cache.topologyRevision = -1
    Map.cache.topologyFloor = -1
    resetCacheStats()
end

local function requestMap(force)
    local now = CurTime()
    if not force and now < (Map.nextRequestAt or 0) then return false end
    Map.nextRequestAt = now + MAP_REQUEST_RETRY
    Map.stats.mapRequests = (Map.stats.mapRequests or 0) + 1
    net.Start("LOD_MapRequest")
    net.SendToServer()
    return true
end

local function currentGridPosition(ply)
    local pos = ply:GetPos()
    local x = math.floor(((pos.x - MC.Origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local y = math.floor(((pos.y - MC.Origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local z = math.floor(((pos.z - MC.Origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(x, 1, MC.Width), math.Clamp(y, 1, MC.Height), math.max(0, z)
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

local STAIR_DIRECTIONS = {
    [0] = {name = "N", dx = 0, dy = 1},
    [1] = {name = "E", dx = 1, dy = 0},
    [2] = {name = "S", dx = 0, dy = -1},
    [3] = {name = "W", dx = -1, dy = 0}
}

local function sameEdge(aKey, bKey, edgeA, edgeB)
    if not edgeA or not edgeB then return false end
    return (aKey == edgeA and bKey == edgeB) or (aKey == edgeB and bKey == edgeA)
end

local function sortedEdgeKey(aKey, bKey)
    return aKey < bKey and (aKey .. "|" .. bKey) or (bKey .. "|" .. aKey)
end

local function buildGraphIndex()
    if Map.cache.indexedRevision == Map.cache.revision then return end

    local floorCells = {}
    local floorStairs = {}
    local floorGates = {}
    local floorJail = {}
    local adjacency = {}
    local seenGates = {}
    local seenJail = {}
    local jailA = Map.jailAKey
    local jailB = Map.jailBKey

    for _, cell in ipairs(Map.cells) do
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
                local neighbor = Map.byKey[neighborKey]
                if neighbor then
                    local gateIndex = dir.gateShift ~= nil and gateCode(cell.gates, dir.gateShift) or 0
                    local isJail = sameEdge(cell.key, neighborKey, jailA, jailB)
                    adjacency[cell.key][#adjacency[cell.key] + 1] = {
                        key = neighborKey,
                        gate = gateIndex,
                        jail = isJail
                    }

                    if dir.gateShift ~= nil and gateIndex > 0 then
                        local ek = sortedEdgeKey(cell.key, neighborKey)
                        if not seenGates[ek] then
                            seenGates[ek] = true
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
                        local ek = sortedEdgeKey(cell.key, neighborKey)
                        if not seenJail[ek] then
                            seenJail[ek] = true
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
    Map.stats.floorIndexBuilds = (Map.stats.floorIndexBuilds or 0) + 1
end

net.Receive("LOD_MapBegin", function()
    Map.level = net.ReadUInt(20)
    Map.layers = net.ReadUInt(3)
    Map.expectedCells = net.ReadUInt(16)
    Map.expectedChunks = net.ReadUInt(8)

    MC.Origin = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())

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
            gates = net.ReadUInt(8),
            stairDirection = net.ReadUInt(2)
        }
        cell.key = cellKey(cell.x, cell.y, cell.z)
        Map.cells[#Map.cells + 1] = cell
        Map.byKey[cell.key] = cell
    end

    Map.receivedChunks = math.max(Map.receivedChunks or 0, chunkIndex)
    if Map.receivedChunks >= (Map.expectedChunks or 0) then
        buildGraphIndex()
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
    if Map.open then
        local level = currentClientLevel()
        if mapReadyForLevel(level) then
            Map.stats.mapCacheReopens = (Map.stats.mapCacheReopens or 0) + 1
        else
            requestMap(true)
        end
    end
end)

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

local function graphReachability(startKey)
    if not Map.byKey[startKey] then return {}, {} end

    local state = LOD.ClientState or {}
    local gates = state.gates or {}
    local jailOpen = state.jailDoorOpen == true
    local queue = {startKey}
    local head = 1
    local reached = {[startKey] = true}
    local previous = {}

    while head <= #queue do
        local currentKey = queue[head]
        head = head + 1
        for _, edge in ipairs(Map.cache.adjacency[currentKey] or {}) do
            local traversable = (not edge.jail or jailOpen)
                and (edge.gate <= 0 or gates[edge.gate] == true)
            if traversable and not reached[edge.key] then
                reached[edge.key] = true
                previous[edge.key] = currentKey
                queue[#queue + 1] = edge.key
            end
        end
    end

    return reached, previous
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

local function buildRouteDisplay(route, gz, breadcrumbCells)
    local segments = {}
    local transitionCell
    local transitionNextCell
    local transitionDirection

    if route and #route > 0 then
        local last = math.min(#route, 1 + math.max(2, math.floor(tonumber(breadcrumbCells) or 6)))
        for i = 2, last do
            local a = Map.byKey[route[i - 1]]
            local b = Map.byKey[route[i]]
            if not a or not b or a.z ~= gz then break end
            if b.z ~= gz then
                transitionCell = a
                transitionNextCell = b
                transitionDirection = b.z > a.z and "↑" or "↓"
                break
            end
            segments[#segments + 1] = {a = a, b = b}
        end
    end

    return segments, transitionCell, transitionNextCell, transitionDirection
end

local function objectiveFields(state)
    local a = state.objectiveA
    local b = state.objectiveB
    return state.objectiveStage or 0, state.objectiveKind or 0,
        a and a.x or -1, a and a.y or -1, a and a.z or -1,
        b and b.x or -1, b and b.y or -1, b and b.z or -1
end

local function cachedRouteData(gx, gy, gz)
    local startKey = cellKey(gx, gy, gz)
    local gateSignature = gateStateSignature()
    local state = LOD.ClientState or {}
    local jailOpen = state.jailDoorOpen == true
    local stage, kind, ax, ay, az, bx, by, bz = objectiveFields(state)
    local localPlayer = LocalPlayer()
    local breadcrumbCells = IsValid(localPlayer)
        and localPlayer:GetNW2Int("LOD_RPGBreadcrumbCells", 6) or 6
    local cached = Map.cache.reach

    if cached and cached.revision == Map.cache.revision
        and cached.startKey == startKey
        and cached.gateSignature == gateSignature
        and cached.jailOpen == jailOpen
        and cached.stage == stage and cached.kind == kind
        and cached.ax == ax and cached.ay == ay and cached.az == az
        and cached.bx == bx and cached.by == by and cached.bz == bz
        and cached.breadcrumbCells == breadcrumbCells
    then
        Map.stats.bfsHits = (Map.stats.bfsHits or 0) + 1
        return cached
    end

    local reached, previous = graphReachability(startKey)
    local target = state.objectiveA
    local targetKey = target and cellKey(target.x, target.y, target.z) or nil
    local route = targetKey and reached[targetKey] and routeTo(previous, startKey, targetKey) or nil
    local segments, transitionCell, transitionNextCell, transitionDirection =
        buildRouteDisplay(route, gz, breadcrumbCells)
    cached = {
        revision = Map.cache.revision,
        startKey = startKey,
        gateSignature = gateSignature,
        jailOpen = jailOpen,
        stage = stage,
        kind = kind,
        ax = ax, ay = ay, az = az,
        bx = bx, by = by, bz = bz,
        breadcrumbCells = breadcrumbCells,
        reached = reached,
        previous = previous,
        targetKey = targetKey,
        route = route,
        routeStatus = route and string.format("BREADCRUMB — %d OF %d CELLS",
            math.min(breadcrumbCells, math.max(0, #route - 1)), math.max(0, #route - 1))
            or "NO LEGAL ROUTE",
        segments = segments,
        transitionCell = transitionCell,
        transitionNextCell = transitionNextCell,
        transitionDirection = transitionDirection
    }
    Map.cache.reach = cached
    Map.stats.bfsBuilds = (Map.stats.bfsBuilds or 0) + 1
    return cached
end

local function mapCellCenter(cell, gridX, gridY, cellSize)
    return gridX + (cell.x - 0.5) * cellSize,
        gridY + (MC.Height - cell.y + 0.5) * cellSize
end

local function cellWorldCenter(cell)
    return MC.Origin + Vector(
        (cell.x - (MC.Width + 1) * 0.5) * MC.CellSize,
        (cell.y - (MC.Height + 1) * 0.5) * MC.CellSize,
        cell.z * MC.LevelHeight
    )
end

local function physicalStairGuide(fromCell, toCell, gridX, gridY, cellSize)
    if not fromCell or not toCell or fromCell.z == toCell.z then return nil end
    local lower = fromCell.z < toCell.z and fromCell or toCell
    local dir = STAIR_DIRECTIONS[lower.stairDirection or fromCell.stairDirection or 0]
    if not dir then return nil end

    local ascending = toCell.z > fromCell.z
    local offset = ascending and -(GC.StairRun + 40) or 52
    local fractionalX = lower.x + dir.dx * offset / MC.CellSize
    local fractionalY = lower.y + dir.dy * offset / MC.CellSize
    local mapX = gridX + (fractionalX - 0.5) * cellSize
    local mapY = gridY + (MC.Height - fractionalY + 0.5) * cellSize
    local world = cellWorldCenter(lower) + Vector(dir.dx * offset, dir.dy * offset,
        ascending and 2 or (MC.LevelHeight + 2))

    return {
        ascending = ascending,
        symbol = ascending and "↑" or "↓",
        mapX = mapX,
        mapY = mapY,
        world = world,
        travelX = ascending and dir.dx or -dir.dx,
        travelY = ascending and dir.dy or -dir.dy
    }
end

local function relativeTurn(targetYaw)
    local delta = math.AngleDifference(targetYaw, EyeAngles().y)
    local magnitude = math.abs(delta)
    if magnitude <= 22 then return "STRAIGHT AHEAD" end
    if magnitude >= 158 then return "TURN AROUND" end
    local side = delta > 0 and "LEFT" or "RIGHT"
    if magnitude <= 68 then return "BEAR " .. side end
    if magnitude <= 112 then return "TURN " .. side end
    return "SHARP " .. side
end

local function stairInstruction(ply, guide)
    local delta = guide.world - ply:GetPos()
    local distance = math.floor(math.sqrt(delta.x * delta.x + delta.y * delta.y) + 0.5)
    local targetYaw
    local action
    if distance > 72 then
        targetYaw = math.deg(math.atan2(delta.y, delta.x))
        action = relativeTurn(targetYaw)
    else
        targetYaw = math.deg(math.atan2(guide.travelY, guide.travelX))
        local turn = relativeTurn(targetYaw)
        local verb = guide.ascending and "CLIMB" or "DESCEND"
        action = turn == "STRAIGHT AHEAD" and verb or (turn .. ", THEN " .. verb)
    end
    return string.format("STAIRS %s — %s — %du", guide.symbol, action, distance)
end

local function drawThickLine(x1, y1, x2, y2, color)
    surface.SetDrawColor(color)
    surface.DrawLine(x1, y1, x2, y2)
    surface.DrawLine(x1 + 1, y1, x2 + 1, y2)
    surface.DrawLine(x1, y1 + 1, x2, y2 + 1)
end

local function drawPlayerMarker(px, py, size)
    local yaw = math.rad(EyeAngles().y)
    local dx = math.cos(yaw)
    local dy = -math.sin(yaw)
    surface.SetDrawColor(COLORS.player)
    surface.DrawCircle(px, py, size, COLORS.player.r, COLORS.player.g, COLORS.player.b, COLORS.player.a)
    surface.DrawLine(px, py, px + dx * (size + 7), py + dy * (size + 7))
end

local function drawObjectiveMarker(state, x, y)
    local pulse = 6 + math.abs(math.sin(CurTime() * 4.5)) * 3
    local kind = state.objectiveKind or 0
    local color = COLORS.routeBright
    if kind == 1 then
        local cardIndex = math.Clamp(math.floor(((state.objectiveStage or 1) + 1) / 2), 1, 3)
        color = gateColors[cardIndex] or color
    elseif kind == 5 then
        color = COLORS.deborah
    end
    surface.DrawCircle(x, y, pulse, color.r, color.g, color.b, color.a)
    surface.DrawCircle(x, y, pulse + 1, color.r, color.g, color.b, 180)
    draw.SimpleText(OBJECTIVE_LABELS[kind] or "GOAL", "LOD_Map_Small", x, y - 11,
        color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end

local function segmentScreen(entry, gridX, gridY, cellSize)
    local x0 = gridX + (entry.x - 1) * cellSize
    local y0 = gridY + (MC.Height - entry.y) * cellSize
    local x1 = x0 + cellSize
    local y1 = y0 + cellSize

    if entry.dx == 1 then return x1, y0, x1, y1 end
    if entry.dx == -1 then return x0, y0, x0, y1 end
    if entry.dy == 1 then return x0, y0, x1, y0 end
    return x0, y1, x1, y1
end

local function renderStaticTopology(gz)
    if Map.cache.indexedRevision ~= Map.cache.revision then return false end
    local cells = Map.cache.floorCells[gz]
    if not cells then return false end

    local cellSize = MAP_RT_SIZE / math.max(MC.Width, MC.Height)
    render.PushRenderTarget(topologyRT)
    render.Clear(COLORS.grid.r, COLORS.grid.g, COLORS.grid.b, 255, true, true)
    cam.Start2D()

    for _, cell in ipairs(cells) do
        local x0 = (cell.x - 1) * cellSize
        local y0 = (MC.Height - cell.y) * cellSize
        local x1 = x0 + cellSize
        local y1 = y0 + cellSize

        surface.SetDrawColor(COLORS.cell)
        surface.DrawRect(x0 + 1, y0 + 1, math.max(1, cellSize - 2), math.max(1, cellSize - 2))
        surface.SetDrawColor(COLORS.wall)
        if not bitOpen(cell.openings, 0) then surface.DrawLine(x0, y0, x1, y0) end
        if not bitOpen(cell.openings, 1) then surface.DrawLine(x1, y0, x1, y1) end
        if not bitOpen(cell.openings, 2) then surface.DrawLine(x0, y1, x1, y1) end
        if not bitOpen(cell.openings, 3) then surface.DrawLine(x0, y0, x0, y1) end
    end

    cam.End2D()
    render.PopRenderTarget()

    Map.cache.topologyRevision = Map.cache.revision
    Map.cache.topologyFloor = gz
    Map.stats.topologyBuilds = (Map.stats.topologyBuilds or 0) + 1
    return true
end

-- Render the expensive, fully static floor topology only when the current floor
-- changes or new map data arrives. HUDPaint then composites one cached texture
-- and only a handful of dynamic overlays each frame.
hook.Add("PostRender", "LOD_MinimapTopologyCache", function()
    if not Map.open or Map.cache.indexedRevision ~= Map.cache.revision then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local _, _, gz = currentGridPosition(ply)
    gz = math.Clamp(gz, 0, math.max(0, (Map.layers or 1) - 1))
    if Map.cache.topologyRevision == Map.cache.revision and Map.cache.topologyFloor == gz then return end
    renderStaticTopology(gz)
end)

hook.Add("HUDPaint", "LOD_MinimapHUD", function()
    if not Map.open then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or not hasAccess(ply) then
        Map.open = false
        return
    end

    local state = LOD.ClientState or {}
    local level = tonumber(state.level) or 0
    if not mapReadyForLevel(level) then
        requestMap(false)
    end

    local panelW, panelH = 336, 408
    local panelX = ScrW() - panelW - 20
    local panelY = 96
    local gridX, gridY = panelX + 26, panelY + 68
    local gridSize = 284
    local cellSize = gridSize / math.max(MC.Width, MC.Height)
    local gx, gy, gz = currentGridPosition(ply)
    gz = math.Clamp(gz, 0, math.max(0, (Map.layers or 1) - 1))

    draw.RoundedBox(4, panelX, panelY, panelW, panelH, COLORS.panel)
    surface.SetDrawColor(COLORS.accent)
    surface.DrawRect(panelX, panelY, 4, panelH)

    draw.SimpleText("LABYRINTH MAP", "LOD_Map_Title", panelX + 18, panelY + 12,
        COLORS.title, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(string.format("FLOOR %d / %d    M — CLOSE", gz + 1, math.max(1, Map.layers or 1)),
        "LOD_Map_Small", panelX + panelW - 16, panelY + 17,
        COLORS.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    local goalFloor = state.objectiveA and (state.objectiveA.z + 1) or nil
    local objectiveLine = state.objective or "EXPEDITION"
    if goalFloor then objectiveLine = objectiveLine .. string.format("  [F%d]", goalFloor) end
    draw.SimpleText(objectiveLine, "LOD_Map_Small", panelX + 18, panelY + 42,
        COLORS.objective, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    if not mapReadyForLevel(level) then
        draw.SimpleText("LOADING MAP...", "LOD_Map_Title", panelX + panelW * 0.5, panelY + panelH * 0.5,
            COLORS.loading, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    if Map.cache.topologyRevision ~= Map.cache.revision or Map.cache.topologyFloor ~= gz then
        draw.SimpleText("PREPARING FLOOR...", "LOD_Map_Small", panelX + panelW * 0.5, panelY + panelH * 0.5,
            COLORS.loading, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    Map.stats.paintFrames = (Map.stats.paintFrames or 0) + 1
    local floorData = cachedRouteData(gx, gy, gz)
    local reached = floorData.reached
    local startKey = floorData.startKey

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(topologyMaterial)
    surface.DrawTexturedRect(gridX, gridY, gridSize, gridSize)

    -- Gates are the only dynamic wall-colored overlays and there are at most a
    -- handful per generated floor. Each canonical gate edge is stored once.
    for _, gate in ipairs(Map.cache.floorGates[gz] or {}) do
        local x0, y0, x1, y1 = segmentScreen(gate, gridX, gridY, cellSize)
        local opened = state.gates and state.gates[gate.gate]
        local color = opened and COLORS.open or (gateColors[gate.gate] or COLORS.title)
        drawThickLine(x0, y0, x1, y1, color)
    end

    for _, jail in ipairs(Map.cache.floorJail[gz] or {}) do
        local x0, y0, x1, y1 = segmentScreen(jail, gridX, gridY, cellSize)
        drawThickLine(x0, y0, x1, y1, state.jailDoorOpen and COLORS.open or COLORS.jailClosed)
    end

    for _, stair in ipairs(Map.cache.floorStairs[gz] or {}) do
        local cell = stair.cell
        local x0 = gridX + (cell.x - 1) * cellSize
        local y0 = gridY + (MC.Height - cell.y) * cellSize
        local x1 = x0 + cellSize
        local y1 = y0 + cellSize
        local stairText = stair.up and stair.down and "↕" or (stair.up and "↑" or "↓")
        local color = reached[stair.key] and COLORS.stairReachable or COLORS.stairLocked
        draw.SimpleText(stairText, "LOD_Map_Small", (x0 + x1) * 0.5, (y0 + y1) * 0.5,
            color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local route = floorData.route
    for _, segment in ipairs(floorData.segments or {}) do
        local ax, ay = mapCellCenter(segment.a, gridX, gridY, cellSize)
        local bx, by = mapCellCenter(segment.b, gridX, gridY, cellSize)
        drawThickLine(ax, ay, bx, by, COLORS.route)
        surface.DrawCircle(bx, by, 2, COLORS.routeBright.r, COLORS.routeBright.g, COLORS.routeBright.b, 235)
    end

    local transitionCell = floorData.transitionCell
    local transitionNextCell = floorData.transitionNextCell
    local transitionDirection = floorData.transitionDirection
    local transitionGuide
    if transitionCell and transitionNextCell then
        transitionGuide = physicalStairGuide(transitionCell, transitionNextCell, gridX, gridY, cellSize)
        local cellX, cellY = mapCellCenter(transitionCell, gridX, gridY, cellSize)
        local tx = transitionGuide and transitionGuide.mapX or cellX
        local ty = transitionGuide and transitionGuide.mapY or cellY
        drawThickLine(cellX, cellY, tx, ty, COLORS.route)
        local pulse = 7 + math.abs(math.sin(CurTime() * 4)) * 3
        surface.DrawCircle(tx, ty, pulse, COLORS.routeBright.r, COLORS.routeBright.g, COLORS.routeBright.b, 255)
        if transitionGuide then
            local arrowLength = cellSize * 0.24
            local arrowX = tx + transitionGuide.travelX * arrowLength
            local arrowY = ty - transitionGuide.travelY * arrowLength
            drawThickLine(tx, ty, arrowX, arrowY, COLORS.routeBright)
        end
        draw.SimpleText(transitionDirection .. " STAIRS", "LOD_Map_Small", tx, ty - 11,
            COLORS.routeBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
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

    draw.SimpleText(floorData.routeStatus, "LOD_Map_Small", panelX + 18, panelY + panelH - 47,
        route and COLORS.routeReady or COLORS.routeBlocked, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

    if transitionGuide then
        draw.SimpleText(stairInstruction(ply, transitionGuide), "LOD_Map_Small",
            panelX + 18, panelY + panelH - 32, COLORS.routeBright,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end

    draw.SimpleText("FOLLOW GOLD LINE • FOLLOW STAIR ARROW • GREEN = OPEN", "LOD_Map_Small",
        panelX + 18, panelY + panelH - 18, COLORS.footer, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end)

concommand.Add("lod_minimap_cache_status", function()
    local stats = Map.stats or {}
    local ready = Map.cache and Map.cache.indexedRevision == Map.cache.revision
    local frames = stats.paintFrames or 0
    local builds = stats.bfsBuilds or 0
    local hits = stats.bfsHits or 0
    local indexed = stats.floorIndexBuilds or 0
    local topology = stats.topologyBuilds or 0
    local requests = stats.mapRequests or 0
    local reopens = stats.mapCacheReopens or 0
    local passed = ready and frames > 0 and builds > 0 and hits > 0
        and builds < frames and indexed == 1 and topology > 0
    print(string.format(
        "[LOD:MINIMAP-CACHE] frames=%d bfsBuilds=%d bfsHits=%d floorIndexBuilds=%d topologyBuilds=%d mapRequests=%d cachedReopens=%d ready=%s result=%s",
        frames, builds, hits, indexed, topology, requests, reopens, tostring(ready), passed and "PASS" or "FAIL"
    ))
end)
