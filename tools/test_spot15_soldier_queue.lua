-- SPOT-15 actual RunManager, Soldier, revival, equipment and clock paths.
-- Source player/engine transport, time and geometry builders are deterministic
-- boundaries; there is no replacement clock, presence or lifecycle algorithm.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local R,CPS,E,RPG=env.Run,LOD.CharacterProgressionSystem,LOD.Equipment,LOD.RPG
local Effects=RPG.FeatEffectSystem
local noop=function() end
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,'SPOT15: '..msg) end
local function near(a,b,msg) check(math.abs(a-b)<.00001,msg..': '..tostring(a)..' ~= '..tostring(b)) end
local now=1000
SysTime=function() return now end;CurTime=SysTime;RealTime=SysTime
OBS_MODE_NONE=0;OBS_MODE_FIXED=1;OBS_MODE_CHASE=2;NULL={};FCVAR_ARCHIVE=0
Angle=function(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
IN_ATTACK=1;IN_ATTACK2=2;
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
dofile(root..'sv_human_soldier_progression.lua')
dofile(root..'sv_run_manager.lua')
dofile(root..'sv_staging_deployment.lua')
dofile(root..'sv_multiplayer_hardening.lua')
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
 -- Retain actual event production; native delivery is the boundary.
 events[#events+1]={actors=actors,category=category,text=text,fields=fields}
end
local function reset()
 now=now+100;humans={};for i=#env.timers,1,-1 do env.timers[i]=nil end
 R.State={RunId='spot15',CampaignEpoch=1,CampaignSeed=73,RosterSeed=73,LevelSeed=7,Level=1,
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
 local give=p.Give
 function p:Give(...)
  local w=give(self,...)
  if w then w.GetPrimaryAmmoType=function() return 1 end; w.Clip2=function() return 0 end; w.SetClip2=noop end
  return w
 end
 p.observer=OBS_MODE_NONE;p.LODRunSpawnSerial=1;p.LODRunInventoryReady=true
 function p:GetNW2String(k,d) return self.nw[k] or d or "" end
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
  self.spawnCount=(self.spawnCount or 0)+1; self.hp=self.max;env.hooks.LOD_PlayerSpawn(self)
 end
 ps.ordinal=#humans+1;ps.heroSerial=1;ps.lives=3;ps.characterName=id;ps.lastPlayerName=id
 ps.deploymentComplete=false;ps.progressionState.featIds={}
 ps.progressionState.featCatalogRevision='hybrid-stable-150-v1'
 R.State.PlayerState[id]=ps;R.State.ActiveIdentity[id]=true;R.State.PlayedIdentities[id]=true
 humans[#humans+1]=p
 setInt(p,score or 17)
 p:SetNW2Bool('LOD_Staged',true);p:SetNW2Bool('LOD_Deployed',false)
 return p
end
local function eliminate(p)
 p.hp=0;p.ps.lives=0;p.ps.eliminated=true;p.ps.eliminatedSince=900;p.ps.queue='hero'
 R.State.ActiveIdentity[p.id]=nil;p.LODHandledRunDeath=nil;R:_SyncPlayerVars(p)
end
local function soldier()
 reset();local p=actor('queued');local ally=actor('ally');eliminate(p)
 local ps=p.ps;ps.inventory={weapons={},ammo={sentinel=7}};ps.equipment={items={},slots={},sentinel='saved'}
 local saved={ps=ps,inventory=ps.inventory,equipment=ps.equipment,progression=ps.progressionState}
 check(R:JoinSoldierRole(p),'actual Soldier admission')
 local inc=LOD.SoldierProgression:StateFor(p)
 check(inc and inc.soldierIncarnation and not R:IsHeroRevivalQueueEligible(p.id),'generated Soldier outside revival queue')
 return p,ally,saved,inc
end
local function preserved(p,saved)
 check(R:GetPlayerState(p)==saved.ps,'same dormant Hero state')
 check(p.ps.inventory==saved.inventory and p.ps.equipment==saved.equipment,'same saved inventory/equipment references')
 check(p.ps.progressionState==saved.progression,'same Hero progression owner')
 check(p.ps.lives==0 and p.ps.eliminated and p.ps.eliminatedSince==900,'lives and original elimination timestamp retained')
end
for _,destination in ipairs({'hero','spectator'}) do
 for _,waiting in ipairs({false,true}) do
  local p,ally,saved,inc=soldier()
  if waiting then flush();p.hp=0;R:HandleDeath(p);check(p.ps.soldierRespawnWait,'real Soldier death enters wait') end
  p.weapons.test={};p.ammo.test=33
  local ctx=R:TeamMenuContext(p);local before=p.LODRunSpawnSerial
  local cmd=destination=='hero' and 'lod_return_to_hero_queue' or 'lod_spectate_only'
  commands[cmd](p,cmd,{ctx})
  check(not R:IsSoldierControl(p) and not inc.soldierIncarnation and inc.soldierXP==0,'incarnation and XP retired')
  check(next(p.weapons)==nil and next(p.ammo)==nil,'native Soldier weapons AND ammo removed')
  check(p.LODRunSpawnSerial>before and not p.LODRunInventoryReady,'pending native life invalidated')
  check(not p:GetNW2Bool('LOD_Deployed') and not p:GetNW2Bool('LOD_Staged'),'retired body not deployed or staged')
  check(p.ps.queue==destination and not p.ps.soldierRespawnWait and not p.ps.respawnAt,'single queue owner cancels automatic respawn')
  check(R:IsHeroRevivalQueueEligible(p.id)==(destination=='hero'),'distinct resurrection eligibility')
  check(p.nw.LOD_HeroQueue==destination and p.nw.LOD_TeamMenuContext==R:TeamMenuContext(p),'authoritative queue/context synchronization')
  preserved(p,saved)
  local life=p.LODRunSpawnSerial
  commands[cmd](p,cmd,{ctx}) -- stale request must be inert
  check(p.LODRunSpawnSerial==life and p.ps.queue==destination,'stale command cannot replay transition')
  check(R:SetHeroQueueMode(p,destination),'repeat current choice succeeds idempotently')
  check(p.LODRunSpawnSerial==life,'repeat current choice does not retire another life')
  flush();preserved(p,saved)
  check(not R:IsSoldierControl(p) and not p:GetNW2Bool('LOD_Deployed'),'old native Spawn cannot redeploy retired incarnation')
  if waiting then
   check(p.ps.soldierReadyAt==now+20,'exact death readiness survives exit')
   local ok,err=R:JoinSoldierRole(p);check(not ok and err=='soldier respawn delay active','cannot skip death delay by switching queue')
   now=now+19.999;check(not R:JoinSoldierRole(p),'still locked just before deadline')
   now=now+.001;check(R:JoinSoldierRole(p),'fresh Soldier admitted at exact deadline')
   local fresh=LOD.SoldierProgression:StateFor(p)
   check(fresh~=inc and fresh.soldierXP==0,'fresh automatic Soldier profile, never retired profile')
  elseif destination=='hero' then
   check(R:ReviveIdentity(p.id),'real queue revival after live Soldier return')
   check(p.ps.lives==1 and not p.ps.eliminated,'revival grants exactly one life')
   local count=p.spawnCount;flush()
   check(p.spawnCount==count+1,'alive former Soldier still gets fresh Hero Spawn')
   check(p.ps.inventory==saved.inventory and p.ps.equipment==saved.equipment,'revival preserves original inventory')
  else
   check(not R:ReviveIdentity(p.id),'explicit spectator not revived')
   p.valid=false;check(not R:IsHeroRevivalQueueEligible(p.id),'disconnected explicit spectator still excluded')
   p.valid=true;check(not R:TryActivatePlayer(p),'reconnect does not auto-admit explicit spectator')
   check(R:ReturnToHeroQueue(p) and R:IsHeroRevivalQueueEligible(p.id),'explicit return restores future eligibility')
  end
 end
end
-- Advance the actual dungeon owner with a voluntarily spectating saved Hero.
local p,ally,saved=soldier();check(R:SpectateOnly(p),'spectator before advance');flush()
R.State.LevelCleared=true
check(R:AdvanceLevel(),'actual successful advance')
check(p.ps.queue=='spectator' and p.ps.lives==1 and not p.ps.eliminated,'comeback life does not revoke spectator choice')
check(not R.State.ActiveIdentity[p.id] and not R:TryActivatePlayer(p),'positive-life spectator not automatically admitted')
check(p.ps.inventory==saved.inventory and p.ps.equipment==saved.equipment,'advance retains dormant Hero gear')
local count=p.spawnCount
check(R:ReturnToHeroQueue(p),'positive-life spectator returns')
check(p.ps.lives==1 and p.spawnCount==count+1,'positive life preserved and fresh Hero spawn issued')
flush();check(not R:IsSoldierControl(p),'positive-life return is Hero, not Soldier')
-- A full team leaves that life in the ordinary admission queue.
p,ally,saved=soldier();check(R:SpectateOnly(p),'full-slot setup');flush()
p.ps.lives=1;p.ps.eliminated=false
for i=1,3 do actor('occupied'..i) end
count=p.spawnCount;check(R:ReturnToHeroQueue(p),'full-slot queue return accepted')
check(p.ps.queue=='hero' and p.ps.lives==1 and not R.State.ActiveIdentity[p.id] and p.spawnCount==count,'full team keeps one life waiting')
R.State.ActiveIdentity.occupied1=nil;humans[#humans].valid=false -- explicit vacancy
check(R:PromoteWaitingSpectators()>=1,'existing admission promotes waiting Hero')
check(R.State.ActiveIdentity[p.id] and p.spawnCount==count+1,'one fresh spawn after slot opens')
-- Server validation rejects stale views and true locks before any retirement.
for _,lock in ipairs({'build','failed','clear','tetris','quiz','expiry'}) do
 p,ally,saved,inc=soldier();flush()
 if lock=='build' then R.State.BuildReady=false
 elseif lock=='failed' then R.State.Failed=true
 elseif lock=='clear' then R.State.LevelCleared=true
 elseif lock=='tetris' then LOD.DeathTetris={IsActiveFor=function() return true end}
 elseif lock=='quiz' then LOD.Equipment.InventoryLocked=function() return true end
 elseif lock=='expiry' then T:Clock().deadline=now end
 local ctx=R:TeamMenuContext(p);commands.lod_spectate_only(p,'',{ctx})
 if lock~='expiry' then check(R:IsSoldierControl(p),'locked '..lock..' cannot retire Soldier')
 else check(R.State.Failed and T:Clock().scene,'authoritative TIME OVER wins at deadline') end
 check(p.ps.queue=='soldier' and p.ps.lives==0,'locked '..lock..' cannot queue or revive')
 LOD.DeathTetris=nil;LOD.Equipment.InventoryLocked=nil
end
for _,change in ipairs({'campaign','hero','life','role'}) do
 p,ally,saved=soldier();local ctx=R:TeamMenuContext(p)
 if change=='campaign' then R.State.CampaignEpoch=R.State.CampaignEpoch+1
 elseif change=='hero' then p.ps.ordinal=p.ps.ordinal+1
 elseif change=='life' then p.LODRunSpawnSerial=p.LODRunSpawnSerial+1
 else R:ReturnToHeroQueue(p) end
 local queue=p.ps.queue;local serial=p.LODRunSpawnSerial
 commands.lod_begin_new_hero(p,'',{ctx});commands.lod_spectate_only(p,'',{ctx})
 check(R:GetPlayerState(p)==saved.ps and p.ps.queue==queue and p.LODRunSpawnSerial==serial,'stale '..change..' commands rejected')
end
reset();p=actor('hero');local ps=p.ps
check(not R:ReturnToHeroQueue(p) and not R:SpectateOnly(p) and not R:BeginNewHero(p),'ordinary living Hero choices cannot become role escape')
check(ps.lives==3 and R.State.ActiveIdentity[p.id],'living Hero state unchanged')
check(not R:SetHeroQueueMode(p,'forged'),'unknown queue rejected')
print('SPOT15_SERVER_PASS '..checks..' actual-production assertions')

-- Reused by the next focused weapon gate; all SPOT-15 assertions above still run.
return {env=env, Run=R, actor=actor, soldier=soldier, reset=reset, flush=flush,
    preserved=preserved, commands=commands, receivers=receivers,
    now=function(value) if value then now=value end;return now end}
