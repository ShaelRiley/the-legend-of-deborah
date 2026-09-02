LOD = LOD or {}

-- Magic visually replaces the stock CHudBattery/Suit readout, but does not use
-- the HL2 armor pool. Valve's HudLayout.res coordinates are proportional to a
-- 640x480 HUD canvas. IMPORTANT: Garry's Mod ScreenScale() scales from WIDTH,
-- so using it for Y on a widescreen display pushes the Suit slot off-screen.
-- Use one height-derived proportional scale for both axes/sizes instead.
local MAGIC_COLOR = Color(72, 168, 255, 255)
local PANEL_COLOR = Color(0, 0, 0, 145)
local DIVERSION_COLOR = Color(180, 225, 255, 235)
local DIVERSION_PANEL = Color(72, 168, 255, 95)

local lastDiversionSerial = -1
local diversionPulseUntil = 0
local diversionTextUntil = 0
local lastDivertedHP = 0
local lastDivertedMagic = 0

local function ps(value)
    return value * (ScrH() / 480)
end

local function hudSuitLayout()
    -- Valve ships a dedicated Steam Deck HudSuit layout. Use it for the Deck's
    -- characteristic 16:10 low-height viewport; otherwise use the normal HL2MP
    -- HudSuit values. Both are still rendered through the same 640x480
    -- height-proportional coordinate system.
    local aspect = ScrW() / math.max(1, ScrH())
    local deckLike = ScrH() <= 900 and aspect >= 1.55 and aspect <= 1.65

    if deckLike then
        return {
            x = 150, y = 426, w = 120, h = 42,
            textX = 8, textY = 23,
            digitX = 56, digitY = 0
        }
    end

    return {
        x = 140, y = 432, w = 108, h = 36,
        textX = 8, textY = 20,
        digitX = 50, digitY = 2
    }
end

hook.Add("HUDShouldDraw", "LOD_MagicReplacesSuitBattery", function(name)
    if name == "CHudBattery" then return false end
end)

hook.Add("HUDPaint", "LOD_MagicHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local maximum = math.max(1, ply:GetNW2Int("LOD_MagicMax", 100))
    local magic = math.Clamp(ply:GetNW2Float("LOD_Magic", maximum), 0, maximum)
    local value = math.floor(magic + 0.5)
    local layout = hudSuitLayout()

    local x = ps(layout.x)
    local y = ps(layout.y)
    local w = ps(layout.w)
    local h = ps(layout.h)

    local serial = ply:GetNW2Int("LOD_ArcaneDiversionSerial", 0)
    if lastDiversionSerial < 0 then
        lastDiversionSerial = serial
    elseif serial ~= lastDiversionSerial then
        lastDiversionSerial = serial
        lastDivertedHP = math.max(0, ply:GetNW2Float("LOD_ArcaneDiversionHP", 0))
        lastDivertedMagic = math.max(0, ply:GetNW2Float("LOD_ArcaneDiversionMagic", 0))
        diversionPulseUntil = CurTime() + 0.45
        diversionTextUntil = CurTime() + 1.10
    end

    if CurTime() < diversionPulseUntil then
        local alphaScale = math.Clamp((diversionPulseUntil - CurTime()) / 0.45, 0, 1)
        draw.RoundedBox(ps(3), x - ps(3), y - ps(3), w + ps(6), h + ps(6),
            Color(DIVERSION_PANEL.r, DIVERSION_PANEL.g, DIVERSION_PANEL.b,
                math.floor(DIVERSION_PANEL.a * alphaScale)))
    end

    draw.RoundedBox(ps(2), x, y, w, h, PANEL_COLOR)

    surface.SetTextColor(MAGIC_COLOR)
    surface.SetFont("Default")
    surface.SetTextPos(x + ps(layout.textX), y + ps(layout.textY))
    surface.DrawText("MAGIC")

    surface.SetTextColor(MAGIC_COLOR)
    surface.SetFont("HudNumbers")
    surface.SetTextPos(x + ps(layout.digitX), y + ps(layout.digitY))
    surface.DrawText(tostring(value))

    if CurTime() < diversionTextUntil and lastDivertedHP > 0 then
        local text = string.format("ARCANE -%.1f HP / -%.1f MAGIC", lastDivertedHP, lastDivertedMagic)
        draw.SimpleText(text, "DefaultBold", x + w * 0.5, y - ps(4), DIVERSION_COLOR,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end
end)
