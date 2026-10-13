AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Both stock props remain available to Map Finder outside the normal PVS.
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

local function rotatedBounds(lo,hi,angles)
    local mins,maxs=Vector(math.huge,math.huge,math.huge),Vector(-math.huge,-math.huge,-math.huge)
    for _,x in ipairs({lo.x,hi.x}) do for _,y in ipairs({lo.y,hi.y}) do for _,z in ipairs({lo.z,hi.z}) do
        local p=Vector(x,y,z);p:Rotate(angles)
        mins.x=math.min(mins.x,p.x);mins.y=math.min(mins.y,p.y);mins.z=math.min(mins.z,p.z)
        maxs.x=math.max(maxs.x,p.x);maxs.y=math.max(maxs.y,p.y);maxs.z=math.max(maxs.z,p.z)
    end end end
    return mins,maxs
end

function ENT:Initialize()
    -- Keep the existing touch target even though stock models have different pivots.
    local offset=math.min(72,LOD.Config.Maze.CellSize*.2)
    local anchor=self:GetPos()+Vector(offset,offset,0)
    self:SetPickupPosition(anchor)
    self:SetModel(util.IsValidModel(self.BookModel) and self.BookModel or self.BookFallbackModel)
    local lo,hi=self:GetModelBounds()
    local size=hi-lo
    local angles=Angle(0,0,0)
    if size.x>=size.y and size.x>=size.z then angles=Angle(-90,0,0)
    elseif size.y>=size.z then angles=Angle(0,0,90) end
    local mins,maxs=rotatedBounds(lo,hi,angles)

    local pedestal=ents.Create("lod_floor_map_pedestal")
    if not IsValid(pedestal) then self:Remove();return end
    self:DeleteOnRemove(pedestal)
    pedestal:SetPos(anchor-Vector(0,0,LOD.Config.Progression.KeycardHeight))
    pedestal:Spawn();pedestal:Activate()
    self.LODFloorMapPedestal=pedestal
    self:SetNW2Entity("LOD_MapPedestal",pedestal)

    local top=pedestal:GetPos().z+pedestal:OBBMaxs().z
    self:SetPos(Vector(anchor.x-(mins.x+maxs.x)*.5,anchor.y-(mins.y+maxs.y)*.5,top+2-mins.z))
    self:SetAngles(angles)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(mins,maxs)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
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
