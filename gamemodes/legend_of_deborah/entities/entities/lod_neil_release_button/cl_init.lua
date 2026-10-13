include("shared.lua")
function ENT:Initialize() LOD.ProgressionProps:RefreshBounds(self) end
function ENT:Draw() LOD.ProgressionProps:Draw(self) end
function ENT:DrawTranslucent()
    local pos=self:GetPos()+Vector(0,0,48)
    if EyePos():DistToSqr(pos)>(LOD.Config.Maze.CellSize*4)^2 then return end
    cam.Start3D2D(pos,LOD.ProgressionProps:LabelFacing(pos),.12)
        draw.RoundedBox(4,-220,-26,440,52,Color(16,18,20,232))
        draw.SimpleText(self:GetReleased() and "NEIL RELEASED" or "E: RELEASE NEIL",
            "DermaLarge",0,0,Color(255,222,104),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
