LOD = LOD or {}

local SUPPORT_DISTANCE = 48
local SUPPORT_HULL_MINS = Vector(-8, -8, 0)
local SUPPORT_HULL_MAXS = Vector(8, 8, 2)
local callbacks = concommand.GetTable()
local previousAudit = callbacks and callbacks["lod_m1_audit"]

local function allowed(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function transitionCellSet(graph)
    local cells = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        cells[LOD.MazeGenerator.CellKey(edge.a.x, edge.a.y, edge.a.z)] = true
        cells[LOD.MazeGenerator.CellKey(edge.b.x, edge.b.y, edge.b.z)] = true
    end
    return cells
end

-- Match player movement more closely than the original infinitely-thin line
-- probe. The generated maze surfaces are SOLID_BBOX entities, and a small feet
-- hull with the player-movement collision group is the relevant support test.
local function hasSupport(pos, ignored)
    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 2),
        endpos = pos - Vector(0, 0, SUPPORT_DISTANCE),
        mins = SUPPORT_HULL_MINS,
        maxs = SUPPORT_HULL_MAXS,
        mask = MASK_SOLID,
        collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
        filter = ignored
    })
    return tr.Hit and not tr.StartSolid, tr
end

local function classifyHit(tr, counts)
    if not tr or not tr.Hit then return end
    if tr.HitWorld then
        counts.world = counts.world + 1
        return
    end
    if IsValid(tr.Entity) then
        local class = tr.Entity:GetClass()
        if class == "lod_static_box" then
            counts.generated = counts.generated + 1
        else
            counts.other = counts.other + 1
        end
    else
        counts.other = counts.other + 1
    end
end

local function supportAudit()
    local state = LOD.RunManager.State
    local graph = state.Graph
    local buildReport = state.BuildReport
    if not state.BuildReady or not graph or not buildReport then
        return nil, "no validated built level is active"
    end

    local ignored = player.GetAll()
    local transitionCells = transitionCellSet(graph)
    local tested = 0
    local unsupported = 0
    local examples = {}
    local hits = {generated = 0, world = 0, other = 0}

    for key, cell in pairs(graph.Cells) do
        if not transitionCells[key] then
            tested = tested + 1
            local pos = LOD.MazeBuilder:CellCenter(cell) + Vector(0, 0, 12)
            local supported, tr = hasSupport(pos, ignored)
            if supported then
                classifyHit(tr, hits)
            else
                unsupported = unsupported + 1
                if #examples < 8 then examples[#examples + 1] = key end
            end
        end
    end

    local startSupported, startTrace = hasSupport(buildReport.startPos, ignored)
    return {
        pass = startSupported and unsupported == 0,
        startSupported = startSupported,
        startHitWorld = startTrace and startTrace.HitWorld or false,
        startHitClass = startTrace and IsValid(startTrace.Entity) and startTrace.Entity:GetClass() or nil,
        testedCenters = tested,
        unsupportedCenters = unsupported,
        unsupportedExamples = examples,
        supportHits = hits,
        supportDistance = SUPPORT_DISTANCE,
        worldFloorZ = buildReport.worldFloorZ,
        mazeOriginZ = buildReport.mazeOriginZ,
        groundFloorOffset = buildReport.groundFloorOffset,
        floorAnchorSource = buildReport.floorAnchorSource
    }
end

local function printSupportReport(ply, result, err)
    if not result then
        local line = "support audit unavailable: " .. tostring(err)
        print("[LOD:M1] " .. line)
        if IsValid(ply) then ply:ChatPrint(line) end
        return false
    end

    local line = string.format(
        "support start=%s unsupported=%d/%d generatedHits=%d worldHits=%d otherHits=%d floorZ=%s originZ=%s offset=%s anchor=%s",
        tostring(result.startSupported),
        result.unsupportedCenters,
        result.testedCenters,
        result.supportHits.generated,
        result.supportHits.world,
        result.supportHits.other,
        tostring(result.worldFloorZ),
        tostring(result.mazeOriginZ),
        tostring(result.groundFloorOffset),
        tostring(result.floorAnchorSource)
    )
    print("[LOD:M1] " .. line)

    if result.unsupportedCenters > 0 then
        print("[LOD:M1] unsupported examples=" .. table.concat(result.unsupportedExamples, ","))
    end

    local finalLine = "M1 AUDIT FINAL " .. (result.pass and "PASS" or "FAIL") .. " | floor-support=" .. (result.pass and "PASS" or "FAIL")
    print("[LOD:M1] " .. finalLine)

    local state = LOD.RunManager.State
    file.CreateDir("legend_of_deborah")
    local filename = string.format(
        "legend_of_deborah/m1_support_%s_L%d_%s.json",
        tostring(state.CampaignSeed), state.Level, tostring(state.LevelSeed)
    )
    file.Write(filename, util.TableToJSON(result, true))
    print("[LOD:M1] wrote data/" .. filename)

    if IsValid(ply) then ply:ChatPrint(finalLine) end
    return result.pass
end

concommand.Add("lod_m1_support", function(ply)
    if not allowed(ply) then return end
    local result, err = supportAudit()
    printSupportReport(ply, result, err)
end)

-- Extend the existing M1 audit without duplicating its established checks.
-- concommand.GetTable is an official API and returns Lua command callbacks.
if previousAudit then
    concommand.Remove("lod_m1_audit")
    concommand.Add("lod_m1_audit", function(ply, cmd, args, argStr)
        if not allowed(ply) then return end
        previousAudit(ply, cmd, args, argStr)
        local result, err = supportAudit()
        printSupportReport(ply, result, err)
    end)
end
