include('shared.lua')
function ENT:Draw()
    self:DrawModel()
    if LOD.BossPresentation then LOD.BossPresentation:DrawObject(self) end
    local label=self:GetNW2String('LOD_BossObjectLabel','')
    local p=LocalPlayer();if label=='' or not IsValid(p) or p:GetPos():DistToSqr(self:GetPos())>500^2 then return end
    local pos=self:GetPos()+Vector(0,0,45);local ang=EyeAngles();ang:RotateAroundAxis(ang:Forward(),90);ang:RotateAroundAxis(ang:Right(),90)
    cam.Start3D2D(pos,ang,.16);draw.SimpleText(label,'DermaDefaultBold',0,0,Color(255,235,180),TEXT_ALIGN_CENTER);local phase=self:GetNW2String('LOD_BossObjectState','');if phase~='' and phase~='stable' then draw.SimpleText(string.upper(phase),'DermaDefaultBold',0,16,Color(255,160,100),TEXT_ALIGN_CENTER) end;cam.End3D2D()
end
