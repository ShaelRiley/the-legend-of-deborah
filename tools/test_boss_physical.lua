local F=dofile('tools/boss_physical_fixture.lua')
local B=F.B
local n=0
local function check(ok,label) assert(ok,label);n=n+1;print('PHYSICAL_OK '..n..' '..label) end
local function near(a,b) return math.abs(a-b)<.0001 end
local function sum(t) local total=0;for _,v in ipairs(t) do total=total+v.amount end;return total end
local c=F.fresh('chonker');local D=c.def
check(D.model=='models/pigeon.mdl' and D.size==1,'Chonker is an ordinary-size stock pigeon')
local o=D:PlaceBomb(c,'black',Vector())
check(o and o.health==24 and o.state=='PLACED','Black bomb is native-HP attackable with explicit initial state')
F.hitObject(c,o,24);F.think(c,5)
check(o.state=='DEFUSED' and #c.damage==0,'Destroying Black bomb defuses without explosion')
c=F.fresh('chonker');D=c.def;c.heroes[1].pos=Vector(25,0,0)
o=D:PlaceBomb(c,'red',Vector());c.data.nextWing=100;c.data.nextAttack=100;F.think(c,.79)
check(o.state=='PLACED' and #c.damage==0,'Proximity mine has a real arming window')
F.think(c,.02)
check(o.state=='TRIGGERED: EVADE' and #c.damage==0,'Red mine triggers but preserves .85-second escape warning')
F.think(c,.84);check(#c.damage==0,'Mine cannot damage before committed fuse')
F.think(c,.02);check(#c.damage==1 and o.state=='DETONATED','Triggered mine uses one shared blast')
c=F.fresh('chonker');D=c.def
local gold=D:PlaceBomb(c,'gold',Vector())
check(gold and not D:PlaceBomb(c,'big',Vector(-100,0,0)),'Gold and THE BIG ONE share one active signature slot')
F.hitObject(c,gold,100)
local big=D:PlaceBomb(c,'big',Vector())
F.hitObject(c,big,150);F.advance(c,.36)
check(big.state=='DEFUSED' and c.staggers[1].seconds==4.5 and #c.damage==0,'Focus-firing THE BIG ONE safely backfires into largest punish window')
D:ObjectEvent(c,big,'destroy');F.advance(c,1)
check(#c.staggers==1,'Duplicate bomb death cannot replay backfire')
c=F.fresh('chonker');D=c.def
for i=1,12 do D:PlaceBomb(c,'black',Vector(i*10,0,0)) end
check(#B:Objects(c,'chonker_bomb')==8,'Bomb population is capped at eight')
check(not D:PlaceBomb(c,'black',c.data.safe),'Guaranteed safe anchor rejects nearby bomb placement')
c=F.fresh('chonker');c.routeBlocked=true
check(not c.def:PlaceBomb(c,'black',Vector()) and #c.routeChecks>0,'Connectivity proof gates every new bomb')
c=F.fresh('chonker');F.think(c,2)
check(c.moves[1].options.mode=='skate' and c.moves[1].options.turnRate==1.8,'Skate movement has bounded turn rate')
B:SetPhase(c,2);c.data.cycle=2;F.think(c,2);F.advance(c,1.4)
check(#B:Objects(c,'chonker_bomb')>=3,'Phase two releases a staggered fast bomb-dropping lap')
B:SetPhase(c,3);c.data.cycle=7;F.think(c,3)
check(c.data.gold and c.data.gold.bombType=='big','Phase three grammar reaches THE BIG ONE')
F.pause(c);check(#B:Objects(c,'chonker_bomb')==0 and not c.data.gold,'No-Hero pause retires offensive bombs without boss reset')

c=F.fresh('felon');D=c.def
check(D.pushScale==0,'Felon body rejects the spawned-melon Push rule')
local normal=D:Throw(c,Vector(500,0,0),'single')
local bank=D:Throw(c,Vector(950,0,0),'bank')
check(normal.spec.velocity.z>bank.spec.velocity.z and normal.spec.bounces==2 and bank.spec.bounces==3,'Single arc and Bank Shot have differentiated lift and ricochet budgets')
check(normal.spec.pushable and bank.spec.pushable,'Spawned produce is explicitly Push-displaceable')
F.impact(c,normal,Vector(0,0,1));F.impact(c,normal,Vector(-1,0,0));F.impact(c,normal,Vector(0,0,1))
check(normal.retired and normal.smashed and #B:Objects(c,'felon_chunk')==2,'Melon shatters after bounded admitted bounces')
for _,chunk in ipairs(B:Objects(c,'felon_chunk')) do check(not chunk.spec.damage and chunk.spec.life==1.1,'Melon fragments are harmless and short lived') end
D:Smash(c,normal);check(#B:Objects(c,'felon_chunk')==2,'Duplicate impact cannot multiply chunks')
c=F.fresh('felon');D=c.def
D:Bounce(c,Vector(400,0,0),'short');check(c.charge.spec.arc==65 and c.charge.spec.warning==.65,'Short bounce is a warned committed body attack')
F.finishCharge(c,false);check(c.staggers[1].seconds==.9,'Short landing has real recovery')
B:SetPhase(c,2);D:Bounce(c,Vector(600,0,0),'long');F.advance(c,1.8)
check(#B:Objects(c,'felon_melon')==3,'Long phase-two bounce drops bounded Melon Trail')
F.finishCharge(c,false,Vector(500,0,0),{Hit=true,HitWorld=true,HitNormal=Vector(-1,0,0)})
F.advance(c,1.81)
check(c.charge and c.charge.spec.label=='WALL REBOUND' and c.charge.destination.x<500,'Hard wall collision creates a separately previewed reflected rebound')
F.finishCharge(c,false)
B:SetPhase(c,3)
for i=1,30 do D:ImpactPunish(c,true) end
check(near(sum(c.selfDamage),c.actor:GetMaxHealth()*.14) and c.actor:Health()>0,'Phase-three hard impacts have a total 14% nonlethal self-damage ceiling')
D:ProduceRain(c);F.advance(c,2.5)
local rain=0;for _,m in ipairs(B:Objects(c,'felon_melon')) do if m.variant=='rain' then rain=rain+1;check(m.pos:DistToSqr(c.data.safe)>210^2,'Produce rain excludes authored safe anchor') end end
check(rain>0 and rain<=6 and #c.routeChecks>0,'Produce Section is bounded rain through connectivity-checked marked regions')
c=F.fresh('felon');D=c.def;D:Bounce(c,Vector(400,0,0),'short');F.think(c,3.6)
check(c.charge.spec.arc==240 and c.charge.spec.label=='HIGH BOUNCE','Stuck geometry triggers a high escape bounce')
c=F.fresh('felon');B:SetPhase(c,2);c.data.cycle=4;F.think(c,2)
check(c.charge and c.charge.spec.arc==240,'High bounce remains reachable in phase-two grammar')
F.pause(c);check(not c.data.bouncing and #B:Objects(c,'felon_melon')==0,'Pause cancels produce and transient body commitment')

c=F.fresh('daryl');D=c.def;o=D:Barrel(c,Vector(60,0,0),'stationary',false)
check(o and o.state=='STABLE' and o.spec.pushable,'Lesser barrel starts Stable and movable')
F.hitObject(c,o,1);check(o.state=='ARMED' and not o.spec.pushable,'A damaging hit visibly arms and bounds barrel movement')
F.think(c,1.79);check(o.state=='ARMED','Armed fuse is not secretly shortened')
F.think(c,.02);check(o.state=='CRITICAL','Fuse exposes a distinct Critical state')
F.think(c,.8);check(o.state=='DETONATED' and c.actor:Health()<c.actor:GetMaxHealth(),'Barrel detonation can modestly hurt Daryl')
local firstStagger=c.staggers[1].seconds
local another=D:Barrel(c,Vector(60,0,0),'stationary',false);D:Explode(c,another)
check(#c.staggers==1,'Back-to-back barrel chain cannot renew blast stagger')
F.advance(c,5.1);another=D:Barrel(c,Vector(60,0,0),'stationary',false);D:Explode(c,another)
check(c.staggers[#c.staggers].seconds<firstStagger,'Next permitted blast stagger has diminishing returns')
for i=1,30 do local barrel=D:Barrel(c,Vector(60,0,0),'stationary',false);if barrel then D:Explode(c,barrel) end end
check(near(c.data.chainSpent,c.actor:GetMaxHealth()*.18),'Chain reactions have an encounter-wide 18% self-damage cap')
c=F.fresh('daryl');D=c.def;local stable=D:Barrel(c,Vector(90,0,0),'stationary',false);local blue=D:Barrel(c,Vector(),'stationary',true)
D:Explode(c,blue)
check(stable.velocity and stable.velocity:Length()>190 and stable.state=='STABLE','Blue barrel repositions stable hazards without arming them')
check(#c.selfDamage==0,'Rare Blue pressure burst cannot become ordinary self-damage chain')
c.heroes[1].pos=Vector(20,0,0);blue=D:Barrel(c,Vector(),'stationary',true);D:Explode(c,blue)
check(c.damage[1].spec.damage==2 and c.damage[1].spec.push==370,'Blue barrel has strong low-damage Push')
c=F.fresh('daryl');D=c.def
local from=D:Barrel(c,Vector(),'stationary',false);local to=D:Barrel(c,Vector(280,0,0),'stationary',false)
D:SetBarrelState(c,from,'ARMED',3);check(D:FuseTransfer(c),'Visible fuse transfer finds a valid source and recipient');F.advance(c,.81)
check(from.state=='STABLE' and to.state=='ARMED' and to.explodeAt>c.now+2,'Fuse transfers exactly once with readable destination window')
c=F.fresh('daryl');D=c.def;B:SetPhase(c,3);c.heroes[1].pos=Vector(20,0,0);c.heroes[1].covered=true
D:InternalFuse(c);F.advance(c,4.51)
check(#c.damage==0 and near(sum(c.selfDamage),c.actor:GetMaxHealth()*.02),'Controlled Detonation respects cover and fixed bounded self-damage')
for i=1,12 do D:InternalFuse(c);F.advance(c,4.6) end
check(near(c.data.internalSpent,c.actor:GetMaxHealth()*.1) and c.actor:Health()>0,'Internal Fuse cannot kill or indefinitely erode Daryl')
c=F.fresh('daryl');D=c.def;D:Pattern(c,'signature');F.advance(c,8.51)
check(#c.staggers==1 and c.staggers[1].seconds==3.3,'Signature sequential ignition ends in real overheat vulnerability')
check(#B:Objects(c,'daryl_barrel')<=7 and #c.routeChecks>=1,'Signature admits only bounded connectivity-checked barrels')
F.pause(c);check(#B:Objects(c,'daryl_barrel')==0,'Pause clears armed ordnance but preserves self-damage ledger')
c=F.fresh('daryl');c.randomValue=1;o=c.def:Barrel(c,Vector(),'stationary')
check(o.blue and c.rngStreams.blue_barrel,'Rare barrel selection uses isolated deterministic substream')

c=F.fresh('sofa');D=c.def
check(#c.data.islands==3 and #c.routeChecks>=6,'Finite designated furniture is admitted with connected Hero routes')
D:SofaCharge(c,Vector(400,0,0));local island=c.data.islands[1]
F.finishCharge(c,false,island.pos,{Hit=true,Entity=island.ent})
check(island.retired and c.staggers[1].seconds==2.7,'Missed charge smashes designated furniture for bounded punish')
local before=#c.staggers;check(not D:SmashIsland(c,Vector(999,999,0),{Hit=true,HitWorld=true},false) and #c.staggers==before,'Unrelated scenery cannot produce furniture stagger')
c=F.fresh('sofa');D=c.def;local originalHP=c.actor:Health();D:SectionalSplit(c,Vector(400,0,0));F.advance(c,1.11)
local section=c.data.section
check(section and section.spec.kind=='sofa_section' and section.spec.role=='detached_chaise','Sectional Split creates a hazard, never a support boss body')
F.hitObject(c,section,60)
check(not c.data.section and c.actor:Health()==originalHP and not c.actor.nw.LOD_BossSectionDetached,'Destroyed chaise reconnects without changing main boss HP or receipt')
D:SectionalSplit(c,Vector(400,0,0));F.advance(c,6.5)
check(not c.data.section,'Undamaged section automatically reconnects after bounded lifetime')
c=F.fresh('sofa');D=c.def;B:SetPhase(c,3);D:SofaCharge(c,Vector(600,0,0));local middle=c.charge.destination
check(middle.y~=0 and middle.x<600,'Broken-Leg Drift commits a crooked first segment')
F.finishCharge(c,false)
check(c.charge and c.charge.destination.x==600 and c.charge.destination.y==0,'Broken-Leg Drift completes fixed second segment without tracking')
F.finishCharge(c,false)
c=F.fresh('sofa');D=c.def;c.heroes[1].pos=Vector(-400,0,0)
D:Recline(c,Vector(400,0,0),true);F.advance(c,1.8)
check(c.data.invertedUntil and c.actor.nw.LOD_BossInverted and c.staggers[1].seconds==4.1,'Missed Full Recline genuinely inverts into the longest punish window')
local melee=F.damageInfo(DMG_CLUB);D:BeforeDamage(c,c.actor,melee)
local bullet=F.damageInfo(2);D:BeforeDamage(c,c.actor,bullet)
check(melee.value==14 and bullet.value==10,'Inverted underside improves melee only, leaving ordinary damage intact')
c.heroes[1].pos=Vector(20,0,0);F.advance(c,4.1)
check(not c.data.invertedUntil and not c.actor.nw.LOD_BossInverted and c.damage[#c.damage].spec.push==300,'Inversion ends with warned violent recovery shove')
c=F.fresh('sofa');D=c.def;c.heroes[1].pos=Vector(150,0,0)
D:Recline(c,Vector(400,0,0),true);F.advance(c,1.8)
check(not c.data.invertedUntil and #c.damage==1 and c.staggers[1].seconds==1.7,'Full Recline hit uses rectangle damage and shorter non-inverted recovery')
c=F.fresh('sofa');D=c.def
local kinds={'chair','lamp','table','ottoman','cushion'};local catalog={}
for _,kind in ipairs(kinds) do catalog[kind]=D:Furniture(c,kind,Vector(400,0,0)) end
check(catalog.lamp.pos.z==310 and catalog.lamp.velocity.z<0,'Lamp falls from a visible bounded overhead source')
check(catalog.table.spec.mass>catalog.chair.spec.mass and catalog.table.spec.damage.push>catalog.chair.spec.damage.push,'Skidding table and sliding chair have meaningful impact/mass differences')
check(catalog.ottoman.spec.radius>catalog.cushion.spec.radius and catalog.cushion.velocity.z>catalog.ottoman.velocity.z,'Ottoman body and arcing cushion have distinct bounds and trajectories')
c=F.fresh('sofa');D=c.def;D:CushionMine(c,Vector(300,0,0));F.advance(c,1.99)
check(#c.damage==0,'Cushion mine warns for two seconds before soft burst');F.advance(c,.02)
check(#c.damage==1 and c.damage[1].spec.push==250 and #B:Objects(c,'sofa_cushion_mine')==0,'Cushion mine uses a finite damage/Push burst then cleans up')
c=F.fresh('sofa');D=c.def;B:SetPhase(c,3);D:Storm(c,Vector(400,0,0));F.advance(c,3.51)
check(#B:Objects(c,'sofa_furniture')==4 and c.data.reclining,'Furniture Storm combines bounded catalog lanes with one Full Recline')
F.pause(c);check(not c.data.reclining and #B:Objects(c,'sofa_furniture')==0,'Pause cancels Storm and removes temporary body poses')
c=F.fresh('sofa');c.actor.pos=Vector(100,90,0)
check(c.def:KeyPosition(c):DistToSqr(c.actor.pos)==0,'Authored cushion key location resolves to reachable boss floor');c.unsafe=true
check(c.def:KeyPosition(c):LengthSqr()==0,'Unsafe cushion drop falls back to recoverable court center')

-- Old-phase, retired-owner and budget-denial behavior is tested through actual callbacks.
for _,id in ipairs({'chonker','felon','daryl','sofa'}) do
    c=F.fresh(id);local hp=c.actor:Health();c.retired=true
    B:Later(c,.1,'stale',function(owner) error('retired callback executed') end);F.advance(c,1)
    check(c.actor:Health()==hp,'Retired '..id..' owner cannot execute a stale callback')
    c=F.fresh(id);B:Later(c,.1,'old_phase',function(owner) error('old phase callback executed') end);B:SetPhase(c,2);F.advance(c,1)
    check(c.phase==2,'Phase transition cancels old '..id..' commitments')
end
-- Resource pressure and cosmetic death callbacks must not trap or harm the encounter.
c=F.fresh('sofa');c.denyZones=true;c.def:Recline(c,Vector(400,0,0),true);F.advance(c,1.7)
check(not c.data.reclining and not c.actor.nw.LOD_BossVertical,'Denied shared zone budget exits vertical recline into safe recovery')
c=F.fresh('sofa');c.def:SofaCharge(c,Vector(400,0,0));c.charge=nil;F.think(c,8.1)
check(not c.data.charging and c.data.recoverUntil>c.now,'Lost native movement callback has a bounded safe Sofa recovery')
for _,id in ipairs({'chonker','felon','daryl','sofa'}) do
    c=F.fresh(id);c.dead=true;c.deathPosition=Vector();c.def:Defeat(c)
    F.advance(c,c.def.deathDuration-.1)
    check(c.data.deathStage~=nil and #c.damage==0,'Authored '..id..' death sequence executes without gameplay damage')
    for _,o in ipairs(c.objects) do
        if o.spec.cosmetic then check(not o.spec.damage and not o.spec.solid and o.spec.hp==0,'Death prop has no hazard or reward authority') end
    end
end
c=F.fresh('chonker');o=c.def:PlaceBomb(c,'red',Vector());c.heroes[1].pos=Vector(-700,0,0);c.now=12.1
c.def:ServiceBombs(c,c.now,B:Targets(c))
check(o.retired and o.state=='EXPIRED SAFELY' and #c.damage==0,'Untriggered Red mine expires harmlessly rather than forcing unavoidable detonation')
c=F.fresh('daryl');local toss=c.def:Barrel(c,Vector(450,0,0),'toss',false);local roll=c.def:Barrel(c,Vector(450,0,0),'rolling',false)
check(toss.velocity.z>roll.velocity.z and toss.spec.gravity>roll.spec.gravity and roll.velocity.x>0,'Toss and constrained Rolling Bomb have distinct ballistic and rolling motion')
c=F.fresh('sofa');c.routeBlocked=true;c.def:Recline(c,Vector(400,0,0),true)
check(not c.data.reclining and not c.pending.sofa_recline,'Unsafe large slam rectangle is not admitted')
-- Every furniture catalog entry is reachable by actual phase grammar, rather than only direct helper tests.
local reached={}
for step=1,9 do
    c=F.fresh('sofa');B:SetPhase(c,2);c.data.cycle=step-1;c.data.nextAttack=0
    c.def:Think(c,0,.1,B:Targets(c));F.advance(c,1.6)
    for _,f in ipairs(B:Objects(c,'sofa_furniture')) do reached[f.spec.role]=true end
end
check(reached.chair and reached.lamp and reached.table and reached.ottoman and reached.cushion,'Phase-two grammar actually reaches all five furniture trajectories')
c=F.fresh('felon')
check(#c.data.bowlRamps==6 and #c.staticBoxes==24,'Felon Start admits six actual shallow rim ramps within 24-box reservation')
for _,ramp in ipairs(c.data.bowlRamps) do
    check(ramp.spec.height/ramp.spec.steps==8 and ramp.spec.length==180,'Bowl rim has shallow eight-unit steps rather than visual-only metadata')
end
c=F.fresh('daryl')
check(#c.data.yardRamps==2 and #c.staticBoxes==8,'Powder Yard Start admits two real loading ramps')
check(#B:Objects(c,'daryl_blast_barrier')==2 and #B:Objects(c,'daryl_barrel_rack')==2 and #B:Objects(c,'daryl_rack_stock')==2,'Powder Yard contains solid blast barriers and visibly stocked racks')
for _,cover in ipairs(B:Objects(c,'daryl_blast_barrier')) do
    check(cover.spec.solid and cover.spec.permanent and cover.health==0 and not cover.spec.pushable,'Blast cover is permanent and cannot be shot or pushed away')
end
for i=1,12 do c.def:Barrel(c,Vector(i*5,0,0),'stationary',false) end
check(#B:Objects(c,'daryl_barrel')==12 and #B:Objects(c)==18 and c.def.maxObjects==22,'Scenery reservation preserves all twelve lesser barrels and four spare object slots')
c=F.fresh('daryl',{routeBlocked=true})
check(#c.data.yardObjects==0 and #c.data.yardRamps==0,'Rejected connectivity admits no partial Powder Yard scenery')
c=F.fresh('felon',{routeBlocked=true})
check(#c.data.bowlRamps==0 and #c.staticBoxes==0,'Rejected connectivity admits no partial bowl rim')
c=F.fresh('daryl');local rolling=c.def:Barrel(c,Vector(400,0,0),'rolling',false)
F.impact(c,rolling,Vector(-1,0,0),c.heroes[1])
check(#c.damage==1 and c.damage[1].spec.damage==7 and rolling.state=='ARMED','Rolling barrel preserves Hero impact damage while settling and visibly arming')
c=F.fresh('sofa');c.def:SectionalSplit(c,Vector(400,0,0));F.advance(c,1.11)
local chaise=c.data.section;F.impact(c,chaise,Vector(-1,0,0),c.heroes[1])
check(#c.damage==1 and c.damage[1].spec.damage==20 and c.damage[1].spec.push==230,'Chaise onImpact preserves native Hero contact damage and Push')
check(not chaise.retired and chaise.state=='WAITING TO RECONNECT','Chaise settles after Hero contact without becoming a second boss body')
local before=#c.damage;F.impact(c,chaise,Vector(0,0,1))
check(#c.damage==before and not chaise.retired,'Chaise world collision is consumed without a spurious Hero hit or deletion')
check(not B.registry.chonker.useOnly and not B.registry.felon.useOnly and not B.registry.daryl.useOnly and not B.registry.sofa.useOnly,'All four retain ordinary canonical damage/death receipt authority')
print('PASS physical boss production behavior: '..n..' assertions; API doubles, not native runtime acceptance')

-- Repeat scenery admission against production B:StaticRamp/Object/ValidateRoutes,
-- with only the native Source entity boundary emulated. Canonical static-box
-- Initialize is executed unchanged to verify real collision bounds/rotation.
local G=dofile('tools/boss_framework_fixture.lua')
local NB=G.B
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_static_box/init.lua')
local nativeStatic=ENT
local create=ents.Create
ents.Create=function(class)
    local e=create(class)
    if not IsValid(e) then return e end
    if class=='lod_static_box' then
        for _,field in ipairs({'BoxMins','BoxMaxs','BoxKind'}) do
            e['Set'..field]=function(self,v) self[field]=v end
            e['Get'..field]=function(self) return self[field] end
        end
        function e:SetSolid(v) self.actualSolid=v end
        function e:SetSolidFlags(v) self.actualSolidFlags=v end
        function e:AddEFlags(v) self.actualEFlags=v end
        function e:Spawn() nativeStatic.Initialize(self) end
    elseif class=='lod_boss_object' then
        function e:SetSolid(v) self.actualSolid=v end
    end
    return e
end
local registered={}
LOD.MazeBuilder._Register=function(_,e) registered[#registered+1]=e end
local _,nc=G.setup(3)
check(#nc.data.bowlRamps==6 and #nc.geometry==24,'Production Start creates twenty-four actual canonical lod_static_box bowl surfaces')
local minimum,maximum=math.huge,-math.huge
for _,ramp in ipairs(nc.data.bowlRamps) do
    for step,e in ipairs(ramp.entities) do
        check(e.LODCollisionReady and e.actualSolid==SOLID_BBOX and e.LODBossGeometry==nc,'Native static-box Initialize creates owned solid geometry')
        check(near(e.collisionMaxs.z,8*step) and e.collisionMins.z==0,'Production bowl collision tops rise monotonically in safe eight-unit steps')
        minimum=math.min(minimum,e.collisionMaxs.z);maximum=math.max(maximum,e.collisionMaxs.z)
    end
end
check(minimum==8 and maximum==32 and #registered==24,'Shallow bowl has actual raised rims around its unchanged lower center')
check(NB:ValidateRoutes(nc,{},0),'Actual graph still connects court entry and jail after bowl admission')
check(not NB:StaticRamp(nc,{pos=NB:Center(nc),steps=2}) and #nc.geometry==24,'Production geometry reservation rejects a twenty-fifth static surface atomically')
local geometry={};for _,e in ipairs(nc.geometry) do geometry[#geometry+1]=e end
NB:Cleanup(nc,'physical_geometry_test')
for _,e in ipairs(geometry) do check(not IsValid(e),'Retirement removes exact owned static bowl collision') end
local _,yard=G.setup(7)
check(#yard.data.yardRamps==2 and #yard.geometry==8,'Production Daryl Start creates eight actual loading-ramp collision boxes')
check(#NB:Objects(yard,'daryl_blast_barrier')==2 and #NB:Objects(yard,'daryl_barrel_rack')==2,'Production Daryl admits native blast barrier and rack objects')
for _,o in ipairs(NB:Objects(yard,'daryl_blast_barrier')) do
    check(o.ent.actualSolid==SOLID_BBOX and o.ent.collisionMaxs.z==65 and o.ent.collisionMins.z==-65,'Blast barrier has real opaque-height native collision bounds')
end
for _,ramp in ipairs(yard.data.yardRamps) do
    for _,o in ipairs(yard.data.yardObjects) do
        if o.spec.solid then
            local x=math.abs(ramp.pos.x-o.pos.x)
            local y=math.abs(ramp.pos.y-o.pos.y)
            check(x>ramp.length*.5+o.spec.radius or y>ramp.width*.5+o.spec.radius,'Powder Yard ramp footprint does not intersect permanent solid cover/rack')
        end
    end
end
local oldRoutes=NB.ValidateRoutes
local _,blocked=G.setup(3,false);NB.ValidateRoutes=function() return false end
check(NB:Prepare() and NB:Commit(G.R.State.Boss),'No-room bowl still admits ordinary boss progression')
blocked=G.R.State.Boss
check(#blocked.data.bowlRamps==0 and not next(blocked.geometry or {}),'Actual denied route validation emits no misleading partial bowl geometry')
NB.ValidateRoutes=oldRoutes
NB:Cleanup(blocked,'physical_test_done')
local _,sc=G.setup(8)
sc.data.nextAttack,sc.data.nextSwipe=G.clock+100,G.clock+100
for _,point in ipairs(sc.points) do
    sc.def:SectionalSplit(sc,point)
    if sc.pending.sofa_split then break end
end
G.step(1.11,.05)
local nativeChaise=assert(sc.data.section,'production chaise missing')
local damageCalls,oldDamage=0,NB.Damage
NB.Damage=function(self,owner,target,spec,source)
    if spec==nativeChaise.spec.damage and target==G.p then damageCalls=damageCalls+1 end
    return oldDamage(self,owner,target,spec,source)
end
util.TraceHull=function(t)
    return {Hit=true,HitWorld=false,HitPos=G.p:GetPos(),HitNormal=Vector(-1,0,0),Fraction=.5,Entity=G.p}
end
NB:ServiceObjects(sc,G.clock+.01,.01)
check(damageCalls==1 and nativeChaise.state=='WAITING TO RECONNECT','Actual production chaise trace reaches canonical Hero damage instead of being consumed by onImpact')
NB:ServiceObjects(sc,G.clock+.02,.01)
check(damageCalls==1,'Settled production chaise does not repeatedly damage the same Hero')
NB.Damage=oldDamage;util.TraceHull=G.clearTrace;NB:Cleanup(sc,'chaise_trace_done')
local _,empty=G.setup(3,false);assert(NB:Prepare());empty=G.R.State.Boss
local originalCreate=ents.Create;local count=0;local partial={}
ents.Create=function(class)
    if class=='lod_static_box' then
        count=count+1;if count==3 then return NULL end
        local e=originalCreate(class);partial[#partial+1]=e;return e
    end
    return originalCreate(class)
end
local rejected=NB:StaticRamp(empty,{pos=NB:Center(empty),width=120,length=160,height=32,steps=4})
ents.Create=originalCreate
check(not rejected and #(empty.geometry or {})==0 and #partial==2 and not IsValid(partial[1]) and not IsValid(partial[2]),'Production partial static-box allocation failure removes earlier boxes without registering partial geometry')
check(not NB:StaticRamp(empty,{pos=NB:Center(empty)+Vector(5000,0,0),steps=4}),'Production static geometry rejects footprints outside the exact court')
NB:Cleanup(empty,'geometry_failure_done')
check(G.errors()=='','No hidden module or native collision errors in physical geometry integration')
print('PASS physical boss behavior plus production geometry: '..n..' assertions; Source engine boundary emulated, native gameplay acceptance still pending')
