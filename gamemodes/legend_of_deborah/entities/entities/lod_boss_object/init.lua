AddCSLuaFile('shared.lua');AddCSLuaFile('cl_init.lua');include('shared.lua')
function ENT:Initialize()
    self:SetMoveType(MOVETYPE_NONE);self:SetSolid(SOLID_NONE);self:SetUseType(CONTINUOUS_USE)
end
function ENT:Use(p) local o=self.LODBossObject;if o and LOD.BossEncounter then LOD.BossEncounter:ObjectUse(o.owner,o,p) end end
function ENT:OnTakeDamage(info) local o=self.LODBossObject;if o and LOD.BossEncounter then LOD.BossEncounter:ObjectDamage(o.owner,o,info) end end
