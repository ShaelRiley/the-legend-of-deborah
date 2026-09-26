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
            for index = math.max(1, #loaded - MAX_HISTORY + 1), #loaded do
                local row = loaded[index]
                if istable(row) and isstring(row.text) then
                    Feed.history[#Feed.history + 1] = {
                        text = string.sub(row.text, 1, LOD.DieLogger.MaxText),
                        stamp = tostring(row.stamp or "previous session"),
                        family = row.family or "routine", category = row.category or 3,
                        cue = row.cue, cueVariant = row.cueVariant, serial = row.serial,
                        segments = LOD.DieLogger:ValidSegments(row.segments, row.text) and row.segments or nil
                    }
                end
            end
        end

        while #Feed.history > MAX_HISTORY do table.remove(Feed.history, 1) end

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
    self.history[#self.history + 1] = {text = entry.text, stamp = os.date("%m-%d %H:%M:%S"),
        family = entry.family, category = entry.category, segments = entry.segments,
        serial = entry.serial, cue = entry.cue, cueVariant = entry.cueVariant}
    while #self.history > MAX_HISTORY do table.remove(self.history, 1) end
    -- Fixed batching: continuous combat still reaches disk.
    if not timer.Exists("LOD_DieLoggerSave") then
        timer.Create("LOD_DieLoggerSave", 2, 1, saveHistory)
    end
    local grammar = LOD.FeedbackLanguage[entry.family] or LOD.FeedbackLanguage.routine
    local now = CurTime()
    if LOD.RPGWisInformation and LOD.RPGWisInformation.OnFeedback then
        LOD.RPGWisInformation:OnFeedback(entry)
    end
    local sounded = LOD.AdventurePresentation and LOD.AdventurePresentation:OnFeedback(entry) or false
    local priority = grammar.priority or 0
    local soundReady = entry.family=="awareness" and now>=(self.nextAwarenessSound or 0)
        or entry.family~="awareness" and (now>=(self.nextFeedbackSound or 0)
            or priority>(self.lastFeedbackPriority or 0))
    if not sounded and not (entry.cue and entry.cue > 0) and grammar.cueId and soundReady then
        LOD.Audio:Play(grammar.cueId)
        self.nextFeedbackSound = now + (priority >= 2 and 0.8 or 0.35)
        self.lastFeedbackPriority = priority
        if entry.family=="awareness" then self.nextAwarenessSound=now+0.8 end
        sounded = true
    end
    if entry.family == "life" or entry.family == "danger" or entry.family == "soldier" then
        local function lifecycle(notice)
            local f = notice.entry.family
            return f == "life" or f == "danger" or f == "soldier"
        end
        if self.notice and lifecycle(self.notice) then self.notice = nil end
        for i = #(self.notices or {}),1,-1 do
            if lifecycle(self.notices[i]) then table.remove(self.notices,i) end
        end
    end
    if priority >= 2 then
        self.notices = self.notices or {}
        self.notices[#self.notices + 1] = {entry = entry, priority = priority, expires = now + 8}
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

hook.Add("HUDPaint", "LOD_FeedbackNotice", function()
    local now = CurTime()
    if Feed.notice and now >= Feed.notice.untilAt then Feed.notice = nil end
    for i = #(Feed.notices or {}), 1, -1 do
        if now >= (Feed.notices[i].expires or 0) then table.remove(Feed.notices, i) end
    end
    if Feed.notices and #Feed.notices > 0 then
        local highest = 1
        for i, item in ipairs(Feed.notices) do
            if item.priority > Feed.notices[highest].priority then highest = i end
        end
        if not Feed.notice or Feed.notices[highest].priority > Feed.notice.priority then
            local nextNotice = table.remove(Feed.notices, highest)
            if Feed.notice then table.insert(Feed.notices, 1, Feed.notice) end
            Feed.notice = {entry = nextNotice.entry, priority = nextNotice.priority, expires = nextNotice.expires, untilAt = now + 2.8}
        end
    end
    local notice = Feed.notice
    if not notice then return end

    local UI=LOD.UI
    local w=math.min(640,ScrW()-48)
    local x,y=(ScrW()-w)*0.5,ScrH()*0.30
    local lines=Feed:Layout(notice.entry,w-32,true)
    local shown=math.min(#lines,6)
    Feed:DrawLines(lines,x+16,y+10,255,1,shown,true)
    Feed:AckFeedback(notice.entry, 1, false)
end)

function Feed:OpenHistory()
    if LOD.UI.IsMinigameLocked and LOD.UI:IsMinigameLocked() then return false end
    if IsValid(self.HistoryFrame) then self.HistoryFrame:Remove() end
    LOD.UI:SelectPage("history")
    local UI, C = LOD.UI, LOD.UI.Colors
    local frame = vgui.Create("DFrame")
    self.HistoryFrame = frame
    frame.OnRemove = function()
        if UI.ActivePage == "history" then UI.ActivePage = nil end
    end
    local w,h = math.min(1000,ScrW()-40),math.min(700,ScrH()-40)
    frame:SetSize(w,h); frame:Center(); frame:SetTitle(""); frame:MakePopup()
    frame.Paint = function(_,fw,fh) UI:Paper(0,0,fw,fh,C.red,255,8) end
    UI:CloseButton(frame,function() frame:Remove() end)
    local title = vgui.Create("DLabel",frame)
    title:SetText("THE LEGEND OF DEBORAH / DIE-LOGGER")
    title:SetFont("LOD_SheetHeading"); title:SetTextColor(C.red)
    title:SetPos(24,20); title:SetSize(w-160,32)
    local subtitle = vgui.Create("DLabel",frame)
    subtitle:SetFont("LOD_SheetSmall"); subtitle:SetTextColor(C.muted)
    subtitle:SetPos(24,54); subtitle:SetSize(w-48,22)
    UI:PageLinks(frame,"history",78)
    local legend = vgui.Create("DLabel",frame)
    legend:SetText("ROLLS: + base die   > continuation   @N+ threshold   => contribution")
    legend:SetFont("LOD_SheetSmall"); legend:SetTextColor(C.blue)
    legend:SetPos(24,110); legend:SetSize(w-48,22)
    local scroll = vgui.Create("DScrollPanel",frame)
    scroll:SetPos(20,138); scroll:SetSize(w-40,h-198)
    local page, pageSize, snapshot = 1, 50, {}
    -- Freeze this view while inspecting. New combat cannot move rows under a click.
    for i,row in ipairs(self.history) do snapshot[i] = row end
    local function refresh()
        scroll:Clear()
        local pages = math.max(1,math.ceil(#snapshot/pageSize))
        page = math.Clamp(page,1,pages)
        subtitle:SetText(string.format("Page %d / %d | %d retained events | newest first | gameplay continues",page,pages,#snapshot))
        local first = #snapshot-(page-1)*pageSize
        for i=first,math.max(1,first-pageSize+1),-1 do
            local row = snapshot[i]
            local lines = Feed:Layout(row,w-82)
            local panel = vgui.Create("DPanel",scroll)
            panel:Dock(TOP); panel:DockMargin(4,3,4,3)
            panel:SetTall(#lines*Feed.RowHeight+36)
            panel.Paint = function(_,pw,ph)
                draw.RoundedBox(1,0,0,pw,ph,C.light)
                surface.SetDrawColor(C.rule); surface.DrawOutlinedRect(0,0,pw,ph,1)
                draw.SimpleText(row.stamp or "","LOD_SheetKey",10,5,C.muted)
                Feed:DrawLines(lines,10,28,255)
            end
        end
        scroll:GetVBar():SetScroll(0)
    end
    local function button(label,x,callback)
        local b=vgui.Create("DButton",frame); b:SetText(label); b:SetPos(x,h-48); b:SetSize(130,26)
        UI:Button(b); b.DoClick=callback
    end
    button("NEWER",24,function() page=page-1;refresh() end)
    button("OLDER",164,function() page=page+1;refresh() end)
    button("LATEST",304,function()
        snapshot={};for i,row in ipairs(Feed.history) do snapshot[i]=row end
        page=1;refresh()
    end)
    refresh()
    return frame
end

local nextToggle = 0
local function toggleHistory()
    if RealTime() < nextToggle then return end
    nextToggle = RealTime()+0.15
    if IsValid(Feed.HistoryFrame) then Feed.HistoryFrame:Remove() else Feed:OpenHistory() end
end
Feed.ToggleHistory = toggleHistory
hook.Add("PlayerButtonDown","LOD_DieLoggerInput",function(ply,key)
    if ply ~= LocalPlayer() or key ~= KEY_L or gui.IsConsoleVisible() or (chat.IsTyping and chat.IsTyping()) then return end
    toggleHistory()
end)
concommand.Add("lod_die_logger",toggleHistory)
