-- B16 observes canonical voluntary motion; it never owns or modifies movement.
local E,N,Rules,Status=LOD.EnemyRoster,LOD.MazeNavigator,LOD.RPGAbilityRules,LOD.RPGStatusElements
local demands=setmetatable({}, {__mode="k"})
local function copy(v) return Vector(v.x,v.y,v.z) end
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function E:DisciplineMotion(p,now)
    if not self:AcquireTarget(p) or not p:IsPlayer() or p:Health()<=0
        or not Status:CanMoveVoluntarily(p) or not p.GetMoveType or p:GetMoveType()~=MOVETYPE_WALK
        or now<(p.LODForcedMovementUntil or 0) then return nil end
    local speed,walk,sprint=Rules:DodgeMovement(p)
    local sample=Rules.DodgeMotion[p]
    if not sample or not finite(sample.at) or sample.at>now or now-sample.at>.25
        or sample.at<(p.LODForcedMovementUntil or -math.huge)
        or not finite(speed) or not finite(walk) or not finite(sprint) or walk<=0 or sprint<=0 then return nil end
    return speed>=.25*walk,sample.at
end
function E:DisciplineOwned(e,a,now)
    return IsValid(e) and e.LODRosterAttack==a and demands[a.target]==a
        and self:ValidLife(a.life) and now<=a.deadline and self:CanCast(e)
        and now>=(e.LODHitStunUntil or 0) and e:GetPos():DistToSqr(a.origin)<=4^2
        and self:AcquireTarget(a.target) and a.target:Health()>0
        and e:GetPos():DistToSqr(a.target:GetPos())<=360^2
        and N:WorldToCell(a.graph,a.target:GetPos())==a.cell
        and self:DisciplineMotion(a.target,now)~=nil
end
function E:DisciplineValid(e,a,now)
    return self:DisciplineOwned(e,a,now) and self:Visible(e,a.target) and self:DisciplineOwned(e,a,now)
end
function E:ObserveDisciplineMotion(p,now)
    local a=demands[p]
    if not a or a.claimed then return end
    if not self:ValidLife(a.life) then a.invalidMotion=true;return end
    local moving,at=self:DisciplineMotion(p,now)
    if moving==nil then a.invalidMotion=true;return end
    if at>=a.window and at<=a.ready then
        if a.sampleLast and (at<a.sampleLast or at-a.sampleLast>.15) then a.invalidMotion=true;return end
        a.sampleFirst=a.sampleFirst or at;a.sampleLast=at
        -- Observe every FinishMove, including multiple samples between roster
        -- ticks. Later compliance cannot erase an earlier violation.
        if moving~=(a.discipline==2) then a.violated=true end
    end
end
function E:DisciplineSpace(e,a)
    local p=a.target;local ground=p:GetPos()
    if not self:MeleeSupported(e,a.graph,a.cell,e:GetPos())
        or not self:MeleeSupported(p,a.graph,a.cell,ground) then return false end
    local delta=ground-e:GetPos();delta.z=0
    local dir=delta:GetNormalized();if dir:LengthSqr()<.01 then dir=Vector(1,0,0) end
    local side=Vector(-dir.y,dir.x,0);local lo,hi=p:GetCollisionBounds()
    for _,sign in ipairs({-1,1}) do
        local goal=ground+side*(96*sign)
        local tr=util.TraceHull({start=ground,endpos=goal,mins=lo,maxs=hi,mask=MASK_PLAYERSOLID,
            filter=function(v) return v~=p and not v.LODHostile and not v:IsPlayer() end})
        if tr.Hit or tr.StartSolid or tr.AllSolid then return false end
        for i=1,4 do
            if not self:MeleeSupported(p,a.graph,a.cell,ground+(goal-ground)*(i/4)) then return false end
        end
    end
    return true
end
function E:RetireDiscipline(e,a)
    if demands[a.target]==a then demands[a.target]=nil end
    -- Canonical Cancel retires ownership before native replication callbacks.
end
function E:BeginDiscipline(e,p,now)
    local d=self.Definitions[e.LODArchetypeId];local s=LOD.RunManager.State
    if e.LODRosterAttack or not d or not d.discipline or not self:CanCast(e)
        or now<(e.LODNextAttack or 0) or now<(e.LODHitStunUntil or 0)
        or not s or not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function deny() e.LODNextAttack=now+.5;e.LODDisciplineAdvanceUntil=now+.5;return false end
    if self:DisciplineMotion(p,now)==nil then return deny() end
    local old=demands[p]
    if old then
        if self:DisciplineValid(old.life.source,old,now) then return deny() end
        -- Do not leave stale tokens pinning a Hero after removal/reset/error.
        if demands[p]==old then demands[p]=nil end
    end
    local life=self:CaptureLife(e,p)
    if not self:ValidLife(life) or not self:Visible(e,p) or e:GetPos():DistToSqr(p:GetPos())>360^2 then return deny() end
    local count=0
    for source in pairs(self.Active) do
        local a=IsValid(source) and source.LODRosterAttack
        if a and a.discipline and self:DisciplineValid(source,a,now) then count=count+1 end
    end
    if count>=16 then return deny() end
    local a=self:Bind({discipline=d.discipline,kind="bullet",life=life,target=p,origin=copy(e:GetPos()),
        cell=N:WorldToCell(s.Graph,e:GetPos()),started=now,ready=now+d.warning,last=now,event={}},s)
    a.deadline=a.ready+.2;a.window=a.ready-.4
    if not self:DisciplineSpace(e,a) then return deny() end
    demands[p]=a;self.Active[e]=true;e.LODRosterAttack=a;e.LODDisciplineAdvanceUntil=nil
    LOD.HostileMotionV2:Stop(e)
    local fields={{"SetNW2Int","LOD_RosterAttack",1},{"SetNW2Int","LOD_DisciplineMode",a.discipline},
        {"SetNW2Vector","LOD_DisciplineOrigin",a.origin},{"SetNW2Vector","LOD_DisciplineAim",p:WorldSpaceCenter()},
        {"SetNW2Float","LOD_DisciplineReady",a.ready},{"SetNW2Float","LOD_DisciplineUntil",a.deadline}}
    for _,field in ipairs(fields) do
        if e.LODRosterAttack~=a or not self:ValidLife(a.life) then return false end
        e[field[1]](e,field[2],field[3])
    end
    if not self:DisciplineValid(e,a,now) then if e.LODRosterAttack==a then self:Cancel(e) end;return false end
    e:EmitSound("npc/metropolice/vo/holdit.wav",72,100,.75)
    if self:DisciplineValid(e,a,now) then e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true) end
    return e.LODRosterAttack==a
end
function E:StepDiscipline(e,a,now)
    if not IsValid(e) or e.LODRosterAttack~=a then return end
    if not self:ValidSourceLife(a.life) then self:Cancel(e);return end
    if a.claimed then
        if now>a.deadline then self:Finish(e,now) end
        return
    end
    if a.invalidMotion or not self:DisciplineValid(e,a,now) or now-a.last>.25 then self:Finish(e,now);return end
    a.last=now
    if now>=(a.nextGeometry or 0) or now>=a.ready then
        a.nextGeometry=now+.2
        if not self:DisciplineSpace(e,a) then self:Finish(e,now);return end
    end
    if now>=(a.nextSync or 0) then
        a.nextSync=now+.1;e:SetNW2Vector("LOD_DisciplineAim",a.target:WorldSpaceCenter())
        if e.LODRosterAttack~=a or not self:DisciplineValid(e,a,now) then return end
    end
    if now<a.ready then return end
    a.claimed=true;a.recoveryUntil=now+self.Definitions[e.LODArchetypeId].recovery
    local covered=a.sampleFirst and a.sampleLast and a.sampleLast-a.sampleFirst>=.3-1e-6
        and a.ready-a.sampleLast<=.1+1e-6
    if covered and a.violated then
        a.event.impactOrigin=a.origin+Vector(0,0,48)
        a.event.commitmentGate=function()
            return not a.invalidMotion and self:DisciplineValid(e,a,CurTime()) and self:DisciplineSpace(e,a)
                and self:DisciplineOwned(e,a,CurTime())
        end
        self:Damage(e,a.target,a.event,"bullet")
    end
    if IsValid(e) and e.LODRosterAttack==a then
        if self:ValidSourceLife(a.life) then self:Finish(e,now) else self:Cancel(e) end
    end
end
