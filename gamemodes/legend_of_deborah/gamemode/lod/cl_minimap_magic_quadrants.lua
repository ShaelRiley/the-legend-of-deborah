LOD = LOD or {}
LOD.MinimapMagicClient = LOD.MinimapMagicClient or {}

local Client = LOD.MinimapMagicClient
local Map = LOD.Minimap
local MC = LOD.Config and LOD.Config.Maze
local Wall = LOD.WallVisualsClient
if not Map or not MC then return end

local HEARTBEAT_SECONDS = 0.45
local PANEL_W = 336
local PANEL_X_MARGIN = 20
local PANEL_Y = 96
local GRID_OFFSET_X = 26
local GRID_OFFSET_Y = 68
local GRID_SIZE = 284
local QUADRANT_ALPHA = 22
local QUADRANT_LETTERS = {"A", "B", "C", "D"}

Client.lastOpen = Client.lastOpen == true
Client.nextHeartbeat = Client.nextHeartbeat or 0
Client.palette = Client.palette or {}
Client.nextPaletteRefresh = Client.nextPaletteRefresh or 0

local function sendState(open)
    net.Start("LOD_MapMagicState")
    net.WriteBool(open == true)
    net.SendToServer()
end

local function currentGridPosition(ply)
    local pos = ply:GetPos()
    local x = math.floor(((pos.x - MC.Origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local y = math.floor(((pos.y - MC.Origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local z = math.floor(((pos.z - MC.Origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(x, 1, MC.Width), math.Clamp(y, 1, MC.Height), math.max(0, z)
end

local function quadrantForCell(x, y)
    local centerX = (MC.Width + 1) * 0.5
    local centerY = (MC.Height + 1) * 0.5
    local left = x <= centerX
    local upper = y >= centerY
    if upper then return left and 1 or 2 end
    return left and 3 or 4
end

local function refreshPalette(force)
    local now = CurTime()
    local world = Wall and Wall.world or nil
    if not world then return end
    if not force and world == Client.paletteWorldRef and now < (Client.nextPaletteRefresh or 0) then return end

    Client.nextPaletteRefresh = now + 0.50
    Client.paletteWorldRef = world
    local palette = {}

    for _, instance in ipairs(world) do
        if instance and instance.floor ~= nil and instance.quadrant then
            local floor = math.floor(tonumber(instance.floor) or 0)
            local quadrant = math.Clamp(math.floor(tonumber(instance.quadrant) or 1), 1, 4)
            palette[floor] = palette[floor] or {}
            if not palette[floor][quadrant] then
                local c = instance.bodyColor or instance.sectionColor
                if c then palette[floor][quadrant] = Color(c.r, c.g, c.b, 255) end
            end
        end
    end

    Client.palette = palette
end

local function closeForNoMagic()
    if not Map.open then return end
    Map.open = false
    sendState(false)
    surface.PlaySound("buttons/button10.wav")
    notification.AddLegacy("MAP CLOSED — NO MAGIC", NOTIFY_HINT, 2.0)
end

net.Receive("LOD_MapMagicForcedClose", function()
    local reason = net.ReadString()
    Map.open = false
    Client.lastOpen = false
    Client.nextHeartbeat = 0
    surface.PlaySound("buttons/button10.wav")
    if reason and reason ~= "" then notification.AddLegacy(reason, NOTIFY_HINT, 2.2) end
end)

hook.Add("Think", "LOD_MinimapMagicHeartbeat", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if Map.open and ply:GetNW2Float("LOD_Magic", 0) <= 0.001 then
        closeForNoMagic()
    end

    local open = Map.open == true
    if open ~= Client.lastOpen then
        Client.lastOpen = open
        sendState(open)
        Client.nextHeartbeat = CurTime() + HEARTBEAT_SECONDS
        if open then refreshPalette(true) end
    elseif open and CurTime() >= (Client.nextHeartbeat or 0) then
        sendState(true)
        Client.nextHeartbeat = CurTime() + HEARTBEAT_SECONDS
    end
end)

hook.Add("PostDrawHUD", "LOD_MinimapQuadrantPresentation", function()
    if not Map.open then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    refreshPalette(false)

    local gx, gy, gz = currentGridPosition(ply)
    local quadrant = quadrantForCell(gx, gy)
    local panelX = ScrW() - PANEL_W - PANEL_X_MARGIN
    local gridX = panelX + GRID_OFFSET_X
    local gridY = PANEL_Y + GRID_OFFSET_Y

    -- Match the odd 21x21 tie rule used by container quadrant labeling: the
    -- centerline belongs to left/up. This makes A/B/C/D map regions correspond to
    -- the same physical section vocabulary printed on the maze walls.
    local leftCells = math.ceil(MC.Width * 0.5)
    local upperCells = math.ceil(MC.Height * 0.5)
    local leftW = GRID_SIZE * leftCells / MC.Width
    local rightW = GRID_SIZE - leftW
    local topH = GRID_SIZE * upperCells / MC.Height
    local bottomH = GRID_SIZE - topH

    local floorPalette = Client.palette[gz] or {}
    local rects = {
        {x = gridX, y = gridY, w = leftW, h = topH, q = 1},
        {x = gridX + leftW, y = gridY, w = rightW, h = topH, q = 2},
        {x = gridX, y = gridY + topH, w = leftW, h = bottomH, q = 3},
        {x = gridX + leftW, y = gridY + topH, w = rightW, h = bottomH, q = 4}
    }

    for _, rect in ipairs(rects) do
        local c = floorPalette[rect.q]
        if c then
            surface.SetDrawColor(c.r, c.g, c.b, QUADRANT_ALPHA)
            surface.DrawRect(rect.x, rect.y, rect.w, rect.h)
        end
    end

    local qColor = floorPalette[quadrant] or Color(185, 188, 190)
    draw.SimpleText("QUADRANT " .. (QUADRANT_LETTERS[quadrant] or "?"),
        "LOD_Map_Small", panelX + PANEL_W - 16, PANEL_Y + 31,
        qColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end)

concommand.Add("lod_minimap_quadrant_status", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    refreshPalette(true)
    local gx, gy, gz = currentGridPosition(ply)
    local quadrant = quadrantForCell(gx, gy)
    local c = Client.palette[gz] and Client.palette[gz][quadrant]
    print(string.format("[LOD:MAP-QUADRANT] floor=%d cell=%d,%d quadrant=%s color=%s magic=%.1f open=%s",
        gz + 1, gx, gy, QUADRANT_LETTERS[quadrant] or "?",
        c and string.format("%d,%d,%d", c.r, c.g, c.b) or "pending",
        ply:GetNW2Float("LOD_Magic", 0), tostring(Map.open == true)))
end)
