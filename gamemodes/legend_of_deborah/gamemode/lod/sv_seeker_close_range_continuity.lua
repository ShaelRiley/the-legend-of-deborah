LOD = LOD or {}
LOD.SeekerCloseRangeContinuity = LOD.SeekerCloseRangeContinuity or {}

local Continuity = LOD.SeekerCloseRangeContinuity
local Motion = LOD.HostileMotionV2
local Navigator = LOD.MazeNavigator
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Motion or not Navigator or not cellKey then return end

-- This module does not move Seekers and owns no recurring service. It repairs an
-- exhausted retreat itinerary only at the exact Motion:Stop transition where the
-- core Seeker state machine would otherwise enter its legacy point-blank hold.
-- The existing 20 Hz Seeker service remains the sole executor of movement.
local MIN_CHARGE_RANGE = 150
local CONTINUATION_STEP = 118
local MIN_USEFUL_STEP = 24
local NEIGHBOR_BONUS = 8

Continuity.Stats = Continuity.Stats or {
    continuations = 0,
    sameCell = 0,
    neighborCell = 0,
    noCandidate = 0
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

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and (tag.safe == true or tag.role == "boss") or false
end

local function livingTarget(target)
    return IsValid(target) and target:IsPlayer() and target:Alive()
end

local function scoreCandidate(pos, candidate, targetPos, lastGoal, neighbor)
    local travel = horizontalDistance(pos, candidate)
    if travel < MIN_USEFUL_STEP then return nil end

    local separation = horizontalDistance(candidate, targetPos)
    local score = separation * 10 + travel + (neighbor and NEIGHBOR_BONUS or 0)

    -- Do not let a chasing player make the continuation bounce between the same
    -- two clamped points. A prior endpoint is a soft penalty, not a prohibition,
    -- because a very tight cell may genuinely have only one useful escape lane.
    if lastGoal and horizontalDistance(candidate, lastGoal) < 36 then
        score = score - 180
    end
    return score
end

local function chooseContinuation(seeker, graph, retreat)
    local target = retreat and retreat.target
    if not livingTarget(target) then return nil end

    local pos = seeker:GetPos()
    local targetPos = target:GetPos()
    if horizontalDistance(pos, targetPos) >= MIN_CHARGE_RANGE then return nil end

    local cell = Navigator:WorldToCell(graph, pos)
    if not cell then return nil end

    local away = Vector(pos.x - targetPos.x, pos.y - targetPos.y, 0)
    if away:LengthSqr() <= 0.01 then
        away = seeker:GetForward()
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

    -- If the current cell cannot provide useful separation, consider only
    -- canonical same-floor open neighbors. This remains graph-authoritative and
    -- cannot cross a wall, locked gate, safe room, or unauthored vertical edge.
    local fromKey = keyOf(cell)
    local neighborKeys = {}
    for neighborKey in pairs(cell.neighbors or {}) do neighborKeys[#neighborKeys + 1] = neighborKey end
    table.sort(neighborKeys)

    for _, neighborKey in ipairs(neighborKeys) do
        local neighbor = graph.Cells and graph.Cells[neighborKey]
        if neighbor and neighbor.z == cell.z and not safeCell(graph, neighbor)
            and Navigator:CanTraverse(graph, fromKey, neighborKey)
        then
            local candidate = Navigator:CellCenter(neighbor)
            if Motion.CellFloorPoint then candidate = Motion:CellFloorPoint(neighbor, candidate) end
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
        seekerRetreat = true,
        seekerContinuity = true
    }, bestKind
end

local function repairExhaustedRetreat(seeker)
    if not IsValid(seeker) or seeker.LODDead or seeker.LODArchetypeId ~= "seeker" then return false end
    if seeker.LODSeekerState or seeker.LODSeekerPolishState then return false end

    local retreat = seeker.LODSeekerRetreat
    if not retreat or not livingTarget(retreat.target) then return false end
    if retreat.waypoints and retreat.waypoints[retreat.index or 1] then return false end
    if horizontalDistance(seeker:GetPos(), retreat.target:GetPos()) >= MIN_CHARGE_RANGE then return false end

    local graph = currentGraph()
    if not graph then return false end

    local waypoint, kind = chooseContinuation(seeker, graph, retreat)
    if not waypoint then
        Continuity.Stats.noCandidate = (Continuity.Stats.noCandidate or 0) + 1
        return false
    end

    retreat.waypoints = retreat.waypoints or {}
    retreat.index = retreat.index or 1
    retreat.waypoints[retreat.index] = waypoint
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

local baseStop = Motion.Stop
function Motion:Stop(hostile)
    baseStop(self, hostile)
    repairExhaustedRetreat(hostile)
end

concommand.Add("lod_seeker_continuity_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format(
        "continuations=%d sameCell=%d neighborCell=%d noCandidate=%d recurringService=false authority=plan-repair-only",
        Continuity.Stats.continuations or 0,
        Continuity.Stats.sameCell or 0,
        Continuity.Stats.neighborCell or 0,
        Continuity.Stats.noCandidate or 0)
    print("[LOD:SEEKER-CONTINUITY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
