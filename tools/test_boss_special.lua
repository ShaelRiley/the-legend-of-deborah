local F=dofile('tools/boss_special_fixture.lua')
local B=F.B
local root='gamemodes/legend_of_deborah/gamemode/lod/bosses/'
for _,id in ipairs({'button','joilette','melf'}) do dofile(root..'sv_'..id..'.lua') end
local checks=0
local function ok(value,label) checks=checks+1;assert(value,label) end
local function equal(a,b,label) ok(a==b,label..' ('..tostring(a)..' ~= '..tostring(b)..')') end
local function route(c,o,p)
    p.pos=o.pos+Vector(180,0,0);c.def:TrackApproaches(c,{p},F.time)
    F.advance(c,.2);p.pos=o.pos+Vector(90,0,0);c.def:TrackApproaches(c,{p},F.time)
    F.advance(c,.2);p.pos=o.pos+Vector(45,0,0);c.def:TrackApproaches(c,{p},F.time)
    F.advance(c,.3);c.def:TrackApproaches(c,{p},F.time)
end
local function press(c,o,p) route(c,o,p);c.def:ObjectEvent(c,o,'use',p) end
-- Button: baseline destinations, E-only HP, timeouts, fakes, pair and final gate.
local c=F.new('button',1);F.advance(c,.1,true)
equal(#c.data.pedestals,10,'ten supported destinations')
equal(#c.data.real,1,'solo has one real button')
local hp=c.actor:Health();local first=c.data.real[1];local p=c.targets[1]
ok(c.def:BeforeDamage(c,c.actor,{kind='bullet'})==false,'ordinary attack immune')
ok(c.def:BeforeDamage(c,F.actor(),{})==true,'obstruction enemies remain damageable')
p.pos=first.pos;c.def:ObjectEvent(c,first,'use',p)
equal(c.actor:Health(),hp,'teleport arrival cannot immediately use')
press(c,first,p)
equal(c.data.successes,1,'legal baseline route earns segment')
ok(c.actor:Health()<hp,'only accepted use removes native HP')
c.def:ObjectEvent(c,first,'use',p);equal(c.data.successes,1,'duplicate use idempotent')
F.advance(c,1.1,true);local second=c.data.real[1]
ok(first.pedestal~=second.pedestal,'no immediate pedestal repeat')
local before=c.data.successes;local deadline=c.data.deadline
F.advance(c,deadline-F.time+.1,true)
equal(c.data.successes,before,'miss never removes old progress')
equal(c.phase,1,'timeout has no permanent escalation')
equal(c.notices[#c.notices],'TOO SLOW','timeout announced')
F.advance(c,1.1,true);local remaining=c.data.deadline-F.time
c.def:Pause(c);F.advance(c,50);c.def:Think(c,F.time,0,{p})
ok(math.abs(c.data.deadline-F.time-remaining)<.01,'ordinary retention pauses button window')
-- Phase 3 fake bounded damage, real remains armed and timer unchanged.
c.data.successes=6;B:SetPhase(c,3);c.def:BeginCycle(c,{p})
local fake=c.data.fake[1];ok(fake~=nil,'distinguishable phase three fake exists')
local real=c.data.real[1];deadline=c.data.deadline
press(c,fake,p)
equal(#c.damage,1,'fake gives one bounded punishment')
equal(c.data.deadline,deadline,'fake does not reset timer')
ok(not real.claimed and not real.retired,'fake does not reset real')
-- Solo cannot get pair even on cadence.
c.data.cycle=2;c.def:BeginCycle(c,{p});equal(#c.data.real,1,'solo never pair')
local co=F.new('button',2);co.phase=2;co.data.cycle=2;co.def:BeginCycle(co,co.targets)
equal(#co.data.real,2,'co-op occasional pair')
local a,b=co.data.real[1],co.data.real[2];hp=co.actor:Health()
press(co,a,co.targets[1]);equal(co.actor:Health(),hp,'first pair use alone no damage')
press(co,b,co.targets[2]);equal(co.data.successes,1,'same-window pair earns one segment')
-- Big Red defeats native actor; Jail Key is still a separate interaction.
c.data.successes=c.data.required-1;c.def:BeginCycle(c,{p});local big=c.data.real[1]
ok(c.data.final,'last segment is Big Red')
press(c,big,p);ok(c.dead and c.receipt,'Big Red creates legitimate defeat receipt')
equal(c.keyCount,0,'Big Red alone does not drop key')
c.def:PostDefeat(c,F.time);local key=c.data.keyButton;ok(key and key.spec.role=='key_button','postdefeat key button admitted')
c.def:ObjectEvent(c,key,'use',p);equal(c.keyCount,1,'Jail Key E request uses canonical key authority')
c.def:ObjectEvent(c,key,'use',p);c.def:PostDefeat(c,F.time);equal(c.keyCount,1,'key interaction cannot duplicate key')
local bad=F.new('button',1);bad.unsafe=true;F.advance(bad,.1,true)
ok(bad.data.deadline==nil,'unsupported destination never starts timer')
-- Joilette: one receipt per successful physical Cleaner; all damage channels deny.
local j=F.new('joilette',1);p=j.targets[1]
for _,kind in ipairs({'bullet','blast','magic','status','physics','penetration','wallCrush'}) do
    ok(j.def:BeforeDamage(j,j.actor,{kind=kind})==false,'BDD rejects '..kind)
end
F.advance(j,.1,true);local slot=j.data.cleaners[1];local neil=slot.actor
ok(neil and neil.archetype=='neil' and neil.opts.manual==false,'Cleaner uses ordinary Neil actor/AI')
F.kill(j,neil);ok(not j.dead,'Cleaner Neil cannot complete boss');F.advance(j,.01)
equal(slot.state,'item','native Cleaner Neil death schedules unique drop')
local item=slot.object;j.def:ObjectEvent(j,item,'use',p)
equal(slot.state,'carried','E binds unique receipt to Hero life')
j.def:ObjectEvent(j,item,'use',p);equal(slot.state,'carried','repeat pickup harmless')
j.failObjects=true
ok(not j.def:PrimaryInput(j,p,IN_ATTACK),'throw budget failure fails safely')
equal(slot.state,'carried','budget failure retains carried Cleaner');j.failObjects=nil
ok(j.def:PrimaryInput(j,p,IN_ATTACK),'LMB throws Cleaner')
local thrown=slot.projectile;local generation=slot.generation
j.def:ImpactCleaner(j,slot,generation,thrown,{Entity=F.actor()})
equal(j.data.hits,0,'miss never advances BDD');equal(slot.state,'pending','miss guarantees replacement')
F.advance(j,1.1,true);ok(slot.actor~=neil and slot.state=='neil','lost opportunity reappears as Cleaner Neil')
F.kill(j,slot.actor);F.advance(j,.01);j.def:ObjectEvent(j,slot.object,'use',p)
p.life=p.life+1;j.def:ServiceCleaners(j,F.time)
equal(slot.state,'item','replacement Hero body cannot inherit old carry')
j.def:ObjectEvent(j,slot.object,'use',p);j.def:PrimaryInput(j,p,IN_ATTACK)
thrown=slot.projectile;generation=slot.generation
ok(j.def:ImpactCleaner(j,slot,generation,thrown,{Entity=j.actor}),'first valid Cleaner impact')
equal(j.data.hits,1,'first hit exactly 1/3');equal(j.phase,2,'first hit opens Out of Order')
j.def:ImpactCleaner(j,slot,generation,thrown,{Entity=j.actor});equal(j.data.hits,1,'same individual never counted twice')
ok(j.def:BeforeDamage(j,j.actor,{kind='magic'})==false,'one Cleaner still invulnerable')
-- Every remaining opportunity forced lost once, then still obtainable.
for i=2,3 do
    slot=j.data.cleaners[i]
    if slot.actor then slot.actor.valid=false end
    slot.nextAt=F.time;j.def:ServiceCleaners(j,F.time)
    F.advance(j,1.1,true)
    if slot.state=='pending' then slot.nextAt=F.time;j.def:ServiceCleaners(j,F.time) end
    ok(slot.actor~=nil,'future required Cleaner '..i..' is guaranteed without RNG')
    F.kill(j,slot.actor);F.advance(j,.01)
    j.def:ObjectEvent(j,slot.object,'use',p);j.def:PrimaryInput(j,p,IN_ATTACK)
    thrown=slot.projectile;generation=slot.generation
    ok(j.def:ImpactCleaner(j,slot,generation,thrown,{Entity=j.actor}),'unique Cleaner '..i..' accepted')
end
equal(j.data.hits,3,'exactly three Cleaner hits');equal(j.phase,3,'third flush exposes primary')
ok(j.def:BeforeDamage(j,j.actor,{kind='bullet'})==true,'normal damage works after BDD break')
local actors=#j.actors
j.def:ServiceCleaners(j,F.time+100);equal(#j.actors,actors,'no Cleaner farming after break')
ok(not j.def:PrimaryInput(j,p,IN_ATTACK),'Cleaner input disabled after break')
local keypos=j.def:KeyPosition(j);equal(keypos.x,j.actor:GetPos().x,'authored bowl key safe position')
F.kill(j,j.actor);equal(j.keyCount,1,'only exposed native primary death grants key')
-- New encounter state rejects old receipts; failed/retired callbacks cannot mutate.
local retired=F.new('joilette',1);local r=retired.data.cleaners[1]
retired.def:DropCleaner(retired,r,Vector());retired.def:ObjectEvent(retired,r.object,'use',retired.targets[1])
retired.def:PrimaryInput(retired,retired.targets[1],IN_ATTACK);local projectile=r.projectile
retired.retired=true
ok(not retired.def:ImpactCleaner(retired,r,r.generation,projectile,{Entity=retired.actor}),'stale receipt rejected')
equal(retired.data.hits,0,'retired impact cannot advance progress')
-- Melf: immutable kit, class core, actual representative weapon, body succession.
local m=F.new('melf',3,{'fighter','rogue','wizard'})
equal(#m.data.kits,3,'one frozen kit per committed Hero');equal(#m.data.bodies,3,'one evil copy per committed Hero')
local fighter=m.data.bodies[1];local rogue=m.data.bodies[2];local wizard=m.data.bodies[3]
equal(fighter.kit.weapon,'weapon_crowbar','representative weapon retained')
equal(#fighter.kit.signatures,2,'at most two executable signature feats')
for _,id in ipairs(fighter.kit.profile.featIds) do ok(id~='TIME_MANAGEMENT','progression utility not mirrored') end
equal(m.def:WeaponSpec(fighter,false).dice[2],6,'copied Bash executes native crowbar profile')
ok(rogue.actor.LODProgressionState.derivedStats.rogueBackstabEnabled,'rogue class core derives')
ok(wizard.actor.LODProgressionState.derivedStats.hpToMagicDiversionFraction>0,'wizard Arcane Shield derives')
m.heroes[3].progressionState.magicFormIds[1]='summon';m.heroes[1].progressionState.featIds[2]='TIME_MANAGEMENT'
equal(wizard.kit.forms[1],'beam','later spell changes never rewrite committed kit')
equal(fighter.kit.profile.featIds[1],'STR_CROWBAR_D6','later equipment/build changes never rewrite kit')
equal(m.def:Target(m,fighter,m.targets),m.targets[1],'evil mirror initially prefers original')
-- Concrete attacks use shared packets, owned forms and Magic spend.
m.targets[1].pos=Vector(50,0,0);fighter.actor.pos=Vector()
m.def:Physical(m,fighter,m.targets[1],'FIGHTER',120,.5);F.advance(m,.6)
equal(#m.damage,1,'fighter attack executes shared packet')
wizard.serial=1;local magic=wizard.actor.LODProgressionState.magic
ok(m.def:Spell(m,wizard,m.targets[3],false),'Wizard executes actually owned form');F.advance(m,1.2)
ok(wizard.actor.LODProgressionState.magic<magic,'Wizard pays native Magic pool')
ok(#m.zones>0 and m.zones[#m.zones].label=='MIRROR BEAM','owned Beam uses readable fixed lane')
-- Delayed attacks cannot strike a replacement life.
m.def:Physical(m,fighter,m.targets[1],'STALE',120,.5);m.targets[1].life=m.targets[1].life+1
local hits=#m.damage;F.advance(m,.6);equal(#m.damage,hits,'old body commitment cannot damage replacement Hero')
-- Kill primary first; same encounter adopts an existing survivor, no key.
local old=m.actor;F.kill(m,old);F.advance(m,.01)
ok(m.actor~=old and not m.dead,'first body death transfers primary to survivor');equal(m.keyCount,0,'mirror death no key')
for _,body in ipairs(m.data.bodies) do if not body.dead then F.kill(m,body.actor) end end
F.advance(m,.01);F.advance(m,1.9,true)
equal(m.phase,2,'all evil copies must die before Bare Bones');equal(#m.data.bodies,3,'same three skeleton identities')
for i,body in ipairs(m.data.bodies) do equal(body.kit.identity,m.data.kits[i].identity,'skeleton identity '..i..' unchanged') end
local skeleton=m.data.bodies[1];local info={context={wallCrush=true},GetDamage=function() return 3 end,GetDamageForce=function() return Vector() end}
m.def:BeforeDamage(m,skeleton.actor,info);ok(skeleton.brokenUntil>F.time,'wall slam triggers bounded Bone Break')
local breaks=#m.staggers;m.def:BeforeDamage(m,skeleton.actor,info);equal(#m.staggers,breaks,'Bone Break cannot be renewed indefinitely')
F.advance(m,8.1);skeleton.actor.LODLastPushback={at=F.time,moved=140}
m.def:Think(m,F.time,.1,m.targets)
ok(skeleton.brokenUntil>F.time,'strong Push receipt triggers Bone Break without impact damage')
for _,body in ipairs(m.data.bodies) do F.kill(m,body.actor) end
F.advance(m,.01);F.advance(m,1.9,true)
equal(m.phase,3,'all skeletons must die before giant');equal(#m.data.bodies,1,'one giant only')
equal(m.rngCalls.melf_giant_identity,1,'giant identity rolls exactly once')
local giant=m.data.bodies[1];local selected=m.data.giantIndex
m.heroes[#m.heroes+1]={identity='late join',player=F.actor(Vector(),true),progressionState={}}
m.def:Think(m,F.time,.1,m.targets);equal(m.data.giantIndex,selected,'late join cannot change giant selection')
ok(m.def:BeforeDamage(m,giant.actor,{})~=false,'giant is directly damageable')
local h=giant.actor:Health();ok(m.def:Reflect(m,giant,m.data.pylons[1].pos),'pylon reflects committed impact')
ok(giant.actor:Health()<h and giant.actor:Health()>0,'reflection damages native giant nonlethally')
for _,class in ipairs({'fighter','rogue','wizard'}) do
    local g=F.new('melf',1,{class});g.def:BeginStage(g,3)
    local body=g.data.bodies[1]
    for serial=1,4 do body.serial=serial;g.def:Giant(g,body,g.targets[1],g.targets);F.advance(g,2) end
    ok(#g.charges>=1,class..' giant has Stop Hitting Yourself')
    if class=='fighter' then ok(#g.zones>=2,'giant Fighter slam and sweep')
    elseif class=='rogue' then ok(#g.zones>=6,'giant Rogue weapon rain and sequential shadows')
    else ok(#g.zones>0 or #B:Objects(g,'mirror_spell')>0,'giant Wizard uses owned forms') end
end
F.kill(m,giant.actor);ok(m.dead,'only giant primary death completes Melf');equal(m.keyCount,1,'giant completion grants exactly one key')
-- Native body loss is recoverable identity state, never a death receipt.
local lost=F.new('melf',2,{'fighter','wizard'})
local primaryRecord=lost.data.primaryBody;local oldPrimary=lost.actor
primaryRecord.serial=7;oldPrimary.hp=63;oldPrimary.maxhp=195;oldPrimary.pos=Vector(420,350,0)
lost.def:AfterDamage(lost,oldPrimary)
lost.targets[1].pos=oldPrimary.pos+Vector(60,0,0)
lost.def:Physical(lost,primaryRecord,lost.targets[1],'OLD BODY WARNING',120,.5)
local oldWarning=lost.pending['melf_attack:1'].fn
local primaryKit=primaryRecord.kit;local bodyCount=#lost.data.bodies;oldPrimary.valid=false
local newPrimary=B:SpawnActor(lost,'melf','primary',primaryRecord.savedPos,{manual=true})
newPrimary.hp=63;newPrimary.maxhp=195;lost.actor=newPrimary;lost.primary=newPrimary
ok(lost.def:ActorReplaced(lost,newPrimary),'lost primary rebinds to frozen body record')
equal(lost.data.primaryBody,primaryRecord,'primary durable record identity retained')
equal(primaryRecord.kit,primaryKit,'primary exact frozen kit retained')
equal(#lost.data.bodies,bodyCount,'replacement never appends another mirror identity')
equal(primaryRecord.actor,newPrimary,'body record now names exact new native entity')
ok(lost.data.byActor[oldPrimary]==nil and lost.data.byActor[newPrimary]==primaryRecord,'native actor map replaces old entry')
equal(newPrimary:Health(),63,'primary preserves damage already taken')
equal(newPrimary:GetMaxHealth(),195,'primary preserves canonical maximum')
equal(primaryRecord.serial,7,'replacement cannot reset class attack sequence')
local incarnation=primaryRecord.incarnation
ok(lost.def:ActorReplaced(lost,newPrimary),'duplicate recovery notification harmless')
equal(primaryRecord.incarnation,incarnation,'duplicate recovery does not allocate new incarnation')
local events=#lost.damage;oldWarning(lost);equal(#lost.damage,events,'old source-body warning cannot execute on replacement')
equal(lost.keyCount,0,'native removal cannot grant boss key')
equal(lost.phase,1,'native removal cannot advance phase')
-- Missing support stays outstanding while budget/creation are blocked, even
-- when the last extant primary is legitimately killed.
local support=lost.data.bodies[2];local oldSupport=support.actor
oldSupport.hp=37;oldSupport.maxhp=173;oldSupport.pos=Vector(600,350,0);oldSupport.LODProgressionState.magic=19
lost.def:AfterDamage(lost,oldSupport);oldSupport.valid=false
lost.failActors=true;local attempts=lost.spawnAttempts
lost.def:Think(lost,F.time,.05,lost.targets)
equal(lost.spawnAttempts,attempts+1,'one bounded support retry starts at loss')
F.advance(lost,.2,true);F.advance(lost,.2,true)
equal(lost.spawnAttempts,attempts+1,'lost support cannot hot-loop native creation')
ok(not support.dead and support.lost,'unavailable support is not treated as killed')
F.kill(lost,newPrimary);F.advance(lost,.01)
ok(lost.data.riseAt==nil,'missing support prevents premature skeleton phase')
lost.failActors=nil;lost.partialFailure=true;F.advance(lost,1,true)
ok(support.actor==oldSupport and not support.dead,'partial failed native creation preserves old outstanding identity')
equal(#lost.data.bodies,bodyCount,'partial creation failure cannot duplicate roster slot')
F.advance(lost,1.01,true)
local recovered=support.actor
ok(recovered~=oldSupport and recovered.valid,'support resumes after native creation succeeds')
equal(recovered:Health(),37,'support restores saved current HP')
equal(recovered:GetMaxHealth(),173,'support restores saved maximum HP')
equal(recovered:GetPos().x,600,'support restores same safe location')
equal(recovered.LODProgressionState.magic,19,'support restores its bounded native Magic pool')
equal(recovered.LODMirrorKit,support.kit,'recovered support uses exact kit')
equal(lost.actor,recovered,'recovered outstanding body inherits primary after real predecessor death')
ok(lost.data.byActor[oldSupport]==nil,'lost support tombstone cannot accept future native death')
equal(lost.phase,1,'successful native recovery does not advance phase')
F.kill(lost,recovered);F.advance(lost,.01);F.advance(lost,1.9,true)
equal(lost.phase,2,'only actual deaths of both recovered identities advance phase')
equal(#lost.data.bodies,2,'recovered roster rises as same two skeletons')
-- Losing the final Hero cancels transient jobs, not sealed body succession.
local pausedBodies=F.new('melf',2,{'fighter','rogue'})
local firstBody=pausedBodies.actor
F.kill(pausedBodies,firstBody);pausedBodies.pending={}
pausedBodies.def:Think(pausedBodies,F.time,.05,pausedBodies.targets)
ok(pausedBodies.actor~=firstBody,'accepted primary death reconciles after canceled pause job')
for _,body in ipairs(pausedBodies.data.bodies) do if not body.dead then F.kill(pausedBodies,body.actor) end end
pausedBodies.pending={};pausedBodies.def:Think(pausedBodies,F.time,.05,pausedBodies.targets)
ok(pausedBodies.data.riseAt~=nil,'accepted final-body deaths retain stage transition without transient job')
F.advance(pausedBodies,1.9,true);equal(pausedBodies.phase,2,'ordinary no-Hero retention cannot strand Melf succession')

-- Giant selection and phase survive primary removal without another RNG draw.
local giantLost=F.new('melf',1,{'wizard'});giantLost.def:BeginStage(giantLost,3)
local giantRecord=giantLost.data.primaryBody;local giantBefore=giantLost.actor
local selectedIdentity=giantLost.data.giantIndex;local rngBefore=giantLost.rngCalls.melf_giant_identity
local pylonCount=#giantLost.data.pylons;giantBefore.hp=451;giantBefore.LODProgressionState.magic=23
giantLost.def:AfterDamage(giantLost,giantBefore);giantBefore.valid=false
local giantAfter=B:SpawnActor(giantLost,'melf','primary',giantRecord.savedPos,{manual=true})
giantAfter.hp=451;giantAfter.maxhp=giantRecord.savedMax;giantLost.actor=giantAfter;giantLost.primary=giantAfter
giantLost.def:ActorReplaced(giantLost,giantAfter)
equal(giantLost.data.giantIndex,selectedIdentity,'giant identity survives missing native body')
equal(giantLost.rngCalls.melf_giant_identity,rngBefore,'giant recovery never rerolls RNG')
equal(#giantLost.data.pylons,pylonCount,'giant recovery never duplicates pylons')
equal(#giantLost.data.bodies,1,'giant recovery keeps one body slot')
equal(giantAfter.nw.LOD_MelfGiant,true,'giant presentation and collision kit restored')
equal(giantAfter:Health(),451,'giant damage retained')
equal(giantAfter.LODProgressionState.magic,23,'giant Magic retained')
F.kill(giantLost,giantAfter);equal(giantLost.keyCount,1,'recovered giant still finishes by native primary death')
-- Same-seed rebuilt dungeon cannot inherit pending old support or callbacks.
local stale=F.new('melf',2,{'fighter','rogue'});local replacementRun=F.new('melf',2,{'wizard','rogue'})
local scope={current=replacementRun};stale.scope=scope;replacementRun.scope=scope
stale.seed=42;replacementRun.seed=42
stale.data.bodies[2].actor.valid=false
local oldAttempts=stale.spawnAttempts;local freshBodies=#replacementRun.data.bodies
stale.def:Think(stale,F.time+20,.05,stale.targets)
equal(stale.spawnAttempts,oldAttempts,'same seed does not revive work in retired encounter identity')
local bogus=F.actor();stale.actor=bogus
ok(not stale.def:ActorReplaced(stale,bogus),'old primary replacement notification rejected after scope reset')
equal(#replacementRun.data.bodies,freshBodies,'old work cannot mutate same-seed replacement encounter')

-- Client modules also execute against a primitive renderer double.
LOD.BossPresentation={Modules={}};local draws=0
render={SetColorMaterial=function() end}
for _,id in ipairs({'DrawSphere','DrawBox','DrawBeam','DrawWireframeSphere'}) do render[id]=function() draws=draws+1 end end
for _,id in ipairs({'melf','button','joilette'}) do
    dofile(root..'cl_'..id..'.lua')
    local e=F.actor();local module=LOD.BossPresentation.Modules[id]
    local start=draws;module:Draw(e,1,{dead=false});ok(draws>start,id..' live presentation renders')
    start=draws;module:Draw(e,1,{dead=true,deathAt=F.time});ok(draws>start,id..' defeat presentation renders')
    if module.Pose then ok(module:Pose(e,1,{dead=true,deathAt=F.time}).angles~=nil,id..' bounded defeat pose') end
end
print('PASS special boss module outcomes: '..checks..' assertions')
