-- End-to-end headless production integration, not module API doubles.
local F=dofile('tools/boss_framework_fixture.lua')
local B,R,P,N=F.B,F.R,F.P,F.N
local passed,failed=0,{}
local function test(name,fn)
 local ok,err=xpcall(fn,debug.traceback)
 if ok then passed=passed+1;print('BOSS_FRAMEWORK_PASS '..name) else failed[#failed+1]={name=name,error=err};print('BOSS_FRAMEWORK_FAIL '..name..'\n'..err) end
end
local function check(v,msg) assert(v,msg) end
local function count(class) return #ents.FindByClass(class) end
local function quiet(c) c.data.nextAttack=F.clock+1000;c.data.nextWing=F.clock+1000 end
local order={'warden','chonker','felon','melf','ollie','crystal_bepis','daryl','sofa','marion','button','ray','cornette','moshi','chuck','rank_and_file','flightmeister','conan','joilette','little_mooky','warden'}
test('exact canonical registry 1 through 20 and subordinate Jane',function()
 check(#LOD.BossRegistry.Order==20,'registry must contain exactly twenty entries')
 for level,id in ipairs(order) do check(LOD.BossRegistry:ForLevel(level)==id,'wrong identity at '..level)
  check(LOD.BossRegistry:GordonClones(level)==(level==20 and 4 or 0),'wrong Gordon clone count at '..level)
  check(LOD.BossRegistry:GordonTurrets(level)==(level==20 and 4 or 0),'wrong Gordon turret count at '..level)
  if id~='warden' then check(B.Modules[id]~=nil,'missing actual module '..id) end
 end
 check(not LOD.BossRegistry.Primary.jane_propane and B.Support.jane_propane,'Jane must be support only')
end)
for level=2,19 do
 local id=order[level]
 test('actual Start Think and phases '..id,function()
  local s,c,g,a=F.setup(level)
  check(c.id==id and c.actor==c.primary and c.started and not s.Warden,'wrong primary identity')
  check(c.actor.LODProgressionState and c.actor:GetMaxHealth()==c.actor.LODProgressionState.derivedStats.maxHP,'real progression HP missing')
  check(c.actor.LODVarianceApplied,'production variance did not run')
  check(#c.points>=25 and a.bossId==id,'authored arena not loaded')
  local original=c.actor;F.step(12,.1)
  check(B:Current(c) and c.actor==original and not c.retired,'initial production service lost encounter')
  for phase=2,3 do
   B:SetPhase(c,phase);F.step(30,.1);check(B:Current(c) and c.phase==phase,'phase service failed')
  end
  check(#B:Objects(c)<=math.min(c.def.maxObjects or 32,64),'module escaped object bound')
  check(B:CountActors(c)<=1+(c.def.maxAdds or 8),'module escaped owned actor bound')
  check(F.errors()=='','module swallowed production error: '..F.errors())
 end)
end
test('prepare commit phase native death key door rescue',function()
 local s,c=F.setup(2,false);s.GatesOpen[4]=false;check(not B:Prepare(),'prepared behind Black Gate');s.GatesOpen[4]=true
 check(LOD.Warden:Prepare(),'native compatibility prepare');c=s.Boss;local serial=c.serial
 check(not P:SpawnJailKey(Vector(),'bypass'),'production progression allowed unearned Jail Key')
 check(LOD.Warden:Commit(),'native compatibility commit');local actor=c.actor;local created=#F.created
 check(not B:Commit(c) and #F.created==created,'duplicate commit created actor')
 local callback=0;B:Later(c,1,'old_phase',function() callback=callback+1 end)
 actor:SetHealth(actor:GetMaxHealth()*.5);F.step(.1);check(c.phase==2 and c.pending.old_phase==nil,'phase transition retained old commitment')
 F.step(1.1);check(callback==0,'old phase callback fired')
 actor:SetHealth(actor:GetMaxHealth()*.2);F.step(.1);check(c.phase==3,'native HP did not drive phase three')
 local before=count('lod_jail_key');F.kill(actor)
 check(c.dead and c.receipt and c.receipt.actor==actor,'native OnKilled did not seal primary receipt')
 check(count('lod_jail_key')==before,'key spawned inside lethal stack');F.flush()
 if c.def.deathDuration then F.step(c.def.deathDuration+.1) end
 local key=s.JailKeyEntity;check(IsValid(key) and key.source=='boss:chonker','wrong/missing primary Jail Key')
 check(key.LODBossKeyReceipt==c.receipt and key.LODBossEncounter==c,'key lost exact receipt')
 F.kill(actor);B:Killed(actor);F.flush();check(s.JailKeyEntity==key and c.serial==serial and count('lod_jail_key')==before+1,'duplicate callback granted another key')
 check(not P:CanRescueTarget(),'boss defeat completed rescue')
 F.p:SetPos(key:GetPos()+Vector(999,0,0));check(not P:CollectJailKey(F.p,key),'remote pickup admitted')
 F.p:SetPos(key:GetPos());check(not P:CollectJailKey(F.p,F.actor('lod_jail_key')),'wrong key admitted')
 check(P:CollectJailKey(F.p,key),'canonical Jail Key collection denied')
 check(not P:CanRescueTarget(),'key pickup skipped locked jail')
 check(P:TryOpenJailDoor(F.p,s.Graph.Progression.JailEdge.entity) and P:CanRescueTarget(),'canonical key-to-door-to-rescue eligibility failed')
end)
test('Jane native death never completes Chuck',function()
 local s,c=F.setup(14);local jane
 for e,role in pairs(c.owned) do if e.LODArchetypeId=='jane_propane' then jane=e end end
 check(IsValid(jane),'actual Chuck Start did not spawn Jane');local primary=c.actor
 F.kill(jane);F.flush();check(not c.dead and not c.receipt and not s.JailKeyEntity and c.actor==primary,'Jane acquired primary receipt')
 F.kill(primary);check(c.dead and c.receipt.actor==primary,'Chuck did not own final receipt');F.flush();check(not s.JailKeyEntity,'Chuck key preceded death presentation')
 local keyAt=c.deathAt+c.def.deathDuration;F.at(keyAt-.001,true);check(not s.JailKeyEntity,'Chuck key released before exact deathDuration');F.at(keyAt,true);check(IsValid(s.JailKeyEntity),'Chuck did not release key at exact deathDuration')
 for _,o in ipairs(c.objects) do check(o.retired or o.spec.cosmetic,'hostile hazard survived Chuck receipt') end
end)
test('no Hero retention reconnect old life and exact scope',function()
 local s,c=F.setup(2);local original=c.actor;original:SetHealth(original:GetMaxHealth()*.45);F.step(.1);local hp,phase=original:Health(),c.phase
 local binding=B:BindTarget(c,F.p);local calls=0;B:Later(c,.2,'targeted_commitment',function() calls=calls+1 end)
 for _,p in ipairs(F.players) do p.alive=false;p.ps.eliminated=true;p.ps.lives=0 end
 F.step(3);check(s.Boss==c and B:Current(c) and c.paused and not s.Failed,'party elimination reset/failed encounter')
 check(c.actor==original and original:Health()==hp and c.phase==phase and calls==0,'retention changed HP phase or offensive commitment')
 F.p.alive=true;F.p.ps.eliminated=false;F.p.ps.lives=3;F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1
 check(not B:TargetLive(c,binding),'old-life binding reacquired respawn')
 F.step(1.2);check(s.Boss==c and c.actor==original and c.phase==phase and original:Health()==hp,'rejoin rerolled encounter')
 local replacement=F.actor('player');replacement.id=F.p.id;replacement.ps=F.p.ps;replacement.LODRunSpawnSerial=999;replacement:SetPos(F.p:GetPos());replacement.hp=100
 F.p.valid=false;check(not B:TargetLive(c,binding),'old-body binding transferred to reconnect')
 F.p.valid=true;local n=#F.created;B:Later(c,.1,'stale',function() calls=calls+1 end);s.CampaignEpoch=s.CampaignEpoch+1;F.at(F.clock+.2,true)
 check(c.retired and not s.Boss and calls==0 and #F.created==n,'stale epoch serviced old work')
end)
test('actual projectile trace impact defuse and bounded object use',function()
 local s,c=F.setup(2);quiet(c);B:Clear(c);local hit=0
 local o=assert(B:Projectile(c,{kind='integration_projectile',pos=F.p:GetPos()+Vector(-50,0,0),velocity=Vector(500,0,0),gravity=0,hp=20,mass=500,life=100,bounces=99,damage={damage=15,dice={1,2,10}},onHit=function() hit=hit+1 end,breakOnImpact=false}))
 check(o.mass<=150 and o.expires<=F.clock+60 and o.bounces<=4,'physics clamp escaped')
 util.TraceHull=function(t) return {Hit=true,HitPos=F.p:GetPos(),Entity=F.p,HitNormal=Vector(-1,0,0)} end
 local hp=F.p:Health();B:ServiceObjects(c,F.clock+.1,.1)
 check(F.p:Health()<hp and hit==1,'actual trace did not enter production shared damage packet')
 local after=F.p:Health();o.velocity=Vector(500,0,0);B:ServiceObjects(c,F.clock+.2,.1);check(F.p:Health()==after and hit==1,'repeated contact damaged same life twice')
 util.TraceHull=F.clearTrace;B:Clear(c)
 local bomb;for _,pos in ipairs(c.points) do bomb=c.def:PlaceBomb(c,'black',pos);if bomb then break end end;check(bomb~=nil,'real Chonker bomb admission failed across legal court')
 bomb.ent:OnTakeDamage(F.info(F.p,1000));check(bomb.retired and bomb.state=='DEFUSED','native object damage did not safely defuse')
 local before=#F.damage;B:ServiceObjects(c,F.clock+20,.1);check(#F.damage==before,'destroyed bomb detonated')
 local used=0;local obj=assert(B:Object(c,{kind='integration_use',pos=F.p:GetPos(),use=true,hold=.5,hp=10,life=5,onUse=function() used=used+1 end}))
 F.p.keys={[IN_USE]=true};check(not obj.ent:Use(F.p,F.p),'hold bypassed first use');F.clock=F.clock+.6;B:ServiceObjects(c,F.clock,.1);check(used==1,'native use did not finish bounded hold')
end)
test('zone warning LOS alcove and charge committed target',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local center=B:Center(c);F.p:SetPos(center+Vector(100,0,0));F.q:SetPos(N:CellCenter(c.arena.entry))
 local z=assert(B:Zone(c,{kind='integration_zone',pos=center,radius=200,delay=1,life=3,interval=.3,damage={damage=12,dice={1,2,10}}}));local hp=F.p:Health();local qhp=F.q:Health()
 B:ServiceZones(c,F.clock+.9);check(F.p:Health()==hp,'zone damaged before warning')
 util.TraceLine=function(t) return {Hit=true,StartSolid=false,Entity=NULL,HitPos=t.endpos} end;B:ServiceZones(c,F.clock+1.1);check(F.p:Health()==hp,'zone ignored hard cover')
 util.TraceLine=F.clearTrace;B:ServiceZones(c,F.clock+1.5);check(F.p:Health()<hp and F.q:Health()==qhp,'zone did not isolate exposed court Hero')
 B:Clear(c);c.actor:SetPos(center);F.p:SetPos(center+Vector(150,0,0));local done,hit=false,false
 check(B:Charge(c,c.actor,center+Vector(400,0,0),{warning=.5,speed=400,width=80,damage={damage=10,dice={1,2,10}},onFinish=function(_,h) done=true;hit=h end}),'charge admission')
 local move=c.moves[c.actor];local dest=move.dest;B:Move(c,c.actor,center+Vector(-400,0,0),100);check(c.moves[c.actor]==move and move.dest==dest,'ordinary Move overwrote charge')
 hp=F.p:Health();B:ServiceMoves(c,F.clock+.4,.1);check(F.p:Health()==hp and c.actor:GetPos():DistToSqr(center)<.001,'charge moved during warning')
 B:ServiceMoves(c,F.clock+1.6,.1);check(done and hit and F.p:Health()<hp and c.actor:GetPos():DistToSqr(dest)<.001,'charge failed swept contact or frozen endpoint')
 c.actor:SetPos(center);F.p:SetPos(center+Vector(150,0,0));check(B:Charge(c,c.actor,center+Vector(400,0,0),{warning=.5,speed=400,width=80,damage={damage=10}}),'second charge admission')
 hp=F.p:Health();F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1;B:ServiceMoves(c,F.clock+1.6,.1);check(F.p:Health()==hp,'charge hit replacement target life')
end)
test('shared budgets callback dedup and frozen source',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c)
 for i=1,100 do B:Object(c,{kind='budget',pos=B:Center(c),life=30}) end
 check(#B:Objects(c)==math.min(c.def.maxObjects or 32,64),'object ceiling not exact');check(not B:Zone(c,{pos=B:Center(c),life=1}),'zones bypass common object budget')
 B:Clear(c);LOD.EnemyRoster.Projectiles={};for i=1,64 do LOD.EnemyRoster.Projectiles[i]={} end
 check(not B:Projectile(c,{pos=B:Center(c),velocity=Vector(1,0,0)}),'boss projectiles bypass shared roster ceiling');LOD.EnemyRoster.Projectiles={}
 local ran=0;B:Later(c,.1,'same',function() ran=ran+100 end);B:Later(c,.1,'same',function() ran=ran+1 end);F.step(.2);check(ran==1,'duplicate callback key did not replace work')
 local source=c.actor;local hp=F.p:Health();s.SimulationFrozen=true;check(B:Damage(c,F.p,{damage=50},source)==0 and F.p:Health()==hp,'frozen source damaged Hero')
 local info=F.info(source,50);check(GM:EntityTakeDamage(F.p,info)==true and info:GetDamage()==0,'native frozen boss damage bypassed framework gate')
 F.step(.1);check(c.paused and c.actor==source and not c.retired,'freeze destroyed retained boss')
 s.SimulationFrozen=false;F.step(1.2);check(B:Current(c) and c.actor==source,'unfreeze replaced encounter')
end)
test('native Melf succession preserves identity and one final receipt',function()
 local s,c=F.setup(4);local kits=c.data.kits;local frozen=table.Copy(kits);local serial=c.serial
 check(#kits==2 and #c.data.bodies==2,'one committed mirror kit per Hero: kits='..#kits..' bodies='..#c.data.bodies..' '..F.errors())
 for stage=1,2 do
  local bodies={};for _,m in ipairs(c.data.bodies) do bodies[#bodies+1]=m.actor end
  for _,actor in ipairs(bodies) do F.kill(actor);F.kill(actor);check(not c.dead and not c.receipt and not s.JailKeyEntity,'mirror body completed encounter');F.step(.1) end
  F.step(2.1);check(c.data.stage==stage+1 and c.phase==stage+1 and c.serial==serial,'native body deaths did not advance stable encounter stage')
 end
 check(c.data.kits==kits and #kits==#frozen and c.data.giantIndex~=nil,'giant rerolled committed kit roster')
 local selected=c.data.giantIndex;local giant=c.actor;check(giant~=nil and giant.LODBossRole=='primary','giant lacks primary authority')
 local lo,hi=giant:GetCollisionBounds();local motionLo,motionHi=B:Hull(giant);check(lo:DistToSqr(motionLo)<.001 and hi:DistToSqr(motionHi)<.001 and lo.x==-42 and hi.z==210,'native giant collision bounds stayed at ordinary body size')
 giant:SetHealth(math.floor(giant:GetMaxHealth()*.57));F.step(.1);local savedHP=giant:Health();local kit=giant.LODMirrorKit;giant:Remove();F.step(.2);giant=c.actor
 lo,hi=giant:GetCollisionBounds();check(IsValid(giant) and giant:Health()==savedHP and giant.LODMirrorKit==kit and c.data.giantIndex==selected and lo.x==-42 and hi.z==210,'recovered giant lost exact kit HP identity or native giant collision bounds')
 F.kill(giant);F.flush();F.step((c.def.deathDuration or 0)+.1)
 check(c.dead and c.receipt.actor==giant and c.data.giantIndex==selected and IsValid(s.JailKeyEntity),'giant final native receipt failed')
end)
test('native Joilette Cleaner Neil drop throw trace three hits and retention',function()
 local s,c=F.setup(18);local hp=c.actor:Health()
 c.actor:TakeDamageInfo(F.info(F.p,100000,DMG_BULLET));check(c.actor:Health()==hp and not c.dead,'bullet bypassed BDD')
 c.actor:TakeDamageInfo(F.info(F.p,100000,DMG_BLAST));check(c.actor:Health()==hp,'blast bypassed BDD')
 for i=1,3 do
  local r=c.data.cleaners[i]
  if r.state=='pending' then check(c.def:SpawnCleanerNeil(c,r),'Cleaner Neil admission failed') end
  check(IsValid(r.actor),'mandatory Cleaner Neil absent');local neil=r.actor
  F.kill(neil);F.kill(neil);F.step(.1)
  local obj=r.object;check(r.state=='item' and obj and not obj.retired,'native Cleaner Neil death did not yield exact unique item')
  F.p:SetPos(obj.pos+Vector(-40,0,0));F.lookAt(F.p,obj.pos);hook.Run('KeyPress',F.p,IN_USE);check(r.state=='carried' and r.carrier==F.p and obj.retired,'native use did not transfer Cleaner ownership')
  hook.Run('KeyPress',F.p,IN_ATTACK);check(r.state=='projectile','native primary input did not throw Cleaner');local projectile=r.projectile
  util.TraceHull=function(t) return {Hit=true,HitPos=c.actor:GetPos(),HitNormal=Vector(-1,0,0),Entity=c.data.bdd and c.data.bdd.ent or c.actor} end
  B:ServiceObjects(c,F.clock+.1,.1);util.TraceHull=F.clearTrace
  check(c.data.hits==i and r.consumed,'production trace did not consume one successful Cleaner')
  c.def:ImpactCleaner(c,r,r.generation,projectile,{Entity=c.actor});check(c.data.hits==i,'duplicate trace duplicated Cleaner hit')
  if i==1 then
   for _,p in ipairs(F.players) do p.alive=false end;F.step(.2);check(c.data.hits==1 and s.Boss==c,'no Hero reset BDD progress')
   F.p.alive=true;F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1;F.step(1.2);check(c.data.hits==1,'rejoin reset BDD progress')
  end
 end
 check(c.phase==3 and c.data.hits==3 and c.actor.nw.LOD_BDDActive==false,'exact third Cleaner did not break BDD')
 c.actor:TakeDamageInfo(F.info(F.p,100000,DMG_BULLET));F.flush();F.step((c.def.deathDuration or 0)+.1)
 check(c.dead and c.receipt and IsValid(s.JailKeyEntity),'exposed Joilette failed native defeat/key')
end)
test('Button ordinary immunity atomic use native death postdefeat key',function()
 local s,c=F.setup(10);local hp=c.actor:Health()
 for _,kind in ipairs({DMG_BULLET,DMG_BLAST,DMG_ENERGYBEAM,DMG_BURN,DMG_POISON}) do c.actor:TakeDamageInfo(F.info(F.p,100000,kind));check(c.actor:Health()==hp and not c.dead,'ordinary damage bypassed Button E gate') end
 check(B:UseDamage(c,10,F.p,'test_button_receipt'),'authorized E native packet rejected');local after=c.actor:Health();check(after<hp,'E damage did not use actual health')
 check(not B:UseDamage(c,10,F.p,'test_button_receipt') and c.actor:Health()==after,'same E receipt applied twice')
 check(B:UseDamage(c,c.actor:Health(),F.p,'test_button_final'),'final authorized E native packet rejected');F.flush()
 check(c.dead and c.receipt and not c.keyReady and not s.JailKeyEntity,'Button death bypassed required Jail Key button')
 F.step(.1);local keyButton=c.data.keyButton;check(keyButton and not keyButton.retired,'postdefeat Jail Key button missing')
 F.p:SetPos(keyButton.pos+Vector(-40,0,0));F.lookAt(F.p,keyButton.pos);hook.Run('KeyPress',F.p,IN_USE);check(c.keyReady and not s.JailKeyEntity,'early postdefeat E bypassed deathDuration')
 F.at(c.keyAt-.001,true);check(not s.JailKeyEntity,'Button key released before deathDuration');F.at(c.keyAt,true);check(IsValid(s.JailKeyEntity),'postdefeat E did not release key at deathDuration')
 local key=s.JailKeyEntity;hook.Run('KeyPress',F.p,IN_USE);B:EnsureKey(c);check(s.JailKeyEntity==key,'duplicate key button use granted new key')
end)
test('shared ninety six actor ceiling retained add queue and retry',function()
 local s,c=F.setup(15);local D=LOD.EncounterDirector;local base=D:GetActiveCount()
 for i=base+1,LOD.Config.Encounter.ActiveHostileCeiling do D.Entities[#D.Entities+1]=F.actor('lod_hostile') end
 local before=#F.created;check(not B:SpawnActor(c,'runner','integration_add',B:Center(c),{manual=false}) and #F.created==before,'shared actor cap allowed new native creation')
 check(B:QueueAdd(c,'runner','integration_add',B:Center(c),{manual=false}),'bounded add queue refused first retry');F.step(.1);check(#c.addQueue==1,'ceiling discarded queued spawn')
 local filler=D.Entities[#D.Entities];filler:Remove();F.step(.1);check(#c.addQueue==0 and B:CountActors(c,'integration_add')==1,'freeing native slot failed bounded queue retry queue='..#c.addQueue..' actors='..B:CountActors(c,'integration_add')..' '..F.errors())
 local countBefore=B:CountActors(c);for i=1,100 do B:SpawnActor(c,'runner','integration_add',B:Center(c),{manual=false}) end
 check(B:CountActors(c)<=1+(c.def.maxAdds or 8) and D:GetActiveCount()<=LOD.Config.Encounter.ActiveHostileCeiling,'owned/global ceiling escaped')
end)
test('defeat callback timeout precedence and exactly one recoverable retained key',function()
 local s,c=F.setup(2);F.kill(c.actor);s.Failed=true;F.flush();F.at(F.clock+5,true)
 check(not s.JailKeyEntity and c.retired,'failure lost precedence to pending boss-death key')
 s,c=F.setup(2);F.kill(c.actor);F.flush();F.step((c.def.deathDuration or 0)+.1)
 local first=assert(s.JailKeyEntity);first:Remove();F.step(.1);local replacement=s.JailKeyEntity
 check(IsValid(replacement) and replacement~=first and replacement.LODBossKeyReceipt==c.receipt,'lost key did not recover exact receipt')
 for _,p in ipairs(F.players) do p.alive=false;p.ps.lives=0;p.ps.eliminated=true end
 F.step(2);check(s.Boss==c and s.JailKeyEntity==replacement and not s.Failed,'no Hero destroyed pending mandatory key')
 F.p.alive=true;F.p.ps.lives=1;F.p.ps.eliminated=false;F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1;F.p:SetPos(replacement:GetPos())
 check(P:CollectJailKey(F.p,replacement) and not P:CanRescueTarget(),'fresh Hero could not recover key or skipped jail')
 check(P:TryOpenJailDoor(F.p,s.Graph.Progression.JailEdge.entity),'fresh Hero jail unlock failed')
 check(P:OnRescueTargetTouched(F.p,s.RescueEntity) and s.LevelCleared,'existing rescue interaction failed final completion')
end)
test('frozen packet source after roll cannot cross native damage boundary',function()
 local s,c=F.setup(2);local source=c.actor;local hp=F.p:Health();local native=F.p.TakeDamageInfo
 F.p.TakeDamageInfo=function(self,info) s.SimulationFrozen=true;return native(self,info) end
 local ok,err=pcall(B.Damage,B,c,F.p,{damage=50,dice={1,2,10}},source);F.p.TakeDamageInfo=native
 check(ok,err);check(F.p:Health()==hp,'source frozen after roll still delivered native packet')
 s.SimulationFrozen=false
end)
test('real KeyPress discovery front range cover hold and old-life rejection',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local uses=0;local pos=F.p:GetPos()+Vector(60,0,0)
 local o=assert(B:Object(c,{kind='input_fixture',pos=pos,use=true,hp=0,life=10,onUse=function() uses=uses+1 end}))
 F.p.aim=Vector(-1,0,0);hook.Run('KeyPress',F.p,IN_USE);check(uses==0,'use discovery reached behind Hero')
 F.lookAt(F.p,pos);util.TraceLine=function(t) return {Hit=true,StartSolid=false,Entity=NULL,HitPos=t.endpos} end
 hook.Run('KeyPress',F.p,IN_USE);check(uses==0,'use discovery crossed cover')
 util.TraceLine=F.clearTrace;hook.Run('KeyPress',F.p,IN_USE);check(uses==1,'nonsolid object not reachable through actual E key')
 hook.Run('KeyPress',F.p,IN_USE);check(uses==1,'duplicate same-frame E activated twice')
 B:RemoveObject(c,o,'test_complete');local h=assert(B:Object(c,{kind='input_hold',pos=pos,use=true,hp=0,hold=.5,life=10,onUse=function() uses=uses+1 end}))
 F.p.keys[IN_USE]=true;hook.Run('KeyPress',F.p,IN_USE);check(h.holding and uses==1,'E hold should arm without immediate action')
 F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1;F.clock=F.clock+.6;B:ServiceObjects(c,F.clock,.1);check(uses==1 and not h.holding,'old-life E hold completed on replacement body')
 hook.Run('KeyPress',F.p,IN_USE);F.clock=F.clock+.6;B:ServiceObjects(c,F.clock,.1);check(uses==2,'fresh-life E hold failed')
end)
for _,hazard in ipairs({'projectile','zone'}) do
 for _,mutation in ipairs({'target_spawn','target_profile','source_profile','source_life','source_removed'}) do
  test(hazard..' pending '..mutation..' cannot damage new life',function()
   local s,c=F.setup(2);B:Clear(c);quiet(c);local source=c.actor;F.p:SetPos(B:Center(c)+Vector(100,0,0))
   local spec={kind='life_fixture',pos=F.p:GetPos(),life=5,damage={damage=15,dice={1,2,10}}}
   local work
   if hazard=='projectile' then spec.velocity=Vector(300,0,0);work=assert(B:Projectile(c,spec)) else spec.delay=.5;spec.radius=100;work=assert(B:Zone(c,spec)) end
   local oldProfile=source.LODProgressionState
   if mutation=='target_spawn' then F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1
   elseif mutation=='target_profile' then F.p.ps.progressionState=table.Copy(F.p.ps.progressionState)
   elseif mutation=='source_profile' then source.LODProgressionState=table.Copy(oldProfile)
   elseif mutation=='source_life' then LOD.RPGStatusElements:ResetActorLife(source)
   elseif mutation=='source_removed' then source:Remove() end
   local hp=F.p:Health();F.clock=F.clock+1
   if hazard=='projectile' then util.TraceHull=function(t) return {Hit=true,HitPos=F.p:GetPos(),HitNormal=Vector(-1,0,0),Entity=F.p} end;B:ServiceObjects(c,F.clock,.1)
   else B:ServiceZones(c,F.clock) end
   util.TraceHull=F.clearTrace;check(F.p:Health()==hp,'pending '..hazard..' rebound to '..mutation)
  end)
 end
end
test('failed native primary creation retries without duplicated Melf kits',function()
 for _,failure in ipairs({'allocation','spawn'}) do
  local s=F.setup(4,false);check(B:Prepare(),'prepare before injected failure');local c=s.Boss
  if failure=='allocation' then F.failClass='lod_hostile' else F.failHostileSpawn=true end
  local ok=B:Commit(c);F.failClass=nil;F.failHostileSpawn=nil
  check(not ok and not c.started and not s.WardenStarted and not c.receipt,'failed '..failure..' committed encounter')
  check(B:Commit(c),'native retry failed '..failure)
  check(#c.heroes==2 and #c.data.kits==2 and #c.data.bodies==2,'failed '..failure..' duplicated frozen Hero roster/kits: heroes='..#c.heroes..' kits='..#c.data.kits)
  check(B:CountActors(c)==2,'failed primary remained alive alongside retried Melf')
 end
end)
test('Flightmeister native spawn lifts negative hull clear of supported floor',function()
 local s=F.setup(16,false);check(B:Prepare(),'air prepare');local c=s.Boss;local floor=B:Center(c).z-2;local negativeChecks=0
 util.TraceHull=function(t)
  if t.mins and t.mins.z<0 then
   negativeChecks=negativeChecks+1
   if t.start.z+t.mins.z<floor then return {Hit=true,StartSolid=true,AllSolid=true,HitPos=t.start,Entity=NULL} end
  end
  return F.clearTrace(t)
 end
 check(B:Commit(c),'air actor started hull-inside-floor');local actor=c.actor;local lo,hi=B:Hull(actor)
 check(negativeChecks>0 and lo.z<0 and actor:GetPos().z+lo.z>floor,'spawn did not validate lifted actual negative-z gunship hull')
 local pos=actor:GetPos();LOD.HostileMotionV2:SnapSpawn(actor);check(actor:GetPos():DistToSqr(pos)<.001,'canonical SnapSpawn snapped airborne boss back to floor')
 check(actor.collisionMins.z==lo.z and actor.collisionMaxs.z==hi.z,'native collision hull diverged from motion hull')
 util.TraceHull=F.clearTrace
end)
test('persistent solid cover blocks actual ground MotionV2 before SetPos',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local actor=c.actor;local start=B:Center(c);actor:SetPos(start)
 local cover=assert(B:Object(c,{kind='integration_cover',pos=start+Vector(80,0,0),solid=true,hp=0,permanent=true,radius=20}))
 check(cover.ent.solid==SOLID_BBOX,'cover lacks native collision')
 local lo,hi=B:Hull(actor);local limit=cover.pos.x+cover.ent.collisionMins.x-hi.x;local traces,illegal=0,false;local nativeSet=actor.SetPos
 actor.SetPos=function(self,pos) if pos.x>limit+.001 then illegal=true end;return nativeSet(self,pos) end
 util.TraceHull=function(t)
  if t.filter and t.filter(cover.ent) and t.start.x<=limit and t.endpos.x>limit then
   traces=traces+1;return {Hit=true,StartSolid=false,AllSolid=false,HitPos=Vector(limit,t.endpos.y,t.endpos.z),Entity=cover.ent,HitNormal=Vector(-1,0,0)}
  end
  return F.clearTrace(t)
 end
 check(B:Move(c,actor,start+Vector(200,0,0),160,{mode='ground'} )~=nil,'ground move admission')
 for i=1,12 do F.clock=F.clock+.1;B:ServiceMoves(c,F.clock,.1) end
 actor.SetPos=nativeSet;util.TraceHull=F.clearTrace
 check(traces>0 and not illegal and actor:GetPos().x<=limit+.001 and actor.LODBossMotionBlocked,'ground authority SetPos crossed persistent cover')
end)
test('delayed callbacks cannot fallback to a replacement target life',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local old=B:BindTarget(c,F.p);local callbacks,admitted=0,0;local hp=F.p:Health()
 B:Later(c,.5,'integration_old_target',function(owner)
  callbacks=callbacks+1
  if B:TargetLive(owner,old) then admitted=admitted+1 end
  local fallback=B:Targets(owner)[1]
  if fallback then B:Damage(owner,fallback,{damage=50,dice={1,2,10}}) end
 end)
 F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1;F.step(.6)
 check(callbacks==1 and admitted==0 and F.p:Health()==hp,'old callback reacquired replacement Hero via fresh Targets')
 local hits=0;local projectile=assert(B:Projectile(c,{kind='callback_life',pos=F.p:GetPos(),velocity=Vector(100,0,0),life=5,onHit=function() hits=hits+1 end}))
 F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1
 util.TraceHull=function(t) return {Hit=true,HitPos=F.p:GetPos(),HitNormal=Vector(-1,0,0),Entity=F.p} end
 B:ServiceObjects(c,F.clock+.1,.1);util.TraceHull=F.clearTrace;check(hits==0,'stale projectile invoked onHit against new Hero life')
 local delivered=0;local z=assert(B:Zone(c,{kind='callback_zone',pos=F.p:GetPos(),delay=.5,life=3,radius=30,onTick=function(_,_,targets) for _,p in ipairs(targets) do if p==F.p then delivered=delivered+1 end end end}))
 F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1;B:ServiceZones(c,F.clock+1);check(delivered==0,'stale zone delivered replacement Hero to onTick callback')
end)
for _,condition in ipairs({'muted','intimidated','hitstun'}) do
 test(condition..' blocks new admissions without changing committed ordnance deadline',function()
  local s,c=F.setup(condition=='intimidated' and 15 or 2);B:Clear(c);quiet(c);local Status=LOD.RPGStatusElements;local source=c.actor
  if condition=='intimidated' then check(Status:IsImmune(source,'intimidated'),'canonical boss morale immunity changed');source=assert(B:SpawnActor(c,'runner','status_subject',B:Point(c,2),{manual=true})) end
  local expired,ticked=0,0;local magical={kind='arc',content='raw',damage=12,dice={1,2,10}}
  local projectile=assert(B:Projectile(c,{kind='status_deadline',source=source,pos=F.p:GetPos(),velocity=Vector(),fuse=1,life=4,damage=magical,onExpire=function() expired=expired+1 end}))
  local zone=assert(B:Zone(c,{kind='status_deadline',source=source,pos=F.p:GetPos(),radius=50,delay=1,life=3,damage=magical,onTick=function() ticked=ticked+1 end}))
  local fuse,ready=projectile.fuse,zone.ready
  if condition=='hitstun' then source.LODHitStunUntil=F.clock+3 else local ok,why=Status:Apply(source,condition,F.p,{direct=true,duration=3});check(ok,'canonical status application failed '..tostring(why)) end
  local countBefore=#F.created
  check(not B:Projectile(c,{source=source,pos=B:Center(c),velocity=Vector(100,0,0),damage=magical}),'new projectile admitted during '..condition)
  check(not B:Zone(c,{source=source,pos=B:Center(c),life=2,damage=magical}),'new zone admitted during '..condition)
  check(not B:Charge(c,source,B:Center(c)+Vector(300,0,0),{warning=.5,damage=magical}),'new charge admitted during '..condition)
  check(#F.created==countBefore,'denied attack allocated native object')
  if condition=='muted' then
   local physical=B:Projectile(c,{pos=B:Center(c),velocity=Vector(100,0,0),damage={kind='bullet',damage=2}})
   check(physical~=nil,'Muted incorrectly disabled physical projectile');B:RemoveObject(c,physical,'test')
  end
  F.clock=fuse-.01;B:ServiceObjects(c,F.clock,.1);B:ServiceZones(c,F.clock);check(expired==0 and ticked==0,'committed ordnance released early')
  F.clock=fuse;B:ServiceObjects(c,F.clock,.1);B:ServiceZones(c,F.clock)
  check(expired==1 and ticked==1 and projectile.retired and projectile.fuse==fuse and zone.ready==ready,'status suspended or shifted already committed ordnance deadline')
 end)
end
test('held charge retires commitment and never teleports on recovery',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local source=c.actor;local start=source:GetPos();local finished,cancelled=0,0
 check(B:Charge(c,source,start+Vector(600,0,0),{warning=.5,speed=300,damage={damage=10},onFinish=function(_,hit,pos,tr) if tr and tr.cancelled then cancelled=cancelled+1;check(not hit and pos:DistToSqr(start)<.001,'cancelled charge fabricated impact') else finished=finished+1 end end}),'initial charge rejected')
 check(LOD.RPGStatusElements:Apply(source,'held',F.p,{direct=true,duration=1}),'canonical Held application failed')
 F.clock=F.clock+.7;B:ServiceMoves(c,F.clock,.1);check(not c.moves[source] and source:GetPos():DistToSqr(start)<.001,'Held retained pending charge or moved body')
 LOD.RPGStatusElements:Clear(source,'held','integration release');F.clock=F.clock+4;B:ServiceMoves(c,F.clock,.1)
 check(source:GetPos():DistToSqr(start)<.001 and finished==0 and cancelled==1,'held charge failed exactly-one cancellation or teleported/impacted on recovery')
end)
test('Mooky sky arena remains grounded with actual native body hull',function()
 local s,c=F.setup(19);local floor=B:Center(c).z
 check(c.def.arena.sky==true,'Mooky test no longer covers generic sky flag')
 check(not c.actor.LODBossAirborne and math.abs(c.actor:GetPos().z-floor)<.01,'generic sky arena floated grounded Strider')
 local lo,hi=B:Hull(c.actor);check(c.actor.collisionMins==lo and c.actor.collisionMaxs==hi,'Mooky native body hull not installed')
end)
test('route clearance rejects offset choke and unreachable button while admitting safe center bomb',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local center=B:Center(c)
 F.p:SetPos(B:Point(c,1));F.q:SetPos(B:Point(c,3))
 check(B:ValidateRoutes(c,{center},175),'legal center bomb lost all baseline routes')
 check(c.def:PlaceBomb(c,'black',center)~=nil,'center bomb with valid escape routes rejected')
 B:Clear(c);local entry=c.arena.entry;local first={x=entry.x+1,y=entry.y,z=entry.z}
 local offset=N:CellCenter(first)+Vector(-184,0,2)
 check(not B:ValidateRoutes(c,{offset},130),'offset barricade closed every entry lane but passed route proof')
 local s2,b=F.setup(10);check(b.def:Pedestals(b),'real mandatory button pedestal plan unavailable');local pedestal=b.data.pedestals[1]
 check(not B:ValidateRoutes(b,{pedestal+Vector(90,0,0)},100),'inaccessible mandatory button pedestal was admitted')
end)
test('lost Melf primary and support recover exact records HP kits and native succession',function()
 local s,c=F.setup(4);F.step(.1);local kits=c.data.kits;local primary=c.actor;local primaryRecord=c.data.byActor[primary]
 primary:SetHealth(math.floor(primary:GetMaxHealth()*.43));F.step(.1);local hp=primary:Health();local serial=c.serial;primary:Remove();F.step(.2)
 local replacement=c.actor
 check(IsValid(replacement) and replacement~=primary and replacement:Health()==hp and c.data.byActor[replacement]==primaryRecord and c.data.byActor[primary]==nil,'primary loss failed exact native record/HP recovery')
 check(replacement.LODMirrorKit==primaryRecord.kit and c.data.kits==kits and #c.data.kits==2 and not c.receipt,'primary recovery rerolled kit or granted receipt')
 local support;for _,m in ipairs(c.data.bodies) do if m~=primaryRecord then support=m end end
 local old=support.actor;old:SetHealth(math.floor(old:GetMaxHealth()*.37));F.step(.1);local supportHP=old:Health();old:Remove();F.step(.2)
 check(IsValid(support.actor) and support.actor~=old and support.actor:Health()==supportHP and c.data.byActor[support.actor]==support and c.data.byActor[old]==nil,'lost support failed identity/HP-safe recovery')
 check(c.serial==serial and c.phase==1 and #c.data.bodies==2,'nonlethal body loss advanced or duplicated Melf encounter')
 F.kill(replacement);F.step(.1);check(not c.dead,'recovered primary death bypassed remaining mirror')
 F.kill(support.actor);F.step(2.1);check(c.phase==2 and c.data.stage==2 and #c.data.bodies==2,'recovered bodies could not progress through native succession')
end)
test('Start error atomically restores open gate objective and checkpoint',function()
 local s,_,g,a=F.setup(2,false);local checkpoint=Vector(12,34,56);s.ObjectiveStage=P.Stages.ENTER_WARDEN;s.CheckpointPos=checkpoint;s.WardenStarted=false;a.lock.entity:OpenGate()
 check(B:Prepare(),'prepare before Start failure');local c=s.Boss;F.failNWKey='LOD_BossAction';local committed=B:Commit(c);F.failNWKey=nil
 check(not committed and c.retired and not s.Boss and not IsValid(c.actor),'failed production Start left native primary alive')
 check(a.lock.entity.opened==true and not s.WardenStarted and s.ObjectiveStage==P.Stages.ENTER_WARDEN and s.CheckpointPos==checkpoint,'Start rollback changed gate objective or checkpoint')
 check(B:Prepare() and B:Commit(s.Boss) and #s.Boss.heroes==2,'fresh retry after Start rollback failed or duplicated roster')
end)
test('harmless death object obeys velocity gravity expiry and cannot damage',function()
 local s,c=F.setup(2);F.kill(c.actor);F.flush();local start=B:Center(c)+Vector(0,0,80);local hp=F.p:Health()
 local o=assert(B:Object(c,{kind='death_physics',cosmetic=true,pos=start,velocity=Vector(120,0,80),gravity=400,life=.5,hp=100,solid=true,use=true,damage={damage=200}}))
 check(o.spec.damage==nil and o.health==0 and not o.spec.solid and not o.spec.use,'cosmetic death object retained hostile interaction')
 F.clock=F.clock+.1;B:ServiceObjects(c,F.clock,.1)
 check(o.pos.x>start.x and o.velocity.z<80 and math.abs(o.pos.z-(start.z+4))<.01,'postdeath Object velocity or gravity did not advance')
 check(F.p:Health()==hp,'cosmetic death object damaged Hero');F.clock=F.clock+1;B:ServiceObjects(c,F.clock,.1);check(o.retired and not IsValid(o.ent),'cosmetic physics escaped finite lifetime')
end)
test('canonical Pushback moves eligible objects respects states and body pushScale',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local Push=LOD.Pushback
 for _,state in ipairs({'stable','leaking','critical','CRITICAL','ignited'}) do
  local o=assert(B:Object(c,{kind='push_object',pos=B:Center(c),hp=20,pushable=true,mass=12,state=state,life=10}))
  local from=o.ent:GetPos();local result=Push:Apply(o.ent,{attacker=F.p,origin=F.p:GetPos(),direction=Vector(1,0,0),distance=120,pushSaveNatural=1,source='integration'})
  if state=='stable' or state=='leaking' then
   check(result and result.moved>0 and o.ent:GetPos().x>from.x and o.pos:DistToSqr(o.ent:GetPos())<.001 and o.velocity.x>0,'canonical Push failed eligible '..state..' object')
   local pushed=o.pos.x;B:ServiceObjects(c,F.clock+.1,.1);check(o.pos.x>pushed,'shared Push impulse was overwritten by object service')
  else check((not result or result.moved==0) and o.pos:DistToSqr(from)<.001 and o.velocity:LengthSqr()==0,'critical/ignited object allowed unsafe punt: '..state) end
  B:RemoveObject(c,o,'test')
 end
 local s2,conan=F.setup(17);local from=conan.actor:GetPos();local result=Push:Apply(conan.actor,{attacker=F.p,direction=Vector(1,0,0),distance=120,pushSaveNatural=1})
 check(result and math.abs(result.authored-120*conan.def.pushScale)<.001,'canonical body Push ignored authored fractional scale')
 check(conan.actor:GetPos():Distance(from)<=120*conan.def.pushScale+.01,'scaled boss body moved beyond authored displacement')
 local s3,felon=F.setup(3);from=felon.actor:GetPos();result=Push:Apply(felon.actor,{attacker=F.p,direction=Vector(1,0,0),distance=120,pushSaveNatural=1})
 check(result and result.moved==0 and felon.actor:GetPos():DistToSqr(from)<.001,'Push immune Felon body moved')
end)
test('authored graph path is executed exactly instead of shortest-path substitution',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local cell=c.arena.center;local start=B:Center(c);c.actor:SetPos(start)
 local path={N:CellCenter({x=cell.x,y=cell.y+1,z=cell.z})+Vector(0,0,2),N:CellCenter({x=cell.x+1,y=cell.y+1,z=cell.z})+Vector(0,0,2),N:CellCenter({x=cell.x+1,y=cell.y,z=cell.z})+Vector(0,0,2)}
 local dest=path[3];B:Move(c,c.actor,dest,180,{mode='ground',path=path,stopDistance=20});local m=c.moves[c.actor]
 check(m and m.authored and #m.waypoints==3,'explicit author path not retained')
 for i,p in ipairs(path) do check(m.waypoints[i].pos:DistToSqr(p)<.001,'authored waypoint changed at '..i) end
 local visited=1
 for i=1,220 do F.clock=F.clock+.1;B:ServiceMoves(c,F.clock,.1);if visited<=3 and c.actor:GetPos():DistToSqr(path[visited])<30^2 then visited=visited+1 end end
 check(visited==4 and c.actor:GetPos():DistToSqr(dest)<30^2 and not c.moves[c.actor],'ground MotionV2 skipped an authored graph waypoint')
 local before=c.actor:GetPos();local _,blocked=B:Move(c,c.actor,start,180,{mode='ground',path={start+Vector(100000,0,0)}})
 check(blocked and not c.moves[c.actor] and c.actor:GetPos():DistToSqr(before)<.001,'invalid authored path moved actor outside court')
end)
test('moving cone formation cannot close offset entry route through Push or object service',function()
 local s,c=F.setup(17);B:Clear(c);quiet(c);local entry=c.arena.entry;local first=N:CellCenter({x=entry.x+1,y=entry.y,z=entry.z})+Vector(0,0,2)
 local function cone(pos) return assert(B:Object(c,{kind='conan_mini',model='models/props_junk/TrafficCone001a.mdl',pos=pos,hp=22,solid=true,pushable=true,radius=19,life=30})) end
 local a=cone(first+Vector(-184,-96,0));local b=cone(first+Vector(-184,96,0));local moving=cone(first+Vector(80,0,0));local from=moving.pos;local sealed=first+Vector(-184,0,0)
 check(not B:ObjectPositionAllowed(moving,sealed),'closed three-cone offset formation passed route admission')
 local result=LOD.Pushback:Apply(moving.ent,{attacker=F.p,direction=Vector(-1,0,0),distance=264,pushSaveNatural=1,ignoreResistance=true})
 check(not result and moving.ent:GetPos():DistToSqr(from)<.001 and moving.pos:DistToSqr(from)<.001,'canonical Push moved cone before route refusal')
 moving.velocity=Vector(-1300,0,0);B:ServiceObjects(c,F.clock+.1,.1);local safe=moving.pos
 B:ServiceObjects(c,F.clock+.2,.1)
 check(not moving.retired and moving.spec.solid and moving.pos:DistToSqr(safe)<.001 and moving.velocity:LengthSqr()==0,'kinematic solid moved through route-denied offset formation')
 check(B:ValidateRoutes(c,{},19),'refused moving cone left final court disconnected')
end)
for _,origin in ipairs({'later','onHit','onTick'}) do
 test(origin..' nested work inherits stale target scope',function()
  local s,c=F.setup(2);B:Clear(c);quiet(c);local pos=B:Center(c);F.p:SetPos(pos);F.q:SetPos(pos+Vector(20,0,0));local made,outer,callbacks={},0,0
  local function spawnNested(owner)
   outer=outer+1
   made.projectile=B:Projectile(owner,{kind='nested_scope',pos=F.p:GetPos(),velocity=Vector(100,0,0),life=3,damage={damage=40,dice={1,2,10}},onHit=function() callbacks=callbacks+1 end})
   made.zone=B:Zone(owner,{kind='nested_scope',pos=F.p:GetPos(),delay=.1,radius=10,life=1,damage={damage=40,dice={1,2,10}},onTick=function(_,_,targets) for _,p in ipairs(targets) do if p==F.p then callbacks=callbacks+1 end end end})
   B:Push(owner,F.p,Vector(1,0,0),100)
   made.constraint=B:Constrain(owner,B:BindTarget(owner,F.p),{key='nested_life',seconds=1,center=F.p:GetPos(),radius=30})
  end
  local work
  if origin=='later' then B:Later(c,.1,'outer_scope',spawnNested)
  elseif origin=='onHit' then work=assert(B:Projectile(c,{kind='outer_scope',pos=F.q:GetPos(),velocity=Vector(100,0,0),life=3,onHit=function(owner) spawnNested(owner) end}))
  else work=assert(B:Zone(c,{kind='outer_scope',pos=pos,radius=40,delay=.1,life=2,onTick=function(owner) spawnNested(owner) end})) end
  F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1;local hp=F.p:Health();local ppos=F.p:GetPos();F.clock=F.clock+.2
  if origin=='later' then B:Service(F.clock)
  elseif origin=='onHit' then util.TraceHull=function(t) return {Hit=true,HitPos=F.q:GetPos(),HitNormal=Vector(-1,0,0),Entity=F.q} end;B:ServiceObjects(c,F.clock,.1)
  else B:ServiceZones(c,F.clock);B:Clear(c,'outer_scope') end
  check(outer==1 and made.projectile and made.zone,'outer callback did not create both nested production work items')
  util.TraceHull=function(t) return {Hit=true,HitPos=F.p:GetPos(),HitNormal=Vector(-1,0,0),Entity=F.p} end
  F.clock=F.clock+.3;B:ServiceObjects(c,F.clock,.1);B:ServiceZones(c,F.clock);util.TraceHull=F.clearTrace
  check(F.p:Health()==hp and F.p:GetPos():DistToSqr(ppos)<.001 and callbacks==0 and not made.constraint,'nested '..origin..' work recaptured respawned target or applied callback/Push side effect')
  check(not c.activeBindings and not c.activeSourceBinding,'callback scope leaked into subsequent fresh attacks')
 end)
end
test('nested delayed callback cannot renew stale source incarnation',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local source=c.actor;local outer,inner=0,0;local made={}
 B:Later(c,.1,'source_outer',function(owner)
  outer=outer+1;B:Later(owner,.1,'source_inner',function(nested)
   inner=inner+1
   made.projectile=B:Projectile(nested,{pos=B:Center(nested),velocity=Vector(100,0,0),damage={damage=10}})
   made.zone=B:Zone(nested,{pos=B:Center(nested),life=1,damage={damage=10}})
  end)
 end)
 source.LODProgressionState=table.Copy(source.LODProgressionState);F.step(.4)
 check(outer==1 and inner==1 and not made.projectile and not made.zone,'nested Later re-bound retired source profile')
 check(not c.activeSourceBinding and not c.activeBindings,'nested source lease contaminated fresh work')
end)
test('charge finish spawned zone keeps pre-respawn target lease',function()
 local s,c=F.setup(2);B:Clear(c);quiet(c);local start=B:Center(c);c.actor:SetPos(start);F.p:SetPos(start+Vector(150,0,0));local child,finished;local hp=F.p:Health();local callbacks=0
 check(B:Charge(c,c.actor,start+Vector(300,0,0),{warning=.3,speed=300,onFinish=function(owner,hit,pos,tr)
  finished=true;child=B:Zone(owner,{kind='charge_child',pos=F.p:GetPos(),radius=50,delay=.1,life=1,damage={damage=30},onTick=function(_,_,targets) for _,p in ipairs(targets) do if p==F.p then callbacks=callbacks+1 end end end})
 end}),'charge admission')
 F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1;F.clock=F.clock+1.4;B:ServiceMoves(c,F.clock,.1);check(finished and child,'charge finish child zone missing')
 F.clock=F.clock+.2;B:ServiceZones(c,F.clock);check(F.p:Health()==hp and callbacks==0,'charge finish child zone reacquired replacement Hero')
end)
test('cancellation callbacks clear flags without new attack spawn healing damage or Push',function()
 local s,c=F.setup(15);B:Clear(c);quiet(c);local actor=c.actor;actor:SetHealth(actor:GetMaxHealth()-100);local ahp=actor:Health();local hp=F.p:Health();local pos=F.p:GetPos();local before=#F.created;local calls=0;local result={};c.data.integrationCharging=true
 check(B:Charge(c,actor,actor:GetPos()+Vector(300,0,0),{warning=1,onFinish=function(owner,hit,where,tr)
  calls=calls+1;check(tr and tr.cancelled and not hit,'cancellation reported legitimate collision');owner.data.integrationCharging=false
  result.damage=B:Damage(owner,F.p,{damage=40});result.heal=B:Heal(owner,50);result.selfDamage=B:SelfDamage(owner,50,'cancel')
  result.push=B:Push(owner,F.p,Vector(1,0,0),100);result.spawn=B:SpawnActor(owner,'runner','cancel_add',B:Center(owner),{manual=true})
  result.projectile=B:Projectile(owner,{pos=B:Center(owner),velocity=Vector(100,0,0)});result.zone=B:Zone(owner,{pos=B:Center(owner),life=1})
  result.object=B:Object(owner,{pos=B:Center(owner),life=1});result.move=B:Move(owner,actor,B:Center(owner)+Vector(50,0,0),100);result.queue=B:QueueAdd(owner,'runner','cancel_queue',B:Center(owner),{manual=true});result.later=B:Later(owner,0,'cancel_work',function() error('cancelled callback scheduled work') end)
 end}),'initial cancellation test charge rejected')
 B:Stop(c,actor);B:Stop(c,actor)
 check(calls==1 and not c.data.integrationCharging and not c.cancelling,'cancel callback was duplicated or failed to clear state')
 check(result.damage==0 and result.heal==0 and result.selfDamage==0 and not result.push and not result.spawn and not result.projectile and not result.zone and not result.object and not result.move and not result.queue and not result.later and #c.addQueue==0,'cancel callback admitted gameplay work')
 check(#F.created==before and actor:Health()==ahp and F.p:Health()==hp and F.p:GetPos():DistToSqr(pos)<.001,'cancellation changed native actors health or position')
end)
for _,case in ipairs({{level=2,id='chonker',create=function(c,p) return c.def:PlaceBomb(c,'black',p) end,explode=function(c,o) c.def:Detonate(c,o) end},{level=7,id='daryl',create=function(c,p) return c.def:Barrel(c,p,'stationary',false) end,explode=function(c,o) c.def:Explode(c,o) end},{level=14,id='jane',create=function(c,p) return c.def:LooseCylinder(c,p,nil,'loose') end,explode=function(c,o) c.def:DetonateCylinder(c,o) end}}) do
 for _,mutation in ipairs({'current','target_respawn','source_profile'}) do
  test(case.id..' manual object detonation obeys original '..mutation..' lease',function()
   local s,c=F.setup(case.level);B:Clear(c);quiet(c);local center=B:Center(c);F.p:SetPos(center+Vector(300,0,0));F.q:SetPos(center+Vector(600,0,0))
   local o=assert(case.create(c,center),'production manual hazard admission failed');F.p:SetPos(o.pos+Vector(40,0,0))
   if mutation=='target_respawn' then F.p.LODRunSpawnSerial=F.p.LODRunSpawnSerial+1
   elseif mutation=='source_profile' then o.source.LODProgressionState=table.Copy(o.source.LODProgressionState) end
   local hp=F.p:Health();local pos=F.p:GetPos();case.explode(c,o)
   if mutation=='current' then check(F.p:Health()<hp,'manual detonation positive control produced no shared damage')
   else check(F.p:Health()==hp and F.p:GetPos():DistToSqr(pos)<.001,'manual '..case.id..' detonation rebound to '..mutation..' with damage or Push') end
   local after=F.p:Health();case.explode(c,o);check(F.p:Health()==after,'duplicate manual detonation replayed damage')
  end)
 end
end
test('production Gordon level one composition and level twenty Hector handoff',function()
 dofile(F.root..'sv_entry_safety.lua')
 local W,H=LOD.Warden,LOD.Hector
 for _,level in ipairs({1,20}) do
  local s,_,g,a=F.setup(level,false)
  for _,p in ipairs(F.players) do p:SetPos(N:CellCenter(a.entry)) end
  util.TraceLine=function(t)
   if math.abs(t.start.x-t.endpos.x)<.01 and math.abs(t.start.y-t.endpos.y)<.01 and t.start.z>t.endpos.z and t.start.z-t.endpos.z<=12.1 then
    return {Hit=true,HitPos=t.start-Vector(0,0,6),HitNormal=Vector(0,0,1),Entity=NULL,StartSolid=false,AllSolid=false}
   end
   return F.clearTrace(t)
  end
  check(W:Prepare() and W:Commit(),'legacy Gordon prepare/commit rejected '..level);local w=s.Warden
  check(not s.Boss and w and w.actor.LODArchetypeId=='warden','replacement framework hijacked Gordon level '..level)
  check(#w.clones==(level==20 and 4 or 0),'actual clone composition wrong at level '..level)
  check(w.turrets and w.turrets.admitted==(level==20 and 4 or 0),'actual turret composition wrong at level '..level..' admitted='..tostring(w.turrets and w.turrets.admitted))
  for _,p in ipairs(F.players) do p:SetPos(N:CellCenter(a.center)+Vector(160,0,0)) end
  F.kill(w.actor);F.flush()
  if level==1 then check(IsValid(s.JailKeyEntity) and not s.Hector,'level one key flow unexpectedly changed')
  else
   check(s.Hector and not s.JailKeyEntity and not P:CanRescueTarget(),'real level twenty Gordon released key before Hector')
   local h=s.Hector;F.clock=F.clock+3.1;H:Step(F.clock);check(h.actor and h.stage==2,'native Hector handoff did not reveal live core')
   F.kill(h.actor);F.flush();F.clock=F.clock+.01;LOD.HostileDeathPresentation:_RunDue();check(IsValid(s.JailKeyEntity) and H:RescueAllowed(s),'legitimate Hector defeat did not authorize sole finale key')
  end
  util.TraceLine=F.clearTrace
 end
end)
test('Gordon twenty failed clone and turret allocations roll back complete group and retry',function()
 local W,H=LOD.Warden,LOD.Hector
 for _,failureAt in ipairs({3,8}) do
  local s,_,g,a=F.setup(20,false);for _,p in ipairs(F.players) do p:SetPos(N:CellCenter(a.entry)) end;a.lock.entity:OpenGate()
  util.TraceLine=function(t) if math.abs(t.start.x-t.endpos.x)<.01 and math.abs(t.start.y-t.endpos.y)<.01 and t.start.z>t.endpos.z and t.start.z-t.endpos.z<=12.1 then return {Hit=true,HitPos=t.start-Vector(0,0,6),HitNormal=Vector(0,0,1),Entity=NULL,StartSolid=false,AllSolid=false} end;return F.clearTrace(t) end
  check(W:Prepare(),'prepare before Gordon allocation failure');local w=s.Warden;local oldCreated=#F.created;F.hostileAttempts=0;F.failHostileAt=failureAt
  local committed=W:Commit();F.failHostileAt=nil
  check(not committed and not w.started and not s.WardenStarted and not w.actor and #w.clones==0 and not w.turrets,'incomplete Gordon composition was committed')
  check(not s.Hector and not s.JailKeyEntity and a.lock.entity.opened and s.ObjectiveStage==P.Stages.ENTER_WARDEN,'failed group granted key/handoff or locked arena')
  local stale;for i=oldCreated+1,#F.created do local e=F.created[i];if e.class=='lod_hostile' then stale=stale or e;check(not IsValid(e),'rolled-back hostile survived partial group') end end
  check(W:Commit() and #w.clones==4 and w.turrets.admitted==4 and LOD.EncounterDirector:GetActiveCount()==9,'retry did not create exact one plus four plus four composition')
  if stale then F.kill(stale);F.flush();check(not w.dead and not s.Hector and not s.JailKeyEntity,'stale rolled-back native death produced reward or handoff') end
  local core=w.actor;F.kill(core);F.flush();local h=s.Hector;check(h and not s.JailKeyEntity,'retry Gordon failed sole Hector handoff');W:Killed(core);F.flush();check(s.Hector==h and not s.JailKeyEntity,'duplicate retry death created extra handoff')
  H:Cleanup(h);util.TraceLine=F.clearTrace
 end
end)
print(string.format('BOSS_FRAMEWORK_SUMMARY passed=%d failed=%d',passed,#failed))
if #failed>0 then error('production integration failures: '..#failed..' (see BOSS_FRAMEWORK_FAIL above)') end
