LOD = LOD or {}
LOD.Spellbook = LOD.Spellbook or {}

local Book = LOD.Spellbook
local BG = Color(24, 24, 28, 248)
local PANEL = Color(42, 44, 51, 245)
local INK = Color(240, 237, 225)
local MUTED = Color(130, 132, 140)
local SELECTED = Color(184, 94, 52)
local AVAILABLE = Color(67, 92, 122)

surface.CreateFont("LOD_SpellbookTitle", {font = "DejaVu Sans Condensed", size = 34, weight = 1000})
surface.CreateFont("LOD_SpellbookButton", {font = "DejaVu Sans Condensed", size = 20, weight = 900})
surface.CreateFont("LOD_SpellbookSmall", {font = "DejaVu Sans", size = 15, weight = 600})

local function inputBusy()
    return gui.IsConsoleVisible() or (chat.IsTyping and chat.IsTyping())
end

function Book:Close()
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame = nil
end

local function selectionButton(parent, entry, kind, x, y, w, h)
    local button = vgui.Create("DButton", parent)
    button:SetPos(x, y)
    button:SetSize(w, h)
    local suffix = entry.owned and "" or "\nLOCKED"
    if kind == "form" then
        suffix = suffix .. string.format("\n%d Magic", tonumber(entry.magicCost) or 0)
    elseif entry.id ~= "raw" then
        suffix = suffix .. string.format("\n+%d Magic", tonumber(entry.surcharge) or 0)
    end
    button:SetText(string.upper(entry.displayName or entry.id) .. suffix)
    button:SetFont("LOD_SpellbookButton")
    button:SetTextColor(entry.owned and INK or MUTED)
    button:SetEnabled(entry.owned == true)
    button.Paint = function(self, width, height)
        local color = entry.selected and SELECTED or (entry.owned and AVAILABLE or PANEL)
        if self:IsHovered() and entry.owned then
            color = Color(math.min(255, color.r + 18), math.min(255, color.g + 18),
                math.min(255, color.b + 18), color.a)
        end
        draw.RoundedBox(4, 0, 0, width, height, color)
        surface.SetDrawColor(255, 255, 255, entry.selected and 150 or 35)
        surface.DrawOutlinedRect(0, 0, width, height, entry.selected and 2 or 1)
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
    frame:ShowCloseButton(true)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, BG)
        draw.SimpleText("SPELLBOOK", "LOD_SpellbookTitle", 24, 18, INK, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(string.format("Magic %.1f / %d", LocalPlayer():GetNW2Float("LOD_Magic", 100),
            LocalPlayer():GetNW2Int("LOD_MagicMax", 100)), "LOD_SpellbookSmall",
            w - 28, 28, INK, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText("FORM — choose one delivery shape", "LOD_SpellbookSmall", 24, 72,
            MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("CONTENT — choose RAW or one unlocked element", "LOD_SpellbookSmall", 24, 267,
            MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("RMB casts the selected Form + Content through the shared Magic authority.",
            "LOD_SpellbookSmall", 24, h - 34, MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

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
    if IsValid(self.Frame) then self:Close() else self:Open() end
end

net.Receive("LOD_MagicSpellbookSnapshot", function()
    local snapshot = net.ReadTable()
    if not istable(snapshot) then return end
    Book.Snapshot = snapshot
    if IsValid(Book.Frame) or Book.PendingOpen then Book:Open() end
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

local FX = {}
local material = Material("sprites/light_glow02_add")
local colors = {
    raw = Color(210, 235, 255), earth = Color(194, 156, 88), fire = Color(255, 105, 45),
    dark = Color(125, 72, 170), ice = Color(125, 220, 255), light = Color(255, 245, 170),
    electric = Color(110, 180, 255)
}

net.Receive("LOD_MagicFormFX", function()
    FX[#FX + 1] = {
        form = net.ReadString(),
        content = net.ReadString(),
        origin = net.ReadVector(),
        destination = net.ReadVector(),
        started = CurTime(),
        lifetime = 0.24
    }
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_MagicFormPresentation", function()
    local now = CurTime()
    for i = #FX, 1, -1 do
        local fx = FX[i]
        local age = now - fx.started
        if age >= fx.lifetime then
            table.remove(FX, i)
        else
            local fade = math.Clamp(1 - age / fx.lifetime, 0, 1)
            local c = colors[fx.content] or colors.raw
            render.SetMaterial(material)
            if fx.form == "beam" then
                render.DrawBeam(fx.origin, fx.destination, 7 + 5 * fade, 0, 1,
                    Color(c.r, c.g, c.b, math.floor(230 * fade)))
            else
                render.DrawSprite(fx.destination, 54 + 70 * (1 - fade), 54 + 70 * (1 - fade),
                    Color(c.r, c.g, c.b, math.floor(210 * fade)))
            end
        end
    end
end)

hook.Add("ShutDown", "LOD_SpellbookClose", function() Book:Close() end)
