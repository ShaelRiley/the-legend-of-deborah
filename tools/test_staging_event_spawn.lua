-- Real full-catalog generation, Skeleton synthesis, native hostile Initialize,
-- event ownership and staging handoff. Only engine methods/room presentation
-- are doubled; Remove deliberately preserves IsValid until the next tick.
local F=dofile('tools/event_expansion_fixture.lua')
local root,Run,D=F.root,F.Run,F.D
for _,name in ipairs({'sv_m2_progression_safety.lua','sv_neil_brute.lua',
 'sv_warden_arena.lua','sv_entry_safety.lua','sv_staging_deployment.lua'}) do dofile(root..name) end
for _,cv in pairs(F.convars) do function cv:GetInt() return tonumber(self.value) or 0 end end
util.IsValidModel=function() return true end
NULL={valid=false}
COLLISION_GROUP_NPC,ACT_IDLE,ACT_WALK,ACT_RUN,EF_BONEMERGE=1,2,3,4,5
LOD.HostileAnimation=nil
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local hostileClass=ENT
local nativeCreate=ents.Create
local pending={}
local rejectClass,rejectPhase,rejections=nil,nil,0
ents.Create=function(class)
 local e=nativeCreate(class)
 if not IsValid(e) then return e end
 function e:IsMarkedForDeletion() return self.marked==true end
 function e:Remove()
  if self.marked or not self.valid then return end
  self.marked=true;pending[#pending+1]=self
 end
 e.SetOwner,e.SetParent,e.AddEffects=F.noop,F.noop,F.noop
 if class=='lod_hostile' then
  setmetatable(e,{__index=hostileClass})
  e.hp,e.maxhp=0,0
  function e:Health() return self.hp end
  function e:GetMaxHealth() return self.maxhp end
  function e:SetHealth(hp) self.hp=hp end
  function e:SetMaxHealth(hp) self.maxhp=hp end
  e.SetNW2Entity,e.SetNW2Float,e.SetNW2Vector=e.SetNW2String,e.SetNW2String,e.SetNW2String
  e.GetNW2Bool,e.GetNW2Float,e.GetNW2Int=e.GetNW2String,e.GetNW2String,e.GetNW2String
  e.SetCollisionBounds,e.StartActivity,e.SetPlaybackRate=F.noop,F.noop,F.noop
  e.loco={SetDesiredSpeed=F.noop,SetAcceleration=F.noop,SetDeceleration=F.noop,
   SetStepHeight=F.noop,SetJumpHeight=F.noop}
  function e:Spawn() self:Initialize() end
 end
 for _,phase in ipairs({'Spawn','Activate'}) do
  local native=e[phase]
  e[phase]=function(self,...)
   local result=native(self,...)
   if class==rejectClass and phase==rejectPhase then
    rejections=rejections+1;self:Remove()
    assert(IsValid(self) and self:IsMarkedForDeletion(),'Removal double must retain native validity')
   end
   return result
  end
 end
 return e
end
local function flush()
 -- Source removes entities at the start of the next tick. Cleanup may queue
 -- dependent resources; old ownership must already be invalid by then.
 while #pending>0 do
  local old=pending;pending={}
  for _,e in ipairs(old) do
   if e.OnRemove then e:OnRemove() end
   e.valid=false
  end
 end
 local timers=F.timers
 while #timers>0 do table.remove(timers,1)() end
 F.hooks.LOD_DungeonEventThink()
end
dofile(root..'sv_combat_rolls.lua')
dofile(root..'sv_magic.lua')
dofile(root..'sv_skeleton_hero.lua')
dofile(root..'sh_campaign_timeout.lua')
dofile(root..'sv_campaign_timeout.lua')
Run.PutInRestrictedSpectator=F.noop
LOD.ProgressionDirector.Announce=F.noop
local huts,errors=0,{}
LOD.StagingDeployment.EnsureHut=function()
 assert(Run.State.BuildReady and D.Context,'Staging preceded complete construction')
 huts=huts+1;return true
end
ErrorNoHalt=function(message) errors[#errors+1]=message end
dofile(root..'sv_campaign_bootstrap_reliability.lua')

-- First reproduction: the preceding bootstrap repair accepts layout 14 for
-- this campaign, but puts its Skeleton at 1:9:0 inside the entry apron. Native
-- Initialize removes it; synthesis assigns positive HP before deferred deletion
-- finishes, so IsValid/Health checks alone incorrectly release the campaign.
F.convars.lod_campaign_seed.value='31676'
Run.State={}
F.hooks.LOD_BeginCampaign()
flush()
assert(Run.State.BuildReady,tostring(LOD.CampaignBootstrapReliability.LastError))
local first=Run.State
flush()
assert(not first.Failed,'Staging immediately failed: '..tostring(first.FailureReason))
assert(#errors==0 and huts==1 and Run.State==first)
local skeleton
for _,i in ipairs(D.Context.plan.instances) do if i.archetype=='skeleton_blockade' then skeleton=i end end
assert(skeleton and LOD.EventSkeletonBlockade.Owned(D,skeleton))
assert(LOD.EntrySafety:SpawnCellAllowed(first.Graph,skeleton.cell))
assert(LOD.EntrySafety:SpawnPositionAllowed(skeleton.hostile:GetPos()))
assert(not skeleton.hostile:IsMarkedForDeletion() and not skeleton.barrier:IsMarkedForDeletion())
assert(skeleton.hostile.LODHostile and skeleton.hostile:Health()>0,'Native Initialize did not finish')
print('STAGING_SPAWN_PASS campaign=31676 layout='..first.Graph.ProgressionLayoutAttempt..' cell='..skeleton.cellKey)

-- Entry safety remains bilateral and authoritative: force the formerly chosen
-- cell back into validation and native initialization, independently of planner
-- output. The placement must be refused, and an illicit spawn must still die.
local g=first.Graph
local apron=assert(g.Cells['1:9:0'])
assert(g.CellTags['1:9:0'].entryApron)
local rejectedEdge
for n in pairs(apron.neighbors) do
 local ek='1:9:0'<n and '1:9:0|'..n or n..'|1:9:0'
 if g.Edges[ek] then rejectedEdge=ek;break end
end
assert(not LOD.EventSkeletonBlockade.Validate(nil,g,{cellKey='1:9:0',edgeKey=rejectedEdge}))
local illicit=ents.Create('lod_hostile')
illicit:SetPos(LOD.MazeBuilder:CellCenter(apron)+Vector(0,0,4));illicit:Spawn()
assert(IsValid(illicit) and illicit:IsMarkedForDeletion())
flush();assert(not IsValid(illicit) and not first.Failed)

local builds,epoch,history=F.nativeBuilds,first.CampaignEpoch,WalletJSONEncode(first.EventEcology)
for _,p in ipairs(F.online) do p.ps.inStaging=true;p.ps.deploymentComplete=false end
for step=1,120 do
 F.now=F.now+30
 LOD.CampaignTimeout:Step();flush()
 assert(LOD.CampaignBootstrapReliability:Ensure('staging watchdog',true))
 assert(Run.State==first and first.BuildReady and not first.Failed and first.CampaignEpoch==epoch)
 assert(not LOD.CampaignTimeout:Clock().deadline,'Staging started the dungeon clock')
 assert(LOD.EventSkeletonBlockade.Owned(D,skeleton))
end
assert(F.nativeBuilds==builds and huts==1,'Staging/watchdog regenerated the maze')

-- Same-level replacement queues old native resources for deletion after the
-- new context is live. Their delayed OnRemove cannot fail the replacement.
local oldHostile,oldBarrier=skeleton.hostile,skeleton.barrier
assert(Run:BuildCurrentLevel())
assert(IsValid(oldHostile) and oldHostile:IsMarkedForDeletion())
flush()
assert(not first.Failed and not IsValid(oldHostile) and not IsValid(oldBarrier))
assert(WalletJSONEncode(first.EventEcology)==history and huts==2)

-- Reuse a validated real plan to isolate native creation/activation failures.
-- IsValid alone cannot admit either primary or secondary pending deletions.
local template=table.Copy(D.Context.plan)
local selected=table.concat(template.selected,',')
assert(selected=='skeleton_blockade,memory_terminal')
local function freshPlan()
 local plan=table.Copy(template)
 for _,i in ipairs(plan.instances) do i.entities={};i.hostile=nil;i.barrier=nil end
 return plan
end
local classes={}
for seed=1,24 do
 local profile=LOD.SkeletonHero:Generate(seed,1)
 if not classes[profile.classId] then
  D:Cleanup('native class test');flush()
  local plan=freshPlan();plan.instances[1].seed=seed
  assert(D:Activate(first.Graph,plan))
  flush()
  local i=plan.instances[1]
  assert(LOD.EventSkeletonBlockade.Owned(D,i) and i.hostile.LODHostile)
  assert(i.hostile.LODProgressionState.classId==profile.classId and i.hostile:Health()>0)
  if profile.classId=='rogue' then assert(IsValid(i.hostile.LODWeaponVisual)) end
  classes[profile.classId]=true
 end
 if classes.fighter and classes.rogue and classes.wizard then break end
end
assert(classes.fighter and classes.rogue and classes.wizard,'Native class coverage incomplete')
for _,fault in ipairs({{'lod_hostile','Spawn'},{'lod_hostile','Activate'},
 {'lod_gate','Spawn'},{'lod_gate','Activate'},{'lod_dungeon_event','Activate'}}) do
 D:Cleanup('native rejection test');flush()
 local plan=freshPlan()
 local from=#F.created+1
 rejectClass,rejectPhase,rejections=fault[1],fault[2],0
 local ok,why=D:Activate(first.Graph,plan)
 rejectClass,rejectPhase=nil,nil
 assert(not ok and why:find('event creation failed',1,true) and rejections==1,why)
 assert(not D.Context and not first.Failed,'Partial creation escaped ordinary cleanup')
 flush()
 for n=from,#F.created do assert(not IsValid(F.created[n]),'Rejected creation leaked '..F.created[n]:GetClass()) end
end

-- A later event's native callback can remove the already initialized barrier.
-- The complete build must reject it before BuildReady/staging, retain exposure
-- history, and clean every resource without a silent new campaign.
local definition=F.R.Definitions.memory_terminal
local create=definition.Create
local invalidated=0
definition.Create=function(...)
 local e,err=create(...)
 local barrier=D.Context.plan.instances[1].barrier
 assert(IsValid(barrier));barrier:Remove();invalidated=invalidated+1
 return e,err
end
local from=#F.created+1
local ok,why=Run:BuildCurrentLevel()
definition.Create=create
assert(not ok and why:find('resource lost during construction',1,true) and invalidated==1,why)
assert(not first.BuildReady and not D.Context and not first.Failed and huts==2)
assert(WalletJSONEncode(first.EventEcology)==history)
flush()
for n=from,#F.created do assert(not IsValid(F.created[n]),'Failed full build leaked native resources') end
assert(Run:BuildCurrentLevel());flush()
assert(first.BuildReady and not first.Failed and huts==3 and first.CampaignEpoch==epoch)
assert(table.concat(D.Context.plan.selected,',')==selected and WalletJSONEncode(first.EventEcology)==history)
D:Cleanup('staging regression complete');LOD.MazeBuilder:Cleanup();flush()
assert(not first.Failed and #errors==0)
print('PASS staging native spawn: three-class Skeleton synthesis/Initialize, arrival rejection, delayed deletion, hour-long staging, no watchdog reset, same-level replacement, primary/secondary partial creation, late resource loss and full-build rollback')
