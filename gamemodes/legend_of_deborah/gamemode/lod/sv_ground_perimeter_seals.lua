LOD = LOD or {}
LOD.MazeBuilder = LOD.MazeBuilder or {}

local MazeBuilder = LOD.MazeBuilder
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry

local function spawnUnderdeck(pos, mins, maxs)
    local ent = ents.Create("lod_static_box")
    if not IsValid(ent) then return nil end

    ent:SetPos(pos)
    ent:SetAngles(angle_zero)
    ent:SetBoxMins(mins)
    ent:SetBoxMaxs(maxs)
    ent:SetBoxKind(5) -- continuous level-0 visual underdeck
    ent:Spawn()
    ent:Activate()

    if ent.IsLODCollisionReady and not ent:IsLODCollisionReady() then
        ent:Remove()
        return nil
    end
    return ent
end

-- Level 0 is intentionally raised above gm_flatgrass so the generated steel deck
-- owns the labyrinth's visual/collision language. The cargo-container model has
-- recessed lower rails and feet, however, and the procedural ground layer contains
-- unoccupied logical cells outside the walkable graph. Even carefully fitted edge
-- aprons can therefore leave occasional oblique sightlines to the map surface.
--
-- Use one continuous, slightly recessed industrial-steel underdeck beneath the
-- ENTIRE generation footprint instead of chasing individual seams. Occupied maze
-- cells retain their authored deck exactly at CellCenter.z and visually cover this
-- blanket. Where a container base, exterior corner, or unoccupied cell would have
-- exposed Flatgrass, the only thing behind it is now matching steel 0.5 units below
-- the primary deck plane. The blanket extends beyond the nominal grid far enough to
-- cover the complete footprint of perimeter container walls.
--
-- This does not alter the canonical graph, wall collision, navigation, or Motion V2.
-- Ground-level voids were already physically supported by gm_flatgrass; replacing
-- that visible map surface with generated steel introduces no new practical route.
function MazeBuilder:_BuildGroundPerimeterSeals(graph)
    local thickness = 2
    local halfThickness = thickness * 0.5
    local topInset = 0.5
    local apron = GC.ContainerWidth * 0.5 + 32
    local halfX = MC.Width * MC.CellSize * 0.5 + apron
    local halfY = MC.Height * MC.CellSize * 0.5 + apron
    local deckTopZ = MC.Origin.z
    local center = Vector(MC.Origin.x, MC.Origin.y, deckTopZ - topInset - halfThickness)

    self:_Register(spawnUnderdeck(
        center,
        Vector(-halfX, -halfY, -halfThickness),
        Vector(halfX, halfY, halfThickness)
    ))
end

local previousBuildWalls = MazeBuilder._BuildWalls
function MazeBuilder:_BuildWalls(graph)
    previousBuildWalls(self, graph)
    if (self.BuildFailures or 0) > 0 then return end
    self:_BuildGroundPerimeterSeals(graph)
end
