LOD = LOD or {}
LOD.M3GroundingPathFix = LOD.M3GroundingPathFix or {}

local Fix = LOD.M3GroundingPathFix
local EncounterDirector = LOD.EncounterDirector

-- Visual enemy scale can vary dramatically, but Source NextBot locomotion becomes
-- unreliable when its vertical movement hull is shrunk to the same extreme size.
-- Keep a grounded, archetype-appropriate vertical locomotion profile while still
-- allowing conservative horizontal size variation. Player firearm hit volume is
-- handled separately by sv_hostile_combat_hulls.lua and continues to follow the
-- visible model scale.
local function stableLocomotionBounds(hostile)
    if not IsValid(hostile) or not hostile.LODHostile then return end

    local size = math.Clamp(hostile:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local archetype = hostile.LODArchetypeId

    local baseHalfWidth = archetype == "deadcrab" and 14 or 16
    local baseHeight = archetype == "deadcrab" and 30 or 72

    -- Do not let tiny visual variants collapse the locomotion footprint into a
    -- floor-penetrating sliver. Large variants grow somewhat in width, but the
    -- vertical hull stays fixed so its origin/feet remain stable on Source floors.
    local widthScale = math.Clamp(size, 0.75, 1.20)
    local halfWidth = baseHalfWidth * widthScale
    hostile:SetCollisionBounds(
        Vector(-halfWidth, -halfWidth, 0),
        Vector(halfWidth, halfWidth, baseHeight)
    )
end

local function settleOnFloor(hostile)
    if not IsValid(hostile) or hostile.LODDead then return end

    -- The NextBot origin is treated as its foot point. Trace the generated world
    -- directly beneath it after final scale/hull setup, then settle from a small
    -- positive clearance. This is spawn-time only; normal locomotion owns Z after.
    local origin = hostile:GetPos()
    local ignored = {hostile}
    for _, other in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(other) and other ~= hostile then ignored[#ignored + 1] = other end
    end

    local tr = util.TraceLine({
        start = origin + Vector(0, 0, 64),
        endpos = origin - Vector(0, 0, 160),
        mask = MASK_NPCSOLID,
        filter = ignored
    })

    if tr.Hit and not tr.StartSolid then
        hostile:SetPos(Vector(origin.x, origin.y, tr.HitPos.z + 2))
    end
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
            settleOnFloor(self)
            self.LODNextRouteRefresh = 0
        end)
    end

    -- Undo the generalized ordinary-cell teleport recovery. If Source reports a
    -- stuck state in ordinary maze geometry, clear the locomotor flag and rebuild
    -- the graph route in place. Stair recovery remains allowed because its exact
    -- centerline waypoints were previously validated for traversal.
    function class:HandleStuck()
        if self.LODDead then return end

        local waypoints = self.LODWaypoints or {}
        local index = self.LODWaypointIndex or 1
        local current = waypoints[index]
        local previous = waypoints[index - 1]
        local onStair = (current and current.stair) or
            (previous and previous.stair and previous.pos and self:GetPos():DistToSqr(previous.pos) <= 112 * 112)

        if onStair and LOD.HostileStairRecovery and LOD.HostileStairRecovery.Recover then
            if LOD.HostileStairRecovery:Recover(self, "nextbot-stair-stuck") then return end
        end

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

-- The previous generalized watchdog could teleport an ordinary moving enemy to
-- an arbitrary cell-center candidate. That was able to place scaled models at a
-- visually incorrect floor height, so disable it. Native HandleStuck above still
-- recovers route state, with explicit teleport recovery reserved for stairs.
hook.Remove("Think", "LOD_HostileGeometrySelfRecovery")

-- Encounter spawns may be physically relocated away from stair endpoint cells,
-- but that physical safety decision must never change the logical home region
-- used by leash and pursuit behavior.
if EncounterDirector and not EncounterDirector.LODM3HomeCellCorrected then
    EncounterDirector.LODM3HomeCellCorrected = true
    local baseSpawnEncounter = EncounterDirector._SpawnEncounter

    function EncounterDirector:_SpawnEncounter(encounter)
        local result = baseSpawnEncounter(self, encounter)
        if encounter and encounter.cellKey then
            for _, hostile in ipairs(encounter.entities or {}) do
                if IsValid(hostile) and hostile.LODHostile then
                    hostile.LODHomeCellKey = encounter.cellKey
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
            local text = string.format(
                "#%d %s size=%.3f posZ=%.1f hullZ=%.1f..%.1f home=%s encounter=%s",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                hostile:GetNW2Float("LOD_SizeScale", 1), hostile:GetPos().z,
                mins and mins.z or 0, maxs and maxs.z or 0,
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
