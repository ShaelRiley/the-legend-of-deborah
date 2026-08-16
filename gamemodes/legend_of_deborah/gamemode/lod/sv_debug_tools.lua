LOD = LOD or {}

util.AddNetworkString("LOD_DebugGraphBegin")
util.AddNetworkString("LOD_DebugGraphEdge")
util.AddNetworkString("LOD_DebugGraphEnd")

local function allowed(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function sendGraph(ply)
    local graph = LOD.RunManager.State.Graph
    if not graph or not IsValid(ply) then return end

    net.Start("LOD_DebugGraphBegin")
    net.WriteUInt(graph.Layers, 3)
    net.WriteUInt(table.Count(graph.Cells), 12)
    net.Send(ply)

    for _, edge in pairs(graph.Edges) do
        net.Start("LOD_DebugGraphEdge")
        net.WriteVector(LOD.MazeBuilder:CellCenter(edge.a) + Vector(0, 0, 40))
        net.WriteVector(LOD.MazeBuilder:CellCenter(edge.b) + Vector(0, 0, 40))
        net.WriteBool(edge.a.z ~= edge.b.z)
        net.Send(ply)
    end

    net.Start("LOD_DebugGraphEnd")
    net.Send(ply)
end

concommand.Add("lod_debug_graph", function(ply)
    if not allowed(ply) then return end
    if IsValid(ply) then sendGraph(ply) end
end)

concommand.Add("lod_regenerate", function(ply, _, args)
    if not allowed(ply) then return end
    local override = tonumber(args[1])
    local ok, result = LOD.RunManager:Regenerate(override)
    local message = ok and "regenerated" or ("failed: " .. tostring(result))
    if IsValid(ply) then ply:ChatPrint("LOD " .. message) else print("[LOD] " .. message) end
end)

concommand.Add("lod_validation", function(ply)
    if not allowed(ply) then return end
    local graph = LOD.RunManager.State.Graph
    if not graph then return end
    local v = graph.Validation
    local line = string.format(
        "valid=%s cells=%d reachable=%d criticalPath=%d vertical=%d attempt=%d",
        tostring(v.valid), v.cellCount, v.reachableCount, v.criticalPathLength,
        v.criticalVerticalTransitions, graph.Attempt
    )
    if IsValid(ply) then ply:ChatPrint(line) else print("[LOD] " .. line) end
end)

concommand.Add("lod_seed_test", function(ply, _, args)
    if not allowed(ply) then return end
    local count = math.Clamp(tonumber(args[1]) or 100, 1, LOD.Config.Debug.SeedTestMax)
    local base = LOD.RunManager.State.LevelSeed or 1
    local failures = 0
    local worstAttempts = 0
    local minVertical = 999

    for i = 1, count do
        local seed = LOD.Seeds.Derive(base, "seed-test:" .. i)
        local graph = LOD.MazeGenerator:Generate(seed)
        if not graph then
            failures = failures + 1
        else
            worstAttempts = math.max(worstAttempts, graph.Attempt)
            minVertical = math.min(minVertical, graph.Validation.criticalVerticalTransitions)
        end
    end

    local report = string.format(
        "seed test: %d generated, %d failures, worst attempts=%d, min critical vertical=%d",
        count, failures, worstAttempts, minVertical == 999 and 0 or minVertical
    )
    print("[LOD] " .. report)
    if IsValid(ply) then ply:ChatPrint(report) end
end)

local PLAYER_HULL_MINS = Vector(-16, -16, 0)
local PLAYER_HULL_MAXS = Vector(16, 16, 72)

local function transitionCellSet(graph)
    local cells = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        cells[LOD.MazeGenerator.CellKey(edge.a.x, edge.a.y, edge.a.z)] = true
        cells[LOD.MazeGenerator.CellKey(edge.b.x, edge.b.y, edge.b.z)] = true
    end
    return cells
end

local function activePlayerDiagnostics()
    local active = 0
    local noCollideFailures = 0
    for _, candidate in ipairs(player.GetAll()) do
        if LOD.RunManager:IsActivePlayer(candidate) then
            active = active + 1
            if not candidate:GetNoCollideWithTeammates() then
                noCollideFailures = noCollideFailures + 1
            end
        end
    end
    return active, noCollideFailures
end

local function auditPlayerClearance(graph, buildReport)
    local ignored = player.GetAll()
    local transitionCells = transitionCellSet(graph)
    local blockedCenters = 0
    local blockedOpenEdges = 0
    local testedCenters = 0
    local testedOpenEdges = 0

    for key, cell in pairs(graph.Cells) do
        if not transitionCells[key] then
            testedCenters = testedCenters + 1
            local pos = LOD.MazeBuilder:CellCenter(cell) + Vector(0, 0, 12)
            local tr = util.TraceHull({
                start = pos,
                endpos = pos,
                mins = PLAYER_HULL_MINS,
                maxs = PLAYER_HULL_MAXS,
                mask = MASK_PLAYERSOLID,
                filter = ignored
            })
            if tr.Hit or tr.StartSolid then blockedCenters = blockedCenters + 1 end
        end
    end

    for _, edge in ipairs(graph.Edges or {}) do
        if edge.a.z == edge.b.z then
            local ak = LOD.MazeGenerator.CellKey(edge.a.x, edge.a.y, edge.a.z)
            local bk = LOD.MazeGenerator.CellKey(edge.b.x, edge.b.y, edge.b.z)
            if not transitionCells[ak] and not transitionCells[bk] then
                testedOpenEdges = testedOpenEdges + 1
                local a = LOD.MazeBuilder:CellCenter(edge.a) + Vector(0, 0, 12)
                local b = LOD.MazeBuilder:CellCenter(edge.b) + Vector(0, 0, 12)
                local tr = util.TraceHull({
                    start = a,
                    endpos = b,
                    mins = PLAYER_HULL_MINS,
                    maxs = PLAYER_HULL_MAXS,
                    mask = MASK_PLAYERSOLID,
                    filter = ignored
                })
                if tr.Hit or tr.StartSolid then blockedOpenEdges = blockedOpenEdges + 1 end
            end
        end
    end

    local startTrace = util.TraceHull({
        start = buildReport.startPos,
        endpos = buildReport.startPos,
        mins = PLAYER_HULL_MINS,
        maxs = PLAYER_HULL_MAXS,
        mask = MASK_PLAYERSOLID,
        filter = ignored
    })

    return {
        testedCenters = testedCenters,
        blockedCenters = blockedCenters,
        testedOpenEdges = testedOpenEdges,
        blockedOpenEdges = blockedOpenEdges,
        startClear = not startTrace.Hit and not startTrace.StartSolid
    }
end

local function modelDiagnostics(buildReport)
    local invalid = {}
    local C = LOD.Config

    if not util.IsValidProp(C.Geometry.ContainerModel) then
        invalid[#invalid + 1] = C.Geometry.ContainerModel
    end
    if not util.IsValidModel(C.Models.Deborah) then
        invalid[#invalid + 1] = C.Models.Deborah
    end
    for _, character in ipairs(C.Models.Characters) do
        if not util.IsValidModel(character.model) then
            invalid[#invalid + 1] = character.model
        end
    end

    local bounds = buildReport.containerBounds
    return {
        invalid = invalid,
        containerBounds = bounds and {
            mins = tostring(bounds.mins),
            maxs = tostring(bounds.maxs),
            size = tostring(bounds.size)
        } or nil
    }
end

local function auditLine(lines, fmt, ...)
    lines[#lines + 1] = string.format(fmt, ...)
end

concommand.Add("lod_m1_audit", function(ply)
    if not allowed(ply) then return end

    local state = LOD.RunManager.State
    local graph = state.Graph
    local buildReport = state.BuildReport
    if not state.BuildReady or not graph or not buildReport then
        local msg = "Milestone 1 audit unavailable: no validated built level is active"
        print("[LOD:M1] " .. msg)
        if IsValid(ply) then ply:ChatPrint(msg) end
        return
    end

    local clearance = auditPlayerClearance(graph, buildReport)
    local models = modelDiagnostics(buildReport)
    local activePlayers, noCollideFailures = activePlayerDiagnostics()
    local G = LOD.Config.Geometry
    local M = LOD.Config.Maze
    local wallHeight = G.ContainerHeight * G.WallStack
    local wallTopGap = M.LevelHeight - wallHeight
    local stairRise = M.LevelHeight / G.StairSteps
    local counts = buildReport.entityCounts or {}
    local validation = graph.Validation or {}

    local report = {
        version = LOD.Version,
        map = game.GetMap(),
        campaignSeed = state.CampaignSeed,
        level = state.Level,
        levelSeed = state.LevelSeed,
        ranked = state.Ranked,
        graph = {
            valid = validation.valid == true,
            cells = validation.cellCount,
            reachable = validation.reachableCount,
            criticalPath = validation.criticalPathLength,
            criticalVertical = validation.criticalVerticalTransitions,
            verticalEdges = #(graph.VerticalEdges or {}),
            generationAttempt = graph.Attempt
        },
        timing = {
            generationSeconds = buildReport.generationSeconds or -1,
            buildSeconds = buildReport.buildSeconds or -1,
            totalSeconds = buildReport.totalSeconds or -1,
            typicalTargetMet = (buildReport.totalSeconds or math.huge) <= 5,
            worstCaseTargetMet = (buildReport.totalSeconds or math.huge) <= 10
        },
        geometry = {
            entities = buildReport.entityCount,
            containers = counts.containers or 0,
            floorBoxes = counts.floorBoxes or 0,
            stairBoxes = counts.stairBoxes or 0,
            railBoxes = counts.railBoxes or 0,
            other = counts.other or 0,
            levelHeight = M.LevelHeight,
            wallHeight = wallHeight,
            wallTopGap = wallTopGap,
            stairRise = stairRise,
            stairRun = G.StairRun,
            model = models
        },
        clearance = clearance,
        multiplayer = {
            activePlayers = activePlayers,
            noCollideFailures = noCollideFailures
        }
    }

    report.pass = (
        report.map == "gm_flatgrass" and
        report.graph.valid and
        #models.invalid == 0 and
        clearance.startClear and
        clearance.blockedCenters == 0 and
        clearance.blockedOpenEdges == 0 and
        noCollideFailures == 0 and
        wallTopGap >= 72 and
        stairRise <= 18 and
        report.timing.worstCaseTargetMet
    )

    local lines = {}
    auditLine(lines, "M1 AUDIT %s | map=%s level=%d campaign=%s seed=%s", report.pass and "PASS" or "FAIL", report.map, report.level, tostring(report.campaignSeed), tostring(report.levelSeed))
    auditLine(lines, "graph valid=%s cells=%d reachable=%d critical=%d criticalVertical=%d verticalEdges=%d attempt=%d", tostring(report.graph.valid), report.graph.cells or -1, report.graph.reachable or -1, report.graph.criticalPath or -1, report.graph.criticalVertical or -1, report.graph.verticalEdges, report.graph.generationAttempt or -1)
    auditLine(lines, "timing generation=%.3fs geometry=%.3fs total=%.3fs typical<=5=%s worst<=10=%s", report.timing.generationSeconds, report.timing.buildSeconds, report.timing.totalSeconds, tostring(report.timing.typicalTargetMet), tostring(report.timing.worstCaseTargetMet))
    auditLine(lines, "entities total=%d containers=%d floors=%d stairs=%d rails=%d other=%d", report.geometry.entities or -1, report.geometry.containers, report.geometry.floorBoxes, report.geometry.stairBoxes, report.geometry.railBoxes, report.geometry.other)
    auditLine(lines, "layer spacing=%d wallHeight=%d wallTopGap=%d stairRise=%.1f stairRun=%d", report.geometry.levelHeight, report.geometry.wallHeight, report.geometry.wallTopGap, report.geometry.stairRise, report.geometry.stairRun)
    auditLine(lines, "clearance start=%s centers=%d/%d blocked openEdges=%d/%d blocked", tostring(clearance.startClear), clearance.blockedCenters, clearance.testedCenters, clearance.blockedOpenEdges, clearance.testedOpenEdges)
    auditLine(lines, "models invalid=%d containerBounds=%s", #models.invalid, models.containerBounds and models.containerBounds.size or "unavailable")
    auditLine(lines, "multiplayer active=%d teammateNoCollideFailures=%d", activePlayers, noCollideFailures)

    for _, line in ipairs(lines) do print("[LOD:M1] " .. line) end

    file.CreateDir("legend_of_deborah")
    local filename = string.format("legend_of_deborah/m1_audit_%s_L%d_%s.json", tostring(state.CampaignSeed), state.Level, tostring(state.LevelSeed))
    file.Write(filename, util.TableToJSON(report, true))
    print("[LOD:M1] wrote data/" .. filename)

    if IsValid(ply) then
        ply:ChatPrint(lines[1])
        ply:ChatPrint("Full audit written to data/" .. filename)
    end
end)
