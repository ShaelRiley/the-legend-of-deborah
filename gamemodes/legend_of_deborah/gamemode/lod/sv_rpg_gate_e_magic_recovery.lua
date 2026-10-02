-- Actual HP loss is observed at the shared native damage boundary, after all
-- damage mitigation/diversion and canonical shell/target aggregation.
LOD=LOD or {}; LOD.RPG=LOD.RPG or {}
local RPG=LOD.RPG
local Catalog=RPG.IdentityCatalog
local Feats=Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects,Rules,Progression=RPG.FeatEffectSystem,LOD.RPGAbilityRules,LOD.CharacterProgressionSystem
if not Feats or not Effects or not Rules or not Progression then return end
local IDS={feedbackLoop="INT_FEEDBACK_LOOP",arcRecovery="INT_ARC_RECOVERY"}
local function owns(state,id)
    for _,v in ipairs(state and state.featIds or {}) do if v==id then return true end end
    return false
end
local function definition(id,name,requirement,kind,description)
    return {featId=id,displayName=name,featFamilyId=id:lower(),rankIndex=1,replacesLowerRank=false,
        repeatableFallback=false,governingAbilities={"int"},abilityRequirements={int=requirement},
        prerequisiteFeatIds={},requiredCapabilityTags={"magic_pool"},incompatibleFeatIds={},
        allowedActorTypes={"hero","human_soldier","ai"},requiredSubsystemTags={},synergyTags={"magic","damage_recovery"},
        oneRank=true,effectHandlerId=kind.."_actual_hp_recovery",
        effectParams={refundFraction=.5,delayDice={1,4},sealedDelay=true,description=description},
        directorBaseWeight=1,eligibilityText="INT "..requirement.." / Magic pool",
        actorText="Heroes, human Soldiers and Magic-using AI"}
end
Feats.INT_FEEDBACK_LOOP=definition(IDS.feedbackLoop,"Feedback Loop",15,"incoming",
    "After actually taking HP damage, refund Magic equal to 50% of that resolved event's HP loss after a sealed non-exploding 1d4-second delay. Fractional Magic is retained, up to 100. Zero HP loss gives nothing; each canonical event pays once. Death or lifecycle replacement cancels pending refunds.")
Feats.INT_ARC_RECOVERY=definition(IDS.arcRecovery,"Arc Recovery",17,"outgoing_magic",
    "After dealing Magic-tagged actual HP damage, refund Magic equal to 50% of that resolved target event's HP loss after a sealed non-exploding 1d4-second delay. Fractional Magic is retained, up to 100. Misses, immunity, zero HP loss and nonmagical damage give nothing. Death or lifecycle replacement cancels pending refunds.")
Catalog.OrdinaryFeats=Feats

-- Fresh module generation invalidates pre-reload closures without enumerating
-- the world or retaining an ever-growing history of attack IDs.
local generation={}
Effects.MagicRecoveryGeneration=generation
Effects.MagicRecoveryPending=setmetatable({}, {__mode="k"})
Effects.MagicRecoveryOrdinals=setmetatable({}, {__mode="k"})
Effects.MagicRecoveryStats={scheduled=0,paid=0,rejected=0,feedbackLoopRestored=0,arcRecoveryRestored=0}
function Effects:MagicRecoveryProfile(state)
    return {feedbackLoop=owns(state,IDS.feedbackLoop),arcRecovery=owns(state,IDS.arcRecovery),
        refundFraction=.5,delaySides=4}
end
function Effects:ResolveDamageRecovery(currentMagic,actualHPDamage)
    local current=math.Clamp(tonumber(currentMagic) or 0,0,100)
    local restored=math.min(100-current,math.max(0,tonumber(actualHPDamage) or 0)*.5)
    return current+restored,restored
end
local function alive(actor)
    return IsValid(actor) and not actor.LODDead and actor.Health and actor:Health()>0
        and (not actor:IsPlayer() or actor:Alive())
end
function Effects:CaptureRecoveryOwner(actor,kind)
    if not alive(actor) then return nil end
    local state=Rules:ProgressionState(actor)
    if not owns(state,IDS[kind]) then return nil end
    local magic=LOD.Magic
    local pool=magic and magic:_EnsureState(actor)
    if not pool then return nil end
    local status=LOD.RPGStatusElements
    if status and status.BindActorLife then status:BindActorLife(actor) end
    local run=LOD.RunManager and LOD.RunManager.State
    return {actor=actor,kind=kind,state=state,pool=pool,magic=magic,run=run,
        epoch=run and run.CampaignEpoch,level=run and run.Level,seed=run and run.LevelSeed,graph=run and run.Graph,
        actorId=state.actorId,spawn=actor.LODRunSpawnSerial,combatLife=actor.LODCombatLifeSerial,
        status=status,lives=status and status.ActorLives,life=status and status.ActorLives and status.ActorLives[actor],
        generation=generation}
end
function Effects:RecoveryOwnerCurrent(binding)
    if not binding or self.MagicRecoveryGeneration~=binding.generation or not alive(binding.actor) then return false end
    local actor=binding.actor
    local run=LOD.RunManager and LOD.RunManager.State
    if run~=binding.run or (run and (run.Failed or run.LevelCleared
        or run.CampaignEpoch~=binding.epoch or run.Level~=binding.level
        or run.LevelSeed~=binding.seed or run.Graph~=binding.graph)) then return false end
    local state=Rules:ProgressionState(actor)
    if state~=binding.state or state.actorId~=binding.actorId or not owns(state,IDS[binding.kind])
        or actor.LODRunSpawnSerial~=binding.spawn or actor.LODCombatLifeSerial~=binding.combatLife then return false end
    local status=LOD.RPGStatusElements
    if status~=binding.status or (status and (status.ActorLives~=binding.lives
        or status.ActorLives[actor]~=binding.life)) then return false end
    return LOD.Magic==binding.magic and binding.magic:_EnsureState(actor)==binding.pool
end
function Effects:RollRecoveryDelay(binding)
    local byKind=self.MagicRecoveryOrdinals[binding.actor]
    if not byKind or byKind.life~=binding.life or byKind.run~=binding.run or byKind.state~=binding.state then
        byKind={life=binding.life,run=binding.run,state=binding.state}
        self.MagicRecoveryOrdinals[binding.actor]=byKind
    end
    local ordinal=(byKind[binding.kind] or 0)+1
    byKind[binding.kind]=ordinal
    local seed=LOD.Seeds.Derive(binding.seed or 1,table.concat({"feat-hp-recovery-delay:v1",binding.kind,
        tostring(binding.actorId or binding.actor:EntIndex()),tostring(binding.spawn or 0),tostring(ordinal)},":"))
    -- Direct, sealed timing draw. Never route this d4 through damage/Boom/Luck.
    return LOD.RNG.New(seed):Int(1,4)
end
function Effects:PayDamageRecovery(record)
    if record.paid then return 0 end
    record.paid=true -- claim even rejected records before observers/resource sync
    if not self:RecoveryOwnerCurrent(record.owner) then
        self.MagicRecoveryStats.rejected=self.MagicRecoveryStats.rejected+1
        return 0
    end
    local owner=record.owner
    local magic,restored=self:ResolveDamageRecovery(owner.pool.magic,record.actualHPDamage)
    owner.pool.magic=magic
    self.MagicRecoveryStats.paid=self.MagicRecoveryStats.paid+1
    local field=owner.kind.."Restored"
    self.MagicRecoveryStats[field]=(self.MagicRecoveryStats[field] or 0)+restored
    if owner.magic._Sync then owner.magic:_Sync(owner.actor,owner.pool) end
    if restored>0 and hook then hook.Run("LODMagicRecoveryPaid",owner.actor,owner.kind,restored,record) end
    return restored
end
function Effects:QueueDamageRecovery(owner,actualHPDamage)
    local loss=math.max(0,tonumber(actualHPDamage) or 0)
    if loss<=0 or not self:RecoveryOwnerCurrent(owner) then return nil end
    local record={owner=owner,actualHPDamage=loss,delay=self:RollRecoveryDelay(owner),paid=false}
    self.MagicRecoveryStats.scheduled=self.MagicRecoveryStats.scheduled+1
    timer.Simple(record.delay,function() self:PayDamageRecovery(record) end)
    return record
end
function Effects:CaptureDamageRecovery(target,info)
    if not info or not alive(target) or info:GetDamage()<=0 then return end
    local status=LOD.RPGStatusElements
    local tags=status and status:DamageContext(info,target) or {}
    local feedback=self:CaptureRecoveryOwner(target,"feedbackLoop")
    local arc=(tags.magic==true or tags.magical==true)
        and self:CaptureRecoveryOwner(info:GetAttacker(),"arcRecovery") or nil
    if not feedback and not arc then return end
    self.MagicRecoveryPending[info]={target=target,before=math.max(0,target:Health()),feedback=feedback,arc=arc}
end
function Effects:FinishDamageRecovery(target,info,wasDamageTaken)
    local pending=self.MagicRecoveryPending[info]
    self.MagicRecoveryPending[info]=nil
    if not pending or pending.target~=target or wasDamageTaken~=true then return 0 end
    local after=IsValid(target) and math.max(0,target:Health()) or 0
    local actual=math.Clamp(pending.before-after,0,pending.before)
    if actual<=0 then return 0 end
    self:QueueDamageRecovery(pending.feedback,actual)
    self:QueueDamageRecovery(pending.arc,actual)
    return actual
end
if not Effects.LODGateEMagicRecoveryApplyDerivedWrapped then
    Effects.LODGateEMagicRecoveryApplyDerivedWrapped=true
    local base=Effects.ApplyDerived
    function Effects:ApplyDerived(state,derived)
        base(self,state,derived)
        local p=self:MagicRecoveryProfile(state)
        derived.feedbackLoopEnabled,derived.arcRecoveryEnabled=p.feedbackLoop,p.arcRecovery
        derived.damageRecoveryFraction=.5
    end
end
if not Progression.LODGateEMagicRecoverySnapshotWrapped then
    Progression.LODGateEMagicRecoverySnapshotWrapped=true
    local base=Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(actor)
        local snapshot=base(self,actor)
        if not snapshot then return nil end
        local p=Effects:MagicRecoveryProfile(Rules:ProgressionState(actor))
        snapshot.feedbackLoopEnabled,snapshot.arcRecoveryEnabled=p.feedbackLoop,p.arcRecovery
        snapshot.damageRecoveryFraction=.5
        return snapshot
    end
end
function Effects:ValidateMagicRecoveryFamilies()
    local p=self:MagicRecoveryProfile({featIds={IDS.feedbackLoop,IDS.arcRecovery}})
    local magic,paid=self:ResolveDamageRecovery(10,5)
    local cap,accepted=self:ResolveDamageRecovery(99.75,10)
    local ok=p.feedbackLoop and p.arcRecovery and magic==12.5 and paid==2.5 and cap==100 and accepted==.25
        and Feats.INT_FEEDBACK_LOOP.abilityRequirements.int==15 and Feats.INT_ARC_RECOVERY.abilityRequirements.int==17
    return ok,ok and {} or {"delayed actual-HP recovery definitions/fractions/cap"}
end
local validation=LOD.RPGValidation
if validation and not validation.LODGateEMagicRecoveryWrapped then
    validation.LODGateEMagicRecoveryWrapped=true
    local base=validation.Run
    function validation:Run(printResult)
        local ok,errors=base(self,printResult); errors=errors or {}
        local valid,ownErrors=Effects:ValidateMagicRecoveryFamilies()
        for _,err in ipairs(ownErrors) do errors[#errors+1]=err end
        return ok and valid,errors
    end
end
local function allowed(actor)
    local cv=GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(actor) or actor:IsAdmin())
end
concommand.Add("lod_rpg_gate_e_magic_recovery_validate",function(actor)
    if not allowed(actor) then return end
    local ok,errors=Effects:ValidateMagicRecoveryFamilies()
    print("[LOD:RECOVERY] "..(ok and "PASS" or "FAIL").." 50% actual HP; sealed 1d4-second delay; "..table.concat(errors,"; "))
end)
concommand.Add("lod_rpg_gate_e_magic_recovery_status",function(actor)
    if not allowed(actor) then return end
    local s=Effects.MagicRecoveryStats
    print(string.format("[LOD:RECOVERY] scheduled=%d paid=%d rejected=%d feedback=%g arc=%g",
        s.scheduled,s.paid,s.rejected,s.feedbackLoopRestored,s.arcRecoveryRestored))
end)
return Effects
