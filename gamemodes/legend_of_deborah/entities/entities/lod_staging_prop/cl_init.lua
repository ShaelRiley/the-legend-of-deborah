include("shared.lua")

local portalGlow = Material("sprites/light_glow02_add")

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    self:DrawModel()
    if self:GetStageKind() ~= self.KIND_PORTAL then return end

    local pos = self:GetPos() + Vector(0, 0, 30)
    render.SetMaterial(portalGlow)
    render.DrawSprite(pos, 86, 86, Color(92, 148, 255, 190))
end
