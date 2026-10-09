-- Real hostile Draw and scale authority; only Source's native boundaries are
-- doubled. --probe SOURCE TRACE records the parent without the work bound.
local mode = arg[1] or '--gate'
local source = arg[2] or 'gamemodes/legend_of_deborah/entities/entities/lod_hostile/cl_init.lua'
local tracePath = arg[3]
local trace, recording = {}, false
local counts = {formats=0, getters=0, matrices=0, bounds=0, draws=0}
local format = string.format
local pattern = '%s:%.4f:%s:%s:%.2f:%.2f:%.2f'
string.format = function(fmt, ...)
    if recording and fmt == pattern then counts.formats = counts.formats + 1 end
    return format(fmt, ...)
end
local function scalar(v)
    if type(v) == 'number' then return format('%.17g', v) end
    if type(v) == 'table' and v.x then return scalar(v.x)..','..scalar(v.y)..','..scalar(v.z) end
    if type(v) == 'table' and v.p then return scalar(v.p)..','..scalar(v.y)..','..scalar(v.r) end
    if type(v) == 'table' then return 'table' end
    return tostring(v)
end
local function note(...)
    local parts={...};for i,v in ipairs(parts) do parts[i]=scalar(v) end
    trace[#trace+1]=table.concat(parts,'|')
end
local noop=function() end
local vector={};vector.__index=vector
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vector) end
vector.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
vector.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
vector.__mul=function(a,n) return Vector(a.x*n,a.y*n,a.z*n) end
function vector:Length() return math.sqrt(self.x*self.x+self.y*self.y+self.z*self.z) end
function vector:Angle() return Angle(0,math.deg(math.atan(self.y,self.x)),0) end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
math.Clamp=function(n,a,b) return math.max(a,math.min(b,n)) end
include=noop;Material=function(n) return n end;ENT={};concommand={Add=noop}
vector_origin=Vector()
local now=10;CurTime=function() return now end
util={GetModelBounds=function(model)
    note('model-bounds',model)
    return Vector(-16,-18,model=='replacement' and -12 or -3),Vector(16,18,72)
end}
function Matrix()
    local m={}
    m.Scale=function(_,v) note('matrix-scale',v) end
    m.Rotate=function(_,v) note('matrix-rotate',v) end
    m.SetTranslation=function(_,v) note('matrix-translation',v) end
    return m
end
render={}
for _,name in ipairs({'SuppressEngineLighting','MaterialOverride','SetColorModulation','SetBlend'}) do
    render[name]=function(...) note(name,...) end
end
LOD={RuntimeReceipts={},EnemyDeathPulse=function(t) note('death-pulse',t);return .25 end}
local function pose(e,label)
    note(label,e.id)
    if e.pose then e.pose(e,label) end
end
LOD.WardenPresentation={Pose=function(_,e) pose(e,'warden-pose') end,Draw=function(_,e,s) note('warden-draw',e.id,s) end}
LOD.NeilBrutePresentation={Pose=function(_,e) pose(e,'neil-pose') end,Draw=function(_,e,s) note('neil-draw',e.id,s) end}
LOD.MonsterIdentity={DrawBody=function(_,e) e:DrawModel() end,DrawAura=function(_,e,s) note('aura',e.id,s) end}
LOD.EnemyRosterVisual={CloseRecoil=function(_,e)
    note('recoil',e.id,e.recoil or 0)
    if e.recoilCallback then e.recoilCallback(e) end
    return e.recoil or 0
end,Draw=function(_,e,s) note('roster-draw',e.id,s) end,Remains=function(_,e) note('remains',e.id) end}
LOD.BossPresentation={DrawActor=function(_,e) note('boss-draw',e.id) end}
dofile(source)
local serial=0
local function actor(archetype)
    serial=serial+1
    local e={id=serial,pos=Vector(serial*17,0,2),model='ordinary',nw={LOD_Archetype=archetype,LOD_SizeScale=1,LOD_MotionV2=true}}
    function e:GetModel()
        if recording then counts.getters=counts.getters+1 end
        note('model',self.id,self.model)
        if self.modelCallback then self.modelCallback(self) end
        return self.model
    end
    function e:GetPos()
        if recording then counts.getters=counts.getters+1 end
        note('position',self.id,self.pos);return self.pos
    end
    local function nw(self,k,d)
        if recording then counts.getters=counts.getters+1 end
        local v=self.nw[k];if v==nil then v=d end
        note('nw',self.id,k,v)
        if self.nwCallback then self.nwCallback(self,k) end
        return v
    end
    e.GetNW2String=nw;e.GetNW2Float=nw;e.GetNW2Bool=nw;e.GetNW2Int=nw
    function e:EnableMatrix(k)
        if recording then counts.matrices=counts.matrices+1 end
        note('enable',self.id,k)
    end
    function e:SetRenderBounds(lo,hi)
        if recording then counts.bounds=counts.bounds+1 end
        note('bounds',self.id,lo,hi)
        if self.boundsCallback then self.boundsCallback(self) end
    end
    function e:DrawModel()
        if recording then counts.draws=counts.draws+1 end
        note('model-draw',self.id)
    end
    return e
end
local scenarios=0
local function draw(e,label)
    scenarios=scenarios+1;note('case',label,e.id)
    ENT.Draw(e)
    note('state',e.id,e.LODLastClientVisualScale or 'nil',e.LODVisualVerticalCompensation or 0,e.LODSeekerVisualRoll or 0)
end
-- Exercise every distinct scale/bounds branch and both sides of the original
-- rounded signature thresholds. A changed input must not bypass those rules.
local archetypes={'shambler','runner','soldier','blitzer','bigcrab','climber','watcher','razor','seeker',
    'sentry','cordon','nodule','lurker','relay','lacemaker','censor','surveyor','fusilier','bombardier',
    'halter','pacer','interposer','mourner','siphoner','accumulator','exactor','absolver','conductor',
    'listener','shy','censer','trailmaker','towline','screenwright','afterburst','outrider','warden'}
for _,id in ipairs(archetypes) do
    local e=actor(id)
    for _,size in ipairs({.2,.33,.999949,.999951,1,1.000001,1.000049,1.000051,1.33,2}) do
        e.nw.LOD_SizeScale=size;draw(e,id..' size');draw(e,id..' repeated')
    end
    e.nw.LOD_MotionV2=false;draw(e,id..' legacy motion')
    e.model='replacement';draw(e,id..' model changed')
    e.nw.LOD_WardenPhase=2;draw(e,id..' phase changed')
    e.LODLastClientVisualScale=nil;draw(e,id..' native cache cleared')
end
local e=actor('watcher')
for _,r in ipairs({0,-0.0,0,.004999,.005001,-.004999,-.005001,4,-4,math.huge,-math.huge,0/0}) do
    e.recoil=r;draw(e,'recoil threshold');draw(e,'recoil repeated')
end
e=actor('seeker')
for _,d in ipairs({0,.009999,.010001,1,180,180.001,2}) do
    e.pos=e.pos+Vector(d,0,0);draw(e,'physical roll threshold')
end
e.LODSeekerVisualRoll=-0.0;draw(e,'negative zero roll')
e.LODSeekerVisualRoll=0;draw(e,'positive zero roll')
e.nw.LOD_DeathPulseStart=9;draw(e,'dying')
e.nw.LOD_WardenHidden=true;draw(e,'dying hidden')
e.nw.LOD_DeathPulseStart=-1;draw(e,'hidden alive')
e.nw.LOD_WardenHidden=false;e.nw.LOD_BossId='gordon';draw(e,'modular boss dispatch')
e.nw.LOD_BossId='';draw(e,'ordinary again')
-- Every native read and pose/recoil callback remains live, including immediate
-- input changes and clearing the older matrix cache after key construction.
e=actor('watcher')
e.pose=function(a,label) if label=='neil-pose' then a.nw.LOD_SizeScale=.75 end end
draw(e,'pose mutation');e.pose=nil
e.modelCallback=function(a) a.nw.LOD_Archetype='lurker' end
draw(e,'native model callback');e.modelCallback=nil
e.nwCallback=function(a,k) if k=='LOD_MotionV2' then a.model='replacement' end end
draw(e,'network callback');e.nwCallback=nil
e.nw.LOD_Archetype='watcher';e.recoilCallback=function(a) a.recoil=.25 end
draw(e,'live recoil callback');e.recoilCallback=nil
e.boundsCallback=function(a) a.LODLastClientVisualScale=nil end
e.nw.LOD_SizeScale=.8;draw(e,'bounds callback');draw(e,'bounds invalidated old cache');e.boundsCallback=nil
local conversions=0
e.nw.LOD_MotionV2=setmetatable({}, {__tostring=function() conversions=conversions+1;return 'custom'..conversions end})
draw(e,'custom conversion');draw(e,'custom conversion repeated')
assert(conversions==2,'custom motion conversion was cached')
e.nw.LOD_MotionV2=true;draw(e,'scalar path restored')
local firstFormatter=string.format
string.format=function(fmt,...) return firstFormatter(fmt,...) end
draw(e,'formatter replaced');string.format=firstFormatter;draw(e,'formatter restored')
local firstConverter=tostring
tostring=function(v) return firstConverter(v) end
draw(e,'converter replaced');tostring=firstConverter;draw(e,'converter restored')
dofile(source);draw(e,'Lua refresh');e.LODLastClientVisualScale=nil;draw(e,'retained entity full update')
local weak=setmetatable({}, {__mode='k'})
do local retired=actor('shambler');weak[retired]=true;draw(retired,'retired entity') end
collectgarbage('collect');collectgarbage('collect');assert(next(weak)==nil,'visual key cache retains retired entity')
-- Representative active scene: 58 visible bodies, 240 draws apiece. All
-- native inputs and model submissions stay live; only stable key formatting
-- may be reused. Count every added native getter (there should be none).
counts={formats=0,getters=0,matrices=0,bounds=0,draws=0}
local actors={};for i=1,58 do actors[i]=actor('shambler') end
recording=true
for frame=1,240 do
    now=10+frame/40
    for _,a in ipairs(actors) do draw(a,'stable body') end
end
recording=false
assert(counts.getters==13920*9+58 and counts.draws==13920 and counts.matrices==58 and counts.bounds==58,
    format('native cadence changed: getters=%d draws=%d matrices=%d bounds=%d',counts.getters,counts.draws,counts.matrices,counts.bounds))
if tracePath then local f=assert(io.open(tracePath,'w'));f:write(table.concat(trace,'\n'),'\n');f:close() end
print(format('HOSTILE_SCALE_WORK scenarios=%d draws=%d formats=%d getters=%d matrices=%d bounds=%d trace_lines=%d',
    scenarios,counts.draws,counts.formats,counts.getters,counts.matrices,counts.bounds,#trace))
if mode~='--probe' then assert(counts.formats==58,'stable scale keys are still formatted every draw') end
print('HOSTILE_SCALE_WORK_PASS: original rounding, all visual branches, native callbacks, roll/recoil, death/hidden/boss, custom fallback and lifecycle; not native FPS')
