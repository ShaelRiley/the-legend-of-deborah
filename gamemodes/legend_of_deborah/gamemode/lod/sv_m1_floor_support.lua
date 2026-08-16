LOD = LOD or {}

local SUPPORT_DISTANCE = 48
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

local function hasSupport(pos, ignored)
    local tr = util.TraceLine({
        start = pos + Vector(0, 0, 2),
        endpos = pos - Vector(0, 0, SUPPORT_DISTANCE),
        mask = MASK_PLAYERSOLID,
        filter = ignored
    })
    return tr.Hit and not tr.StartSolid, tr
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

    for key, cell in pairs(graph.Cells) do
        if not transitionCells[key] then
            tested = tested + 1
            local pos = LOD.MazeBuilder:CellCenter(cell) + Vector(0, 0, 12)
            local supported = hasSupport(pos, ignored)
            if not supported then
                unsupported = unsupported + 1
                if #examples < 8 then examples[#examples + 1] = key end
            end
        end
    end

    local startSupported = hasSupport(buildReport.startPos, ignored)
    return {
        pass = startSupported and unsupported == 0,
        startSupported = startSupported,
        testedCenters = tested,
        unsupportedCenters = unsupported,
        unsupportedExamples = examples,
        supportDistance = SUPPORT_DISTANCE,
        worldFloorZ = buildReport.worldFloorZ,
        mazeOriginZ = buildReport.mazeOriginZ,
        groundFloorOffset = buildReport.groundFloorOffset
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
        "support start=%s unsupported=%d/%d worldFloorZ=%s mazeOriginZ=%s offset=%s",
        tostring(result.startSupported),
        result.unsupportedCenters,
        result.testedCenters,
        tostring(result.worldFloorZ),
        tostring(result.mazeOriginZ),
        tostring(result.groundFloorOffset)
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
