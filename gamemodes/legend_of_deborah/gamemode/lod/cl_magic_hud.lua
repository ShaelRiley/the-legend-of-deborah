LOD = LOD or {}

-- Mirror the visual language of Source/GMod's stock CHudBattery rather than
-- presenting Magic as a separate custom subsystem. The actual HL2 armor/suit
-- pool remains unused; only its familiar lower-left HUD footprint is inherited.
surface.CreateFont("LOD_MagicHUD_Label", {
    font = "Trebuchet MS",
    size = 12,
    weight = 700,
    antialias = true
})
surface.CreateFont("LOD_MagicHUD_Number", {
    font = "Trebuchet MS",
    size = 40,
    weight = 900,
    antialias = true
})

hook.Add("HUDShouldDraw", "LOD_MagicReplacesSuitBattery", function(name)
    if name == "CHudBattery" then return false end
end)

hook.Add("HUDPaint", "LOD_MagicHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_PlayedIdentity", false) then return end

    local maximum = math.max(1, ply:GetNW2Int("LOD_MagicMax", 100))
    local magic = math.Clamp(ply:GetNW2Float("LOD_Magic", maximum), 0, maximum)
    local value = math.floor(magic + 0.5)

    -- Stock CHudHealth occupies the far lower-left. CHudBattery normally sits
    -- directly beside it; keep that same compact horizontal footprint so MAGIC
    -- reads as the renamed/re-purposed suit indicator rather than a new widget.
    local scale = math.Clamp(ScrH() / 768, 0.80, 1.35)
    local x = math.floor(166 * scale)
    local y = ScrH() - math.floor(67 * scale)
    local w = math.floor(154 * scale)
    local h = math.floor(55 * scale)

    local panel = Color(0, 0, 0, 118)
    local normal = Color(255, 208, 64, 255)
    local low = Color(255, 96, 72, 255)
    local textColor = value <= 20 and low or normal

    draw.RoundedBox(0, x, y, w, h, panel)

    draw.SimpleText("MAGIC", "LOD_MagicHUD_Label",
        x + math.floor(10 * scale),
        y + math.floor(35 * scale),
        textColor,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER)

    draw.SimpleText(tostring(value), "LOD_MagicHUD_Number",
        x + math.floor(72 * scale),
        y + math.floor(28 * scale),
        textColor,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER)
end)
