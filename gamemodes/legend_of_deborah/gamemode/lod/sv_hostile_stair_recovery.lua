LOD = LOD or {}
LOD.HostileStairRecovery = LOD.HostileStairRecovery or {}

local Recovery = LOD.HostileStairRecovery

local CHECK_INTERVAL = 0.10
local STUCK_SECONDS = 0.80
local MIN_TRAVEL = 7
local RECOVERY_COOLDOWN = 1.25

local function currentStairAnchor(hostile)
    local waypoints = hostile.LODWaypoints or {}
    local index = hostile.LODWaypointIndex or 1
    local current = waypoints[index]
    if current and current.stair and current.pos then
        return current, "stair"
    end

    -- At the crest the route may already have advanced to the first ordinary
    -- waypoint while the hull is still physically leaving the final landing.
    local previous = waypoints[index - 1]
    if previous and previous.stair and previous.pos
        and hostile:GetPos():DistToSqr(previous.pos) <= (112 * 112)
    then
        return previous, "crest"
    end

    return nil, nil
end

local function hasMovementIntent(hostile)
    if not IsValid(hostile) or hostile.LODDead or hostile.LODActivated == false then return false end
    if CurTime() < (hostile.LODHitStunUntil or 0) then return false end
    if hostile.LODSoldierBurst or hostile.LODBioBlast then return false end
    if hostile.LODDeadcrabState == "latched" or hostile.LODDeadcrabState == "leaping" then return false end

    local target = hostile.LODTarget
    local cfg = hostile.LODConfig

    -- Melee enemies intentionally stop once they are in striking distance.
    if IsValid(target) and cfg and (cfg.meleeRange or 0) > 0 then
        local range = cfg.meleeRange
        if hostile:GetPos():DistToSqr(target:GetPos()) <= range * range then return false end
    end

    -- Ranged archetypes intentionally hold position inside preferred range when
    -- they have line of sight, including the cooldown between attacks.
    if IsValid(target) and cfg and (cfg.preferredRange or 0) > 0 and hostile._HasLineOfSight then
        local range = cfg.preferredRange
        if hostile:GetPos():DistToSqr(target:GetPos()) <= range * range
            and hostile:_HasLineOfSight(target)
        then
            return false
        end
    end

    local waypoints = hostile.LODWaypoints or {}
    local waypoint = waypoints[hostile.LODWaypointIndex or 1]
    if waypoint and waypoint.pos then return true end
    if IsValid(target) then return true end
    return hostile.LODReturningHome == true
end

local function hullClear(hostile, candidate)
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then return false end

    local ignored = {hostile}
    for _, other in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(other) and other ~= hostile then ignored[#ignored + 1] = other end
    end

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

local function stairRecoveryCandidate(hostile)
    local anchor, context = currentStairAnchor(hostile)
    if not anchor then return nil, nil end

    -- Exact stair waypoints are centered over validated tread/landing geometry.
    -- Only lift vertically; never introduce lateral drift into the stair route.
    for _, lift in ipairs({4, 8, 12, 16, 22}) do
        local candidate = anchor.pos + Vector(0, 0, lift)
        if hullClear(hostile, candidate) then return candidate, context end
    end
    return nil, context
end

local function ordinaryCellCandidate(hostile)
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph then return nil, "no-graph" end

    local cell = LOD.MazeNavigator:WorldToCell(graph, hostile:GetPos())
    if not cell then return nil, "no-cell" end
    local center = LOD.MazeNavigator:CellCenter(cell)

    -- Maze cell centers are the graph-authoritative safe interior. Small bounded
    -- offsets give us alternatives if the exact center is occupied by unusual
    -- generated geometry. These never approach the 192-unit cell boundary.
    local offsets = {
        Vector(0, 0, 16),
        Vector(24, 0, 16), Vector(-24, 0, 16),
        Vector(0, 24, 16), Vector(0, -24, 16),
        Vector(24, 24, 16), Vector(-24, 24, 16),
        Vector(24, -24, 16), Vector(-24, -24, 16)
    }

    for _, offset in ipairs(offsets) do
        local candidate = center + offset
        if hullClear(hostile, candidate) then return candidate, "cell" end
    end
    return nil, "cell-blocked"
end

local function recoveryCandidate(hostile)
    local stairCandidate, stairContext = stairRecoveryCandidate(hostile)
    if stairCandidate then return stairCandidate, stairContext end
    return ordinaryCellCandidate(hostile)
end

function Recovery:Recover(hostile, reason)
    if not IsValid(hostile) then return false end
    if CurTime() < (hostile.LODNextGeometryRecovery or 0) then return false end

    local candidate, context = recoveryCandidate(hostile)
    if not candidate then
        hostile.LODNextGeometryRecovery = CurTime() + 0.35
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

    -- Rebuild from the recovered graph position instead of continuing a route
    -- that may have been generated while the hull was embedded in geometry.
    hostile.LODNextRouteRefresh = 0
    hostile.LODNextTargetRefresh = 0
    hostile.LODNextGeometryRecovery = CurTime() + RECOVERY_COOLDOWN
    hostile.LODGeometryRecoveryCount = (hostile.LODGeometryRecoveryCount or 0) + 1
    hostile.LODGeometryRecoveryLastTime = CurTime()
    hostile.LODGeometryRecoveryLastContext = context
    hostile.LODGeometryRecoverySamplePos = candidate
    hostile.LODGeometryRecoveryProgressTime = CurTime()

    print(string.format(
        "[LOD:GEOMETRY-RECOVERY] #%d %s reason=%s context=%s count=%d moved=%.1f",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId), tostring(reason or "no-progress"),
        tostring(context), hostile.LODGeometryRecoveryCount, before:Distance(candidate)
    ))
    return true
end

hook.Add("Think", "LOD_HostileGeometrySelfRecovery", function()
    local now = CurTime()
    if now < (Recovery.NextCheck or 0) then return end
    Recovery.NextCheck = now + CHECK_INTERVAL

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile and hasMovementIntent(hostile) then
            local pos = hostile:GetPos()
            local sample = hostile.LODGeometryRecoverySamplePos

            if not sample then
                hostile.LODGeometryRecoverySamplePos = pos
                hostile.LODGeometryRecoveryProgressTime = now
            elseif pos:Distance(sample) >= MIN_TRAVEL then
                hostile.LODGeometryRecoverySamplePos = pos
                hostile.LODGeometryRecoveryProgressTime = now
            elseif now - (hostile.LODGeometryRecoveryProgressTime or now) >= STUCK_SECONDS then
                Recovery:Recover(hostile, "no-progress")
            end
        elseif IsValid(hostile) then
            -- Intentional stationary states must never accumulate stuck time.
            hostile.LODGeometryRecoverySamplePos = hostile:GetPos()
            hostile.LODGeometryRecoveryProgressTime = now
        end
    end
end)

-- NextBot's native stuck callback used to only clear its flag, which can leave a
-- hull physically embedded in generated wall/floor geometry. Route the callback
-- through the same verified recovery logic as the watchdog.
local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODGeometryRecoveryPatched then return false end
    class.LODGeometryRecoveryPatched = true

    local baseHandleStuck = class.HandleStuck
    function class:HandleStuck()
        if self.LODDead then
            if baseHandleStuck then return baseHandleStuck(self) end
            return
        end
        if not Recovery:Recover(self, "nextbot-stuck") and baseHandleStuck then
            return baseHandleStuck(self)
        end
    end
    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_GeometryRecoveryInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

concommand.Add("lod_m3_geometry_recovery_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local found = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile then
            found = found + 1
            local stairAnchor, stairContext = currentStairAnchor(hostile)
            local text = string.format(
                "#%d %s size=%.3f context=%s recoveryCount=%d last=%s",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                hostile:GetNW2Float("LOD_SizeScale", 1),
                tostring(stairAnchor and stairContext or "ordinary"),
                hostile.LODGeometryRecoveryCount or 0,
                tostring(hostile.LODGeometryRecoveryLastContext or "none")
            )
            print("[LOD:GEOMETRY-RECOVERY] " .. text)
            if IsValid(ply) then ply:ChatPrint(text) end
        end
    end
    if found == 0 then
        print("[LOD:GEOMETRY-RECOVERY] no live hostiles")
        if IsValid(ply) then ply:ChatPrint("no live hostiles") end
    end
end)

-- Backward-compatible alias while Milestone 3 stair testing is still active.
concommand.Add("lod_m3_stair_recovery_status", function(ply)
    RunConsoleCommand("lod_m3_geometry_recovery_status")
end)
