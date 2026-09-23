-- B4 owns finite reaction commitments, not damage, movement or mitigation.
LOD.EnemyReactions=LOD.EnemyReactions or {}
local R=LOD.EnemyReactions
local E,M,Status,Rules=LOD.EnemyRoster,LOD.HostileMotionV2,LOD.RPGStatusElements,LOD.RPGAbilityRules
R.Profiles={pavise={index=1},repriser={index=2},redliner={index=3}}
R.Active=R.Active or setmetatable({}, {__mode="k"})
R.Damage=R.Damage or setmetatable({}, {__mode="k"})
local stages={pending=1,guard_warning=2,guard=3,attack=2,recovery=4,approach=5}
local function state() return LOD.RunManager and LOD.RunManager.State end
local function live(s) return s and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen end
function R:Capture(e,hero)
    return E:CaptureLife(e,hero)
end
function R:ValidLife(r)
    return E:ValidLife(r)
end
function R:CanAct(e,allowHitStun)
    return IsValid(e) and not e.LODDead and e:Health()>0 and e.LODActivated
        and (allowHitStun or CurTime()>=(e.LODHitStunUntil or 0))
        and Status:CanInitiateAttack(e) and Status:CanMoveVoluntarily(e) and not Status:Has(e,"morale_flee")
end
function R:ValidAttack(r)
    return self:ValidLife(r) and E:AcquireTarget(r.hero)
        and (r.kind and self:CanAct(r.source) or not r.kind and E:CanCast(r.source)
            and CurTime()>=(r.source.LODHitStunUntil or 0) and not Status:Has(r.source,"morale_flee"))
end
function R:Show(e,a)
    e.LODReaction=a;self.Active[e]=a
    e:SetNW2Int("LOD_ReactionMode",self.Profiles[a.kind].index)
    e:SetNW2Int("LOD_ReactionStage",stages[a.stage])
    e:SetNW2Float("LOD_ReactionReady",a.ready or 0);e:SetNW2Float("LOD_ReactionUntil",a.expires or 0)
    e:SetNW2Float("LOD_ReactionYaw",a.yaw or e:GetAngles().y);e:SetNW2Entity("LOD_ReactionTarget",a.hero)
end
function R:Interrupt(e,attackEvent,attacker)
    local a=self.Active[e]
    -- Shotgun settles HP before applying its one shell stun. Adopt only that
    -- triggering event's late stun; later hits cannot inherit this allowance.
    if a and a.stage=="pending" and attackEvent and a.triggerEvent==attackEvent and a.hero==attacker
        and CurTime()<a.expires and self:ValidLife(a) and self:CanAct(e,true) then
        a.triggerStun=e.LODHitStunUntil or 0;return
    end
    self:Cancel(e)
end
function R:Cancel(e,retire)
    local a=self.Active[e]
    -- More hits cannot shorten or repeatedly extend the exhausted window.
    if a and a.stage=="recovery" and not retire and self:ValidLife(a) then M:Stop(e);return end
    self.Active[e]=nil
    if not IsValid(e) then return end
    e.LODReaction=nil;e:SetNW2Int("LOD_ReactionMode",0);e:SetNW2Int("LOD_ReactionStage",0)
    if a and e.LODRosterAttack and e.LODRosterAttack.reactionRecord==a then E:Cancel(e) end
    if not a then return end
    M:Stop(e)
    if a.kind=="pavise" then e.LODNextGuard=CurTime()+6 end
    if a.kind=="redliner" and a.stage~="recovery" and not retire then
        if not self:ValidLife(a) then return end
        a.stage="recovery";a.ready=CurTime()+3;a.expires=a.ready
        e.LODNextAttack=math.max(e.LODNextAttack or 0,a.ready);self:Show(e,a)
    end
end
function R:BeginGuard(e,hero,now)
    if e.LODArchetypeId~="pavise" or self.Active[e] or e.LODRosterAttack or now<(e.LODNextGuard or 0)
        or not live(state()) or not self:CanAct(e) or not E:AcquireTarget(hero)
        or e:GetPos():DistToSqr(hero:GetPos())>600^2 or not E:Visible(e,hero) then return false end
    local a=self:Capture(e,hero);a.kind="pavise";a.stage="guard_warning";a.ready=now+.65;a.expires=a.ready+2.5
    a.yaw=(hero:GetPos()-e:GetPos()):Angle().y
    E:Cancel(e);M:Stop(e);e:_SetActivity(ACT_IDLE);e:SetAngles(Angle(0,a.yaw,0));self:Show(e,a)
    e:EmitSound("npc/combine_soldier/gear2.wav",72,85,.8);return true
end
function R:GuardContribution(e,attacker,info)
    local a=self.Active[e]
    if not a or a.kind~="pavise" or a.stage~="guard" then return 0 end
    if not self:ValidAttack(a) or CurTime()>=a.expires then self:Cancel(e);return 0 end
    if not IsValid(attacker) then return 0 end
    local context=info and Status:DamageContext(info,e) or {}
    local contract=context.damageContract or {}
    local origin=context.equipmentSnapshot and context.equipmentSnapshot.origin
        or contract.sourcePosition or contract.originContract and contract.originContract.sourcePosition
        or context.attackOrigin or context.projectileOrigin or context.pushOrigin
    local force=info and info.GetDamageForce and info:GetDamageForce()
    local delta=origin and (origin-e:GetPos()) or (force and force:LengthSqr()>0 and -force) or (attacker:GetPos()-e:GetPos())
    delta=Vector(delta.x,delta.y,0)
    return delta:LengthSqr()>0 and delta:GetNormalized():Dot(Angle(0,a.yaw,0):Forward())>=math.cos(math.rad(60)) and .25 or 0
end
function R:ObserveHit(e,hero,context,effective,now)
    local kind=IsValid(e) and e.LODArchetypeId
    if not self.Profiles[kind] or effective<=0 or not live(state()) or not self:CanAct(e,true)
        or not E:AcquireTarget(hero) or not hero:IsPlayer() or not LOD.FactionManager:IsEnemyCombatant(e)
        or context.statusDamage or context.passiveDamage or context.reactiveDamage or context.auraBurst
        or context.environmental or context.wallCrush or context.equipmentContact or context.scriptedKill then return false end
    -- A second positive hit interrupts even inside the normal flinch debounce.
    if self.Active[e] then self:Interrupt(e);return false end
    if kind=="pavise" then return false end
    if kind=="repriser" and now<(e.LODNextReprisal or 0) then return false end
    if kind=="redliner" and (e.LODRedlineSpent or e:Health()>e:GetMaxHealth()*.4) then return false end
    if not E:Visible(e,hero) or e:GetPos():DistToSqr(hero:GetPos())>600^2 then return false end
    local a=self:Capture(e,hero);a.kind=kind;a.stage="pending";a.ready=now;a.expires=now+2
    a.triggerEvent=context.attackEvent
    a.triggerStun=e.LODHitStunUntil or 0
    if kind=="repriser" then e.LODNextReprisal=now+5 else e.LODRedlineSpent=true end
    E:Cancel(e);M:Stop(e);self:Show(e,a);return true
end
function R:BeginAttack(e,a,now)
    if not self:ValidAttack(a) or not E:Visible(e,a.hero) then self:Cancel(e);return false end
    local range=a.kind=="redliner" and 400 or 600
    if e:GetPos():DistToSqr(a.hero:GetPos())>range^2 then return false end
    a.stage="attack";a.ready=now+1;a.expires=a.ready+1
    M:Stop(e);M:FaceToward(e,a.hero:GetPos());self:Show(e,a)
    E:Begin(e,a.hero,now,{kind=a.kind=="redliner" and "dive" or "bullet",warning=1,range=range,reactionRecord=a})
    return true
end
function R:AfterAttack(e,attack,now)
    local a=self.Active[e]
    if a and attack.reactionRecord==a then self:Cancel(e) end
end
function R:Advance(e,a,now)
    if not self:ValidLife(a) then self:Cancel(e,true);return end
    if a.stage=="recovery" then
        M:Stop(e)
        if now>=a.expires then self:Cancel(e,true) end
        return
    end
    if not E:AcquireTarget(a.hero) or not self:CanAct(e,a.stage=="pending")
        or (a.stage=="pending" and (e.LODHitStunUntil or 0)>a.triggerStun)
        or now>=a.expires then self:Cancel(e);return end
    if a.stage=="guard_warning" or a.stage=="guard" then
        M:Stop(e);e:_SetActivity(ACT_IDLE);e:SetAngles(Angle(0,a.yaw,0))
        if a.stage=="guard_warning" and now>=a.ready then a.stage="guard";self:Show(e,a) end
    elseif a.stage=="pending" and now>=(e.LODHitStunUntil or 0) then
        if not E:Visible(e,a.hero) or e:GetPos():DistToSqr(a.hero:GetPos())>600^2 then self:Cancel(e);return end
        if not self:BeginAttack(e,a,now) and self.Active[e]==a and a.kind=="redliner" then
            a.stage="approach";a.ready=now;a.expires=now+4;self:Show(e,a)
        end
    elseif a.stage=="approach" then
        if not E:Visible(e,a.hero) then self:Cancel(e);return end
        self:BeginAttack(e,a,now)
    end
end
function R:Tick(e,now)
    if e.LODArchetypeId=="redliner" and e:Health()>=e:GetMaxHealth()*.6 then e.LODRedlineSpent=nil end
    local a=self.Active[e]
    if a then
        self:Advance(e,a,now);a=self.Active[e]
        if a and a.stage=="approach" then
            e.LODTarget=a.hero;e:_RefreshRoute(state().Graph);local wp=e:_AdvanceWaypoint()
            if wp and E:LegalStep(e,e:GetPos(),wp.pos)
                and (not LOD.EnemyPursuit or LOD.EnemyPursuit:Hull(e,e:GetPos(),wp.pos)) then M:MoveToward(e,wp) else M:Stop(e) end
        elseif a then M:Stop(e) end
        return true
    end
    if e.LODArchetypeId=="pavise" and now>=(e.LODNextGuardScan or 0) then
        e.LODNextGuardScan=now+.3;e:_RefreshTarget(state().Graph)
        return self:BeginGuard(e,e.LODTarget,now)
    end
    return false
end
function R:Service(now,active)
    for e,a in pairs(self.Active) do
        if not active then self:Cancel(e,true) else self:Advance(e,a,now) end
    end
end
-- Capture before native health settlement, after the established mitigation
-- chain. PostDamage observes actual loss; resisted/blocked/lethal hits cannot arm.
function R:BeginDamage(e,info,before)
    if not IsValid(e) or not self.Profiles[e.LODArchetypeId] or info:GetDamage()<=0 then return end
    if e.LODArchetypeId=="redliner" and before>=e:GetMaxHealth()*.6 then e.LODRedlineSpent=nil end
    local hero=info:GetAttacker();if not E:AcquireTarget(hero) or not hero:IsPlayer() then return end
    self.Damage[info]={target=e,hero=hero,before=before,context=Status:DamageContext(info,e),record=self:Capture(e,hero)}
end
function R:PostDamage(e,info,taken)
    local row=self.Damage[info];self.Damage[info]=nil
    if not taken or not row or row.target~=e or not self:ValidLife(row.record) then return end
    self:ObserveHit(e,row.hero,row.context,math.max(0,math.min(row.before,row.before-e:Health())),CurTime())
end
local previous=GM.EntityTakeDamage
function GM:EntityTakeDamage(e,info)
    local before=IsValid(e) and e:Health() or 0
    local result=previous and previous(self,e,info)
    if result~=true then R:BeginDamage(e,info,before) end
    return result
end
hook.Add("PostEntityTakeDamage","LOD_EnemyReactionHit",function(e,info,taken) R:PostDamage(e,info,taken) end)
hook.Add("EntityRemoved","LOD_EnemyReactionRemoved",function(e) R:Cancel(e,true) end)
hook.Add("OnNPCKilled","LOD_EnemyReactionDeath",function(e) R:Cancel(e,true) end)
