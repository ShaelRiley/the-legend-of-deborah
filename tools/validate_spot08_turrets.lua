-- Execute production Gordon + Sentry + native packet guard. Only engine-boundary
-- physics, networking and generated-actor fixtures are doubled; never substitute
-- the placement planner, turret owner, attack scheduler or damage commitment.
local base=dofile('tools/test_warden.lua')
local env,root=base.env,'gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local v=getmetatable(Vector())
v.__div=function(a,b) return a*(1/b) end;v.__unm=function(a) return a*-1 end
function v:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function v:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function v:Normalize() local n=self:GetNormalized();self.x,self.y,self.z=n.x,n.y,n.z end
local am={};am.__index=am
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},am) end
function am:Forward() local y=math.rad(self.y);return Vector(math.cos(y),math.sin(y),0) end
function v:Angle() return Angle(0,math.deg(math.atan(self.y,self.x)),0) end
MASK_SOLID,MASK_NPCSOLID,MASK_PLAYERSOLID=3,4,5
DMG_SLASH=6;ACT_RANGE_ATTACK1=7;ACT_IDLE=4
net.WriteUInt=noop;net.WriteVector=noop;net.WriteBool=noop;net.Broadcast=noop
LOD.RPGPerceptionState={IsInvisible=function(_,p) return p.invisible end}
local status={ActorLives={},CanInitiateAttack=function(_,e) return not e.disabled end,
 CanMoveVoluntarily=function(_,e) return not e.held end,Has=function(_,e,id) return id=='morale_flee' and e.fleeing end,
 AttachDamageContext=noop}
function status:BindActorLife(e) self.ActorLives[e]=self.ActorLives[e] or {} end
LOD.RPGStatusElements=status
LOD.RPGAbilityRules={ProgressionState=function(_,e) return e.progression end,RateOfFireMultiplier=function() return 1 end}
LOD.FactionManager={IsValidPlayerTarget=function(_,p) return IsValid(p) and p:IsPlayer() and p:Alive() and p.active and p:Health()>0 end}
function LOD.FactionManager:CanAcquirePlayerTarget(p) return self:IsValidPlayerTarget(p) and not p.invisible end
dofile(root..'sv_entry_safety.lua')
local exactCell=LOD.EntrySafety.ExactCell
LOD.EntrySafety={ExactCell=exactCell,SpawnCellAllowed=function(_,g,c) return not c.sanctuary end,
 SpawnPositionAllowed=function() return true end,Source=function(_,e) return e.proxyOwner or e end}
LOD.CombatRolls.HostileDamageProfiles={}
local hits,rolls,contexts=0,0,0
local defenseCallback,rollCallback
LOD.CombatRolls.RollHostileAttack=function(_,e,profile,amount)
 rolls=rolls+1;if rollCallback then rollCallback() end
 assert(profile.count==2 and profile.sides==6 and profile.bonus==2,'canonical Sentry damage contract')
 return {total=amount,scale=1,attackEvent={}}
end
LOD.CombatRolls.ResolveActorDamage=function(_,c,e,p,tags)
 contexts=contexts+1;assert(tags.physical and not tags.magic and not tags.melee)
 return 7
end
LOD.CombatRolls.QueueDamageReport=noop
GM={EntityTakeDamage=function() if defenseCallback then defenseCallback() end end}
function DamageInfo()
 local info={}
 function info:SetAttacker(e) self.attacker=e end;function info:GetAttacker() return self.attacker end
 function info:SetInflictor(e) self.inflictor=e end;function info:GetInflictor() return self.inflictor end
 function info:SetDamage(n) self.damage=n end;function info:GetDamage() return self.damage end
 info.SetDamageType=noop;info.SetDamagePosition=noop
 return info
end
dofile(root..'sv_damage_info.lua')
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_crossfire.lua')
local E,W,R,N=LOD.EnemyRoster,LOD.Warden,LOD.RunManager,LOD.MazeNavigator
-- Real Motion seating, without its unrelated native metatable installation.
dofile(root..'sv_hostile_motion_v2.lua')
local M=LOD.HostileMotionV2
M.Stop=noop;M.HoldHitStun=function(_,e,t) return t<(e.LODHitStunUntil or 0) end
M.FaceToward=noop
local serial=0
local function actor()
 local e=base.actor();serial=serial+1;e.serial=serial;e.progression={};e.LODActivated=true;e.LODHostile=true
 e.LODDead=nil;e.hp=100;e.maximum=100;e.angles=Angle();e.active=true;e.alive=true
 e.SetColor=noop;e.GetAngles=function(self) return self.angles end
 e.GetNW2Float=function(self,k,d) return self.nw[k] or d end
 e.GetNW2Int=e.GetNW2Float;e.GetNW2Bool=e.GetNW2Float
 function e:TakeDamageInfo(info)
  if not GM:EntityTakeDamage(self,info) and info:GetDamage()>0 then hits=hits+1;self.hp=self.hp-info:GetDamage() end
 end
 return e
end
local created={}
ents.Create=function() local e=actor();created[#created+1]=e;return e end
local varianceCalls=0
LOD.EnemyVariance.Apply=function(_,e)
 varianceCalls=varianceCalls+1;e.LODVariance={size=1};e:SetHealth(e.LODConfig.baseHP);e:SetMaxHealth(e.LODConfig.baseHP)
end
local geometry,collision=nil,nil
local traceCallback
util.TraceHull=function(t)
 if geometry=='occupied' and t.start:DistToSqr(t.endpos)==0 then return {Hit=true} end
 if collision and t.mins.x==-2 then if traceCallback then traceCallback() end;return {Hit=true,HitPos=collision:GetPos(),Entity=collision,StartSolid=geometry=='startsolid'} end
 return {Hit=false,HitPos=t.endpos}
end
util.TraceLine=function(t)
 if t.mask==MASK_NPCSOLID then
  return {Hit=geometry~='unsupported',HitNormal=Vector(0,0,geometry=='slope' and .1 or 1),
    HitPos=Vector(t.start.x,t.start.y,t.start.z-6),Entity=geometry=='actor_support' and created[1] or nil}
 end
 return {Hit=geometry=='cover',StartSolid=geometry=='startsolid',HitPos=t.endpos}
end
local p=actor();p.player=true;p.LODHostile=false
local p2=actor();p2.player=true;p2.LODHostile=false
local party={p,p2};player.GetAll=function() return party end
R.IsActivePlayer=function(_,who) return who.active and who.player and who.alive end
R.GetPlayerState=function(_,who) return {identity=tostring(who.serial)} end
local g,a=base.graph,base.arena
local activeOverride
LOD.EncounterDirector.GetActiveCount=function()
 if activeOverride then return activeOverride end
 local n=0;for _,e in ipairs(LOD.EncounterDirector.Entities) do if IsValid(e) and not e.LODDead then n=n+1 end end;return n
end
dofile(root..'sv_warden_turrets.lua')
local T=LOD.WardenTurrets
local n=0
local function check(ok,message) assert(ok,'SPOT08: '..message);n=n+1 end
local clock=1000
local function at(t) clock=t;base.time(t) end
local function reset(level)
 T:Retire(T.current);base.flush();T.current=nil
 local s=R.State;s.Warden=nil;s.Level=level or 20;s.Graph=g;s.BuildReady=true;s.SimulationFrozen=false;s.Failed=false;s.LevelCleared=false
 s.LevelSeed=1297;s.CampaignEpoch=1;s.CampaignSeed=42;s.RunId=77;s.GatesOpen={true,true,true,true}
 s.WardenStarted=false;s.JailDoorOpen=false
 g.Progression.Warden=a;geometry=nil;collision=nil;activeOverride=nil;E.Active={};E.Projectiles={}
 LOD.EncounterDirector.Entities={};created={};party={p,p2}
 for _,h in ipairs(party) do h.alive=true;h.active=true;h.hp=100;h.invisible=false;h.progression={};status.ActorLives[h]={};h:SetPos(N:CellCenter(a.center)+Vector(0,0,2)) end
 at(clock+10);check(W:Prepare(),'prepare');check(W:Commit(),'commit')
 return s.Warden,s.Warden.turrets
end
local function first(group)
 for _,slot in ipairs(group.slots) do if slot.admitted then return slot.actor,slot end end
 error('No admitted turret')
end
local function aim(e,h)
 local side=Angle(0,e.LODRosterYaw,0):Forward()
 h:SetPos(e:GetPos()+side*180);h.hp=100;h.active=true;h.alive=true;h.invisible=false
end
local function warning(e)
 aim(e,p);aim(e,p2);p2:SetPos(p2:GetPos()+Vector(0,20,0))
 at(clock+2);E:Cancel(e);e.LODNextAttack=clock;e.LODHitStunUntil=nil;e.disabled=false;e.fleeing=false
 E:Begin(e,p,clock);check(e.LODRosterAttack~=nil,'production Begin warns')
 return e.LODRosterAttack
end
local function release(e)
 local a=warning(e)
 for i=1,3 do at(clock+.2);E:Attack(e,a,clock) end
 at(a.ready);E:Attack(e,a,clock)
 check(a.released and a.shotEmitted,'production Release emitted one bullet')
 return E.Projectiles[#E.Projectiles],a
end
for _,pair in ipairs({{1,0},{4,0},{5,1},{9,1},{10,2},{14,2},{15,3},{19,3},{20,4},{25,4},{100000,4},{-1,0}}) do check(T:Count(pair[1])==pair[2],'threshold '..pair[1]) end
local s=R.State;s.Level=20;s.Graph=g;s.LevelSeed=1297
local plan=T:Plan(s,a);local again=T:Plan(s,a);local seen={}
for i,slot in ipairs(plan) do
 check(not seen[slot.cell],'distinct corner');seen[slot.cell]=true
 check(slot.cell==again[i].cell and slot.pos:DistToSqr(again[i].pos)==0,'stable corner seed')
 check(slot.cell.z==a.center.z,'lower court')
 check(T:Placement(s,a,slot,slot.pos),'actual arena routes and native support preflight')
end
local w,group=reset(20)
check(group.desired==4 and group.admitted==4 and group.skipped==0,'four single-pass slots')
check(#created==9,'one Gordon, four clones, four turrets')
check(varianceCalls>=9,'normal generation invoked')
local e,slot=first(group)
check(e.LODArchetypeId=='sentry' and e:GetMaxHealth()==55,'ordinary reference HP; no boss/party override')
check(not e.LODWarden and not e.LODWardenClone and not e.LODMajorThreat,'no boss-authority masquerade')
check(e.LODNextAttack>=clock+1.2,'initial arming wait')
check(T:Reservation(R.State)==0,'consumed slots release pending reservation')
local before=#created;T:Admit(R.State,w,a);check(#created==before,'idempotent admission')
e.LODDead=true;e.hp=0;T:Service();T:Admit(R.State,w,a)
check(slot.dead and #created==before,'destroyed slot never respawns')
w,group=reset(5);e,slot=first(group);check(group.desired==1,'D5 one slot')
local old=e.hp;p.alive=false;p2.alive=false;T:Service()
check(e.hp==old and slot.admitted and not group.retired,'no-target wait preserves HP/body')
p.alive=true;p2.alive=true
-- Geometry must use the canonical exact-cell query, not navigation's nearest
-- fallback for a void or out-of-map point.
p:SetPos(N:CellCenter(a.center)+Vector(0,0,LOD.Config.Maze.LevelHeight+2))
check(not T:Court(group,p),'upper central void is not a gallery cell')
p:SetPos(N:CellCenter(a.center)+Vector(0,0,-2*LOD.Config.Maze.LevelHeight))
check(not T:Court(group,p),'outside vertical bounds is not nearest court')
local attack=warning(e);check(attack.ready-attack.started>=.75,'minimum full warning')
local frozen=attack.aim;p:SetPos(p:GetPos()+Vector(0,20,0));at(clock+.1);E:Attack(e,attack,clock)
check(attack.aim==frozen,'aim does not track target movement')
e:SetPos(e:GetPos()+Vector(5,0,0));at(clock+.1);E:Attack(e,attack,clock)
check(not e.LODRosterAttack,'source displacement cancels warning');e:SetPos(slot.pos)
attack=warning(e);at(attack.ready+.21);E:Attack(e,attack,clock);check(not e.LODRosterAttack and #E.Projectiles==0,'late warning forfeits')
attack=warning(e);at(clock+.26);E:Attack(e,attack,clock);check(not e.LODRosterAttack,'service gap cancels')
attack=warning(e);p.invisible=true;at(clock+.1);E:Attack(e,attack,clock);check(not e.LODRosterAttack,'invisible target cancels directed fire');p.invisible=false
attack=warning(e);e.disabled=true;at(clock+.1);E:Attack(e,attack,clock);check(not e.LODRosterAttack,'attack prohibition');e.disabled=false
attack=warning(e);e.fleeing=true;at(clock+.1);E:Attack(e,attack,clock);check(not e.LODRosterAttack,'morale interruption');e.fleeing=false
attack=warning(e);e.LODHitStunUntil=clock+1;at(clock+.1);E:Attack(e,attack,clock);check(not e.LODRosterAttack,'ordinary hit stun');e.LODHitStunUntil=nil
attack=warning(e);geometry='cover';at(clock+.1);E:Attack(e,attack,clock);check(not e.LODRosterAttack,'cover cancels warning');geometry=nil
local q;q,attack=release(e)
local prior=hits;collision=p;E.NextService=0;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior+1 and #E.Projectiles==0,'shared swept projectile performs native guarded damage')
E:Damage(e,p,q.event,'bullet');check(hits==prior+1,'same event cannot replay')
q=release(e);p.invisible=true;collision=p;E.NextService=0;prior=hits;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior+1,'invisibility is not immunity to released nonhoming shot');p.invisible=false
q=release(e);status.ActorLives[p]={};collision=p;E.NextService=0;prior=hits;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior,'replacement target life cannot inherit bullet')
q=release(e);collision=p2;defenseCallback=function() p2.progression={} end;E.NextService=0;prior=hits;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior,'native defense callback life replacement rejects HP write');defenseCallback=nil
q=release(e);collision=p;rollCallback=function() R.State.LevelSeed=R.State.LevelSeed+1 end;E.NextService=0;prior=hits;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior,'roll callback changed scope cannot damage');rollCallback=nil
w,group=reset(20);e,slot=first(group)
q=release(e);collision=p;e.held=true;e.muted=true;e.LODHitStunUntil=clock+2;E.NextService=0;prior=hits;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior+1,'released shot survives ordinary stun/Held/Muted');e.held=false;e.muted=false;e.LODHitStunUntil=nil
q=release(e);collision=p;p:SetPos(N:CellCenter(a.entry));E.NextService=0;prior=hits;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior,'entry alcove cannot receive damage')
-- Incoming alcove attacks, including proxy attribution, share the existing gate.
local proxy=actor();proxy.proxyOwner=p;local info=DamageInfo();info:SetAttacker(proxy);info:SetDamage(9)
check(env.hooks.LOD_WardenAlcove(e,info)==true and info:GetDamage()==0,'proxy from alcove blocked')
q=release(e);p.alive=false;p2.alive=false;T:Service();check(not T:ProjectileLive(q,clock),'no-target wait retires released shot')
p.alive=true;p2.alive=true
q=release(e);R.State.SimulationFrozen=true;T:Service();check(not T:ProjectileLive(q,clock) and not group.retired,'freeze quiesces without respawning bodies');R.State.SimulationFrozen=false
check(not T:ProjectileLive(q,clock),'unfreeze cannot revive old shot')
q=release(e);R.State.Failed=true;T:Service();check(group.retired and not T:ProjectileLive(q,clock),'wipe retires all ownership');R.State.Failed=false;base.flush()
check(not IsValid(e),'deferred teardown removes owned living turret')
-- Geometry refusal is per selected slot, with no fallback/retry.
w,group=reset(5);T:Retire(group);base.flush();w.turrets=nil
geometry='occupied';before=#created;T:Admit(R.State,w,a)
check(w.turrets.admitted==0 and w.turrets.skipped==1 and #created==before,'occupied seat skips without body/fallback')
geometry=nil;T:Admit(R.State,w,a);check(#created==before,'no delayed occupied-seat retry')
for _,mode in ipairs({'unsupported','slope','actor_support'}) do
 w,group=reset(5);local seat=T:Plan(R.State,a)[1];geometry=mode
 check(not T:Placement(R.State,a,seat,seat.pos),'reject '..mode);geometry=nil
end
local seat=T:Plan(R.State,a)[1];seat.cell.sanctuary=true
check(not T:Placement(R.State,a,seat,seat.pos),'sanctuary placement rejected');seat.cell.sanctuary=nil
w,group=reset(20);e,slot=first(group);q=release(e)
for i=1,15 do w.hazards[i]={} end
check(not T:Budget(group),'turret cannot exceed shared 16 hazards')
check(not W:AddHazard(w,'orb',e:GetPos(),Vector(),p,clock),'boss cannot exceed same shared 16 hazards')
w.hazards={};E.Projectiles={};for i=1,64 do E.Projectiles[i]={owner=e,expires=clock+2} end
check(not T:Budget(group),'global roster projectile ceiling remains 64')
E.Projectiles={};attack=warning(e)
for i=1,3 do at(clock+.2);E:Attack(e,attack,clock) end
for i=1,16 do w.hazards[i]={} end
at(attack.ready);E:Attack(e,attack,clock)
check(not attack.shotEmitted,'filled budget during warning refuses release');w.hazards={}
-- Exact root/campaign/progression/native-source bindings, including same seed.
for _,field in ipairs({'Level','CampaignEpoch','CampaignSeed','RunId','LevelSeed'}) do
 w,group=reset(5);e=first(group);q=release(e);R.State[field]=R.State[field]+1
 check(not T:ProjectileLive(q,clock),'reject changed '..field)
end
w,group=reset(5);e=first(group);q=release(e);local original=R.State.Graph;R.State.Graph=table.Copy(original)
check(not T:ProjectileLive(q,clock),'same-seed graph replacement');R.State.Graph=original
w,group=reset(5);e=first(group);q=release(e);status.ActorLives[w.actor]={}
check(not T:ProjectileLive(q,clock),'root native life replacement')
w,group=reset(5);e=first(group);q=release(e);e.progression={}
check(not T:ProjectileLive(q,clock),'source progression replacement')
w,group=reset(20);e,slot=first(group);q=release(e)
-- Use the real Gordon death seam; a minimal Hector callback observes immediate
-- retirement and FIFO deferred-body cleanup, without asserting native acceptance.
local handoff=false
LOD.Hector={OnGordonDefeated=function(_,s,root,arena,body)
 check(group.retired and not T:ProjectileLive(q,clock),'Gordon handoff sees retired turret shots')
 timer.Simple(0,function() check(not IsValid(e),'turrets removed before Hector reveal');handoff=true end)
 return true
end}
w.actor.LODDead=true;w.actor.hp=0;w.combatDeath=w.actor
W:Killed(w.actor);check(IsValid(e),'no body deletion inside Gordon lethal callback');base.flush();check(handoff,'Hector continuation retained')
w,group=reset(5);e,slot=first(group);T:Retire(group);e.progression={};base.flush()
check(IsValid(e),'deferred cleanup preserves replacement incarnation')
w,group=reset(5);e,slot=first(group);q=release(e);collision=p;prior=hits
traceCallback=function() e.LODWardenTurret=nil end
E.NextService=0;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks();traceCallback=nil
check(hits==prior,'ownership stripped during collision must not fall through to unguarded damage')
-- Additional admission, native-order and presentation boundaries.
w,group=reset(5);e,slot=first(group)
aim(e,p);aim(e,p2);E:Cancel(e);at(clock+2);e.LODNextAttack=clock
local refresh=e._RefreshTarget;e._RefreshTarget=function() error('ordinary target refresh overwrote arena authority') end
E:Tick(e);check(e.LODRosterAttack and e.LODRosterAttack.target==p,'real AI dispatch uses court-only selection');e._RefreshTarget=refresh
E:Cancel(e);p:SetPos(e:GetPos()-Angle(0,e.LODRosterYaw,0):Forward()*80)
check(not T:Acquire(e,p),'fixed frontal cone can be flanked')
p:SetPos(e:GetPos()+Angle(0,e.LODRosterYaw,0):Forward()*2000)
check(not T:Acquire(e,p),'outside physical Sentry range')
p:SetPos(N:CellCenter(a.entry));check(not T:Acquire(e,p),'entry cannot be acquired')
aim(e,p);p.active=false;check(not T:Acquire(e,p),'non-Hero role cannot be acquired');p.active=true
p.invisible=true;check(not T:Acquire(e,p),'invisible Hero cannot be acquired');p.invisible=false
for _,mode in ipairs({'cover','startsolid'}) do geometry=mode;check(not T:Acquire(e,p),'sight rejects '..mode) end;geometry=nil
local grand={};for i=1,16 do R.State.LevelSeed=1297+i*719;local seats=T:Plan(R.State,a);grand[seats[1].cell]=true end
check(table.Count(grand)==4,'separate seeded stream exposes every corner')
R.State.LevelSeed=1297
local savedRandom=math.random;math.random=function() error('global RNG consumed') end
local rngOK=pcall(T.Plan,T,R.State,a);math.random=savedRandom
check(rngOK,'corner selection does not consume global gameplay RNG')
-- No new lives inherit a released warning; a captured teammate may intercept.
q=release(e);collision=p2;prior=hits;E.NextService=0;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior+1,'captured cooperative Hero can intercept released bullet')
q=release(e);local late=actor();late.player=true;late.LODHostile=false;late:SetPos(p:GetPos());party[#party+1]=late
collision=late;prior=hits;E.NextService=0;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior,'late joining Hero cannot inherit old bullet');party={p,p2}
q=release(e);collision=p;geometry='startsolid';prior=hits;E.NextService=0;at(clock+.025);env.hooks.LOD_EnemyRosterAttacks()
check(hits==prior,'solid-start projectile cannot damage');geometry=nil
q=release(e);at(clock+.26);check(not T:ProjectileLive(q,clock),'released projectile rejects service gap')
q=release(e);at(q.expires);check(not T:ProjectileLive(q,clock),'range-derived expiry is inclusive')
q=release(e);local beforeRun=R.State;R.State={}
for k,vv in pairs(beforeRun) do R.State[k]=vv end
check(not T:ProjectileLive(q,clock),'same-data replacement run object rejected');R.State=beforeRun
q=release(e);local prog=g.Progression;g.Progression={};for k,vv in pairs(prog) do g.Progression[k]=vv end
check(not T:ProjectileLive(q,clock),'same-data replacement progression object rejected');g.Progression=prog
-- Unrelated/new ownership is not cancelled by servicing the stale slot.
local newSlot={};local newAttack={kind='bullet',identity='new'}
e.LODWardenTurret=newSlot;e.LODRosterAttack=newAttack;T:Service()
check(e.LODRosterAttack==newAttack,'old service preserves replacement attack owner')
-- Capacity, actual create failure and post-spawn settlement failure all consume
-- only the selected slot, without a Shambler or delayed retry.
for _,mode in ipairs({'capacity','create','settlement'}) do
 w,group=reset(5);T:Retire(group);base.flush();w.turrets=nil
 local create=ents.Create;local snap=M.SnapSpawn
 if mode=='capacity' then activeOverride=LOD.Config.Encounter.ActiveHostileCeiling
 elseif mode=='create' then ents.Create=function() return nil end
 else M.SnapSpawn=function(_,body) body:SetPos(body:GetPos()+Vector(12,0,0)) end end
 T:Admit(R.State,w,a);local admitted=w.turrets
 check(admitted.admitted==0 and admitted.skipped==1,'single-pass '..mode..' skip')
 ents.Create=create;M.SnapSpawn=snap;activeOverride=nil
 before=#created;T:Admit(R.State,w,a);check(#created==before,mode..' never retries')
end
w,group=reset(20);T:Retire(group);base.flush();R.State.Warden=nil
activeOverride=90;check(W:Prepare() and not W:Commit(),'boss precommit respects turret plus clone/roamer reservation')
activeOverride=nil
w,group=reset(5);local seat=T:Plan(R.State,a)[1]
local neighbor,nextKey=next(seat.cell.neighbors)
seat.cell.neighbors[neighbor]=nil
check(not T:Placement(R.State,a,seat,seat.pos),'broken route refuses placement');seat.cell.neighbors[neighbor]=nextKey
-- Each actual stair heading is checked, not a hardcoded north/south shortcut.
local stairEdges={};for _,edge in ipairs(g.VerticalEdges) do
 if a.court[LOD.MazeGenerator.CellKey(edge.a.x,edge.a.y,edge.a.z)] then stairEdges[#stairEdges+1]=edge end
end
for _,dir in ipairs({'N','S','E','W'}) do
 for _,edge in ipairs(stairEdges) do edge.LODStairDirection=dir end
 check(T:Placement(R.State,a,seat,seat.pos),'corner pocket preserves '..dir..' stair centerline')
end
for _,edge in ipairs(stairEdges) do edge.LODStairDirection=nil end
-- Actual Hector OnGordonDefeated, including reversed timer ordering. The reveal
-- engine-body creation is the boundary spy; its scheduling/ownership is real.
dofile(root..'sv_hector.lua')
w,group=reset(20);R.State.Hector=nil;e,slot=first(group);q=release(e)
local H=LOD.Hector;local spawnH=H.Spawn;local revealed=false
H.Spawn=function(_,h) check(not IsValid(e),'actual Hector handoff drains turrets before reveal');revealed=true end
local simple=timer.Simple;local deferred={};timer.Simple=function(_,fn) deferred[#deferred+1]=fn end
w.actor.LODDead=true;w.actor.hp=0;w.combatDeath=w.actor
W:Killed(w.actor);check(IsValid(e) and group.retired,'native death stack only retires ownership')
check(#deferred==2,'one group retirement plus existing Hector continuation')
for i=#deferred,1,-1 do deferred[i]() end
timer.Simple=simple;H.Spawn=spawnH
check(revealed,'Hector reveal independent of timer ordering')
R.State.Hector=nil
-- Execute existing client Draw, with only unrelated family dispatch disabled.
w,group=reset(5);e,slot=first(group);attack=warning(e)
Material=function(name) return name end
net.Receive=noop;local art,low=0,false
render={SetMaterial=noop,DrawSprite=function() art=art+1 end,DrawBeam=function() art=art+1 end}
EyePos=function() return e:GetPos()+Vector(200,0,60) end
GetConVar=function() return {GetBool=function() return low end} end
function e:GetNW2String(k,d) return k=='LOD_Archetype' and 'sentry' or self.nw[k] or d end
function e:GetNW2Vector(k,d) return self.nw[k] or d end
dofile(root..'cl_enemy_roster.lua')
local V=LOD.EnemyRosterVisual;V.Remains=noop;V.Support=noop;V.Pursuit=noop;V.Reaction=noop
for _,reduced in ipairs({false,true}) do low=reduced;art=0;V:Draw(e,1);check(art==2,'full/reduced Sentry muzzle and lane remain visible') end
at(e.nw.LOD_RosterUntil);art=0;V:Draw(e,1);check(art==0,'fixed client warning expiry cannot linger')
e.nw.LOD_RosterUntil=clock+1;e.nw.LOD_RosterAlive=false;art=0;V:Draw(e,1);check(art==0,'retired Sentry client tells suppressed')

check(rolls>0 and contexts>0,'real canonical damage and guarded packet paths exercised')
print('SPOT08_PASS: '..n..' focused production assertions; native engine/physics/audio acceptance remains open')
