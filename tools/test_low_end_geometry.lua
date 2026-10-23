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
 function e:SetNoDraw(value) self.noDraw=value end;function e:GetNoDraw() return self.noDraw or false end
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
-- Collision-only boxes are the majority of a generated maze. They must skip
-- visibility bounds/transforms entirely, while same-pass kind changes recover.
local collision=box(500,3);local transformCalls=0
local oldPosition=collision.GetPos
collision.GetPos=function(self) transformCalls=transformCalls+1;return oldPosition(self) end
assert(frame()==5 and transformCalls==0,'invisible collision geometry still performs visibility work')
collision.kind=1;assert(frame()==6 and transformCalls>0,'late kind change did not recover')
collision:OnRemove(false)
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

-- Exercise the actual Source visibility handoff with declared datatables.
-- A newly seen or uncertain box always falls back to the original Lua pass.
for _,e in ipairs(entities) do e:OnRemove(false) end
late:OnRemove(false)
CLIENT=true
dofile('gamemodes/legend_of_deborah/entities/entities/lod_static_box/shared.lua')
local native=box(200)
local values={BoxKind=1,BoxMins=Vector(-10,-10,-10),BoxMaxs=Vector(10,10,10)}
local notifications={}
function native:GetTable() return self end
function native:NetworkVar(_,_,name)
 local owner=self
 self['Get'..name]=function() return owner and values[name] end
 self['Set'..name]=function(self,value)
  if notifications[name] then notifications[name](self,name,values[name],value) end
  values[name]=value
 end
end
function native:NetworkVarNotify(name,fn) notifications[name]=fn end
function native:SetNextClientThink(at) self.nextThink=at end
native:SetupDataTables()
local nativeDraw=ENT.Draw
local positionReads=0
native.GetPos=function(self) positionReads=positionReads+1;return self.pos end
view={origin=eye,angles=angle_zero,fov=90,aspect=1,znear=1,zfar=10000}
local function nativeFrame(submitted,between)
 draws,wires,materialCalls={}, {}, 0
 hooks.PreRender.LOD_StaticBoxNativeVisibility()
 hooks.PreDrawOpaqueRenderables.LOD_StaticBoxNativeVisibility(false,false,false)
 if submitted then native:Draw() end
 if between then between() end
 positionReads=0
 draw(false,false,false)
 local count=0;for _ in pairs(draws) do count=count+1 end
 return count,positionReads
end
assert(nativeFrame(false)==1,'unobserved native Draw must fail open')
native:Initialize()
assert(nativeFrame(false)==0,'fresh declared instance did not use native selection')
assert(nativeFrame(true)==1,'native-visible floor disappeared')
local count,reads=nativeFrame(false)
assert(count==0 and reads==0,'native rejection still reads native pose or draws offscreen floor')
assert(nativeFrame(true)==1,'moving into native visibility did not recover immediately')
-- Native selection belongs to the entity and current view even if a refresh
-- replaces its Lua registration between Source's Draw and the manual pass.
assert(nativeFrame(true,function()
 local previous=native._LODVisualKindRecord
 native:SetupDataTables();native:Initialize()
 assert(native._LODVisualKindRecord~=previous)
end)==1,'same-pass registration replacement lost an actual native selection')
assert(nativeFrame(false)==0,'registration replacement retained selection into next view')
-- Native NoDraw can suppress ENT:Draw without changing the manual floor.
native:SetNoDraw(true)
assert(nativeFrame(false)==1,'native NoDraw incorrectly hid a manually rendered floor')
native:SetNoDraw(false)
-- Invisible collision-only kinds leave the native render queue, then a proxy
-- must release that flag before a late same-pass kind transition is rendered.
native:SetBoxKind(3);native:Think()
assert(native:GetNoDraw() and native._LODVisualKindRecord.clientNoDrawOwned,'invisible collision surrogate stayed in native render queue')
local kindNotify=notifications.BoxKind
notifications.BoxKind=function(...)
 kindNotify(...);native:Think()
 assert(not native:GetNoDraw(),'reentrant Think re-hid a newly visible kind before native write')
end
assert(nativeFrame(false,function() native:SetBoxKind(1) end)==1,'same-pass visible kind borrowed stale native omission')
notifications.BoxKind=kindNotify
native:Think();assert(nativeFrame(true)==1 and nativeFrame(false)==0,'visible kind did not recover native selection')
-- Unknown/custom kind accessors and externally owned flags stay conservative.
native:SetBoxKind(4);native:Think();assert(native:GetNoDraw())
local kindGetter=native.GetBoxKind
native.GetBoxKind=function() return 1 end
native._LODNextBoundsRefresh=0;native:Think()
assert(not native:GetNoDraw() and nativeFrame(false)==1,'custom kind retained owned invisible flag')
native.GetBoxKind=kindGetter
native:SetNoDraw(true);native:SetBoxKind(3);native:Think()
assert(not native._LODVisualKindRecord.clientNoDrawOwned,'claimed an externally owned NoDraw flag')
native:SetBoxKind(1);native:Think()
assert(native:GetNoDraw() and nativeFrame(false)==1,'changed external NoDraw ownership or hid manual floor')
native:SetNoDraw(false);assert(nativeFrame(true)==1)
native:SetBoxMaxs(Vector(15,10,10))
assert(native.nextThink==CurTime() and nativeFrame(false)==1,'pending bounds notification hid changed geometry')
native:Think();assert(nativeFrame(false)==0,'updated native bounds did not regain conservative selection')
-- A notification can call back into Think before the native setter commits.
local notify=notifications.BoxMaxs
notifications.BoxMaxs=function(...)
 notify(...);native:Think()
 assert(not native._LODVisualKindRecord.boundsReady,'reentrant Think certified pre-write bounds')
end
native:SetBoxMaxs(Vector(20,10,10))
assert(nativeFrame(false)==1,'reentrant native bounds update did not fail open')
native:Think();assert(nativeFrame(false)==0)
local getter=native.GetBoxMins
native.GetBoxMins=function() return Vector(-15,-10,-10) end
assert(nativeFrame(false)==1,'custom/replaced bounds accessor borrowed native bounds')
native.GetBoxMins=getter;native:Think()
native.Draw=function() end
assert(nativeFrame(false)==1,'replaced native Draw silently removed generated geometry')
native.Draw=nil
local wrapper=function(self,...) return nativeDraw(self,...) end
native.Draw=wrapper
LOD.RuntimeAudit={CPUProfile={bindings={[native]={Draw={wrapper=wrapper,callback=nativeDraw}}}}}
assert(nativeFrame(true)==1 and nativeFrame(false)==0,'opt-in CPU wrapper lost native visibility ownership')
LOD.RuntimeAudit=nil;native.Draw=nil
assert(nativeFrame(false,function() view.origin=Vector(-20,0,0) end)==1,'different/nested view borrowed native rejection')
view.origin=eye
view.ortho={};assert(nativeFrame(false)==1,'orthographic native pass did not fail open');view.ortho=nil
native:OnRemove(true);assert(nativeFrame(false)==1,'full-update bounds used retired native selection')
CurTime=function() return 12 end
native:Think();assert(nativeFrame(true)==1 and nativeFrame(false)==0)
native.nw.LOD_GeometryHidden=true;assert(nativeFrame(true)==0,'native handoff exposed hidden false floor')
native.nw.LOD_GeometryHidden=false;assert(nativeFrame(true)==1)
native:OnRemove(false);assert(nativeFrame(true)==0,'removed entity was resurrected by native Draw')
native:Initialize();native:OnRemove(true)
local retained=native._LODVisualKindRecord
local weak=setmetatable({native},{__mode='v'})
native=nil;getter=nil;kindGetter=nil;entities={};collectgarbage('collect');collectgarbage('collect')
assert(weak[1]==nil and retained.lua[1]==nil,'retained bounds cache owns removed entity through native accessor closures')
print('NATIVE_GEOMETRY_VISIBILITY_PASS: native selection avoids offscreen pose reads; newly seen/custom/pending/reentrant/full-update views fail open; exact view ownership, CPU wrappers, hidden state and removal')
