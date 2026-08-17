LOD = LOD or {}

local ProgressionDirector = LOD.ProgressionDirector
local cellKey = LOD.MazeGenerator.CellKey
local previousPlan = ProgressionDirector.Plan

local function transitionCells(graph)
    local set = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        set[cellKey(edge.a.x, edge.a.y, edge.a.z)] = true
        set[cellKey(edge.b.x, edge.b.y, edge.b.z)] = true
    end
    return set
end

-- Gate checkpoints must be flat, safe cells immediately beyond their gates.
-- Reject an otherwise-solvable layout if either side of a selected gate is also
-- a vertical-transition cell; RunManager deterministically tries the next layout seed.
function ProgressionDirector:Plan(graph, masterLevelSeed)
    local ok, result = previousPlan(self, graph, masterLevelSeed)
    if not ok then return false, result end

    local transitions = transitionCells(graph)
    for _, gate in ipairs(result.Gates or {}) do
        local beforeKey = cellKey(gate.beforeCell.x, gate.beforeCell.y, gate.beforeCell.z)
        local afterKey = cellKey(gate.afterCell.x, gate.afterCell.y, gate.afterCell.z)
        if transitions[beforeKey] or transitions[afterKey] then
            graph.Progression = nil
            return false, string.format("%s gate checkpoint intersects a vertical-transition cell", tostring(gate.id))
        end
    end

    return true, result
end
