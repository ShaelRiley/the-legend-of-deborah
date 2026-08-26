LOD = LOD or {}

local Watcher = LOD.Watcher
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2
local WanderingDirector = LOD.WanderingDirector
local EncounterDirector = LOD.EncounterDirector
local cellKey = LOD.MazeGenerator and LOD.MazeGenerator.CellKey

if not Watcher or not Navigator or not Motion or not cellKey then return end

local TEST_WATCHER_ORDINAL = 980001
local TEST_SLEEPER_ORDINAL = 980002
local MIN_VISIBLE_DISTANCE = 154
local DESIRED_VISIBLE_DISTANCE = 184

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
    ent.LODWanderSeed = LOD.Seeds.Derive((LOD.RunManager.State.LevelSeed or 1), "watcher-visible-test:" .. ordinal)
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

-- The old test placed the Scanner at the exact logical cell center regardless of
-- the player's position. A player near that center could therefore have the test
-- entity created inside/above their own body, after which close-range recovery
-- immediately carried it away. The command correctly printed a valid entity id,
-- but the human-facing test could look as though nothing spawned.
--
-- Pick a same-cell, graph-safe point deliberately separated from the player and
-- preferably in front of their view. This alters only developer-test placement;
-- production Watcher spawn/routing remains untouched.
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

local function distantTestCell(graph, playerCell)
    local keys = {}
    for key, cell in pairs(graph.Cells or {}) do
        if cell.z == playerCell.z and not safeCell(graph, cell) then keys[#keys + 1] = key end
    end
    table.sort(keys)
    local fallback
    for _, key in ipairs(keys) do
        local cell = graph.Cells[key]
        local distance = Navigator:Distance(graph, playerCell, cell)
        if distance == 5 or distance == 6 then return cell end
        if not fallback and distance > 4 and distance ~= math.huge then fallback = cell end
    end
    return fallback
end

concommand.Remove("lod_watcher_test")
concommand.Add("lod_watcher_test", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local state, graph = currentState()
    if not state or not graph or not state.BuildReady then
        ply:ChatPrint("Watcher test requires an active generated dungeon.")
        return
    end

    local playerCell = Navigator:WorldToCell(graph, ply:GetPos())
    if not playerCell then
        ply:ChatPrint("Watcher test could not resolve your maze cell.")
        return
    end
    if safeCell(graph, playerCell) then
        ply:ChatPrint("Watcher test: move into a normal non-safe maze cell, then run the command again.")
        return
    end

    local watcherPos = visibleWatcherSpawn(graph, playerCell, ply)
    if not watcherPos then
        ply:ChatPrint("Watcher test could not find a visible same-cell spawn point. Step toward the middle of this cell and retry.")
        return
    end

    cleanupTestEntities()
    local watcher = spawnTestHostile("watcher", graph, playerCell, watcherPos, TEST_WATCHER_ORDINAL)
    local alertCell = distantTestCell(graph, playerCell)
    local sleeper = alertCell and spawnTestHostile("shambler", graph, alertCell,
        Motion:CellFloorPoint(alertCell, Navigator:CellCenter(alertCell)), TEST_SLEEPER_ORDINAL) or nil

    if IsValid(watcher) then
        watcher.LODTarget = ply
        watcher.LODReturningHome = false
        watcher.LODWaypoints = {}
        watcher.LODWaypointIndex = 1
        watcher.LODNextTargetRefresh = CurTime() + 0.65
        watcher.LODNextRouteRefresh = 0
        -- Briefly delay scan eligibility so the spawned Scanner is visibly present
        -- before its ordinary approach/range-recovery/scan state machine takes over.
        watcher.LODNextWatcherScan = CurTime() + 0.55
        watcher:SetNoDraw(false)
    end
    if IsValid(sleeper) then sleeper.LODNextTargetRefresh = CurTime() + 0.15 end

    Watcher.Stats.testSpawns = (Watcher.Stats.testSpawns or 0) + 1
    local sleeperDistance = alertCell and Navigator:Distance(graph, playerCell, alertCell) or math.huge
    local visibleDistance = IsValid(watcher) and watcher:GetPos():Distance(ply:GetPos()) or 0
    local line = string.format(
        "watcher=#%s visibleSpawn=%.0fu alertWanderer=#%s naturalAcquireDistance=%s scan=1.25s alertRadius=6",
        IsValid(watcher) and watcher:EntIndex() or "FAIL",
        visibleDistance,
        IsValid(sleeper) and sleeper:EntIndex() or "none",
        sleeperDistance ~= math.huge and tostring(sleeperDistance) or "none")
    print("[LOD:WATCHER-TEST] " .. line)
    ply:ChatPrint(line)
end)
