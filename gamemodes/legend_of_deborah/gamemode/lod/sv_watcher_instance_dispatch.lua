LOD = LOD or {}

local Unified = LOD.WatcherUnified
if not Unified then return end

-- The first working unified-Watcher build proved that direct instance dispatch is
-- necessary on this NextBot class, but it bound the stored class's _BehaviourTick
-- onto EVERY hostile instance. That bypassed the real SENT method lookup for
-- non-Watchers; wrappers such as Bio Blaster then called helper methods that did
-- not exist on that stored table, producing _RunBioBlasterTick=nil errors.
--
-- Keep direct instance dispatch at the RunBehaviour level instead. Every hostile
-- gets the normal coroutine loop below. Non-Watchers resolve self:_BehaviourTick()
-- exactly as they did before the Watcher work. Watchers alone call the final
-- unified function captured from the patched stored class. Motion V2 remains the
-- sole physical mover and this adds no timer or recurring hook beyond NextBot's
-- existing behaviour coroutine.

hook.Remove("OnEntityCreated", "LOD_WatcherUnifiedControllerInstall")

local function unifiedWatcherTick()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or not class.LODWatcherUnifiedControllerInstalled then return nil end
    return class._BehaviourTick
end

local function bindRunBehaviour(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return false end

    local watcherTick = unifiedWatcherTick()
    if not watcherTick then return false end

    -- Remove the previous build's per-instance _BehaviourTick override so ordinary
    -- archetypes once again resolve their complete wrapper/helper chain normally.
    ent._BehaviourTick = nil

    ent.RunBehaviour = function(self)
        while true do
            if self.LODArchetypeId == "watcher" then
                watcherTick(self)
            else
                self:_BehaviourTick()
            end
            coroutine.yield()
        end
    end

    if not ent.LODWatcherUnifiedInstanceBound then
        ent.LODWatcherUnifiedInstanceBound = true
        Unified.Stats = Unified.Stats or {}
        Unified.Stats.instanceBinds = (Unified.Stats.instanceBinds or 0) + 1
    end
    return true
end

hook.Add("OnEntityCreated", "LOD_WatcherUnifiedRunBehaviourDispatch", function(ent)
    -- OnEntityCreated fires before Spawn/Activate, so replacing RunBehaviour here
    -- occurs before NextBot starts its behaviour coroutine. Archetype assignment may
    -- happen later in the same spawn function; the runtime branch reads it lazily.
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then bindRunBehaviour(ent) end
end)

for _, ent in ipairs(ents.FindByClass("lod_hostile")) do bindRunBehaviour(ent) end

print("[LOD:WATCHER-UNIFIED] safe RunBehaviour instance dispatch installed")
