-- One portable reader. The staging entity and Player Menu only call Open().
LOD = LOD or {}
LOD.FieldManual = LOD.FieldManual or {}
local Manual = LOD.FieldManual
local UI = LOD.UI
local manifest = include("lod/manual/manifest.lua")
Manual.Manifest = manifest
Manual.Page = Manual.Page or cookie.GetNumber("lod_manual_page", 0)
Manual.Scroll = Manual.Scroll or cookie.GetNumber("lod_manual_scroll", 0)
Manual.TextSize = Manual.TextSize or cookie.GetNumber("lod_manual_text_size", 18)
local html

local function document()
    if html then return html end
    local chunks = {}
    for index = 1, manifest.chunks do
        chunks[index] = include(string.format("lod/manual/html_%02d.lua", index))
    end
    html = table.concat(chunks)
    return html
end

function Manual:Close()
    cookie.Set("lod_manual_page", self.Page or 0)
    cookie.Set("lod_manual_scroll", self.Scroll or 0)
    cookie.Set("lod_manual_text_size", self.TextSize or 18)
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame, self.Browser = nil, nil
    if UI.ActivePage == "manual" then UI.ActivePage = nil end
end

function Manual:Open()
    if IsValid(self.Frame) then self.Frame:MakePopup(); return end
    UI:SelectPage("manual")
    local page = math.Clamp(math.floor(tonumber(self.Page) or 0), 0, manifest.chapters - 1)
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
    -- Garry's Mod installs AddFunction into the current document, so registering
    -- before SetHTML loses the bridge when Chromium replaces about:blank. Bind
    -- after every document-ready event and restore the bookmark from that same
    -- event. Arbitrary RunLua remains disabled.
    browser:SetAllowLua(false)
    browser.OnDocumentReady = function(panel)
        if Manual.Browser ~= browser or not IsValid(browser) then return end
        panel:AddFunction("lod", "position", function(nextPage, nextScroll, nextSize)
            if Manual.Browser ~= browser or not IsValid(browser) then return end
            nextPage, nextScroll, nextSize = tonumber(nextPage), tonumber(nextScroll), tonumber(nextSize)
            if not nextPage or nextPage ~= nextPage or not nextScroll or nextScroll ~= nextScroll
                or not nextSize or nextSize ~= nextSize then return end
            Manual.Page = math.Clamp(math.floor(nextPage), 0, manifest.chapters - 1)
            Manual.Scroll = math.Clamp(nextScroll, 0, 1000000)
            Manual.TextSize = math.Clamp(nextSize, 15, 26)
        end)
        panel:AddFunction("lod", "close", function()
            if Manual.Browser == browser then Manual:Close() end
        end)
        panel:AddFunction("lod", "tab", function(code)
            if Manual.Browser ~= browser then return end
            local key = ({[80] = KEY_P, [73] = KEY_I, [76] = KEY_L})[tonumber(code)]
            if key then UI:PageKey(key) end
        end)
        browser:QueueJavascript(string.format("window.LODManual.restore(%d,%.1f,%d);", page, scroll, size))
    end
    browser:SetHTML(document())
end

-- Registration is independent of whether a physical book exists on this map.
net.Receive("LOD_OpenFieldManual", function() Manual:Open() end)
