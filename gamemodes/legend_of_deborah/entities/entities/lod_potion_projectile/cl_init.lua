include("shared.lua")
local cloudMaterial=Material("particle/particle_smokegrenade")
function ENT:Draw()
    local ends=self:GetNW2Float("LOD_CloudUntil",0)
    if ends<=0 then self:DrawModel(); return end
    if ends<=CurTime() then return end
    render.SetMaterial(cloudMaterial)
    local origin=self:GetPos()
    for i=1,8 do
        local angle=CurTime()*0.5+i*math.pi/4
        local pos=origin+Vector(math.cos(angle)*48,math.sin(angle)*48,12+math.sin(angle*2)*12)
        render.DrawSprite(pos,96,96,Color(115,155,55,45*math.min(1,ends-CurTime())))
    end
end
