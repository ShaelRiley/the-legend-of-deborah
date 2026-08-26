LOD = LOD or {}
LOD.Watcher = LOD.Watcher or {}

local Watcher = LOD.Watcher
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Navigator or not Motion or not cellKey then return end

-- Watcher uses the same range-recovery principle as Seeker, adapted to its
-- support role: a successful scan is followed by one committed graph-valid
-- disengage. While too close to a player it prioritizes range recovery and will
-- not begin another scan. The destination/path is chosen once per retreat so
-- player movement cannot make the Watcher oscillate between freshly replanned
-- escape points.
local MIN_SCAN_RANGE = 150
local RETREAT_TARGET_DISTANCE = 320
local RETREAT_SEARCH_DEPTH = 2
local RETREAT_SERVICE = "LOD_WatcherCommittedRetreatService"
local RETREAT_INTERVAL = 0.05
local RETREAT_HOLD_RECHECK = 0.25

Watcher.RetreatActive = Watcher.RetreatActive or {}
Watcher.Stats = Watcher.Stats or {}
Watcher.Stats.retreatStarts = Watcher.Stats.retreatStarts or 0
Watcher.Stats.retreatCompletes = Watcher.Stats.retreatCompletes or 0
Watcher.Stats.postScanRetreats = Watcher.Stats.postScanRetreats or 0
Watcher.Stats.closeRangeRetreats = Watcher.Stats.closeRangeRetreats or 0
Watcher.Stats.retreatBlocked = Watcher.Stats.retreatBlocked or 0

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
    if safeCell(graph, to) then return false end
    return true
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

local function committedRetreatWaypoints(watcher, graph, target)
    local startCell = Navigator:WorldToCell(graph, watcher:GetPos())
    local targetCell = Navigator:WorldToCell(graph, target:GetPos())
    if not startCell or not targetCell or startCell.z ~= targetCell.z then return nil end

    local targetSnapshot = Vector(target:GetPos().x, target:GetPos().y, target:GetPos().z)
    local startKey = keyOf(startCell)
    local queue = {{key = startKey, depth = 0}}
    local head = 1
    local seen = {[startKey] = true}
    local previous = {}
    local bestKey = startKey
    local bestDistance = horizontalDistance(Navigator:CellCenter(startCell), targetSnapshot)
    local bestAtRange = bestDistance >= RETREAT_TARGET_DISTANCE

    while head <= #queue do
        local item = queue[head]
        head = head + 1
        local cell = graph.Cells[item.key]
        if cell then
            local distance = horizontalDistance(Navigator:CellCenter(cell), targetSnapshot)
            local atRange = distance >= RETREAT_TARGET_DISTANCE
            local better = false

            if atRange and not bestAtRange then
                better = true
            elseif atRange and bestAtRange then
                better = math.abs(distance - RETREAT_TARGET_DISTANCE)
                    < math.abs(bestDistance - RETREAT_TARGET_DISTANCE)
            elseif not bestAtRange and distance > bestDistance then
                better = true
            end

            if better and not safeCell(graph, cell) then
                bestKey = item.key
                bestDistance = distance
                bestAtRange = atRange
            end

            if item.depth < RETREAT_SEARCH_DEPTH then
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

    if bestKey ~= startKey then
        local reverse = {bestKey}
        local cursor = bestKey
        while cursor ~= startKey do
            cursor = previous[cursor]
            if not cursor then break end
            reverse[#reverse + 1] = cursor
        end

        if cursor == startKey then
            local path = {}
            for i = #reverse, 1, -1 do path[#path + 1] = graph.Cells[reverse[i]] end
            local waypoints = Navigator:PathToWaypoints(graph, path)
            if #waypoints > 0 then return waypoints, targetSnapshot end
        end
    end

    -- Same-cell fallback is safe because Motion:CellFloorPoint clamps the goal to
    -- the current cell interior; it cannot cross a wall/gate. This point is also
    -- frozen for the retreat rather than recalculated every service tick.
    local watcherPos = watcher:GetPos()
    local away = Vector(watcherPos.x - targetSnapshot.x, watcherPos.y - targetSnapshot.y, 0)
    if away:LengthSqr() <= 0.01 then away = watcher:GetForward() * -1 end
    away:Normalize()
    local wanted = watcherPos + away * RETREAT_TARGET_DISTANCE
    local localGoal = Motion:CellFloorPoint(startCell, wanted)
    if localGoal and horizontalDistance(localGoal, targetSnapshot)
        > horizontalDistance(watcherPos, targetSnapshot) + 8
    then
        return {{pos = localGoal, tolerance = 12, stair = false, watcherRetreat = true}}, targetSnapshot
    end

    return nil, targetSnapshot
end

local function finishRetreat(watcher, target)
    if not IsValid(watcher) then return end
    watcher.LODWatcherRetreat = nil
    Watcher.RetreatActive[watcher] = nil
    Motion:Stop(watcher)
    watcher.LODMotionMode = "ground"
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
    watcher.LODNextRouteRefresh = 0
    if livingPlayer(target) then
        watcher.LODTarget = target
        watcher.LODReturningHome = false
        watcher.LODNextTargetRefresh = CurTime() + 0.20
        Motion:FaceToward(watcher, target:GetPos())
    end
    Watcher.Stats.retreatCompletes = (Watcher.Stats.retreatCompletes or 0) + 1
end

local function beginRetreat(watcher, graph, target, reason)
    if not targetEligible(watcher, graph, target) then return false end
    if watcher.LODWatcherScan or watcher.LODWatcherRetreat then return false end

    local waypoints, targetSnapshot = committedRetreatWaypoints(watcher, graph, target)
    watcher.LODWatcherRetreat = {
        target = target,
        reason = reason or "range",
        targetSnapshot = targetSnapshot,
        waypoints = waypoints or {},
        index = 1,
        blocked = not waypoints or #waypoints == 0,
        nextHoldCheck = 0
    }
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
    watcher.LODNextRouteRefresh = CurTime() + 1.0
    watcher.LODNextTargetRefresh = CurTime() + 1.0
    Watcher.RetreatActive[watcher] = true

    Watcher.Stats.retreatStarts = (Watcher.Stats.retreatStarts or 0) + 1
    if reason == "post-scan" then
        Watcher.Stats.postScanRetreats = (Watcher.Stats.postScanRetreats or 0) + 1
    else
        Watcher.Stats.closeRangeRetreats = (Watcher.Stats.closeRangeRetreats or 0) + 1
    end
    if watcher.LODWatcherRetreat.blocked then
        Watcher.Stats.retreatBlocked = (Watcher.Stats.retreatBlocked or 0) + 1
    end
    return true
end

local function runRetreatStep(watcher, graph)
    local retreat = watcher.LODWatcherRetreat
    if not retreat then return false end
    local target = retreat.target

    if not targetEligible(watcher, graph, target) then
        finishRetreat(watcher, nil)
        return false
    end

    local liveDistance = horizontalDistance(watcher:GetPos(), target:GetPos())
    if liveDistance >= RETREAT_TARGET_DISTANCE then
        finishRetreat(watcher, target)
        return true
    end

    if retreat.blocked then
        Motion:Stop(watcher)
        Motion:FaceToward(watcher, target:GetPos())
        watcher.LODMotionMode = "watcher-retreat-blocked"
        if liveDistance >= MIN_SCAN_RANGE then finishRetreat(watcher, target) end
        return true
    end

    local waypoint = retreat.waypoints[retreat.index]
    if not waypoint then
        -- The committed route has ended. Do not pick a new direction on the next
        -- frame: either range is now legal, or hold until the player creates it.
        if liveDistance >= MIN_SCAN_RANGE then
            finishRetreat(watcher, target)
        else
            retreat.blocked = true
            retreat.nextHoldCheck = CurTime() + RETREAT_HOLD_RECHECK
            Watcher.Stats.retreatBlocked = (Watcher.Stats.retreatBlocked or 0) + 1
            Motion:Stop(watcher)
            watcher.LODMotionMode = "watcher-retreat-blocked"
        end
        return true
    end

    local reached = Motion:MoveToward(watcher, waypoint)
    watcher.LODMotionMode = "watcher-retreat"
    if reached then retreat.index = retreat.index + 1 end
    return true
end

local function installPatch()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherCommittedRetreatInstalled or not class._RunWatcherTick then return false end
    class.LODWatcherCommittedRetreatInstalled = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if self.LODArchetypeId == "watcher" then self.LODWatcherRetreat = nil end
    end

    local baseRunWatcherTick = class._RunWatcherTick
    function class:_RunWatcherTick()
        if self.LODArchetypeId ~= "watcher" then return baseRunWatcherTick(self) end

        local state, graph = currentState()
        if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared then
            return baseRunWatcherTick(self)
        end

        if self.LODWatcherRetreat then return true end

        -- Refresh through the existing acquisition authority before the Watcher
        -- state machine can begin a scan. This lets close-range recovery preempt
        -- scanning even on the first tick that acquires the player.
        if not self.LODWatcherScan then self:_RefreshTarget(graph) end
        local target = self.LODTarget
        if IsValid(target) and targetEligible(self, graph, target)
            and horizontalDistance(self:GetPos(), target:GetPos()) < MIN_SCAN_RANGE
        then
            if beginRetreat(self, graph, target, "too-close") then return true end
        end

        local scanTarget = self.LODWatcherScan and self.LODWatcherScan.target or target
        local completedBefore = Watcher.Stats.scansCompleted or 0
        local result = baseRunWatcherTick(self)

        -- Watcher scans are serviced serially by the shared Watcher service, so
        -- a completion-count increment during this call belongs to this Watcher.
        if (Watcher.Stats.scansCompleted or 0) > completedBefore and IsValid(scanTarget) then
            beginRetreat(self, graph, scanTarget, "post-scan")
            return true
        end

        return result
    end

    local baseOnRemove = class.OnRemove
    function class:OnRemove()
        if self.LODArchetypeId == "watcher" then
            Watcher.RetreatActive[self] = nil
            self.LODWatcherRetreat = nil
        end
        if baseOnRemove then return baseOnRemove(self) end
    end

    return true
end

installPatch()
hook.Add("OnEntityCreated", "LOD_WatcherCommittedRetreatInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installPatch() end
end)

-- Move only Watchers that are actively disengaging; unlike the scan service this
-- does not scan the hostile registry at 20 Hz.
timer.Create(RETREAT_SERVICE, RETREAT_INTERVAL, 0, function()
    local state, graph = currentState()
    if not state or not graph or not state.BuildReady or state.Failed or state.LevelCleared
        or state.SimulationFrozen
    then
        return
    end

    for watcher in pairs(Watcher.RetreatActive) do
        if not IsValid(watcher) or watcher.LODDead or not watcher.LODWatcherRetreat then
            Watcher.RetreatActive[watcher] = nil
        else
            runRetreatStep(watcher, graph)
        end
    end
end)

concommand.Add("lod_watcher_retreat_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local active = 0
    for watcher in pairs(Watcher.RetreatActive) do
        if IsValid(watcher) and watcher.LODWatcherRetreat then active = active + 1 end
    end

    local line = string.format(
        "active=%d starts=%d completes=%d postScan=%d closeRange=%d blocked=%d minRange=%d targetRange=%d",
        active,
        Watcher.Stats.retreatStarts or 0,
        Watcher.Stats.retreatCompletes or 0,
        Watcher.Stats.postScanRetreats or 0,
        Watcher.Stats.closeRangeRetreats or 0,
        Watcher.Stats.retreatBlocked or 0,
        MIN_SCAN_RANGE,
        RETREAT_TARGET_DISTANCE)
    print("[LOD:WATCHER-RETREAT] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
