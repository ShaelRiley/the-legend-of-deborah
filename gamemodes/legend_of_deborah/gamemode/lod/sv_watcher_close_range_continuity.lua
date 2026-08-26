LOD = LOD or {}
LOD.WatcherCloseRangeContinuity = LOD.WatcherCloseRangeContinuity or {}

local Continuity = LOD.WatcherCloseRangeContinuity
local Watcher = LOD.Watcher
local Motion = LOD.HostileMotionV2
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Watcher or not Motion or not Navigator or not cellKey then return end

-- Watcher is allowed to stop only for an intentional scan/stun at legal support
-- range. This patch owns no movement loop: it only repairs a retreat itinerary at
-- the exact stop transition where the legacy Watcher code would otherwise park
-- point-blank, and it cancels a scan if the player rushes inside hard scan range.
local MIN_SCAN_RANGE = 150
local CONTINUATION_STEP = 118
local MIN_USEFUL_STEP = 24
local SCAN_RETRY = 0.35

Continuity.Stats = Continuity.Stats or {
    continuations = 0,
    sameCell = 0,
    neighborCell = 0,
    noCandidate = 0,
    pointBlankScanCancels = 0
}

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function currentGraph()
    local state = LOD.RunManager and LOD.RunManager.State
    if not state or not state.Graph or not state.BuildReady or state.Failed or state.LevelCleared then return nil end
    return state.Graph
end

local function horizontalDistance(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function livingTarget(target)
    return IsValid(target) and target:IsPlayer() and target:Alive()
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and tag.safe == true or false
end

local function scoreCandidate(pos, candidate, targetPos, lastGoal, neighbor)
    local travel = horizontalDistance(pos, candidate)
    if travel < MIN_USEFUL_STEP then return nil end
    local separation = horizontalDistance(candidate, targetPos)
    local score = separation * 10 + travel + (neighbor and 8 or 0)
    if lastGoal and horizontalDistance(candidate, lastGoal) < 36 then score = score - 180 end
    return score
end

local function chooseContinuation(watcher, graph, retreat)
    local target = retreat and retreat.target
    if not livingTarget(target) then return nil end

    local pos = watcher:GetPos()
    local targetPos = target:GetPos()
    if horizontalDistance(pos, targetPos) >= MIN_SCAN_RANGE then return nil end

    local cell = Navigator:WorldToCell(graph, pos)
    if not cell then return nil end

    local away = Vector(pos.x - targetPos.x, pos.y - targetPos.y, 0)
    if away:LengthSqr() <= 0.01 then
        away = watcher:GetForward() * -1
        away.z = 0
    end
    if away:LengthSqr() <= 0.01 then away = Vector(1, 0, 0) end
    away:Normalize()
    local lateral = Vector(-away.y, away.x, 0)

    local directions = {
        away,
        (away + lateral * 0.70):GetNormalized(),
        (away - lateral * 0.70):GetNormalized(),
        lateral,
        -lateral,
        (-away + lateral * 0.55):GetNormalized(),
        (-away - lateral * 0.55):GetNormalized()
    }

    local bestPos, bestScore, bestKind
    for _, direction in ipairs(directions) do
        local candidate = Motion:CellFloorPoint(cell, pos + direction * CONTINUATION_STEP)
        if candidate then
            local score = scoreCandidate(pos, candidate, targetPos, retreat.continuityLastGoal, false)
            if score and (not bestScore or score > bestScore) then
                bestPos, bestScore, bestKind = candidate, score, "same-cell"
            end
        end
    end

    local fromKey = keyOf(cell)
    local neighborKeys = {}
    for neighborKey in pairs(cell.neighbors or {}) do neighborKeys[#neighborKeys + 1] = neighborKey end
    table.sort(neighborKeys)

    for _, neighborKey in ipairs(neighborKeys) do
        local neighbor = graph.Cells and graph.Cells[neighborKey]
        if neighbor and neighbor.z == cell.z and not safeCell(graph, neighbor)
            and Navigator:CanTraverse(graph, fromKey, neighborKey)
        then
            local candidate = Motion:CellFloorPoint(neighbor, Navigator:CellCenter(neighbor))
            if candidate then
                local score = scoreCandidate(pos, candidate, targetPos, retreat.continuityLastGoal, true)
                if score and (not bestScore or score > bestScore) then
                    bestPos, bestScore, bestKind = candidate, score, "neighbor"
                end
            end
        end
    end

    if not bestPos then return nil end
    return {
        pos = bestPos,
        tolerance = 10,
        stair = false,
        watcherRetreat = true,
        watcherContinuity = true
    }, bestKind
end

local function repairExhaustedRetreat(watcher)
    if not IsValid(watcher) or watcher.LODDead or watcher.LODArchetypeId ~= "watcher" then return false end
    local retreat = watcher.LODWatcherRetreat
    if not retreat or not livingTarget(retreat.target) then return false end

    local current = retreat.waypoints and retreat.waypoints[retreat.index or 1]
    if current and not retreat.blocked then return false end
    if horizontalDistance(watcher:GetPos(), retreat.target:GetPos()) >= MIN_SCAN_RANGE then return false end

    local graph = currentGraph()
    if not graph then return false end
    local waypoint, kind = chooseContinuation(watcher, graph, retreat)
    if not waypoint then
        Continuity.Stats.noCandidate = (Continuity.Stats.noCandidate or 0) + 1
        return false
    end

    retreat.waypoints = retreat.waypoints or {}
    retreat.index = retreat.index or 1
    retreat.waypoints[retreat.index] = waypoint
    retreat.blocked = false
    retreat.continuityLastGoal = waypoint.pos
    retreat.continuityCount = (retreat.continuityCount or 0) + 1

    Continuity.Stats.continuations = (Continuity.Stats.continuations or 0) + 1
    if kind == "neighbor" then
        Continuity.Stats.neighborCell = (Continuity.Stats.neighborCell or 0) + 1
    else
        Continuity.Stats.sameCell = (Continuity.Stats.sameCell or 0) + 1
    end
    return true
end

-- The existing Watcher retreat service calls Stop exactly when an exhausted path
-- would enter its blocked hold. Repair that itinerary synchronously; the existing
-- service then executes the appended waypoint on its next 20 Hz tick.
local baseStop = Motion.Stop
function Motion:Stop(hostile)
    baseStop(self, hostile)
    repairExhaustedRetreat(hostile)
end

local function installScanRangeGuard()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODWatcherCloseRangeGuardInstalled or not class._RunWatcherTick then return false end
    class.LODWatcherCloseRangeGuardInstalled = true

    local baseRunWatcherTick = class._RunWatcherTick
    function class:_RunWatcherTick()
        if self.LODArchetypeId ~= "watcher" then return baseRunWatcherTick(self) end

        local scan = self.LODWatcherScan
        local target = scan and scan.target
        if scan and livingTarget(target)
            and horizontalDistance(self:GetPos(), target:GetPos()) < MIN_SCAN_RANGE
        then
            -- End the client beam immediately. Calling the already-installed
            -- Watcher state machine afterward lets its own committed-retreat
            -- authority acquire the same target and disengage in this same tick.
            self.LODWatcherScan = nil
            self.LODNextWatcherScan = CurTime() + SCAN_RETRY
            net.Start("LOD_WatcherScanState")
            net.WriteEntity(self)
            net.WriteBool(false)
            net.Broadcast()
            self.LODTarget = target
            self.LODNextTargetRefresh = CurTime() + 0.20
            self.LODNextRouteRefresh = 0
            Continuity.Stats.pointBlankScanCancels = (Continuity.Stats.pointBlankScanCancels or 0) + 1
        end

        return baseRunWatcherTick(self)
    end
    return true
end

installScanRangeGuard()
hook.Add("OnEntityCreated", "LOD_WatcherCloseRangeContinuityInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installScanRangeGuard() end
end)

concommand.Add("lod_watcher_continuity_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format(
        "continuations=%d sameCell=%d neighborCell=%d noCandidate=%d pointBlankScanCancels=%d recurringService=false authority=plan-repair-only",
        Continuity.Stats.continuations or 0,
        Continuity.Stats.sameCell or 0,
        Continuity.Stats.neighborCell or 0,
        Continuity.Stats.noCandidate or 0,
        Continuity.Stats.pointBlankScanCancels or 0)
    print("[LOD:WATCHER-CONTINUITY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)