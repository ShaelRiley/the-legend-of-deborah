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
    ent:SetBoxKind(5) -- thin horizontal under-wall shadow plate
    ent:Spawn()
    ent:Activate()

    if ent.IsLODCollisionReady and not ent:IsLODCollisionReady() then
        ent:Remove()
        return nil
    end
    return ent
end

local function isClosedHorizontalEdge(graph, hereKey, neighborKey)
    if not graph.Cells[neighborKey] then return true end
    return not (graph.Edges and graph.Edges[edgeKey(hereKey, neighborKey)])
end

-- The earlier fix filled the full 16-unit gap between gm_flatgrass and the deck
-- with vertical boxes. That hid green, but the exposed ends of those boxes looked
-- like rusty concrete/metal risers beneath individual containers. Do not fabricate
-- vertical foundations. Instead lay a very thin dark metal underlay directly over
-- the world surface beneath every closed level-0 wall footprint. Combined with the
-- slightly embedded container visuals, any remaining model-base notch now reveals
-- only a recessed shadow plate rather than Flatgrass or a visible pedestal.
function MazeBuilder:_BuildGroundPerimeterSeals(graph)
    local worldFloorZ = self.WorldFloorZ
    if not worldFloorZ then return end

    local seen = {}
    local halfCell = MC.CellSize * 0.5
    local halfDepth = GC.ContainerWidth * 0.5 + 8
    local endOverlap = 10
    local plateThickness = 2
    local plateCenterZ = worldFloorZ + plateThickness * 0.5 + 0.25
    local halfPlate = plateThickness * 0.5

    for _, cell in pairs(graph.Cells or {}) do
        if cell.z == 0 then
            local center = self:CellCenter(cell)
            local hereKey = cellKey(cell.x, cell.y, 0)

            for _, d in ipairs(DIRS) do
                local neighborKey = cellKey(cell.x + d.dx, cell.y + d.dy, 0)
                local key = edgeKey(hereKey, neighborKey)

                if not seen[key] and isClosedHorizontalEdge(graph, hereKey, neighborKey) then
                    seen[key] = true

                    local edgeCenter = Vector(
                        center.x + d.dx * halfCell,
                        center.y + d.dy * halfCell,
                        plateCenterZ
                    )
                    local mins
                    local maxs

                    -- Slight footprint overlap covers the recessed corner feet of
                    -- intersecting container models without extending into open
                    -- corridor edges; this plate is far below the authored deck.
                    if d.name == "N" or d.name == "S" then
                        mins = Vector(-halfCell - endOverlap, -halfDepth, -halfPlate)
                        maxs = Vector(halfCell + endOverlap, halfDepth, halfPlate)
                    else
                        mins = Vector(-halfDepth, -halfCell - endOverlap, -halfPlate)
                        maxs = Vector(halfDepth, halfCell + endOverlap, halfPlate)
                    end

                    self:_Register(spawnSealBox(edgeCenter, mins, maxs))
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
