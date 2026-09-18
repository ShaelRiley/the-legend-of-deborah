ENT.Type='anim'
ENT.Base='base_anim'
ENT.PrintName='Magic Wall'
ENT.Spawnable=false
function ENT:SetupDataTables()
    self:NetworkVar('Vector',0,'WallMins')
    self:NetworkVar('Vector',1,'WallMaxs')
    self:NetworkVar('Float',0,'ExpiresAt')
end
