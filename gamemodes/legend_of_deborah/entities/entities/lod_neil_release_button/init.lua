AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
function ENT:Initialize()
    local offset=math.min(72,LOD.Config.Maze.CellSize*.2)
    local anchor=self:GetPos()+Vector(offset,offset,0)
    self:SetPickupPosition(anchor)
    local model="models/props_lab/generatorconsole.mdl"
    if not util.IsValidModel(model) then model="models/props_c17/consolebox01a.mdl" end
    local buttonModel="models/props_combine/combinebutton.mdl"
    if not util.IsValidModel(model) or not util.IsValidModel(buttonModel) then self:Remove();return end
    self:SetModel(model);self:SetAngles(Angle(0,0,0))
    local lo,hi=self:GetModelBounds()
    local floor=anchor.z-LOD.Config.Progression.KeycardHeight
    self:SetPos(Vector(anchor.x-(lo.x+hi.x)*.5,anchor.y-(lo.y+hi.y)*.5,floor-lo.z))
    local button=ents.Create("prop_dynamic")
    if not IsValid(button) then self:Remove();return end
    self:DeleteOnRemove(button)
    button:SetModel(buttonModel)
    local angles=Angle(45,0,0)
    local blo,bhi=button:GetModelBounds()
    local mins,maxs=LOD.ProgressionProps:RotatedBounds(blo,bhi,angles)
    -- The angled native button sits on the top control face. Seat from actual
    -- model bounds, not a guessed pivot, so both models stay physically legible.
    local mount=Vector((lo.x+hi.x)*.5-(mins.x+maxs.x)*.5,
        (lo.y+hi.y)*.5-(mins.y+maxs.y)*.5,hi.z+1-mins.z)
    button:SetPos(self:GetPos()+mount);button:SetAngles(angles)
    button:SetColor(Color(235,55,45));button:Spawn()
    if not IsValid(button) then self:Remove();return end
    button:Activate();button:SetParent(self)
    button:SetMoveType(MOVETYPE_NONE);button:SetSolid(SOLID_NONE)
    self.LODReleaseButtonProp=button
    self:SetNW2Entity("LOD_ReleaseButtonProp",button)
    -- One trace/use owner covers console and button. Native bounds supply a
    -- frozen interaction hull, including the button above the console. The
    -- weapon collision group leaves Hero passage/checkpoint centers clear.
    local hullLo=Vector(math.min(lo.x,mount.x+mins.x),math.min(lo.y,mount.y+mins.y),lo.z)
    local hullHi=Vector(math.max(hi.x,mount.x+maxs.x),math.max(hi.y,mount.y+maxs.y),mount.z+maxs.z)
    self:PhysicsInitBox(hullLo,hullHi)
    self:SetMoveType(MOVETYPE_NONE);self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    local physics=self:GetPhysicsObject()
    if not IsValid(physics) then self:Remove();return end
    physics:EnableMotion(false);self:SetUseType(SIMPLE_USE)
end
function ENT:Use(activator)
    if LOD.NeilBrute:Release(activator,self) then
        sound.Play("buttons/button3.wav",self:GetPos(),70,100,1)
    end
end
