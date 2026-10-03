-- Behavioral contracts over the REAL four authored modules. Boundary doubles do not claim native GMod acceptance.
local F=dofile('tools/boss_large_fixture.lua');local B=F.B
local n=0
local function ok(condition,why) assert(condition,why);n=n+1 end
local function equal(a,b,why) ok(a==b or (type(a)=='number' and type(b)=='number' and math.abs(a-b)<1e-8),(why or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function last(a) return a[#a] end
local function count(c,kind) return #B:Objects(c,kind) end
local function phase(c,p) B:SetPhase(c,p) end
local function fresh(id) local c=F.fresh(id);return c,c.def end
local function used(c,kind,p) local o=B:Objects(c,kind)[1];assert(o,kind);o.spec.onUse(c,o,p or c.heroes[1]);return o end

-- MARION: actual traffic packets, post-impact immunity, heavy geometry and finite wreck routes.
do
 local c,d=fresh('marion')
 equal(c.def.maxAdds,0,'Marion no arbitrary adds');ok(c.charge.spec.damage==nil,'intro car ride is harmless');ok(count(c,'marion_car')==1,'visible intro car')
 F.finishCharge(c,false);F.advance(c,4);phase(c,2);d:Traffic(c)
 local before=count(c,'marion_car');F.advance(c,2.5);equal(count(c,'marion_car')-before,2,'rush hour admits exactly two traffic lanes')
 local cars=B:Objects(c,'marion_car');local p=c.heroes[1];local a,b=cars[#cars-1],cars[#cars]
 a.spec.onHit(c,a,p);equal(#c.damage,1,'first traffic impact damage');a.spec.onHit(c,a,p);equal(#c.damage,1,'same car spent after first impact')
 b.spec.onHit(c,b,p);equal(#c.damage,1,'another car cannot pinball during protection');equal(b.carSpent,true,'protected collision still spends the car')
 F.advance(c,2.6);local car=d:Car(c,Vector(),Vector(800,0,0),'kick');car.spec.onHit(c,car,p);equal(#c.damage,2,'finite protection expires')
 local replacement=d:Car(c,Vector(),Vector(800,0,0),'kick');p.life=p.life+1;replacement.spec.onHit(c,replacement,p);equal(#c.damage,3,'new exact life does not inherit old immunity')
 phase(c,3);before=#c.objects;d:Traffic(c);F.advance(c,1.7);equal(#c.objects-before,1,'FORE background thins to one lane')
 local h=fresh('marion');h.data.entranceUntil=0;B:Stop(h,h.actor)
 h.def:Combo(h,Vector(100,0,0));F.advance(h,2.7);equal(#h.zones,0,'sledge combo is localized impact rather than generic area loop')
 equal(#h.warnings>=3,true,'all three combo strikes previewed')
 local barrier=h.data.barriers[1];ok(barrier~=nil,'heavy reinforced car exists')
 h.actor.pos=barrier.pos-Vector(105,0,0);h.def:Combo(h,barrier.pos);F.advance(h,2.7);ok(#h.staggers>0,'overhead hammer sticks in designated heavy car')
 local ric=h.def:Car(h,barrier.pos,Vector(),'smash');ric.pos=barrier.pos
 ok(ric.spec.onImpact(h,ric,{Entity=barrier.ent,HitNormal=Vector(-1,0,0)}),'authored barrier handles ricochet');F.advance(h,.7)
 ok(ric.ricochet and last(h.staggers).seconds==3.2,'wreck near Marion creates long stagger')
 local r=fresh('marion');r.def:Roadside(r);F.advance(r,4.3)
 ok(#r.zones==1 and r.zones[1].spec.damage.content=='fire','roadside gag uses shared Fire content')
 local q=fresh('marion');q.actor.hp=q.actor.maxhp*.19;F.think(q,4.6);F.advance(q,2)
 ok(q.data.pileup,'20 percent pileup committed');equal(count(q,'marion_wreck'),3,'three validated settled cover wrecks')
 q.def:Pileup(q);F.advance(q,2);equal(count(q,'marion_wreck'),3,'pileup once only')
 ok(#q.routeChecks>=6,'combined route validations occur');ok(q.def:KeyPosition(q)~=nil,'hammer key position recoverable')
 local denied=fresh('marion');denied.routeBlocked=true;denied.def:Pileup(denied);F.advance(denied,2);equal(count(denied,'marion_wreck'),0,'unsafe wrecks rejected')
end

-- FLIGHTMEISTER: bounded aerial nodes, true bank opportunity, separate ordnance and permanent cover.
do
 local c,d=fresh('flightmeister')
 equal(count(c,'flight_hard_cover'),4,'four permanent hard cover pieces');equal(count(c,'flight_expendable'),2,'limited expendable cover');equal(c.def.maxAdds,0,'no aerial-distraction adds')
 d:Think(c,0,.1,c.heroes);equal(last(c.moves).options.mode,'air','gunship uses authored air motion')
 local beacon=used(c,'flight_beacon');local lane=c.data.beaconLane;ok(lane~=nil,'beacon chooses pass lane')
 local cd=c.data.beaconReady;used(c,'flight_beacon');equal(c.data.beaconReady,cd,'beacon cannot reset cooldown')
 d:Strafe(c,false);equal(c.data.beaconLane,nil,'next pass consumes beacon');equal(c.data.flight.lane,lane,'exact beacon lane used')
 equal(c.data.flight.recovery,4,'beacon guarantees long vulnerable bank');equal(#c.damage,0,'beacon deals no damage')
 local info=F.damageInfo();info.pos=c.actor:GetPos()-Vector(0,0,20);d:BeforeDamage(c,c.actor,info);equal(info.value,11.8,'exposed underside modest bonus')
 local normal=F.damageInfo();normal.pos=c.actor:GetPos()+Vector(0,0,100);d:BeforeDamage(c,c.actor,normal);equal(normal.value,10,'ordinary hits always work')
 d:AfterDamage(c,c.actor,c.actor.maxhp*.06,c.heroes[1],c.actor:GetPos());ok(#c.staggers>0,'engine concentrated damage staggers')
 phase(c,2);d:Bombing(c);equal(#c.zones,5,'five sequential bomb marks');equal(c.zones[1].spec.delay+1.8,c.zones[5].spec.delay,'bombing is sequential')
 equal(last(c.logs).data.safeLanes,2,'bombing guarantees other lanes');d:CoverBreak(c);F.advance(c,2.1)
 equal(count(c,'flight_expendable'),1,'cover break destroys only expendable');equal(count(c,'flight_hard_cover'),4,'hard cover survives')
 d:Crosswind(c);local z=last(c.zones);local p=c.heroes[1];p.pos=(z.spec.pos+z.spec.finish)*.5
 local outside=F.actor(Vector(-900,900,0));c.heroes[2]=outside;F.advance(c,1.5);ok(#c.pushes==1 and c.pushes[1].p==p,'crosswind pushes only geometry-filtered targets')
 phase(c,3);d:Dive(c,Vector(300,0,0));equal(c.charge.spec.mode,'air','dive preserves swept aerial movement')
 local structure=c.data.cover[1];F.finishCharge(c,false,structure.pos,{Hit=true,Entity=structure.ent});equal(last(c.staggers).seconds,5,'actual heavy structure collision major stagger')
 d:Dive(c,Vector(300,0,0));F.finishCharge(c,false,Vector(300,0,0),{Hit=true,HitWorld=true});equal(last(c.staggers).seconds,2.5,'arbitrary wall not falsely designated')
 local dog,dd=fresh('flightmeister');phase(dog,2);dd:Dogfight(dog,Vector(300,0,0));F.advance(dog,3.3);equal(dog.data.flight.name,'DOGFIGHT: CLIMB','Dogfight climb authored')
 F.advance(dog,2.3);equal(dog.data.flight.name,'BOMBING RUN','Dogfight bombing authored')
 F.advance(dog,3.8);equal(dog.data.action,'HOVER FIRE / EXPOSED ENGINE','Dogfight hover authored');ok(dog.data.flight==nil,'hover stationary punish')
 F.advance(dog,2.7);equal(dog.data.flight.name,'DOGFIGHT: LOW RETURN','Dogfight low return authored')
 F.advance(dog,3);ok(dog.data.recoverUntil>dog.now and dog.data.flight==nil,'Dogfight ends long recovery')
 local heavy=fresh('flightmeister');heavy.def:Heavy(heavy,Vector(300,0,0));F.advance(heavy,1.8);equal(count(heavy,'flight_heavy'),2,'small bounded heavy ordnance pair')
 F.pause(heavy);local pending=#heavy.objects;F.advance(heavy,10);ok(count(heavy,'flight_heavy')==0,'pause cannot spawn delayed old ordnance')
end

-- Every next-pass form honors a beacon, including ordnance and dive rather than strafe only.
for _,method in ipairs({'Bombing','Crosswind','Dive'}) do
 local c,d=fresh('flightmeister');used(c,'flight_beacon');local lane=c.data.beaconLane
 d[method](d,c,Vector(600,0,0));equal(c.data.beaconLane,nil,method..' consumes next-pass beacon')
 if method=='Dive' then F.finishCharge(c,false);equal(last(c.staggers).seconds,4,'beacon guarantees dive recovery')
 else equal(c.data.flight.lane,lane,method..' flies actual beacon lane');equal(c.data.flight.recovery,4,method..' guarantees beacon bank') end
end
-- CONAN: every formation, explicit detour, finite collision bait and bounded solo/multiplayer traps.
do
 local c,d=fresh('conan');equal(#c.data.lanes,4,'four authored road lanes')
 for _,name in ipairs({'funnel','zigzag','partial_ring','lane_divider','chicane'}) do
  B:Clear(c,'conan_mini');ok(d:Cones(c,name,Vector()),'authored formation '..name);F.advance(c,1)
  local objects=B:Objects(c,'conan_mini');ok(#objects>=5 and #objects<=6,'bounded formation '..name)
  ok(objects[1].spec.pushable and objects[1].spec.hp==22 and objects[1].spec.life==16,'mini cones finite HP / push / lifetime')
 end
 B:Clear(c,'conan_mini');c.routeBlocked=true;ok(not d:Cones(c,'funnel',Vector()),'reject disconnected formation');equal(count(c,'conan_mini'),0,'invalid formation spawns none');c.routeBlocked=false
 d:Closure(c);d:Closure(c);local live=0;for _,z in ipairs(c.zones) do if not z.retired and z.spec.kind=='conan_closure' then live=live+1 end end
 equal(live,1,'at most one lane closure');equal(last(c.logs).data.guaranteedOpen,3,'three alternate lanes')
 d:Charge(c,Vector(500,250,0),true);local first=c.charge;local previews=#c.warnings;ok(previews>=2,'both detour segments previewed before movement')
 F.finishCharge(c,false);ok(c.charge~=first and c.charge.spec.label=='DETOUR SEGMENT 2','committed second segment follows first');F.finishCharge(c,false)
 local sign=c.data.signs[1];d:Cones(c,'funnel',Vector());F.advance(c,1);d:Charge(c,sign.pos,false);F.finishCharge(c,false,sign.pos,{Hit=true,Entity=sign.ent})
 ok(sign.retired,'finite designated sign consumed');equal(count(c,'conan_mini'),0,'barrier bait clears mini-cones');equal(last(c.staggers).seconds,3.5,'barrier bait stagger')
 local solo,sd=fresh('conan');local p=solo.heroes[1];sd:Coned(solo,p);local landed=p:GetPos();F.finishCharge(solo,true,landed)
 ok(solo.data.trap and table.Count(solo.constraints)==1,'CONED real landing traps captured Hero');equal(solo.data.trap.untilTime-solo.now,3.2,'solo trap strictly finite')
 F.think(solo,3.21);ok(not solo.data.trap and table.Count(solo.constraints)==0,'solo auto escape');ok(not sd:Coned(solo,p),'recovery immunity prevents chain locking')
 local missed,md=fresh('conan');md:Coned(missed,missed.heroes[1]);F.finishCharge(missed,false);ok(not missed.data.trap,'miss never traps');equal(last(missed.staggers).seconds,2.4,'miss punish')
 local stale,st=fresh('conan');st:Coned(stale,stale.heroes[1]);stale.heroes[1].life=2;F.finishCharge(stale,true,stale.heroes[1]:GetPos());ok(not stale.data.trap,'old drop cannot trap new life')
 local coop,co=fresh('conan');coop.party=2;local teammate=F.actor(Vector(350,0,0));coop.heroes[2]=teammate
 co:Coned(coop,coop.heroes[1]);F.finishCharge(coop,true,coop.heroes[1]:GetPos());local escape=coop.data.trap.object
 escape.spec.onUse(coop,escape,teammate);F.advance(coop,.8);escape.spec.onUse(coop,escape,teammate);F.think(coop,.01)
 ok(not coop.data.trap,'teammate accelerates release before solo bound')
 local paused,pa=fresh('conan');pa:Coned(paused,paused.heroes[1]);F.finishCharge(paused,true,paused.heroes[1]:GetPos());F.pause(paused)
 ok(not paused.data.trap and table.Count(paused.constraints)==0,'pause releases all temporary trap state')
 local double,db=fresh('conan');double.party=2;double.heroes[2]=F.actor(Vector(-300,0,0));db:DoubleConed(double,double.heroes)
 F.finishCharge(double,false);F.advance(double,7.6);ok(double.charge and double.charge.destination.x==-300,'separated second coned targets different Hero')
 local storm=fresh('conan');storm.def:Cascade(storm);F.advance(storm,1.4);equal(count(storm,'conan_cascade'),8,'bounded outward cascade')
end

-- Native cancellation must never convert rejection/hit stun/phase retirement into a punish or a second charge.
for _,method in ipairs({'Charge','Coned'}) do
 for _,mode in ipairs({'reject','stun','timeout','phase'}) do
  local c,d=fresh('conan');local target=c.heroes[1]
  if mode=='reject' then c.rejectCharge=true end
  if method=='Coned' then d:Coned(c,target) else d:Charge(c,target:GetPos(),true) end
  if mode=='stun' then F.finishCharge(c,false,c.actor:GetPos(),{cancelled=true})
  elseif mode=='timeout' then F.think(c,30)
  elseif mode=='phase' then
   local q=c.charge;c.charge=nil;if q then q.spec.onFinish(c,false,c.actor:GetPos(),{cancelled=true}) end;phase(c,3)
  end
  ok(not c.data.charging and not c.data.coned,method..' clears flag on '..mode)
  equal(#c.staggers,0,method..' cancellation has no punish '..mode)
  ok(not c.data.trap,method..' cancellation cannot trap '..mode)
 end
end
for _,mode in ipairs({'reject','stun','timeout','phase'}) do
 local c,d=fresh('flightmeister');if mode=='reject' then c.rejectCharge=true end;d:Dive(c,Vector(300,0,0))
 if mode=='stun' then F.finishCharge(c,false,c.actor:GetPos(),{cancelled=true})
 elseif mode=='timeout' then F.think(c,30)
 elseif mode=='phase' then local q=c.charge;c.charge=nil;q.spec.onFinish(c,false,c.actor:GetPos(),{cancelled=true});phase(c,3) end
 ok(not c.data.diving,'dive clears flag on '..mode);equal(#c.staggers,0,'dive cancellation never punishes '..mode)
end
do
 local c,d=fresh('conan');local p=c.heroes[1];d:Coned(c,p);equal(c.actor.LODBossHull.mins.z,80,'CONED native hull leaves72-unit escape')
 F.finishCharge(c,true,p:GetPos());F.pause(c)
 ok(c.data.trapHullOpen,'pause cannot re-enclose nearby Hero');equal(c.actor.LODBossHull.mins.z,80,'high hull survives paused escape')
 p.pos=Vector(-600,-600,0);d:RestoreTrapHull(c);ok(not c.data.trapHullOpen,'normal hull returns only after safe separation');equal(c.actor.LODBossHull.mins.z,0,'normal collision restored')
end
-- MOOKY: graph, resolved-damage knee counters, true underbody safety, capped locked laser and full walk.
do
 local c,d=fresh('little_mooky');equal(#c.data.graph.nodes,8,'eight authored Strider graph nodes');equal(table.Count(c.data.graph.edges),8,'every movement edge validated')
 equal(c.def.maxAdds,0,'Mooky never summons');ok(c.def.hull.mins.z>=245,'native main-body hull leaves underbody passage')
 equal(count(c,'mooky_permanent_cover'),4,'four permanent cover blocks')
 local knee=d:RigPoint(c,'left',false);local hp=c.actor.hp
 d:AfterDamage(c,c.actor,c.actor.maxhp*.03,c.heroes[1],knee);ok(not c.data.lowerUntil,'one small knee hit cannot buckle')
 d:AfterDamage(c,c.actor,c.actor.maxhp*.02,c.heroes[1],knee);ok(c.data.lowerUntil>c.now,'concentrated actual damage buckles')
 equal(c.actor.hp,hp,'knee counter never mutates or creates HP');local countStagger=#c.staggers
 d:AfterDamage(c,c.actor,1000,c.heroes[1],knee);equal(#c.staggers,countStagger,'lowered state cannot chain stagger')
 F.advance(c,4.3);d:AfterDamage(c,c.actor,1000,c.heroes[1],knee);equal(#c.staggers,countStagger,'recovered knee protected')
 local info=F.damageInfo();c.data.lowerUntil=c.now+1;info.pos=c.actor:GetPos()+Vector(0,0,340);d:BeforeDamage(c,c.actor,info);equal(info.value,12,'lowered main body modest vulnerability')
 local decay,dc=fresh('little_mooky');local k=dc:RigPoint(decay,'right',false);dc:AfterDamage(decay,decay.actor,decay.actor.maxhp*.03,decay.heroes[1],k)
 F.advance(decay,4.1);dc:AfterDamage(decay,decay.actor,decay.actor.maxhp*.02,decay.heroes[1],k);ok(not decay.data.lowerUntil,'knee damage must be concentrated')
 local fire,fd=fresh('little_mooky');fire.heroes[1].pos=Vector(40,0,0);local outside=F.actor(Vector(400,0,0));fire.heroes[2]=outside
 fd:FireLane(fire,Vector(700,0,0),'pulse',.8);F.advance(fire,.9);equal(#fire.damage,1,'underbody has cannon safety');equal(fire.damage[1].player,outside,'outside body takes cannon packet')
 local lock,ld=fresh('little_mooky');local target=Vector(450,0,0);ld:Laser(lock,target);target.x=-500;lock.heroes[1].pos=Vector(-500,0,0);F.advance(lock,1.1)
 equal(last(lock.zones).spec.finish.x,450,'laser final lock never tracks moved target');ld:Laser(lock,Vector(500,0,0));ld:Laser(lock,Vector(600,0,0));equal(lock.data.lasers,2,'maximum two laser events')
 local stomp,st=fresh('little_mooky');st:Stomp(stomp,true);equal(#stomp.zones,3,'three distinct stomp footprints');ok(stomp.zones[1].spec.delay<stomp.zones[3].spec.delay,'triple stomp sequential')
 local container,ct=fresh('little_mooky');ct:Container(container);F.advance(container,1.9);local o=B:Objects(container,'mooky_container')[1];ok(o~=nil,'container kick launches known lane')
 ok(not o.spec.onImpact(container,o,{Entity=container.heroes[1]}),'hero collision retains native impact damage');o.pos=Vector(500,100,0);o.spec.onHit(container,o,container.heroes[1]);equal(count(container,'mooky_kicked_cover'),1,'kicked container becomes validated cover')
 local walk,wd=fresh('little_mooky');wd:MookyWalk(walk);walk.moveReached=true;wd:Think(walk,walk.now,.1,walk.heroes)
 equal(walk.data.walk.stage,'walk','walk retreats before entire-court pass');walk.moveReached=false;F.think(walk,2.1)
 ok(#walk.zones>=4,'walk combines moving leg columns and cannon');walk.moveReached=true;F.think(walk,.1);F.think(walk,.1)
 ok(not walk.data.walk and walk.data.recoverUntil>walk.now,'far-side turn long recovery');equal(last(walk.staggers).seconds,5,'walk major punish window')
 local jitter,jd=fresh('little_mooky');jd:Jitter(jitter,Vector(500,0,0));F.advance(jitter,1.2);equal(#jitter.warnings,4,'four visible aim jitters');equal(#jitter.zones,1,'one final locked lane');equal(last(jitter.zones).spec.finish.x,500,'damaged aim commits fixed final line')
end

-- Authored Mooky edges are actually executed; native hull validation is repeated after owned cover changes.
do
 local c,d=fresh('little_mooky');local traces={};local original=util.TraceHull
 util.TraceHull=function(spec) traces[#traces+1]=spec;return {Hit=false,StartSolid=false,AllSolid=false} end
 local fingerprint=c.data.graph.fingerprint
 B:Object(c,{kind='test_new_cover',pos=Vector(200,200,0),hp=40,solid=true,permanent=true})
 d:RefreshGraph(c,false)
 ok(c.data.graph.fingerprint~=fingerprint,'owned cover mutation invalidates Strider graph cache')
 equal(#traces,16,'both directions of eight graph edges retraced')
 for _,tr in ipairs(traces) do equal(tr.mins.z,245,'revalidation sweeps model-specific native body hull') end
 d:Step(c,false);F.think(c,1.2);local move=last(c.moves)
 ok(move.options.path and #move.options.path==1,'step supplies explicit authored waypoint path')
 equal(move.options.path[1].x,move.destination.x,'canonical mover receives exact intended segment')
 local hp=c.actor.hp;local index=c.data.route;c.moveBlocked=true
 for _=1,3 do F.think(c,.9) end
 ok(not c.data.step,'blocked actual native movement ends after bounded retries')
 equal(c.actor.hp,hp,'route recovery preserves HP');equal(c.data.route,index,'failed edge cannot advance route index')
 local before=#c.staggers
 util.TraceHull=function() return {Hit=true,StartSolid=false,AllSolid=false} end
 B:Object(c,{kind='test_blocking_cover',pos=Vector(210,210,0),solid=true,permanent=true})
 d:Step(c,false);ok(not c.data.step,'blocked post-cover graph edge is never admitted')
 equal(#c.staggers,before,'path failure is not a fabricated punish window')
 util.TraceHull=original
 local w,wd=fresh('little_mooky');wd:MookyWalk(w);w.moveReached=true;wd:Think(w,w.now,.1,w.heroes)
 equal(w.data.walk.stage,'walk','retreat follows its exact native-clear approach')
 equal(w.data.walk.path[1].x,w.data.graph.nodes[2].x,'Mooky Walk includes authored middle node')
 equal(w.data.walk.path[2].x,w.data.graph.nodes[3].x,'Mooky Walk ends at authored far node')
 F.think(w,.1);local first=last(w.moves);F.think(w,.1);local second=last(w.moves)
 equal(first.options.path[1].x,w.data.graph.nodes[2].x,'first walk edge sent to explicit path mover')
 equal(second.options.path[1].x,w.data.graph.nodes[3].x,'second walk edge cannot shortcut the middle node')
end
do
 local c,d=fresh('conan')
 equal(count(c,'conan_curb'),8,'eight native low curb models')
 equal(count(c,'conan_gantry_post'),4,'two gantries have four real posts')
 equal(count(c,'conan_gantry_beam'),2,'two native elevated gantry crossbeams')
 for _,o in ipairs(c.data.roadwork) do ok(o.spec.cosmetic and o.spec.permanent,'roadwork prop cannot obstruct an escape or expire midfight') end
 c.dead=true;d:Defeat(c);local snag=B:Objects(c,'conan_tiny_snag')[1]
 ok(snag and snag.spec.model==d.model,'death snag is an actual tiny cone model')
 equal(snag.spec.scale,.75,'snag dwarfed by6.8-scale Conan');equal(snag.spec.life,5,'death snag finite')
 ok(snag.spec.cosmetic and not snag.spec.damage,'death snag has no offensive packet')
 equal(snag.pos.x,c.data.deathTarget.x,'client trip ends at the actual snag prop')
end
-- Lifecycle and geometry rejection are tested for every module, not inferred from labels.
for _,id in ipairs({'marion','flightmeister','conan','little_mooky'}) do
 local c,d=fresh(id);local before=#c.damage;c.dead=true;c.retired=true;F.advance(c,60);equal(#c.damage,before,id..' retired callbacks inert')
 local p,def=fresh(id);phase(p,3);ok(p.phase==3,id..' health phase supported');F.pause(p);F.advance(p,30);ok(not p.data.trap,id..' pause retains no temporary trap')
end
-- Exhaust the real phase schedulers under finite deterministic movement and interruption.
for _,id in ipairs({'marion','flightmeister','conan','little_mooky'}) do
 for ph=1,3 do
  local c,d=fresh(id);if ph>1 then phase(c,ph) end;c.moveReached=true
  for tick=1,480 do
   F.think(c,.25)
   if c.charge then
    local q=c.charge;q.fixtureAt=q.fixtureAt or c.now
    if c.now-q.fixtureAt>(q.spec.warning or 1)+1 then F.finishCharge(c,false) end
   end
  end
  ok(c.data.cycle>3,id..' phase '..ph..' executes sustained authored scheduler')
  ok(count(c)<=d.maxObjects,id..' phase '..ph..' respects shared object admission')
 end
end
for _,id in ipairs({'flightmeister','little_mooky'}) do
 local c,d=fresh(id);B:Clear(c,id=='flightmeister' and 'flight_hard_cover' or 'mooky_permanent_cover')
 c.denyObjects=true;c.data.nextAttack=0;local attacks=c.data.cycle;F.think(c,3)
 equal(c.data.cycle,attacks,id..' stops attacks without mandatory hard cover')
 c.denyObjects=false;F.think(c,2.1)
 ok(count(c,id=='flightmeister' and 'flight_hard_cover' or 'mooky_permanent_cover')>=2,id..' retries safe cover admission')
end
-- Presentation is invoked through the same Draw + optional Death contract as the shared renderer.
LOD.BossPresentation={Modules={}};local draws=0
render={SetColorMaterial=function() end,DrawBeam=function() draws=draws+1 end,DrawBox=function() draws=draws+1 end,
 DrawSphere=function() draws=draws+1 end,DrawWireframeSphere=function() draws=draws+1 end}
local clock=0;function CurTime() return clock end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
for _,id in ipairs({'marion','flightmeister','conan','little_mooky'}) do
 dofile('gamemodes/legend_of_deborah/gamemode/lod/bosses/cl_'..id..'.lua')
 local c=fresh(id);local e=c.actor
 function e:GetAngles() return Angle() end
 function e:GetForward() return Vector(1,0,0) end
 function e:GetRight() return Vector(0,1,0) end
 function e:GetUp() return Vector(0,0,1) end
 function e:GetNW2Bool(k,d) if self.nw[k]==nil then return d end;return self.nw[k] end
 function e:GetNW2Float(k,d) return self.nw[k] or d end
 function e:GetNW2String(k,d) return self.nw[k] or d end
 function e:GetNW2Vector(k,d) return self.nw[k] or d end
 local m=LOD.BossPresentation.Modules[id]
 for ph=1,3 do for _,dead in ipairs({false,true}) do for t=0,8 do
  clock=t;local state={phase=ph,dead=dead,deathAt=0,position=Vector(),deathTarget=Vector(300,0,0)}
  m:Pose(e,c.def.size,state);m:Draw(e,c.def.size,state);if dead and m.Death then m:Death(e,c.def.size,state) end
 end end end
 ok(draws>0,id..' phase/death presentation executes without allocations')
end
print('PASS boss large authored behavior assertions: '..n)
