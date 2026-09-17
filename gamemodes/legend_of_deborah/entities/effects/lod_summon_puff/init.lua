-- Bounded immediate geometry: no emitter, timer, attached particle or light.
local material = Material("particle/particle_smokegrenade")
function EFFECT:Init(data)
    self.Origin = data:GetOrigin()
    self:SetPos(self.Origin)
    self.Born = CurTime()
    self.Scale = math.Clamp(data:GetScale(), 0.5, 2)
    self:SetRenderBounds(Vector(-64,-64,-16), Vector(64,64,96))
end
function EFFECT:Think() return CurTime() - self.Born < 0.7 end
function EFFECT:Render()
    local age = math.Clamp((CurTime()-self.Born)/0.7,0,1)
    render.SetMaterial(material)
    for i=1,5 do
        local a=i*math.pi*2/5
        local p=self.Origin+Vector(math.cos(a)*age*22,math.sin(a)*age*22,age*28)
        local size=(12+age*26)*self.Scale
        render.DrawSprite(p,size,size,Color(180,205,220,110*(1-age)))
    end
end
