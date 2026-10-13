AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local PC = LOD.Config.Progression
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:Initialize()
    local anchor=self:GetPos()
    self:SetPickupPosition(anchor)
    if not LOD.ProgressionProps:Place(self,anchor,"models/props_c17/TrapPropeller_Lever.mdl",
        "models/props_c17/BriefCase001a.mdl",Color(255,222,104)) then return end
    if self:GetKeySource() == "" then self:SetKeySource("production") end
    self.NextPickupCheck = 0
end

function ENT:Think()
    if CurTime() < (self.NextPickupCheck or 0) then return end
    self.NextPickupCheck = CurTime() + 0.08
    local radiusSqr = PC.KeycardTriggerRadius * PC.KeycardTriggerRadius

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and LOD.RunManager:IsActivePlayer(ply) then
            -- Match colored-keycard semantics: touching the objective with any
            -- part of the player hull is enough. Player-origin distance made
            -- floating objective pickups unnecessarily finicky.
            local pickupPos=self:GetPickupPosition()
            local nearest = ply:NearestPoint(pickupPos)
            if nearest:DistToSqr(pickupPos) <= radiusSqr then
                if LOD.ProgressionDirector:CollectJailKey(ply, self) then
                    sound.Play("items/itempickup.wav", pickupPos, 75, 82, 1)
                    return
                end
            end
        end
    end

    self:NextThink(CurTime() + 0.08)
    return true
end

