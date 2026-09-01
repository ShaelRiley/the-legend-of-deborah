LOD = LOD or {}
LOD.WatcherUnifiedDispatch = LOD.WatcherUnifiedDispatch or {}

local Unified = LOD.WatcherUnified
local Dispatch = LOD.WatcherUnifiedDispatch
if not Unified then return end

-- Bind one router at the earliest Lua entity lifecycle point. Also bind the final
-- stored-class behaviour/scan methods directly onto each instance: native
-- RunBehaviour resolves self:_BehaviourTick() every cycle, so this remains safe
-- even if NEXTBOT captured the native coroutine before RunBehaviour replacement.

local function unifiedWatcherTick()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or not class.LODWatcherUnifiedControllerInstalled then return nil end
    return class._BehaviourTick
end

local function bindFinalMethods(self)
    if not IsValid(self) or self:GetClass() ~= "lod_hostile" then return false end
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class then return false end
    if class._BehaviourTick then self._BehaviourTick = class._BehaviourTick end
    if class._RunWatcherTick then self._RunWatcherTick = class._RunWatcherTick end
    self.LODWatcherFinalMethodsBound = true
    return true
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
            stopWatcherSafely(self)
            self.LODMotionMode = "watcher-dispatch-wait"
        end
        coroutine.yield()
    end
end

local function runBehaviourRouter(self)
    while not self.LODArchetypeId do coroutine.yield() end

    if self.LODArchetypeId == "watcher" then
        return watcherRunLoop(self)
    end

    local native = Dispatch.NativeRunBehaviour
    if native and native ~= runBehaviourRouter then
        return native(self)
    end

    while true do
        self:_BehaviourTick()
        coroutine.yield()
    end
end

Dispatch.Router = runBehaviourRouter
Dispatch.BindFinalMethods = bindFinalMethods

local function installClassRouter()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class then return false end

    -- OnEntityCreated can arrive before every late SENT method is guaranteed to be
    -- visible on the new instance. Initialize is the deterministic second seam:
    -- after the complete existing Initialize chain runs, stamp the final stored
    -- class methods directly onto the instance before ordinary behaviour advances.
    if not class.LODWatcherDispatchInitializeBindingInstalled then
        class.LODWatcherDispatchInitializeBindingInstalled = true
        local baseInitialize = class.Initialize
        function class:Initialize(...)
            if baseInitialize then baseInitialize(self, ...) end
            bindFinalMethods(self)
        end
    end

    local current = class.RunBehaviour
    if not Dispatch.NativeRunBehaviour and current and current ~= runBehaviourRouter then
        Dispatch.NativeRunBehaviour = current
    end

    if class.RunBehaviour ~= runBehaviourRouter then
        class.RunBehaviour = runBehaviourRouter
    end
    return Dispatch.NativeRunBehaviour ~= nil
end

installClassRouter()

hook.Add("OnEntityCreated", "LOD_WatcherUnifiedPreSpawnRunBehaviourDispatch", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
    installClassRouter()
    bindFinalMethods(ent)
    ent.RunBehaviour = runBehaviourRouter
end)

-- Hot reload repairs live native-coroutine hostiles on their very next behaviour
-- cycle because native RunBehaviour dynamically resolves self:_BehaviourTick().
for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
    if IsValid(ent) then
        bindFinalMethods(ent)
        ent.RunBehaviour = runBehaviourRouter
    end
end

concommand.Add("lod_watcher_dispatch_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    local live, tickBound, scanBound = 0, 0, 0
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(ent) and not ent.LODDead and ent.LODArchetypeId == "watcher" then
            live = live + 1
            if class and ent._BehaviourTick == class._BehaviourTick then tickBound = tickBound + 1 end
            if class and ent._RunWatcherTick == class._RunWatcherTick then scanBound = scanBound + 1 end
        end
    end
    local pass = live == 0 or (tickBound == live and scanBound == live)
    local line = string.format("live=%d tickBound=%d scanBound=%d initBind=%s result=%s",
        live, tickBound, scanBound,
        tostring(class and class.LODWatcherDispatchInitializeBindingInstalled == true),
        pass and "PASS" or "FAIL")
    print("[LOD:WATCHER-DISPATCH] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

print("[LOD:WATCHER-UNIFIED] pre-spawn router + Initialize final-method binding armed")
