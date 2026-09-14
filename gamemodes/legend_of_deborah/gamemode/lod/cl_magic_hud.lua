LOD = LOD or {}

-- Magic visually replaces the stock CHudBattery/Suit readout, but does not use
-- the HL2 armor pool. Valve's HudLayout.res coordinates are proportional to a
-- 640x480 HUD canvas. IMPORTANT: Garry's Mod ScreenScale() scales from WIDTH,
-- so using it for Y on a widescreen display pushes the Suit slot off-screen.
-- Use one height-derived proportional scale for both axes/sizes instead.
local MAGIC_COLOR = LOD.UI.HUDColor
local DIVERSION_COLOR = Color(180, 225, 255, 235)

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
    if not IsValid(ply) or not ply:Alive() then
        return
    end

    local maximum = math.max(1, ply:GetNW2Int("LOD_MagicMax", 100))
    local magic = math.Clamp(ply:GetNW2Float("LOD_Magic", maximum), 0, maximum)
    local value = math.floor(magic + 0.5)
    local muted = ply:GetNW2Bool("LOD_StatusMuted", false)
    local layout = hudSuitLayout()

    local x = ps(layout.x)
    local y = ps(layout.y)

    local diversion = LOD.WizardFX and LOD.WizardFX.active and LOD.WizardFX.active[4]
    local color = diversion and CurTime() - diversion.created < 0.45 and DIVERSION_COLOR or MAGIC_COLOR
    LOD.UI:HUDText("MAGIC", "Default", x + ps(layout.textX), y + ps(layout.textY), color)
    LOD.UI:HUDText(muted and "MUTE" or tostring(value), muted and "HudHintTextLarge" or "HudNumbers",
        x + ps(layout.digitX), y + ps(layout.digitY), color)

end)
