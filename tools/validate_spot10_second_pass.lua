-- SPOT-10 D-J: execute shipped resolvers and schedulers against finite native
-- boundary doubles. These are source contracts, not Source/co-op acceptance.
local hooks,timers,now,n={}, {},100,0
function CurTime() return now end
hook={Add=function(event,id,fn) hooks[id]=fn end,GetTable=function() return {} end,Run=function() end}
timer={Create=function(id,_,_,fn) timers[id]=fn end,Simple=function() end,Remove=function() end,Exists=function() return false end}
dofile('tools/test_checkpoint_d_closure.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local RPG,R,E,S=LOD.RPG,LOD.RPGAbilityRules,LOD.RPG.FeatEffectSystem,LOD.RPGStatusElements
local C=RPG.IdentityCatalog.OrdinaryFeats
local function check(v,m) n=n+1;assert(v,'SPOT10_DJ '..n..': '..m) end
local function near(a,b,m) check(type(a)=='number' and math.abs(a-b)<1e-7,m..': '..tostring(a)..' vs '..b) end
function IsValid(x) return type(x)=='table' and x.valid==true end
local noop=function() end
MOVETYPE_WALK=2;IN_JUMP=2;DMG_GENERIC=0;vector_origin=Vector()
local serial=0
local function actor(kind,ids,class)
 serial=serial+1
 local a={id=serial,valid=true,kind=kind or 'hero',hp=100,max=100,active=true,ground=false,jump=true,
  resource={magic=40},velocity=Vector(),ammo={},weapons={},cell={x=0,y=0,z=0},
  state={actorType=kind or 'hero',featIds=ids or {},classId=class or 'rogue',level=10,derivedStats={}}}
 function a:IsPlayer() return self.kind~='ai' end
 function a:Alive() return self.hp>0 end
 function a:Health() return self.hp end
 function a:GetMaxHealth() return self.max end
 function a:SetHealth(h) self.hp=h end
 function a:EntIndex() return self.id end
 function a:GetPos() return self.cell end
 function a:WorldSpaceCenter() return self.cell end
 function a:GetVelocity() return self.velocity end
 function a:SetVelocity(v) self.velocity=Vector((self.velocity.x or 0)+v.x,(self.velocity.y or 0)+v.y,(self.velocity.z or 0)+v.z) end
 function a:OnGround() return self.ground end
 function a:KeyDown() return self.jump end
 function a:GetMoveType() return self.moveType or MOVETYPE_WALK end
 function a:IsFrozen() return self.frozen end
 function a:InVehicle() return false end
 function a:GetWeapon(c) return self.weapons[c] end
 function a:GetAmmoCount(c) return self.ammo[c] or 0 end
 function a:SetAmmo(v,c) self.ammo[c]=v end
 a.SetNW2Int=noop;a.SetNW2Float=noop;a.SetNW2Bool=noop
 return a
end
local run={State={Graph={},CampaignEpoch=1,LevelSeed=22,BuildReady=true},
 IsActivePlayer=function(_,a) return a.active and a.kind=='hero' end,
 IsSoldierControl=function(_,a) return a.active and a.kind=='human_soldier' end,
 GetPlayerState=function(_,a) return {progressionState=a.state} end}
LOD.RunManager=run
R.ProgressionState=function(_,a) return a and a.state end
-- Keep the real life binder; only generated profile values are a test boundary.
R.Derived=function(_,a) if not IsValid(a) then return nil end;S:BindActorLife(a);return a.state.derivedStats end
LOD.Magic={_EnsureState=function(_,a) return a.resource end,_Sync=noop}
local function derived(a) E:ApplyDerived(a.state,a.state.derivedStats);return a.state.derivedStats end
local a=actor('hero',{'INT_ARC_RECOVERY','INT_FEEDBACK_LOOP'})
for _,kind in ipairs({'hero','human_soldier','ai'}) do
 a=actor(kind,{'INT_ARC_RECOVERY','INT_FEEDBACK_LOOP'});derived(a)
 local p=E:MagicRecoveryProfile(a.state);near(p.arcRecoveryMagic,11,kind..' Arc profile');near(p.feedbackLoopPerCastCap,12,'Feedback cap')
 a.resource.magic=60
 near(E:ApplyArcRecovery(a,a.resource,false,100),0,'non-AI kill excluded')
 near(E:ApplyArcRecovery(a,a.resource,true,100),11,'qualified kill amount')
 near(E:ApplyArcRecovery(a,a.resource,true,101.999),0,'two second cooldown')
 near(E:ApplyArcRecovery(a,a.resource,true,102),11,'exact cooldown boundary')
 a.resource.magic=99;near(E:ApplyArcRecovery(a,a.resource,true,104),1,'Arc capacity');near(a.resource.magic,100,'capacity 100')
 a.resource.magic=50
 local refund,used=E:ApplyFeedbackLoop(a,a.resource,0,0);near(refund,0,'no initial-die refund')
 refund,used=E:ApplyFeedbackLoop(a,a.resource,1,used);near(refund,2,'one actual continuation')
 refund,used=E:ApplyFeedbackLoop(a,a.resource,4,used);near(refund,8,'later targets share event')
 refund,used=E:ApplyFeedbackLoop(a,a.resource,32,used);near(refund,2,'remaining event budget only');near(used,12,'event cap')
 refund,used=E:ApplyFeedbackLoop(a,a.resource,32,used);near(refund,0,'exhausted event replay cannot refund')
 a.resource.magic=99.75;refund,used=E:ApplyFeedbackLoop(a,a.resource,1,0);near(used,.25,'fractional accepted refund retained')
 a.resource.magic=50;refund,used=E:ApplyFeedbackLoop(a,a.resource,32,used);near(refund,11.75,'fractional prior refund consumes cap');near(used,12,'fractional cap total')
 a.state.featIds={};near(E:ApplyArcRecovery(a,a.resource,true,110),0,'unowned Arc excluded');near(E:ApplyFeedbackLoop(a,a.resource,8,0),0,'unowned Feedback excluded')
end
-- F: every class/rank, actual whole-HP scheduler, delay and ordinary ceiling.
local healthIds={'CON_REGEN_11','CON_REGEN_22','CON_REGEN_33'}
for _,class in ipairs({'fighter','rogue','wizard'}) do for rank=1,3 do
 a=actor('ai',{},class);for i=1,rank do table.insert(a.state.featIds,healthIds[i]) end
 local d=derived(a);d.conRegenMultiplier=2
 near(d.healthRegenCeilingFraction,.22*rank+(class=='fighter' and .33 or 0),'rank ceiling '..class..rank)
 near(d.healthRegenBaseMaxHPPerSecond,({.01,.015,.02})[rank],'rank base rate')
 a.hp=1;now=200;E:TrackActor(a,true);near(a.LODRPGHealthRegenEligibleAt,205,'five seconds wait')
 now=204.999;E:_TickActor(a,1);near(a.hp,1,'no premature recovery')
 now=205;E:_TickActor(a,1);near(a.hp,1+({2,3,4})[rank],'actual HP rate')
 local cap=math.floor(100*d.healthRegenCeilingFraction);a.hp=cap-1;E:_TickActor(a,1);near(a.hp,cap,'stop at ceiling')
 a.hp=120;E:_TickActor(a,1);near(a.hp,120,'overfill not healed or clamped down')
 a.hp=1;now=210;E:OnEffectiveDamage(a,1);now=214.9;E:_TickActor(a,1);near(a.hp,1,'damage interrupts recovery')
 now=215;E:_TickActor(a,.25);check(a.hp==1 or a.hp==2,'fractional accumulation uses whole HP')
 a.hp=0;E:_TickActor(a,1);near(a.hp,0,'dead actor never healed')
end end
for _,max in ipairs({1,7,37,101}) do
 a=actor('hero',{healthIds[3]},'fighter');local d=derived(a);a.max=max;a.hp=math.max(1,math.floor(max*.99))-1
 if a.hp>0 then E:TrackActor(a,true);now=now+5;E:_TickActor(a,100);near(a.hp,math.max(1,math.floor(max*.99)),'integer ceiling '..max) end
end
a=actor('ai',{healthIds[3]},'fighter');derived(a);a.hp=1;E:TrackActor(a,true);now=now+5
for _,flag in ipairs({'SimulationFrozen','Failed','LevelCleared'}) do run.State[flag]=true;E:_TickActor(a,1);near(a.hp,1,'health '..flag);run.State[flag]=false end
a.LODHector=true;E:_TickActor(a,1);near(a.hp,1,'Hector exclusion');a.LODHector=nil
a.LODArchetypeId='warden';local warden=LOD.Warden;LOD.Warden={Targets=function() return {} end};E:_TickActor(a,1);near(a.hp,1,'Gordon no-target exclusion');a.LODArchetypeId=nil;LOD.Warden=warden
run.State.Graph={};E:_TickActor(a,1);near(a.hp,1,'new graph cannot inherit old ready delay');near(a.LODRPGHealthRegenEligibleAt,now+5,'new life full wait')
-- G: real final-loaded gun authority, all five families, rank replacement.
if not LOD.DiceAmmo then dofile(root..'sv_dice_ammo.lua') end
LOD.LootDirector=LOD.LootDirector or {};weapons=weapons or {GetStored=function() return nil end}
dofile(root..'sv_smg_capacity_rebalance.lua')
local Ammo=LOD.DiceAmmo
local ammoIds={'INT_AMMO_FLOOR_44','INT_AMMO_FLOOR_55','INT_AMMO_FLOOR_66'}
for _,kind in ipairs({'hero','human_soldier'}) do for rank=0,3 do
 a=actor(kind,{});for i=1,rank do table.insert(a.state.featIds,ammoIds[i]) end;local d=derived(a)
 local speed=1+.22*rank;near(d.ammoRegenSpeedMultiplier,speed,'ammo highest rank speed')
 for class,p in pairs(Ammo.RegenerativeProfiles) do
  local gun={valid=true,clip=0,Primary={}};function gun:Clip1() return self.clip end;function gun:SetClip1(v) self.clip=v end;function gun:GetClass() return class end
  a.weapons={[class]=gun};a.ammo={[p.ammo]=0,AR2AltFire=5};Ammo.PlayerState[a]=nil
  local interval=p.recovery/p.floor/speed
  near(Ammo:RegenRoundInterval(a,class,p),interval,class..' final interval')
  near(Ammo:RegenFloorRounds(a,class,p),math.ceil(p.cap*({.33,.44,.55,.66})[rank+1]),class..' ceiling')
  Ammo:TickPlayer(a,300);near(a:GetAmmoCount(p.ammo),0,'no instant rounds')
  local fs=Ammo:_FamilyState(a,class);near(fs.nextRoundAt,303+interval,'unchanged no-fire delay')
  Ammo:TickPlayer(a,fs.nextRoundAt-1e-6);near(a:GetAmmoCount(p.ammo),0,'before round deadline')
  Ammo:TickPlayer(a,fs.nextRoundAt);near(a:GetAmmoCount(p.ammo),1,'one whole round at deadline')
  Ammo:Interrupt(a,class,400);near(fs.nextRoundAt,403+interval,'shot restarts wait')
  Ammo:TickPlayer(a,403+interval-1e-6);near(a:GetAmmoCount(p.ammo),1,'interrupted wait no refill')
  Ammo:TickPlayer(a,10000);near(a:GetAmmoCount(p.ammo),Ammo:RegenFloorRounds(a,class,p),'bounded catch-up to floor')
  gun.clip=math.min(p.load,3);a:SetAmmo(p.cap-gun.clip,p.ammo);Ammo:TickPlayer(a,10001)
  near(a:GetAmmoCount(p.ammo)+gun:Clip1(),p.cap,'clip plus reserve conserved');near(a:GetAmmoCount('AR2AltFire'),5,'secondary ammo excluded')
  a.hp=0;a:SetAmmo(0,p.ammo);Ammo:TickPlayer(a,20000);near(a:GetAmmoCount(p.ammo),0,'dead player no rounds');a.hp=100
 end
end end
check(not Ammo.RegenerativeProfiles.weapon_lod_wand and not Ammo.RegenerativeProfiles.weapon_frag,'Wand and consumable not regenerative')
-- H: same live movement handlers, exact six-Magic full payment and no rearming.
a=actor('hero',{'INT_FLOAT_ON'});derived(a);a.resource.magic=20;now=500
check(R:TryStartFloatOn(a,now),'Float starts at apex');near(a.resource.magic,20,'no up-front charge')
for i=1,24 do now=500+i*.25;R:TickFloatOn(a,now) end
near(a.resource.magic,14,'full six seconds exactly six Magic');check(not E.FloatOnState[a].active and E.FloatOnState[a].used,'full duration retires but remains used')
check(not R:TryStartFloatOn(a,507),'no second airborne use')
for _,amount in ipairs({.1,.5,1,6}) do
 a=actor('human_soldier',{'INT_FLOAT_ON'});derived(a);a.resource.magic=amount;now=600
 check(R:TryStartFloatOn(a,now),'positive partial pool starts');now=601;R:TickFloatOn(a,now)
 near(a.resource.magic,math.max(0,amount-1),'elapsed debit limited to available resource')
 if amount<=1 then check(not E.FloatOnState[a].active,'exhaustion stops float') end
end
a=actor('hero',{'INT_FLOAT_ON'});derived(a);now=700;R:TryStartFloatOn(a,now);now=700.5;R:TickFloatOn(a,now);a.jump=false;R:TickFloatOn(a,now)
near(a.resource.magic,39.5,'half-second partial debit');check(not E.FloatOnState[a].active,'release stops float')

a=actor('hero',{'INT_FLOAT_ON'});derived(a);R:TryStartFloatOn(a,720);a.jump=false;R:TickFloatOn(a,720.375)
near(a.resource.magic,39.625,'release settles final fractional interval')
a=actor('hero',{'INT_FLOAT_ON'});derived(a);R:TryStartFloatOn(a,730);a.ground=true;R:TickFloatOn(a,730.625)
near(a.resource.magic,39.375,'landing settles final fractional interval')
a=actor('hero',{'INT_FLOAT_ON'});derived(a);R:TryStartFloatOn(a,740);local oldPool=a.resource;a.resource={magic=70};R:TickFloatOn(a,741)
near(oldPool.magic,40,'retired float pool untouched');near(a.resource.magic,70,'replacement float pool not debited');check(not E.FloatOnState[a].active,'pool replacement retires float')
for _,reason in ipairs({'inactive','frozen','held','ground','ladder','zero','earlyapex','cloudunused','worldfrozen'}) do
 a=actor('hero',{'INT_FLOAT_ON'});local d=derived(a);a.active=reason~='inactive';a.frozen=reason=='frozen';a.ground=reason=='ground'
 if reason=='ladder' then a.moveType=9 end;if reason=='zero' then a.resource.magic=0 end;if reason=='earlyapex' then a.velocity.z=100 end
 if reason=='cloudunused' then d.cloudStepEnabled=true end
 local cm=S.CanMoveVoluntarily;if reason=='held' then S.CanMoveVoluntarily=function() return false end end
 run.State.SimulationFrozen=reason=='worldfrozen';local before=a.resource.magic
 check(not R:TryStartFloatOn(a,800),'Float restriction '..reason);near(a.resource.magic,before,'failed start spends nothing')
 S.CanMoveVoluntarily=cm;run.State.SimulationFrozen=false
end
a=actor('hero',{'INT_FLOAT_ON'});derived(a);R:TryStartFloatOn(a,900);local old=E.FloatOnState[a];a.state=table.Copy(a.state);R:TickFloatOn(a,901)
near(a.resource.magic,40,'replacement life not charged');check(E.FloatOnState[a]~=old,'replacement life drops old float')
-- I: production duration authority, not only card/profile parameters.
scripted_ents={GetStored=function() return nil end}
if not LOD.M3HitFeedback then dofile(root..'sv_m3_hit_feedback.lua') end
local H=LOD.M3HitFeedback
for rank=1,3 do
 a=actor('hero',{});for i=1,rank do table.insert(a.state.featIds,'CHA_HITSTUN_'..i) end
 local d=derived(a);near(d.featHitStunMultiplier,1+.22*rank,'Presence replacement multiplier')
 local t=actor('ai');t.LODHostile=true;derived(t);now=1000
 check(H:ApplyHitStun(t,1,a),'real inflicted stun');near(t.LODHitStunUntil-now,({.366,.432,.498})[rank],'ordinary neutral duration')
 check(not H:ApplyHitStun(t,1,a),'retrigger denial');near(t.LODHitStunUntil,1000+({.366,.432,.498})[rank],'no extending repeated hits')
 t.LODNextHitStun=0;t.LODHitStunUntil=0;t.state.derivedStats.chaHitStunResistanceMultiplier=.7;H:ApplyHitStun(t,1,a)
 near(t.LODHitStunUntil-now,.3*(1+.22*rank)*.7,'defender resistance composes')
 t.LODNextHitStun=0;t.LODHitStunUntil=0;H:ApplyHitStun(t,10,a);near(t.LODHitStunUntil-now,.6,'shared ordinary multiplier cap')
 t.LODArchetypeId='warden';LOD.Warden={HitStunDeadline=function() return now+.05 end,Interrupt=noop};t.LODNextHitStun=0;t.LODHitStunUntil=0
 H:ApplyHitStun(t,1,a);near(t.LODHitStunUntil,now+.05,'fixed Gordon opportunity bounds stun');LOD.Warden=warden
end
-- J: actual shared scheduler, real cell filter/damage context/Glow Up.
local owners,targets={},{}
player.GetAll=function() return owners end;LOD.HostileRegistry={List=function() return {} end}
LOD.MazeNavigator={WorldToCell=function(_,_,pos) return pos end}
LOD.FactionManager={Opponents=function() return targets end}
function DamageInfo()
 local info={}
 for _,key in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition','DamageForce'}) do
  info['Set'..key]=function(self,v) self[key]=v end
  info['Get'..key]=function(self) return self[key] end
 end
 return info
end
RPG.QueueAuraDamageReport=noop -- presentation already gated by SPOT05.
local count,amount=0,0
local function target(x,y,z)
 local t=actor('ai');t.cell={x=x,y=y,z=z}
 function t:TakeDamageInfo(info)
  count=count+1;amount=amount+info:GetDamage();local c=S:DamageContext(info)
  check(c.passiveDamage and c.personalityAura and c.feedbackIneligible and c.moraleIneligible and c.statusProcIneligible,'passive exclusions retained')
 end
 return t
end
local pulse=assert(hooks.LOD_CheckpointDPersonalityAura)
local rng=LOD.RNG.New;LOD.RNG.New=function() error('Aura cadence must not roll dice') end
for rank,id in ipairs({'CHA_ABRASIVE_PERSONALITY_1','CHA_NARCISSISM_2','CHA_MEGALOMANIA_3'}) do
 a=actor('hero',{id,'CON_GLOW_UP'});local d=derived(a);d.chaMod=3;d.conMod=2;owners={a};targets={target(0,0,0),target(rank,0,0),target(0,0,1)}
 count,amount=0,0;now=1100+rank*100;RPG.CheckpointDPersonalityAuraNextThink=0;pulse();near(count,0,'full initial aura wait');near(a.LODPersonalityAuraNextAt,now+3,'fixed first interval')
 now=now+2.75;pulse();near(count,0,'no early pulse');now=now+.25;pulse();near(count,1,'only in-range same-floor hostile');near(amount,5,'CHA plus Glow Up once')
 now=now+30;pulse();near(count,2,'stall yields only one pulse, no burst');near(a.LODPersonalityAuraNextAt,now+3,'next full interval from current time')
 run.State.SimulationFrozen=true;now=now+.25;pulse();check(a.LODPersonalityAuraNextAt==nil,'freeze clears old pulse');near(count,2,'freeze no damage');run.State.SimulationFrozen=false
 now=now+20;pulse();near(count,2,'resume waits full interval');near(a.LODPersonalityAuraNextAt,now+3,'resume new initial deadline')
 run.State.Graph={};now=now+3;pulse();near(count,2,'same-seed graph replacement cannot inherit pulse');near(a.LODPersonalityAuraNextAt,now+3,'new graph full initial wait')
 a.hp=0;now=now+3;pulse();near(count,2,'dead aura no damage')
end

a=actor('hero',{'CHA_ABRASIVE_PERSONALITY_1'});derived(a).chaMod=3;owners={a};local t1,t2=target(0,0,0),target(0,0,0);targets={t1,t2}
local take=t1.TakeDamageInfo;t1.TakeDamageInfo=function(self,info) take(self,info);S:ResetActorLife(a) end
count=0;RPG:ResolveCheckpointDPersonalityAura(a);near(count,1,'owner life retirement during native damage stops remaining pulse recipients')
LOD.RNG.New=rng
check(C.INT_FLOAT_ON.effectParams.magicPerSecond==1 and C.INT_FLOAT_ON.effectParams.maximumSeconds==6,'Float canonical card parameters')
check(C.DEX_EXPLODE_D8.prerequisiteFeatIds[1]=='DEX_EXPLODE_D10' and C.DEX_EXPLODE_D4.prerequisiteFeatIds[1]=='DEX_EXPLODE_D8','rejected A untouched')
print('SPOT10_SECOND_PASS_PASS '..n..' focused production assertions; native boundary doubles; no campaign/native acceptance claim')
