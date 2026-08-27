LOD = LOD or {}
LOD.WatcherUnifiedDispatch = LOD.WatcherUnifiedDispatch or {}

local Unified = LOD.WatcherUnified
local Dispatch = LOD.WatcherUnifiedDispatch
if not Unified then return end

-- The Watcher must never depend on a post-creation SENT method replacement.
-- NEXTBOT:BehaveStart owns the behaviour coroutine lifecycle, so rebinding
-- RunBehaviour from Initialize is not an authority guarantee: a Watcher can retain
-- the original generic hostile coroutine and then approach/follow the player with
-- neither its scan state nor its retreat state ever receiving control.
--
-- Bind one router at the earliest Lua entity lifecycle point and also install it on
-- the stored class whenever that class is available. The router waits until the
-- archetype is known. Watchers then call the final unified class tick directly on
-- every coroutine cycle. All other hostiles delegate to the exact native
-- RunBehaviour function captured before this router was installed, preserving
-- their complete instance/helper method chain.

local function unifiedWatcherTick()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or not class.LODWatcherUnifiedControllerInstalled then return nil end
    return class._BehaviourTick
end

local function stopWatcherSafely(self)
    local motion = LOD.HostileMotionV2
    if motion and motion.Stop then
        motion:Stop(self)
    elseif self.loco then
        self.loco:SetDesiredSpeed(0)
    end
end

local function markWatcherBound(self)
    if self.LODWatcherUnifiedRunBehaviourBound then return end
    self.LODWatcherUnifiedRunBehaviourBound = true
    Unified.Stats = Unified.Stats or {}
    Unified.Stats.instanceBinds = (Unified.Stats.instanceBinds or 0) + 1
end

local function watcherRunLoop(self)
    markWatcherBound(self)
    while true do
        local watcherTick = unifiedWatcherTick()
        if watcherTick then
            watcherTick(self)
        else
            -- Never use generic hostile pursuit as a startup fallback. If the
            -- unified controller is momentarily unavailable, holding position for
            -- one coroutine cycle is safe; walking into the player is not.
            stopWatcherSafely(self)
            self.LODMotionMode = "watcher-dispatch-wait"
        end
        coroutine.yield()
    end
end

local function runBehaviourRouter(self)
    -- OnEntityCreated precedes the caller's archetype assignment. If the engine
    -- starts the coroutine unusually early, yield until Initialize/spawn metadata
    -- has made the archetype explicit instead of permanently choosing a branch
    -- from a transient nil value.
    while not self.LODArchetypeId do coroutine.yield() end

    if self.LODArchetypeId == "watcher" then
        return watcherRunLoop(self)
    end

    local native = Dispatch.NativeRunBehaviour
    if native and native ~= runBehaviourRouter then
        return native(self)
    end

    -- Defensive fallback only if startup order prevented capture of the native
    -- method. This is byte-for-byte equivalent in control flow to lod_hostile's
    -- ordinary RunBehaviour loop and never enters Watcher-specific state.
    while true do
        self:_BehaviourTick()
        coroutine.yield()
    end
end

Dispatch.Router = runBehaviourRouter

local function installClassRouter()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class then return false end

    local current = class.RunBehaviour
    if not Dispatch.NativeRunBehaviour and current and current ~= runBehaviourRouter then
        Dispatch.NativeRunBehaviour = current
    end

    if class.RunBehaviour ~= runBehaviourRouter then
        class.RunBehaviour = runBehaviourRouter
    end
    return Dispatch.NativeRunBehaviour ~= nil
end

-- Normal startup usually installs here, before any production hostile exists.
installClassRouter()

hook.Add("OnEntityCreated", "LOD_WatcherUnifiedPreSpawnRunBehaviourDispatch", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end

    -- This is the route that previously proved able to reach Watchers before their
    -- NextBot behaviour coroutine committed to generic AI. It is intentionally
    -- applied to every lod_hostile because LODArchetypeId is assigned immediately
    -- after ents.Create; the router itself delegates every non-Watcher to the
    -- untouched native coroutine once that identifier exists.
    installClassRouter()
    ent.RunBehaviour = runBehaviourRouter
end)

-- Hot-reload visibility only. A full game restart remains the authoritative test,
-- because an already-running NextBot coroutine cannot be assumed to adopt a newly
-- assigned RunBehaviour function.
for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
    if IsValid(ent) then ent.RunBehaviour = runBehaviourRouter end
end

print("[LOD:WATCHER-UNIFIED] pre-spawn RunBehaviour router armed; non-Watchers delegate native")
