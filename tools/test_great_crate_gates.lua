-- Execute production presentation with native boundaries doubled. Physical gate
-- collision and progression are covered by the existing full-update/event gates.
local root='gamemodes/legend_of_deborah/'
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:DistToSqr(b) local d=self-b;return d.x*d.x+d.y*d.y+d.z*d.z end
function Angle(_,yaw)
 local a=math.rad(yaw or 0)
 return {Forward=function() return Vector(math.cos(a),math.sin(a),0) end,
 Right=function() return Vector(math.sin(a),-math.cos(a),0) end,Up=function() return Vector(0,0,1) end}
end
angle_zero=Angle(0,0);color_white={r=255,g=255,b=255,a=255}
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function IsValid(o) return type(o)=='table' and o.valid~=false end
local now=10;CurTime=function() return now end
local hooks={};hook={Add=function(event,id,f) hooks[event]=hooks[event] or {};hooks[event][id]=f end}
include=noop;concommand={Add=noop};render={SetMaterial=noop,DrawBox=noop}
Material=function(path) assert(not path:find('concrete'));return {path=path} end
CreateMaterial=function() return {} end
LOD={};dofile(root..'gamemode/lod/sh_config.lua')
local PC,GC=LOD.Config.Progression,LOD.Config.Geometry
local native,fail,bad,thinY,allocations,draws=nil,false,false,false,0,0
function Matrix() return {Scale=function(self,s) self.scale=s end} end
function ClientsideModel(path)
 assert(path==GC.GateModel);allocations=allocations+1
 if fail then return nil end
 local m={valid=true}
 function m:SetNoDraw(v) assert(v) end
 m.DrawShadow=noop
 function m:GetModelBounds()
  if bad then return Vector(),Vector() end
  -- Off-center model fixture; alternate its thin axis to test measured orientation.
  if thinY then return Vector(-53,-2,5),Vector(67,6,133) end
  return Vector(-2,-53,5),Vector(6,67,133)
 end
 function m:EnableMatrix(_,matrix) self.scale=matrix.scale end
 function m:SetRenderBounds(a,b) self.mins,self.maxs=a,b end
 function m:SetPos(p) self.pos=p end
 function m:SetAngles(a) self.ang=a end
 function m:SetColor(c) assert(c==color_white) end
 m.SetupBones=noop
 function m:DrawModel() draws=draws+1 end
 function m:Remove() self.valid=false end
 native=m;return m
end
ENT={};dofile(root..'entities/entities/lod_gate/cl_init.lua')
local G=LOD.GatePresentation
local center=Vector(110,230,410)
local function checkBounds(axis)
 assert(G.Draw(center,axis));local a,b=native:GetModelBounds()
 local lo,hi=Vector(1e9,1e9,1e9),Vector(-1e9,-1e9,-1e9)
 for _,x in ipairs({a.x,b.x}) do for _,y in ipairs({a.y,b.y}) do for _,z in ipairs({a.z,b.z}) do
  local p=native.pos+native.ang:Forward()*(x*native.scale.x)-native.ang:Right()*(y*native.scale.y)+native.ang:Up()*(z*native.scale.z)
  for _,k in ipairs({'x','y','z'}) do lo[k]=math.min(lo[k],p[k]);hi[k]=math.max(hi[k],p[k]) end
 end end end
 local span=hi-lo
 assert(math.abs(span.x-(axis==0 and PC.GateThickness or PC.GateWidth))<1e-7)
 assert(math.abs(span.y-(axis==0 and PC.GateWidth or PC.GateThickness))<1e-7)
 assert(math.abs(span.z-PC.GateBlockerHeight)<1e-7)
 local mid=(lo+hi)*0.5;assert(mid:DistToSqr(center)<1e-12,'off-center stock origin displaced gate')
end
checkBounds(0);checkBounds(1)
for _=1,100 do checkBounds(0) end
assert(allocations==1,'model allocated per gate/frame')
local prior=native;hooks.PostCleanupMap.LOD_GatePresentation();assert(not prior.valid)
thinY=true;checkBounds(0);checkBounds(1);assert(allocations==2)
prior=native;hooks.ShutDown.LOD_GatePresentation();assert(not prior.valid)
fail=true;assert(not G.Draw(center,0));local n=allocations
for _=1,30 do assert(not G.Draw(center,0)) end
assert(allocations==n,'failed allocation spins each frame')
now=13;fail=false;bad=true;assert(not G.Draw(center,0) and not native.valid)
now=16;bad=false;checkBounds(0)
-- Full production draw hooks: closed/moving/open gates and missing-model fallback.
local e=setmetatable({opened=false,started=0},{__index=ENT})
e.GetPos=function() return center end;e.GetGateAxis=function() return 1 end;e.GetGateIndex=function() return 1 end
e.GetOpened=function(self) return self.opened end;e.GetOpenedAt=function(self) return self.started end
e.GetNW2String=function(_,_,default) return default end
EyePos=function() return center end
local fallbacks=0
LOD.TexturedBox={GetIndustrialMaterial=function() error('gate requested floor material') end,
 Draw=function(_,_,_,_,_,mat,_,tile) assert(mat.path==GC.GateMaterial and tile==GC.GateTextureTile);fallbacks=fallbacks+1 end}
e:Initialize()
local draw=hooks.PostDrawOpaqueRenderables.LOD_DrawSecurityGates
local before=draws;draw();assert(draws==before+1 and G.Summary().stockBodies==1)
e.opened=true;e.started=now-PC.GateOpenSeconds*.5;draw();assert(draws==before+2)
e.started=now-PC.GateOpenSeconds;draw();assert(draws==before+2,'open gate body retained')
e.opened=false;G.Clear();fail=true;draw();assert(fallbacks==1 and G.Summary().fallbackBodies==1)
local count=fallbacks;draw(true);assert(fallbacks==count,'depth pass drew gate')
now=20;fail=false;draw();assert(G.Summary().stockBodies==1)
prior=native;dofile(root..'entities/entities/lod_gate/cl_init.lua');assert(not prior.valid,'Lua refresh leaked model')
print('CRATE_GATES_PASS: measured stock bounds; both thin/gate axes; off-center alignment; one shared model; cleanup/shutdown/refresh; failed allocation backoff; open animation; independent metal fallback; approved floor untouched')
