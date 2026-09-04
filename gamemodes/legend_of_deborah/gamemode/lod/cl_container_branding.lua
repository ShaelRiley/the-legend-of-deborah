LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Company identity is presentation-only. cl_container_section_recolor.lua owns the
-- gritty neutral hull and procedural section hue. This pass adds one alpha-tested,
-- dithered company stencil over most of the broad side of each ordinary container.
-- Marked wayfinding containers deliberately suppress company paint.
local DRAW_DISTANCE = 1650
local DRAW_DISTANCE_SQR = DRAW_DISTANCE * DRAW_DISTANCE
local BUCKET_CELLS = 4
local SURFACE_OFFSET = 0.80
local LOGO_Y_FRACTION = 0.50
local LOGO_Z_FRACTION = 0.55
local SIDE_WIDTH_FRACTION = 0.86
local SIDE_HEIGHT_FRACTION = 0.66
local BRAND_GLOBAL_CAP_FRACTION = 0.40
local BRAND_COVERAGE_RADIUS_CELLS = 3
local BRAND_COVERAGE_GOAL = 0.92
local BRAND_LOWER_TIER_BIAS = 0.35

local BRAND_COUNT = 256
local BRANDS_PER_ATLAS = 64
local ATLAS_COLUMNS = 8
local ATLAS_ROWS = 8
local CELL_U = 1 / ATLAS_COLUMNS
local CELL_V = 1 / ATLAS_ROWS
local UV_INSET = 0.00035

local selectedSeed
local selectedId
local selectedAtlas
local selectedColumn
local selectedRow
local selectedMaterial
local selectedPath
local atlasMaterialCache = {}

local function bucketKey(x, y)
    return math.floor((x - 1) / BUCKET_CELLS), math.floor((y - 1) / BUCKET_CELLS)
end

local function gridPosition(pos)
    local origin = Wall.origin or MC.Origin or vector_origin
    local gx = math.floor(((pos.x - origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local gy = math.floor(((pos.y - origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local gz = math.floor(((pos.z - origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(gx, 1, MC.Width), math.Clamp(gy, 1, MC.Height), math.Clamp(gz, 0, 7)
end

local function materialForAtlas(atlasIndex)
    local cached = atlasMaterialCache[atlasIndex]
    if cached and not cached:IsError() then return cached end

    local path = string.format(
        "legend_of_deborah/container_surfaces/container_brand_spray_atlas_%02d.png",
        atlasIndex
    )
    local source = Material(path, "smooth nocull")
    if not source or source:IsError() then return nil, path end

    local texture = source:GetTexture("$basetexture")
    if not texture then return nil, path end

    local material = CreateMaterial(
        string.format("lod_container_spray_atlas_%02d_v8", atlasIndex),
        "VertexLitGeneric",
        {
            -- Start from a guaranteed built-in texture, then bind the mounted PNG's
            -- ITexture directly. Never round-trip texture:GetName() through Source's
            -- VTF resolver: that was the source of the opaque black broad-side card.
            ["$basetexture"] = "vgui/white",
            ["$model"] = "1",
            ["$alphatest"] = "1",
            ["$alphatestreference"] = "0.500",
            ["$vertexcolor"] = "1",
            ["$vertexalpha"] = "1",
            ["$nocull"] = "1",
            ["$halflambert"] = "1"
        }
    )
    if not material or material:IsError() then return nil, path end
    material:SetTexture("$basetexture", texture)
    if material.Recompute then material:Recompute() end

    atlasMaterialCache[atlasIndex] = material
    return material, path
end

local function ensureSelection()
    local seed = tonumber(Wall.seed) or 0
    if selectedSeed == seed and selectedId and selectedMaterial then
        return not selectedMaterial:IsError()
    end
    if not LOD.Seeds or not LOD.Seeds.Derive then return false end

    selectedSeed = seed
    local derived = tonumber(LOD.Seeds.Derive(seed, "container-brand:v1")) or seed
    selectedId = (derived % BRAND_COUNT) + 1
    selectedAtlas = math.floor((selectedId - 1) / BRANDS_PER_ATLAS) + 1

    local cell = (selectedId - 1) % BRANDS_PER_ATLAS
    selectedColumn = cell % ATLAS_COLUMNS
    selectedRow = math.floor(cell / ATLAS_COLUMNS)
    selectedMaterial, selectedPath = materialForAtlas(selectedAtlas)
    return selectedMaterial and not selectedMaterial:IsError()
end

local placementWorldRef = nil
local placementSeed = nil
local placementMarkedCount = -1
local brandedCount = 0
local brandableCount = 0
local geometryBlockedCount = 0
local targetBrandCount = 0
local placeableCount = 0
local globalBrandCap = 0
local relaxedGeometryCount = 0
local coverageObservedCount = 0
local coverageCoveredCount = 0
local coveragePrefixCount = 0

local DIR_DELTA = {
    [1] = {0, 1},
    [2] = {1, 0},
    [3] = {0, -1},
    [4] = {-1, 0}
}

local function placementSort(a, b)
    local ia, ib = a.instance, b.instance
    if (ia.floor or 0) ~= (ib.floor or 0) then return (ia.floor or 0) < (ib.floor or 0) end
    if (ia.quadrant or 0) ~= (ib.quadrant or 0) then return (ia.quadrant or 0) < (ib.quadrant or 0) end
    if (ia.gridY or 0) ~= (ib.gridY or 0) then return (ia.gridY or 0) < (ib.gridY or 0) end
    if (ia.gridX or 0) ~= (ib.gridX or 0) then return (ia.gridX or 0) < (ib.gridX or 0) end
    if (ia.stackIndex or 0) ~= (ib.stackIndex or 0) then
        return (ia.stackIndex or 0) < (ib.stackIndex or 0)
    end
    return a.index < b.index
end

local function currentMarkedCount(world)
    local count = 0
    for _, instance in ipairs(world or {}) do
        if instance.marked then count = count + 1 end
    end
    return count
end

-- Physical contact is always forbidden: vertical partners on one logical wall edge
-- touch, and same-tier collinear neighbors sharing an endpoint touch end-to-end.
local function candidateConflicts(instance, occupiedEdges, occupiedEndpoints)
    local edgeKey = instance.overlayEdgeKey
    local endpointA = instance.overlayEndpointA
    local endpointB = instance.overlayEndpointB
    local orientation = instance.overlayOrientation
    if not edgeKey or not endpointA or not endpointB or not orientation then return true end
    if occupiedEdges[edgeKey] then return true end

    local stackKey = tostring(instance.stackIndex or 0) .. ":" .. orientation
    local endpoints = occupiedEndpoints[stackKey]
    return endpoints and (endpoints[endpointA] or endpoints[endpointB]) or false
end

local function reserveCandidate(instance, occupiedEdges, occupiedEndpoints)
    occupiedEdges[instance.overlayEdgeKey] = true
    local stackKey = tostring(instance.stackIndex or 0) .. ":" .. instance.overlayOrientation
    local endpoints = occupiedEndpoints[stackKey]
    if not endpoints then
        endpoints = {}
        occupiedEndpoints[stackKey] = endpoints
    end
    endpoints[instance.overlayEndpointA] = true
    endpoints[instance.overlayEndpointB] = true
end

local function inBounds(x, y)
    return x >= 1 and x <= MC.Width and y >= 1 and y <= MC.Height
end

local function observationKey(floor, x, y)
    return string.format("%d:%d:%d", floor or 0, x, y)
end

local function passageKey(floor, x1, y1, x2, y2)
    if x2 < x1 or (x2 == x1 and y2 < y1) then
        x1, x2 = x2, x1
        y1, y2 = y2, y1
    end
    return string.format("%d:%d:%d>%d:%d", floor or 0, x1, y1, x2, y2)
end

local function buildBlockedPassages()
    local blocked = {}
    for _, segment in ipairs(Wall.logical or {}) do
        local x = tonumber(segment[1]) or 0
        local y = tonumber(segment[2]) or 0
        local floor = tonumber(segment[3]) or 0
        local delta = DIR_DELTA[tonumber(segment[4]) or 0]
        if delta then
            blocked[passageKey(floor, x, y, x + delta[1], y + delta[2])] = true
        end
    end
    return blocked
end

-- Approximate first-person visibility from the actual maze topology, not Euclidean
-- distance through walls. The company stencil is rendered on whichever broad side the
-- player occupies, so seed the neighborhood from both cells adjacent to the wall and
-- flood through open passages for a short corridor-aware radius.
local function coverageForInstance(instance, blocked)
    local floor = instance.floor or 0
    local starts = {{instance.gridX or 0, instance.gridY or 0}}
    local delta = DIR_DELTA[instance.overlayDirection or 0]
    if delta then
        local nx = (instance.gridX or 0) + delta[1]
        local ny = (instance.gridY or 0) + delta[2]
        if inBounds(nx, ny) then starts[#starts + 1] = {nx, ny} end
    end

    local covered = {}
    local visited = {}
    local queue = {}
    local head = 1
    for _, cell in ipairs(starts) do
        local x, y = cell[1], cell[2]
        if inBounds(x, y) then
            local key = observationKey(floor, x, y)
            if not visited[key] then
                visited[key] = true
                queue[#queue + 1] = {x = x, y = y, distance = 0}
            end
        end
    end

    while head <= #queue do
        local current = queue[head]
        head = head + 1
        covered[observationKey(floor, current.x, current.y)] = true
        if current.distance < BRAND_COVERAGE_RADIUS_CELLS then
            for _, move in pairs(DIR_DELTA) do
                local nx = current.x + move[1]
                local ny = current.y + move[2]
                if inBounds(nx, ny)
                    and not blocked[passageKey(floor, current.x, current.y, nx, ny)]
                then
                    local key = observationKey(floor, nx, ny)
                    if not visited[key] then
                        visited[key] = true
                        queue[#queue + 1] = {
                            x = nx,
                            y = ny,
                            distance = current.distance + 1
                        }
                    end
                end
            end
        end
    end
    return covered
end

local function floorDistanceSquared(a, b)
    local dx = (a.gridX or 0) - (b.gridX or 0)
    local dy = (a.gridY or 0) - (b.gridY or 0)
    return dx * dx + dy * dy
end

local function deterministicNoise(seed, candidate)
    local token = string.format(
        "container-brand-coverage:v5:%d:%d:%d:%d:%d",
        candidate.index or 0,
        candidate.instance.floor or 0,
        candidate.instance.gridX or 0,
        candidate.instance.gridY or 0,
        candidate.instance.stackIndex or 0
    )
    local derived = tonumber(LOD.Seeds.Derive(seed, token)) or 0
    return (derived % 10000) / 10000
end

local function minChosenDistanceSquared(instance, chosen)
    if #chosen == 0 then return math.huge end
    local best = math.huge
    for _, item in ipairs(chosen) do
        local distance = floorDistanceSquared(instance, item.instance)
        if distance < best then best = distance end
    end
    return best
end

local function coverageGain(candidate, covered)
    local gain = 0
    for key in pairs(candidate.coverage or {}) do
        if not covered[key] then gain = gain + 1 end
    end
    return gain
end

local function pickCoverageCandidate(candidates, chosen, covered,
    occupiedEdges, occupiedEndpoints, seed)
    local best = nil
    local bestGain = -1
    local bestDistance = -1
    local bestVisibility = -1
    local bestNoise = -1

    for _, candidate in ipairs(candidates) do
        local instance = candidate.instance
        if not candidate.selected
            and not candidateConflicts(instance, occupiedEdges, occupiedEndpoints)
        then
            local gain = coverageGain(candidate, covered)
            local distance = minChosenDistanceSquared(instance, chosen)
            local visibility = (instance.stackIndex or 0) == 0 and BRAND_LOWER_TIER_BIAS or 0
            local noise = deterministicNoise(seed, candidate)
            if gain > bestGain
                or (gain == bestGain and distance > bestDistance)
                or (gain == bestGain and distance == bestDistance and visibility > bestVisibility)
                or (gain == bestGain and distance == bestDistance
                    and visibility == bestVisibility and noise > bestNoise)
            then
                best = candidate
                bestGain = gain
                bestDistance = distance
                bestVisibility = visibility
                bestNoise = noise
            end
        end
    end
    return best, bestGain
end

local function selectCoverageOrder(candidates, floor, seed, blocked)
    local chosen = {}
    local occupiedEdges = {}
    local occupiedEndpoints = {}
    local covered = {}
    local coveredCount = 0
    local observationCount = MC.Width * MC.Height
    local goalCount = math.ceil(observationCount * BRAND_COVERAGE_GOAL)
    local prefixCount = 0

    for _, candidate in ipairs(candidates) do
        candidate.coverage = coverageForInstance(candidate.instance, blocked)
    end

    while true do
        local candidate = pickCoverageCandidate(
            candidates, chosen, covered, occupiedEdges, occupiedEndpoints, seed
        )
        if not candidate then break end

        candidate.selected = true
        reserveCandidate(candidate.instance, occupiedEdges, occupiedEndpoints)
        chosen[#chosen + 1] = candidate
        for key in pairs(candidate.coverage or {}) do
            if not covered[key] then
                covered[key] = true
                coveredCount = coveredCount + 1
            end
        end
        if prefixCount == 0 and coveredCount >= goalCount then
            prefixCount = #chosen
        end
    end

    if prefixCount == 0 then prefixCount = #chosen end
    return {
        floor = floor,
        chosen = chosen,
        coveragePrefix = prefixCount,
        observationCount = observationCount
    }
end

local function allocateFloorCounts(groups, target)
    local allocation = {}
    if target <= 0 or #groups == 0 then return allocation end

    local totalChosen = 0
    local totalCoveragePrefix = 0
    for index, group in ipairs(groups) do
        allocation[index] = 0
        totalChosen = totalChosen + #group.chosen
        totalCoveragePrefix = totalCoveragePrefix + math.min(#group.chosen, group.coveragePrefix or 0)
    end
    if target >= totalChosen then
        for index, group in ipairs(groups) do allocation[index] = #group.chosen end
        return allocation
    end

    -- Spend the constrained budget on coverage prefixes first. If even those exceed
    -- the 40% ceiling, preserve at least one mark per floor when possible and then
    -- distribute proportionally by each floor's coverage-prefix demand.
    local baselineTarget = math.min(target, totalCoveragePrefix)
    if baselineTarget >= #groups then
        for index, group in ipairs(groups) do
            if #group.chosen > 0 then allocation[index] = 1 end
        end
    end

    local allocated = 0
    for _, count in pairs(allocation) do allocated = allocated + count end
    local remaining = baselineTarget - allocated
    while remaining > 0 do
        local bestIndex = nil
        local bestNeed = -1
        for index, group in ipairs(groups) do
            local need = math.min(#group.chosen, group.coveragePrefix or 0) - (allocation[index] or 0)
            if need > bestNeed and need > 0 then
                bestNeed = need
                bestIndex = index
            end
        end
        if not bestIndex then break end
        allocation[bestIndex] = (allocation[bestIndex] or 0) + 1
        remaining = remaining - 1
    end

    allocated = 0
    for _, count in pairs(allocation) do allocated = allocated + count end
    remaining = target - allocated
    while remaining > 0 do
        local bestIndex = nil
        local bestCapacity = -1
        for index, group in ipairs(groups) do
            local capacity = #group.chosen - (allocation[index] or 0)
            if capacity > bestCapacity and capacity > 0 then
                bestCapacity = capacity
                bestIndex = index
            end
        end
        if not bestIndex then break end
        allocation[bestIndex] = (allocation[bestIndex] or 0) + 1
        remaining = remaining - 1
    end
    return allocation
end

local function rebuildBrandPlacement(world)
    brandedCount = 0
    brandableCount = 0
    geometryBlockedCount = 0
    targetBrandCount = 0
    placeableCount = 0
    relaxedGeometryCount = 0
    coverageObservedCount = 0
    coverageCoveredCount = 0
    coveragePrefixCount = 0
    globalBrandCap = math.floor(#(world or {}) * BRAND_GLOBAL_CAP_FRACTION)

    local byFloor = {}
    for index, instance in ipairs(world or {}) do
        instance.companyBranded = false
        if instance.brandSurfaceEligible ~= true then
            geometryBlockedCount = geometryBlockedCount + 1
        elseif not instance.marked then
            if instance.fullSurfaceEligible ~= true then
                relaxedGeometryCount = relaxedGeometryCount + 1
            end
            local floor = instance.floor or 0
            local group = byFloor[floor]
            if not group then
                group = {}
                byFloor[floor] = group
            end
            group[#group + 1] = {index = index, instance = instance, selected = false}
            brandableCount = brandableCount + 1
        end
    end

    local seed = tonumber(Wall.seed) or 1
    local blocked = buildBlockedPassages()
    local floors = {}
    for floor in pairs(byFloor) do floors[#floors + 1] = floor end
    table.sort(floors)

    local groups = {}
    for _, floor in ipairs(floors) do
        local candidates = byFloor[floor]
        table.sort(candidates, placementSort)
        local floorSeed = LOD.Seeds.Derive(seed, "container-brand-coverage:v5:floor:" .. tostring(floor))
        local group = selectCoverageOrder(candidates, floor, floorSeed, blocked)
        groups[#groups + 1] = group
        placeableCount = placeableCount + #group.chosen
        coverageObservedCount = coverageObservedCount + group.observationCount
        coveragePrefixCount = coveragePrefixCount + group.coveragePrefix
    end

    targetBrandCount = math.min(placeableCount, globalBrandCap)
    local allocation = allocateFloorCounts(groups, targetBrandCount)
    local finalCovered = {}

    for index, group in ipairs(groups) do
        local count = math.min(#group.chosen, allocation[index] or 0)
        for chosenIndex = 1, count do
            local item = group.chosen[chosenIndex]
            if item and item.instance then
                item.instance.companyBranded = true
                brandedCount = brandedCount + 1
                for key in pairs(item.coverage or {}) do finalCovered[key] = true end
            end
        end
    end
    for _ in pairs(finalCovered) do coverageCoveredCount = coverageCoveredCount + 1 end

    placementWorldRef = world
    placementSeed = tonumber(Wall.seed) or 0
    placementMarkedCount = currentMarkedCount(world)
end

local function ensureBrandPlacement(world)
    local seed = tonumber(Wall.seed) or 0
    local marked = currentMarkedCount(world)
    if placementWorldRef ~= world or placementSeed ~= seed or placementMarkedCount ~= marked then
        rebuildBrandPlacement(world)
    end
end

hook.Add("Think", "LOD_RebuildSparseContainerBrandPlacement", function()
    local world = Wall.world or {}
    if #world == 0 then return end
    ensureBrandPlacement(world)
end)

local function sprayPaintColor(instance)
    local c = instance.bodyColor or instance.sectionColor or Color(110, 110, 110, 255)
    local luminance = (c.r or 0) * 0.2126 + (c.g or 0) * 0.7152 + (c.b or 0) * 0.0722
    if luminance < 150 then
        return Color(244, 241, 222, 246)
    end
    return Color(24, 25, 24, 238)
end

local function atlasUV()
    local u0 = selectedColumn * CELL_U + UV_INSET
    local v0 = selectedRow * CELL_V + UV_INSET
    local u1 = (selectedColumn + 1) * CELL_U - UV_INSET
    local v1 = (selectedRow + 1) * CELL_V - UV_INSET
    return u0, v0, u1, v1
end

local function addVertex(position, normal, u, v, color)
    mesh.Position(position)
    mesh.Normal(normal)
    mesh.TexCoord(0, u, v)
    mesh.Color(color.r, color.g, color.b, color.a)
    mesh.AdvanceVertex()
end

local function drawBrand(model, instance, eyePos)
    if not ensureSelection() then return end

    local mins, maxs = model:GetRenderBounds()
    local spanY = maxs.y - mins.y
    local spanZ = maxs.z - mins.z
    local side = model:GetForward():Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + SURFACE_OFFSET) or (mins.x - SURFACE_OFFSET)
    local localY = mins.y + spanY * LOGO_Y_FRACTION
    local localZ = mins.z + spanZ * LOGO_Z_FRACTION
    local center = model:LocalToWorld(Vector(localX, localY, localZ))

    local normal = model:GetForward() * side
    -- A physical decal viewed from the opposite outward normal needs the opposite
    -- tangent from the model's local Right vector. V3 used the right-handed surface
    -- tangent directly, which made text read backwards to a player facing the wall.
    local horizontal = side > 0 and -model:GetRight() or model:GetRight()
    local up = model:GetUp()

    -- The V5 cell is authored at a wide 4:1 aspect ratio. It deliberately occupies
    -- most of one cargo-container side rather than hovering as a small placard.
    local width = spanY * SIDE_WIDTH_FRACTION
    local height = math.min(spanZ * SIDE_HEIGHT_FRACTION, width * 0.25)
    local halfW = width * 0.5
    local halfH = height * 0.5

    local topLeft = center - horizontal * halfW + up * halfH
    local topRight = center + horizontal * halfW + up * halfH
    local bottomRight = center + horizontal * halfW - up * halfH
    local bottomLeft = center - horizontal * halfW - up * halfH
    local u0, v0, u1, v1 = atlasUV()
    local paint = sprayPaintColor(instance)

    render.SetMaterial(selectedMaterial)
    mesh.Begin(MATERIAL_QUADS, 1)
        addVertex(topLeft, normal, u0, v0, paint)
        addVertex(topRight, normal, u1, v0, paint)
        addVertex(bottomRight, normal, u1, v1, paint)
        addVertex(bottomLeft, normal, u0, v1, paint)
    mesh.End()
end

hook.Remove("PostDrawOpaqueRenderables", "LOD_DrawContainerBranding")
hook.Remove("PostDrawTranslucentRenderables", "LOD_DrawContainerBranding")
hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerBranding", function()
    local world = Wall.world or {}
    if #world == 0 then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local eyePos = EyePos()
    local gx, gy, gz = gridPosition(eyePos)
    local floorBuckets = Wall.labelBuckets and Wall.labelBuckets[gz]
    if not floorBuckets then return end

    local bucketRadius = math.ceil(DRAW_DISTANCE / (BUCKET_CELLS * MC.CellSize)) + 1
    local centerBX, centerBY = bucketKey(gx, gy)
    for bx = centerBX - bucketRadius, centerBX + bucketRadius do
        for by = centerBY - bucketRadius, centerBY + bucketRadius do
            local bucket = floorBuckets[tostring(bx) .. ":" .. tostring(by)]
            if bucket then
                for _, index in ipairs(bucket) do
                    local instance = world[index]
                    local model = Wall.models and Wall.models[index]
                    if instance and instance.companyBranded == true
                        and instance.brandSurfaceEligible == true and not instance.marked
                        and IsValid(model)
                        and eyePos:DistToSqr(model:GetPos()) <= DRAW_DISTANCE_SQR
                    then
                        drawBrand(model, instance, eyePos)
                    end
                end
            end
        end
    end
end)

concommand.Add("lod_container_brand_status", function()
    local world = Wall.world or {}
    if #world > 0 then ensureBrandPlacement(world) end
    local ok = ensureSelection()
    print(string.format(
        "[LOD] container brand: seed=%s brand=%s atlas=%s cell=%s,%s material=%s path=%s mode=vertexlit-spray-v8-alphatest-dither width=%.2f height=%.2f placement=%d/%d placeable=%d all=%d cap=%.0f%% capCount=%d targetCount=%d separation=touching-never distribution=coverage-first radius=%dcells coverage=%d/%d(%.0f%%) goal=%.0f%% coveragePrefix=%d geometryBlocked=%d decalRelaxed=%d lowerBias=%.2f",
        tostring(Wall.seed or 0),
        selectedId and string.format("%03d", selectedId) or "none",
        selectedAtlas and string.format("%02d", selectedAtlas) or "none",
        tostring(selectedColumn or "none"),
        tostring(selectedRow or "none"),
        ok and "ok" or "error",
        tostring(selectedPath or "none"),
        SIDE_WIDTH_FRACTION,
        SIDE_HEIGHT_FRACTION,
        brandedCount,
        brandableCount,
        placeableCount,
        #world,
        BRAND_GLOBAL_CAP_FRACTION * 100,
        globalBrandCap,
        targetBrandCount,
        BRAND_COVERAGE_RADIUS_CELLS,
        coverageCoveredCount,
        coverageObservedCount,
        coverageObservedCount > 0 and (coverageCoveredCount / coverageObservedCount) * 100 or 0,
        BRAND_COVERAGE_GOAL * 100,
        coveragePrefixCount,
        geometryBlockedCount,
        relaxedGeometryCount,
        BRAND_LOWER_TIER_BIAS
    ))
end)
