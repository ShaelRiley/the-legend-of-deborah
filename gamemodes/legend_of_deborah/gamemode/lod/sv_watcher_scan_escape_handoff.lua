LOD = LOD or {}
LOD.WatcherScanEscapeHandoff = LOD.WatcherScanEscapeHandoff or {}

local Handoff = LOD.WatcherScanEscapeHandoff
local Unified = LOD.WatcherUnified
local Watcher = LOD.Watcher
local Rolls = LOD.CombatRolls

if not Unified or not Watcher then return end

-- The unified Watcher controller historically inferred scan completion by sampling
-- Watcher.Stats.scansCompleted around _RunWatcherTick. Runtime evidence shows that
-- scanning itself is now reliable but the scan -> escape transition can still be
-- lost, leaving the scanner stationary in its attack presentation.
--
-- Make that boundary explicit and per-instance. _RunWatcherTick records an exact
-- completion token on the Watcher that completed the scan. The unified controller
-- still gets first opportunity to create its ordinary escape state. Only if that
-- state is absent when the behaviour tick returns do we seed the same escape data
-- contract that sv_watcher_unified.lua consumes. All route selection, concealment
-- checks, replanning and physical movement remain owned by the unified controller
-- and HostileMotionV2; this module is a transition guarantee, not another AI loop.

local BLINK_SECONDS = 0.50
local CLOAK_DICE_COUNT = 2
local HIDE_DICE_COUNT = 8
local D6_PROFILE = {sides = 6, exploding = 6}
local MAX_FALLBACK_CHAIN = 64

Handoff.Stats = Handoff.Stats or {
    completionsObserved = 0,
    nativeEscapes = 0,
    fallbackEscapes = 0,
    invalidTargets = 0
}

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function fallbackExplodingChain(rng)
    local total = 0
    local values = {}
    for _ = 1, MAX_FALLBACK_CHAIN do
        local value = rng:Int(1, 6)
        values[#values + 1] = value
        total = total + value
        if value ~= 6 then break end
    end
    return total, values
end

local function rollExplodingDice(watcher, label, count)
    watcher.LODWatcherUnifiedRollSerial = (watcher.LODWatcherUnifiedRollSerial or 0) + 1
    local state = LOD.RunManager and LOD.RunManager.State
    local levelSeed = state and state.LevelSeed or 1
    local identity = watcher.LODEncounterOrdinal
        or watcher.LODWanderSeed
        or watcher.LODEncounterId
        or watcher:EntIndex()
    local seed = LOD.Seeds.Derive(levelSeed, string.format(
        "watcher-handoff-v1:%s:%s:%d", label, tostring(identity), watcher.LODWatcherUnifiedRollSerial))
    local rng = LOD.RNG.New(seed)

    local total = 0
    local chains = {}
    for index = 1, count do
        local subtotal, values
        if Rolls and Rolls._RollExploding then
            subtotal, values = Rolls:_RollExploding(D6_PROFILE, rng)
        else
            subtotal, values = fallbackExplodingChain(rng)
        end
        total = total + (subtotal or 0)
        chains[index] = table.concat(values or {}, ">")
    end
    return math.max(count, total), table.concat(chains, " | ")
end

local function resetOrdinaryRoute(watcher)
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
    watcher.LODNextRouteRefresh = 0
end

local function emitCompletionPulse(watcher, target)
    if not util.NetworkStringToID or util.NetworkStringToID("LOD_WatcherScanPulse") == 0 then return end
    Unified.Stats = Unified.Stats or {}
    Unified.Stats.scanPulses = (Unified.Stats.scanPulses or 0) + 1
    watcher:EmitSound("ambient/energy/zap1.wav", 76, 112, 0.72, CHAN_AUTO)
    net.Start("LOD_WatcherScanPulse")
    net.WriteEntity(watcher)
    net.WriteEntity(IsValid(target) and target or NULL)
    net.Broadcast()
end

local function seedEscape(watcher, target)
    if not IsValid(watcher) or watcher.LODDead or watcher.LODArchetypeId ~= "watcher" then return false end
    if watcher.LODWatcherUnifiedEscape then return false end
    if not livingPlayer(target) then
        Handoff.Stats.invalidTargets = (Handoff.Stats.invalidTargets or 0) + 1
        return false
    end

    local now = CurTime()
    local cloakDuration, cloakRoll = rollExplodingDice(watcher, "cloak", CLOAK_DICE_COUNT)
    local hideDuration, hideRoll = rollExplodingDice(watcher, "hide", HIDE_DICE_COUNT)

    watcher.LODWatcherUnifiedEscape = {
        target = target,
        phase = "seeking",
        cloakDuration = cloakDuration,
        cloakRoll = cloakRoll,
        hideDuration = hideDuration,
        hideRoll = hideRoll,
        blinkUntil = now + BLINK_SECONDS,
        invisibleUntil = now + BLINK_SECONDS + cloakDuration,
        waypoints = {},
        index = 1,
        nextVisibilityAt = 0,
        hiddenSince = nil,
        hiddenEndsAt = nil,
        nextPlanAt = 0,
        handoffFallback = true
    }

    watcher.LODWatcherUnifiedBackoff = nil
    watcher.LODWatcherUnifiedDisengageUntil = 0
    watcher.LODNextWatcherScan = math.huge
    watcher.LODNextTargetRefresh = math.huge
    watcher.LODWatcherUnifiedSpeedScale = math.max(watcher.LODWatcherUnifiedSpeedScale or 1, 1.80)
    resetOrdinaryRoute(watcher)

    watcher:SetNW2Float("LOD_WatcherBlinkUntil", now + BLINK_SECONDS)
    watcher:SetNW2Float("LOD_WatcherInvisibleUntil", now + BLINK_SECONDS + cloakDuration)
    watcher:SetNW2Float("LOD_WatcherEscapeSeconds", cloakDuration)

    Unified.Stats = Unified.Stats or {}
    Unified.Stats.escapeStarts = (Unified.Stats.escapeStarts or 0) + 1
    Unified.Stats.lastCloakSeconds = cloakDuration
    Unified.Stats.lastCloakRoll = cloakRoll
    Unified.Stats.lastHideSeconds = hideDuration
    Unified.Stats.lastHideRoll = hideRoll

    emitCompletionPulse(watcher, target)
    Handoff.Stats.fallbackEscapes = (Handoff.Stats.fallbackEscapes or 0) + 1
    return true
end

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherScanEscapeHandoffInstalled then return false end
    if not class._RunWatcherTick or not class.LODWatcherUnifiedControllerInstalled then return false end

    class.LODWatcherScanEscapeHandoffInstalled = true

    local baseRunWatcherTick = class._RunWatcherTick
    function class:_RunWatcherTick()
        if self.LODArchetypeId ~= "watcher" then return baseRunWatcherTick(self) end

        local scanBefore = self.LODWatcherScan
        local completedBefore = Watcher.Stats.scansCompleted or 0
        local result = baseRunWatcherTick(self)
        local completedAfter = Watcher.Stats.scansCompleted or 0

        if scanBefore and not self.LODWatcherScan and completedAfter > completedBefore then
            self.LODWatcherScanEscapePending = {
                target = scanBefore.target,
                completedAt = CurTime(),
                serial = (self.LODWatcherScanEscapeSerial or 0) + 1
            }
            self.LODWatcherScanEscapeSerial = self.LODWatcherScanEscapePending.serial
            Handoff.Stats.completionsObserved = (Handoff.Stats.completionsObserved or 0) + 1
        end

        return result
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId ~= "watcher" then return baseBehaviourTick(self) end

        local pendingBefore = self.LODWatcherScanEscapePending
        if pendingBefore then
            if self.LODWatcherUnifiedEscape then
                self.LODWatcherScanEscapePending = nil
                Handoff.Stats.nativeEscapes = (Handoff.Stats.nativeEscapes or 0) + 1
            else
                seedEscape(self, pendingBefore.target)
                self.LODWatcherScanEscapePending = nil
            end
        end

        local result = baseBehaviourTick(self)

        -- A completion token can be created inside baseBehaviourTick itself. Give
        -- the native unified completion branch the whole tick to act first; only
        -- then close the transition if no escape state exists.
        local pendingAfter = self.LODWatcherScanEscapePending
        if pendingAfter then
            if self.LODWatcherUnifiedEscape then
                self.LODWatcherScanEscapePending = nil
                Handoff.Stats.nativeEscapes = (Handoff.Stats.nativeEscapes or 0) + 1
            else
                seedEscape(self, pendingAfter.target)
                self.LODWatcherScanEscapePending = nil
            end
        end

        return result
    end

    local baseOnRemove = class.OnRemove
    function class:OnRemove()
        self.LODWatcherScanEscapePending = nil
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_WatcherScanEscapeHandoffInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)

concommand.Add("lod_watcher_handoff_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local pending = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODArchetypeId == "watcher" and hostile.LODWatcherScanEscapePending then
            pending = pending + 1
        end
    end

    local line = string.format(
        "completed=%d nativeEscapes=%d fallbackEscapes=%d invalidTargets=%d pending=%d authority=transition-only",
        Handoff.Stats.completionsObserved or 0,
        Handoff.Stats.nativeEscapes or 0,
        Handoff.Stats.fallbackEscapes or 0,
        Handoff.Stats.invalidTargets or 0,
        pending)
    print("[LOD:WATCHER-HANDOFF] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

print("[LOD:WATCHER-HANDOFF] explicit scan-complete escape handoff armed")
