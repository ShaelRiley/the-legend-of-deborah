-- Actual post-mitigation HP loss, sealed timing RNG, fractional capped payouts,
-- and every retained actor/run identity boundary. No damage dice are consulted.
local base = 'gamemodes/legend_of_deborah/gamemode/lod/'
local timers, events = {}, {}
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
function IsValid(v) return type(v)=='table' and v.valid~=false end
function GetConVar() return nil end
concommand={Add=function() end}
hook={Run=function(...) events[#events+1]={...} end}
timer={Simple=function(delay,fn) timers[#timers+1]={delay=delay,fn=fn} end}
LOD={RPG={IdentityCatalog={OrdinaryFeats={}},FeatEffectSystem={}},RPGAbilityRules={},
 CharacterProgressionSystem={},RunManager={State={CampaignEpoch=1,Level=3,LevelSeed=123,Graph={}}},
 Magic={},RPGStatusElements={ActorLives={}}}
local E,R,M,S=LOD.RPG.FeatEffectSystem,LOD.RPGAbilityRules,LOD.Magic,LOD.RPGStatusElements
function E:ApplyDerived() end
function R:ProgressionState(a) return a.state end
function R:Derived(a) return a.state.derivedStats end
function M:_EnsureState(a) return a.pool end
function M:_Sync() end
function S:BindActorLife(a) self.ActorLives[a]=self.ActorLives[a] or {} end
function S:DamageContext(info) return info.tags end
function LOD.CharacterProgressionSystem:BuildClientSnapshot() return {} end
dofile(base..'sh_rng.lua')
dofile(base..'sv_rpg_gate_e_magic_recovery.lua')
local ok, errors=E:ValidateMagicRecoveryFamilies();assert(ok,table.concat(errors,';'))
local function actor(id,feats)
 local a={health=100,alive=true,LODRunSpawnSerial=1,LODCombatLifeSerial=1,
  state={actorId=id,featIds=feats,derivedStats={}},pool={magic=10}}
 function a:IsPlayer() return true end
 function a:Alive() return self.alive end
 function a:Health() return self.health end
 function a:EntIndex() return 1 end
 return a
end
local owner=actor('owner',{'INT_ARC_RECOVERY','INT_FEEDBACK_LOOP'})
local target=actor('target',{'INT_FEEDBACK_LOOP'})
local function damage(amount,magic)
 local info={amount=amount,tags={magic=magic},owner=owner}
 function info:GetDamage() return self.amount end
 function info:GetAttacker() return self.owner end
 return info
end
local function flush()
 local pending=timers;timers={}
 for _,t in ipairs(pending) do assert(t.delay>=1 and t.delay<=4 and t.delay%1==0);t.fn() end
 return pending
end
local info=damage(99,true)
E:CaptureDamageRecovery(target,info);target.health=94.5
assert(E:FinishDamageRecovery(target,info,true)==5.5)
assert(#timers==2 and owner.pool.magic==10 and target.pool.magic==10,'no immediate recovery')
assert(E:FinishDamageRecovery(target,info,true)==0 and #timers==2,'same canonical target event only once')
local once=flush();assert(owner.pool.magic==12.75 and target.pool.magic==12.75,'actual HP, not incoming amount; fractions retained')
for _,t in ipairs(once) do t.fn() end
assert(owner.pool.magic==12.75 and target.pool.magic==12.75,'callback cannot duplicate itself')
info=damage(10,true);E:CaptureDamageRecovery(target,info);E:FinishDamageRecovery(target,info,true)
assert(#timers==0,'zero HP damage never pays')
info=damage(10,true);E:CaptureDamageRecovery(target,info);target.health=90
E:FinishDamageRecovery(target,info,false);assert(#timers==0,'engine rejected damage never pays')
info=damage(10,false);E:CaptureDamageRecovery(target,info);target.health=85.5
E:FinishDamageRecovery(target,info,true);assert(#timers==1,'physical damage gives Feedback but not Arc')
flush();assert(owner.pool.magic==12.75 and target.pool.magic==15)
owner.pool.magic=99.75
local binding=assert(E:CaptureRecoveryOwner(owner,'arcRecovery'))
local record=assert(E:QueueDamageRecovery(binding,8.5));flush()
assert(owner.pool.magic==100 and E:PayDamageRecovery(record)==0,'exact cap and one claim')
-- Independent same-frame events own separate sealed non-exploding timing draws.
owner.pool.magic=0
local oldNew=LOD.RNG.New;local timingDraws=0
LOD.RNG.New=function(seed)
 local rng=oldNew(seed);local int=rng.Int
 function rng:Int(lo,hi) assert(lo==1 and hi==4);timingDraws=timingDraws+1;return int(self,lo,hi) end
 return rng
end
for _=1,4 do assert(E:QueueDamageRecovery(E:CaptureRecoveryOwner(owner,'arcRecovery'),1)) end
assert(timingDraws==4);flush();assert(owner.pool.magic==2)
LOD.RNG.New=oldNew
-- Lifecycle cases create a fresh owner/run for each mutation. None may fund a
-- new incarnation, replaced progression state, new pool, reload or new dungeon.
local mutations={
 function(a) a.alive=false end,
 function(a) a.health=0 end,
 function(a) a.valid=false end,
 function(a) a.LODRunSpawnSerial=2 end,
 function(a) a.LODCombatLifeSerial=2 end,
 function(a) a.state.actorId='replacement' end,
 function(a) a.state={actorId='case',featIds={'INT_FEEDBACK_LOOP'}} end,
 function(a) a.state.featIds={} end,
 function(a) a.pool={magic=10} end,
 function(a) S.ActorLives[a]={} end,
 function() S.ActorLives={} end,
 function() LOD.RunManager.State.CampaignEpoch=2 end,
 function() LOD.RunManager.State.Level=4 end,
 function() LOD.RunManager.State.LevelSeed=124 end,
 function() LOD.RunManager.State.Graph={} end,
 function() LOD.RunManager.State.Failed=true end,
 function() LOD.RunManager.State.LevelCleared=true end,
 function() LOD.RunManager.State={} end,
 function() E.MagicRecoveryGeneration={} end,
 function() LOD.Magic={} end,
 function() LOD.RPGStatusElements={ActorLives={}} end,
}
for i,mutate in ipairs(mutations) do
 LOD.RunManager.State={CampaignEpoch=1,Level=3,LevelSeed=123,Graph={}}
 LOD.Magic=M;LOD.RPGStatusElements=S;S.ActorLives={}
 dofile(base..'sv_rpg_gate_e_magic_recovery.lua')
 local a=actor('case',{'INT_FEEDBACK_LOOP'});local pool=a.pool
 local b=assert(E:CaptureRecoveryOwner(a,'feedbackLoop'))
 assert(E:QueueDamageRecovery(b,20));mutate(a);flush()
 assert(pool.magic==10 and a.pool.magic==10,'stale callback rejected: '..i)
end
print('MAGIC_RECOVERY_PASS: actual HP boundary, magic tags, 50% fractional capped refunds, sealed d4s, dedup, 21 lifecycle boundaries')
