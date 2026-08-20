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
    ent:SetBoxKind(5) -- same-height exterior deck apron beneath container walls
    ent:Spawn()
    ent:Activate()

    if ent.IsLODCollisionReady and not ent:IsLODCollisionReady() then
        ent:Remove()
        return nil
    end
    return ent
end

-- Ground-floor cells already own a substantial steel slab whose top is exactly
-- CellCenter.z. At an exterior boundary the slab stops on the logical cell edge,
-- while the centered cargo-container model extends roughly half its width beyond
-- that edge. From shallow interior angles, the model's recessed lower rail can
-- therefore expose gm_flatgrass beyond the slab even when the container itself is
-- visually embedded into the deck.
--
-- Solve the topology rather than sinking the wall ever farther: extend the SAME
-- deck plane beneath the complete footprint of exterior container walls. These
-- aprons have the same top Z and thickness as the ordinary floor, render only top
-- and underside faces, and overlap the existing floor invisibly. Internal closed
-- walls need no apron because occupied cells already provide deck on both sides.
-- Open graph edges are never touched.
function MazeBuilder:_BuildGroundPerimeterSeals(graph)
    local seen = {}
    local halfCell = MC.CellSize * 0.5
    local halfDepth = GC.ContainerWidth * 0.5 + 12
    local endOverlap = 12
    local thickness = GC.FloorThickness or 32
    local halfThickness = thickness * 0.5

    for _, cell in pairs(graph.Cells or {}) do
        if cell.z == 0 then
            local center = self:CellCenter(cell)
            local hereKey = cellKey(cell.x, cell.y, 0)

            for _, d in ipairs(DIRS) do
                local neighborKey = cellKey(cell.x + d.dx, cell.y + d.dy, 0)
                local key = edgeKey(hereKey, neighborKey)

                -- Only a missing neighboring logical cell exposes the outside of
                -- the generated ground deck. If a neighbor exists, its own floor
                -- already extends beneath any internal closed wall on that edge.
                if not seen[key] and not graph.Cells[neighborKey] then
                    seen[key] = true

                    local edgeCenter = center + Vector(
                        d.dx * halfCell,
                        d.dy * halfCell,
                        -halfThickness
                    )
                    local mins
                    local maxs

                    -- Symmetric overlap beneath the wall footprint is intentional:
                    -- the inward half disappears into the existing floor while the
                    -- outward half replaces every possible Flatgrass sightline.
                    -- Extra end overlap closes perpendicular corner seams.
                    if d.name == "N" or d.name == "S" then
                        mins = Vector(-halfCell - endOverlap, -halfDepth, -halfThickness)
                        maxs = Vector(halfCell + endOverlap, halfDepth, halfThickness)
                    else
                        mins = Vector(-halfDepth, -halfCell - endOverlap, -halfThickness)
                        maxs = Vector(halfDepth, halfCell + endOverlap, halfThickness)
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
