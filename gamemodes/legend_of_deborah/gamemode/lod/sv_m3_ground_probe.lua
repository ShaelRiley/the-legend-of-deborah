LOD = LOD or {}

-- On-demand diagnostic for the current Milestone-3 locomotion fault. This does
-- no autonomous polling and makes no movement changes; it only inspects the
-- nearest live hostile when explicitly invoked from the developer console.
local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return false end
    return IsValid(ply)
end

local function nearestHostile(ply)
    local nearest, nearestDist
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead then
            local d = hostile:GetPos():DistToSqr(ply:GetPos())
            if not nearestDist or d < nearestDist then
                nearest, nearestDist = hostile, d
            end
        end
    end
    return nearest
end

local function entLabel(ent)
    if not IsValid(ent) then return "none" end
    if ent:IsWorld() then return "world" end
    return ent:GetClass() or tostring(ent)
end

local function traceLabel(tr)
    if not tr or not tr.Hit then return "none" end
    if tr.HitWorld then return "world" end
    return entLabel(tr.Entity)
end

local function waypointInfo(hostile)
    local waypoints = hostile.LODWaypoints or {}
    local waypoint = waypoints[hostile.LODWaypointIndex or 1]
    if not waypoint or not waypoint.pos then return "none", nil end
    return waypoint.stair and "stair" or "route", waypoint.pos.z
end

concommand.Add("lod_m3_ground_probe", function(ply)
    if not developerAllowed(ply) then return end

    local hostile = nearestHostile(ply)
    if not IsValid(hostile) then
        print("[LOD:GROUND-PROBE] none")
        return
    end

    local pos = hostile:GetPos()
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then
        mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72)
    end

    local ignored = {hostile}
    local line = util.TraceLine({
        start = pos + Vector(0, 0, 64),
        endpos = pos - Vector(0, 0, 96),
        mask = MASK_SOLID,
        filter = ignored
    })
    local hull = util.TraceHull({
        start = pos + Vector(0, 0, 64),
        endpos = pos - Vector(0, 0, 96),
        mins = mins,
        maxs = maxs,
        mask = MASK_NPCSOLID,
        filter = ignored
    })

    local graph = LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.Graph
    local cell = graph and LOD.MazeNavigator and LOD.MazeNavigator:WorldToCell(graph, pos) or nil
    local floorZ = cell and LOD.MazeNavigator:CellCenter(cell).z or nil
    local waypointType, waypointZ = waypointInfo(hostile)
    local locoGround = hostile.loco and hostile.loco.IsOnGround and hostile.loco:IsOnGround() or false
    local groundEntity = hostile.GetGroundEntity and hostile:GetGroundEntity() or NULL

    print(string.format(
        "[LOD:GROUND-PROBE] #%d %s size=%.3f entityGround=%s locoGround=%s groundEnt=%s lineHit=%s lineDZ=%.1f hullHit=%s hullDZ=%.1f startSolid=%s posZ=%.1f floorZ=%s waypoint=%s waypointZ=%s vel2D=%.1f velZ=%.1f",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId), hostile:GetNW2Float("LOD_SizeScale", 1),
        tostring(hostile:IsOnGround()), tostring(locoGround), entLabel(groundEntity),
        traceLabel(line), line.Hit and (pos.z - line.HitPos.z) or -999,
        traceLabel(hull), hull.Hit and (pos.z - hull.HitPos.z) or -999, tostring(hull.StartSolid),
        pos.z, floorZ and string.format("%.1f", floorZ) or "none",
        waypointType, waypointZ and string.format("%.1f", waypointZ) or "none",
        hostile:GetVelocity():Length2D(), hostile:GetVelocity().z
    ))
end)
