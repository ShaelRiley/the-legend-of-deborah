LOD = LOD or {}
LOD.Watcher = LOD.Watcher or {}
LOD.WatcherPolish = LOD.WatcherPolish or {}

local Watcher = LOD.Watcher
local Polish = LOD.WatcherPolish
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local Rolls = LOD.CombatRolls
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Watcher or not Navigator or not Motion or not cellKey then return end

-- Watcher locomotion audit / consolidation.
--
-- The earlier implementation had correct state ownership in principle, but two
-- Watcher-specific timer services advanced retreat/concealment at cadences that
-- differed from ordinary Motion V2. That could make the Scanner appear to stutter
-- and left unnecessary room for two state-specific callers to touch movement in
-- the same rendered interval. This module supersedes those services: all Watcher
-- physical travel now advances from the entity's ordinary Behaviour coroutine and
-- every Watcher MoveToward call is guarded to one physical step per server frame.
-- Motion V2 remains the sole physical movement kernel.

local LEGACY_RETREAT_TIMER = "LOD_WatcherCommittedRetreatService"
local LEGACY_CONCEAL_TIMER = "LOD_WatcherConcealmentService"
local MIN_SCAN_RANGE = 150
local RETREAT_TARGET_DISTANCE = 320
local COVER_SEARCH_DEPTH = 5
local VISIBILITY_INTERVAL = 0.25

local BLINK_SECONDS = 0.50
local CLOAK_DICE_COUNT = 2
local D6_PROFILE = {sides = 6, exploding = 6}
local MAX_FALLBACK_CHAIN = 64

local SPEED_NEAR_DISTANCE = 128
local SPEED_FAR_DISTANCE = 640
local PROXIMITY_SPEED_BONUS = 0.85
local RETREAT_SPEED_BONUS = 0.35
local RETREAT_SPEED_FLOOR = 1.55
local SPEED_SCALE_CAP = 2.20
local SPEED_APPROACH_STEP = 0.10

util.AddNetworkString("LOD_WatcherScanPulse")

Polish.Stats = Polish.Stats or {
    movementCalls = 0,
    duplicateMovementSuppressed = 0,
    retreatSteps = 0,
    concealmentSteps = 0,
    coverPlans = 0,
    coverReplans = 0,
    scanPulses = 0,
    escapeStarts = 0,
    escapeRolls = 0,
    lastEscapeSeconds = 0,
    lastEscapeRoll = "none",
    maxObservedSpeedScale = 1
}

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function currentState()
    local state = LOD.RunManager and LOD.RunManager.State
    return state, state and state.Graph or nil
end

local function livingPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if LOD.RunManager and LOD.RunManager.IsActivePlayer then
        return LOD.RunManager:IsActivePlayer(ply)
    end
    return true
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and tag.safe == true or false
end

local function targetEligible(watcher, graph, target)
    if not IsValid(watcher) or not livingPlayer(target) then return false end
    local from = Navigator:WorldToCell(graph, watcher:GetPos())
    local to = Navigator:WorldToCell(graph, target:GetPos())
    if not from or not to or from.z ~= to.z then return false end
    return not safeCell(graph, to)
end

local function horizontalDistance(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function sortedNeighborKeys(cell)
    local out = {}
    for neighborKey in pairs(cell and cell.neighbors or {}) do out[#out + 1] = neighborKey end
    table.sort(out)
    return out
end

local function playerCanSeePoint(watcher, target, point)
    if not IsValid(watcher) or not livingPlayer(target) or not point then return false end
    local tr = util.TraceLine({
        start = target:EyePos(),
        endpos = point + Vector(0, 0, 34),
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

local function playerCanSeeWatcher(watcher, target)
    return IsValid(watcher) and playerCanSeePoint(watcher, target, watcher:GetPos()) or false
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

local function rollEscapeDuration(watcher)
    local state = LOD.RunManager and LOD.RunManager.State
    local levelSeed = state and state.LevelSeed or 1
    watcher.LODWatcherEscapeRollSerial = (watcher.LODWatcherEscapeRollSerial or 0) + 1
    local identity = watcher.LODEncounterOrdinal
        or watcher.LODWanderSeed
        or watcher.LODEncounterId
        or watcher:EntIndex()
    local seed = LOD.Seeds.Derive(levelSeed, string.format(
        "watcher-escape:%s:%d", tostring(identity), watcher.LODWatcherEscapeRollSerial))
    local rng = LOD.RNG.New(seed)

    local total = 0
    local text = {}
    for index = 1, CLOAK_DICE_COUNT do
        local subtotal, values
        if Rolls and Rolls._RollExploding then
            subtotal, values = Rolls:_RollExploding(D6_PROFILE, rng)
        else
            subtotal, values = fallbackExplodingChain(rng)
        end
        total = total + (subtotal or 0)
        text[index] = table.concat(values or {}, ">")
    end

    total = math.max(CLOAK_DICE_COUNT, total)
    Polish.Stats.escapeRolls = (Polish.Stats.escapeRolls or 0) + 1
    Polish.Stats.lastEscapeSeconds = total
    Polish.Stats.lastEscapeRoll = table.concat(text, " | ")
    return total, Polish.Stats.lastEscapeRoll
end

local function activeTarget(watcher)
    local conceal = watcher.LODWatcherConcealment
    if conceal and livingPlayer(conceal.target) then return conceal.target end
    local retreat = watcher.LODWatcherRetreat
    if retreat and livingPlayer(retreat.target) then return retreat.target end
    if livingPlayer(watcher.LODTarget) then return watcher.LODTarget end
    return nil
end

local function desiredSpeedScale(watcher)
    local target = activeTarget(watcher)
    if not target then return 1 end

    local distance = horizontalDistance(watcher:GetPos(), target:GetPos())
    local span = math.max(1, SPEED_FAR_DISTANCE - SPEED_NEAR_DISTANCE)
    local closeness = 1 - math.Clamp((distance - SPEED_NEAR_DISTANCE) / span, 0, 1)
    local desired = 1 + PROXIMITY_SPEED_BONUS * closeness

    if watcher.LODWatcherRetreat or watcher.LODWatcherConcealment then
        desired = math.max(RETREAT_SPEED_FLOOR, desired + RETREAT_SPEED_BONUS)
    end
    return math.min(SPEED_SCALE_CAP, desired)
end

-- Wrap the single existing Motion V2 kernel rather than inventing another mover.
-- The temporary config multiplication is synchronous and restored before return;
-- it preserves all existing variance because it scales the already-resolved speed.
local baseMoveToward = Motion.MoveToward
function Motion:MoveToward(hostile, waypoint)
    if not IsValid(hostile) or hostile.LODArchetypeId ~= "watcher" then
        return baseMoveToward(self, hostile, waypoint)
    end

    local frame = FrameNumber()
    if hostile.LODWatcherMoveFrame == frame then
        Polish.Stats.duplicateMovementSuppressed = (Polish.Stats.duplicateMovementSuppressed or 0) + 1
        return false
    end
    hostile.LODWatcherMoveFrame = frame
    Polish.Stats.movementCalls = (Polish.Stats.movementCalls or 0) + 1

    local desired = desiredSpeedScale(hostile)
    local current = hostile.LODWatcherSpeedScale or desired
    current = math.Approach(current, desired, SPEED_APPROACH_STEP)
    hostile.LODWatcherSpeedScale = current
    Polish.Stats.maxObservedSpeedScale = math.max(Polish.Stats.maxObservedSpeedScale or 1, current)

    local cfg = hostile.LODConfig
    if not cfg then return baseMoveToward(self, hostile, waypoint) end
    local originalSpeed = cfg.speed or 135
    cfg.speed = originalSpeed * current
    local reached = baseMoveToward(self, hostile, waypoint)
    cfg.speed = originalSpeed
    return reached
end

local function restoreTarget(watcher, target)
    watcher.LODTarget = nil
    watcher.LODNextTargetRefresh = 0
    watcher.LODNextRouteRefresh = 0
    if livingPlayer(target) then
        watcher.LODTarget = target
        watcher.LODReturningHome = false
        watcher.LODNextTargetRefresh = CurTime() + 0.20
        Motion:FaceToward(watcher, target:GetPos())
    end
end

local function finishRetreat(watcher, target)
    watcher.LODWatcherRetreat = nil
    if Watcher.RetreatActive then Watcher.RetreatActive[watcher] = nil end
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
    Motion:Stop(watcher)
    watcher.LODMotionMode = "ground"
    restoreTarget(watcher, target)
    Watcher.Stats.retreatCompletes = (Watcher.Stats.retreatCompletes or 0) + 1
end

local function runRetreatStep(watcher, graph)
    local retreat = watcher.LODWatcherRetreat
    if not retreat then return false end
    local target = retreat.target
    Polish.Stats.retreatSteps = (Polish.Stats.retreatSteps or 0) + 1

    if not targetEligible(watcher, graph, target) then
        finishRetreat(watcher, nil)
        return false
    end

    local liveDistance = horizontalDistance(watcher:GetPos(), target:GetPos())
    if liveDistance >= RETREAT_TARGET_DISTANCE then
        finishRetreat(watcher, target)
        return true
    end

    local waypoint = retreat.waypoints and retreat.waypoints[retreat.index or 1]
    if waypoint and not retreat.blocked then
        local reached = Motion:MoveToward(watcher, waypoint)
        watcher.LODMotionMode = "watcher-retreat-unified"
        if reached then retreat.index = (retreat.index or 1) + 1 end
        return true
    end

    -- Give the existing synchronous close-range continuity repair one chance to
    -- append a legal segment; Motion:Stop owns that plan repair but never movement.
    Motion:Stop(watcher)
    waypoint = retreat.waypoints and retreat.waypoints[retreat.index or 1]
    if waypoint and not retreat.blocked then return true end

    if liveDistance >= MIN_SCAN_RANGE then
        finishRetreat(watcher, target)
    else
        retreat.blocked = true
        watcher.LODMotionMode = "watcher-retreat-blocked"
    end
    return true
end

local function reconstructWaypoints(graph, startKey, goalKey, previous)
    if not goalKey or goalKey == startKey then return nil end
    local reverse = {goalKey}
    local cursor = goalKey
    while cursor ~= startKey do
        cursor = previous[cursor]
        if not cursor then return nil end
        reverse[#reverse + 1] = cursor
    end

    local path = {}
    for index = #reverse, 1, -1 do
        local cell = graph.Cells[reverse[index]]
        if not cell then return nil end
        path[#path + 1] = cell
    end
    local waypoints = Navigator:PathToWaypoints(graph, path)
    return #waypoints > 0 and waypoints or nil
end

-- One bounded cover search per completed movement leg. It stops at the nearest
-- graph depth containing actual geometric occlusion, preferring the candidate
-- farthest from the scanned player at that depth. No recurring maze search exists.
local function buildCoverPlan(watcher, graph, target)
    local startCell = Navigator:WorldToCell(graph, watcher:GetPos())
    local targetCell = Navigator:WorldToCell(graph, target:GetPos())
    if not startCell or not targetCell or startCell.z ~= targetCell.z then return nil, false end

    local startKey = keyOf(startCell)
    local queue = {{key = startKey, depth = 0}}
    local head = 1
    local seen = {[startKey] = true}
    local previous = {}
    local targetPos = target:GetPos()
    local hiddenDepth
    local hiddenCandidates = {}
    local fallbackKey, fallbackDistance = nil, -1

    while head <= #queue do
        local item = queue[head]
        head = head + 1
        if hiddenDepth and item.depth > hiddenDepth then break end
        local cell = graph.Cells[item.key]
        if cell then
            if item.depth > 0 and not safeCell(graph, cell) then
                local center = Motion:CellFloorPoint(cell, Navigator:CellCenter(cell))
                    or Navigator:CellCenter(cell)
                local distance = horizontalDistance(center, targetPos)
                if distance > fallbackDistance then
                    fallbackKey = item.key
                    fallbackDistance = distance
                end
                if not playerCanSeePoint(watcher, target, center) then
                    hiddenDepth = hiddenDepth or item.depth
                    if item.depth == hiddenDepth then
                        hiddenCandidates[#hiddenCandidates + 1] = {key = item.key, distance = distance}
                    end
                end
            end

            if item.depth < COVER_SEARCH_DEPTH and not hiddenDepth then
                for _, neighborKey in ipairs(sortedNeighborKeys(cell)) do
                    local neighbor = graph.Cells[neighborKey]
                    if neighbor and neighbor.z == startCell.z and not seen[neighborKey]
                        and not safeCell(graph, neighbor)
                        and Navigator:CanTraverse(graph, item.key, neighborKey)
                    then
                        seen[neighborKey] = true
                        previous[neighborKey] = item.key
                        queue[#queue + 1] = {key = neighborKey, depth = item.depth + 1}
                    end
                end
            end
        end
    end

    local goalKey = fallbackKey
    local hiddenGoal = false
    if #hiddenCandidates > 0 then
        table.sort(hiddenCandidates, function(a, b)
            if a.distance == b.distance then return a.key < b.key end
            return a.distance > b.distance
        end)
        goalKey = hiddenCandidates[1].key
        hiddenGoal = true
    end

    Polish.Stats.coverPlans = (Polish.Stats.coverPlans or 0) + 1
    local waypoints = reconstructWaypoints(graph, startKey, goalKey, previous)
    return waypoints, waypoints ~= nil and hiddenGoal
end

local function clearConcealment(watcher, target, now, completed)
    watcher.LODWatcherConcealment = nil
    if LOD.WatcherConcealment and LOD.WatcherConcealment.Active then
        LOD.WatcherConcealment.Active[watcher] = nil
    end
    watcher.LODNextWatcherScan = completed and now or (now + 0.35)
    watcher.LODTarget = completed and livingPlayer(target) and target or nil
    watcher.LODReturningHome = false
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
    watcher.LODNextTargetRefresh = 0
    watcher.LODNextRouteRefresh = 0
    watcher:SetNW2Float("LOD_WatcherBlinkUntil", 0)
    watcher:SetNW2Float("LOD_WatcherInvisibleUntil", 0)
    if completed then
        Watcher.Stats.concealmentCompletes = (Watcher.Stats.concealmentCompletes or 0) + 1
        if LOD.WatcherConcealment and LOD.WatcherConcealment.Stats then
            local stats = LOD.WatcherConcealment.Stats
            stats.completions = (stats.completions or 0) + 1
        end
    end
end

local function armEscapePresentation(watcher, conceal, now)
    if conceal.LODPolishEscapeArmed then return end
    conceal.LODPolishEscapeArmed = true
    local duration, rollText = rollEscapeDuration(watcher)
    conceal.escapeDuration = duration
    conceal.escapeRollText = rollText
    conceal.escapeBlinkUntil = now + BLINK_SECONDS
    conceal.escapeInvisibleUntil = conceal.escapeBlinkUntil + duration
    conceal.polishPhase = watcher.LODWatcherRetreat and "retreat" or "planning"
    conceal.polishWaypoints = {}
    conceal.polishIndex = 1
    conceal.polishHiddenSince = nil
    conceal.polishHiddenEndsAt = nil
    conceal.polishNextVisibilityAt = 0
    conceal.polishPlanHasHiddenGoal = false

    watcher.LODWatcherSpeedScale = math.max(watcher.LODWatcherSpeedScale or 1, 1.80)
    watcher:SetNW2Float("LOD_WatcherBlinkUntil", conceal.escapeBlinkUntil)
    watcher:SetNW2Float("LOD_WatcherInvisibleUntil", conceal.escapeInvisibleUntil)
    watcher:SetNW2Float("LOD_WatcherEscapeSeconds", duration)
    Polish.Stats.escapeStarts = (Polish.Stats.escapeStarts or 0) + 1
end

local function enterHiddenHold(watcher, conceal, now)
    watcher.LODWatcherRetreat = nil
    if Watcher.RetreatActive then Watcher.RetreatActive[watcher] = nil end
    Motion:Stop(watcher)
    watcher.LODMotionMode = "watcher-concealment-hold"
    conceal.polishPhase = "hidden"
    conceal.polishHiddenSince = now
    conceal.polishHiddenEndsAt = now + (conceal.duration or 8)
    conceal.polishNextVisibilityAt = now + VISIBILITY_INTERVAL
    conceal.polishWaypoints = {}
    conceal.polishIndex = 1
end

local function beginCoverPlan(watcher, graph, conceal, replan)
    local waypoints, hiddenGoal = buildCoverPlan(watcher, graph, conceal.target)
    conceal.polishWaypoints = waypoints or {}
    conceal.polishIndex = 1
    conceal.polishPlanHasHiddenGoal = hiddenGoal == true
    if replan then Polish.Stats.coverReplans = (Polish.Stats.coverReplans or 0) + 1 end
    if waypoints then
        conceal.polishPhase = "seeking"
        return true
    end
    conceal.polishPhase = "blocked"
    Motion:Stop(watcher)
    watcher.LODMotionMode = "watcher-concealment-blocked"
    return false
end

local function runConcealmentStep(watcher, graph, now)
    local conceal = watcher.LODWatcherConcealment
    if not conceal then return false end
    Polish.Stats.concealmentSteps = (Polish.Stats.concealmentSteps or 0) + 1
    local target = conceal.target

    if not targetEligible(watcher, graph, target) then
        clearConcealment(watcher, nil, now, false)
        return false
    end

    armEscapePresentation(watcher, conceal, now)

    if watcher.LODWatcherRetreat then
        runRetreatStep(watcher, graph)
        -- The committed range-reset may have ended this tick. If geometry already
        -- hid the Watcher, begin the authoritative 8d6 concealment immediately.
        if not watcher.LODWatcherRetreat and not playerCanSeeWatcher(watcher, target) then
            enterHiddenHold(watcher, conceal, now)
        end
        return true
    end

    local phase = conceal.polishPhase or "planning"
    if phase == "hidden" then
        if now < (conceal.polishNextVisibilityAt or 0) then return true end
        conceal.polishNextVisibilityAt = now + VISIBILITY_INTERVAL
        if playerCanSeeWatcher(watcher, target) then
            if LOD.WatcherConcealment and LOD.WatcherConcealment.Stats then
                local stats = LOD.WatcherConcealment.Stats
                stats.reexposures = (stats.reexposures or 0) + 1
            end
            conceal.polishHiddenSince = nil
            conceal.polishHiddenEndsAt = nil
            beginCoverPlan(watcher, graph, conceal, true)
            return true
        end
        if conceal.polishHiddenEndsAt and now >= conceal.polishHiddenEndsAt then
            clearConcealment(watcher, target, now, true)
        end
        return true
    end

    if phase == "planning" then
        beginCoverPlan(watcher, graph, conceal, false)
        return true
    end

    if phase == "blocked" then
        -- No legal local cover plan exists. Stay put rather than hammering the
        -- graph every tick; a player/floor/state transition will release the state.
        return true
    end

    local waypoint = conceal.polishWaypoints and conceal.polishWaypoints[conceal.polishIndex or 1]
    if waypoint then
        local reached = Motion:MoveToward(watcher, waypoint)
        watcher.LODMotionMode = "watcher-concealment-unified"
        if reached then conceal.polishIndex = (conceal.polishIndex or 1) + 1 end
        return true
    end

    if not playerCanSeeWatcher(watcher, target) then
        enterHiddenHold(watcher, conceal, now)
    else
        beginCoverPlan(watcher, graph, conceal, true)
    end
    return true
end

local function emitScanPulse(watcher, target)
    if not IsValid(watcher) then return end
    Polish.Stats.scanPulses = (Polish.Stats.scanPulses or 0) + 1
    watcher:EmitSound("npc/scanner/scanner_photo1.wav", 78, 88, 0.92, CHAN_AUTO)
    net.Start("LOD_WatcherScanPulse")
    net.WriteEntity(watcher)
    net.WriteEntity(IsValid(target) and target or NULL)
    net.Broadcast()
end

-- Disable the old Watcher movement schedulers. The concealment module's local
-- ensureService() only checks timer.Exists, so a paused sentinel prevents it from
-- recreating its former 10 Hz mover without consuming recurring runtime work.
timer.Remove(LEGACY_RETREAT_TIMER)
timer.Remove(LEGACY_CONCEAL_TIMER)
timer.Create(LEGACY_CONCEAL_TIMER, 1, 0, function() end)
timer.Pause(LEGACY_CONCEAL_TIMER)

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherUnifiedPolishInstalled then return false end
    class.LODWatcherUnifiedPolishInstalled = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId == "watcher" then
            self.LODWatcherSpeedScale = 1
            self.LODWatcherMoveFrame = nil
            self.LODWatcherEscapeRollSerial = 0
            self:SetNW2Float("LOD_WatcherBlinkUntil", 0)
            self:SetNW2Float("LOD_WatcherInvisibleUntil", 0)
            self:SetNW2Float("LOD_WatcherEscapeSeconds", 0)
        end
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId ~= "watcher" then return baseBehaviourTick(self) end

        local state, graph = currentState()
        if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared then
            return baseBehaviourTick(self)
        end

        if self.LODWatcherConcealment then
            runConcealmentStep(self, graph, CurTime())
            return
        end

        if self.LODWatcherRetreat then
            runRetreatStep(self, graph)
            return
        end

        local completedBefore = Watcher.Stats.scansCompleted or 0
        local scanTarget = self.LODWatcherScan and self.LODWatcherScan.target or self.LODTarget
        local result = baseBehaviourTick(self)
        local completedAfter = Watcher.Stats.scansCompleted or 0
        if completedAfter > completedBefore then
            local conceal = self.LODWatcherConcealment
            local target = conceal and conceal.target or scanTarget
            if conceal then armEscapePresentation(self, conceal, CurTime()) end
            emitScanPulse(self, target)
        end
        return result
    end

    local baseOnRemove = class.OnRemove
    function class:OnRemove()
        if self.LODArchetypeId == "watcher" then
            if Watcher.RetreatActive then Watcher.RetreatActive[self] = nil end
            if LOD.WatcherConcealment and LOD.WatcherConcealment.Active then
                LOD.WatcherConcealment.Active[self] = nil
            end
        end
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_WatcherUnifiedPolishInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)

concommand.Add("lod_watcher_motion_audit", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local watchers, retreating, concealing = 0, 0, 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and not hostile.LODDead and hostile.LODArchetypeId == "watcher" then
            watchers = watchers + 1
            if hostile.LODWatcherRetreat then retreating = retreating + 1 end
            if hostile.LODWatcherConcealment then concealing = concealing + 1 end
        end
    end

    local line = string.format(
        "watchers=%d retreating=%d concealing=%d moveCalls=%d duplicateMovesSuppressed=%d retreatSteps=%d concealSteps=%d coverPlans=%d replans=%d scanPulses=%d lastEscape=2d6!=%ds[%s] maxSpeedScale=%.2f legacyRetreatTimer=%s legacyConcealTimerPaused=%s authority=Behaviour+MotionV2",
        watchers, retreating, concealing,
        Polish.Stats.movementCalls or 0,
        Polish.Stats.duplicateMovementSuppressed or 0,
        Polish.Stats.retreatSteps or 0,
        Polish.Stats.concealmentSteps or 0,
        Polish.Stats.coverPlans or 0,
        Polish.Stats.coverReplans or 0,
        Polish.Stats.scanPulses or 0,
        Polish.Stats.lastEscapeSeconds or 0,
        tostring(Polish.Stats.lastEscapeRoll or "none"),
        Polish.Stats.maxObservedSpeedScale or 1,
        tostring(timer.Exists(LEGACY_RETREAT_TIMER)),
        tostring(timer.Exists(LEGACY_CONCEAL_TIMER) and timer.RepsLeft(LEGACY_CONCEAL_TIMER) ~= nil))
    print("[LOD:WATCHER-MOTION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)