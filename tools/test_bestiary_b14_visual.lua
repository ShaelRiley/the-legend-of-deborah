-- Runs the real client Draw seam; render/NW2/clock are doubles, not Source QA.
local noop=function() end
local mt={};mt.__index=mt
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},mt) end
mt.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
mt.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
mt.__mul=function(a,n) return Vector(a.x*n,a.y*n,a.z*n) end
function mt:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function mt:DistToSqr(b) return (self-b):LengthSqr() end
function mt:GetNormalized() local n=math.sqrt(self:LengthSqr());return n>0 and self*(1/n) or Vector() end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
math.Clamp=function(n,a,b) return math.max(a,math.min(b,n)) end
local time,low=10,false
CurTime=function() return time end
local eye=Vector(0,0,64);EyePos=function() return eye end
Material=function(name) return name end
GetConVar=function() return {GetBool=function() return low end} end
IsValid=function(x) return type(x)=='table' and not x.removed end
local hooks={};hook={Add=function(_,id,fn) hooks[id]=fn end}
net={Receive=noop}
LOD={}
local beams,sprites={},0
render={SetMaterial=noop,SetColorMaterial=noop,
    DrawSprite=function() sprites=sprites+1 end,
    DrawBeam=function(a,b,width,_,__,color) beams[#beams+1]={a=a,b=b,width=width,color=color} end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_enemy_roster.lua')
function mt:Angle() return {Right=function() return Vector(0,1,0) end} end
local function actor(id)
    local e={pos=Vector(100,200,2),nw={LOD_Archetype=id,LOD_RosterAlive=true,LOD_RosterAttack=1,
        LOD_PerceptionMode=id=='listener' and 1 or 2,LOD_PerceptionStart=Vector(100,200,2),
        LOD_PerceptionGoal=Vector(228,200,2),LOD_PerceptionReady=10.8,LOD_PerceptionUntil=12.2}}

    function e:GetPos() return self.pos end
    function e:WorldSpaceCenter() return self:GetPos()+Vector(0,0,32) end
    function e:GetNW2Int(key,default) local value=self.nw[key];if value==nil then return default end;return value end
    e.GetNW2Bool=e.GetNW2Int;e.GetNW2Float=e.GetNW2Int;e.GetNW2Vector=e.GetNW2Int
    e.GetNW2Entity=e.GetNW2Int;e.GetNW2String=e.GetNW2Int
    return e
end
local function draw(e) beams={};sprites=0;LOD.EnemyRosterVisual:Draw(e,1);return #beams end
local function near(a,b) assert(math.abs(a-b)<.0001,tostring(a)..' != '..tostring(b)) end
local function same(a,b) near(a.x,b.x);near(a.y,b.y);near(a.z,b.z) end
local function bar(index,length) near(math.sqrt(beams[index].a:DistToSqr(beams[index].b)),length) end
NULL={removed=true}
ENT={};include=noop;concommand={Add=noop};util={GetModelBounds=function() return Vector(-16,-16,0),Vector(16,16,72) end}
Matrix=function() return {Scale=noop,Rotate=noop,SetTranslation=noop} end
render.SuppressEngineLighting=noop;render.MaterialOverride=noop;render.SetColorModulation=noop;render.SetBlend=noop
LOD.RuntimeReceipts={}
LOD.EnemyDeathPulse=function() return 1 end
dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/cl_init.lua')
local function native(e)
 e.GetModel=function() return 'models/antlion.mdl' end
 e.EnableMatrix=noop;e.DrawModel=noop
 e.SetRenderBounds=function(_,lo,hi) e.bounds={lo=lo,hi=hi} end
 beams={};sprites=0;ENT.Draw(e);return #beams
end
for _,reduced in ipairs({false,true}) do
 low=reduced;time=10
 for mode=1,3 do
  local e=actor(mode==1 and 'siphoner' or 'accumulator')
  local duration=mode==3 and 2 or 1.25
  e.nw.LOD_ResourceMode=mode;e.nw.LOD_ResourceOrigin=Vector(100,200,2)
  e.nw.LOD_ResourceAim=mode==3 and Vector(100,200,2) or Vector(300,200,2)
  e.nw.LOD_ResourceReady=10+duration;e.nw.LOD_ResourceUntil=10+duration+.2
  local count=mode==1 and 32 or (mode==2 and 29 or 8)
  time=10;assert(native(e)==count and sprites==0,'native semantic glyph/countdown survives reduced effects')
  bar(count,48)
  if mode~=3 then
   same(beams[1].a,Vector(364,200,5));same(beams[25].a,Vector(100,200,50));same(beams[25].b,Vector(300,200,5))
  else
   for _,b in ipairs(beams) do assert(b.a.z>=58 and b.b.z>=58,'self recharge must not resemble a damaging ground circle') end
  end
  assert(beams[1].color.r==(mode==1 and 185 or 235) and beams[1].color.g==(mode==1 and 115 or 205))
  assert(e.bounds.lo.x<=-428 and e.bounds.hi.x>=428 and e.bounds.lo.z<=-364 and e.bounds.hi.z>=412,'native bounds include mark and recharge glyph')
  time=10+duration/2;native(e);bar(count,24)
  local first=beams[1].a;e.pos=Vector(103,200,2);native(e);same(beams[1].a,first)
  local joined=actor(mode==1 and 'siphoner' or 'accumulator');joined.nw=e.nw
  native(joined);bar(count,24);same(beams[1].a,first)
  time=10+duration+.2;assert(native(e)==0,'fixed deadline expires stale snapshot')
  time=10;e.nw.LOD_ResourceUntil=math.huge;assert(native(e)==0,'infinite expiry rejected')
  e.nw.LOD_ResourceUntil=10+duration+.2;e.nw.LOD_ResourceReady=0/0;assert(native(e)==0,'nonfinite ready rejected')
  e.nw.LOD_ResourceReady=10+duration;e.nw.LOD_ResourceAim=Vector(1000,300,2)
  assert(native(e)==0,'unbounded geometry rejected before rendering')
  e.nw.LOD_ResourceAim=Vector(0/0,0,0);assert(native(e)==0,'nonfinite geometry rejected')
  e.nw.LOD_ResourceAim=mode==3 and Vector(100,200,2) or Vector(300,200,2)
  e.nw.LOD_RosterAlive=false;assert(native(e)==0,'source death clears resource warning')
  e.nw.LOD_RosterAlive=true;e.nw.LOD_DeathPulseStart=10;assert(native(e)==0,'native death draw suppresses warnings')
  e.nw.LOD_DeathPulseStart=-1;e.nw.LOD_RosterAttack=0;assert(native(e)==0,'interruption clears tell')
  e.nw.LOD_RosterAttack=2;assert(native(e)==0,'wrong stage cannot retain resource tell')
  e.nw.LOD_RosterAttack=1;eye=Vector(5000,0,0);assert(native(e)==0,'distance culling');eye=Vector(0,0,64)
  e.pos=Vector(105,200,2);assert(native(e)==0,'source displacement expires frozen commitment')
  e.pos=Vector(100,200,2);e.nw.LOD_ResourceMode=0;assert(native(e)==0,'cleared mode has no generic fallback')
  e.nw.LOD_ResourceMode=mode==1 and 2 or 1;assert(native(e)==0,'mismatched resource identity rejected')
 end
end
print('BESTIARY_B14_VISUAL_PASS: native Draw/culling, distinct full/reduced drain/attack/recharge glyphs, frozen marks/countdowns, bounded finite expiry, late snapshots, death/interruption/distance cleanup')
