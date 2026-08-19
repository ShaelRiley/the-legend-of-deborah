LOD = LOD or {}
LOD.HostileNoProgressRecovery = LOD.HostileNoProgressRecovery or {}

local CHECK_INTERVAL = 0.25
local STALL_SECONDS = 1.10
local MIN_PROGRESS_2D = 8
local RECOVERY_COOLDOWN = 2.50
local nextCheck = 0
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator.CellKey

local function currentWaypoint(hostile)
    local waypoints = hostile.LODWaypoints or {}
    return waypoints[hostile.LODWaypointIndex or 1]
end

local function intentionalStationary(hostile)
    if hostile.LODDead or hostile.LODActivated == false then return true end
    if hostile.LODHitStunUntil and CurTime() < hostile.LODHitStunUntil then return true end
    if hostile.LODSoldierBurst then return true end
    if hostile.LODBioBlast then return true end
    if hostile.LODDeadcrabState == "leaping"
        or hostile.LODDeadcrabState == "latched"
        or hostile.LODDeadcrabState == "detonated"
    then
        return true
    end

    -- Never interpret an actually airborne/falling NextBot as horizontally
    -- stuck. Recovery must wait until Source says locomotion is grounded.
    if hostile.loco and hostile.loco.IsOnGround and not hostile.loco:IsOnGround() then
        return true
    end

    local waypoint = currentWaypoint(hostile)
    if waypoint and waypoint.stair then return true end

    local target = hostile.LODTarget
    local cfg = hostile.LODConfig or {}
    if IsValid(target) and (cfg.meleeRange or 0) > 0 then
        local stopRange = (cfg.meleeRange or 0) + 18
        if hostile:GetPos():DistToSqr(target:GetPos()) <= stopRange * stopRange then
            return true
        end
    end
    return false
end

local function shouldBeMoving(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or intentionalStationary(hostile) then return false end
    if currentWaypoint(hostile) then return true end
    if IsValid(hostile.LODTarget) then return true end
    return false
end

local function dist2D(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function graphAndCell(hostile)
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not Navigator then return nil, nil end
    return graph, Navigator:WorldToCell(graph, hostile:GetPos())
end

local function isVerticalEndpoint(graph, cell)
    if not graph or not cell then return false end
    local wanted = cellKey(cell.x, cell.y, cell.z)
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        local a = edge.a and cellKey(edge.a.x, edge.a.y, edge.a.z)
        local b = edge.b and cellKey(edge.b.x, edge.b.y, edge.b.z)
        if a == wanted or b == wanted then return true end
    end
    return false
end

local SAFE_OFFSETS = {
    Vector(0, 0, 0),
    Vector(64, 0, 0), Vector(-64, 0, 0),
    Vector(0, 64, 0), Vector(0, -64, 0),
    Vector(64, 64, 0), Vector(-64, 64, 0),
    Vector(64, -64, 0), Vector(-64, -64, 0)
}

local function ignoredHostiles()
    local ignored = {}
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(ent) then ignored[#ignored + 1] = ent end
    end
    return ignored
end

local function safeGroundCandidate(hostile, graph, cell, offset, ignored)
    local center = Navigator:CellCenter(cell)
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then
        mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72)
    end

    local x = center.x + offset.x
    local y = center.y + offset.y
    local currentZ = hostile:GetPos().z

    -- The trace is validation only. Earlier code mistakenly returned its high
    -- start point and teleported recovering enemies into the sky. Preserve the
    -- entity's current native grounded Z when moving within the same flat cell.
    local traceStartZ = math.max(currentZ + 48, center.z + 48)
    local traceEndZ = math.min(currentZ - 96, center.z - 128)
    local tr = util.TraceHull({
        start = Vector(x, y, traceStartZ),
        endpos = Vector(x, y, traceEndZ),
        mins = mins,
        maxs = maxs,
        mask = MASK_SOLID,
        filter = ignored
    })

    if tr.StartSolid or not tr.Hit then return nil end

    -- Confirm the candidate belongs to this exact logical cell. This prevents
    -- recovery from crossing a wall/gate or changing floors.
    local probe = tr.HitPos + Vector(0, 0, 8)
    local resolved = Navigator:WorldToCell(graph, probe)
    if not resolved or cellKey(resolved.x, resolved.y, resolved.z) ~= cellKey(cell.x, cell.y, cell.z) then
        return nil
    end

    -- Check the candidate at the hostile's current Source-owned ground-relative
    -- Z. We only want a horizontal escape from wall/corner wedging.
    local candidate = Vector(x, y, currentZ)
    local occupancy = util.TraceHull({
        start = candidate,
        endpos = candidate,
        mins = mins,
        maxs = maxs,
        mask = MASK_SOLID,
        filter = ignored
    })
    if occupancy.StartSolid or occupancy.Hit then return nil end

    return candidate
end

local function recoverInsideCurrentCell(hostile)
    local graph, cell = graphAndCell(hostile)
    if not graph or not cell or isVerticalEndpoint(graph, cell) then return false end

    local ignored = ignoredHostiles()
    local candidates = {}
    for _, offset in ipairs(SAFE_OFFSETS) do
        local pos = safeGroundCandidate(hostile, graph, cell, offset, ignored)
        if pos then
            candidates[#candidates + 1] = {
                pos = pos,
                distance = dist2D(hostile:GetPos(), pos)
            }
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    local chosen = candidates[1]
    if not chosen then return false end

    hostile:SetPos(chosen.pos)
    -- Source owns final ground settlement. Because X/Y changed but Z did not,
    -- DropToFloor only needs to resolve a local same-floor contact rather than a
    -- large artificial fall.
    hostile:DropToFloor()
    return true
end

local function recover(hostile)
    if not IsValid(hostile) or hostile.LODDead then return end

    local moved = recoverInsideCurrentCell(hostile)
    if not moved then
        -- Safe fallback for stair endpoints or unusual geometry: do not move XY.
        hostile:DropToFloor()
    end

    if hostile.loco then hostile.loco:ClearStuck() end
    hostile.LODNextRouteRefresh = 0
    hostile.LODNextTargetRefresh = 0
    hostile.LODWaypoints = {}
    hostile.LODWaypointIndex = 1
    hostile.LODNoProgressRecoveries = (hostile.LODNoProgressRecoveries or 0) + 1
    hostile.LODNoProgressRecoveryUntil = CurTime() + RECOVERY_COOLDOWN

    print(string.format(
        "[LOD:NO-PROGRESS] #%d %s recovered mode=%s count=%d",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId),
        moved and "same-cell-horizontal" or "source-drop-in-place",
        hostile.LODNoProgressRecoveries
    ))
end

hook.Add("Think", "LOD_HostileNoProgressRecovery", function()
    local now = CurTime()
    if now < nextCheck then return end
    nextCheck = now + CHECK_INTERVAL

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if shouldBeMoving(hostile) then
            local pos = hostile:GetPos()
            local sample = hostile.LODProgressSamplePos
            local sampleTime = hostile.LODProgressSampleTime or now

            if not sample then
                hostile.LODProgressSamplePos = pos
                hostile.LODProgressSampleTime = now
            elseif dist2D(pos, sample) >= MIN_PROGRESS_2D then
                hostile.LODProgressSamplePos = pos
                hostile.LODProgressSampleTime = now
            elseif now - sampleTime >= STALL_SECONDS
                and now >= (hostile.LODNoProgressRecoveryUntil or 0)
            then
                recover(hostile)
                hostile.LODProgressSamplePos = hostile:GetPos()
                hostile.LODProgressSampleTime = now
            end
        else
            hostile.LODProgressSamplePos = nil
            hostile.LODProgressSampleTime = nil
        end
    end
end)

local function statusLine(hostile)
    local graph, cell = graphAndCell(hostile)
    local waypoint = currentWaypoint(hostile)
    local grounded = hostile.loco and hostile.loco.IsOnGround and hostile.loco:IsOnGround()
    return string.format(
        "#%d %s size=%.3f cell=%s pos=(%.1f,%.1f,%.1f) vel2D=%.1f velZ=%.1f grounded=%s recoveries=%d expectedMove=%s target=%s waypoint=%s encounter=%s wanderer=%s",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId),
        hostile:GetNW2Float("LOD_SizeScale", 1),
        cell and cellKey(cell.x, cell.y, cell.z) or "none",
        hostile:GetPos().x, hostile:GetPos().y, hostile:GetPos().z,
        hostile:GetVelocity():Length2D(), hostile:GetVelocity().z, tostring(grounded),
        hostile.LODNoProgressRecoveries or 0,
        tostring(shouldBeMoving(hostile)),
        IsValid(hostile.LODTarget) and ("#" .. hostile.LODTarget:EntIndex()) or "none",
        waypoint and (waypoint.stair and "stair" or "route") or "none",
        tostring(hostile.LODEncounterId or "none"), tostring(hostile.LODWanderer == true)
    )
end

concommand.Add("lod_m3_no_progress_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile then
            print("[LOD:NO-PROGRESS-STATUS] " .. statusLine(hostile))
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

    if not IsValid(nearest) then
        print("[LOD:NEAREST-HOSTILE] none")
        return
    end
    print("[LOD:NEAREST-HOSTILE] " .. statusLine(nearest))
end)
