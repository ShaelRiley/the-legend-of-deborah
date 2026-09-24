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
        LOD_EdictMode=id=='censor' and 1 or 2,LOD_EdictPhase=1,LOD_EdictOrigin=Vector(100,200,2),
        LOD_EdictAim=id=='censor' and Vector(300,200,50) or Vector(300,200,2),
        LOD_EdictRefuge=Vector(300,296,2),LOD_EdictEscape=Vector(300,40,2),
        LOD_EdictReady=id=='censor' and 10.8 or 11.6,LOD_EdictUntil=id=='censor' and 13.4 or 11.8}}

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
  for phase=1,(mode==1 and 3 or 1) do
   time=10
   local e=actor(mode==1 and 'censor' or 'surveyor');e.nw.LOD_EdictPhase=phase
   local duration=mode==2 and 1.6 or (phase==1 and .8 or (phase==2 and 2.4 or 1.2))
   local tail=mode==2 and .2 or (phase==1 and 2.6 or .2)
   e.nw.LOD_EdictReady=time+duration;e.nw.LOD_EdictUntil=time+duration+tail
   assert(native(e)>5 and sprites==0,'finite semantic geometry without particles')
   local count=#beams
   local label=mode==2 and 'REFUGE / LEAVE RING' or (phase==3 and 'RETALIATION' or 'CEASE FIRE')
   assert(labels[#labels-1]==label,'literal counterplay')
   assert(labels[#labels]==string.format('%s %.1fs',mode==2 and 'JUDGMENT' or (phase==1 and 'PREPARE' or (phase==2 and 'WATCH' or 'FIRE')),duration),'phase countdown')
   if mode==2 then assert(labels[1]=='REFUGE','label displaced safe pocket') end
   local key=mode..':'..phase
   if not reduced then full[key]=signature() else assert(signature()==full[key],'full/reduced geometry and labels are identical') end
   bar(count,48)
   assert(e.bounds.lo.x<=-532 and e.bounds.hi.x>=532,'native conservative bounds')
   for _,beam in ipairs(beams) do
    for _,p in ipairs({beam.a,beam.b}) do
     local offset=p-e.pos
     for _,axis in ipairs({'x','y','z'}) do assert(offset[axis]>=e.bounds.lo[axis] and offset[axis]<=e.bounds.hi[axis],'all tell points fit native bounds') end
    end
   end
   local snapshot=signature();local joined=actor(mode==1 and 'censor' or 'surveyor');joined.nw=e.nw
   native(joined);assert(signature()==snapshot,'late observer reconstructs current phase')
   e.nw.LOD_EdictHero={GetPos=function() error('must not query live Hero') end,WorldSpaceCenter=function() error('must not track Hero center') end}
   native(e);assert(signature()==snapshot,'no live entity queries')
   if mode==2 then
    -- First32 segments enclose the threat; next32 the displaced refuge.
    local ground=e.nw.LOD_EdictAim+Vector(0,0,3);local refuge=e.nw.LOD_EdictRefuge+Vector(0,0,3)
    for i=1,32 do near(beams[i].a:DistToSqr(ground),144^2);near(beams[i].b:DistToSqr(ground),144^2) end
    for i=33,64 do near(beams[i].a:DistToSqr(refuge),48^2);near(beams[i].b:DistToSqr(refuge),48^2) end
    same(beams[65].a,ground);same(beams[65].b,refuge)
    same(beams[68].b,e.nw.LOD_EdictEscape+Vector(0,0,3))
   else same(beams[1].a,Vector(100,200,50));same(beams[1].b,e.nw.LOD_EdictAim) end
   time=10+duration/2;native(e);bar(count,24)
   time=e.nw.LOD_EdictUntil;assert(native(e)==0 and #labels==0,'deadline clears stale tell')
   time=9.9;assert(native(e)==0,'future phase rejected');time=10
   local ready,untilAt=e.nw.LOD_EdictReady,e.nw.LOD_EdictUntil
   for _,bad in ipairs({math.huge,100,ready-.01}) do e.nw.LOD_EdictUntil=bad;assert(native(e)==0,'invalid expiry') end
   e.nw.LOD_EdictUntil=untilAt;e.nw.LOD_EdictReady=0/0;assert(native(e)==0,'nonfinite ready');e.nw.LOD_EdictReady=ready
   for _,field in ipairs(mode==2 and {'Origin','Aim','Refuge','Escape'} or {'Origin','Aim'}) do
    local key='LOD_Edict'..field;local saved=e.nw[key]
    e.nw[key]=Vector(0/0,0,0);assert(native(e)==0,'nonfinite '..field)
    e.nw[key]=Vector(9000,0,0);assert(native(e)==0,'unbounded '..field)
    e.nw[key]=saved
   end
   if mode==2 then
    local saved=e.nw.LOD_EdictRefuge
    e.nw.LOD_EdictRefuge=saved+Vector(0,0,1);assert(native(e)==0,'off-plane refuge')
    e.nw.LOD_EdictRefuge=e.nw.LOD_EdictAim+Vector(96,0,0);assert(native(e)==0,'mismatched opposite exit')
    e.nw.LOD_EdictRefuge=saved
   end
   e.nw.LOD_RosterAlive=false;assert(native(e)==0,'death');e.nw.LOD_RosterAlive=true
   e.nw.LOD_DeathPulseStart=10;assert(native(e)==0,'native death pulse');e.nw.LOD_DeathPulseStart=-1
   e.nw.LOD_RosterAttack=0;assert(native(e)==0,'interruption');e.nw.LOD_RosterAttack=2;assert(native(e)==0,'wrong stage');e.nw.LOD_RosterAttack=1
   eye=e.pos+Vector(2400,0,0);assert(native(e)==count,'distance cull boundary');eye=e.pos+Vector(2400.01,0,0);assert(native(e)==0,'distance cull');eye=Vector(0,0,64)
   e.pos=Vector(104,200,2);assert(native(e)==count,'bounded source drift')
   e.pos=Vector(104.01,200,2);assert(native(e)==0,'excessive source drift');e.pos=Vector(100,200,2)
   e.nw.LOD_EdictMode=0;assert(native(e)==0,'cleared mode cannot render generic warning')
   e.nw.LOD_EdictMode=3-mode;assert(native(e)==0,'identity mismatch')
  end
 end
end
-- Acquisition at the far range boundary, plus adverse source drift, must keep
-- every ring and escape-arrow vertex inside the native model render bounds.
for _,reduced in ipairs({false,true}) do
 low=reduced;time=10
 local e=actor('surveyor')
 e.nw.LOD_EdictAim=Vector(460,200,2)
 e.nw.LOD_EdictRefuge=Vector(460,296,2);e.nw.LOD_EdictEscape=Vector(460,40,2)
 e.pos=Vector(96,200,2)
 assert(native(e)>0,'far legal acquisition survives client guard')
 for _,b in ipairs(beams) do for _,point in ipairs({b.a,b.b}) do
  local p=point-e.pos
  for _,axis in ipairs({'x','y','z'}) do assert(p[axis]>=e.bounds.lo[axis] and p[axis]<=e.bounds.hi[axis],'far-bound vertex retained') end
 end end
 e.nw.LOD_EdictAim=Vector(460.1,200,2)
 e.nw.LOD_EdictRefuge=Vector(460.1,296,2);e.nw.LOD_EdictEscape=Vector(460.1,40,2)
 assert(native(e)==0,'outside acquisition bounds')
end
assert(full['1:1']~=full['2:1'] and full['1:1']~=full['1:3'],'distinct semantic geometry')
local e=actor('surveyor');e.nw.LOD_EdictPhase=2;assert(native(e)==0,'Surveyor has no watch phase')
print('BESTIARY_B18_VISUAL_PASS: native Draw/bounds, CEASE FIRE/RETALIATION and REFUGE / LEAVE RING; exact frozen outer/refuge/escape geometry; countdowns, full/reduced/late-join parity; malformed, expiry, death, drift and culling; render/NW doubles, not Source QA')
