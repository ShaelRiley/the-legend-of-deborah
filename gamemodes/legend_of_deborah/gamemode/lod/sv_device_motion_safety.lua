LOD = LOD or {}

local Motion = LOD.HostileMotionV2
local Navigator = LOD.MazeNavigator
if not Motion or not Navigator or Motion.LODDeviceFloorSafetyInstalled then return end
Motion.LODDeviceFloorSafetyInstalled = true

local DEVICE_ARCHETYPES = {
    watcher = true,
    seeker = true
}

local function graph()
    local state = LOD.RunManager and LOD.RunManager.State
    if not state or not state.Graph or not state.BuildReady or state.Failed or state.LevelCleared then return nil end
    return state.Graph
end

local function normalizeDeviceFloor(hostile, waypoint)
    if not IsValid(hostile) or hostile.LODDead or not DEVICE_ARCHETYPES[hostile.LODArchetypeId] then return end
    if waypoint and waypoint.stair then return end

    local g = graph()
    if not g then return end
    local cell = Navigator:WorldToCell(g, hostile:GetPos())
    if not cell then return end

    local floorPoint = Motion:CellFloorPoint(cell, hostile:GetPos())
    if not floorPoint then return end
    local pos = hostile:GetPos()
    if math.abs(pos.z - floorPoint.z) <= 0.05 then return end

    pos.z = floorPoint.z
    hostile:SetPos(pos)
    hostile:SetAngles(Angle(0, hostile:GetAngles().y, 0))
    hostile.LODMotionLastPos = pos
end

-- Scanner and Rollermine are presentation/shape outliers but still use the same
-- graph-authoritative Motion V2 kernel. Normalize their physical origin to the
-- current graph floor after every non-stair move. This is not another locomotion
-- system: it is a postcondition on the one existing movement operation, with no
-- timer, trace, physics response, or extra pathfinding.
local baseMoveToward = Motion.MoveToward
function Motion:MoveToward(hostile, waypoint)
    local reached = baseMoveToward(self, hostile, waypoint)
    normalizeDeviceFloor(hostile, waypoint)
    return reached
end

-- Attack-state transitions often stop on the same tick that contact/impact is
-- resolved. Apply the same postcondition synchronously there so a charge cannot
-- finish with a Rollermine origin slightly below the authored floor and remain
-- visually/physically stranded while stunned or retreating.
local baseStop = Motion.Stop
function Motion:Stop(hostile)
    baseStop(self, hostile)
    normalizeDeviceFloor(hostile, nil)
end

function Motion:NormalizeDeviceFloor(hostile)
    normalizeDeviceFloor(hostile, nil)
end