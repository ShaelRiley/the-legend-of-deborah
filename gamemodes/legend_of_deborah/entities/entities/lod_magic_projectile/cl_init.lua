include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    local color = self:GetColor()
    local light = DynamicLight(self:EntIndex())
    if light then
        light.pos = self:GetPos()
        light.r = color.r
        light.g = color.g
        light.b = color.b
        light.brightness = 1.4
        light.Decay = 900
        light.Size = 96
        light.DieTime = CurTime() + 0.08
    end
end
