-- Capture the actual shared-load movement callbacks before the inherited fixture
-- switches its engine hook registry. Never re-evaluate/reimplement their bodies.
local sharedHooks={}
hook={Add=function(_,id,fn) sharedHooks[id]=fn end}
local f=dofile('tools/test_spot16_soldier_rifle.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local env,R,S,Effects=f.env,f.Run,f.Specials,f.Effects
-- init.lua supplies the actual resource authority after shared.lua.
dofile(root..'sv_magic.lua')
local Rules,Status,M=LOD.RPGAbilityRules,LOD.RPGStatusElements,LOD.SoldierMovement
local moveHook=assert(sharedHooks.LOD_RPG_GateD_Movement)
local dodgeHook=assert(sharedHooks.LOD_RPG_DodgeVoluntaryMotion)
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,'SPOT17_SERVER: '..msg) end
local function near(a,b,msg) check(math.abs(a-b)<.00001,msg..' '..tostring(a)..' ~= '..tostring(b)) end
bit={band=function(a,b) return a&b end,bnot=function(a) return ~a end}
MOVETYPE_WALK=2
local oldActor=env.actor
function env.actor(...)
 local p=oldActor(...)
 p.ground=true;p.keys=0
 function p:OnGround() return self.ground end
 function p:KeyDown(k) return (self.keys & k)~=0 end
 function p:GetMoveType() return MOVETYPE_WALK end
 function p:WaterLevel() return 0 end
 function p:InVehicle() return false end
 function p:IsFrozen() return false end
 function p:GetBaseVelocity() return self.base or Vector() end
 function p:GetJumpPower() return 200 end
 function p:SetVelocity(v) self.velocity=self.velocity+v end
 return p
end
local function setup(rank,rate)
 local p,w,saved,inc=f.setup(rank,rate)
 inc.classId='fighter';LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
 check(M:Active(p),'actual deployed Soldier role')
 return p,w,saved,inc
end
local function move(forward,side,mask,cap,velocity)
 local m={forward=forward or 450,side=side or 0,up=120,mask=mask or 0,
  max=cap or 200,client=cap or 200,velocity=velocity or Vector(300,200,-70)}
 function m:GetForwardSpeed() return self.forward end;function m:SetForwardSpeed(v) self.forward=v end
 function m:GetSideSpeed() return self.side end;function m:SetSideSpeed(v) self.side=v end
 function m:GetUpSpeed() return self.up end;function m:SetUpSpeed(v) self.up=v end
 function m:GetMaxSpeed() return self.max end;function m:SetMaxSpeed(v) self.max=v end
 function m:GetMaxClientSpeed() return self.client end;function m:SetMaxClientSpeed(v) self.client=v end
 function m:GetVelocity() return self.velocity end;function m:SetVelocity(v) self.velocity=v end
 function m:GetButtons() return self.mask end;function m:SetButtons(v) self.mask=v end
 function m:KeyDown(k) return (self.mask & k)~=0 end
 return m
end
local function assertRoot(p,label)
 local m=move(450,450,IN_SPEED|IN_JUMP|IN_FORWARD|IN_MOVERIGHT|IN_DUCK)
 moveHook(p,m)
 check(M:Locked(p),label..' exact commitment owns lock')
 near(m.forward,0,label..' forward root');near(m.side,0,label..' side root');near(m.up,0,label..' up root')
 near(m.velocity.x,0,label..' cancels carried ordinary x');near(m.velocity.y,0,label..' cancels carried ordinary y')
 near(m.velocity.z,-70,label..' gravity/falling unchanged')
 check(m.mask==IN_DUCK,label..' locomotion buttons removed, crouch retained')
 near(p:GetNW2Float('LOD_SoldierRootUntil',0),select(2,M:Locked(p)),label..' current deadline projected')
 check(p:GetNW2Entity('LOD_SoldierRootWeapon')==p:GetActiveWeapon(),label..' exact weapon projected')
 check(p:GetNW2String('LOD_SoldierRootContext')==R:TeamMenuContext(p),label..' current life projected')
 dodgeHook(p,move(0,0,0,200,Vector(250,0,0)))
 check(Rules:DodgeMovement(p)==0,label..' no Dodge from root or carried velocity')
 return m
end
check(not M:Active({valid=true,IsPlayer=function() return true end}),'read-only snapshot actor is not a live movement body')
check(M:BaseSpeed()==140,'live ordinary AI Soldier speed, not a new balance constant')
-- Real final multipliers and input pipeline, including native crouch ceilings.
for _,class in ipairs({'fighter','rogue','wizard'}) do
 for _,ground in ipairs({true,false}) do
  for _,mask in ipairs({0,IN_SPEED,IN_JUMP,IN_DUCK,IN_SPEED|IN_JUMP|IN_DUCK}) do
   local p,w,saved,inc=setup();inc.classId=class;p.ground=ground;p.keys=mask
   LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
   local multiplier=Rules:MovementMultiplier(p)
   for _,axes in ipairs({{450,0},{-450,0},{0,450},{450,450},{-450,-450}}) do
    local m=move(axes[1],axes[2],mask,400)
    moveHook(p,m)
    near(m.max,140*multiplier,'base capped before actual modifiers')
    near(m.client,m.max,'client/server max agree')
    check(not m:KeyDown(IN_SPEED),'no ordinary sprint')
    check(m:KeyDown(IN_JUMP)==(not ground and (mask&IN_JUMP)~=0),'only airborne jump input remains')
    near(m.velocity.x,300,'uncommitted ordinary velocity not rewritten')
   end
   local crouch=move(450,0,IN_DUCK,40);moveHook(p,crouch)
   near(crouch.max,40*multiplier,'native reduced crouch ceiling remains lower')
   if class=='rogue' then near(Rules:RogueMovementMultiplier(p,true),1.11,'Soldier Rogue cannot sprint-stack') end
   dodgeHook(p,move(0,0,0,200,Vector(80,0,0)))
   local speed,walk,sprint=Rules:DodgeMovement(p)
   near(speed,80,'ordinary motion remains eligible');near(walk,140*multiplier,'Dodge uses actual target');near(sprint,walk,'no separate sprint target')
   f.fixture.preserved(p,saved)
  end
 end
end
-- Retained directional feats survive the ordinary Soldier base ceiling.
-- Removed ranks are inert even in a stale stored incarnation.
for _,id in ipairs({'INT_WAS_DEBORAH','DEX_STRAFER_1'}) do
 local p,w,_,inc=setup();inc.featIds={id};LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
 local base=140*Rules:MovementMultiplier(p)
 local m=move(-450,450);moveHook(p,m)
 check(m.max>base,id..' real directional bonus survives')
 check(m.max<=520,id..' canonical global ceiling')
end
for _,id in ipairs({'DEX_SIDELER_2','DEX_LATERAL_MOVER_3','INT_HASTE_2','INT_HASTE_3'}) do
 local p,w,_,inc=setup();inc.featIds={id};LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
 local base=140*Rules:MovementMultiplier(p)
 local m=move(-450,450);moveHook(p,m)
 near(m.max,base,id..' retired ownership cannot change Soldier movement')
end
local p,w,saved,inc=setup()
local before=Rules:MovementMultiplier(p)
inc.featIds={'INT_HASTE_1'};LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
check(Rules:Derived(p).hasteEnabled,'actual passive Haste grant')
near(Rules:MovementMultiplier(p),before,'Haste does not contaminate shared air/impulse multiplier')
local resource=LOD.Magic:_EnsureState(p);resource.magic=13.25
local hm=move();moveHook(p,hm);near(hm.max,140*before*1.33,'passive Haste composes once with Soldier ground movement')
near(resource.magic,13.25,'passive Haste spends no Magic')
p.ground=false
hm=move();moveHook(p,hm);near(hm.max,140*before,'Haste does not increase airborne movement')
inc.featIds={'INT_HASTE_1','DEX_STRAFER_1','DEX_SPRING_HEEL'}
LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
hm=move(450,0);moveHook(p,hm);near(hm.max,140*before*1.5,'Spring Heel alone supplies airborne voluntary multiplier')
near(resource.magic,13.25,'movement composition has zero Magic interaction')
-- Every burst size with the real final cadence wrapper. Recovery uses actual
-- completion/cadence, never a duplicate guessed duration or second owner.
for rank=0,3 do
 for _,rate in ipairs({0,1,3}) do
  p,w,saved,inc=setup(rank,rate>0 and rate or nil)
  check(not M:Locked(p),'no loadout-only root')
  dodgeHook(p,move(0,0,0,200,Vector(180,0,0)))
  check(Rules:DodgeMovement(p)>0,'pre-commitment observed step qualifies')
  check(S:BeginAR2Burst(p,w,p.aim),'final public commitment')
  check(Rules:DodgeMovement(p)==0,'commitment invalidates pre-FinishMove Dodge immediately')
  local a=S.PlayerState[p].ar2;local start=CurTime()
  assertRoot(p,'commit')
  f.input(p,f.command(0));assertRoot(p,'released primary')
  f.fixture.now(start+.449);assertRoot(p,'warning')
  for n=0,2+rank do
   f.step(p,start+.45+n*.09+.000001)
   check(#f.shots()==n+1,'same exact committed projectile count')
   if n<2+rank then assertRoot(p,'inter-round') end
  end
  f.cadence()
  local ready=a.readyAt
  check(not a.active,'actual burst completed')
  if ready>CurTime()+.00001 then
   f.fixture.now(ready-.00001);assertRoot(p,'actual recovery')
  end
  f.fixture.now(ready)
  check(not M:Locked(p),'unlocked exactly at actual cadence deadline')
  local m=move();moveHook(p,m);check(m.max>0 and m.forward>0,'ordinary movement restored without native speed writes')
  check(p:GetNW2Float('LOD_SoldierRootUntil',0)==0,'expired projection cleared')
  f.input(p,f.command(IN_ATTACK));f.input(p,f.command(IN_ATTACK))
  if S.PlayerState[p].ar2.active then
   local same=S.PlayerState[p].ar2;f.input(p,f.command(IN_ATTACK))
   check(S.PlayerState[p].ar2==same,'held primary cannot replace commitment')
  end
  f.fixture.preserved(p,saved)
 end
end
-- Forced velocity and native vertical motion are not ordinary movement/Dodge.
p,w=setup();check(S:BeginAR2Burst(p,w,p.aim),'forced-motion test commitment')
p.LODForcedMovementUntil=CurTime()+.1
local m=move();moveHook(p,m)
near(m.velocity.x,300,'marked Push horizontal motion survives');near(m.velocity.z,-70,'forced vertical survives')
near(m.forward,0,'Push does not restore movement input')
dodgeHook(p,m);check(Rules:DodgeMovement(p)==0,'Push grants no Dodge')
p.LODForcedMovementUntil=nil;assertRoot(p,'forced interval ended')
-- Real airborne feat entry points are denied without spending while rooted,
-- then available again; Float On's six seconds at 1 Magic/second are retained.
p,w,_,inc=setup();p.ground=false;p.keys=IN_JUMP
inc.featIds={'INT_CLOUD_STEP','INT_FLOAT_ON','DEX_WALL_JUMP'}
LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
local resource=LOD.Magic:_EnsureState(p);resource.magic=100
check(S:BeginAR2Burst(p,w,p.aim),'airborne commitment')
local magic=resource.magic
check(not Rules:TryCloudStep(p),'direct Cloud Step blocked')
check(not Rules:TryWallJump(p),'direct Wall Jump blocked before tracing')
check(not Rules:TryStartFloatOn(p,CurTime()),'direct Float On blocked')
near(resource.magic,magic,'denied movement abilities spend no Magic')
S:CancelSoldierAR2(p,S.PlayerState[p])
check(Status:CanMoveVoluntarily(p),'voluntary action admission restored')
inc.featIds={'INT_FLOAT_ON'};LOD.CharacterProgressionSystem:_RecomputeProgressionState(inc)
p.velocity=Vector();Effects.FloatOnState[p]=nil
check(Rules:TryStartFloatOn(p,CurTime()),'actual Float On remains available off-commitment')
local started=CurTime();f.fixture.now(started+1);Rules:TickFloatOn(p,CurTime());near(resource.magic,magic-1,'Float On still costs 1 Magic/second')
f.fixture.now(started+6);Rules:TickFloatOn(p,CurTime());near(resource.magic,magic-6,'six-second cap settles only six Magic')
check(not (Effects.FloatOnState[p] and Effects.FloatOnState[p].active),'six-second Float On ends')
-- Source/lifecycle changes during both warning and recovery retire the lock.
local changes={
 queue=function(q) check(R:ReturnToHeroQueue(q),'actual F3 queue exit') end,
 spectate=function(q) check(R:SpectateOnly(q),'actual F3 spectate exit') end,
 death=function(q) q.hp=0;R:HandleDeath(q) end,
 disconnect=function(q) env.hooks.LOD_PlayerWeaponSpecials_ResetDisconnect(q) end,
 state=function() R.State=table.Copy(R.State) end,
 graph=function() R.State.Graph={} end, seed=function() R.State.LevelSeed=99 end,
 epoch=function() R.State.CampaignEpoch=2 end,campaign=function() R.State.CampaignSeed=99 end,
 runid=function() R.State.RunId='replacement' end,level=function() R.State.Level=2 end,
 playerstate=function(q) R.State.PlayerState[q.id]=table.Copy(q.ps) end,
 life=function(q) q.LODRunSpawnSerial=q.LODRunSpawnSerial+1 end,
 progression=function(q) q.LODHumanSoldierProgressionState=table.Copy(q.LODHumanSoldierProgressionState) end,
 owner=function(q,r) r.owner={} end,missing=function(q) q.weapons.weapon_ar2=nil end,
 replacement=function(q,r) q.weapons.weapon_ar2={valid=true,GetClass=r.GetClass,GetOwner=r.GetOwner,owner=q} end,
 switch=function(q,r) env.hooks.LOD_PlayerWeaponSpecials_SoldierSwitch(q,r,{}) end,
 build=function() R.State.BuildReady=false end,failed=function() R.State.Failed=true end,
 clear=function() R.State.LevelCleared=true end,frozen=function() R.State.SimulationFrozen=true end,
 staged=function(q) q.nw.LOD_Staged=true end,undeployed=function(q) q.nw.LOD_Deployed=false end,
 observer=function(q) q.observer=OBS_MODE_CHASE end,hitstun=function(q) q.LODHitStunUntil=CurTime()+1 end,
 expired=function() R.State.CampaignClock={deadline=SysTime()-1} end,
 intimidated=function(q) check(Status:Apply(q,'intimidated',q,{duration=5}),'real intimidation') end,
}
for name,change in pairs(changes) do
 for _,completed in ipairs({false,true}) do
  p,w,saved=setup();check(S:BeginAR2Burst(p,w,p.aim),name..' commitment')
  local a=S.PlayerState[p].ar2
  if completed then local at=a.fireAt;for n=0,2 do f.step(p,at+n*.09+.000001) end end
  local count=#f.shots();local xp=saved.progression.xp
  change(p,w);check(not M:Locked(p),name..' immediate lock release')
  M:Publish(p);check(p:GetNW2Float('LOD_SoldierRootUntil',0)==0,name..' projection retired')
  local state=S.PlayerState[p]
  check(not state or not state.ar2.soldierBinding,name..' observed invalidation cannot rearm old root')
  if state then S:ProcessPlayer(p,state,CurTime()) end
  check(#f.shots()==count and saved.progression.xp==xp,name..' no late shot or dormant Hero development')
 end
end
p,w=setup();S:BeginAR2Burst(p,w,p.aim);local a=S.PlayerState[p].ar2
f.fixture.now(a.fireAt+.200001);check(not M:Locked(p),'existing lateness boundary forfeits root and work')
check(not S.PlayerState[p].ar2.active,'late work actually cancelled, not hidden')
-- Restore the same body to a real Hero using existing role authorities; stale
-- Soldier projection cannot restrict Hero speed, sprint, jump or active rifle.
p,w,saved=setup();S:BeginAR2Burst(p,w,p.aim);check(R:ReturnToHeroQueue(p),'return to dormant Hero')
check(R:ReviveIdentity(p.id),'ordinary one-life revival')
f.fixture.flush()
check(not M:Active(p),'revived Hero is not Soldier movement role')
local hero=move(450,450,IN_SPEED|IN_JUMP,400);local hv=hero.velocity
moveHook(p,hero)
check(hero.mask==(IN_SPEED|IN_JUMP),'Hero sprint and jump untouched')
check(hero.max>140 and hero.velocity==hv,'Hero speed and velocity not inherited from Soldier')
check(not M:Locked(p),'Hero never inherits rifle root')
print('SPOT17_SERVER_PASS '..checks..' new actual-production assertions; native acceptance pending')
