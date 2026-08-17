include("shared.lua")

local PC = LOD.Config.Progression
local cardMaterial = CreateMaterial("lod_keycard_opaque_v1", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1"
})

function ENT:Draw()
    local card = PC.Cards[math.Clamp(self:GetCardIndex(), 1, 3)]
    render.SetMaterial(cardMaterial)
    render.CullMode(MATERIAL_CULLMODE_NONE)
    render.DrawBox(self:GetPos(), Angle(0, CurTime() * 45 % 360, 0), Vector(-18, -28, -3), Vector(18, 28, 3), card.color)
    render.CullMode(MATERIAL_CULLMODE_CCW)

    local ang = Angle(0, EyeAngles().y - 90, 90)
    cam.Start3D2D(self:GetPos() + Vector(0, 0, 38), ang, 0.12)
        draw.RoundedBox(4, -130, -30, 260, 60, Color(16, 18, 20, 230))
        draw.SimpleText(card.name .. " KEYCARD", "DermaLarge", 0, -8, card.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(card.letter .. " / " .. card.symbol, "DermaDefaultBold", 0, 18, Color(245, 245, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
