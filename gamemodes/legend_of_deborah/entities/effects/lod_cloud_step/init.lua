-- Short expanding cloud ring; no lights, timers, emitter or persistent owner.
local smoke = Material("particle/particle_smokegrenade")
function EFFECT:Init(data)
    self.Origin, self.Born = data:GetOrigin(), CurTime()
    self:SetPos(self.Origin)
    self:SetRenderBounds(Vector(-72,-72,-16), Vector(72,72,40))
end
function EFFECT:Think() return CurTime() - self.Born < .35 end
function EFFECT:Render()
    local age = math.Clamp((CurTime() - self.Born) / .35, 0, 1)
    render.SetMaterial(smoke)
    for i=1,8 do
        local angle = i * math.pi / 4
        local radius, size = 10 + age * 36, 14 + age * 12
        local pos = self.Origin + Vector(math.cos(angle)*radius, math.sin(angle)*radius, 6 + age*8)
        render.DrawSprite(pos, size, size, Color(235,242,255,180*(1-age)))
    end
end
