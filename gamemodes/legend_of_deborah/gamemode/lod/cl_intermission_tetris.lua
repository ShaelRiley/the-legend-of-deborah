LOD = LOD or {}
LOD.IntermissionTetrisClient = LOD.IntermissionTetrisClient or {}

local Client = LOD.IntermissionTetrisClient
local Tetris = LOD.Tetris
if not Tetris then return end

surface.CreateFont("LOD_IntermissionTetrisTitle", {
    font = "DejaVu Sans",
    size = 24,
    weight = 900
})
surface.CreateFont("LOD_IntermissionTetrisBody", {
    font = "DejaVu Sans",
    size = 15,
    weight = 700
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

local eventSounds = {
    [1] = "buttons/button15.wav",
    [2] = "physics/metal/metal_box_impact_soft2.wav",
    [3] = "physics/metal/metal_box_impact_soft1.wav",
    [4] = "buttons/button9.wav",
    [5] = "buttons/button10.wav"
}

local fWasDown = false

local function readBoard()
    local board = {}
    for y = 1, Tetris.Height do
        board[y] = {}
        for x = 1, Tetris.Width do board[y][x] = net.ReadUInt(3) end
    end
    return board
end

net.Receive("LOD_IntermissionTetrisState", function()
    local active = net.ReadBool()
    local available = net.ReadBool()
    local remaining = net.ReadFloat()
    local wasActive = Client.active == true

    Client.active = active
    Client.available = available
    Client.endsAt = CurTime() + math.max(0, remaining)

    if not active then
        Client.board = nil
        Client.gameOver = false
        Client.feedback = nil
        if not available then
            Client.clearSerial = nil
            Client.eventSerial = nil
        end
        return
    end

    Client.board = readBoard()
    Client.currentId = net.ReadUInt(3)
    Client.currentRotation = net.ReadUInt(2) + 1
    Client.currentX = net.ReadInt(6)
    Client.currentY = net.ReadInt(6)
    Client.nextPiece = net.ReadUInt(3)
    Client.bonus = net.ReadUInt(16)
    local clearSerial = net.ReadUInt(8)
    local lines = net.ReadUInt(3)
    Client.gameOver = net.ReadBool()
    local eventSerial = net.ReadUInt(8)
    local eventType = net.ReadUInt(3)

    if not wasActive then
        Client.clearSerial = clearSerial
        Client.eventSerial = eventSerial
    else
        if clearSerial ~= (Client.clearSerial or 0) then
            Client.clearSerial = clearSerial
            Client.feedback = feedbackNames[lines]
            Client.feedbackUntil = CurTime() + 1.5
        end
        if eventSerial ~= (Client.eventSerial or 0) then
            Client.eventSerial = eventSerial
            local soundPath = eventSounds[eventType]
            if soundPath then surface.PlaySound(soundPath) end
        end
    end
end)

local function sendStart()
    net.Start("LOD_IntermissionTetrisAction")
    net.WriteUInt(1, 2)
    net.SendToServer()
end

local function sendInput(action)
    if not Client.active or Client.gameOver then return end
    net.Start("LOD_IntermissionTetrisInput")
    net.WriteUInt(action, 3)
    net.SendToServer()
end

hook.Add("Think", "LOD_IntermissionTetrisStartInput", function()
    local down = input.IsKeyDown(KEY_F)
    if down and not fWasDown and Client.available and not Client.active
        and not gui.IsGameUIVisible() and not IsValid(vgui.GetKeyboardFocus())
    then
        sendStart()
    end
    fWasDown = down
end)

local bindActions = {
    {"+moveleft", 1}, {"+left", 1},
    {"+moveright", 2}, {"+right", 2},
    {"+forward", 3}, {"+back", 4}, {"+jump", 5}
}

hook.Add("PlayerBindPress", "LOD_IntermissionTetrisControls", function(_, bind, pressed)
    if not pressed or not Client.active then return end
    local lower = string.lower(bind or "")
    for _, mapping in ipairs(bindActions) do
        if string.find(lower, mapping[1], 1, true) then
            if not Client.gameOver then sendInput(mapping[2]) end
            return true
        end
    end
end)

local function drawCell(x, y, cell, value)
    local c = pieceColors[value] or Color(130, 130, 130)
    surface.SetDrawColor(c.r, c.g, c.b, 240)
    surface.DrawRect(x + 1, y + 1, cell - 2, cell - 2)
    surface.SetDrawColor(245, 220, 155, 60)
    surface.DrawRect(x + 2, y + 2, math.max(1, cell - 4), 2)
end

local function drawBoard(x, y, cell)
    local boardW = Tetris.Width * cell
    local boardH = Tetris.Height * cell
    surface.SetDrawColor(15, 18, 20, 235)
    surface.DrawRect(x, y, boardW, boardH)

    for row = 1, Tetris.Height do
        for column = 1, Tetris.Width do
            local value = Client.board[row][column] or 0
            if value > 0 then
                drawCell(x + (column - 1) * cell, y + (row - 1) * cell, cell, value)
            else
                surface.SetDrawColor(58, 62, 64, 80)
                surface.DrawOutlinedRect(x + (column - 1) * cell, y + (row - 1) * cell, cell, cell, 1)
            end
        end
    end

    if Client.currentId and Client.currentId > 0 then
        for _, block in ipairs(Tetris.CellsFor(Client.currentId, Client.currentRotation, Client.currentX, Client.currentY)) do
            if block.y >= 1 and block.y <= Tetris.Height and block.x >= 1 and block.x <= Tetris.Width then
                drawCell(x + (block.x - 1) * cell, y + (block.y - 1) * cell, cell, Client.currentId)
            end
        end
    end

    if Client.gameOver then
        surface.SetDrawColor(30, 32, 34, 205)
        surface.DrawRect(x, y, boardW, boardH)
        draw.SimpleText("TETRIS LOST", "LOD_IntermissionTetrisBody",
            x + boardW * 0.5, y + boardH * 0.5,
            Color(205, 205, 205), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

hook.Add("PostDrawHUD", "LOD_IntermissionTetrisPresentation", function()
    if not Client.available then return end
    local remaining = math.max(0, (Client.endsAt or CurTime()) - CurTime())
    if remaining <= 0 then return end

    if not Client.active or not Client.board then
        local w, h = 500, 62
        local x = math.floor((ScrW() - w) * 0.5)
        local y = math.floor(ScrH() * 0.67)
        draw.RoundedBox(5, x, y, w, h, Color(12, 15, 17, 225))
        surface.SetDrawColor(220, 140, 48, 240)
        surface.DrawRect(x, y, 5, h)
        draw.SimpleText("DEBORAH RESCUED", "LOD_IntermissionTetrisBody",
            x + 18, y + 10, Color(238, 194, 92), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(string.format("F — PLAY TETRIS FOR NEXT-LEVEL HP     %02ds", math.ceil(remaining)),
            "LOD_IntermissionTetrisBody", x + 18, y + 34,
            Color(235, 235, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        return
    end

    -- Compact inset by design: the rescue/celebration world remains visible behind
    -- the microgame instead of replacing it with the death screen presentation.
    local cell = math.Clamp(math.floor(ScrH() * 0.018), 11, 15)
    local boardW = Tetris.Width * cell
    local boardH = Tetris.Height * cell
    local panelW = boardW + 190
    local panelH = boardH + 64
    local x = ScrW() - panelW - 26
    local y = math.max(90, math.floor((ScrH() - panelH) * 0.5))
    local boardX = x + 18
    local boardY = y + 48
    local sideX = boardX + boardW + 18

    draw.RoundedBox(5, x, y, panelW, panelH, Color(12, 15, 17, 232))
    surface.SetDrawColor(220, 140, 48, 240)
    surface.DrawRect(x, y, 5, panelH)
    draw.SimpleText("VICTORY TETRIS", "LOD_IntermissionTetrisTitle", x + 17, y + 10,
        Color(238, 194, 92), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(string.format("%02ds", math.ceil(remaining)), "LOD_IntermissionTetrisBody",
        x + panelW - 15, y + 16, Color(235, 235, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    drawBoard(boardX, boardY, cell)

    draw.SimpleText("NEXT LEVEL", "LOD_IntermissionTetrisBody", sideX, boardY,
        Color(205, 205, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("+" .. tostring(Client.bonus or 0) .. " HP", "LOD_IntermissionTetrisTitle",
        sideX, boardY + 24, Color(245, 210, 115), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    if Client.feedback and CurTime() < (Client.feedbackUntil or 0) then
        draw.SimpleText(Client.feedback, "LOD_IntermissionTetrisBody", sideX, boardY + 64,
            Color(245, 210, 115), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local controlsY = boardY + boardH - 90
    draw.SimpleText("LEFT/RIGHT  MOVE", "LOD_IntermissionTetrisBody", sideX, controlsY,
        Color(205, 205, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("UP  ROTATE", "LOD_IntermissionTetrisBody", sideX, controlsY + 22,
        Color(205, 205, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("DOWN  DROP", "LOD_IntermissionTetrisBody", sideX, controlsY + 44,
        Color(205, 205, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("JUMP  HARD DROP", "LOD_IntermissionTetrisBody", sideX, controlsY + 66,
        Color(205, 205, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)
