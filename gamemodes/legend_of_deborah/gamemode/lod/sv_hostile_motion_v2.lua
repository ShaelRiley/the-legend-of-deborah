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
local CELL_INTERIOR_MARGIN = 32
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

    -- Keep local pursuit and spawn offsets at least 32 units inside a cell edge.
    -- The stable humanoid hull is 16 units wide per side, leaving another 16
    -- units of deterministic clearance from a closed container wall.
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
    if not IsValid(hostile) or hostile.LODDead then return false end
    local _, graph = graphState()
    if not graph or not Navigator then return false end
    local cell = Navigator:WorldToCell(graph, hostile:GetPos())
    if not cell then return false end

    local safe = self:CellFloorPoint(cell, hostile:GetPos())
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
    if not IsValid(hostile) or hostile.LODDead or not waypoint or not waypoint.pos then
        self:Stop(hostile)
        return false
    end
    if hostile.LODDeadcrabState == "leaping" or hostile.LODDeadcrabState == "latched" then
        return false
    end

    local now = CurTime()
    local last = hostile.LODMotionLastUpdate or now
    local dt = math.Clamp(now - last, 0, MAX_STEP_DT)
    hostile.LODMotionLastUpdate = now
    if dt <= 0 then return false end

    quiesceEngineLocomotion(hostile)

    local pos = hostile:GetPos()
    local goal = waypoint.pos
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
    local speed = math.max(1, cfg.speed or 90)
    local step = math.min(distance, speed * dt)
    local direction = delta / distance
    local nextPos = pos + direction * step

    if not waypoint.stair then nextPos.z = goal.z end

    -- Physical execution is intentionally independent of Source collision
    -- response. The graph and validated local waypoint compiler are the movement
    -- authority; SetPos cannot become stuck while trying to resolve generated
    -- floor/wall contacts.
    hostile:SetPos(nextPos)
    self:FaceToward(hostile, nextPos + direction * 32)

    local moved = nextPos - pos
    hostile.LODMotionVelocity = dt > 0 and (moved / dt) or vector_origin
    hostile.LODMotionSpeed = dt > 0 and (moved:Length2D() / dt) or 0
    hostile.LODMotionMode = waypoint.stair and "stair" or "ground"
    hostile.LODMotionLastPos = nextPos
    hostile.LODMotionTravel = (hostile.LODMotionTravel or 0) + moved:Length()
    advanceStrideVariance(hostile, moved:Length())
    return step >= distance - 0.05
end

local function movementActivity(hostile)
    if hostile.LODArchetypeId == "soldier" then return hostile:_SoldierRunActivity() end
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

        if self.LODArchetypeId == "soldier" and self.LODSoldierBurst then
            Motion:Stop(self)
            if IsValid(self.LODSoldierBurst.target) then
                Motion:FaceToward(self, self.LODSoldierBurst.target:GetPos())
            end
            self:_ProcessSoldierBurst()
            return
        end

        local target = self.LODTarget
        local waypoint = self:_AdvanceWaypoint()

        if self.LODArchetypeId == "soldier" and IsValid(target) and self:_HasLineOfSight(target) then
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
            local localGoal = sameCellTargetGoal(self, graph, target)
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
                if self.LODArchetypeId == "soldier" then self:_SetActivity(self:_SoldierIdleActivity()) end
            end
        end

        if IsValid(target) and self.LODArchetypeId ~= "soldier" then self:_TryAttack(target) end
    end

    -- BodyMoveXY derives animation direction from CLuaLocomotion velocity. V2
    -- deliberately does not use that velocity, so calling it would recreate the
    -- backwards/sideways animation ambiguity seen in testing. Explicit yaw owns
    -- facing; the selected walk/run activity simply advances in place.
    function class:BodyUpdate()
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
