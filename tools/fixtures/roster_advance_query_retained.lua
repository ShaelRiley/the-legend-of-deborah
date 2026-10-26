-- Immutable production oracle from 26ccc4d06aff1f385e1e2743b048d5577435329f.
-- Only these two function bodies differ in the parity test.
return {
CanTargetFromHere=[==[
function E:CanTargetFromHere(e,p,presentThreatOnly)
    local d=self.Definitions[e.LODArchetypeId]
    if not d or not self:AcquireTarget(p) then return false end
    local g=state().Graph
    if d.kind=="gas" or presentThreatOnly and d.stationary and d.trap then
        if key(N:WorldToCell(g,e:GetPos()))~=key(N:WorldToCell(g,p:GetPos())) then return false end
        if d.kind=="gas" then return true end
    end
    local origin=self:Origin(e)
    local range=d.kind=="beam" and EC.Archetypes.beamsweeper.fireRange or e.LODConfig.fireRange
    if origin:DistToSqr(p:WorldSpaceCenter())>range^2 or not self:Visible(e,p,origin) then return false end
    if d.kind=="bullet" and not d.support and not d.pursuit and not d.reaction and not d.pattern
        and not d.trap and not d.tactical and not d.mobile and not d.condition and not d.crossfire
        and not d.discipline and not d.companion and not d.edict and not d.link then
        local direction=(p:GetPos()-e:GetPos()):GetNormalized()
        return direction:Dot(Angle(0,e.LODRosterYaw or 0,0):Forward())>=math.cos(math.rad(55))
    end
    return true
end
]==],
Tick=[==[
function E:Tick(e)
    if e.LODFallenHero then return LOD.FallenHeroes:TickAI(e) end
    -- This shared dispatch also sees non-roster Fighter/Rogue skeletons before
    -- ordinary melee/Soldier execution. Late native method binding cannot erase
    -- the exact-event guard by replacing an instance method.
    if e.LODSkeletonHero and not LOD.SkeletonHero:Live(e) then
        e.LODSoldierBurst=nil;self:Cancel(e);LOD.HostileMotionV2:Stop(e);return true
    end
    local d=self.Definitions[e.LODArchetypeId];if not d then return false end
    local s=state();local motion=LOD.HostileMotionV2;local now=CurTime()
    if e.LODDead or not e.LODActivated or not s or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then
        self:Cancel(e);if LOD.EnemyReactions then LOD.EnemyReactions:Cancel(e,true) end;if LOD.EnemySupport then LOD.EnemySupport:Cancel(e) end;if LOD.EnemyPursuit then LOD.EnemyPursuit:Cancel(e) end;if e.LODClimberVictim and LOD.Climber then LOD.Climber:Detach(e) end;motion:Stop(e);return true
    end
    self:Prepare(e)
    if e.LODWardenTurret and (not LOD.WardenTurrets or not LOD.WardenTurrets:Select(e)) then self:Cancel(e);motion:Stop(e);return true end
    if not self:Live(e.LODRosterContext,s) then self:Cancel(e);if LOD.EnemyReactions then LOD.EnemyReactions:Cancel(e,true) end;if LOD.EnemySupport then LOD.EnemySupport:Cancel(e) end;if LOD.EnemyPursuit then LOD.EnemyPursuit:Cancel(e) end;motion:Stop(e);return true end
    if LOD.EnemyRemains and LOD.EnemyRemains.Pending[e] then motion:Stop(e);return true end
    if e.LODMeleeRecovery then
        local recovery=e.LODMeleeRecovery
        if self:ValidSourceLife(recovery.life) and now<recovery.expires then
            motion:Stop(e);e:_SetActivity(ACT_IDLE);return true
        end
        e.LODMeleeRecovery=nil
    end
    if d.reaction and LOD.EnemyReactions and LOD.EnemyReactions:Tick(e,now) then return true end
    if d.support and LOD.EnemySupport and LOD.EnemySupport:Tick(e,now) then motion:Stop(e);return true end
    if d.kind=="climber" then return LOD.Climber:Tick(e,s,now) end
    if d.kind=="gas" then
        motion:Stop(e);e:_SetActivity(ACT_IDLE)
        if now>=(e.LODNextGas or 0) then
            e.LODNextGas=now+1
            local cell=N:WorldToCell(s.Graph,e:GetPos());local event={}
            for _,p in ipairs(player.GetAll()) do
                if self:Target(p) and key(N:WorldToCell(s.Graph,p:GetPos()))==key(cell) then self:Damage(e,p,event,"gas") end
            end
        end
        return true
    end
    local a=e.LODRosterAttack
    if a then motion:Stop(e);return true end -- shared service owns attacks, even committed sweeps during stun
    if d.perception and (now<(e.LODHitStunUntil or 0) or not self:CanCast(e) or not LOD.RPGStatusElements:CanMoveVoluntarily(e)) then
        self:Cancel(e)
        -- Perception retirement must not consume canonical morale locomotion.
        if not LOD.RPGStatusElements:Has(e,"morale_flee") then motion:Stop(e);return true end
    end
    if motion:HoldHitStun(e,now) then return true end
    local statuses=LOD.RPGStatusElements
    if d.stationary then
        motion:Stop(e)
        if not statuses:CanInitiateAttack(e) or statuses:Has(e,"morale_flee") then return true end
    elseif statuses:HandleAIFlee(e,s.Graph,motion) then return true end
    if d.perception then return self:TickPerception(e,now) end
    if not e.LODPursuit and not e.LODWardenTurret then e:_RefreshTarget(s.Graph) end
    local p=e.LODTarget
    if d.pursuit and LOD.EnemyPursuit and LOD.EnemyPursuit:Tick(e,p,now) then return true end
    if d.pursuit and (not self:AcquireTarget(p) or not self:Visible(e,p)) then
        e.LODTarget=nil
        if not self:PatrolWanderer(e,s.Graph) then motion:Stop(e);e:_SetActivity(ACT_IDLE) end
        return true
    end
    local can=self:CanCast(e) and self:CanTargetFromHere(e,p)
    if can and d.kind=="beam" and now>=(e.LODNextAttack or 0) then
        local direction=p:GetPos()-e:GetPos();direction.z=0
        local yaw=direction:Angle().y
        local origin=e:GetPos()+Vector(0,0,56)
        local range=EC.Archetypes.beamsweeper.fireRange
        for offset=-45,45,15 do
            local tr=util.TraceLine({start=origin,endpos=origin+Angle(0,yaw+offset,0):Forward()*range,mask=MASK_SOLID,
                filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
            if tr.Hit then range=math.min(range,origin:Distance(tr.HitPos)-8) end
        end
        if range>=120 then e.LODRosterYaw=yaw;e.LODConfig.fireRange=range;motion:FaceToward(e,p:GetPos()) end
    end
    if can and d.kind=="beam" then
        local direction=(p:GetPos()-e:GetPos()):GetNormalized()
        can=direction:Dot(Angle(0,e.LODRosterYaw or 0,0):Forward())>=math.cos(math.rad(45))
    end
    -- Arc Casters advance between commitments. Previously merely seeing a target
    -- inside the very long cast range held them still for the entire cooldown.
    local reposition=(e.LODArchetypeId=="razor" and now<(e.LODRazorApproachUntil or 0)) or (d.link and now<(e.LODLinkAdvanceUntil or 0)) or (d.edict and now<(e.LODEdictAdvanceUntil or 0)) or (d.companion and now<(e.LODCompanionAdvanceUntil or 0)) or (d.discipline and now<(e.LODDisciplineAdvanceUntil or 0)) or (d.crossfire and now<(e.LODCrossfireAdvanceUntil or 0)) or (d.resource and now<(e.LODResourceAdvanceUntil or 0)) or (d.spacing and now<(e.LODSpacingAdvanceUntil or 0)) or (d.condition and now<(e.LODConditionAdvanceUntil or 0)) or (d.mobile and now<(e.LODMobileAdvanceUntil or 0)) or (d.tactical and now<(e.LODTacticalAdvanceUntil or 0)) or (d.melee and now<(e.LODMeleeAdvanceUntil or 0)) or (d.trap and now<(e.LODTrapAdvanceUntil or 0)) or (d.kind=="arc" and not d.trap and now<(e.LODNextAttack or 0)
        and self:Target(p) and e:GetPos():DistToSqr(p:GetPos())>240^2)
    if can and not reposition then
        motion:Stop(e)
        if not d.stationary then motion:FaceToward(e,p:GetPos()) end
        if now>=(e.LODNextAttack or 0) then self:Begin(e,p,now) end
    elseif not d.stationary then
        e:_RefreshRoute(s.Graph);local wp=e:_AdvanceWaypoint()
        if wp then motion:MoveToward(e,wp) else motion:Stop(e);e:_SetActivity(ACT_IDLE) end
    end
    return true
end
]==],
}
