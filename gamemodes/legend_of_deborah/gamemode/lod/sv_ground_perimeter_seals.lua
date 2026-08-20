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
    ent:SetBoxKind(5) -- visible ground-perimeter skirt / under-container seal
    ent:Spawn()
    ent:Activate()

    if ent.IsLODCollisionReady and not ent:IsLODCollisionReady() then
        ent:Remove()
        return nil
    end
    return ent
end

-- The authored level-0 walkable plane intentionally sits slightly above the
-- gm_flatgrass world surface. At the outer boundary of the generated labyrinth,
-- cargo-container wall models therefore leave a narrow sightline to green map
-- grass underneath their outward half. Seal only edges whose neighboring logical
-- cell does not exist. Internal coplanar floor seams stay completely untouched,
-- preserving the newly-flat continuous deck presentation.
function MazeBuilder:_BuildGroundPerimeterSeals(graph)
    local worldFloorZ = self.WorldFloorZ
    if not worldFloorZ then return end

    local seen = {}
    local halfCell = MC.CellSize * 0.5
    local halfDepth = GC.ContainerWidth * 0.5 + 2

    for _, cell in pairs(graph.Cells or {}) do
        if cell.z == 0 then
            local center = self:CellCenter(cell)
            local sealHeight = center.z - worldFloorZ

            if sealHeight > 0.5 then
                local halfHeight = sealHeight * 0.5

                for _, d in ipairs(DIRS) do
                    local neighborKey = cellKey(cell.x + d.dx, cell.y + d.dy, 0)
                    if not graph.Cells[neighborKey] then
                        local hereKey = cellKey(cell.x, cell.y, 0)
                        local key = edgeKey(hereKey, neighborKey)

                        if not seen[key] then
                            seen[key] = true

                            local edgeCenter = center + Vector(d.dx * halfCell, d.dy * halfCell, -halfHeight)
                            local mins
                            local maxs

                            -- Extend two units past each corner so perpendicular
                            -- perimeter skirts overlap instead of revealing a
                            -- hairline of Flatgrass at convex/concave corners.
                            if d.name == "N" or d.name == "S" then
                                mins = Vector(-halfCell - 2, -halfDepth, -halfHeight)
                                maxs = Vector(halfCell + 2, halfDepth, halfHeight)
                            else
                                mins = Vector(-halfDepth, -halfCell - 2, -halfHeight)
                                maxs = Vector(halfDepth, halfCell + 2, halfHeight)
                            end

                            self:_Register(spawnSealBox(edgeCenter, mins, maxs))
                        end
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
