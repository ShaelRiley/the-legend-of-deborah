LOD = LOD or {}

local Watcher = LOD.Watcher
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local WanderingDirector = LOD.WanderingDirector
local EncounterDirector = LOD.EncounterDirector
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Watcher or not Navigator or not Motion or not cellKey then return end

local TEST_WATCHER_ORDINAL = 980001
local MIN_VISIBLE_DISTANCE = 154
local DESIRED_VISIBLE_DISTANCE = 184
local INITIAL_SCAN_DELAY = 1.00

local PendingCycleTests = setmetatable({}, {__mode = "k"})

local function currentState()
    local state = LOD.RunManager and LOD.RunManager.State
    return state, state and state.Graph or nil
end

local function keyOf(cell)
    return cell and cellKey(cell.x, cell.y, cell.z) or nil
end

local function safeCell(graph, cell)
    local tag = graph and graph.CellTags and graph.CellTags[keyOf(cell)]
    return tag and tag.safe == true or false
end

local function cleanupTestEntities()
    for _, ent in ipairs(Watcher.TestEntities or {}) do
        if IsValid(ent) then ent:Remove() end
    end
    Watcher.TestEntities = {}
end

local function spawnTestHostile(archetypeId, graph, cell, pos, ordinal)
    local ent = ents.Create("lod_hostile")
    if not IsValid(ent) then return nil end

    local key = keyOf(cell)
    ent.LODArchetypeId = archetypeId
    ent.LODHomeCellKey = key
    ent.LODEncounterId = nil
    ent.LODEncounterOrdinal = ordinal
    ent.LODWanderer = true
    ent.LODWanderFloor = cell.z
    ent.LODWanderAnchorCellKey = key
    ent.LODWanderSeed = LOD.Seeds.Derive(
        (LOD.RunManager.State.LevelSeed or 1),
        "watcher-cycle-test:" .. ordinal)
    ent.LODActivated = true
    ent:SetPos(pos or Motion:CellFloorPoint(cell, Navigator:CellCenter(cell)))
    ent:Spawn()
    ent:Activate()

    if WanderingDirector then
        WanderingDirector.Entities = WanderingDirector.Entities or {}
        WanderingDirector.Entities[#WanderingDirector.Entities + 1] = ent
    end
    if EncounterDirector then
        EncounterDirector.Entities = EncounterDirector.Entities or {}
        EncounterDirector.Entities[#EncounterDirector.Entities + 1] = ent
    end

    Watcher.TestEntities = Watcher.TestEntities or {}
    Watcher.TestEntities[#Watcher.TestEntities + 1] = ent
    return ent
end

local function horizontal(v)
    local out = Vector(v.x, v.y, 0)
    if out:LengthSqr() <= 0.001 then return Vector(1, 0, 0) end
    return out:GetNormalized()
end

local function clearSightToPlayer(ply, pos)
    local tr = util.TraceLine({
        start = pos + Vector(0, 0, 52),
        endpos = ply:EyePos(),
        mask = MASK_SHOT,
        filter = function(ent)
            if ent == ply then return false end
            if IsValid(ent) and ent.LODHostile then return false end
            return true
        end
    })
    return not tr.Hit or tr.Fraction >= 0.995
end

-- Human-facing test placement. Choose a legal point in the player's current cell,
-- deliberately separated from the player and preferentially in front of the view.
-- The important invariant is that the tester can see the Watcher before its state
-- machine starts doing anything interesting.
local function visibleWatcherSpawn(graph, cell, ply)
    local forward = horizontal(ply:EyeAngles():Forward())
    local right = horizontal(ply:EyeAngles():Right())
    local dirs = {
        forward,
        horizontal(forward + right * 0.55),
        horizontal(forward - right * 0.55),
        right,
        -right,
        -forward
    }

    local best, bestScore
    for index, dir in ipairs(dirs) do
        local raw = ply:GetPos() + dir * DESIRED_VISIBLE_DISTANCE
        local candidate = Motion:CellFloorPoint(cell, raw)
        local distance = candidate:Distance(ply:GetPos())
        if distance >= MIN_VISIBLE_DISTANCE and clearSightToPlayer(ply, candidate) then
            local facing = forward:Dot(horizontal(candidate - ply:GetPos()))
            local score = facing * 1000 + distance - index * 0.01
            if not bestScore or score > bestScore then
                best = candidate
                bestScore = score
            end
        end
    end

    if best then return best end

    local center = Navigator:CellCenter(cell)
    local offsets = {
        Vector(150, 150, 0), Vector(150, -150, 0),
        Vector(-150, 150, 0), Vector(-150, -150, 0),
        Vector(150, 0, 0), Vector(-150, 0, 0),
        Vector(0, 150, 0), Vector(0, -150, 0)
    }
    for _, offset in ipairs(offsets) do
        local candidate = Motion:CellFloorPoint(cell, center + offset)
        local distance = candidate:Distance(ply:GetPos())
        if distance >= MIN_VISIBLE_DISTANCE and clearSightToPlayer(ply, candidate) then
            return candidate
        end
    end
    return nil
end

local function validateTestLocation(ply)
    local state, graph = currentState()
    if not state or not graph or not state.BuildReady then
        return nil, nil, "Watcher test requires an active generated dungeon."
    end

    local playerCell = Navigator:WorldToCell(graph, ply:GetPos())
    if not playerCell then
        return nil, nil, "Watcher test could not resolve your maze cell."
    end
    if safeCell(graph, playerCell) then
        return nil, nil, "Watcher test: move into a normal non-safe maze cell, then run the command again."
    end
    return graph, playerCell, nil
end

local function beginCycleTest(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local graph, playerCell, err = validateTestLocation(ply)
    if err then
        ply:ChatPrint(err)
        return
    end

    local watcherPos = visibleWatcherSpawn(graph, playerCell, ply)
    if not watcherPos then
        ply:ChatPrint("Watcher test could not find a visible spawn point. Step toward the middle of this cell and retry.")
        return
    end

    cleanupTestEntities()
    local watcher = spawnTestHostile("watcher", graph, playerCell, watcherPos, TEST_WATCHER_ORDINAL)
    if not IsValid(watcher) then
        ply:ChatPrint("Watcher test failed to create the Watcher.")
        return
    end

    watcher.LODWatcherCycleTest = true
    watcher.LODTarget = ply
    watcher.LODReturningHome = false
    watcher.LODWaypoints = {}
    watcher.LODWaypointIndex = 1
    watcher.LODNextTargetRefresh = CurTime() + 0.65
    watcher.LODNextRouteRefresh = 0
    watcher.LODNextWatcherScan = CurTime() + INITIAL_SCAN_DELAY
    watcher:SetNoDraw(false)

    Watcher.Stats.testSpawns = (Watcher.Stats.testSpawns or 0) + 1
    local visibleDistance = watcher:GetPos():Distance(ply:GetPos())
    local line = string.format(
        "watcher=#%s visibleSpawn=%.0fu cycleOnly=true initialScanDelay=%.2fs",
        watcher:EntIndex(),
        visibleDistance,
        INITIAL_SCAN_DELAY)
    print("[LOD:WATCHER-TEST] " .. line)
    ply:ChatPrint(line)
end

local function movementResumed(cmd)
    if not cmd then return false end
    return math.abs(cmd:GetForwardMove()) > 0.01
        or math.abs(cmd:GetSideMove()) > 0.01
        or math.abs(cmd:GetUpMove()) > 0.01
end

-- Do not start the experiment while the developer console is still covering the
-- game. Console time is real server time in GMod; the old test could complete a
-- scan and enter cloak before the tester ever returned to gameplay. Arm the test
-- at the command, then spawn only after the first actual movement usercmd.
hook.Add("StartCommand", "LOD_WatcherCycleTestResumeGate", function(ply, cmd)
    local pending = PendingCycleTests[ply]
    if not pending or not movementResumed(cmd) then return end
    if CurTime() < (pending.armedAt or 0) + 0.10 then return end

    PendingCycleTests[ply] = nil
    timer.Simple(0, function()
        if IsValid(ply) then beginCycleTest(ply) end
    end)
end)

hook.Add("PlayerDisconnected", "LOD_WatcherCycleTestCleanupPending", function(ply)
    PendingCycleTests[ply] = nil
end)

concommand.Remove("lod_watcher_test")
concommand.Add("lod_watcher_test", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local _, _, err = validateTestLocation(ply)
    if err then
        ply:ChatPrint(err)
        return
    end

    cleanupTestEntities()
    PendingCycleTests[ply] = {armedAt = CurTime()}
    local line = "Watcher cycle test armed. Close console, then tap a movement key; one Watcher will spawn in front of you."
    print("[LOD:WATCHER-TEST] " .. line)
    ply:ChatPrint(line)
end)

print("[LOD:WATCHER-TEST] deterministic post-console cycle test armed")
