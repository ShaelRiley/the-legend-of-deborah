LOD = LOD or {}
LOD.GraphIntegrity = LOD.GraphIntegrity or {}

local Integrity = LOD.GraphIntegrity
local Generator = LOD.MazeGenerator
local cellKey = Generator.CellKey

local function edgeKey(a, b)
    if a < b then return a .. "|" .. b end
    return b .. "|" .. a
end

function Integrity:Audit(graph)
    local errors = {}
    if not graph or not graph.Cells then
        return {valid = false, errors = {"missing graph/cells"}, checkedRelations = 0}
    end

    local checked = 0
    for key, cell in pairs(graph.Cells) do
        for neighborKey in pairs(cell.neighbors or {}) do
            checked = checked + 1
            local neighbor = graph.Cells[neighborKey]
            if not neighbor then
                errors[#errors + 1] = key .. " references missing neighbor " .. tostring(neighborKey)
            else
                local manhattan = math.abs(cell.x - neighbor.x) + math.abs(cell.y - neighbor.y) + math.abs(cell.z - neighbor.z)
                if manhattan ~= 1 then
                    errors[#errors + 1] = key .. " has non-adjacent neighbor " .. neighborKey
                end
                if not neighbor.neighbors or neighbor.neighbors[key] ~= true then
                    errors[#errors + 1] = "asymmetric neighbor relation " .. key .. " -> " .. neighborKey
                end
                if not graph.Edges or not graph.Edges[edgeKey(key, neighborKey)] then
                    errors[#errors + 1] = "neighbor relation missing canonical graph.Edges entry " .. key .. " <-> " .. neighborKey
                end
            end
        end
    end

    for ek, edge in pairs(graph.Edges or {}) do
        local aKey = edge and edge.a and cellKey(edge.a.x, edge.a.y, edge.a.z)
        local bKey = edge and edge.b and cellKey(edge.b.x, edge.b.y, edge.b.z)
        local a = aKey and graph.Cells[aKey]
        local b = bKey and graph.Cells[bKey]
        if not a or not b then
            errors[#errors + 1] = "canonical edge " .. tostring(ek) .. " references missing cell"
        elseif not a.neighbors or not b.neighbors or a.neighbors[bKey] ~= true or b.neighbors[aKey] ~= true then
            errors[#errors + 1] = "canonical edge lacks reciprocal neighbor relation " .. tostring(ek)
        end
    end

    return {
        valid = #errors == 0,
        errors = errors,
        checkedRelations = checked
    }
end

if Generator and not Generator.LODGraphIntegrityWrapped then
    Generator.LODGraphIntegrityWrapped = true
    local baseValidate = Generator.Validate

    function Generator:Validate(graph)
        local valid, report = baseValidate(self, graph)
        local audit = Integrity:Audit(graph)
        graph.Validation = graph.Validation or report or {}
        graph.Validation.graphIntegrity = audit
        if not audit.valid then
            graph.Validation.valid = false
            graph.Validation.errors = graph.Validation.errors or {}
            for _, err in ipairs(audit.errors) do
                graph.Validation.errors[#graph.Validation.errors + 1] = "graph integrity: " .. err
            end
            return false, graph.Validation
        end
        return valid, graph.Validation
    end
end

concommand.Add("lod_graph_integrity", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    local audit = Integrity:Audit(graph)
    print(string.format("[LOD:GRAPH-INTEGRITY] valid=%s relations=%d errors=%d", tostring(audit.valid), audit.checkedRelations or 0, #(audit.errors or {})))
    for i, err in ipairs(audit.errors or {}) do
        if i > 20 then
            print("[LOD:GRAPH-INTEGRITY] ... additional errors omitted")
            break
        end
        print("[LOD:GRAPH-INTEGRITY] " .. err)
    end
end)
