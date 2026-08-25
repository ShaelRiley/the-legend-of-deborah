LOD = LOD or {}

-- Magic visually replaces the stock CHudBattery/Suit readout, but does not use
-- the HL2 armor pool. Match Valve/GMod's actual HudSuit layout contract rather
-- than approximating it with a custom panel:
--   xpos 140, ypos 432, wide 108, tall 36
--   text 8,20; digits 50,2
-- All values are Source proportional coordinates on a 640x480 HUD canvas.
local MAGIC_COLOR = Color(72, 168, 255, 255)
local PANEL_COLOR = Color(0, 0, 0, 145)

local function ss(value)
    return ScreenScale(value)
end

hook.Add("HUDShouldDraw", "LOD_MagicReplacesSuitBattery", function(name)
    if name == "CHudBattery" then return false end
end)

hook.Add("HUDPaint", "LOD_MagicHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Do not gate the persistent Magic meter on LOD_PlayedIdentity. That network
    -- flag is used by some death/identity presentation paths but is not guaranteed
    -- to remain true throughout every ordinary live-run state. The main LOD HUD
    -- itself only requires a valid local player, so Magic follows the same rule.
    local maximum = math.max(1, ply:GetNW2Int("LOD_MagicMax", 100))
    local magic = math.Clamp(ply:GetNW2Float("LOD_Magic", maximum), 0, maximum)
    local value = math.floor(magic + 0.5)

    -- Exact stock HudSuit proportional bounds from HL2/GMod HudLayout.res.
    local x = ss(140)
    local y = ss(432)
    local w = ss(108)
    local h = ss(36)

    -- PaintBackgroundType 2 is the stock compact HUD-panel treatment. Lua does
    -- not expose that native border object directly, so reproduce its footprint
    -- with the same dark translucent bounding box while using the engine's own
    -- stock HUD fonts below.
    draw.RoundedBox(ss(2), x, y, w, h, PANEL_COLOR)

    -- CHudNumericDisplay itself uses TextFont="Default" and
    -- NumberFont="HudNumbers". Reuse those exact engine fonts so Magic has
    -- genuine font/size parity with the Suit indicator instead of a lookalike.
    surface.SetTextColor(MAGIC_COLOR)
    surface.SetFont("Default")
    surface.SetTextPos(x + ss(8), y + ss(20))
    surface.DrawText("MAGIC")

    surface.SetTextColor(MAGIC_COLOR)
    surface.SetFont("HudNumbers")
    surface.SetTextPos(x + ss(50), y + ss(2))
    surface.DrawText(tostring(value))
end)
