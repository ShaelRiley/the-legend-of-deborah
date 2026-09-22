local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
GM=GM or {};dofile(root.."sv_damage_info.lua")
local noop=function() end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
math.Round=function(n) return math.floor(n+0.5) end
net.WriteBool=noop;net.WriteUInt=noop;net.WriteVector=noop;net.WriteFloat=noop;net.WriteEntity=noop;net.WriteString=noop;net.Broadcast=noop
hook.Run=noop
local queued={};timer.Simple=function(_,fn) queued[#queued+1]=fn end
local function flush() local q=queued;queued={};for _,f in ipairs(q) do f() end end
function ErrorNoHalt(s) error(s) end
function Angle() return {} end
local clock=100;env.setTime(clock)
local function time(n) clock=n;env.setTime(n) end
player.GetAll=function() return {env.hero} end
LOD.RunManager.IsActivePlayer=function(_,p) return p==env.hero end
LOD.RunManager.GetPlayerState=function() return {identity='hero-a'} end
LOD.MazeBuilder._Register=noop;LOD.MazeBuilder._BuildProgressionEntities=noop
LOD.WanderingDirector={GetDeficitReservation=function() return 3 end}
LOD.DiceAmmo={GrantWardenResupply=noop}
LOD.Equipment.Grant=function() return true end
LOD.RPGTestLog={Write=noop}
dofile(root..'sh_rng.lua');dofile(root..'sv_maze_generator.lua');dofile(root..'sv_progression_director.lua')
dofile(root..'sv_neil_brute.lua');dofile(root..'sv_warden_arena.lua');dofile(root..'sv_warden.lua');dofile(root..'sv_graph_integrity.lua')
local P,W,N,R,H=LOD.ProgressionDirector,LOD.Warden,LOD.MazeNavigator,LOD.RunManager,LOD.NeilBrute
local key=function(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local graphs={}
for seed=1,24 do
 local g,ok,err
 for attempt=0,30 do g=assert(LOD.MazeGenerator:Generate(seed*1297+attempt));ok,err=P:Plan(g,seed*1297+attempt);if ok then break end end
 assert(ok,err)
 local a=g.Progression.Warden
 assert(g.Width==LOD.Config.Maze.Width+5 and g.Layers<=7)
 assert(LOD.GraphIntegrity:Audit(g).valid)
 local n=0;for _ in pairs(a.court) do n=n+1 end;assert(n==17)
 local blocked={[g.Progression.Gates[4].edgeKey]=true,[g.Progression.JailEdge.edgeKey]=true}
 local reach=H:Walk(g,{key(g.Start)},blocked);assert(not reach[key(a.entry)])
 blocked[g.Progression.Gates[4].edgeKey]=nil
 reach=H:Walk(g,{key(g.Start)},blocked)
 for k in pairs(a.court) do assert(reach[k]) end
 assert(not reach[key(g.Progression.DeborahCell)])
 assert(key(N:WorldToCell(g,N:CellCenter(a.center)))==key(a.center),'extended grid clamped to maze')
 graphs[#graphs+1]=g
end
local g=graphs[1];P:ResetLevelState(g);local s=R.State;s.Graph=g;s.BuildReady=true;s.LevelSeed=1297;s.Level=1
s.GatesOpen={true,true,true,false};s.NeilHunt={started=true};g.CellTags={}
local a=g.Progression.Warden
local created=0
local function actor()
 local e=env.actor(1)
 e.SetNW2String=e.SetNW2Bool;e.SetNW2Int=e.SetNW2Bool;e.SetNW2Float=e.SetNW2Bool
 e.SetNotSolid=noop;e.SetModel=noop;e.DrawShadow=noop;e.SetOpened=noop
 function e:Health() return self.hp or 1000 end
 function e:GetMaxHealth() return self.maximum or 1000 end
 function e:SetHealth(v) self.hp=v end
 function e:SetMaxHealth(v) self.maximum=v end
 function e:SetKeySource(v) self.source=v end
 function e:Spawn() self.LODConfig=table.Copy(LOD.Config.Encounter.Archetypes[self.LODArchetypeId] or {}) end
 function e:OpenGate() self.opened=true end
 return e
end
ents.Create=function() created=created+1;return actor() end
ents.FindByClass=function() return {} end
LOD.EnemyVariance={Apply=function(_,e) e.LODVariance={size=1};e:SetMaxHealth(1000);e:SetHealth(1000) end}
LOD.EncounterDirector.GetActiveCount=function() return 0 end
LOD.EncounterDirector.Entities={}
a.lock.entity=actor()
local p=env.hero;p.hp=40;p.GetMaxHealth=function() return 100 end
p.Health=function(self) return self.hp end;p.SetHealth=function(self,v) self.hp=v end
p.NearestPoint=function(self) return self:GetPos() end
assert(not W:Prepare())
s.GatesOpen[4]=true;assert(W:Prepare());local w=s.Warden
p:SetPos(N:CellCenter(a.entry));assert(W:Protected(p))
W:Resupply(p);W:Resupply(p);assert(p.hp==65,'resupply duplicated')
assert(W:Commit());local e=w.actor;local count=created
assert(s.WardenStarted and s.ObjectiveStage==14 and not W:Commit() and created==count)
assert(not P:EnsureCoreJailKey() and not s.JailKey,'temporary key bypass')
assert(not N:CanTraverse(g,key(a.lock.beforeCell),key(a.lock.afterCell)))
p:SetPos(N:CellCenter(a.center)+Vector(300,0,0))
local shots=0;local add=W.AddHazard
W.AddHazard=function(self,...) shots=shots+1;return add(self,...) end
util.TraceHull=function(t) return {Hit=false,HitPos=t.endpos} end
util.TraceLine=function(t) return {Hit=false,HitPos=t.endpos} end
w.hiddenUntil=101;time(100);W:Tick(e);assert(e.nw.LOD_WardenHidden)
time(101);W:Tick(e);assert(not e.nw.LOD_WardenHidden and shots==0)
for _,t in ipairs({101.7,102,102.3,102.6,103}) do time(t);W:Tick(e) end
assert(shots==4 and #w.hazards==4,'appearance must fire exactly four')
-- Phase transitions clear every old projectile, including delayed damage.
e.hp=600;time(104);W:Tick(e);assert(w.phase==2 and #w.hazards==0 and not e.nw.LOD_WardenHidden)
time(105.1);W:Tick(e);assert(#w.hazards==1 and w.hazards[1].kind=='bomb')
e.hp=250;time(106);W:Tick(e);assert(w.phase==3 and #w.hazards==0 and not w.volley)
time(110);W:Tick(e);assert(shots==5,'ranged attack survived phase three')
-- No-target/death-Tetris wait keeps the same boss, HP and phase.
p.alive=false;time(120);W:Tick(e);assert(e.hp==250 and w.phase==3 and w.actor==e)
p.alive=true
-- Resource ceiling and single authoritative center-key release.
for i=1,30 do add(W,w,'orb',e:GetPos(),Vector(1,0,0),p,clock) end
assert(#w.hazards==16)
local before=created;W:Killed(actor());assert(not w.dead)
W:Killed(e);W:Killed(e);assert(w.dead and #w.hazards==0 and created==before and #queued==1)
flush();assert(created==before+1 and s.JailKeyEntity.source=='gordon_warden')
local card=s.JailKeyEntity;assert(card:GetPos():DistToSqr(N:CellCenter(a.center)+Vector(0,0,LOD.Config.Progression.KeycardHeight))==0)
assert(W:EnsureKey()==card and created==before+1)
p:SetPos(card:GetPos()+Vector(999,0,0));assert(not P:CollectJailKey(p,card))
p:SetPos(card:GetPos());assert(not P:CollectJailKey(p,actor()));assert(P:CollectJailKey(p,card))
assert(not P:CollectJailKey(p,card) and not P:CanRescueDeborah())
assert(P:TryOpenJailDoor(p,actor()) and P:CanRescueDeborah())
-- Wipe state wins over a pending boss-death callback and cannot create a key.
P:ResetLevelState(g);s=R.State;s.Graph=g;s.LevelSeed=1297;s.BuildReady=true;s.GatesOpen={true,true,true,true};s.NeilHunt={started=true}
assert(W:Prepare());assert(W:Commit());w=s.Warden;before=created;W:Killed(w.actor);s.Failed=true;flush()
assert(created==before and not W:EnsureKey())
-- Old callbacks cannot affect a new dungeon, even with the same numeric seed.
s.Failed=false;w.dead=false;W:Killed(w.actor);P:ResetLevelState(g);flush();assert(not R.State.WardenStarted and not R.State.Warden)
print('WARDEN_PASS: 24 arena graphs, two floors/stairs, Black/jail separation, reserve, commitment, resupply, four-shot volley, phase cancellation, respawn persistence, bounded hazards, center key, wipe/stale callback precedence')
-- The actual active floor builder must include the extension and leave the
-- central gallery void open, with perforated floors over both real staircases.
dofile(root..'sv_maze_builder_floor_anchor.lua')
local floors,stairs={},0
LOD.MazeBuilder._BuildFloorRun=function(_,c,last) for x=c.x,last.x do floors[LOD.MazeGenerator.CellKey(x,c.y,c.z)]=true end end
LOD.MazeBuilder._BuildPerforatedFloor=function(_,c) floors[key(c)]=true;stairs=stairs+1 end
LOD.MazeBuilder:_BuildFloors(g)
for k in pairs(a.cells) do assert(floors[k],'missing physical Warden floor '..k) end
for k in pairs(g.WardenVoid) do assert(not floors[k],'gallery void filled') end
assert(stairs==#g.VerticalEdges)
-- Execute the real damage bridge with boundary doubles: a bomb shares its base
-- roll/event across targets, retaining separate defense resolution per target.
s=R.State;s.Graph=g;s.Warden={seed=s.LevelSeed,started=true,phase=2,hazards={},actor=e};w=s.Warden
p.alive=true;p:SetPos(N:CellCenter(a.center));e.hp=1000;e.LODConfig.meleeDamage=8
local rolled,resolved,taken=0,0,0
LOD.CombatRolls.RollHostileAttack=function(_,actor,profile,scale) rolled=rolled+1;return {scale=1,total=12,attackEvent={},profile=profile} end
LOD.CombatRolls.ResolveActorDamage=function(_,contract,attacker,target,tags) resolved=resolved+1;assert(tags.physical and tags.damageContract==contract);return 7 end
LOD.CombatRolls.QueueDamageReport=noop
local context
LOD.RPGStatusElements=LOD.RPGStatusElements or {}
LOD.RPGStatusElements.AttachDamageContext=function(_,info,tags) context=tags end
function DamageInfo() return {SetAttacker=noop,SetInflictor=noop,SetDamage=noop,SetDamageType=noop,SetDamagePosition=noop} end
p.TakeDamageInfo=function() assert(context.actorDamageResolved);taken=taken+1 end
local contract=W:RollAttack(e,'bomb');W:Damage(e,p,'bomb',contract);W:Damage(e,p,'bomb',contract)
assert(rolled==1 and resolved==2 and taken==2,'shared blast re-rolled or skipped per-target defenses')
p:SetPos(N:CellCenter(a.entry));W:Damage(e,p,'bomb',contract);assert(taken==2,'protected alcove damaged')
w.volley={count=2};w.swing={ready=clock+1};W:Interrupt(e);assert(not w.volley and not w.swing)
print('WARDEN_BOUNDARIES_PASS: extended production floors/apertures, shared multi-target blast roll, separate defenses, alcove immunity, interrupted windup cancellation')
-- Ordnance is serviced even when the outer hostile wrapper holds hit stun.
p:SetPos(N:CellCenter(a.center));w.phase=2;e.hp=600;w.hazards={};w.nextHazard=0
W:AddHazard(w,'bomb',p:GetPos(),Vector(),nil,200)
time(204);local explosions=0
function EffectData() return {SetOrigin=noop} end
util.Effect=function() explosions=explosions+1 end;sound={Play=noop}
e.LODHitStunUntil=210
local damageBefore=taken
env.hooks.LOD_WardenOrdnance()
assert(#w.hazards==0 and explosions==1 and taken==damageBefore+1,'hit stun suspended a bomb fuse')
W:AddHazard(w,'bomb',p:GetPos(),Vector(),nil,204);e.hp=250;time(208)
env.hooks.LOD_WardenOrdnance()
assert(w.phase==3 and #w.hazards==0 and explosions==1,'phase three detonated a stale bomb')
print('WARDEN_FUSES_PASS: independent fixed-time fuse, phase threshold cancels ordnance before detonation')
-- Actual hit-stun authority through every installed wrapper. Melee protection
-- belongs to the boss, not the attacking player or all damage categories.
hook.Remove=noop
dofile(root..'sv_shotgun_identity_balance.lua')
dofile(root..'sv_hostile_hurt_pose.lua')
dofile(root..'sv_soldier_shot_contract.lua')
local boss=actor();boss.LODArchetypeId='warden';boss.LODHostile=true
boss.LookupSequence=function() return 1 end;boss.GetSequenceName=function() return 'flinch' end
boss.GetSequence=function() return 1 end;boss.SetSequence=noop;boss.SetCycle=noop;boss.SetPlaybackRate=noop
boss.ResetSequence=noop
local feedback=LOD.M3HitFeedback
time(300);assert(feedback:ApplyHitStun(boss,1,p,nil,'melee'))
assert(boss.LODBossMeleeStaggerReady==303)
time(300.5);assert(not feedback:ApplyHitStun(boss,1,p,nil,'melee'))
assert(feedback:ApplyHitStun(boss,1,p),'firearms retain stun during melee immunity')
time(301);assert(feedback:ApplyHitStun(boss,1,p,2.5),'Wall stun survives every wrapper')
assert(math.abs(boss.LODHitStunUntil-301.75)<1e-6)
time(303);assert(feedback:ApplyHitStun(boss,1,p,nil,'melee'))
local tw={hiddenUntil=320,volley={count=0},swing={}}
boss.LODBossLastDamage=300;time(311);assert(not W:Taunt(tw,boss,clock))
time(312);assert(W:Taunt(tw,boss,clock) and tw.tauntUntil==314 and not tw.volley and not tw.swing)
assert(boss.nw.LOD_WardenHidden==false and boss.nw.LOD_WardenTauntUntil==314)
time(313);env.hooks.LOD_BossDamagePresentation(boss,{GetDamage=function() return 10 end},true)
assert(not W:Taunt(tw,boss,clock) and not tw.tauntUntil and tw.hiddenUntil==316)
boss.LODBossLastDamage=300;time(315);assert(not W:Taunt(tw,boss,clock),'taunt cooldown prevents repeated reveals')
local neil=actor();neil.LODArchetypeId='neil'
env.hooks.LOD_BossDamagePresentation(neil,{GetDamage=function() return 10 end},false)
assert(not neil.nw.LOD_NeilHurtAt)
env.hooks.LOD_BossDamagePresentation(neil,{GetDamage=function() return 10 end},true)
assert(neil.nw.LOD_NeilHurtAt==315)
print('BOSS_FEEDBACK_PASS: shared melee window, preserved gun/Wall stun through wrappers, idle reveal, damage/cooldown cancellation and Neil recoil dispatch')
-- Real bounded clone creation and isolated lifecycle: exact grade thresholds,
-- one-third HP, distinct legal cells, independent attack state, one global budget.
for level,count in pairs({[1]=0,[3]=0,[4]=1,[7]=1,[8]=2,[12]=3,[16]=4,[20]=4,[100]=4}) do assert(W:CloneCount(level)==count) end
LOD.RPGStatusElements.CanInitiateAttack=function() return true end
LOD.RPGStatusElements.CanMoveVoluntarily=function() return true end
s.Level=16;w.clones={};w.cloneStates={};w.dead=false;s.Failed=false;s.LevelCleared=false
w.actor=e;e.hp=1000;e.maximum=1000;w.hazards={};w.phase=1
assert(W:SpawnClones(s,w,a) and #w.clones==4)
local cells={};local afterClones=created
for i,clone in ipairs(w.clones) do
 local body=clone.actor;local cell=key(N:WorldToCell(g,body:GetPos()))
 assert(body:GetMaxHealth()==333 and body:Health()==333 and not cells[cell] and a.court[cell])
 assert(body.nw.LOD_WardenClone==i and not body.LODMajorThreat)
 assert(w.cloneStates[body]==clone);cells[cell]=true
 clone.hiddenUntil=0;time(400+i);W:Tick(body)
 assert(clone.volley and clone.phase==1,'clone uses the real phase scheduler')
end
assert(W:SpawnClones(s,w,a) and created==afterClones,'clone creation is idempotent')
local ids={}
for i=1,16 do
 local owner=(i%2==0) and w or w.clones[1]
 assert(W:AddHazard(owner,'bomb',p:GetPos(),Vector(),nil,clock))
end
assert(not W:AddHazard(w.clones[2],'bomb',p:GetPos(),Vector(),nil,clock))
for _,q in ipairs(W:AllHazards(w)) do assert(not ids[q.id]);ids[q.id]=true end
assert(#W:AllHazards(w)==16,'clones share the sixteen-hazard cap')
local objective=s.ObjectiveStage;W:Killed(w.clones[1].actor)
assert(w.clones[1].dead and not w.dead and s.ObjectiveStage==objective,'clone death cannot complete Gordon')
assert(#W:AllHazards(w)==8,'dead clone ordnance is retired')
local serializedBoss
net.WriteEntity=function(body) serializedBoss=body end
W:Sync();assert(serializedBoss==e,'only the real Gordon owns the boss health bar')
print('WARDEN_CLONES_PASS: dungeon thresholds, exact HP, legal separated spawns, idempotence, shared AI/budget, unique hazard IDs and isolated death/HUD')
local originalTargets,originalRoute=W.Targets,W.Route
local heroes={}
for i=1,4 do heroes[i]=actor();heroes[i]:SetPos(Vector(10000+i*500,10000,0)) end
W.Targets=function() return heroes end
local selected={};W.Route=function(_,body,arena,target) selected[target]=true end
for _,clone in ipairs(w.clones) do
 if not clone.dead then
  clone.actor.hp=50;clone.actor.LODHitStunUntil=nil;clone.actor.LODNextHitStun=nil
  clone.swing=nil;time(clock+1);W:Tick(clone.actor)
 end
end
local selectedCount=0;for _ in pairs(selected) do selectedCount=selectedCount+1 end
assert(selectedCount==3,'three surviving clones prefer three different Heroes')
W.Targets=originalTargets;W.Route=originalRoute
local fullReservation=LOD.WanderingDirector:GetDeficitReservation(g)
local missing=table.remove(w.clones);assert(LOD.WanderingDirector:GetDeficitReservation(g)==fullReservation+1)
w.clones[#w.clones+1]=missing
print('WARDEN_DISTRIBUTION_PASS: separate Hero assignments and retained reservation for missing spawns')
