LOD = LOD or {}
LOD.WatcherScanEscapeHandoff = LOD.WatcherScanEscapeHandoff or {}

local Handoff = LOD.WatcherScanEscapeHandoff
local Unified = LOD.WatcherUnified
local Watcher = LOD.Watcher
local Rolls = LOD.CombatRolls
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2

if not Unified or not Watcher or not Navigator or not Motion then return end

-- This layer closes two narrow state-boundary failures without becoming a second
-- movement controller. The unified Watcher controller and Motion V2 still own all
-- route planning and physical travel.
--
-- 1) Scan completion is recorded per Watcher so a successful scan cannot be lost
--    at the scan -> escape boundary.
-- 2) Runtime video showed a subtler failure after that handoff: the unified
--    controller considered the Watcher hidden as soon as its ORIGIN crossed behind
--    a wall. It then discarded the rest of its route and began the long 8d6!
--    concealment timer while the scanner model was still visibly protruding through
--    the wall. Concealment is now admitted only when the Watcher's visible bounds
--    are occluded and it has reached a stable cell-interior hold point.
--
-- Any rejected concealment is returned to the unified "seeking" phase. Motion V2
-- performs the corrective move; this file never SetPos's the entity itself.

local BLINK_SECONDS = 0.50
local CLOAK_DICE_COUNT = 2
local HIDE_DICE_COUNT = 8
local D6_PROFILE = {sides = 6, exploding = 6}
local MAX_FALLBACK_CHAIN = 64
local HIDDEN_CENTER_TOLERANCE = 40
local BOUNDS_INSET = 6

Handoff.Stats = Handoff.Stats or {}
local defaults = {
    completionsObserved = 0,
    nativeEscapes = 0,
    fallbackEscapes = 0,
    invalidTargets = 0,
    falseHiddenRejected = 0,
    interiorCorrections = 0,
    boundVisibilityRejects = 0
}
for key, value in pairs(defaults) do
    if Handoff.Stats[key] == nil then Handoff.Stats[key] = value end
end

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function currentGraph()
    local state = LOD.RunManager and LOD.RunManager.State
    return state and state.Graph or nil
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
        "watcher-handoff-v2:%s:%s:%d", label, tostring(identity), watcher.LODWatcherUnifiedRollSerial))
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

local function traceVisible(watcher, target, point)
    if not point or not IsValid(watcher) or not livingPlayer(target) then return false end
    local tr = util.TraceLine({
        start = target:EyePos(),
        endpos = point,
        mask = MASK_SHOT,
        filter = function(ent)
            if ent == watcher or ent == target then return false end
            if IsValid(ent) and ent.LODHostile then return false end
            if IsValid(ent) and (ent:GetOwner() == target or ent:GetParent() == target) then return false end
            return true
        end
    })
    return not tr.Hit or tr.Fraction >= 0.995
end

-- A center-point visibility test is not sufficient for the scanner model. Sample
-- the world-space bounds so a wall cannot hide only the entity origin while part
-- of the visible model still projects into the player's corridor.
local function boundsVisibleToPlayer(watcher, target)
    if not IsValid(watcher) or not livingPlayer(target) then return false end

    local mins, maxs = watcher:WorldSpaceAABB()
    if not mins or not maxs then return traceVisible(watcher, target, watcher:WorldSpaceCenter()) end

    local cx = (mins.x + maxs.x) * 0.5
    local cy = (mins.y + maxs.y) * 0.5
    local cz = (mins.z + maxs.z) * 0.5
    local x0 = math.min(cx, mins.x + BOUNDS_INSET)
    local x1 = math.max(cx, maxs.x - BOUNDS_INSET)
    local y0 = math.min(cy, mins.y + BOUNDS_INSET)
    local y1 = math.max(cy, maxs.y - BOUNDS_INSET)
    local z0 = mins.z + (maxs.z - mins.z) * 0.28
    local z1 = mins.z + (maxs.z - mins.z) * 0.72

    local samples = {
        Vector(cx, cy, cz),
        Vector(x0, cy, cz), Vector(x1, cy, cz),
        Vector(cx, y0, cz), Vector(cx, y1, cz),
        Vector(x0, y0, z0), Vector(x1, y0, z0),
        Vector(x0, y1, z1), Vector(x1, y1, z1)
    }

    for _, point in ipairs(samples) do
        if traceVisible(watcher, target, point) then return true end
    end
    return false
end

local function interiorRecoveryWaypoint(watcher)
    local graph = currentGraph()
    if not graph then return nil, false end
    local cell = Navigator:WorldToCell(graph, watcher:GetPos())
    if not cell then return nil, false end

    local center = Motion:CellFloorPoint(cell, Navigator:CellCenter(cell))
    if not center then return nil, false end
    local delta = center - watcher:GetPos()
    delta.z = 0
    local interior = delta:Length2D() <= HIDDEN_CENTER_TOLERANCE
    return {
        pos = center,
        tolerance = 10,
        stair = false,
        watcherUnified = true,
        concealmentInterior = true
    }, interior
end

-- The unified controller may have entered hidden this frame using its legacy
-- origin-only LOS test. Refuse that state until the whole scanner is occluded and
-- its origin is safely near the logical cell center. If rejected, provide a legal
-- interior waypoint for the existing unified escape routine to execute next.
local function enforceConcealmentIntegrity(watcher)
    local escape = watcher.LODWatcherUnifiedEscape
    if not escape or escape.phase ~= "hidden" then return false end
    local target = escape.target
    if not livingPlayer(target) then return false end

    local centerWaypoint, interior = interiorRecoveryWaypoint(watcher)
    local boundsVisible = boundsVisibleToPlayer(watcher, target)
    if interior and not boundsVisible then return false end

    escape.phase = "seeking"
    escape.hiddenSince = nil
    escape.hiddenEndsAt = nil
    escape.nextVisibilityAt = 0
    escape.nextPlanAt = 0

    if centerWaypoint and not interior then
        escape.waypoints = {centerWaypoint}
        escape.index = 1
        Handoff.Stats.interiorCorrections = (Handoff.Stats.interiorCorrections or 0) + 1
    else
        -- Already at the center but still visible: force the unified planner to
        -- choose another graph cell rather than repeatedly accepting this wall.
        escape.waypoints = {}
        escape.index = 1
    end

    Handoff.Stats.falseHiddenRejected = (Handoff.Stats.falseHiddenRejected or 0) + 1
    if boundsVisible then
        Handoff.Stats.boundVisibilityRejects = (Handoff.Stats.boundVisibilityRejects or 0) + 1
    end
    watcher.LODMotionMode = boundsVisible
        and "watcher-concealment-visible-rejected"
        or "watcher-concealment-interior-correction"
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

        -- A Watcher that became exposed between behaviour frames must leave its
        -- hidden hold before the legacy origin-only check gets another chance to
        -- preserve it.
        enforceConcealmentIntegrity(self)

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

        -- baseBehaviourTick may enter hidden during this exact frame. Validate the
        -- new state immediately so the Watcher never spends a full concealment tick
        -- parked visibly in a wall edge.
        enforceConcealmentIntegrity(self)

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
        "completed=%d nativeEscapes=%d fallbackEscapes=%d invalidTargets=%d pending=%d falseHidden=%d interiorFix=%d boundsVisible=%d authority=transition+concealment-admission",
        Handoff.Stats.completionsObserved or 0,
        Handoff.Stats.nativeEscapes or 0,
        Handoff.Stats.fallbackEscapes or 0,
        Handoff.Stats.invalidTargets or 0,
        pending,
        Handoff.Stats.falseHiddenRejected or 0,
        Handoff.Stats.interiorCorrections or 0,
        Handoff.Stats.boundVisibilityRejects or 0)
    print("[LOD:WATCHER-HANDOFF] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

print("[LOD:WATCHER-HANDOFF] scan escape + concealment integrity armed")
