AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')
function ENT:Initialize()
    self:SetModel('models/alyx.mdl')
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16,-16,0),Vector(16,16,74))
    self:SetUseType(SIMPLE_USE)
    self:SetMaterial('models/shiny')
    self:SetColor(Color(205,164,67))
    self:SetSequence(self:LookupSequence('idle') or 0)
end
function ENT:Use(ply)
    if LOD.CryptoDirector then LOD.CryptoDirector:OpenStatue(ply,self) end
end
