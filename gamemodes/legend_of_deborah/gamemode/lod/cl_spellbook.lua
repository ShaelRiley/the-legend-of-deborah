LOD = LOD or {}
LOD.Spellbook = LOD.Spellbook or {}

local Book = LOD.Spellbook
local UI, C = LOD.UI, LOD.UI.Colors
local descriptions = {
    wall = "Barrier / WIS duration", super_ball = "Ricocheting multi-hit", watermelon = "1d6 bounces + shatter", cone = "Directional force cone", blast = "Surrounding area", beam = "Piercing line", bomb = "Lobbed area",
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

function Book:Availability(entry,kind)
    if not entry.owned then return entry.wizardOnly and "WIZARD / LOCKED" or "LOCKED",C.muted end
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return "UNAVAILABLE",C.muted end
    if ply:GetNW2Bool("LOD_StatusMuted",false) or ply:GetNW2Bool("LOD_StatusIntimidated",false)
        or ply:GetNW2Int("LOD_ThrowableCount",0)>0 and LOD.Equipment:IsActive(ply) then return "BLOCKED",C.red end
    if CurTime()<ply:GetNW2Float("LOD_MagicNextCast",0) then return "COOLDOWN",C.gold end
    if kind=="form" and entry.id=="super_ball" and ply:GetNW2Int("LOD_SuperBallRemaining",1)<=0 then return "BALL LIMIT",C.gold end
    if kind=="form" and entry.id=="wall" and ply:GetNW2Int("LOD_WallRemaining",1)<=0 then return "WALL LIMIT",C.gold end
    local snap=self.Snapshot or {};local base,surcharge=0,0
    for _,f in ipairs(snap.forms or {}) do if f.selected then base=f.magicCost or 0 end end
    for _,c in ipairs(snap.contents or {}) do if c.selected then surcharge=c.surcharge or 0 end end
    if kind=="form" then base=entry.magicCost or 0 else surcharge=entry.surcharge or 0 end
    local cost=math.ceil((base+surcharge)*(snap.costMultiplier or 1))
    if ply:GetNW2Float("LOD_Magic",0)<cost then return "NEED MAGIC",C.red end
    return entry.selected and "READY / SELECTED" or "AVAILABLE",C.blue
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
        local label,color = Book:Availability(entry,kind)
        local title=string.upper(entry.displayName or entry.id)
        if kind=='form' then
            for key,id in pairs(Book.Snapshot.bindings or {}) do
                if id==entry.id then title=title..' ['..(key=='2' and 'RMB' or 'M'..key)..']' end
            end
        end
        local titleFont="LOD_SheetSubheading";surface.SetFont(titleFont)
        if surface.GetTextSize(title)>width-8 then titleFont="LOD_SheetSmall" end
        draw.SimpleText(title,titleFont,
            width*0.5,height<120 and 5 or 16,color,TEXT_ALIGN_CENTER)
        local labelFont="LOD_SheetKey"
        surface.SetFont(labelFont)
        if surface.GetTextSize(label)>width-8 then labelFont="DermaDefault" end
        draw.SimpleText(label,
            labelFont,width*0.5,height<120 and 27 or 44,color,TEXT_ALIGN_CENTER)
        local cost = kind == "form" and string.format("%d base Magic",entry.magicCost or 0)
            or string.format("+%d Magic",entry.surcharge or 0)
        draw.SimpleText(cost,"LOD_SheetSmall",width*0.5,height<120 and 47 or 72,C.ink,TEXT_ALIGN_CENTER)
        draw.SimpleText(descriptions[entry.id] or "","LOD_SheetSmall",width*0.5,height<120 and 66 or 100,C.muted,TEXT_ALIGN_CENTER)
        if self:IsHovered() and entry.owned then
            surface.SetDrawColor(C.blue);surface.DrawRect(8,height-6,width-16,2)
        end
    end
    local function select(buttonCode)
        if not entry.owned then return end
        surface.PlaySound("buttons/button14.wav")
        if kind=='form' then
            local button=({[MOUSE_MIDDLE]=3,[MOUSE_4]=4,[MOUSE_5]=5})[buttonCode] or 2
            net.Start("LOD_MagicBindForm");net.WriteString(entry.id);net.WriteUInt(button,3)
        else
            net.Start("LOD_MagicSpellbookSelect");net.WriteUInt(1,1);net.WriteString(entry.id)
        end
        net.SendToServer()
    end
    button.DoClick=function() select(MOUSE_LEFT) end
    button.DoRightClick=function() select(MOUSE_RIGHT) end
    local nativePressed=button.OnMousePressed
    button.OnMousePressed=function(self,code)
        if code==MOUSE_MIDDLE or code==MOUSE_4 or code==MOUSE_5 then select(code)
        elseif nativePressed then nativePressed(self,code) end
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
        draw.SimpleText("CONTENT / ELEMENT & RIDER","LOD_SheetSubheading",24,303,C.red)
        draw.SimpleText("Click a Form with LMB/RMB to bind RMB; click with M3/M4/M5 to bind that button.",
            "LOD_SheetBody",24,h-64,C.ink)
        draw.SimpleText("Locked entries unlock through progression. Gameplay continues while this book is open.",
            "LOD_SheetSmall",24,h-38,C.muted)
    end

    UI:PageLinks(frame,"book",frame:GetTall()-96)
    local width = frame:GetWide()
    local gap = 10
    local left = 24
    local usable = width - left * 2
    local formCount=math.max(1,#(self.Snapshot.forms or {}))
    local columns=math.min(5,formCount)
    local formW = math.floor((usable - gap * (columns-1)) / columns)
    for i, entry in ipairs(self.Snapshot.forms or {}) do
        selectionButton(frame, entry, "form", left + ((i - 1)%columns) * (formW + gap), 100+math.floor((i-1)/columns)*98, formW, 88)
    end

    local contentW = math.floor((usable - gap * 6) / 7)
    for i, entry in ipairs(self.Snapshot.contents or {}) do
        selectionButton(frame, entry, "content", left + (i - 1) * (contentW + gap), 327, contentW, 113)
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
