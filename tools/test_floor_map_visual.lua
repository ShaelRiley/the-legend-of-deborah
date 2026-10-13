-- Validate production globe geometry, culling, caching and viewer-facing eye.
-- Native GMod lighting/depth/appearance remain a separate observation.
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},V) end
function V.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function V.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:Cross(b) return Vector(self.y*b.z-self.z*b.y,self.z*b.x-self.x*b.z,self.x*b.y-self.y*b.x) end
function V:LengthSqr() return self:Dot(self) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
local A={};A.__index=A
function Angle(p,y,r)
 local cp,sp,cy,sy,cr,sr=math.cos(math.rad(p)),math.sin(math.rad(p)),math.cos(math.rad(y)),math.sin(math.rad(y)),math.cos(math.rad(r)),math.sin(math.rad(r))
 return setmetatable({p=p,y=y,r=r,f=Vector(cp*cy,cp*sy,-sp),
  right=Vector(-sr*sp*cy+cr*sy,-sr*sp*sy-cr*cy,-sr*cp),
  up=Vector(cr*sp*cy+sr*sy,cr*sp*sy-sr*cy,cr*cp)},A)
end
function V:Angle() return Angle(math.deg(math.atan(-self.z,math.sqrt(self.x^2+self.y^2))),math.deg(math.atan(self.y,self.x)),0) end
function A:Right() return self.right end
function A:Up() return self.up end
function A:RotateAroundAxis(axis,degrees)
 local co,si=math.cos(math.rad(degrees)),math.sin(math.rad(degrees))
 local function rotate(v) return v*co+axis:Cross(v)*si+axis*(axis:Dot(v)*(1-co)) end
 self.f,self.right,self.up=rotate(self.f),rotate(self.right),rotate(self.up)
end
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
local now,eye,reduced=10,Vector(100,0,45),false
CurTime=function() return now end;EyePos=function() return eye end
include=noop;TEXT_ALIGN_CENTER=1
LOD={Config={Maze={CellSize=384}},AdventurePresentation={Reduced=function() return reduced end}}
local material,meshes,matrices,transforms,planes,polys,texts={}, {},0,{}, {}, {}, {}
CreateMaterial=function(_,shader,params) assert(shader=='UnlitGeneric' and params['$ignorez']=='0');return material end
Mesh=function()
 local m={draws=0};meshes[#meshes+1]=m
 function m:BuildFromTriangles(v) assert(not self.vertices);self.vertices=v end
 function m:Draw() assert(not self.destroyed);self.draws=self.draws+1 end
 function m:Destroy() self.destroyed=true end
 return m
end
Matrix=function()
 matrices=matrices+1;return {SetTranslation=function(self,v) self.pos=v end,SetAngles=function(self,v) self.angles=v end}
end
render={SetMaterial=function(m) assert(m==material) end}
cam={PushModelMatrix=function(m) transforms[#transforms+1]=m end,PopModelMatrix=noop,
 Start3D2D=function(pos,ang,scale) planes[#planes+1]={pos=pos,ang=ang,scale=scale} end,End3D2D=noop}
surface={SetDrawColor=noop,DrawPoly=function(p) polys[#polys+1]=p end}
draw={NoTexture=noop,RoundedBox=noop,SimpleText=function(t) texts[#texts+1]=t end}
local hooks={};hook={Add=function(_,id,fn) hooks[id]=fn end}
ENT={}
local path='gamemodes/legend_of_deborah/entities/entities/lod_floor_map/cl_init.lua'
dofile(path)
local function pickup(index)
 local e=setmetatable({pos=Vector(0,0,0),index=index}, {__index=ENT})
 function e:GetPos() return self.pos end
 function e:EntIndex() return self.index end
 function e:GetFloorIndex() return 2 end
 function e:SetRenderBounds(lo,hi) self.lo,self.hi=lo,hi end
 e:Initialize();return e
end
local a,b=pickup(1),pickup(2)
a:Draw();assert(#meshes==1 and #planes==2 and #polys==5 and texts[1]=='FLOOR 3 MAP')
local m=meshes[1];assert(#m.vertices==224*3,'globe triangle budget changed')
local edges,colors={},{}
local function key(v) return string.format('%.5f,%.5f,%.5f',math.abs(v.x)<.00001 and 0 or v.x,math.abs(v.y)<.00001 and 0 or v.y,math.abs(v.z)<.00001 and 0 or v.z) end
for i=1,#m.vertices,3 do
 local v1,v2,v3=m.vertices[i],m.vertices[i+1],m.vertices[i+2]
 assert((v2.pos-v1.pos):Cross(v3.pos-v1.pos):Dot(v1.pos+v2.pos+v3.pos)>0,'inward/degenerate globe face')
 for _,v in ipairs({v1,v2,v3}) do
  assert(math.abs(v.pos:LengthSqr()-18^2)<.00001 and math.abs(v.normal:LengthSqr()-1)<.00001)
  colors[v.color.g]=true
 end
 for _,pair in ipairs({{v1,v2},{v2,v3},{v3,v1}}) do
  local x,y=key(pair[1].pos),key(pair[2].pos);local k=x<y and x..'|'..y or y..'|'..x
  edges[k]=(edges[k] or 0)+1
 end
end
for _,count in pairs(edges) do assert(count==2,'open globe seam') end
assert(colors[132] and colors[210],'globe needs seas and land')
local cachedPoly=polys[1]
for _,height in ipairs({-100,33,150}) do for yaw=0,315,45 do
 eye=Vector(math.cos(math.rad(yaw))*100,math.sin(math.rad(yaw))*100,height)
 planes={};polys={};a:Draw()
 local p=planes[1];local delta=eye-p.pos;local dir=delta*(1/math.sqrt(delta:LengthSqr()))
 -- Source's 3D2D Y flip makes the front normal Forward cross Right.
 assert(p.ang.f:Cross(p.ang:Right()):Dot(dir)>.99999,'eye became edge-on/back-facing')
 assert(polys[1]==cachedPoly,'eye polygon rebuilt each frame')
 for _,plane in ipairs(planes) do
  local radius=plane.scale==1 and math.sqrt(26^2+12^2) or math.sqrt(145^2+25^2)*.12
  for _,axis in ipairs({'x','y','z'}) do
   assert(plane.pos[axis]-radius>=a.lo[axis] and plane.pos[axis]+radius<=a.hi[axis],'billboard escapes culling bounds')
  end
 end
end end
b:Draw();assert(#meshes==1 and matrices==2,'globe mesh/matrix not reused')
reduced=true;a:Draw();local t=a.LODGlobeTransform;local pos,angle=t.pos,t.angles
now=23;a:Draw();assert(t.pos.z==pos.z and t.angles.y==angle.y and angle.y==0,'reduced globe still bobs/spins')
eye=Vector(384*3,0,0);planes={};a:Draw();assert(#planes==1,'far label not culled')
eye=Vector(384*6+1,0,0);planes={};local draws=m.draws;a:Draw();assert(m.draws==draws and #planes==0,'distant pickup not culled')
-- Finder uses registered pickups (no recurring scan), including distant floors,
-- and always restores native depth after an entity drawing failure.
local depth=false;cam.IgnoreZ=function(v) depth=v end
local owner={alive=true,finder=false,nw={}}
function owner:Alive() return self.alive end
function owner:GetNW2Bool(key) return key=='LOD_RPGMapFinder' and self.finder or self.nw[key] or false end
LocalPlayer=function() return owner end
IsValid=function(e) return e==owner or (e==a or e==b) and not e.removed end
ErrorNoHalt=function() end
local finder=hooks.LOD_MapFinderPickups
local before=m.draws;finder(false,false);assert(m.draws==before and not depth)
owner.finder=true;finder(true,false);assert(m.draws==before,'depth pass drew Finder')
finder(false,false);assert(m.draws==before+2 and not depth,'Finder lost distant pickup or depth cleanup')
for _,key in ipairs({'LOD_IsSoldier','LOD_Eliminated'}) do
 owner.nw[key]=true;before=m.draws;finder(false,false);assert(m.draws==before);owner.nw[key]=nil
end
owner.alive=false;before=m.draws;finder(false,false);assert(m.draws==before);owner.alive=true
b.removed=true;finder(false,false);assert(not LOD.FloorMapVisual.pickups[b])
local renderOld=render.SetMaterial;render.SetMaterial=function() error('draw failure') end
finder(false,false);assert(not depth,'Finder left the rest of the world visible through walls');render.SetMaterial=renderOld
dofile(path);assert(m.destroyed and not LOD.FloorMapVisual.mesh,'Lua refresh retained old GPU mesh')
eye=Vector(100,0,0);a:Draw();assert(#meshes==2)
hooks.LOD_FloorMapGlobeCleanup();assert(meshes[2].destroyed and not LOD.FloorMapVisual.mesh)
print('FLOOR_MAP_VISUAL_PASS: closed outward 224-triangle colored globe; 24 eye viewpoints; complete render bounds; shared cached mesh/polygons; Reduced Effects; distance culls; refresh/shutdown cleanup')
