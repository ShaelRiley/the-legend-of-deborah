-- Wall-lane and latch specialist. No parenting, Source climbing, or ceiling routes.
LOD.Climber=LOD.Climber or {}
local C=LOD.Climber
local E=LOD.EnemyRoster
local N=LOD.MazeNavigator
local key=E.Key
-- Containers extend half their 128-unit width into a logical cell. The old
-- 30-unit inset placed the Climber *inside* that wall.
local function laneOffset()
    return LOD.Config.Maze.CellSize*.5 - ((LOD.Config.Geometry and LOD.Config.Geometry.ContainerWidth or 128)*.5 + 22)
end
local function clearLane(pos)
    local tr=util.TraceHull({start=pos,endpos=pos,mins=Vector(-14,-14,-8),maxs=Vector(14,14,42),mask=MASK_NPCSOLID,
        filter=function(v) return not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit and not tr.StartSolid
end
local axes={Vector(1,0,0),Vector(0,1,0),Vector(-1,0,0),Vector(0,-1,0)}
function C:Lanes(graph,c)
    local out={};if E:Safe(graph,c) then return out end
    local center=N:CellCenter(c)+Vector(0,0,100)
    local offset=laneOffset()
    for i,v in ipairs(axes) do
        local k=LOD.MazeGenerator.CellKey(c.x+v.x,c.y+v.y,c.z)
        -- Only true closed wall faces, never a gate or an open edge.
        if not c.neighbors[k] and clearLane(center+v*offset) then out[i]={cell=c,side=i,pos=center+v*offset,normal=v} end
    end
    return out
end
-- Ties are stable across hash iteration order, including recovery in a junction.
local function nearest(lanes,pos)
    local best,dist
    for _,lane in pairs(lanes) do
        local d=lane.pos:DistToSqr(pos)
        if not dist or d<dist or (d==dist and lane.side<best.side) then best,dist=lane,d end
    end
    return best
end
function C:NearestLane(graph,c,pos)
    return nearest(self:Lanes(graph,c),pos)
end
-- A four-way junction has no wall to perch on, but remains a legal graph route.
-- These transient center nodes are for travel only. Placement continues using
-- Lanes/NearestLane, and blocked real wall lanes never become phantom openings.
function C:RouteLanes(graph,c)
    local lanes=self:Lanes(graph,c)
    if next(lanes) or E:Safe(graph,c) then return lanes end
    for _,v in ipairs(axes) do
        local k=LOD.MazeGenerator.CellKey(c.x+v.x,c.y+v.y,c.z)
        if not c.neighbors[k] or not graph.Cells[k] then return lanes end
    end
    local pos=N:CellCenter(c)+Vector(0,0,100)
    if clearLane(pos) then lanes[0]={cell=c,side=0,pos=pos,normal=vector_origin,transit=true} end
    return lanes
end
function C:ClearRoute(e)
    e.LODWallRoute=nil;e.LODWallRouteIndex=1;e.LODWallBlockedSince=nil
    e.LODWallRoutePurpose=nil;e.LODWallNextRoute=0
end
function C:Route(e,graph,p,fleeing,returning)
    self:ClearRoute(e)
    e.LODWallRoutePurpose=returning and "return" or "pursuit"
    local here=N:WorldToCell(graph,e:GetPos());if not here then return end
    local cache={}
    local function lanes(c)
        local k=key(c)
        if not cache[k] then cache[k]=self:RouteLanes(graph,c) end
        return cache[k]
    end
    local first=nearest(lanes(here),e:GetPos());if not first then return end
    local home=graph.Cells[e.LODHomeCellKey] or here
    -- A latched Hero can carry the actor beyond its home leash. Recovery has
    -- no Hero goal: bound that retreat from its current cell, while pursuit
    -- retains the original home-domain restriction.
    local domain=LOD.EnemyUpdate:Reachable(graph,key(returning and here or home),LOD.Config.Encounter.LeashCells)
    local queue={first};local seen={[key(here)..":"..first.side]=true};local previous={}
    local best=not returning and first or nil
    local aim=not returning and p:EyePos() or nil
    local function id(n) return key(n.cell)..":"..n.side end
    local head=1
    while queue[head] and head<=256 do
        local lane=queue[head];head=head+1
        -- Breadth-first recovery selects the nearest reachable actual wall.
        -- A center connector may be crossed but never completes attachment.
        if returning then
            if not lane.transit then best=lane;break end
        else
            local distance,bestDistance=lane.pos:DistToSqr(aim),best.pos:DistToSqr(aim)
            if (fleeing and distance>bestDistance) or (not fleeing and distance<bestDistance) then best=lane end
        end
        local candidates={}
        for side,n in pairs(lanes(lane.cell)) do
            if (side-lane.side)%2==1 then candidates[#candidates+1]=n end
        end
        for k in pairs(lane.cell.neighbors) do
            local n=graph.Cells[k]
            if n and domain[k]~=nil and N:CanTraverse(graph,key(lane.cell),k) then
                local available=lanes(n)
                local nextLane=n.z==lane.cell.z and available[lane.side] or nil
                nextLane=nextLane or nearest(available,lane.pos)
                if nextLane then candidates[#candidates+1]=nextLane end
            end
        end
        table.sort(candidates,function(a,b) return id(a)<id(b) end)
        for _,n in ipairs(candidates) do
            if not seen[id(n)] then seen[id(n)]=true;previous[id(n)]=lane;queue[#queue+1]=n end
        end
    end
    if not best then return end
    local nodes={};local n=best
    while n and id(n)~=id(first) do table.insert(nodes,1,n);n=previous[id(n)] end
    -- Re-anchor displaced actors with swept movement before following a lane.
    local points={{pos=first.pos,lane=first}};local last=first
    for _,nextLane in ipairs(nodes) do
        if key(last.cell)==key(nextLane.cell) then
            local center=N:CellCenter(last.cell)+Vector(0,0,100)
            points[#points+1]={pos=center+(last.normal+nextLane.normal)*(laneOffset())}
        elseif last.cell.z~=nextLane.cell.z then
            -- Floor change follows the actual authored stair itinerary only.
            for _,wp in ipairs(N:PathToWaypoints(graph,{last.cell,nextLane.cell})) do
                points[#points+1]={pos=wp.pos+Vector(0,0,72),stair=true}
            end
        elseif last.transit or nextLane.transit or last.side~=nextLane.side then
            points[#points+1]={pos=N:CellCenter(last.cell)+Vector(0,0,100)}
            points[#points+1]={pos=N:CellCenter(nextLane.cell)+Vector(0,0,100)}
        end
        points[#points+1]={pos=nextLane.pos,lane=nextLane,stair=last.cell.z~=nextLane.cell.z};last=nextLane
    end
    e.LODWallRoute=points;e.LODWallRouteIndex=1
end
function C:Step(e,goal,speed,dt,allowStair)
    local from=e:GetPos();local delta=goal-from;local distance=delta:Length()
    if distance<2 then return true end
    local nextPos=from+delta:GetNormalized()*math.min(distance,speed*dt)
    if not allowStair and not E:LegalStep(e,from,nextPos) then return false end
    local tr=util.TraceHull({start=from,endpos=nextPos,mins=Vector(-12,-12,-12),maxs=Vector(12,12,30),mask=MASK_NPCSOLID,
        filter=function(v) return v~=e and not v.LODHostile and not v:IsPlayer() end})
    if tr.Hit or tr.StartSolid then return false end
    if LOD.EntrySafety and not LOD.EntrySafety:MovementAllowed(e,from,nextPos) then return false end
    e:SetPos(nextPos);e.LODMotionSpeed=speed;e.LODMotionVelocity=delta:GetNormalized()*speed
    LOD.HostileMotionV2:FaceToward(e,goal);e:_SetActivity(ACT_CLIMB_UP or ACT_RUN)
    return distance<=speed*dt+2
end
-- Both pursuit and recovery use the same swept, sanctuary-aware execution.
function C:AdvanceRoute(e,now,dt)
    local wp=e.LODWallRoute and e.LODWallRoute[e.LODWallRouteIndex or 1]
    if not wp then return false end
    local before=e:GetPos()
    if self:Step(e,wp.pos,e.LODConfig.speed,dt,wp.stair) then
        e.LODWallRouteIndex=e.LODWallRouteIndex+1
        e.LODWallLane=wp.lane and not wp.lane.transit and wp.lane or nil
        e.LODWallBlockedSince=nil
        if e.LODWallRouteIndex>#e.LODWallRoute then return true end
    elseif e:GetPos():DistToSqr(before)>.01 then e.LODWallBlockedSince=nil
    else
        e.LODWallBlockedSince=e.LODWallBlockedSince or now
        if now-e.LODWallBlockedSince>.8 then
            local purpose=e.LODWallRoutePurpose
            self:ClearRoute(e);e.LODWallRoutePurpose=purpose;e.LODWallNextRoute=now+.8
        end
    end
    if e:GetPos():DistToSqr(before)>.01 and now>=(e.LODNextScrape or 0) then
        e.LODNextScrape=now+.65;e:EmitSound("npc/fast_zombie/foot1.wav",62,130,.6)
    end
    return false
end
function C:Detach(e)
    self:ClearRoute(e)
    e.LODClimberVictim=nil;e:SetNW2Entity("LOD_ClimberVictim",NULL);e.LODClimberLeap=nil
    e.LODClimberAttached=false;e.LODNextAttack=CurTime()+1;e.LODWallReturn=true
end
function C:Interrupt(e)
    if e.LODClimberVictim then e.LODNextBite=CurTime()+.4
    elseif e.LODClimberLeap then e.LODClimberLeap=nil;e.LODWallReturn=true;self:ClearRoute(e) end
end
function C:Tick(e,s,now)
    local motion=LOD.HostileMotionV2
    motion:Stop(e) -- quiesce native NextBot velocity/gravity before manual wall travel
    local dt=math.Clamp(now-(e.LODWallLast or now),0,.05);e.LODWallLast=now
    local c=N:WorldToCell(s.Graph,e:GetPos())
    if not c then motion:Stop(e);return true end
    if not e.LODWallInitialized then
        local lane=self:NearestLane(s.Graph,c,e:GetPos())
        if not lane then motion:Stop(e);return true end
        if LOD.EntrySafety and not LOD.EntrySafety:MovementAllowed(e,e:GetPos(),lane.pos) then return true end
        e.LODWallInitialized=true;e:SetPos(lane.pos);e.LODWallLane=lane
    end
    local victim=e.LODClimberVictim
    if victim then
        local there=E:AcquireTarget(victim) and N:WorldToCell(s.Graph,victim:GetPos()) or nil
        if not there or there.z~=e.LODClimberFloor or E:Safe(s.Graph,there) then self:Detach(e);return true end
        local goal=victim:EyePos()+victim:EyeAngles():Forward()*22-Vector(0,0,14)
        local trace=util.TraceLine({start=victim:EyePos(),endpos=goal,mask=MASK_SOLID,filter={victim,e}})
        if trace.Hit then self:Detach(e);return true end
        if LOD.EntrySafety and not LOD.EntrySafety:MovementAllowed(e,e:GetPos(),goal) then self:Detach(e);return true end
        e:SetPos(goal);e:SetAngles(Angle(0,victim:EyeAngles().y+180,0));motion:Stop(e)
        if motion:HoldHitStun(e,now) then e.LODNextBite=now+.4;return true end
        if LOD.RPGStatusElements:CanInitiateAttack(e) and now>=(e.LODNextBite or 0) then
            E:Damage(e,victim,{},"climber");e.LODNextBite=now+.75
            e:EmitSound("npc/fast_zombie/claw_strike1.wav",70,115,.7)
        end
        return true
    end
    if motion:HoldHitStun(e,now) or not LOD.RPGStatusElements:CanMoveVoluntarily(e) then motion:Stop(e);return true end
    local leap=e.LODClimberLeap
    if leap then
        local goal=leap.goal
        if not E:AcquireTarget(leap.target) or now>leap.expires then e.LODClimberLeap=nil;e.LODWallReturn=true
        else
            self:Step(e,goal,620,dt,false)
            if e:GetPos():DistToSqr(leap.target:EyePos())<42^2 and E:Visible(e,leap.target,e:GetPos()) then
                e.LODClimberVictim=leap.target;e.LODClimberFloor=c.z;e.LODClimberLeap=nil
                e.LODNextBite=now+.4;e.LODClimberAttached=true;e:SetNW2Entity("LOD_ClimberVictim",leap.target)
                e:EmitSound("npc/fast_zombie/fz_scream1.wav",72,125,.7)
            elseif e:GetPos():DistToSqr(goal)<8^2 then e.LODClimberLeap=nil;e.LODWallReturn=true end
        end
        return true
    end
    if e.LODWallReturn then
        local wp=e.LODWallRoute and e.LODWallRoute[e.LODWallRouteIndex or 1]
        if e.LODWallRoutePurpose~="return" then self:ClearRoute(e);wp=nil end
        if not wp and now>=(e.LODWallNextRoute or 0) then
            self:Route(e,s.Graph,nil,false,true);e.LODWallNextRoute=now+.8
        end
        if self:AdvanceRoute(e,now,dt) and e.LODWallLane then
            e.LODWallReturn=nil;self:ClearRoute(e)
        end
        return true
    end
    e:_RefreshTarget(s.Graph)
    local fleeing,entry=LOD.RPGStatusElements:Has(e,"morale_flee")
    local p=fleeing and entry and entry.source or e.LODTarget
    if not E:AcquireTarget(p) then motion:Stop(e);e:_SetActivity(ACT_IDLE);return true end
    if LOD.RPGStatusElements:CanInitiateAttack(e) and now>=(e.LODNextAttack or 0)
        and e:GetPos():DistToSqr(p:EyePos())<=e.LODConfig.fireRange^2 and E:Visible(e,p,e:GetPos()) then
        local tr=util.TraceHull({start=e:GetPos(),endpos=p:EyePos(),mins=Vector(-12,-12,-12),maxs=Vector(12,12,12),mask=MASK_SHOT,
            filter=function(v) return v~=e and not v.LODHostile end})
        local targetCell=N:WorldToCell(s.Graph,p:GetPos())
        if targetCell and targetCell.z==c.z and not E:Safe(s.Graph,targetCell) and (not tr.Hit or tr.Entity==p) then
            self:ClearRoute(e)
            e.LODClimberLeap={target=p,goal=p:EyePos(),expires=now+.8};e.LODNextAttack=now+1.2
            e:EmitSound("npc/fast_zombie/leap1.wav",74,115,.8);return true
        end
    end
    local wp=e.LODWallRoute and e.LODWallRoute[e.LODWallRouteIndex or 1]
    if not wp and now>=(e.LODWallNextRoute or 0) then
        self:Route(e,s.Graph,p,fleeing);e.LODWallNextRoute=now+.8
        wp=e.LODWallRoute and e.LODWallRoute[e.LODWallRouteIndex or 1]
    end
    if wp then self:AdvanceRoute(e,now,dt)
    else motion:Stop(e);e:_SetActivity(ACT_IDLE) end
    return true
end

-- Release-safe, read-only evidence: placement counters are not live sightings.
-- No spawn, population, clock, ranking, or cadence change accompanies this query.
concommand.Add("lod_climber_status",function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local director=LOD.EncounterDirector
    local plan=director and director.Plan
    local composition,dormant,living=0,0,0
    for _,encounter in ipairs(plan and plan.encounters or {}) do
        local count=(encounter.composition or {}).climber or 0
        composition=composition+count
        if not encounter.spawned and not encounter.cleared then dormant=dormant+count end
    end
    for _,e in ipairs(director and director.Entities or {}) do
        if IsValid(e) and not e.LODDead and e.LODArchetypeId=="climber" then
            living=living+1
            print(string.format("[LOD:CLIMBER] #%d pos=%s route=%d/%d returning=%s leap=%s latch=%s",
                e:EntIndex(),tostring(e:GetPos()),e.LODWallRouteIndex or 0,#(e.LODWallRoute or {}),
                tostring(e.LODWallReturn==true),tostring(e.LODClimberLeap~=nil),tostring(IsValid(e.LODClimberVictim))))
        end
    end
    local stats=E.PlacementStats and E.PlacementStats.climber or {}
    print(string.format("[LOD:CLIMBER] revision=spot02 motif=%s currentComposition=%d dormant=%d living=%d placementAccepted=%d placementRejected=%d",
        tostring(plan and plan.ecology and plan.ecology.theme or "none"),composition,dormant,living,
        stats.accepted or 0,stats.rejected or 0))
end)
