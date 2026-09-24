-- B14 shares finite roster commitments and the canonical Magic resource state.
local E,N=LOD.EnemyRoster,LOD.MazeNavigator
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
function E:ResourceCost(e)
    return LOD.RPGAbilityRules:OffensiveMagicCost(e,40)
end
function E:ResourceValid(e,a)
    return IsValid(e) and e.LODRosterAttack==a and self:ValidLife(a.life)
        and a.target:Health()>0 and self:AcquireTarget(a.target) and self:CanCast(e)
        and CurTime()>=(e.LODHitStunUntil or 0) and self:Visible(e,a.target)
        and e:GetPos():DistToSqr(a.origin)<=4^2
        and e:GetPos():DistToSqr(a.target:GetPos())<=360^2
        and LOD.Magic:_EnsureState(e)==a.pool
        and LOD.Magic:_EnsureState(a.target)==a.targetPool
end
function E:ResourceSpace(e,a)
    if not self:MeleeSupported(e,a.graph,a.cell,e:GetPos()) then return false end
    if a.mode==3 then return true end
    return self:ConditionSpace(e,a)
end
function E:BeginResource(e,p,now)
    if e.LODRosterAttack or not self:AcquireTarget(p) or p:Health()<=0 or not self:CanCast(e)
        or now<(e.LODHitStunUntil or 0) or now<(e.LODNextAttack or 0) then return false end
    local s=LOD.RunManager.State;local d=self.Definitions[e.LODArchetypeId]
    if not s or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen or not s.Graph then return false end
    local function deny() e.LODNextAttack=now+.5;e.LODResourceAdvanceUntil=now+.5;return false end
    local life=self:CaptureLife(e,p)
    if not self:ValidLife(life) or not self:Visible(e,p) or e:GetPos():DistToSqr(p:GetPos())>d.range^2 then return deny() end
    local pool,targetPool=LOD.Magic:_EnsureState(e),LOD.Magic:_EnsureState(p)
    if not pool or not targetPool then return deny() end
    local origin=copy(e:GetPos());local cell=N:WorldToCell(s.Graph,origin)
    if not self:MeleeSupported(p,s.Graph,cell,p:GetPos()) then return deny() end
    local count=0
    for source in pairs(self.Active) do
        local a=IsValid(source) and source.LODRosterAttack
        if a and a.resource then count=count+1 end
    end
    if count>=16 then return deny() end
    local mode=d.resource=="drain" and 1 or (pool.magic<self:ResourceCost(e) and 3 or 2)
    local direction=flat(p:GetPos()-origin):GetNormalized()
    if direction:LengthSqr()<.01 then direction=Angle(0,e:GetAngles().y,0):Forward() end
    local a=self:Bind({resource=true,mode=mode,kind="arc",target=p,life=life,cell=cell,
        pool=pool,targetPool=targetPool,origin=origin,aim=mode==3 and origin or copy(p:GetPos()),
        direction=direction,ready=now+(mode==3 and 2 or d.warning),last=now,
        event={impactOrigin=origin+Vector(0,0,48)}},s)
    a.deadline=a.ready+.2
    if not self:ResourceSpace(e,a) then return deny() end
    self.Active[e]=true;e.LODRosterAttack=a;e.LODResourceAdvanceUntil=nil
    LOD.HostileMotionV2:Stop(e)
    e:SetNW2Int("LOD_ResourceMode",mode);e:SetNW2Int("LOD_RosterAttack",1)
    e:SetNW2Vector("LOD_ResourceOrigin",origin);e:SetNW2Vector("LOD_ResourceAim",a.aim)
    e:SetNW2Float("LOD_ResourceReady",a.ready);e:SetNW2Float("LOD_ResourceUntil",a.deadline)
    if not self:ResourceValid(e,a) then if e.LODRosterAttack==a then self:Cancel(e) end;return false end
    e:EmitSound("npc/vort/attack_charge.wav",72,mode==3 and 85 or 110,.75)
    if self:ResourceValid(e,a) then e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true) end
    return e.LODRosterAttack==a
end
function E:ResourceNotice(e,recipient,label,amount)
    if amount<=0 then return end
    LOD.CombatRolls:_Send(recipient,1,label.." "..string.format("%g",amount).." MAGIC")
end
function E:ResourceDamage(e,a)
    local dealt=self:Damage(e,a.target,a.event,"arc")
    -- These generated Magic users can own Feedback Loop. Reuse its canonical
    -- per-attack continuation cap; replenishment is never a voluntary cast.
    local effects=LOD.RPG.FeatEffectSystem
    if self:ValidSourceLife(a.life) and e.LODRosterAttack==a and LOD.Magic:_EnsureState(e)==a.pool
        and effects and effects.ApplyFeedbackLoop and a.event.roll then
        local roll=a.event.roll
        local continuations=math.max(0,#(roll.values or {})-(roll.baseDice or 1))
        local restored
        restored,a.event.feedbackRestored=effects:ApplyFeedbackLoop(e,a.pool,continuations,a.event.feedbackRestored or 0)
        if restored>0 then LOD.Magic:_Sync(e,a.pool) end
    end
    return dealt
end
function E:StepResource(e,a,now)
    if not IsValid(e) or e.LODRosterAttack~=a then return end
    if not self:ValidSourceLife(a.life) then self:Cancel(e);return end
    if a.settling then
        -- Reentry is inert; an interrupted/erroring native callback cannot leave
        -- a claimed commitment pinning a living actor beyond its fixed deadline.
        if now>a.deadline then self:Finish(e,now) end
        return
    end
    if not self:ResourceValid(e,a) or now>a.deadline or now-a.last>.25 then self:Finish(e,now);return end
    a.last=now
    if now>=(a.nextGeometry or 0) or now>=a.ready then
        a.nextGeometry=now+.2
        if not self:ResourceSpace(e,a) then self:Finish(e,now);return end
    end
    if now<a.ready then return end
    a.settling=true -- claim before resource sync, dice, HP or observer callbacks
    if a.mode==3 then
        local restored=math.min(45,100-a.pool.magic)
        a.pool.magic=a.pool.magic+restored
        LOD.Magic:_Sync(e,a.pool)
        if self:ResourceValid(e,a) then self:ResourceNotice(e,a.target,"ACCUMULATOR +",restored) end
    else
        if a.mode==2 then
            local cost=self:ResourceCost(e)
            if a.pool.magic<cost then self:Finish(e,now);return end
            a.event.resourceFullMagicBonus=LOD.RPGWizardOffense and LOD.RPGWizardOffense:FullMagicBonus(e) or 0
            local context={}
            if LOD.RPG.PrepareCheckpointDAuraBurst then context.auraBurst=LOD.RPG:PrepareCheckpointDAuraBurst(e) end
            a.pool.magic=a.pool.magic-cost
            LOD.Magic:_Sync(e,a.pool)
            if not self:ResourceValid(e,a) then if e.LODRosterAttack==a then self:Cancel(e) end;return end
            local effects=LOD.RPG.FeatEffectSystem
            if effects and effects.RecordQuantumSpend then effects:RecordQuantumSpend(e,40,cost) end
            hook.Run("LODDiscreteMagicSpent",e,cost,context)
            if not self:ResourceValid(e,a) then if e.LODRosterAttack==a then self:Cancel(e) end;return end
        end
        local delta=a.target:GetPos()-a.aim
        if N:WorldToCell(a.graph,a.target:GetPos())==a.cell and flat(delta):LengthSqr()<=64^2
            and delta.z>=-4 and delta.z<=72 then
            local dealt=self:ResourceDamage(e,a)
            if a.mode==1 and dealt and dealt>0 and self:ResourceValid(e,a) then
                -- Damage/Arcane Shield resolve first. This bounded involuntary
                -- loss neither transfers Magic nor triggers voluntary-spend feats.
                local lost=math.min(12,a.targetPool.magic)
                a.targetPool.magic=a.targetPool.magic-lost
                LOD.Magic:_Sync(a.target,a.targetPool)
                if self:ResourceValid(e,a) then self:ResourceNotice(e,a.target,"SIPHONER -",lost) end
            end
        end
    end
    if IsValid(e) and e.LODRosterAttack==a then
        if self:ValidSourceLife(a.life) then self:Finish(e,now) else self:Cancel(e) end
    end
end
