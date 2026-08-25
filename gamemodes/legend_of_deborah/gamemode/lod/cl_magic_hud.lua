LOD = LOD or {}

surface.CreateFont("LOD_MagicHUD_Label", {
    font = "DejaVu Sans",
    size = 13,
    weight = 700
})
surface.CreateFont("LOD_MagicHUD_Value", {
    font = "DejaVu Sans",
    size = 34,
    weight = 700
})

hook.Add("HUDShouldDraw", "LOD_MagicReplacesSuitBattery", function(name)
    if name == "CHudBattery" then return false end
end)

hook.Add("HUDPaint", "LOD_MagicHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNW2Bool("LOD_PlayedIdentity", false) then return end

    local maximum = math.max(1, ply:GetNW2Int("LOD_MagicMax", 100))
    local magic = math.Clamp(ply:GetNW2Float("LOD_Magic", maximum), 0, maximum)
    local ratio = magic / maximum

    -- Occupy the classic HEV/suit-resource neighborhood immediately to the
    -- right of the stock HL2 health panel. LOD never uses suit armor as health.
    local x = 176
    local y = ScrH() - 70
    local w = 150
    local h = 56

    draw.RoundedBox(4, x, y, w, h, Color(8, 12, 18, 178))
    draw.SimpleText("MAGIC", "LOD_MagicHUD_Label", x + 10, y + 10,
        Color(125, 205, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(tostring(math.floor(magic + 0.5)), "LOD_MagicHUD_Value", x + 12, y + 35,
        Color(175, 225, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local barX = x + 72
    local barY = y + 30
    local barW = w - 82
    local barH = 10
    draw.RoundedBox(2, barX, barY, barW, barH, Color(28, 42, 54, 220))
    draw.RoundedBox(2, barX, barY, math.floor(barW * ratio + 0.5), barH,
        Color(95, 185, 245, 235))
end)
