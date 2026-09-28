-- Production seams against the pre-change math; native APIs are doubles.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local mt={};mt.__index=mt
local normalizations=0
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},mt) end
mt.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
mt.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
mt.__mul=function(a,n) return Vector(a.x*n,a.y*n,a.z*n) end
function mt:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function mt:DistToSqr(b) return (self-b):LengthSqr() end
function mt:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function mt:GetNormalized()
    normalizations=normalizations+1
    local length=math.sqrt(self:LengthSqr())
    return length>0 and self*(1/length) or Vector()
end
function mt:Angle() return {Right=function() return Vector(0,1,0) end} end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
math.Clamp=function(n,a,b) return math.max(a,math.min(b,n)) end
IsValid=function(e) return type(e)=='table' and not e.removed end
local now,eye,forward=10,Vector(),Vector(1,0,0)
CurTime=function() return now end
EyePos=function() return eye end
local traces=0
util={TraceLine=function(t) traces=traces+1;return {Hit=t.endpos.blocked==true} end}
local candidates={}
ents={FindInCone=function() return candidates end}
local viewer={EyePos=function() return eye end,EyeAngles=function() return {Forward=function() return forward end} end,
    GetEyeTrace=function(self) return {Entity=self.direct} end}
local function actor(id,pos)
    return {pos=pos,id=id,GetPos=function(e) return e.pos end,WorldSpaceCenter=function(e) return e.pos end,
        EntIndex=function(e) return e.id end,GetNoDraw=function(e) return e.hidden end,
        GetNW2Bool=function(e,k,default) return e[k] or default end,
        GetNW2Float=function(e,k,default) return e[k] or default end}
end
LOD={}
dofile(root..'sh_near_look.lua')
local look=LOD.NearLook
local cosine=math.cos(math.rad(6))
local function legacyQualifies(e,range)
    local delta=e.pos-eye;local d=delta:LengthSqr()
    return d<=range*range and (d==0 or delta:GetNormalized():Dot(forward)>=cosine) and look:Visible(viewer,e)
end
local comparisons=0
for yaw=-180,180,.25 do
    for _,distance in ipairs({0,1,100,511.99,512.01,900}) do
        local angle=math.rad(yaw)
        local e=actor(1,Vector(math.cos(angle)*distance,math.sin(angle)*distance,0))
        assert(look:Qualifies(viewer,e,512)==legacyQualifies(e,512),'cone/range drift at '..yaw..'/'..distance)
        comparisons=comparisons+1
    end
end
for _,yaw in ipairs({-6.0001,-5.9999,5.9999,6.0001}) do
    local r=math.rad(yaw);local e=actor(1,Vector(math.cos(r)*100,math.sin(r)*100,0))
    assert(look:Qualifies(viewer,e,512)==(math.abs(yaw)<6),'cone boundary drift')
end
local function legacyFind()
    local best,score,distance
    for _,e in ipairs(candidates) do
        if look:Visible(viewer,e) then
            local delta=e.pos-eye;local d=delta:LengthSqr()
            local dot=d>0 and delta:GetNormalized():Dot(forward) or 1
            if d<=512^2 and dot>=cosine and (not score or dot>score
                or dot==score and (d<distance or d==distance and e.id<best.id)) then
                best,score,distance=e,dot,d
            end
        end
    end
    return best
end
for i=1,64 do
    local a=math.rad((i-1)*.075)
    candidates[i]=actor(i,Vector(100*math.cos(a),100*math.sin(a),0))
end
traces=0;local expected=legacyFind();local oldTraces=traces
traces=0;normalizations=0
assert(look:Find(viewer,512,function() return true end)==expected)
assert(normalizations==0 and traces==1 and oldTraces==64)
local newTraces=traces
-- Better but occluded/hidden/cloaked candidates cannot suppress a visible one.
for _,mode in ipairs({'blocked','hidden','cloak'}) do
    candidates[1].pos.blocked=mode=='blocked';candidates[1].hidden=mode=='hidden'
    candidates[1].LOD_Watcher=mode=='cloak';candidates[1].LOD_WatcherInvisibleUntil=now+1
    assert(look:Find(viewer,512,function() return true end)==legacyFind(),mode)
end
candidates={actor(8,Vector(50,0,0)),actor(3,Vector(50,0,0)),actor(1,Vector(80,0,0))}
assert(look:Find(viewer,512,function() return true end).id==3,'distance then entity tie break')
viewer.direct=actor(99,Vector(100,20,0))
assert(look:Find(viewer,512,function() return true end)==viewer.direct,'direct trace priority')
viewer.direct=nil;candidates[2].removed=true
assert(look:Find(viewer,512,function() return true end).id==8,'invalid candidate')
eye=Vector(10,20,30);forward=Vector(0,0,1)
assert(look:Qualifies(viewer,actor(1,Vector(10,20,100)),512),'vertical view')
assert(not look:Qualifies(viewer,actor(1,Vector(10,20,-100)),512),'behind vertical view')
print(string.format('QUANTIZED_CONE_PASS: %d paired angle/range samples; no normalizations; 64-candidate LOS %d -> %d; obstruction/cloak/direct/tie cases',comparisons,oldTraces,newTraces))

-- Finite loot states retain the exact legacy curve and all dynamic modifiers.
dofile(root..'sh_rng.lua');dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
dofile(root..'sh_equipment_economy.lua')
local E=LOD.Equipment
local sqrt,log=math.sqrt,math.log;local roots,logs=0,0
math.sqrt=function(n) roots=roots+1;return sqrt(n) end
math.log=function(n) logs=logs+1;return log(n) end
local families={'ring','gloves','boots','headwear','vest','pants','shield','weapon_357'}
local function reference(level,family,rarity,quality)
    local d=type(level)=='number' and level==level and math.abs(level)<math.huge and math.floor(level) or 1
    d=math.max(1,math.min(E.ScalingDungeonCap,d))
    local base=100+math.floor(12*sqrt(d-1)+4*log(d)/log(2))
    local multiplier=E.Definitions[family] and E.Definitions[family].budgetMultiplier or (family=='gloves' and 2 or 1)
    return math.floor(base*multiplier*(E.Rarities[rarity or 1].factor/100)*(quality or 100)/100)+E:InnateValue(family,quality)
end
comparisons=0
for d=1,999 do for _,family in ipairs(families) do for rarity=1,4 do for _,quality in ipairs({90,100,110}) do
    assert(E:Budget(d,family,rarity,quality)==reference(d,family,rarity,quality),'loot value drift')
    comparisons=comparisons+1
end end end end
assert(roots==999 and logs==1998,'one curve evaluation per discrete depth')
for _,d in ipairs({-100,0,1.99,998.99,1000,1e20,math.huge,-math.huge,0/0,'20',false}) do
    assert(E:Budget(d,'ring')==reference(d,'ring'),'invalid/fractional depth drift')
end
local factor=E.Rarities[1].factor;E.Rarities[1].factor=123
assert(E:Budget(20,'ring')==reference(20,'ring'),'rarity cannot be cached')
E.Rarities[1].factor=factor
E.Definitions.quantization_probe={budgetMultiplier=3}
assert(E:Budget(20,'quantization_probe')==reference(20,'quantization_probe'),'family multiplier cannot be cached')
E.Definitions.quantization_probe=nil
E.ScalingDungeonCap=10000;E:Budget(10000,'ring');E:Budget(10000,'ring')
assert(roots==1001,'noncanonical depths must not grow the finite cache')
E.ScalingDungeonCap=999;math.sqrt,math.log=sqrt,log
print(string.format('QUANTIZED_LOOT_PASS: %d exact budget comparisons; sqrt %d -> 999; log %d -> 1998; live modifiers and bounded cache',comparisons,comparisons,comparisons*2))

-- Real receiver/render hook: snapshots bound direction work, not frame rate.
local hooks,receivers={},{}
hook={Add=function(_,id,f) hooks[id]=f end}
local packets,readAt,numberAt
net={Receive=function(id,f) receivers[id]=f end,
    ReadUInt=function() numberAt=numberAt+1;return numberAt==1 and #packets or packets[numberAt-1].kind end,
    ReadVector=function() readAt=readAt+1;local q=packets[math.ceil(readAt/2)];return readAt%2==1 and q.pos or q.velocity end}
Material=function(name) return name end
local beams={}
render={SetMaterial=noop,DrawSprite=noop,DrawBeam=function(a,b) beams[#beams+1]={a=a,b=b} end}
dofile(root..'cl_enemy_roster.lua')
local draw=hooks.LOD_RosterProjectiles
local function receive(list) packets=list;readAt,numberAt=0,0;receivers.LOD_RosterProjectiles() end
local function same(a,b) assert(a:DistToSqr(b)<1e-16,'projectile endpoint changed') end
eye=Vector();normalizations=0
local sample={}
for i=1,64 do sample[i]={pos=Vector(i,10,20),velocity=Vector(100+i,20,-10),kind=i%4} end
local expectedTrails={}
for i,q in ipairs(sample) do expectedTrails[i]=q.velocity:GetNormalized()*24 end
normalizations=0
for tick=0,9 do
    now=10+tick*.1;receive(sample)
    for frame=0,5 do
        now=10+tick*.1+frame/60;beams={};draw(false,false)
        assert(#beams==64)
        for i,q in ipairs(sample) do
            local pos=q.pos+q.velocity*math.min(.1,now-(10+tick*.1))
            same(beams[i].b,pos);same(beams[i].a,pos-expectedTrails[i])
        end
    end
end
assert(normalizations==640,'trail normalization repeats within snapshot')
local before=normalizations
now=12;receive({{pos=Vector(5000,0,0),velocity=Vector(100,0,0),kind=0}})
draw(false,false);assert(normalizations==before,'out-of-range snapshot did work')
eye=Vector(5000,0,0);draw(true,false);draw(false,true);assert(normalizations==before)
draw(false,false);assert(normalizations==before+1,'first visible frame must prepare its trail')
now=12.31;beams={};draw(false,false);assert(#beams==0,'stale snapshot did not expire')
eye=Vector();now=13;receive({{pos=Vector(20,0,0),velocity=Vector(),kind=3}})
beams={};draw(false,false);assert(#beams==5,'zero-velocity Reeler diamond lost')
same(beams[1].a,beams[1].b)
receive({});beams={};draw(false,false);assert(#beams==0,'empty replacement retained projectile')
print('QUANTIZED_PROJECTILE_PASS: 64 projectiles at 60 FPS / 10 snapshots: normalizations 3840 -> 640; identical smooth endpoints; hidden/expiry/zero-velocity/replacement cases')
