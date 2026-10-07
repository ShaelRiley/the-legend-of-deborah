-- Deborah's lifecycle for the pinned VRMod addon. No polling hook is needed:
-- the existing join/exit messages and explicit local start own activation.
vrmod = vrmod or {}
if vrmod.LODIdle then return end
local Idle = {version = "deborah-vr-idle-20261007", active = false, loading = true,
    hooks = {}, timers = {}, foreign = {}, bindings = {}, resources = {}, sequence = 0}
vrmod.LODIdle = Idle
local engineHook, engineTimer = hook, timer
local function pack(...) return {n = select("#", ...), ...} end
local function bootstrap(event)
    return event:sub(1, 6) == "VRMod_" or event == "Initialize"
        or event == "InitPostEntity" or event == "ShutDown" or event == "PlayerDisconnected"
end
local function key(event, id) return event .. "\0" .. tostring(id) end
local function liveHook(event, id)
    local list = engineHook.GetTable()[event]
    return list and list[id]
end
Idle.Hook = setmetatable({}, {__index = engineHook})
Idle.Timer = setmetatable({}, {__index = engineTimer})

-- Shared engine/Derma methods must have their original binding while idle,
-- rather than leaving a VR wrapper on every ordinary desktop call.
function Idle:Binding(owner, name, original, replacement)
    local list = self.bindings[owner] or {}; self.bindings[owner] = list
    local entry = list[name]
    if not entry then entry = {original = original}; list[name] = entry end
    entry.replacement = replacement
    if not self.active and owner[name] == replacement then owner[name] = entry.original end
end

local function arm(entry)
    engineTimer.Create(entry.id, entry.delay, entry.repetitions, function()
        if Idle.timers[entry.id] ~= entry then return end
        if entry.repetitions > 0 then
            entry.remaining = entry.remaining - 1
            if entry.remaining == 0 then Idle.timers[entry.id] = nil end
        end
        entry.fn()
    end)
end
function Idle:Resume()
    if self.active then return end
    self.active = true
    for _, entry in pairs(self.foreign) do
        if liveHook(entry.event, entry.id) == entry.fn then engineHook.Remove(entry.event, entry.id) end
    end
    for _, entry in pairs(self.hooks) do
        if not bootstrap(entry.event) then engineHook.Add(entry.event, entry.id, entry.fn) end
    end
    for owner, list in pairs(self.bindings) do
        for name, entry in pairs(list) do
            if owner[name] == entry.original then owner[name] = entry.replacement end
        end
    end
    for id, entry in pairs(self.timers) do
        if entry.cleanup then
            -- World-object cleanup still belongs to its dropped object. Session
            -- setting/input restores must not run in a new VR lifetime.
            if not entry.resource_cleanup then engineTimer.Remove(id); self.timers[id] = nil end
        else
            entry.remaining = entry.repetitions
            arm(entry)
        end
    end
end
function Idle:Suspend()
    self.active = false
    for _, entry in pairs(self.hooks) do
        if not bootstrap(entry.event) and liveHook(entry.event, entry.id) == entry.fn then
            engineHook.Remove(entry.event, entry.id)
        end
    end
    for _, entry in pairs(self.foreign) do
        local current = liveHook(entry.event, entry.id)
        local owned = self.hooks[key(entry.event, entry.id)]
        if not current or (owned and current == owned.fn) then
            engineHook.Add(entry.event, entry.id, entry.fn)
        end
    end
    for owner, list in pairs(self.bindings) do
        for name, entry in pairs(list) do
            if owner[name] == entry.replacement then owner[name] = entry.original end
        end
    end
    for id, entry in pairs(self.timers) do
        -- Finite exit jobs finish ordinary teardown once. They cannot poll or
        -- restart a VR session; all other runtime jobs stop now.
        if not entry.cleanup then
            engineTimer.Remove(id)
            if not entry.initial then self.timers[id] = nil end
        end
    end
end
function Idle:PlayerCount()
    local count = 0
    local state = CLIENT and g_VR and g_VR.net or g_VR
    for _, data in pairs(state or {}) do
        if type(data) == "table" and (CLIENT or data.characterAltHead ~= nil) then count = count + 1 end
    end
    return count
end
function Idle:Reconcile()
    if self.starting or (CLIENT and g_VR and g_VR.active) or self:PlayerCount() > 0 then
        self:Resume()
    else
        self:Suspend()
    end
end

-- Use the addon's canonical drop path before presence is removed. This detaches
-- held physics and retires its motion controller when the final hand is empty.
function Idle:ReleaseHeld(sid)
    if not SERVER or not vrmod.Drop then return end
    local previous = self.exiting
    self.exiting = true
    local ok, err = pcall(function()
        vrmod.Drop(sid, true)
        vrmod.Drop(sid, false)
    end)
    self.exiting = previous
    if not ok then error(err, 0) end
end

function Idle.Hook.Add(event, id, fn)
    local k = key(event, id)
    local entry = {event = event, id = id, fn = fn}
    -- Bootstrap callbacks are event-only; wrap those to settle state after the
    -- complete callback, never a per-frame early-out on an idle engine hook.
    if event == "InitPostEntity" or event == "Initialize" then
        entry.fn = function(...)
            Idle.initializing = true
            local results = pack(pcall(fn, ...))
            Idle.initializing = false
            if not results[1] then error(results[2], 0) end
            return unpack(results, 2, results.n)
        end
    elseif event == "VRMod_Start" then
        entry.fn = function(...)
            Idle:Resume()
            return fn(...)
        end
    end
    Idle.hooks[k] = entry
    if Idle.active or bootstrap(event) then engineHook.Add(event, id, entry.fn) end
end
function Idle.Hook.Remove(event, id)
    local k = key(event, id)
    local owned = Idle.hooks[k]
    if owned then
        if liveHook(event, id) == owned.fn then engineHook.Remove(event, id) end
        Idle.hooks[k] = nil
    else
        local current = liveHook(event, id)
        if current then
            Idle.foreign[k] = {event = event, id = id, fn = current}
            if Idle.active then engineHook.Remove(event, id) end
        end
    end
end
function Idle.Hook.Run(event, ...)
    if event == "VRMod_Start" then Idle:Resume() end
    if event ~= "VRMod_Exit" then return engineHook.Run(event, ...) end
    local previous = Idle.exiting
    Idle.exiting = true
    local results = pack(pcall(engineHook.Run, event, ...))
    Idle.exiting = previous; Idle:Reconcile()
    if not results[1] then error(results[2], 0) end
    return unpack(results, 2, results.n)
end

function Idle.Timer.Create(id, delay, repetitions, fn)
    engineTimer.Remove(id)
    local entry = {id = id, delay = delay, repetitions = repetitions,
        remaining = repetitions, fn = fn, initial = Idle.loading or Idle.initializing,
        cleanup = repetitions > 0 and (Idle.exiting or id == "vrmod_mat_queue_restore")}
    Idle.timers[id] = entry
    if Idle.active or entry.cleanup then arm(entry) end
end
function Idle.Timer.Simple(delay, fn)
    Idle.sequence = Idle.sequence + 1
    Idle.Timer.Create("LOD_VR_once_" .. Idle.sequence, delay, 1, fn)
end
function Idle:Cleanup(delay, fn)
    self.sequence = self.sequence + 1
    local id = "LOD_VR_cleanup_" .. self.sequence
    self.Timer.Create(id, delay, 1, fn)
    local entry = self.timers[id]
    entry.cleanup = true; entry.resource_cleanup = true
    if not engineTimer.Exists(id) then arm(entry) end
end
function Idle.Timer.Remove(id)
    Idle.timers[id] = nil
    return engineTimer.Remove(id)
end
function Idle.Timer.Exists(id) return Idle.timers[id] ~= nil or engineTimer.Exists(id) end

function Idle:FinishLoad()
    self.loading = false
    if CLIENT and VRUtilClientStart then
        local start = VRUtilClientStart
        VRUtilClientStart = function(...)
            self.starting = true; self:Resume()
            local results = pack(pcall(start, ...))
            self.starting = false; self:Reconcile()
            if not results[1] then error(results[2], 0) end
            return unpack(results, 2, results.n)
        end
        local exit = VRUtilClientExit
        if exit then
            VRUtilClientExit = function(...)
                local results = pack(pcall(exit, ...))
                self:Reconcile()
                if not results[1] then error(results[2], 0) end
                return unpack(results, 2, results.n)
            end
        end
    end
    self:Reconcile()
end

-- Presence discovery is one map event, not a Think/CreateMove poll. It keeps
-- already-connected remote VR players visible to a newly joining desktop peer.
if CLIENT then
    engineHook.Add("InitPostEntity", "LOD_VRPresence", function()
        net.Start("vrutil_net_requestvrplayers", true); net.SendToServer()
        local auto = GetConVar("vrmod_autostart")
        if (auto and auto:GetBool()) or file.Exists("vrmod/openxr_launch.txt", "DATA") then
            if vrmod.ApplyOpenXRLaunchMarker then vrmod.ApplyOpenXRLaunchMarker() end
            RunConsoleCommand("vrmod_start", "force")
        end
    end)
end
engineHook.Add("PlayerDisconnected", "LOD_VRPresenceCleanup", function(ply)
    -- The upstream disconnect callback also broadcasts exit. Reconcile after
    -- it via the scoped hook.Run below; this fallback covers invalid entities.
    local sid = ply:SteamID()
    if SERVER and g_VR and g_VR[sid] then
        Idle:ReleaseHeld(sid)
        g_VR[sid] = nil
        Idle.Hook.Run("VRMod_Exit", ply, sid)
        net.Start("vrutil_net_exit"); net.WriteString(sid); net.Broadcast()
    end
    Idle:Reconcile()
end)

function Idle:Snapshot()
    local out = {version = self.version, active = self.active, players = self:PlayerCount(),
        local_tracking = CLIENT and g_VR and g_VR.active == true or false,
        runtime_hooks = 0, recurring_timers = 0, pending_once = 0, method_overrides = 0,
        native_resources = 0, resource_counts = {}}
    for _, entry in pairs(self.hooks) do
        if not bootstrap(entry.event) and liveHook(entry.event, entry.id) == entry.fn then
            out.runtime_hooks = out.runtime_hooks + 1
        end
    end
    for id, entry in pairs(self.timers) do
        if engineTimer.Exists(id) then
            if entry.repetitions == 0 then out.recurring_timers = out.recurring_timers + 1
            else out.pending_once = out.pending_once + 1 end
        end
    end
    for owner, list in pairs(self.bindings) do
        for name, entry in pairs(list) do
            if owner[name] == entry.replacement then out.method_overrides = out.method_overrides + 1 end
        end
    end
    -- Sample private native ownership only for an explicitly requested snapshot,
    -- never from a frame hook, repeating timer or ordinary audit heartbeat.
    for _, countResources in pairs(self.resources) do
        for name, count in pairs(countResources()) do
            out.resource_counts[name] = (out.resource_counts[name] or 0) + count
            out.native_resources = out.native_resources + count
        end
    end
    out.idle = not out.active and out.runtime_hooks == 0 and out.recurring_timers == 0
        and out.pending_once == 0 and out.method_overrides == 0 and out.native_resources == 0
        and not out.local_tracking
    return out
end
