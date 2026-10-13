include("shared.lua")
local MC=LOD.Config.Maze
local SEA,LAND=Color(60,132,222),Color(110,210,145)
local INK,WHITE,IRIS=Color(18,35,48),Color(252,247,224),Color(74,178,226)
local material=CreateMaterial("lod_floor_map_globe","UnlitGeneric",{
    ["$basetexture"]="color/white",["$vertexcolor"]="1",["$vertexalpha"]="1",["$ignorez"]="0"})
LOD.FloorMapVisual=LOD.FloorMapVisual or {}
local Visual=LOD.FloorMapVisual
if Visual.mesh then Visual.mesh:Destroy();Visual.mesh=nil end

-- One immutable toy globe mesh for every pickup; no per-frame vertex/RNG work.
local function globeMesh()
    if Visual.mesh then return Visual.mesh end
    local vertices={}
    local function point(ring,segment)
        local lat=-math.pi*.5+ring*math.pi/8
        local lon=segment*math.pi*2/16
        local normal=Vector(math.cos(lat)*math.cos(lon),math.cos(lat)*math.sin(lon),math.sin(lat))
        return {pos=normal*18,normal=normal,u=segment/16,v=ring/8}
    end
    local function tri(a,b,c,color)
        for _,v in ipairs({a,b,c}) do
            vertices[#vertices+1]={pos=v.pos,normal=v.normal,u=v.u,v=v.v,color=color}
        end
    end
    for ring=0,7 do for segment=0,15 do
        local lat=-math.pi*.5+(ring+.5)*math.pi/8
        local lon=(segment+.5)*math.pi*2/16
        local land=math.sin(lon*2+lat)+.7*math.cos(lon*3-lat*2)>.65 and math.abs(lat)<1.3
        local color=land and LAND or SEA
        local a,b,c,d=point(ring,segment),point(ring,segment+1),point(ring+1,segment+1),point(ring+1,segment)
        if ring>0 then tri(a,b,c,color) end
        if ring<7 then tri(a,c,d,color) end
    end end
    Visual.mesh=Mesh();Visual.mesh:BuildFromTriangles(vertices)
    return Visual.mesh
end

local function circle(radius,dx,dy)
    local out={}
    for i=0,19 do
        local a=i*math.pi*2/20
        out[#out+1]={x=(dx or 0)+math.cos(a)*radius,y=(dy or 0)+math.sin(a)*radius}
    end
    return out
end
local function almond(rx,ry)
    local out={}
    for i=0,31 do
        local a=i*math.pi*2/32
        out[#out+1]={x=math.cos(a)*rx,y=math.sin(a)*ry*(.65+.35*math.abs(math.sin(a)))}
    end
    return out
end
local eyeLayers={{almond(26,12),INK},{almond(24,10),WHITE},
    {circle(8),IRIS},{circle(4),INK},{circle(2,-2,-3),WHITE}}
local function facing(pos)
    -- Pitch and yaw both follow the viewer, also from above/below.
    local ang=(EyePos()-pos):Angle()
    ang:RotateAroundAxis(ang:Right(),90);ang:RotateAroundAxis(ang:Up(),-90)
    return ang
end

function ENT:Initialize()
    self:SetRenderBounds(Vector(-36,-36,-24),Vector(36,36,84))
end

function ENT:Draw()
    if not self.GetFloorIndex or self:GetPos():DistToSqr(EyePos())>(MC.CellSize*6)^2 then return end
    local reduced=LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced()
    local pos=self:GetPos()+Vector(0,0,reduced and 0 or math.sin(CurTime()*1.8+self:EntIndex())*3)
    self.LODGlobeTransform=self.LODGlobeTransform or Matrix()
    self.LODGlobeTransform:SetTranslation(pos)
    self.LODGlobeTransform:SetAngles(Angle(0,reduced and 0 or CurTime()*20%360,0))
    render.SetMaterial(material)
    cam.PushModelMatrix(self.LODGlobeTransform)
        globeMesh():Draw()
    cam.PopModelMatrix()
    local eye=pos+Vector(0,0,33)
    cam.Start3D2D(eye,facing(eye),1)
        draw.NoTexture()
        for _,layer in ipairs(eyeLayers) do
            surface.SetDrawColor(layer[2]);surface.DrawPoly(layer[1])
        end
    cam.End3D2D()
    if self:GetPos():DistToSqr(EyePos())>(MC.CellSize*2)^2 then return end
    local label=pos+Vector(0,0,60)
    cam.Start3D2D(label,facing(label),0.12)
        draw.RoundedBox(4,-145,-25,290,50,Color(16,18,20,230))
        draw.SimpleText("FLOOR "..(self:GetFloorIndex()+1).." MAP","DermaLarge",0,0,WHITE,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

hook.Add("ShutDown","LOD_FloorMapGlobeCleanup",function()
    if Visual.mesh then Visual.mesh:Destroy();Visual.mesh=nil end
end)
