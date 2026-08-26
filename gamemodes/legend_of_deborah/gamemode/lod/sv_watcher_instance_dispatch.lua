LOD = LOD or {}

local Unified = LOD.WatcherUnified
if not Unified then return end

-- Watchers need direct RunBehaviour dispatch on this NextBot class: Garry's Mod
-- may keep the original SENT coroutine even after the stored class's
-- _BehaviourTick is patched. The previous accepted build solved that by replacing
-- RunBehaviour before Spawn, but it also erased each instance's _BehaviourTick.
-- If the engine retained the original coroutine, that erased method produced the
-- lod_hostile/init.lua:766 nil-method Lua errors.
--
-- Keep the proven pre-Spawn RunBehaviour dispatch, but NEVER clear or replace an
-- instance's _BehaviourTick. Non-Watchers therefore retain their complete normal
-- wrapper/helper chain. Watchers resolve the final unified tick dynamically each
-- coroutine cycle, so startup order cannot leave them permanently on generic AI.

local function unifiedWatcherTick()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or not class.LODWatcherUnifiedControllerInstalled then return nil end
    return class._BehaviourTick
end

local function bindRunBehaviour(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return false end

    ent.RunBehaviour = function(self)
        while true do
            if self.LODArchetypeId == "watcher" then
                local watcherTick = unifiedWatcherTick()
                if watcherTick then
                    watcherTick(self)
                else
                    -- Startup-order fallback only. Once the unified class patch is
                    -- installed the next coroutine cycle dispatches directly to it.
                    self:_BehaviourTick()
                end
            else
                self:_BehaviourTick()
            end
            coroutine.yield()
        end
    end

    if not ent.LODWatcherUnifiedRunBehaviourBound then
        ent.LODWatcherUnifiedRunBehaviourBound = true
        Unified.Stats = Unified.Stats or {}
        Unified.Stats.instanceBinds = (Unified.Stats.instanceBinds or 0) + 1
    end
    return true
end

hook.Add("OnEntityCreated", "LOD_WatcherUnifiedRunBehaviourDispatch", function(ent)
    -- OnEntityCreated fires during ents.Create, before Spawn starts the NextBot
    -- behaviour coroutine. Archetype assignment may occur later in the same spawn
    -- function; the branch above deliberately reads LODArchetypeId lazily.
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then bindRunBehaviour(ent) end
end)

-- Developer hot-reload coverage. Production entities are bound pre-Spawn above.
for _, ent in ipairs(ents.FindByClass("lod_hostile")) do bindRunBehaviour(ent) end

print("[LOD:WATCHER-UNIFIED] safe direct RunBehaviour dispatch armed")
