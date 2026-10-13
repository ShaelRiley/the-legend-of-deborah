-- Execute the real stock-map entities at explicit native model/physics boundaries.
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self.x^2+self.y^2+self.z^2 end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:Cross(b) return Vector(self.y*b.z-self.z*b.y,self.z*b.x-self.x*b.z,self.x*b.y-self.y*b.x) end
local A={};A.__index=A
function Angle(p,y,r)
 local cp,sp,cy,sy,cr,sr=math.cos(math.rad(p)),math.sin(math.rad(p)),math.cos(math.rad(y)),math.sin(math.rad(y)),math.cos(math.rad(r)),math.sin(math.rad(r))
 return setmetatable({p=p,y=y,r=r,f=Vector(cp*cy,cp*sy,-sp),
  right=Vector(-sr*sp*cy+cr*sy,-sr*sp*sy-cr*cy,-sr*cp),
  up=Vector(cr*sp*cy+sr*sy,cr*sp*sy-sr*cy,cr*cp)},A)
end
function V:Rotate(a)
 local v=a.f*self.x+a.right*(-self.y)+a.up*self.z
 self.x,self.y,self.z=v.x,v.y,v.z
end
function V:Angle() return Angle(math.deg(math.atan(-self.z,math.sqrt(self.x^2+self.y^2))),math.deg(math.atan(self.y,self.x)),0) end
function A:Right() return self.right end
function A:Up() return self.up end
function A:RotateAroundAxis(axis,degrees)
 local co,si=math.cos(math.rad(degrees)),math.sin(math.rad(degrees))
 local function rotate(v) return v*co+axis:Cross(v)*si+axis*(axis:Dot(v)*(1-co)) end
 self.f,self.right,self.up=rotate(self.f),rotate(self.right),rotate(self.up)
end
local noop=function() end
MOVETYPE_NONE,SOLID_NONE,SOLID_BBOX,COLLISION_GROUP_NONE,TRANSMIT_ALWAYS=0,0,2,0,2
RENDERGROUP_OPAQUE,RENDERGROUP_BOTH=0,2
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
IsValid=function(e) return type(e)=='table' and not e.removed end
local now,players,checkCount=0,{},0
CurTime=function() return now end;player={GetAll=function() return players end}
LOD={Config={Maze={CellSize=384},Progression={KeycardHeight=40}},MinimapServer={CollectFloorMap=function() checkCount=checkCount+1;return false end}}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_progression_props.lua')
local fallback=false
util={IsValidModel=function() return not fallback end}
AddCSLuaFile=noop
local root='gamemodes/legend_of_deborah/entities/entities/'
local classes,initializers={},{}
for _,name in ipairs({'lod_floor_map_pedestal','lod_floor_map'}) do
 ENT={}
 include=function(leaf) dofile(root..name..'/'..leaf) end
 dofile(root..name..'/init.lua')
 classes[name]=ENT;initializers[name]=ENT.Initialize
end
local native={}
function native:NetworkVar(kind,_,name)
 self['Get'..name]=function(s) return s['net_'..name] or (kind=='Vector' and Vector() or 0) end
 self['Set'..name]=function(s,v) s['net_'..name]=v end
end
function native:SetModel(m) self.model=m end
function native:GetModel() return self.model end
function native:GetModelBounds()
 if self.model=='models/hunter/blocks/cube05x05x05.mdl' then return Vector(-12,-12,-12),Vector(12,12,12) end
 return Vector(-8,-6,-.75),Vector(8,6,.75)
end
function native:SetPos(p) self.pos=p end
function native:GetPos() return self.pos or Vector() end
function native:SetAngles(a) self.angles=a end
function native:GetAngles() return self.angles or Angle(0,0,0) end
function native:SetMoveType(v) self.move=v end
function native:SetSolid(v) self.solid=v end
function native:SetCollisionBounds(lo,hi) self.lo,self.hi=lo,hi end
function native:OBBMaxs() return self.hi end
function native:SetCollisionGroup(v) self.collisionGroup=v end
function native:SetMaterial(v) self.material=v end
function native:GetMaterial() return self.material or '' end
function native:SetColor(c) self.color=c end
function native:GetColor() return self.color or Color(255,255,255) end
function native:DrawShadow() end
function native:SetNW2Entity(k,v) self[k]=v end
function native:GetNW2Entity(k) return self[k] end
function native:Spawn() initializers[self.class](self) end
function native:Activate() end
function native:DeleteOnRemove(e) self.children=self.children or {};self.children[#self.children+1]=e end
function native:Remove()
 if self.removed then return end
 self.removed=true
 for _,e in ipairs(self.children or {}) do e:Remove() end
 if self.OnRemove then self:OnRemove() end
end
function native:NextThink(v) self.nextThink=v end
function native:SetRenderBounds(lo,hi) self.renderLo,self.renderHi=lo,hi end
function native:SetModelScale() error('stock props must not introduce scaled-anim collision drift') end
function native:EntIndex() return self.index end
function native:DrawModel() self.draws=(self.draws or 0)+1 end
local created,fail={},{value=false}
local function make(name)
 local e=setmetatable({class=name,index=#created+1}, {__index=function(_,k) return classes[name] and classes[name][k] or native[k] end})
 if e.SetupDataTables then e:SetupDataTables() end
 created[#created+1]=e;return e
end
ents={Create=function(name) return not fail.value and make(name) or nil end}
local function pickup(pos)
 local e=make('lod_floor_map');e:SetPos(pos);e:SetFloorIndex(1);e:Spawn();return e
end
local start=Vector(1000,-800,424)
local map=pickup(start);local pedestal=map.LODFloorMapPedestal
assert(map:GetModel()=='models/props_lab/binderblue.mdl' and IsValid(pedestal),'map must be a stock book on a real pedestal')
assert(pedestal:GetModel()=='models/hunter/blocks/cube05x05x05.mdl')
assert(map.solid==SOLID_NONE and pedestal.solid==SOLID_BBOX and map.move==MOVETYPE_NONE and pedestal.move==MOVETYPE_NONE)
assert(map:UpdateTransmitState()==TRANSMIT_ALWAYS and pedestal:UpdateTransmitState()==TRANSMIT_ALWAYS)
local anchor=map:GetPickupPosition()
assert(anchor.x==1072 and anchor.y==-728 and anchor.z==424,'touch anchor/pedestal side placement')
assert(pedestal:GetPos().z+pedestal.lo.z==384,'pedestal floats or sinks into the floor')
assert(pedestal.hi.z-pedestal.lo.z<32,'stock pedestal is not low')
local lo,hi=LOD.ProgressionProps:RotatedBounds(map:GetModelBounds(),select(2,map:GetModelBounds()),map:GetAngles())
assert(math.abs(lo.z+map:GetPos().z-(pedestal:GetPos().z+pedestal.hi.z+2))<.001,'book is not atop its pedestal')
assert(hi.z-lo.z>hi.x-lo.x,'book is edge-on flat instead of upright')
assert(math.abs(pedestal:GetPos().x-start.x)-pedestal.hi.x>32,'pedestal occupies the arrival center')
assert(map:GetNW2Entity('LOD_MapPedestal')==pedestal)
players={{},{}};map:Think();assert(checkCount==2);map:Think();assert(checkCount==2,'pickup polling duplicated')
now=.09;map:Think();assert(checkCount==4)
fallback=true;local alternate=pickup(start);assert(alternate:GetModel()=='models/props_lab/clipboard.mdl');fallback=false
map:Remove();assert(pedestal.removed,'collection/reset leaves an orphan pedestal')
fail.value=true;local broken=make('lod_floor_map');broken:SetPos(start);broken:Spawn();assert(broken.removed,'failed prop creation left an invisible map');fail.value=false
print('FLOOR_MAP_PROPS_PASS: actual book/pedestal entities; upright native models; solid stationary bounds; unscaled low block; clear arrival center; canonical touch anchor/cadence; fallback; both-floor transmission; owned teardown')
return {classes=classes,native=native,pickup=pickup,start=start,created=created,initializers=initializers,make=make}

