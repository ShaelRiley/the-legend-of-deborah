local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local F,R=LOD.MagicForms,fixture.Run
local v=getmetatable(Vector())
v.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
v.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
v.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
v.__unm=function(a) return a*-1 end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:LengthSqr() return self:Dot(self) end
function v:Length() return math.sqrt(self:LengthSqr()) end
function v:GetNormalized() return self*(1/math.max(self:Length(),.00001)) end
function v:Angle() return {} end
local now=0;CurTime=function() return now end
local hooks={};hook.Add=function(_,id,fn) hooks[id]=fn end
net.Start=function() end;net.WriteString=function() end;net.WriteVector=function() end
net.WriteEntity=function() end;net.WriteUInt=function() end;net.WriteFloat=function() end;net.Broadcast=function() end
local owner=fixture.actor('ball-owner');local other=fixture.actor('other-owner')
function owner:GetShootPos() return Vector(100,0,64) end
function owner:GetAimVector() return Vector(1,0,0) end
function owner:GetClass() return 'player' end
R.State.PlayerState['ball-owner']=owner.ps
LOD.Magic._EnsureState=function(_,p) return p.ps end
LOD.Magic._Sync=function() end;LOD.Magic.NextCast={};LOD.Magic.Stats={casts=0}
LOD.MagicProgression:GrantForm(owner.ps.progressionState,'super_ball')
LOD.MagicProgression:SelectForm(owner.ps.progressionState,'super_ball')
owner.ps.progressionState.contentIds={'fire'};owner.ps.progressionState.selectedMagicContentId='fire'
dofile(root..'sv_magic_super_ball.lua')
local env=setmetatable({ENT={},AddCSLuaFile=function() end},{__index=_G})
env.include=function() end
assert(loadfile('gamemodes/legend_of_deborah/entities/entities/lod_magic_projectile/init.lua','t',env))()
local function noop() end
local spawned={};ents={Create=function(class)
 assert(class=='lod_magic_projectile')
 local e=setmetatable({valid=true},{__index=env.ENT})
 for _,name in ipairs({'SetMagicForm','SetModel','SetMoveType','SetSolid','SetCollisionGroup','DrawShadow','SetRenderMode','SetColor','SetAngles','Activate','NextThink'}) do e[name]=noop end
 function e:SetPos(p) self.pos=p end;function e:GetPos() return self.pos end
 function e:Spawn() self:Initialize() end
 function e:Remove() self.valid=false;self:OnRemove() end
 function e:EmitSound(path) assert(path=='garrysmod/balloon_pop_cute.wav');self.sounds=(self.sounds or 0)+1 end
 spawned[#spawned+1]=e;return e
end}
local targets={}
for i,x in ipairs({40,160}) do
 local t=fixture.actor('ball-target'..i,true);t.pos=Vector(x,0,64)
 t.WorldSpaceCenter=function(self) return self.pos end;t.GetOwner=function() end
 targets[i]=t
end
LOD.FactionManager={IsOpponent=function(_,_,t) return IsValid(t) and t.LODHostile and t:Health()>0 end}
MASK_SOLID=1
-- Analytic swept hull against a corridor and two bodies, not pre-canned impacts.
local boxes={
 {lo=Vector(-100,-200,-100),hi=Vector(0,200,300)},
 {lo=Vector(200,-200,-100),hi=Vector(300,200,300)},
 {lo=Vector(0,-200,-100),hi=Vector(200,-45,300)},
 {lo=Vector(0,45,-100),hi=Vector(200,200,300)},
 {lo=Vector(0,-45,-100),hi=Vector(200,45,0)},
 {lo=Vector(0,-45,128),hi=Vector(200,45,300)}}
for _,t in ipairs(targets) do boxes[#boxes+1]={entity=t,lo=t.pos-Vector(8,35,54),hi=t.pos+Vector(8,35,54)} end
local function trace(data,radius,worldOnly)
 local delta=data.endpos-data.start;local result={Hit=false,Fraction=1,HitPos=data.endpos}
 for _,b in ipairs(boxes) do
  if not (worldOnly and b.entity) and (not b.entity or not data.filter or data.filter(b.entity)) then
   local lo,hi=b.lo-Vector(radius,radius,radius),b.hi+Vector(radius,radius,radius)
   local enter,leave,normal=0,1,Vector();local inside=true;local miss=false
   for _,axis in ipairs({'x','y','z'}) do
    local start,step=data.start[axis],delta[axis]
    if start<=lo[axis] or start>=hi[axis] then inside=false end
    if math.abs(step)<.00001 then if start<lo[axis] or start>hi[axis] then miss=true end
    else
     local a,c=(lo[axis]-start)/step,(hi[axis]-start)/step;local sign=-1
     if a>c then a,c=c,a;sign=1 end
     if a>enter then enter=a;normal=Vector();normal[axis]=sign end
     leave=math.min(leave,c)
    end
   end
   if inside then return {StartSolid=true,Hit=true,HitPos=data.start,Fraction=0} end
   if not miss and enter<=leave and enter>=0 and enter<result.Fraction and leave>0 then
    result={Hit=true,Fraction=enter,HitPos=data.start+delta*enter,HitNormal=normal,Entity=b.entity}
   end
  end
 end
 return result
end
local traces=0
util.TraceHull=function(d) traces=traces+1;assert(d.mask==MASK_SOLID);return trace(d,8,false) end
util.TraceLine=function(d) return trace(d,0,true) end
local hits,riders={},{}
local productionApply=F._ApplyDamage
F._ApplyDamage=function(_,caster,credit,target,form,content,context)
 assert(caster==owner and credit==owner and form.id=='super_ball' and context.equipmentSnapshot)
 hits[target]=(hits[target] or 0)+1
 if content and content.rider then riders[target]=(riders[target] or 0)+1 end
 target.hp=target.hp-1;return true
end
owner.ps.magic=100;assert(F:CastSelected(owner))
assert(owner.ps.magic==53,'32 base + 15 Fire uses the common cast transaction')
local ball=spawned[#spawned];assert(ball.LODBall and owner.nw.LOD_SuperBallRemaining==1)
for i=1,300 do
 now=i*.025;local before=traces
 if ball.valid then ball:Think() end
 assert(traces-before<=F.Tuning.SuperBall.steps,'Bounded traces even in corners')
 if not ball.valid then break end
end
assert(not ball.valid and hits[targets[1]] and hits[targets[2]],'Geometry must permit hitting both bodies')
assert(hits[targets[1]]>1 or hits[targets[2]]>1,'A ricochet may damage a body again')
assert(riders[targets[1]]==1 and riders[targets[2]]==1,'Content rider stays once per damaged target/cast')
assert(hits[targets[1]]+hits[targets[2]]==6,'Six contact opportunities, not unbounded corner damage')
assert(owner.nw.LOD_SuperBallRemaining==2 and not next(F.ActiveSuperBalls))
-- Authority rejects an apparent target beyond a solid floor; open shaft admits it.
local dummy={LODCaster=owner,LODCastContext=ball.LODCastContext,LODContentId='fire',LODDirection=Vector(1,0,0),GetPos=owner.GetShootPos}
targets[1].pos=Vector(100,0,200)
assert(not F:SuperBallHit(dummy,targets[1],owner:GetShootPos(),false))
local ceiling=table.remove(boxes,6)
assert(F:SuperBallHit(dummy,targets[1],owner:GetShootPos(),false));table.insert(boxes,6,ceiling)
-- Direct repeated collision in the same instant cannot damage again.
local function newBall(caster)
 local e=ents.Create('lod_magic_projectile');e.LODFormId='super_ball';e.LODCaster=caster or owner
 e.LODCastContext={castSerial=71,equipmentSnapshot={}};e.LODSpeed=900;e.LODDirection=Vector(1,0,0)
 e:SetPos(Vector(100,0,64));e:Spawn();return e
end
local repeated=newBall();local count=0
local oldHit=F.SuperBallHit;F.SuperBallHit=function() count=count+1;return true end
util.TraceHull=function(d) return {Hit=true,Fraction=0,HitPos=d.start,HitNormal=Vector(-1,0,0),Entity=targets[2]} end
repeated:Think();now=now+.025;repeated:Think();assert(count==1)
F.SuperBallHit=oldHit;repeated:Remove()
-- Lifecycle and capacity belong to each caster; failed casts spend nothing.
util.TraceHull=function(d) return {Hit=false,Fraction=1,HitPos=d.endpos} end
local a,b=newBall(),newBall();assert(owner.nw.LOD_SuperBallRemaining==0)
owner.ps.magic=100;LOD.Magic.NextCast[owner]=0
local ok,why=F:CastSelected(owner);assert(not ok and why=='super_ball_cap' and owner.ps.magic==100)
local c=newBall(other);hooks.LOD_SuperBallDisconnect(other);assert(not c.valid and a.valid)
hooks.LOD_SuperBallDeath(owner);assert(not a.valid and not b.valid)
local expired=newBall();now=now+7;expired:Think();assert(not expired.valid)
local reset=newBall();R.State.LevelSeed=R.State.LevelSeed+1;reset:Think();assert(not reset.valid)
local dead=newBall();owner.hp=0;now=now+.02;dead:Think();assert(not dead.valid);owner.hp=100
local failed=newBall();R.State.Failed=true;now=now+.02;failed:Think();assert(not failed.valid);R.State.Failed=false
local embedded=newBall();util.TraceHull=function() return {StartSolid=true} end
now=now+.02;embedded:Think();assert(not embedded.valid)
local clean=newBall();hooks.LOD_SuperBallCleanup();assert(not clean.valid and not next(F.ActiveSuperBalls))
F._ApplyDamage=productionApply
print('SUPER_BALL_PASS: real cast/cost, geometric multi-body/repeat ricochets, one rider per target, floor/open-shaft cover, cooldown, caps, expiry, death/disconnect/level/cleanup')
