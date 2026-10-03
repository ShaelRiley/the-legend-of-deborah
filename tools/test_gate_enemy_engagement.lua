-- Real generated geometry, gate navigation, EntrySafety, native target/route
-- methods, Motion V2 and hostile coroutine. Only Source entities/traces/HP are
-- doubled; an admitted tick must reach a real attack rather than a tick counter.
local safetySource=arg[1]
arg[1]='--runtime'
local H=dofile('tools/test_bestiary_b29.lua')
arg[1]=safetySource
local root='gamemodes/legend_of_deborah/gamemode/lod/'
if safetySource then dofile(safetySource) end
local S,g,T,R=LOD.EntrySafety,H.graph,H.X.T,H.X.R
local N=LOD.MazeNavigator
local productionRoster=LOD.EnemyRoster
local function read(p) local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local source=read('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local cls={}
local prelude='local ENT=...\n'..assert(source:match('(local function soldierFamily%(.-\nend)'))..'\n'
for _,name in ipairs({'GetLODHomeCell','_RouteToCell','_TargetCell','_CanAcquireTarget','_RefreshTarget','_RefreshRoute',
    '_AdvanceWaypoint','_IgnoredShotEntities','_HasLineOfSight','_MeleeAttack','_TryAttack','RunBehaviour',
    '_SoldierRunActivity','_SoldierIdleActivity','_SoldierAttackActivity','_SoldierTargetAimPos'}) do
    assert(load(prelude..assert(source:match('(function ENT:'..name..'%([^\n]*%)[\n].-\nend)')),
        '@native-hostile-'..name))(cls)
end
scripted_ents.GetStored=function() return {t=cls} end
local V=getmetatable(Vector())
V.__div=function(a,b)return a*(1/b)end
function V:Length2D()return math.sqrt(self.x*self.x+self.y*self.y)end
function Angle(p,y,r)
    return {p=p or 0,y=y or 0,r=r or 0,Forward=function(self)
        local pitch,yaw=math.rad(self.p),math.rad(self.y)
        return Vector(math.cos(pitch)*math.cos(yaw),math.cos(pitch)*math.sin(yaw),-math.sin(pitch))
    end}
end
function V:Angle()return Angle(math.deg(-math.atan(self.z,self:Length2D())),math.deg(math.atan(self.y,self.x)),0)end
LOD.EnemyRoster=nil;LOD.EnemyUpdate=nil;LOD.EnemySupport=nil
LOD.RPGAbilityRules=nil;LOD.HostileAnimation=nil
LOD.RPGStatusElements={CanMoveVoluntarily=function()return true end,
    LocomotionMultiplier=function()return 1 end,ObserveCell=function()end,HandleAIFlee=function()return false end,
    AllowsFriendlyFire=function()return false end}
dofile(root..'sv_hostile_motion_v2.lua')
-- Install the production wandering wrapper even for directed actors; it must
-- forward new-reservation eligibility to the native base without dropping flags.
dofile(root..'sv_wandering_director.lua')
local M=LOD.HostileMotionV2
M.FaceToward=function()end
LOD.RunManager.IsActivePlayer=function(_,p)return p.active~=false end
dofile(root..'sv_faction_manager.lua')
local hero=H.actor('gate-hero',2)
local heroes={hero}
T.setHeroes(heroes);player.GetAll=function()return heroes end
local F=LOD.FactionManager
F.LivingTargets=function()return heroes end
local clock=40000
local function at(t) clock=t;H.time(t);S.NextService=0 end
local function pos(c,offset)return N:CellCenter(c)+(offset or Vector(0,0,12))end
local function key(c)return LOD.MazeGenerator.CellKey(c.x,c.y,c.z)end
local gate=g.Progression.Gates[1]
R.State.GatesOpen[1]=true
local path=assert(N:FindPath(g,g.Start,gate.afterCell));assert(#path>9)
local home,current,dest=path[#path-8],path[#path-2],path[#path]
local made={}
ents.FindByClass=function()return made end
local function actor(id,where,anchor,offset)
    local e=H.actor(id,4,true,'shambler');setmetatable(e,{__index=cls})
    e:SetPos(pos(where,offset));e.LODHomeCellKey=key(anchor or where)
    e.LODActivated=true;e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes.shambler)
    e.LODNextAttack=0;e.LODNextTargetRefresh=0;e.LODNextRouteRefresh=0
    e.LODWaypoints={};e.LODWaypointIndex=1;e.LODMotionLastUpdate=clock
    e.WorldSpaceCenter=function(self)return self:GetPos()+Vector(0,0,36)end
    e.GetAngles=function()return {y=0}end;e.SetAngles=function()end
    e._SetActivity=function()end;e.EmitSound=function()end;e.SetColor=function()end
    e.SetSolid=function()end;e.SetCollisionBounds=function()end
    e.GetModel=function(self)return self.LODConfig.model end
    e.GetNW2Float=function(self,k,default)return self.nw[k] or default end
    e.GetNW2Int=e.GetNW2Float;e.GetNW2Vector=e.GetNW2Float;e.SetNW2Entity=e.SetNW2Bool
    made[#made+1]=e
    return e
end
hero.WorldSpaceCenter=function(self)return self:GetPos()+Vector(0,0,36)end
hero.TakeDamage=function(self,n,attacker)self.hits=(self.hits or 0)+1;self.lastAttacker=attacker end
local function deploy()
    S:Reset();R.State.PlayerState={};at(clock+10)
    hero:SetPos(pos(H.cell(0)));hero.hits=0
    S:Deployed(hero,R.State);S:Service()
    hero:SetPos(pos(dest));at(clock+1);S:Service()
end
local function tick(e)
    if not e.co then e.co=coroutine.create(function()cls.RunBehaviour(e)end)end
    local ok,err=coroutine.resume(e.co);assert(ok,err)
end
util.TraceLine=function(t)return {Hit=false,StartSolid=false,Fraction=1,HitPos=t.endpos}end
deploy()
local ghost=actor('returning-body',current,home)
assert(N:Distance(g,home,dest)==8 and N:Distance(g,current,dest)==2)
local close=actor('revealed-body',dest,dest,Vector(60,0,12))
assert(not S:Claim(ghost),'out-of-home-leash actor stole the only opening attack slot')
assert(not S.Records['gate-hero'].wave,'non-engaging actor created an empty contact')
ghost:_RefreshTarget(g)
assert(ghost.LODTarget==nil and ghost.LODReturningHome,'native home leash was bypassed')
tick(close)
assert(close.LODTarget==hero and hero.hits==1 and hero.lastAttacker==close,
    'nearby gate-revealed actor did not enter its actual native attack')
assert(S.Records['gate-hero'].wave.count==1,'repair bypassed combined opening quota')
for i=1,6 do tick(actor('extra-'..i,dest,dest,Vector(80+i,0,12)))end
assert(S.Records['gate-hero'].wave.count==1 and hero.hits==1,'gate reveal released a swarm')
-- Admission is not permission to attack through a closed gate or cover.
deploy();R.State.GatesOpen[1]=false
local across=actor('closed-gate',gate.beforeCell,gate.beforeCell)
tick(across);assert(not across.LODTarget and hero.hits==0,'closed gate acquired a Hero')
R.State.GatesOpen[1]=true;at(clock+.1)
local covered=actor('covered-body',dest,dest,Vector(60,0,12))
util.TraceLine=function(t)return {Hit=true,StartSolid=false,Fraction=.5,HitPos=t.endpos}end
tick(covered);assert(covered.LODTarget==hero and hero.hits==0,'cover did not block native melee')
util.TraceLine=function(t)return {Hit=false,StartSolid=false,Fraction=1,HitPos=t.endpos}end
at(clock+.1);tick(covered);assert(hero.hits==1,'visible actor stayed disarmed after cover cleared')
-- A reservation hint is not proof of an actual acquired target in release logs.
covered.LODTarget=nil;covered.LODEntryTarget=hero
LOD.HostileRegistry={List=function()return {covered}end}
LOD.EncounterDirector.Entities={};LOD.WanderingDirector.Entities={}
local snap=S:Snapshot();assert(snap.heroes[1].admitted==1 and snap.heroes[1].engaged==0,
    'release observer misreported a reserved but target-free actor as engaged')
print('GATE_ENGAGEMENT_PASS: real first-gate/home-leash ghost rejected; native close attack, shared reveal quota, closed gate/cover, real-target diagnostics')

-- Native target changes invalidate return/patrol goals without destroying a
-- physically committed stair connector. Invalid/dead/invisible targets retire.
deploy()
local routeActor=actor('stale-route',dest,dest)
local stale={{pos=pos(home),tolerance=18}}
routeActor.LODWaypoints=stale;routeActor.LODNextRouteRefresh=clock+50
routeActor:_RefreshTarget(g)
assert(routeActor.LODTarget==hero and #routeActor.LODWaypoints==0 and routeActor.LODNextRouteRefresh==0,
    'new target inherited old patrol/return-home goal')
routeActor.LODTarget=nil;routeActor.LODNextTargetRefresh=0
local stair={{pos=pos(home),stair=true,tolerance=18}}
routeActor.LODWaypoints=stair;routeActor:_RefreshTarget(g)
assert(routeActor.LODWaypoints==stair,'acquisition abandoned a committed stair connector')
routeActor.LODWaypoints=stale;routeActor.LODNextTargetRefresh=0
LOD.RPGPerceptionState={IsInvisible=function(_,p)return p==hero end}
routeActor:_RefreshTarget(g)
assert(not routeActor.LODTarget and #routeActor.LODWaypoints==0,'invisibility retained stale target/route')
LOD.RPGPerceptionState=nil
-- A stale no-target polling deadline gets one withdrawal tick, never starvation.
deploy()
local delayed=actor('delayed-refresh',dest,dest,Vector(60,0,12))
delayed.LODNextTargetRefresh=clock+50
tick(delayed);at(clock+.05);tick(delayed)
assert(hero.hits==1 and delayed.LODTarget==hero,'newly reachable Hero waited for old polling deadline')
-- Nearby teammates share the same contact; neither may allocate its own swarm.
deploy()
local second=H.actor('gate-teammate',2)
second.WorldSpaceCenter=hero.WorldSpaceCenter;second.TakeDamage=hero.TakeDamage
second:SetPos(pos(H.cell(0)));heroes={hero,second};T.setHeroes(heroes)
S:Deployed(second,R.State);second:SetPos(pos(dest,Vector(100,0,12)));at(clock+.1);S:Service()
local pairEnemy=actor('pair-contact',dest,dest,Vector(60,0,12));tick(pairEnemy)
assert(S.Records['gate-hero'].wave.count==1 and S.Records['gate-teammate'].wave.count==1,
    'nearby teammates did not reserve the same contact')
local excess=actor('pair-excess',dest,dest,Vector(120,0,12));tick(excess)
assert(excess.LODEntrySuppressed and not excess.LODTarget,'teammate allocated an extra opening attacker')
heroes={hero};T.setHeroes(heroes)
-- The actual final Soldier burst authority must warn before releasing; a safety
-- transition cancels both state and beam and readmission creates a fresh tell.
dofile(root..'sv_soldier_shot_contract.lua')
local shots={}
ents.Create=function(class)
    assert(class=='lod_soldier_bolt','unexpected native allocation')
    local e=T.entity();e.SetAngles=function()end;e.Spawn=function()end;e.Activate=function()end
    shots[#shots+1]=e;return e
end
hero.EyePos=function(self)return self:GetPos()+Vector(0,0,64)end
local function soldier(id)
    local e=actor(id,dest,dest,Vector(180,0,12));e.LODArchetypeId='soldier'
    e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes.soldier)
    e.GetModel=function()return 'models/combine_soldier.mdl'end
    e.GetNW2Bool=e.GetNW2Float;e.LocalToWorld=function(self,v)return self:GetPos()+v end
    return e
end
deploy();local gunner=soldier('gate-gunner');tick(gunner)
local burst=assert(gunner.LODSoldierBurst,'revealed Soldier never began its real attack routine')
assert(burst.windupEnd==clock+gunner.LODConfig.burstTelegraph and #shots==0 and gunner.nw.LOD_SoldierShotTelegraph,
    'ranged admission skipped or shortened the tell')
at(burst.windupEnd-.01);tick(gunner);assert(#shots==0,'early bolt')
at(burst.windupEnd);tick(gunner);assert(#shots==1,'warned bolt never released')
local frozen=burst.shotDirection
hero:SetPos(hero:GetPos()+Vector(0,80,0))
for i=1,2 do at(clock+gunner.LODConfig.burstShotInterval+.001);tick(gunner)end
assert(#shots==3 and not gunner.LODSoldierBurst and shots[3].LODDirection:DistToSqr(frozen)<.000001,
    'ordinary three-shot frozen commitment changed')
at(gunner.LODNextAttack+.01);tick(gunner);assert(gunner.LODSoldierBurst)
hero:SetPos(pos(H.cell(0)));at(clock+.1);tick(gunner)
assert(not gunner.LODSoldierBurst and not gunner.nw.LOD_SoldierShotTelegraph,
    'sanctuary transition retained burst or visible beam')
hero:SetPos(pos(dest));at(clock+.1);tick(gunner)
at(gunner.LODNextAttack+.01);tick(gunner)
assert(gunner.LODSoldierBurst and gunner.LODSoldierBurst.windupEnd>clock and #shots==3,
    'readmission replayed an old shot instead of a full fresh warning')
-- Sniper cancellation uses the production owner, including presentation.
local sniperSource=read(root..'sv_enemy_update.lua')
LOD.EnemyUpdate={}
assert(load('local U=...\n'..assert(sniperSource:match('(function U:Cancel%(.-\nend)')),
    '@production-sniper-cancel'))(LOD.EnemyUpdate)
gunner.LODSniperShot={target=hero,ready=clock-1};gunner:SetNW2Bool('LOD_SoldierShotTelegraph',true)
S:Cancel(gunner)
assert(not gunner.LODSniperShot and not gunner.nw.LOD_SoldierShotTelegraph,'suppressed Sniper retained stale shot')
-- Freeze/reset remain ownership barriers; this checkpoint does not spend quota
-- or start attacks for staged, invisible or replaced worlds.
S:Reset();R.State.SimulationFrozen=true;local before=gunner:GetPos()
S:BeforeAI(gunner);assert(gunner:GetPos()==before and next(S.Records)==nil,'freeze created admission work')
R.State.SimulationFrozen=false
local owner=S.Owner;local replacement={};for k,v in pairs(R.State)do replacement[k]=v end
R.State=replacement;S:Context();assert(S.Owner~=owner and next(S.Records)==nil,'replacement world kept old contacts')
print('GATE_ENGAGEMENT_LIFECYCLE_PASS: stale routes/stairs, concealment, bounded refresh, shared co-op quota, real Soldier tell/burst/cancel/rearm, Sniper retirement, freeze/reset')

-- An actor displaced beyond its OWN leash must not steal a slot even when the
-- Hero is still within six cells of its home (the complementary route gate).
LOD.EnemyUpdate=nil
deploy();hero:SetPos(pos(current));at(clock+.1);S:Service()
local returning=actor('outside-current-leash',dest,home)
assert(N:Distance(g,home,current)==6 and N:Distance(g,home,dest)==8)
tick(returning);returning:_RefreshTarget(g);returning:_RefreshRoute(g)
assert(not S.Records['gate-hero'].wave and not returning.LODTarget and returning.LODReturningHome,
    'out-of-leash returning body reserved a contact that native routing cannot execute')
local ready=actor('ready-at-hero',current,current,Vector(60,0,12));tick(ready)
assert(hero.hits==1 and ready.LODTarget==hero,'returning actor suppressed the ready nearby body')
print('GATE_CURRENT_LEASH_PASS: displaced actor and Hero home-leash gates agree before reservation')

-- A cached positive target cannot authorize a new reservation after movement.
deploy()
local stalePositive=actor('stale-positive',current,home)
stalePositive.LODTarget=hero;stalePositive.LODNextTargetRefresh=clock+.2
local deadline=stalePositive.LODNextTargetRefresh
assert(not S:Claim(stalePositive) and not S.Records['gate-hero'].wave,
    'cached target bypassed fresh native leash eligibility')
assert(stalePositive.LODNextTargetRefresh==deadline,'eligibility check reset ordinary polling budget')
local live=actor('fresh-ready',dest,dest,Vector(60,0,12));tick(live)
assert(hero.hits==1,'stale positive target starved the ready actor')
print('GATE_FRESH_SELECTION_PASS: cached positive target cannot reserve; native refresh cadence preserved')

-- Cached target concealment/death is rechecked even when another visible Hero
-- supplies the initial local admission candidate.
for _,invalid in ipairs({'invisible','dead','inactive'})do
    deploy();second:SetPos(pos(H.cell(0)));heroes={hero,second};T.setHeroes(heroes)
    S:Deployed(second,R.State);second:SetPos(pos(dest,Vector(100,0,12)));at(clock+.1);S:Service()
    local cached=actor('cached-'..invalid,dest,dest,Vector(60,0,12))
    cached.LODTarget=hero;cached.LODNextTargetRefresh=clock+.2
    if invalid=='invisible' then LOD.RPGPerceptionState={IsInvisible=function(_,p)return p==hero end}
    elseif invalid=='dead' then hero.LODDead=true
    else hero.active=false end
    -- The native membership predicate excludes dead players; this doubled Hero
    -- implements Alive through Health, so represent that engine boundary here.
    local alive=hero.Alive;if invalid=='dead'then hero.Alive=function()return false end end
    assert(not S:Claim(cached) and not S.Records['gate-teammate'].wave,
        'cached '..invalid..' target stole the visible teammate contact')
    hero.Alive=alive;hero.LODDead=nil;hero.active=nil;LOD.RPGPerceptionState=nil
    heroes={hero};T.setHeroes(heroes)
end
-- Existing native selection may draw Reckless. Admission and execution consume
-- that ONE scheduled decision, including negative retries; never preflight RNG.
local status=LOD.RPGStatusElements
local statusSource=read(root..'sv_rpg_status_elements.lua')
assert(load('local System=...;local valid=IsValid\n'..assert(statusSource:match('(function System:ChooseRecklessTarget%(.-\nend)')),
    '@production-reckless-target'))(status)
local draws=0;local roll=2;local reckless
status.AllowsFriendlyFire=function(_,e)return e==reckless end
status._RNG=function(_,name)assert(name=='reckless:betrayal');return {Int=function()draws=draws+1;return roll end}end
deploy();reckless=actor('reckless-body',dest,dest,Vector(60,0,12))
local ally=actor('reckless-ally',dest,dest,Vector(120,0,12))
LOD.HostileRegistry={List=function()return {reckless,ally}end}
assert(S:Claim(reckless)==hero);tick(reckless)
assert(draws==1 and hero.hits==1 and reckless.LODTarget==hero,'admission rerolled native Reckless selection')
deploy();reckless=actor('reckless-negative',dest,dest,Vector(60,0,12));roll=1
local beforeDraws=draws
for i=1,20 do assert(not S:Claim(reckless))end
assert(draws==beforeDraws+1 and not S.Records['gate-hero'].wave,'negative admission redrew every coroutine tick')
status.ChooseRecklessTarget=nil;status.AllowsFriendlyFire=function()return false end
-- Existing reservation retains finite/infinite primary and escape holds.
deploy();local heldOwner=actor('owned-contact',dest,dest,Vector(60,0,12))
assert(S:Claim(heldOwner)==hero)
for _,deadline in ipairs({clock+5,math.huge})do
    heldOwner.LODTarget=nil;heldOwner.LODNextTargetRefresh=deadline
    local pending={target=hero};heldOwner.LODSeekerState=pending
    assert(not S:BeforeAI(heldOwner) and heldOwner.LODSeekerState==pending
        and heldOwner.LODNextTargetRefresh==deadline,'reservation reset advertised owner deadline')
end
heldOwner.LODSeekerState=nil
-- Stationary controllers cannot chase to make an impossible reservation real.
-- Reuse their exact production origin/range/LOS/cone/cell eligibility; mobile
-- enemies still acquire through cover and pursue along the graph.
LOD.EnemyRoster=productionRoster
local function advanced()
    deploy();S.Records['gate-hero'].completed=2;at(clock+.1);S:Service()
end
local function stationary(id,where)
    local e=actor('stationary-'..id,where or dest,where or dest,Vector(160,0,12))
    e.LODArchetypeId=id;e.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[id])
    e.GetAngles=function()return Angle(0,180,0)end
    return e
end
advanced();local sentry=stationary('sentry')
util.TraceLine=function(t)return {Hit=true,StartSolid=false,Fraction=.5,HitPos=t.endpos}end
assert(not S:Claim(sentry) and not S.Records['gate-hero'].wave,'occluded stationary attacker reserved a contact')
util.TraceLine=function(t)return {Hit=false,StartSolid=false,Fraction=1,HitPos=t.endpos}end
sentry.LODRosterYaw=0
assert(not S:Claim(sentry),'fixed sentry acquired through its rear firing cone')
sentry.LODRosterYaw=180
assert(S:Claim(sentry)==hero,'stationary enemy with a real shot stayed unadmitted')
util.TraceLine=function(t)return {Hit=true,StartSolid=false,Fraction=.5,HitPos=t.endpos}end
assert(S:Claim(sentry)==hero,'later LOS change revoked a committed contact')
util.TraceLine=function(t)return {Hit=false,StartSolid=false,Fraction=1,HitPos=t.endpos}end
advanced();local gas=stationary('nodule',gate.beforeCell)
assert(not S:Claim(gas),'off-cell Nodule reserved a contact it cannot damage')
gas:SetPos(pos(dest,Vector(160,0,12)));gas.LODHomeCellKey=key(dest)
local gasClaim=S:Claim(gas)
assert(gasClaim==hero,'same-cell Nodule could not use its real danger volume: target='..tostring(gas.LODTarget==hero)..' eligibility='..tostring(gas:_CanAcquireTarget(g,hero,true))..' threat='..tostring(productionRoster:CanTargetFromHere(gas,hero,true))..' cap='..tostring(S.Records['gate-hero'].cap))
advanced();local beam=stationary('beamsweeper');beam.GetAngles=function()return Angle(0,0,0)end
assert(S:Claim(beam)==hero,'pre-admission cone prevented legal ready-time Beam Sweeper aim')
advanced();local ring=stationary('cordon',gate.beforeCell)
assert(productionRoster:CanTargetFromHere(ring,hero),'ordinary Cordon approach warning changed')
assert(not S:Claim(ring),'off-cell stationary ring could not execute its reserved attack')
advanced();local melee=actor('occluded-mobile',dest,dest,Vector(60,0,12))
util.TraceLine=function(t)return {Hit=true,StartSolid=false,Fraction=.5,HitPos=t.endpos}end
assert(S:Claim(melee)==hero,'repair required direct sight for ordinary mobile pursuit')
LOD.EnemyRoster=nil
print('GATE_ADMISSION_PARITY_PASS: stale invisible/dead/inactive targets, one native Reckless draw, bounded negative polling, owned deadlines, stationary cover/cone/cell, beam reorientation, mobile pursuit')

-- Wandering admission retains current-cell/floor policy rather than acquiring
-- the directed home leash through the newly shared eligibility interface.
util.TraceLine=function(t)return {Hit=false,StartSolid=false,Fraction=1,HitPos=t.endpos}end
local roamCell
for _,c in pairs(g.Cells)do
    local tag=g.CellTags[key(c)] or {}
    if c.z==dest.z and not tag.safe and tag.role~='boss' and N:Distance(g,dest,c)<=2
        and N:Distance(g,home,c)>LOD.Config.Encounter.LeashCells then roamCell=c;break end
end
assert(roamCell,'fixture needs a nearby legal non-safe roaming cell')
advanced();hero:SetPos(pos(roamCell));at(clock+.1);S:Service()
local roamer=actor('near-wanderer',roamCell,home,Vector(60,0,12))
roamer.LODWanderer=true;roamer.LODWanderFloor=roamCell.z
assert(S:Claim(roamer)==hero,'wanderer inherited a directed home leash')
advanced();hero:SetPos(pos(roamCell));at(clock+.1);S:Service()
local otherFloor=actor('wrong-floor-wanderer',roamCell,home,Vector(60,0,12))
otherFloor.LODWanderer=true;otherFloor.LODWanderFloor=roamCell.z+1
assert(not S:Claim(otherFloor) and not S.Records['gate-hero'].wave,'off-floor wanderer reserved contact')
print('GATE_WANDER_WRAPPER_PASS: live wrapper forwards directed admission and preserves separate roaming home/floor policy')

-- Listener native selection deliberately returns receipt.hero, distance zero.
-- Its current sensory receipt must remain authoritative even after displacement.
LOD.EnemyRoster=productionRoster
LOD.RPGAbilityRules={ProgressionState=function(_,e)return e.profile end}
local perceptionSource=read(root..'sv_enemy_perception.lua')
assert(load('local F,E,N=LOD.FactionManager,LOD.EnemyRoster,LOD.MazeNavigator\n'..
    assert(perceptionSource:match('(function F:HeardFootstep%(.-\nend)')),'@production-heard-footstep'))()
advanced();hero:SetPos(pos(roamCell));at(clock+.1);S:Service()
local listener=actor('displaced-listener',roamCell,home,Vector(60,0,12))
listener.LODArchetypeId='listener';listener.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes.listener)
productionRoster:Prepare(listener)
hero.profile={};status.ActorLives={[hero]={}}
F.Footsteps={[hero]=productionRoster:Bind({hero=hero,position=hero:GetPos(),cell=roamCell,
    time=clock,expires=clock+1.5,heroState=hero.profile,heroLife=status.ActorLives[hero]},R.State)}
assert(N:Distance(g,home,roamCell)>6 and S:Claim(listener)==hero and listener.LODTarget==hero,
    'admission replaced native Listener hearing authority with a home leash')
advanced();hero:SetPos(pos(roamCell));at(clock+.1);S:Service()
listener.LODTarget=hero;listener.LODNextTargetRefresh=clock+50
assert(not S:Claim(listener),'expired sensory receipt remained an eligible cached contact')
print('GATE_LISTENER_AUTHORITY_PASS: actual footstep receipt, native zero-distance override, displaced source, expired receipt rejection')
