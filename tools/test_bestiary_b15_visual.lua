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
function mt:Angle() return {Right=function() return Vector(0,1,0) end} end
local function actor(id)
    local e={pos=Vector(100,200,2),nw={LOD_Archetype=id,LOD_RosterAlive=true,LOD_RosterAttack=1,
        LOD_CrossfireMode=id=='fusilier' and 1 or 2,LOD_CrossfireOrigin=Vector(100,200,2),
        LOD_CrossfireAim=Vector(300,200,id=='fusilier' and 50 or 2),
        LOD_CrossfireReady=id=='fusilier' and 11.25 or 11.6,
        LOD_CrossfireUntil=id=='fusilier' and 11.45 or 11.8}}

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
 beams={};sprites=0;ENT.Draw(e);return #beams
end
MASK_SHOT=123
local obstruction
util.TraceHull=function(args)
 traces=traces+1
 same(args.start,Vector(100,200,50));same(args.endpos,Vector(300,200,50))
 same(args.mins,Vector(-4,-4,-4));same(args.maxs,Vector(4,4,4))
 assert(args.mask==MASK_SHOT and args.filter.nw.LOD_Archetype=='fusilier')
 return obstruction or {Hit=false}
end
local function signature()
 local result={}
 for _,b in ipairs(beams) do
  result[#result+1]=table.concat({b.a.x,b.a.y,b.a.z,b.b.x,b.b.y,b.b.z,b.width,b.color.r,b.color.g,b.color.b},',')
 end
 return table.concat(result,';')
end
local full={}
for _,reduced in ipairs({false,true}) do
 low=reduced;time=10
 for mode=1,2 do
  obstruction=nil
  local e=actor(mode==1 and 'fusilier' or 'bombardier')
  local duration=mode==1 and 1.25 or 1.6
  local count=mode==1 and 4 or 34
  time=10;traces=0
  assert(native(e)==count and sprites==0,'native semantic geometry rendered without particles')
  assert(traces==(mode==1 and 1 or 0),'one bounded line trace; blast has no trace or body scan')
  bar(count,48)
  if not reduced then full[mode]=signature() else assert(signature()==full[mode],'all semantic geometry identical in reduced effects') end
  if mode==1 then
   same(beams[1].a,Vector(100,200,50));same(beams[1].b,Vector(300,200,50))
   obstruction={Hit=true,HitPos=Vector(220,200,50),Entity={}}
   assert(native(e)==10,'intercepted body gains six bracket strokes')
   same(beams[1].b,obstruction.HitPos)
   -- Entity faction is deliberately irrelevant to this harmless interception
   -- cue: an excluded body still blocks the shot without receiving damage.
   obstruction.Entity.excluded=true;assert(native(e)==10)
   obstruction.HitWorld=true;assert(native(e)==4,'wall clips without body glyph')
   same(beams[1].b,obstruction.HitPos)
   obstruction.HitPos=Vector(math.huge,0,0);assert(native(e)==0,'nonfinite trace rejected')
   obstruction.HitPos=Vector(800,200,50);assert(native(e)==0,'out-of-bounds trace rejected')
   obstruction=nil;native(e)
  else
   same(beams[1].a,Vector(372,200,5))
   for i=1,24 do near(math.sqrt(beams[i].a:DistToSqr(Vector(300,200,5))),72) end
   same(beams[26].a,Vector(372,200,5));same(beams[26].b,Vector(372,200,74))
   same(beams[33].a,Vector(100,200,50));same(beams[33].b,Vector(300,200,5))
  end
  assert(beams[1].color.r==(mode==1 and 225 or 210) and beams[1].color.g==(mode==1 and 135 or 175))
  assert(e.bounds.lo.x<=-500 and e.bounds.hi.x>=500 and e.bounds.lo.z<=-500 and e.bounds.hi.z>=500,'native bounds include frozen lane/area')
  time=10+duration/2;native(e);bar(count,24)
  local first=beams[1].a;e.pos=Vector(104,200,2);native(e);same(beams[1].a,first)
  local joined=actor(mode==1 and 'fusilier' or 'bombardier');joined.nw=e.nw
  native(joined);bar(count,24);same(beams[1].a,first)
  time=10+duration;assert(native(e)==count,'finite release grace retains geometry');bar(count,0)
  time=10+duration+.201;assert(native(e)==0,'fixed deadline expires stale snapshot')
  time=9.9;assert(native(e)==0,'future snapshot beyond authored duration rejected')
  time=10;e.nw.LOD_CrossfireUntil=math.huge;assert(native(e)==0,'infinite expiry rejected')
  e.nw.LOD_CrossfireUntil=10+duration-.01;assert(native(e)==0,'inverted expiry rejected')
  e.nw.LOD_CrossfireUntil=10+duration+.3;assert(native(e)==0,'oversized grace rejected')
  e.nw.LOD_CrossfireUntil=10+duration+.2;e.nw.LOD_CrossfireReady=0/0;assert(native(e)==0,'nonfinite ready rejected')
  e.nw.LOD_CrossfireReady=10+duration;e.nw.LOD_CrossfireAim=Vector(1000,300,2)
  assert(native(e)==0,'unbounded geometry rejected before rendering')
  e.nw.LOD_CrossfireAim=Vector(0/0,0,0);assert(native(e)==0,'nonfinite aim rejected')
  e.nw.LOD_CrossfireAim=Vector(300,200,mode==1 and 50 or 2)
  e.nw.LOD_CrossfireOrigin=Vector(100,math.huge,2);assert(native(e)==0,'nonfinite origin rejected')
  e.nw.LOD_CrossfireOrigin=Vector(100,200,2)
  e.nw.LOD_RosterAlive=false;assert(native(e)==0,'source death clears warning')
  e.nw.LOD_RosterAlive=true;e.nw.LOD_DeathPulseStart=10;assert(native(e)==0,'native death draw suppresses warning')
  e.nw.LOD_DeathPulseStart=-1;e.nw.LOD_RosterAttack=0;assert(native(e)==0,'interruption clears tell')
  e.nw.LOD_RosterAttack=2;assert(native(e)==0,'wrong stage cannot retain tell')
  e.nw.LOD_RosterAttack=1;eye=Vector(5000,0,0);assert(native(e)==0,'distance culling');eye=Vector(0,0,64)
  e.pos=Vector(104.01,200,2);assert(native(e)==0,'source displacement beyond4 expires commitment')
  e.pos=Vector(100,200,2);e.nw.LOD_CrossfireMode=0;assert(native(e)==0,'cleared mode has no generic fallback')
  e.nw.LOD_CrossfireMode=mode==1 and 2 or 1;assert(native(e)==0,'mismatched identity rejected')
 end
end
print('BESTIARY_B15_VISUAL_PASS: native Draw/bounds, first-body brackets and blast fragments, full/reduced parity, fixed marks/countdowns, finite expiry/drift/culling, death/interruption; render/trace/NW doubles, not Source QA')
