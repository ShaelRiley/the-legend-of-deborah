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
 local e=actor('conductor');e.nw.LOD_SpacingMode=2
 e.nw.LOD_SpacingOrigin=Vector(100,200,2)
 e.nw.LOD_SpacingAimA=Vector(300,200,2);e.nw.LOD_SpacingAimB=Vector(300,300,2)
 e.nw.LOD_SpacingReady=11.4;e.nw.LOD_SpacingUntil=11.6
 assert(native(e)==52 and sprites==0,'native twin circles, tethers, connecting line and countdown in either mode')
 same(beams[1].a,Vector(364,200,5));same(beams[26].a,Vector(364,300,5))
 same(beams[51].a,Vector(300,200,5));same(beams[51].b,Vector(300,300,5));bar(52,48)
 assert(beams[1].color.r==150 and beams[1].color.g==190 and beams[1].color.b==250)
 assert(e.bounds.lo.x<=-424 and e.bounds.hi.x>=424 and e.bounds.hi.z>=112,'native bounds include both frozen circles')
 time=10.7;native(e);bar(52,24)
 e.pos=Vector(140,200,2);native(e);same(beams[1].a,Vector(364,200,5))
 local joined=actor('conductor');joined.nw=e.nw
 native(joined);bar(52,24);same(beams[1].a,Vector(364,200,5))
 time=11.6;assert(native(e)==0,'fixed deadline expires stale snapshot')
 time=10;e.nw.LOD_SpacingUntil=math.huge;assert(native(e)==0,'nonfinite expiry rejected')
 e.nw.LOD_SpacingUntil=11.6;e.nw.LOD_SpacingReady=0/0;assert(native(e)==0,'nonfinite ready rejected')
 e.nw.LOD_SpacingReady=11.4;e.nw.LOD_SpacingAimB=Vector(1000,300,2)
 assert(native(e)==0,'unbounded geometry rejected before rendering')
 e.nw.LOD_SpacingAimB=Vector(300,300,2);e.nw.LOD_RosterAlive=false;assert(native(e)==0,'source death clears pair')
 e.nw.LOD_RosterAlive=true;e.nw.LOD_DeathPulseStart=10;assert(native(e)==0,'native death renderer bypasses stale warning')
 e.nw.LOD_DeathPulseStart=-1;e.nw.LOD_RosterAttack=0;assert(native(e)==0,'interruption clears pair')
 e.nw.LOD_RosterAttack=1;eye=Vector(5000,0,0);assert(native(e)==0);eye=Vector(0,0,64)
 e.nw.LOD_SpacingMode=0;e.nw.LOD_RosterReady=11.4;e.nw.LOD_RosterRelease=0
 assert(native(e)==2 and sprites==1,'fallback has ordinary warned bolt, no stale circle or link')
 bar(2,48);time=10.7;native(e);bar(2,24)
 time=11.6;assert(native(e)==0,'fresh fallback warning has finite expiry without release packet')
 e.nw.LOD_RosterAttack=2;e.nw.LOD_RosterRelease=11.4
 time=11.5;assert(native(e)==1 and sprites==1,'released bolt keeps short tell without countdown')
 time=11.6;assert(native(e)==0,'released fallback has finite stale snapshot expiry')
 time=10;e.nw.LOD_RosterAlive=false;assert(native(e)==0,'dead source cannot show fallback')
 local o=actor('outrider');o.nw.LOD_SpacingMode=1;o.nw.LOD_SpacingOrigin=Vector(100,200,2)
 o.nw.LOD_SpacingReady=11.1;o.nw.LOD_SpacingUntil=11.3
 o.nw.LOD_MeleeMode=4;o.nw.LOD_MeleeOrigin=Vector(100,200,2)
 o.nw.LOD_MeleeDirection=Vector(1,0,0);o.nw.LOD_MeleeReady=11.1;o.nw.LOD_MeleeUntil=11.3
 assert(native(o)==18 and sprites==0,'native narrow arc plus distinct isolation glyph')
 same(beams[1].a,Vector(100,200,5));same(beams[1].b,Vector(100+112*math.cos(math.pi/6),144,5))
 bar(11,48);assert(beams[1].color.r==225 and beams[1].color.g==170 and beams[1].color.b==80)
 assert(o.bounds.lo.x<=-144 and o.bounds.hi.x>=144 and o.bounds.hi.z>=80,'native cull includes arc and glyph')
 time=10.55;native(o);bar(11,24)
 o.pos=Vector(140,200,2);native(o);same(beams[1].a,Vector(100,200,5))
 time=11.3;assert(native(o)==0,'isolation and arc expire together')
 time=10;o.nw.LOD_SpacingMode=0;assert(native(o)==0,'regroup cancellation clears all tells even stale melee fields')
 o.nw.LOD_SpacingMode=1;o.nw.LOD_RosterAlive=false;assert(native(o)==0)
 o.nw.LOD_RosterAlive=true;o.nw.LOD_RosterAttack=0;assert(native(o)==0)
 o.nw.LOD_RosterAttack=1;eye=Vector(5000,0,0);assert(native(o)==0);eye=Vector(0,0,64)
end
print('BESTIARY_B13_VISUAL_PASS: native Draw/culling, full/reduced spacing glyphs, frozen geometry/countdowns, finite expiry, fallback, death/interruption/distance cleanup')
