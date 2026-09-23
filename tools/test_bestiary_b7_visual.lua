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
for mode,id in ipairs({'reaper','drubber','fencer'}) do
    local e=actor(id,mode)
    for _,reduced in ipairs({false,true}) do
        low=reduced;time=10;e.pos=Vector(100,200,0)
        assert(draw(e)==({15,21,10})[mode],'full semantic geometry at either effects setting')
        assert(sprites==0,'melee uses no particle or glow decoration')
        if mode==1 then
            sector(1,144,90,12,2);bar(15,48)
            time=10.55;draw(e);bar(15,24)
            time=11.1;assert(draw(e)==14);sector(1,144,90,12,4)
        elseif mode==2 then
            sector(1,112,30,8,2);sector(11,184,30,8,1);bar(21,48)
            time=10.5;draw(e);bar(21,24)
            time=11;assert(draw(e)==11,'spent inner beat hides, outer warning remains')
            sector(1,184,30,8,2);bar(11,48)
            time=11.425;draw(e);bar(11,24)
            time=11.85;assert(draw(e)==10);sector(1,184,30,8,4)
        else
            for i=1,4 do
                same(beams[i].a,Vector(100,280-(i-1)*20,3))
                same(beams[i].b,Vector(100,270-(i-1)*20,3))
                assert(beams[i].width==1,'dashed retreat is distinct from damaging outline')
            end
            same(beams[5].a,Vector(100,200,3));same(beams[6].a,Vector(100,200,3))
            time=10.6;assert(draw(e)==5,'thrust warning begins after the backstep')
            local points={Vector(124,200,3),Vector(124,440,3),Vector(76,440,3),Vector(76,200,3)}
            for i=1,4 do same(beams[i].a,points[i]);same(beams[i].b,points[i%4+1]);assert(beams[i].width==2) end
            bar(5,48)
            time=11.05;draw(e);bar(5,24)
            time=11.5;assert(draw(e)==4);assert(beams[1].width==4)
        end
        local frozen=beams
        e.pos=Vector(500,500,40);draw(e)
        for i,b in ipairs(frozen) do same(beams[i].a,b.a);same(beams[i].b,b.b) end
        assert(#beams==#frozen,'source motion never retargets the footprint')
        local joined=actor(id,mode);draw(joined)
        for i,b in ipairs(frozen) do same(beams[i].a,b.a);same(beams[i].b,b.b) end
        assert(#beams==#frozen,'late snapshots use original deadlines, never restart animation')
    end
    time=e.nw.LOD_MeleeUntil;assert(draw(e)==0,'stale snapshot expires at its fixed deadline')
    time=10;e.nw.LOD_RosterAlive=false;assert(draw(e)==0,'death hides melee commitment')
    e.nw.LOD_RosterAlive=true;e.nw.LOD_RosterAttack=0;assert(draw(e)==0,'cancellation hides commitment')
    e.nw.LOD_RosterAttack=1;eye=Vector(5000,5000,0);assert(draw(e)==0,'distance cull')
    eye=Vector(0,0,64);e.nw.LOD_MeleeMode=0;assert(draw(e)==0,'invalid mode hides melee')
end
local count=0;for _ in pairs(hooks) do count=count+1 end
assert(count==1 and hooks.LOD_RosterProjectiles,'melee introduces no global render hook')
print('PASS: B7 production Draw: frozen exact sectors/thrust, two-beat timing, distinct retreat, reduced effects, finite cleanup and culling')
