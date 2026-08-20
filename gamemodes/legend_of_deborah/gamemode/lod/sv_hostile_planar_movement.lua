LOD = LOD or {}
LOD.HostilePlanarMovement = LOD.HostilePlanarMovement or {}

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODPlanarMovementPatched then return false end
    class.LODPlanarMovementPatched = true

    -- Runtime evidence established an important distinction between a live
    -- NextBot entity origin and the physical walking surface. On generated
    -- floors Source commonly keeps GetPos().z about 24 units BELOW the authored
    -- floor plane. Rewriting ordinary waypoint Z to GetPos().z therefore put the
    -- locomotion goal inside the floor. The bot reported horizontal velocity but
    -- made no world-position progress, then entered an endless recovery loop.
    --
    -- Keep the navigator's authored ordinary waypoints untouched. They already
    -- sit at CellCenter(cell) + 8, safely above the physical deck, and every
    -- ordinary edge remains on one logical floor. Planarity is enforced by
    -- disabling autonomous jump/climb/gap-jump authority, NOT by copying the raw
    -- entity-origin Z into movement goals. Explicit stair waypoints retain their
    -- authored changing elevations.
    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if not IsValid(self) or not self.loco or self.LODArchetypeId == "deadcrab" then return end

        self.loco:SetJumpHeight(0)
        if self.loco.SetClimbAllowed then self.loco:SetClimbAllowed(false) end
        if self.loco.SetJumpGapsAllowed then self.loco:SetJumpGapsAllowed(false) end
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_HostilePlanarMovementInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)
