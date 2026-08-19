LOD = LOD or {}
LOD.MazeGeometryAudit = LOD.MazeGeometryAudit or {}

local Audit = LOD.MazeGeometryAudit
local Builder = LOD.MazeBuilder
local MC = LOD.Config.Maze
local cellKey = LOD.MazeGenerator.CellKey

local function edgeKey(a, b)
    if a < b then return a .. "|" .. b end
    return b .. "|" .. a
end

local function wallBounds()
    local out = {}
    for _, ent in ipairs(ents.FindByClass("lod_static_box")) do
        if IsValid(ent) and ent.GetBoxKind and ent:GetBoxKind() == 4 then
            local mins = ent:GetBoxMins()
            local maxs = ent:GetBoxMaxs()
            local pos = ent:GetPos()
            out[#out + 1] = {
                ent = ent,
                mins = pos + mins,
                maxs = pos + maxs
            }
        end
    end
    return out
end

local function pointInside(point, box, epsilon)
    epsilon = epsilon or 0.5
    return point.x >= box.mins.x - epsilon and point.x <= box.maxs.x + epsilon and
        point.y >= box.mins.y - epsilon and point.y <= box.maxs.y + epsilon and
        point.z >= box.mins.z - epsilon and point.z <= box.maxs.z + epsilon
end

local function wallAt(point, walls)
    for _, box in ipairs(walls) do
        if pointInside(point, box) then return box.ent end
    end
    return nil
end

local function visualAt(point)
    local best
    local bestDist = math.huge
    for _, ent in ipairs(ents.FindByClass("lod_container_visual")) do
        if IsValid(ent) then
            local p = ent:GetPos()
            local dx = p.x - point.x
            local dy = p.y - point.y
            local d2 = dx * dx + dy * dy
            if d2 < bestDist then
                bestDist = d2
                best = ent
            end
        end
    end
    -- Wall visuals are authored exactly on logical edge centers. A very small
    -- tolerance catches an actual segment at this boundary without confusing a
    -- perpendicular wall whose center is one half-cell away.
    if best and bestDist <= 4 * 4 then return best end
    return nil
end

local function gateIndexByEdge(graph)
    local out = {}
    for i, gate in ipairs(graph.Progression and graph.Progression.Gates or {}) do
        if gate.edgeKey then out[gate.edgeKey] = i end
    end
    return out
end

function Audit:Run(graph)
    local result = {
        valid = true,
        checked = 0,
        collisionMismatches = {},
        visualMismatches = {}
    }
    if not graph or not graph.Cells then
        result.valid = false
        result.collisionMismatches[1] = "missing graph/cells"
        return result
    end

    local walls = wallBounds()
    local gates = gateIndexByEdge(graph)
    local dirs = {
        {dx = 1, dy = 0},
        {dx = 0, dy = 1}
    }

    for key, cell in pairs(graph.Cells) do
        for _, d in ipairs(dirs) do
            local neighborKey = cellKey(cell.x + d.dx, cell.y + d.dy, cell.z)
            local neighbor = graph.Cells[neighborKey]
            if neighbor then
                local ek = edgeKey(key, neighborKey)
                local open = graph.Edges and graph.Edges[ek] ~= nil
                local a = Builder:CellCenter(cell)
                local b = Builder:CellCenter(neighbor)
                local boundary = (a + b) * 0.5 + Vector(0, 0, 64)
                local blocker = wallAt(boundary, walls)
                local visual = visualAt(boundary)
                result.checked = result.checked + 1

                if open and IsValid(blocker) then
                    result.collisionMismatches[#result.collisionMismatches + 1] =
                        string.format("OPEN edge %s blocked by wall #%d", ek, blocker:EntIndex())
                elseif not open and not IsValid(blocker) then
                    result.collisionMismatches[#result.collisionMismatches + 1] =
                        string.format("CLOSED edge %s has no wall blocker", ek)
                end

                if open and IsValid(visual) then
                    result.visualMismatches[#result.visualMismatches + 1] =
                        string.format("OPEN edge %s has container visual #%d", ek, visual:EntIndex())
                elseif not open and not IsValid(visual) then
                    result.visualMismatches[#result.visualMismatches + 1] =
                        string.format("CLOSED edge %s has no container visual", ek)
                end

                -- Gate edges are canonical open graph edges and intentionally
                -- have no static wall. Their temporary lod_gate collision is not
                -- part of this wall audit.
                if gates[ek] and not open then
                    result.collisionMismatches[#result.collisionMismatches + 1] =
                        string.format("GATE %d edge %s is not canonical-open", gates[ek], ek)
                end
            end
        end
    end

    result.valid = #result.collisionMismatches == 0 and #result.visualMismatches == 0
    result.wallBoxes = #walls
    return result
end

local function printAudit(result)
    print(string.format(
        "[LOD:GEOMETRY-AUDIT] valid=%s checked=%d wallBoxes=%d collisionMismatch=%d visualMismatch=%d",
        tostring(result.valid), result.checked or 0, result.wallBoxes or 0,
        #(result.collisionMismatches or {}), #(result.visualMismatches or {})
    ))
    local shown = 0
    for _, err in ipairs(result.collisionMismatches or {}) do
        shown = shown + 1
        if shown > 30 then break end
        print("[LOD:GEOMETRY-AUDIT] " .. err)
    end
    for _, err in ipairs(result.visualMismatches or {}) do
        shown = shown + 1
        if shown > 30 then break end
        print("[LOD:GEOMETRY-AUDIT] " .. err)
    end
    if shown > 30 then print("[LOD:GEOMETRY-AUDIT] ... additional mismatches omitted") end
end

if Builder and not Builder.LODGeometryAuditWrapped then
    Builder.LODGeometryAuditWrapped = true
    local baseBuild = Builder.Build
    function Builder:Build(graph)
        local ok, report = baseBuild(self, graph)
        if not ok then return false, report end

        local audit = Audit:Run(graph)
        report.geometryAudit = audit
        printAudit(audit)
        if not audit.valid then
            self:Cleanup()
            return false, string.format(
                "graph/physical maze mismatch: collision=%d visual=%d",
                #(audit.collisionMismatches or {}), #(audit.visualMismatches or {})
            )
        end
        return true, report
    end
end

concommand.Add("lod_map_geometry_audit", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local state = LOD.RunManager and LOD.RunManager.State
    local result = Audit:Run(state and state.Graph)
    printAudit(result)
end)

concommand.Add("lod_map_edge_audit", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) then return end

    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    if not graph then return end
    local cell = LOD.MazeNavigator:WorldToCell(graph, ply:GetPos())
    if not cell then return end

    local forward = Angle(0, ply:EyeAngles().y, 0):Forward()
    local dx, dy, dir
    if math.abs(forward.x) >= math.abs(forward.y) then
        dx = forward.x >= 0 and 1 or -1
        dy = 0
        dir = dx > 0 and "E" or "W"
    else
        dx = 0
        dy = forward.y >= 0 and 1 or -1
        dir = dy > 0 and "N" or "S"
    end

    local aKey = cellKey(cell.x, cell.y, cell.z)
    local bKey = cellKey(cell.x + dx, cell.y + dy, cell.z)
    local neighbor = graph.Cells[bKey]
    local ek = edgeKey(aKey, bKey)
    local open = neighbor and graph.Edges and graph.Edges[ek] ~= nil or false
    local boundary = Builder:CellCenter(cell) + Vector(dx * MC.CellSize * 0.5, dy * MC.CellSize * 0.5, 64)
    local blocker = wallAt(boundary, wallBounds())
    local visual = visualAt(boundary)
    local gate = gateIndexByEdge(graph)[ek]

    print(string.format(
        "[LOD:EDGE-AUDIT] cell=%s facing=%s neighbor=%s canonicalOpen=%s gate=%s wall=%s visual=%s",
        aKey, dir, tostring(neighbor ~= nil), tostring(open), tostring(gate or "none"),
        IsValid(blocker) and ("#" .. blocker:EntIndex()) or "none",
        IsValid(visual) and ("#" .. visual:EntIndex()) or "none"
    ))
end)
