LOD = LOD or {}

local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local cellKey = LOD.MazeGenerator.CellKey

local DIRS = {
    {name = "N", dx = 0, dy = 1},
    {name = "E", dx = 1, dy = 0},
    {name = "S", dx = 0, dy = -1},
    {name = "W", dx = -1, dy = 0}
}

local function allowed(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    return keys
end

local function hasOpenEdge(graph, cell, nx, ny, nz)
    local c = graph.Cells[cellKey(cell.x, cell.y, cell.z)]
    return c and c.neighbors[cellKey(nx, ny, nz)] == true
end

local function transitionDirection(edge)
    if edge.LODStairDirection then return edge.LODStairDirection end
    local n = (edge.a.x * 17 + edge.a.y * 31 + edge.a.z * 13) % 4
    return ({"E", "N", "W", "S"})[n + 1]
end

local function lowerCell(edge)
    return edge.a.z < edge.b.z and edge.a or edge.b
end

local function upperCell(edge)
    return edge.a.z > edge.b.z and edge.a or edge.b
end

local function stairEntry(dir)
    -- The low end now extends into the graph-approved open approach cell. Put
    -- the tester a short distance before that first tread rather than inside the
    -- transition cell itself.
    local topOffset = GC.StairTopOffset or 64
    local approach = GC.StairRun - topOffset + 32
    if dir == "E" then return Vector(-approach, 0, 20), Angle(0, 0, 0) end
    if dir == "W" then return Vector(approach, 0, 20), Angle(0, 180, 0) end
    if dir == "N" then return Vector(0, -approach, 20), Angle(0, 90, 0) end
    return Vector(0, approach, 20), Angle(0, -90, 0)
end

local function bypassAudit()
    local state = LOD.RunManager.State
    local graph = state.Graph
    if not state.BuildReady or not graph then
        return nil, "no validated built level is active"
    end

    local seen = {}
    local tested = 0
    local blocked = 0
    local gaps = 0
    local examples = {}
    local visibleWallHeight = GC.ContainerHeight * GC.WallStack
    local blockerHeight = GC.AntiBypassHeight or MC.LevelHeight
    local testHeight = visibleWallHeight + math.max(16, (blockerHeight - visibleWallHeight) * 0.5)
    local ignored = player.GetAll()

    for _, key in ipairs(sortedKeys(graph.Cells)) do
        local cell = graph.Cells[key]
        local center = LOD.MazeBuilder:CellCenter(cell)

        for _, d in ipairs(DIRS) do
            local nx, ny, nz = cell.x + d.dx, cell.y + d.dy, cell.z
            if not hasOpenEdge(graph, cell, nx, ny, nz) then
                local a = cellKey(cell.x, cell.y, cell.z)
                local b = cellKey(nx, ny, nz)
                local wallKey = a < b and (a .. "|" .. b) or (b .. "|" .. a)
                if not seen[wallKey] then
                    seen[wallKey] = true
                    tested = tested + 1

                    local startPos = center + Vector(0, 0, testHeight)
                    local endPos = startPos + Vector(d.dx * MC.CellSize, d.dy * MC.CellSize, 0)
                    local tr = util.TraceLine({
                        start = startPos,
                        endpos = endPos,
                        mask = MASK_PLAYERSOLID,
                        filter = ignored
                    })

                    local wallBlocked = tr.Hit and IsValid(tr.Entity) and
                        tr.Entity:GetClass() == "lod_static_box" and
                        tr.Entity:GetBoxKind() == 4

                    if wallBlocked then
                        blocked = blocked + 1
                    else
                        gaps = gaps + 1
                        if #examples < 8 then examples[#examples + 1] = wallKey end
                    end
                end
            end
        end
    end

    return {
        pass = gaps == 0 and blockerHeight >= MC.LevelHeight,
        tested = tested,
        blocked = blocked,
        gaps = gaps,
        gapExamples = examples,
        visibleWallHeight = visibleWallHeight,
        blockerHeight = blockerHeight,
        testHeight = testHeight
    }
end

local function printBypass(result, err)
    if not result then
        print("[LOD:M1] bypass audit unavailable: " .. tostring(err))
        return false
    end

    print(string.format(
        "[LOD:M1] bypass %s walls=%d blocked=%d gaps=%d visibleWall=%d blocker=%d testZ=%.1f",
        result.pass and "PASS" or "FAIL",
        result.tested,
        result.blocked,
        result.gaps,
        result.visibleWallHeight,
        result.blockerHeight,
        result.testHeight
    ))
    if result.gaps > 0 then
        print("[LOD:M1] bypass gap examples=" .. table.concat(result.gapExamples, ","))
    end
    return result.pass
end

concommand.Add("lod_m1_bypass_audit", function(ply)
    if not allowed(ply) then return end
    local result, err = bypassAudit()
    local pass = printBypass(result, err)
    if IsValid(ply) then
        ply:ChatPrint("M1 wall-top bypass audit: " .. (pass and "PASS" or "FAIL"))
    end
end)

concommand.Add("lod_m1_stairs", function(ply)
    if not allowed(ply) then return end
    local graph = LOD.RunManager.State.Graph
    if not graph then return end

    local innerWallFace = MC.CellSize * 0.5 - GC.ContainerWidth * 0.5
    local upperLanding = innerWallFace - (GC.StairTopOffset or 64)
    print(string.format(
        "[LOD:M1] vertical transitions=%d stairRun=%d topOffset=%d upperLanding=%.1f",
        #(graph.VerticalEdges or {}), GC.StairRun, GC.StairTopOffset or 64, upperLanding
    ))
    for i, edge in ipairs(graph.VerticalEdges or {}) do
        local lower = lowerCell(edge)
        local upper = upperCell(edge)
        print(string.format(
            "[LOD:M1] stair %d lower=(%d,%d,%d) upper=(%d,%d,%d) entry=%s ascend=%s",
            i, lower.x, lower.y, lower.z, upper.x, upper.y, upper.z,
            tostring(edge.LODStairEntrySide), transitionDirection(edge)
        ))
    end
    if IsValid(ply) then ply:ChatPrint("Use lod_m1_stair <number> to test a transition.") end
end)

concommand.Add("lod_m1_stair", function(ply, _, args)
    if not allowed(ply) or not IsValid(ply) then return end
    local state = LOD.RunManager.State
    local graph = state.Graph
    if not state.BuildReady or not graph then
        ply:ChatPrint("No validated labyrinth is active.")
        return
    end

    local count = #(graph.VerticalEdges or {})
    local index = math.floor(tonumber(args[1]) or 1)
    if index < 1 or index > count then
        ply:ChatPrint(string.format("Stair index must be 1-%d.", count))
        return
    end

    local edge = graph.VerticalEdges[index]
    if not edge.LODStairEntrySide then
        ply:ChatPrint(string.format("Stair %d has no horizontal lower approach; this transition requires investigation.", index))
        return
    end

    LOD.RunManager:MarkUnranked("vertical traversal debug teleport")
    local lower = lowerCell(edge)
    local upper = upperCell(edge)
    local dir = transitionDirection(edge)
    local offset, view = stairEntry(dir)
    local target = LOD.MazeBuilder:CellCenter(lower) + offset

    local hull = util.TraceHull({
        start = target,
        endpos = target,
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_PLAYERSOLID,
        filter = ply
    })
    if hull.Hit or hull.StartSolid then
        ply:ChatPrint(string.format("Stair %d debug approach is obstructed; do not attempt traversal.", index))
        return
    end

    ply:SetPos(target)
    ply:SetEyeAngles(view)
    ply:SetVelocity(-ply:GetVelocity())
    ply:ChatPrint(string.format(
        "Stair %d/%d: clear approach from %s; walk straight %s from layer %d to %d. Do not jump.",
        index, count, edge.LODStairEntrySide, dir, lower.z, upper.z
    ))
end)

local callbacks = concommand.GetTable()
local previousAudit = callbacks and callbacks["lod_m1_audit"]
if previousAudit then
    concommand.Remove("lod_m1_audit")
    concommand.Add("lod_m1_audit", function(ply, cmd, args, argStr)
        if not allowed(ply) then return end
        previousAudit(ply, cmd, args, argStr)
        local result, err = bypassAudit()
        printBypass(result, err)
    end)
end
