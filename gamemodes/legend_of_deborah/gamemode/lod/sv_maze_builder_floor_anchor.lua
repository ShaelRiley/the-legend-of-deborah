LOD = LOD or {}
LOD.MazeBuilder = LOD.MazeBuilder or {}

local MazeBuilder = LOD.MazeBuilder
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local cellKey = LOD.MazeGenerator.CellKey

local function upperTransitionMap(graph)
    local transitions = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        local upper = edge.a.z > edge.b.z and edge.a or edge.b
        transitions[cellKey(upper.x, upper.y, upper.z)] = edge
    end
    return transitions
end

-- Resolve the logical Level-0 plane against gm_flatgrass world geometry rather
-- than assuming that world Z=0 is the grass surface. Generated entities are
-- excluded by the brush-only mask, so regeneration cannot anchor to the old maze.
function MazeBuilder:_ResolveWorldFloor()
    local probeX = MC.Origin.x
    local probeY = MC.Origin.y
    local tr = util.TraceLine({
        start = Vector(probeX, probeY, 1024),
        endpos = Vector(probeX, probeY, -4096),
        mask = MASK_SOLID_BRUSHONLY
    })

    if not tr.Hit then
        return false, "could not locate gm_flatgrass world floor beneath maze origin"
    end

    local offset = GC.GroundFloorOffset or 2
    self.WorldFloorZ = tr.HitPos.z
    MC.Origin = Vector(probeX, probeY, tr.HitPos.z + offset)
    return true
end

-- Build explicit floor collision on Level 0 as well as elevated layers. The
-- world brush remains beneath the maze, but gameplay no longer depends on its
-- exact elevation or on every occupied logical cell coinciding with map ground.
function MazeBuilder:_BuildFloors(graph)
    local transitions = upperTransitionMap(graph)

    for z = 0, graph.Layers - 1 do
        for y = 1, MC.Height do
            local x = 1
            while x <= MC.Width do
                local k = cellKey(x, y, z)
                local cell = graph.Cells[k]
                local transition = transitions[k]

                if transition then
                    self:_BuildPerforatedFloor(cell, transition)
                    x = x + 1
                elseif cell then
                    local runEnd = x
                    while runEnd + 1 <= MC.Width do
                        local nextKey = cellKey(runEnd + 1, y, z)
                        if not graph.Cells[nextKey] or transitions[nextKey] then break end
                        runEnd = runEnd + 1
                    end
                    self:_BuildFloorRun(cell, graph.Cells[cellKey(runEnd, y, z)])
                    x = runEnd + 1
                else
                    x = x + 1
                end
            end
        end
    end
end

local previousBuild = MazeBuilder.Build
function MazeBuilder:Build(graph)
    local floorOK, floorErr = self:_ResolveWorldFloor()
    if not floorOK then
        self:Cleanup()
        return false, floorErr
    end

    local ok, report = previousBuild(self, graph)
    if not ok then return false, report end

    report.worldFloorZ = self.WorldFloorZ
    report.mazeOriginZ = MC.Origin.z
    report.groundFloorOffset = GC.GroundFloorOffset or 2
    return true, report
end
