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
-- Instead, leave every non-Watcher completely untouched. Once a newly-created
-- hostile has had its archetype assigned, bind the final unified tick directly to
-- Watchers only. This preserves the accepted single Watcher authority while the
-- normal SENT/wrapper chain remains authoritative for all other archetypes.

hook.Remove("OnEntityCreated", "LOD_WatcherUnifiedControllerInstall")
hook.Remove("OnEntityCreated", "LOD_WatcherUnifiedRunBehaviourDispatch")

local function unifiedWatcherTick()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or not class.LODWatcherUnifiedControllerInstalled then return nil end
    return class._BehaviourTick
end

local watcherTick = unifiedWatcherTick()
if not watcherTick then
    ErrorNoHalt("[LOD:WATCHER-UNIFIED] final Watcher tick unavailable; direct bind skipped\n")
    return
end

local function bindWatcher(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return false end
    if ent.LODArchetypeId ~= "watcher" then return false end

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
    -- LODArchetypeId. One next-tick callback observes the finished spawn metadata;
    -- it is finite (not a recurring controller or movement timer).
    timer.Simple(0, function()
        if IsValid(ent) then bindWatcher(ent) end
    end)
end)

-- Covers any Watcher that already exists when this module is loaded/reloaded.
for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
    bindWatcher(ent)
end

print("[LOD:WATCHER-UNIFIED] watcher-only direct BehaviourTick dispatch installed")
