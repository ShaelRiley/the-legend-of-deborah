LOD = LOD or {}
LOD.SeekerPersonality = LOD.SeekerPersonality or {}

local Personality = LOD.SeekerPersonality
local Seeker = LOD.Seeker
local Motion = LOD.HostileMotionV2
local Navigator = LOD.MazeNavigator
local RNG = LOD.RNG
local Seeds = LOD.Seeds

if not Seeker or not Motion or not Navigator or not RNG or not Seeds then return end

-- Seeker polish stays subordinate to the accepted single-authority Seeker state
-- machine. It only temporarily owns a Seeker during an authored feint/orbit, and
-- its adaptive service exists only while one of those short movements is active.
local SERVICE_NAME = "LOD_SeekerPersonalityService"
local SERVICE_INTERVAL = 0.05
local FEINT_CHANCE = 0.30
local POST_HIT_ORBIT_CHANCE = 0.25
local FEINT_SPEED = 230
local ORBIT_SPEED = 240
local FEINT_RECOVERY = 0.30
local ORBIT_RADIUS = 105
local ORBIT_POINTS = 10
local ORBIT_ABORT_DISTANCE = 180
local TELEPORT_GUARD_DISTANCE = 220

Personality.Active = Personality.Active or {}
Personality.PendingFeint = Personality.PendingFeint or {}
Personality.PendingOrbit = Personality.PendingOrbit or {}
Personality.Stats = Personality.Stats or {
    feints = 0,
    feintLeft = 0,
    feintRight = 0,
    orbits = 0,
    orbitCW = 0,
    orbitCCW = 0,
    orbitAborts = 0
}

local ensureService

local function currentGraph()
    local state = LOD.RunManager and LOD.RunManager.State
    if not state or not state.Graph or not state.BuildReady or state.Failed or state.LevelCleared then return nil end
    return state.Graph, state
end

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function horizontalDistance(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function seekerRNG(seeker)
    if seeker.LODSeekerPersonalityRNG then return seeker.LODSeekerPersonalityRNG end
    local _, state = currentGraph()
    local seed = state and (state.LevelSeed or state.CampaignSeed) or 1
    local identity = seeker.LODEncounterOrdinal or seeker.LODHomeCellKey or seeker:EntIndex()
    seeker.LODSeekerPersonalityRNG = RNG.New(Seeds.Derive(seed, "seeker-personality:" .. tostring(identity)))
    return seeker.LODSeekerPersonalityRNG
end

local function clearChargeFX(seeker)
    if not IsValid(seeker) then return end
    net.Start("LOD_SeekerState")
    net.WriteEntity(seeker)
    net.WriteUInt(0, 2)
    net.WriteFloat(0)
    net.Broadcast()
end

local function freezeGenericMotion(seeker)
    seeker.LODTarget = nil
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1
    seeker.LODNextTargetRefresh = math.huge
    seeker.LODNextRouteRefresh = math.huge
    seeker.LODNextSeekerCharge = math.huge
end

local function restoreOrdinaryTargeting(seeker, target, nextCharge)
    if not IsValid(seeker) then return end
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1
    seeker.LODNextRouteRefresh = 0
    seeker.LODNextTargetRefresh = 0
    seeker.LODNextSeekerCharge = nextCharge or (CurTime() + FEINT_RECOVERY)
    if livingPlayer(target) then
        seeker.LODTarget = target
        seeker.LODReturningHome = false
        seeker.LODNextTargetRefresh = CurTime() + 0.20
        Motion:FaceToward(seeker, target:GetPos())
    else
        seeker.LODTarget = nil
    end
end

local function distinctWaypoints(cell, rawPoints)
    local out = {}
    local last
    for _, raw in ipairs(rawPoints) do
        local point = Motion:CellFloorPoint(cell, raw)
        if point and (not last or point:DistToSqr(last) >= 10 * 10) then
            out[#out + 1] = {pos = point, tolerance = 9, stair = false, seekerPersonality = true}
            last = point
        end
    end
    return out
end

local function buildFeintWaypoints(seeker, graph, target, side)
    local cell = Navigator:WorldToCell(graph, seeker:GetPos())
    if not cell or not livingPlayer(target) then return nil end

    local pos = seeker:GetPos()
    local targetPos = target:GetPos()
    local forward = Vector(targetPos.x - pos.x, targetPos.y - pos.y, 0)
    if forward:LengthSqr() <= 0.01 then forward = seeker:GetForward() end
    forward:Normalize()
    local lateral = Vector(-forward.y, forward.x, 0) * (side < 0 and -1 or 1)

    -- A compact teardrop loop: slip outward, curl behind the original attack
    -- line, then return near the starting lane. Every point is clamped to the
    -- current graph-cell interior, so this flourish cannot cut a wall or gate.
    return distinctWaypoints(cell, {
        pos + lateral * 62 + forward * 24,
        pos + lateral * 92 - forward * 10,
        pos + lateral * 78 - forward * 58,
        pos + lateral * 36 - forward * 82,
        pos - forward * 52,
        pos + lateral * 8 - forward * 14,
        pos + forward * 10
    })
end

local function buildOrbitWaypoints(seeker, graph, target, clockwise)
    if not livingPlayer(target) then return nil end
    local targetCell = Navigator:WorldToCell(graph, target:GetPos())
    local seekerCell = Navigator:WorldToCell(graph, seeker:GetPos())
    if not targetCell or not seekerCell or targetCell.z ~= seekerCell.z then return nil end

    -- A full orbit is intentionally same-cell only. If the impact happened on a
    -- cell boundary, normal retreat wins rather than drawing a decorative circle
    -- through architecture.
    if targetCell.x ~= seekerCell.x or targetCell.y ~= seekerCell.y then return nil end

    local center = Vector(target:GetPos().x, target:GetPos().y, target:GetPos().z)
    local radial = seeker:GetPos() - center
    radial.z = 0
    if radial:LengthSqr() <= 0.01 then radial = seeker:GetForward() * -1 end
    local startAngle = math.atan2(radial.y, radial.x)
    local direction = clockwise and -1 or 1
    local raw = {}

    for i = 1, ORBIT_POINTS do
        local theta = startAngle + direction * (math.pi * 2) * (i / ORBIT_POINTS)
        raw[#raw + 1] = center + Vector(math.cos(theta), math.sin(theta), 0) * ORBIT_RADIUS
    end

    local points = distinctWaypoints(targetCell, raw)
    if #points < 6 then return nil end
    return points, center
end

local function moveAtSpeed(seeker, waypoint, speed)
    local cfg = seeker.LODConfig or {}
    local oldSpeed = cfg.speed
    cfg.speed = speed
    local reached = Motion:MoveToward(seeker, waypoint)
    cfg.speed = oldSpeed
    return reached
end

local function startFeint(seeker, stateRef)
    local graph = currentGraph()
    if not graph or not IsValid(seeker) or seeker.LODSeekerState ~= stateRef
        or not stateRef or stateRef.phase ~= "windup" or not livingPlayer(stateRef.target)
    then
        return false
    end

    local side = stateRef.personalityFeintSide or 1
    local waypoints = buildFeintWaypoints(seeker, graph, stateRef.target, side)
    if not waypoints or #waypoints < 4 then return false end

    seeker.LODSeekerState = nil
    seeker.LODSeekerPolishState = {
        kind = "feint",
        target = stateRef.target,
        waypoints = waypoints,
        index = 1,
        side = side
    }
    freezeGenericMotion(seeker)
    clearChargeFX(seeker)
    Personality.Active[seeker] = true
    Personality.Stats.feints = (Personality.Stats.feints or 0) + 1
    if side < 0 then
        Personality.Stats.feintLeft = (Personality.Stats.feintLeft or 0) + 1
    else
        Personality.Stats.feintRight = (Personality.Stats.feintRight or 0) + 1
    end
    return true
end

local function startOrbit(seeker, target)
    local graph = currentGraph()
    if not graph or not IsValid(seeker) or not livingPlayer(target)
        or seeker.LODSeekerPolishState or not seeker.LODSeekerRetreat
    then
        return false
    end

    local rng = seekerRNG(seeker)
    local clockwise = rng:Chance(0.50)
    local waypoints, center = buildOrbitWaypoints(seeker, graph, target, clockwise)
    if not waypoints then return false end

    local resumeRetreat = seeker.LODSeekerRetreat
    seeker.LODSeekerRetreat = nil
    seeker.LODSeekerPolishState = {
        kind = "orbit",
        target = target,
        center = center,
        waypoints = waypoints,
        index = 1,
        clockwise = clockwise,
        resumeRetreat = resumeRetreat
    }
    freezeGenericMotion(seeker)
    Personality.Active[seeker] = true
    Personality.Stats.orbits = (Personality.Stats.orbits or 0) + 1
    if clockwise then
        Personality.Stats.orbitCW = (Personality.Stats.orbitCW or 0) + 1
    else
        Personality.Stats.orbitCCW = (Personality.Stats.orbitCCW or 0) + 1
    end
    return true
end

local function finishFeint(seeker, state)
    seeker.LODSeekerPolishState = nil
    Personality.Active[seeker] = nil
    seeker.LODSeekerForceCharge = true
    Motion:Stop(seeker)
    restoreOrdinaryTargeting(seeker, state.target, CurTime() + FEINT_RECOVERY)
end

local function restoreRetreatAfterOrbit(seeker, state, aborted)
    seeker.LODSeekerPolishState = nil
    Personality.Active[seeker] = nil
    if aborted then Personality.Stats.orbitAborts = (Personality.Stats.orbitAborts or 0) + 1 end
    Motion:Stop(seeker)

    if state.resumeRetreat then
        seeker.LODSeekerRetreat = state.resumeRetreat
        seeker.LODTarget = nil
        seeker.LODWaypoints = {}
        seeker.LODWaypointIndex = 1
        seeker.LODNextTargetRefresh = math.huge
        seeker.LODNextRouteRefresh = math.huge
        seeker.LODNextSeekerCharge = math.huge
    else
        restoreOrdinaryTargeting(seeker, state.target, CurTime() + FEINT_RECOVERY)
    end
end

local function runActive(seeker)
    local state = seeker.LODSeekerPolishState
    if not state then
        Personality.Active[seeker] = nil
        return
    end

    if not livingPlayer(state.target) then
        if state.kind == "orbit" then
            restoreRetreatAfterOrbit(seeker, state, true)
        else
            seeker.LODSeekerPolishState = nil
            Personality.Active[seeker] = nil
            restoreOrdinaryTargeting(seeker, nil, CurTime() + FEINT_RECOVERY)
        end
        return
    end

    if state.kind == "orbit" and state.center
        and horizontalDistance(state.target:GetPos(), state.center) > ORBIT_ABORT_DISTANCE
    then
        restoreRetreatAfterOrbit(seeker, state, true)
        return
    end

    local waypoint = state.waypoints[state.index]
    if not waypoint then
        if state.kind == "orbit" then
            restoreRetreatAfterOrbit(seeker, state, false)
        else
            finishFeint(seeker, state)
        end
        return
    end

    local speed = state.kind == "orbit" and ORBIT_SPEED or FEINT_SPEED
    local reached = moveAtSpeed(seeker, waypoint, speed)
    seeker.LODMotionMode = state.kind == "orbit" and "seeker-orbit" or "seeker-feint"
    if reached then state.index = state.index + 1 end
end

local function hasWork()
    return next(Personality.Active) ~= nil
        or next(Personality.PendingFeint) ~= nil
        or next(Personality.PendingOrbit) ~= nil
end

local function service()
    for seeker, stateRef in pairs(Personality.PendingFeint) do
        Personality.PendingFeint[seeker] = nil
        if IsValid(seeker) then startFeint(seeker, stateRef) end
    end

    for seeker, target in pairs(Personality.PendingOrbit) do
        Personality.PendingOrbit[seeker] = nil
        if IsValid(seeker) then startOrbit(seeker, target) end
    end

    for seeker in pairs(Personality.Active) do
        if not IsValid(seeker) or seeker.LODDead then
            Personality.Active[seeker] = nil
        else
            runActive(seeker)
        end
    end

    if not hasWork() then timer.Remove(SERVICE_NAME) end
end

ensureService = function()
    if timer.Exists(SERVICE_NAME) then return end
    timer.Create(SERVICE_NAME, SERVICE_INTERVAL, 0, service)
end

-- The accepted Seeker core creates its wind-up state immediately before calling
-- Motion:Stop(). Mark the new state there, then convert it on the next 50 ms
-- personality tick, after the core has completed its own synchronous bookkeeping.
-- Likewise, a charge only calls Stop at player/wall resolution; proximity to the
-- live target distinguishes a successful player hit from a wall impact.
local baseStop = Motion.Stop
function Motion:Stop(hostile)
    baseStop(self, hostile)
    if not IsValid(hostile) or hostile.LODDead or hostile.LODArchetypeId ~= "seeker" then return end

    local state = hostile.LODSeekerState
    if state and state.phase == "windup" and not state.personalityConsidered then
        state.personalityConsidered = true
        if hostile.LODSeekerForceCharge then
            hostile.LODSeekerForceCharge = nil
        else
            local rng = seekerRNG(hostile)
            if rng:Chance(FEINT_CHANCE) then
                state.personalityFeintSide = rng:Chance(0.50) and -1 or 1
                Personality.PendingFeint[hostile] = state
                ensureService()
            end
        end
    elseif state and state.phase == "charge" and not state.personalityOrbitConsidered
        and livingPlayer(state.target)
        and hostile:GetPos():DistToSqr(state.target:GetPos()) <= 70 * 70
    then
        state.personalityOrbitConsidered = true
        if seekerRNG(hostile):Chance(POST_HIT_ORBIT_CHANCE) then
            Personality.PendingOrbit[hostile] = state.target
            ensureService()
        end
    end
end

local function installBehaviourGuard()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODSeekerPersonalityGuardInstalled then return false end
    class.LODSeekerPersonalityGuardInstalled = true

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId == "seeker" and self.LODSeekerPolishState then return end
        return baseBehaviourTick(self)
    end
    return true
end

installBehaviourGuard()
hook.Add("OnEntityCreated", "LOD_SeekerPersonalityInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installBehaviourGuard() end
end)

hook.Add("EntityRemoved", "LOD_SeekerPersonalityCleanup", function(ent)
    Personality.Active[ent] = nil
    Personality.PendingFeint[ent] = nil
    Personality.PendingOrbit[ent] = nil
end)

concommand.Add("lod_seeker_personality_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local active = 0
    for seeker in pairs(Personality.Active) do
        if IsValid(seeker) and seeker.LODSeekerPolishState then active = active + 1 end
    end
    local line = string.format(
        "active=%d feints=%d left=%d right=%d orbits=%d cw=%d ccw=%d orbitAborts=%d feintChance=%d%% orbitChance=%d%% service=%s",
        active,
        Personality.Stats.feints or 0,
        Personality.Stats.feintLeft or 0,
        Personality.Stats.feintRight or 0,
        Personality.Stats.orbits or 0,
        Personality.Stats.orbitCW or 0,
        Personality.Stats.orbitCCW or 0,
        Personality.Stats.orbitAborts or 0,
        math.floor(FEINT_CHANCE * 100 + 0.5),
        math.floor(POST_HIT_ORBIT_CHANCE * 100 + 0.5),
        timer.Exists(SERVICE_NAME) and "active" or "idle")
    print("[LOD:SEEKER-PERSONALITY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)