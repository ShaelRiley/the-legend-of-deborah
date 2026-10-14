-- Native cargo lifecycle and elapsed-budget boundaries, without Source/FPS claims.
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V:DistToSqr(b) local d=self-b;return d.x*d.x+d.y*d.y+d.z*d.z end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function Angle(p,y,r) return {p=p,y=y,r=r} end
function IsValid(e) return type(e)=='table' and e.valid~=false end
function istable(t) return type(t)=='table' end
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
vector_origin=Vector();color_white=Color(255,255,255)
local root='gamemodes/legend_of_deborah/gamemode/lod/'
LOD={};dofile(root..'sh_config.lua');dofile(root..'sh_rng.lua')
surface={CreateFont=noop};local hooks,receivers,callbacks={},{},{}
hook={Add=function(_,id,fn) hooks[id]=fn end};concommand={Add=noop}
cvars={AddChangeCallback=function(name,fn) callbacks[name]=fn end}
local poolOn=true
function CreateClientConVar() return {GetBool=function() return poolOn end} end
local now,cost,created,removed,writes=0,.001,0,0,0
SysTime=function() return now end
function ClientsideModel(path)
 created=created+1;now=now+cost
 local e={path=path}
 function e:GetModel() return self.path end
 function e:Remove() assert(self.valid~=false);self.valid=false;removed=removed+1 end
 function e:SetPos(p) self.pos=p;now=now+cost end
 function e:SetAngles(a) self.ang=a end
 function e:SetNoDraw(v) self.hidden=v end
 function e:SetSubMaterial() self.submaterial=nil;writes=writes+1 end
 function e:SetMaterial(v) self.material=v end
 function e:SetColor(v) self.color=v end
 function e:SetSkin(v) self.skin=v end
 e.DrawShadow=noop
 function e:GetRenderBounds() return Vector(-10,-10,-10),Vector(10,10,10) end
 return e
end
local packet
net={Receive=function(id,fn) receivers[id]=fn end,ReadUInt=function() return packet and 2 or 0 end,ReadData=function() return '{}' end}
util={Decompress=function(v) return v end,JSONToTable=function() return packet end}
ErrorNoHalt=function(s) error(s) end
dofile(root..'cl_wall_visuals.lua')
local W=LOD.WallVisualsClient
local segments={};for x=1,20 do segments[#segments+1]={x,1,0,1} end
local function manifest(seed)
 packet={v=2,origin={0,0,0},seed=seed,segments=segments};receivers.LOD_WallVisuals()
end
local function settle()
 for i=1,200 do
  local before=now;hooks.LOD_BuildProceduralContainerWalls()
  -- A native operation cannot be preempted; allow ONE operation over the deadline.
  assert(now-before<=.0035+2*cost+.000001,'unbounded construction pass')
  if W.nextModel>#W.world and #W.retryQueue==0 then return end
 end
 error('model construction never completed')
end
manifest(7);settle();assert(created==40 and #W.world==40 and removed==0)
local owners={};for _,m in pairs(W.models) do owners[m]=true;m.submaterial='old';m.material='old' end
manifest(8);assert(#W.modelPool==40 and removed==0);settle()
assert(created==40 and #W.modelPool==0 and removed==0,'transition recreated cargo models')
for i,m in pairs(W.models) do
 assert(owners[m] and not m.hidden and m.submaterial==nil and m.material~='old')
 assert(m.pos==W.world[i].pos and m.ang==W.world[i].ang,'pooled cargo lost transform')
end
packet=nil;receivers.LOD_WallVisuals();assert(#W.modelPool==40)
poolOn=false;callbacks.lod_container_model_pool();assert(#W.modelPool==0 and removed==40)
poolOn=true;cost=0;manifest(9);hooks.LOD_BuildProceduralContainerWalls();assert(W.nextModel==41)
-- Count ceiling remains finite even when the native timer has zero resolution.
segments={};for x=1,21 do for y=1,3 do segments[#segments+1]={x,y,0,1} end end
manifest(10);hooks.LOD_BuildProceduralContainerWalls();assert(W.nextModel==49)
settle();hooks.LOD_WallVisualsMapCleanup();assert(#W.modelPool==0 and next(W.models)==nil)
segments={}
for z=0,2 do for x=1,21 do for y=1,21 do segments[#segments+1]={x,y,z,1} end end end
manifest(11);settle();packet=nil;receivers.LOD_WallVisuals()
assert(#W.modelPool==2048 and created-removed==2048,'idle model pool ceiling escaped')
hooks.LOD_WallVisualsClientCleanup();assert(created==removed,'shutdown retained client models')
print('CONSULT_WALL_POOL_PASS 40 models reused without creation; exact transforms/material reset; 48-count and 3.5ms admission; disable/map/shutdown cleanup; native FPS unmeasured')
