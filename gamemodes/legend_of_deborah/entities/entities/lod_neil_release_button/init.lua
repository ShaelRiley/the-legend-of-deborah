AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
function ENT:Initialize()
    -- Use the existing map-prop inset so checkpoints and hunt spawn centers
    -- stay clear even when this control shares their graph cell.
    local offset=math.min(72,LOD.Config.Maze.CellSize*.2)
    local anchor=self:GetPos()+Vector(offset,offset,0)
    self:SetPickupPosition(anchor)
    if not LOD.ProgressionProps:Place(self,anchor,"models/props_lab/reciever01b.mdl",
        "models/props_lab/reciever01a.mdl",Color(255,222,104)) then return end
    -- E needs a native traceable body. Freeze the stock model on its owned
    -- low plinth; a sprite/custom silhouette never owns this interaction.
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    local physics=self:GetPhysicsObject()
    if not IsValid(physics) then self:Remove();return end
    physics:EnableMotion(false)
    self:SetUseType(SIMPLE_USE)
end
function ENT:Use(activator)
    if LOD.NeilBrute:Release(activator,self) then
        sound.Play("buttons/button3.wav",self:GetPos(),70,100,1)
    end
end
