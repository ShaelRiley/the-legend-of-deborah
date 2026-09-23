-- Production event ownership, native hostile death scheduler, attribution and
-- loot handoff. Actor generation/combat has its own production suite. This gate
-- isolates the native spawn boundary and forces useful loot to observe duplicate
-- handoffs; it does not claim Source multiplayer acceptance.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run})
local root,D,Run=F.root,F.D,F.Run
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
LOD.Audio.At=F.noop
LOD.HostileAnimation=nil
SOLID_BBOX,ACT_DIESIMPLE,ACT_IDLE,COLLISION_GROUP_DEBRIS=2,1,2,3
NULL={valid=false}
local insideDamage=false
local timers={}
timer.Create=function(id,delay,_,fn) timers[id]={delay=delay,fn=fn} end
timer.Exists=function(id) return timers[id]~=nil end
timer.Adjust=function(id,delay) assert(timers[id]);timers[id].delay=delay end
timer.Remove=function(id) timers[id]=nil end
local function tick(delta)
 F.now=F.now+delta
 local t=timers.LOD_HostileDeathPresentationShared
 if t then t.fn() end
end
local a,b=equipment.actor('76561198000000001'),equipment.actor('76561198000000002')
for n=#F.online,1,-1 do table.remove(F.online,n) end
for _,p in ipairs({a,b}) do
 p.SteamID64=function(self) return self.id end
 p.ps.deploymentComplete=true;p.ps.lives=3
 F.online[#F.online+1]=p
end
Run.State.PlayerState={[a.id]=a.ps,[b.id]=b.ps}
function Run:GetPlayerState(p) return type(p)=='table' and p.ps or self.State.PlayerState[p] end
LOD.CharacterProgressionSystem.SyncPlayer=F.noop
LOD.CharacterProgressionSystem._ApplyPlayerMaxHP=F.noop
dofile(root..'sv_rpg_gate_d.lua')
local Attribution=LOD.CombatAttributionSystem
local encounters,killHooks=0,0
LOD.EncounterDirector={OnHostileKilled=function(_,h,damage)
 encounters=encounters+1
 assert(insideDamage and h.LODDead)
 h:OnKilled(damage) -- Real extension re-entry must not double-settle.
end}
hook.Run=function(id,...)
 if id=='OnNPCKilled' then
  killHooks=killHooks+1
  F.hooks.LOD_RPG_GateD_XPSettlement(...)
 end
end
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local hostileClass=ENT
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_gate/init.lua')
local gateClass,nativeCreate=ENT,ents.Create
ents.Create=function(class)
 local e=nativeCreate(class)
 if class=='lod_gate' then
  setmetatable(e,{__index=gateClass})
  for _,field in ipairs({'GateIndex','GateAxis','Opened','OpenedAt','Solid'}) do
   e['Set'..field]=function(self,v)
    assert(not insideDamage,'Native barrier mutation inside OnKilled')
    self[field]=v
   end
   e['Get'..field]=function(self) return self[field] end
  end
  e.GetNotSolid=nil
  function e:IsSolid() return self:GetSolid()~=SOLID_NONE and not self.NotSolid end
  e.SetCollisionBounds,e.AddEFlags,e.CollisionRulesChanged=F.noop,F.noop,F.noop
  function e:Spawn() self:Initialize() end
 elseif class=='lod_hostile' then
  setmetatable(e,{__index=hostileClass})
  e.hp,e.mutations=100,0
  function e:Health() return self.hp end
  local function native(self) assert(not insideDamage,'Native corpse mutation inside OnKilled');self.mutations=self.mutations+1 end
  e.SetNW2Bool,e.SetNW2Entity,e.SetNW2Float=native,native,native
  e.SetVelocity,e.SetCollisionGroup,e.SetSolid,e.SetMoveType=native,native,native,native
  e.DrawShadow,e.StartActivity,e.SetPlaybackRate=native,native,native
  e.loco={SetDesiredSpeed=function() native(e) end}
  function e:SetNoDraw(v) native(self);self.NoDraw=v end
  function e:Remove() assert(not insideDamage);self:OnRemove();self.valid=false end
 end
 return e
end
dofile(root..'sv_skeleton_hero.lua')
LOD.SkeletonHero.Spawn=function(_,director,i,g)
 local h=ents.Create('lod_hostile')
 if not IsValid(h) then return end
 if not director:Track(i,h) then h:Remove();return end
 h.LODHostile=true;h.LODSkeletonHero=true;h.LODActivated=true;h.LODArchetypeId='runner';i.hostile=h
 h.LODEventRole='hostile';h.LODSkeletonRole='hostile'
 h.LODInstanceSeed=i.seed;h.LODProgressionState={level=1,classId='fighter'}
 h:SetPos(LOD.MazeBuilder:CellCenter(g.Cells[i.cellKey]))
 return h
end
dofile(root..'sv_maze_navigator.lua')
dofile(root..'sv_safe_teleport.lua')
local builder=LOD.MazeBuilder.Build
dofile(root..'sv_progression_builder.lua');LOD.MazeBuilder.Build=builder
dofile(root..'sv_event_skeleton_blockade.lua')
dofile(root..'sv_maze_navigator.lua')
ents.FindByClass=function(class)
 local found={};for _,e in ipairs(F.created) do if IsValid(e) and e:GetClass()==class then found[#found+1]=e end end;return found
end
dofile(root..'sv_phase_zero_runtime_optimization.lua')
local S=LOD.EventSkeletonBlockade
Run.PutInRestrictedSpectator=F.noop
LOD.ProgressionDirector.Announce,LOD.ProgressionDirector.SyncAll=F.noop,F.noop
-- Actual canonical loot ownership/deduplication, forced success only below its
-- category/native-pickup boundary so assertions are independent of drop luck.
dofile(root..'sv_loot_director.lua')
local Loot=LOD.LootDirector
local drops=0
Loot._DropCategory=function() return 'health',false end
Loot._SpawnEnemyResult=function() drops=drops+1;return true end
Loot.TraceStage=F.noop
local function activate()
 Run.State.Failed=nil;Run.State.Finalized=nil;Run.State.LevelCleared=nil
 Run.State.BuildReady=true;Run.State.SimulationFrozen=nil;Run.State.CampaignClock=nil
 local ok,plan=D:Plan(Run.State.Graph,{preview='skeleton_blockade'})
 assert(ok,tostring(plan));assert(D:Activate(Run.State.Graph,plan))
 local i=assert(plan.instances[1]);assert(S.Owned(D,i))
 return i,i.hostile,i.barrier
end
local damageLive=true
local function damage(p,n)
 return {GetAttacker=function() assert(damageLive,'Retained native DamageInfo');return p end,
  GetInflictor=function() assert(damageLive,'Retained native DamageInfo');return p end,
  GetDamage=function() return n end}
end
local function contribute(h)
 damageLive=true
 h.hp=100;Attribution:Record(h,damage(a,60));h.hp=40;Attribution:Record(h,damage(b,40))
 h.hp=0
end
local function kill(h)
 damageLive=true;insideDamage=true
 h:OnKilled(damage(b,40))
 insideDamage=false;damageLive=false
end
local function totals() return (a.ps.progressionState.xp or 0)+(b.ps.progressionState.xp or 0) end
local i,h,barrier=activate()
local initialXP,initialDrops=totals(),drops
-- Calling death/payout APIs on a living actor does not turn an obstruction into
-- a reward dispenser. A missing authoritative combat receipt remains decisive.
assert(not S.AcceptDeath(h,damage(a,1)))
assert(not S.RewardOwned(h))
Loot:OnHostileLootHandoff(h)
assert(drops==initialDrops and not h.LODLootHandoffCompleted)
contribute(h)
local beforeA,beforeB=a.ps.progressionState.xp or 0,b.ps.progressionState.xp or 0
local edge=Run.State.Graph.Edges[i.placement.edgeKey]
local nav=LOD.MazeNavigator
assert(not nav:FindPath(Run.State.Graph,edge.a,edge.b))
local cache=Run.State.Graph.LODPhaseZeroNavCache
kill(h)
assert(h.LODDead and i.combatDeath and i.deathHostile==h)
assert(i.state=='active' and not barrier:GetOpened() and h.mutations==0,'Opening/corpse work escaped native scheduler')
assert(encounters==1 and killHooks==1)
assert(totals()>initialXP and (a.ps.progressionState.xp or 0)>beforeA and (b.ps.progressionState.xp or 0)>beforeB,'Both actual contributors require XP')
local settlement=assert(h.LODRPGXPSettlement)
assert(totals()-initialXP==settlement.value and settlement.killer==b.id)
local paidXP=totals()
kill(h);Attribution:Settle(h)
assert(totals()==paidXP and encounters==1 and killHooks==1,'Duplicate lethal hook paid twice')
tick(.01)
assert(i.state=='resolved' and barrier:GetOpened() and not barrier:IsSolid())
assert(#nav:FindPath(Run.State.Graph,edge.a,edge.b)==2 and Run.State.Graph.LODPhaseZeroNavCache~=cache,'Opening failed to refresh optimized paths')
local recipient=F.actor('76561198000000003');recipient.active=false
D:SyncPlayer(recipient)
local packet=F.packets[#F.packets]
assert(packet.recipient==recipient and packet.body.events[1].state=='resolved','Late join did not receive shared opening')
S.ResolveDeath(h);h:_BeginDeathPresentation();Attribution:Settle(h)
assert(totals()==paidXP and i.state=='resolved')
tick(1.3)
assert(drops-initialDrops==2 and not IsValid(h),'Exactly one ordinary loot roll per active Hero required')
Loot:OnHostileLootHandoff(h);S.ResolveDeath(h)
assert(drops-initialDrops==2 and totals()==paidXP)
-- Normal corpse retirement never produces a new live-loss failure.
F.hooks.LOD_DungeonEventThink();S.Tick(D,i);assert(not Run.State.Failed)

-- Identical seed, run and graph do not confer ownership across replacement.
local old,oldHostile=activate();contribute(oldHostile);kill(oldHostile)
local afterOldDeath=totals()
local fresh,freshHostile,freshBarrier=activate()
assert(not IsValid(oldHostile) and not D:IsCurrent(old))
S.ResolveDeath(oldHostile);Attribution:Settle(oldHostile);Loot:OnHostileLootHandoff(oldHostile);tick(1.4)
assert(fresh.state=='active' and not freshBarrier:GetOpened() and totals()==afterOldDeath and drops==initialDrops+2)
-- Exact pair identity, not arbitrary copied fields or a recycled entity index.
local impostor=ents.Create('lod_hostile');impostor.LODEventInstance=fresh;impostor.LODHostile=true;impostor.hp=0
impostor.LODSkeletonHero=true;impostor.LODSkeletonRole='hostile';impostor.LODEventRole='hostile';impostor.index=freshHostile:EntIndex()
assert(not S.AcceptDeath(impostor,damage(a,1)) and not S.RewardOwned(impostor))
S.ResolveDeath(impostor);assert(not freshBarrier:GetOpened())
impostor:Remove()
local swapped=ents.Create('lod_gate');swapped.LODEventInstance=fresh
fresh.barrier=swapped;freshHostile.hp=0
assert(not S.AcceptDeath(freshHostile,damage(a,1)))
fresh.barrier=freshBarrier;freshHostile.hp=100;swapped:Remove()

-- Time/failure authority blocks a delayed lethal callback even if native entity
-- health is nonpositive. The event remains closed and cannot pay anything.
for _,mode in ipairs({'frozen','expired','failed','cleared'}) do
 local denied,actor,gate=activate();contribute(actor)
 if mode=='frozen' then Run.State.SimulationFrozen=true
 elseif mode=='expired' then Run.State.CampaignClock={deadline=F.now-1}
 elseif mode=='failed' then Run.State.Failed=true
 else Run.State.LevelCleared=true end
 local xp,loot=totals(),drops
 kill(actor);Attribution:Settle(actor);Loot:OnHostileLootHandoff(actor)
 assert(not denied.combatDeath and not gate:GetOpened() and totals()==xp and drops==loot,mode..' accepted stale reward')
end

-- A reversible native opening failure cannot publish a resolved event.
local faulty,corpse,gate=activate();contribute(corpse);kill(corpse)
local setSolid=gate.SetSolid
function gate:SetSolid(v) if v==SOLID_NONE then error('injected native opening failure') end;return setSolid(self,v) end
tick(.01)
assert(faulty.state~='resolved' and not gate:GetOpened() and gate:IsSolid(),'Partial opening was not restored')
gate.SetSolid=setSolid

-- Unexpected live removal never opens or rewards. Use canonical campaign failure
-- and finalization; only native spectator movement/network are engine boundaries.
Run.PutInRestrictedSpectator=F.noop
LOD.ProgressionDirector.Announce,LOD.ProgressionDirector.SyncAll=F.noop,F.noop
local lost,lostHostile,lostBarrier=activate()
local xp,loot=totals(),drops
lostHostile:Remove();assert(lost.state~='resolved' and not lostBarrier:GetOpened())
S.Tick(D,lost)
assert(Run.State.Failed and Run.State.Finalized and not D.Context,'Missing hostile must abort and clean the dungeon')
assert(totals()==xp and drops==loot and not IsValid(lostBarrier))
local missing,liveActor,missingGate=activate()
missingGate:Remove();S.Tick(D,missing)
assert(Run.State.Failed and Run.State.Finalized and not IsValid(liveActor) and not D.Context,'Lost barrier left a live orphan encounter')
-- A legitimate reward callback may replace the dungeon synchronously. The
-- original recipient can receive its earned award; remaining old-run payouts
-- must revalidate the exact encounter after that extension returns.
local reentrant,oldActor=activate();contribute(oldActor)
local award=LOD.CharacterProgressionSystem.AwardHeroXP
local awardCalls,previousState=0,Run.State
LOD.CharacterProgressionSystem.AwardHeroXP=function(self,...)
 awardCalls=awardCalls+1
 local result=award(self,...)
 if awardCalls==1 then
  local replacement={};for k,v in pairs(Run.State) do replacement[k]=v end
  Run.State=replacement -- same seeds and graph, distinct authoritative run-state object
 end
 return result
end
kill(oldActor)
LOD.CharacterProgressionSystem.AwardHeroXP=award
Run.State=previousState;D:Cleanup('reentrant award teardown')
assert(awardCalls==1,'A first XP callback allowed another old-dungeon reward')
local rewardEvent,rewardActor=activate();contribute(rewardActor);kill(rewardActor);tick(.01)
local spawn=Loot._SpawnEnemyResult
local rewardCalls=0
Loot._SpawnEnemyResult=function(...)
 rewardCalls=rewardCalls+1
 local result=spawn(...)
 if rewardCalls==1 then D:Cleanup('replacement inside first loot result') end
 return result
end
Loot:OnHostileLootHandoff(rewardActor)
Loot._SpawnEnemyResult=spawn
assert(rewardCalls==1,'A first loot callback allowed another old-dungeon recipient')
-- An already accepted combat death must not lose its only shared-scheduler
-- callback if the server pauses before deferred presentation begins.
local paused,pausedActor,pausedGate=activate();contribute(pausedActor);kill(pausedActor)
local beforePauseXP,beforePauseLoot=totals(),drops
Run.State.SimulationFrozen=true
tick(.01)
assert(paused.state=='resolved' and pausedGate:GetOpened() and not pausedGate:IsSolid(),'Freeze stranded an accepted lethal event')
tick(1.3)
assert(drops==beforePauseLoot+2 and totals()==beforePauseXP and not IsValid(pausedActor),'Sealed death did not finish ordinary handoff while frozen')
-- The canonical damage seam rejects a still-valid source belonging to a retired
-- run object, even when every seed, level and graph identity is otherwise equal.
local outgoing,outgoingActor=activate()
assert(LOD.SkeletonHero:Live(outgoingActor))
local current=Run.State
local retired={};for k,v in pairs(current) do retired[k]=v end
Run.State=retired
local amount=99
local staleDamage={GetAttacker=function() return outgoingActor end,
 GetDamage=function() return amount end,SetDamage=function(_,n) amount=n end}
assert(GM:EntityTakeDamage(a,staleDamage)==true and amount==0,'Retired Skeleton source damaged a current Hero')
Run.State=current
-- Native creation can return a valid entity whose health/lifecycle was changed
-- during callbacks. Neither case may publish a dungeon or leak either resource.
local createActor=LOD.SkeletonHero.Spawn
for _,failure in ipairs({'zero health','dead flag'}) do
 local first=#F.created+1
 LOD.SkeletonHero.Spawn=function(...)
  local e=createActor(...)
  if failure=='zero health' then e.hp=0 else e.LODDead=true end
  return e
 end
 local ok,plan=D:Plan(Run.State.Graph,{preview='skeleton_blockade'});assert(ok)
 assert(not D:Activate(Run.State.Graph,plan),'Creator accepted '..failure)
 assert(not D.Context)
 for n=first,#F.created do assert(not IsValid(F.created[n]),'Rejected creation leaked '..F.created[n]:GetClass()) end
end
LOD.SkeletonHero.Spawn=createActor
-- Shared opening is sealed before transport, but a reentrant teardown during
-- transport must prevent subsequent native presentation on the removed body.
local synced,syncedActor=activate();contribute(syncedActor);kill(syncedActor)
local savedSync=D.SyncAll
D.SyncAll=function(self) self.SyncAll=savedSync;self:Cleanup('replacement during opening snapshot') end
tick(.01)
assert(synced.state=='cleaned' and not IsValid(syncedActor) and not syncedActor.LODDeathPresentationStarted)
local torn,actor,obstacle=activate();D:Cleanup('lifecycle test teardown')
S.Removed(actor);S.Tick(D,torn);S.ResolveDeath(actor)
assert(not D.Context and not IsValid(actor) and not IsValid(obstacle) and not Run.State.Failed)
assert(#D:Snapshot(a).events==0)
print('SKELETON_LIFECYCLE_PASS: real native-deferred death; two-Hero canonical XP; exactly-once ordinary loot; shared/late-join resolution; path cache refresh; partial-open rollback; entity replacement; clock/failure checks; accepted-death freeze; stale outgoing damage; zero-health/dead creation rejection; live-loss campaign abort; same-seed stale callbacks and cleanup')
