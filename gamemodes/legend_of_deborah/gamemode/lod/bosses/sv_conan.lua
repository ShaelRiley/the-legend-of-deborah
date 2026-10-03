-- Dungeon 17: validated roadwork formations and a short exact-life CONED trap.
local B=LOD.BossEncounter
local D={name='Conan the Cone',model='models/props_junk/TrafficCone001a.mdl',baseHP=2050,speed=145,size=6.8,
 hull={mins=Vector(-62,-62,0),maxs=Vector(62,62,180)},combatBounds={mins=Vector(-80,-80,0),maxs=Vector(80,80,255)},
 maxObjects=40,maxAdds=0,pushScale=.08,phaseNames={'Merge Left','Detour','UNDER CONSTRUCTION'},
 arena={theme='roadwork',width=7,depth=7,upper=true},deathCaption='ROAD OPEN',keyLocation='center',deathDuration=5,
 presentation={body='traffic_cone',lanes=4,trapCaption='YOU HAVE BEEN CONED'}}
local model=D.model
local function copy(p) return Vector(p.x,p.y,p.z) end
local function action(c,s) c.data.action=s;c.actor:SetNW2String('LOD_BossAction',s);c.actor:SetNW2Float('LOD_BossActionAt',c.now) end
local function allPositions(c,more)
 local out={};for _,o in ipairs(B:Objects(c)) do if o.spec.solid then out[#out+1]=o.pos end end
 for _,p in ipairs(more or {}) do out[#out+1]=p end;return out
end
local shapes={
 funnel={{-2,-2},{-2,2},{-1,-1.5},{-1,1.5},{0,-1},{0,1}},
 zigzag={{-2,-1},{-1,1},{0,-1},{1,1},{2,-1}},
 partial_ring={{-1.5,0},{-1,-1},{0,-1.5},{1,-1},{1.5,0}},
 lane_divider={{-2,0},{-1,0},{0,0},{1,0},{2,0}},
 chicane={{-2,-1.5},{-2,-.5},{0,.5},{0,1.5},{2,-1.5},{2,-.5}}}
local order={'funnel','zigzag','partial_ring','lane_divider','chicane'}
function D:BuildRoadwork(c)
 -- These are actual bounded encounter-owned models, not a theme-name or client-only drawing.
 c.data.roadwork={}
 local lo,hi=c.data.lo,c.data.hi
 for _,y in ipairs({lo.y,hi.y}) do for i=1,4 do
  local p=B:Floor(c,Vector(lo.x+(hi.x-lo.x)*(i-.5)/4,y,lo.z))
  if p then local o=B:Object(c,{kind='conan_curb',model='models/props_c17/concrete_barrier001a.mdl',pos=p,
   scale=.35,cosmetic=true,permanent=true,hp=0,label='LOW ROADWORK CURB / ROUTE GAP'})
   if o then c.data.roadwork[#c.data.roadwork+1]=o end
  end
 end end
 for _,x in ipairs({lo.x+80,hi.x-80}) do
  for _,y in ipairs({lo.y,hi.y}) do
   local p=B:Floor(c,Vector(x,y,lo.z))
   if p then
    local model='models/props_c17/utilitypole01a.mdl'
    local a,b;if util and util.GetModelBounds then a,b=util.GetModelBounds(model) end
    a,b=a or Vector(0,0,0),b or Vector(20,20,330)
    local scale=math.max(.05,math.min(8,330/math.max(1,b.z-a.z)))
    local o=B:Object(c,{kind='conan_gantry_post',model=model,pos=p-Vector(0,0,a.z*scale),scale=scale,
     cosmetic=true,permanent=true,hp=0,label='CONSTRUCTION GANTRY POST'})
    if o then c.data.roadwork[#c.data.roadwork+1]=o end
   end
  end
  local model='models/props_debris/wood_board07a.mdl';local a,b
  if util and util.GetModelBounds then a,b=util.GetModelBounds(model) end
  a,b=a or Vector(-250,-8,-8),b or Vector(250,8,8)
  local spans=b-a;local length=math.max(spans.x,spans.y,spans.z)
  local scale=math.max(.05,math.min(8,(hi.y-lo.y)/math.max(1,length)))
  local angle=spans.x>=spans.y and spans.x>=spans.z and Angle(0,90,0) or spans.y>=spans.z and Angle() or Angle(0,0,90)
  local o=B:Object(c,{kind='conan_gantry_beam',model=model,pos=Vector(x,(lo.y+hi.y)*.5,lo.z+330),scale=scale,
   cosmetic=true,permanent=true,hp=0,label='CONSTRUCTION GANTRY CROSSBEAM'})
  if o then o.ent:SetAngles(angle);c.data.roadwork[#c.data.roadwork+1]=o end
 end
end
function D:Start(c)
 local ctr=B:Center(c);local lo,hi=copy(ctr),copy(ctr)
 for _,p in ipairs(c.points) do if math.abs(p.z-ctr.z)<40 then lo.x=math.min(lo.x,p.x);lo.y=math.min(lo.y,p.y);hi.x=math.max(hi.x,p.x);hi.y=math.max(hi.y,p.y) end end
 c.data.center=ctr;c.data.lo=lo;c.data.hi=hi;c.data.lanes={}
 c.actor:SetNW2Vector('LOD_RoadMin',c.data.lo);c.actor:SetNW2Vector('LOD_RoadMax',c.data.hi)

 for i=1,4 do local y=lo.y+(hi.y-lo.y)*i/5;c.data.lanes[i]={a=Vector(lo.x+70,y,ctr.z),b=Vector(hi.x-70,y,ctr.z)} end
 c.data.cycle=0;c.data.formation=0;c.data.nextAttack=c.now+2;c.data.trapImmunity={};c.data.signs={};c.data.conedSerial=0
 for i=1,3 do local lane=c.data.lanes[i];local p=B:Floor(c,lane.b+Vector(-80,115,0))
  if p and B:ValidateRoutes(c,allPositions(c,{p}),42) then local o=B:Object(c,{kind='conan_sign',model='models/props_c17/streetsign004e.mdl',
   pos=p,hp=80,solid=true,permanent=true,radius=36,label='DESIGNATED ROAD BARRIER / BAIT CHARGE'})
   if o then c.data.signs[#c.data.signs+1]=o end
  end
 end
 self:BuildRoadwork(c)
 action(c,'MERGE LEFT / FOUR LANES OPEN')
end
function D:Cones(c,name,center)
 local template=shapes[name];if not template then return false end
 local points={};local space=math.min(120,(c.data.hi.y-c.data.lo.y)/12)
 for _,v in ipairs(template) do
  local p=B:Floor(c,center+Vector(v[1]*space,v[2]*space,0))
  if not p then return false end;points[#points+1]=p
 end
 if #B:Objects(c,'conan_mini')+#points>12 or not B:ValidateRoutes(c,allPositions(c,points),26) then
  B:Log(c,'CONAN_FORMATION_REJECT',{shape=name});return false
 end
 action(c,'CONE MAZE: '..string.upper(name))
 for i,p in ipairs(points) do B:Warn(c,'MINI-CONE '..name,p,.9,23)
  B:Later(c,.9,'conan_formation_'..i,function(owner)
   if #B:Objects(owner,'conan_mini')<12 and B:ValidateRoutes(owner,allPositions(owner,{p}),26) then
    B:Object(owner,{kind='conan_mini',model=model,pos=p,hp=22,solid=true,pushable=true,pushScale=2.2,radius=19,
     mass=7,life=16,scale=1.2,label='MINI-CONE / SHOOT OR PUSH',formation=name})
   end
  end)
 end
 B:Log(c,'CONAN_FORMATION',{shape=name,count=#points,validated=true});return true
end
function D:Roadblock(c)
 local lane=c.data.lanes[(c.data.cycle-1)%4+1];local center=lane.a+(lane.b-lane.a)*.45
 -- A short line occupies only part of one lane; three other lanes remain open.
 self:Cones(c,'lane_divider',center);c.data.nextAttack=c.now+3
end
function D:Closure(c)
 B:Clear(c,'conan_closure');local i=(c.data.cycle-1)%4+1;local lane=c.data.lanes[i]
 c.data.closedLane=i;action(c,'LANE '..i..' CLOSED / THREE LANES OPEN')
 B:Zone(c,{kind='conan_closure',label='LANE '..i..' CLOSED: USE OTHER LANES',pos=lane.a,finish=lane.b,shape='lane',width=145,
  delay=1.4,life=5.8,interval=1,damage={kind='melee',damage=12,reference=18,push=70},
  onExpire=function(owner) if owner.data.closedLane==i then owner.data.closedLane=nil end end})
 B:Log(c,'CONAN_LANE_CLOSURE',{closed=i,guaranteedOpen=3})
end
function D:WorkZone(c,destination)
 local p=B:Floor(c,destination);if not p then return end
 action(c,'WORK ZONE');B:Zone(c,{kind='conan_workzone',label='WORK ZONE: STEP OUT',pos=p,radius=145,delay=1.2,life=3.5,interval=1,
  damage={kind='melee',damage=13,reference=18,push=100}});c.data.nextAttack=c.now+3.8
end
function D:OpenTrapHull(c)
 if c.data.trapHullOpen then return true end
 local admitted=B:SetHull(c,c.actor,{mins=Vector(-62,-62,80),maxs=Vector(62,62,180)})
 if admitted then c.data.trapHullOpen=true end;return admitted
end
function D:RestoreTrapHull(c)
 if not c.data.trapHullOpen or c.data.trap or c.data.coned or not IsValid(c.actor) then return end
 -- B:Targets intentionally excludes invisible Heroes; collision safety must not.
 local candidates=player and player.GetAll and player.GetAll() or B:Targets(c)
 for _,p in ipairs(candidates) do if B:Hero(c,p) and p:GetPos():DistToSqr(c.actor:GetPos())<160^2 then return false end end
 if B:SetHull(c,c.actor,self.hull) then c.data.trapHullOpen=nil;return true end
 return false
end
function D:ChargeFinish(c,hit,p,tr)
 c.data.charging=false;c.data.chargeUntil=nil
 if tr and tr.cancelled then c.data.nextAttack=c.now+1.2;return end
 local caught
 for _,o in ipairs(c.data.signs) do if not o.retired and tr and tr.Entity==o.ent then caught=o;break end end
 if caught then
  B:RemoveObject(c,caught,'charge_barrier_broken');B:Clear(c,'conan_mini');B:Stagger(c,3.5);c.data.recoverUntil=c.now+3.5
  action(c,'BARRIER COLLISION / MINI-CONES CLEARED')
 elseif not hit then B:Stagger(c,1.5);c.data.recoverUntil=c.now+1.5;action(c,'MISSED CHARGE / PUNISH') end
end
function D:Charge(c,destination,detour)
 local dest=B:Floor(c,destination);if not dest then return end
 local start=copy(c.actor:GetPos());local middle=B:Floor(c,Vector((start.x+dest.x)*.5,start.y+(dest.y>=start.y and 160 or -160),start.z))
 if detour and not middle then return end
 action(c,detour and 'DETOUR: TWO SEGMENTS LOCKED' or 'CONE CHARGE')
 c.data.charging=true;c.data.chargeUntil=c.now+math.min(18,3+(dest-start):Length()/430+(detour and 3 or 0))
 if detour then
  B:Warn(c,'DETOUR SEGMENT 1',start,1.5,65,{shape='lane',finish=middle,width=130})
  B:Warn(c,'DETOUR SEGMENT 2: LOCKED NOW',middle,1.5,65,{shape='lane',finish=dest,width=130})
 end
 B:Charge(c,c.actor,detour and middle or dest,{label=detour and 'DETOUR SEGMENT 1' or 'CONE CHARGE',warning=1.5,speed=430,width=64,
  recovery=detour and .6 or 1.7,damage={kind='melee',damage=25,reference=18,push=250},
  onFinish=function(owner,hit,p,tr)
   if tr and tr.cancelled then self:ChargeFinish(owner,hit,p,tr);return end
   if detour and not (tr and tr.Hit) then
    B:Charge(owner,owner.actor,dest,{label='DETOUR SEGMENT 2',warning=.65,speed=430,width=64,recovery=1.8,
     damage={kind='melee',damage=25,reference=18,push=250},onFinish=function(o,h,v,t) self:ChargeFinish(o,h,v,t) end})
   else self:ChargeFinish(owner,hit,p,tr) end
  end})
 c.data.nextAttack=c.now+(detour and 7 or 4.5)
end
function D:Release(c,reason)
 local trap=c.data.trap;if not trap then return end
 B:ReleaseConstraint(c,trap.key);if trap.object then B:RemoveObject(c,trap.object,'coned_'..reason) end
 c.data.trap=nil;c.data.recoverUntil=c.now+1.2;B:Log(c,'CONAN_RELEASE',{reason=reason});
 if IsValid(c.actor) then action(c,'CONED: RELEASED / PUNISH') end
end
function D:Trap(c,binding,point)
 if not B:TargetLive(c,binding) then return false end
 local p=binding.player;local guard=c.data.trapImmunity[p]
 if guard and B:TargetLive(c,guard.binding) and guard.untilTime>c.now then return false end
 local key='conan:'..c.serial..':'..c.data.conedSerial
 local applied=B:Constrain(c,binding,{key=key,seconds=3.2,center=copy(point),radius=55})
 if not applied then return false end
 local trap={key=key,binding=binding,untilTime=c.now+3.2,helpReady=0};c.data.trap=trap
 c.data.trapImmunity[p]={binding=binding,untilTime=c.now+13}
 trap.object=B:Object(c,{kind='conan_escape',model='models/props_c17/TrapPropeller_Lever.mdl',pos=point+Vector(75,0,5),
  hp=0,use=true,hold=.25,life=3.4,label='YOU HAVE BEEN CONED / AUTO-ESCAPE 3.2s',useLabel='E: LIFT CONAN / HELP TEAMMATE',
  onUse=function(owner,object,helper)
   local t=owner.data.trap
   if not t or t.object~=object or helper==t.binding.player or not B:Hero(owner,helper) or owner.now<t.helpReady then return end
   t.helpReady=owner.now+.75;t.untilTime=math.max(owner.now,t.untilTime-1.4)
   if t.untilTime<=owner.now then self:Release(owner,'teammate_lift') end
  end})
 B:Announce(c,'YOU HAVE BEEN CONED! AUTO-ESCAPE / TEAMMATES CAN LIFT')
 B:Log(c,'CONAN_TRAP',{seconds=3.2,solo=c.party==1});return true
end
function D:Coned(c,target)
 local binding=B:BindTarget(c,target);if not binding then return false end
 local guard=c.data.trapImmunity[target]
 if guard and B:TargetLive(c,guard.binding) and guard.untilTime>c.now then return false end
 local point=B:Floor(c,target:GetPos());if not point or not self:OpenTrapHull(c) then return false end
 c.data.conedSerial=c.data.conedSerial+1;local serial=c.data.conedSerial
 B:Stop(c,c.actor);c.data.coned=true;c.data.conedUntil=c.now+3.4+math.sqrt((point-c.actor:GetPos()):LengthSqr()+800^2)/330; action(c,'CONED: MARK / LAUNCH / DROP')
 B:Warn(c,'CONED DROP CIRCLE: MOVE NOW',point,1.9,140)
 B:Charge(c,c.actor,point,{label='CONED: LAUNCH AND DROP',warning=1.9,speed=330,width=95,arc=400,minimumDuration=1.8,recovery=2,
  damage={kind='melee',damage=18,reference=18,push=25},
  onFinish=function(owner,hit,land,tr)
   owner.data.coned=false;owner.data.conedUntil=nil
   if tr and tr.cancelled then owner.data.nextAttack=owner.now+1.2;self:RestoreTrapHull(owner);return end
   -- Charge contact can be another Hero; only the captured exact life inside the final footprint is trapped.
   if hit and B:TargetLive(owner,binding) and binding.player:GetPos():DistToSqr(land)<=125^2 and self:Trap(owner,binding,land) then return end
   B:Stagger(owner,2.4);owner.data.recoverUntil=owner.now+2.4;action(owner,'CONED MISSED / STUCK')
  end})
 c.data.nextAttack=c.now+7;B:Log(c,'CONAN_CONED_COMMIT',{serial=serial,point=point});return true
end
function D:DoubleConed(c,targets)
 if #targets<2 or c.party<2 then return self:Coned(c,targets[1]) end
 local first,second=B:BindTarget(c,targets[1]),B:BindTarget(c,targets[2])
 self:Coned(c,targets[1]);c.data.doubleUntil=c.now+14
 B:Later(c,7.5,'conan_second_coned',function(owner)
  if second and B:TargetLive(owner,second) and not owner.data.trap and not owner.data.coned then self:Coned(owner,second.player) end
 end)
 B:Log(c,'CONAN_DOUBLE_CONED',{separated=7.5,different=first and second and first.player~=second.player})
end
function D:Cascade(c)
 action(c,'CONE CASCADE');local center=copy(c.actor:GetPos())
 for i=1,8 do local angle=(i-1)*math.pi/4;local dir=Vector(math.cos(angle),math.sin(angle),0)
  local to=B:Floor(c,center+dir*450)
  if to then B:Warn(c,'OUTWARD CONE CASCADE',center,1.3,28,{shape='lane',finish=to,width=65})
   B:Later(c,1.3,'conan_cascade_'..i,function(owner)
    if #B:Objects(owner,'conan_cascade')>=8 then return end
    B:Projectile(owner,{kind='conan_cascade',model=model,pos=center+Vector(0,0,45),velocity=dir*310+Vector(0,0,110),gravity=200,
     radius=18,mass=7,hp=18,life=2.4,bounces=1,pushable=true,breakOnImpact=true,damage={kind='melee',damage=14,reference=18,push=130},label='OUTWARD CASCADE'})
   end)
  end
 end
 c.data.nextAttack=c.now+4.5
end
function D:Frenzy(c,target)
 self:Closure(c);B:Clear(c,'conan_mini');c.data.formation=c.data.formation%5+1
 local lane=c.data.lanes[(c.data.closedLane%4)+1];self:Cones(c,order[c.data.formation],(lane.a+lane.b)*.5)
 B:Later(c,1.5,'conan_frenzy_charge',function(owner) self:Charge(owner,target,false) end)
 action(c,'CONSTRUCTION FRENZY: ONE CLOSURE / ONE MAZE / CHARGE');c.data.nextAttack=c.now+7
end
function D:Think(c,now,dt,targets)
 if (c.data.charging and now>(c.data.chargeUntil or now+1)) or (c.data.coned and now>(c.data.conedUntil or now+1)) then
  B:Stop(c,c.actor);c.data.charging=false;c.data.coned=false;c.data.chargeUntil=nil;c.data.conedUntil=nil;c.data.nextAttack=now+1.2
 end
 self:RestoreTrapHull(c)
 if c.data.trap then
  local t=c.data.trap
  if not B:TargetLive(c,t.binding) then self:Release(c,'life_changed') elseif now>=t.untilTime then self:Release(c,'auto_escape') end
  return
 end
 if not targets[1] or c.data.charging or c.data.coned or now<(c.data.recoverUntil or 0) or now<(c.data.doubleUntil or 0) or now<c.data.nextAttack then return end
 c.data.cycle=c.data.cycle+1;local n=c.data.cycle;local target=targets[(n-1)%#targets+1];local p=copy(target:GetPos())
 local grammar=c.phase==1 and {'charge','roadblock','work','coned'} or c.phase==2 and {'maze','closure','detour','coned','work'}
  or {'cascade','frenzy','double','detour','maze','coned'}
 local move=grammar[(n-1)%#grammar+1]
 if move=='charge' or move=='detour' then self:Charge(c,p,move=='detour')
 elseif move=='roadblock' then self:Roadblock(c)
 elseif move=='work' then self:WorkZone(c,p)
 elseif move=='closure' then self:Closure(c);c.data.nextAttack=now+3
 elseif move=='coned' then if not self:Coned(c,target) then c.data.nextAttack=now+1 end
 elseif move=='double' then self:DoubleConed(c,targets)
 elseif move=='cascade' then self:Cascade(c)
 elseif move=='frenzy' then self:Frenzy(c,p)
 else B:Clear(c,'conan_mini');c.data.formation=c.data.formation%5+1;self:Cones(c,order[c.data.formation],c.data.center);c.data.nextAttack=now+3 end
end
function D:Phase(c) self:Release(c,'phase');c.data.coned=false;c.data.charging=false;c.data.doubleUntil=0;c.data.chargeUntil=nil;c.data.conedUntil=nil;c.data.nextAttack=c.now+1.5;self:RestoreTrapHull(c) end
function D:Pause(c) self:Release(c,'pause');B:Stop(c,c.actor);c.data.coned=false;c.data.charging=false;c.data.doubleUntil=0;c.data.chargeUntil=nil;c.data.conedUntil=nil;c.data.nextAttack=c.now+1.5;self:RestoreTrapHull(c) end
function D:Retire(c) self:Release(c,'retire');c.data.trapImmunity={} end
function D:Snapshot(c) return c.data.trap and 'YOU HAVE BEEN CONED / E: HELP / AUTO-ESCAPE' or c.data.action or 'FOUR LANES OPEN' end
function D:Defeat(c)
 self:Release(c,'defeat');c.data.action='ONE TINY CONE / ROAD OPEN';c.data.deathStage='charge_trip_flip'
 local origin=IsValid(c.actor) and c.actor:GetPos() or c.savedPos or B:Center(c)
 c.data.deathTarget=B:SafePoint(c,origin+Vector(210,0,0)) or B:SafePoint(c,origin) or B:Center(c)
 B:Object(c,{kind='conan_tiny_snag',model=model,pos=c.data.deathTarget,scale=.75,
  cosmetic=true,life=5,hp=0,label='ONE TINY CONE / FINAL CHARGE SNAG'})
end
B:Register('conan',D)
