-- Shared cosmetic area grammar; geometry always comes from the existing effect.
LOD.MagicArea={}
local A=LOD.MagicArea
A.Material=CreateMaterial('LOD_MagicAreaBoundary','UnlitGeneric',{
    ['$basetexture']='color/white',['$vertexcolor']='1',['$vertexalpha']='1',
    ['$translucent']='1',['$ignorez']='0'
})
A.FlatMaterial=CreateMaterial('LOD_MagicAreaFlat','UnlitGeneric',{
    ['$basetexture']='color/white',['$vertexcolor']='1',['$vertexalpha']='1',
    ['$translucent']='1',['$ignorez']='0',['$nocull']='1'
})
A.Colors={raw=Color(210,235,255),earth=Color(194,156,88),fire=Color(255,105,45),
    dark=Color(125,72,170),ice=Color(125,220,255),light=Color(255,245,170),electric=Color(110,180,255)}
function A:Ink(color,fade)
    return Color(color.r,color.g,color.b,math.floor(255*fade)),
        Color(color.r,color.g,color.b,math.floor(102*fade))
end
local up,down=Vector(0,0,1),Vector(0,0,-1)
function A:Cell(center,size,color)
    render.SetMaterial(self.Material)
    render.DrawQuadEasy(center,EyePos().z<center.z and down or up,size,size,color,0)
end
function A:Sphere(center,radius,color,reduced)
    render.SetMaterial(self.Material)
    -- A single visible shell: inward when viewed from inside, no doubled opacity.
    local inward=EyePos():DistToSqr(center)<radius*radius
    render.DrawSphere(center,inward and -radius or radius,reduced and 16 or 32,reduced and 8 or 16,color)
end
local unit={}
for i=0,32 do local angle=i/32*math.pi*2;unit[i+1]={math.cos(angle),math.sin(angle)} end
function A:Disc(center,radius,right,vertical,color)
    -- A single two-sided plane, not two overlapping translucent surfaces.
    render.SetMaterial(self.FlatMaterial)
    local previous=center+right*radius
    for i=2,#unit do
        local point=center+right*(unit[i][1]*radius)+vertical*(unit[i][2]*radius)
        render.DrawQuad(center,previous,point,center,color)
        previous=point
    end
end
