AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:Initialize()
    -- Native stock dimensions: a low block, without model-scale collision drift.
    self:SetModel(self.PedestalModel)
    local mins,maxs=self:GetModelBounds()
    local deck=self:GetPos()
    self:SetPos(Vector(deck.x-(mins.x+maxs.x)*.5,deck.y-(mins.y+maxs.y)*.5,deck.z-mins.z))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(mins,maxs)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:SetMaterial("models/debug/debugwhite")
    self:SetColor(Color(255,222,104))
    self:DrawShadow(false)
end
