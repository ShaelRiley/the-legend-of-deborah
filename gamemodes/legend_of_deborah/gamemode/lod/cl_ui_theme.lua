LOD = LOD or {}
-- Paper menus and transparent gameplay readouts share semantic roles, not panels.
LOD.UI = LOD.UI or {}
local UI = LOD.UI
UI.Colors = {
    paper = Color(244, 237, 218), light = Color(251, 247, 233), ink = Color(32, 32, 29),
    red = Color(170, 61, 50), blue = Color(55, 91, 145), peach = Color(237, 201, 162),
    gold = Color(145, 104, 29), muted = Color(112, 104, 91), rule = Color(190, 177, 149),
    green = Color(55, 108, 70), violet = Color(105, 73, 130), frame = Color(18, 19, 21, 248)
}
local C = UI.Colors
UI.Roles = {prose = C.ink, identity = C.blue, character = C.red, recipient = C.red,
    source = C.green, dice = C.violet, continuation = C.gold, total = C.gold,
    damage = C.red, resource = C.green, status = C.violet, awareness = C.violet, resist = C.blue,
    magic = C.blue, progress = C.gold, objective = C.gold, danger = C.red,
    life = C.green, soldier = C.blue, proc = C.violet, clear = C.green,
    weakness = C.red, blocked = C.red, kill = C.red, routine = C.ink}
function UI:Paper(x, y, w, h, accent, alpha, inset)
    alpha, inset = alpha or 255, inset or 4
    local function tint(c) return Color(c.r, c.g, c.b, math.min(c.a or 255, alpha)) end
    draw.RoundedBox(3, x, y, w, h, tint(C.frame))
    draw.RoundedBox(1, x + inset, y + inset, w - inset * 2, h - inset * 2, tint(C.paper))
    surface.SetDrawColor(tint(accent or C.red))
    surface.DrawRect(x + inset, y + inset, w - inset * 2, 3)
    surface.SetDrawColor(tint(C.blue))
    surface.DrawRect(x + inset, y + h - inset - 2, w - inset * 2, 2)
end
function UI:Button(button, accent)
    button:SetFont("LOD_SheetKey")
    button:SetTextColor(C.ink)
    button.Paint = function(self, w, h)
        draw.RoundedBox(1, 0, 0, w, h, self:IsHovered() and C.peach or C.light)
        surface.SetDrawColor(self:IsEnabled() and (accent or C.blue) or C.rule)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
end
function UI:CloseButton(frame, callback)
    frame:ShowCloseButton(false)
    local close = vgui.Create("DButton", frame)
    close:SetText("CLOSE / ESC")
    close:SetPos(frame:GetWide() - 128, 22)
    close:SetSize(104, 26)
    self:Button(close, C.red)
    close.DoClick = callback
    frame.LODAcceptToggleAt=RealTime()+0.15
    frame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then callback()
        elseif RealTime() >= frame.LODAcceptToggleAt then UI:PageKey(key) end
    end
    return close
end
-- Closing pending requests is part of closing a page, so delayed snapshots cannot
-- steal focus from the page the player deliberately chose.
function UI:SelectPage(page)
    self.ActivePage = page
    if page ~= "wallet" and LOD.Wallet and LOD.Wallet.Close then LOD.Wallet:Close() end
    if page ~= "sheet" and LOD.CharacterSheet and LOD.CharacterSheet.Close then LOD.CharacterSheet:Close() end
    if page ~= "book" and LOD.Spellbook and LOD.Spellbook.Close then LOD.Spellbook:Close() end
    if page ~= "manual" and LOD.FieldManual and LOD.FieldManual.Close then LOD.FieldManual:Close() end
    if page ~= "equipment" and LOD.Equipment and LOD.Equipment.Close then LOD.Equipment:Close() end
    if page ~= "history" and LOD.CombatRollFeed and IsValid(LOD.CombatRollFeed.HistoryFrame) then
        LOD.CombatRollFeed.HistoryFrame:Remove()
    end
end

surface.CreateFont("LOD_SheetTitle", {
    font = "DejaVu Sans Condensed", size = 38, weight = 1000, antialias = true
})
surface.CreateFont("LOD_SheetHeading", {
    font = "DejaVu Sans Condensed", size = 24, weight = 1000, antialias = true
})
surface.CreateFont("LOD_SheetSubheading", {
    font = "DejaVu Sans Condensed", size = 18, weight = 900, antialias = true
})
surface.CreateFont("LOD_SheetBody", {
    font = "Georgia", size = 17, weight = 500, antialias = true
})
surface.CreateFont("LOD_SheetSmall", {
    font = "Georgia", size = 14, weight = 500, antialias = true
})
surface.CreateFont("LOD_SheetKey", {
    font = "DejaVu Sans", size = 14, weight = 1000, antialias = true
})


function UI:PageLinks(frame, active, y)
    local key=LOD.Equipment and LOD.Equipment.MenuKey
    local equipmentLabel=(key and input.GetKeyName and input.GetKeyName(key:GetInt()) or "O"):upper().." / EQUIPMENT"
    local pages={{"sheet","P / CHARACTER",function() LOD.CharacterSheet:Open() end},
        {"book","I / SPELLBOOK",function() LOD.Spellbook:Open() end},
        {"equipment",equipmentLabel,function() LOD.Equipment:Open() end},
        {"history","L / DIE-LOGGER",function() LOD.CombatRollFeed:OpenHistory() end},
        {"manual","MANUAL",function() LOD.FieldManual:Open() end}}
    if LOD.Wallet then pages[#pages+1]={"wallet","WALLET",function() LOD.Wallet:Open() end} end
    local tabWidth=math.min(144,(frame:GetWide()-48-10*(#pages-1))/#pages)
    for i,page in ipairs(pages) do
        local button=vgui.Create("DButton",frame)
        button:SetText(frame:GetWide()<760 and (page[1]=="sheet" and "P / HERO" or page[1]=="book" and "I / MAGIC" or page[1]=="history" and "L / LOG" or page[2]) or page[2]);button:SetPos(24+(i-1)*(tabWidth+10),y);button:SetSize(tabWidth,24)
        self:Button(button,page[1]==active and C.red or C.blue)
        button.DoClick=page[3]
    end
end

function UI:PageKey(key)
    local focus=vgui.GetKeyboardFocus and vgui.GetKeyboardFocus()
    if IsValid(focus) and (focus.IsEditing and focus:IsEditing()
        or focus.GetClassName and (focus:GetClassName()=="DTextEntry" or focus:GetClassName()=="DBinder")) then return end
    local equipment=LOD.Equipment
    if equipment and equipment.MenuKey and key==equipment.MenuKey:GetInt() then equipment:Toggle()
    elseif key == KEY_P then LOD.CharacterSheet:Toggle()
    elseif key == KEY_I then LOD.Spellbook:Toggle()
    elseif key == KEY_L then
        LOD.CombatRollFeed:ToggleHistory()
    end
end

-- Gameplay text needs luminous colors against the world; menus retain dark ink.
-- Hue still means the same thing on both surfaces. No HUD background or border.
UI.HUDColor = Color(255, 220, 100)
UI.HUDRoles = {
    prose = Color(240, 232, 205), routine = Color(240, 232, 205),
    identity = Color(120, 180, 255), character = Color(255, 135, 115),
    recipient = Color(255, 135, 115), source = Color(165, 215, 170),
    dice = Color(205, 175, 255), continuation = UI.HUDColor, total = UI.HUDColor,
    damage = Color(255, 135, 115), danger = Color(255, 135, 115),
    resource = Color(165, 235, 165), life = Color(165, 235, 165), clear = Color(165, 235, 165),
    status = Color(205, 175, 255), proc = Color(205, 175, 255), awareness = Color(195, 130, 255),
    resist = Color(120, 180, 255), magic = Color(120, 180, 255), soldier = Color(120, 180, 255),
    progress = UI.HUDColor, objective = UI.HUDColor, weakness = Color(255, 135, 115),
    blocked = Color(255, 135, 115), kill = Color(255, 135, 115)
}
function UI:HUDText(text, font, x, y, color, alignX, alignY)
    color = color or self.HUDColor
    draw.SimpleTextOutlined(text, font, x, y, color, alignX or TEXT_ALIGN_LEFT,
        alignY or TEXT_ALIGN_TOP, 1, Color(0, 0, 0, math.floor((color.a or 255)*0.8)))
end
