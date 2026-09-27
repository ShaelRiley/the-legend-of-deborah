-- Reuse actual Soldier/Hero authority and native time/actor boundaries.
local f=dofile('tools/test_spot15_soldier_queue.lua')
local R,env=f.Run,f.env
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local checks,failures=0,{}
local function check(ok,msg)
 checks=checks+1
 if not ok then failures[#failures+1]=msg;print('LIFECYCLE_FAIL '..msg) end
end
local function drain() for i=#env.timers,1,-1 do env.timers[i]=nil end end
local basePut=R.PutInRestrictedSpectator
local put=0
R.PutInRestrictedSpectator=function(...) put=put+1;return basePut(...) end
local mutations={
 unchanged=function() end,
 life=function(p) p.LODRunSpawnSerial=p.LODRunSpawnSerial+1 end,
 state=function() local s=table.Copy(R.State);R.State=s end,
 graph=function() R.State.Graph={Cells={}} end,
 epoch=function() R.State.CampaignEpoch=R.State.CampaignEpoch+1 end,
 level=function() R.State.Level=R.State.Level+1 end,
 seed=function() R.State.LevelSeed=R.State.LevelSeed+1 end,
 profile=function(p) R.State.PlayerState[p.id]=table.Copy(p.ps) end,
 alive=function(p) p.hp=100 end,
 disconnect=function(p) p.valid=false end
}
for _,role in ipairs({'hero','soldier'}) do
 for name,mutate in pairs(mutations) do
  local p
  if role=='soldier' then p=f.soldier();f.flush()
  else f.reset();p=f.actor('dead-hero');f.actor('survivor') end
  drain();p.ps.deploymentComplete=true;p:SetNW2Bool('LOD_Staged',false);p:SetNW2Bool('LOD_Deployed',true)
  p.hp=0;p.LODHandledRunDeath=nil;put=0
  R:HandleDeath(p)
  -- Only execute the actual deferred spectator callback. Other native callbacks
  -- may intentionally process the current party and are tested by SPOT-15.
  local callback=env.timers[1]
  check(type(callback)=='function',role..' schedules death spectator')
  mutate(p);local before=put;callback()
  check(put-before==(name=='unchanged' and 1 or 0),role..' death callback '..name)
 end
end
R.PutInRestrictedSpectator=basePut
-- Singleton registration is reloaded only to capture its real KeyPress callback
-- in this existing hook boundary; the effect math and progression are production.
dofile(root..'sv_rpg_gate_e_singletons.lua')
local E=LOD.RPG.FeatEffectSystem
local jump=env.hooks.LOD_RPG_GateE_SpringHeel
local death=env.hooks.LOD_RPG_GateE_SpringHeelDeath
local telemetry=env.hooks.LOD_RPG_GateE_SpringHeelTelemetry
local function jumper(enabled)
 f.reset();local p=f.actor('jumper');drain()
 p.ps.progressionState.featIds=enabled and {'DEX_SPRING_HEEL'} or {}
 E.SpringHeelTraces[p]=nil;p.velocity=Vector(0,0,200)
 function p:SetVelocity(v) self.velocity=self.velocity+v;self.boosts=(self.boosts or 0)+1 end
 return p
end
local p=jumper(true)
jump(p,IN_JUMP);jump(p,IN_JUMP)
check(#env.timers==1,'duplicate grounded inputs coalesce before takeoff')
f.flush()
check((p.boosts or 0)==1 and math.abs(p.velocity.z-200*math.sqrt(2))<.00001,'ordinary jump amplified once by sqrt(2)')
p=jumper(false);jump(p,IN_JUMP);f.flush()
check((p.boosts or 0)==0 and p.velocity.z==200,'no-feat baseline unmodified')
for name,mutate in pairs(mutations) do
 if name~='alive' then
  p=jumper(true);jump(p,IN_JUMP);mutate(p);f.flush()
  check((p.boosts or 0)==(name=='unchanged' and 1 or 0),'jump callback '..name)
 end
end
p=jumper(true);jump(p,IN_JUMP)
local old=table.remove(env.timers,1)
p.LODRunSpawnSerial=p.LODRunSpawnSerial+1
death(p);jump(p,IN_JUMP)
old();check((p.boosts or 0)==0,'old life cannot consume or apply new jump claim')
f.flush();check((p.boosts or 0)==1,'new life still receives exactly its own jump')
-- Death without a replacement life cancels pending work and stale telemetry.
p=jumper(true);jump(p,IN_JUMP);death(p);f.flush()
check((p.boosts or 0)==0,'death clears pending jump even before native serial changes')
p=jumper(true);jump(p,IN_JUMP);f.flush();p.LODRunSpawnSerial=p.LODRunSpawnSerial+1
telemetry();check(E.SpringHeelTraces[p]==nil,'old-life jump telemetry discarded')
-- The native acceptance kit must reset telemetry, not reserve a phantom jump.
p=jumper(false)
local dev=GetConVar('lod_developer_mode') or CreateConVar('lod_developer_mode',0)
dev.value=1
f.commands.lod_rpg_gate_e_singletons_testkit(p,'lod_rpg_gate_e_singletons_testkit',{'1'})
f.flush()
check(not E.SpringHeelPending or not E.SpringHeelPending[p],'testkit does not block pending jump')
jump(p,IN_JUMP);f.flush()
check((p.boosts or 0)==1,'testkit-enabled ordinary jump remains usable')
assert(#failures==0,table.concat(failures,'; '))
print('CLEANUP_LIFECYCLE_PASS '..checks..' production assertions')
