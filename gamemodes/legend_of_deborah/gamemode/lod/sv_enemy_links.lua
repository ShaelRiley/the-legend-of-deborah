-- B19: ordinary allies supply finite firing origins or a moving hazard endpoint.
-- The ward keeps its own AI; only this exact channel owns its link reservation.
local E,N,Rules,Status=LOD.EnemyRoster,LOD.MazeNavigator,LOD.RPGAbilityRules,LOD.RPGStatusElements
local wards=setmetatable({}, {__mode="k"})
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
local function current(e,a) return IsValid(e) and e.LODRosterAttack==a end
local function wardKind(w)
    return IsValid(w) and not w.LODFriendlySummon and not w.LODSummonedSeeker
        and w.LODArchetypeId~="relay" and w.LODArchetypeId~="lacemaker"
end
function E:RetireLink(e,a)
    if a.ward and wards[a.ward]==a then wards[a.ward]=nil end
end
function E:LinkOwned(e,a,now)
    if not current(e,a) or not self:ValidLife(a.life) or now>a.deadline
        or not self:CanCast(e) or now<(e.LODHitStunUntil or 0)
        or e:GetPos():DistToSqr(a.origin)>4^2 or not self:AcquireTarget(a.target)
        or a.target:Health()<=0 or e:GetPos():DistToSqr(a.target:GetPos())>360^2
        or N:WorldToCell(a.graph,e:GetPos())~=a.cell
        or N:WorldToCell(a.graph,a.target:GetPos())~=a.cell then return false end
    if a.mode==2 and (not Status:CanMoveVoluntarily(a.target)
        or not a.target.GetMoveType or a.target:GetMoveType()~=MOVETYPE_WALK
        or now<(a.target.LODForcedMovementUntil or 0)) then return false end
    if a.ward then
        local w=a.ward;local drift=a.mode==2 and 96 or 32
        if not wardKind(w) or wards[w]~=a or not LOD.EnemySupport:Eligible(e,w,240)
            or Status.ActorLives[w]~=a.wardLife or Rules:ProgressionState(w)~=a.wardState
            or N:WorldToCell(a.graph,w:GetPos())~=a.cell
            or w:GetPos():DistToSqr(a.wardOrigin)>drift^2
            or w:GetPos():DistToSqr(a.wardPrevious)>32^2
            or w:GetPos():DistToSqr(a.target:GetPos())>360^2 then return false end
    end
    return current(e,a) and self:ValidLife(a.life) and (not a.ward or wards[a.ward]==a)
end
function E:LinkValid(e,a,now)
    return self:LinkOwned(e,a,now) and self:Visible(e,a.target)
        and (not a.ward or self:Visible(a.ward,a.target)) and self:LinkOwned(e,a,now)
end
function E:LinkSpace(e,a)
    local p=a.target;local ground=p:GetPos()
    if not self:MeleeSupported(e,a.graph,a.cell,e:GetPos())
        or not self:MeleeSupported(p,a.graph,a.cell,ground)
        or a.ward and not self:MeleeSupported(a.ward,a.graph,a.cell,a.ward:GetPos()) then return false end
    local direction=flat(a.mode==2 and a.ward:GetPos()-a.origin or a.aim-a.from):GetNormalized()
    if direction:LengthSqr()<.01 then direction=Vector(1,0,0) end
    local side=Vector(-direction.y,direction.x,0);local lo,hi=p:GetCollisionBounds()
    for _,sign in ipairs({-1,1}) do
        local goal=ground+side*(96*sign)
        local tr=util.TraceHull({start=ground,endpos=goal,mins=lo,maxs=hi,mask=MASK_PLAYERSOLID,
            filter=function(v) return v~=p and not v.LODHostile and not v:IsPlayer() end})
        if tr.Hit or tr.StartSolid or tr.AllSolid then return false end
        for i=0,4 do
            if not self:MeleeSupported(p,a.graph,a.cell,ground+(goal-ground)*(i/4)) then return false end
        end
    end
    if a.mode==2 then
        local delta=a.ward:GetPos()-a.origin;local steps=math.max(1,math.ceil(delta:Length()/24))
        if steps>10 then return false end
        for i=0,steps do
            if not self:MeleeSupported(p,a.graph,a.cell,a.origin+delta*(i/steps)) then return false end
        end
    end
    return true
end
function E:LinkLane(e,a)
    local tr=util.TraceLine({start=a.from,endpos=a.aim,mask=MASK_SHOT,
        filter=function(v) return v~=e and v~=a.ward end})
    return tr.Hit and not tr.StartSolid and not tr.AllSolid and tr.Entity==a.target
end
function E:LinkContact(e,a)
    local from=a.origin;local delta=a.ward:GetPos()-from;local length=flat(delta):LengthSqr()
    if length<1 then return false end
    local p=a.target:GetPos();local along=math.Clamp(flat(p-from):Dot(flat(delta))/length,0,1)
    local point=from+delta*along;local offset=p-point
    if flat(offset):LengthSqr()>18^2 or offset.z< -4 or offset.z>72 then return false end
    local tr=util.TraceLine({start=point+Vector(0,0,24),endpos=a.target:WorldSpaceCenter(),mask=MASK_SHOT,
        filter=function(v) return v~=e and v~=a.ward end})
    if tr.StartSolid or tr.AllSolid or tr.Hit and tr.Entity~=a.target then return false end
    return true,point+Vector(0,0,24)
end
function E:PublishLink(e,a)
    local endpoint=a.mode==2 and copy(a.ward:GetPos()) or a.from
    local fields={{"SetNW2Int","LOD_RosterAttack",1},{"SetNW2Int","LOD_LinkMode",a.mode},
        {"SetNW2Int","LOD_LinkPhase",a.phase=="active" and 2 or 1},
        {"SetNW2Vector","LOD_LinkOrigin",a.origin},{"SetNW2Vector","LOD_LinkWard",endpoint},
        {"SetNW2Vector","LOD_LinkAim",a.aim},{"SetNW2Float","LOD_LinkReady",a.ready},
        {"SetNW2Float","LOD_LinkUntil",a.deadline},{"SetNW2Float","LOD_LinkStarted",a.started}}
    for _,f in ipairs(fields) do
        if not self:LinkValid(e,a,CurTime()) then return false end
        e[f[1]](e,f[2],f[3])
    end
    return self:LinkValid(e,a,CurTime())
end
function E:LinkCount(now)
    local count=0
    for source in pairs(self.Active) do
        local a=IsValid(source) and source.LODRosterAttack
        if a and a.link and now<=a.deadline then count=count+1 end
    end
    return count
end
function E:BeginLink(e,p,now)
    local d=self.Definitions[e.LODArchetypeId];local s=LOD.RunManager.State
    if e.LODRosterAttack or not d or not d.link or not self:CanCast(e)
        or now<(e.LODNextAttack or 0) or now<(e.LODHitStunUntil or 0)
        or not s or not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function deny()
        if IsValid(e) and not e.LODRosterAttack then e.LODNextAttack=now+.5;e.LODLinkAdvanceUntil=now+.5 end
        return false
    end
    if not self:AcquireTarget(p) or not self:Visible(e,p) or e:GetPos():DistToSqr(p:GetPos())>360^2
        or self:LinkCount(now)>=16 then return deny() end
    local life=self:CaptureLife(e,p)
    if not self:ValidLife(life) then return deny() end
    local a=self:Bind({link=d.link,mode=d.link,kind="bullet",phase="prep",life=life,target=p,
        origin=copy(e:GetPos()),cell=N:WorldToCell(s.Graph,e:GetPos()),aim=copy(p:WorldSpaceCenter()),
        started=now,last=now,event={}},s)
    local candidates={}
    for i,w in ipairs(LOD.HostileRegistry:List()) do
        if i>128 then break end
        local old=wards[w]
        if old and (not current(old.life.source,old) or not self:ValidSourceLife(old.life) or now>old.deadline)
            and wards[w]==old then wards[w]=nil end
        if not wards[w] and wardKind(w) and LOD.EnemySupport:Eligible(e,w,240)
            and N:WorldToCell(a.graph,w:GetPos())==a.cell and w:GetPos():DistToSqr(p:GetPos())<=360^2
            and self:MeleeSupported(w,a.graph,a.cell,w:GetPos()) and self:Visible(w,p) then candidates[#candidates+1]=w end
    end
    table.sort(candidates,function(x,y)
        local dx,dy=e:GetPos():DistToSqr(x:GetPos()),e:GetPos():DistToSqr(y:GetPos())
        return dx==dy and x:EntIndex()<y:EntIndex() or dx<dy
    end)
    for i,w in ipairs(candidates) do
        if i>8 then break end
        a.ward=w;a.wardOrigin=copy(w:GetPos());a.wardPrevious=copy(w:GetPos());a.from=copy(w:WorldSpaceCenter())
        if self:LinkSpace(e,a) then
            Status:BindActorLife(w);a.wardLife=Status.ActorLives[w];a.wardState=Rules:ProgressionState(w);break
        end
        a.ward=nil
    end
    if not a.ward then a.mode=3;a.from=a.origin+Vector(0,0,48) end
    a.ready=now+(a.mode==2 and 1.2 or 1.4);a.activeEnd=a.mode==2 and a.ready+2 or nil
    a.deadline=(a.activeEnd or a.ready)+.2
    if not self:LinkSpace(e,a) or N:WorldToCell(a.graph,p:GetPos())~=a.cell then return deny() end
    if e.LODRosterAttack or not self:ValidLife(life) or not self:CanCast(e)
        or a.ward and (wards[a.ward] or not wardKind(a.ward) or not LOD.EnemySupport:Eligible(e,a.ward,240)
            or Status.ActorLives[a.ward]~=a.wardLife or Rules:ProgressionState(a.ward)~=a.wardState) then return deny() end
    if e.LODRosterAttack or not self:ValidLife(life) or a.ward and wards[a.ward] then return deny() end
    if self:LinkCount(now)>=16 or e.LODRosterAttack or a.ward and wards[a.ward] then return deny() end
    self.Active[e]=true;e.LODRosterAttack=a;e.LODLinkAdvanceUntil=nil
    if a.ward then wards[a.ward]=a end
    local function abort() if current(e,a) then self:Finish(e,now) end;return false end
    if not self:PublishLink(e,a) then return abort() end
    LOD.HostileMotionV2:Stop(e)
    if not self:LinkValid(e,a,now) then return abort() end
    e:EmitSound("npc/turret_floor/active.wav",72,100,.75)
    if not self:LinkValid(e,a,now) then return abort() end
    e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    if not self:LinkValid(e,a,now) then return abort() end
    return current(e,a)
end
function E:StepLink(e,a,now)
    if not current(e,a) then return end
    if a.servicing or a.claimed then
        if now>a.deadline then self:Finish(e,now) end
        return
    end
    if not self:ValidSourceLife(a.life) then self:Cancel(e);return end
    local function finish() if current(e,a) then self:Finish(e,now) end end
    if not self:LinkValid(e,a,now) or now-a.last>.25 then finish();return end
    a.last=now;a.servicing=true
    local function work()
        if now>=(a.nextGeometry or 0) or now>=a.ready then
            a.nextGeometry=now+.1
            if not self:LinkSpace(e,a) or not self:LinkValid(e,a,now) then finish();return end
        end
        if a.mode==2 then
            if now>=a.activeEnd then finish();return end
            if now>=(a.nextSync or 0) then
                a.nextSync=now+.1
                if not self:PublishLink(e,a) then finish();return end
            end
        end
        if now<a.ready then return end
        if a.mode==2 and a.phase=="prep" then
            if now>a.ready+.2 then finish();return end
            a.phase="active"
            if not self:PublishLink(e,a) then finish();return end
        end
        local function gate()
            if not self:LinkValid(e,a,CurTime()) or not self:LinkSpace(e,a) then return false end
            local contact=a.mode==2 and CurTime()<a.activeEnd and self:LinkContact(e,a)
                or a.mode~=2 and CurTime()<=a.ready+.2 and self:LinkLane(e,a)
            return contact and self:LinkOwned(e,a,CurTime())
        end
        if not gate() then if a.mode~=2 then finish() end;return end
        a.claimed=true;a.recoveryUntil=now+3
        local impact
        if a.mode==2 then local contact;contact,impact=self:LinkContact(e,a) end
        a.event.impactOrigin=impact or a.from;a.event.commitmentGate=gate
        self:Damage(e,a.target,a.event,"bullet")
        finish()
    end
    work()
    if current(e,a) and a.ward then a.wardPrevious=copy(a.ward:GetPos()) end
    a.servicing=nil
end
