-- B13 party spacing: bounded commitments in the existing roster service.
local E,F,N=LOD.EnemyRoster,LOD.FactionManager,LOD.MazeNavigator
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
function E:PublishSpacing(e,a)
    e:SetNW2Int("LOD_SpacingMode",a.spacing=="isolation" and 1 or 2)
    e:SetNW2Vector("LOD_SpacingOrigin",a.origin)
    e:SetNW2Vector("LOD_SpacingAimA",a.aim or a.origin)
    e:SetNW2Vector("LOD_SpacingAimB",a.otherAim or a.aim or a.origin)
    e:SetNW2Float("LOD_SpacingReady",a.ready);e:SetNW2Float("LOD_SpacingUntil",a.deadline)
end
function E:SpacingSpace(e,a)
    if not self:ConditionSpace(e,a) then return false end
    if a.other then
        return self:ConditionSpace(e,{graph=a.graph,cell=a.cell,aim=a.otherAim,target=a.other,direction=a.otherDirection})
    end
    return true
end
function E:SpacingFallbackValid(e,a,now)
    if not self:ValidLife(a.life) or a.target:Health()<=0 or now-a.last>.25
        or e:GetPos():DistToSqr(a.sourceGround)>4^2 or not self:CanCast(e)
        or not self:AcquireTarget(a.target) or not self:Visible(e,a.target)
        or not self:MeleeSupported(e,a.graph,a.cell,e:GetPos()) then return false end
    a.last=now;return true
end
function E:BeginSpacing(e,p,now)
    if e.LODRosterAttack or not self:AcquireTarget(p) or p:Health()<=0 or not self:CanCast(e)
        or now<(e.LODHitStunUntil or 0) or now<(e.LODNextAttack or 0) then return false end
    local s=LOD.RunManager.State;local d=self.Definitions[e.LODArchetypeId]
    if not s or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen or not s.Graph then return false end
    local function deny() e.LODNextAttack=now+.5;e.LODSpacingAdvanceUntil=now+.5;return false end
    local life=self:CaptureLife(e,p)
    if not self:ValidLife(life) or not self:Visible(e,p) or e:GetPos():DistToSqr(p:GetPos())>d.range^2 then return deny() end
    local origin=copy(e:GetPos());local cell=N:WorldToCell(s.Graph,origin)
    if not self:MeleeSupported(e,s.Graph,cell,origin) then return deny() end
    local other,complete=F:CooperativeNeighbor(e,p,s.Graph,d.spacing=="isolation" and 192 or 160,d.spacing=="link",now)
    if not complete or (d.spacing=="isolation" and other) then return deny() end
    if d.spacing=="link" and not other then
        self:Begin(e,p,now,{spacingFallback=true})
        local a=e.LODRosterAttack
        if a and a.spacingFallback and self:ValidLife(a.life) then a.sourceGround=origin;a.cell=cell;e.LODSpacingAdvanceUntil=nil;return true end
        return false
    end
    local count=0
    for source in pairs(self.Active) do
        local a=IsValid(source) and source.LODRosterAttack
        if a and a.spacing then count=count+1 end
    end
    if count>=16 then return deny() end
    local direction=flat(p:GetPos()-origin):GetNormalized()
    if direction:LengthSqr()<.01 then direction=Angle(0,e:GetAngles().y,0):Forward() end
    local a=self:Bind({spacing=d.spacing,kind=d.kind,target=p,life=life,cell=cell,origin=origin,
        aim=copy(p:GetPos()),direction=direction,ready=now+d.warning,last=now,
        event={impactOrigin=origin+Vector(0,0,48)}},s)
    a.deadline=a.ready+.2
    if other then
        a.other=other;a.otherLife=self:CaptureLife(e,other);a.otherAim=copy(other:GetPos())
        a.otherDirection=flat(other:GetPos()-origin):GetNormalized()
        if a.otherDirection:LengthSqr()<.01 then a.otherDirection=direction end
        if not self:ValidLife(a.otherLife) then return deny() end
    end
    if not self:SpacingSpace(e,a) then return deny() end
    self.Active[e]=true;e.LODSpacingAdvanceUntil=nil
    if d.spacing=="isolation" then
        -- Keep B7's frozen narrow strike, exact participant and shared damage.
        return self:BeginMelee(e,p,now,a)
    end
    e.LODRosterAttack=a
    LOD.HostileMotionV2:Stop(e);self:PublishSpacing(e,a);e:SetNW2Int("LOD_RosterAttack",1)
    if not self:ValidLife(a.life) or e.LODRosterAttack~=a then return false end
    e:EmitSound("npc/vort/attack_charge.wav",72,100,.75)
    if self:ValidLife(a.life) and e.LODRosterAttack==a then e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true) end
    return e.LODRosterAttack==a
end
function E:SpacingInside(a,p,aim)
    local delta=p:GetPos()-aim
    return N:WorldToCell(a.graph,p:GetPos())==a.cell and flat(delta):LengthSqr()<=64^2 and delta.z>=-4 and delta.z<=72
end
function E:StepSpacing(e,a,now)
    if not IsValid(e) or e.LODRosterAttack~=a then return end
    if not self:ValidSourceLife(a.life) then self:Cancel(e);return end
    if a.spacingReleased then return end
    if not self:ValidLife(a.life) or a.target:Health()<=0 or not self:CanCast(e)
        or now<(e.LODHitStunUntil or 0) or now>a.deadline or now-a.last>.25
        or e:GetPos():DistToSqr(a.origin)>4^2 or not self:AcquireTarget(a.target) or not self:Visible(e,a.target) then
        self:Finish(e,now);return
    end
    a.last=now
    if a.spacing=="isolation" then
        local other,complete=F:CooperativeNeighbor(e,a.target,a.graph,192,false,now)
        if not complete or other then self:Finish(e,now);return end
    else
        if not self:ValidLife(a.otherLife) or a.other:Health()<=0 or not self:AcquireTarget(a.other)
            or not self:Visible(e,a.other) or not F:CooperativeVisible(a.target,a.other)
            or a.target:GetPos():DistToSqr(a.other:GetPos())>160^2
            or not self:SpacingInside(a,a.target,a.aim) or not self:SpacingInside(a,a.other,a.otherAim) then self:Finish(e,now);return end
    end
    if now>=(a.nextGeometry or 0) or now>=a.ready then
        a.nextGeometry=now+.2
        if not self:SpacingSpace(e,a) then self:Finish(e,now);return end
    end
    if a.spacing=="isolation" then return self:StepMelee(e,a,now) end
    if now<a.ready then return end
    -- Both pair predicates qualified before callbacks. A first victim's death
    -- does not cancel the second; that victim's own exact life still gates it.
    a.spacingReleased=true
    for _,life in ipairs({a.life,a.otherLife}) do
        if not IsValid(e) or e.LODRosterAttack~=a or not self:ValidSourceLife(a.life) then return end
        if self:ValidLife(life) and life.hero:Health()>0 then self:Damage(e,life.hero,a.event,"arc") end
    end
    if IsValid(e) and e.LODRosterAttack==a and self:ValidSourceLife(a.life) then self:Finish(e,now) end
end
