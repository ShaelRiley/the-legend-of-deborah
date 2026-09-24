-- Execute real fit renderer and mesh UV compiler; Source-only boundaries doubled.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
V.__unm=function(a) return a*-1 end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:DistToSqr(b) return (self-b):Dot(self-b) end
function V:Cross(b) return Vector(self.y*b.z-self.z*b.y,self.z*b.x-self.x*b.z,self.x*b.y-self.y*b.x) end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
color_white=Color(255,255,255);vector_origin=Vector();angle_zero={y=0}
function IsValid(v) return type(v)=='table' and v.valid~=false end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local hooks={};hook={Add=function(_,id,f) hooks[id]=f end,Remove=function(_,id) hooks[id]=nil end}
concommand={Add=noop};LOD={}
dofile(root..'sh_config.lua');dofile(root..'sh_rng.lua');dofile(root..'sh_crate_visuals.lua');dofile(root..'sh_crate_brand_metadata.lua')
local loads,creates=0,0
function Material(path)
 loads=loads+1
 return {IsError=function() return false end,GetTexture=function() return {IsError=function() return false end} end}
end
function CreateMaterial(name,shader,args)
 creates=creates+1;assert(args['$nocull']=='0' and args['$alphatest']=='1')
 return {SetTexture=noop,Recompute=noop,IsError=function() return false end}
end
render={SetMaterial=noop,SetColorModulation=noop,SetBlend=noop,DrawLine=noop}
MATERIAL_QUADS=7
local vertices,current,lastMesh,draws={},{}
function Mesh()
 return {Destroy=function(self) self.dead=true end,Draw=function(self) assert(not self.dead);draws=(draws or 0)+1 end}
end
mesh={Begin=function(a,b,c) vertices={};current={};lastMesh=type(a)=='table' and a or nil end,
 Position=function(p) current.pos=p end,Normal=function(n) current.normal=n end,
 TexCoord=function(_,u,v) current.u,current.v=u,v end,
 Color=function(r,g,b,a) current.color=Color(r,g,b,a) end,
 TangentS=noop,TangentT=noop,UserData=noop,
 AdvanceVertex=function() vertices[#vertices+1]=current;current={} end,
 End=function() if lastMesh then lastMesh.vertices=vertices end end}
LOD.WallVisualsClient={world={},models={},logical={},labelBuckets={},seed=1}
dofile(root..'cl_container_branding.lua')
assert(loads==0 and creates==0,'catalog eagerly materialized')
local Brand,C=LOD.CrateBranding,LOD.CrateVisuals
local mat=assert(Brand.MaterialFor(1));Brand.MaterialFor(1);assert(loads==1 and creates==1)
Brand.MaterialFor(256);assert(creates==1)
Brand.MaterialFor(1,'preview');assert(creates==2)
local model={pos=Vector(),yaw=0}
function model:GetPos() return self.pos end
function model:GetRenderBounds() return Vector(-64,-195,-64),Vector(64,195,64) end
function model:GetForward() return Vector(math.cos(self.yaw),math.sin(self.yaw),0) end
function model:GetRight() return Vector(math.sin(self.yaw),-math.cos(self.yaw),0) end
function model:GetUp() return Vector(0,0,1) end
function model:LocalToWorld(p) return self.pos+self:GetForward()*p.x-self:GetRight()*p.y+self:GetUp()*p.z end
local checks=0
for _,yaw in ipairs({0,90,180,270}) do
 model.yaw=math.rad(yaw);model.pos=Vector(112,328,450)
 for _,side in ipairs({-1,1}) do
  for id=1,256 do
   Brand.Draw(model,id,mat,model.pos+model:GetForward()*(side*500))
   assert(#vertices==4)
   local a,b,c=vertices[1],vertices[2],vertices[3]
   assert((b.pos-a.pos):Cross(c.pos-a.pos):Dot(a.normal)>0,'backface winding')
   for _,v in ipairs(vertices) do
    local p=v.pos-model.pos
    assert(math.abs(p:Dot(model:GetRight()))<=C.SafeWidth*.5+1e-8)
    assert(math.abs(p:Dot(model:GetForward())-side*(64+C.SurfaceOffset))<1e-8)
    assert(v.u>=0 and v.u<=1 and v.v>=0 and v.v<=1)
    assert(v.color.r==255 and v.color.g==255 and v.color.b==255 and v.color.a==255)
   end
   checks=checks+1
  end
 end
end
-- Hard draw cap in a deliberately excessive visible population; depth/sky skip.
local w=LOD.WallVisualsClient;w.labelBuckets[0]={['0:0']={}}
model.pos=Vector(-3840,-3840,64)
for i=1,1000 do
 w.world[i]={companyBranded=true,brandSurfaceEligible=true};w.models[i]=model
 w.labelBuckets[0]['0:0'][i]=i
end
function LocalPlayer() return {} end
function EyePos() return Vector(-3840,-3840,64) end
hooks.LOD_DrawContainerBranding();assert(Brand.lastDrawCount==64)
local before=vertices;hooks.LOD_DrawContainerBranding(true);assert(vertices==before)
-- Actual world-aligned UVs agree at every shared seam, including rotated slabs.
dofile(root..'cl_textured_box.lua')
local B=LOD.TexturedBox
local function worldUV(mins,maxs,pos,yaw)
 local obj=B:GetSlabMesh(mins,maxs,512,pos,{y=yaw});local out={}
 for _,v in ipairs(obj.vertices) do
  if v.normal.z>0 then
   local c,s=math.cos(math.rad(yaw)),math.sin(math.rad(yaw))
   local x,y=v.pos.x*c-v.pos.y*s+pos.x,v.pos.x*s+v.pos.y*c+pos.y
   local key=string.format('%.3f:%.3f',x,y)
   out[key]={u=v.u,v=v.v}
  end
 end
 return out
end
local a=worldUV(Vector(-128,-64,-16),Vector(128,64,16),Vector(140,233,0),0)
local b=worldUV(Vector(-64,-128,-16),Vector(64,128,16),Vector(140,233,0),90)
for key,uv in pairs(a) do
 local other=assert(b[key]);assert(math.abs(uv.u-other.u)<1e-9 and math.abs(uv.v-other.v)<1e-9)
end
local neighbor=worldUV(Vector(-128,-64,-16),Vector(128,64,16),Vector(396,233,0),0)
local seams=0
for key,uv in pairs(a) do if neighbor[key] then
 assert(math.abs(uv.u-neighbor[key].u)<1e-9 and math.abs(uv.v-neighbor[key].v)<1e-9);seams=seams+1
end end
assert(seams==2)
-- Grate is one cached opaque mesh, including bar/frame undersides.
function Matrix() return {Translate=noop,Rotate=noop} end
cam={PushModelMatrix=noop,PopModelMatrix=noop}
B:DrawGrate(Vector(),angle_zero,Vector(-192,64,-16),Vector(192,192,16))
local grate=lastMesh;local quads=#grate.vertices/4
assert(quads==192,'grate geometry budget changed')
local undersides=0
for _,v in ipairs(grate.vertices) do if v.normal.z<0 then undersides=undersides+1 end end
assert(undersides>0 and quads<200)
local cached=B:MeshCacheCount();B:DrawGrate(Vector(20,20,0),angle_zero,Vector(-192,64,-16),Vector(192,192,16))
assert(B:MeshCacheCount()==cached)
hooks.LOD_TexturedBoxMeshes();assert(grate.dead)
print('CRATE_RENDER_PASS: '..checks..' original composition/orientation checks; independent untinted artwork; two lazy shader slots; 64-draw ceiling for 1000 candidates; rotated/shared slab UV seams; '..quads..' cached opaque grate quads with underside and cleanup')
