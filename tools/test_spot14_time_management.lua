-- SPOT-14 actual shipped feat/stat/equipment, RunManager, staging and clock paths.
-- Source player/engine transport, time and geometry builders are deterministic
-- boundaries; there is no replacement clock, presence or lifecycle algorithm.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local R,CPS,E,RPG=env.Run,LOD.CharacterProgressionSystem,LOD.Equipment,LOD.RPG
local Effects=RPG.FeatEffectSystem
local noop=function() end
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,'SPOT14: '..msg) end
local function near(a,b,msg) check(math.abs(a-b)<.00001,msg..': '..tostring(a)..' ~= '..tostring(b)) end
local now=1000
SysTime=function() return now end;CurTime=SysTime;RealTime=SysTime
OBS_MODE_NONE=0;OBS_MODE_FIXED=1;OBS_MODE_CHASE=2;NULL={};FCVAR_ARCHIVE=0
Angle=function(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Length() return math.sqrt(self.x^2+self.y^2+self.z^2) end
local origin=LOD.Config.Maze.Origin
LOD.Config.Maze.Origin=Vector(origin.x,origin.y,origin.z) -- native-vector adapter for preloaded config
local vars={}
CreateConVar=function(id,value)
 local cv={value=tonumber(value) or 0};function cv:GetInt() return self.value end
 function cv:GetBool() return self.value~=0 end;vars[id]=cv;return cv
end
GetConVar=function(id) return vars[id] end
CreateConVar('sv_hibernate_think',1)
RunConsoleCommand=function(id,value) check(id=='sv_hibernate_think','only retained hibernation command');vars[id].value=tonumber(value) end
local receivers,commands,packets,packet={},{},{},{}
net.Start=function(id) packet={};packets[id]=packet end
local write=function(v) packet[#packet+1]=v end
for _,name in ipairs({'UInt','Bool','Float','Vector','String','Table'}) do net['Write'..name]=write end
net.Receive=function(id,fn) receivers[id]=fn end;net.Send=noop;net.Broadcast=noop
concommand.Add=function(id,fn) commands[id]=fn end
util.IsValidModel=function() return true end
ErrorNoHalt=function(s) error(s) end
local humans={}
player.GetAll=function() return humans end;player.GetHumans=player.GetAll
ents={FindByClass=function() return {} end}
game={GetMap=function() return 'gm_flatgrass' end,GetAmmoName=function(id) return id end}
LOD.ProgressionDirector={Announce=noop,SyncPlayer=noop,SyncAll=noop,Plan=function() return true end,
 ResetLevelState=noop,CommitBuiltLevel=noop}
LOD.MazeGenerator={CellKey=function(x,y,z) return x..','..y..','..z end,
 Generate=function() return {Cells={},Validation={cellCount=1,criticalVerticalTransitions=0},Attempt=1} end}
LOD.MazeBuilder={Entities={},Cleanup=noop,Build=function() return true,{entityCount=0,startPos=Vector(9,9,9)} end}
LOD.MazeNavigator={CellCenter=function(_,c) return Vector(c.x,c.y,c.z) end}
LOD.WallVisuals={Segments={}}
LOD.LootDirector.EnsureStaticForPlayer=noop -- native loot transmission, not timer admission
LOD.SnapshotDelivery.Queue=noop -- snapshot transport tested by the retained suites
CPS.SyncPlayer=env.syncPlayer -- restore the real stat/lifecycle sync, not its old transport-only test stub
for i=#env.timers,1,-1 do env.timers[i]=nil end
local function flush()
 local count=0
 while #env.timers>0 do
  local fn=table.remove(env.timers,1);count=count+1;assert(count<1000,'native callback boundary failed to settle');fn()
 end
end
dofile(root..'sv_run_manager.lua')
dofile(root..'sv_staging_deployment.lua')
local Staging=LOD.StagingDeployment
Staging.EnsureHut=function() return true end -- gm_flatgrass architecture boundary
Staging.PlacePlayerInHut=function(_,p)
 p:SetNW2Bool('LOD_Staged',true);p:SetNW2Bool('LOD_Deployed',false);p:UnSpectate();return true
end
dofile(root..'sh_campaign_timeout.lua');dofile(root..'sv_campaign_timeout.lua')
dofile(root..'sv_equipment_moves.lua');dofile(root..'sv_magic_hourglass.lua')
local T=LOD.CampaignTimeout
local events={}
LOD.CombatRolls._Send=function(_,actors,category,text,family,fields)
 check(family=='resource','time/Hourglass uses canonical resource family')
 events[#events+1]={actors=actors,category=category,text=text,fields=fields}
end
local function reset()
 now=now+100;humans={};for i=#env.timers,1,-1 do env.timers[i]=nil end
 R.State={RunId='spot14',CampaignEpoch=1,CampaignSeed=73,RosterSeed=73,LevelSeed=7,Level=1,
  BuildReady=true,Graph={Cells={}},BuildReport={startPos=Vector(9,9,9)},
  PlayerState={},ActiveIdentity={},PlayedIdentities={},WaitingSince={},CharacterByIdentity={},
  NextCharacterOrdinal=1,RescueCount=0,HighestLevel=1,Ranked=false,CharacterOrder=LOD.Config.Models.Characters}
 events={}
end
local function setInt(p,score)
 local s=p.ps.progressionState
 CPS:_RecomputeProgressionState(s)
 s.baseAbilities.int=s.baseAbilities.int+score-s.effectiveAbilities.int
 CPS:_RecomputeProgressionState(s)
 check(s.effectiveAbilities.int==score,'real effective INT fixture')
end
local function actor(id,score,owned)
 local p=env.actor(id);local ps=p.ps
 p.observer=OBS_MODE_NONE;p.LODRunSpawnSerial=1;p.LODRunInventoryReady=true
 function p:SteamID64() return self.id end
 function p:Nick() return self.id end
 function p:GetObserverMode() return self.observer end
 function p:Spectate(mode) self.observer=mode end
 function p:UnSpectate() self.observer=OBS_MODE_NONE end
 function p:GetWeapons() local a={};for _,w in pairs(self.weapons) do a[#a+1]=w end;return a end
 function p:GetAmmo() return self.ammo end
 function p:Armor() return 0 end
 function p:SetPos(v) self.pos=v end
 function p:GetPos() return self.pos or Vector() end
 function p:SetLocalVelocity(v) self.velocity=v end
 function p:SetModelScale(v) self.scale=v end
 function p:GetModelScale() return self.scale or 1 end
 function p:GetNW2Int(k,d) return self.nw[k] or d or 0 end
 function p:StripWeapons() self.weapons={} end
 function p:RemoveAllAmmo() self.ammo={} end
 function p:IsAdmin() return true end
 p.SetTeam=noop;p.SetNoCollideWithTeammates=noop;p.CollisionRulesChanged=noop
 p.SetModel=noop;p.SetArmor=noop;p.SetEyeAngles=noop;p.SpectateEntity=noop
 p.SetHull=noop;p.SetHullDuck=noop;p.GetWalkSpeed=function() return 200 end;p.GetRunSpeed=function() return 400 end
 function p:Spawn()
  self.hp=self.max;env.hooks.LOD_PlayerSpawn(self)
 end
 ps.ordinal=#humans+1;ps.heroSerial=1;ps.lives=3;ps.characterName=id;ps.lastPlayerName=id
 ps.deploymentComplete=false;ps.progressionState.featIds=owned==false and {} or {'INT_TIME_MANAGEMENT'}
 ps.progressionState.featCatalogRevision='feat-rebalance-20261002-v1'
 R.State.PlayerState[id]=ps;R.State.ActiveIdentity[id]=true;R.State.PlayedIdentities[id]=true
 humans[#humans+1]=p
 setInt(p,score or 17)
 p:SetNW2Bool('LOD_Staged',true);p:SetNW2Bool('LOD_Deployed',false)
 return p
end
local function deploy(p)
 Staging:_ExecuteDeploymentTransition(p,p.ps,Vector(9,9,9),R.State)
end
local function deadline() return T:Clock().deadline end
local function sync(p) CPS:SyncPlayer(p) end
local ID='INT_TIME_MANAGEMENT'
local definition=RPG.IdentityCatalog.OrdinaryFeats[ID]
check(definition and definition.effectParams.secondsPerIntBonus==60,'registered minute conversion')
check(definition.abilityRequirements.int==17 and #definition.prerequisiteFeatIds==0,'INT 17 only')
check(#definition.allowedActorTypes==1 and definition.allowedActorTypes[1]=='hero','Hero-only catalog')
check(definition.oneRank and not definition.repeatableFallback,'one nonrepeatable ordinary rank')
-- Actual qualification and selected hand, not a label-only registry test.
reset();local p=actor('qualification',16,false);local s=p.ps.progressionState
check(not CPS:_FeatEligible(p.ps,s,definition),'intrinsic 16 cannot qualify')
s.equipmentAbilityDelta.int=10;CPS:_RecomputeProgressionState(s)
check(s.derivedStats.intMod>=3 and not CPS:_FeatEligible(p.ps,s,definition),'gear strengthens effects, not qualifications')
s.equipmentAbilityDelta.int=0;setInt(p,17)
check(CPS:_FeatEligible(p.ps,s,definition),'intrinsic 17 qualifies')
for _,kind in ipairs({'ai','human_soldier'}) do
 s.actorType=kind;check(not CPS:_FeatEligible(p.ps,s,definition),kind..' cannot draft');s.actorType='hero'
end
local saved=RPG.IdentityCatalog.OrdinaryFeats
RPG.IdentityCatalog.OrdinaryFeats={[ID]=definition}
local draft=CPS:_GenerateOrdinaryDraft(p.ps,s,321,1)
check(draft.offerFeatIds[1]==ID and #draft.offerFeatIds==4,'real ordinary priority + legal fallbacks')
RPG.IdentityCatalog.OrdinaryFeats=saved
check(CPS:CommitFeat(p,ID,1),'real Hero commit')
check(draft.selectedFeatId==ID and draft.resolved,'stored exact chosen result')
check(not CPS:CommitFeat(p,ID,1),'same hand cannot grant twice')
check(not CPS:_FeatEligible(p.ps,s,definition),'owned feat cannot be redrafted')
local hand=table.concat(draft.offerFeatIds,'|')
check(CPS:_GenerateOrdinaryDraft(p.ps,s,999,1)==draft and table.concat(draft.offerFeatIds,'|')==hand,'stored draft not rerolled')
for score=3,30 do
 setInt(p,score);near(Effects:TimeManagementSeconds(s),math.max(0,math.floor((score-10)/2))*60,'canonical INT range')
end
s.featIds={ID,ID,ID};setInt(p,17);near(Effects:TimeManagementSeconds(s),180,'duplicate IDs do not stack')
for _,kind in ipairs({'ai','human_soldier'}) do
 s.actorType=kind;near(Effects:TimeManagementSeconds(s),0,kind..' injected ownership still inert');s.actorType='hero'
end
for _,bad in ipairs({math.huge,-math.huge,0/0}) do
 s.derivedStats.intMod=bad;near(Effects:TimeManagementSeconds(s),0,'nonfinite derived data cannot poison clock')
end
setInt(p,17)
-- First real deployment; repeated sync/start never converts a presence into loot.
reset();p=actor('one',17);local q=actor('two',18)
sync(p);check(not deadline(),'staged owner cannot start or contribute')
deploy(p);near(deadline(),now+1980,'first deployment = 30 + 3 minutes')
near(packets[T.Message][3],1980,'existing packet carries augmented time')
local initial=deadline();local eventCount=#events
for i=1,12 do now=now+.25;sync(p);T:Start(p) end
near(deadline(),initial,'repeated updates never bank time');check(#events==eventCount,'quiet refreshes emit no extra resource events')
deploy(q);near(deadline(),initial+240,'second Hero stacks')
near(T:Clock().timeManagementSeconds,420,'party allowance')
local duplicate=actor('one',17);duplicate.ps=p.ps;R.State.PlayerState.one=p.ps;deploy(duplicate)
near(T:Clock().timeManagementSeconds,420,'duplicate identity is counted once')
duplicate.valid=false;T:RefreshTimeManagement();near(T:Clock().timeManagementSeconds,420,'removing duplicate preserves real holder')
-- Current derived INT changes and actual equipped INT item aggregation.
setInt(p,18);sync(p);near(deadline(),initial+300,'INT modifier growth contributes delta only')
setInt(p,16);sync(p);near(deadline(),initial+240,'owned lower INT still uses current modifier')
setInt(p,17);sync(p)
local inv=E:Ensure(p.ps)
local worn
for seed=1,400 do
 local candidate=E:NewItem(p,'ring','spot14-int-'..seed)
 if candidate then
  for _,property in ipairs(candidate.properties or {}) do
   if property.id=='ability_int' and (property.amount or 0)>0 then worn=candidate;break end
  end
 end
 if worn then break end
end
check(worn and E:ValidateWearable(worn),'real generated positive-INT ring fixture')
local beforeGear=p.ps.progressionState.derivedStats.intMod
check(E:StoreWearable(inv,worn),'canonical wearable storage')
local slot='right_hand';check(E:Equip(inv,worn.id,slot),'canonical ring equip')
E:RefreshDerived(p,p.ps)
check(p.ps.progressionState.derivedStats.intMod>beforeGear,'positive INT item changes actual modifier')
near(T:Clock().timeManagementSeconds,(math.max(0,p.ps.progressionState.derivedStats.intMod)+4)*60,'actual equipment refresh composes canonical INT')
E:UnequipItem(inv,worn.id);check(not E:Equipped(inv,slot),'canonical ring removal');E:RefreshDerived(p,p.ps)
near(p.ps.progressionState.derivedStats.intMod,beforeGear,'unequip restores actual INT')
near(T:Clock().timeManagementSeconds,(beforeGear+4)*60,'unequip uses difference, not a new grant')
-- Preflight observes removal even before a scheduled transport/sync tick.
local full=deadline();p.hp=0;T:Expire();near(deadline(),full-180,'death removes exactly one allowance')
p.hp=100;p.LODRunSpawnSerial=p.LODRunSpawnSerial+1;p.LODRunInventoryReady=false;sync(p)
near(deadline(),full-180,'premature new body cannot restore')
p.LODRunInventoryReady=true;T:Start(p);near(deadline(),full,'completed deployed life restores once')
local base=deadline()
for _,mutation in ipairs({'staged','observer','role','eliminated','zero-lives','wrong-floor-dungeon','identity','life'}) do
 local oldSerial=p.ps.heroSerial
 if mutation=='staged' then p:SetNW2Bool('LOD_Staged',true)
 elseif mutation=='observer' then p.observer=OBS_MODE_FIXED
 elseif mutation=='role' then check(R:AttachSoldier(p,197,100,1)~=nil,'real Soldier attach')
 elseif mutation=='eliminated' then p.ps.eliminated=true
 elseif mutation=='zero-lives' then p.ps.lives=0
 elseif mutation=='wrong-floor-dungeon' then p.ps.deployedDungeonLevel=2
 elseif mutation=='identity' then p.ps.heroSerial=oldSerial+1
 elseif mutation=='life' then p.LODRunSpawnSerial=p.LODRunSpawnSerial+1 end
 T:RefreshTimeManagement();near(deadline(),base-180,mutation..' removes holder only')
 p:SetNW2Bool('LOD_Staged',false);p.observer=OBS_MODE_NONE;R:RetireSoldier(p)
 p.ps.eliminated=false;p.ps.lives=3;p.ps.deployedDungeonLevel=1;p.ps.heroSerial=oldSerial
 T:Start(p);near(deadline(),base,mutation..' return is idempotent')
end
-- Disconnect is synchronous while native IsValid is still true; stale callbacks
-- cannot readmit it. Elapsed time continues, and a fresh entity restores once.
local old=p;local ps=p.ps;local id=p.id
R:ReleasePlayer(old);env.hooks.LOD_CampaignClockLeave(old)
near(deadline(),base-180,'disconnect removes old native body')
check(not T:RegisterTimeManagement(old),'stale disconnected body cannot readmit')
now=now+25
p=actor(id,17);R.State.PlayerState[id]=ps;p.ps=ps;deploy(p)
near(deadline(),base,'new connected body restores allowance, not elapsed seconds')
near(T:Remaining(T:Clock(),now),base-now,'rejoin keeps absolute elapsed time')
-- Real death authority, delayed native respawn, and actual ApplyPlayerState path.
reset();p=actor('death',17);q=actor('survivor',18);deploy(p);deploy(q);base=deadline()
p.hp=0;R:HandleDeath(p,q)
check(p.ps.lives==2 and p.ps.respawnAt==now+LOD.Config.Lives.RespawnDelay,'real life debit/lockout')
near(deadline(),base-180,'real death sync revokes allowance')
now=p.ps.respawnAt;p:Spawn();T:RefreshTimeManagement();near(deadline(),base-180,'PlayerSpawn does not grant before apply')
flush();near(deadline(),base,'actual ApplyPlayerState restores after committed native placement')
check(p:GetPos().x==9,'restoration follows canonical checkpoint placement')
-- Real same-dungeon build wrapper and HoldPlayersForBuild must not cause a false
-- departure while its own TryActivatePlayer preflights or delayed spawn run.
base=deadline();local epoch=R.State.CampaignEpoch
check(R:BuildCurrentLevel(),'actual rebuild succeeds with deterministic geometry provider')
near(deadline(),base,'internal build retains offset')
now=now+3;T:Expire();near(deadline(),base,'held build clock continues without rebasing')
flush();near(deadline(),base,'completed rebuilt bodies do not regrant')
check(R.State.CampaignEpoch==epoch,'same rebuild not a new campaign')
-- Established internal hold cannot hide actual loss of life or a role change.
T:HoldTimeManagementForBuild();p.hp=0;T:Expire();near(deadline(),base-180,'real death defeats build hold')
p.hp=100;p.LODRunSpawnSerial=p.LODRunSpawnSerial+1;T:RefreshTimeManagement()
near(deadline(),base-180,'revival cannot reuse a retired hold')
T:Start(p);near(deadline(),base,'completed deployment restores normally')
T:HoldTimeManagementForBuild();setInt(p,30);sync(p)
near(deadline(),base,'held positive stat change waits for deployment')
setInt(p,13);sync(p);near(deadline(),base-120,'held real stat loss is not hidden')
setInt(p,17);sync(p);near(deadline(),base-120,'held loss cannot be refilled by stat toggling')
T:Start(p);near(deadline(),base,'completed deployment releases only the genuine hold')
-- Hourglass source transaction retains every rolled second through allowance
-- gains/losses. A binding captured before an allowance delta is genuinely stale.
reset();p=actor('hourglass',17);deploy(p);base=deadline()
inv=E:Ensure(p.ps);check(E:Grant(p,'magic_hourglass',2) and E:Equip(inv,'magic_hourglass','throwable'),'real Hourglass item')
check(E:Activate(p),'native held Hourglass materialization')
local rolled=0
LOD.CombatRolls._RNG=function(_,label)
 check(label=='magic-hourglass','unchanged dice channel')
 return {Int=function(_,lo,hi) check(lo==1 and hi==4,'plain d4');rolled=rolled+1;return rolled%2==1 and 2 or 3 end}
end
check(E:UseMagicHourglass(p),'actual Hourglass source debit')
near(deadline(),base+300,'five rolled minutes added above allowance')
check(rolled==2 and inv.items.magic_hourglass.count==1,'one item and exactly two dice')
local binding=T:ExtensionBinding();setInt(p,18);sync(p)
local spent=false;check(not T:TryExtend(binding,function() spent=true;return 120 end) and not spent,'changed allowance invalidates stale source binding')
p.hp=0;T:Expire();near(deadline(),base+300-180,'losing changed allowance preserves all Hourglass seconds')
-- Exact old effective deadline wins even when a new holder/stat/Hourglass would
-- make the newly proposed deadline positive. Removing allowance can itself fail.
for _,which in ipairs({'late-deploy','stat','hourglass','rescue','removal'}) do
 reset();p=actor(which,17);deploy(p);base=deadline()
 if which=='removal' then now=base-100;p.hp=0
 else now=base end
 if which=='late-deploy' then q=actor('late',30);deploy(q)
 elseif which=='stat' then setInt(p,30);sync(p)
 elseif which=='hourglass' then
  spent=false;check(not T:TryExtend(T:ExtensionBinding(),function() spent=true;return 480 end) and not spent,'expired callback never debits')
 elseif which=='rescue' then check(not R:CompleteLevel(p),'expired real rescue blocked before rewards')
 else T:RefreshTimeManagement() end
 check(R.State.Failed and T:Clock().scene and R.State.FailureReason=='TIME OVER',which..' irrevocably expires')
 local frozen=deadline();p.hp=100;T:Start(p);near(deadline(),frozen,which..' cannot be resurrected')
 check(R:ApplyPlayerState(p)==false,which..' expired spawn cannot commit')
 check(not R:CompleteLevel(p) and not R.State.LevelCleared,which..' no post-expiry rescue')
end
-- Empty-server clock is still absolute; service checks before scene presentation.
reset();p=actor('empty',17);deploy(p);base=deadline()
R:ReleasePlayer(p);env.hooks.LOD_CampaignClockLeave(p);humans={};R.State.SimulationFrozen=true
near(deadline(),base-180,'last disconnect does not leave ghost bonus')
now=deadline();T:Step();check(R.State.Failed and not T:Clock().scene.started,'empty server expires before anyone reconnects')
-- Actual successful rescue retires clock-local records; a new campaign resets
-- through the real RunManager wrapper with no previous-player/world resurrection.
reset();p=actor('rescue',17);deploy(p)
check(R:CompleteLevel(p),'unexpired actual rescue succeeds')
check(R.State.LevelCleared and not deadline() and not T:Clock().timeManagementActors,'rescue clears deadline + allowances')
near(T:Remaining(T:Clock(),now),1800,'paused next dungeon has base time')
check(not T:Start(p),'intermission cannot start next clock')
humans={};check(R:NewCampaign(),'actual new campaign/build reset')
check(not deadline() and not T:Clock().timeManagementActors,'new campaign has no old body records')
-- Warning rearm and live snapshot use existing clock transport after an increase.
reset();p=actor('warnings',17);deploy(p);T:Clock().deadline=now+500;T:Clock().warned={[600]=true,[300]=true}
setInt(p,21);sync(p)
near(T:Remaining(T:Clock(),now),620,'increase rearms crossed threshold without rebasing')
check(not T:Clock().warned[600] and not T:Clock().warned[300],'warning thresholds rearmed')
near(packets[T.Message][3],620,'existing live packet agrees with authority')
check(events[#events].fields.allowance==300 and events[#events].fields.seconds==120,'one delta resource event')
print('SPOT14_TIME_MANAGEMENT_PASS: '..checks..' production assertions; deterministic native adapters, not native/co-op acceptance')
