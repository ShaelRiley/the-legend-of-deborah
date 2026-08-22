LOD = LOD or {}
LOD.VerticalTransitionAudit = LOD.VerticalTransitionAudit or {}

local Audit = LOD.VerticalTransitionAudit
local Builder = LOD.MazeBuilder
local Navigator = LOD.MazeNavigator
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local cellKey = LOD.MazeGenerator.CellKey

local DIR = {
    E = Vector(1, 0, 0), W = Vector(-1, 0, 0),
    N = Vector(0, 1, 0), S = Vector(0, -1, 0)
}

local function lowerUpper(edge)
    if edge.a.z < edge.b.z then return edge.a, edge.b end
    return edge.b, edge.a
end

local function authoritativeStaticBoxes()
    if Builder and istable(Builder.Entities) and #Builder.Entities > 0 then
        return Builder.Entities
    end
    return ents.FindByClass("lod_static_box")
end

local function wallBoxes()
    local out = {}
    for _, ent in ipairs(authoritativeStaticBoxes()) do
        if IsValid(ent) and ent:GetClass() == "lod_static_box"
            and ent.GetBoxKind and ent:GetBoxKind() == 4
        then
            local pos = ent:GetPos()
            out[#out + 1] = {
                ent = ent,
                mins = pos + ent:GetBoxMins(),
                maxs = pos + ent:GetBoxMaxs()
            }
        end
    end
    return out
end

local function inside(point, box)
    return point.x >= box.mins.x and point.x <= box.maxs.x and
        point.y >= box.mins.y and point.y <= box.maxs.y and
        point.z >= box.mins.z and point.z <= box.maxs.z
end

local function blockingWall(point, walls)
    for _, box in ipairs(walls) do
        if inside(point, box) then return box.ent end
    end
    return nil
end

local function countStairBoxes()
    local n = 0
    for _, ent in ipairs(authoritativeStaticBoxes()) do
        if IsValid(ent) and ent:GetClass() == "lod_static_box"
            and ent.GetBoxKind and ent:GetBoxKind() == 2
        then
            n = n + 1
        end
    end
    return n
end

function Audit:Run(graph)
    local result = {valid = true, checked = 0, errors = {}}
    if not graph then
        result.valid = false
        result.errors[1] = "missing graph"
        return result
    end

    local walls = wallBoxes()
    local edges = graph.VerticalEdges or {}
    local expectedBoxes = #edges * math.max(1, GC.StairSteps or 24)
    local actualBoxes = countStairBoxes()
    result.verticalEdges = #edges
    result.expectedStairBoxes = expectedBoxes
    result.actualStairBoxes = actualBoxes

    if actualBoxes < expectedBoxes then
        result.errors[#result.errors + 1] = string.format(
            "stair collision boxes missing: expected>=%d actual=%d", expectedBoxes, actualBoxes)
    end

    for index, edge in ipairs(edges) do
        result.checked = result.checked + 1
        local lower, upper = lowerUpper(edge)
        local lowerKey = cellKey(lower.x, lower.y, lower.z)
        local upperKey = cellKey(upper.x, upper.y, upper.z)
        local direction = edge.LODStairDirection
        local entrySide = edge.LODStairEntrySide
        local d = DIR[direction or ""]

        if not d or not entrySide then
            result.errors[#result.errors + 1] = string.format(
                "stair #%d %s>%s has no graph-open authored approach", index, lowerKey, upperKey)
        else
            local lowerCenter = Builder:CellCenter(lower)
            -- The stair runs from lowerCenter - direction*StairRun to lowerCenter.
            -- Sample the centerline at chest height above the authored incline.
            -- We test only merged wall collision (kind 4), not the stair treads
            -- themselves, because the steps are intentionally walked upon.
            for sample = 0, 24 do
                local t = sample / 24
                local foot = lowerCenter - d * (GC.StairRun * (1 - t)) +
                    Vector(0, 0, MC.LevelHeight * t)
                local chest = foot + Vector(0, 0, 40)
                local blocker = blockingWall(chest, walls)
                if IsValid(blocker) then
                    result.errors[#result.errors + 1] = string.format(
                        "stair #%d %s>%s centerline blocked at %.0f%% by wall #%d",
                        index, lowerKey, upperKey, t * 100, blocker:EntIndex())
                    break
                end
            end
        end
    end

    result.valid = #result.errors == 0
    return result
end

local function printAudit(result)
    print(string.format(
        "[LOD:VERTICAL-AUDIT] valid=%s edges=%d checked=%d stairBoxes=%d/%d errors=%d",
        tostring(result.valid), result.verticalEdges or 0, result.checked or 0,
        result.actualStairBoxes or 0, result.expectedStairBoxes or 0, #(result.errors or {})))
    for i, err in ipairs(result.errors or {}) do
        if i > 30 then print("[LOD:VERTICAL-AUDIT] ... additional errors omitted") break end
        print("[LOD:VERTICAL-AUDIT] " .. err)
    end
end

if Builder and not Builder.LODVerticalTransitionAuditWrapped then
    Builder.LODVerticalTransitionAuditWrapped = true
    local baseBuild = Builder.Build
    function Builder:Build(graph)
        local ok, report = baseBuild(self, graph)
        if not ok then return false, report end
        local audit = Audit:Run(graph)
        report.verticalTransitionAudit = audit
        printAudit(audit)
        if not audit.valid then
            self:Cleanup()
            return false, "vertical transition audit failed: " .. table.concat(audit.errors or {}, "; ")
        end
        return true, report
    end
end

concommand.Add("lod_map_vertical_audit", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local state = LOD.RunManager and LOD.RunManager.State
    printAudit(Audit:Run(state and state.Graph))
end)

concommand.Add("lod_map_stair_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) then return end
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph then return end
    local current = Navigator:WorldToCell(graph, ply:GetPos())
    if not current then return end

    local bestUp, bestUpDist, reachableUp = nil, math.huge, 0
    local bestDown, bestDownDist, reachableDown = nil, math.huge, 0
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        local lower, upper = lowerUpper(edge)
        if lower.z == current.z then
            local path = Navigator:FindPath(graph, current, graph.Cells[cellKey(lower.x, lower.y, lower.z)])
            if path then
                reachableUp = reachableUp + 1
                local dist = #path - 1
                if dist < bestUpDist then bestUp, bestUpDist = lower, dist end
            end
        end
        if upper.z == current.z then
            local path = Navigator:FindPath(graph, current, graph.Cells[cellKey(upper.x, upper.y, upper.z)])
            if path then
                reachableDown = reachableDown + 1
                local dist = #path - 1
                if dist < bestDownDist then bestDown, bestDownDist = upper, dist end
            end
        end
    end

    local function ctext(c)
        return c and string.format("(%d,%d,%d)", c.x, c.y, c.z) or "none"
    end
    local text = string.format(
        "cell=(%d,%d,%d) reachableUp=%d nearestUp=%s dist=%s reachableDown=%d nearestDown=%s dist=%s objectiveStage=%s",
        current.x, current.y, current.z, reachableUp, ctext(bestUp),
        bestUp and tostring(bestUpDist) or "inf", reachableDown, ctext(bestDown),
        bestDown and tostring(bestDownDist) or "inf", tostring(state.ObjectiveStage or "?"))
    print("[LOD:STAIR-STATUS] " .. text)
    ply:ChatPrint(text)
end)
