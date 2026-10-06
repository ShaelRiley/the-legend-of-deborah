-- Production static renderer + mesh cache. Native boundaries are doubled;
-- counts below are Lua/native-call work, not GPU timings or Steam Deck FPS.
-- Optional arguments supply baseline mesh/entity source paths for paired probes.
local baseline = arg and arg[1] == '--baseline'
local override = baseline or arg and arg[1] == '--source'
local meshPath = override and assert(arg[2]) or 'gamemodes/legend_of_deborah/gamemode/lod/cl_textured_box.lua'
local entityPath = override and assert(arg[3]) or 'gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua'
local noop = function() end
local hooks = {}
hook = {Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end}
local function fire(event,...) for _,fn in pairs(hooks[event] or {}) do fn(...) end end
local now=100
include=noop;CurTime=function() return now end
function IsValid(e) return type(e)=='table' and e.valid~=false end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
color_white=Color(255,255,255)
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
-- Angle axes cross a native vector boundary in GMod. Count their component
-- reads without assigning a hardware cost to the doubled accessors.
local axisReads=0
local AX={__index=function(v,k)
 if k=='x' or k=='y' or k=='z' then axisReads=axisReads+1;return v.values[k] end
 return V[k]
end,__add=V.__add,__sub=V.__sub}
local function axis(x,y,z) return setmetatable({values={x=x,y=y,z=z}},AX) end
local A={};A.__index=A
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},A) end
function A:Forward()
 local p,y=math.rad(self.p),math.rad(self.y)
 return axis(math.cos(p)*math.cos(y),math.cos(p)*math.sin(y),-math.sin(p))
end
function A:Right()
 local p,y,r=math.rad(self.p),math.rad(self.y),math.rad(self.r)
 return axis(-math.sin(r)*math.sin(p)*math.cos(y)+math.cos(r)*math.sin(y),
  -math.sin(r)*math.sin(p)*math.sin(y)-math.cos(r)*math.cos(y),-math.sin(r)*math.cos(p))
end
function A:Up()
 local p,y,r=math.rad(self.p),math.rad(self.y),math.rad(self.r)
 return axis(math.cos(r)*math.sin(p)*math.cos(y)+math.sin(r)*math.sin(y),
  math.cos(r)*math.sin(p)*math.sin(y)-math.sin(r)*math.cos(y),math.cos(r)*math.cos(p))
end
angle_zero=Angle();vector_origin=Vector()
local view={origin=Vector(),angles=Angle(),fov=90,aspect=1.6,znear=1}
EyePos=function() return view.origin end;EyeVector=function() return view.angles:Forward() end
local formats,matrices,allocations,live,peak,draws,geometryReads=0,0,0,0,0,0,0
local absoluteValues=0
local absolute=math.abs
math.abs=function(n) absoluteValues=absoluteValues+1;return absolute(n) end
local format=string.format
string.format=function(...) formats=formats+1;return format(...) end
local currentMatrix,lastDraw,seen=nil,nil,{}
function Matrix()
 matrices=matrices+1
 return {Translate=function(self,p) self.pos=Vector(p.x,p.y,p.z) end,
  Rotate=function(self,a) self.ang=Angle(a.p,a.y,a.r) end}
end
cam={PushModelMatrix=function(m) assert(not currentMatrix);currentMatrix=m end,
 PopModelMatrix=function() assert(currentMatrix);currentMatrix=nil end}
local vertices,current,building
function Mesh()
 allocations=allocations+1;live=live+1;peak=math.max(peak,live)
 return {Destroy=function(self) assert(not self.dead,'double destruction');self.dead=true;live=live-1 end,
  Draw=function(self)
   assert(not self.dead,'evicted mesh drawn');assert(currentMatrix)
   draws=draws+1;lastDraw={mesh=self,matrix=currentMatrix}
   seen[format('%g,%g,%g',currentMatrix.pos.x,currentMatrix.pos.y,currentMatrix.pos.z)]=true
  end}
end
mesh={Begin=function(obj) building=obj;vertices={};current={} end,
 Position=function(p) current.pos=p end,Normal=function(n) current.normal=n end,
 TexCoord=function(_,u,v) current.u,current.v=u,v end,Color=noop,TangentS=noop,TangentT=noop,UserData=noop,
 AdvanceVertex=function() vertices[#vertices+1]=current;current={} end,
 End=function() building.vertices=vertices end}
local material={IsError=function() return false end,GetTexture=function() return {IsError=function() return false end} end}
Material=function() return material end
local lastMaterial,blend,tint
render={GetViewSetup=function(current) assert(current);return view end,
 SetMaterial=function(m) lastMaterial=m end,SetBlend=function(b) blend=b end,
 SetColorModulation=function(r,g,b) tint={r,g,b} end,DrawWireframeBox=noop}
LOD={Config={Geometry={FloorTextureTile=512}},CrateVisuals={GrateInset=8,GratePitch=24,GrateBarWidth=3}}
MATERIAL_QUADS=7
dofile(meshPath);ENT={};dofile(entityPath)
local B=LOD.TexturedBox
local entities={}
local function box(pos,kind)
 local e=setmetatable({pos=pos,ang=Angle(),mins=Vector(-8,-8,-4),maxs=Vector(8,8,4),kind=kind or 1,nw={}},{__index=ENT})
 function e:GetPos() geometryReads=geometryReads+1;return self.pos end
 function e:GetAngles() geometryReads=geometryReads+1;return self.ang end
 function e:GetBoxMins() geometryReads=geometryReads+1;return self.mins end
 function e:GetBoxMaxs() geometryReads=geometryReads+1;return self.maxs end
 function e:GetBoxKind() return self.kind end;function e:SetRenderBounds() end
 function e:SetNextClientThink(t) self.thinkAt=t end
 function e:GetNW2Bool(k,d) if self.nw[k]==nil then return d end;return self.nw[k] end
 e.GetNW2String=e.GetNW2Bool
 function e:GetClass() return 'lod_static_box' end
 e:Initialize();entities[#entities+1]=e;return e
end
local function resetScene()
 for _,e in ipairs(entities) do e:OnRemove(false) end
 entities={};B:ClearMeshCache();assert(live==0)
end
local function frame()
 seen={};draws=0;fire('PostDrawOpaqueRenderables',false,false,false);return draws
end
-- Same 120 visible static entities; alternating floors/stairs share few meshes.
for i=1,120 do box(Vector(1000+i*2,(i%5)*16,(i%3)*16),i%2+1) end
assert(frame()==120)
formats,matrices,geometryReads,absoluteValues,axisReads=0,0,0,0,0
for _=1,120 do assert(frame()==120) end
print(format('LOW_END_STATIC_WORK entities=120 frames=120 cache_key_formats=%d matrix_allocations=%d native_peak_meshes=%d',formats,matrices,peak))
if not baseline then assert(formats==0 and matrices==0,'static drawing repeats compilation/transform allocation') end
print(format('LOW_END_NATIVE_GETTERS entities=120 frames=120 reads=%d native_fps_measured=false',geometryReads))
if not baseline then assert(geometryReads==4*120*120,'drawable boxes repeat native geometry reads within a pass') end
print(format('LOW_END_PLANE_WORK entities=120 passes=120 absolute_values=%d basis_component_reads=%d native_fps_measured=false',absoluteValues,axisReads))
if not baseline then
 assert(absoluteValues<=20*120,'identity-axis support repeats plane arithmetic per box')
 assert(axisReads<=9*120,'unchanged box support repeats native basis component reads')
end
-- Simulate Source honoring SetNextClientThink/true, including the existing
-- one-second deadline. The parent invokes each callback every rendered frame.
local callbacks=0
for i=1,600 do
 now=100+(i-1)/60
 for _,e in ipairs(entities) do
  if now>=(e.thinkAt or 0) then
   callbacks=callbacks+1
   if e:Think()~=true then e.thinkAt=now end
  end
 end
end
print(format('LOW_END_STATIC_THINK entities=120 frames=600 callbacks=%d native_fps_measured=false',callbacks))
if not baseline then
 assert(callbacks<=120*11,'native idle Think was not scheduled at the existing refresh deadline')
 local e=entities[1];local getter=e.GetBoxMins;e.GetBoxMins=nil
 fire('NotifyShouldTransmit',e,true);assert(e.thinkAt==now,'transmission did not wake deferred bounds')
 assert(e:Think()~=true,'incomplete datatables were put to sleep')
 e.GetBoxMins=getter;assert(e:Think()==true and e.thinkAt>now,'ready datatables did not reschedule')
end
resetScene()
-- Fixed camera distribution: 100 visible, 200 outside side/top/bottom, 300 rear.
for i=1,600 do
 local pos
 if i<=100 then pos=Vector(1000+i,0,0)
 elseif i<=200 then pos=Vector(1000,3000+i,0)
 elseif i<=300 then pos=Vector(1000,0,(i%2==0 and 1 or -1)*(3000+i))
 else pos=Vector(-1000-i,0,0) end
 box(pos)
end
local submitted=frame()
print(format('LOW_END_VIEW_WORK entities=600 submitted=%d native_fps_measured=false',submitted))
for i=1,100 do assert(seen[format('%g,0,0',1000+i)],'visible box lost') end
if not baseline then assert(submitted==100,'side/top/bottom culling absent') end
resetScene()
-- Long thin floor runs: their enclosing spheres intersect the camera but the
-- actual surfaces are wholly beyond a side plane. Retain all visible stairs,
-- floors and one camera-enclosing underdeck without a distance/floor shortcut.
for i=1,100 do box(Vector(1000+i,0,0),i%2+1) end
for i=1,100 do
 local e=box(Vector(4000,6000+i*2,0))
 e.mins=Vector(-1800,-16,-16);e.maxs=Vector(1800,16,16)
end
for i=1,100 do
 local e=box(Vector(1000,0,0))
 e.mins=Vector(0,3000+i,-16);e.maxs=Vector(64,3500+i,16)
end
local deck=box(Vector(),5);deck.mins=Vector(-4096,-4096,-32);deck.maxs=Vector(4096,4096,0)
submitted=frame()
for i=1,100 do assert(seen[format('%g,0,0',1000+i)],'visible elongated-scene box lost') end
assert(seen['0,0,0'],'camera-enclosing underdeck lost')
print(format('LOW_END_ELONGATED_VIEW entities=301 submitted=%d native_fps_measured=false',submitted))
if baseline then resetScene();return end
assert(submitted==101,'wholly off-camera thin/offset slabs over-admitted')
resetScene()
-- Exercise actual renderer under changing aspect/FOV, pitch/yaw/roll and camera.
local e=box(Vector(1000,800,0))
view.fov=90;assert(frame()==1)
view.fov=60;assert(frame()==0);view.fov=120;assert(frame()==1)
e.pos=Vector(1000,0,800);view.fov=90;view.aspect=1;assert(frame()==1)
view.aspect=2;assert(frame()==0)
view.angles=Angle(0,0,90);assert(frame()==1,'roll ignored')
view.angles=Angle(-90,0,0);e.pos=Vector(0,0,1000);assert(frame()==1,'pitch ignored')
view.angles=Angle(0,180,0);e.pos=Vector(-1000,0,0);assert(frame()==1,'yaw ignored')
view.origin=Vector(-2000,0,0);assert(frame()==0,'moved camera ignored')
view.angles=Angle();assert(frame()==1)
-- Active view wins even if an addon exposes different main EyePos/EyeVector.
local savedEye,savedForward=EyePos,EyeVector
EyePos=function() return Vector(2000,0,0) end;EyeVector=function() return Vector(-1,0,0) end
assert(frame()==1,'nested view used main camera');EyePos,EyeVector=savedEye,savedForward
view.origin=Vector();view.angles=Angle();view.aspect=1.6
e.pos=Vector(1000,1010,0);assert(frame()==1,'plane-intersecting sphere rejected')
e.pos=Vector(0,0,0);assert(frame()==1,'camera-intersecting sphere rejected')
e.pos=Vector(10,300,0);e.maxs.y=600;e.ang=Angle(37,92,18)
assert(frame()==0,'wholly outside rotated box retained by its enclosing sphere')
e.pos=Vector(600,0,0);assert(frame()==1,'visible asymmetric/rotated box rejected')
e.pos=Vector(10,300,0)
e.maxs.y=8;assert(frame()==0,'changed bounds not observed')
for _,field in ipairs({'ortho','offcenter'}) do view[field]={};assert(frame()==1);view[field]=nil end
local savedAspect=view.aspect;view.aspect=nil;assert(frame()==1,'unknown aspect must not side-cull');view.aspect=savedAspect
e.pos=Vector(1000,0,0);e.nw.LOD_GeometryHidden=true;assert(frame()==0)
e:OnRemove(true);e.nw.LOD_GeometryHidden=false;assert(frame()==1)
e:OnRemove(false);assert(frame()==0);fire('NotifyShouldTransmit',e,true);assert(frame()==1)
-- Existing entities can still carry the previous file's cached native basis
-- when only the renderer is hot-reloaded. Rebuild before borrowing new fields.
local priorSnapshot=e._LODVisualBox
ENT={};dofile(entityPath)
assert(frame()==1,'renderer refresh delayed a registered floor')
assert(e._LODVisualBox~=priorSnapshot,'renderer refresh borrowed a previous snapshot schema')
-- Independent corner projection oracle: every sampled visible corner requires a
-- draw. Culling may conservatively retain more, but may never hide such a box.
local function dot(a,b) return a.x*b.x+a.y*b.y+a.z*b.z end
local checked=0
for _,aspect in ipairs({.6,1,1.6,2.4}) do
 for _,fov in ipairs({40,75,110,150}) do
  for j=1,60 do
   view.aspect=aspect;view.fov=fov;view.angles=Angle((j*17)%160-80,(j*43)%360,(j*31)%360)
   view.origin=Vector(57,-93,18)
   e.pos=Vector((j*317)%2400-1200,(j*211)%2400-1200,(j*131)%1600-800)
   e.ang=Angle((j*19)%180,(j*29)%360,(j*37)%360)
   e.mins=Vector(-10-j*2,-17,-31);e.maxs=Vector(24,50+j,80)
   local visible=false
   for _,x in ipairs({e.mins.x,e.maxs.x}) do for _,y in ipairs({e.mins.y,e.maxs.y}) do for _,z in ipairs({e.mins.z,e.maxs.z}) do
    local f,r,u=e.ang:Forward(),e.ang:Right(),e.ang:Up()
    local p=Vector(e.pos.x+f.x*x-r.x*y+u.x*z,e.pos.y+f.y*x-r.y*y+u.y*z,e.pos.z+f.z*x-r.z*y+u.z*z)-view.origin
    local depth=dot(p,view.angles:Forward());local half=math.tan(math.rad(fov/2))
    if depth>1 and math.abs(dot(p,view.angles:Right())/depth)<=half
     and math.abs(dot(p,view.angles:Up())/depth)<=half/aspect then visible=true end
   end end end
   local n=frame();if visible then assert(n==1,'visible projected corner culled');checked=checked+1 end
  end
 end
end
assert(checked>50)
-- Independent eight-corner support oracle: if EVERY frustum plane contains at
-- least one corner, the conservative culler must retain the box, even when no
-- corner itself lies inside the whole frustum (large/intersecting slabs).
local conservative,crossing=0,0
for j=1,400 do
 view.aspect=.7+(j%8)*.3;view.fov=45+(j%9)*12;view.origin=Vector(23,-67,13)
 view.angles=Angle((j*17)%160-80,(j*43)%360,(j*31)%360)
 e.pos=Vector((j*317)%4800-2400,(j*211)%4800-2400,(j*131)%2400-1200)
 e.ang=Angle((j*19)%180,(j*29)%360,(j*37)%360)
 e.mins=Vector(-400-j*3,-17,-31);e.maxs=Vector(24,50+j*2,80)
 local cf,cr,cu=view.angles:Forward(),view.angles:Right(),view.angles:Up()
 local tx=math.tan(math.rad(view.fov/2));local ty=tx/view.aspect
 local maxima={-math.huge,-math.huge,-math.huge,-math.huge,-math.huge}
 local cornerInside=false
 for _,x in ipairs({e.mins.x,e.maxs.x}) do for _,y in ipairs({e.mins.y,e.maxs.y}) do for _,z in ipairs({e.mins.z,e.maxs.z}) do
  local f,r,u=e.ang:Forward(),e.ang:Right(),e.ang:Up()
  local p=Vector(e.pos.x+f.x*x-r.x*y+u.x*z,e.pos.y+f.y*x-r.y*y+u.y*z,e.pos.z+f.z*x-r.z*y+u.z*z)-view.origin
  local d,s,h=dot(p,cf),dot(p,cr),dot(p,cu)
  local inside=true
  for k,v in ipairs({d,d*tx-s,d*tx+s,d*ty-h,d*ty+h}) do
   maxima[k]=math.max(maxima[k],v);if v<0 then inside=false end
  end
  if inside then cornerInside=true end
 end end end
 local mustRetain=true;for _,v in ipairs(maxima) do if v<0 then mustRetain=false end end
 if mustRetain then
  assert(frame()==1,'intersecting box rejected by a frustum plane');conservative=conservative+1
  if not cornerInside then crossing=crossing+1 end
 end
end
assert(conservative>20 and crossing>0)
view.origin=Vector();view.angles=Angle();view.aspect=1.6;view.fov=90
e.pos=Vector(1000,1200,0);e.ang=Angle();e.mins=Vector(-100,-100,-16);e.maxs=Vector(100,100,16)
assert(frame()==1,'exact side-plane tangency rejected')
e.pos.y=1202;assert(frame()==0,'strictly outside tangent box retained')
local before=draws
for _,args in ipairs({{true,false,false},{false,true,false},{false,false,true}}) do
 fire('PostDrawOpaqueRenderables',table.unpack(args));assert(draws==before,'depth/sky pass submitted static geometry')
end
e.pos=Vector(1000,0,0);assert(frame()==1)
dofile(entityPath);assert(frame()==1,'scheduled Think delayed floor registration after Lua refresh')
resetScene()
-- Direct calls also keep their historical uncached-owner API, vertex UVs, tint
-- and transform. In-place mutations and eviction must rebuild only what changed.
local owner={};local pos,ang,mins,maxs=Vector(140,233,0),Angle(),Vector(-128,-64,-16),Vector(128,64,16)
local function signature(obj)
 local out={};for _,v in ipairs(obj.vertices) do out[#out+1]=format('%g,%g,%g|%.9g,%.9g',v.pos.x,v.pos.y,v.pos.z,v.u,v.v) end
 return table.concat(out,';')
end
local function check(kind)
 if kind=='slab' then
  B:DrawSlab(pos,ang,mins,maxs,material,color_white,512,owner)
  assert(signature(lastDraw.mesh)==signature(B:GetSlabMesh(mins,maxs,512,pos,ang)))
 elseif kind=='box' then
  B:Draw(pos,ang,mins,maxs,material,color_white,512,owner)
  assert(signature(lastDraw.mesh)==signature(B:GetMesh(mins,maxs,512)))
 else B:DrawGrate(pos,ang,mins,maxs,owner);assert(#lastDraw.mesh.vertices>8) end
 assert(lastDraw.matrix.pos.x==pos.x and lastDraw.matrix.pos.y==pos.y and lastDraw.matrix.pos.z==pos.z)
 assert((lastDraw.matrix.ang or angle_zero).p==ang.p and (lastDraw.matrix.ang or angle_zero).y==ang.y and (lastDraw.matrix.ang or angle_zero).r==ang.r)
 assert(blend==1 and tint[1]==1 and tint[2]==1 and tint[3]==1,'render state leaked')
end
check('slab');local first=lastDraw.mesh;matrices=0
pos.z=128;check('slab');assert(lastDraw.mesh==first and matrices==1,'Z movement rebuilt planar UVs or left stale matrix')
pos.x=141;check('slab');assert(lastDraw.mesh~=first)
ang.y=90;check('slab');ang.p=30;ang.r=25;check('slab')
maxs.x=192;check('slab');check('box');check('grate');check('slab')
local recent=lastDraw.mesh
for i=1,1000 do B:GetMesh(Vector(),Vector(i,7,9));assert(live<=256) end
assert(recent.dead);check('slab');assert(lastDraw.mesh~=recent and not lastDraw.mesh.dead)
local otherMaterial={};B:DrawSlab(pos,ang,mins,maxs,otherMaterial,color_white,256,owner)
assert(lastMaterial==otherMaterial and signature(lastDraw.mesh)==signature(B:GetSlabMesh(mins,maxs,256,pos,ang)))
local beforeDraw=draws;maxs.x=0/0;B:DrawSlab(pos,ang,mins,maxs,material,color_white,512,owner);assert(draws==beforeDraw)
maxs.x=192;check('slab')
fire('PostCleanupMap');assert(live==0);check('slab')
dofile(meshPath);assert(live==0);check('slab')
-- A weak owner cache cannot retain an otherwise unreachable entity.
local weak=setmetatable({owner},{__mode='v'});owner=nil;collectgarbage('collect');assert(weak[1]==nil)
B:DrawSlab(pos,ang,mins,maxs,material,color_white,512);assert(lastDraw.mesh and currentMatrix==nil)
fire('ShutDown');assert(live==0 and peak<=256)
print(format('LOW_END_RENDER_PASS: %d visible-corner and %d conservative plane cases (%d without an inside corner); native getter reuse and scheduled bounds; FOV/aspect/roll/pitch/yaw/nested views; mutations/kind/UV/material/eviction/cleanup/refresh/weak owners; ceiling=256',checked,conservative,crossing))
