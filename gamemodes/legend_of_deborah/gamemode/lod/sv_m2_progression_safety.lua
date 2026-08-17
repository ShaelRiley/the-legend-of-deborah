LOD = LOD or {}

local ProgressionDirector = LOD.ProgressionDirector
local cellKey = LOD.MazeGenerator.CellKey
local PC = LOD.Config.Progression
local previousPlan = ProgressionDirector.Plan

local function transitionCells(graph)
    local set = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        set[cellKey(edge.a.x, edge.a.y, edge.a.z)] = true
        set[cellKey(edge.b.x, edge.b.y, edge.b.z)] = true
    end
    return set
end

local function taxicabDistance(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
end

-- Gate checkpoints must be flat, safe cells immediately beyond their gates.
-- Keycards must also remain physically separated from their own locks even when
-- the graph route to the card is long. Reject an otherwise-solvable layout and
-- let RunManager deterministically try the next layout seed.
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

    local minSeparation = PC.KeycardGateCellSeparationMin or 3
    for i, card in ipairs(result.Keycards or {}) do
        local gate = result.Gates and result.Gates[i]
        if gate and card.cell then
            local separation = math.min(
                taxicabDistance(card.cell, gate.beforeCell),
                taxicabDistance(card.cell, gate.afterCell)
            )
            card.gateCellSeparation = separation
            if separation < minSeparation then
                graph.Progression = nil
                return false, string.format(
                    "%s keycard is only %d logical cells from its gate; minimum is %d",
                    tostring(card.id), separation, minSeparation
                )
            end
        end
    end

    return true, result
end
