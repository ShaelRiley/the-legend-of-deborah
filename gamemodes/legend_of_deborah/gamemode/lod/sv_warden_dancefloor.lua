-- Author-directed phase-one generosity. Extend the existing Warden owner;
-- its lifecycle service, damage authority and Motion V2 remain authoritative.
local W=LOD.Warden
local C=W.Config
local N,R=LOD.MazeNavigator,LOD.RunManager
-- The old two-second visible salvo budget included the three 0.22s gaps.
-- Quadruple the actual quiet opening AFTER the final shot, not the warning.
C.postShotExposure=(2-3*C.shotGap)*4 -- 1.34s -> 5.36s
C.visible=3*C.shotGap+C.postShotExposure
C.exposureCap=13
C.tauntDuration=6.4 -- eight times the old 0.8-second tease
C.tauntCooldown=3
C.danceRepath=0.5

-- Re-including this tuning module must not stack wrappers or multiply timers.
W.DancefloorBase=W.DancefloorBase or {
    service=W.ServicePhaseOne,tick=W.Tick,retire=W.RetirePhaseOne,
    hidden=W.BeginHidden
}
local base=W.DancefloorBase
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function clearDance(e)
    if not IsValid(e) then return end
    e:SetNW2Float("LOD_WardenDanceStart",0)
    e:SetNW2Int("LOD_WardenDanceMove",0)
end
function W:RetirePhaseOne(w,e)
    if w and w.phaseOne and w.phaseOne.dancing and IsValid(e) then
        e.LODWaypoints={};e.LODWaypointIndex=1
    end
    clearDance(e)
    return base.retire(self,w,e)
end
function W:BeginHidden(w,e,now,initial)
    clearDance(e)
    -- Do not carry a dance route into concealed pursuit or the next phase.
    if w and w.phaseOne and w.phaseOne.dancing and IsValid(e) then
        e.LODWaypoints={};e.LODWaypointIndex=1
    end
    return base.hidden(self,w,e,now,initial)
end
function W:StartDance(w,e,work,now,deadline)
    if work.dancing then return end
    work.dancing=true;work.stage="taunt";work.deadline=math.min(deadline,work.cap)
    work.danceStarted=now;work.danceRouteAt=now
    w.danceOrdinal=(w.danceOrdinal or 0)+1
    local move=((w.danceOrdinal-1+(w.cloneIndex or 0))%4)+1
    e.LODWaypoints={};e.LODWaypointIndex=1
    w.volley=nil;w.tauntUntil=work.deadline
    e:SetNW2Float("LOD_WardenTauntUntil",work.deadline)
    e:SetNW2Float("LOD_WardenDanceStart",now)
    e:SetNW2Int("LOD_WardenDanceMove",move)
    -- One caption/audio onset, never renewed by a hit or snapshot.
    w.phaseCues={}
    -- Captions now follow the rendered actor for this fixed dance lifetime.
    if not work.arrivalTaunt and LOD.Audio then LOD.Audio:Emit(e,"boss_taunt") end
end
function W:ServicePhaseOne(w,e,now,targets)
    local work=base.service(self,w,e,now,targets)
    if work and work.stage=="taunt" and not work.dancing then
        work.arrivalTaunt=true -- the base owner already emitted its onset cue
        self:StartDance(w,e,work,now,work.deadline)
    end
    return work
end
function W:OnEffectiveHit(e,now)
    local _,root=self:State()
    local w=root and (root.cloneStates and root.cloneStates[e] or root)
    if not w or e~=w.actor or w.phase~=1 then return end
    local work=self:ServicePhaseOne(w,e,now)
    if not work then return end
    root.lastIncoming=now
    if work.stage~="attack" and work.stage~="taunt" then return end
    if not work.followup then
        -- Fixed, nonrenewing stun allowance; landing a hit must NEVER shorten
        -- the promised exposure or cancel a taunt. Repeated hits cannot pin him.
        work.followup=math.min(now+C.followup,work.cap)
        work.deadline=math.min(work.cap,math.max(work.deadline,work.followup))
        if LOD.RPGTestLog then LOD.RPGTestLog:Write("WARDEN_FOLLOWUP",{
            cycle=work.cycle,untilTime=work.followup,cap=work.cap,clone=w.cloneIndex or 0}) end
    end
    w.volley=nil
    if not work.dancing then self:StartDance(w,e,work,now,work.deadline) end
    w.tauntUntil=work.deadline;e:SetNW2Float("LOD_WardenTauntUntil",work.deadline)
    e.LODHitStunUntil=math.min(e.LODHitStunUntil or now,work.followup)
end
function W:DanceAcrossCourt(w,e,work,a,now)
    local motion=LOD.HostileMotionV2
    local g=R.State.Graph
    local from=N:WorldToCell(g,e:GetPos())
    if not from or not a.court[key(from)] then motion:Stop(e);return end
    local waypoint=e:_AdvanceWaypoint()
    if not waypoint and now>=(work.danceRouteAt or 0) then
        work.danceRouteAt=now+C.danceRepath
        -- A full floor-crossing, not random jukes around the player. Sorted
        -- court cells give stable ties without consuming any combat RNG.
        local keys={};for k in pairs(a.court) do keys[#keys+1]=k end;table.sort(keys)
        local dest,best=nil,-1
        for _,k in ipairs(keys) do
            local cell=g.Cells[k]
            if cell and cell.z==from.z then
                local distance=N:CellCenter(cell):DistToSqr(e:GetPos())
                if distance>best then dest=cell;best=distance end
            end
        end
        local path=dest and N:FindPath(g,from,dest,function(cell)
            return cell and cell.z==from.z and not not a.court[key(cell)]
        end)
        local safe=path and #path>0
        for _,cell in ipairs(path or {}) do
            if not a.court[key(cell)] or cell.z~=from.z then safe=false;break end
        end
        e.LODWaypoints=safe and (N:PathToWaypoints(g,path) or {}) or {}
        e.LODWaypointIndex=1
        waypoint=e:_AdvanceWaypoint()
    end
    if waypoint and not waypoint.stair then
        e:_SetActivity(ACT_WALK)
        motion:MoveToward(e,waypoint)
    else motion:Stop(e) end
end
function W:Tick(e)
    local result=base.tick(self,e)
    if e.LODArchetypeId~="warden" then return result end
    local s,root,a=self:State()
    local w=root and (root.cloneStates and root.cloneStates[e] or root)
    local work=w and w.phaseOne
    if not work or not self:PhaseOwner(w,e,work) or s.SimulationFrozen then return result end
    local now=CurTime()
    local v=w.volley
    if work.stage=="attack" and v and v.cycle==work.cycle and v.count>=4 then
        -- Anchor to the actual last release, including ordinary AI tick delay.
        self:StartDance(w,e,work,now,now+C.postShotExposure)
    end
    if not work.dancing or work.stage~="taunt" or now>=math.min(work.deadline,work.cap) then return result end
    local status=LOD.RPGStatusElements
    if #self:PhaseTargets()==0 or status and not status:CanMoveVoluntarily(e)
        or LOD.HostileMotionV2:HoldHitStun(e,now) then return result end
    self:DanceAcrossCourt(w,e,work,a,now)
    return result
end
