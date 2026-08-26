LOD = LOD or {}
LOD.WatcherUnifiedDispatch = LOD.WatcherUnifiedDispatch or {}

local Unified = LOD.WatcherUnified
local Dispatch = LOD.WatcherUnifiedDispatch
if not Unified then return end

-- Garry's Mod NextBots can retain the RunBehaviour coroutine associated with the
-- entity instance even when the stored SENT table is patched later. Watchers need
-- a direct path into the final unified controller, but ordinary hostiles must not
-- receive that override: doing so can make their later archetype helper methods
-- (_RunDeadcrabTick, _RunBioBlasterTick, etc.) resolve against an incomplete
-- instance method table.
--
-- The safe lifecycle point is Initialize. Encounter/wanderer code assigns
-- LODArchetypeId before ent:Spawn(); Spawn calls Initialize before the behaviour
-- coroutine begins. We therefore install one class-level Initialize wrapper and
-- assign a custom RunBehaviour ONLY to entities already identified as Watchers.
-- No _BehaviourTick field is cleared or copied onto any entity.

local function unifiedWatcherTick()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or not class.LODWatcherUnifiedControllerInstalled then return nil end
    return class._BehaviourTick
end

local function watcherRunBehaviour(self)
    while true do
        local watcherTick = unifiedWatcherTick()
        if watcherTick then
            watcherTick(self)
        else
            -- Startup-order fallback only. The unified installer is armed on the
            -- same class and should be available by the next coroutine cycle.
            self:_BehaviourTick()
        end
        coroutine.yield()
    end
end

function Dispatch:BindWatcher(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return false end
    if ent.LODArchetypeId ~= "watcher" then return false end

    ent.RunBehaviour = watcherRunBehaviour
    if not ent.LODWatcherUnifiedRunBehaviourBound then
        ent.LODWatcherUnifiedRunBehaviourBound = true
        Unified.Stats = Unified.Stats or {}
        Unified.Stats.instanceBinds = (Unified.Stats.instanceBinds or 0) + 1
    end
    return true
end

local function installInitializeDispatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherRunBehaviourDispatchInstalled then return false end

    class.LODWatcherRunBehaviourDispatchInstalled = true
    local baseInitialize = class.Initialize
    function class:Initialize()
        -- Bind before the rest of Initialize executes so the Watcher-specific
        -- coroutine is unquestionably present before NextBot starts behaviour.
        if self.LODArchetypeId == "watcher" then
            Dispatch:BindWatcher(self)
        end
        return baseInitialize(self)
    end
    return true
end

installInitializeDispatch()

hook.Add("OnEntityCreated", "LOD_WatcherUnifiedRunBehaviourDispatchInstall", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
    -- OnEntityCreated occurs after ents.Create but before ent:Spawn, so if the
    -- scripted class was unavailable during gamemode include this still installs
    -- the Initialize wrapper in time for this entity's Spawn call.
    installInitializeDispatch()
end)

print("[LOD:WATCHER-UNIFIED] Watcher-only Initialize RunBehaviour dispatch armed")
