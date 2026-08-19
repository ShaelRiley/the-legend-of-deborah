LOD = LOD or {}
LOD.M3GroundingPathFix = LOD.M3GroundingPathFix or {}

local Fix = LOD.M3GroundingPathFix
local EncounterDirector = LOD.EncounterDirector

local FLOOR_CHECK_INTERVAL = 0.05
local FLOOR_DRIFT_TOLERANCE = 3.0
local nextFloorCheck = 0

-- Runtime testing showed that varying the NextBot movement hull together with
-- visual enemy size is unsafe on generated Source collision. Restore the exact
-- pre-variance locomotion hulls that already passed ordinary corridor/stair
-- traversal. Visual scale, firearm combat volume, HP, damage, speed, cadence,
-- and range variation remain independent of these movement bounds.
local function stableLocomotionBounds(hostile)
    if not IsValid(hostile) or not hostile.LODHostile then return end

    if hostile.LODArchetypeId == "deadcrab" then
        hostile:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 30))
    else
        hostile:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
    end
end

local function activeStairContext(hostile)
    local waypoints = hostile.LODWaypoints or {}
    local index = hostile.LODWaypointIndex or 1
    local current = waypoints[index]
    if current and current.stair then return true end

    local previous = waypoints[index - 1]
    if previous and previous.stair and previous.pos
        and hostile:GetPos():DistToSqr(previous.pos) <= 112 * 112
    then
        return true
    end
    return false
end

local function canGroundLock(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead then return false end
    if activeStairContext(hostile) then return false end
    if hostile.LODDeadcrabState == "leaping" or hostile.LODDeadcrabState == "latched" then return false end
    return true
end

local function authoritativeFloor(hostile)
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not LOD.MazeNavigator then return nil, nil end

    local cell = LOD.MazeNavigator:WorldToCell(graph, hostile:GetPos())
    if not cell then return nil, nil end
    local center = LOD.MazeNavigator:CellCenter(cell)
    return center and center.z or nil, cell
end

local function snapToKnownFloor(hostile, reason)
    if not canGroundLock(hostile) then return false end
    local floorZ = authoritativeFloor(hostile)
    if floorZ == nil then return false end

    local pos = hostile:GetPos()
    if math.abs(pos.z - floorZ) <= FLOOR_DRIFT_TOLERANCE then return false end

    hostile:SetPos(Vector(pos.x, pos.y, floorZ))
    if hostile.loco then hostile.loco:ClearStuck() end
    hostile.LODNextRouteRefresh = 0
    hostile.LODNextTargetRefresh = 0
    hostile.LODGroundCorrectionCount = (hostile.LODGroundCorrectionCount or 0) + 1
    hostile.LODGroundCorrectionReason = reason or "floor-drift"
    hostile.LODGroundCorrectionLastZ = pos.z
    hostile.LODGroundCorrectionFloorZ = floorZ

    print(string.format(
        "[LOD:GROUND-CORRECT] #%d %s reason=%s fromZ=%.1f floorZ=%.1f count=%d",
        hostile:EntIndex(), tostring(hostile.LODArchetypeId),
        tostring(reason or "floor-drift"), pos.z, floorZ,
        hostile.LODGroundCorrectionCount
    ))
    return true
end

local function settleOnFloor(hostile)
    if not IsValid(hostile) or hostile.LODDead then return end
    stableLocomotionBounds(hostile)

    -- Prefer the maze graph's exact authored floor plane over DropToFloor/trace
    -- inference. All ordinary cell floors are generated at CellCenter(cell).z.
    if snapToKnownFloor(hostile, "spawn-settle") then return end

    -- During very early initialization the graph may not yet be queryable. Keep
    -- a conservative fallback for that exceptional case only; the continuous
    -- authoritative floor watchdog below will correct the entity once the graph
    -- becomes available.
    if not (LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.Graph) then
        hostile:DropToFloor()
        if hostile.loco then hostile.loco:ClearStuck() end
    end
end

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODM3GroundingPatched then return false end
    class.LODM3GroundingPatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if not IsValid(self) or not self.LODHostile then return end
        stableLocomotionBounds(self)

        timer.Simple(0, function()
            if not IsValid(self) or self.LODDead then return end
            stableLocomotionBounds(self)
            settleOnFloor(self)
            self.LODNextRouteRefresh = 0
        end)
    end

    -- Ordinary-cell stuck recovery must not teleport an enemy sideways or choose
    -- a guessed elevation. Clear the native stuck flag, put the entity back on
    -- its exact logical floor if necessary, and rebuild the route in place.
    -- Stair recovery remains separate because stairs have validated tread-center
    -- waypoints at deliberately changing Z values.
    function class:HandleStuck()
        if self.LODDead then return end

        if activeStairContext(self) and LOD.HostileStairRecovery and LOD.HostileStairRecovery.Recover then
            if LOD.HostileStairRecovery:Recover(self, "nextbot-stair-stuck") then return end
        end

        snapToKnownFloor(self, "nextbot-stuck")
        if self.loco then self.loco:ClearStuck() end
        self.LODNextRouteRefresh = 0
        self.LODNextTargetRefresh = 0
    end

    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_M3GroundingInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

-- The old generalized recovery watchdog teleported enemies to guessed cell
-- positions. Keep it disabled. Exact Z-only floor anchoring below is safer and
-- cannot move a hostile across walls, gates, or progression boundaries.
hook.Remove("Think", "LOD_HostileGeometrySelfRecovery")

-- Generated maze floors have an exact graph-authored elevation. On ordinary
-- cells, enforce that plane if Source locomotion drifts by more than a few units.
-- This directly prevents small/fast visual variants from progressively walking
-- into custom floor collision. Stair traversal and Deadcrab airborne states are
-- excluded because their Z is intentionally dynamic.
hook.Add("Think", "LOD_HostileAuthoritativeFloorLock", function()
    local now = CurTime()
    if now < nextFloorCheck then return end
    nextFloorCheck = now + FLOOR_CHECK_INTERVAL

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if canGroundLock(hostile) then
            local floorZ = authoritativeFloor(hostile)
            if floorZ ~= nil and math.abs(hostile:GetPos().z - floorZ) > FLOOR_DRIFT_TOLERANCE then
                snapToKnownFloor(hostile, "runtime-floor-drift")
            end
        end
    end
end)

-- Encounter spawns may be physically relocated away from stair endpoint cells,
-- but that physical safety decision must never change the logical home region
-- used by leash and pursuit behavior. Also settle authored enemies to the exact
-- floor after the final encounter wrapper has completed its spawn work.
if EncounterDirector and not EncounterDirector.LODM3HomeCellCorrected then
    EncounterDirector.LODM3HomeCellCorrected = true
    local baseSpawnEncounter = EncounterDirector._SpawnEncounter

    function EncounterDirector:_SpawnEncounter(encounter)
        local result = baseSpawnEncounter(self, encounter)
        if encounter and encounter.cellKey then
            for _, hostile in ipairs(encounter.entities or {}) do
                if IsValid(hostile) and hostile.LODHostile then
                    hostile.LODHomeCellKey = encounter.cellKey
                    stableLocomotionBounds(hostile)
                    settleOnFloor(hostile)
                    hostile.LODNextTargetRefresh = 0
                    hostile.LODNextRouteRefresh = 0
                end
            end
        end
        return result
    end
end

concommand.Add("lod_m3_grounding_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local found = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile then
            found = found + 1
            local mins, maxs = hostile:GetCollisionBounds()
            local floorZ = authoritativeFloor(hostile)
            local text = string.format(
                "#%d %s size=%.3f posZ=%.1f floorZ=%s hullZ=%.1f..%.1f corrections=%d home=%s encounter=%s",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                hostile:GetNW2Float("LOD_SizeScale", 1), hostile:GetPos().z,
                floorZ ~= nil and string.format("%.1f", floorZ) or "n/a",
                mins and mins.z or 0, maxs and maxs.z or 0,
                hostile.LODGroundCorrectionCount or 0,
                tostring(hostile.LODHomeCellKey or "none"),
                tostring(hostile.LODEncounterId or "debug")
            )
            print("[LOD:GROUNDING] " .. text)
            if IsValid(ply) then ply:ChatPrint(text) end
        end
    end
    if found == 0 then
        print("[LOD:GROUNDING] no live hostiles")
        if IsValid(ply) then ply:ChatPrint("no live hostiles") end
    end
end)
