LOD = LOD or {}
LOD.MazeBuilder = LOD.MazeBuilder or {}

local MazeBuilder = LOD.MazeBuilder
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local cellKey = LOD.MazeGenerator.CellKey

local DIRS = {
    {name = "N", dx = 0, dy = 1},
    {name = "E", dx = 1, dy = 0},
    {name = "S", dx = 0, dy = -1},
    {name = "W", dx = -1, dy = 0}
}

local function edgeKey(a, b)
    if a < b then return a .. "|" .. b end
    return b .. "|" .. a
end

local function spawnSealBox(pos, mins, maxs)
    local ent = ents.Create("lod_static_box")
    if not IsValid(ent) then return nil end

    ent:SetPos(pos)
    ent:SetAngles(angle_zero)
    ent:SetBoxMins(mins)
    ent:SetBoxMaxs(maxs)
    ent:SetBoxKind(5) -- visible under-container seal / ground-wall plinth
    ent:Spawn()
    ent:Activate()

    if ent.IsLODCollisionReady and not ent:IsLODCollisionReady() then
        ent:Remove()
        return nil
    end
    return ent
end

local function isClosedHorizontalEdge(graph, hereKey, neighborKey)
    -- Match the wall builder's canonical authority exactly: if this undirected
    -- same-floor edge is absent from graph.Edges, a cargo-container wall occupies
    -- the boundary. This includes BOTH exterior perimeter walls and internal maze
    -- walls between two otherwise occupied cells. The previous implementation
    -- sealed only missing-neighbor perimeter edges, which left Flatgrass visible
    -- below internal closed walls at corners and long corridor boundaries.
    if not graph.Cells[neighborKey] then return true end
    return not (graph.Edges and graph.Edges[edgeKey(hereKey, neighborKey)])
end

-- Level 0 sits slightly above gm_flatgrass so the generated steel deck can own
-- authoritative collision. Cargo-container models have a small visual undercut at
-- their base; without a plinth, the bright green map surface can peek through that
-- undercut. Seal EVERY level-0 boundary that actually owns a container wall, but
-- never open graph edges. The seal lives entirely inside the wall footprint and
-- terminates flush with the deck plane, so it cannot reintroduce false floor
-- topography or obstruct a legitimate corridor/gate opening.
function MazeBuilder:_BuildGroundPerimeterSeals(graph)
    local worldFloorZ = self.WorldFloorZ
    if not worldFloorZ then return end

    local seen = {}
    local halfCell = MC.CellSize * 0.5
    local halfDepth = GC.ContainerWidth * 0.5 + 4
    local endOverlap = 6

    for _, cell in pairs(graph.Cells or {}) do
        if cell.z == 0 then
            local center = self:CellCenter(cell)
            local sealHeight = center.z - worldFloorZ

            if sealHeight > 0.5 then
                local halfHeight = sealHeight * 0.5
                local hereKey = cellKey(cell.x, cell.y, 0)

                for _, d in ipairs(DIRS) do
                    local neighborKey = cellKey(cell.x + d.dx, cell.y + d.dy, 0)
                    local key = edgeKey(hereKey, neighborKey)

                    if not seen[key] and isClosedHorizontalEdge(graph, hereKey, neighborKey) then
                        seen[key] = true

                        local edgeCenter = center + Vector(
                            d.dx * halfCell,
                            d.dy * halfCell,
                            -halfHeight
                        )
                        local mins
                        local maxs

                        -- Deliberate overlap in both wall depth and segment length
                        -- closes model-base notches and perpendicular corner seams.
                        if d.name == "N" or d.name == "S" then
                            mins = Vector(-halfCell - endOverlap, -halfDepth, -halfHeight)
                            maxs = Vector(halfCell + endOverlap, halfDepth, halfHeight)
                        else
                            mins = Vector(-halfDepth, -halfCell - endOverlap, -halfHeight)
                            maxs = Vector(halfDepth, halfCell + endOverlap, halfHeight)
                        end

                        self:_Register(spawnSealBox(edgeCenter, mins, maxs))
                    end
                end
            end
        end
    end
end

local previousBuildWalls = MazeBuilder._BuildWalls
function MazeBuilder:_BuildWalls(graph)
    previousBuildWalls(self, graph)
    if (self.BuildFailures or 0) > 0 then return end
    self:_BuildGroundPerimeterSeals(graph)
end
