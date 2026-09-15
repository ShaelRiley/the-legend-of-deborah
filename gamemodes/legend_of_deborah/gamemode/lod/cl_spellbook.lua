LOD = LOD or {}
LOD.Spellbook = LOD.Spellbook or {}

local Book = LOD.Spellbook
local UI, C = LOD.UI, LOD.UI.Colors
local descriptions = {
    blast = "Surrounding area", beam = "Piercing line", bomb = "Lobbed area",
    missile = "Guided area", bolt = "Precision shot", summon = "Wizard-only Seeker",
    raw = "No Content rider", earth = "Push", fire = "Immolated", dark = "Poisoned",
    ice = "Held", light = "Muted", electric = "Intimidated"
}
local function inputBusy()
    return gui.IsConsoleVisible() or (chat.IsTyping and chat.IsTyping())
end

function Book:Close()
    if UI.ActivePage == "book" then UI.ActivePage = nil end
    self.PendingOpen = false
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame = nil
end

local function selectionButton(parent, entry, kind, x, y, w, h)
    local button = vgui.Create("DButton", parent)
    button:SetPos(x, y)
    button:SetSize(w, h)
    button:SetText("")
    button:SetEnabled(entry.owned == true)
    button.Paint = function(self, width, height)
        local selected = entry.selected == true
        draw.RoundedBox(1,0,0,width,height,selected and C.peach or C.light)
        surface.SetDrawColor(selected and C.red or C.rule)
        surface.DrawOutlinedRect(0,0,width,height,selected and 2 or 1)
        local color = entry.owned and C.blue or C.muted
        draw.SimpleText(string.upper(entry.displayName or entry.id),"LOD_SheetSubheading",
            width*0.5,16,color,TEXT_ALIGN_CENTER)
        draw.SimpleText(selected and "SELECTED" or (entry.owned and "AVAILABLE" or "LOCKED"),
            "LOD_SheetKey",width*0.5,44,selected and C.red or C.muted,TEXT_ALIGN_CENTER)
        local cost = kind == "form" and string.format("%d base Magic",entry.magicCost or 0)
            or string.format("+%d Magic",entry.surcharge or 0)
        draw.SimpleText(cost,"LOD_SheetSmall",width*0.5,72,C.ink,TEXT_ALIGN_CENTER)
        draw.SimpleText(descriptions[entry.id] or "","LOD_SheetSmall",width*0.5,100,C.muted,TEXT_ALIGN_CENTER)
        if self:IsHovered() and entry.owned then
            surface.SetDrawColor(C.blue);surface.DrawRect(8,height-6,width-16,2)
        end
    end
    button.DoClick = function()
        if not entry.owned then return end
        surface.PlaySound("buttons/button14.wav")
        net.Start("LOD_MagicSpellbookSelect")
        net.WriteUInt(kind == "form" and 0 or 1, 1)
        net.WriteString(entry.id)
        net.SendToServer()
    end
    return button
end

function Book:Open()
    self:Close()
    LOD.UI:SelectPage("book")
    if LOD.CharacterSheet and LOD.CharacterSheet.Close then LOD.CharacterSheet:Close() end
    if not self.Snapshot then
        self.PendingOpen = true
        net.Start("LOD_RPG_RequestSheet")
        net.SendToServer()
        return
    end
    self.PendingOpen = false

    local frame = vgui.Create("DFrame")
    self.Frame = frame
    frame:SetTitle("")
    frame:SetSize(math.min(ScrW() - 32, 1120), math.min(ScrH() - 32, 590))
    frame:Center()
    frame:MakePopup()
    UI:CloseButton(frame,function() Book:Close() end)
    frame.Paint = function(self,w,h)
        UI:Paper(0,0,w,h,C.red,255,8)
        draw.SimpleText("SPELLBOOK","LOD_SheetHeading",24,20,C.red)
        local ply = LocalPlayer()
        if IsValid(ply) then
            draw.SimpleText(string.format("Magic %.1f / %d",ply:GetNW2Float("LOD_Magic",100),
                ply:GetNW2Int("LOD_MagicMax",100)),"LOD_SheetBody",24,52,C.blue)
        end
        draw.SimpleText("FORM / DELIVERY","LOD_SheetSubheading",24,78,C.red)
        draw.SimpleText("CONTENT / ELEMENT & RIDER","LOD_SheetSubheading",24,266,C.red)
        draw.SimpleText("Right mouse casts the selected Form + Content. Base cost plus Content; feats may reduce the cost.",
            "LOD_SheetBody",24,h-64,C.ink)
        draw.SimpleText("Locked entries unlock through progression. Gameplay continues while this book is open.",
            "LOD_SheetSmall",24,h-38,C.muted)
    end

    UI:PageLinks(frame,"book",frame:GetTall()-96)
    local width = frame:GetWide()
    local gap = 10
    local left = 24
    local usable = width - left * 2
    local formW = math.floor((usable - gap * 5) / 6)
    for i, entry in ipairs(self.Snapshot.forms or {}) do
        selectionButton(frame, entry, "form", left + (i - 1) * (formW + gap), 100, formW, 140)
    end

    local contentW = math.floor((usable - gap * 6) / 7)
    for i, entry in ipairs(self.Snapshot.contents or {}) do
        selectionButton(frame, entry, "content", left + (i - 1) * (contentW + gap), 295, contentW, 140)
    end
end

function Book:Toggle()
    local now = RealTime()
    if (self.NextToggleAt or 0) > now then return end
    self.NextToggleAt = now + 0.15
    if IsValid(self.Frame) or self.PendingOpen then self:Close() else self:Open() end
end

net.Receive("LOD_MagicSpellbookSnapshot", function()
    local snapshot = net.ReadTable()
    if not istable(snapshot) then return end
    Book.Snapshot = snapshot
    if Book.PendingOpen or IsValid(Book.Frame) then Book:Open() end
end)

hook.Add("PlayerButtonDown", "LOD_SpellbookInput", function(ply, key)
    if ply ~= LocalPlayer() or inputBusy() then return end
    if key == KEY_I then
        Book:Toggle()
    elseif key == KEY_P and IsValid(Book.Frame) then
        Book:Close()
    end
end)

hook.Add("PlayerBindPress", "LOD_SpellbookBindingFallback", function(ply, _, pressed)
    if ply ~= LocalPlayer() or not pressed or inputBusy() then return end
    if input.IsKeyDown(KEY_I) then Book:Toggle() end
end)

concommand.Add("lod_spellbook", function() Book:Toggle() end)

hook.Add("ShutDown", "LOD_SpellbookClose", function() Book:Close() end)
