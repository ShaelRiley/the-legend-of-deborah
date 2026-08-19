LOD = LOD or {}
LOD.HostileNoProgressRecovery = LOD.HostileNoProgressRecovery or {}

-- The older autonomous ungrounded watcher used loco:IsOnGround() as its primary
-- signal. Runtime evidence showed that generated floors can report grounded=false
-- for many perfectly ordinary NextBots, creating a recovery/trace/console storm.
-- Keep its topology-safe recovery routine available, but make this actual-world-
-- displacement watcher the sole authority for deciding WHEN a recovery is needed.
hook.Remove("Think", "LOD_UngroundedStallRecovery")

local CHECK_INTERVAL = 0.25
local STALL_SECONDS = 1.10
local MIN_PROGRESS_2D = 8
local RECOVERY_COOLDOWN = 2.50
local MAX_INTENTIONAL_VERTICAL_SPEED = 30
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

    -- Do not recover a genuinely falling actor mid-flight. Ordinary humanoids
    -- have zero autonomous jump height, so near-zero vertical speed is NOT a
    -- legitimate reason to ignore a world-position stall.
    if math.abs(hostile:GetVelocity().z) > MAX_INTENTIONAL_VERTICAL_SPEED then
        return true
    end

    local target = hostile.LODTarget
    local cfg = hostile.LODConfig or {}

    if IsValid(target) and (cfg.meleeRange or 0) > 0 then
        local stopRange = (cfg.meleeRange or 0) + 18
        if hostile:GetPos():DistToSqr(target:GetPos()) <= stopRange * stopRange then
            return true
        end
    end

    -- Ranged enemies intentionally hold their ground inside preferred range
    -- between attacks. Without this, their normal cooldown can masquerade as a
    -- locomotion stall.
    if IsValid(target) and (cfg.preferredRange or 0) > 0 and hostile._HasLineOfSight then
        local range = cfg.preferredRange
        if hostile:GetPos():DistToSqr(target:GetPos()) <= range * range
            and hostile:_HasLineOfSight(target)
        then
            return true
        end
    end

    return false
end

local function shouldBeMoving(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or intentionalStationary(hostile) then return false end
    if currentWaypoint(hostile) then return true end
    if IsValid(hostile.LODTarget) then return true end
    return hostile.LODReturningHome == true
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

local function safeGroundCandidate(hostile, graph, cell, offset, ignored)
    local center = Navigator:CellCenter(cell)
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then
        mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72)
    end

    local x = center.x + offset.x
    local y = center.y + offset.y
    local currentZ = hostile:GetPos().z

    -- Find the actual physical floor under a conservative interior point of the
    -- current logical cell. The hull trace's HitPos is the hostile-origin
    -- position at which its mins.z touches that floor; unlike earlier versions,
    -- we keep this grounded result instead of preserving an already-buried Z.
    local traceStartZ = math.max(currentZ + 96, center.z + 96)
    local traceEndZ = math.min(currentZ - 128, center.z - 160)
    local tr = util.TraceHull({
        start = Vector(x, y, traceStartZ),
        endpos = Vector(x, y, traceEndZ),
        mins = mins,
        maxs = maxs,
        mask = MASK_SOLID,
        filter = ignored
    })

    if tr.StartSolid or not tr.Hit or not tr.HitNormal or tr.HitNormal.z < 0.65 then return nil end

    local candidate = tr.HitPos + Vector(0, 0, 2)

    -- Confirm the grounded candidate still belongs to this exact logical cell.
    -- Recovery can never cross a wall, gate, staircase transition, or floor.
    local probe = candidate + Vector(0, 0, 8)
    local resolved = Navigator:WorldToCell(graph, probe)
    if not resolved or cellKey(resolved.x, resolved.y, resolved.z) ~= cellKey(cell.x, cell.y, cell.z) then
        return nil
    end

    local occupancy = util.TraceHull({
        start = candidate,
        endpos = candidate,
        mins = mins,
        maxs = maxs,
        mask = MASK_SOLID,
        filter = ignored
    })
    if occupancy.StartSolid then return nil end

    return candidate
end

local function recoverInsideCurrentCell(hostile)
    local graph, cell = graphAndCell(hostile)
    if not graph or not cell or isVerticalEndpoint(graph, cell) then return false end

    local ignored = ignoredDynamicActors()
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
    if hostile.loco and hostile.loco.SetVelocity then hostile.loco:SetVelocity(vector_origin) end
    hostile.LODLastRecoveryGroundZ = chosen.pos.z
    return true
end

local function finishRecoveryBookkeeping(hostile, mode)
    if hostile.loco then hostile.loco:ClearStuck() end
    hostile.LODNextRouteRefresh = 0
    hostile.LODNextTargetRefresh = 0
    hostile.LODWaypoints = {}
    hostile.LODWaypointIndex = 1
    hostile.LODNoProgressRecoveries = (hostile.LODNoProgressRecoveries or 0) + 1
    hostile.LODNoProgressRecoveryUntil = CurTime() + RECOVERY_COOLDOWN

    print(string.format(
        "[LOD:NO-PROGRESS] #%d %s recovered mode=%s count=%d",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId), tostring(mode),
        hostile.LODNoProgressRecoveries
    ))
end

local function recover(hostile)
    if not IsValid(hostile) or hostile.LODDead then return end

    -- This routine knows the authored stair treads/landings and performs a
    -- physically traced same-cell recovery elsewhere. It is now invoked only
    -- after actual world-position stasis, never merely because Source reports
    -- IsOnGround() == false.
    local topologyRecovery = LOD.UngroundedStallRecovery
    if topologyRecovery and topologyRecovery.Recover
        and topologyRecovery:Recover(hostile, "world-position-stall")
    then
        finishRecoveryBookkeeping(hostile, "topology-safe")
        return
    end

    local moved = recoverInsideCurrentCell(hostile)
    if not moved then
        -- If no verified relocation exists, ask Source to settle locally rather
        -- than guessing another cell/floor position.
        hostile:DropToFloor()
    end

    finishRecoveryBookkeeping(hostile, moved and "same-cell-traced-ground" or "source-drop-in-place")
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
        "#%d %s size=%.3f cell=%s pos=(%.1f,%.1f,%.1f) vel2D=%.1f velZ=%.1f grounded=%s recoveries=%d topologyRecoveries=%d expectedMove=%s target=%s waypoint=%s encounter=%s wanderer=%s lastRecoveryGroundZ=%s",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId),
        hostile:GetNW2Float("LOD_SizeScale", 1),
        cell and cellKey(cell.x, cell.y, cell.z) or "none",
        hostile:GetPos().x, hostile:GetPos().y, hostile:GetPos().z,
        hostile:GetVelocity():Length2D(), hostile:GetVelocity().z, tostring(grounded),
        hostile.LODNoProgressRecoveries or 0,
        hostile.LODUngroundedRecoveryCount or 0,
        tostring(shouldBeMoving(hostile)),
        IsValid(hostile.LODTarget) and ("#" .. hostile.LODTarget:EntIndex()) or "none",
        waypoint and (waypoint.stair and "stair" or "route") or "none",
        tostring(hostile.LODEncounterId or "none"), tostring(hostile.LODWanderer == true),
        hostile.LODLastRecoveryGroundZ and string.format("%.1f", hostile.LODLastRecoveryGroundZ) or "none"
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
