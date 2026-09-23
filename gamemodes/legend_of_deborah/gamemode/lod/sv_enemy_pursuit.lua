-- B3 commitments choose bounded graph routes; Navigator and Motion V2 still
-- own waypoint geometry and locomotion. Hidden Heroes never update a route.
LOD.EnemyPursuit=LOD.EnemyPursuit or {}
local P=LOD.EnemyPursuit
local E,N,M=LOD.EnemyRoster,LOD.MazeNavigator,LOD.HostileMotionV2
local Status,Rules=LOD.RPGStatusElements,LOD.RPGAbilityRules
P.MaxNodes=32;P.MaxDepth=4;P.MaxCandidates=8
P.Profiles={pincer={mode=1,warning=.6},harrier={mode=2,warning=0},waylayer={mode=3,warning=1,hold=1.5}}
P.Active=P.Active or setmetatable({}, {__mode="k"})
local function state() return LOD.RunManager and LOD.RunManager.State end
local function live(s) return s and s.BuildReady and not s.Failed and not s.LevelCleared and not s.SimulationFrozen end
local function identity(e) return Rules:ProgressionState(e) end
local function keys(g,c)
    if N.SortedNeighborKeys then return N:SortedNeighborKeys(g,c) end
    local out={};for k in pairs(c.neighbors or {}) do out[#out+1]=k end;table.sort(out);return out
end
function P:CellLegal(g,c,z)
    if not c or c.z~=z or E:Safe(g,c) then return false end
    local tag=(g.CellTags or {})[E.Key(c)] or {}
    if tag.objective or (E.IsTransition and E:IsTransition(g,c)) then return false end
    return true
end
function P:CanAct(e)
    return IsValid(e) and not e.LODDead and e:Health()>0 and e.LODActivated
        and CurTime()>=(e.LODHitStunUntil or 0) and Status:CanInitiateAttack(e)
        and Status:CanMoveVoluntarily(e) and not Status:Has(e,"morale_flee")
end
function P:Capture(e,hero)
    Status:BindActorLife(e);Status:BindActorLife(hero)
    return E:Bind({source=e,hero=hero,sourceState=identity(e),heroState=identity(hero),
        sourceLife=Status.ActorLives[e],heroLife=Status.ActorLives[hero]},state())
end
function P:ValidLife(r)
    return r and live(state()) and E:Live(r,state()) and IsValid(r.source) and not r.source.LODDead
        and r.source:Health()>0 and r.source.LODActivated
        and E:Target(r.hero) and identity(r.source)==r.sourceState and identity(r.hero)==r.heroState
        and Status.ActorLives[r.source]==r.sourceLife and Status.ActorLives[r.hero]==r.heroLife
end
function P:ValidRecord(r) return self:ValidLife(r) and E:AcquireTarget(r.hero) and self:CanAct(r.source) end
function P:ValidCharge(r)
    return self:ValidLife(r) and E:AcquireTarget(r.hero) and E:CanCast(r.source) and CurTime()>=(r.source.LODHitStunUntil or 0)
end
-- The optional forbidden edge creates a genuinely different first approach.
-- Sorted neighbors and bounded BFS have no dependency on any random stream.
function P:Search(g,start,forbidden)
    local sk=E.Key(start);local queue={sk};local depth={[sk]=0};local previous={};local head=1
    while queue[head] and head<=self.MaxNodes do
        local k=queue[head];head=head+1;local c=g.Cells[k]
        if depth[k]<self.MaxDepth then
            for _,nk in ipairs(keys(g,c)) do
                local nextCell=g.Cells[nk]
                if not depth[nk] and #queue<self.MaxNodes and self:CellLegal(g,nextCell,start.z)
                    and not (forbidden and N:EdgeKey(k,nk)==forbidden) and N:CanTraverse(g,k,nk) then
                    depth[nk]=depth[k]+1;previous[nk]=k;queue[#queue+1]=nk
                end
            end
        end
    end
    self.LastSearchNodes=#queue
    return queue,depth,previous
end
function P:Path(g,start,goal,previous)
    local sk=E.Key(start);local reverse={goal};local cursor=goal
    while cursor~=sk do
        cursor=previous[cursor];if not cursor or #reverse>self.MaxDepth then return nil end
        reverse[#reverse+1]=cursor
    end
    local out={};for i=#reverse,1,-1 do out[#out+1]=g.Cells[reverse[i]] end
    return out
end
function P:Exits(g,c)
    local out={}
    for _,k in ipairs(keys(g,c)) do
        if self:CellLegal(g,g.Cells[k],c.z) and N:CanTraverse(g,E.Key(c),k) then out[#out+1]=k end
    end
    return out
end
function P:Cycle(g,c)
    for _,nk in ipairs(self:Exits(g,c)) do
        local _,depth,previous=self:Search(g,c,N:EdgeKey(E.Key(c),nk))
        if depth[nk] and depth[nk]+1<=self.MaxDepth then
            local path=self:Path(g,c,nk,previous);path[#path+1]=c;return path
        end
    end
end
function P:Placement(g,c,id)
    if not self:CellLegal(g,c,c.z) then return false end
    if id=="pincer" then
        if self:Cycle(g,c) then return true end
        local center=M:CellFloorPoint(c)
        for _,sign in ipairs({1,-1}) do
            local side=M:CellFloorPoint(c,center+Vector(0,96*sign,0))
            local close=M:CellFloorPoint(c,side+Vector(96,0,0))
            if math.abs(side.y-center.y)>=64 and close.x-side.x>=32
                and self:Hull(nil,center,side) and self:Hull(nil,side,close) then return true end
        end
        return false
    end
    if id=="harrier" then return #self:Exits(g,c)>0 end
    local queue=self:Search(g,c)
    for i=2,#queue do if #self:Exits(g,g.Cells[queue[i]])>=3 then return true end end
    return false
end
function P:Hull(e,from,to)
    local lo,hi
    if e and e.GetCollisionBounds then lo,hi=e:GetCollisionBounds() end
    if not lo or not hi then
        local scale=math.Clamp(e and e:GetNW2Float("LOD_SizeScale",1) or 1,.33,1.33)
        lo=Vector(-16,-16,2)*scale;hi=Vector(16,16,72)*scale
    end
    local tr=util.TraceHull({start=from,endpos=to,mins=lo,maxs=hi,mask=MASK_NPCSOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit and not tr.StartSolid
end
function P:RouteLegal(g,path)
    if not path or #path<1 or #path>self.MaxDepth+1 then return false end
    for i,c in ipairs(path) do
        if g.Cells[E.Key(c)]~=c or not self:CellLegal(g,c,path[1].z) then return false end
        if i>1 then
            local before=path[i-1];local k=E.Key(c)
            if not before.neighbors[k] or not N:CanTraverse(g,E.Key(before),k) then return false end
        end
    end
    return true
end
function P:Waypoints(e,g,path)
    if not self:RouteLegal(g,path) then return nil end
    local waypoints=N:PathToWaypoints(g,path)
    -- Recenter before the first graph edge: source->next center could otherwise
    -- cut the corner of a container when a source starts off-center.
    table.insert(waypoints,1,{pos=M:CellFloorPoint(path[1]),tolerance=12,stair=false})
    local previous=e:GetPos()
    for _,wp in ipairs(waypoints) do
        if not self:Hull(e,previous,wp.pos) then return nil end
        previous=wp.pos
    end
    return waypoints
end
function P:Covered(e,point,snapshot)
    local tr=util.TraceLine({start=point+Vector(0,0,48),endpos=snapshot+Vector(0,0,48),mask=MASK_SOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    return tr.Hit and not tr.StartSolid
end
function P:LocalFlank(e,hero,g,cell,snapshot)
    local origin=e:GetPos();local direction=Vector(snapshot.x-origin.x,snapshot.y-origin.y,0)
    if direction:LengthSqr()<32^2 then return nil end
    direction=direction:GetNormalized();local side=Vector(-direction.y,direction.x,0)
    for _,sign in ipairs({1,-1}) do
        local first=M:CellFloorPoint(cell,origin+side*(96*sign))
        local last=M:CellFloorPoint(cell,snapshot+direction*48+side*(96*sign))
        if math.abs((first-origin):Dot(side))>=64 and (last-first):Dot(direction)>=32
            and self:Hull(e,origin,first) and self:Hull(e,first,last) then
            return {path={cell},waypoints={{pos=first,tolerance=12,stair=false},{pos=last,tolerance=12,stair=false}},
                index=1,snapshot=snapshot,destination=last,mode="pincer",record=self:Capture(e,hero),localRoute=true}
        end
    end
end
function P:Plan(e,hero,mode,record)
    local s=state();local g=s and s.Graph
    if not self.Profiles[mode] or not live(s) or not self:CanAct(e) or not E:AcquireTarget(hero) then return nil end
    -- AfterAttack supplies the observed shot snapshot; do not read hidden live
    -- positions or demand sight through the cover the retreat is seeking.
    if record then if not self:ValidRecord(record) or record.source~=e or record.hero~=hero or not record.snapshot then return nil end
    elseif not E:Visible(e,hero) then return nil end
    local snapshot=record and record.snapshot or Vector(hero:GetPos().x,hero:GetPos().y,hero:GetPos().z)
    local from=N:WorldToCell(g,e:GetPos());local target=N:WorldToCell(g,snapshot)
    if not from or not target or not self:CellLegal(g,from,from.z) or not self:CellLegal(g,target,from.z) then return nil end
    local queue,depth,previous=self:Search(g,from);local candidates={}
    if mode=="pincer" then
        if E.Key(from)==E.Key(target) then
            local path=self:Cycle(g,from);if path then candidates[1]={path=path,score=0} end
        elseif depth[E.Key(target)] then
            local direct=self:Path(g,from,E.Key(target),previous)
            local _,alternate,parents=self:Search(g,from,N:EdgeKey(E.Key(from),E.Key(direct[2])))
            if alternate[E.Key(target)] then candidates[1]={path=self:Path(g,from,E.Key(target),parents),score=0} end
        end
    else
        local startDistance=e:GetPos():DistToSqr(snapshot)
        for i=2,#queue do
            local c=g.Cells[queue[i]];local pos=M:CellFloorPoint(c);local distance=pos:DistToSqr(snapshot)
            if (mode=="harrier" and distance>startDistance+64^2)
                or (mode=="waylayer" and #self:Exits(g,c)>=3 and target.neighbors[E.Key(c)]
                    and N:CanTraverse(g,E.Key(target),E.Key(c))) then
                -- Interceptors choose a reachable junction near the observed
                -- Hero, not a prediction derived from unseen velocity/input.
                candidates[#candidates+1]={path=self:Path(g,from,queue[i],previous),
                    score=mode=="harrier" and -distance or distance,key=queue[i],pos=pos}
            end
        end
        table.sort(candidates,function(a,b) if a.score~=b.score then return a.score<b.score end return a.key<b.key end)
    end
    local fallback
    for i=1,math.min(#candidates,self.MaxCandidates) do
        local candidate=candidates[i];local waypoints=self:Waypoints(e,g,candidate.path)
        if waypoints then
            local plan={path=candidate.path,waypoints=waypoints,index=1,snapshot=snapshot,
                destination=waypoints[#waypoints].pos,mode=mode,record=record or self:Capture(e,hero)}
            if mode~="harrier" or self:Covered(e,plan.destination,snapshot) then return plan end
            fallback=fallback or plan
        end
    end
    if not fallback and mode=="pincer" and depth[E.Key(target)] and depth[E.Key(target)]<=2 then
        return self:LocalFlank(e,hero,g,from,snapshot)
    end
    return fallback
end
function P:Cancel(e)
    if IsValid(e) and not self.Active[e] and not e.LODPursuit and not self.Profiles[e.LODArchetypeId] then return end
    self.Active[e]=nil
    if IsValid(e) then
        if e.LODPursuit then e.LODNextPursuit=CurTime()+8 end
        e.LODPursuit=nil;e:SetNW2Int("LOD_PursuitMode",0)
        e.LODWaypoints={};e.LODWaypointIndex=1;e.LODNextRouteRefresh=0
    end
end
function P:Start(e,hero,mode,now,record)
    if e.LODPursuit or now<(e.LODNextPursuit or 0) then return false end
    e.LODNextPursuit=now+2
    local a=self:Plan(e,hero,mode,record);if not a then return false end
    local profile=self.Profiles[mode]
    local distance=0;local previous=e:GetPos()
    for _,wp in ipairs(a.waypoints) do distance=distance+previous:Distance(wp.pos);previous=wp.pos end
    local speed=(e.LODConfig.speed or 90)*Status:LocomotionMultiplier(e)
        *(Rules.RogueMovementMultiplier and Rules:RogueMovementMultiplier(e) or 1)
        *(Rules.HostileDexMovementMultiplier and Rules:HostileDexMovementMultiplier(e) or 1)
    a.ready=now+profile.warning
    a.expires=a.ready+math.Clamp(distance/math.max(1,speed)+1+(profile.hold or 0),6,16)
    e.LODPursuit=a;self.Active[e]=true;e.LODNextPursuit=now+8
    e:SetNW2Int("LOD_PursuitMode",profile.mode);e:SetNW2Vector("LOD_PursuitDestination",a.destination)
    e:SetNW2Float("LOD_PursuitReady",a.ready);e:SetNW2Float("LOD_PursuitExpires",a.expires)
    if profile.warning>0 then e:EmitSound("npc/metropolice/vo/moveit.wav",70,mode=="pincer" and 115 or 85,.65) end
    return true
end
function P:AfterAttack(e,a,now)
    if e.LODArchetypeId=="harrier" and a.shotEmitted and not a.pursuitAttempted
        and self:ValidRecord(a.pursuitRecord) and a.pursuitRecord.source==e and a.pursuitRecord.hero==a.target then
        a.pursuitAttempted=true
        return self:Start(e,a.target,"harrier",now,a.pursuitRecord)
    end
    return false
end
function P:Tick(e,hero,now)
    local a=e.LODPursuit
    if not a then
        if e.LODArchetypeId=="harrier" then return false end
        if not self:Start(e,hero,e.LODArchetypeId,now) then return false end
        a=e.LODPursuit
    end
    if not self:ValidRecord(a.record) or now>=a.expires or not self:RouteLegal(state().Graph,a.path) then
        self:Cancel(e);M:Stop(e);return true
    end
    if now<a.ready then M:Stop(e);return true end
    local wp=a.waypoints[a.index]
    if wp and e:GetPos():DistToSqr(wp.pos)<=(wp.tolerance or 18)^2 then a.index=a.index+1;wp=a.waypoints[a.index] end
    if not wp then
        if N:WorldToCell(state().Graph,e:GetPos())~=a.path[#a.path] then self:Cancel(e);M:Stop(e);return true end
        local hold=self.Profiles[a.mode].hold or 0
        a.holdUntil=a.holdUntil or math.min(a.expires,now+hold)
        if now>=a.holdUntil then self:Cancel(e) end
        M:Stop(e);return true
    end
    -- Validate the complete remaining graph commitment plus this exact physical
    -- segment on every move. Dynamic gates, blockades and native solids win.
    local current=N:WorldToCell(state().Graph,e:GetPos())
    local before=a.localRoute and a.path[1] or a.path[math.max(1,a.index-1)]
    local destination=a.localRoute and a.path[1] or a.path[a.index]
    if (current~=before and current~=destination) or not E:LegalStep(e,e:GetPos(),wp.pos)
        or not self:Hull(e,e:GetPos(),wp.pos) then self:Cancel(e);M:Stop(e);return true end
    M:MoveToward(e,wp);return true
end
function P:Service(now,active)
    for e in pairs(self.Active) do
        local a=IsValid(e) and e.LODPursuit
        if not active or not a or not self:ValidRecord(a.record) or now>=a.expires
            or not self:RouteLegal(state().Graph,a.path) then self:Cancel(e);if IsValid(e) then M:Stop(e) end end
    end
end
