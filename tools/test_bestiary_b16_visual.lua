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
local beams,sprites,traces={},0,0
render={SetMaterial=noop,SetColorMaterial=noop,
    DrawSprite=function() sprites=sprites+1 end,
    DrawBeam=function(a,b,width,_,__,color) beams[#beams+1]={a=a,b=b,width=width,color=color} end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_enemy_roster.lua')
function mt:Angle() return {y=0,Right=function() return Vector(0,1,0) end} end
Angle=function() return {} end
local labels={}
TEXT_ALIGN_CENTER=1
cam={Start3D2D=noop,End3D2D=noop}
draw={SimpleText=function(text) labels[#labels+1]=text end}
local function actor(id)
    local e={pos=Vector(100,200,2),nw={LOD_Archetype=id,LOD_RosterAlive=true,LOD_RosterAttack=1,
        LOD_DisciplineMode=id=='halter' and 1 or 2,LOD_DisciplineOrigin=Vector(100,200,2),
        LOD_DisciplineAim=Vector(300,200,50),LOD_DisciplineReady=11.6,LOD_DisciplineUntil=11.8}}

    function e:GetPos() return self.pos end
    function e:WorldSpaceCenter() return self:GetPos()+Vector(0,0,32) end
    function e:GetNW2Int(key,default) local value=self.nw[key];if value==nil then return default end;return value end
    e.GetNW2Bool=e.GetNW2Int;e.GetNW2Float=e.GetNW2Int;e.GetNW2Vector=e.GetNW2Int
    e.GetNW2Entity=e.GetNW2Int;e.GetNW2String=e.GetNW2Int
    return e
end
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
 beams={};labels={};sprites=0;ENT.Draw(e);return #beams
end
local function signature()
 local result={}
 for _,b in ipairs(beams) do
  result[#result+1]=table.concat({b.a.x,b.a.y,b.a.z,b.b.x,b.b.y,b.b.z,b.width,b.color.r,b.color.g,b.color.b},',')
 end
 return table.concat(result,';')..table.concat(labels,';')
end
local full={}
for _,reduced in ipairs({false,true}) do
 low=reduced
 for mode=1,2 do
  local e=actor(mode==1 and 'halter' or 'pacer')
  local count=mode==1 and 14 or 8
  time=10
  assert(native(e)==count and sprites==0,'native semantic geometry without particles')
  assert(labels[1]==(mode==1 and 'STOP' or 'KEEP MOVING') and labels[2]=='PREPARE 1.6s','literal demand and countdown')
  if not reduced then full[mode]=signature() else assert(signature()==full[mode],'full and reduced semantics identical') end
  same(beams[1].a,Vector(100,200,50));same(beams[1].b,Vector(300,200,50))
  bar(count,48)
  assert(e.bounds.lo.x<=-500 and e.bounds.hi.x>=500 and e.bounds.lo.z<=-500 and e.bounds.hi.z>=500,'native bounds include full tether')
  time=10.8;native(e);bar(count,24)
  assert(labels[2]=='PREPARE 0.8s' and beams[2].width==2)
  time=11.2;native(e);bar(count,12)
  assert(labels[2]=='JUDGMENT 0.4s' and beams[2].width==4,'final interval changes text and stroke width')
  local judge=signature()
  local joined=actor(mode==1 and 'halter' or 'pacer');joined.nw=e.nw;native(joined)
  assert(signature()==judge,'late observer reconstructs judgment from snapshot')
  e.nw.LOD_DisciplineHero={WorldSpaceCenter=function() error('must not query live replacement life') end}
  native(e);assert(signature()==judge,'live identity never derives tether position')
  e.nw.LOD_DisciplineAim=Vector(310,200,50);native(e);same(beams[1].b,Vector(310,200,50))
  e.nw.LOD_DisciplineAim=Vector(300,200,50)
  time=11.6;assert(native(e)==count,'bounded release grace');bar(count,0)
  time=11.801;assert(native(e)==0 and #labels==0,'fixed expiry clears stale tell')
  time=9.9;assert(native(e)==0,'future snapshot rejected')
  time=10;e.nw.LOD_DisciplineUntil=math.huge;assert(native(e)==0,'nonfinite expiry')
  e.nw.LOD_DisciplineUntil=11.5;assert(native(e)==0,'inverted expiry')
  e.nw.LOD_DisciplineUntil=11.9;assert(native(e)==0,'excessive expiry')
  e.nw.LOD_DisciplineUntil=11.8;e.nw.LOD_DisciplineReady=0/0;assert(native(e)==0,'nonfinite deadline')
  e.nw.LOD_DisciplineReady=11.6;e.nw.LOD_DisciplineAim=Vector(900,0,0);assert(native(e)==0,'unbounded aim')
  e.nw.LOD_DisciplineAim=Vector(0/0,0,0);assert(native(e)==0,'nonfinite aim')
  e.nw.LOD_DisciplineAim=Vector(300,200,50);e.nw.LOD_DisciplineOrigin=Vector(math.huge,0,0);assert(native(e)==0,'nonfinite origin')
  e.nw.LOD_DisciplineOrigin=Vector(100,200,2);e.nw.LOD_RosterAlive=false;assert(native(e)==0,'source death')
  e.nw.LOD_RosterAlive=true;e.nw.LOD_DeathPulseStart=10;assert(native(e)==0,'native death suppresses tell')
  e.nw.LOD_DeathPulseStart=-1;e.nw.LOD_RosterAttack=0;assert(native(e)==0,'interruption')
  e.nw.LOD_RosterAttack=2;assert(native(e)==0,'wrong attack stage')
  e.nw.LOD_RosterAttack=1;eye=Vector(5000,0,0);assert(native(e)==0,'distance cull');eye=Vector(0,0,64)
  e.pos=Vector(104,200,2);assert(native(e)==count,'bounded source drift');same(beams[1].a,Vector(100,200,50))
  e.pos=Vector(104.01,200,2);assert(native(e)==0,'source displacement expires tell')
  e.pos=Vector(100,200,2);e.nw.LOD_DisciplineMode=0;assert(native(e)==0,'clear mode has no generic fallback')
  e.nw.LOD_DisciplineMode=3-mode;assert(native(e)==0,'identity mismatch')
 end
end
print('BESTIARY_B16_VISUAL_PASS: native Draw/bounds, literal STOP/KEEP MOVING and judgment/countdowns, snapshot-only tether, reduced parity, finite expiry/drift/culling/death; render/NW doubles, not Source QA')
