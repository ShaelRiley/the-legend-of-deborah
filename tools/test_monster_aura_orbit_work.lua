-- Actual presentation authority; native state/vector/sprite boundaries doubled.
-- --probe SOURCE TRACE compares the published parent without the new work bound.
-- --gate [SOURCE] [TRACE] also rejects that parent's repeated orbit arithmetic.
local mode=arg[1] or '--gate'
local source=arg[2] or 'gamemodes/legend_of_deborah/gamemode/lod/cl_monster_identity.lua'
local tracePath=arg[3]
local trace,counts,recording={}, {},false
local nativeCos,nativeSin,nativePi=math.cos,math.sin,math.pi
local function number(n) return string.format('%.17g',n) end
local function note(...)
    local out={...}
    for i,v in ipairs(out) do out[i]=type(v)=='number' and number(v) or tostring(v) end
    trace[#trace+1]=table.concat(out,'|')
end
math.cos=function(n) if recording then counts.trig=counts.trig+1 end;return nativeCos(n) end
math.sin=function(n) if recording then counts.trig=counts.trig+1 end;return nativeSin(n) end
local cos,sin=math.cos,math.sin
local V={};V.__index=V
function Vector(x,y,z)
    if recording then counts.vectors=counts.vectors+1 end
    return setmetatable({x=x or 0,y=y or 0,z=z or 0},V)
end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,n) return Vector(a.x*n,a.y*n,a.z*n) end
function V:DistToSqr(b) return (self.x-b.x)^2+(self.y-b.y)^2+(self.z-b.z)^2 end
local eye=Vector()
EyePos=function() if recording then counts.getters=counts.getters+1 end;note('eye',eye.x,eye.y,eye.z);return eye end
function Color(r,g,b,a)
    if recording then counts.colors=counts.colors+1 end
    return {r=r,g=g,b=b,a=a or 255}
end
function IsValid(e)
    if recording then counts.getters=counts.getters+1 end
    note('valid',e.id,e.valid~=false);return e.valid~=false
end
math.Clamp=function(n,lo,hi) return math.max(lo,math.min(hi,n)) end
local low,clock,callback=true,10,nil
local cv={GetBool=function() if recording then counts.getters=counts.getters+1 end;note('low',low);return low end}
GetConVar=function(name)
    if recording then counts.getters=counts.getters+1 end
    note('convar',name);return cv
end
CurTime=function() if recording then counts.getters=counts.getters+1 end;note('time',clock);return clock end
hook={Add=function() end};CreateMaterial=function() return 'glow' end
render={SetMaterial=function(mat) note('material',mat) end,
    DrawSprite=function(p,w,h,c)
        if recording then counts.sprites=counts.sprites+1 end
        note('sprite',p.x,p.y,p.z,w,h,c.r,c.g,c.b,c.a)
        if callback then local call=callback;callback=nil;call() end
    end}
LOD={Equipment={StatusOrder={'first','second'},StatusPresentation={
    first={key='Held',color={30,70,110}},second={key='Muted',color={140,180,220}}}},
    MagicArea={Colors={fire=Color(255,80,20),ice=Color(30,130,250)}}}
LOD.WatcherPolishFX={IsVisible=function(_,e)
    if recording then counts.getters=counts.getters+1 end
    note('visible',e.id,not e.cloaked);return not e.cloaked
end}
local function load() dofile(source);return LOD.MonsterIdentity end
local M=load()
local serial=0
local function actor()
    serial=serial+1
    local e={id=serial,nw={LOD_MonsterElement='fire'},pos=Vector(10,20,2),center=Vector(10,20,40)}
    local function query(self,label,v)
        if recording then counts.getters=counts.getters+1 end
        note(label,self.id,type(v)=='table' and 'vector' or v);return v
    end
    function e:GetNoDraw() return query(self,'nodraw',self.hidden==true) end
    function e:IsPlayer() return query(self,'player',self.player==true) end
    function e:Alive() return query(self,'alive',self.alive~=false) end
    function e:GetNW2String(k,d) local v=self.nw[k];if v==nil then v=d end;return query(self,k,v) end
    function e:GetNW2Bool(k,d) local v=self.nw[k];if v==nil then v=d end;return query(self,k,v) end
    function e:GetPos()
        query(self,'position',self.pos);note('pos',self.pos.x,self.pos.y,self.pos.z)
        if self.onPosition then self.onPosition(self) end
        return self.pos
    end
    function e:WorldSpaceCenter()
        query(self,'center',self.center);note('center-pos',self.center.x,self.center.y,self.center.z)
        if self.onCenter then self.onCenter(self) end
        return self.center
    end
    return e
end
local scenarios=0
local function draw(e,size,label)
    scenarios=scenarios+1;note('case',label,e.id,size or 'nil');M:DrawAura(e,size)
end
local e=actor()
for _,size in ipairs({-2,-0.0,0,.33,10/19-1e-12,10/19,10/19+1e-12,
    .9999999999999999,1,1.0000000000000002,1.33,40/19-1e-12,40/19,40/19+1e-12,4}) do
    for _,reduced in ipairs({true,false}) do
        low=reduced
        for _,t in ipairs({0,10,1000.125}) do
            clock=t;draw(e,size,'size/phase');draw(e,size,'repeat')
        end
    end
end
low=true;clock=10
draw(e,nil,'default size')
for _,flag in ipairs({'hidden','cloaked','invalid','dead-player','ordinary-player','soldier'}) do
    e.hidden=flag=='hidden';e.cloaked=flag=='cloaked';e.valid=flag~='invalid'
    e.player=flag=='dead-player' or flag=='ordinary-player' or flag=='soldier'
    e.alive=flag~='dead-player';e.nw.LOD_IsSoldier=flag=='soldier'
    draw(e,1,flag)
end
e.hidden=false;e.cloaked=false;e.valid=true;e.player=false;e.alive=true
for _,x in ipairs({1599.9999999999998,1600,1600.0000000000002}) do
    e.pos=Vector(x,0,0);draw(e,1,'distance boundary')
end
e.pos=Vector(10,20,2)
e.nw.LOD_MonsterElement='';draw(e,1,'untyped')
e.nw.LOD_StatusMuted=true;draw(e,1,'status supplies aura')
e.nw.LOD_StatusHeld=true;draw(e,1,'status priority')
LOD.Equipment.StatusPresentation.first.color[1]=240;draw(e,1,'live status color')
e.nw.LOD_StatusHeld=false;e.nw.LOD_StatusMuted=false;e.nw.LOD_MonsterElement='ice';draw(e,1,'live element')
e.onCenter=function(self) low=false;self.center=Vector(-10,30,80) end
draw(e,1,'center callback changes preference');e.onCenter=nil;low=true
cv=nil;draw(e,1,'missing preference');cv={GetBool=function() note('low',low);return low end}
-- Replacements preserve their ordinary calls, including impure custom helpers.
local calls=0
math.cos=function(n) calls=calls+1;return nativeCos(n)+calls*.01 end
draw(e,1,'custom cosine');draw(e,1,'custom cosine repeated');math.cos=cos
math.sin=function(n) calls=calls+1;return nativeSin(n)-calls*.01 end
draw(e,1,'custom sine');draw(e,1,'custom sine repeated');math.sin=sin
math.pi=nativePi+.125;draw(e,1,'custom pi');math.pi=nativePi
for _,changed in ipairs({'cos','sin','pi','nested','preference','color'}) do
    callback=function()
        if changed=='cos' then math.cos=function(n) return nativeCos(n)+.25 end
        elseif changed=='sin' then math.sin=function(n) return nativeSin(n)-.25 end
        elseif changed=='pi' then math.pi=nativePi+.25
        elseif changed=='nested' then draw(e,1.33,'nested same actor different radius')
        elseif changed=='preference' then low=false
        else LOD.MagicArea.Colors.ice.r=200 end
    end
    draw(e,1,'sprite callback '..changed)
    math.cos,math.sin,math.pi=cos,sin,nativePi;low=true
end
local clamp=math.Clamp
math.Clamp=function() return 0/0 end
draw(e,1,'NaN radius');draw(e,1,'NaN repeated');math.Clamp=clamp
callback=function() error('injected sprite error',0) end
assert(not pcall(function() draw(e,1,'native failure') end))
draw(e,1,'retry after native failure')
M=load();draw(e,1,'Lua refresh')
-- The same entity can be reused through full update/life changes. Every input
-- remains live; only the exact two radius-dependent offsets are reusable.
e.pos=Vector(90,-10,4);e.center=Vector(90,-10,52);draw(e,.33,'full update/reincarnation')
e.valid=false;draw(e,1,'removed');e.valid=true;draw(e,1.33,'revived')
local retired=actor();draw(retired,1,'weak retirement')
local weak=setmetatable({retired},{__mode='v'});retired=nil
collectgarbage('collect');collectgarbage('collect');assert(not weak[1],'orbit cache retains actor')

-- Frozen parent and candidate execute identical moving actors. Count every
-- native read, vector/color allocation and sprite; only trig work may fall.
M=load();LOD.Equipment.StatusOrder={};cv={GetBool=function()
    if recording then counts.getters=counts.getters+1 end;return true
end}
local actors={};for i=1,58 do actors[i]=actor() end
counts={trig=0,getters=0,vectors=0,colors=0,sprites=0};recording=true
for frame=1,240 do
    for i,ent in ipairs(actors) do
        ent.pos.x=10+frame*.25;ent.center.x=ent.pos.x
        M:DrawAura(ent,.33+i/100)
    end
end
recording=false
local report=string.format('MONSTER_AURA_ORBIT_WORK scenarios=%d draws=13920 trig=%d getters=%d vectors=%d colors=%d sprites=%d trace_rows=%d native_fps_measured=false',
    scenarios,counts.trig,counts.getters,counts.vectors,counts.colors,counts.sprites,#trace)
if tracePath then local f=assert(io.open(tracePath,'w'));f:write(table.concat(trace,'\n'));f:close() end
print(report)
assert(counts.getters==12*13920 and counts.sprites==27840 and counts.vectors==7*13920
    and counts.colors==13920,'changed native input/sprite/allocation work')
if mode=='--gate' then assert(counts.trig==4*58,'unchanged reduced orbit repeats trigonometry') end
print('MONSTER_AURA_ORBIT_PASS exact native input/sprite traces; boundaries/statuses/preferences/custom helpers/nested callbacks/refresh/retry/weak retirement; not hardware FPS')
