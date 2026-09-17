include("shared.lua")
local glowMaterial=Material('sprites/light_glow02_add')
local cloudMaterial=Material("particle/particle_smokegrenade")
function ENT:Initialize()
    self:SetRenderBounds(Vector(-100,-100,-40),Vector(100,100,80))
end
function ENT:Draw()
    local ends=self:GetNW2Float("LOD_CloudUntil",0)
    if ends<=0 then
        self:DrawModel()
        local def=LOD.Equipment.Definitions[self:GetNW2String("LOD_BombType","")]
        if def then
            local spec=def.status and LOD.Equipment.StatusPresentation[def.status]
            local c=spec and Color(spec.color[1],spec.color[2],spec.color[3]) or LOD.MagicArea.Colors[def.element or 'raw']
            render.SetMaterial(glowMaterial)
            render.DrawSprite(self:GetPos(),22,22,c)
        end
        return
    end
    if ends<=CurTime() then return end
    render.SetMaterial(cloudMaterial)
    local origin=self:GetPos()
    for i=1,8 do
        local angle=CurTime()*0.5+i*math.pi/4
        local pos=origin+Vector(math.cos(angle)*48,math.sin(angle)*48,12+math.sin(angle*2)*12)
        render.DrawSprite(pos,96,96,Color(115,155,55,45*math.min(1,ends-CurTime())))
    end
end
function ENT:DrawTranslucent() self:Draw() end
