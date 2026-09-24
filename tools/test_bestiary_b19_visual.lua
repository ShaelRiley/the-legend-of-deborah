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
local function actor(id,mode,phase)
 local e={pos=Vector(100,200,2),nw={LOD_Archetype=id,LOD_RosterAlive=true,LOD_RosterAttack=1,
  LOD_LinkMode=mode,LOD_LinkPhase=phase,LOD_LinkOrigin=Vector(100,200,2),
  LOD_LinkWard=mode==2 and Vector(300,200,2) or Vector(300,200,50),
  LOD_LinkAim=Vector(400,200,50),LOD_LinkStarted=10,
  LOD_LinkReady=mode==2 and 11.2 or 11.4,LOD_LinkUntil=mode==2 and 13.4 or 11.6}}
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
local full,monochrome={},{}
local function geometry()
 local result={}
 for _,b in ipairs(beams) do result[#result+1]=table.concat({b.a.x,b.a.y,b.a.z,b.b.x,b.b.y,b.b.z,b.width},",") end
 return table.concat(result,";")
end
local cases={{'relay',1,1},{'lacemaker',2,1},{'lacemaker',2,2},{'relay',3,1},{'lacemaker',3,1}}
local function bounds(e)
 for _,b in ipairs(beams) do for _,p in ipairs({b.a,b.b}) do
  local offset=p-e.pos
  for _,axis in ipairs({'x','y','z'}) do assert(offset[axis]>=e.bounds.lo[axis] and offset[axis]<=e.bounds.hi[axis],'native bounds contain every endpoint') end
 end end
end
for _,reduced in ipairs({false,true}) do
 low=reduced
 for index,case in ipairs(cases) do
  local id,mode,phase=table.unpack(case);local e=actor(id,mode,phase)
  time=phase==2 and 11.2 or 10
  assert(native(e)>5 and sprites==0,'native Draw emits semantic geometry only')
  local count=#beams;bounds(e);bar(count,48)
  local instruction=mode==1 and 'RELAY SHOT / BREAK LINK' or (mode==2 and 'LEAVE RIBBON / BREAK LINK' or 'SOURCE SHOT / SIDESTEP')
  assert(labels[#labels-1]==instruction,'literal counterplay')
  local duration=phase==2 and 2 or (mode==2 and 1.2 or 1.4)
  assert(labels[#labels]==string.format('%s %.1fs',phase==2 and 'ACTIVE' or 'PREPARE',duration),'correct phase countdown')
  if mode==1 then
   same(beams[1].a,e.nw.LOD_LinkOrigin+Vector(0,0,48));same(beams[1].b,e.nw.LOD_LinkWard)
   same(beams[2].a,e.nw.LOD_LinkWard);same(beams[2].b,e.nw.LOD_LinkAim)
   assert(labels[1]=='SHOT ORIGIN','remote muzzle is identified')
  elseif mode==2 then
   same(beams[1].a,Vector(100,218,5));same(beams[1].b,Vector(300,218,5))
   same(beams[2].a,Vector(100,182,5));same(beams[2].b,Vector(300,182,5))
   near(beams[51].width,phase==2 and 4 or 1)
   assert(labels[1]=='MOVING END','ordinary ally motion is identified')
  else same(beams[1].a,Vector(100,200,50));same(beams[1].b,e.nw.LOD_LinkAim) end
  if not reduced then full[index]=signature();monochrome[index]=geometry() else assert(signature()==full[index],'full/reduced semantic parity') end
  local original=signature();local joined=actor(id,mode,phase);joined.nw=e.nw
  native(joined);assert(signature()==original,'late observer same snapshot')
  e.nw.LOD_LinkHero={GetPos=function() error('no Hero tracking') end}
  e.nw.LOD_LinkAlly={WorldSpaceCenter=function() error('no client ward tracking') end}
  native(e);assert(signature()==original,'no live entity queries')
  time=time+duration/2;native(e);bar(count,24)
  if phase==2 then
   time=e.nw.LOD_LinkReady+1.999;assert(native(e)>0,'last active instant')
   time=e.nw.LOD_LinkReady+2;assert(native(e)==0,'active ribbon ends before service grace')
  end
  time=e.nw.LOD_LinkUntil;assert(native(e)==0 and #labels==0,'expired snapshot')
  time=phase==2 and 11.2 or 10
  for _,field in ipairs({'Started','Ready','Until'}) do
   local key='LOD_Link'..field;local saved=e.nw[key]
   for _,bad in ipairs({0/0,math.huge,saved+1}) do e.nw[key]=bad;assert(native(e)==0,'invalid timeline '..field) end
   e.nw[key]=saved
  end
  for _,field in ipairs(mode==3 and {'Origin','Aim'} or {'Origin','Aim','Ward'}) do
   local key='LOD_Link'..field;local saved=e.nw[key]
   e.nw[key]=Vector(0/0,0,0);assert(native(e)==0,'nonfinite '..field)
   e.nw[key]=Vector(9000,0,0);assert(native(e)==0,'excess range '..field);e.nw[key]=saved
  end
  if mode==2 then
   local saved=e.nw.LOD_LinkWard;e.nw.LOD_LinkWard=e.nw.LOD_LinkOrigin
   assert(native(e)==0,'degenerate ribbon');e.nw.LOD_LinkWard=saved
   e.nw.LOD_LinkWard=Vector(260,280,2);assert(native(e)==count,'updated moving endpoint renders')
   same(beams[1].b,e.nw.LOD_LinkWard+Vector(0,0,3)+Vector(-80,160,0)*(18/math.sqrt(32000)))
   assert(signature()~=original,'moving ribbon updates only published endpoint');e.nw.LOD_LinkWard=saved
  end
  e.nw.LOD_RosterAlive=false;assert(native(e)==0,'death');e.nw.LOD_RosterAlive=true
  e.nw.LOD_DeathPulseStart=10;assert(native(e)==0,'native death pulse');e.nw.LOD_DeathPulseStart=-1
  e.nw.LOD_RosterAttack=0;assert(native(e)==0,'interruption');e.nw.LOD_RosterAttack=2;assert(native(e)==0,'wrong stage');e.nw.LOD_RosterAttack=1
  eye=e.pos+Vector(2400,0,0);assert(native(e)==count,'cull boundary');eye=e.pos+Vector(2400.01,0,0);assert(native(e)==0,'distance cull');eye=Vector(0,0,64)
  e.pos=Vector(104,200,2);assert(native(e)==count,'source drift boundary');e.pos=Vector(104.01,200,2);assert(native(e)==0,'source drift outside boundary');e.pos=Vector(100,200,2)
  e.nw.LOD_LinkMode=0;assert(native(e)==0,'cleared mode never falls back to generic warning')
  e.nw.LOD_LinkMode=mode;e.nw.LOD_LinkPhase=3;assert(native(e)==0,'invalid phase')
  time=9.99;e.nw.LOD_LinkPhase=phase;assert(native(e)==0,'future commitment')
 end
end
-- Monochrome geometry still distinguishes the two linked modes from fallback.
assert(monochrome[1]~=monochrome[2] and monochrome[1]~=monochrome[4] and monochrome[2]~=monochrome[5])
for _,mode in ipairs({1,2,3}) do
 time=10;local e=actor(mode==1 and 'relay' or 'lacemaker',mode,1)
 e.nw.LOD_LinkAim=e.pos+Vector(432,0,0)
 e.nw.LOD_LinkWard=e.pos+Vector(mode==2 and 244 or 312,0,0)
 e.pos=e.pos-Vector(4,0,0)
 assert(native(e)>0,'maximum extents and opposite drift render');bounds(e)
 e.nw.LOD_LinkAim=e.nw.LOD_LinkAim+Vector(.01,0,0);assert(native(e)==0,'outside aim bound')
end
local e=actor('relay',2,1);assert(native(e)==0,'identity-mode mismatch')
e=actor('lacemaker',2,1);time=11.401;assert(native(e)==0,'stale prep snapshot')
e.nw.LOD_LinkPhase=2;time=11.199;assert(native(e)==0,'premature active snapshot')
-- NW2 uses float32 timestamps; a day-old server must still show its warnings.
local function float32(n) return string.unpack('f',string.pack('f',n)) end
for _,case in ipairs(cases) do
 local id,mode,phase=table.unpack(case);local e=actor(id,mode,phase)
 for _,field in ipairs({'Started','Ready','Until'}) do local key='LOD_Link'..field;e.nw[key]=float32(e.nw[key]+86400) end
 time=phase==2 and e.nw.LOD_LinkReady or e.nw.LOD_LinkStarted
 assert(native(e)>0,'quantized long-uptime timestamps remain readable')
end
print('BESTIARY_B19_VISUAL_PASS: actual native Draw; relay remote shot, moving radius18 ribbon and source fallback; labels, countdowns, full/reduced/late observer parity, native bounds, malformed timelines/vectors, identity, expiry, death, interruption, drift and culling. Render/NW doubles; not Source QA.')
