LOD = LOD or {}
LOD.M3GroundingPathFix = LOD.M3GroundingPathFix or {}

local EncounterDirector = LOD.EncounterDirector

-- Runtime probing established a stable model/engine invariant for the humanoid
-- roster: the visible foot plane sits about 24 Source units above GetPos().z on
-- the generated maze. Keep that offset as coordinate metadata for routing and
-- diagnostics. It is NOT a collision-bounds offset.
LOD.HumanoidFootOffset = LOD.HumanoidFootOffset or 24

-- Important follow-up evidence: moving the collision bounds upward by 24 did not
-- move the physical foot plane upward. Source simply settled the NextBot origin
-- another ~24 units downward, preserving the same bad contact state. Therefore
-- SetCollisionBounds is not the knob that defines humanoid NextBot ground contact
-- here. Restore the native fixed movement bounds that previously proved stable;
-- visual scale and firearm combat volume remain independent.
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

-- Diagnostic only. This is the authored physical floor plane. Never force a live
-- NextBot origin to this Z: its model-space foot plane is offset from GetPos().z.
local function graphFloorZ(hostile)
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph or not LOD.MazeNavigator then return nil, nil end

    local cell = LOD.MazeNavigator:WorldToCell(graph, hostile:GetPos())
    if not cell then return nil, nil end
    local center = LOD.MazeNavigator:CellCenter(cell)
    return center and center.z or nil, cell
end

local function settleUsingSource(hostile)
    if not IsValid(hostile) or hostile.LODDead then return end
    stableLocomotionBounds(hostile)

    if hostile.LODDeadcrabState == "leaping" or hostile.LODDeadcrabState == "latched" then return end
    if activeStairContext(hostile) then return end

    -- Preserve Source's native local settlement. Ground registration on generated
    -- static boxes is handled separately by sv_hostile_ground_bridge.lua.
    hostile:DropToFloor()
    if hostile.loco then hostile.loco:ClearStuck() end
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
            settleUsingSource(self)
            self.LODNextRouteRefresh = 0
            self.LODNextTargetRefresh = 0
        end)
    end

    function class:HandleStuck()
        if self.LODDead then return end

        if activeStairContext(self) and LOD.HostileStairRecovery and LOD.HostileStairRecovery.Recover then
            if LOD.HostileStairRecovery:Recover(self, "nextbot-stair-stuck") then return end
        end

        settleUsingSource(self)
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

-- Historical Z watchdogs remain disabled. They fought Source settlement and are
-- intentionally not part of the new generated-ground registration bridge.
hook.Remove("Think", "LOD_HostileGeometrySelfRecovery")
hook.Remove("Think", "LOD_HostileAuthoritativeFloorLock")

-- Encounter spawns may be physically relocated away from stair endpoint cells,
-- but that safety choice must never change the logical home used by leash logic.
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
                    settleUsingSource(hostile)
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
            local floorZ = graphFloorZ(hostile)
            local delta = floorZ ~= nil and (hostile:GetPos().z - floorZ) or nil
            local text = string.format(
                "#%d %s size=%.3f posZ=%.1f graphFloorZ=%s delta=%s hullZ=%.1f..%.1f home=%s encounter=%s wanderer=%s",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                hostile:GetNW2Float("LOD_SizeScale", 1), hostile:GetPos().z,
                floorZ ~= nil and string.format("%.1f", floorZ) or "n/a",
                delta ~= nil and string.format("%.1f", delta) or "n/a",
                mins and mins.z or 0, maxs and maxs.z or 0,
                tostring(hostile.LODHomeCellKey or "none"),
                tostring(hostile.LODEncounterId or "debug"),
                tostring(hostile.LODWanderer == true)
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
