LOD = LOD or {}
LOD.UngroundedStallRecovery = LOD.UngroundedStallRecovery or {}

local Recovery = LOD.UngroundedStallRecovery
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator.CellKey

local CHECK_INTERVAL = 0.25
local STALL_SECONDS = 0.80
local MIN_WORLD_TRAVEL = 6
local MAX_STALLED_VERTICAL_SPEED = 14
local RECOVERY_COOLDOWN = 2.50

local SAFE_OFFSETS = {
    Vector(0, 0, 0),
    Vector(64, 0, 0), Vector(-64, 0, 0),
    Vector(0, 64, 0), Vector(0, -64, 0),
    Vector(64, 64, 0), Vector(-64, 64, 0),
    Vector(64, -64, 0), Vector(-64, -64, 0)
}

local function currentWaypoint(hostile)
    local waypoints = hostile.LODWaypoints or {}
    return waypoints[hostile.LODWaypointIndex or 1]
end

local function movementIntent(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead or hostile.LODActivated == false then return false end
    if CurTime() < (hostile.LODHitStunUntil or 0) then return false end
    if hostile.LODSoldierBurst or hostile.LODBioBlast then return false end
    if hostile.LODDeadcrabState == "leaping"
        or hostile.LODDeadcrabState == "latched"
        or hostile.LODDeadcrabState == "detonated"
    then
        return false
    end

    local target = hostile.LODTarget
    local cfg = hostile.LODConfig or {}

    if IsValid(target) and (cfg.meleeRange or 0) > 0 then
        local stopRange = (cfg.meleeRange or 0) + 18
        if hostile:GetPos():DistToSqr(target:GetPos()) <= stopRange * stopRange then return false end
    end

    if IsValid(target) and (cfg.preferredRange or 0) > 0 and hostile._HasLineOfSight then
        local range = cfg.preferredRange
        if hostile:GetPos():DistToSqr(target:GetPos()) <= range * range
            and hostile:_HasLineOfSight(target)
        then
            return false
        end
    end

    local waypoint = currentWaypoint(hostile)
    return (waypoint and waypoint.pos ~= nil) or IsValid(target) or hostile.LODReturningHome == true
end

local function graphAndCell(hostile)
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not Navigator then return nil, nil end
    return graph, Navigator:WorldToCell(graph, hostile:GetPos())
end

local function ignoredDynamicActors()
    local ignored = {}
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(ent) then ignored[#ignored + 1] = ent end
    end
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then ignored[#ignored + 1] = ply end
    end
    return ignored
end

local function hullClear(hostile, candidate, ignored)
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72) end

    local tr = util.TraceHull({
        start = candidate,
        endpos = candidate,
        mins = mins,
        maxs = maxs,
        mask = MASK_NPCSOLID,
        filter = ignored
    })
    return not tr.StartSolid and not tr.AllSolid
end

local function edgeForEndpoint(graph, cell)
    if not graph or not cell then return nil end
    local wanted = cellKey(cell.x, cell.y, cell.z)
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        local ak = edge.a and cellKey(edge.a.x, edge.a.y, edge.a.z)
        local bk = edge.b and cellKey(edge.b.x, edge.b.y, edge.b.z)
        if ak == wanted or bk == wanted then return edge end
    end
    return nil
end

local function nearestAuthoredStairPoint(hostile, graph, cell, ignored)
    local edge = edgeForEndpoint(graph, cell)
    if not edge then return nil end

    local a = graph.Cells[cellKey(edge.a.x, edge.a.y, edge.a.z)] or edge.a
    local b = graph.Cells[cellKey(edge.b.x, edge.b.y, edge.b.z)] or edge.b
    local lower, upper = a.z < b.z and a or b, a.z < b.z and b or a
    local waypoints = Navigator:PathToWaypoints(graph, {lower, upper}) or {}

    local ranked = {}
    for _, waypoint in ipairs(waypoints) do
        if waypoint.stair and waypoint.pos then
            ranked[#ranked + 1] = {
                pos = waypoint.pos,
                distance = hostile:GetPos():DistToSqr(waypoint.pos)
            }
        end
    end
    table.sort(ranked, function(left, right) return left.distance < right.distance end)

    for _, item in ipairs(ranked) do
        for _, lift in ipairs({2, 6, 10, 14, 20}) do
            local candidate = item.pos + Vector(0, 0, lift)
            if hullClear(hostile, candidate, ignored) then return candidate end
        end
    end
    return nil
end

local function tracedCellGround(hostile, graph, cell, ignored)
    local center = Navigator:CellCenter(cell)
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72) end

    local ranked = {}
    for _, offset in ipairs(SAFE_OFFSETS) do
        local x, y = center.x + offset.x, center.y + offset.y
        local tr = util.TraceHull({
            start = Vector(x, y, center.z + 128),
            endpos = Vector(x, y, center.z - 176),
            mins = mins,
            maxs = maxs,
            mask = MASK_SOLID,
            filter = ignored
        })

        if not tr.StartSolid and tr.Hit and tr.HitNormal and tr.HitNormal.z >= 0.65 then
            local candidate = tr.HitPos + Vector(0, 0, 2)
            local resolved = Navigator:WorldToCell(graph, candidate + Vector(0, 0, 8))
            if resolved and cellKey(resolved.x, resolved.y, resolved.z) == cellKey(cell.x, cell.y, cell.z)
                and hullClear(hostile, candidate, ignored)
            then
                ranked[#ranked + 1] = {
                    pos = candidate,
                    distance = hostile:GetPos():DistToSqr(candidate)
                }
            end
        end
    end

    table.sort(ranked, function(left, right) return left.distance < right.distance end)
    return ranked[1] and ranked[1].pos or nil
end

function Recovery:Recover(hostile, reason)
    if not IsValid(hostile) or hostile.LODDead then return false end
    if CurTime() < (hostile.LODUngroundedRecoveryUntil or 0) then return false end

    local graph, cell = graphAndCell(hostile)
    if not graph or not cell then return false end
    local ignored = ignoredDynamicActors()

    -- If the graph says this is a stair endpoint, recover to the exact authored
    -- tread/landing sequence even when the hostile's route metadata has already
    -- advanced to an ordinary waypoint. This is the failure seen in live testing:
    -- waypoint=route, grounded=false, velZ=0, no actual position progress.
    local candidate = nearestAuthoredStairPoint(hostile, graph, cell, ignored)
    local mode = candidate and "authored-stair" or nil

    if not candidate then
        candidate = tracedCellGround(hostile, graph, cell, ignored)
        mode = candidate and "traced-cell-ground" or nil
    end

    if not candidate then
        hostile.LODUngroundedRecoveryUntil = CurTime() + 0.5
        return false
    end

    local before = hostile:GetPos()
    hostile:SetPos(candidate)
    hostile:SetVelocity(vector_origin)
    if hostile.loco then
        if hostile.loco.SetVelocity then hostile.loco:SetVelocity(vector_origin) end
        hostile.loco:ClearStuck()
        if hostile.LODConfig then hostile.loco:SetDesiredSpeed(hostile.LODConfig.speed or 90) end
    end

    hostile.LODWaypoints = {}
    hostile.LODWaypointIndex = 1
    hostile.LODNextRouteRefresh = 0
    hostile.LODNextTargetRefresh = 0
    hostile.LODUngroundedRecoveryUntil = CurTime() + RECOVERY_COOLDOWN
    hostile.LODUngroundedRecoveryCount = (hostile.LODUngroundedRecoveryCount or 0) + 1

    print(string.format(
        "[LOD:UNGROUNDED-RECOVERY] #%d %s reason=%s mode=%s count=%d moved=%.1f",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId), tostring(reason or "stall"),
        tostring(mode), hostile.LODUngroundedRecoveryCount, before:Distance(candidate)
    ))
    return true
end

hook.Add("Think", "LOD_UngroundedStallRecovery", function()
    local now = CurTime()
    if now < (Recovery.NextCheck or 0) then return end
    Recovery.NextCheck = now + CHECK_INTERVAL

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if not IsValid(hostile) or not movementIntent(hostile) then
            if IsValid(hostile) then
                hostile.LODUngroundedSamplePos = nil
                hostile.LODUngroundedSampleTime = nil
            end
        else
            local grounded = hostile.loco and hostile.loco.IsOnGround and hostile.loco:IsOnGround()
            local vz = hostile:GetVelocity().z

            if grounded or math.abs(vz) > MAX_STALLED_VERTICAL_SPEED then
                -- A genuinely falling/jumping actor is not stuck. Only the
                -- grounded=false + near-zero-vZ state accumulates stall time.
                hostile.LODUngroundedSamplePos = hostile:GetPos()
                hostile.LODUngroundedSampleTime = now
            else
                local pos = hostile:GetPos()
                local sample = hostile.LODUngroundedSamplePos
                local sampleTime = hostile.LODUngroundedSampleTime or now

                if not sample then
                    hostile.LODUngroundedSamplePos = pos
                    hostile.LODUngroundedSampleTime = now
                elseif pos:Distance(sample) >= MIN_WORLD_TRAVEL then
                    hostile.LODUngroundedSamplePos = pos
                    hostile.LODUngroundedSampleTime = now
                elseif now - sampleTime >= STALL_SECONDS then
                    Recovery:Recover(hostile, "ungrounded-no-world-progress")
                    hostile.LODUngroundedSamplePos = hostile:GetPos()
                    hostile.LODUngroundedSampleTime = now
                end
            end
        end
    end
end)

concommand.Add("lod_m3_ungrounded_recovery_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile then
            local grounded = hostile.loco and hostile.loco.IsOnGround and hostile.loco:IsOnGround()
            print(string.format(
                "[LOD:UNGROUNDED-STATUS] #%d %s grounded=%s velZ=%.1f recoveries=%d",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId), tostring(grounded),
                hostile:GetVelocity().z, hostile.LODUngroundedRecoveryCount or 0
            ))
        end
    end
end)
