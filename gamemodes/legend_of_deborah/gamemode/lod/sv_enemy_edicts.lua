-- B18 owns finite warnings and observations, never attacks, motion or resources.
local E,N,Status=LOD.EnemyRoster,LOD.MazeNavigator,LOD.RPGStatusElements
E.HeroOrders=E.HeroOrders or setmetatable({}, {__mode="k"})
local orders=E.HeroOrders
local function copy(v) return Vector(v.x,v.y,v.z) end
local function flat(v) return Vector(v.x,v.y,0) end
local function current(e,a) return IsValid(e) and e.LODRosterAttack==a end
function E:RetireEdict(e,a)
    if orders[a.target]==a then orders[a.target]=nil end
end
function E:EdictOwned(e,a,now)
    if not current(e,a) or orders[a.target]~=a or not self:ValidLife(a.life)
        or now>a.deadline or not self:CanCast(e) or now<(e.LODHitStunUntil or 0)
        or e:GetPos():DistToSqr(a.origin)>4^2 or not self:AcquireTarget(a.target)
        or a.target:Health()<=0 or e:GetPos():DistToSqr(a.target:GetPos())>360^2
        or N:WorldToCell(a.graph,e:GetPos())~=a.cell
        or N:WorldToCell(a.graph,a.target:GetPos())~=a.cell then return false end
    if a.edict==2 and (not Status:CanMoveVoluntarily(a.target)
        or not a.target.GetMoveType or a.target:GetMoveType()~=MOVETYPE_WALK
        or now<(a.target.LODForcedMovementUntil or 0)) then return false end
    return self:ValidLife(a.life) and current(e,a) and orders[a.target]==a
end
function E:EdictValid(e,a,now)
    return self:EdictOwned(e,a,now) and self:Visible(e,a.target) and self:EdictOwned(e,a,now)
end
function E:EdictPath(a,from,to)
    local p=a.target;local distance=from:Distance(to)
    local steps=math.max(1,math.ceil(distance/24))
    if steps>8 then return false end
    local lo,hi=p:GetCollisionBounds()
    local tr=util.TraceHull({start=from,endpos=to,mins=lo,maxs=hi,mask=MASK_PLAYERSOLID,
        filter=function(v) return v~=p and not v.LODHostile and not v:IsPlayer() end})
    if tr.Hit or tr.StartSolid or tr.AllSolid then return false end
    for i=0,steps do
        if not self:MeleeSupported(p,a.graph,a.cell,from+(to-from)*(i/steps)) then return false end
    end
    return true
end
function E:EdictSpace(e,a)
    if a.edict==1 then return self:CompanionSpace(e,a) end
    if not self:MeleeSupported(e,a.graph,a.cell,e:GetPos())
        or not self:MeleeSupported(a.target,a.graph,a.cell,a.target:GetPos()) then return false end
    -- Marks and opposite escape stay frozen. Moving into the refuge must not
    -- move that escape farther away or manufacture a new warning footprint.
    return self:EdictPath(a,a.aim,a.refuge) and self:EdictPath(a,a.aim,a.escape)
        and self:EdictPath(a,a.target:GetPos(),a.refuge)
end
function E:EdictLane(e,a)
    local tr=util.TraceLine({start=a.origin+Vector(0,0,48),endpos=a.aim,mask=MASK_SHOT,filter=e})
    return tr.Hit and not tr.StartSolid and not tr.AllSolid and tr.Entity==a.target
        and self:EdictOwned(e,a,CurTime())
end
function E:EdictDanger(a)
    local pos=a.target:GetPos()
    return flat(pos-a.aim):LengthSqr()<=144^2 and flat(pos-a.refuge):LengthSqr()>48^2
end
function E:PublishEdict(e,a)
    local phase=a.phase=="watch" and 2 or (a.phase=="shot" and 3 or 1)
    local fields={{"SetNW2Int","LOD_RosterAttack",1},{"SetNW2Int","LOD_EdictMode",a.edict},
        {"SetNW2Int","LOD_EdictPhase",phase},{"SetNW2Vector","LOD_EdictOrigin",a.origin},
        {"SetNW2Vector","LOD_EdictAim",a.aim},{"SetNW2Vector","LOD_EdictRefuge",a.refuge or a.origin},
        {"SetNW2Vector","LOD_EdictEscape",a.escape or a.origin},{"SetNW2Float","LOD_EdictReady",a.ready},
        {"SetNW2Float","LOD_EdictUntil",a.deadline},{"SetNW2Float","LOD_EdictStarted",a.started}}
    for _,f in ipairs(fields) do
        if not self:EdictValid(e,a,CurTime()) then return false end
        e[f[1]](e,f[2],f[3])
    end
    return self:EdictValid(e,a,CurTime())
end
function E:EdictCount(now)
    local count=0
    for source in pairs(self.Active) do
        local a=IsValid(source) and source.LODRosterAttack
        if a and a.edict and now<=a.deadline then count=count+1 end
    end
    return count
end
function E:BeginEdict(e,p,now)
    local d=self.Definitions[e.LODArchetypeId];local s=LOD.RunManager.State
    if e.LODRosterAttack or not d or not d.edict or not self:CanCast(e)
        or now<(e.LODNextAttack or 0) or now<(e.LODHitStunUntil or 0)
        or not s or not s.Graph or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen then return false end
    local function deny()
        if IsValid(e) and not e.LODRosterAttack then e.LODNextAttack=now+.5;e.LODEdictAdvanceUntil=now+.5 end
        return false
    end
    if not self:AcquireTarget(p) or not self:Visible(e,p) or e:GetPos():DistToSqr(p:GetPos())>360^2 then return deny() end
    local old=orders[p]
    if old then
        if old.edict and self:EdictValid(old.life.source,old,now)
            or old.discipline and self:DisciplineValid(old.life.source,old,now) then return deny() end
        if orders[p]==old then orders[p]=nil end
    end
    if self:EdictCount(now)>=16 then return deny() end
    local life=self:CaptureLife(e,p)
    if not self:ValidLife(life) then return deny() end
    local a=self:Bind({edict=d.edict,kind=d.kind,phase="prep",life=life,target=p,origin=copy(e:GetPos()),
        aim=copy(d.edict==2 and p:GetPos() or p:WorldSpaceCenter()),cell=N:WorldToCell(s.Graph,e:GetPos()),
        started=now,ready=now+d.warning,last=now,event={}},s)
    a.watchEnd=a.edict==1 and a.ready+2.4 or nil
    a.deadline=(a.watchEnd or a.ready)+.2
    if a.edict==2 then
        if not Status:CanMoveVoluntarily(p) or not p.GetMoveType or p:GetMoveType()~=MOVETYPE_WALK
            or now<(p.LODForcedMovementUntil or 0) then return deny() end
        local dir=flat(a.aim-a.origin):GetNormalized()
        if dir:LengthSqr()<.01 then dir=Vector(1,0,0) end
        local side=Vector(-dir.y,dir.x,0);local found=false
        for _,sign in ipairs({1,-1}) do
            a.refuge=a.aim+side*(96*sign);a.escape=a.aim-side*(160*sign)
            if self:EdictSpace(e,a) then found=true;break end
        end
        if not found then return deny() end
    elseif not self:EdictSpace(e,a) then return deny() end
    -- Geometry and replication natives may reenter admission. Reserve only after
    -- their final callbacks, and never overwrite a newer source or Hero token.
    if e.LODRosterAttack or orders[p] or not self:ValidLife(life) or not self:CanCast(e)
        or not self:AcquireTarget(p) or not self:Visible(e,p)
        or e:GetPos():DistToSqr(a.origin)>4^2 or e:GetPos():DistToSqr(p:GetPos())>360^2
        or N:WorldToCell(a.graph,p:GetPos())~=a.cell then return deny() end
    if e.LODRosterAttack or orders[p] or not self:ValidLife(life) or self:EdictCount(now)>=16 then return deny() end
    if e.LODRosterAttack or orders[p] then return deny() end
    orders[p]=a;self.Active[e]=true;e.LODRosterAttack=a;e.LODEdictAdvanceUntil=nil
    local function abort() if current(e,a) then self:Finish(e,now) end;return false end
    if not self:PublishEdict(e,a) then return abort() end
    LOD.HostileMotionV2:Stop(e)
    if not self:EdictValid(e,a,now) then return abort() end
    e:EmitSound(a.edict==1 and "npc/metropolice/vo/holdit.wav" or "npc/vort/attack_charge.wav",72,100,.75)
    if not self:EdictValid(e,a,now) then return abort() end
    e:_SetActivity(ACT_RANGE_ATTACK1 or ACT_IDLE,true)
    if not self:EdictValid(e,a,now) then return abort() end
    return current(e,a)
end
function E:CaptureEdictAttack(p,now)
    local a=orders[p]
    if not a or a.edict~=1 or a.phase~="watch" or a.trigger or a.claimed or a.observing
        or now<a.armed or now>a.ready then return nil end
    a.observing=true
    local valid=self:EdictValid(a.life.source,a,now)
    a.observing=nil
    if valid and orders[p]==a and a.phase=="watch" and not a.trigger then
        return {attack=a,life=a.life,at=now}
    end
end
function E:ObserveEdictAttack(p,now,receipt)
    receipt=receipt or self:CaptureEdictAttack(p,now)
    local a=receipt and receipt.attack
    if not a or orders[p]~=a or a.edict~=1 or a.phase~="watch" or a.trigger or a.claimed or a.observing
        or receipt.life~=a.life or receipt.at<a.armed or receipt.at>a.ready
        or receipt.at>now or now-receipt.at>.25 then return end
    a.observing=true
    if self:EdictValid(a.life.source,a,now) and orders[p]==a and a.phase=="watch" and not a.trigger then
        a.trigger=receipt
    end
    a.observing=nil
end

function E:EdictShot(e,a,now)
    if not self:EdictValid(e,a,now) then return false end
    a.phase="shot";a.aim=copy(a.target:WorldSpaceCenter());a.ready=now+1.2;a.deadline=a.ready+.2
    a.last=now;a.nextGeometry=now+.2
    if not self:EdictSpace(e,a) or not self:PublishEdict(e,a) then return false end
    e:EmitSound("npc/turret_floor/active.wav",72,100,.75)
    return self:EdictValid(e,a,CurTime())
end
function E:StepEdict(e,a,now)
    if not current(e,a) then return end
    if a.servicing or a.claimed then
        if now>a.deadline then self:Finish(e,now) end
        return
    end
    if not self:ValidSourceLife(a.life) then self:Cancel(e);return end
    local function finish() if current(e,a) then self:Finish(e,now) end end
    if not self:EdictValid(e,a,now) or now-a.last>.25 then finish();return end
    a.last=now;a.servicing=true
    local function work()
        if now>=(a.nextGeometry or 0) or now>=a.ready then
            a.nextGeometry=now+.2
            if not self:EdictSpace(e,a) or not self:EdictValid(e,a,now) then finish();return end
        end
        if a.edict==1 then
            if a.phase=="prep" then
                if now<a.ready then return end
                if now>a.ready+.2 then finish();return end
                a.phase="watch";a.armed=a.ready;a.ready=a.watchEnd
                if not self:PublishEdict(e,a) then finish() end
                return
            elseif a.phase=="watch" then
                local trigger=a.trigger
                if trigger then
                    if trigger.life~=a.life or trigger.at<a.armed or trigger.at>a.ready
                        or trigger.at>now or now-trigger.at>.25 then finish();return end
                    if not self:EdictShot(e,a,now) then finish() end
                elseif now>=a.ready then finish() end
                return
            end
        end
        if now<a.ready then return end
        if now>a.ready+.2 then finish();return end
        a.claimed=true;a.recoveryUntil=now+3
        local function gate()
            return self:EdictValid(e,a,CurTime()) and self:EdictSpace(e,a)
                and (a.edict==1 and self:EdictLane(e,a) or a.edict==2 and self:EdictDanger(a))
                and self:EdictOwned(e,a,CurTime())
        end
        if gate() then
            a.event.impactOrigin=a.origin+Vector(0,0,48);a.event.commitmentGate=gate
            self:Damage(e,a.target,a.event,a.kind)
        end
        finish()
    end
    work()
    a.servicing=nil
end
