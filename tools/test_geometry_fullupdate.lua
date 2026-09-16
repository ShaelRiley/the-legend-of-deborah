-- Production entity registries and draw hooks across Source's full-update
-- removal/reappearance sequence, where Initialize is not called again.
local noop=function() end
local hooks={};hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end}
include=noop;concommand={Add=noop}
IsValid=function(e) return type(e)=='table' and e.valid~=false end
CurTime=function() return 10 end
Color=function(...) return {...} end
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
local V={};V.__index=V
Vector=function(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V:DistToSqr(b) return (self.x-b.x)^2+(self.y-b.y)^2+(self.z-b.z)^2 end
angle_zero={};Angle=function() return {} end
EyePos=function() return Vector() end
Material=function() return {IsError=function() return false end} end;CreateMaterial=Material
render={SetMaterial=noop,DrawBox=noop,DrawWireframeBox=noop,CullMode=noop}
cam={Start3D2D=noop,End3D2D=noop};draw={RoundedBox=noop,SimpleText=noop};surface={SetDrawColor=noop,DrawRect=noop}
LOD={};dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_config.lua')
local slabs,bodies=0,0
LOD.TexturedBox={DrawSlab=function() slabs=slabs+1 end,Draw=function() bodies=bodies+1 end}
local function transmit(e,on) for _,fn in pairs(hooks.NotifyShouldTransmit) do fn(e,on) end end
for _,name in ipairs({'lod_static_box','lod_gate','lod_keycard','lod_jail_door'}) do
 ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/'..name..'/cl_init.lua')
 local e=setmetatable({valid=true},{__index=ENT})
 e.GetClass=function() return name end;e.GetPos=function() return Vector() end;e.GetAngles=function() return angle_zero end
 e.GetBoxMins=function() return Vector(-100,-100,-32) end;e.GetBoxMaxs=function() return Vector(100,100,0) end
 e.GetBoxKind=function() return 1 end;e.SetRenderBounds=noop
 e.GetGateAxis=function() return 0 end;e.GetGateIndex=function() return 1 end;e.GetCardIndex=function() return 1 end
 e.GetOpened=function() return false end;e.EntIndex=function() return 1 end
 local function visible()
  if name=='lod_static_box' then local before=slabs;hooks.PostDrawOpaqueRenderables['LOD.DrawGeneratedStaticGeometry']();return slabs>before end
  if name=='lod_gate' then local before=bodies;hooks.PostDrawOpaqueRenderables.LOD_DrawSecurityGates();return bodies>before end
  return (name=='lod_keycard' and LOD.ClientKeycards[e] or name=='lod_jail_door' and LOD.ClientJailDoors[e])==true
 end
 e:Initialize();assert(visible(),name..' initial registration')
 e:OnRemove(true);transmit(e,false)
 e.valid=false -- temporary absence lasting several seconds; no Initialize
 e.valid=true;transmit(e,true)
 assert(visible(),name..' lost after full update')
 -- Recovery also repairs the old unqualified OnRemove path / Lua refresh.
 e:OnRemove(false);assert(not visible(),name..' actual removal retained')
 transmit(e,true);assert(visible(),name..' transmission did not recover registry')
 e:OnRemove(false);e.valid=false;transmit(e,true)
 assert(not visible(),name..' stale invalid entity revived')
end
print('GEOMETRY_FULLUPDATE_PASS: floors, gates, keycards and jail recover without Initialize; real draw hooks; genuine removal stays removed')
