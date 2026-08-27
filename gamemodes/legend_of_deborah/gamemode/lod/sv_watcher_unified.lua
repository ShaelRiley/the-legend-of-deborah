LOD = LOD or {}
LOD.WatcherUnified = LOD.WatcherUnified or {}

local Unified = LOD.WatcherUnified
local Watcher = LOD.Watcher
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local Rolls = LOD.CombatRolls
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Watcher or not Navigator or not Motion or not cellKey then return end

-- Single-authority Watcher controller. Behaviour selects state; Motion V2 alone
-- owns physical movement. The complete routine is:
-- acquire -> approach -> scan standoff -> 1.25s scan -> 0.5s blink -> 2d6! cloak
-- while fleeing -> actual LOS break -> continuous 8d6! concealment -> disengage.
local SCAN_STANDOFF = 300
local MIN_SCAN_RANGE = 150
local BACKOFF_RELEASE_RANGE = 220
local ESCAPE_SEARCH_DEPTH = 6
local VISIBILITY_INTERVAL = 0.25
local GRAPH_RETRY_SECONDS = 0.20
local POST_HIDE_DISENGAGE_SECONDS = 3.0
local ABORT_DISENGAGE_SECONDS = 0.75

local BLINK_SECONDS = 0.50
local CLOAK_DICE_COUNT = 2
local HIDE_DICE_COUNT = 8
local D6_PROFILE = {sides = 6, exploding = 6}
local MAX_FALLBACK_CHAIN = 64

local SPEED_NEAR_DISTANCE = 128
local SPEED_FAR_DISTANCE = 640
local PROXIMITY_SPEED_BONUS = 0.85
local ESCAPE_SPEED_BONUS = 0.45
local ESCAPE_SPEED_FLOOR = 1.65
local SPEED_SCALE_CAP = 2.20
local SPEED_APPROACH_STEP = 0.12

util.AddNetworkString("LOD_WatcherScanPulse")

Unified.Stats = Unified.Stats or {}
local defaults = {
    behaviourTicks = 0,
    scanDispatches = 0,
    scanPulses = 0,
    standoffHolds = 0,
    movementCalls = 0,
    escapeStarts = 0,
    escapeMoves = 0,
    escapePlans = 0,
    escapeReplans = 0,
    blockedPlans = 0,
    hiddenStarts = 0,
    reexposures = 0,
    hideCompletes = 0,
    disengageStarts = 0,
    backoffStarts = 0,
    backoffMoves = 0,
    backoffExtensions = 0,
    instanceBinds = 0,
    lastCloakSeconds = 0,
    lastCloakRoll = "none",
    lastHideSeconds = 0,
    lastHideRoll = "none",
    maxSpeedScale = 1
}
for key, value in pairs(defaults) do
    if Unified.Stats[key] == nil then Unified.Stats[key] = value end
end

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
    local wc = Navigator:WorldToCell(graph, watcher:GetPos())
    local tc = Navigator:WorldToCell(graph, target:GetPos())
    if not wc or not tc or wc.z ~= tc.z then return false end
    return not safeCell(graph, tc)
end

local function horizontalDistance(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function sharedLOS(watcher, target)
    if not IsValid(watcher) or not livingPlayer(target) then return false end
    if watcher._HasLineOfSight then return watcher:_HasLineOfSight(target) end
    local tr = util.TraceLine({
        start = watcher:WorldSpaceCenter(),
        endpos = target:EyePos(),
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
    return playerCanSeePoint(watcher, target, watcher:GetPos())
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
        "watcher-unified-v2:%s:%s:%d", label, tostring(identity), watcher.LODWatcherUnifiedRollSerial))
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

local function emitScanPulse(watcher, target)
    if not IsValid(watcher) then return end
    Unified.Stats.scanPulses = (Unified.Stats.scanPulses or 0) + 1
    watcher:EmitSound("ambient/energy/zap1.wav", 76, 112, 0.72, CHAN_AUTO)
    net.Start("LOD_WatcherScanPulse")
    net.WriteEntity(watcher)
    net.WriteEntity(IsValid(target) and target or NULL)
    net.Broadcast()
end

local function cancelActiveScan(watcher, cooldown)
    if not watcher.LODWatcherScan then return false end
    watcher.LODWatcherScan = nil
    watcher.LODNextWatcherScan = CurTime() + (cooldown or 0.35)
    net.Start("LOD_WatcherScanState")
    net.WriteEntity(watcher)
    net.WriteBool(false)
    net.Broadcast()
    return true
end

local function sortedNeighborKeys(cell)
    local out = {}
    for neighborKey in pairs(cell and cell.neighbors or {}) do out[#out + 1] = neighborKey end
    table.sort(out)
    return out
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

-- Immediate same-cell away/tangential recovery. This is intentionally attempted
-- before a graph search whenever the Watcher is inside its minimum scan range.
local function localFleeWaypoint(watcher, graph, target)
    local cell = Navigator:WorldToCell(graph, watcher:GetPos())
    if not cell or not livingPlayer(target) then return nil end

    local pos = watcher:GetPos()
    local targetPos = target:GetPos()
    local away = Vector(pos.x - targetPos.x, pos.y - targetPos.y, 0)
    if away:LengthSqr() <= 0.01 then away = -watcher:GetForward() end
    if away:LengthSqr() <= 0.01 then away = Vector(1, 0, 0) end
    away:Normalize()
    local lateral = Vector(-away.y, away.x, 0)

    local directions = {
        away,
        (away + lateral * 0.70):GetNormalized(),
        (away - lateral * 0.70):GetNormalized(),
        lateral,
        -lateral
    }

    local best, bestScore
    for index, dir in ipairs(directions) do
        local candidate = Motion:CellFloorPoint(cell, pos + dir * 220)
        if candidate then
            local travel = horizontalDistance(candidate, pos)
            if travel >= 24 then
                local score = horizontalDistance(candidate, targetPos) * 10 + travel - index * 0.01
                if not bestScore or score > bestScore then
                    best = candidate
                    bestScore = score
                end
            end
        end
    end

    if not best then return nil end
    return {pos = best, tolerance = 10, stair = false, watcherUnified = true}
end

-- One committed same-floor retreat. Prefer the shallowest cell that actually
-- breaks geometric LOS, then the farthest such cell; otherwise choose the farthest
-- legal cell in the bounded search.
local function buildEscapePlan(watcher, graph, target)
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
    local hidden = {}
    local fallbackKey, fallbackDistance = nil, -1

    while head <= #queue do
        local item = queue[head]
        head = head + 1
        if hiddenDepth and item.depth > hiddenDepth then break end

        local cell = graph.Cells[item.key]
        if cell then
            if item.depth > 0 and not safeCell(graph, cell) then
                local center = Motion:CellFloorPoint(cell, Navigator:CellCenter(cell))
                local distance = horizontalDistance(center, targetPos)
                if distance > fallbackDistance then
                    fallbackKey = item.key
                    fallbackDistance = distance
                end
                if not playerCanSeePoint(watcher, target, center) then
                    hiddenDepth = hiddenDepth or item.depth
                    if item.depth == hiddenDepth then
                        hidden[#hidden + 1] = {key = item.key, distance = distance}
                    end
                end
            end

            if item.depth < ESCAPE_SEARCH_DEPTH and not hiddenDepth then
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
    if #hidden > 0 then
        table.sort(hidden, function(a, b)
            if a.distance == b.distance then return a.key < b.key end
            return a.distance > b.distance
        end)
        goalKey = hidden[1].key
        hiddenGoal = true
    end

    local waypoints = reconstructWaypoints(graph, startKey, goalKey, previous)
    if not waypoints then
        local localWaypoint = localFleeWaypoint(watcher, graph, target)
        if localWaypoint then waypoints = {localWaypoint} end
    end

    Unified.Stats.escapePlans = (Unified.Stats.escapePlans or 0) + 1
    if not waypoints then Unified.Stats.blockedPlans = (Unified.Stats.blockedPlans or 0) + 1 end
    return waypoints, hiddenGoal
end

local function desiredSpeedScale(watcher, target, escaping)
    if not livingPlayer(target) then return 1 end
    local distance = horizontalDistance(watcher:GetPos(), target:GetPos())
    local span = math.max(1, SPEED_FAR_DISTANCE - SPEED_NEAR_DISTANCE)
    local closeness = 1 - math.Clamp((distance - SPEED_NEAR_DISTANCE) / span, 0, 1)
    local desired = 1 + PROXIMITY_SPEED_BONUS * closeness
    if escaping then desired = math.max(ESCAPE_SPEED_FLOOR, desired + ESCAPE_SPEED_BONUS) end
    return math.min(SPEED_SCALE_CAP, desired)
end

local function moveWatcher(watcher, waypoint, target, escaping)
    if not waypoint then return false end
    local desired = desiredSpeedScale(watcher, target, escaping)
    local current = watcher.LODWatcherUnifiedSpeedScale or desired
    current = math.Approach(current, desired, SPEED_APPROACH_STEP)
    watcher.LODWatcherUnifiedSpeedScale = current
    Unified.Stats.maxSpeedScale = math.max(Unified.Stats.maxSpeedScale or 1, current)

    local cfg = watcher.LODConfig
    if not cfg then return Motion:MoveToward(watcher, waypoint) end
    local originalSpeed = cfg.speed or 135
    cfg.speed = originalSpeed * current
    local reached = Motion:MoveToward(watcher, waypoint)
    cfg.speed = originalSpeed
    Unified.Stats.movementCalls = (Unified.Stats.movementCalls or 0) + 1
    return reached
end

local function resetOrdinaryRoute(watcher)
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
    watcher.LODNextRouteRefresh = 0
end

local function startDisengage(watcher, now, duration)
    watcher.LODWatcherUnifiedDisengageUntil = now + math.max(0, duration or 0)
    watcher.LODTarget = nil
    watcher.LODReturningHome = true
    watcher.LODNextTargetRefresh = watcher.LODWatcherUnifiedDisengageUntil
    resetOrdinaryRoute(watcher)
    Unified.Stats.disengageStarts = (Unified.Stats.disengageStarts or 0) + 1
end

local function runReturnRoute(watcher, graph, mode)
    watcher.LODTarget = nil
    watcher.LODReturningHome = true
    watcher:_RefreshRoute(graph)
    local waypoint = watcher:_AdvanceWaypoint()
    if waypoint then
        moveWatcher(watcher, waypoint, nil, false)
        watcher.LODMotionMode = mode or "watcher-return-home"
        return true
    end
    Motion:Stop(watcher)
    watcher.LODMotionMode = (mode or "watcher-return-home") .. "-idle"
    return false
end

local function runDisengage(watcher, graph, now)
    local untilTime = watcher.LODWatcherUnifiedDisengageUntil or 0
    if untilTime <= now then
        watcher.LODWatcherUnifiedDisengageUntil = 0
        watcher.LODNextTargetRefresh = 0
        return false
    end
    runReturnRoute(watcher, graph, "watcher-postscan-disengage")
    return true
end

local function enterHidden(watcher, escape, now)
    Motion:Stop(watcher)
    escape.phase = "hidden"
    escape.hiddenSince = now
    escape.hiddenEndsAt = now + escape.hideDuration
    escape.nextVisibilityAt = now + VISIBILITY_INTERVAL
    escape.waypoints = {}
    escape.index = 1
    watcher.LODMotionMode = "watcher-hidden-hold"
    Unified.Stats.hiddenStarts = (Unified.Stats.hiddenStarts or 0) + 1
end

local function clearEscape(watcher, now, completed)
    watcher.LODWatcherUnifiedEscape = nil
    watcher.LODWatcherUnifiedBackoff = nil
    watcher.LODWatcherUnifiedSpeedScale = 1
    watcher:SetNW2Float("LOD_WatcherBlinkUntil", 0)
    watcher:SetNW2Float("LOD_WatcherInvisibleUntil", 0)
    watcher:SetNW2Float("LOD_WatcherEscapeSeconds", 0)
    resetOrdinaryRoute(watcher)

    if completed then
        Unified.Stats.hideCompletes = (Unified.Stats.hideCompletes or 0) + 1
        watcher.LODNextWatcherScan = now + POST_HIDE_DISENGAGE_SECONDS
        startDisengage(watcher, now, POST_HIDE_DISENGAGE_SECONDS)
    else
        watcher.LODNextWatcherScan = now + ABORT_DISENGAGE_SECONDS
        startDisengage(watcher, now, ABORT_DISENGAGE_SECONDS)
    end
end

local function planEscape(watcher, graph, escape, replan)
    local waypoints, hiddenGoal = buildEscapePlan(watcher, graph, escape.target)
    escape.waypoints = waypoints or {}
    escape.index = 1
    escape.hiddenGoal = hiddenGoal == true
    escape.nextPlanAt = 0
    if replan then Unified.Stats.escapeReplans = (Unified.Stats.escapeReplans or 0) + 1 end
    if not waypoints then
        escape.nextPlanAt = CurTime() + GRAPH_RETRY_SECONDS
        watcher.LODMotionMode = "watcher-escape-blocked"
        Motion:Stop(watcher)
        return false
    end
    escape.phase = "seeking"
    return true
end

local function beginEscape(watcher, graph, target)
    local now = CurTime()
    local cloakDuration, cloakRoll = rollExplodingDice(watcher, "cloak", CLOAK_DICE_COUNT)
    local hideDuration, hideRoll = rollExplodingDice(watcher, "hide", HIDE_DICE_COUNT)

    local escape = {
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
        nextPlanAt = 0
    }

    watcher.LODWatcherUnifiedEscape = escape
    watcher.LODWatcherUnifiedBackoff = nil
    watcher.LODNextWatcherScan = math.huge
    watcher.LODNextTargetRefresh = math.huge
    watcher.LODWatcherUnifiedSpeedScale = math.max(watcher.LODWatcherUnifiedSpeedScale or 1, 1.80)
    resetOrdinaryRoute(watcher)

    watcher:SetNW2Float("LOD_WatcherBlinkUntil", escape.blinkUntil)
    watcher:SetNW2Float("LOD_WatcherInvisibleUntil", escape.invisibleUntil)
    watcher:SetNW2Float("LOD_WatcherEscapeSeconds", cloakDuration)

    Unified.Stats.escapeStarts = (Unified.Stats.escapeStarts or 0) + 1
    Unified.Stats.lastCloakSeconds = cloakDuration
    Unified.Stats.lastCloakRoll = cloakRoll
    Unified.Stats.lastHideSeconds = hideDuration
    Unified.Stats.lastHideRoll = hideRoll

    emitScanPulse(watcher, target)
    planEscape(watcher, graph, escape, false)
    return escape
end

local function runEscape(watcher, graph, now)
    local escape = watcher.LODWatcherUnifiedEscape
    if not escape then return false end
    local target = escape.target

    if not targetEligible(watcher, graph, target) then
        clearEscape(watcher, now, false)
        return true
    end

    if escape.phase == "hidden" then
        if now < (escape.nextVisibilityAt or 0) then return true end
        escape.nextVisibilityAt = now + VISIBILITY_INTERVAL

        if playerCanSeeWatcher(watcher, target) then
            -- Reset elapsed concealment without rerolling the original 8d6! value.
            escape.hiddenSince = nil
            escape.hiddenEndsAt = nil
            escape.phase = "seeking"
            Unified.Stats.reexposures = (Unified.Stats.reexposures or 0) + 1
            planEscape(watcher, graph, escape, true)
            return true
        end

        if escape.hiddenEndsAt and now >= escape.hiddenEndsAt then
            clearEscape(watcher, now, true)
        end
        return true
    end

    if now >= (escape.nextVisibilityAt or 0) then
        escape.nextVisibilityAt = now + VISIBILITY_INTERVAL
        if not playerCanSeeWatcher(watcher, target) then
            enterHidden(watcher, escape, now)
            return true
        end
    end

    local waypoint = escape.waypoints and escape.waypoints[escape.index or 1]
    if not waypoint then
        -- The player may have moved after route commitment. Extend the escape rather
        -- than returning to pursuit or waiting beside the target.
        if now >= (escape.nextPlanAt or 0) then
            planEscape(watcher, graph, escape, true)
            waypoint = escape.waypoints and escape.waypoints[escape.index or 1]
        end
        if not waypoint then return true end
    end

    local reached = moveWatcher(watcher, waypoint, target, true)
    watcher.LODMotionMode = "watcher-escape-unified"
    Unified.Stats.escapeMoves = (Unified.Stats.escapeMoves or 0) + 1
    if reached then escape.index = (escape.index or 1) + 1 end
    return true
end

local function extendBackoff(watcher, graph, target, backoff)
    local localWaypoint = localFleeWaypoint(watcher, graph, target)
    if localWaypoint then
        backoff.waypoints = {localWaypoint}
        backoff.index = 1
        Unified.Stats.backoffExtensions = (Unified.Stats.backoffExtensions or 0) + 1
        return true
    end

    if CurTime() < (backoff.nextGraphPlanAt or 0) then return false end
    local waypoints = select(1, buildEscapePlan(watcher, graph, target))
    backoff.waypoints = waypoints or {}
    backoff.index = 1
    backoff.nextGraphPlanAt = CurTime() + GRAPH_RETRY_SECONDS
    if waypoints then
        Unified.Stats.backoffExtensions = (Unified.Stats.backoffExtensions or 0) + 1
        return true
    end
    return false
end

local function beginBackoff(watcher, graph, target)
    local backoff = {
        target = target,
        waypoints = {},
        index = 1,
        nextGraphPlanAt = 0
    }
    watcher.LODWatcherUnifiedBackoff = backoff
    Unified.Stats.backoffStarts = (Unified.Stats.backoffStarts or 0) + 1
    extendBackoff(watcher, graph, target, backoff)
    return backoff
end

local function runBackoff(watcher, graph, target)
    local backoff = watcher.LODWatcherUnifiedBackoff
    if not backoff or backoff.target ~= target then
        backoff = beginBackoff(watcher, graph, target)
    end

    local distance = horizontalDistance(watcher:GetPos(), target:GetPos())
    if distance >= BACKOFF_RELEASE_RANGE then
        watcher.LODWatcherUnifiedBackoff = nil
        watcher.LODNextWatcherScan = math.max(watcher.LODNextWatcherScan or 0, CurTime() + 0.15)
        Motion:Stop(watcher)
        watcher.LODMotionMode = "watcher-backoff-complete"
        return false
    end

    local waypoint = backoff.waypoints and backoff.waypoints[backoff.index or 1]
    if not waypoint then
        -- If a leg is exhausted while still too close, extend immediately with
        -- another legal away/tangential movement segment.
        extendBackoff(watcher, graph, target, backoff)
        waypoint = backoff.waypoints and backoff.waypoints[backoff.index or 1]
    end

    if not waypoint then
        Motion:Stop(watcher)
        watcher.LODMotionMode = "watcher-backoff-blocked"
        return true
    end

    local reached = moveWatcher(watcher, waypoint, target, true)
    watcher.LODMotionMode = "watcher-backoff"
    Unified.Stats.backoffMoves = (Unified.Stats.backoffMoves or 0) + 1
    if reached then backoff.index = (backoff.index or 1) + 1 end
    return true
end

local function approachTarget(watcher, graph, target)
    watcher:_RefreshRoute(graph)
    local waypoint = watcher:_AdvanceWaypoint()

    if not waypoint then
        local tc = Navigator:WorldToCell(graph, target:GetPos())
        if tc then
            local safe = Motion:CellFloorPoint(tc, target:GetPos())
            if safe then waypoint = {pos = safe, tolerance = 18, stair = false, watcherUnified = true} end
        end
    end

    if waypoint then
        moveWatcher(watcher, waypoint, target, false)
        watcher.LODMotionMode = "watcher-approach"
    else
        Motion:Stop(watcher)
        watcher.LODMotionMode = "watcher-approach-blocked"
    end
end

local function holdStandoff(watcher, target, reason)
    watcher.LODWatcherUnifiedSpeedScale = 1
    Motion:Stop(watcher)
    if Motion.FaceToward then Motion:FaceToward(watcher, target:GetPos()) end
    watcher.LODMotionMode = reason or "watcher-standoff"
    Unified.Stats.standoffHolds = (Unified.Stats.standoffHolds or 0) + 1
end

local function dispatchWatcherScan(watcher)
    if not watcher._RunWatcherTick then return false end
    watcher.LODWatcherDispatchFrame = nil
    Unified.Stats.scanDispatches = (Unified.Stats.scanDispatches or 0) + 1
    return watcher:_RunWatcherTick()
end

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherUnifiedControllerInstalled then return false end
    class.LODWatcherUnifiedControllerInstalled = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId ~= "watcher" then return end
        self.LODWatcherUnifiedEscape = nil
        self.LODWatcherUnifiedBackoff = nil
        self.LODWatcherUnifiedDisengageUntil = 0
        self.LODWatcherUnifiedSpeedScale = 1
        self.LODWatcherUnifiedRollSerial = 0
        self:SetNW2Float("LOD_WatcherBlinkUntil", 0)
        self:SetNW2Float("LOD_WatcherInvisibleUntil", 0)
        self:SetNW2Float("LOD_WatcherEscapeSeconds", 0)
    end

    local baseTryAttack = class._TryAttack
    function class:_TryAttack(target)
        if self.LODArchetypeId == "watcher" then return false end
        if baseTryAttack then return baseTryAttack(self, target) end
        return false
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId ~= "watcher" then return baseBehaviourTick(self) end
        Unified.Stats.behaviourTicks = (Unified.Stats.behaviourTicks or 0) + 1

        local now = CurTime()
        if self.LODDead or not self.LODActivated then
            Motion:Stop(self)
            return
        end

        local state, graph = currentState()
        if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared then
            Motion:Stop(self)
            return
        end

        if Motion.HoldHitStun and Motion:HoldHitStun(self, now) then
            if self.LODWatcherScan then dispatchWatcherScan(self) end
            return
        end

        if self.LODWatcherUnifiedEscape then
            runEscape(self, graph, now)
            return
        end

        if runDisengage(self, graph, now) then return end

        self:_RefreshTarget(graph)
        local target = self.LODTarget
        if not targetEligible(self, graph, target) then
            self.LODWatcherUnifiedBackoff = nil
            if self.LODReturningHome then
                runReturnRoute(self, graph, "watcher-patrol-return")
            else
                Motion:Stop(self)
                self.LODMotionMode = "watcher-idle"
            end
            return
        end

        local distance = horizontalDistance(self:GetPos(), target:GetPos())
        local hasLOS = sharedLOS(self, target)

        if self.LODWatcherScan then
            if distance < MIN_SCAN_RANGE then
                cancelActiveScan(self, 0.35)
                beginBackoff(self, graph, target)
                runBackoff(self, graph, target)
                return
            end

            local completedBefore = Watcher.Stats.scansCompleted or 0
            dispatchWatcherScan(self)
            if (Watcher.Stats.scansCompleted or 0) > completedBefore then
                beginEscape(self, graph, target)
                runEscape(self, graph, now)
            end
            return
        end

        if distance < MIN_SCAN_RANGE then
            runBackoff(self, graph, target)
            return
        end

        if self.LODWatcherUnifiedBackoff then
            if distance < BACKOFF_RELEASE_RANGE then
                runBackoff(self, graph, target)
                return
            end
            self.LODWatcherUnifiedBackoff = nil
        end

        -- Visible scan range is a HOLD state, never a generic-pursuit fallthrough.
        -- This is the direct fix for Watchers walking into and following the feet.
        if distance <= SCAN_STANDOFF and hasLOS then
            holdStandoff(self, target,
                now < (self.LODNextWatcherScan or 0) and "watcher-standoff-cooldown"
                    or "watcher-standoff-ready")

            if now >= (self.LODNextWatcherScan or 0) then
                local completedBefore = Watcher.Stats.scansCompleted or 0
                dispatchWatcherScan(self)
                if (Watcher.Stats.scansCompleted or 0) > completedBefore then
                    beginEscape(self, graph, target)
                    runEscape(self, graph, now)
                end
            end
            return
        end

        -- If geometry blocks LOS but the target is already close, recover range
        -- before trying to route around a corner.
        if not hasLOS and distance < BACKOFF_RELEASE_RANGE then
            runBackoff(self, graph, target)
            return
        end

        approachTarget(self, graph, target)
    end

    local baseOnRemove = class.OnRemove
    function class:OnRemove()
        if self.LODArchetypeId == "watcher" then
            self.LODWatcherUnifiedEscape = nil
            self.LODWatcherUnifiedBackoff = nil
            self.LODWatcherUnifiedDisengageUntil = 0
        end
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_WatcherUnifiedControllerInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)

local function watcherStatusLine(hostile)
    local escape = hostile.LODWatcherUnifiedEscape
    local backoff = hostile.LODWatcherUnifiedBackoff
    local target = escape and escape.target or hostile.LODTarget
    local distance = livingPlayer(target)
        and horizontalDistance(hostile:GetPos(), target:GetPos()) or -1
    local backoffRemaining = backoff
        and math.max(0, #(backoff.waypoints or {}) - (backoff.index or 1) + 1) or 0
    local escapeRemaining = escape
        and math.max(0, #(escape.waypoints or {}) - (escape.index or 1) + 1) or 0
    return string.format(
        "#%d bound=%s mode=%s target=%s dist=%.0f scan=%s escape=%s escapeWp=%d backoff=%s backoffWp=%d disengage=%.1f cloakLeft=%.1f",
        hostile:EntIndex(),
        tostring(hostile.LODWatcherUnifiedRunBehaviourBound == true),
        tostring(hostile.LODMotionMode or "none"),
        IsValid(target) and (target:IsPlayer() and target:Nick() or target:GetClass()) or "none",
        distance,
        tostring(hostile.LODWatcherScan ~= nil),
        escape and tostring(escape.phase) or "none",
        escapeRemaining,
        tostring(backoff ~= nil),
        backoffRemaining,
        math.max(0, (hostile.LODWatcherUnifiedDisengageUntil or 0) - CurTime()),
        math.max(0, hostile:GetNW2Float("LOD_WatcherInvisibleUntil", 0) - CurTime()))
end

local function printWatcherStatus(ply)
    local live = 0
    local lines = {}
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and not hostile.LODDead and hostile.LODArchetypeId == "watcher" then
            live = live + 1
            lines[#lines + 1] = watcherStatusLine(hostile)
        end
    end

    print(string.format(
        "[LOD:WATCHER-UNIFIED] live=%d behaviour=%d standoff=%d scanDispatch=%d moveCalls=%d escapeStarts=%d escapeMoves=%d plans=%d replans=%d blocked=%d hiddenStarts=%d reexposures=%d hideCompletes=%d backoffStarts=%d backoffMoves=%d backoffExtensions=%d disengages=%d instanceBinds=%d lastCloak=2d6!=%ds[%s] lastHide=8d6!=%ds[%s] maxSpeed=%.2f authority=RunBehaviour->class _BehaviourTick->MotionV2",
        live,
        Unified.Stats.behaviourTicks or 0,
        Unified.Stats.standoffHolds or 0,
        Unified.Stats.scanDispatches or 0,
        Unified.Stats.movementCalls or 0,
        Unified.Stats.escapeStarts or 0,
        Unified.Stats.escapeMoves or 0,
        Unified.Stats.escapePlans or 0,
        Unified.Stats.escapeReplans or 0,
        Unified.Stats.blockedPlans or 0,
        Unified.Stats.hiddenStarts or 0,
        Unified.Stats.reexposures or 0,
        Unified.Stats.hideCompletes or 0,
        Unified.Stats.backoffStarts or 0,
        Unified.Stats.backoffMoves or 0,
        Unified.Stats.backoffExtensions or 0,
        Unified.Stats.disengageStarts or 0,
        Unified.Stats.instanceBinds or 0,
        Unified.Stats.lastCloakSeconds or 0,
        tostring(Unified.Stats.lastCloakRoll or "none"),
        Unified.Stats.lastHideSeconds or 0,
        tostring(Unified.Stats.lastHideRoll or "none"),
        Unified.Stats.maxSpeedScale or 1))
    for _, line in ipairs(lines) do print("[LOD:WATCHER-UNIFIED] " .. line) end
    if IsValid(ply) then
        ply:ChatPrint(string.format("Watcher status: %d live; details in console.", live))
    end
end

concommand.Add("lod_watcher_state_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    printWatcherStatus(ply)
end)

concommand.Add("lod_watcher_motion_audit", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    printWatcherStatus(ply)
end)

print("[LOD:WATCHER-UNIFIED] v2 complete-routine controller armed")
