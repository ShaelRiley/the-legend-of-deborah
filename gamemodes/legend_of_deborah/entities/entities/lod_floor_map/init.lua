AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/clipboard.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(false)
end

function ENT:Think()
    local now=CurTime()
    if now<(self.NextPickupCheck or 0) then return end
    self.NextPickupCheck=now+0.08
    for _, ply in ipairs(player.GetAll()) do
        if LOD.MinimapServer:CollectFloorMap(ply,self) then return end
    end
    self:NextThink(now+0.08)
    return true
end
