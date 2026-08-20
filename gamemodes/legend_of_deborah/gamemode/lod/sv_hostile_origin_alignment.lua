LOD = LOD or {}
LOD.HostileOriginAlignment = LOD.HostileOriginAlignment or {}

local Alignment = LOD.HostileOriginAlignment
Alignment.FootOffset = LOD.HumanoidFootOffset or 24

local function needsOriginAlignment(hostile)
    return IsValid(hostile) and hostile.LODHostile and hostile.LODArchetypeId ~= "deadcrab"
end

local function alignWaypoint(hostile, waypoint)
    if not needsOriginAlignment(hostile) or not waypoint or not waypoint.pos or waypoint.LODOriginAligned then return end
    local foot = Alignment.FootOffset
    waypoint.pos = waypoint.pos - Vector(0, 0, foot)
    waypoint.LODOriginAligned = true
end

function Alignment:AlignWaypoints(hostile)
    if not needsOriginAlignment(hostile) then return end
    for _, waypoint in ipairs(hostile.LODWaypoints or {}) do
        alignWaypoint(hostile, waypoint)
    end
end

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODOriginAlignmentPatched then return false end
    class.LODOriginAlignmentPatched = true

    -- MazeNavigator waypoints are authored in physical foot-space: ordinary cell
    -- centers sit +8 above the deck and stair waypoints sit a few units above each
    -- tread/landing. Humanoid NextBots, however, expose an entity origin 24 units
    -- below that foot plane. Convert every freshly built route into entity-origin
    -- coordinates exactly once before locomotion consumes it.
    local baseRefreshRoute = class._RefreshRoute
    function class:_RefreshRoute(graph)
        local result = baseRefreshRoute(self, graph)
        Alignment:AlignWaypoints(self)
        return result
    end

    -- Some route producers (notably wanderers) can leave an existing waypoint
    -- active while intentionally skipping a route rebuild. Align again immediately
    -- before waypoint advancement; the per-waypoint marker prevents double shifts.
    local baseAdvanceWaypoint = class._AdvanceWaypoint
    function class:_AdvanceWaypoint()
        Alignment:AlignWaypoints(self)
        return baseAdvanceWaypoint(self)
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_HostileOriginAlignmentInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)
