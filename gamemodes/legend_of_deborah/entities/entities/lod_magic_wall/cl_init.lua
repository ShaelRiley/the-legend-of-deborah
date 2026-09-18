include('shared.lua')
ENT.RenderGroup=RENDERGROUP_TRANSLUCENT
local material=Material('models/debug/debugwhite')
local angle=Angle(0,0,0)
function ENT:Initialize()
    self:SetCustomCollisionCheck(true)
end
function ENT:Think()
    if self.GetWallMins and self.GetWallMaxs then self:SetRenderBounds(self:GetWallMins(),self:GetWallMaxs()) end
end
function ENT:DrawTranslucent()
    if not self.GetWallMins or not self.GetWallMaxs or not self.GetExpiresAt then return end
    local lo,hi=self:GetWallMins(),self:GetWallMaxs()
    if hi.z<=lo.z then return end
    self:SetRenderBounds(lo,hi)
    local color=self:GetColor()
    local fade=math.Clamp((self:GetExpiresAt()-CurTime())/.8,0,1)
    render.SetMaterial(material)
    render.DrawBox(self:GetPos(),angle,lo,hi,Color(color.r,color.g,color.b,70*fade),true)
    render.DrawWireframeBox(self:GetPos(),angle,lo,hi,Color(color.r,color.g,color.b,230*fade),false)
    -- Bounded solid bands communicate the collision plane without hiding aiming.
    for i=1,7 do
        local z=lo.z+(hi.z-lo.z)*i/8
        render.DrawBox(self:GetPos(),angle,Vector(lo.x,lo.y,z),Vector(hi.x,hi.y,z+2),Color(color.r,color.g,color.b,150*fade),true)
    end
end
