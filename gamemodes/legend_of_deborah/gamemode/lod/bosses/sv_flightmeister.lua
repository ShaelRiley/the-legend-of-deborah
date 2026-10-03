-- Dungeon 16: authored bounded flight grammar; no unrestricted stock NPC wandering.
local B=LOD.BossEncounter
local D={name='The Flightmeister',model='models/gunship.mdl',baseHP=2200,speed=250,size=1,airborne=true,
 hull={mins=Vector(-95,-95,-42),maxs=Vector(95,95,86)},combatBounds={mins=Vector(-190,-175,-78),maxs=Vector(190,175,120)},
 maxObjects=22,maxAdds=0,pushScale=0,phaseNames={'Air Patrol','No-Fly Zone','ENGINE FAILURE'},
 arena={theme='airfield',width=7,depth=7,upper=true,sky=true},deathCaption='AIRSPACE SECURED',keyLocation='center',deathDuration=6,
 presentation={body='combine_gunship',motion='authored_air',damagedPhase=3}}
local function copy(p) return Vector(p.x,p.y,p.z) end
local function unit(v) return v:LengthSqr()>1 and v:GetNormalized() or Vector(1,0,0) end
local function action(c,s) c.data.action=s;c.actor:SetNW2String('LOD_BossAction',s);c.actor:SetNW2Float('LOD_BossActionAt',c.now) end
local function expose(c,seconds,label)
 c.data.exposedUntil=c.now+seconds;c.actor:SetNW2Float('LOD_BossExposedUntil',c.data.exposedUntil)
 B:Warn(c,label or 'UNDERSIDE / ENGINE EXPOSED',c.actor:GetPos(),seconds,65)
end
local function solidPositions(c,p)
 local a={p};for _,o in ipairs(B:Objects(c)) do if o.spec.solid then a[#a+1]=o.pos end end;return a
end
function D:Start(c)
 local ctr=B:Center(c);local lo,hi=copy(ctr),copy(ctr)
 for _,p in ipairs(c.points) do if math.abs(p.z-ctr.z)<40 then lo.x=math.min(lo.x,p.x);lo.y=math.min(lo.y,p.y);hi.x=math.max(hi.x,p.x);hi.y=math.max(hi.y,p.y) end end
 local x1,x2=lo.x+(hi.x-lo.x)*.18,hi.x-(hi.x-lo.x)*.18
 local y1,y2=lo.y+(hi.y-lo.y)*.18,hi.y-(hi.y-lo.y)*.18
 c.data.height=math.min(440,c.arena.flightHeight or 400);c.data.lowHeight=math.max(180,c.data.height*.58)
 c.data.nodes={Vector(x1,y1,ctr.z),Vector((x1+x2)/2,y1,ctr.z),Vector(x2,y1,ctr.z),Vector(x2,(y1+y2)/2,ctr.z),
  Vector(x2,y2,ctr.z),Vector((x1+x2)/2,y2,ctr.z),Vector(x1,y2,ctr.z),Vector(x1,(y1+y2)/2,ctr.z)}
 c.data.lanes={};for i=1,3 do local y=lo.y+(hi.y-lo.y)*i/4;c.data.lanes[i]={a=Vector(x1,y,ctr.z),b=Vector(x2,y,ctr.z)} end
 c.data.cycle=0;c.data.route=1;c.data.nextAttack=c.now+3;c.data.engineDamage=0;c.data.beaconReady=0;c.data.heavyCount=0
 c.data.cover={};c.data.beacons={}
 for i=1,4 do local p=B:Floor(c,Vector(i%2==0 and x2-80 or x1+80,i<=2 and y1+135 or y2-135,ctr.z))
  if p and B:ValidateRoutes(c,solidPositions(c,p),90) then
   local o=B:Object(c,{kind='flight_hard_cover',model='models/props_wasteland/rockgranite03b.mdl',pos=p,
    hp=0,solid=true,permanent=true,scale=1.35,radius=85,label='PERMANENT HARD COVER / DIVE STRUCTURE'})
   if o then c.data.cover[#c.data.cover+1]=o end
  end
 end
 for i=1,2 do
  local p=B:Floor(c,Vector(ctr.x,ctr.y+(i==1 and -210 or 210),ctr.z))
  if p and B:ValidateRoutes(c,solidPositions(c,p),55) then B:Object(c,{kind='flight_expendable',model='models/props_junk/wood_crate002a.mdl',
   pos=p,hp=75,solid=true,permanent=true,radius=50,label='EXPENDABLE COVER'}) end
  local lane=c.data.lanes[i==1 and 1 or 3];local q=B:SafePoint(c,lane.a+Vector(0,i==1 and -120 or 120,0))
  if q then local o=B:Object(c,{kind='flight_beacon',model='models/props_lab/reciever01a.mdl',pos=q,
   hp=0,permanent=true,use=true,hold=.3,label='TARGETING BEACON',useLabel='E: ATTRACT NEXT PASS / COOLDOWN 24s',
   onUse=function(owner,object,p)
    if not B:Hero(owner,p) or owner.now<owner.data.beaconReady then return end
    owner.data.beaconLane=i==1 and 1 or 3;owner.data.beaconReady=owner.now+24;object.state='PASS LOCKED'
    B:Announce(owner,'BEACON LOCK: NEXT PASS / EXPOSED BANK');B:Log(owner,'FLIGHT_BEACON',{lane=owner.data.beaconLane})
   end});if o then c.data.beacons[#c.data.beacons+1]=o end end
 end
 self:Maneuver(c,'WIDE ORBIT',{1,2,3},c.data.height,245,4)
end
function D:EnsureHardCover(c)
 local covers=B:Objects(c,'flight_hard_cover');if #covers>=2 then c.data.cover=covers;return true end
 -- A transient shared-budget rejection cannot leave an ordnance arena without its mandatory cover.
 if c.now<(c.data.retryCoverAt or 0) then return false end;c.data.retryCoverAt=c.now+2
 for _,candidate in ipairs(c.points) do
  if math.abs(candidate.z-B:Center(c).z)<40 and candidate:DistToSqr(B:Center(c))>260^2 then
   local clear=true;for _,o in ipairs(covers) do if o.pos:DistToSqr(candidate)<260^2 then clear=false end end
   local p=clear and B:SafePoint(c,candidate)
   if p and B:ValidateRoutes(c,solidPositions(c,p),90) then
    local o=B:Object(c,{kind='flight_hard_cover',model='models/props_wasteland/rockgranite03b.mdl',pos=p,
     hp=0,solid=true,permanent=true,scale=1.35,radius=85,label='PERMANENT HARD COVER / DIVE STRUCTURE'})
    if o then covers[#covers+1]=o end
   end
   if #covers>=2 then c.data.cover=covers;return true end
  end
 end
 B:Stop(c,c.actor);action(c,'HOLDING AIRSPACE / CLEARING COVER ROUTES');return false
end
function D:Maneuver(c,name,nodes,height,speed,recovery)
 c.data.flight={name=name,nodes=nodes,index=1,height=height,speed=speed,deadline=c.now+12,recovery=recovery or 0}
 action(c,name)
end
function D:ServiceFlight(c,now)
 local f=c.data.flight;if not f then return false end
 if now>f.deadline then
  B:Stop(c,c.actor);c.data.flight=nil;c.data.recoverUntil=now+2;expose(c,2,'FLIGHT REPOSITION RECOVERY');return false
 end
 local p=c.data.nodes[f.nodes[f.index]];if not p then c.data.flight=nil;return false end
 local reached=B:Move(c,c.actor,p+Vector(0,0,f.height),f.speed,{mode='air',height=f.height,turnRate=c.phase==3 and 1.3 or 2.3,stopDistance=80})
 if reached then
  f.index=f.index+1
  if f.index>#f.nodes then
   c.data.flight=nil;c.data.recoverUntil=now+f.recovery
   if f.recovery>0 then expose(c,f.recovery,'VULNERABLE BANK / RECOVERY') end
  end
 end
 return c.data.flight~=nil
end
function D:Cannon(c,from,destination,label,delay,width,damage)
 local a=B:Floor(c,from) or B:Center(c);local b=B:Floor(c,destination);if not b then return end
 a.z=b.z -- Aim at the chosen gallery/floor rather than granting permanent elevated immunity.
 B:Zone(c,{kind='flight_cannon',label=label,pos=a,finish=b,shape='lane',width=width or 80,delay=delay or .85,life=.18,interval=1,
  source=c.actor,damage={kind='bullet',damage=damage or 16,reference=18,origin=copy(from)}})
end
function D:Strafe(c,low)
 local laneID=c.data.beaconLane or ((c.data.cycle-1)%3+1);local beacon=c.data.beaconLane~=nil;c.data.beaconLane=nil
 local lane=c.data.lanes[laneID];local h=low and c.data.lowHeight or c.data.height
 action(c,low and 'LOW-ALTITUDE CANNON STRAFE' or 'CANNON STRAFE')
 B:Warn(c,beacon and 'BEACON PASS: THIS LANE / VULNERABLE BANK' or 'CANNON STRAFE LANE',lane.a,1.2,60,{shape='lane',finish=lane.b,width=120})
 local start=lane.a+Vector(0,0,h);local finish=lane.b+Vector(0,0,h)
 self:Maneuver(c,'STRAFE PASS',{1,3},h,low and 300 or 275,beacon and 4 or 1.5)
 expose(c,3.5,beacon and 'BEACON: EXPOSED ENGINE' or 'COMMITTED UNDERSIDE');c.data.nextAttack=c.now+5.8
 -- First reach the actual lane mouth. Cannon commitments then march with the physical pass.
 c.data.flight.custom={start,finish};c.data.flight.nodes={1,3};c.data.flight.lane=laneID
 c.data.flight.onPass=function(owner)
  local duration=(finish-start):Length()/(low and 300 or 275)
  for i=1,4 do local p=lane.a+(lane.b-lane.a)*(i/5)
   B:Later(owner,math.max(0,duration*i/5-.6),'flight_strafe_'..i,function(current) self:Cannon(current,start,p,'CANNON STRAFE '..i,.6,90,16) end)
  end
 end
end
function D:Hover(c,target)
 c.data.flight=nil;B:Stop(c,c.actor);action(c,'HOVER FIRE / EXPOSED ENGINE')
 c.data.recoverUntil=c.now+4
 expose(c,5,'HOVER FIRE: EXPOSED ENGINE');local origin=copy(c.actor:GetPos());local destination=copy(target)
 for i=1,3 do B:Later(c,(i-1)*.65,'flight_hover_'..i,function(owner)
  self:Cannon(owner,origin,destination+Vector(0,(i-2)*65,0),'HOVER SUPPRESSION '..i,1,70,13)
 end) end
 c.data.nextAttack=c.now+5.8
end
function D:Bombing(c)
 action(c,'BOMBING RUN: SEQUENTIAL LANES');local laneID=c.data.beaconLane or ((c.data.cycle-1)%3+1);local beacon=c.data.beaconLane~=nil;c.data.beaconLane=nil
 local lane=c.data.lanes[laneID]
 self:Maneuver(c,'BOMBING RUN',{7,5},c.data.height,255,beacon and 4 or 2.5)
 c.data.flight.custom={lane.a+Vector(0,0,c.data.height),lane.b+Vector(0,0,c.data.height)};c.data.flight.lane=laneID
 for i=1,5 do local p=lane.a+(lane.b-lane.a)*(i/6)
  B:Zone(c,{kind='flight_bomb',label='BOMB '..i..' / OTHER LANES SAFE',pos=p,radius=110,delay=1.6+i*.45,life=.18,interval=1,
   damage={kind='blast',damage=27,reference=18,push=190}})
 end
 B:Log(c,'FLIGHT_BOMBING',{lane=laneID,safeLanes=2});c.data.nextAttack=c.now+6
end
function D:Heavy(c,target)
 action(c,'HEAVY PROJECTILES');local origin=copy(c.actor:GetPos());local dest=copy(target)
 for i=1,2 do local p=dest+Vector(0,(i==1 and -70 or 70),0)
  B:Warn(c,'HEAVY PROJECTILE '..i,p,1.5+i*.35,105)
  B:Later(c,1+i*.35,'flight_heavy_'..i,function(owner)
   local delta=p-origin
   B:Projectile(owner,{kind='flight_heavy',model='models/Combine_Helicopter/helicopter_bomb01.mdl',pos=origin,
    velocity=delta/1.2+Vector(0,0,132),gravity=220,radius=18,mass=30,life=3.5,hp=20,bounces=0,
    breakOnImpact=true,explodeRadius=105,damage={kind='blast',damage=30,reference=18,push=170},label='HEAVY ORDNANCE'})
  end)
 end
 c.data.nextAttack=c.now+4.5
end
function D:CoverBreak(c)
 local o=B:Objects(c,'flight_expendable')[1]
 if not o then self:Bombing(c);return end
 action(c,'COVER BREAK / HARD COVER SURVIVES');local p=copy(o.pos)
 B:Warn(c,'EXPENDABLE COVER BREAK',p,2,125)
 B:Later(c,2,'flight_cover_break',function(owner)
  if o.retired then return end;B:Area(owner,p,125,{kind='blast',damage=23,reference=18,push=140});B:RemoveObject(owner,o,'authored_cover_break')
 end)
 c.data.nextAttack=c.now+4.2
end
function D:Crosswind(c)
 local laneID=c.data.beaconLane or ((c.data.cycle-1)%3+1);local beacon=c.data.beaconLane~=nil;c.data.beaconLane=nil
 local lane=c.data.lanes[laneID];action(c,'LOW PASS: CROSSWIND')
 self:Maneuver(c,'LOW CROSSWIND PASS',{1,3},c.data.lowHeight,300,beacon and 4 or 2)
 c.data.flight.custom={lane.a+Vector(0,0,c.data.lowHeight),lane.b+Vector(0,0,c.data.lowHeight)};c.data.flight.lane=laneID
 B:Zone(c,{kind='flight_crosswind',label='CROSSWIND / LOW PASS',pos=lane.a,finish=lane.b,shape='lane',width=200,
  delay=1.4,life=.3,interval=1,onTick=function(owner,z,targets)
   for _,p in ipairs(targets) do B:Push(owner,p,Vector(0,1,0),210) end
  end})
 c.data.nextAttack=c.now+4.7
end
function D:Dive(c,target)
 action(c,'DESPERATION DIVE');local beacon=c.data.beaconLane~=nil
 local destination=B:Floor(c,beacon and c.data.lanes[c.data.beaconLane].b or target);if not destination then return end;c.data.beaconLane=nil
 c.data.flight=nil;B:Stop(c,c.actor);c.data.diving=true;c.data.divingUntil=c.now+3.4+(destination+Vector(0,0,80)-c.actor:GetPos()):Length()/420
 B:Charge(c,c.actor,destination+Vector(0,0,80),{label='DESPERATION DIVE: BAIT HEAVY STRUCTURE',mode='air',height=80,
  warning=2.4,speed=420,width=130,recovery=3,damage={kind='melee',damage=35,reference=18,push=280},
  onFinish=function(owner,hit,p,tr)
   owner.data.diving=false;owner.data.divingUntil=nil
   if tr and tr.cancelled then owner.data.nextAttack=owner.now+1.4;return end
   local structure=false
   for _,o in ipairs(owner.data.cover) do if not o.retired and tr and tr.Entity==o.ent then structure=true;break end end
   local duration=structure and 5 or beacon and 4 or 2.5
   owner.data.recoverUntil=owner.now+duration;owner.data.diving=false;B:Stagger(owner,duration);expose(owner,duration,'DAMAGED BANK / ENGINE EXPOSED')
   action(owner,structure and 'HEAVY STRUCTURE COLLISION: MAJOR STAGGER' or 'DIVE RECOVERY')
  end})
 c.data.nextAttack=c.now+7
end
function D:Dogfight(c,target)
 action(c,'DOGFIGHT');B:Announce(c,'DOGFIGHT: STRAFE / CLIMB / BOMBS / HOVER / RETURN')
 self:Strafe(c,c.phase==3);c.data.dogfightUntil=c.now+16
 B:Later(c,3.2,'flight_dogfight_climb',function(o) self:Maneuver(o,'DOGFIGHT: CLIMB',{4,5},o.data.height,245,0) end)
 B:Later(c,5.5,'flight_dogfight_bombs',function(o) self:Bombing(o) end)
 B:Later(c,9.3,'flight_dogfight_hover',function(o) self:Hover(o,target) end)
 B:Later(c,12,'flight_dogfight_return',function(o) self:Maneuver(o,'DOGFIGHT: LOW RETURN',{7,8,1},o.data.lowHeight,260,5) end)
 B:Later(c,15,'flight_dogfight_recover',function(o)
  o.data.flight=nil;B:Stop(o,o.actor);o.data.recoverUntil=o.now+5;expose(o,5,'DOGFIGHT COMPLETE / LONG RECOVERY');o.data.nextAttack=o.now+5
 end)
 c.data.nextAttack=c.now+20
end
function D:Think(c,now,dt,targets)
 if c.data.diving and now>(c.data.divingUntil or now+1) then B:Stop(c,c.actor);c.data.diving=false;c.data.divingUntil=nil;c.data.nextAttack=now+1.4 end
 if not targets[1] or not self:EnsureHardCover(c) then return end
 if c.data.flight and c.data.flight.custom then
  local f=c.data.flight;local p=f.custom[f.index]
  if p then local reached=B:Move(c,c.actor,p,f.speed,{mode='air',height=f.height,turnRate=c.phase==3 and 1.3 or 2.3,stopDistance=70})
   if reached then f.index=f.index+1;if f.index==2 and f.onPass then f.onPass(c);f.onPass=nil end end
  end
  if not f.custom[f.index] or now>f.deadline then c.data.flight=nil;c.data.recoverUntil=now+f.recovery;expose(c,f.recovery,'VULNERABLE BANK') end
 else self:ServiceFlight(c,now) end
 if c.data.flight or c.data.diving or now<(c.data.recoverUntil or 0) or now<(c.data.dogfightUntil or 0) or now<c.data.nextAttack then return end
 c.data.cycle=c.data.cycle+1;local n=c.data.cycle;local target=copy(targets[(n-1)%#targets+1]:GetPos())
 local grammar=c.phase==1 and {'strafe','hover','orbit','strafe','suppression'} or c.phase==2 and {'bombs','heavy','crosswind','cover','hover','dogfight'}
  or {'low','dive','bombs','hover','dogfight','heavy'}
 local move=grammar[(n-1)%#grammar+1]
 if move=='strafe' or move=='low' then self:Strafe(c,move=='low')
 elseif move=='hover' or move=='suppression' then self:Hover(c,target)
 elseif move=='bombs' then self:Bombing(c)
 elseif move=='heavy' then self:Heavy(c,target)
 elseif move=='crosswind' then self:Crosswind(c)
 elseif move=='cover' then self:CoverBreak(c)
 elseif move=='dive' then self:Dive(c,target)
 elseif move=='dogfight' then self:Dogfight(c,target)
 else self:Maneuver(c,'WIDE ORBIT / RETREAT AND RETURN',{5,6,7,8,1},c.data.height,240,1.8);c.data.nextAttack=now+5 end
end
function D:BeforeDamage(c,actor,info)
 if actor~=c.actor then return end
 if c.now<(c.data.exposedUntil or 0) then local p=info:GetDamagePosition()
  if p and p.z<actor:GetPos().z+28 then info:ScaleDamage(1.18) end
 end
end
function D:AfterDamage(c,actor,amount,attacker,pos)
 if actor~=c.actor or c.now>=(c.data.exposedUntil or 0) or not pos or pos.z>actor:GetPos().z+28 then return end
 c.data.engineDamage=c.data.engineDamage+amount
 if c.data.engineDamage>=actor:GetMaxHealth()*.055 then
  c.data.engineDamage=0;if B:Stagger(c,2.6) then c.data.recoverUntil=c.now+2.6;action(c,'ENGINE STAGGER') end
 end
end
function D:Phase(c,phase)
 c.data.flight=nil;c.data.diving=false;c.data.divingUntil=nil;c.data.dogfightUntil=0;c.data.nextAttack=c.now+1.8;c.data.engineDamage=0
 c.actor:SetNW2Bool('LOD_BossEngineDamaged',phase==3)
end
function D:Pause(c) B:Stop(c,c.actor);c.data.flight=nil;c.data.diving=false;c.data.divingUntil=nil;c.data.dogfightUntil=0;c.data.nextAttack=c.now+2 end
function D:Retire(c) c.data.flight=nil end
function D:Snapshot(c) return (c.data.action or 'AIR PATROL')..(c.now<c.data.beaconReady and ' / BEACON COOLING' or ' / E: TARGETING BEACON') end
function D:Defeat(c)
 if IsValid(c.actor) then c.actor:SetNW2Bool('LOD_BossEngineDamaged',true) end
 c.data.action='ENGINE FAILURE / CONTROLLED CRASH';c.data.deathStage='spiral_crash'
 c.data.deathTarget=c.data.cover[1] and copy(c.data.cover[1].pos) or B:Center(c)
 B:Object(c,{kind='flight_crash_structure',model='models/props_wasteland/rockgranite03b.mdl',pos=c.data.deathTarget,
  cosmetic=true,life=6,scale=1.35,hp=0,label='DESIGNATED CRASH STRUCTURE'})
end
B:Register('flightmeister',D)
