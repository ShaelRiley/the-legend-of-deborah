include("shared.lua")
local MC=LOD.Config.Maze
local GOLD=Color(255,222,104)
function ENT:Initialize() LOD.ProgressionProps:RefreshBounds(self) end
hook.Add("NotifyShouldTransmit","LOD_JailKeyDisplayBounds",function(ent,transmitting)
    if transmitting and IsValid(ent) and ent:GetClass()=="lod_jail_key" then LOD.ProgressionProps:RefreshBounds(ent) end
end)
function ENT:Draw() LOD.ProgressionProps:Draw(self) end
function ENT:DrawTranslucent()
    local anchor=self:GetPickupPosition()
    if anchor:DistToSqr(EyePos())>(MC.CellSize*4)^2 then return end
    local temporary=self:GetKeySource()=="temporary_core"
    local pos=anchor+Vector(0,0,44)
    cam.Start3D2D(pos,LOD.ProgressionProps:LabelFacing(pos),.12)
        local width=temporary and 310 or 240
        draw.RoundedBox(4,-width*.5,-26,width,52,Color(16,18,20,232))
        draw.SimpleText(temporary and "CORE — JAIL KEY" or "JAIL KEY","DermaLarge",0,0,GOLD,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
