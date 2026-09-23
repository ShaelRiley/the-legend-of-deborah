ENT.Type='anim'
ENT.Base='base_anim'
ENT.PrintName='Dungeon Event'
ENT.Spawnable=false
function ENT:SetupDataTables()
    self:NetworkVar('String',0,'EventID')
end
