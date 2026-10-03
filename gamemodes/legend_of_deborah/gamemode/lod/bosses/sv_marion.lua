-- Dungeon 9: a hammer fighter beside authored traffic lanes, never live car physics.
local B=LOD.BossEncounter
local D={name='Marion the Carbarian',model='models/Humans/Group03/male_07.mdl',baseHP=1500,speed=170,size=1.55,
 maxObjects=20,maxAdds=0,pushScale=.12,phaseNames={'Road Rage','Rush Hour','FORE!'},
 arena={theme='interchange',width=7,depth=7,upper=true},deathCaption='MARION THE CARBARIAN DEFEATED',keyLocation='hammer',
 presentation={body='carbarian',weapon='oversized_sledgehammer',safeMedians=true},deathDuration=5}
local carModel='models/props_vehicles/car004a_physics.mdl'
local function copy(p) return Vector(p.x,p.y,p.z) end
local function unit(v) v=copy(v);v.z=0;return v:LengthSqr()>1 and v:GetNormalized() or Vector(1,0,0) end
local function action(c,s) c.data.action=s;c.actor:SetNW2String('LOD_BossAction',s);c.actor:SetNW2Float('LOD_BossActionAt',c.now) end
local function plan(c)
 local ctr=B:Center(c);local lo,hi=copy(ctr),copy(ctr)
 for _,p in ipairs(c.points) do if math.abs(p.z-ctr.z)<40 then
  lo.x=math.min(lo.x,p.x);lo.y=math.min(lo.y,p.y);hi.x=math.max(hi.x,p.x);hi.y=math.max(hi.y,p.y)
 end end
 local lanes={};for n=1,4 do local y=lo.y+(hi.y-lo.y)*(n/5)
  lanes[n]={a=Vector(lo.x+55,y,ctr.z),b=Vector(hi.x-55,y,ctr.z)}
 end
 return lanes,lo,hi
end
local function obstacles(c,extra)
 local p={};for _,o in ipairs(B:Objects(c)) do if o.spec.solid then p[#p+1]=o.pos end end
 if extra then p[#p+1]=extra end;return p
end
function D:Start(c)
 c.data.lanes,c.data.lo,c.data.hi=plan(c);
 c.actor:SetNW2Vector('LOD_RoadMin',c.data.lo);c.actor:SetNW2Vector('LOD_RoadMax',c.data.hi)
c.data.carSerial=0;c.data.cycle=0;c.data.trafficWave=0
 c.data.impactGuard={};c.data.nextAttack=c.now+4.5;c.data.nextTraffic=c.now+7;c.data.entranceUntil=c.now+3.8
 c.data.barriers={};c.data.hammer=B:SafePoint(c,B:Center(c)) or B:Point(c,1)
 for _,idx in ipairs({1,4}) do local lane=c.data.lanes[idx];local p=B:Floor(c,lane.b+Vector(-130,idx==1 and 135 or -135,0))
  if p and B:ValidateRoutes(c,obstacles(c,p),85) then
   local o=B:Object(c,{kind='marion_reinforced_car',model=carModel,pos=p,label='REINFORCED CAR / HAMMER STICK',
    hp=0,permanent=true,solid=true,radius=75,scale=1,mass=120})
   if o then c.data.barriers[#c.data.barriers+1]=o end
  end
 end
 action(c,'ENTRANCE: RIDING TO ROAD RAGE')
 local a,b=copy(c.actor:GetPos()),c.data.lanes[2].b
 local car=self:Car(c,a,b,'entrance',nil)
 B:Charge(c,c.actor,b,{label='MARION ARRIVES',warning=.3,speed=400,width=36,recovery=1,arc=32,
  onFinish=function(owner,hit,position,tr)
   if tr and tr.cancelled then owner.data.entranceUntil=0;owner.data.nextAttack=owner.now+1.2;return end
   if car and not car.retired then B:RemoveObject(owner,car,'entrance_hammer_wreck') end
   action(owner,'JUMPS OFF / DESTROYS CAR');B:Warn(owner,'ENTRANCE HAMMER SMASH',b,.7,95)
  end})
 B:Later(c,3.8,'marion_intro_end',function(owner) owner.data.entranceUntil=0;B:Stop(owner,owner.actor);action(owner,'ROAD RAGE') end)
end
function D:Car(c,from,to,kind,warning)
 if #B:Objects(c,'marion_car')>=6 then return end
 local dir=unit(to-from);local speed=kind=='smash' and 720 or kind=='kick' and 410 or 390
 local delay=warning or 0;local serial=c.data.carSerial+1;c.data.carSerial=serial
 local function launch(owner)
  local o=B:Projectile(owner,{kind='marion_car',model=carModel,pos=from+Vector(0,0,20),velocity=dir*speed,
   gravity=0,radius=48,mass=120,life=math.min(5,(to-from):Length()/speed+1),hp=65,bounces=kind=='smash' and 1 or 0,
   breakOnImpact=true,pushable=false,label=kind=='smash' and 'FORE! HAMMER-LAUNCHED CAR' or 'TRAFFIC: SINGLE IMPACT',
   onHit=function(current,obj,p)
    if obj.carSpent or kind=='entrance' then return end
    obj.carSpent=true;obj.state='WRECK / CONTACT SPENT'
    local binding=B:BindTarget(current,p);local guard=current.data.impactGuard[p]
    if binding and B:TargetLive(current,binding) and (not guard or guard.untilTime<=current.now or not B:TargetLive(current,guard.binding)) then
     if B:Damage(current,p,{kind='melee',damage=kind=='smash' and 38 or 25,reference=18,push=280,direction=dir,origin=obj.pos}) then
      current.data.impactGuard[p]={untilTime=current.now+2.5,binding=binding}
     end
    end
   end,
   onImpact=function(current,obj,tr)
    if kind=='smash' and not obj.ricochet and tr and tr.Entity then
     for _,barrier in ipairs(current.data.barriers) do if not barrier.retired and tr.Entity==barrier.ent then
      obj.ricochet=true;obj.pos=copy(tr.HitPos or obj.pos)+(tr.HitNormal or unit(current.actor:GetPos()-obj.pos))*55
      obj.velocity=unit(current.actor:GetPos()-obj.pos)*270;obj.expires=current.now+1.3
      B:Warn(current,'WRECK RICOCHET TOWARD MARION',obj.pos,.35,70)
      B:Later(current,.6,'marion_ricochet_'..serial,function(owner2)
       if not obj.retired and IsValid(owner2.actor) and owner2.actor:GetPos():DistToSqr(obj.pos)<330^2 then
        B:Stagger(owner2,3.2);owner2.data.recoverUntil=owner2.now+3.2;action(owner2,'CAR WRECK: PUNISH')
       end
      end)
      return true
     end end
    end
   end})
  if o then o.carKind=kind end;return o
 end
 if delay>0 then B:Warn(c,kind=='smash' and 'FORE! CAR SMASH' or 'INCOMING TRAFFIC',from,delay,48,{shape='lane',finish=to,width=112})
  B:Later(c,delay,'marion_car_'..serial,launch)
 else return launch(c) end
end
function D:Traffic(c)
 c.data.trafficWave=c.data.trafficWave+1;local n=c.data.trafficWave
 -- Phase 2 uses two separated lanes, phase 3 exactly one. Entire medians remain dry.
 local indexes=c.phase==3 and {((n-1)%4)+1} or {((n-1)%4)+1,((n+1)%4)+1}
 for k,i in ipairs(indexes) do local lane=c.data.lanes[i];local a,b=lane.a,lane.b
  if n%2==0 then a,b=b,a end;self:Car(c,a,b,'traffic',1.6+(k-1)*.7)
 end
 B:Log(c,'MARION_TRAFFIC',{lanes=indexes,guaranteedOpen=4-#indexes})
 c.data.nextTraffic=c.now+(c.phase==3 and 10 or 6.8)
end
function D:Combo(c,target)
 action(c,'SLEDGE: LEFT / RIGHT / OVERHEAD');B:Stop(c,c.actor)
 local origin=copy(c.actor:GetPos());local dir=unit(target-origin)
 for i,hit in ipairs({{.65,110,14},{1.4,125,16},{2.65,150,27}}) do
  local point=B:Floor(c,origin+dir*(i==3 and 105 or 65)) or origin
  B:Warn(c,i==3 and 'SLOW OVERHEAD SMASH' or 'SLEDGE '..i,point,hit[1],hit[2])
  B:Later(c,hit[1],'marion_combo_'..i,function(owner)
   B:Area(owner,point,hit[2],{kind='melee',damage=hit[3],reference=18,push=i==3 and 180 or 70,origin=origin})
   if i==3 then for _,o in ipairs(owner.data.barriers) do
    if not o.retired and o.pos:DistToSqr(point)<190^2 then
     B:Stagger(owner,2.7);owner.data.recoverUntil=owner.now+2.7;action(owner,'HAMMER STUCK');break
    end
   end end
  end)
 end
 c.data.nextAttack=c.now+4
end
function D:Pound(c)
 action(c,'GROUND POUND: WATCH THE TRAFFIC');local p=copy(c.actor:GetPos())
 B:Zone(c,{kind='marion_pound',label='GROUND POUND',pos=p,radius=205,delay=1.1,life=.2,interval=1,
  damage={kind='melee',damage=14,reference=18,push=260,origin=p}})
 c.data.nextAttack=c.now+2.8
end
function D:CarKick(c,destination,smash)
 action(c,smash and 'FORE!' or 'CAR KICK');local dir=unit(destination-c.actor:GetPos())
 local from=B:Floor(c,c.actor:GetPos()+dir*100) or B:Floor(c,c.actor:GetPos());if not from then return end
 local to=B:Floor(c,from+dir*1000) or destination
 local p=B:Object(c,{kind='marion_designated_car',model=carModel,pos=from+Vector(0,0,18),life=smash and 2.3 or 1.4,
  hp=0,mass=120,label=smash and 'HAMMER WIND-UP: FORE!' or 'CAR KICK WIND-UP'})
 local delay=smash and 2.2 or 1.3
 B:Warn(c,smash and 'FORE! HIGH-DAMAGE CAR' or 'CAR KICK',from,delay,65,{shape='lane',finish=to,width=130})
 B:Later(c,delay,'marion_designated_launch',function(owner)
  if p then B:RemoveObject(owner,p,'launched') end;self:Car(owner,from,to,smash and 'smash' or 'kick')
 end)
 c.data.nextAttack=c.now+delay+1.8
end
function D:Pileup(c)
 if c.data.pileup then return end;c.data.pileup=true;action(c,'PILEUP / NEW COVER');B:Announce(c,'PILEUP! WRECKS SETTLE INTO COVER')
 for i=1,3 do local lane=c.data.lanes[i];local p=B:Floor(c,lane.a+(lane.b-lane.a)*(.25+i*.12)+Vector(0,115,0))
  if p and B:ValidateRoutes(c,obstacles(c,p),80) then
   B:Warn(c,'SETTLING WRECK: KEEP ROUTE CLEAR',p,1.8,85)
   B:Later(c,1.8,'marion_pileup_'..i,function(owner)
    if B:ValidateRoutes(owner,obstacles(owner,p),80) then B:Object(owner,{kind='marion_wreck',model=carModel,pos=p,
     permanent=true,solid=true,hp=0,mass=120,radius=75,label='PILEUP WRECK / PERMANENT COVER'}) end
   end)
  end
 end
 c.data.nextAttack=c.now+4
end
function D:Roadside(c)
 action(c,'ROADSIDE ASSISTANCE');local p=B:Floor(c,c.actor:GetPos()+Vector(110,0,0)) or B:Center(c)
 local o=B:Object(c,{kind='marion_disabled',model=carModel,pos=p,life=4.8,hp=35,label='REPAIRING... BADLY'})
 B:Warn(c,'ROADSIDE ASSISTANCE: CAR WILL IGNITE',p,2.4,150)
 B:Later(c,2.4,'marion_roadside_fire',function(owner)
  if not o or o.retired then return end;o.state='ON FIRE / EXPLOSION IMMINENT'
  B:Zone(owner,{kind='marion_car_fire',label='CAR FIRE',pos=p,radius=125,delay=.4,life=1.5,interval=.8,
   damage={kind='flame',content='fire',damage=10,reference=18}})
  B:Warn(owner,'DISABLED CAR EXPLOSION',p,1.8,175)
  B:Later(owner,1.8,'marion_roadside_blast',function(current)
   if o.retired then return end;B:Area(current,p,175,{kind='blast',damage=26,reference=18,push=190});B:RemoveObject(current,o,'repair_explosion')
  end)
 end)
 c.data.nextAttack=c.now+5
end
function D:Think(c,now,dt,targets)
 if not targets[1] or now<(c.data.entranceUntil or 0) then return end
 if c.actor:Health()/math.max(1,c.actor:GetMaxHealth())<=.2 and not c.data.pileup then self:Pileup(c);return end
 if c.phase>=2 and now>=c.data.nextTraffic then self:Traffic(c) end
 if now<(c.data.recoverUntil or 0) or now<c.data.nextAttack then return end
 c.data.cycle=c.data.cycle+1;local n=c.data.cycle;local p=targets[(n-1)%#targets+1]:GetPos()
 if n%11==0 then self:Roadside(c)
 elseif c.phase==3 and n%3==0 then self:CarKick(c,p,true)
 elseif n%4==0 then self:CarKick(c,p,false)
 elseif n%3==0 then self:Pound(c)
 elseif c.actor:GetPos():DistToSqr(p)<=290^2 then self:Combo(c,p)
 else
  local lane=c.data.lanes[(n-1)%4+1];local edge=B:Floor(c,Vector(p.x,lane.a.y+135,p.z)) or B:Point(c,n)
  action(c,'LANE-EDGE PURSUIT');B:Move(c,c.actor,edge,170,{mode='ground',turnRate=80});c.data.nextAttack=now+1.3
 end
end
function D:Phase(c) B:Stop(c,c.actor);c.data.nextAttack=c.now+1.3;c.data.entranceUntil=0;c.data.nextTraffic=c.now+2 end
function D:Pause(c) B:Stop(c,c.actor);c.data.entranceUntil=0;c.data.nextAttack=c.now+1.5 end
function D:Retire(c) c.data.impactGuard={} end
function D:Snapshot(c) return c.data.action or 'SAFE MEDIANS / WATCH TRAFFIC LIGHTS' end
function D:KeyPosition(c) return B:SafePoint(c,c.data.hammer) or B:Center(c) end
function D:Defeat(c)
 c.data.action='HAMMER PLANTED / FINAL UNMANNED CAR';c.data.deathStage='hammer_car_exit'
 c.data.hammer=B:SafePoint(c,IsValid(c.actor) and c.actor:GetPos() or c.savedPos or B:Center(c)) or B:Center(c)
 B:Object(c,{kind='marion_death_hammer',model='models/props_c17/TrapPropeller_Lever.mdl',pos=c.data.hammer,
  cosmetic=true,life=8,hp=0,label='UPRIGHT HAMMER / JAIL KEY'})
 B:Later(c,1,'cosmetic:marion_last_car',function(owner)
  B:Object(owner,{kind='marion_final_car',model=carModel,pos=owner.data.hammer+Vector(-400,0,20),velocity=Vector(450,0,0),
   cosmetic=true,life=2.4,hp=0,label='FINAL UNMANNED CAR',radius=0})
 end)
end
B:Register('marion',D)
