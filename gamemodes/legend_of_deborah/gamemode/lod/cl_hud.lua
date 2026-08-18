LOD = LOD or {}
LOD.ClientState = LOD.ClientState or {
    level = 1,
    objectiveStage = 1,
    cards = {false, false, false},
    gates = {false, false, false},
    checkpoint = 0,
    ranked = true,
    failed = false,
    levelCleared = false,
    objective = "FIND RED KEYCARD — R / TRIANGLE"
}

surface.CreateFont("LOD_HUD_Title", {
    font = "DejaVu Sans",
    size = 24,
    weight = 800
})
surface.CreateFont("LOD_HUD_Body", {
    font = "DejaVu Sans",
    size = 18,
    weight = 650
})
surface.CreateFont("LOD_HUD_Small", {
    font = "DejaVu Sans",
    size = 14,
    weight = 600
})
surface.CreateFont("LOD_HUD_Announcement", {
    font = "DejaVu Sans",
    size = 34,
    weight = 900
})
surface.CreateFont("LOD_HUD_Countdown", {
    font = "DejaVu Sans",
    size = 68,
    weight = 900
})

net.Receive("LOD_RunState", function()
    local state = LOD.ClientState
    state.level = net.ReadUInt(20)
    state.objectiveStage = net.ReadUInt(3)
    state.cards = {net.ReadBool(), net.ReadBool(), net.ReadBool()}
    state.gates = {net.ReadBool(), net.ReadBool(), net.ReadBool()}
    state.checkpoint = net.ReadUInt(2)
    state.ranked = net.ReadBool()
    state.failed = net.ReadBool()
    state.levelCleared = net.ReadBool()
    state.hasTarget = net.ReadBool()
    state.target = state.hasTarget and net.ReadVector() or nil
    state.objective = net.ReadString()
end)

net.Receive("LOD_Announcement", function()
    LOD.ClientAnnouncement = net.ReadString()
    LOD.ClientAnnouncementUntil = CurTime() + 4.0
end)

local cardColors = {
    Color(205, 54, 54),
    Color(64, 118, 210),
    Color(224, 190, 52)
}
local letters = {"R", "B", "Y"}
local symbolNames = {"TRIANGLE", "CIRCLE", "SQUARE"}
local nextRestartRequest = 0

local function drawSymbol(index, x, y, color)
    surface.SetDrawColor(color)
    if index == 1 then
        surface.DrawPoly({
            {x = x, y = y - 7},
            {x = x - 8, y = y + 7},
            {x = x + 8, y = y + 7}
        })
    elseif index == 2 then
        surface.DrawCircle(x, y, 7, color.r, color.g, color.b, color.a)
        surface.DrawCircle(x, y, 6, color.r, color.g, color.b, color.a)
    else
        surface.DrawRect(x - 7, y - 7, 14, 14)
    end
end

local function objectiveArrow(target)
    if not target then return nil end
    local delta = target - EyePos()
    if delta:LengthSqr() < 1 then return "▲" end
    local diff = math.AngleDifference(delta:Angle().y, EyeAngles().y)
    if math.abs(diff) <= 12 then return "▲" end
    return diff > 0 and "▶" or "◀"
end

local function drawDeathState(ply, state)
    if state.failed or state.levelCleared then return end
    if not ply:GetNW2Bool("LOD_PlayedIdentity", false) or ply:Alive() then return end

    local eliminated = ply:GetNW2Bool("LOD_Eliminated", false)
    draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(5, 7, 9, 150))

    if eliminated then
        draw.SimpleText("OUT OF LIVES", "LOD_HUD_Announcement", ScrW() * 0.5, ScrH() * 0.43,
            Color(235, 105, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("SPECTATING UNTIL THE NEXT LEVEL", "LOD_HUD_Body", ScrW() * 0.5, ScrH() * 0.49,
            Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local remaining = math.max(0, ply:GetNW2Float("LOD_RespawnRemaining", 0))
    local seconds = math.max(0, math.ceil(remaining))

    draw.SimpleText("YOU DIED", "LOD_HUD_Announcement", ScrW() * 0.5, ScrH() * 0.38,
        Color(235, 105, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("RESPAWNING IN", "LOD_HUD_Body", ScrW() * 0.5, ScrH() * 0.45,
        Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(tostring(seconds), "LOD_HUD_Countdown", ScrW() * 0.5, ScrH() * 0.54,
        Color(245, 210, 115), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("CHECKPOINT " .. tostring(state.checkpoint or 0), "LOD_HUD_Small", ScrW() * 0.5, ScrH() * 0.62,
        Color(205, 205, 205), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("PlayerBindPress", "LOD_FailedCampaignRestart", function(_, bind, pressed)
    if not pressed or not LOD.ClientState or not LOD.ClientState.failed then return end
    if not string.find(string.lower(bind or ""), "+use", 1, true) then return end

    if CurTime() >= nextRestartRequest then
        nextRestartRequest = CurTime() + 1.0
        net.Start("LOD_RestartCampaign")
        net.SendToServer()
    end
    return true
end)

hook.Add("HUDPaint", "LOD_PersistentHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local state = LOD.ClientState
    local margin = 22
    local panelW = 360
    local panelH = 150

    draw.RoundedBox(6, margin, margin, panelW, panelH, Color(15, 18, 20, 210))
    surface.SetDrawColor(220, 140, 48, 230)
    surface.DrawRect(margin, margin, 5, panelH)

    draw.SimpleText("THE LEGEND OF DEBORAH", "LOD_HUD_Title", margin + 18, margin + 10, Color(238, 194, 92))
    draw.SimpleText("LEVEL " .. tostring(state.level) .. (state.ranked and "" or "  •  UNRANKED"), "LOD_HUD_Small",
        margin + 20, margin + 40, state.ranked and Color(210, 210, 210) or Color(235, 160, 90))

    local lives = ply:GetNW2Int("LOD_Lives", 0)
    local eliminated = ply:GetNW2Bool("LOD_Eliminated", false)
    local lifeText = eliminated and "LIVES: 0 — SPECTATOR" or ("LIVES: " .. tostring(lives))
    draw.SimpleText(lifeText, "LOD_HUD_Body", margin + 20, margin + 64, eliminated and Color(220, 95, 80) or Color(245, 245, 245))

    for i = 1, 3 do
        local x = margin + 34 + (i - 1) * 106
        local y = margin + 104
        local collected = state.cards[i]
        local color = collected and cardColors[i] or Color(82, 86, 88)
        draw.RoundedBox(4, x - 16, y - 14, 92, 31, Color(28, 31, 33, 235))
        drawSymbol(i, x, y + 1, color)
        draw.SimpleText(letters[i], "LOD_HUD_Body", x + 15, y, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(collected and "CARD" or symbolNames[i], "LOD_HUD_Small", x + 33, y + 1, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local objectiveW = math.min(ScrW() - 60, 680)
    local objectiveX = (ScrW() - objectiveW) * 0.5
    draw.RoundedBox(6, objectiveX, 24, objectiveW, 54, Color(13, 16, 18, 215))
    draw.SimpleText(state.objective or "EXPEDITION", "LOD_HUD_Title", ScrW() * 0.5, 50, Color(238, 194, 92), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if state.hasTarget and state.target then
        local arrow = objectiveArrow(state.target)
        if arrow then
            draw.SimpleText(arrow, "LOD_HUD_Announcement", ScrW() * 0.5, 98, Color(238, 194, 92), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    if LOD.ClientAnnouncement and CurTime() < (LOD.ClientAnnouncementUntil or 0) then
        local alpha = math.Clamp(((LOD.ClientAnnouncementUntil or 0) - CurTime()) * 255, 0, 255)
        draw.SimpleText(LOD.ClientAnnouncement, "LOD_HUD_Announcement", ScrW() * 0.5, ScrH() * 0.28,
            Color(245, 210, 115, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if state.failed then
        draw.RoundedBox(0, 0, 0, ScrW(), ScrH(), Color(25, 0, 0, 155))
        draw.SimpleText("CAMPAIGN FAILED", "LOD_HUD_Announcement", ScrW() * 0.5, ScrH() * 0.42,
            Color(245, 90, 75), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("PRESS USE / E TO RESTART FROM LEVEL 1", "LOD_HUD_Body", ScrW() * 0.5, ScrH() * 0.50,
            Color(245, 210, 115), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("THE SERVER AND CONNECTED GROUP STAY TOGETHER", "LOD_HUD_Small", ScrW() * 0.5, ScrH() * 0.55,
            Color(215, 215, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif state.levelCleared then
        draw.SimpleText("DEBORAH RESCUED", "LOD_HUD_Announcement", ScrW() * 0.5, ScrH() * 0.42,
            Color(245, 210, 115), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("BUILDING THE NEXT LABYRINTH", "LOD_HUD_Body", ScrW() * 0.5, ScrH() * 0.47,
            Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        drawDeathState(ply, state)
    end
end)