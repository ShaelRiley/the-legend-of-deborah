LOD = LOD or {}
LOD.HostilePlanarMovement = LOD.HostilePlanarMovement or {}

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODPlanarMovementPatched then return false end
    class.LODPlanarMovementPatched = true

    -- Preserve every archetype-specific Initialize wrapper that was installed
    -- earlier, but remove ordinary jump authority from grounded humanoid
    -- hostiles. Mandatory vertical traversal is already represented explicitly
    -- by 16-unit stair treads; StepHeight=24 is sufficient for those. Deadcrab
    -- keeps its dedicated leap setup from sv_deadcrab.lua.
    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if IsValid(self) and self.loco and self.LODArchetypeId ~= "deadcrab" then
            self.loco:SetJumpHeight(0)
        end
    end

    -- Every ordinary graph waypoint is horizontal movement. Source/NextBot owns
    -- the live grounded Z; only explicit stair waypoints are allowed to carry a
    -- vertical destination. This prevents flat-corridor AI from interpreting a
    -- cell-center Z offset as a reason to climb local wall/container geometry.
    local baseRefreshRoute = class._RefreshRoute
    function class:_RefreshRoute(graph)
        local result = baseRefreshRoute(self, graph)
        local z = self:GetPos().z
        for _, waypoint in ipairs(self.LODWaypoints or {}) do
            if waypoint and waypoint.pos and not waypoint.stair then
                waypoint.pos = Vector(waypoint.pos.x, waypoint.pos.y, z)
            end
        end
        return result
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_HostilePlanarMovementInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)
