include("shared.lua")
local MC=LOD.Config.Maze
local paper=Color(246,227,178)
local ink=Color(65,78,64)
local material=CreateMaterial("lod_floor_map_paper","UnlitGeneric",{
    ["$basetexture"]="color/white",["$vertexcolor"]="1",["$vertexalpha"]="1"})

function ENT:Draw()
    if not self.GetFloorIndex or self:GetPos():DistToSqr(EyePos())>(MC.CellSize*6)^2 then return end
    local reduced=LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced()
    local pos=self:GetPos()+Vector(0,0,reduced and 0 or math.sin(CurTime()*1.8+self:EntIndex())*3)
    local ang=Angle(0,reduced and 0 or CurTime()*20%360,0)
    render.SetMaterial(material)
    render.DrawBox(pos,ang,Vector(-22,-29,-1),Vector(22,29,1),paper)
    cam.Start3D2D(pos+Vector(0,0,1.2),ang,1)
        surface.SetDrawColor(ink)
        surface.DrawOutlinedRect(-18,-25,36,50,1)
        -- Printed labyrinth fragment, seen only on the actual world pickup.
        for i=-2,2 do
            surface.DrawLine(-13,i*7,11-(i%2)*8,i*7)
            surface.DrawLine(i*6,-19,i*6,14-(i%2)*7)
        end
        draw.SimpleText("F"..(self:GetFloorIndex()+1),"DermaDefaultBold",0,20,ink,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
    if LOD.AdventurePresentation then LOD.AdventurePresentation:Glint(pos,self:EntIndex(),paper) end
    if self:GetPos():DistToSqr(EyePos())>(MC.CellSize*2)^2 then return end
    cam.Start3D2D(self:GetPos()+Vector(0,0,38),Angle(0,EyeAngles().y-90,90),0.12)
        draw.RoundedBox(4,-145,-25,290,50,Color(16,18,20,230))
        draw.SimpleText("FLOOR "..(self:GetFloorIndex()+1).." MAP","DermaLarge",0,0,paper,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
