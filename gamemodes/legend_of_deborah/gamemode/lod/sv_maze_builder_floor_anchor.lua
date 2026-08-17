LOD = LOD or {}
LOD.MazeBuilder = LOD.MazeBuilder or {}

local MazeBuilder = LOD.MazeBuilder
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local cellKey = LOD.MazeGenerator.CellKey

local SPAWN_CLASSES = {
    "info_player_start",
    "info_player_deathmatch",
    "info_player_rebel",
    "info_player_combine"
}

local function upperTransitionMap(graph)
    local transitions = {}
    for _, edge in ipairs(graph.VerticalEdges or {}) do
        local upper = edge.a.z > edge.b.z and edge.a or edge.b
        transitions[cellKey(upper.x, upper.y, upper.z)] = edge
    end
    return transitions
end

local function sortedSpawnPositions()
    local positions = {}
    for _, className in ipairs(SPAWN_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            if IsValid(ent) then
                positions[#positions + 1] = ent:GetPos()
            end
        end
    end

    table.sort(positions, function(a, b)
        if a.z ~= b.z then return a.z < b.z end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    return positions
end

local function traceWorldAt(pos)
    return util.TraceLine({
        start = pos + Vector(0, 0, 1024),
        endpos = pos - Vector(0, 0, 4096),
        mask = MASK_SOLID
    })
end

-- Level 0 owns explicit collision, so world-floor discovery is a placement aid,
-- not a prerequisite for correctness. Prefer a real world hit; if the maze's
-- configured X/Y lies outside traceable map ground, derive Z from map spawnpoints.
-- A final fixed Z fallback keeps gm_flatgrass startup fail-safe rather than
-- refusing to construct an otherwise self-supported maze.
function MazeBuilder:_ResolveWorldFloor()
    self:Cleanup()

    local probeX = MC.Origin.x
    local probeY = MC.Origin.y
    local floorZ
    local source

    local originTrace = traceWorldAt(Vector(probeX, probeY, 0))
    if originTrace.Hit and originTrace.HitWorld then
        floorZ = originTrace.HitPos.z
        source = "maze-origin-world-trace"
    end

    local spawnPositions = sortedSpawnPositions()
    if floorZ == nil then
        for _, spawnPos in ipairs(spawnPositions) do
            local tr = traceWorldAt(spawnPos)
            if tr.Hit and tr.HitWorld then
                floorZ = tr.HitPos.z
                source = "map-spawn-world-trace"
                break
            end
        end
    end

    if floorZ == nil and #spawnPositions > 0 then
        local median = spawnPositions[math.ceil(#spawnPositions * 0.5)]
        floorZ = median.z
        source = "map-spawn-z-fallback"
    end

    if floorZ == nil then
        floorZ = GC.FallbackFloorZ or 0
        source = "explicit-gm_flatgrass-fallback"
    end

    local offset = GC.GroundFloorOffset or 2
    self.WorldFloorZ = floorZ
    self.FloorAnchorSource = source
    MC.Origin = Vector(probeX, probeY, floorZ + offset)

    print(string.format(
        "[LOD] Level-0 anchor source=%s floorZ=%.2f originZ=%.2f spawnpoints=%d",
        source, floorZ, MC.Origin.z, #spawnPositions
    ))
    return true
end

-- Level 0 remains row-merged for efficiency. Elevated layers deliberately use
-- one floor entity per occupied logical cell. Their origins therefore stay local
-- to the visible corridor/platform they represent, eliminating the long-entity
-- visibility ambiguity that repeatedly made solid upper floors appear absent.
function MazeBuilder:_BuildFloors(graph)
    local transitions = upperTransitionMap(graph)

    -- Ground layer: merge deterministic contiguous row runs.
    for y = 1, MC.Height do
        local x = 1
        while x <= MC.Width do
            local k = cellKey(x, y, 0)
            local cell = graph.Cells[k]
            if cell then
                local runEnd = x
                while runEnd + 1 <= MC.Width do
                    local nextKey = cellKey(runEnd + 1, y, 0)
                    if not graph.Cells[nextKey] then break end
                    runEnd = runEnd + 1
                end
                self:_BuildFloorRun(cell, graph.Cells[cellKey(runEnd, y, 0)])
                x = runEnd + 1
            else
                x = x + 1
            end
        end
    end

    -- Elevated layers: explicit cell-local floors. Transition cells retain their
    -- authored stair aperture; every other occupied cell gets a complete slab.
    for z = 1, graph.Layers - 1 do
        for y = 1, MC.Height do
            for x = 1, MC.Width do
                local k = cellKey(x, y, z)
                local cell = graph.Cells[k]
                if cell then
                    local transition = transitions[k]
                    if transition then
                        self:_BuildPerforatedFloor(cell, transition)
                    else
                        self:_BuildFloorRun(cell, cell)
                    end
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
    report.floorAnchorSource = self.FloorAnchorSource
    return true, report
end
