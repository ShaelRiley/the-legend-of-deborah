include("shared.lua")

local beam = Material("effects/laser1")
local glow = Material("sprites/light_glow02_add")
local gold = Material("models/debug/debugwhite")

function ENT:Initialize()
    self:SetRenderBounds(Vector(-96, -96, -96), Vector(96, 96, 96))
end

function ENT:DrawTranslucent()
    local pos = self:GetPos()
    local direction = self:GetForward()
    local baseAngles = direction:Angle()
    local spin = (CurTime() * 620) % 360
    self:SetRenderAngles(Angle(baseAngles.p, baseAngles.y, spin))

    render.SuppressEngineLighting(false)
    render.MaterialOverride(nil)
    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    self:DrawModel()

    render.SuppressEngineLighting(true)
    render.MaterialOverride(gold)
    render.SetColorModulation(1, 0.72, 0.10)
    render.SetBlend(0.62)
    self:DrawModel()
    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
    render.SuppressEngineLighting(false)
    self:SetRenderAngles(nil)

    render.SetMaterial(beam)
    render.DrawBeam(pos - direction * 76, pos, 12, 0, 1,
        Color(255, 178, 34, 225))
    render.SetMaterial(glow)
    render.DrawSprite(pos, 54, 54, Color(255, 218, 88, 245))
    render.DrawSprite(pos, 25, 25, Color(255, 255, 214, 255))

    local light = DynamicLight(31000 + self:EntIndex())
    if light then
        light.pos = pos
        light.r = 255
        light.g = 174
        light.b = 46
        light.brightness = 2.8
        light.decay = 1000
        light.size = 190
        light.dietime = CurTime() + 0.08
    end
end
