AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local PC = LOD.Config.Progression
local PICKUP_PITCH = {96, 108, 120}

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(false)
    self.NextPickupCheck = 0
end

function ENT:Think()
    if CurTime() < (self.NextPickupCheck or 0) then return end
    self.NextPickupCheck = CurTime() + 0.08
    local radiusSqr = PC.KeycardTriggerRadius * PC.KeycardTriggerRadius

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and LOD.RunManager:IsActivePlayer(ply) and ply:GetPos():DistToSqr(self:GetPos()) <= radiusSqr then
            if LOD.ProgressionDirector:CollectCard(self:GetCardIndex(), ply) then
                -- Same recognizable pickup timbre, ascending pitch by progression
                -- color: Red < Blue < Yellow. The card is therefore legible by ear
                -- without inventing three unrelated interface sounds.
                self:EmitSound("items/itempickup.wav", 70, PICKUP_PITCH[self:GetCardIndex()] or 108, 0.9)
                self:Remove()
                return
            end
        end
    end

    self:NextThink(CurTime() + 0.08)
    return true
end
