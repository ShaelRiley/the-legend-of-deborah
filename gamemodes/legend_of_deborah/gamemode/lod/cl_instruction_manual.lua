-- One portable reader. The staging entity and Player Menu only call Open().
LOD = LOD or {}
LOD.FieldManual = LOD.FieldManual or {}
local Manual = LOD.FieldManual
local UI = LOD.UI
local REQUEST_NET = "LOD_RequestInstructionManual"
local PAYLOAD_NET = "LOD_InstructionManualPayload"
local MAX_PACKED_BYTES = 4 * 1024 * 1024
local ACK_NET = "LOD_InstructionManualAck"
local MAX_CHUNKS = 255
local MAX_HTML_BYTES = 8 * 1024 * 1024
Manual.Page = Manual.Page or cookie.GetNumber("lod_manual_page", 0)
Manual.Scroll = Manual.Scroll or cookie.GetNumber("lod_manual_scroll", 0)
Manual.TextSize = Manual.TextSize or cookie.GetNumber("lod_manual_text_size", 18)
Manual.Chapters = Manual.Chapters or 124
local rejectTransfer

function Manual:RequestPayload()
    local now = RealTime()
    if self.RequestedAt then return end
    self.RequestedAt = now
    self.ProgressAt = now
    self.Transfer = nil
    net.Start(REQUEST_NET)
    net.SendToServer()
    local function watchdog()
        if Manual.RequestedAt ~= now or isstring(Manual.HTML) then return end
        if RealTime() - (Manual.ProgressAt or now) >= 15 then
            rejectTransfer("BOOKLET SERVER DID NOT RESPOND")
        else
            timer.Simple(1, watchdog)
        end
    end
    timer.Simple(1, watchdog)
end

function Manual:LoadDocument()
    local browser = self.Browser
    if not IsValid(browser) or not isstring(self.HTML) then return end
    if IsValid(self.LoadingLabel) then self.LoadingLabel:Remove() end
    self.LoadingLabel = nil
    browser.LODManualDocument = true
    if LOD.RuntimeAudit then LOD.RuntimeAudit:Record("MANUAL_HTML", "bytes=" .. #self.HTML) end
    browser:SetHTML(self.HTML)
end

rejectTransfer = function(message)
    Manual.Transfer = nil
    Manual.RequestedAt = nil
    if IsValid(Manual.LoadingLabel) then
        Manual.LoadingLabel:SetText(message .. "\nClick to retry.")
        Manual.LoadingLabel:SetMouseInputEnabled(true)
        Manual.LoadingLabel.DoClick = function()
            if IsValid(Manual.LoadingLabel) then
                Manual.LoadingLabel:SetText("RETRIEVING INSTRUCTION BOOKLET…")
                Manual.LoadingLabel:SetMouseInputEnabled(false)
            end
            Manual:RequestPayload()
        end
    end
end

net.Receive(PAYLOAD_NET, function()
    if not Manual.RequestedAt then return end
    local version = net.ReadString()
    local chapters = net.ReadUInt(8)
    local transferId = net.ReadUInt(16)
    local index = net.ReadUInt(8)
    local count = net.ReadUInt(8)
    local total = net.ReadUInt(24)
    local size = net.ReadUInt(16)
    if version == "" or chapters < 1 or transferId < 1 or index < 1 or index > count
        or count < 1 or count > MAX_CHUNKS or total < 1 or total > MAX_PACKED_BYTES
        or size < 1 or size > 16384
    then
        rejectTransfer("BOOKLET TRANSFER REJECTED")
        return
    end

    local data = net.ReadData(size)
    if not isstring(data) or #data ~= size then
        rejectTransfer("BOOKLET TRANSFER INCOMPLETE")
        return
    end

    local transfer = Manual.Transfer
    if not transfer then
        if index ~= 1 then rejectTransfer("BOOKLET TRANSFER OUT OF ORDER"); return end
        transfer = {id = transferId, version = version, chapters = chapters,
            count = count, total = total, chunks = {}, received = 0}
        Manual.Transfer = transfer
    end
    if transfer.id ~= transferId or index ~= transfer.received + 1 or transfer.version ~= version or transfer.chapters ~= chapters
        or transfer.count ~= count or transfer.total ~= total
    then
        rejectTransfer("BOOKLET TRANSFER MISMATCH")
        return
    end
    if not transfer.chunks[index] then
        transfer.chunks[index] = data
        transfer.received = transfer.received + 1
    end
    Manual.ProgressAt = RealTime()
    if IsValid(Manual.LoadingLabel) then
        Manual.LoadingLabel:SetText(string.format("RETRIEVING INSTRUCTION BOOKLET… %d%%", math.floor(index * 100 / count)))
    end
    net.Start(ACK_NET); net.WriteUInt(transferId, 16); net.WriteUInt(index, 8); net.SendToServer()
    if transfer.received ~= count then return end

    local packed = table.concat(transfer.chunks)
    if #packed ~= total then
        rejectTransfer("BOOKLET TRANSFER TRUNCATED")
        return
    end
    local html = util.Decompress(packed, MAX_HTML_BYTES)
    if not isstring(html) or not string.find(html, "<!doctype html>", 1, true) then
        rejectTransfer("BOOKLET DECOMPRESSION FAILED")
        return
    end
    Manual.Transfer = nil
    Manual.RequestedAt = nil
    Manual.Version = version
    Manual.Chapters = chapters
    Manual.HTML = html
    Manual:LoadDocument()
end)

function Manual:Close()
    cookie.Set("lod_manual_page", self.Page or 0)
    cookie.Set("lod_manual_scroll", self.Scroll or 0)
    cookie.Set("lod_manual_text_size", self.TextSize or 18)
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame, self.Browser = nil, nil
    if UI.ActivePage == "manual" then UI.ActivePage = nil end
end

function Manual:Open()
    if LOD.UI.IsMinigameLocked and LOD.UI:IsMinigameLocked() then return false end
    if LOD.RuntimeAudit then LOD.RuntimeAudit:Record("MANUAL_OPEN", "cached=" .. tostring(isstring(self.HTML))) end
    if IsValid(self.Frame) then self.Frame:MakePopup(); return end
    UI:SelectPage("manual")
    local page = math.Clamp(math.floor(tonumber(self.Page) or 0), 0, self.Chapters - 1)
    local scroll = math.max(0, tonumber(self.Scroll) or 0)
    local size = math.floor(math.Clamp(tonumber(self.TextSize) or 18, 15, 26))
    local frame = vgui.Create("DFrame")
    self.Frame = frame
    frame:SetSize(math.min(1180, ScrW() - 24), math.min(850, ScrH() - 24))
    frame:Center(); frame:SetTitle(""); frame:SetDraggable(false)
    frame:SetDeleteOnClose(true); frame:MakePopup()
    frame.Paint = function(_, w, h)
        UI:Paper(0, 0, w, h)
        draw.SimpleText("INSTRUCTION BOOKLET", "LOD_SheetHeading", 24, 25, UI.Colors.blue)
    end
    UI:CloseButton(frame, function() Manual:Close() end)
    UI:PageLinks(frame, "manual", 76)
    local browser = vgui.Create("DHTML", frame)
    self.Browser = browser
    browser:SetPos(12, 110); browser:SetSize(frame:GetWide() - 24, frame:GetTall() - 122)
    local loading = vgui.Create("DButton", frame)
    self.LoadingLabel = loading
    loading:SetPos(24, 130); loading:SetSize(frame:GetWide() - 48, frame:GetTall() - 162)
    loading:SetText("RETRIEVING INSTRUCTION BOOKLET…")
    loading:SetFont("LOD_SheetHeading"); loading:SetTextColor(UI.Colors.blue)
    loading:SetContentAlignment(5); loading:SetWrap(true)
    -- Garry's Mod installs AddFunction into the current document, so registering
    -- before SetHTML loses the bridge when Chromium replaces about:blank. Bind
    -- after every document-ready event and restore the bookmark from that same
    -- event. Arbitrary RunLua remains disabled.
    browser:SetAllowLua(false)
    browser.OnDocumentReady = function(panel)
        if Manual.Browser ~= browser or not IsValid(browser) or not browser.LODManualDocument then return end
        if LOD.RuntimeAudit then LOD.RuntimeAudit:Record("MANUAL_READY", Manual.Version) end
        panel:AddFunction("lod", "position", function(nextPage, nextScroll, nextSize)
            if Manual.Browser ~= browser or not IsValid(browser) then return end
            nextPage, nextScroll, nextSize = tonumber(nextPage), tonumber(nextScroll), tonumber(nextSize)
            if not nextPage or nextPage ~= nextPage or not nextScroll or nextScroll ~= nextScroll
                or not nextSize or nextSize ~= nextSize then return end
            Manual.Page = math.Clamp(math.floor(nextPage), 0, Manual.Chapters - 1)
            Manual.Scroll = math.Clamp(nextScroll, 0, 1000000)
            Manual.TextSize = math.Clamp(nextSize, 15, 26)
        end)
        panel:AddFunction("lod", "close", function()
            if Manual.Browser == browser then Manual:Close() end
        end)
        panel:AddFunction("lod", "tab", function(code, name)
            if Manual.Browser ~= browser then return end
            local key = ({[80] = KEY_P, [73] = KEY_I, [76] = KEY_L})[tonumber(code)]
            local equipment=LOD.Equipment
            if equipment and equipment.MenuKey then
                local bound=equipment.MenuKey:GetInt()
                local keyName=input.GetKeyName and input.GetKeyName(bound)
                if bound==KEY_O and tonumber(code)==79 or keyName and keyName:lower()==tostring(name or ''):lower() then key=bound end
            end
            if key then UI:PageKey(key) end
        end)
        browser:QueueJavascript(string.format("window.LODManual.restore(%d,%.1f,%d);", page, scroll, size))
    end
    if isstring(self.HTML) then self:LoadDocument() else self:RequestPayload() end
end

-- Registration is independent of whether a physical book exists on this map.
net.Receive("LOD_OpenFieldManual", function() Manual:Open() end)
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["manual_reader"] = "generator-jit-20260917-01"
