LOD = LOD or {}
LOD.Watcher = LOD.Watcher or {}
LOD.WatcherConcealment = LOD.WatcherConcealment or {}

local Watcher = LOD.Watcher
local Concealment = LOD.WatcherConcealment
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local Rolls = LOD.CombatRolls
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Navigator or not Motion or not cellKey then return end

-- Successful Watcher scans enter one bounded concealment cycle. The Watcher uses
-- its already-proven committed retreat first, then (only if still visible) builds
-- one bounded graph plan toward nearby generated cover. It does not continuously
-- search the maze. Once genuinely hidden, it holds that position for one freshly
-- rolled 8d6! interval; every natural 6 recursively adds another d6 under LOD's
-- universal d6 rule. Re-exposure resets elapsed hidden time, but not the roll.
local SERVICE_NAME = "LOD_WatcherConcealmentService"
local SERVICE_INTERVAL = 0.10
local VISIBILITY_INTERVAL = 0.25
local SEARCH_DEPTH = 5
local HIDE_DICE_COUNT = 8
local HIDE_PROFILE = {sides = 6, exploding = 6}
local MAX_FALLBACK_CHAIN = 64

Concealment.Active = Concealment.Active or {}
Concealment.Stats = Concealment.Stats or {
    starts = 0,
    completions = 0,
    reexposures = 0,
    plans = 0,
    hiddenPlans = 0,
    fallbackPlans = 0,
    blockedPlans = 0,
    visibilityChecks = 0,
    lastDuration = 0,
    lastRollText = "none"
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
    Concealment.Stats.visibilityChecks = (Concealment.Stats.visibilityChecks or 0) + 1
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

local function rollHideDuration(watcher)
    local state = LOD.RunManager and LOD.RunManager.State
    local levelSeed = state and state.LevelSeed or 1
    watcher.LODWatcherConcealRollSerial = (watcher.LODWatcherConcealRollSerial or 0) + 1

    local identity = watcher.LODEncounterOrdinal
        or watcher.LODWanderSeed
        or watcher.LODEncounterId
        or watcher:EntIndex()
    local seed = LOD.Seeds.Derive(levelSeed, string.format(
        "watcher-conceal:%s:%d", tostring(identity), watcher.LODWatcherConcealRollSerial))
    local rng = LOD.RNG.New(seed)

    local total = 0
    local chains = {}
    for index = 1, HIDE_DICE_COUNT do
        local subtotal, values
        if Rolls and Rolls._RollExploding then
            subtotal, values = Rolls:_RollExploding(HIDE_PROFILE, rng)
        else
            subtotal, values = fallbackExplodingChain(rng)
        end
        total = total + (subtotal or 0)
        chains[index] = table.concat(values or {}, ">")
    end

    Concealment.Stats.lastDuration = math.max(HIDE_DICE_COUNT, total)
    Concealment.Stats.lastRollText = string.sub(table.concat(chains, " | "), 1, 160)
    return Concealment.Stats.lastDuration, Concealment.Stats.lastRollText
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

-- Search breadth-first and stop at the first graph depth that contains actual
-- cover. This is deliberately one-shot work: at most one bounded search is made
-- when a concealment leg begins, rather than repeating BFS/trace work on a timer.
local function buildConcealmentPlan(watcher, graph, target)
    local startCell = Navigator:WorldToCell(graph, watcher:GetPos())
    local targetCell = Navigator:WorldToCell(graph, target:GetPos())
    if not startCell or not targetCell or startCell.z ~= targetCell.z then return nil, false end

    local startKey = keyOf(startCell)
    local queue = {{key = startKey, depth = 0}}
    local head = 1
    local seen = {[startKey] = true}
    local previous = {}
    local targetPos = target:GetPos()
    local hiddenAtDepth = {}
    local hiddenDepth = nil
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

                if playerCanSeePoint(watcher, target, center) == false then
                    hiddenDepth = hiddenDepth or item.depth
                    if item.depth == hiddenDepth then
                        hiddenAtDepth[#hiddenAtDepth + 1] = {key = item.key, distance = distance}
                    end
                end
            end

            if item.depth < SEARCH_DEPTH and not hiddenDepth then
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

    local goalKey
    if #hiddenAtDepth > 0 then
        table.sort(hiddenAtDepth, function(a, b)
            if a.distance == b.distance then return a.key < b.key end
            return a.distance > b.distance
        end)
        goalKey = hiddenAtDepth[1].key
    else
        goalKey = fallbackKey
    end

    local waypoints = reconstructWaypoints(graph, startKey, goalKey, previous)
    return waypoints, waypoints ~= nil and #hiddenAtDepth > 0
end

local function serviceNeeded()
    for watcher in pairs(Concealment.Active) do
        if IsValid(watcher) and watcher.LODWatcherConcealment then return true end
    end
    return false
end

local function clearState(watcher, target, now, completed)
    watcher.LODWatcherConcealment = nil
    Concealment.Active[watcher] = nil
    watcher.LODNextWatcherScan = completed and now or (now + 0.35)
    watcher.LODTarget = completed and livingPlayer(target) and target or nil
    watcher.LODReturningHome = false
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
    watcher.LODNextTargetRefresh = 0
    watcher.LODNextRouteRefresh = 0
    if completed then
        Watcher.Stats.concealmentCompletes = (Watcher.Stats.concealmentCompletes or 0) + 1
        Concealment.Stats.completions = (Concealment.Stats.completions or 0) + 1
    end
end

local function cancelLegacyRetreat(watcher)
    if not watcher.LODWatcherRetreat then return end
    watcher.LODWatcherRetreat = nil
    if Watcher.RetreatActive then Watcher.RetreatActive[watcher] = nil end
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
end

local function enterHiddenHold(watcher, conceal, now)
    cancelLegacyRetreat(watcher)
    Motion:Stop(watcher)
    watcher.LODMotionMode = "watcher-concealment-hold"
    conceal.phase = "hidden"
    conceal.hiddenSince = now
    conceal.hiddenEndsAt = now + conceal.duration
    conceal.nextVisibilityAt = now + VISIBILITY_INTERVAL
    conceal.waypoints = {}
    conceal.index = 1
end

local function beginPlan(watcher, graph, conceal)
    local waypoints, hiddenGoal = buildConcealmentPlan(watcher, graph, conceal.target)
    Concealment.Stats.plans = (Concealment.Stats.plans or 0) + 1
    conceal.waypoints = waypoints or {}
    conceal.index = 1
    conceal.planHasHiddenGoal = hiddenGoal == true
    if waypoints then
        if hiddenGoal then
            Concealment.Stats.hiddenPlans = (Concealment.Stats.hiddenPlans or 0) + 1
        else
            Concealment.Stats.fallbackPlans = (Concealment.Stats.fallbackPlans or 0) + 1
        end
        conceal.phase = "seeking"
        return true
    end

    Concealment.Stats.blockedPlans = (Concealment.Stats.blockedPlans or 0) + 1
    conceal.phase = "blocked"
    Motion:Stop(watcher)
    watcher.LODMotionMode = "watcher-concealment-blocked"
    return false
end

local function stepConcealment(watcher, graph, now)
    local conceal = watcher.LODWatcherConcealment
    if not conceal then return end
    local target = conceal.target

    if not targetEligible(watcher, graph, target) then
        clearState(watcher, nil, now, false)
        return
    end

    -- During the already-proven short post-scan retreat, do only one cheap LOS
    -- check at 4 Hz. If that retreat reaches actual cover, immediately hold there.
    if watcher.LODWatcherRetreat then
        if now >= (conceal.nextVisibilityAt or 0) then
            conceal.nextVisibilityAt = now + VISIBILITY_INTERVAL
            if playerCanSeeWatcher(watcher, target) == false then
                enterHiddenHold(watcher, conceal, now)
            end
        end
        return
    end

    if conceal.phase == "hidden" then
        if now < (conceal.nextVisibilityAt or 0) then return end
        conceal.nextVisibilityAt = now + VISIBILITY_INTERVAL
        if playerCanSeeWatcher(watcher, target) then
            Concealment.Stats.reexposures = (Concealment.Stats.reexposures or 0) + 1
            conceal.hiddenSince = nil
            conceal.hiddenEndsAt = nil
            conceal.phase = "planning"
            beginPlan(watcher, graph, conceal)
            return
        end
        if conceal.hiddenEndsAt and now >= conceal.hiddenEndsAt then
            clearState(watcher, target, now, true)
        end
        return
    end

    if conceal.phase == "planning" then
        beginPlan(watcher, graph, conceal)
        return
    end

    if conceal.phase == "blocked" then
        return
    end

    local waypoint = conceal.waypoints and conceal.waypoints[conceal.index or 1]
    if waypoint then
        local reached = Motion:MoveToward(watcher, waypoint)
        watcher.LODMotionMode = "watcher-concealment-retreat"
        if reached then conceal.index = (conceal.index or 1) + 1 end
        return
    end

    -- One committed concealment leg ended. Check once. If it actually reached
    -- cover, begin the rolled hold; otherwise compile exactly one further leg.
    if playerCanSeeWatcher(watcher, target) == false then
        enterHiddenHold(watcher, conceal, now)
    else
        conceal.phase = "planning"
        beginPlan(watcher, graph, conceal)
    end
end

local function ensureService()
    if timer.Exists(SERVICE_NAME) then return end
    timer.Create(SERVICE_NAME, SERVICE_INTERVAL, 0, function()
        local state, graph = currentState()
        if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared
            or state.SimulationFrozen
        then
            return
        end

        local now = CurTime()
        for watcher in pairs(Concealment.Active) do
            if not IsValid(watcher) or watcher.LODDead or not watcher.LODWatcherConcealment then
                Concealment.Active[watcher] = nil
            else
                stepConcealment(watcher, graph, now)
            end
        end
        if not serviceNeeded() then timer.Remove(SERVICE_NAME) end
    end)
end

local function beginConcealment(watcher, target)
    if not IsValid(watcher) or not livingPlayer(target) or watcher.LODWatcherConcealment then return false end
    local duration, rollText = rollHideDuration(watcher)
    watcher.LODWatcherConcealment = {
        target = target,
        duration = duration,
        rollText = rollText,
        phase = watcher.LODWatcherRetreat and "legacy-retreat" or "planning",
        hiddenSince = nil,
        hiddenEndsAt = nil,
        nextVisibilityAt = 0,
        waypoints = {},
        index = 1
    }
    watcher.LODNextWatcherScan = math.huge
    Concealment.Active[watcher] = true
    Concealment.Stats.starts = (Concealment.Stats.starts or 0) + 1
    Watcher.Stats.concealmentStarts = (Watcher.Stats.concealmentStarts or 0) + 1
    Watcher.Stats.lastConcealmentDuration = duration
    ensureService()
    return true
end

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherConcealmentInstalled or not class._RunWatcherTick then return false end
    class.LODWatcherConcealmentInstalled = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId == "watcher" then self.LODWatcherConcealment = nil end
    end

    local baseRunWatcherTick = class._RunWatcherTick
    function class:_RunWatcherTick()
        if self.LODArchetypeId ~= "watcher" then return baseRunWatcherTick(self) end
        if self.LODWatcherConcealment then return true end

        local scanTarget = self.LODWatcherScan and self.LODWatcherScan.target or self.LODTarget
        local completedBefore = Watcher.Stats.scansCompleted or 0
        local result = baseRunWatcherTick(self)
        if (Watcher.Stats.scansCompleted or 0) > completedBefore and livingPlayer(scanTarget) then
            beginConcealment(self, scanTarget)
            return true
        end
        return result
    end

    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId == "watcher" and self.LODWatcherConcealment then return end
        return baseBehaviourTick(self)
    end

    local baseOnRemove = class.OnRemove
    function class:OnRemove()
        if self.LODArchetypeId == "watcher" then
            Concealment.Active[self] = nil
            self.LODWatcherConcealment = nil
        end
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_WatcherConcealmentInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)

concommand.Add("lod_watcher_concealment_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local active, hidden, blocked = 0, 0, 0
    for watcher in pairs(Concealment.Active) do
        local conceal = IsValid(watcher) and watcher.LODWatcherConcealment or nil
        if conceal then
            active = active + 1
            if conceal.phase == "hidden" then hidden = hidden + 1 end
            if conceal.phase == "blocked" then blocked = blocked + 1 end
        end
    end

    local line = string.format(
        "active=%d hidden=%d blocked=%d starts=%d completes=%d reexposures=%d plans=%d hiddenPlans=%d fallbackPlans=%d blockedPlans=%d visibilityChecks=%d last8d6=%ds rolls=%s service=%s",
        active, hidden, blocked,
        Concealment.Stats.starts or 0,
        Concealment.Stats.completions or 0,
        Concealment.Stats.reexposures or 0,
        Concealment.Stats.plans or 0,
        Concealment.Stats.hiddenPlans or 0,
        Concealment.Stats.fallbackPlans or 0,
        Concealment.Stats.blockedPlans or 0,
        Concealment.Stats.visibilityChecks or 0,
        Concealment.Stats.lastDuration or 0,
        tostring(Concealment.Stats.lastRollText or "none"),
        tostring(timer.Exists(SERVICE_NAME)))
    print("[LOD:WATCHER-CONCEAL] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
