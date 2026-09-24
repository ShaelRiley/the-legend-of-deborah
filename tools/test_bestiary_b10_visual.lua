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
    local e={pos=Vector(100,200,0),nw={LOD_Archetype=id,LOD_RosterAlive=true,LOD_RosterAttack=1,
        LOD_MobileMode=id=='censer' and 1 or 2,LOD_MobileStart=Vector(100,200,2),
        LOD_MobileGoal=Vector(100,344,2),LOD_MobileReady=11.2,
        LOD_MobileUntil=id=='censer' and 13 or 15}}
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
    low=reduced;time=10
    local censer=actor('censer')
    assert(draw(censer)==27 and sprites==0,'full frozen capsule and countdown survive both settings')
    same(beams[1].a,Vector(164,200,2));same(beams[1].b,Vector(164,344,2))
    same(beams[2].a,Vector(36,200,2));same(beams[2].b,Vector(36,344,2));bar(27,48)
    time=10.6;draw(censer);bar(27,24)
    censer.pos=Vector(100,230,0);draw(censer)
    same(beams[1].a,Vector(164,200,2))
    time=11.2;censer.nw.LOD_RosterAttack=2
    assert(draw(censer)==25,'carrier only shows actual live circle after warning')
    same(beams[1].a,Vector(164,230,2));assert(beams[1].width==4);bar(25,48)
    censer.pos=Vector(100,270,0);time=12.1;draw(censer)
    same(beams[1].a,Vector(164,270,2));bar(25,24)
    time=13;assert(draw(censer)==0,'carrier fixed expiry needs no clear packet')
    censer.nw.LOD_MobileUntil=15;assert(draw(censer)==0,'carrier never survives movement deadline')

    local trail=actor('trailmaker');time=10
    assert(draw(trail)==41,'dashed route, three prospective circles and initial warning')
    same(beams[5].a,Vector(144,200,2));same(beams[17].a,Vector(144,272,2))
    same(beams[29].a,Vector(144,344,2));assert(beams[5].width==1);bar(41,48)
    time=10.6;draw(trail);bar(41,24)
    time=11.2;trail.nw.LOD_RosterAttack=2
    trail.nw.LOD_MobilePatchReady1=12;trail.nw.LOD_MobilePatchUntil1=13.2
    assert(draw(trail)==53,'placed patch gains solid warning and independent countdown')
    assert(beams[5].width==2);bar(29,48)
    time=11.6;draw(trail);bar(29,24)
    time=12;draw(trail);assert(beams[5].width==4);bar(29,48)
    trail.pos=Vector(100,320,0);draw(trail);same(beams[5].a,Vector(144,200,2))
    time=13.1;assert(draw(trail)==25,'unplaced plans disappear at movement deadline')
    time=13.2;assert(draw(trail)==0,'expired placed circle never turns back into planned ghost')
    trail.nw.LOD_MobilePatchReady2=13.5;trail.nw.LOD_MobilePatchUntil2=14.7
    assert(draw(trail)==25);same(beams[1].a,Vector(144,272,2));assert(beams[1].width==2)
    time=14;draw(trail);assert(beams[1].width==4)
    trail.nw.LOD_MobilePatchReady3=13.8;trail.nw.LOD_MobilePatchUntil3=15
    assert(draw(trail)==50);same(beams[26].a,Vector(144,344,2))
    time=15;assert(draw(trail)==0,'global fixed expiry hides every patch without later networking')

    for _,id in ipairs({'censer','trailmaker'}) do
        local e=actor(id);time=10
        e.GetModel=function() return id=='censer' and 'models/combine_soldier.mdl' or 'models/police.mdl' end
        e.EnableMatrix=noop
        local bounds;e.SetRenderBounds=function(_,lo,hi) bounds={lo=lo,hi=hi} end
        local models=0;e.DrawModel=function() models=models+1 end
        beams={};ENT.Draw(e)
        assert(models==1 and #beams==(id=='censer' and 27 or 41),'native Draw reaches mobile presentation')
        assert(bounds.lo.x<=-208 and bounds.lo.y<=-208 and bounds.hi.x>=208 and bounds.hi.y>=208
            and bounds.hi.z>=80,'cached bounds enclose every route endpoint plus full carrier radius')
        e.nw.LOD_RosterAlive=false;assert(draw(e)==0,'dead source hides mobile warning')
        e.nw.LOD_RosterAlive=true;e.nw.LOD_RosterAttack=0;assert(draw(e)==0,'interruption clears every shape')
        e.nw.LOD_RosterAttack=1;e.nw.LOD_MobileMode=0;assert(draw(e)==0,'cleared mode has no fallback ghost')
        e.nw.LOD_MobileMode=id=='censer' and 1 or 2;e.nw.LOD_MobileUntil=0
        assert(draw(e)==0,'retired deadline has no warning')
        e.nw.LOD_MobileUntil=15;eye=Vector(5000,5000,0);assert(draw(e)==0,'distance cull')
        eye=Vector(0,0,64)
    end
end
print('BESTIARY_B10_VISUAL_PASS: native Draw/bounds; full/reduced frozen capsule, actual moving ring, dashed plans, independent patch arming/live countdowns, finite deadlines, source death/interruption/cancel/cull and no stale ghosts')
