LOD = LOD or {}
LOD.HostileSeparation = LOD.HostileSeparation or {}

local Separation = LOD.HostileSeparation

local function sizeOf(ent)
    return math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
end

local function stableLaneUnit(ent)
    if ent.LODSeparationLaneUnit then return ent.LODSeparationLaneUnit end
    local seed = ent.LODInstanceSeed or ent:GetNW2Int("LOD_InstanceSeed", ent:EntIndex())
    if LOD.Seeds and LOD.RNG then
        local rng = LOD.RNG.New(LOD.Seeds.Derive(seed, "separation-lane"))
        ent.LODSeparationLaneUnit = rng:Float(-1, 1)
    else
        ent.LODSeparationLaneUnit = ((seed % 2001) / 1000) - 1
    end
    return ent.LODSeparationLaneUnit
end

local function deterministicEscape(self, other)
    local a = self.LODInstanceSeed or self:EntIndex()
    local b = other.LODInstanceSeed or other:EntIndex()
    local degrees = (a * 17 + b * 31) % 360
    local radians = math.rad(degrees)
    return Vector(math.cos(radians), math.sin(radians), 0)
end

function Separation:AdjustedGoal(hostile, goal, isStair)
    if not IsValid(hostile) or not goal then return goal end

    local pos = hostile:GetPos()
    local toward = goal - pos
    toward.z = 0
    if toward:Length2DSqr() < 4 then return goal end
    toward:Normalize()

    local right = Vector(-toward.y, toward.x, 0)
    local laneMax = isStair and 13 or 24
    local lane = right * (stableLaneUnit(hostile) * laneMax)

    local repel = Vector(0, 0, 0)
    local myRadius = math.max(11, 16 * sizeOf(hostile))

    for _, other in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(other) and other ~= hostile and other.LODHostile and not other.LODDead then
            local delta = pos - other:GetPos()
            if math.abs(delta.z) <= 56 then
                delta.z = 0
                local distance = delta:Length2D()
                local otherRadius = math.max(11, 16 * sizeOf(other))
                local wanted = myRadius + otherRadius + 12
                local influence = wanted + 28

                if distance < influence then
                    local direction
                    if distance < 0.5 then
                        direction = deterministicEscape(hostile, other)
                        distance = 0
                    else
                        direction = delta / distance
                    end
                    local strength = math.Clamp((influence - distance) / influence, 0, 1)
                    repel = repel + direction * (8 + 26 * strength)
                end
            end
        end
    end

    local repelMax = isStair and 12 or 20
    if repel:Length2D() > repelMax then
        repel:Normalize()
        repel = repel * repelMax
    end

    local offset = lane + repel
    -- Stair tread tolerance is 22 units; keeping the final steering offset below
    -- that value means separation can never make a valid stair waypoint
    -- geometrically unreachable. Ordinary cell waypoints tolerate a wider lane.
    local totalMax = isStair and 18 or 32
    if offset:Length2D() > totalMax then
        offset:Normalize()
        offset = offset * totalMax
    end

    return goal + offset
end

local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODSeparationPatched then return false end
    class.LODSeparationPatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if not IsValid(self) or not self.LODHostile then return end
        -- Allied hostiles steer apart instead of physically deadlocking. They
        -- continue colliding normally with players and maze geometry.
        self:SetCustomCollisionCheck(true)
        stableLaneUnit(self)
    end

    local baseAdvanceWaypoint = class._AdvanceWaypoint
    function class:_AdvanceWaypoint()
        local waypoint = baseAdvanceWaypoint(self)
        if not waypoint or not waypoint.pos or self.LODDead then return waypoint end

        local adjusted = table.Copy(waypoint)
        adjusted.pos = Separation:AdjustedGoal(self, waypoint.pos, waypoint.stair == true)
        return adjusted
    end

    return true
end

installHostilePatch()
hook.Add("OnEntityCreated", "LOD_HostileSeparationInstallBeforeSpawn", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installHostilePatch() end
end)

hook.Add("ShouldCollide", "LOD_HostilesDoNotDeadlockEachOther", function(a, b)
    if IsValid(a) and IsValid(b) and a.LODHostile and b.LODHostile then
        return false
    end
end)
