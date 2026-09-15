include("shared.lua")
local glow=Material("sprites/light_glow02_add")
function ENT:Draw()
    self:DrawModel()
    local center=self:GetPos()+Vector(0,0,14)
    local color=self:GetColor()
    render.SetMaterial(glow)
    render.DrawSprite(center,26,26,Color(color.r,color.g,color.b,110))
    local cv=GetConVar("lod_reduced_effects")
    if cv and cv:GetBool() then return end
    for i=1,3 do
        local a=CurTime()*2+i*math.pi*2/3
        local q=center+Vector(math.cos(a)*19,math.sin(a)*19,math.sin(a*2)*9)
        render.DrawSprite(q,7,7,color)
    end
end
