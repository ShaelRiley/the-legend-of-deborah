include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    local light = DynamicLight(self:EntIndex())
    if light then
        light.pos = self:GetPos() + Vector(0, 0, 12)
        light.r = 255
        light.g = 190
        light.b = 45
        light.brightness = 1.1
        light.Decay = 700
        light.Size = 84
        light.DieTime = CurTime() + 0.08
    end
end
