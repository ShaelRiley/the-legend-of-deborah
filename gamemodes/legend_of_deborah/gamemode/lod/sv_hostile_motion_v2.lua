LOD = LOD or {}
LOD.HostileMotionV2 = LOD.HostileMotionV2 or {}

local Motion = LOD.HostileMotionV2
local Navigator = LOD.MazeNavigator
local MC = LOD.Config.Maze
local cellKey = LOD.MazeGenerator.CellKey

-- Milestone-3 locomotion v2
--
-- The original hostile architecture correctly used the canonical maze graph for
-- high-level routing, but delegated physical execution of each waypoint to
-- CLuaLocomotion:Approach. Runtime testing on generated lod_static_box floors and
-- stairs showed that Source's NextBot ground state is not dependable there:
-- bots can report velocity while making no world-position progress, fail to
-- register generated floors as ground, wedge into walls, and repeatedly enter
-- recovery loops. Recovery then became a second movement system fighting the
-- first.
--
-- Keep the successful graph/target/encounter architecture and replace ONLY the
-- physical motion kernel. Ground travel is now server-authoritative kinematic
-- movement along graph-authored waypoints. We do not ask Source to discover the
-- floor, climb, jump, avoid a wall, or infer stair elevation. Ordinary Z changes
-- are impossible; explicit stair waypoints are the only ground-route nodes that
-- may alter elevation. Deadcrab retains its dedicated leap state as the sole
-- intentional airborne exception.

local FLOOR_LIFT = 2
local MAX_STEP_DT = 0.050
local CELL_INTERIOR_MARGIN = (LOD.Config.Geometry.ContainerWidth or 128)*.5 + 24
local MIN_FACE_DELTA_SQR = 0.25

Motion.Version = 2
Motion.FloorLift = FLOOR_LIFT

local function graphState()
    local state = LOD.RunManager and LOD.RunManager.State
    return state, state and state.Graph or nil
end

local function sameCell(a, b)
    return a and b and a.x == b.x and a.y == b.y and a.z == b.z
end

-- Collision data is derived from the current graph and its actual immutable
-- generated boxes. Never scan entities per actor/tick or retain a previous build.
local stairDirections={N={0,1},E={1,0},S={0,-1},W={-1,0}}
local function stairIndex()
    local state,graph=graphState()
    local builder=LOD.MazeBuilder
    local entities=builder and builder.Entities
    if not graph or not entities then return nil end
    local old=graph.LODHostileStairCollision
    if old and old.graph==graph and old.version==2 and old.owner==entities and old.count==#entities then return old end
    local index={graph=graph,version=2,owner=entities,count=#entities,flights={},byEdge={},buckets={},cellSize=math.max(1,MC.CellSize)}
    graph.LODHostileStairCollision=index
    local geometry=LOD.Config.Geometry
    for _,edge in ipairs(graph.VerticalEdges or {}) do
        local d=stairDirections[edge.LODStairDirection]
        if d then
            local lower=edge.a.z<edge.b.z and edge.a or edge.b
            local base=Navigator:CellCenter(lower)
            local f={edge=edge,graph=graph,base=base,dx=d[1],dy=d[2],
                center=base-Vector(d[1],d[2],0)*(geometry.StairRun*.5),uMin=math.huge,uMax=-math.huge,
                solids={},treads={},lo=Vector(math.huge,math.huge,math.huge),
                hi=Vector(-math.huge,-math.huge,-math.huge)}
            index.flights[#index.flights+1]=f;index.byEdge[edge]=f
        end
    end
    for _,e in ipairs(entities) do
        if IsValid(e) and e.GetBoxKind and e.GetCollisionBounds and e.GetPos then
            local kind=e:GetBoxKind()
            if kind==1 or kind==2 or kind==3 then
                local pos=e:GetPos();local lo,hi=e:GetCollisionBounds()
                if lo and hi then for _,f in ipairs(index.flights) do
                    local expected
                    if kind==2 then expected=f.center
                    elseif kind==3 then expected=f.center+Vector(0,0,MC.LevelHeight*.5)
                    else expected=f.base+Vector(0,0,MC.LevelHeight-(geometry.FloorThickness or 16)*.5) end
                    if pos:DistToSqr(expected)<.01 then
                        f.solids[#f.solids+1]=e;if kind==2 then f.treads[#f.treads+1]=e end
                        if kind~=1 then
                            local a=(pos.x+lo.x-f.base.x)*f.dx+(pos.y+lo.y-f.base.y)*f.dy
                            local b=(pos.x+hi.x-f.base.x)*f.dx+(pos.y+hi.y-f.base.y)*f.dy
                            f.uMin=math.min(f.uMin,a,b);f.uMax=math.max(f.uMax,a,b)
                        end
                        f.lo.x=math.min(f.lo.x,pos.x+lo.x);f.lo.y=math.min(f.lo.y,pos.y+lo.y);f.lo.z=math.min(f.lo.z,pos.z+lo.z)
                        f.hi.x=math.max(f.hi.x,pos.x+hi.x);f.hi.y=math.max(f.hi.y,pos.y+hi.y);f.hi.z=math.max(f.hi.z,pos.z+hi.z)
                    end
                end end
            end
        end
    end
    -- A coarse world grid keeps ordinary movement away from stairs out of
    -- the native trace path; the actual boxes remain collision authority.
    local size=index.cellSize
    for _,f in ipairs(index.flights) do
        if #f.solids>0 then
            for x=math.floor(f.lo.x/size),math.floor(f.hi.x/size) do
                for y=math.floor(f.lo.y/size),math.floor(f.hi.y/size) do
                    for z=math.floor(f.lo.z/size),math.floor(f.hi.z/size) do
                        local k=x..":"..y..":"..z
                        local bucket=index.buckets[k] or {};index.buckets[k]=bucket;bucket[#bucket+1]=f
                    end
                end
            end
        end
    end
    return index
end
local function nearFlights(index,a,b,lo,hi)
    local result,seen;local size=index.cellSize
    for x=math.floor((math.min(a.x,b.x)+lo.x)/size),math.floor((math.max(a.x,b.x)+hi.x)/size) do
        for y=math.floor((math.min(a.y,b.y)+lo.y)/size),math.floor((math.max(a.y,b.y)+hi.y)/size) do
            for z=math.floor((math.min(a.z,b.z)+lo.z)/size),math.floor((math.max(a.z,b.z)+hi.z)/size) do
                local bucket=index.buckets[x..":"..y..":"..z]
                if bucket then
                    result=result or {};seen=seen or {}
                    for _,f in ipairs(bucket) do if not seen[f] then seen[f]=true;result[#result+1]=f end end
                end
            end
        end
    end
    return result
end
local function actorBounds(e)
    if not e.GetCollisionBounds then return nil end
    return e:GetCollisionBounds()
end
local function overlapsFlight(f,a,b,lo,hi)
    return math.min(a.x,b.x)+lo.x<=f.hi.x and math.max(a.x,b.x)+hi.x>=f.lo.x
        and math.min(a.y,b.y)+lo.y<=f.hi.y and math.max(a.y,b.y)+hi.y>=f.lo.y
        and math.min(a.z,b.z)+lo.z<=f.hi.z and math.max(a.z,b.z)+hi.z>=f.lo.z
end
local function traceList(a,b,lo,hi,list)
    return util.TraceHull({start=a,endpos=b,mins=lo,maxs=hi,mask=MASK_NPCSOLID,
        filter=list,whitelist=true,ignoreworld=true})
end
local function worldFilter(e)
    return not e.LODHostile and not (e.IsPlayer and e:IsPlayer())
end
local function traceWorld(a,b,lo,hi)
    return util.TraceHull({start=a,endpos=b,mins=lo,maxs=hi,mask=MASK_NPCSOLID,filter=worldFilter})
end
local function clearTrace(tr)
    return tr and not tr.StartSolid and not tr.AllSolid and not tr.Hit
end
function Motion:TraceStairMovement(hostile,from,to)
    local index=stairIndex();if not index or #index.flights==0 then return nil end
    local lo,hi=actorBounds(hostile);if not lo or not hi then return nil end
    local nearby=nearFlights(index,from,to,lo,hi);if not nearby then return nil end
    local solids={}
    for _,f in ipairs(nearby) do
        if overlapsFlight(f,from,to,lo,hi) then
            for _,e in ipairs(f.solids) do if IsValid(e) then solids[#solids+1]=e end end
        end
    end
    if #solids==0 then return nil end
    return traceList(from,to,lo,hi,solids)
end
local function flightForWaypoint(waypoint)
    local index=stairIndex()
    if not index or waypoint.stairGraph~=select(2,graphState()) then return nil end
    return index.byEdge[waypoint.stairEdge]
end
local function supportedPoint(hostile,point,flight)
    local lo,hi=actorBounds(hostile);if not lo or not hi or #flight.treads==0 then return point end
    local top=Vector(point.x,point.y,flight.base.z+MC.LevelHeight+FLOOR_LIFT-lo.z)
    local bottom=Vector(point.x,point.y,flight.base.z+FLOOR_LIFT-lo.z)
    local tr=traceList(top,bottom,lo,hi,flight.treads)
    if tr and tr.Hit and not tr.StartSolid and not tr.AllSolid then return tr.HitPos+Vector(0,0,FLOOR_LIFT) end
    return point
end
local function flightForEntity(e)
    local index=stairIndex();if not index or not IsValid(e) then return nil end
    for _,f in ipairs(index.flights) do for _,v in ipairs(f.solids) do if v==e then return f end end end
end
local function sidePoint(hostile,goal,flight,sign)
    local lo,hi=actorBounds(hostile);if not lo or not hi then return nil end
    local tx,ty=-flight.dy,flight.dx
    local radius=math.max(math.abs(lo.x*tx+lo.y*ty),math.abs(hi.x*tx+hi.y*ty))
    local side=sign*((LOD.Config.Geometry.StairWidth or 128)*.5+radius+FLOOR_LIFT)
    local v=(goal.x-flight.base.x)*tx+(goal.y-flight.base.y)*ty
    return goal+Vector(tx,ty,0)*(side-v)
end
function Motion:WaypointPosition(hostile,waypoint)
    if not waypoint or not waypoint.pos then return nil end
    local flight=waypoint.stair and flightForWaypoint(waypoint)
    if flight then return supportedPoint(hostile,waypoint.pos,flight) end
    local tr=self:TraceStairMovement(hostile,waypoint.pos,waypoint.pos)
    if not tr or not (tr.Hit or tr.StartSolid or tr.AllSolid) then return waypoint.pos end
    local f=flightForEntity(tr.Entity);if not f then return nil end
    local lo,hi=actorBounds(hostile);local p=hostile:GetPos()
    local side=(p.x-f.base.x)*(-f.dy)+(p.y-f.base.y)*f.dx
    local first=side<0 and -1 or 1
    for _,sign in ipairs({first,-first}) do
        local candidate=sidePoint(hostile,waypoint.pos,f,sign)
        if candidate and clearTrace(traceWorld(candidate,candidate,lo,hi)) then return candidate end
    end
    return nil
end
-- Stair movement is an up/across/down path, not a diagonal SetPos through a
-- riser. The supported waypoint accounts for the actor's whole footprint.
function Motion:ConstrainStairMovement(hostile,from,to,waypoint,goal)
    local flight=waypoint.stair and flightForWaypoint(waypoint)
    local lo,hi=actorBounds(hostile)
    if flight and lo and hi then
        local supported=supportedPoint(hostile,to,flight)
        local raised=Vector(from.x,from.y,math.max(from.z,supported.z))
        local across=Vector(supported.x,supported.y,raised.z)
        if not clearTrace(traceWorld(from,raised,lo,hi))
            or not clearTrace(traceWorld(raised,across,lo,hi))
            or not clearTrace(traceWorld(across,supported,lo,hi)) then return from,true,true end
        return supported,false,true
    end
    local index=stairIndex()
    local plan=hostile.LODMotionStairDetour
    local function sameBounds(p)
        return lo and hi and p.lo.x==lo.x and p.lo.y==lo.y and p.lo.z==lo.z
            and p.hi.x==hi.x and p.hi.y==hi.y and p.hi.z==hi.z
    end
    if plan and (plan.index~=index or not sameBounds(plan) or plan.target~=hostile.LODTarget
        or math.abs(plan.goalZ-goal.z)>.05) then plan=nil;hostile.LODMotionStairDetour=nil end
    local tr=self:TraceStairMovement(hostile,from,plan and goal or to)
    if not tr or not (tr.Hit or tr.StartSolid or tr.AllSolid) then
        hostile.LODMotionStairDetour=nil;return to,false,false
    end
    if tr.StartSolid or tr.AllSolid then return from,true,false end
    local f=flightForEntity(tr.Entity)
    if not f or not lo or not hi or not tr.HitNormal or math.abs(tr.HitNormal.z)>.5 then return from,true,false end
    local tx,ty=-f.dy,f.dx
    local goalV=(goal.x-f.base.x)*tx+(goal.y-f.base.y)*ty
    local goalSide=goalV<0 and -1 or 1
    if plan and (plan.flight~=f or plan.goalSide~=goalSide) then plan=nil;hostile.LODMotionStairDetour=nil end
    if not plan then
        local v=(from.x-f.base.x)*tx+(from.y-f.base.y)*ty
        local fromSide=v<0 and -1 or 1
        local radius=math.max(math.abs(lo.x*f.dx+lo.y*f.dy),math.abs(hi.x*f.dx+hi.y*f.dy))
        local bestCost
        for _,u in ipairs({f.uMin-radius-FLOOR_LIFT,f.uMax+radius+FLOOR_LIFT}) do
            local axis=f.base+Vector(f.dx,f.dy,0)*u;axis.z=from.z
            local one=sidePoint(hostile,axis,f,fromSide)
            local two=sidePoint(hostile,axis,f,goalSide)
            if clearTrace(traceWorld(from,one,lo,hi)) and clearTrace(traceWorld(one,two,lo,hi))
                and clearTrace(traceWorld(two,goal,lo,hi)) then
                local cost=(one-from):Length()+(two-one):Length()+(goal-two):Length()
                if not bestCost or cost<bestCost then
                    bestCost=cost;plan={index=index,flight=f,target=hostile.LODTarget,goalZ=goal.z,
                        goalSide=goalSide,lo=lo,hi=hi,points={one,two},at=1}
                end
            end
        end
        if not plan then return from,true,false end
        hostile.LODMotionStairDetour=plan
    end
    while plan.points[plan.at] and from:DistToSqr(plan.points[plan.at])<=.05*.05 do plan.at=plan.at+1 end
    local point=plan.points[plan.at]
    if not point then hostile.LODMotionStairDetour=nil;return from,true,false end
    local delta=point-from;local distance=(to-from):Length();local length=delta:Length()
    local candidate=from+delta*(math.min(distance,length)/length)
    if clearTrace(traceWorld(from,candidate,lo,hi)) then return candidate,true,false end
    hostile.LODMotionStairDetour=nil;return from,true,false
end

local function currentWaypoint(hostile)
    local waypoints = hostile.LODWaypoints or {}
    return waypoints[hostile.LODWaypointIndex or 1]
end

local function quiesceEngineLocomotion(hostile)
    if not hostile.loco then return end

    -- Desired speed and velocity remain dynamic: variance and hit-stun wrappers
    -- can restore them between motion updates, so they must still be suppressed.
    hostile.loco:SetDesiredSpeed(0)
    if hostile.loco.SetVelocity then hostile.loco:SetVelocity(vector_origin) end

    -- Gravity/jump/climb policy is invariant for ordinary Motion V2 hostiles.
    -- Reissuing these four engine setters every update performed no useful work.
    -- Deadcrab is excluded because its committed leap deliberately owns them.
    if hostile.LODArchetypeId ~= "deadcrab" and not hostile.LODMotionStaticSuppressionCached then
        if hostile.loco.SetGravity then hostile.loco:SetGravity(0) end
        if hostile.loco.SetJumpHeight then hostile.loco:SetJumpHeight(0) end
        if hostile.loco.SetClimbAllowed then hostile.loco:SetClimbAllowed(false) end
        if hostile.loco.SetJumpGapsAllowed then hostile.loco:SetJumpGapsAllowed(false) end
        hostile.LODMotionStaticSuppressionCached = true
    end
end

function Motion:FaceToward(hostile, worldPos)
    if not IsValid(hostile) or not worldPos then return end
    local pos = hostile:GetPos()
    local delta = Vector(worldPos.x - pos.x, worldPos.y - pos.y, 0)
    if delta:LengthSqr() <= MIN_FACE_DELTA_SQR then return end
    local yaw = delta:Angle().y
    hostile:SetAngles(Angle(0, yaw, 0))
    hostile.LODMotionYaw = yaw
end

function Motion:Stop(hostile)
    if not IsValid(hostile) then return end
    hostile.LODMotionStairDetour = nil
    hostile.LODMotionSpeed = 0
    hostile.LODMotionVelocity = vector_origin
    hostile.LODMotionMode = "hold"
    quiesceEngineLocomotion(hostile)
end

-- Hit feedback can be installed before or after this class patch depending on
-- Source's OnEntityCreated hook order. Enforce the stun at the one physical
-- movement authority so no wrapper order can restore kinematic travel.
function Motion:HoldHitStun(hostile, now)
    if not IsValid(hostile) then return false end
    now = now or CurTime()

    local stunUntil = hostile.LODHitStunUntil or 0
    if now >= stunUntil then
        local audit = hostile.LODMotionHitStunAudit
        if audit and not audit.finished then
            audit.finished = true
            audit.active = false
        end
        return false
    end

    local audit = hostile.LODMotionHitStunAudit
    if not audit or audit.stunUntil ~= stunUntil then
        audit = {
            active = true,
            finished = false,
            stunUntil = stunUntil,
            startPos = hostile:GetPos(),
            holdTicks = 0,
            maxDrift = 0
        }
        hostile.LODMotionHitStunAudit = audit
    end

    local drift = hostile:GetPos():Distance(audit.startPos)
    audit.holdTicks = audit.holdTicks + 1
    audit.maxDrift = math.max(audit.maxDrift, drift)

    self:Stop(hostile)
    hostile.LODMotionMode = "hit-stun"
    return true
end

function Motion:CellFloorPoint(cell, sourcePos)
    if not cell or not Navigator then return sourcePos end
    local center = Navigator:CellCenter(cell)
    if not sourcePos then return center + Vector(0, 0, FLOOR_LIFT) end

    -- A closed container occupies half its width inside the logical cell.
    -- Reserve that volume plus the humanoid half-hull and clearance.
    local limit = math.max(32, MC.CellSize * 0.5 - CELL_INTERIOR_MARGIN)
    return Vector(
        math.Clamp(sourcePos.x, center.x - limit, center.x + limit),
        math.Clamp(sourcePos.y, center.y - limit, center.y + limit),
        center.z + FLOOR_LIFT
    )
end

function Motion:SafeEngagementPoint(graph, target)
    if not graph or not IsValid(target) then return nil end
    local cell = Navigator:WorldToCell(graph, target:GetPos())
    if not cell then return target:GetPos() end
    return self:CellFloorPoint(cell, target:GetPos())
end

function Motion:SnapSpawn(hostile)
    if IsValid(hostile) and hostile.LODBossAirborne then self:Stop(hostile);return true end
    if not IsValid(hostile) or hostile.LODDead then return false end
    local _, graph = graphState()
    if not graph or not Navigator then return false end
    local cell = Navigator:WorldToCell(graph, hostile:GetPos())
    if not cell then return false end

    if hostile.LODRosterPlacement and (hostile.LODRosterPlacement.ceiling or hostile.LODRosterPlacement.wallLane) then
        quiesceEngineLocomotion(hostile)
        hostile:SetPos(hostile.LODRosterPlacement.pos)
        if hostile.LODRosterPlacement.wallLane then
            hostile.LODWallInitialized=true
            hostile.LODWallLane=hostile.LODRosterPlacement.wallLane
        end
        return true
    end
    if hostile.LODWallInitialized then return true end
    local safe = self:CellFloorPoint(cell, hostile:GetPos())
    safe = self:WaypointPosition(hostile,{pos=safe})
    if not safe then return false end
    local yaw = hostile:GetAngles().y
    hostile:SetPos(safe)
    -- SOLID_BBOX entities can have angles disturbed by SetPos; restore yaw after
    -- positioning rather than depending on NextBot's delayed FaceTowards.
    hostile:SetAngles(Angle(0, yaw, 0))
    hostile.LODMotionLastUpdate = CurTime()
    hostile.LODMotionLastPos = safe
    hostile.LODMotionSpeed = 0
    hostile.LODMotionVelocity = vector_origin
    hostile.LODMotionMode = "spawn"
    quiesceEngineLocomotion(hostile)
    return true
end

local function advanceStrideVariance(hostile, travelled)
    if travelled <= 0 or not hostile.LODStrideRNG then return end
    hostile.LODStrideAccumDistance = (hostile.LODStrideAccumDistance or 0) + travelled
    local target = hostile.LODStrideTargetDistance or hostile.LODStrideBaseDistance or 52
    if hostile.LODStrideAccumDistance >= target then
        hostile.LODStrideAccumDistance = math.max(0, hostile.LODStrideAccumDistance - target)
        if LOD.EnemyVariance and LOD.EnemyVariance.AdvanceFootstep then
            LOD.EnemyVariance:AdvanceFootstep(hostile)
        end
    end
end

function Motion:MoveToward(hostile, waypoint)
    if IsValid(hostile) and hostile.LODEntrySuppressed and not hostile.LODEntryWithdrawing then
        self:Stop(hostile);return false
    end
    if not IsValid(hostile) or hostile.LODDead or not waypoint or not waypoint.pos then
        self:Stop(hostile)
        return false
    end
    -- Specialized retreat timers share this kernel with the native coroutine.
    -- They may not move an actor out of its advertised stationary close strike.
    if hostile.LODRosterAttack and hostile.LODRosterAttack.closeDefense then
        self:Stop(hostile);return false
    end
    if hostile.LODDeadcrabState == "leaping" or hostile.LODDeadcrabState == "latched" then
        return false
    end
    local statusElements = LOD.RPGStatusElements
    if statusElements and not statusElements:CanMoveVoluntarily(hostile) then
        self:Stop(hostile)
        return false
    end

    if LOD.HostileAnimation then LOD.HostileAnimation:Move(hostile) end
    local now = CurTime()
    local last = hostile.LODMotionLastUpdate or now
    local dt = math.Clamp(now - last, 0, MAX_STEP_DT)
    hostile.LODMotionLastUpdate = now
    if dt <= 0 then return false end

    quiesceEngineLocomotion(hostile)

    local pos = hostile:GetPos()
    local goal = self:WaypointPosition(hostile,waypoint)
    if not goal then self:Stop(hostile);hostile.LODNextRouteRefresh=0;return false end
    local delta = goal - pos

    -- Ordinary graph travel is mathematically planar. Only an explicit stair
    -- node is allowed to carry a changing Z coordinate. Container-top travel is
    -- therefore impossible by construction instead of by jump-height heuristics.
    if not waypoint.stair then delta.z = 0 end

    local distance = delta:Length()
    if distance <= 0.05 then
        self:Stop(hostile)
        return true
    end

    local cfg = hostile.LODConfig or {}
    local statusMultiplier = statusElements and statusElements:LocomotionMultiplier(hostile) or 1
    local rules = LOD.RPGAbilityRules
    local rogueMultiplier = rules and rules.RogueMovementMultiplier and rules:RogueMovementMultiplier(hostile) or 1
    local dexMultiplier = rules and rules.HostileDexMovementMultiplier and rules:HostileDexMovementMultiplier(hostile) or 1
    local speed = math.max(1, (cfg.speed or 90) * statusMultiplier * rogueMultiplier * dexMultiplier)
    local step = math.min(distance, speed * dt)
    local direction = delta / distance
    local nextPos = pos + direction * step

    if not waypoint.stair then nextPos.z = goal.z end

    local magicForms=LOD.MagicForms
    local wallBlocked=false
    if magicForms and magicForms.ConstrainWallMovement then
        nextPos,wallBlocked=magicForms:ConstrainWallMovement(hostile,pos,nextPos)
    end

    -- Physical execution is intentionally independent of Source collision
    -- response. The graph and validated local waypoint compiler are the movement
    -- authority; SetPos cannot become stuck while trying to resolve generated
    -- floor/wall contacts.
    local stairBlocked,stairWorldChecked
    nextPos,stairBlocked,stairWorldChecked=self:ConstrainStairMovement(hostile,pos,nextPos,waypoint,goal)
    wallBlocked=wallBlocked or stairBlocked
    if hostile.LODBossEncounter and LOD.BossEncounter and not stairWorldChecked then
        local lo,hi=LOD.BossEncounter:Hull(hostile)
        local tr=util.TraceHull({start=pos,endpos=nextPos,mins=lo,maxs=hi,mask=MASK_NPCSOLID,
            filter=function(e) return e~=hostile and not e:IsPlayer() and not e.LODHostile end})
        hostile.LODBossBlockTrace=tr
        if tr.StartSolid or tr.AllSolid then self:Stop(hostile);hostile.LODBossMotionBlocked=true;return false end
        if tr.Hit then nextPos=tr.HitPos;wallBlocked=true end
        hostile.LODBossMotionBlocked=tr.Hit==true
    end
    if LOD.EntrySafety and not LOD.EntrySafety:MovementAllowed(hostile,pos,nextPos) then
        self:Stop(hostile);return false
    end
    hostile:SetPos(nextPos)
    self:FaceToward(hostile, nextPos + direction * 32)

    local moved = nextPos - pos
    hostile.LODMotionVelocity = dt > 0 and (moved / dt) or vector_origin
    hostile.LODMotionSpeed = dt > 0 and (moved:Length2D() / dt) or 0
    hostile.LODMotionMode = wallBlocked and "magic-wall" or waypoint.stair and "stair" or "ground"
    hostile.LODMotionLastPos = nextPos
    hostile.LODMotionTravel = (hostile.LODMotionTravel or 0) + moved:Length()
    advanceStrideVariance(hostile, moved:Length())
    if statusElements then statusElements:ObserveCell(hostile) end
    return not wallBlocked and step >= distance - 0.05
end

local function soldierFamily(hostile)
    local archetype = hostile and hostile.LODArchetypeId
    return archetype == "soldier" or archetype == "blitzer"
end

local function movementActivity(hostile)
    if soldierFamily(hostile) then return hostile:_SoldierRunActivity() end
    return hostile.LODConfig and hostile.LODConfig.activity or ACT_WALK
end

local function meleeHold(hostile, target)
    if not IsValid(target) then return false end
    local cfg = hostile.LODConfig or {}
    local range = cfg.meleeRange or 0
    if range <= 0 then return false end
    return hostile:GetPos():DistToSqr(target:GetPos()) <= (range * 0.92) * (range * 0.92)
end

local function sameCellTargetGoal(hostile, graph, target)
    if not IsValid(target) then return nil end
    local here = Navigator:WorldToCell(graph, hostile:GetPos())
    local there = Navigator:WorldToCell(graph, target:GetPos())
    if not sameCell(here, there) then return nil end
    return Motion:SafeEngagementPoint(graph, target)
end

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODMotionV2Patched then return false end
    class.LODMotionV2Patched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if not IsValid(self) or not self.LODHostile then return end
        self.LODMotionV2 = true
        self:SetNW2Bool("LOD_MotionV2", true)
        quiesceEngineLocomotion(self)
        timer.Simple(0, function()
            if IsValid(self) and not self.LODDead then Motion:SnapSpawn(self) end
        end)
    end

    -- Replace only the generic physical-execution loop. Archetype modules loaded
    -- after this file still wrap this method, so Soldier, Deadcrab, Bio Blaster,
    -- variance, wandering, hit-stun, and death retain their state machines while
    -- sharing one motion kernel.
    function class:_BehaviourTick()
        if LOD.EntrySafety and LOD.EntrySafety:BeforeAI(self) then return end
        if LOD.BossEncounter and LOD.BossEncounter:TickActor(self) then return end
        if LOD.Hector and LOD.Hector:Tick(self) then return end
        if LOD.Warden and LOD.Warden:Tick(self) then return end
        if LOD.NeilBrute and LOD.NeilBrute:Tick(self) then return end
        if LOD.EnemyRoster and LOD.EnemyRoster:Tick(self) then return end
        if LOD.EnemyUpdate and LOD.EnemyUpdate:Tick(self) then return end
        if self.LODDead or not self.LODActivated then
            Motion:Stop(self)
            return
        end

        if Motion:HoldHitStun(self, CurTime()) then return end

        local state, graph = graphState()
        if not graph or not state.BuildReady or state.Failed or state.LevelCleared then
            Motion:Stop(self)
            return
        end

        local statusElements = LOD.RPGStatusElements
        if statusElements and statusElements:HandleAIFlee(self, graph, Motion) then return end

        -- Archetype combat is explicit Motion V2 dispatch, not an incidental
        -- wrapper-ordering side effect. These methods are supplied by their
        -- respective archetype modules.
        if self.LODArchetypeId == "deadcrab" and self._RunDeadcrabTick
            and self:_RunDeadcrabTick()
        then
            return
        end

        if self.LODArchetypeId == "bioblaster" and self._RunBioBlasterTick
            and self:_RunBioBlasterTick()
        then
            return
        end

        self:_RefreshTarget(graph)
        self:_RefreshRoute(graph)

        if soldierFamily(self) and self.LODSoldierBurst then
            Motion:Stop(self)
            if IsValid(self.LODSoldierBurst.target) then
                Motion:FaceToward(self, self.LODSoldierBurst.target:GetPos())
            end
            self:_ProcessSoldierBurst()
            return
        end

        local target = self.LODTarget
        local waypoint = self:_AdvanceWaypoint()

        if soldierFamily(self) and IsValid(target) and self:_HasLineOfSight(target) then
            local preferred = self.LODConfig.preferredRange or 480
            if self:GetPos():DistToSqr(target:GetPos()) <= preferred * preferred then
                Motion:Stop(self)
                Motion:FaceToward(self, target:GetPos())
                if not self:_TryAttack(target) then self:_SetActivity(self:_SoldierIdleActivity()) end
                return
            end
        end

        if IsValid(target) and meleeHold(self, target) and self:_HasLineOfSight(target) then
            Motion:Stop(self)
            Motion:FaceToward(self, target:GetPos())
        else
            -- When actor and target occupy the same logical cell, never chase the
            -- player's raw wall-hugging coordinates. Clamp the engagement point to
            -- the cell's guaranteed interior so a melee enemy cannot repeatedly
            -- drive its hull into a closed container wall.
            local localGoal = not (waypoint and waypoint.stair) and sameCellTargetGoal(self, graph, target)
            local moveWaypoint = localGoal and {
                pos = localGoal,
                tolerance = 18,
                stair = false,
                localEngagement = true
            } or waypoint

            if moveWaypoint then
                self:_SetActivity(movementActivity(self))
                Motion:MoveToward(self, moveWaypoint)
            elseif IsValid(target) then
                local safe = Motion:SafeEngagementPoint(graph, target)
                if safe then
                    self:_SetActivity(movementActivity(self))
                    Motion:MoveToward(self, {pos = safe, tolerance = 18, stair = false, localEngagement = true})
                end
            else
                Motion:Stop(self)
                if soldierFamily(self) then self:_SetActivity(self:_SoldierIdleActivity()) end
            end
        end

        if IsValid(target) and not soldierFamily(self) then self:_TryAttack(target) end
    end

    -- BodyMoveXY derives animation direction from CLuaLocomotion velocity. V2
    -- deliberately does not use that velocity, so calling it would recreate the
    -- backwards/sideways animation ambiguity seen in testing. Explicit yaw owns
    -- facing; player rigs use its recorded speed for their 9-way blend, while
    -- NPC rigs retain the existing walk/run cycle and move_yaw presentation.
    function class:BodyUpdate()
        if LOD.HostileAnimation and LOD.HostileAnimation:UpdatePlayerBody(self) then return end
        if self.SetPoseParameter then self:SetPoseParameter("move_yaw", 0) end
        self:FrameAdvance()
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_HostileMotionV2Install", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)

concommand.Add("lod_hitstun_motion_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local tested = 0
    local passed = 0
    local maxDrift = 0
    local holdTicks = 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        local audit = IsValid(hostile) and hostile.LODMotionHitStunAudit or nil
        if audit then
            tested = tested + 1
            holdTicks = holdTicks + (audit.holdTicks or 0)
            maxDrift = math.max(maxDrift, audit.maxDrift or 0)
            if (audit.holdTicks or 0) > 0 and (audit.maxDrift or math.huge) <= 1 then
                passed = passed + 1
            end
        end
    end

    local result = tested > 0 and tested == passed and "PASS" or "FAIL"
    local line = string.format(
        "tested=%d passed=%d holdTicks=%d maxDrift=%.3f result=%s",
        tested, passed, holdTicks, maxDrift, result
    )
    print("[LOD:HIT-STUN-MOTION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

local function statusLine(hostile)
    local _, graph = graphState()
    local cell = graph and Navigator:WorldToCell(graph, hostile:GetPos()) or nil
    local wp = currentWaypoint(hostile)
    return string.format(
        "#%d %s size=%.3f cell=%s pos=(%.1f,%.1f,%.1f) motion=%.1f mode=%s target=%s waypoint=%s encounter=%s wanderer=%s",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId),
        hostile:GetNW2Float("LOD_SizeScale", 1),
        cell and cellKey(cell.x, cell.y, cell.z) or "none",
        hostile:GetPos().x, hostile:GetPos().y, hostile:GetPos().z,
        hostile.LODMotionSpeed or 0, tostring(hostile.LODMotionMode or "none"),
        IsValid(hostile.LODTarget) and ("#" .. hostile.LODTarget:EntIndex()) or "none",
        wp and (wp.stair and "stair" or "route") or "none",
        tostring(hostile.LODEncounterId or "none"), tostring(hostile.LODWanderer == true)
    )
end

concommand.Add("lod_m3_motion_v2", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead then
            print("[LOD:MOTION-V2] " .. statusLine(hostile))
        end
    end
end)

concommand.Add("lod_m3_nearest_hostile", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) then return end

    local nearest, nearestDist
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead then
            local d = hostile:GetPos():DistToSqr(ply:GetPos())
            if not nearestDist or d < nearestDist then nearest, nearestDist = hostile, d end
        end
    end
    print("[LOD:NEAREST-HOSTILE] " .. (IsValid(nearest) and statusLine(nearest) or "none"))
end)


concommand.Add("lod_motion_suppression_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local ordinary = 0
    local cached = 0
    local deadcrabs = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead then
            if hostile.LODArchetypeId == "deadcrab" then
                deadcrabs = deadcrabs + 1
            else
                ordinary = ordinary + 1
                if hostile.LODMotionStaticSuppressionCached then cached = cached + 1 end
            end
        end
    end

    local passed = ordinary > 0 and cached == ordinary
    local line = string.format(
        "ordinary=%d cached=%d deadcrabs-exempt=%d avoidedStaticSettersPerUpdate=%d result=%s",
        ordinary, cached, deadcrabs, cached * 4, passed and "PASS" or "FAIL"
    )
    print("[LOD:MOTION-SUPPRESSION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
