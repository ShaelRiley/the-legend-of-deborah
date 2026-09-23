-- Original short inward stone facets; no emitter, light, timer or retained actor.
local facet=Material("effects/splashwake1")
function EFFECT:Init(data)
    self.Origin,self.Born=data:GetOrigin(),CurTime()
    self:SetPos(self.Origin)
    self:SetRenderBounds(Vector(-48,-48,0),Vector(48,48,80))
end
function EFFECT:Think() return CurTime()-self.Born<.3 end
function EFFECT:Render()
    local age=math.Clamp((CurTime()-self.Born)/.3,0,1)
    render.SetMaterial(facet)
    for i=1,6 do
        local angle=i*math.pi/3+age*.8
        local radius=38*(1-age)
        local pos=self.Origin+Vector(math.cos(angle)*radius,math.sin(angle)*radius,12+i*9)
        render.DrawSprite(pos,12*(1-age),18*(1-age),Color(190,182,154,200*(1-age)))
    end
end
