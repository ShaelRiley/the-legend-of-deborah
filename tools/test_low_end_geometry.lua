-- Actual generated-static-geometry hook, engine boundary doubles. --baseline
-- records prior draw/material work; normal mode asserts conservative rejection.
local baseline=arg and arg[1]=='--baseline'
local noop=function() end
local hooks={};hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end}
include=noop;concommand={Add=noop};CurTime=function() return 10 end
function IsValid(e) return type(e)=='table' and e.valid~=false end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
local eye,forward=Vector(),Vector(1,0,0)
EyePos=function() return eye end;EyeVector=function() return forward end
angle_zero={p=0,y=0,r=0}
local view={fov=90,znear=1}
local draws,wires,materialCalls,grates={},{},0,0
local material={}
render={SetMaterial=noop,DrawBox=noop,DrawWireframeBox=function(pos) wires[pos]=true end,
 GetViewSetup=function(noPlayer) assert(noPlayer==true,'wrong view setup (player instead of render camera)');return view end}
LOD={Config={Geometry={}}}
LOD.TexturedBox={GetIndustrialMaterial=function() materialCalls=materialCalls+1;return material,false end,
 DrawSlab=function(_,pos,ang,mins,maxs,mat) assert(mat==material);draws[pos]=true end,
 Draw=function(_,pos,ang,mins,maxs,mat) assert(mat==material);draws[pos]=true end,
 DrawGrate=function(_,pos) grates=grates+1;draws[pos]=true end}
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua')
local entities={}
local function box(x,kind,mins,maxs)
 local e=setmetatable({pos=Vector(x,0,0),kind=kind or 1,mins=mins or Vector(-10,-10,-10),
 maxs=maxs or Vector(10,10,10),nw={},ang=angle_zero},{__index=ENT})
 function e:GetPos() return self.pos end;function e:GetAngles() return self.ang end
 function e:GetBoxKind() return self.kind end;function e:GetBoxMins() return self.mins end
 function e:GetBoxMaxs() return self.maxs end;function e:SetRenderBounds() end
 function e:GetClass() return 'lod_static_box' end
 function e:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then return d end;return v end
 e.GetNW2String=e.GetNW2Bool;e:Initialize();entities[#entities+1]=e;return e
end
for i=1,600 do box(i<=300 and 200+i or -200-i) end
local draw=assert(hooks.PostDrawOpaqueRenderables['LOD.DrawGeneratedStaticGeometry'])
local function frame()
 draws,wires,materialCalls={}, {}, 0;draw(false,false,false)
 local n=0;for _ in pairs(draws) do n=n+1 end;return n
end
local n=frame();print(string.format('LOW_END_GEOMETRY boxes=600 submitted=%d floor_material_resolutions=%d native_fps_measured=false',n,materialCalls))
if baseline then return end
assert(n==300 and materialCalls==1,'rear geometry not culled / materials not shared')
for i,e in ipairs(entities) do assert((draws[e.pos]==true)==(i<=300),'wrong half-space') end
forward=Vector(-1,0,0);assert(frame()==300 and materialCalls==1)
for i,e in ipairs(entities) do assert((draws[e.pos]==true)==(i>300),'rotation retained stale visibility') end
-- A detached/cutscene camera, not a LocalPlayer-space decision.
eye=Vector(-2000,0,0);forward=Vector(1,0,0);assert(frame()==600)
for _,e in ipairs(entities) do e:OnRemove(false) end
entities={};eye=Vector();forward=Vector(1,0,0)
local near=box(-1) -- intersects camera plane: always retained
local big=box(-400,5,Vector(-500,-500,-32),Vector(500,500,0)) -- underdeck encloses camera
local offcenter=box(-200,2,Vector(-5,-5,0),Vector(300,6,50)) -- origin is not box center
local grate=box(200);grate.nw.LOD_CrateGrate=true
local hazard=box(400);hazard.nw.LOD_EventArchetype='false_floor'
assert(frame()==5 and draws[near.pos] and draws[big.pos] and draws[offcenter.pos] and wires[offcenter.pos] and wires[hazard.pos] and grates>0)
-- Arbitrary pitch/yaw cannot escape the origin-centred bounding sphere.
offcenter.ang={p=87,y=137,r=21};assert(frame()==5)
-- Same-tick new geometry bounds, motion and hidden state must be observed.
near.mins=Vector(-1,-1,-1);near.maxs=Vector(1,1,1);near.pos=Vector(-100,0,0)
assert(frame()==4 and not draws[near.pos])
near.maxs.x=150;assert(frame()==5 and draws[near.pos],'mutable bound was cached by reference')
hazard.nw.LOD_GeometryHidden=true;assert(frame()==4 and not wires[hazard.pos] and not draws[hazard.pos])
hazard.nw.LOD_GeometryHidden=false;assert(frame()==5 and wires[hazard.pos])
-- Unknown, non-perspective, extreme-FOV or negative-near views fail open.
near.maxs.x=1
for _,v in ipairs({{ortho={},fov=90,znear=1},{offcenter={},fov=90,znear=1},{fov=180,znear=1},{fov=0,znear=1},{fov=90,znear=-1},{}}) do
 view=v;assert(frame()==5,'special/unknown camera lost geometry')
end
view=nil;assert(frame()==5)
view={fov=90,znear=1};local saved=EyeVector;EyeVector=nil;assert(frame()==5);EyeVector=saved
-- No accidental work in excluded render passes or empty scenes.
for _,args in ipairs({{true,false,false},{false,true,false},{false,false,true}}) do
 materialCalls=0;draws={};draw(table.unpack(args));assert(materialCalls==0 and next(draws)==nil)
end
for _,e in ipairs(entities) do e:OnRemove(false) end
assert(frame()==0 and materialCalls==0)
-- Missing network accessors stay registered and recover without Initialize.
local late=box(100);late.GetBoxMins=false;assert(frame()==0)
late.GetBoxMins=function(self) return self.mins end;assert(frame()==1)
late:OnRemove(true);assert(frame()==1)
late:OnRemove(false);assert(frame()==0)
hooks.NotifyShouldTransmit.LOD_Recover_lod_static_box(late,true);assert(frame()==1)
-- Failure/fallback resolution is not sticky across independent render passes.
material={};assert(frame()==1 and materialCalls==1)
print('LOW_END_GEOMETRY_PASS: rear-only rejection; camera/rotation/intersection/asymmetry/changed bounds; orthographic/unknown fail-open; floors/stairs/grates/hazards; full update; per-pass material refresh')
