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
EyeAngles=function() return {y=0} end
Material=function() return {IsError=function() return false end} end;CreateMaterial=Material
render={SetMaterial=noop,DrawBox=noop,DrawWireframeBox=noop,CullMode=noop}
cam={Start3D2D=noop,End3D2D=noop};draw={RoundedBox=noop,SimpleText=noop};surface={SetDrawColor=noop,DrawRect=noop}
LOD={};dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_config.lua')
local slabs,bodies=0,0
LOD.TexturedBox={DrawSlab=function() slabs=slabs+1 end,Draw=function() bodies=bodies+1 end}
local function transmit(e,on) for _,fn in pairs(hooks.NotifyShouldTransmit) do fn(e,on) end end
for _,name in ipairs({'lod_static_box','lod_gate','lod_keycard','lod_jail_door'}) do
 ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/'..name..'/cl_init.lua')
 local e=setmetatable({valid=true,nw={}},{__index=ENT})
 -- NW2 accessors are native Entity methods, unlike generated datatable
 -- accessors that can briefly disappear during a full update.
 function e:GetNW2Bool(key,default) local v=self.nw[key];if v==nil then return default end;return v end
 function e:SetNW2Bool(key,value) self.nw[key]=value end
 e.GetNW2String,e.SetNW2String=e.GetNW2Bool,e.SetNW2Bool
 e.GetClass=function() return name end;e.GetPos=function() return Vector() end;e.GetAngles=function() return angle_zero end
 -- NotifyShouldTransmit may precede SetupDataTables. Exercise exactly the
 -- screenshot's missing GetBoxMins path and render callbacks in that frame.
 local function renderFrame()
  for _,fn in pairs(hooks.PostDrawOpaqueRenderables or {}) do fn() end
  for _,fn in pairs(hooks.PostDrawTranslucentRenderables or {}) do fn() end
  e:Draw()
 end
 local boundsRefreshes=0
 e.SetRenderBounds=function() boundsRefreshes=boundsRefreshes+1 end
 transmit(e,true);renderFrame()
 if name=='lod_static_box' then e:Think();assert(boundsRefreshes==0,'bounds refreshed before accessors') end
 e.GetBoxMins=function() return Vector(-100,-100,-32) end;e.GetBoxMaxs=function() return Vector(100,100,0) end
 e.GetBoxKind=function() return 1 end
 e.GetGateAxis=function() return 0 end;e.GetGateIndex=function() return 1 end;e.GetCardIndex=function() return 1 end
 e.GetOpened=function() return false end;e.GetOpenedAt=function() return 0 end;e.GetDoorAxis=function() return 0 end;e.EntIndex=function() return 1 end
 local function visible()
  if name=='lod_static_box' then local before=slabs;hooks.PostDrawOpaqueRenderables['LOD.DrawGeneratedStaticGeometry']();return slabs>before end
  if name=='lod_gate' then local before=bodies;hooks.PostDrawOpaqueRenderables.LOD_DrawSecurityGates();return bodies>before end
  return (name=='lod_keycard' and LOD.ClientKeycards[e] or name=='lod_jail_door' and LOD.ClientJailDoors[e])==true
 end
 renderFrame();assert(visible(),name..' early transmission did not recover when ready')
 -- Each missing accessor must be safe independently, including partial setup.
 local required={lod_static_box={'GetBoxMins','GetBoxMaxs','GetBoxKind'},lod_gate={'GetGateAxis','GetGateIndex','GetOpened','GetOpenedAt'},lod_keycard={'GetCardIndex'},lod_jail_door={'GetDoorAxis','GetOpened','GetOpenedAt'}}
 for _,key in ipairs(required[name]) do
  local getter=e[key];e[key]=nil
  transmit(e,true);renderFrame()
  if name=='lod_static_box' then
   local before=boundsRefreshes;e:Think();assert(boundsRefreshes==before,'incomplete bounds refreshed')
  end
  e[key]=getter;renderFrame();assert(visible(),name..' did not recover '..key)
 end
 e:Initialize();assert(visible(),name..' initial registration')
 if name=='lod_static_box' then
  e:SetNW2String('LOD_EventArchetype','false_floor')
  e:SetNW2Bool('LOD_GeometryHidden',true)
  renderFrame();assert(not visible(),'open false floor must skip the real slab draw hook')
  e:OnRemove(true);transmit(e,false);transmit(e,true)
  renderFrame();assert(not visible(),'full update cannot reveal a hidden open false floor')
  e:SetNW2Bool('LOD_GeometryHidden',false)
  renderFrame();assert(visible(),'rearmed false floor must redraw without Initialize or another transmission')
 end
 e:OnRemove(true);transmit(e,false)
 local getters={}
 for k,v in pairs(e) do if k:match('^Get') and not k:match('^GetNW2') and k~='GetClass' and k~='GetPos' and k~='GetAngles' then getters[k]=v;e[k]=nil end end
 transmit(e,true);renderFrame()
 for k,v in pairs(getters) do e[k]=v end
 renderFrame();assert(visible(),name..' failed to recover without another notification')
 if name=='lod_static_box' then
  local before=boundsRefreshes;e:Think();assert(boundsRefreshes==before+1,'deferred bounds not refreshed')
 end
 e.valid=false -- temporary absence lasting several seconds; no Initialize
 e.valid=true;transmit(e,true)
 assert(visible(),name..' lost after full update')
 -- Recovery also repairs the old unqualified OnRemove path / Lua refresh.
 e:OnRemove(false);assert(not visible(),name..' actual removal retained')
 transmit(e,true);assert(visible(),name..' transmission did not recover registry')
 e:OnRemove(false);e.valid=false;transmit(e,true)
 assert(not visible(),name..' stale invalid entity revived')
end
print('GEOMETRY_FULLUPDATE_PASS: floors, gates, keycards and jail recover without Initialize; false floor hidden state survives full update and rearms through native NW2 state; partial accessors, draw hooks, deferred bounds and genuine removal')
