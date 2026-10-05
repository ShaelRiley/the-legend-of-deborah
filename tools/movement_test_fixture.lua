-- Engine boundaries for the actual shared and predicted movement authorities.
local E={now=10,callbacks={},hooks={},commands={},wire={},read={},stops=0,plays=0,cv={},announced={},frame=1/60,volumeWrites=0}
function CurTime() return E.now end;SysTime=CurTime
function FrameTime() return .1 end
function RealFrameTime() return E.frame end
engine={AbsoluteFrameTime=RealFrameTime,TickInterval=function() return .015 end}
function IsValid(x) return type(x)=='table' and x.valid~=false end
function isstring(x) return type(x)=='string' end
function Color(...) return {...} end
function math.Clamp(n,a,b) return math.min(b,math.max(a,n)) end
function math.Approach(n,t,s) return n<t and math.min(t,n+s) or math.max(t,n-s) end
function table.Copy(t) if type(t)~='table' then return t end local n={};for k,v in pairs(t) do n[k]=table.Copy(v) end;return n end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
function V.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function V.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:DistToSqr(b) local d=self-b;return d.x*d.x+d.y*d.y+d.z*d.z end
FCVAR_ARCHIVE,FCVAR_REPLICATED,FCVAR_NOTIFY=1,2,4
IN_SPEED,MOVETYPE_WALK=131072,2
bit={bor=function(a,b,c) return a|b|(c or 0) end}
local function cv(name,value)
 E.cv[name]=E.cv[name] or {value=tostring(value)};local c=E.cv[name]
 function c:GetBool() return self.value~='0' end
 function c:GetFloat() return tonumber(self.value) end
 function c:GetInt() return tonumber(self.value) end
 return c
end
CreateConVar=cv;CreateClientConVar=cv;GetConVar=function(name) return E.cv[name] end
cvars={AddChangeCallback=function(name,fn,id) E.callbacks[name]=E.callbacks[name] or {};E.callbacks[name][id]=fn end}
function E.set(name,v) E.cv[name].value=tostring(v);for _,f in pairs(E.callbacks[name] or {}) do f() end end
hook={Add=function(event,id,fn) E.hooks[id]=fn end}
concommand={Add=function(name,fn) E.commands[name]=fn end}
file={Read=function() end,CreateDir=function() end,Write=function() end}
local json={}
LOD={Config={}}
E.checks=0
function E.check(ok,msg) E.checks=E.checks+1;assert(ok,msg) end
return E
