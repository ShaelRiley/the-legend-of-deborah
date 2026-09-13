local Feed = LOD.CombatRollFeed
local HISTORY = "legend_of_deborah/dialogger_history.json"
local MAX_HISTORY = 1000
Feed.history = Feed.history or {}
if not Feed.historyLoaded and file.Exists(HISTORY, "DATA") then
    local loaded = util.JSONToTable(file.Read(HISTORY, "DATA") or "")
    if istable(loaded) then
        for _, row in ipairs(loaded) do
            if istable(row) and isstring(row.text) then
                Feed.history[#Feed.history + 1] = {text = string.sub(row.text, 1, 512),
                    stamp = tostring(row.stamp or "previous session")}
            end
        end
    end
end
Feed.historyLoaded = true
while #Feed.history > MAX_HISTORY do table.remove(Feed.history, 1) end

local function saveHistory()
    file.CreateDir("legend_of_deborah")
    file.Write(HISTORY, util.TableToJSON(Feed.history))
end
hook.Add("ShutDown", "LOD_DialoggerSave", saveHistory)

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
    -- Fixed batching (not debounce): continuous combat still reaches disk.
    if not timer.Exists("LOD_DialoggerSave") then timer.Create("LOD_DialoggerSave", 2, 1, saveHistory) end
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
    hook.Run("LODDialoggerUpdated")
end

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
    -- Separate compact, outlined text below the top HUD. No screen flash/shake.
    local w = math.min(620, ScrW() - 48)
    local x, y = (ScrW() - w) * 0.5, ScrH() * 0.27
    surface.SetFont("LOD_CombatRoll")
    local lines, line = {}, ""
    for word in notice.entry.text:gmatch("%S+") do
        local candidate = line == "" and word or line .. " " .. word
        if surface.GetTextSize(candidate) > w - 24 and line ~= "" then
            lines[#lines + 1], line = line, word
        else line = candidate end
    end
    lines[#lines + 1] = line
    draw.RoundedBox(3, x, y, w, #lines * 20 + 16, Color(12, 16, 20, 235))
    surface.SetDrawColor(238, 223, 176, 255)
    surface.DrawOutlinedRect(x, y, w, #lines * 20 + 16, 2)
    for i, text in ipairs(lines) do
        draw.SimpleText(text, "LOD_CombatRoll", x + 12, y + 8 + (i - 1) * 20, Color(255, 240, 205))
    end
    Feed:AckFeedback(notice.entry, 1, false)
end)

function Feed:OpenHistory()
    if IsValid(self.HistoryFrame) then self.HistoryFrame:Remove() end
    local frame = vgui.Create("DFrame")
    self.HistoryFrame = frame
    frame:SetSize(math.min(900, ScrW() - 40), math.min(650, ScrH() - 40))
    frame:Center()
    frame:SetTitle("DIALOGGER / Last 1,000 events / Newest first")
    frame:MakePopup()
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    local function refresh()
        if not IsValid(frame) then return end
        scroll:Clear()
        for i = #Feed.history, 1, -1 do
            local row = Feed.history[i]
            local label = vgui.Create("DLabel", scroll)
            label:Dock(TOP)
            label:DockMargin(8, 4, 8, 5)
            label:SetFont("LOD_CombatRoll")
            label:SetTextColor(Color(235, 231, 218))
            label:SetText(row.stamp .. "  " .. row.text)
            label:SetWrap(true)
            label:SetAutoStretchVertical(true)
        end
    end
    refresh()
    local refreshButton = vgui.Create("DButton", frame)
    refreshButton:SetText("Refresh")
    refreshButton:SetPos(frame:GetWide() - 150, 3)
    refreshButton:SetSize(80, 20)
    refreshButton.DoClick = refresh
end
