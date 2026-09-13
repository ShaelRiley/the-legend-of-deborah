local Feed = LOD.CombatRollFeed
local PREFERRED_HISTORY = "legend_of_deborah/die_logger_history.json"
local FALLBACK_HISTORY = "legend_of_deborah/dialogger_history.json"
local MAX_HISTORY = 1000
Feed.history = Feed.history or {}

if not Feed.historyLoaded then
    local loadedPath
    if file.Exists(PREFERRED_HISTORY, "DATA") then
        loadedPath = PREFERRED_HISTORY
    elseif file.Exists(FALLBACK_HISTORY, "DATA") then
        loadedPath = FALLBACK_HISTORY
    end

    if loadedPath then
        local rawData = file.Read(loadedPath, "DATA") or ""
        local loaded = util.JSONToTable(rawData)
        if istable(loaded) then
            for _, row in ipairs(loaded) do
                if istable(row) and isstring(row.text) then
                    Feed.history[#Feed.history + 1] = {
                        text = string.sub(row.text, 1, 512),
                        stamp = tostring(row.stamp or "previous session")
                    }
                end
            end
        end

        -- Safe legacy migration: if loaded from fallback history, write to die_logger_history.json
        if loadedPath == FALLBACK_HISTORY and #Feed.history > 0 then
            file.CreateDir("legend_of_deborah")
            local jsonStr = util.TableToJSON(Feed.history)
            if jsonStr and jsonStr ~= "" then
                file.Write(PREFERRED_HISTORY, jsonStr)
            end
        end
    end
end
Feed.historyLoaded = true
while #Feed.history > MAX_HISTORY do table.remove(Feed.history, 1) end

local function saveHistory()
    file.CreateDir("legend_of_deborah")
    file.Write(PREFERRED_HISTORY, util.TableToJSON(Feed.history))
end
hook.Add("ShutDown", "LOD_DieLoggerSave", saveHistory)

function Feed:AckFeedback(entry, stage, sound)
    if not entry.tracked then return end
    if stage == 1 then
        if entry.drawn then return end
        entry.drawn = true
    end
    net.Start("LOD_FeedbackAck")
    net.WriteUInt(entry.serial, 32)
    net.WriteUInt(stage, 2)
    net.WriteBool(sound == true)
    net.SendToServer()
end

function Feed:RetainFeedback(entry)
    self.history[#self.history + 1] = {text = entry.text, stamp = os.date("%m-%d %H:%M:%S")}
    while #self.history > MAX_HISTORY do table.remove(self.history, 1) end
    -- Fixed batching: continuous combat still reaches disk.
    if not timer.Exists("LOD_DieLoggerSave") then
        timer.Create("LOD_DieLoggerSave", 2, 1, saveHistory)
    end
    local grammar = LOD.FeedbackLanguage[entry.family] or LOD.FeedbackLanguage.routine
    local now, sounded = CurTime(), false
    local priority = grammar.priority or 0
    if grammar.sound and (now >= (self.nextFeedbackSound or 0)
        or priority > (self.lastFeedbackPriority or 0)) then
        surface.PlaySound(grammar.sound)
        self.nextFeedbackSound = now + (priority >= 2 and 0.8 or 0.35)
        self.lastFeedbackPriority = priority
        sounded = true
    end
    if priority >= 2 then
        self.notices = self.notices or {}
        self.notices[#self.notices + 1] = {entry = entry, priority = priority}
        -- Preserve life/danger over progression if an extreme burst fills the queue.
        if #self.notices > 8 then
            local lowest = 1
            for i, notice in ipairs(self.notices) do
                if notice.priority < self.notices[lowest].priority then lowest = i end
            end
            table.remove(self.notices, lowest)
        end
    end
    self:AckFeedback(entry, 0, sounded)
    hook.Run("LODDieLoggerUpdated")
end

local PAPER = Color(244, 237, 218)
local PAPER_LIGHT = Color(251, 247, 233)
local INK = Color(32, 32, 29)
local RED = Color(170, 61, 50)
local BLUE = Color(55, 91, 145)
local MUTED = Color(112, 104, 91)

hook.Add("HUDPaint", "LOD_FeedbackNotice", function()
    local now = CurTime()
    if Feed.notice and now >= Feed.notice.untilAt then Feed.notice = nil end
    if Feed.notices and #Feed.notices > 0 then
        local highest = 1
        for i, item in ipairs(Feed.notices) do
            if item.priority > Feed.notices[highest].priority then highest = i end
        end
        if not Feed.notice or Feed.notices[highest].priority > Feed.notice.priority then
            local nextNotice = table.remove(Feed.notices, highest)
            if Feed.notice then table.insert(Feed.notices, 1, Feed.notice) end
            Feed.notice = {entry = nextNotice.entry, priority = nextNotice.priority, untilAt = now + 2.8}
        end
    end
    local notice = Feed.notice
    if not notice then return end

    -- Sol-styled HUD notice banner (parchment paper with red accent bar and crisp text)
    local w = math.min(640, ScrW() - 48)
    local x, y = (ScrW() - w) * 0.5, ScrH() * 0.27
    surface.SetFont("LOD_CombatRoll")
    local lines, line = {}, ""
    for word in notice.entry.text:gmatch("%S+") do
        local candidate = line == "" and word or line .. " " .. word
        if surface.GetTextSize(candidate) > w - 32 and line ~= "" then
            lines[#lines + 1], line = line, word
        else line = candidate end
    end
    lines[#lines + 1] = line

    local h = #lines * 20 + 20
    draw.RoundedBox(4, x, y, w, h, Color(18, 19, 21, 248))
    draw.RoundedBox(2, x + 4, y + 4, w - 8, h - 8, PAPER)
    surface.SetDrawColor(RED)
    surface.DrawRect(x + 4, y + 4, w - 8, 4)
    surface.SetDrawColor(BLUE)
    surface.DrawRect(x + 4, y + h - 8, w - 8, 4)

    for i, text in ipairs(lines) do
        draw.SimpleText(text, "LOD_CombatRoll", x + 16, y + 10 + (i - 1) * 20, INK)
    end
    Feed:AckFeedback(notice.entry, 1, false)
end)

function Feed:OpenHistory()
    if IsValid(self.HistoryFrame) then self.HistoryFrame:Remove() end
    local frame = vgui.Create("DFrame")
    self.HistoryFrame = frame
    local w = math.min(940, ScrW() - 40)
    local h = math.min(680, ScrH() - 40)
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame:MakePopup()

    frame.Paint = function(self, fw, fh)
        draw.RoundedBox(4, 0, 0, fw, fh, Color(18, 19, 21, 248))
        draw.RoundedBox(2, 8, 8, fw - 16, fh - 16, PAPER)
        surface.SetDrawColor(RED)
        surface.DrawRect(8, 8, fw - 16, 6)
        surface.SetDrawColor(BLUE)
        surface.DrawRect(8, fh - 14, fw - 16, 6)
    end

    local title = vgui.Create("DLabel", frame)
    title:SetText("THE LEGEND OF DEBORAH / DIE LOGGER")
    title:SetFont("LOD_SheetHeading")
    title:SetTextColor(RED)
    title:SetPos(24, 20)
    title:SetSize(w - 240, 30)

    local subtitle = vgui.Create("DLabel", frame)
    subtitle:SetText("Last 1,000 systemic combat events & roll histories (newest first)")
    subtitle:SetFont("LOD_SheetSmall")
    subtitle:SetTextColor(MUTED)
    subtitle:SetPos(24, 48)
    subtitle:SetSize(w - 240, 20)

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetText("Close [ESC]")
    closeBtn:SetFont("LOD_SheetKey")
    closeBtn:SetTextColor(INK)
    closeBtn:SetPos(w - 130, 22)
    closeBtn:SetSize(106, 26)
    closeBtn.Paint = function(self, bw, bh)
        draw.RoundedBox(3, 0, 0, bw, bh, self:IsHovered() and PAPER_LIGHT or Color(230, 220, 195))
        surface.SetDrawColor(self:IsHovered() and RED or MUTED)
        surface.DrawOutlinedRect(0, 0, bw, bh, 1)
    end
    closeBtn.DoClick = function() if IsValid(frame) then frame:Remove() end end

    local refreshBtn = vgui.Create("DButton", frame)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetFont("LOD_SheetKey")
    refreshBtn:SetTextColor(INK)
    refreshBtn:SetPos(w - 226, 22)
    refreshBtn:SetSize(86, 26)
    refreshBtn.Paint = function(self, bw, bh)
        draw.RoundedBox(3, 0, 0, bw, bh, self:IsHovered() and PAPER_LIGHT or Color(230, 220, 195))
        surface.SetDrawColor(self:IsHovered() and BLUE or MUTED)
        surface.DrawOutlinedRect(0, 0, bw, bh, 1)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(20, 76)
    scroll:SetSize(w - 40, h - 96)
    local canvas = scroll:GetCanvas()
    canvas.Paint = function(_, cw, ch)
        surface.SetDrawColor(80, 66, 41, 10)
        for cy = 0, ch, 4 do surface.DrawRect(0, cy, cw, 1) end
    end

    local function refresh()
        if not IsValid(frame) then return end
        scroll:Clear()
        for i = #Feed.history, 1, -1 do
            local row = Feed.history[i]
            local entryPanel = vgui.Create("DPanel", scroll)
            entryPanel:Dock(TOP)
            entryPanel:DockMargin(4, 3, 4, 3)
            entryPanel.Paint = function(self, pw, ph)
                draw.RoundedBox(2, 0, 0, pw, ph, PAPER_LIGHT)
                surface.SetDrawColor(Color(210, 200, 175))
                surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            end

            local stampLabel = vgui.Create("DLabel", entryPanel)
            stampLabel:SetText(row.stamp or "")
            stampLabel:SetFont("LOD_SheetKey")
            stampLabel:SetTextColor(MUTED)
            stampLabel:SetPos(8, 4)
            stampLabel:SetSize(130, 20)

            local textLabel = vgui.Create("DLabel", entryPanel)
            textLabel:SetText(row.text or "")
            textLabel:SetFont("LOD_CombatRoll")
            textLabel:SetTextColor(INK)
            textLabel:SetPos(144, 4)
            textLabel:SetSize(w - 210, 20)
            textLabel:SetWrap(true)
            textLabel:SetAutoStretchVertical(true)

            entryPanel:InvalidateLayout(true)
            timer.Simple(0, function()
                if IsValid(entryPanel) and IsValid(textLabel) then
                    entryPanel:SetTall(math.max(28, textLabel:GetTall() + 8))
                end
            end)
        end
    end
    refresh()
    refreshBtn.DoClick = refresh
    return frame
end
