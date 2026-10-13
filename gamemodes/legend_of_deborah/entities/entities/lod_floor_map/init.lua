AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
function ENT:Initialize()
    local offset=math.min(72,LOD.Config.Maze.CellSize*.2)
    local anchor=self:GetPos()+Vector(offset,offset,0)
    self:SetPickupPosition(anchor)
    if not LOD.ProgressionProps:Place(self,anchor,self.BookModel,self.BookFallbackModel) then return end
    self.LODFloorMapPedestal=self.LODProgressionPedestal
end
function ENT:Think()
    local now=CurTime()
    if now<(self.NextPickupCheck or 0) then return end
    self.NextPickupCheck=now+0.08
    for _,ply in ipairs(player.GetAll()) do
        if LOD.MinimapServer:CollectFloorMap(ply,self) then return end
    end
    self:NextThink(now+0.08)
    return true
end
