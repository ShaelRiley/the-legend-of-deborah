-- Dungeon 19: a real stock Strider rig, high main-body hull and authored leg danger.
-- Knee counters consume resolved main-body damage; they are NEVER a second HP pool.
local B=LOD.BossEncounter
local D={name='Little Mooky',model='models/combine_strider.mdl',baseHP=2900,speed=145,size=1,
 hull={mins=Vector(-92,-92,245),maxs=Vector(92,92,455)},combatBounds={mins=Vector(-225,-220,115),maxs=Vector(225,220,480)},
 maxObjects=18,maxAdds=0,pushScale=0,phaseNames={'Big Mooky','Mooky Is Upset','Little Mooky'},
 arena={theme='mooky_yard',width=7,depth=7,upper=true,sky=true},deathCaption='LITTLE MOOKY DEFEATED',keyLocation='center',deathDuration=8,deathCaptionDelay=7.2,
 presentation={body='stock_strider',kneeTargets=2,underbody=true,smokePhase=3}}
local function copy(p) return Vector(p.x,p.y,p.z) end
local function unit(p) return p:LengthSqr()>1 and p:GetNormalized() or Vector(1,0,0) end
local function action(c,s) c.data.action=s;c.actor:SetNW2String('LOD_BossAction',s);c.actor:SetNW2Float('LOD_BossActionAt',c.now) end
local function obstacles(c,p)
 local out={p};for _,o in ipairs(B:Objects(c)) do if o.spec.solid then out[#out+1]=o.pos end end;return out
end
function D:RigPoint(c,side,foot)
 local actor=c.actor
 local names=side=='left' and (foot and {'left foot','left_foot'} or {'Strider_LLeg_Bone1','Strider.LeftLeg_Bone1','LeftLeg_Bone1'})
  or side=='right' and (foot and {'right foot','right_foot'} or {'Strider_RLeg_Bone1','Strider.RightLeg_Bone1','RightLeg_Bone1'})
  or {'back foot','back_foot'}
 if foot and actor.LookupAttachment and actor.GetAttachment then
  for _,name in ipairs(names) do local index=actor:LookupAttachment(name)
   if index and index>0 then local a=actor:GetAttachment(index);if a and a.Pos then return copy(a.Pos) end end
  end
 elseif actor.LookupBone and actor.GetBonePosition then
  for _,name in ipairs(names) do local index=actor:LookupBone(name)
   if index then local p=actor:GetBonePosition(index);if p and p:DistToSqr(actor:GetPos())>80^2 then return copy(p) end end
  end
 end
 -- Authored fallback markers remain inside the native combat bounds, visible and hittable.
 local offset=side=='left' and Vector(145,-140,foot and 5 or 190) or side=='right' and Vector(145,140,foot and 5 or 190) or Vector(-175,0,5)
 return actor.LocalToWorld and actor:LocalToWorld(offset) or actor:GetPos()+offset
end
function D:EdgeClear(c,a,b)
 if not a or not b then return false end
 for n=0,8 do if not B:Floor(c,a+(b-a)*n/8) then return false end end
 if util and util.TraceHull then
  local tr=util.TraceHull({start=a,endpos=b,mins=self.hull.mins,maxs=self.hull.maxs,mask=MASK_NPCSOLID,
   filter=function(e) return e~=c.actor and not e:IsPlayer() and not e.LODHostile end})
  if tr.Hit or tr.StartSolid or tr.AllSolid then return false end
 end
 return B:ValidateRoutes(c,{},24)
end
function D:RefreshGraph(c,force)
 local signature={}
 for _,o in ipairs(B:Objects(c)) do if o.spec.solid then
  signature[#signature+1]=o.id..':'..math.floor(o.pos.x)..':'..math.floor(o.pos.y)..':'..math.floor(o.pos.z)
 end end
 local fingerprint=table.concat(signature,'|');local g=c.data.graph
 if not force and g.fingerprint==fingerprint then return end
 g.fingerprint=fingerprint;g.edges={};g.reverse={}
 for i,a in ipairs(g.nodes) do local j=i%#g.nodes+1;local b=g.nodes[j]
  if self:EdgeClear(c,a,b) then g.edges[i]=j end
  if self:EdgeClear(c,b,a) then g.reverse[j]=i end
 end
 B:Log(c,'MOOKY_GRAPH_REVALIDATED',{edges=table.Count(g.edges),solids=#signature})
end
function D:GraphPath(c,targetIndex)
 self:RefreshGraph(c,false);local g=c.data.graph;local origin=c.actor:GetPos();local best,bestLength
 -- Only a native-hull-clear approach to an authored node is allowed, followed by approved ring edges.
 for startIndex,node in ipairs(g.nodes) do if self:EdgeClear(c,origin,node) then
  for _,edges in ipairs({g.edges,g.reverse}) do
   local path={copy(node)};local index=startIndex;local length=(node-origin):Length();local seen={}
   while index~=targetIndex and edges[index] and not seen[index] do
    seen[index]=true;local nextIndex=edges[index];length=length+(g.nodes[nextIndex]-g.nodes[index]):Length()
    path[#path+1]=copy(g.nodes[nextIndex]);index=nextIndex
   end
   if index==targetIndex and (not bestLength or length<bestLength) then best,bestLength=path,length end
  end
 end end
 return best
end
function D:MotionRecovery(c,kind,reason)
 B:Stop(c,c.actor);c.data[kind]=nil;c.data.recoverUntil=c.now+1.5;c.data.nextAttack=c.now+1.5
 action(c,'STRIDER ROUTE RECOVERY');B:Log(c,'MOOKY_MOTION_RECOVERY',{kind=kind,reason=reason,hp=c.actor:Health()})
end
function D:FollowGraphPath(c,state,speed,kind)
 if c.now<(state.retryAt or 0) then return false,false end
 self:RefreshGraph(c,false)
 if not state.path then
  state.path=self:GraphPath(c,state.targetIndex);state.pathIndex=1
  if not state.path then
   state.retries=(state.retries or 0)+1;state.retryAt=c.now+.8
   if state.retries>2 then self:MotionRecovery(c,kind,'no_validated_retry');return false,true end
   return false,false
  end
 end
 local waypoint=state.path[state.pathIndex or 1]
 if not waypoint then return true,false end
 if not self:EdgeClear(c,c.actor:GetPos(),waypoint) then
  B:Stop(c,c.actor);state.retries=(state.retries or 0)+1
  if state.retries>2 then self:MotionRecovery(c,kind,'native_edge_blocked');return false,true end
  state.path=self:GraphPath(c,state.targetIndex);state.pathIndex=1;state.retryAt=c.now+.8
  if not state.path then self:RefreshGraph(c,true) end
  return false,false
 end
 -- Explicit path is the authority: the shared mover must never ask Navigator for a shortcut.
 local reached,blocked=B:Move(c,c.actor,waypoint,speed,{mode='ground',path={copy(waypoint)},turnRate=28,stopDistance=45})
 if reached then state.pathIndex=(state.pathIndex or 1)+1;state.retries=0
  return state.pathIndex>#state.path,false
 elseif blocked then
  B:Stop(c,c.actor);state.retries=(state.retries or 0)+1;state.retryAt=c.now+.8
  if state.retries>2 then self:MotionRecovery(c,kind,'swept_motion_blocked');return false,true end
  state.path=self:GraphPath(c,state.targetIndex);state.pathIndex=1
 end
 return false,false
end
function D:Start(c)
 local center=B:Center(c);local lo,hi=copy(center),copy(center)
 for _,p in ipairs(c.points) do if math.abs(p.z-center.z)<40 then lo.x=math.min(lo.x,p.x);lo.y=math.min(lo.y,p.y);hi.x=math.max(hi.x,p.x);hi.y=math.max(hi.y,p.y) end end
 local x1,x2=lo.x+185,hi.x-185
 local y1,y2=lo.y+(hi.y-lo.y)*.28,hi.y-(hi.y-lo.y)*.28
 c.data.graph={nodes={},edges={}};local candidates={Vector(x1,y1,center.z),Vector(center.x,y1,center.z),Vector(x2,y1,center.z),
  Vector(x2,center.y,center.z),Vector(x2,y2,center.z),Vector(center.x,y2,center.z),Vector(x1,y2,center.z),Vector(x1,center.y,center.z)}
 for _,p in ipairs(candidates) do local q=B:Floor(c,p)
  if q and B:SafePoint(c,q) then c.data.graph.nodes[#c.data.graph.nodes+1]=q end
 end
 local nodes=c.data.graph.nodes
 c.data.route=1;c.data.cycle=0;c.data.nextAttack=c.now+2.5;c.data.knees={left={damage=0,guard=0,last=0},right={damage=0,guard=0,last=0}}
 c.data.lasers=0;c.data.walks=0;c.data.rigAt=0;c.data.cover={};c.data.containerSerial=0
 for i=1,4 do local p=B:Floor(c,Vector(i%2==0 and x2+145 or x1-145,i<=2 and y1 or y2,center.z))
  if p and B:ValidateRoutes(c,obstacles(c,p),90) then
   local o=B:Object(c,{kind='mooky_permanent_cover',model='models/props_wasteland/rockgranite03b.mdl',pos=p,permanent=true,solid=true,
    hp=0,radius=85,scale=1.5,label='PERMANENT HARD COVER / LASER SAFE'})
   if o then c.data.cover[#c.data.cover+1]=o end
  end
 end
 for i=1,2 do local p=B:Floor(c,Vector(center.x,center.y+(i==1 and -270 or 270),center.z))
  if p and B:ValidateRoutes(c,obstacles(c,p),60) then B:Object(c,{kind='mooky_secondary_cover',model='models/props_junk/wood_crate002a.mdl',
   pos=p,permanent=true,solid=true,hp=65,radius=55,label='SECONDARY COVER / DESTRUCTIBLE'}) end
 end
 self:RefreshGraph(c,true)
 action(c,'BIG MOOKY / FRONT KNEES / UNDERBODY ROUTES');B:Log(c,'MOOKY_GRAPH',{nodes=#nodes,validatedEdges=table.Count(c.data.graph.edges)})
end
function D:EnsureHardCover(c)
 local covers=B:Objects(c,'mooky_permanent_cover');if #covers>=2 then c.data.cover=covers;return true end
 if c.now<(c.data.retryCoverAt or 0) then return false end;c.data.retryCoverAt=c.now+2
 for _,candidate in ipairs(c.points) do
  if math.abs(candidate.z-B:Center(c).z)<40 and candidate:DistToSqr(B:Center(c))>260^2 then
   local clear=true;for _,o in ipairs(covers) do if o.pos:DistToSqr(candidate)<260^2 then clear=false end end
   local p=clear and B:SafePoint(c,candidate)
   if p and B:ValidateRoutes(c,obstacles(c,p),90) then
    local o=B:Object(c,{kind='mooky_permanent_cover',model='models/props_wasteland/rockgranite03b.mdl',pos=p,
     hp=0,solid=true,permanent=true,scale=1.5,radius=85,label='PERMANENT HARD COVER / LASER SAFE'})
    if o then covers[#covers+1]=o end
   end
   if #covers>=2 then c.data.cover=covers;return true end
  end
 end
 B:Stop(c,c.actor);action(c,'HOLDING FIRE / CLEARING COVER ROUTES');return false
end
function D:Underbody(c,p)
 local d=p:GetPos()-c.actor:GetPos();return d.x*d.x+d.y*d.y<145^2 and d.z<220
end
function D:FireLane(c,destination,kind,delay)
 local pos=copy(c.actor:GetPos());local finish=B:Floor(c,destination);local start=B:Floor(c,pos)
 if not start or not finish then return end
 start.z=finish.z -- Gallery targets receive a gallery-height locked lane as well.
 local heavy=kind=='heavy' or kind=='laser';local damage=kind=='laser' and 42 or heavy and 34 or 16
 local width=kind=='laser' and 115 or heavy and 135 or 80
 -- This tuple is captured once. No callback reacquires the target or tracks after lock.
 B:Zone(c,{kind='mooky_shot',label=kind=='laser' and 'MOOKY LASER: FINAL LINE LOCKED' or heavy and 'HEAVY CANNON: LOCKED LANE' or 'PULSE CANNON',
  pos=start,finish=copy(finish),shape='lane',width=width,delay=delay or (heavy and 2.3 or .8),life=.18,interval=1,
  onTick=function(owner,z,targets)
   for _,p in ipairs(targets) do if not self:Underbody(owner,p) then
    B:Damage(owner,p,{kind=heavy and 'blast' or 'bullet',damage=damage,reference=18,push=heavy and 210 or 30,
     origin=pos+Vector(0,0,340)})
   end end
  end})
 B:Log(c,'MOOKY_CANNON_LOCK',{kind=kind,finish=copy(finish),width=width})
end
function D:Pulse(c,target)
 action(c,'PULSE CANNON');self:FireLane(c,target,'pulse',.9);c.data.nextAttack=c.now+2.2
end
function D:Sweep(c,target)
 action(c,'SWEEP FIRE: THREE FIXED LANES');local origin=c.actor:GetPos();local dir=unit(target-origin);dir.z=0
 local side=Vector(-dir.y,dir.x,0)
 for i=1,3 do local p=B:Floor(c,target+side*((i-2)*170));if p then self:FireLane(c,p,'pulse',.9+(i-1)*.55) end end
 c.data.nextAttack=c.now+3.5
end
function D:Stomp(c,triple)
 action(c,triple and 'TRIPLE STOMP: LEFT / RIGHT / BACK' or 'LEG STRIKE')
 local sides=triple and {'left','right','back'} or {c.data.cycle%2==0 and 'left' or 'right'}
 for i,side in ipairs(sides) do local p=B:Floor(c,self:RigPoint(c,side,true))
  if p then B:Zone(c,{kind='mooky_stomp',label=triple and 'TRIPLE STOMP '..i or 'LEG STRIKE / RADIAL PUSH',pos=p,radius=170,
   delay=1.15+(i-1)*.8,life=.2,interval=1,damage={kind='melee',damage=25,reference=18,push=270,origin=p}}) end
 end
 c.data.nextAttack=c.now+(triple and 4.8 or 2.7)
end
function D:Step(c,hunter)
 self:RefreshGraph(c,false);local g=c.data.graph;local nextNode=g.edges[c.data.route]
 if not nextNode then self:MotionRecovery(c,'step','authored_edge_unavailable');return end
 local path=self:GraphPath(c,nextNode)
 if not path then self:MotionRecovery(c,'step','approach_unavailable');return end
 local p=g.nodes[nextNode];c.data.step={destination=copy(p),index=nextNode,targetIndex=nextNode,path=path,pathIndex=1,
  expires=c.now+12,hunter=hunter,begin=c.now+1.1}
 B:Warn(c,hunter and 'HUNTER MODE: FAST STRIDER STEP' or 'STRIDER STEP',c.actor:GetPos(),1.1,65,{shape='lane',finish=p,width=130})
 action(c,hunter and 'HUNTER MODE' or 'STRIDER STEP');c.data.nextAttack=c.now+3.5
end
function D:ServiceStep(c,now)
 local s=c.data.step;if not s or now<s.begin then return end
 if now>s.expires then self:MotionRecovery(c,'step','deadline');return end
 local reached=self:FollowGraphPath(c,s,s.hunter and 195 or c.phase>=2 and 175 or 135,'step')
 if reached then c.data.route=s.index;c.data.step=nil;c.data.recoverUntil=now+1.2 end
end
function D:Heavy(c,target)
 action(c,'HEAVY CANNON: CHARGE / LOCK')
 self:FireLane(c,target,'heavy',2.35);c.data.nextAttack=c.now+4.1
 if c.now<(c.data.lowerUntil or 0) then action(c,'PARTIALLY LOWERED: HEAVY CANNON') end
end
function D:Container(c)
 local g=c.data.graph;local a=g.nodes[1];local b=g.nodes[3];if not a or not b then return end
 local from=B:Floor(c,a+Vector(0,100,0));local finish=B:Floor(c,b+Vector(0,100,0));if not from or not finish then return end
 if #B:Objects(c,'mooky_kicked_cover')>=2 or not B:ValidateRoutes(c,obstacles(c,finish),85) then self:Step(c,false);return end
 action(c,'CONTAINER KICK / WILL SETTLE AS COVER');c.data.containerSerial=c.data.containerSerial+1;local serial=c.data.containerSerial
 B:Warn(c,'CONTAINER KICK: KNOWN LANE',from,1.8,75,{shape='lane',finish=finish,width=155})
 B:Later(c,1.8,'mooky_container_'..serial,function(owner)
  local duration=math.min(4,(finish-from):Length()/340)
  local settled=false
  local function settle(current,object)
   if settled then return end;settled=true
   local p=B:Floor(current,object.pos) or finish
   B:RemoveObject(current,object,'container_settled')
   if B:ValidateRoutes(current,obstacles(current,p),85) then B:Object(current,{kind='mooky_kicked_cover',model='models/props_wasteland/cargo_container01.mdl',
    pos=p,scale=.24,hp=90,permanent=true,solid=true,radius=80,mass=120,label='KICKED CONTAINER / NEW COVER'}) end
  end
  B:Projectile(owner,{kind='mooky_container',model='models/props_wasteland/cargo_container01.mdl',pos=from+Vector(0,0,15),scale=.24,
   velocity=unit(finish-from)*340,gravity=0,radius=65,mass=120,hp=90,life=duration,bounces=0,breakOnImpact=false,
   damage={kind='melee',damage=30,reference=18,push=250},label='CONTAINER KICK',onExpire=settle,
   onHit=function(current,object) settle(current,object) end,
   onImpact=function(current,object,tr) if tr and B:Hero(current,tr.Entity) then return false end;settle(current,object);return true end})
 end)
 c.data.nextAttack=c.now+5
end
function D:Laser(c,target)
 if c.data.lasers>=2 then return self:Heavy(c,target) end
 c.data.lasers=c.data.lasers+1;local shot=c.data.lasers
 local destination=copy(target);action(c,'MOOKY LASER: CHARGING')
 B:Warn(c,'MOOKY LASER: CHARGE / FINAL LOCK IN 1s',destination,1,125)
 B:Later(c,1,'mooky_laser_lock_'..shot,function(owner)
  action(owner,'MOOKY LASER: FINAL LOCK / USE HARD COVER');self:FireLane(owner,destination,'laser',2.5)
 end)
 c.data.nextAttack=c.now+6
end
function D:Jitter(c,target)
 action(c,'DAMAGED CANNON: AIM JITTER / THEN LOCK');local origin=copy(target)
 local offsets={-125,105,-55,0}
 for i,offset in ipairs(offsets) do B:Later(c,(i-1)*.28,'mooky_jitter_'..i,function(owner)
  local p=B:Floor(owner,origin+Vector(0,offset,0))
  if p then B:Warn(owner,i==4 and 'FINAL AIM LOCK' or 'DAMAGED AIM JITTER',p,.3,65) end
 end) end
 B:Later(c,1.12,'mooky_jitter_fire',function(owner) self:FireLane(owner,origin,'heavy',1.6) end)
 c.data.nextAttack=c.now+4.5
end
function D:MookyWalk(c)
 self:RefreshGraph(c,false)
 local g=c.data.graph
 if #g.nodes<5 or not g.edges[1] or not g.edges[2] then self:MotionRecovery(c,'walk','walk_lane_unavailable');return end
 local path=self:GraphPath(c,1);if not path then self:MotionRecovery(c,'walk','retreat_unavailable');return end
 c.data.walks=c.data.walks+1;c.data.step=nil;B:Stop(c,c.actor)
 c.data.walk={stage='retreat',destination=copy(g.nodes[1]),endPoint=copy(g.nodes[3]),targetIndex=1,path=path,pathIndex=1,
  deadline=c.now+30,nextLeg=c.now+1.2,nextFire=c.now+2}
 action(c,'MOOKY WALK: RETREAT TO END');B:Announce(c,'MOOKY WALK: LEGS ARE MOVING COLUMNS / FAR TURN IS EXPOSED')
 c.data.nextAttack=c.now+35
end
function D:ServiceWalk(c,now,targets)
 local w=c.data.walk;if not w then return false end
 if now>w.deadline then self:MotionRecovery(c,'walk','deadline');return false end
 local reached,failed=self:FollowGraphPath(c,w,w.stage=='retreat' and 155 or 115,'walk')
 if failed or not c.data.walk then return false end
 if reached and w.stage=='retreat' then
  self:RefreshGraph(c,true)
  if not c.data.graph.edges[1] or not c.data.graph.edges[2] then self:MotionRecovery(c,'walk','changed_cover');return false end
  w.stage='walk';w.destination=copy(w.endPoint);w.targetIndex=3
  w.path={copy(c.data.graph.nodes[2]),copy(c.data.graph.nodes[3])};w.pathIndex=1;w.retries=0
  action(c,'MOOKY WALK: FULL-COURT ADVANCE')
 elseif reached and w.stage=='walk' then
  c.data.walk=nil;c.data.route=3;c.data.recoverUntil=now+5;c.data.nextAttack=now+5;B:Stagger(c,5);action(c,'FAR-SIDE TURN / MAJOR RECOVERY');return false
 end
 if w.stage=='walk' and now>=w.nextLeg then
  w.nextLeg=now+1.4
  for _,side in ipairs({'left','right','back'}) do local p=B:Floor(c,self:RigPoint(c,side,true))
   if p then B:Zone(c,{kind='mooky_leg_column',label='MOVING STRIDER LEG',pos=p,radius=95,delay=.55,life=.18,interval=1,
    damage={kind='melee',damage=20,reference=18,push=210,origin=p}}) end
  end
 end
 if w.stage=='walk' and now>=w.nextFire and targets[1] then w.nextFire=now+2;self:FireLane(c,copy(targets[1]:GetPos()),'pulse',1) end
 return true
end
function D:BeforeDamage(c,actor,info)
 if actor~=c.actor then return end
 if c.now<(c.data.lowerUntil or 0) then local p=info:GetDamagePosition()
  if p and p.z>actor:GetPos().z+230 then info:ScaleDamage(1.2) end
 end
end
function D:AfterDamage(c,actor,amount,attacker,position)
 if actor~=c.actor or not position or c.now<(c.data.lowerUntil or 0) then return end
 for _,side in ipairs({'left','right'}) do local k=c.data.knees[side]
  if c.now>=k.guard and position:DistToSqr(self:RigPoint(c,side,false))<=72^2 then
   if c.now-k.last>4 then k.damage=0 end;k.damage=k.damage+amount;k.last=c.now
   if k.damage>=actor:GetMaxHealth()*.045 then
    k.damage=0;k.guard=c.now+12;c.data.lowerUntil=c.now+4.2;c.data.recoverUntil=c.now+3.2;c.data.step=nil;c.data.walk=nil
    B:Stagger(c,3.2);B:Stop(c,c.actor);c.actor:SetNW2Float('LOD_MookyLowerUntil',c.data.lowerUntil)
    c.data.protectedSide=side;c.actor:SetNW2String('LOD_MookyProtectedKnee',side);action(c,string.upper(side)..' KNEE BUCKLES / BODY EXPOSED')
    B:Log(c,'MOOKY_KNEE_STAGGER',{side=side,protection=12,lowered=4.2,sharedHP=true})
   end
   return
  end
 end
end
function D:Think(c,now,dt,targets)
 if now>=c.data.rigAt then c.data.rigAt=now+.25
  local side=c.data.protectedSide;if side and now>=c.data.knees[side].guard then c.data.protectedSide=nil;c.actor:SetNW2String('LOD_MookyProtectedKnee','') end
  c.actor:SetNW2Vector('LOD_MookyLeftKnee',self:RigPoint(c,'left',false));c.actor:SetNW2Vector('LOD_MookyRightKnee',self:RigPoint(c,'right',false))
 end
 if not targets[1] or not self:EnsureHardCover(c) then return end
 if self:ServiceWalk(c,now,targets) then return end
 self:ServiceStep(c,now)
 if c.data.step then return end
 if now<(c.data.recoverUntil or 0) or now<c.data.nextAttack then return end
 c.data.cycle=c.data.cycle+1;local n=c.data.cycle;local p=copy(targets[(n-1)%#targets+1]:GetPos())
 if c.phase>=2 and c.now<(c.data.lowerUntil or 0) then self:Pulse(c,p);action(c,'PARTIALLY LOWERED FIRE');return end
 local grammar=c.phase==1 and {'pulse','stomp','sweep','step','walk'} or c.phase==2 and {'heavy','container','step','laser','stomp','walk','sweep'}
  or {'hunter','triple','jitter','laser','walk','heavy','sweep'}
 local move=grammar[(n-1)%#grammar+1]
 if move=='pulse' then self:Pulse(c,p)
 elseif move=='stomp' or move=='triple' then self:Stomp(c,move=='triple')
 elseif move=='sweep' then self:Sweep(c,p)
 elseif move=='step' or move=='hunter' then self:Step(c,move=='hunter')
 elseif move=='heavy' then self:Heavy(c,p)
 elseif move=='container' then self:Container(c)
 elseif move=='laser' then self:Laser(c,p)
 elseif move=='jitter' then self:Jitter(c,p)
 else self:MookyWalk(c) end
end
function D:Phase(c,phase)
 B:Stop(c,c.actor);c.data.step=nil;c.data.walk=nil;c.data.nextAttack=c.now+1.8;c.actor:SetNW2Bool('LOD_MookyDamaged',phase==3)
end
function D:Pause(c) B:Stop(c,c.actor);c.data.step=nil;c.data.walk=nil;c.data.nextAttack=c.now+1.8 end
function D:Retire(c) c.data.step=nil;c.data.walk=nil end
function D:Snapshot(c) return (c.data.action or 'LITTLE MOOKY')..' / KNEES STAGGER / HARD COVER SURVIVES' end
function D:Defeat(c)
 c.data.action='';c.data.deathStage='two_steps_kneel_collapse'
 B:Later(c,7.2,'cosmetic:mooky_caption_hud',function(owner) owner.data.action='LITTLE MOOKY DEFEATED' end)
 B:Later(c,7,'cosmetic:mooky_tink',function(owner) if sound and sound.Play then sound.Play('physics/metal/metal_solid_impact_bullet1.wav',B:Center(owner),65,160,.45) end end)
end
B:Register('little_mooky',D)
