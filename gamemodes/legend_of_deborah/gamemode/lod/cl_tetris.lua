LOD = LOD or {}
LOD.TetrisClient = LOD.TetrisClient or {}

local Client = LOD.TetrisClient
local Tetris = LOD.Tetris

surface.CreateFont("LOD_Tetris_Header", {
    font = "DejaVu Sans",
    size = 30,
    weight = 900
})
surface.CreateFont("LOD_Tetris_Label", {
    font = "DejaVu Sans",
    size = 17,
    weight = 750
})
surface.CreateFont("LOD_Tetris_Feedback", {
    font = "DejaVu Sans",
    size = 22,
    weight = 900
})

local pieceColors = {
    [1] = Color(92, 185, 205),
    [2] = Color(222, 190, 70),
    [3] = Color(157, 104, 190),
    [4] = Color(94, 166, 108),
    [5] = Color(190, 78, 73),
    [6] = Color(78, 112, 180),
    [7] = Color(215, 132, 61)
}

local feedbackNames = {
    [1] = "SINGLE  +10 HP",
    [2] = "DOUBLE  +30 HP",
    [3] = "TRIPLE  +50 HP",
    [4] = "TETRIS  +80 HP"
}

local function readBoard()
    local board = {}
    for y = 1, Tetris.Height do
        board[y] = {}
        for x = 1, Tetris.Width do
            board[y][x] = net.ReadUInt(3)
        end
    end
    return board
end

net.Receive("LOD_TetrisState", function()
    local active = net.ReadBool()
    Client.active = active
    if not active then return end

    Client.kind = net.ReadUInt(2)
    Client.board = readBoard()
    Client.currentId = net.ReadUInt(3)
    Client.currentRotation = net.ReadUInt(2) + 1
    Client.currentX = net.ReadInt(6)
    Client.currentY = net.ReadInt(6)
    Client.nextPiece = net.ReadUInt(3)
    Client.bonus = net.ReadUInt(16)
    Client.firstClear = net.ReadBool()

    local serial = net.ReadUInt(8)
    local lines = net.ReadUInt(3)
    Client.resetCount = net.ReadUInt(8)
    if serial ~= (Client.clearSerial or 0) then
        Client.clearSerial = serial
        Client.feedback = feedbackNames[lines]
        Client.feedbackUntil = CurTime() + 1.6
    end
end)

local function sendAction(action)
    if not Client.active then return end
    net.Start("LOD_TetrisInput")
    net.WriteUInt(action, 3)
    net.SendToServer()
end

local bindActions = {
    {"+moveleft", 1},
    {"+left", 1},
    {"+moveright", 2},
    {"+right", 2},
    {"+forward", 3},
    {"+back", 4},
    {"+jump", 5}
}

hook.Add("PlayerBindPress", "LOD_DeathTetrisControls", function(ply, bind, pressed)
    if not pressed or not Client.active or not IsValid(ply) or ply:Alive() then return end
    local lower = string.lower(bind or "")
    for _, mapping in ipairs(bindActions) do
        if string.find(lower, mapping[1], 1, true) then
            sendAction(mapping[2])
            return true
        end
    end
end)

local function drawCell(x, y, cell, value)
    local color = pieceColors[value] or Color(130, 130, 130)
    surface.SetDrawColor(color.r, color.g, color.b, 235)
    surface.DrawRect(x + 1, y + 1, cell - 2, cell - 2)
    surface.SetDrawColor(245, 220, 155, 55)
    surface.DrawRect(x + 2, y + 2, math.max(1, cell - 4), 2)
end

local function drawPiecePreview(pieceId, x, y, cell)
    if not pieceId or pieceId <= 0 then return end
    for _, block in ipairs(Tetris.CellsFor(pieceId, 1, 0, 0)) do
        drawCell(x + block.x * cell, y + block.y * cell, cell, pieceId)
    end
end

function Client:DrawDeathState(ply, state)
    if not self.active or not self.board then return false end

    local sw, sh = ScrW(), ScrH()
    draw.RoundedBox(0, 0, 0, sw, sh, Color(4, 6, 8, 218))

    local cell = math.Clamp(math.floor(sh * 0.023), 14, 19)
    local boardW = Tetris.Width * cell
    local boardH = Tetris.Height * cell
    local sideW = math.max(205, math.floor(boardW * 0.95))
    local panelW = boardW + sideW + 54
    local panelH = boardH + 112
    local panelX = math.floor((sw - panelW) * 0.5)
    local panelY = math.max(92, math.floor((sh - panelH) * 0.5))
    local boardX = panelX + 24
    local boardY = panelY + 78
    local sideX = boardX + boardW + 28

    draw.RoundedBox(5, panelX, panelY, panelW, panelH, Color(12, 15, 17, 255))
    surface.SetDrawColor(220, 140, 48, 240)
    surface.DrawRect(panelX, panelY, 5, panelH)
    surface.DrawRect(panelX, panelY, panelW, 3)

    local headline = self.firstClear and "The dead love Tetris" or "YOU DIED"
    local headlineColor = self.firstClear and Color(245, 210, 115) or Color(235, 105, 90)
    draw.SimpleText(headline, "LOD_Tetris_Header", panelX + 24, panelY + 18,
        headlineColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local remaining = math.max(0, ply:GetNW2Float("LOD_RespawnRemaining", 0))
    draw.SimpleText(string.format("RESPAWN  %02d", math.ceil(remaining)), "LOD_Tetris_Label",
        panelX + panelW - 22, panelY + 24, Color(235, 235, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    surface.SetDrawColor(45, 49, 51, 255)
    surface.DrawRect(boardX - 2, boardY - 2, boardW + 4, boardH + 4)
    surface.SetDrawColor(18, 21, 23, 255)
    surface.DrawRect(boardX, boardY, boardW, boardH)

    for y = 1, Tetris.Height do
        for x = 1, Tetris.Width do
            local value = self.board[y][x] or 0
            if value > 0 then
                drawCell(boardX + (x - 1) * cell, boardY + (y - 1) * cell, cell, value)
            else
                surface.SetDrawColor(58, 62, 64, 85)
                surface.DrawOutlinedRect(boardX + (x - 1) * cell, boardY + (y - 1) * cell, cell, cell, 1)
            end
        end
    end

    if self.currentId and self.currentId > 0 then
        for _, block in ipairs(Tetris.CellsFor(self.currentId, self.currentRotation, self.currentX, self.currentY)) do
            if block.y >= 1 and block.y <= Tetris.Height and block.x >= 1 and block.x <= Tetris.Width then
                drawCell(boardX + (block.x - 1) * cell, boardY + (block.y - 1) * cell, cell, self.currentId)
            end
        end
    end

    draw.SimpleText("NEXT", "LOD_Tetris_Label", sideX, boardY, Color(238, 194, 92), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    drawPiecePreview(self.nextPiece, sideX + 4, boardY + 34, math.max(12, cell - 2))

    draw.SimpleText("NEXT-LIFE OVERFILL", "LOD_Tetris_Label", sideX, boardY + 118,
        Color(205, 205, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("+" .. tostring(self.bonus or 0) .. " HP", "LOD_Tetris_Feedback", sideX, boardY + 143,
        Color(245, 210, 115), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    if self.feedback and CurTime() < (self.feedbackUntil or 0) then
        draw.SimpleText(self.feedback, "LOD_Tetris_Feedback", sideX, boardY + 194,
            Color(245, 210, 115), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local controlsY = boardY + boardH - 112
    draw.SimpleText("CONTROLS", "LOD_Tetris_Label", sideX, controlsY,
        Color(238, 194, 92), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("LEFT / RIGHT   move", "LOD_HUD_Small", sideX, controlsY + 27,
        Color(210, 210, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("UP / FORWARD   rotate", "LOD_HUD_Small", sideX, controlsY + 49,
        Color(210, 210, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("DOWN / BACK   soft drop", "LOD_HUD_Small", sideX, controlsY + 71,
        Color(210, 210, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("JUMP / A   hard drop", "LOD_HUD_Small", sideX, controlsY + 93,
        Color(210, 210, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    return true
end

hook.Add("PostDrawHUD", "LOD_DeathTetrisPresentation", function()
    local ply = LocalPlayer()
    if not Client.active or not IsValid(ply) or ply:Alive() then return end
    Client:DrawDeathState(ply, LOD.ClientState or {})
end)
