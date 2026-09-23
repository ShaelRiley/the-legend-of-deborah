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
    local e={nw={LOD_Archetype=id,LOD_RosterAlive=true,LOD_RosterAttack=1,LOD_TrapMode=mode,
        LOD_TrapUntil=20,LOD_TrapReady=11.25,LOD_TrapSnap=0,
        LOD_TrapA=Vector(100,200,3),LOD_TrapB=mode==1 and Vector(324,200,3) or Vector(100,200,3)}}
    function e:GetPos() return Vector(100,200,0) end
    function e:WorldSpaceCenter() return self:GetPos()+Vector(0,0,32) end
    function e:GetNW2Int(key,default) local value=self.nw[key];if value==nil then return default end;return value end
    e.GetNW2Bool=e.GetNW2Int;e.GetNW2Float=e.GetNW2Int;e.GetNW2Vector=e.GetNW2Int
    e.GetNW2Entity=e.GetNW2Int;e.GetNW2String=e.GetNW2Int
    return e
end
local function draw(e) beams={};sprites=0;LOD.EnemyRosterVisual:Draw(e,1);return #beams end
local function near(a,b) assert(math.abs(a-b)<.0001) end
for mode,id in ipairs({'wirewright','snarer','cordon'}) do
    local e=actor(id,mode)
    for _,reduced in ipairs({false,true}) do
        low=reduced;time=10;e.nw.LOD_RosterAttack=1;e.nw.LOD_TrapSnap=0
        assert(draw(e)==({22,28,56})[mode],'complete arming geometry at either effects setting')
        assert(beams[1].width==2 and sprites==0,'thin arming boundary; no particles or glows')
        if mode==1 then
            near(beams[1].b.x-beams[1].a.x,224)
            near(beams[2].a.y,186);near(beams[3].a.y,214)
            for i=4,15 do
                local center=i%2==0 and e.nw.LOD_TrapA or e.nw.LOD_TrapB
                near(math.sqrt(beams[i].a:DistToSqr(center)),14)
            end
            near(beams[16].b.z,48);near(beams[17].b.z,48)
        else
            for i=1,(mode==2 and 24 or 48) do
                local radius=i<=24 and (mode==2 and 72 or 80) or 160
                near(math.sqrt(beams[i].a:DistToSqr(e.nw.LOD_TrapA)),radius)
                near(beams[i].a.z,3);near(beams[i].b.z,3)
            end
            if mode==3 then near(beams[49].b.z,72) end
        end
        time=12;e.nw.LOD_RosterAttack=2
        assert(draw(e)==({18,24,52})[mode],'armed boundaries omit arming diamond')
        assert(beams[1].width==4,'armed boundary is geometrically distinct')
        if mode==2 then
            e.nw.LOD_TrapSnap=13.25
            assert(draw(e)==29,'snap adds four inward teeth and countdown')
            near(beams[29].b.x-beams[29].a.x,48)
            time=12.625;draw(e);near(beams[29].b.x-beams[29].a.x,24)
            time=13.25;assert(draw(e)==0,'stale snare snap hides at its deadline')
            e.nw.LOD_TrapSnap=0
        end
    end
    time=20;assert(draw(e)==0,'hard expiry hides stale snapshots')
    time=12;e.nw.LOD_RosterAlive=false;assert(draw(e)==0,'death hides trap')
    e.nw.LOD_RosterAlive=true;e.nw.LOD_RosterAttack=0;assert(draw(e)==0,'cancel hides trap')
    e.nw.LOD_RosterAttack=2;eye=Vector(5000,5000,0);assert(draw(e)==0,'distance cull')
    eye=Vector(0,0,64);e.nw.LOD_TrapMode=0;assert(draw(e)==0,'invalid mode hides trap')
end
local count=0;for _ in pairs(hooks) do count=count+1 end
assert(count==1 and hooks.LOD_RosterProjectiles,'trap introduces no global rendering hook')
print('PASS: B6 production Draw: exact footprints/heights, arming/armed/snap semantics, reduced effects, finite cleanup and distance culling')
