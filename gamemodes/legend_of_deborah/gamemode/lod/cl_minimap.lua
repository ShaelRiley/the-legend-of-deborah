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

    surface.SetDrawColor(58, 62, 64, 105)
    surface.DrawRect(gridX, gridY, gridSize, gridSize)

    local wallColor = Color(180, 184, 186, 220)
    local stairColor = Color(238, 194, 92, 230)

    for _, cell in ipairs(Map.cells) do
        if cell.z == gz then
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
                local stairText = up and down and "↕" or (up and "↑" or "↓")
                draw.SimpleText(stairText, "LOD_Map_Small", (x0 + x1) * 0.5, (y0 + y1) * 0.5,
                    stairColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    if Map.byKey[cellKey(gx, gy, gz)] then
        local px = gridX + (gx - 0.5) * cellSize
        local py = gridY + (MC.Height - gy + 0.5) * cellSize
        drawPlayerMarker(px, py, 3)
    end

    draw.SimpleText("stairs ↑/↓   gates: color=locked  green=open", "LOD_Map_Small",
        panelX + 18, panelY + panelH - 18, Color(170, 174, 176), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end)
