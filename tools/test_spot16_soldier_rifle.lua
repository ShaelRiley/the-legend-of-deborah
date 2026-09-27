-- Execute the real loadout, incarnation, queue, clock, rifle, compatibility,
-- input, cadence, ammo and shared damage authorities. Engine calls are boundaries.
local f=dofile('tools/test_spot15_soldier_queue.lua')
local env,R=f.env,f.Run
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
-- Restore a complete deterministic RNG after the earlier equipment test's Float-only boundary.
LOD.CombatRolls._RNG=function() return LOD.RNG.New(442) end
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,'SPOT16: '..msg) end
local function near(a,b,msg) check(math.abs(a-b)<.00001,msg) end
local V=getmetatable(Vector())
function V:GetNormalized() local n=math.sqrt(self.x*self.x+self.y*self.y+self.z*self.z);if n==0 then return vector_origin end;return Vector(self.x/n,self.y/n,self.z/n) end
function V:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
V.__eq=function(a,b) return a.x==b.x and a.y==b.y and a.z==b.z end
IN_ATTACK=1;IN_ATTACK2=2;IN_RELOAD=4;CHAN_WEAPON=1;CHAN_ITEM=2
IN_SPEED=8;IN_JUMP=16;IN_FORWARD=32;IN_BACK=64;IN_MOVELEFT=128;IN_MOVERIGHT=256;IN_DUCK=512
ACT_VM_PRIMARYATTACK=1;PLAYER_ATTACK1=1
Angle=function(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,Forward=function() return Vector(1,0,0) end} end
weapons={GetStored=function() return nil end}
local timers={}
timer.Create=function(id,_,_,fn) timers[id]=fn end
local receivers={};net.Receive=function(id,fn) receivers[id]=fn end
local packet='';net.ReadString=function() return packet end
include=function(name) return dofile(root..name) end
local originalActor=env.actor
local shots={}
local clipWrites=0
function env.actor(...)
 local p=originalActor(...)
 p.SetNW2Vector=p.SetNW2String;p.SetAnimation=noop;p.MuzzleFlash=noop;p.ViewPunch=noop
 p.aim=Vector(1,0,0);p.shoot=Vector(1,2,3)
 function p:GetAimVector() return self.aim end
 function p:EyeAngles() return {Forward=function() return self.aim end} end
 function p:GetShootPos() return self.shoot end
 function p:LagCompensation(on) self.lag=on end
 function p:FireBullets(b)
  check(b.Attacker==self and b.Inflictor==self:GetActiveWeapon(),'native attacker and inflictor preserved')
  local event=self.LODCommittedAttackEvent or b.LODAttackEvent
  check(event~=nil,'committed attack event reaches shared physical emitter')
  local c=LOD.CombatRolls:RollPlayerWeapon(self,'weapon_ar2',event)
  check(c and c.profile.sides==10 and c.baseDice>=1,'real shared pulse-rifle damage roll is d10')
  shots[#shots+1]={bullet=b,contract=c,event=event,at=CurTime()}
  if self.injectAfterFire then self:injectAfterFire() end
 end
 local give=p.Give
 function p:Give(...)
  local w=give(self,...)
  if w then
   local set=w.SetClip1
   function w:SetClip1(n) clipWrites=clipWrites+1;set(self,n) end
   w.next=0;w.EmitSound=noop;w.SendWeaponAnim=noop
   w.SetNW2Float=w.SetNW2String;w.SetNW2Bool=w.SetNW2String
   function w:GetNextPrimaryFire() return self.next end
   function w:SetNextPrimaryFire(n) self.next=n end
   function w:GetMaxClip1() return 30 end
  end
  return w
 end
 return p
end
dofile(root..'sv_player_weapon_specials.lua')
local S=LOD.PlayerWeaponSpecials
local nativeBegin,nativeFire=S.BeginAR2Burst,S.FireAR2Round
dofile(root..'sv_player_weapon_specials_input.lua')
dofile(root..'sv_firearm_economy_equalization.lua')
dofile(root..'sv_magnum_super_explosive.lua')
dofile(root..'sv_magnum_aim_state.lua')
check(LOD.UniversalAim and S.LODUniversalAimBurstWrapped,'actual universal aim compatibility wrapper loaded')
local Effects=LOD.RPG.FeatEffectSystem
Effects.InstallAR2RateOfFireAuthorityWrappers()
local finalBegin,finalFire=S.BeginAR2Burst,S.FireAR2Round
check(finalBegin==S.LODRateOfFireBeginWrapper and finalFire==S.LODRateOfFireFireWrapper,'final public compatibility authority installed')
dofile(root..'sv_dice_ammo.lua');dofile(root..'sv_smg_capacity_rebalance.lua')
local Ammo=LOD.DiceAmmo
local function setup(rank,rate)
 local p,ally,saved,inc=f.soldier();f.flush()
 local w=p:GetActiveWeapon()
 check(w and w:GetClass()=='weapon_ar2' and p:GetWeapon('weapon_smg1')==nil,'actual ApplyPlayerState gives only pulse rifle')
 check(w:Clip1()==0 and p:GetAmmoCount(w:GetPrimaryAmmoType())==0,'zero native ammunition loadout')
 inc.featIds={};if rank and rank>0 then inc.featIds[#inc.featIds+1]='DEX_BURSTER_'..rank end
 if rate then inc.featIds[#inc.featIds+1]='DEX_RATE_OF_FIRE_'..rate end
 LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
 check(LOD.RPGAbilityRules:BurstBonusRounds(p)==(rank or 0),'actual burst feat derivation')
 check(S:SoldierAR2BindingValid(p,S.PlayerState[p].soldierLoadout),'loadout bound to actual current lifecycle')
 shots={};clipWrites=0
 return p,w,saved,inc,ally
end
local function step(p,at)
 f.now(at);S:ProcessPlayer(p,S.PlayerState[p],at)
end
local function cmd(mask)
 return {mask=mask,KeyDown=function(self,k) return (self.mask & k)~=0 end,
  RemoveKey=function(self,k) self.mask=self.mask & (~k) end,GetViewAngles=function() return Angle() end}
end
local input=env.hooks.LOD_PlayerWeaponSpecials_Input
local cadence=env.hooks.LOD_RPG_GateE_AR2RateOfFireCommit
for _,mode in ipairs({'native','final'}) do
 S.BeginAR2Burst=mode=='native' and nativeBegin or finalBegin
 S.FireAR2Round=mode=='native' and nativeFire or finalFire
 for rank=0,3 do
  local p,w,saved=setup(rank)
  local start=CurTime();local ammo= S.Stats.ar2AmmoCommitted
  local c=cmd(IN_ATTACK|IN_ATTACK2|IN_RELOAD);input(p,c)
  check(c.mask==0,'server suppresses stock primary, secondary orb and reload')
  local a=S.PlayerState[p].ar2
  check(a.active and a.targetShots==3+rank and a.ammoCommitted==0,'committed feat-sized infinite Soldier burst')
  near(a.fireAt,start+.45,'existing warning duration')
  input(p,cmd(0));check(a.active,'release does not cancel committed burst')
  p.aim=Vector(0,1,0);p.shoot=Vector(4,5,6)
  step(p,start+.449);check(#shots==0,'no shot before warning')
  for n=1,3+rank do
   step(p,start+.45+(n-1)*.09+.000001)
   check(#shots==n,'exactly one due projectile per service step')
   check(shots[n].bullet.Dir==Vector(1,0,0) and shots[n].bullet.Src==p.shoot,'frozen aim and current shoot position')
  end
  check(not a.active and #shots==3+rank,'entire authored burst completed')
  check(w:Clip1()==0 and p:GetAmmoCount('AR2')==0 and clipWrites==0,'no debit, temporary cartridge or refill at zero ammo')
  check(S.Stats.ar2AmmoCommitted==ammo,'Soldier adds no Hero ammo debit statistic')
  near(a.readyAt,CurTime()+.25,'ordinary recovery after actual completion')
  f.preserved(p,saved)
 end
end
S.BeginAR2Burst,S.FireAR2Round=finalBegin,finalFire
-- Held input never starts a second burst; re-press after cooldown does.
local p,w,saved,inc=setup(0)
input(p,cmd(IN_ATTACK));local a=S.PlayerState[p].ar2;local t=a.fireAt
for n=0,2 do step(p,t+n*.09+.000001);input(p,cmd(IN_ATTACK)) end
step(p,CurTime()+2);input(p,cmd(IN_ATTACK));check(#shots==3 and not a.active,'hold cannot auto-repeat')
input(p,cmd(0));input(p,cmd(IN_ATTACK));check(S.PlayerState[p].ar2.active,'fresh re-press accepted')
-- Final cadence authority may accelerate only genuinely completed bursts.
p,w=setup(1,3);check(S:BeginAR2Burst(p,w,p.aim),'rate-feat burst begins')
a=S.PlayerState[p].ar2;local plan=Effects.AR2RateOfFirePlans[p];check(plan and plan.ar2==a,'cadence binds same burst')
t=a.fireAt;for n=0,3 do step(p,t+n*.09+.000001) end
local before=a.readyAt;cadence();check(a.readyAt<before and not Effects.AR2RateOfFirePlans[p],'actual completion earns shared cadence')
-- The actual aim wrapper consumes one armed state and freezes its multiplier
-- for the whole burst; later aim changes cannot rewrite committed damage.
p,w,saved,inc=setup()
inc.featIds={'DEX_MAGNUM_DEADEYE'};LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
local Aim=LOD.UniversalAim
Aim.States[p]={weaponClass='weapon_ar2',weapon=w,armed=true,multiplier=2}
check(S:BeginAR2Burst(p,w,p.aim),'aimed infinite rifle commits')
a=S.PlayerState[p].ar2;check(a.LODUniversalAimMultiplier==2 and not Aim.States[p].armed,'aim consumed exactly once at commit')
t=a.fireAt
for n=0,2 do step(p,t+n*.09+.000001);check(shots[n+1].contract.aimMultiplier==2,'same shared aimed-damage multiplier across burst') end
-- Stall: one due round within tolerance, no three-shot catch-up; then forfeit.
p,w=setup();S:BeginAR2Burst(p,w,p.aim);a=S.PlayerState[p].ar2
step(p,a.fireAt+.19);check(#shots==1,'late service releases at most one due shot')
step(p,CurTime()+.21);check(#shots==1 and not S.PlayerState[p].ar2.active,'overdue remainder forfeited')
local changes={
 death=function(q) q.hp=0;R:HandleDeath(q) end,
 disconnect=function(q) env.hooks.LOD_PlayerDisconnected(q);env.hooks.LOD_PlayerWeaponSpecials_ResetDisconnect(q) end,
 disconnect_reverse=function(q) env.hooks.LOD_PlayerWeaponSpecials_ResetDisconnect(q);env.hooks.LOD_PlayerDisconnected(q) end,
 f3_queue=function(q) assert(R:ReturnToHeroQueue(q)) end,
 f3_spectate=function(q) assert(R:SpectateOnly(q)) end,
 retire=function(q) LOD.SoldierProgression:Retire(q) end,
 state=function() R.State=table.Copy(R.State) end,
 epoch=function() R.State.CampaignEpoch=R.State.CampaignEpoch+1 end,
 campaign=function() R.State.CampaignSeed=99 end,
 runid=function() R.State.RunId='new-run' end,
 graph=function() R.State.Graph={} end,
 seed=function() R.State.LevelSeed=99 end,
 level=function() R.State.Level=2 end,
 playerstate=function(q) R.State.PlayerState[q.id]=table.Copy(q.ps) end,
 life=function(q) q.LODRunSpawnSerial=q.LODRunSpawnSerial+1 end,
 progression=function(q) q.LODHumanSoldierProgressionState=table.Copy(q.LODHumanSoldierProgressionState) end,
 owner=function(q,r) r.owner={} end,
 missing=function(q) q.weapons.weapon_ar2=nil end,
 switch=function(q,r) q.activeClass='weapon_smg1';env.hooks.LOD_PlayerWeaponSpecials_SoldierSwitch(q,r,{}) end,
 build=function() R.State.BuildReady=false end,
 failed=function() R.State.Failed=true end,
 clear=function() R.State.LevelCleared=true end,
 frozen=function() R.State.SimulationFrozen=true end,
 staged=function(q) q.nw.LOD_Staged=true end,
 undeployed=function(q) q.nw.LOD_Deployed=false end,
 observer=function(q) q.observer=OBS_MODE_CHASE end,
 hitstun=function(q) q.LODHitStunUntil=CurTime()+1 end,
 expired=function() R.State.CampaignClock={deadline=SysTime()-1} end,
 tetris=function(q) LOD.DeathTetris={IsActiveFor=function(_,v) return v==q end} end,
 minigame=function(q) LOD.Equipment.InventoryLocked=function(_,v) return v==q end end,
 intimidated=function(q) assert(LOD.RPGStatusElements:Apply(q,'intimidated',q,{duration=5})) end,
}
for name,change in pairs(changes) do
 for _,afterRound in ipairs({false,true}) do
  p,w,saved,inc=setup(0,3);assert(S:BeginAR2Burst(p,w,p.aim));a=S.PlayerState[p].ar2
  local state=S.PlayerState[p];if afterRound then step(p,a.fireAt+.000001) end
  local count=#shots;local heroXP=saved.progression.xp
  change(p,w)
  check(not finalFire(S,p,a),name..' cannot release through final wrapper')
  S:ProcessPlayer(p,state,CurTime()+.10);cadence()
  check(#shots==count,name..' does not fire old work')
  check(not Effects.AR2RateOfFirePlans[p],name..' cancels cadence')
  check(saved.progression.xp==heroXP,name..' does not develop dormant Hero')
  LOD.DeathTetris=nil;LOD.Equipment.InventoryLocked=nil
 end
end
-- Holding the same rifle object cannot keep an old burst through switch-away/back.
p,w=setup();S:BeginAR2Burst(p,w,p.aim);a=S.PlayerState[p].ar2
input(p,cmd(0));env.hooks.LOD_PlayerWeaponSpecials_SoldierSwitch(p,w,{})
check(not finalFire(S,p,a),'retired burst object rejected even with same current weapon')
-- Native emitter failures and reentrant role retirement cannot leak the attack
-- event, lag-compensation state or the remaining committed rounds.
p,w=setup();local sentinel={};p.LODCommittedAttackEvent=sentinel
local oldError=ErrorNoHalt;local errors=0;ErrorNoHalt=function() errors=errors+1 end
p.FireBullets=function() error('SPOT16 expected native boundary failure') end
S:BeginAR2Burst(p,w,p.aim);a=S.PlayerState[p].ar2;step(p,a.fireAt+.000001)
ErrorNoHalt=oldError
check(errors==1 and p.lag==false and p.LODCommittedAttackEvent==sentinel,'final emitter restores event and lag state after failure')
check(not S.PlayerState[p].ar2.active and w:Clip1()==0,'failed emitter cancels without Soldier ammo mutation')
p,w,saved=setup();p.LODCommittedAttackEvent=sentinel
p.injectAfterFire=function(q) assert(R:SpectateOnly(q)) end
S:BeginAR2Burst(p,w,p.aim);a=S.PlayerState[p].ar2;step(p,a.fireAt+.000001)
check(#shots==1 and p.lag==false and p.LODCommittedAttackEvent==sentinel,'reentrant F3 exit retires remaining work after released round')
check(not Effects.AR2RateOfFirePlans[p] and not S.PlayerState[p],'exit does not restore retired rifle state')
f.preserved(p,saved)
-- Existing net channel uses current role/life context; stale requests do not cross lives.
p,w=setup();packet=R:TeamMenuContext(p)
receivers.LOD_PlayerAR2Activate(0,p);check(not S.PlayerState[p].ar2.active,'legacy Hero packet cannot activate Soldier')
local current=packet;packet='old-life';receivers.LOD_PlayerAR2Activate(64,p)
check(not S.PlayerState[p].ar2.active,'stale Soldier packet rejected')
packet=current;receivers.LOD_PlayerAR2Activate(64,p);check(S.PlayerState[p].ar2.active,'current contextual activation accepted')
check(S.PlayerState[p].ar2.targetShots==3,'network uses same shared burst target')
-- Regeneration is not the infinite permission and never fills Soldier reserve.
p,w=setup();Ammo:TickPlayer(p,CurTime());Ammo:TickPlayer(p,CurTime()+10000)
check(p:GetAmmoCount('AR2')==0 and clipWrites==0,'final ammo service does not refill Soldier')
-- Hero uses the same final wrappers with finite cost, including empty-clip rejection.
f.reset();p=f.actor('ordinary');w=p:Give('weapon_ar2');p:SelectWeapon('weapon_ar2')
local function heroReset(clip)
 S:ResetPlayer(p);w.clip=clip;w.next=0;shots={};clipWrites=0
 p.ps.progressionState.featIds={};LOD.CharacterProgressionSystem:_RecomputeProgressionState(p.ps.progressionState)
end
heroReset(0);check(not S:BeginAR2Burst(p,w,p.aim),'empty Hero rifle rejected')
heroReset(5);local heroAmmo=S.Stats.ar2AmmoCommitted;check(S:BeginAR2Burst(p,w,p.aim),'finite Hero burst accepted')
a=S.PlayerState[p].ar2;t=a.fireAt
for n=0,2 do step(p,t+n*.09+.000001) end
check(w:Clip1()==4 and S.Stats.ar2AmmoCommitted==heroAmmo+1 and #shots==3,'Hero pays exactly one round per trigger')
heroReset(5);packet=current;receivers.LOD_PlayerAR2Activate(64,p)
check(not S.PlayerState[p] or not S.PlayerState[p].ar2.active,'stale Soldier payload does not debit Hero')
receivers.LOD_PlayerAR2Activate(0,p);check(w:Clip1()==4,'legacy Hero activation unchanged')
-- Human eligibility follows actual rifle, while AI keeps its generated SMG capability.
local CPS=LOD.CharacterProgressionSystem
local human=LOD.SoldierProgression:CreateIncarnation(224,35,1)
local ai=CPS:GenerateMonsterProgression('soldier',224,1,35,'ai')
check(CPS:_HasCapability({starterWeaponClass='weapon_ar2'},human,'d10_damage'),'human has pulse d10 capability')
check(not CPS:_HasCapability({starterWeaponClass='weapon_smg1'},human,'smg'),'stale Soldier SMG hint cannot authorize heat feats')
check(not CPS:_HasCapability({},human,'reloadable_firearm'),'infinite Soldier has no reload feats')
check(CPS:_HasCapability({starterWeaponClass='weapon_smg1'},ai,'smg'),'AI SMG capabilities unchanged')
check(human.progressionHitDieSides==ai.progressionHitDieSides and human.level==ai.level,'shared automatic generation and levels retained')
print('SPOT16_SERVER_PASS '..checks..' actual-production assertions; native engine acceptance pending')

-- Reusable final-production fixture; inherited assertions are not counted again.
return {fixture=f, env=env, Run=R, Specials=S, Effects=Effects, setup=setup,
 step=step, command=cmd, input=input, cadence=cadence, shots=function() return shots end}
