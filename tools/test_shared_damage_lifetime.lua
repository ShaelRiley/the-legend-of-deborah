local env=dofile('tools/test_cross_feats_dodge.lua')
local pending={};timer.Simple=function(_,fn) pending[#pending+1]=fn end
local function flush() local batch=pending;pending={};for _,fn in ipairs(batch) do fn() end end
local source,target=env.actor({},true),env.actor()
local weapon={valid=true,GetClass=function() return 'weapon_pistol' end}
function source:GetActiveWeapon() return weapon end
local info=DamageInfo()
local native=DamageInfo
DamageInfo=function() return info end -- actual Source shared-reference behavior
local Status,Rolls=LOD.RPGStatusElements,LOD.CombatRolls
LOD.MagnumPiercing={DamageSegments={}}
for i=1,1000 do
 Status.DamageContexts[info]={settledShotgun=true,statusDamage=true}
 Rolls.PendingDamageReports[info]=function() error('stale report') end
 LOD.MagnumPiercing.DamageSegments[info]={depth=8}
 assert(LOD.NewDamageInfo()==info)
 assert(next(Status:DamageContext(info))==nil and not Rolls.PendingDamageReports[info]
  and not LOD.MagnumPiercing.DamageSegments[info],'native reuse inherited previous attack semantics')
end
-- Exercise the real Pusher post-damage observer; a reaction must not allocate or
-- mutate shared engine damage state until all native observers have finished.
local Effects=LOD.RPG.FeatEffectSystem
Effects.TryPusherProc=function() return 168,true end
local pushes,inNative=0,true
LOD.Pushback={Apply=function()
 assert(not inNative,'nested native damage from PostEntityTakeDamage')
 pushes=pushes+1;local nextInfo=LOD.NewDamageInfo();nextInfo:SetDamage(999)
end}
info:SetAttacker(source);info:SetInflictor(weapon);info:SetDamage(12);info:SetDamageType(DMG_BULLET)
Status:AttachDamageContext(info,{physical=true})
env.hooks.PostEntityTakeDamage.LOD_RPG_GateE_PusherWeaponHit(target,info,true)
assert(pushes==0 and info:GetDamage()==12 and #pending==1)
GM:PostEntityTakeDamage(target,info,true)
assert(next(Status:DamageContext(info))==nil,'completed native event retained context')
inNative=false;flush();assert(pushes==1)
local n=pushes
LOD.DeferDamageReaction(source,target,function() pushes=pushes+1 end)
target.valid=false;flush();target.valid=true;assert(pushes==n)
LOD.DeferDamageReaction(source,target,function() pushes=pushes+1 end)
source.LODCombatLifeSerial=1;flush();assert(pushes==n)
LOD.DeferDamageReaction(source,target,function() pushes=pushes+1 end)
LOD.RunManager.State.LevelSeed=500;flush();assert(pushes==n)
DamageInfo=native
print('SHARED_DAMAGE_LIFETIME_PASS: 1000 native reuses, real Pusher observer, no nested mutation, death/removal/transition cancellation')
