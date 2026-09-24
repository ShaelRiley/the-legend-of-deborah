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
    local tow=id=='towline'
    local e={pos=Vector(100,200,0),nw={LOD_Archetype=id,LOD_RosterAlive=true,LOD_RosterAttack=1,
        LOD_TacticalMode=tow and 1 or 2,LOD_TacticalOrigin=Vector(100,200,0),
        LOD_TacticalAim=tow and Vector(100,440,0) or Vector(100,264,0),
        LOD_TacticalDirection=Vector(0,1,0),LOD_TacticalReady=tow and 11.2 or 11,
        LOD_TacticalUntil=tow and 11.4 or 14}}
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
for _,reduced in ipairs({false,true}) do
    low=reduced;time=10
    local tow=actor('towline')
    assert(draw(tow)==6 and sprites==0,'tether corridor, line, two inward chevrons and countdown survive both effects settings')
    same(beams[1].a,Vector(124,296,3));same(beams[1].b,Vector(124,464,3))
    same(beams[2].a,Vector(76,296,3));same(beams[2].b,Vector(76,464,3))
    same(beams[3].a,Vector(100,200,40));same(beams[3].b,Vector(100,440,40))
    same(beams[4].a,Vector(100,408,40));same(beams[4].b,Vector(112,424,40))
    same(beams[5].a,Vector(100,408,40));same(beams[5].b,Vector(88,424,40));bar(6,48)
    time=10.6;draw(tow);bar(6,24)
    tow.pos=Vector(400,300,0);draw(tow);same(beams[1].a,Vector(124,296,3))
    time=11.4;assert(draw(tow)==0,'fixed tether expiry needs no fresh network packet')
    time=10;tow.nw.LOD_RosterAlive=false;assert(draw(tow)==0,'dead tether source hides commitment')
    local screen=actor('screenwright')
    assert(draw(screen)==9 and sprites==0,'screen rectangle, source link, three open slats, countdown')
    same(beams[1].a,Vector(180,264,0));same(beams[1].b,Vector(20,264,0))
    same(beams[2].a,Vector(180,264,96));same(beams[2].b,Vector(20,264,96))
    same(beams[3].a,Vector(180,264,0));same(beams[3].b,Vector(180,264,96))
    same(beams[4].a,Vector(20,264,0));same(beams[4].b,Vector(20,264,96))
    same(beams[5].a,Vector(100,200,40));same(beams[5].b,Vector(100,264,48))
    for i,x in ipairs({140,100,60}) do
        same(beams[5+i].a,Vector(x,264,20));same(beams[5+i].b,Vector(x,264,76))
    end
    for _,i in ipairs({1,2,3,4,6,7,8}) do assert(beams[i].width==1,'warning remains thin') end
    bar(9,48);time=10.5;draw(screen);bar(9,24)
    time=11;screen.nw.LOD_RosterAttack=2;assert(draw(screen)==9);bar(9,48)
    for _,i in ipairs({1,2,3,4,6,7,8}) do assert(beams[i].width==3,'active plane has clear visual state') end
    time=12.5;draw(screen);bar(9,24)
    screen.pos=Vector(400,300,0);draw(screen);same(beams[1].a,Vector(180,264,0))
    time=14;assert(draw(screen)==0,'fixed screen expiry needs no fresh network packet')
    time=10;screen.nw.LOD_TacticalUntil=0;assert(draw(screen)==0,'retirement clears warning')
    screen=actor('screenwright');screen.nw.LOD_TacticalMode=0
    screen.nw.LOD_RosterOrigin=Vector(100,200,48);screen.nw.LOD_RosterAim=Vector(100,800,48)
    assert(draw(screen)==1 and sprites==1,'ordinary physical fallback retains canonical warning')
    same(beams[1].a,screen.nw.LOD_RosterOrigin);same(beams[1].b,screen.nw.LOD_RosterAim)
    assert(beams[1].width==1)
    screen.nw.LOD_RosterAttack=0;assert(draw(screen)==0,'fallback cancellation hides warning')
end
-- Execute native entity Draw and validate broad bounds, not only the visual helper.
ENT={};include=noop;concommand={Add=noop};util={GetModelBounds=function() return Vector(-16,-16,0),Vector(16,16,72) end}
Matrix=function() return {Scale=noop,Rotate=noop,SetTranslation=noop} end
render.SuppressEngineLighting=noop;render.MaterialOverride=noop;render.SetColorModulation=noop;render.SetBlend=noop
LOD.RuntimeReceipts={}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/cl_init.lua')
for _,id in ipairs({'towline','screenwright'}) do
    local e=actor(id);e.GetModel=function() return id=='towline' and 'models/police.mdl' or 'models/combine_soldier.mdl' end
    e.EnableMatrix=noop
    local bounds;e.SetRenderBounds=function(_,lo,hi) bounds={lo=lo,hi=hi} end
    local models=0;e.DrawModel=function() models=models+1 end
    beams={};time=10;ENT.Draw(e)
    assert(models==1 and #beams==(id=='towline' and 6 or 9),'native Draw reaches tactical presentation')
    local extent=id=='towline' and 344 or 600
    assert(bounds.lo.x<=-extent and bounds.lo.y<=-extent and bounds.hi.x>=extent and bounds.hi.y>=extent
        and bounds.hi.z>=96,'native bounds enclose full authored tactical or fallback warning')
    eye=Vector(5000,5000,0);assert(draw(e)==0,'distance cull');eye=Vector(0,0,64)
end
print('BESTIARY_B9_VISUAL_PASS: native Draw and bounds; full/reduced frozen tether corridor/chevrons, passable screen/slats, warning/active countdown, fixed expiry/death/cancel/cull and fallback warning')
