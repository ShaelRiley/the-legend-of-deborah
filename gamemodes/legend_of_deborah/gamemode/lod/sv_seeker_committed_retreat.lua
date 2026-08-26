LOD = LOD or {}
LOD.SeekerCommittedRetreat = LOD.SeekerCommittedRetreat or {}

local Retreat = LOD.SeekerCommittedRetreat
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Navigator or not Motion or not cellKey then return end

local DETECT_TIMER = "LOD_SeekerCommittedRetreatDetect"
local MOTION_TIMER = "LOD_SeekerCommittedRetreatMotion"
local DETECT_INTERVAL = 0.20
local MOTION_INTERVAL = 0.05
local MIN_CHARGE_RANGE = 150
local RETREAT_TARGET_DISTANCE = 320
local SEARCH_DEPTH = 3

Retreat.Active = Retreat.Active or setmetatable({}, {__mode = "k"})
Retreat.Stats = Retreat.Stats or {adopted = 0, completed = 0, blocked = 0}

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function currentGraph()
    local state = LOD.RunManager and LOD.RunManager.State
    if not state or not state.Graph or not state.BuildReady or state.Failed or state.LevelCleared
        or state.SimulationFrozen
    then
        return nil
    end
    return state.Graph
end

local function livingPlayer(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:Alive()
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and (tag.safe == true or tag.role == "boss") or false
end

local function horizontalDistance(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function buildCommittedPath(seeker, graph, anchorPos)
    local startCell = Navigator:WorldToCell(graph, seeker:GetPos())
    if not startCell or safeCell(graph, startCell) then return nil end

    local startKey = keyOf(startCell)
    local queue = {{key = startKey, depth = 0}}
    local head = 1
    local seen = {[startKey] = true}
    local previous = {}
    local bestKey = startKey
    local bestDistance = horizontalDistance(Navigator:CellCenter(startCell), anchorPos)
    local bestReady = bestDistance >= RETREAT_TARGET_DISTANCE

    while head <= #queue do
        local item = queue[head]
        head = head + 1
        local cell = graph.Cells[item.key]
        if cell then
            local distance = horizontalDistance(Navigator:CellCenter(cell), anchorPos)
            local ready = distance >= RETREAT_TARGET_DISTANCE
            local better = false

            if ready and not bestReady then
                better = true
            elseif ready and bestReady then
                better = math.abs(distance - RETREAT_TARGET_DISTANCE)
                    < math.abs(bestDistance - RETREAT_TARGET_DISTANCE)
            elseif not bestReady and distance > bestDistance then
                better = true
            end

            if better and not safeCell(graph, cell) then
                bestKey = item.key
                bestDistance = distance
                bestReady = ready
            end

            if item.depth < SEARCH_DEPTH then
                local neighbors = {}
                for neighborKey in pairs(cell.neighbors or {}) do neighbors[#neighbors + 1] = neighborKey end
                table.sort(neighbors)
                for _, neighborKey in ipairs(neighbors) do
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
            if #waypoints > 0 then return waypoints, bestDistance end
        end
    end

    -- No open neighboring route improved separation. Stay inside the current
    -- authoritative graph cell and take one committed step directly away.
    local seekerPos = seeker:GetPos()
    local away = Vector(seekerPos.x - anchorPos.x, seekerPos.y - anchorPos.y, 0)
    if away:LengthSqr() <= 0.01 then away = seeker:GetForward() * -1 end
    away:Normalize()
    local localGoal = Motion:CellFloorPoint(startCell, seekerPos + away * RETREAT_TARGET_DISTANCE)
    if localGoal and horizontalDistance(localGoal, anchorPos) > horizontalDistance(seekerPos, anchorPos) + 8 then
        return {{pos = localGoal, tolerance = 12, stair = false, seekerRetreat = true}},
            horizontalDistance(localGoal, anchorPos)
    end

    return {}, bestDistance
end

local function adopt(seeker, graph)
    if Retreat.Active[seeker] or not IsValid(seeker) or seeker.LODArchetypeId ~= "seeker" then return false end
    local legacy = seeker.LODSeekerRetreat
    if not legacy or not livingPlayer(legacy.target) then return false end

    local target = legacy.target
    local anchor = Vector(target:GetPos().x, target:GetPos().y, target:GetPos().z)
    local waypoints, plannedDistance = buildCommittedPath(seeker, graph, anchor)

    -- Retire the old retreat planner state. From this point until completion,
    -- this one immutable waypoint sequence is the sole Seeker retreat authority.
    seeker.LODSeekerRetreat = nil
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1

    -- The original Seeker service also runs at 20 Hz. If it is allowed to keep a
    -- normal target while committed retreat owns movement, it can immediately
    -- create a second close-range retreat (or start a wind-up) and both systems
    -- fight over the same Rollermine. Freeze ordinary acquisition/routing and
    -- clear the normal target until this committed disengage has finished.
    seeker.LODTarget = nil
    seeker.LODNextTargetRefresh = math.huge
    seeker.LODNextRouteRefresh = math.huge

    local resumeChargeAt = seeker.LODNextSeekerCharge or CurTime()
    seeker.LODNextSeekerCharge = math.huge
    seeker.LODSeekerCommittedRetreat = true
    Retreat.Active[seeker] = {
        target = target,
        anchor = anchor,
        reason = legacy.reason or "range",
        waypoints = waypoints or {},
        index = 1,
        plannedDistance = plannedDistance or 0,
        resumeChargeAt = resumeChargeAt
    }
    Retreat.Stats.adopted = (Retreat.Stats.adopted or 0) + 1
    if #(waypoints or {}) == 0 then Retreat.Stats.blocked = (Retreat.Stats.blocked or 0) + 1 end
    return true
end

local function finish(seeker, record)
    if not IsValid(seeker) then return end
    Retreat.Active[seeker] = nil
    seeker.LODSeekerCommittedRetreat = nil
    seeker.LODWaypoints = {}
    seeker.LODWaypointIndex = 1
    Motion:Stop(seeker)

    -- Always unfreeze ordinary acquisition/routing, even if the player that
    -- caused the retreat died or disconnected while the Seeker was disengaging.
    seeker.LODTarget = nil
    seeker.LODNextTargetRefresh = 0
    seeker.LODNextRouteRefresh = 0

    local target = record and record.target
    if livingPlayer(target) then
        seeker.LODTarget = target
        seeker.LODReturningHome = false
        seeker.LODNextTargetRefresh = CurTime() + 0.20
        Motion:FaceToward(seeker, target:GetPos())
    end
    seeker.LODNextSeekerCharge = math.max(record and record.resumeChargeAt or 0, CurTime() + 0.10)

    if LOD.Seeker and LOD.Seeker.Stats then
        LOD.Seeker.Stats.retreatCompletes = (LOD.Seeker.Stats.retreatCompletes or 0) + 1
    end
    Retreat.Stats.completed = (Retreat.Stats.completed or 0) + 1
end

timer.Create(DETECT_TIMER, DETECT_INTERVAL, 0, function()
    local graph = currentGraph()
    if not graph then return end
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODArchetypeId == "seeker" and hostile.LODSeekerRetreat
            and not hostile.LODSeekerCommittedRetreat
        then
            adopt(hostile, graph)
        end
    end
end)

timer.Create(MOTION_TIMER, MOTION_INTERVAL, 0, function()
    local graph = currentGraph()
    if not graph then return end

    for seeker, record in pairs(Retreat.Active) do
        if not IsValid(seeker) or seeker.LODDead then
            Retreat.Active[seeker] = nil
        elseif not livingPlayer(record.target) then
            finish(seeker, record)
        else
            local currentDistance = horizontalDistance(seeker:GetPos(), record.target:GetPos())
            local waypoint = record.waypoints[record.index]

            if not waypoint then
                -- A committed path is complete. Medium range is preferred, but
                -- being outside the hard 150-unit minimum is sufficient to resume
                -- the normal charge state machine. If topology made even that
                -- impossible, hold safely rather than attacking from too close.
                if currentDistance >= MIN_CHARGE_RANGE then
                    finish(seeker, record)
                else
                    Motion:Stop(seeker)
                    Motion:FaceToward(seeker, record.target:GetPos())
                    seeker.LODMotionMode = "seeker-retreat-blocked"
                end
            else
                local reached = Motion:MoveToward(seeker, waypoint)
                seeker.LODMotionMode = "seeker-retreat-committed"
                if reached then record.index = record.index + 1 end
            end
        end
    end
end)

-- The generic behaviour coroutine must not pull a Seeker toward the player while
-- the committed retreat service owns its movement.
local function installBehaviourGuard()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODSeekerCommittedRetreatGuard then return false end
    class.LODSeekerCommittedRetreatGuard = true
    local baseBehaviourTick = class._BehaviourTick
    function class:_BehaviourTick()
        if self.LODArchetypeId == "seeker" and self.LODSeekerCommittedRetreat then return end
        return baseBehaviourTick(self)
    end
    return true
end

installBehaviourGuard()
hook.Add("OnEntityCreated", "LOD_SeekerCommittedRetreatGuardInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then installBehaviourGuard() end
end)

concommand.Add("lod_seeker_retreat_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local active = 0
    for seeker in pairs(Retreat.Active) do if IsValid(seeker) then active = active + 1 end end
    local line = string.format("active=%d adopted=%d completed=%d blocked=%d committed=true",
        active, Retreat.Stats.adopted or 0, Retreat.Stats.completed or 0, Retreat.Stats.blocked or 0)
    print("[LOD:SEEKER-RETREAT] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
