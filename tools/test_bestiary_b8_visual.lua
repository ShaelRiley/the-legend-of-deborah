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
local function actor(id,mode)
    local e={pos=Vector(100,200,0),nw={LOD_Archetype=id,LOD_RosterAlive=true,LOD_RosterAttack=1,
        LOD_MeleeMode=mode,LOD_MeleeOrigin=Vector(100,200,0),LOD_MeleeDirection=Vector(0,1,0),
        LOD_MeleeStart=Vector(100,280,0),LOD_MeleeReady=mode==1 and 11.1 or (mode==2 and 11 or 11.5),
        LOD_MeleeSecond=mode==2 and 11.85 or 0,LOD_MeleeUntil=mode==1 and 11.3 or (mode==2 and 12.05 or 11.7)}}
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
local function sector(first,radius,halfAngle,segments,width)
    local origin=Vector(100,200,3);local half=math.rad(halfAngle)
    local function point(angle) return origin+Vector(-math.sin(angle),math.cos(angle),0)*radius end
    same(beams[first].a,origin);same(beams[first].b,point(-half))
    for i=1,segments do
        same(beams[first+i].a,point(-half+2*half*(i-1)/segments))
        same(beams[first+i].b,point(-half+2*half*i/segments))
    end
    same(beams[first+segments+1].a,point(half));same(beams[first+segments+1].b,origin)
    for i=first,first+segments+1 do assert(beams[i].width==width) end
end
local function bar(index,length) near(math.sqrt(beams[index].a:DistToSqr(beams[index].b)),length) end

NULL={removed=true}
for _,reduced in ipairs({false,true}) do
    low=reduced;time=10
    local body=actor('afterburst',0);body.nw.LOD_RosterAlive=false;body.nw.LOD_RosterAttack=0
    body.nw.LOD_RemainsOrigin=Vector(100,200,0);body.nw.LOD_RemainsBurstReady=10.8;body.nw.LOD_RemainsBurstUntil=10.9
    assert(draw(body)==25 and sprites==0,'dead actor retains full frozen circle and bar at both effects levels')
    for i=1,24 do near(math.sqrt(beams[i].a:DistToSqr(Vector(100,200,3))),128) end
    bar(25,48);time=10.4;draw(body);bar(25,24)
    body.pos=Vector(400,300,0);draw(body);same(beams[1].a,Vector(228,200,3))
    time=10.9;assert(draw(body)==0,'fixed expiry without another network message')
    time=10;body.nw.LOD_RemainsBurstUntil=0;assert(draw(body)==0,'consumption/cancel removes warning')
    local e=actor('carrion',0);e.nw.LOD_RosterAttack=0;e.nw.LOD_RemainsTarget=body
    e.nw.LOD_RemainsFeedOrigin=Vector(100,200,0);e.nw.LOD_RemainsFeedAim=Vector(160,200,0)
    e.nw.LOD_RemainsFeedReady=10.6;e.nw.LOD_RemainsFeedUntil=10.7
    assert(draw(e)==4 and sprites==0,'semantic tether, jaws and countdown')
    same(beams[1].a,Vector(100,200,40));same(beams[1].b,Vector(160,200,8));bar(4,48)
    time=10.3;draw(e);bar(4,24)
    time=10.7;assert(draw(e)==0);time=10
    body.removed=true;assert(draw(e)==0,'removed corpse retires tether');body.removed=false
    e.nw.LOD_RosterAlive=false;assert(draw(e)==0,'dead scavenger hides feeding')
    for _,id in ipairs({'afterburst','carrion'}) do
        e=actor(id,4);e.nw.LOD_MeleeReady=10+(id=='afterburst' and .9 or .8)
        assert(draw(e)==11,'ordinary narrow melee warning exists for both new identities')
        sector(1,112,30,8,2)
    end
end
-- Execute the real native entity corpse Draw branch with engine rendering doubled.
ENT={};include=noop;concommand={Add=noop};util={GetModelBounds=function() return Vector(-16,-16,0),Vector(16,16,72) end}
Matrix=function() return {Scale=noop,Rotate=noop,SetTranslation=noop} end
render.SuppressEngineLighting=noop;render.MaterialOverride=noop;render.SetColorModulation=noop;render.SetBlend=noop
LOD.EnemyDeathPulse=function() return .5 end
local b=actor('afterburst',0);b.nw.LOD_DeathPulseStart=10;b.nw.LOD_RosterAlive=false
b.nw.LOD_RemainsOrigin=Vector(100,200,0);b.nw.LOD_RemainsBurstReady=10.8;b.nw.LOD_RemainsBurstUntil=10.9
b.GetModel=function() return 'models/zombie/classic.mdl' end;b.EnableMatrix=noop
local bound;b.SetRenderBounds=function(_,lo,hi) bound=hi end
local models=0;b.DrawModel=function() models=models+1 end
GetConVar=function() return {GetBool=function() return low end} end
LOD.RuntimeReceipts={}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/cl_init.lua')
beams={};time=10;ENT.Draw(b)
assert(models==2 and #beams==25 and bound.x>=128,'actual native dying Draw retains pulse, broad bounds and warning')
eye=Vector(5000,5000,0);assert(draw(b)==0,'distance cull')
print('BESTIARY_B8_VISUAL_PASS: actual native corpse Draw; full/reduced burst circle/countdown, feeding tether/jaws, fallback melee, fixed expiry and culling')
