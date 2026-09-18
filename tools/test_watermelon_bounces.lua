local fx=dofile('tools/test_magic_wall.lua')
local F,owner,boxes=fx.F,fx.owner,fx.boxes
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sv_magic_watermelon.lua')
local env=setmetatable({ENT={},include=function() end,AddCSLuaFile=function() end},{__index=_G})
assert(loadfile('gamemodes/legend_of_deborah/entities/entities/lod_magic_projectile/init.lua','t',env))()
local now=100;fx.setTime(now)
for i=#boxes,1,-1 do boxes[i]=nil end
boxes[1]={lo=Vector(-10000,-10000,-30),hi=Vector(10000,10000,0)}
local messages,visuals={},{ }
LOD.RPGPresentation.Event=function(_,_,kind,text,data) messages[#messages+1]=data end
F.BroadcastFX=function(_,form) visuals[#visuals+1]=form end
local rng=LOD.CombatRolls._RNG
local limit=1;LOD.CombatRolls._RNG=function() return {Int=function(_,lo,hi) assert(lo==1 and hi==6);return limit end} end
local function melon()
 local e=setmetatable({valid=true,LODCaster=owner,LODFormId='watermelon',LODContentId='fire',LODLevelSeed=fx.Run.State.LevelSeed,
  LODCastContext={castSerial=123,damageDiceUsed=0},LODMaximumTravel=4000,LODBlastRadius=72,
  LODDirection=Vector(1,0,0),LODSpeed=580}, {__index=env.ENT})
 for _,key in ipairs({'SetMagicForm','SetModel','SetMoveType','SetSolid','SetCollisionGroup','DrawShadow','SetRenderMode','SetColor','SetAngles','NextThink'}) do e[key]=function() end end
 function e:SetPos(pos) self.pos=pos end;function e:GetPos() return self.pos end
 function e:Remove() self.valid=false;self:OnRemove() end
 e:SetPos(Vector(0,0,64));e:Initialize();return e
end
local originalImpact=F.ProjectileImpact
local finalCount=0
F.ProjectileImpact=function(_,ent,tr)
 assert(not ent.finished,'No repeated final shatter');ent.finished=true;ent.finalAt=ent.LODMelon.bounces
 finalCount=finalCount+1;ent:Remove()
end
for count=1,6 do
 limit=count;local e=melon();local ticks=0
 while e.valid and ticks<1000 do now=now+.01;fx.setTime(now);e:Think();ticks=ticks+1 end
 assert(e.finished and e.finalAt==count,'Must complete rolled bounce budget on open floor: '..count)
 assert(messages[#messages].total==count and messages[#messages].sides==6)
end
assert(finalCount==6)
-- Repeated callbacks while departing the same face consume nothing.
limit=6;local e=melon();e.LODVelocity=Vector(100,0,200)
local nativeTrace=util.TraceHull
util.TraceHull=function(d) return {Hit=true,HitPos=d.start,HitNormal=Vector(0,0,1),Fraction=0} end
F:StepWatermelon(e,.01,function() return true end);assert(e.LODMelon.bounces==0 and e.valid)
-- Incoming body hits share cooldown/rider bookkeeping; terminal area is separate.
local target=fx.actor('melon-target',true)
F.TargetIsOpponent=function(_,_,t) return t==target end
F.LineOfEffect=function() return true end
local damage,riders=0,0
local oldDamage=F._ApplyDamage
F._ApplyDamage=function(_,_,_,t,form,content)
 assert(form.id=='watermelon');damage=damage+1;if content and content.rider then riders=riders+1 end
 t.hp=t.hp-1
end
util.TraceHull=function(d) return {Hit=true,HitPos=d.endpos,HitNormal=Vector(-1,0,0),Fraction=1,Entity=target} end
for _=1,2 do e.LODVelocity=Vector(100,0,0);F:StepWatermelon(e,.01,function() return true end) end
assert(damage==1 and riders==1,'Rapid repeated body contact does not multiply damage')
now=now+.5;fx.setTime(now);e.LODVelocity=Vector(100,0,0);F:StepWatermelon(e,.01,function() return true end)
assert(damage==2 and riders==1,'Later bounce damages, rider remains once per target')
-- Execute real terminal impact twice, proving one AoE and no extra Content rider.
F.ProjectileImpact=originalImpact
F._AreaTargets=function() return {target} end
net.Start=function() end;net.WriteString=function() end;net.WriteVector=function() end
net.WriteEntity=function() end;net.WriteUInt=function() end;net.WriteFloat=function() end;net.Broadcast=function() end
F:ProjectileImpact(e,{HitPos=e:GetPos(),HitNormal=Vector(-1,0,0)});F:ProjectileImpact(e)
assert(damage==3 and riders==1 and not e.valid)
-- Timer terminal shatters once, lifecycle invalidation never damages a new run.
F.ProjectileImpact=function(_,ent) finalCount=finalCount+1;ent:Remove() end
local expired=melon();now=now+9;fx.setTime(now);expired:Think();assert(not expired.valid and finalCount==7)
local dead=melon();owner.hp=0;now=now+.02;fx.setTime(now);dead:Think();assert(not dead.valid and finalCount==7);owner.hp=100
local reset=melon();fx.Run.State.LevelSeed=fx.Run.State.LevelSeed+1;reset:Think();assert(not reset.valid and finalCount==7)
local embed=melon();util.TraceHull=function() return {StartSolid=true} end
now=now+.02;fx.setTime(now);embed:Think();assert(not embed.valid and finalCount==7)
local sky=melon();util.TraceHull=function() return {HitSky=true} end
now=now+.02;fx.setTime(now);sky:Think();assert(not sky.valid and finalCount==7)
util.TraceHull=nativeTrace;F.ProjectileImpact=originalImpact;F._ApplyDamage=oldDamage;LOD.CombatRolls._RNG=rng
print('WATERMELON_BOUNCES_PASS: all six rolled budgets on swept floor geometry, real entity lifecycle, nonexploding logged count, incoming-only contacts, repeat-hit cadence, one rider, idempotent final AoE, timeout/death/level/embed/sky')
