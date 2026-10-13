AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local PC = LOD.Config.Progression
local PICKUP_PITCH = {96, 108, 120}
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:Initialize()
    local anchor=self:GetPos()
    self:SetPickupPosition(anchor)
    local card=PC.Cards[math.Clamp(self:GetCardIndex(),1,4)]
    if not LOD.ProgressionProps:Place(self,anchor,"models/props_c17/BriefCase001a.mdl",
        "models/props_lab/binderblue.mdl",card.color) then return end
    self.NextPickupCheck = 0
end

function ENT:Think()
    if CurTime() < (self.NextPickupCheck or 0) then return end
    self.NextPickupCheck = CurTime() + 0.08
    local radiusSqr = PC.KeycardTriggerRadius * PC.KeycardTriggerRadius

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and LOD.RunManager:IsActivePlayer(ply) then
            -- Pickup should read as touching the keycard with any part of the
            -- player hull. Using GetPos() measured from the player's feet while
            -- the card floats above the deck, consuming most of the nominal
            -- trigger radius vertically and making obvious body contact fail.
            local anchor=self:GetPickupPosition()
            local nearest = ply:NearestPoint(anchor)
            if nearest:DistToSqr(anchor) <= radiusSqr then
                if LOD.ProgressionDirector:CollectCard(self:GetCardIndex(), ply, self) then
                    -- Same recognizable pickup timbre, ascending pitch by progression
                    -- color: Red < Blue < Yellow. The card is therefore legible by ear
                    -- without inventing three unrelated interface sounds.
                    self:EmitSound("items/itempickup.wav", 70, PICKUP_PITCH[self:GetCardIndex()] or 108, 0.9)
                    self:Remove()
                    return
                end
            end
        end
    end

    self:NextThink(CurTime() + 0.08)
    return true
end


