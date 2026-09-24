-- B12 extends the roster service; condition lifetime/removal belongs to Status.
local E,N,Status=LOD.EnemyRoster,LOD.MazeNavigator,LOD.RPGStatusElements
local ailments={"bleeding","immolated","poisoned"}
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
function E:ConditionSpace(e,a)
    if not self:MeleeSupported(e,a.graph,a.cell,e:GetPos())
        or not self:MeleeSupported(e,a.graph,a.cell,a.aim) then return false end
    local side=Vector(-a.direction.y,a.direction.x,0)
    for _,sign in ipairs({-1,1}) do
        local goal=a.aim+side*(96*sign)
        local lo,hi=a.target:GetCollisionBounds()
        local tr=util.TraceHull({start=a.aim,endpos=goal,mins=lo,maxs=hi,mask=MASK_PLAYERSOLID,
            filter=function(v) return v~=a.target and not v.LODHostile and not v:IsPlayer() end})
        if tr.Hit or tr.StartSolid or tr.AllSolid then return false end
        for i=1,4 do
            if not self:MeleeSupported(e,a.graph,a.cell,a.aim+(goal-a.aim)*(i/4)) then return false end
        end
    end
    return true
end
function E:ConditionValid(e,a)
    if not IsValid(e) or e.LODRosterAttack~=a or not self:ValidLife(a.life)
        or not self:CanCast(e) or CurTime()<(e.LODHitStunUntil or 0)
        or e:GetPos():DistToSqr(a.origin)>4^2 or not self:AcquireTarget(a.target) or a.target:Health()<=0
        or not self:Visible(e,a.target) then return false end
    local active,entry=Status:Has(a.target,a.statusId)
    return active and entry==a.statusEntry
end
function E:BeginCondition(e,p,now)
    if e.LODRosterAttack or not self:AcquireTarget(p) or not self:CanCast(e)
        or now<(e.LODNextAttack or 0) or now<(e.LODHitStunUntil or 0) then return false end
    local s=LOD.RunManager.State;local d=self.Definitions[e.LODArchetypeId]
    if not s or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function fail() e.LODNextAttack=now+.5;e.LODConditionAdvanceUntil=now+.5;return false end
    if not self:Visible(e,p) or e:GetPos():DistToSqr(p:GetPos())>d.range^2 then return fail() end
    local life=self:CaptureLife(e,p)
    if not self:ValidLife(life) then return fail() end
    local id,entry=Status:FirstNegative(p,ailments)
    if not id then
        e:SetNW2Bool("LOD_ConditionMark",false)
        self:Begin(e,p,now,{conditionFallback=true});return e.LODRosterAttack~=nil
    end
    local origin=copy(e:GetPos());local cell=N:WorldToCell(s.Graph,origin)
    -- Capture ground, not a future/airborne location; the mark never follows.
    if not self:MeleeSupported(p,s.Graph,cell,p:GetPos()) then return fail() end
    local direction=flat(p:GetPos()-origin):GetNormalized()
    if direction:LengthSqr()<.01 then direction=Angle(0,e:GetAngles().y,0):Forward() end
    local a=self:Bind({condition=true,kind="bullet",target=p,life=life,cell=cell,
        origin=origin,aim=copy(p:GetPos()),direction=direction,statusId=id,statusEntry=entry,
        ready=now+d.warning,last=now,event={impactOrigin=origin+Vector(0,0,48)}},s)
    a.deadline=a.ready+.2
    if not self:ConditionSpace(e,a) then return fail() end
    local count=0
    for source in pairs(self.Active) do
        local attack=IsValid(source) and source.LODRosterAttack
        if attack and attack.condition then count=count+1 end
    end
    if count>=16 then return fail() end
    self.Active[e]=true;e.LODRosterAttack=a;e.LODConditionAdvanceUntil=nil
    LOD.HostileMotionV2:Stop(e);e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    e:SetNW2Int("LOD_RosterAttack",1);e:SetNW2Bool("LOD_ConditionMark",true)
    e:SetNW2Vector("LOD_ConditionOrigin",origin);e:SetNW2Vector("LOD_ConditionAim",a.aim)
    e:SetNW2Float("LOD_ConditionReady",a.ready);e:SetNW2Float("LOD_ConditionUntil",a.deadline)
    e:EmitSound("npc/combine_soldier/vo/targetcontactat.wav",72,100,.75)
    return true
end
function E:StepCondition(e,a,now)
    if e.LODRosterAttack~=a or a.released then return end
    if not self:ConditionValid(e,a) or now>a.deadline or now-a.last>.25 then self:Finish(e,now);return end
    a.last=now
    -- Geometry is bounded and checked at most five times per second, plus release.
    if now>=(a.nextGeometry or 0) or now>=a.ready then
        a.nextGeometry=now+.2
        if not self:ConditionSpace(e,a) then self:Finish(e,now);return end
    end
    if now<a.ready then return end
    a.released=true -- claim before native damage/condition callbacks
    local p=a.target;local delta=p:GetPos()-a.aim
    if N:WorldToCell(a.graph,p:GetPos())==a.cell and flat(delta):LengthSqr()<=64^2
        and delta.z>=-4 and delta.z<=72 then
        local dealt=self:Damage(e,p,a.event,"bullet")
        if dealt and dealt>0 and self:ConditionValid(e,a) then
            Status:ClearExpected(p,a.statusId,a.statusEntry,"exactor")
        end
    end
    if IsValid(e) and e.LODRosterAttack==a then self:Finish(e,now) end
end
