local F=dofile('tools/boss_companions_fixture.lua')
local B,check=F.B,F.Assert
F.Load()
local assertions=0
local function ok(v,msg) assertions=assertions+1;check(v,msg) end
local function latest(c,kind) local o=B:Objects(c,kind);return o[#o] end
local function warned(c,word) for _,w in ipairs(c.warnings) do if string.find(w.label,word,1,true) then return true end end end
ok(B.Modules.chuck and B.Modules.rank_and_file and B.Modules.cornette,'three primary modules registered')
ok(B.Support.jane_propane and not B.Modules.jane_propane,'Jane is support, never an official boss')
-- Chuck: deterministic citizen; genuinely distinct physics; delayed commitment capture.
local c=F.New('chuck'),nil
local second=F.New('chuck')
ok(c.actor:GetModel()==second.actor:GetModel() and c.actor.nw.LOD_Beaver,'citizen roll deterministic and beaver embodiment enabled')
ok(c.owned[c.data.jane]=='jane_propane' and c.primary==c.actor,'Jane belongs to exact Chuck encounter')
local cfg={}
for _,kind in ipairs({'plank','timber','panel'}) do
    local e=F.New('chuck')
    ok(e.def:ThrowWood(e,kind,e.targets[1]),kind..' accepted')
    ok(#B:Objects(e,'chuck_wood')==0,kind..' cannot fire before tell')
    F.Advance(e,1.6,false)
    local o=latest(e,'chuck_wood');ok(o and o.woodType==kind,kind..' actual projectile emitted')
    cfg[kind]=o.spec
end
ok(cfg.plank.mass<cfg.panel.mass and cfg.panel.mass<cfg.timber.mass,'three wood masses differ')
ok(cfg.plank.velocity:Length()>cfg.timber.velocity:Length() and cfg.timber.velocity:Length()>cfg.panel.velocity:Length(),'plank/timber/panel speeds differ')
ok(cfg.timber.damage.push>cfg.plank.damage.push and cfg.plank.damage.push>cfg.panel.damage.push,'discrete authored Push differs')
ok(cfg.plank.life<cfg.timber.life and cfg.plank.bounces==1 and cfg.panel.bounces==0,'finite lifetime/bounce vocabulary')
local panel=F.New('chuck');panel.def:ThrowWood(panel,'panel',panel.targets[1]);F.Advance(panel,1.45,false)
local po=latest(panel,'chuck_wood');po.pos=Vector(250,80,0);po.spec.onImpact(panel,po,{HitPos=po.pos,HitNormal=Vector(0,0,1)})
ok(po.retired and #B:Objects(panel,'chuck_panel')==1,'broad panel settles into actual breakable denial')
local barrier=latest(panel,'chuck_panel');ok(barrier.spec.life==5 and barrier.spec.hp>0 and panel.routeChecks>0,'panel is short-lived, breakable and route-validated')
local log=F.New('chuck');log.def:ThrowWood(log,'timber',log.targets[1]);F.Advance(log,1.6,false)
local lo=latest(log,'chuck_wood');lo.spec.onImpact(log,lo,{HitPos=Vector(250,0,0),HitNormal=Vector(0,0,1)})
ok(lo.rolling and lo.velocity:Length()==190 and lo.expires<=log.now+1.5,'heavy timber becomes a bounded short roll')
local stale=F.New('chuck');stale.def:ThrowWood(stale,'plank',stale.targets[1]);stale.targets[1].life=2;F.Advance(stale,1,false)
ok(#B:Objects(stale,'chuck_wood')==0,'old wood tell does not retarget replacement Hero')
local full=F.New('chuck');for i=1,7 do B:Projectile(full,{kind='chuck_wood',pos=Vector(),life=6}) end
ok(not full.def:ThrowWood(full,'plank',full.targets[1]),'wood simultaneous cap enforced')
-- Every Jane cylinder state is actual persistent state; Critical cannot be punted.
local j=F.New('chuck');local cylinder=j.def:LooseCylinder(j,Vector(250,0,0));ok(cylinder.state=='Stable','cylinder starts stable')
j.now=1.5;j.def:ServiceCylinders(j,j.now);ok(cylinder.state=='Leaking' and cylinder.spec.pushable,'stable becomes visibly leaking')
j.now=4.2;j.def:ServiceCylinders(j,j.now);ok(cylinder.state=='Ignited' and not cylinder.spec.pushable,'separately warned fuel ignites')
j.now=5.2;j.def:ServiceCylinders(j,j.now);ok(cylinder.state=='Critical' and warned(j,'CRITICAL'),'critical stage announces blast')
j.now=6.5;j.def:ServiceCylinders(j,j.now);ok(cylinder.retired and #j.damage>0,'critical cylinder detonates through shared damage')
local valve=F.New('chuck');local cy=valve.def:LooseCylinder(valve,Vector(250,0,0))
valve.def:ValveHit(valve,cy,F.Info(cy.pos,valve.targets[1],true));ok(cy.state=='Stable','Fire cannot ignite a stable sealed cylinder')
valve.def:ValveHit(valve,cy,F.Info(cy.pos+Vector(0,0,25),valve.targets[1]));ok(cy.state=='Leaking','precise valve shot vents')
valve.now=.2;valve.def:ValveHit(valve,cy,F.Info(cy.pos+Vector(0,0,25),valve.targets[1]));ok(cy.velocity:Length()>200 and cy.igniteAt>=1.2,'leaking valve redirects and grants ignition warning')
cy.state='Ignited';valve.def:ValveHit(valve,cy,F.Info(cy.pos+Vector(0,0,25),valve.targets[1]));ok(cy.state=='Critical' and cy.blastAt>=valve.now+1,'precise ignited valve accelerates critical with fair warning')
local vented=F.New('chuck');local safeCylinder=vented.def:LooseCylinder(vented,Vector(250,0,0));F.Destroy(vented,safeCylinder)
ok(#vented.damage==0 and safeCylinder.done,'shooting cylinder safely vents without hidden instant damage')
local gas=F.New('chuck');local g=gas.def:GasPocket(gas,Vector(280,0,0),105,3)
ok(g and #gas.damage==0,'gas before fire creates positional pressure only')
F.Advance(gas,1.95,false);gas.def:ServiceGas(gas,gas.now);ok(g.warned and not g.ignited and #gas.damage==0,'ignition has a separate tell')
F.Advance(gas,1.1,false);gas.def:ServiceGas(gas,gas.now);F.Advance(gas,.8,false)
ok(g.ignited and #gas.damage>0 and gas.damage[1].spec.content=='fire','gas fire uses canonical fire pipeline')
local cap=F.New('chuck');cap.data.jane:SetPos(Vector(100,100,0));local max=cap.data.janeMaxHP
for i=1,40 do cap.now=i*4.1;cap.def:JaneBlast(cap,cap.data.jane:GetPos()) end
ok(cap.data.janeBlastDamage<=max*.16+.0001 and cap.data.jane:Health()>0,'cylinder self-damage is lifetime bounded and nonlethal')
ok(cap.selfDamage[1].amount>cap.selfDamage[2].amount,'Jane backfire has diminishing returns')
local nightmare=F.New('chuck');nightmare.phase=3;nightmare.def:PropaneNightmare(nightmare)
ok(#nightmare.data.gas==3 and nightmare.data.gas[1].expires<nightmare.data.gas[2].igniteAt,'nightmare has sequential fire and migrating safe gaps')
F.Advance(nightmare,2.5,false);ok(nightmare.data.jane.sound=='buttons/button10.wav','nightmare emits repeated failed ignition clicks')
F.Advance(nightmare,7.6,false);ok(#nightmare.data.gas==0 and nightmare.data.janeRecover>nightmare.now,'nightmare ends fully vented/vulnerable')
local relief=F.New('chuck');local rel=relief.def:LooseCylinder(relief,Vector(240,0,0));relief.def:GasPocket(relief,Vector(280,0,0),100,3);relief.def:EmergencyRelief(relief)
ok(rel.velocity:Length()==180 and #relief.data.gas==0 and relief.data.janeRecover==4,'relief clears fire and pushes light cylinders outward')
for phase=1,3 do
    local e=F.New('chuck');B:SetPhase(e,phase)
    for i=1,(phase==1 and 4 or phase==2 and 8 or 12) do e.def:JaneAttack(e,e.targets[1]);F.Advance(e,2,false) end
    ok(#e.warnings>=2 and #e.objects>0 and #e.hazards>0 and #e.charges>0,'Jane phase '..phase..' executes authored attack vocabulary')
end
local death=F.New('chuck');local primary=death.actor;death.def:LooseCylinder(death,Vector(250,0,0));death.def:GasPocket(death,Vector(300,0,0),90,3)
ok(death.def:ActorKilled(death,death.data.jane,'jane_propane'),'Jane death is handled internally')
ok(death.actor==primary and death.completions==0 and death.replacements==0 and death.data.janeDisabled,'Jane cannot own completion, primary or receipt')
ok(#B:Objects(death,'jane_cylinder')==1 and #death.data.gas==0,'Jane death marks hazards inert without native removal inside lethal callback')
F.Advance(death,.05,false)
ok(#B:Objects(death,'jane_cylinder')==0,'Jane hazards retire after lethal callback returns')
F.Advance(death,.2,false);ok(#B:Objects(death,'jane_death')==1 and #death.damage==0,'Jane death spectacle is delayed cosmetic only')
local vanished=F.New('chuck');local oldJane=vanished.data.jane
vanished.def:LooseCylinder(vanished,Vector(250,0,0));oldJane.valid=false;vanished.def:EnsureJane(vanished)
ok(vanished.data.janeDisabled and #B:Objects(vanished,'jane_cylinder')==0,'native Jane removal neutralizes her own hazards')
vanished.now=20;vanished.def:EnsureJane(vanished);ok(vanished.data.jane==oldJane,'successfully admitted Jane is never re-admitted')
local admission=F.New('chuck');admission.owned[admission.data.jane]=nil;admission.data.jane.valid=false
admission.data.jane=nil;admission.data.janeAdmitted=nil;admission.data.janeSpawnAt=0;admission.globalFull=true
admission.def:EnsureJane(admission);ok(not admission.data.jane and admission.data.janeSpawnAt==1,'failed initial Jane admission waits one second')
admission.globalFull=false;admission.now=.5;admission.def:EnsureJane(admission);ok(not admission.data.jane,'initial-admission retry does not busy-loop')
admission.now=1.1;admission.def:EnsureJane(admission);ok(IsValid(admission.data.jane) and admission.data.janeAdmitted,'failed initial admission resumes with exact registered support')
local lanes=F.New('chuck');lanes.def:VentAndIgnite(lanes)
local laneCount=0;for _,z in ipairs(lanes.hazards) do if z.kind=='jane_gas' and z.shape=='lane' and z.finish then laneCount=laneCount+1 end end
ok(laneCount>0,'Vent-and-Ignite is real directional lane geometry')
for _,id in ipairs({'chuck','rank_and_file','cornette'}) do
    local restored=F.New(id);local oldModel=restored.actor.model
    restored.actor=F.Entity(Vector(),restored.def.baseHP);restored.primary=restored.actor;restored.owned[restored.actor]='primary'
    restored.def:ActorReplaced(restored,restored.actor)
    ok(id~='chuck' or restored.actor.model==oldModel and restored.actor.nw.LOD_Beaver,'lost primary body restores frozen presentation: '..id)
end
-- Rank: real labels, cancellable markers, bounded normal-zombie queue and relocation.
local r=F.New('rank_and_file',4)
ok(#r.data.doors==3 and #r.data.shredders==2,'archive doors and optional shredders actually created')
ok(r.data.addCap==10 and r.data.queueCap==14,'party-aware simultaneous and pending zombie caps')
r.def:QueueBatch(r,30,'TEST');ok(#r.data.spawnQueue==14,'oversized zombie request bounded')
r.globalFull=true;F.Advance(r,1.5,false);r.def:ServiceQueue(r,r.now);F.Advance(r,1.5,false);r.def:ServiceQueue(r,r.now)
ok(#r.data.spawnQueue==14 and B:CountActors(r,'rank_zombie')==0,'global hostile ceiling pauses, does not lose queue')
r.globalFull=false;F.Advance(r,.7,false);r.def:ServiceQueue(r,r.now)
ok(#r.data.spawnQueue==13 and B:CountActors(r,'rank_zombie')==1,'same queue resumes when capacity returns')
local rz
for actor,role in pairs(r.owned) do if role=='rank_zombie' then rz=actor end end
ok(rz.opts.manual==false and rz.LODRankOrdinaryFamily,'zombies keep normal ordinary AI and family identity')
r.def:Misfiled(r);ok(#r.relocations==1 and r.relocations[1].actor==rz,'MISFILED relocates existing exact actor')
local rhp=rz:Health();F.Advance(r,1.1,false);ok(rz:Health()==rhp and B:CountActors(r,'rank_zombie')==1,'MISFILED preserves HP and actor/reward identity')
r.data.spawnQueue={};r.def:DuplicateCopy(r);ok(#r.data.spawnQueue==3 and r.data.spawnQueue[1].family==rz.LODRankOrdinaryFamily,'DUPLICATE COPY uses bounded ordinary family batch')
local p=F.New('rank_and_file');local folder=p.def:Pending(p,Vector(250,0,0));F.Destroy(p,folder);p.now=6;p.def:ServicePending(p,p.now)
ok(#p.data.spawnQueue==0,'destroyed PENDING folder cancels the zombie before emergence')
local folder2=p.def:Pending(p,Vector(250,0,0));p.now=10.1;p.def:ServicePending(p,p.now)
ok(folder2.queued and not folder2.done and #p.data.spawnQueue==1,'PENDING retains its destructible marker while queued for native emergence')
F.Destroy(p,folder2);p.now=11;p.def:ServiceQueue(p,p.now)
ok(#p.data.spawnQueue==0 and B:CountActors(p,'rank_zombie')==0,'destroying a ceiling-delayed folder cancels its queued emergence')
local shred=F.New('rank_and_file');local sh=shred.data.shredders[1];local marker=shred.def:Pending(shred,sh.pos+Vector(50,0,0));sh.nextUse=.2
shred.def:ObjectEvent(shred,sh,'use',shred.targets[1]);ok(marker and marker.done and #shred.data.spawnQueue==0,'optional E shredder cancels nearby folder despite shared use debounce')
local mass=F.New('rank_and_file');mass.def:MassFiling(mass,mass.targets[1]);ok(#mass.data.spawnQueue>0,'Mass Filing begins PERSONNEL')
F.Advance(mass,1.6,false);ok(#B:Objects(mass,'rank_pending')==2,'Mass Filing continues PENDING')
F.Advance(mass,1.6,false);ok(mass.data.action=='DENIED: FRONTAL PUSH','Mass Filing finishes DENIED in order')
local surge=F.New('rank_and_file',4);surge.def:Personnel(surge,true)
ok(#surge.data.spawnQueue==8 and surge.data.exposedUntil==6 and surge.actor.nw.LOD_RankAllDrawers,'ALL HANDS queues larger bounded surge while stationary/exposed')
local hit=F.Info();surge.def:BeforeDamage(surge,surge.actor,hit);ok(hit.amount==13,'open-all punish increases actual primary damage only')
B:SetPhase(surge,3);surge.data.exposedUntil=nil
local weak=F.Info(Vector(65,0,100));surge.def:BeforeDamage(surge,surge.actor,weak);ok(weak.amount==12.5,'phase-three extended drawer is an optional native-HP weak point')
local body=F.Info(Vector(-40,0,100));surge.def:BeforeDamage(surge,surge.actor,body);ok(body.amount==10,'cabinet body remains ordinarily damageable')
ok(surge.def:KeyPosition(surge).z==0,'MISC drawer key position is reachable floor')
-- Cornette: alternating physical hands, finite return, flank drones and true column contact.
local co=F.New('cornette');ok(#co.data.columns==3 and co.actor.nw.LOD_CornetteAndroid,'heavy columns and android embodiment enabled')
co.def:DrillShot(co,co.targets[1],false);F.Advance(co,1.1,false);local drill=latest(co,'cornette_drill')
ok(drill.hand=='Left' and co.data.hands.Left and drill.spec.velocity:Length()>700,'left hand physically leaves as non-hitscan drill')
co.def:DrillShot(co,co.targets[1],false);F.Advance(co,1.1,false);local drill2=latest(co,'cornette_drill')
ok(drill2.hand=='Right' and co.data.hands.Right,'right hand alternates')
local tr={HitPos=Vector(300,100,0),HitNormal=Vector(-1,0,0)}
ok(drill.spec.onImpact(co,drill,tr)==nil,'normal drill allows first ricochet')
ok(drill.spec.onImpact(co,drill,tr)==true and drill.state=='EMBEDDED' and drill.velocity:Length()==0,'second wall impact embeds drill briefly')
F.Advance(co,1.1,false);ok(not co.data.hands.Left,'embedded drill returns/reconstitutes')
local destroyed=F.New('cornette');destroyed.def:DrillShot(destroyed,destroyed.targets[1],false);F.Advance(destroyed,1.1,false);F.Destroy(destroyed,latest(destroyed,'cornette_drill'))
ok(not destroyed.data.hands.Left,'destroying thrown drill restores its exact hand')
local runaway=F.New('cornette');B:SetPhase(runaway,3);runaway.def:DrillShot(runaway,runaway.targets[1],true);F.Advance(runaway,1.6,false)
ok(latest(runaway,'cornette_drill').spec.bounces==3 and not runaway.def:DrillShot(runaway,runaway.targets[1],true),'one capped runaway drill with bounded ricochets')
local drones=F.New('cornette',4);B:SetPhase(drones,2);F.Advance(drones,.6,false);drones.def:ServiceDrones(drones,drones.now,drones.targets)
ok(B:CountActors(drones,'drizel_drone')==1,'phase two spawns killable drone')
for i=1,5 do drones.now=drones.now+13;drones.def:ServiceDrones(drones,drones.now,drones.targets) end
ok(B:CountActors(drones,'drizel_drone')==3,'drone replacement cooldown and simultaneous cap')
local dr
for actor,role in pairs(drones.owned) do if role=='drizel_drone' then dr=actor;break end end
local ds=drones.data.droneState[dr];ds.chargingUntil=nil
drones.def:AcquireDrone(drones,dr,drones.targets[1],true);ok(ds.chargingUntil>drones.now and warned(drones,'DRONE PUSH'),'drone visibly charges a committed lane')
F.Advance(drones,1.2,false);local bolt
for _,o in ipairs(B:Objects(drones,'cornette_drone_blast')) do if o.source==dr then bolt=o end end
ok(bolt and bolt.source==dr and bolt.spec.damage.push==100,'drone fires ordinary positional blast and modest inward Push')
local expected=(drones.actor:GetPos()-(drones.targets[1]:GetPos()+Vector(0,0,28))):GetNormalized()
ok(bolt.spec.damage.direction:Dot(expected)>.99,'drone Push is toward Cornette')
dr.hp=0;drones.def:ActorKilled(drones,dr,'drizel_drone');ok(drones.data.nextDrone>=drones.now+12,'dead drone replacement waits full cooldown')
local strain=F.New('cornette');B:SetPhase(strain,3);strain.def:AddStrain(strain,99);ok(not strain.data.overstrainUntil,'below overstrain threshold remains active')
strain.def:AddStrain(strain,3);ok(strain.data.overstrainUntil==4.8 and strain.data.action=='OW OW OW OW OW: OVERSTRAIN','overstrain produces actual finite vulnerability')
local hurt=F.Info();strain.def:BeforeDamage(strain,strain.actor,hurt);ok(hurt.amount==12.5,'overstrain is a real damage punish window')
strain.now=5;strain.def:Think(strain,5,.05,strain.targets);ok(strain.data.strain==20 and not strain.actor.nw.LOD_CornetteOverheated,'overstrain resets rather than chain-locking')
local column=F.New('cornette');column.def:DrillSkateCharge(column,column.targets[1]);local ch=column.charges[1]
ch.spec.onFinish(column,false,column.data.columns[1].pos,{Entity=column.data.columns[1].ent})
ok(column.data.recoverUntil==5.5 and column.actor.nw.LOD_CornetteColumnStuck,'both drills striking actual heavy column create major punish')
local near=F.New('cornette');near.def:DrillSkateCharge(near,near.targets[1]);near.charges[1].spec.onFinish(near,false,near.data.columns[1].pos,nil)
ok(near.data.recoverUntil==1.8,'merely standing near column cannot counterfeit a column collision')
local missing=F.New('cornette');missing.data.hands.Left=true;missing.def:DrillSkateCharge(missing,missing.targets[1]);missing.charges[1].spec.onFinish(missing,false,missing.data.columns[1].pos,{Entity=missing.data.columns[1].ent})
ok(missing.data.recoverUntil==1.8,'one missing hand cannot claim both drills stuck')
-- Stress all phases and lifecycle branches with the real authored methods.
for _,id in ipairs({'chuck','rank_and_file','cornette'}) do
    local e=F.New(id,4)
    for phase=1,3 do B:SetPhase(e,phase);F.Advance(e,95,true) end
    ok(#B:Objects(e)<=e.def.maxObjects,id..' bounded object population across long three-phase simulation')
    ok(B:CountActors(e)-1<=e.def.maxAdds,id..' bounded owned adds')
    ok(e.completions==0 and e.replacements==0,id..' hazards and support never complete a primary')
    local before=#e.damage
    e.def:Pause(e);e.paused=true;F.Advance(e,10,true)
    ok(#e.damage==before,id..' paused simulation cannot attack')
    e.paused=false;e.retired=true;F.Advance(e,10,true)
    ok(#e.damage==before,id..' stale callbacks cannot attack retired owner')
end
-- Render invocation records prove there is actual geometry, not only descriptor strings.
local shapes={sphere=0,box=0,beam=0,line=0,text=0}
render={SetColorMaterial=function() end,DrawSphere=function() shapes.sphere=shapes.sphere+1 end,
    DrawBox=function() shapes.box=shapes.box+1 end,DrawBeam=function() shapes.beam=shapes.beam+1 end,
    DrawLine=function() shapes.line=shapes.line+1 end}
cam={Start3D2D=function() end,End3D2D=function() end};draw={SimpleText=function() shapes.text=shapes.text+1 end}
TEXT_ALIGN_CENTER=1
function CurTime() return 1 end
for _,id in ipairs({'chuck','rank_and_file','cornette'}) do dofile('gamemodes/legend_of_deborah/gamemode/lod/bosses/cl_'..id..'.lua') end
local visual=F.New('chuck');LOD.BossPresentation.Modules.chuck:Draw(visual.actor,1.15,{phase=1})
ok(shapes.box>=12 and shapes.sphere>=5 and shapes.line>=12,'Chuck actually draws beaver muzzle/incisors/ears and crosshatched paddle tail')
local n=shapes.text;local cabinet=F.New('rank_and_file');LOD.BossPresentation.Modules.rank_and_file:Draw(cabinet.actor,3.2,{phase=1})
ok(shapes.text==n+5,'all five cabinet drawer labels actually render')
local android=F.New('cornette');local beams=shapes.beam;LOD.BossPresentation.Modules.cornette:Draw(android.actor,1.15,{phase=3})
ok(shapes.beam>beams+25,'Cornette actually renders helical drill hands, skating equipment and damage effects')
print('PASS boss companions: '..assertions..' authored behavioral/render assertions; no native-runtime acceptance claim')
