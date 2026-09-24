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
    DrawBeam=function(a,b,width) beams[#beams+1]={a=a,b=b,width=width} end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_enemy_roster.lua')
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
dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/cl_init.lua')
for _,reduced in ipairs({false,true}) do
 low=reduced
 for _,id in ipairs({'listener','shy'}) do
    local e=actor(id);time=10
    local expected=id=='listener' and 29 or 10
    assert(draw(e)==expected and sprites==0,'semantic dashed route, sound/closed-eye glyph and countdown in both settings')
    same(beams[1].a,Vector(100,200,2));same(beams[1].b,Vector(116,200,2));bar(expected,48)
    time=10.4;draw(e);bar(expected,24)
    e.pos=Vector(145,200,2);draw(e);same(beams[1].a,Vector(100,200,2))
    time=10.8;e.nw.LOD_RosterAttack=2;draw(e);bar(expected,48)
    time=11.5;draw(e);bar(expected,24)
    time=12.2;assert(draw(e)==0,'fixed expiry needs no later packet')
    time=10;e.pos=Vector(100,200,2);e.GetModel=function() return 'models/police.mdl' end
    e.EnableMatrix=noop
    local bounds;e.SetRenderBounds=function(_,lo,hi) bounds={lo=lo,hi=hi} end
    local models=0;e.DrawModel=function() models=models+1 end
    beams={};ENT.Draw(e)
    assert(models==1 and #beams==expected,'native Draw reaches B11 geometry')
    assert(bounds.lo.x<=-160 and bounds.hi.x>=160 and bounds.hi.z>=80,'native bounds include route and glyph')
    e.nw.LOD_RosterAlive=false;assert(draw(e)==0)
    e.nw.LOD_RosterAlive=true;e.nw.LOD_RosterAttack=0;assert(draw(e)==0,'interruption hides')
    e.nw.LOD_RosterAttack=1;eye=Vector(5000,0,0);assert(draw(e)==0);eye=Vector(0,0,64)
    e.nw.LOD_PerceptionMode=0;e.nw.LOD_MeleeMode=4
    e.nw.LOD_MeleeOrigin=Vector(100,200,2);e.nw.LOD_MeleeDirection=Vector(1,0,0)
    e.nw.LOD_MeleeReady=10.9;e.nw.LOD_MeleeUntil=11.1
    assert(draw(e)==11,'separate solid ordinary melee sector replaces investigative route')
    bar(11,48);time=10.45;draw(e);bar(11,24)
    time=11.1;assert(draw(e)==0,'melee warning expires')
 end
end
print('BESTIARY_B11_VISUAL_PASS: native Draw and cull bounds, full/reduced semantic glyphs/frozen routes, movement and melee countdowns, interruption/death/distance/fixed expiry')
