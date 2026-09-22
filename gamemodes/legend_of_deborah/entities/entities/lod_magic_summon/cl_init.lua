include("shared.lua")
local glow=Material("sprites/light_glow02_add")
function ENT:Draw()
    local pos=self:GetPos()
    local previous=self.LODRollPosition
    self.LODRollPosition=Vector(pos.x,pos.y,pos.z)
    local mins,maxs=util.GetModelBounds(self:GetModel())
    local radius=math.max(8,math.max(maxs.x-mins.x,maxs.y-mins.y,maxs.z-mins.z)*.5)
    if previous then
        local delta=pos-previous
        local distance=delta:Length()
        if distance>.01 and distance<180 then
            self.LODRollAngle=((self.LODRollAngle or 0)+math.deg(distance/radius))%360
        end
    end
    local matrix=Matrix()
    matrix:Rotate(Angle(self.LODRollAngle or 0,0,0))
    matrix:SetTranslation(Vector(0,0,radius))
    self:EnableMatrix("RenderMultiply",matrix)
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
