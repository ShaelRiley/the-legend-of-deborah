AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')
function ENT:Initialize()
    self:SetModel('models/hunter/blocks/cube025x025x025.mdl')
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetSolidFlags(0)
    self:SetCustomCollisionCheck(true)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:SetCollisionBounds(self:GetWallMins(),self:GetWallMaxs())
    self:DrawShadow(false)
    self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
end
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
function ENT:Think() return LOD.MagicForms:StepWall(self) end
function ENT:OnRemove() LOD.MagicForms:RetireWall(self) end
