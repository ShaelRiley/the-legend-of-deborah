-- Execute real fit renderer and mesh UV compiler; Source-only boundaries doubled.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local baseline=arg and arg[1]=='--baseline'
local brandingPath=baseline and assert(arg[2]) or root..'cl_container_branding.lua'
local noop=function() end
CurTime=function() return 100 end
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
 return {IsError=function() return false end,GetTexture=function() return {IsError=function() return false end} end,GetShader=function() return "UnlitGeneric" end}
end
function CreateMaterial(name,shader,args)
 creates=creates+1;assert(shader=='UnlitGeneric' and args['$nocull']=='0' and args['$alphatest']=='1')
 return {SetTexture=noop,Recompute=noop,IsError=function() return false end,GetShader=function() return "UnlitGeneric" end}
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
dofile(brandingPath)
assert(loads==0 and creates==0,'catalog eagerly materialized')
local Brand,C=LOD.CrateBranding,LOD.CrateVisuals
local mat=assert(Brand.MaterialFor(1));Brand.MaterialFor(1);assert(loads==1 and creates==1)
Brand.MaterialFor(256);assert(creates==1)
Brand.MaterialFor(1,'preview');assert(creates==2)
local model={pos=Vector(),yaw=0}
function model:GetPos() return self.pos end
-- Regression: culling bounds can be empty; physical anchors must still render.
function model:GetRenderBounds() return Vector(),Vector() end
function model:GetModel() return LOD.Config.Geometry.ContainerModel end
function model:GetForward() return Vector(math.cos(self.yaw),math.sin(self.yaw),0) end
function model:GetRight() return Vector(math.sin(self.yaw),-math.cos(self.yaw),0) end
function model:GetUp() return Vector(0,0,1) end
function model:GetAngles() return {p=0,y=math.deg(self.yaw),r=0} end
function model:LocalToWorld(p) return self.pos+self:GetForward()*p.x-self:GetRight()*p.y+self:GetUp()*p.z end
local checks=0
-- Independent Source reference: Facepunch render.DrawQuad's upward-facing
-- example uses (0,0), (0,100), (100,100), (100,0). Its cross product is -Z.
-- The exported stock cargo VTX agrees: all 428 triangles have cross dot normal <0.
-- A positive cross dot normal is the BACK face, despite the old test's label.
local sourceFrontCross=Vector(0,100,0):Cross(Vector(100,100,0))
assert(sourceFrontCross:Dot(Vector(0,0,1))<0)
for _,yaw in ipairs({0,90,180,270}) do
 model.yaw=math.rad(yaw);model.pos=Vector(112,328,450)
 for _,side in ipairs({-1,1}) do
  for id=1,256 do
   Brand.Draw(model,id,mat,model.pos+model:GetForward()*(side*500))
   assert(#vertices==4)
   local a,b,c=vertices[1],vertices[2],vertices[3]
   assert((b.pos-a.pos):Cross(c.pos-a.pos):Dot(a.normal)<0,'Source front-face winding is reversed')
   -- UVs must still run left-to-right and top-to-bottom from the viewer's side.
   local screenRight=side>0 and -model:GetRight() or model:GetRight()
   for i=1,4 do for j=i+1,4 do
    local p,q=vertices[i],vertices[j]
    assert((q.pos-p.pos):Dot(screenRight)*(q.u-p.u)>=-1e-9,'mirrored company text')
    assert((q.pos-p.pos):Dot(model:GetUp())*(q.v-p.v)<=1e-9,'upside-down company text')
   end end
   for _,v in ipairs(vertices) do
    local p=v.pos-model.pos
    assert(math.abs(p:Dot(model:GetRight()))<=C.SafeWidth*.5+1e-8)
    assert(math.abs(p:Dot(model:GetForward())-(side>0 and C.CargoMaxs.x+C.SurfaceOffset or C.CargoMins.x-C.SurfaceOffset))<1e-8)
    assert(v.u>=0 and v.u<=1 and v.v>=0 and v.v<=1)
    assert(v.color.r==255 and v.color.g==255 and v.color.b==255 and v.color.a==255)
   end
   checks=checks+1
  end
 end
end
-- Wrong models must not receive guessed anchors; actual draw count excludes them.
local oldModel=model.GetModel; model.GetModel=function() return "models/error.mdl" end
local ok,why=Brand.Draw(model,1,mat,Vector());assert(not ok and why=='wrong-model')
model.GetModel=oldModel
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
model.GetModel=function() return "models/error.mdl" end
hooks.LOD_DrawContainerBranding();assert(Brand.lastDrawCount==0 and Brand.lastSkippedCount==64)
model.GetModel=oldModel;hooks.LOD_DrawContainerBranding();assert(Brand.lastDrawCount==64)
local before=vertices;hooks.LOD_DrawContainerBranding(true);assert(vertices==before)
-- Exercise the real wall compiler -> eligibility -> placement -> bucket renderer.
-- Earlier coverage injected companyBranded=true and never crossed these seams.
function model:Remove() self.valid=false end
surface={CreateFont=noop};net={Receive=noop}
function Angle(p,y,r) return {p=p,y=y,r=r} end
function ClientsideModel(path)
 local m=setmetatable({pos=Vector(),yaw=0,valid=true},{__index=model})
 function m:SetNoDraw() end
 function m:SetPos(p) self.pos=p end
 function m:SetAngles(a) self.yaw=math.rad(a.y) end
 m.SetSkin=noop;m.SetMaterial=noop;m.SetColor=noop;m.DrawShadow=noop
 function m:Remove() self.valid=false end
 return m
end
dofile(root..'cl_wall_visuals.lua')
w.logical={};w.seed=725;w.origin=Vector();w.dirty=true
for x=2,20 do w.logical[#w.logical+1]={x,10,0,1} end
hooks.LOD_BuildProceduralContainerWalls()
assert(#w.world==38)
-- Simulate a subset reserved for wayfinding, then run real brand placement.
for i,instance in ipairs(w.world) do instance.marked=i%7==0 end
w.markRevision=1
hooks.LOD_RebuildSparseContainerBrandPlacement()
local chosen,edges,endpoints=0,{},{}
for _,instance in ipairs(w.world) do
 if instance.companyBranded then
  chosen=chosen+1;assert(not instance.marked and instance.brandSurfaceEligible)
  assert(not edges[instance.overlayEdgeKey]);edges[instance.overlayEdgeKey]=true
  local prefix=tostring(instance.stackIndex)..':'..instance.overlayOrientation..':'
  for _,endpoint in ipairs({instance.overlayEndpointA,instance.overlayEndpointB}) do
   assert(not endpoints[prefix..endpoint]);endpoints[prefix..endpoint]=true
  end
 end
end
assert(chosen>0 and chosen<=math.floor(#w.world*.4),'brand selection is empty/unbounded')
EyePos=function() return Vector(0,-384,64) end
hooks.LOD_DrawContainerBranding();assert(Brand.lastDrawCount>0,'compiled brands never reach rendering')
local selected={};for i,v in ipairs(w.world) do selected[i]=v.companyBranded end
w.markRevision=2;hooks.LOD_RebuildSparseContainerBrandPlacement()
for i,v in ipairs(w.world) do assert(selected[i]==v.companyBranded,'placement is nondeterministic') end
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
-- Wayfinding owns sparse placement only, even if run after the material owner.
-- Re-running it must preserve canonical skin/material/body/stencil colors.
local appearanceWrites=0
for i,m in ipairs(w.models) do
    m.SetSkin=function() appearanceWrites=appearanceWrites+1 end
    m.SetMaterial=function() appearanceWrites=appearanceWrites+1 end
    m.SetColor=function() appearanceWrites=appearanceWrites+1 end
    w.world[i].bodyColor=Color(21,43,65);w.world[i].stencilColor=Color(123,145,167)
end
dofile(root..'cl_container_wayfinding_projection.lua')
hooks.LOD_ApplyContainerSectionColors()
for _=1,40 do hooks.LOD_ApplyContainerSectionColors() end
assert(appearanceWrites==0,'wayfinding overwrote canonical appearance')
for _,inst in ipairs(w.world) do
    assert(inst.bodyColor.r==21 and inst.stencilColor.r==123,'wayfinding tint authority duplicated')
end
assert(w.markRevision>2,'sparse mark placement did not run')

-- Loaded overlay hooks share the existing conservative batch-view authority.
-- Exercise actual 3D2D/mesh submissions; native models stay visible throughout.
CreateClientConVar=function() return {GetBool=function() return false end} end
GetConVar=CreateClientConVar;cvars={AddChangeCallback=noop}
dofile(root..'cl_wall_batch.lua')
assert(w.OverlayView and w.OverlaySphereVisible,'overlay camera authority missing')
local A={};A.__index=A
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},A) end
function A:Forward()
 local p,y=math.rad(self.p),math.rad(self.y)
 return Vector(math.cos(p)*math.cos(y),math.cos(p)*math.sin(y),-math.sin(p))
end
function A:Right()
 local p,y,r=math.rad(self.p),math.rad(self.y),math.rad(self.r)
 return Vector(-math.sin(r)*math.sin(p)*math.cos(y)+math.cos(r)*math.sin(y),
  -math.sin(r)*math.sin(p)*math.sin(y)-math.cos(r)*math.cos(y),-math.sin(r)*math.cos(p))
end
function A:Up()
 local p,y,r=math.rad(self.p),math.rad(self.y),math.rad(self.r)
 return Vector(math.cos(r)*math.sin(p)*math.cos(y)+math.sin(r)*math.sin(y),
  math.cos(r)*math.sin(p)*math.sin(y)-math.sin(r)*math.cos(y),math.cos(r)*math.cos(p))
end
-- Panel rotations are native boundaries; this checkpoint does not change them.
A.RotateAroundAxis=noop
function model:GetAngles() return Angle(0,math.deg(self.yaw),0) end
function model:GetRenderBounds() return C.CargoMins,C.CargoMaxs end
local view,metrics,boardDraws,quadDraws=nil,0,0,0
local boardAnchors={}
render.GetViewSetup=function(current) assert(current);return view end
EyePos=function() return Vector(0,0,64) end
cam.Start3D2D=function(pos,_,scale)
 assert(scale==0.22);boardDraws=boardDraws+1;boardAnchors[#boardAnchors+1]=pos
end
cam.End3D2D=noop
surface.SetFont=noop;surface.SetDrawColor=noop;surface.SetMaterial=noop
surface.DrawRect=noop;surface.DrawTexturedRect=noop
surface.GetTextSize=function(code) metrics=metrics+1;return #code*100,172 end
draw={SimpleText=noop};TEXT_ALIGN_CENTER=1
local begin=mesh.Begin
mesh.Begin=function(a,b,c) if type(a)=='number' then quadDraws=quadDraws+1 end;return begin(a,b,c) end
w.world={};w.models={};w.labelBuckets={[0]={['2:2']={}}}
for i=1,600 do
 local m=setmetatable({pos=Vector(i%2==0 and 1000 or -1000,0,0),yaw=0,valid=true},{__index=model})
 local inst={marked=i<=300,companyBranded=i>300,brandSurfaceEligible=true,
  sectionColor=Color(21,43,65),bodyColor=Color(21,43,65),stencilColor=Color(123,145,167),code='1A'}
 w.world[i]=inst;w.models[i]=m;w.labelBuckets[0]['2:2'][i]=i
end
local function overlays()
 boardDraws,quadDraws,boardAnchors=0,0,{}
 hooks.LOD_DrawContainerWayfinding();hooks.LOD_DrawContainerBranding()
 return boardDraws,quadDraws
end
local oldBoards,oldBrands=overlays()
assert(oldBoards==300 and oldBrands==64,'unknown view changed historical submissions')
assert(metrics==300)
view={origin=Vector(0,0,64),angles=Angle(),fov=90,aspect=1.6,znear=1}
local newBoards,newBrands=overlays()
print(string.format('OVERLAY_SUBMISSIONS unknown_view_boards=%d known_view_boards=%d unknown_view_brands=%d known_view_brands=%d',oldBoards,newBoards,oldBrands,newBrands))
assert(newBoards==150 and newBrands==32,'offscreen overlays still submitted')
assert(w.wayfindingStats.culled==150 and Brand.lastCulledCount==32)
for _,pos in ipairs(boardAnchors) do assert(pos.x>0,'rear board submitted') end
local fixedMetrics=metrics
for _=1,600 do overlays() end
assert(metrics==fixedMetrics,'unchanged stencil layout measured every frame')
view.angles=Angle(0,180,0);overlays()
assert(boardDraws==150 and quadDraws==32)
for _,pos in ipairs(boardAnchors) do assert(pos.x<0,'nested view used player camera') end
for _,args in ipairs({{true,false,false},{false,true,false},{false,false,true}}) do
 local oldBoardCount,oldQuadCount=boardDraws,quadDraws
 hooks.LOD_DrawContainerWayfinding(table.unpack(args));hooks.LOD_DrawContainerBranding(table.unpack(args))
 assert(boardDraws==oldBoardCount and quadDraws==oldQuadCount,'overlay repeated in excluded pass')
end
for _,flag in ipairs({'ortho','offcenter'}) do
 view[flag]={};overlays();assert(boardDraws==300 and quadDraws==64,'nonperspective view lost overlays');view[flag]=nil
end
for _,field in ipairs({'fov','aspect','znear'}) do
 local old=view[field];view[field]=0/0;overlays()
 assert(boardDraws==300 and quadDraws==64,'malformed view did not retain overlays');view[field]=old
end
local angles,origin=view.angles,view.origin
view.angles={};overlays();assert(boardDraws==300 and quadDraws==64)
view.angles=angles;view.origin=Vector(0/0,0,0);overlays();assert(boardDraws==300 and quadDraws==64)
view.origin=origin
-- Text/code changes and Lua refresh invalidate only exact instance layouts.
w.world[1].code='123456789A';overlays();assert(metrics==fixedMetrics+1)
local layout=w.world[1].stencilLayout
assert(layout.radius>=math.sqrt((layout.width*.5+5)^2+(layout.height*.5+6)^2)*.22)
dofile(root..'cl_container_wayfinding_projection.lua');overlays();assert(metrics==fixedMetrics+301)
assert(appearanceWrites==0,'overlay optimization mutated native appearance')
assert(w.batchStats.hidden==0 and w.batchStats.status=='off','overlay optimization enabled mesh replacements')
-- Independent corner projection oracle: every visible corner inside a sphere
-- must retain its submission, including edge intersections and rolled cameras.
local projected=0
for _,aspect in ipairs({.6,1,1.6,2.4}) do for _,fov in ipairs({40,75,110,150}) do
 for j=1,60 do
  view.aspect=aspect;view.fov=fov;view.angles=Angle((j*17)%160-80,(j*43)%360,(j*31)%360)
  view.origin=Vector(57,-93,18)
  local center=Vector((j*317)%2400-1200,(j*211)%2400-1200,(j*131)%1600-800)
  local extent=30+j;local radius=math.sqrt(3)*extent
  local any=false
  for _,x in ipairs({-extent,extent}) do for _,y in ipairs({-extent,extent}) do for _,z in ipairs({-extent,extent}) do
   local p=center+Vector(x,y,z)-view.origin;local depth=p:Dot(view.angles:Forward())
   local half=math.tan(math.rad(fov*.5))
   if depth>1 and math.abs(p:Dot(view.angles:Right())/depth)<=half
    and math.abs(p:Dot(view.angles:Up())/depth)<=half/aspect then any=true end
  end end end
  if any then
   assert(w:OverlaySphereVisible(w:OverlayView(),center,radius),'visible projected corner culled')
   projected=projected+1
  end
 end
end end
assert(projected>50)
assert(w:OverlaySphereVisible(w:OverlayView(),Vector(0/0,0,0),55)
 and w:OverlaySphereVisible(w:OverlayView(),Vector(),0/0),'invalid geometry did not draw conservatively')
print(string.format('OVERLAY_WORK unknown_view_boards=%d known_view_boards=%d unknown_view_brands=%d known_view_brands=%d stable_600_frames_metric_reads=0 projected_corner_cases=%d native_fps_measured=false',oldBoards,newBoards,oldBrands,newBrands,projected))

-- Paired production probe: static logo geometry must stop rebuilding, without
-- changing immediate quad submissions, world/preview poses or artwork inputs.
view=nil
local rawVector,rawFit=Vector,C.FitBrand
local vectorCalls,fitCalls=0,0
Vector=function(...) vectorCalls=vectorCalls+1;return rawVector(...) end
C.FitBrand=function(...) fitCalls=fitCalls+1;return rawFit(...) end
local probe=setmetatable({pos=Vector(112,328,450),yaw=.7,valid=true},{__index=model})
Brand.Draw(probe,17,mat,Vector(800,200,500))
local probeEye=Vector(800,200,500)
vectorCalls,fitCalls=0,0
for _=1,600 do assert(Brand.Draw(probe,17,mat,probeEye)) end
local steadyVectors,steadyFits=vectorCalls,fitCalls
print(string.format('BRAND_GEOMETRY_WORK draws=600 vectors=%d fit_resolutions=%d native_fps_measured=false',steadyVectors,steadyFits))
if not baseline then assert(steadyVectors==600 and steadyFits==0,'steady logo geometry was rebuilt') end
Vector,C.FitBrand=rawVector,rawFit

local function geometryOracle(eye,id)
 assert(Brand.Draw(probe,id,mat,eye));local fit=assert(C.FitBrand(id))
 local side=probe:GetForward():Dot(eye-probe:GetPos())>=0 and 1 or -1
 local center=probe:LocalToWorld(Vector(side>0 and C.CargoMaxs.x+C.SurfaceOffset or C.CargoMins.x-C.SurfaceOffset,
  (C.CargoMins.y+C.CargoMaxs.y)*.5,C.CargoMins.z+(C.CargoMaxs.z-C.CargoMins.z)*.55))
 local horizontal=side>0 and -probe:GetRight() or probe:GetRight();local up=probe:GetUp()
 local positions={center-horizontal*fit.width*.5+up*fit.height*.5,
  center+horizontal*fit.width*.5+up*fit.height*.5,center+horizontal*fit.width*.5-up*fit.height*.5,
  center-horizontal*fit.width*.5-up*fit.height*.5}
 local uv={{fit.u0,fit.v0},{fit.u1,fit.v0},{fit.u1,fit.v1},{fit.u0,fit.v1}}
 for i,v in ipairs(vertices) do
  assert(v.pos:DistToSqr(positions[i])<1e-12,'cached projection lost its actual pose')
  assert(v.u==uv[i][1] and v.v==uv[i][2],'cached projection lost full artwork UVs')
 end
end
for i=1,40 do
 probe.pos.x=112+i*13;probe.pos.y=328-i*7;probe.pos.z=450+i*11
 probe.yaw=i*.137;geometryOracle(probe.pos+probe:GetForward()*500,17)
 geometryOracle(probe.pos-probe:GetForward()*500,232)
end
probe.pose=Angle(17,91,23)
function probe:GetAngles() return self.pose end
function probe:GetForward() return self.pose:Forward() end
function probe:GetRight() return self.pose:Right() end
function probe:GetUp() return self.pose:Up() end
probe.scale=1
function probe:GetModelScale() return self.scale end
function probe:LocalToWorld(p) return self.pos+(self:GetForward()*p.x-self:GetRight()*p.y+self:GetUp()*p.z)*self.scale end
for i=1,30 do
 probe.pose.p=(i*17)%140-70;probe.pose.y=(i*43)%360;probe.pose.r=(i*31)%360
 probe.scale=i%3==0 and 1.25 or 1
 geometryOracle(probe.pos+probe:GetForward()*500,17)
 geometryOracle(probe.pos-probe:GetForward()*500,232)
end
local metadata=LOD.CrateBrandMetadata[232];local bound=metadata.bounds[1]
metadata.bounds[1]=bound+1;geometryOracle(probeEye,232);metadata.bounds[1]=bound
local safeWidth=C.SafeWidth;C.SafeWidth=safeWidth*.5;geometryOracle(probeEye,232);C.SafeWidth=safeWidth
local offset=C.SurfaceOffset;C.SurfaceOffset=offset+2;geometryOracle(probeEye,232);C.SurfaceOffset=offset
local cargoZ=C.CargoMaxs.z;C.CargoMaxs.z=cargoZ+10;geometryOracle(probeEye,232);C.CargoMaxs.z=cargoZ
local metadataWidth=metadata.width;metadata.width=metadataWidth+10;geometryOracle(probeEye,232);metadata.width=metadataWidth
local oldFit=C.FitBrand;C.FitBrand=function(id) local f=oldFit(id);f.width=f.width*.5;return f end
geometryOracle(probeEye,232);C.FitBrand=oldFit
local weak=setmetatable({probe},{__mode='v'});probe=nil;collectgarbage('collect');collectgarbage('collect')
assert(weak[1]==nil,'geometry cache retained a retired model')

-- Exact nearest-64 oracle, including ties, arbitrary bucket order, excess
-- candidates, movement, eligibility changes and admission BEFORE view culling.
local rawDraw,rawSort=Brand.Draw,table.sort
local selected,maxSorted,selectionCases={},0,0
Brand.Draw=function(m,...) selected[#selected+1]=m.probeIndex;return rawDraw(m,...) end
table.sort=function(t,compare) maxSorted=math.max(maxSorted,#t);return rawSort(t,compare) end
for _,count in ipairs({0,1,63,64,65,128,300,1000}) do for pattern=1,4 do
 w.world={};w.models={};w.labelBuckets[0]={['2:2']={}}
 local expected={}
 for i=1,count do
  local x=pattern==1 and i or pattern==2 and count-i or pattern==3 and (i%7)*11 or ((i*7919)%1401)-700
  local m=setmetatable({pos=Vector(x,0,64),yaw=0,valid=true,probeIndex=i},{__index=model})
  w.world[i]={companyBranded=true,brandSurfaceEligible=true,marked=i%31==0};w.models[i]=m
  w.labelBuckets[0]['2:2'][count-i+1]=i
  if not w.world[i].marked then expected[#expected+1]={index=i,distance=EyePos():DistToSqr(m:GetPos())} end
 end
 rawSort(expected,function(a,b) return a.distance<b.distance or (a.distance==b.distance and a.index<b.index) end)
 selected={};hooks.LOD_DrawContainerBranding()
 assert(#selected==math.min(#expected,C.MaxBrandDraws))
 for i,index in ipairs(selected) do assert(index==expected[i].index,'nearest/tie order changed') end
 selectionCases=selectionCases+1
end end
Brand.Draw,table.sort=rawDraw,rawSort
print(string.format('BRAND_SELECTION_WORK exact_scenes=%d largest_sort=%d max_admitted=%d native_fps_measured=false',selectionCases,maxSorted,C.MaxBrandDraws))
if not baseline then assert(maxSorted<=C.MaxBrandDraws,'unselected population still sorted') end

-- Same loaded scene/engine doubles for both exact parent and candidate. This is
-- Lua workload timing only; neither native GPU work nor whole-game FPS.
hooks.LOD_DrawContainerBranding();collectgarbage('collect')
local started=os.clock()
for _=1,600 do hooks.LOD_DrawContainerBranding();assert(Brand.lastDrawCount==64) end
print(string.format('BRAND_SCENE_WORK candidates=968 admitted=64 frames=600 lua_seconds=%.6f native_fps_measured=false',os.clock()-started))

-- A gate/eligibility/model lifetime update is visible on the very next pass.
w.world[1].marked=true;w.models[2].pos.x=1500;w.models[3].valid=false
local oracle={}
for index,instance in ipairs(w.world) do
 local m=w.models[index]
 if not instance.marked and IsValid(m) then oracle[#oracle+1]={index=index,distance=EyePos():DistToSqr(m:GetPos())} end
end
rawSort(oracle,function(a,b) return a.distance<b.distance or (a.distance==b.distance and a.index<b.index) end)
selected={};Brand.Draw=function(m,...) selected[#selected+1]=m.probeIndex;return rawDraw(m,...) end
hooks.LOD_DrawContainerBranding()
for i,index in ipairs(selected) do assert(index==oracle[i].index,'candidate lifetime change was cached') end
local visible=w.OverlaySphereVisible
w.OverlaySphereVisible=function(_,_,pos) return pos.x>=0 end
selected={};hooks.LOD_DrawContainerBranding()
local cursor=0
for i=1,64 do local index=oracle[i].index;if w.models[index].pos.x>=0 then cursor=cursor+1;assert(selected[cursor]==index) end end
assert(#selected==cursor,'culled admission was filled by farther artwork')
w.OverlaySphereVisible=visible;Brand.Draw=rawDraw
print('CRATE_RENDER_PASS: '..checks..' original composition/orientation checks; independent untinted artwork; two lazy shader slots; 64-draw ceiling for 1000 candidates; rotated/shared slab UV seams; '..quads..' cached opaque grate quads with underside and cleanup')
