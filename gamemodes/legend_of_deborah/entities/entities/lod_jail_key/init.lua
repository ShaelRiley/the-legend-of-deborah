AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local PC = LOD.Config.Progression

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(false)
    if self:GetKeySource() == "" then self:SetKeySource("production") end
    self.NextPickupCheck = 0
end

function ENT:Think()
    if CurTime() < (self.NextPickupCheck or 0) then return end
    self.NextPickupCheck = CurTime() + 0.08
    local radiusSqr = PC.KeycardTriggerRadius * PC.KeycardTriggerRadius

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and LOD.RunManager:IsActivePlayer(ply) and
            ply:GetPos():DistToSqr(self:GetPos()) <= radiusSqr then
            local pickupPos = self:GetPos()
            if LOD.ProgressionDirector:CollectJailKey(ply, self) then
                sound.Play("items/itempickup.wav", pickupPos, 75, 82, 1)
                return
            end
        end
    end

    self:NextThink(CurTime() + 0.08)
    return true
end
