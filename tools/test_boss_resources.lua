local F=dofile('tools/boss_resources_fixture.lua')
local B,check=F.B,F.check
local c=F.new('ollie');local D=c.def
check(#B:Objects(c,'ollie_loose')==6,'Ollie finite six-piece shopping stock')
check(#B:Objects(c,'ollie_corral')==2,'two designated cart corrals')
local pos=Vector(0,400,0)
for _,item in ipairs({'can','ball','melon','explosive','groceries','crabs','spring'}) do D:Launch(c,item,pos) end
check(#F.log(c,'ollie_purchase')==7,'all seven concrete catalog outcomes')
local objects=B:Objects(c,'ollie_purchase');local ball,can,spring,explosive,melon
for _,o in ipairs(objects) do
    if o.spec.label=='BOWLING BALL' then ball=o elseif o.spec.label=='SOUP CAN BARRAGE' then can=o elseif o.spec.label=='SPRING-LOADED PROP' then spring=o elseif o.spec.label=='EXPLOSIVE PURCHASE' then explosive=o elseif o.spec.label=='ANGRY MELON' then melon=o end
end
check(ball.spec.mass>can.spec.mass and ball.spec.push==nil and ball.spec.damage.push>can.spec.damage.push,'ball is heavier and pushes through native packet')
check(spring.velocity:Length()>can.velocity:Length(),'spring prop has distinct fast trajectory')
check(explosive.spec.fuse and explosive.spec.explodeRadius>melon.spec.explodeRadius,'separate explosive and melon splash')
check(#c.adds==2 and c.adds[1].options.manual==false,'Cart Crabs retain ordinary AI and bounded adds')
D:Launch(c,'crabs',pos);D:Launch(c,'crabs',pos);check(#c.adds==3,'Cart Crabs capped at three')
check(c.hazards[1].spec.kind=='ollie_groceries' and c.hazards[1].spec.life==5,'finite bad groceries hazard')
c=F.new('ollie');D=c.def;D:Pull(c,'explosive',pos)
local exposed=B:Objects(c,'ollie_exposed')[1];check(exposed~=nil,'selected purchases exposed in basket')
F.event(c,exposed,'destroy',F.damageInfo(20));F.advance(c,2)
check(#F.log(c,'ollie_purchase')==0 and #c.staggers==1 and c.actor.health<c.actor.maxHealth,'early shot cancels throw, stuns and backfires only once')
F.event(c,exposed,'destroy',F.damageInfo(20));check(#c.staggers==1,'exposed-item callback deduplicated')
c=F.new('ollie');D=c.def
check(D:Pull(c,'mystery',pos),'mystery starts');check(not D:Pull(c,'mystery',pos),'one high-intensity mystery at a time')
F.advance(c,6);check(#F.log(c,'ollie_purchase')==2,'Mystery Bag remixes two known outcomes')
c=F.new('ollie');D=c.def
local loose=B:Objects(c,'ollie_loose');B:RemoveObject(c,loose[1],'shot');B:RemoveObject(c,loose[2],'shot')
D:ShoppingSpree(c);c.moveReached=true
for i=1,3 do D:Think(c,c.now,.1,{c.hero}) end
local frozen=F.log(c,'ollie_spree_frozen')[1]
check(frozen.data.count==4 and #B:Objects(c,'ollie_loose')==0,'pre-spree shooting reduces frozen inventory from six to four')
F.advance(c,10);check(#F.log(c,'ollie_purchase')==4,'frozen shopping set disgorges sequentially')
D:Crash(c,c.data.corrals[1]);c.charges[#c.charges].spec.onFinish(c,true,c.data.corrals[1])
check(c.data.recovery==c.now+4 and c.data.action=='CART CORRAL: STUCK','corral collision grants major stagger')
c=F.new('ollie');B:SetPhase(c,3);F.advance(c,3);c.def:Think(c,c.now,.1,{c.hero});check(c.data.priceTarget~=nil or #c.moves>0 or c.data.action~=nil,'phase-three authored controller services')

c=F.new('crystal_bepis');D=c.def
check(c.data.stock==4 and c.data.machine.spec.hold==1.5,'finite vending stock and real hold interaction')
F.event(c,c.data.machine,'use',c.hero);F.event(c,c.data.machine,'use',c.hero);check(c.data.jammed,'jam cannot stack')
D:StartRun(c);D:EndRun(c,true)
check(not c.data.jammed and c.data.stock==4 and c.healed==0 and c.data.furiousUntil>c.now,'one jam consumes exactly one attempt without healing')
local info=F.damageInfo(100);D:BeforeDamage(c,c.actor,info);check(info.amount==120,'jammed furious exposure is modest bonus')
c.actor.health=100
for i=1,4 do D:StartRun(c);D:EndRun(c,true) end
check(c.data.stock==0 and not D:StartRun(c) and c.healed==c.actor.maxHealth*.36,'four drinks bound total possible healing and prevent stalemate')
F.event(c,c.data.machine,'use',c.hero);check(not c.data.jammed,'sold-out machine cannot be jammed')
c=F.new('crystal_bepis');D=c.def;D:StartRun(c)
D:AfterDamage(c,c.actor,1);check(c.data.run~=nil,'one trivial hit does not interrupt vending run')
D:AfterDamage(c,c.actor,30);D:AfterDamage(c,c.actor,35);check(c.data.run==nil and c.data.stock==4,'focused burst interrupts without spending stock')
D:StartRun(c);c.moveBlocked=true;D:Think(c,c.now,2.1,{c.hero});check(c.data.run==nil,'route/control denial ends vending run')
B:SetPhase(c,3);c.actor.health=100;D:StartRun(c,true);D:EndRun(c,true)
check(c.data.stock==3 and c.healed==50 and c.data.buffUntil==c.now+7,'DIET CRYSTAL heals less and has finite nonstacking buff')
check(#c.hazards>0 and c.hazards[1].spec.label:find('CRYSTAL CLEAR',1,true),'CRYSTAL CLEAR commits marked poison positions while running')
for _,name in ipairs({'BEPIS TOSS','SHAKEN CAN','FASTBALL','SODA POP','SIX-PACK','SODA FOUNTAIN','CAN SKIP'}) do D:Attack(c,pos,name);F.advance(c,2) end
for _,o in ipairs(B:Objects(c,'bepis_can')) do check(o.spec.damage.kind=='venom','every soda projectile uses canonical Poisoned packet') end
for _,z in ipairs(c.hazards) do check(z.spec.damage.kind=='venom','every soda spray uses canonical Poisoned packet') end
check(#c.areas>0 and c.areas[1].spec.push==180,'Soda Pop is Poison/Push')
local returnPos=D:KeyPosition(c);check(returnPos:DistToSqr(c.data.machinePos)==80^2,'key uses safely reachable vending-return exception')
D:Pause(c);check(c.data.stock==3 and c.data.run==nil,'pause retains finite drink receipt')

c=F.new('ray');D=c.def
check(#c.data.valves==2,'two optional relief valves')
local valve=c.data.valves[1]
local near=D:HeatZone(c,valve.pos,'test hot',60,0,5)
D:StartVent(c);local ending=c.data.ventEnd
F.event(c,valve,'use',c.hero)
check(near==nil or near.retired,'relief valve clears local heat')
check(c.data.ventEnd==ending-1.5 and c.data.coolBonus==1.5,'relief shortens dangerous vent and extends cooled window')
F.event(c,valve,'use',c.hero);check(c.data.ventEnd==ending-1.5,'valve cooldown rejects repeat use')
F.advance(c,3);D:Think(c,c.now,.1,{c.hero});check(c.data.mode=='VENTING','warning transitions to actual vent')
F.advance(c,3);D:Think(c,c.now,.1,{c.hero});check(c.data.mode=='COOLED' and c.data.coolEnd==c.now+8.5,'emergency vent leads to enlarged cooled window')
info=F.damageInfo(100);D:BeforeDamage(c,c.actor,info);check(info.amount==130,'cooled damage bonus')
D:Think(c,c.now,.1,{c.hero});check(c.moves[#c.moves].speed==55,'cooled radiator visibly slower')
for _,z in ipairs(c.data.ventZones) do check(z.retired,'vent zones retire before cooled punish window') end
F.advance(c,9);D:Think(c,c.now,.1,{c.hero});check(c.data.mode=='HEATING','cooled window ends and heating resumes')
check(D:PipeDown(c),'PIPE DOWN enters authored sequence');F.advance(c,6)
check(c.data.mode=='PIPE DOWN' and #c.hazards>1,'perimeter-inward steam waves emitted')
F.advance(c,1);D:Think(c,c.now,.1,{c.hero});check(c.data.mode=='VENT WARNING' and c.data.majorVent,'PIPE DOWN ends in full major vent')
c=F.new('ray');D=c.def
for _,name in ipairs({'STEAM JET','HOT PIPE','RADIATOR RAM','HEATED FLOOR','DETACHED PIPE','BURST MAIN','PIPE SWEEP','PIPE BOMBARDMENT','PRESSURE HOP'}) do D:Attack(c,pos,name) end
c.charges[1].spec.onFinish(c,false);c.data.recoverUntil=0
F.advance(c,1.4);check(#B:Objects(c,'ray_pipe')==4,'single detached pipe and finite three-pipe bombardment')
check(c.data.hop~=nil,'Pressure Hop uses explicit staged move')
F.advance(c,1.1);D:Think(c,c.now,.1,{c.hero})
local hop=c.charges[#c.charges];check(c.data.hop~=nil and hop.spec.arc==95 and hop.spec.minimumDuration==1.3,'Pressure Hop awaits its actual warned native arc landing')
hop.spec.onFinish(c,false,hop.pos)
check(c.data.hop==nil and #c.areas>=2,'Pressure Hop impact settles only after the real committed motion callback')
D:Attack(c,pos,'PRESSURE HOP');local cancelled=c.charges[#c.charges];local areaBefore=#c.areas
cancelled.spec.onFinish(c,false,cancelled.pos,{cancelled=true})
check(c.data.hop==nil and #c.areas==areaBefore,'Cancelled Pressure Hop clears state without remote impact damage')
c.charges[1].spec.onFinish(c,false);check(c.staggers[#c.staggers]==2.8,'missed radiator ram offers recovery')
for _,o in ipairs(B:Objects(c,'ray_pipe')) do check(o.spec.damage.kind=='flame' and o.spec.life==4,'pipes have finite shared Fire packets') end
B:SetPhase(c,3);c.data.recoverUntil=0;c.data.pressure=0;c.data.nextAttack=c.now+99;D:Think(c,c.now,1,{c.hero});check(c.data.pressure==8,'REDLINE pressure builds faster')
D:Pause(c);check(c.data.hop==nil,'pause discards transient hop')

c=F.new('moshi');D=c.def
check(c.data.cycle=='Fill' and #c.data.drains==3,'Moshi starts visible Fill cycle with optional drains')
check(#c.data.reinforced==2 and c.routeChecks==4,'reinforced Spin-Out geometry route-validated')
for _,z in ipairs(c.hazards) do check(z.spec.traction==.72 and z.spec.damage==nil,'ordinary water changes bounded traction without hidden damage') end
local drain=c.data.drains[1];D:WetZone(c,drain.pos,false)
F.event(c,drain,'use',c.hero);check(drain.cleared,'E clears jammed drain')
local count=#c.hazards;D:WetZone(c,drain.pos,true);check(#c.hazards==count,'clear drain suppresses future local water/suds')
F.event(c,c.data.drains[2],'destroy',F.damageInfo(30));check(c.data.drains[2].cleared,'shooting also clears drain')
D:NextCycle(c,c.hero);check(c.data.cycle=='Wash','Fill -> Wash')
D:NextCycle(c,c.hero);check(c.data.cycle=='Spin' and #c.charges==1 and c.charges[1].spec.lateralArc==0,'Wash -> straight phase-one Spin Charge')
c.charges[1].spec.onFinish(c,false,pos);check(c.data.recoverUntil==c.now+2.8,'missed spin produces skid/wobble punish')
D:NextCycle(c,c.hero);check(c.data.cycle=='Drain','Spin -> Drain')
for _,z in ipairs(c.hazards) do if z.spec.kind=='moshi_wet' then check(z.retired,'Drain removes lingering traction zones') end end
D:NextCycle(c,c.hero);check(c.data.cycle=='Fill' and c.data.round==2,'Drain -> Fill repeats')
c=F.new('moshi');D=c.def;B:SetPhase(c,2);D:WetZone(c,Vector(-350,0,0),true)
check(c.hazards[#c.hazards].spec.traction==.48,'Heavy Load suds are slipperier than water')
for _,class in ipairs({'light','medium','heavy'}) do D:Eject(c,pos,class) end
F.advance(c,2)
local loads=B:Objects(c,'moshi_debris');check(#loads==3,'all three differentiated debris classes are real projectiles')
check(loads[1].spec.mass<loads[2].spec.mass and loads[2].spec.mass<loads[3].spec.mass,'debris classes have distinct bounded mass')
check(loads[1].spec.damage.damage<loads[3].spec.damage.damage and loads[3].spec.bounces==1,'heavy load has meaningful impact and bounce distinction')
D:SpinCharge(c,pos);local charge=c.charges[#c.charges];check(math.abs(charge.spec.lateralArc)==55,'off-balance spin uses frozen slight curvature')
charge.spec.onFinish(c,false,c.data.reinforced[1],{Hit=true});check(c.data.recoverUntil==c.now+4.5,'reinforced collision triggers major Spin-Out')
info=F.damageInfo(100,c.actor:GetPos()+Vector(34,0,48));D:BeforeDamage(c,c.actor,info);check(info.amount==120,'open front drum is modest optional weak point')
info=F.damageInfo(100,Vector(-300,0,0));D:BeforeDamage(c,c.actor,info);check(info.amount==100,'drum weak point respects hit location')
B:SetPhase(c,3);D:LostSock(c,c.hero)
local sock=B:Objects(c,'moshi_sock')[1];check(sock and sock.spec.damage==nil,'THE LOST SOCK is harmless')
local oldCharges=#c.charges;F.advance(c,1.15);check(#c.charges==oldCharges+1 and c.charges[#c.charges].spec.speed==680,'sock pause resolves to massive off-angle charge')
check(c.charges[#c.charges].pos:DistToSqr(c.hero:GetPos())==100^2,'lost-sock charge offset is committed, not target homing')
D:ViolentSpin(c);F.advance(c,.8);check(#c.data.orbits==3,'Violent Spin has exactly three finite orbiting debris')
D:Think(c,c.now,.1,{c.hero});for _,o in ipairs(c.data.orbits) do check(o.velocity:Length()<=360.001,'orbit velocity bounded') end
D:Rinse(c);local rinse
for _,z in ipairs(c.hazards) do if z.spec.kind=='moshi_rinse' then rinse=z;check(z.spec.damage==nil,'rinse only modest displacement') end end
check(rinse~=nil,'RINSE CYCLE directional bands are present')
rinse.spec.onTick(c,rinse,{c.hero});check(c.pushes[#c.pushes].strength==105,'rinse pushes through canonical displacement')
D:Pause(c);check(c.data.drains[1].cleared==nil and #c.data.orbits==0 and c.data.cycle=='Drain','pause removes transient debris/traction and retains drain records')

for _,id in ipairs({'ollie','crystal_bepis','ray','moshi'}) do
    c=F.new(id,{denyObjects=true});check(type(c.def:Snapshot(c))=='string',id..' survives exhausted object admission')
    c=F.new(id);c.def:Defeat(c);c.dead=true;local counts=#c.areas+#c.charges
    F.advance(c,4);check(#c.areas+#c.charges==counts,id..' cosmetic death callbacks never attack')
    for _,o in ipairs(c.objects) do if o.spec.cosmetic then check(not o.spec.damage and not o.spec.use and not o.spec.solid,id..' death props harmless') end end
    c=F.new(id);B:Later(c,1,'old_test',function(owner) owner.badStale=true end);c.retired=true;F.advance(c,2)
    check(not c.badStale,id..' rejects stale exact-owner callbacks')
end
print('PASS boss resource modules: '..F.checks..' substantive assertions; native traces, status authority and presentation remain runtime gates')
-- Exercise repeated real module scheduling, rather than only invoking named attacks.
for _,id in ipairs({'ollie','crystal_bepis','ray','moshi'}) do
    for phase=1,3 do
        local sim=F.new(id,{moveReached=true})
        if phase>1 then B:SetPhase(sim,phase) end
        local finishQueue={};local known=0
        for tick=1,360 do
            F.advance(sim,.25)
            for _,q in ipairs(finishQueue) do
                if not q.done and sim.now>=q.at then
                    q.done=true;sim.actor:SetPos(q.charge.pos)
                    if q.charge.spec.onFinish then q.charge.spec.onFinish(sim,false,q.charge.pos) end
                end
            end
            sim.def:Think(sim,sim.now,.25,{sim.hero})
            for n=known+1,#sim.charges do
                local charge=sim.charges[n]
                finishQueue[#finishQueue+1]={charge=charge,at=sim.now+charge.spec.warning+1}
            end
            known=#sim.charges
        end
        check(type(sim.def:Snapshot(sim))=='string',id..' phase '..phase..' remains coherent through 90-second service loop')
        check(#sim.logs+#sim.charges+#sim.hazards+#sim.areas>0,id..' phase '..phase..' produces authored behavior')
    end
end
-- Spatial anchors must not inherit mixed-floor lexical point clustering.
c=F.new('ray');check(c.data.sectors[1]:DistToSqr(c.data.sectors[5])>500^2,'opposite authored sectors spread around ground court')
-- Re-entering after no-Hero pause preserves uncommitted frozen shopping purchases.
c=F.new('ollie');D=c.def;D:ShoppingSpree(c);c.moveReached=true
for i=1,3 do D:Think(c,c.now,.1,{c.hero}) end
F.advance(c,1.2);local purchases=#F.log(c,'ollie_purchase')
for key in pairs(c.pending) do c.pending[key]=nil end
D:Pause(c);check(c.data.spree and #c.data.spree.collected==5,'five uncommitted purchases persist after first one was thrown')
D:Think(c,c.now,.1,{c.hero});F.advance(c,12)
check(#F.log(c,'ollie_purchase')==purchases+5,'retained shopping inventory retelegraphs once after resumption')
c=F.new('ollie');D=c.def;c.phase=2;c.data.nextPrice=c.now;c.data.nextSpree=c.now+99
D:Think(c,c.now,.1,{c.hero});check(c.data.priceTarget~=nil,'Price Check captures an exact target life')
c.hero.spawn=c.hero.spawn+1;local before=#c.charges
D:Think(c,c.now,.1,{c.hero});check(#c.charges==before and c.data.priceTarget==nil,'Price Check cannot reacquire a replacement Hero body')
print('PASS boss resource soak and retention: '..F.checks..' total assertions')
-- Actual drainage layout requests, real support geometry and dry-space contracts.
c=F.new('moshi');D=c.def
check(#c.geometry==16 and #c.data.dryPlatforms==2,'two raised dry islands use sixteen bounded static support boxes')
check(#B:Objects(c,'moshi_central_grate')==1 and #B:Objects(c,'moshi_channel')==3,'central drainage grate connects three visible nonblocking channels')
check(#B:Objects(c,'moshi_dry_platform')==2,'raised dry landing surfaces have owned readable markers')
for _,platform in ipairs(c.data.dryPlatforms) do
    check(platform.height==24 and platform.width==200 and platform.length==256,'dry platform has authored shallow footprint')
    check(platform.west.spec.yaw==0 and platform.east.spec.yaw==180,'opposed walk-up approaches preserve baseline traversal')
    for _,ramp in ipairs({platform.west,platform.east}) do
        check(ramp.steps==4 and ramp.height/ramp.steps==6,'four six-unit step rises need no special jump or movement ability')
        check(ramp.length==128 and ramp.width==200 and #ramp.entities==4,'each dry approach has four real static support sections')
    end
    local count=#c.hazards
    D:WetZone(c,platform.pos,false);D:WetZone(c,platform.pos,true)
    check(#c.hazards==count,'both ordinary water and stronger suds exclude dry platforms')
end
check(c.data.dry:DistToSqr(c.data.dryPlatforms[1].pos)==0,'advertised guaranteed dry space is an actual raised platform')
for i,channel in ipairs(B:Objects(c,'moshi_channel')) do
    check(not channel.spec.solid and not channel.spec.damage and not channel.spec.use,'drainage strip cannot block routes or add hidden damage')
    check(channel.channelFrom.x==0 and channel.channelFrom.y==0,'each channel visibly starts at central drain')
    check(channel.channelTo.x==c.data.drains[i].drainPos.x and channel.channelTo.y==c.data.drains[i].drainPos.y,'each channel visibly ends at its optional jammed cover')
end
local geometry=c.geometry
F.event(c,c.data.drains[1],'use',c.hero);D:Pause(c)
check(c.geometry==geometry and #geometry==16 and c.data.drains[1].cleared,'pause and optional drain clearing retain physical walkable dry platforms')
c=F.new('moshi',{routesValid=false});check(#c.data.dryPlatforms==0 and #(c.geometry or {})==0,'failed route validation admits no new raised support geometry')
local existing={};for i=1,20 do existing[i]={} end
c=F.new('moshi',{geometry=existing});check(#c.geometry==20 and #c.data.dryPlatforms==0,'geometry ceiling refuses incomplete two-sided platform admission')

-- Render ownership is per known object; the modules allocate no models or scans.
LOD.BossPresentation={Modules={}}
local draws={boxes=0,quads=0,lines=0}
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
render={SetColorMaterial=function()end,DrawBox=function()draws.boxes=draws.boxes+1 end,
    DrawQuad=function()draws.quads=draws.quads+1 end,DrawLine=function()draws.lines=draws.lines+1 end}
local entmeta=getmetatable(F.entity())
function entmeta:GetNW2String(key,default) return self.nw[key] or default end
function entmeta:GetNW2Vector(key,default) return self.nw[key] or default end
function entmeta:SetRenderBounds(lo,hi) self.renderBounds={lo,hi} end
dofile('gamemodes/legend_of_deborah/gamemode/lod/bosses/cl_moshi.lua')
local M=LOD.BossPresentation.Modules.moshi
c=F.new('moshi')
for _,o in ipairs(c.objects) do o.ent:SetNW2String('LOD_BossObjectKind',o.spec.kind);M:DrawObject(o.ent,1,{}) end
check(draws.quads==3 and draws.lines==24,'three drainage strips render bounded grating and directed channel shapes')
check(draws.boxes>=45,'central grate, jammed covers and dry landings render distinct physical cues')
for _,o in ipairs(B:Objects(c,'moshi_channel')) do check(o.ent.renderBounds~=nil,'long channel custom bounds prevent tiny-model culling') end
print('PASS boss resources plus drainage geometry: '..F.checks..' total assertions')
-- Load the actual shared StaticRamp and native lod_static_box implementation.
-- Only engine services are doubles here, not the boss geometry construction.
local native=dofile('tools/boss_framework_fixture.lua')
local nativeState,nativeMoshi=native.setup(13)
check(#nativeMoshi.data.dryPlatforms==2 and #nativeMoshi.geometry==16,'actual production Moshi admits two complete supported dry platforms')
local nativeGeometry={}
for _,e in ipairs(nativeMoshi.geometry) do
    nativeGeometry[#nativeGeometry+1]=e
    check(e:GetClass()=='lod_static_box' and e:IsLODCollisionReady() and e.solid==SOLID_BBOX,'real static-box initializer establishes authoritative solid support')
    local lo,hi=e:GetCollisionBounds()
    check(lo.z==0 and hi.z>=6 and hi.z<=24 and hi.z%6==0,'actual platform collisions have six-unit stepped elevations')
    check(e.LODBossGeometry==nativeMoshi,'every static platform section is exactly encounter-owned')
end
check(#native.B:Objects(nativeMoshi,'moshi_channel')==3,'production drainage strips are actual owned entities')
for _,o in ipairs(native.B:Objects(nativeMoshi,'moshi_channel')) do
    check(o.ent.solid==SOLID_NONE and o.ent:GetNW2String('LOD_BossObjectKind')=='moshi_channel','actual drainage channel cannot block a baseline Hero')
end
native.B:Quiesce(nativeMoshi,'geometry_regression_pause')
check(#nativeMoshi.geometry==16 and IsValid(nativeGeometry[1]),'physical dry supports persist through no-Hero pause')
native.B:Cleanup(nativeMoshi,'geometry_regression_cleanup')
for _,e in ipairs(nativeGeometry) do check(not IsValid(e),'exact owner cleanup retires every static dry-platform section') end
print('PASS boss resources with production drainage support: '..F.checks..' total assertions')
