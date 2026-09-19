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
    synchronized = false,
    objective = "INITIALIZING EXPEDITION..."
}

surface.CreateFont("LOD_HUD_Title", {
    font = "DejaVu Sans Condensed",
    size = 24,
    weight = 800
})
surface.CreateFont("LOD_HUD_Body", {
    font = "Tahoma",
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
    state.synchronized = true
    state.level = net.ReadDouble()
    state.objectiveStage = net.ReadUInt(4)
    state.cards = {net.ReadBool(), net.ReadBool(), net.ReadBool(), net.ReadBool()}
    state.gates = {net.ReadBool(), net.ReadBool(), net.ReadBool(), net.ReadBool()}
    state.jailKey = net.ReadBool()
    state.jailDoorOpen = net.ReadBool()
    state.checkpoint = net.ReadUInt(3)
    state.ranked = net.ReadBool()
    state.failed = net.ReadBool()
    state.levelCleared = net.ReadBool()
    state.hasTarget = net.ReadBool()
    state.target = state.hasTarget and net.ReadVector() or nil
    state.objective = net.ReadString()
    state.objectiveKind = net.ReadUInt(3)
    state.objectiveA = nil
    state.objectiveB = nil
    if state.objectiveKind > 0 then
        state.objectiveA = {
            x = net.ReadUInt(7),
            y = net.ReadUInt(7),
            z = net.ReadUInt(3)
        }
        if net.ReadBool() then
            state.objectiveB = {
                x = net.ReadUInt(7),
                y = net.ReadUInt(7),
                z = net.ReadUInt(3)
            }
        end
    end
end)

net.Receive("LOD_Announcement", function()
    LOD.ClientAnnouncement = net.ReadString()
    LOD.ClientAnnouncementUntil = CurTime() + 4.0
end)

local UI = LOD.UI

local cardColors = {
    Color(205, 54, 54),
    Color(64, 118, 210),
    Color(224, 190, 52),
    Color(190, 190, 200)
}
local letters = {"R", "B", "Y", "K"}
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
        draw.SimpleText("HERO QUEUE / WATCH FOR REVIVAL", "LOD_HUD_Body", ScrW() * 0.5, ScrH() * 0.49,
            Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    -- Once Tetris is active, cl_tetris.lua owns the entire death presentation in
    -- PostDrawHUD. Keep this normal spectator presentation for the opt-in phase.
    if ply:GetNW2Bool("LOD_DeathTetrisActive", false) then return end

    local remaining = math.max(0, ply:GetNW2Float("LOD_RespawnRemaining", 0))
    local seconds = math.max(0, math.ceil(remaining))

    draw.SimpleText("YOU DIED", "LOD_HUD_Announcement", ScrW() * 0.5, ScrH() * 0.38,
        Color(235, 105, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if remaining > 0 then
        draw.SimpleText("Press F to pay respects", "LOD_HUD_Small", ScrW() * 0.5, ScrH() * 0.425,
            Color(205, 205, 205), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("RESPAWN AVAILABLE IN", "LOD_HUD_Body", ScrW() * 0.5, ScrH() * 0.47,
            Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(seconds), "LOD_HUD_Countdown", ScrW() * 0.5, ScrH() * 0.56,
            Color(245, 210, 115), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("LEFT CLICK TO RESPAWN", "LOD_HUD_Body", ScrW() * 0.5, ScrH() * 0.47,
            Color(245, 210, 115), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    draw.SimpleText("CHECKPOINT " .. tostring(state.checkpoint or 0), "LOD_HUD_Small", ScrW() * 0.5, ScrH() * 0.64,
        Color(205, 205, 205), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("PlayerBindPress", "LOD_FailedCampaignRestart", function(_, bind, pressed)
    if LOD.CampaignTimeout and LOD.CampaignTimeout:IsCinematic() then return end
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
    local lives = ply:GetNW2Int("LOD_Lives", 0)
    local role = ply:GetNW2Bool("LOD_IsSoldier", false) and "HUMAN SOLDIER"
        or ply:GetNW2Bool("LOD_Eliminated", false) and "SPECTATOR"
        or ("LIVES " .. tostring(lives))
    local levelText = state.synchronized
        and ("LEVEL " .. tostring(state.level) .. "   " .. role .. (state.ranked and "" or "   UNRANKED"))
        or "INITIALIZING RUN..."
    UI:HUDText(levelText,"HudHintTextLarge",margin,margin)
    for i = 1, 4 do
        local x, y = margin+8+(i-1)*92, margin+32
        local collected = state.cards[i]
        local color = collected and cardColors[i] or Color(170,170,170,175)
        drawSymbol(i,x,y,color)
        UI:HUDText(letters[i] .. (collected and " CARD" or " --"),"Default",x+14,y,color,
            TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
    end

    local arrow = state.hasTarget and state.target and objectiveArrow(state.target) or nil
    local objective = (state.objective or "EXPEDITION") .. (arrow and ("  " .. arrow) or "")
    local feed = LOD.CombatRollFeed
    if feed and feed.Layout then
        LOD.ObjectiveEntry = LOD.ObjectiveEntry and LOD.ObjectiveEntry.text == objective
            and LOD.ObjectiveEntry or {text=objective,family="objective"}
        local width=math.min(600,ScrW()*0.48)
        local lines=feed:Layout(LOD.ObjectiveEntry,width,true)
        feed:DrawLines(lines,ScrW()-margin-width,margin,255,nil,nil,true)
    else
        UI:HUDText(objective,"HudHintTextLarge",ScrW()-margin,margin,nil,TEXT_ALIGN_RIGHT)
    end

    local feed = LOD.CombatRollFeed
    local noticeBusy = feed and (feed.notice or #(feed.notices or {}) > 0)
    if not noticeBusy and LOD.ClientAnnouncement and CurTime() < (LOD.ClientAnnouncementUntil or 0) then
        local alpha = math.Clamp(((LOD.ClientAnnouncementUntil or 0) - CurTime()) * 255, 0, 255)
        local entry = {text=LOD.ClientAnnouncement,family="objective"}
        LOD.AnnouncementEntry = LOD.AnnouncementEntry and LOD.AnnouncementEntry.text == entry.text and LOD.AnnouncementEntry or entry
        local feed=LOD.CombatRollFeed
        if feed and feed.Layout then
            local width=math.min(680,ScrW()-48)
            local lines=feed:Layout(LOD.AnnouncementEntry,width-32,true)
            local y=ScrH()*0.35
            feed:DrawLines(lines,(ScrW()-width)*0.5+16,y+10,alpha,nil,nil,true)
        end
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
        draw.SimpleText((LOD.Damsels and LOD.Damsels:Current().victory or "LEVEL CLEAR"), "LOD_HUD_Announcement", ScrW() * 0.5, ScrH() * 0.42,
            Color(245, 210, 115), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("BUILDING THE NEXT LABYRINTH", "LOD_HUD_Body", ScrW() * 0.5, ScrH() * 0.47,
            Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        drawDeathState(ply, state)
    end
end)

