LOD = LOD or {}

local Unified = LOD.WatcherUnified
if not Unified then return end

-- The unified Watcher controller must be bound directly because Garry's Mod can
-- keep a NextBot's original SENT method table after the stored class is patched.
--
-- Never clear _BehaviourTick on ordinary hostiles and never try to replace
-- RunBehaviour per instance: NextBot may already be using the class coroutine,
-- which would continue calling the original RunBehaviour after the erased method
-- is gone. That produced the production error at lod_hostile/init.lua:766.
--
-- Important startup-order rule: lod_hostile may not be registered yet when the
-- gamemode includes this file. sv_watcher_unified.lua therefore keeps its own
-- OnEntityCreated late-install hook armed until the first hostile exists. Do not
-- remove that hook here and do not snapshot the patched tick during gamemode
-- startup. Resolve it only after the entity has actually been created.

local function unifiedWatcherTick()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or not class.LODWatcherUnifiedControllerInstalled then return nil end
    return class._BehaviourTick
end

local function bindWatcher(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return false end
    if ent.LODArchetypeId ~= "watcher" then return false end

    local watcherTick = unifiedWatcherTick()
    if not watcherTick then return false end

    ent._BehaviourTick = watcherTick
    if not ent.LODWatcherUnifiedInstanceBound then
        ent.LODWatcherUnifiedInstanceBound = true
        Unified.Stats = Unified.Stats or {}
        Unified.Stats.instanceBinds = (Unified.Stats.instanceBinds or 0) + 1
    end
    return true
end

hook.Add("OnEntityCreated", "LOD_WatcherUnifiedWatcherOnlyBind", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end

    -- ents.Create fires OnEntityCreated before encounter/wanderer code assigns
    -- LODArchetypeId. One next-tick callback observes the finished spawn metadata
    -- and also gives sv_watcher_unified's class installer time to run. This is a
    -- finite spawn callback, not a recurring controller or movement timer.
    timer.Simple(0, function()
        if IsValid(ent) then bindWatcher(ent) end
    end)
end)

-- Covers Watchers that already exist when this module is hot-reloaded. Normal
-- production startup has none here, but this keeps developer reloads harmless.
for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
    timer.Simple(0, function()
        if IsValid(ent) then bindWatcher(ent) end
    end)
end

print("[LOD:WATCHER-UNIFIED] watcher-only direct BehaviourTick dispatch armed")
