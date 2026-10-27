-- Native-shape regression, not engine/render acceptance. BUG018 froze clear
-- point rays and VISIBLE hulls; only MONSTER-inclusive nonzero-Z hulls hit BBox.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local V={} V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function Color(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
function IsValid(e) return type(e)=='table' and not e.invalid end
function CurTime() return 100 end
MASK_VISIBLE,CONTENTS_MONSTER=24705,33554432
bit=bit or {bor=function(a,b)
 local sum,p=0,1 while a>0 or b>0 do
  if a%2==1 or b%2==1 then sum=sum+p end
  a=math.floor(a/2) b=math.floor(b/2) p=p*2
 end return sum
end}
LOD={} dofile(root..'sh_config.lua') dofile(root..'sh_crate_visuals.lua')
local E={} E.__index=E
local function body(class,pos,lo,hi,kind)
 return setmetatable({class=class,pos=pos,lo=lo,hi=hi,kind=kind},E)
end
function E:GetClass() return self.class end
function E:GetPos() return self.pos end
function E:GetAngles() return {y=self.yaw or 0} end
function E:GetCollisionBounds() return self.lo,self.hi end
function E:GetBoxMins() return self.lo end
function E:GetBoxMaxs() return self.hi end
function E:GetBoxKind() return self.kind end
function E:GetOpened() return self.open==true end
function E:GetNoDraw() return self.hidden==true end
function E:GetNW2Bool(k,default) if k=='LOD_GeometryHidden' then return self.geometryHidden==true end return self[k] or default end
function E:GetNW2Float(k,default) return self[k] or default end
function E:WorldSpaceCenter() return self.pos end
function E:EntIndex() return self.id or 1054 end
local eye=Vector(-3040,3072,-12207.017578125)
local target=body('lod_loot_pickup',Vector(-2620,3072,-12229.96875))
local viewer={EyePos=function() return eye end,EyeAngles=function() return {Forward=function() return Vector(1,0,0) end} end,
 GetEyeTrace=function() return {} end}
local gate=body('lod_gate',Vector(-2880,3072,-12079.96875),Vector(-14,-192,-192),Vector(14,192,192))
local colliders={gate}
local oldBlock,oldTarget,lineCalls,hullCalls=nil,false,0,0
local function fraction(a,delta,pos,angle,lo,hi)
 local yaw=math.rad(angle.y or 0) local co,si=math.cos(yaw),math.sin(yaw)
 local d=a-pos local start={d.x*co+d.y*si,-d.x*si+d.y*co,d.z}
 local step={delta.x*co+delta.y*si,-delta.x*si+delta.y*co,delta.z}
 local lower,upper={lo.x,lo.y,lo.z},{hi.x,hi.y,hi.z} local first,last=0,1
 for axis=1,3 do
  if math.abs(step[axis])<1e-12 then if start[axis]<lower[axis] or start[axis]>upper[axis] then return nil end
  else
   local x,y=(lower[axis]-start[axis])/step[axis],(upper[axis]-start[axis])/step[axis]
   if x>y then x,y=y,x end first=math.max(first,x) last=math.min(last,y)
   if first>last then return nil end
  end
 end return first
end
util={IntersectRayWithOBB=function(a,d,pos,angle,lo,hi)
 local f=fraction(a,d,pos,angle,lo,hi) if f then return Vector(a.x+d.x*f,a.y+d.y*f,a.z+d.z*f),Vector(),f end
end,TraceLine=function(q)
 lineCalls=lineCalls+1 assert(q.mask==MASK_VISIBLE,'ordinary visible ray changed')
 return {Hit=oldBlock~=nil or oldTarget,Entity=oldBlock or (oldTarget and target or nil)}
end,TraceHull=function(q)
 hullCalls=hullCalls+1
 assert(q.ignoreworld==true,'fallback must not add world/sliver occlusion')
 assert(q.mins.x==0 and q.mins.y==0 and q.maxs.x==0 and q.maxs.y==0 and q.maxs.z==1,'sight widened horizontally')
 if math.floor(q.mask/CONTENTS_MONSTER)%2~=1 then return {Hit=false} end
 local best,first
 for _,e in ipairs(colliders) do
  -- Native broadphase includes entities before the callback; their complete
  -- collision bounds are deliberately independent of rendered body bands.
  local f=fraction(q.start,q.endpos-q.start,e.pos,e:GetAngles(),e.lo,e.hi)
  if f and q.filter(e) and (not first or f<first) then best,first=e,f end
 end
 return {Hit=best~=nil,Entity=best,Fraction=first or 1,Contents=best and 1 or 0}
end}
ents={FindInCone=function() return {target} end,
 FindByClass=function() error('near-look visibility must not scan the world') end,
 GetAll=function() error('near-look visibility must not scan all entities') end}
dofile(root..'sh_near_look.lua') local look=LOD.NearLook
assert(not look:Visible(viewer,target),'Health name revealed beyond native-shaped closed Red gate')
assert(not look:Qualifies(viewer,target,512) and not look:Find(viewer,512,function() return true end))
oldTarget=true
assert(not look:Visible(viewer,target),'target-hit legacy ray bypassed earlier generated cover')
oldTarget=false gate.open=true
assert(look:Visible(viewer,target),'opened gate retained false opaque cover')
gate.open=false colliders={}
local beforeLine,beforeHull=lineCalls,hullCalls
assert(look:Visible(viewer,target) and lineCalls==beforeLine+1 and hullCalls==beforeHull+1,'clear query is not one ray plus one hull')
oldTarget=true assert(look:Visible(viewer,target),'unobstructed target-hit positive lost') oldTarget=false
oldBlock=body('prop_physics') beforeHull=hullCalls
assert(not look:Visible(viewer,target) and hullCalls==beforeHull,'ordinary opaque ray must remain authoritative') oldBlock=nil
local function scene(z)
 eye=Vector(0,0,z) target.pos=Vector(400,0,z)
end
gate.pos=Vector(200,0,192) gate.hi=Vector(14,192,1000) colliders={gate}
scene(64) assert(not look:Visible(viewer,target),'closed body disappeared')
scene(450) assert(look:Visible(viewer,target),'invisible gate overhead became opaque')
gate.class='lod_jail_door' scene(64) assert(not look:Visible(viewer,target),'closed Jail door bypass')
gate.open=true assert(look:Visible(viewer,target),'opened Jail door remained opaque') gate.open=false
local box=body('lod_static_box',Vector(200,0,500),Vector(-64,-192,-500),Vector(64,192,500),4)
box.hidden=true -- accepted client proxy queue hides this collider, not its cargo visuals
colliders={box} scene(64) assert(not look:Visible(viewer,target),'opaque cargo-backed wall bypass')
scene(180) assert(not look:Visible(viewer,target),'second cargo body bypass')
scene(117.6567) assert(look:Visible(viewer,target),'real four-unit cargo gap was filled')
scene(300) assert(look:Visible(viewer,target),'invisible anti-bypass column became opaque')
assert(box.lo.z==-500 and box.hi.z==500,'visibility mutated networked/collision bounds')
for _,kind in ipairs({1,2,5}) do
 box.kind=kind scene(64) assert(not look:Visible(viewer,target),'rendered floor/stair/underdeck bypass')
 box.geometryHidden=true assert(look:Visible(viewer,target),'hidden false floor remained sight cover') box.geometryHidden=false
end
for _,kind in ipairs({3,7}) do box.kind=kind assert(look:Visible(viewer,target),'invisible rail/hut containment became opaque') end
local glass=body('prop_physics',Vector(80,0,64),Vector(-1,-32,-32),Vector(1,32,32))
local actor=body('lod_hostile',Vector(120,0,64),Vector(-16,-16,-36),Vector(16,16,36))
local grate=body('func_brush',Vector(150,0,64),Vector(-1,-32,-32),Vector(1,32,32))
scene(64) colliders={glass,actor,grate} assert(look:Visible(viewer,target),'fallback changed glass/grate/actor sight policy')
gate.class='lod_gate' colliders={glass,actor,grate,box,gate}
assert(not look:Visible(viewer,target),'ignored foreground collision hid a later closed gate from correction')
target.hidden=true beforeLine=lineCalls beforeHull=hullCalls
assert(not look:Visible(viewer,target) and lineCalls==beforeLine and hullCalls==beforeHull,'hidden target revealed or traced')
target.hidden=false target.LOD_Watcher=true target.LOD_WatcherInvisibleUntil=101
assert(not look:Visible(viewer,target),'cloaked target revealed')
target.LOD_WatcherInvisibleUntil=0 colliders={} target.pos=Vector(400,100,64)
assert(not look:Qualifies(viewer,target,512),'look-away tracking appeared')
assert(LOD.Config.Geometry.ContainerVisualEmbed==16 and LOD.Config.Geometry.StackVisualGap==4,'existing wall offsets retuned')
print('NEAR_LOOK_NATIVE_BOUNDS_PASS: exact gate/mask/hull negative; target-hit/clear/open controls; visible cargo bands/gap; invisible overhead/hut/rail; floor removal; original glass/grate/actor/ray/cloak policy; bounded queries')
