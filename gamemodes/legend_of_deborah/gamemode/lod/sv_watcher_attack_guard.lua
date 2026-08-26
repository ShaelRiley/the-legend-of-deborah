LOD = LOD or {}

local function installWatcherAttackGuard()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherAttackGuardInstalled then return false end
    class.LODWatcherAttackGuardInstalled = true

    local baseTryAttack = class._TryAttack
    function class:_TryAttack(target)
        if self.LODArchetypeId == "watcher" then return false end
        return baseTryAttack(self, target)
    end
    return true
end

installWatcherAttackGuard()
hook.Add("OnEntityCreated", "LOD_WatcherAttackGuardInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installWatcherAttackGuard() end
end)
