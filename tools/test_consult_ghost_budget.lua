-- Real afterimage receiver/render hook: stress the global cosmetic draw ceiling.
local noop=function() end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function LerpVector(t,a,b) return a+(b-a)*t end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function IsValid(e) return type(e)=='table' and e.valid~=false end
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
vector_origin=Vector();angle_zero={};RENDERGROUP_OTHER=1
local now,frame,low,slow=0,1,false,false
CurTime=function() return now end;FrameNumber=function() return frame end
FrameTime=function() return slow and .03 or .016 end
GetConVar=function() return {GetBool=function() return low end} end
Material=function() return {} end
LocalPlayer=function() return {EyePos=function() return vector_origin end} end
local hooks,receive={},{ }
hook={Add=function(_,id,fn) hooks[id]=fn end}
local packet,index
local function read() index=index+1;return packet[index] end
net={Receive=function(id,fn) receive[id]=fn end,ReadEntity=read,ReadVector=read,ReadBool=read,ReadString=read,ReadAngle=read}
local live,draws=0,0
function ClientsideModel()
 live=live+1
 local g=setmetatable({}, {__index=function() return noop end})
 function g:DrawModel() draws=draws+1 end
 function g:Remove() assert(self.valid~=false);self.valid=false;live=live-1 end
 return g
end
render={MaterialOverride=noop,SetColorModulation=noop,SetBlend=noop,SetMaterial=noop,DrawBeam=noop}
LOD={};dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_pushback_fx.lua')
local function send()
 packet={{valid=false},Vector(),Vector(500,0,0),Vector(),Vector(),false,'test','stock-model',angle_zero}
 index=0;receive.LOD_PushbackFX()
end
for i=1,12 do send() end
local paint=hooks.LOD_PushbackMotionTrails
paint(true);paint(false,true);assert(draws==0,'ghosts drawn in depth/sky pass')
paint();assert(draws==12 and LOD.PushbackFX.ghostDraws<=16)
paint();assert(draws<=16,'second view escaped per-frame cap')
frame=2;draws=0;low=true;paint();assert(draws==8 and LOD.PushbackFX.ghostDraws==8)
frame=3;draws=0;low=false;slow=true;paint();assert(draws==8,'slow-frame cosmetic shedding missing')
now=1;frame=4;paint();assert(#LOD.PushbackFX.trails==0 and live<=64,'expiry/pool ceiling broken')
hooks.LOD_PushbackGhostCacheCleanup();assert(live==0,'ghost pool leaked')
print('CONSULT_GHOST_BUDGET_PASS 12 simultaneous throws retain full-path sparse samples; global 16/8 draw ceiling across views; depth/sky suppression; expiry and native pool cleanup; native FPS unmeasured')
