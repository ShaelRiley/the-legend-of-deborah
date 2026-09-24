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
        LOD_CompanionMode=id=='interposer' and 1 or 2,LOD_CompanionPhase=1,LOD_CompanionOrigin=Vector(100,200,2),
        LOD_CompanionGoal=Vector(180,200,2),LOD_CompanionWard=Vector(244,200,34),
        LOD_CompanionAim=Vector(300,200,50),LOD_CompanionReady=10.8,
        LOD_CompanionUntil=id=='interposer' and 14.6 or 13.8}}

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
  for phase=1,3 do
   for retaliation=0,(phase==3 and mode==2 and 1 or 0) do
    time=10
    local e=actor(mode==1 and 'interposer' or 'mourner')
    e.nw.LOD_CompanionPhase=phase;e.nw.LOD_CompanionRetaliation=retaliation
    local duration=phase==1 and .8 or (phase==3 and 1.2 or (mode==1 and 2 or 3))
    local tail=phase==1 and (mode==1 and 3.8 or 3) or (phase==3 and .2 or 0)
    e.nw.LOD_CompanionReady=10+duration;e.nw.LOD_CompanionUntil=10+duration+tail
    local count=phase==3 and (retaliation==1 and 10 or 6) or (mode==1 and 10 or 6)
    assert(native(e)==count and sprites==0,'native semantic geometry without particles')
    local label=phase==3 and (retaliation==1 and 'RETALIATION' or 'SHOT') or (mode==1 and 'BODYGUARD' or 'OATH')
    assert(labels[1]==label,'literal action label')
    assert(labels[2]==string.format('%s %.1fs',phase==1 and 'PREPARE' or (phase==3 and 'FIRE' or 'ACTIVE'),duration),'phase countdown')
    local key=table.concat({mode,phase,retaliation},':')
    if not reduced then full[key]=signature() else assert(signature()==full[key],'full/reduced identical semantic geometry') end
    bar(count,48)
    assert(e.bounds.lo.x<=-500 and e.bounds.hi.x>=500 and e.bounds.lo.z<=-500 and e.bounds.hi.z>=500,'native conservative bounds')
    local snapshot=signature()
    local joined=actor(mode==1 and 'interposer' or 'mourner');joined.nw=e.nw
    native(joined);assert(signature()==snapshot,'late observer reconstructs finite phase')
    e.nw.LOD_CompanionHero={WorldSpaceCenter=function() error('live Hero must never be tracked') end}
    e.nw.LOD_CompanionWardEntity={WorldSpaceCenter=function() error('live ward must never be tracked') end}
    native(e);assert(signature()==snapshot,'no live recipient queries')
    if phase==3 then
     same(beams[1].a,Vector(100,200,50));same(beams[1].b,Vector(300,200,50))
    elseif mode==1 then
     same(beams[1].a,Vector(100,200,5));same(beams[1].b,Vector(180,200,5))
     if phase==2 then
      e.pos=Vector(140,200,2);native(e)
      same(beams[1].a,Vector(100,200,5));same(beams[1].b,Vector(180,200,5))
      near(beams[4].a.x,140);same(beams[9].b,Vector(244,200,34))
      e.pos=Vector(100,200,2)
     end
    else
     same(beams[5].a,Vector(100,200,50));same(beams[5].b,Vector(244,200,34))
    end
    time=10+duration/2;native(e);bar(count,24)
    time=e.nw.LOD_CompanionUntil+.001;assert(native(e)==0 and #labels==0,'fixed expiry clears stale tell')
    time=9.9;assert(native(e)==0,'future snapshot rejected')
    time=10
    local untilAt=e.nw.LOD_CompanionUntil
    e.nw.LOD_CompanionUntil=math.huge;assert(native(e)==0,'nonfinite expiry')
    e.nw.LOD_CompanionUntil=e.nw.LOD_CompanionReady-.01;assert(native(e)==0,'inverted expiry')
    e.nw.LOD_CompanionUntil=100;assert(native(e)==0,'excessive expiry')
    e.nw.LOD_CompanionUntil=untilAt
    local ready=e.nw.LOD_CompanionReady;e.nw.LOD_CompanionReady=0/0;assert(native(e)==0,'nonfinite ready');e.nw.LOD_CompanionReady=ready
    for _,field in ipairs({'Origin','Goal','Ward','Aim'}) do
     local name='LOD_Companion'..field;local saved=e.nw[name]
     e.nw[name]=Vector(0/0,0,0);assert(native(e)==0,'nonfinite snapshot '..field)
     e.nw[name]=Vector(9000,0,0);assert(native(e)==0,'unbounded snapshot '..field)
     e.nw[name]=saved
    end
    e.nw.LOD_RosterAlive=false;assert(native(e)==0,'death');e.nw.LOD_RosterAlive=true
    e.nw.LOD_DeathPulseStart=10;assert(native(e)==0,'native death pulse');e.nw.LOD_DeathPulseStart=-1
    e.nw.LOD_RosterAttack=0;assert(native(e)==0,'interruption');e.nw.LOD_RosterAttack=2;assert(native(e)==0,'wrong stage');e.nw.LOD_RosterAttack=1
    eye=Vector(5000,0,0);assert(native(e)==0,'distance cull');eye=Vector(0,0,64)
    local limit=mode==1 and phase==2 and 164 or 4
    e.pos=Vector(100+limit,200,2);assert(native(e)==count,'permitted source drift')
    e.pos=Vector(100+limit+.01,200,2);assert(native(e)==0,'excessive source drift')
    e.pos=Vector(100,200,2)
    e.nw.LOD_CompanionMode=0;assert(native(e)==0,'cleared mode has no generic fallback')
    e.nw.LOD_CompanionMode=3-mode;assert(native(e)==0,'identity mismatch')
   end
  end
 end
end
-- Guard arrival changes Origin to Goal but must not permit further travel.
for _,reduced in ipairs({false,true}) do
 low=reduced;time=10
 local e=actor('interposer');e.nw.LOD_CompanionPhase=2
 e.nw.LOD_CompanionGoal=Vector(100,200,2)
 e.nw.LOD_CompanionReady=12;e.nw.LOD_CompanionUntil=12
 assert(native(e)==10 and labels[1]=='BODYGUARD' and labels[2]=='ACTIVE 2.0s','arrival hold')
 e.pos=Vector(104,200,2);assert(native(e)==10,'hold bounded source drift')
 e.pos=Vector(104.01,200,2);assert(native(e)==0,'hold cannot inherit movement drift')
end
print('BESTIARY_B17_VISUAL_PASS: real native Draw/bounds; BODYGUARD/OATH/RETALIATION/SHOT labels and countdowns; actual-body shield/frozen route; oath/broken-oath; snapshot-only lane/ward; reduced parity, expiry/drift/culling/death; render/NW doubles, not Source QA')
