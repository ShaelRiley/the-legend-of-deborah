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
function C:NearestLane(graph,c,pos)
    local best,dist
    for _,lane in pairs(self:Lanes(graph,c)) do
        local d=lane.pos:DistToSqr(pos)
        if not dist or d<dist then best,dist=lane,d end
    end
    return best
end
function C:Route(e,graph,p,fleeing)
    local here=N:WorldToCell(graph,e:GetPos());if not here then return end
    local first=self:NearestLane(graph,here,e:GetPos());if not first then return end
    local home=graph.Cells[e.LODHomeCellKey] or here
    local domain=LOD.EnemyUpdate:Reachable(graph,key(home),LOD.Config.Encounter.LeashCells)
    local queue={first};local seen={[key(here)..":"..first.side]=true};local previous={};local best=first
    local function id(n) return key(n.cell)..":"..n.side end
    local head=1
    while queue[head] and head<=256 do
        local lane=queue[head];head=head+1
        local distance,bestDistance=lane.pos:DistToSqr(p:EyePos()),best.pos:DistToSqr(p:EyePos())
        if (fleeing and distance>bestDistance) or (not fleeing and distance<bestDistance) then best=lane end
        local candidates={}
        for side,n in pairs(self:Lanes(graph,lane.cell)) do
            if (side-lane.side)%2==1 then candidates[#candidates+1]=n end
        end
        for k in pairs(lane.cell.neighbors) do
            local n=graph.Cells[k]
            if domain[k] and N:CanTraverse(graph,key(lane.cell),k) then
                if n.z==lane.cell.z then
                    local nextLane=self:Lanes(graph,n)[lane.side]
                    if nextLane then candidates[#candidates+1]=nextLane
                    else
                        nextLane=self:NearestLane(graph,n,lane.pos)
                        if nextLane then nextLane.connector=true;candidates[#candidates+1]=nextLane end
                    end
                else
                    local nextLane=self:NearestLane(graph,n,lane.pos)
                    if nextLane then nextLane.stairFrom=lane.cell;candidates[#candidates+1]=nextLane end
                end
            end
        end
        table.sort(candidates,function(a,b) return id(a)<id(b) end)
        for _,n in ipairs(candidates) do
            if not seen[id(n)] then seen[id(n)]=true;previous[id(n)]=lane;queue[#queue+1]=n end
        end
    end
    local nodes={};local n=best
    while n and id(n)~=id(first) do table.insert(nodes,1,n);n=previous[id(n)] end
    local points={};local last=first
    for _,nextLane in ipairs(nodes) do
        if key(last.cell)==key(nextLane.cell) then
            local center=N:CellCenter(last.cell)+Vector(0,0,100)
            points[#points+1]={pos=center+(last.normal+nextLane.normal)*(laneOffset())}
        elseif nextLane.connector and last.cell.z==nextLane.cell.z then
            points[#points+1]={pos=N:CellCenter(last.cell)+Vector(0,0,100)}
            points[#points+1]={pos=N:CellCenter(nextLane.cell)+Vector(0,0,100)}
        elseif last.cell.z~=nextLane.cell.z then
            -- Floor change follows the actual authored stair itinerary only.
            for _,wp in ipairs(N:PathToWaypoints(graph,{last.cell,nextLane.cell})) do
                points[#points+1]={pos=wp.pos+Vector(0,0,72),stair=true}
            end
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
    e:SetPos(nextPos);e.LODMotionSpeed=speed;e.LODMotionVelocity=delta:GetNormalized()*speed
    LOD.HostileMotionV2:FaceToward(e,goal);e:_SetActivity(ACT_CLIMB_UP or ACT_RUN)
    return distance<=speed*dt+2
end
function C:Detach(e)
    e.LODClimberVictim=nil;e:SetNW2Entity("LOD_ClimberVictim",NULL);e.LODClimberLeap=nil
    e.LODClimberAttached=false;e.LODNextAttack=CurTime()+1;e.LODWallReturn=true
end
function C:Interrupt(e)
    if e.LODClimberVictim then e.LODNextBite=CurTime()+.4
    elseif e.LODClimberLeap then e.LODClimberLeap=nil;e.LODWallReturn=true end
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
        e.LODWallInitialized=true;e:SetPos(lane.pos);e.LODWallLane=lane
    end
    local victim=e.LODClimberVictim
    if victim then
        local there=E:Target(victim) and N:WorldToCell(s.Graph,victim:GetPos()) or nil
        if not there or there.z~=e.LODClimberFloor or E:Safe(s.Graph,there) then self:Detach(e);return true end
        local goal=victim:EyePos()+victim:EyeAngles():Forward()*22-Vector(0,0,14)
        local trace=util.TraceLine({start=victim:EyePos(),endpos=goal,mask=MASK_SOLID,filter={victim,e}})
        if trace.Hit then self:Detach(e);return true end
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
        if not E:Target(leap.target) or now>leap.expires then e.LODClimberLeap=nil;e.LODWallReturn=true
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
        local lane=self:NearestLane(s.Graph,c,e:GetPos())
        if lane and self:Step(e,lane.pos,e.LODConfig.speed,dt,false) then e.LODWallReturn=nil;e.LODWallLane=lane end
        return true
    end
    e:_RefreshTarget(s.Graph)
    local fleeing,entry=LOD.RPGStatusElements:Has(e,"morale_flee")
    local p=fleeing and entry and entry.source or e.LODTarget
    if not E:Target(p) then motion:Stop(e);e:_SetActivity(ACT_IDLE);return true end
    if LOD.RPGStatusElements:CanInitiateAttack(e) and now>=(e.LODNextAttack or 0)
        and e:GetPos():DistToSqr(p:EyePos())<=e.LODConfig.fireRange^2 and E:Visible(e,p,e:GetPos()) then
        local tr=util.TraceHull({start=e:GetPos(),endpos=p:EyePos(),mins=Vector(-12,-12,-12),maxs=Vector(12,12,12),mask=MASK_SHOT,
            filter=function(v) return v~=e and not v.LODHostile end})
        local targetCell=N:WorldToCell(s.Graph,p:GetPos())
        if targetCell and targetCell.z==c.z and not E:Safe(s.Graph,targetCell) and (not tr.Hit or tr.Entity==p) then
            e.LODClimberLeap={target=p,goal=p:EyePos(),expires=now+.8};e.LODNextAttack=now+1.2
            e:EmitSound("npc/fast_zombie/leap1.wav",74,115,.8);return true
        end
    end
    local wp=e.LODWallRoute and e.LODWallRoute[e.LODWallRouteIndex or 1]
    if not wp and now>=(e.LODWallNextRoute or 0) then
        self:Route(e,s.Graph,p,fleeing);e.LODWallNextRoute=now+.8
        wp=e.LODWallRoute and e.LODWallRoute[e.LODWallRouteIndex or 1]
    end
    if wp then
        local before=e:GetPos()
        if self:Step(e,wp.pos,e.LODConfig.speed,dt,wp.stair) then
            e.LODWallRouteIndex=e.LODWallRouteIndex+1;e.LODWallLane=wp.lane;e.LODWallBlockedSince=nil
        elseif e:GetPos():DistToSqr(before)>.01 then e.LODWallBlockedSince=nil
        else
            e.LODWallBlockedSince=e.LODWallBlockedSince or now
            if now-e.LODWallBlockedSince>.8 then e.LODWallRoute=nil;e.LODWallBlockedSince=nil end
        end
        if now>=(e.LODNextScrape or 0) then e.LODNextScrape=now+.65;e:EmitSound("npc/fast_zombie/foot1.wav",62,130,.6) end
    else motion:Stop(e);e:_SetActivity(ACT_IDLE) end
    return true
end
