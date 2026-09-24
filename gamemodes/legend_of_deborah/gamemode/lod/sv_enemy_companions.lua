-- B17 owns finite companion commitments; motion, death receipts and damage keep
-- their canonical owners. A bodyguard is an ordinary body, never a defense buff.
local E,N,Rules,Status=LOD.EnemyRoster,LOD.MazeNavigator,LOD.RPGAbilityRules,LOD.RPGStatusElements
local wards=setmetatable({}, {__mode="k"})
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
local function current(e,a) return IsValid(e) and e.LODRosterAttack==a end
local function wardKind(w)
    return IsValid(w) and not w.LODFriendlySummon and not w.LODSummonedSeeker
        and w.LODArchetypeId~="interposer" and w.LODArchetypeId~="mourner"
end
function E:RetireCompanion(e,a)
    if a.ward and wards[a.ward]==a then wards[a.ward]=nil end
    -- Caller removes the attack token before Stop/network callbacks.
end
function E:CompanionOwned(e,a,now)
    if not current(e,a) or not self:ValidLife(a.life) or not self:CanCast(e)
        or now>a.deadline or now<(e.LODHitStunUntil or 0)
        or not self:AcquireTarget(a.target) or a.target:Health()<=0
        or e:GetPos():DistToSqr(a.target:GetPos())>360^2
        or N:WorldToCell(a.graph,e:GetPos())~=a.cell
        or N:WorldToCell(a.graph,a.target:GetPos())~=a.cell then return false end
    local anchor=a.phase=="move" and a.lastPos or a.origin
    if e:GetPos():DistToSqr(anchor)>4^2 then return false end
    if a.companion==1 and (a.phase=="prep" or a.phase=="move")
        and not Status:CanMoveVoluntarily(e) then return false end
    return true
end
function E:CompanionValid(e,a,now)
    return self:CompanionOwned(e,a,now) and self:Visible(e,a.target) and self:CompanionOwned(e,a,now)
end
function E:CompanionWard(e,a,dead)
    local w=a.ward
    if not wardKind(w) or wards[w]~=a or Rules:ProgressionState(w)~=a.wardState
        or w:GetPos():DistToSqr(a.wardOrigin)>32^2 or e:GetPos():DistToSqr(w:GetPos())>240^2
        or N:WorldToCell(a.graph,w:GetPos())~=a.cell
        or not self:MeleeSupported(w,a.graph,a.cell,w:GetPos()) or not self:Visible(e,w) then return false end
    if not dead then
        return LOD.EnemySupport:Eligible(e,w,240) and Status.ActorLives[w]==a.wardLife
    end
    local r=w.LODRemainsReceipt
    return a.phase=="oath" and r and r.source==w and r.sourceState==a.wardState
        and r.livingLife==a.wardLife and r.sealedAt>=a.armed and r.sealedAt<=a.oathEnd
        and CurTime()>=r.sealedAt and CurTime()-r.sealedAt<=.25
        and LOD.EnemyRemains:CorpseLive(r) and self:Live(r,LOD.RunManager.State)
end
function E:CompanionSpace(e,a)
    local p=a.target;local ground=p:GetPos()
    if not self:MeleeSupported(e,a.graph,a.cell,e:GetPos())
        or not self:MeleeSupported(p,a.graph,a.cell,ground) then return false end
    if a.phase~="shot" then return true end
    local dir=flat(ground-e:GetPos()):GetNormalized()
    if dir:LengthSqr()<.01 then dir=Vector(1,0,0) end
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
local function overlaps(e,pos,other)
    local lo,hi=e:GetCollisionBounds();local ol,oh=other:GetCollisionBounds();local p=other:GetPos()
    return pos.x+hi.x>p.x+ol.x and pos.x+lo.x<p.x+oh.x
        and pos.y+hi.y>p.y+ol.y and pos.y+lo.y<p.y+oh.y
        and pos.z+hi.z>p.z+ol.z and pos.z+lo.z<p.z+oh.z
end
function E:CompanionRoute(e,a)
    local from=e:GetPos();local goal=a.goal;local lo,hi=e:GetCollisionBounds()
    if overlaps(e,goal,a.target) or overlaps(e,goal,a.ward) then return false end
    local tr=util.TraceHull({start=from,endpos=goal,mins=lo,maxs=hi,mask=MASK_NPCSOLID,filter=e})
    if tr.Hit or tr.StartSolid or tr.AllSolid then return false end
    local steps=math.max(1,math.ceil(from:Distance(goal)/24))
    if steps>8 then return false end
    for i=0,steps do
        if not self:MeleeSupported(e,a.graph,a.cell,from+(goal-from)*(i/steps)) then return false end
    end
    return true
end
function E:CompanionPublishValid(e,a)
    return self:CompanionValid(e,a,CurTime()) and (a.phase=="shot" or self:CompanionWard(e,a,false))
        and self:CompanionOwned(e,a,CurTime())
end
function E:PublishCompanion(e,a)
    local phase=a.phase=="prep" and 1 or (a.phase=="shot" and 3 or 2)
    local fields={{"SetNW2Int","LOD_RosterAttack",1},{"SetNW2Int","LOD_CompanionMode",a.companion},
        {"SetNW2Int","LOD_CompanionPhase",phase},{"SetNW2Int","LOD_CompanionRetaliation",a.retaliation and 1 or 0},
        {"SetNW2Vector","LOD_CompanionOrigin",a.origin},{"SetNW2Vector","LOD_CompanionGoal",a.goal or a.origin},
        {"SetNW2Vector","LOD_CompanionWard",a.wardSnapshot or a.origin},
        {"SetNW2Vector","LOD_CompanionAim",a.aim},{"SetNW2Float","LOD_CompanionReady",a.ready},
        {"SetNW2Float","LOD_CompanionUntil",a.deadline}}
    for _,f in ipairs(fields) do
        if not self:CompanionPublishValid(e,a) then return false end
        e[f[1]](e,f[2],f[3])
    end
    return self:CompanionPublishValid(e,a)
end
function E:CompanionShot(e,a,now,retaliation)
    if not self:CompanionValid(e,a,now) then return false end
    if a.ward and wards[a.ward]==a then wards[a.ward]=nil end
    a.phase="shot";a.retaliation=retaliation;a.origin=copy(e:GetPos());a.goal=nil;a.wardSnapshot=nil
    a.aim=copy(a.target:WorldSpaceCenter());a.ready=now+1.2;a.deadline=a.ready+.2
    a.last=now;a.nextGeometry=now+.2;a.event={};a.claimed=nil
    if not self:CompanionSpace(e,a) or not self:PublishCompanion(e,a) then return false end
    LOD.HostileMotionV2:Stop(e)
    if not self:CompanionValid(e,a,now) then return false end
    e:EmitSound("npc/turret_floor/active.wav",72,100,.75)
    if not self:CompanionValid(e,a,now) then return false end
    e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    return self:CompanionValid(e,a,now)
end
function E:BeginCompanion(e,p,now)
    local d=self.Definitions[e.LODArchetypeId];local s=LOD.RunManager.State
    if e.LODRosterAttack or not d or not d.companion or not self:CanCast(e)
        or now<(e.LODNextAttack or 0) or now<(e.LODHitStunUntil or 0)
        or not s or not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function deny() e.LODNextAttack=now+.5;e.LODCompanionAdvanceUntil=now+.5;return false end
    if not self:AcquireTarget(p) or not self:Visible(e,p) or e:GetPos():DistToSqr(p:GetPos())>360^2 then return deny() end
    local count=0
    for source in pairs(self.Active) do
        local a=IsValid(source) and source.LODRosterAttack
        if a and a.companion and now<=a.deadline then count=count+1 end
    end
    if count>=16 then return deny() end
    local life=self:CaptureLife(e,p)
    if not self:ValidLife(life) then return deny() end
    local a=self:Bind({companion=d.companion,phase="prep",life=life,target=p,origin=copy(e:GetPos()),
        cell=N:WorldToCell(s.Graph,e:GetPos()),aim=copy(p:WorldSpaceCenter()),started=now,
        ready=now+.8,last=now,event={}},s)
    a.deadline=a.ready+(a.companion==1 and 3.8 or 3)
    if not self:CompanionSpace(e,a) or N:WorldToCell(a.graph,p:GetPos())~=a.cell then return deny() end
    local candidates={}
    for i,w in ipairs(LOD.HostileRegistry:List()) do
        if i>128 then break end
        local old=wards[w]
        if old and (not current(old.life.source,old) or not self:ValidSourceLife(old.life) or now>old.deadline) then
            if wards[w]==old then wards[w]=nil end
        end
        if not wards[w] and wardKind(w)
            and LOD.EnemySupport:Eligible(e,w,240) and N:WorldToCell(a.graph,w:GetPos())==a.cell
            and self:MeleeSupported(w,a.graph,a.cell,w:GetPos()) then candidates[#candidates+1]=w end
    end
    table.sort(candidates,function(x,y)
        local dx,dy=e:GetPos():DistToSqr(x:GetPos()),e:GetPos():DistToSqr(y:GetPos())
        return dx==dy and x:EntIndex()<y:EntIndex() or dx<dy
    end)
    for _,w in ipairs(candidates) do
        a.ward=w;a.wardOrigin=copy(w:GetPos());a.wardSnapshot=copy(w:WorldSpaceCenter())
        local usable=true
        if a.companion==1 then
            local delta=flat(p:GetPos()-w:GetPos());local dist=delta:Length()
            a.goal=w:GetPos()+delta:GetNormalized()*64
            local travel=e:GetPos():Distance(a.goal)
            usable=Status:CanMoveVoluntarily(e) and dist>=160 and dist<=360 and travel>=32 and travel<=160
                and self:CompanionRoute(e,a)
        end
        if usable then
            Status:BindActorLife(w);a.wardLife=Status.ActorLives[w];a.wardState=Rules:ProgressionState(w);break
        end
        a.ward=nil;a.goal=nil;a.wardSnapshot=nil
    end
    if not a.ward then a.phase="shot";a.ready=now+1.2;a.deadline=a.ready+.2 end
    if not self:CompanionSpace(e,a) then return deny() end
    -- Traces/life binding are native boundaries: never overwrite a reentrant
    -- new attack or a reservation taken while preflight was running.
    if e.LODRosterAttack or not self:ValidLife(life) or not self:CanCast(e) then return false end
    if a.ward and (wards[a.ward] or not wardKind(a.ward) or not LOD.EnemySupport:Eligible(e,a.ward,240)
        or Status.ActorLives[a.ward]~=a.wardLife or Rules:ProgressionState(a.ward)~=a.wardState) then return deny() end
    if e.LODRosterAttack or not self:ValidLife(life) or a.ward and wards[a.ward] then return false end
    -- The final callback-free capacity check includes admissions made by traces
    -- and life/visibility callbacks during preflight.
    count=0
    for source in pairs(self.Active) do
        local pending=IsValid(source) and source.LODRosterAttack
        if pending and pending.companion and now<=pending.deadline then count=count+1 end
    end
    if count>=16 then return deny() end
    self.Active[e]=true;e.LODRosterAttack=a;e.LODCompanionAdvanceUntil=nil
    if a.ward then wards[a.ward]=a end
    local function abort() if current(e,a) then self:Finish(e,now) end;return false end
    if not self:CompanionPublishValid(e,a) or not self:PublishCompanion(e,a) then return abort() end
    LOD.HostileMotionV2:Stop(e)
    if not self:CompanionPublishValid(e,a) then return abort() end
    e:EmitSound("npc/metropolice/vo/holdit.wav",72,100,.75)
    if not self:CompanionPublishValid(e,a) then return abort() end
    e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    if not self:CompanionPublishValid(e,a) then return abort() end
    return current(e,a)
end
function E:CompanionLane(e,a)
    local tr=util.TraceLine({start=a.origin+Vector(0,0,48),endpos=a.aim,mask=MASK_SHOT,filter=e})
    return tr.Hit and not tr.StartSolid and not tr.AllSolid and tr.Entity==a.target
        and self:CompanionOwned(e,a,CurTime())
end
function E:StepCompanion(e,a,now)
    if not current(e,a) then return end
    if a.servicing or a.claimed then
        if now>a.deadline then self:Finish(e,now) end
        return
    end
    if not self:ValidSourceLife(a.life) then self:Cancel(e);return end
    local function finish() if current(e,a) then self:Finish(e,now) end end
    if not self:CompanionValid(e,a,now) or now-a.last>.25 then finish();return end
    a.last=now;a.servicing=true
    local function work()
        if now>=(a.nextGeometry or 0) or (a.phase=="shot" and now>=a.ready) then
            a.nextGeometry=now+.2
            if not self:CompanionSpace(e,a) then finish();return end
        end
        if a.phase~="shot" then
            local dead=IsValid(a.ward) and (a.ward.LODDead or a.ward:Health()<=0)
            if not self:CompanionWard(e,a,dead) then finish();return end
            if dead then
                -- Receipt is consumed only by this oath; corpse/reward ownership stays intact.
                a.oathConsumed=true
                if not self:CompanionShot(e,a,now,true) then finish() end
                return
            end
            if now>=(a.nextSync or 0) then
                a.nextSync=now+.1;a.wardSnapshot=copy(a.ward:WorldSpaceCenter())
                e:SetNW2Vector("LOD_CompanionWard",a.wardSnapshot)
                if not self:CompanionPublishValid(e,a) then finish();return end
            end
        end
        if a.phase=="prep" then
            if now<a.ready then return end
            if now>a.ready+.2 then finish();return end
            if a.companion==1 then
                a.phase="move";a.moveEnd=a.ready+1.8;a.holdCap=a.ready+3.8
                a.ready=a.moveEnd;a.lastPos=copy(e:GetPos());e.LODMotionLastUpdate=now
            else
                a.phase="oath";a.armed=a.ready;a.oathEnd=a.ready+3;a.ready=a.oathEnd
            end
            if not self:PublishCompanion(e,a) then finish();return end
        end
        if a.phase=="move" then
            if now>a.moveEnd or not self:CompanionRoute(e,a) then finish();return end
            local beforeMove=copy(e:GetPos())
            LOD.HostileMotionV2:MoveToward(e,{pos=a.goal})
            if not current(e,a) or not self:ValidLife(a.life) then return end
            local path=a.goal-a.origin;local moved=e:GetPos()-a.origin;local length=path:Length()
            local along=moved:Dot(path:GetNormalized())
            if (e:GetPos():DistToSqr(beforeMove)>.05^2 and (not e.LODMotionLastPos or e:GetPos():DistToSqr(e.LODMotionLastPos)>.05^2))
                or along<-.05 or along>length+.05 or (moved-path:GetNormalized()*along):LengthSqr()>4^2
                or not self:MeleeSupported(e,a.graph,a.cell,e:GetPos()) then finish();return end
            a.lastPos=copy(e:GetPos())
            if e:GetPos():DistToSqr(a.goal)<=.05^2 then
                a.phase="guard";a.origin=copy(e:GetPos());a.ready=math.min(now+2,a.holdCap);a.deadline=a.ready
                LOD.HostileMotionV2:Stop(e)
                if not self:PublishCompanion(e,a) then finish();return end
                e:_SetActivity(ACT_IDLE,true)
            end
        elseif a.phase=="guard" or a.phase=="oath" then
            if now>=a.ready then finish() end
        elseif a.phase=="shot" and now>=a.ready then
            a.claimed=true;a.recoveryUntil=now+3
            local origin=a.origin+Vector(0,0,48)
            local tr=util.TraceLine({start=origin,endpos=a.aim,mask=MASK_SHOT,filter=e})
            if tr.Hit and not tr.StartSolid and not tr.AllSolid and tr.Entity==a.target
                and self:CompanionValid(e,a,now) then
                a.event.impactOrigin=origin
                a.event.commitmentGate=function()
                    return self:CompanionValid(e,a,CurTime()) and self:CompanionSpace(e,a)
                        and self:CompanionLane(e,a) and self:CompanionOwned(e,a,CurTime())
                end
                self:Damage(e,a.target,a.event,"bullet")
            end
            finish()
        end
    end
    work()
    a.servicing=nil
end
