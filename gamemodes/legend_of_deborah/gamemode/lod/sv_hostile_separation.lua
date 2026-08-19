LOD = LOD or {}
LOD.HostileSeparation = LOD.HostileSeparation or {}

-- Hostile-vs-hostile physical collision caused the original pileups, but
-- perturbing authored waypoint positions introduced a worse failure mode:
-- NextBots could be steered off the exact stair-tread centers that were already
-- runtime-validated. Keep separation deliberately simple. Allies may pass
-- through one another physically; per-instance speed variance and per-footstep
-- stride variance then naturally de-synchronise their visual movement without
-- changing any graph/stair target position.
local function installHostilePatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODSeparationPatched then return false end
    class.LODSeparationPatched = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if not IsValid(self) or not self.LODHostile then return end
        self:SetCustomCollisionCheck(true)
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
