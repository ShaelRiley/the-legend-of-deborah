include("shared.lua")

local glow = Material("sprites/light_glow02_add")

function ENT:DrawTranslucent()
    render.SetMaterial(glow)
    render.DrawSprite(self:GetPos(), 14, 14, Color(255, 145, 70, 235))
end
