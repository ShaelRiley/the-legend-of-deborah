-- Loads production admission and staging code; engine, geometry, and loot are stubs.
local function noop() end
local commands, enabled = {}, true
function Vector(x,y,z) return {x=x,y=y,z=z} end
Angle = Vector
vector_origin = Vector(0,0,0)
function IsValid(x) return type(x)=='table' and x.valid == true end
function isstring(x) return type(x)=='string' end
function CurTime() return 10 end
function CreateConVar() return {} end
function GetConVar() return {GetBool=function() return enabled end} end
function table.Count(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
function table.Copy(t) local r={} for k,v in pairs(t) do r[k]=v end return r end
hook={Add=noop}; timer={Simple=noop}; concommand={Add=function(n,f) commands[n]=f end}
GM={}; player={GetAll=function() return {} end}
local lootCalls=0
LOD={Config={MaxActivePlayers=2, Campaign={MaxPlayedIdentities=4}, Lives={StartingLives=3}},
 Seeds={Derive=function() return 1 end}, RNG={New=function() return {Shuffle=noop} end},
 CharacterProgressionSystem={InitializeHero=function(_,_,ps) ps.xp=0 end, SyncPlayer=noop,
 IsDeploymentEligible=function(_,ps) return ps.chosen == true end},
 LootDirector={EnsureStaticForPlayer=function() lootCalls=lootCalls+1 end}}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_run_manager.lua')
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_staging_deployment.lua')
local run, staging=LOD.RunManager,LOD.StagingDeployment
local function actor(id)
 local p={valid=true,admin=true,alive=true,id=id,nw={},teleports=0}
 function p:SteamID64() return self.id end
 function p:IsAdmin() return self.admin end
 function p:IsPlayer() return true end
 function p:Alive() return self.alive end
 function p:Nick() return self.id end
 function p:SetNW2Bool(k,v) self.nw[k]=v end
 p.SetNW2Int=p.SetNW2Bool; p.SetNW2String=p.SetNW2Bool
 function p:SetPos(v) self.pos=v; self.teleports=self.teleports+1 end
 p.SetEyeAngles=noop; p.SetLocalVelocity=noop; p.ChatPrint=noop; p.EmitSound=noop
 p.Spectate=noop; p.SpectateEntity=noop
 function p:Give() error('unexpected equipment grant') end
 function p:Spawn() error('unexpected respawn') end
 return p
end
local a,b=actor('a'),actor('b')
local function reset()
 run.State={BuildReady=true,Level=2,LevelSeed=123,CampaignSeed=1,Ranked=true,
 CheckpointPos=Vector(100,200,300),CharacterOrder={{id=1,name='A'},{id=2,name='B'}},
 PlayerState={},ActiveIdentity={},PlayedIdentities={},CharacterByIdentity={},WaitingSince={},Cards={}}
 a.teleports=0; a.admin=true; a.alive=true; enabled=true; lootCalls=0
end
local ingress=commands.lod_dev_enter_maze
reset(); enabled=false; ingress(a); assert(a.teleports==0 and run.State.Ranked)
enabled=true; a.admin=false; ingress(a); assert(a.teleports==0)
a.admin=true; a.alive=false; ingress(a); assert(a.teleports==0)
a.alive=true; ingress(nil); assert(a.teleports==0)
for _,flag in ipairs({'Failed','LevelCleared'}) do
 reset(); run.State[flag]=true; ingress(a); assert(a.teleports==0 and run.State.Ranked)
end
reset(); run.State.BuildReady=false; ingress(a); assert(a.teleports==0)
reset(); run.State.CheckpointPos=nil; ingress(a); assert(a.teleports==0 and next(run.State.PlayerState)==nil)
reset(); run.State.ActiveIdentity={x=true,y=true}; ingress(a)
assert(not run.State.ActiveIdentity.a and next(run.State.PlayerState)==nil and run.State.Ranked)
reset(); run.State.WardenStarted=true; ingress(a); assert(not run.State.PlayerState.a)
reset(); run.State.PlayerState.a={identity='a',lives=0,eliminated=true}; run.State.ActiveIdentity.a=true
ingress(a); assert(a.teleports==0 and run.State.Ranked)
reset(); assert(run:TryActivatePlayer(b)); local peer=run:GetPlayerState(b)
ingress(a); local ps=run:GetPlayerState(a)
assert(run:IsSlotActivePlayer(a) and run:IsActivePlayer(a) and run:IsDungeonPlayer(a))
assert(ps.deploymentComplete and ps.deployedAtLevel==2 and ps.deployedAtLevelSeed==123 and ps.deployedDungeonLevel==2)
assert(a.pos==run.State.CheckpointPos and a.nw.LOD_Deployed and not a.nw.LOD_Staged)
assert(not run.State.Ranked and run.State.UnrankedReason=='developer maze ingress')
assert(not ps.chosen and not ps.starterClaimed and not ps.initialLoadoutGranted and ps.xp==0 and ps.lives==3)
assert(not peer.deploymentComplete and b.teleports==0 and not next(run.State.Cards))
ingress(a); assert(run:GetPlayerState(a)==ps and ps.xp==0 and ps.lives==3 and not ps.starterClaimed)
assert(lootCalls==2) -- ensures ordinary world-loot materialization is still called; not inventory grants.
reset(); assert(run:TryActivatePlayer(a)); ps=run:GetPlayerState(a)
assert(not staging:DeployPlayer(a) and a.teleports==0) -- missing character decisions
ps.chosen=true; local starterChecks=0
staging.EnsureStarterPickup=function() starterChecks=starterChecks+1 end
assert(not staging:DeployPlayer(a) and starterChecks==1 and a.teleports==0)
ps.starterClaimed=true; assert(staging:DeployPlayer(a))
assert(run.State.Ranked and run:IsActivePlayer(a) and a.teleports==1)
assert(not staging:DeployPlayer(a) and a.teleports==1) -- production duplicate denied
print('PASS: developer authorization, production admission/capacity, lives, deployment isolation, unranked bypass, unchanged portal prerequisites')
