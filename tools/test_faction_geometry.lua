-- Execute actual area/cone/beam selectors, Magic projectile Think and Soldier
-- bolt Think. Engine traces and final dice/HP transport are explicit boundaries.
local env=dofile('tools/test_faction_damage.lua')
local F,S=env.F,env.S
local h,ally=table.unpack(env.heroes)
local m,m2=table.unpack(env.enemies)
local soldier=env.soldiers[1]
local checks=0
local function check(ok,label) checks=checks+1;assert(ok,'FACTION_GEOMETRY: '..label) end
local noop=function() end
local root='gamemodes/legend_of_deborah/gamemode/'
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:LengthSqr() return self:Dot(self) end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:Distance(b) return (self-b):Length() end
function V:GetNormalized() return self*(1/math.max(.00001,self:Length())) end
function V:Angle() return {p=0,y=0} end
vector_origin=Vector()
for i,p in ipairs({h,ally,m,m2,soldier}) do
 p.pos=Vector(i*10,0,0)
 p.GetPos=function(self) return self.pos end;p.WorldSpaceCenter=p.GetPos;p.GetShootPos=p.GetPos
 p.GetAimVector=function() return Vector(1,0,0) end;p.EmitSound=noop
end
h.pos=Vector(0,0,0);ally.pos=Vector(40,0,0);m.pos=Vector(60,0,0);m2.pos=Vector(75,0,0);soldier.pos=Vector(90,0,0)
player.GetAll=function() return {h,ally,soldier} end
LOD.HostileRegistry.List=function() return {m,m2} end
LOD.Magic={};LOD.CharacterProgressionSystem={};LOD.MagicProgression={};LOD.CombatRolls={}
LOD.RPG.MagicForms={bolt={id="bolt"}};LOD.RPG.MagicContents={}
LOD.Config.Maze={CellSize=384,LevelHeight=384}
LOD.MazeNavigator={WorldToCell=function() return {x=0,y=0,z=0} end,CanTraverse=function() return true end}
LOD.RunManager.State.Graph={Cells={['0:0:0']={x=0,y=0,z=0,neighbors={}}}}
LOD.MazeBuilder={CellCenter=function() return Vector() end}
net={};for _,name in ipairs({'Start','WriteUInt','WriteString','WriteVector','WriteFloat','WriteEntity','Broadcast'}) do net[name]=noop end
local cover=false
util={AddNetworkString=noop,TraceLine=function(t) return {Hit=cover,Fraction=cover and .5 or 1,HitPos=t.endpos} end}
MASK_SOLID=1;MASK_SHOT=2;DMG_BULLET=1;DMG_ENERGYBEAM=2
MOVETYPE_NONE=0;SOLID_NONE=0;COLLISION_GROUP_PROJECTILE=0
local includeBoundary=include
include=noop;dofile(root..'lod/sv_magic_forms.lua')
local Forms=LOD.MagicForms
Forms.ActiveSummons={} -- the core matrix separately exercises summon allegiance
local function contains(list,wanted) for _,p in ipairs(list) do if p==wanted then return true end end;return false end
check(not contains(Forms:_AreaTargets(h,h.pos,100),ally),'ordinary area excludes teammate')
env.reckless(h)
check(contains(Forms:_AreaTargets(h,h.pos,100),ally),'Reckless area includes actual in-radius ally')
check(contains(Forms:_BlastTargets(h,0),ally),'graph-footprint blast includes legal ally')
check(contains(Forms:_ConeTargets(h,h.pos,Vector(1,0,0),100),ally),'Cone includes forward ally')
ally.pos=Vector(-40,0,0)
check(not contains(Forms:_ConeTargets(h,h.pos,Vector(1,0,0),100),ally),'Cone does not damage behind caster')
ally.pos=Vector(400,0,0);check(not contains(Forms:_AreaTargets(h,h.pos,100),ally),'Reckless does not enlarge radius')
ally.pos=Vector(40,0,0);cover=true
check(not contains(Forms:_AreaTargets(h,h.pos,100),ally),'solid cover still rejects ally damage')
cover=false
local context={spatialBonusCells=0,castSerial=7};F:CaptureAttackPermission(h,context)
S:Clear(h,'reckless')
check(contains(Forms:_AreaTargets(h,h.pos,100,context),ally),'committed area keeps exact source permission')
check(not contains(Forms:_AreaTargets(h,h.pos,100,{}),ally),'new area cannot borrow expired permission')
local hit={}
Forms._ApplyDamage=function(_,source,credit,target,form,content,event)
 -- Native transport exercises the real faction/GM gates; damage dice/mitigation
 -- have their separate retained production suites.
 target.TakeDamageInfo=function(_,info) hit[target]=(hit[target] or 0)+env.damage(info:GetAttacker(),target,info:GetInflictor()) end
 local info={GetAttacker=function() return credit end,GetInflictor=function() return source end}
 F:DealDamage(target,info,event,source)
 return true
end
local tracing=0
util.TraceLine=function(t)
 tracing=tracing+1
 if tracing==1 then return {Hit=true,Fraction=.1,HitPos=ally.pos,Entity=ally} end
 return {Hit=false,Fraction=1,HitPos=t.endpos}
end
check(Forms:_CastBeam(h,{id='beam'},nil,context) and hit[ally]==10,'real Beam reaches ally and both damage gates')
-- A real delayed projectile impact resolves after cure, without licensing a new cast.
util.TraceLine=function(t) return {Hit=false,Fraction=1,HitPos=t.endpos} end
local projectile={valid=true,LODCaster=h,LODCastContext=context,LODFormId='bolt',LODDirection=Vector(1,0,0),
 GetPos=function() return ally.pos end,Remove=function(self) self.valid=false end}
Forms:ProjectileImpact(projectile,{Entity=ally,HitPos=ally.pos})
check(hit[ally]==20 and not projectile.valid,'committed Bolt finishes exactly once after cure')
Forms:ProjectileImpact(projectile,{Entity=ally});check(hit[ally]==20,'duplicate projectile impact cannot repeat')
local MagicEnt={};ENT=MagicEnt;dofile('gamemodes/legend_of_deborah/entities/entities/lod_magic_projectile/init.lua')
local function movingProjectile(owner,form,event)
 local p={valid=true,LODCaster=owner,LODOwner=owner,LODFormId=form,LODCastContext=event,LODAttackEvent=event,
  LODLastThink=CurTime()-.05,LODExpireAt=CurTime()+2,LODVelocity=Vector(100,0,0),LODDirection=Vector(1,0,0),
  LODMaximumTravel=10000,LODTravelled=0,LODDamage=10,pos=Vector()}
 function p:GetPos() return self.pos end;function p:SetPos(v) self.pos=v end
 function p:GetForward() return Vector(1,0,0) end
 function p:Remove() self.valid=false end
 p.NextThink=noop;p.SetAngles=noop
 return p
end
local filterChecks=0
util.TraceHull=function(t)
 check(t.filter(ally)==true,'actual Magic projectile trace admits committed ally');filterChecks=filterChecks+1
 return {Hit=false,Fraction=1,HitPos=t.endpos}
end
local mp=movingProjectile(h,'bolt',context);setmetatable(mp,{__index=MagicEnt});mp:Think()
check(filterChecks==1,'real Magic Think owns the trace filter')
local Bolt={};ENT=Bolt;dofile('gamemodes/legend_of_deborah/entities/entities/lod_soldier_bolt/init.lua')
ents={FindAlongRay=function() return {} end}
function LOD.NewDamageInfo()
 local i={};i.SetDamage=function(self,v) self.amount=v end;i.GetDamage=function(self) return self.amount end
 i.SetAttacker=function(self,v) self.a=v end;i.GetAttacker=function(self) return self.a end
 i.SetInflictor=function(self,v) self.b=v end;i.GetInflictor=function(self) return self.b end
 i.SetDamageType=noop;i.SetDamagePosition=noop;return i
end
local boltHits=0
m2.TakeDamageInfo=function(_,info) boltHits=boltHits+env.damage(info:GetAttacker(),m2,info:GetInflictor()) end
for _,reckless in ipairs({false,true}) do
 local event={}
 if reckless then env.reckless(m,1) end
 F:CaptureAttackPermission(m,event)
 if reckless then env.clock(CurTime()+1) end
 local b=movingProjectile(m,'soldier',event);setmetatable(b,{__index=Bolt})
 util.TraceHull=function(t)
  check(t.filter(m2)==reckless,'Soldier trace distinguishes ordinary ally from committed Reckless ally')
  return {Hit=reckless,Entity=m2,HitPos=m2.pos}
 end
 b:Think()
 check(boltHits==(reckless and 10 or 0),'actual Soldier projectile applies authorized ally HP damage')
end
check(not S:Has(m,'reckless') and not F:CanDamage(m,m2,{}),'completed bolt did not leave Reckless globally active')
include=includeBoundary
print('FACTION_GEOMETRY_PASS '..checks..' production-path assertions')
