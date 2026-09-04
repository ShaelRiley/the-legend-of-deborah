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
local BRAND_TARGET_FRACTION = 0.26
local BRAND_SOFT_SPACING_CELLS = 2
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
local relaxedSpacingCount = 0

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

-- Physical contact is a hard exclusion. Upper/lower partners on one wall edge touch,
-- and same-tier collinear neighbors sharing an endpoint touch end-to-end.
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

local function floorDistanceSquared(a, b)
    local dx = (a.gridX or 0) - (b.gridX or 0)
    local dy = (a.gridY or 0) - (b.gridY or 0)
    return dx * dx + dy * dy
end

local function deterministicNoise(seed, candidate)
    local token = string.format(
        "container-brand-coverage:v3:%d:%d:%d:%d:%d",
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

local function pickBestCandidate(candidates, chosen, occupiedEdges, occupiedEndpoints,
    seed, minimumDistanceSquared)
    local best = nil
    local bestDistance = -1
    local bestVisibility = -1
    local bestNoise = -1

    for _, candidate in ipairs(candidates) do
        local instance = candidate.instance
        if not candidate.selected
            and not candidateConflicts(instance, occupiedEdges, occupiedEndpoints)
        then
            local distance = minChosenDistanceSquared(instance, chosen)
            if distance >= minimumDistanceSquared then
                -- Favor eye-level/lower containers only as a tie-breaker. Spatial
                -- coverage remains the dominant criterion, which avoids visible clumps.
                local visibility = (instance.stackIndex or 0) == 0 and BRAND_LOWER_TIER_BIAS or 0
                local noise = deterministicNoise(seed, candidate)
                if distance > bestDistance
                    or (distance == bestDistance and visibility > bestVisibility)
                    or (distance == bestDistance and visibility == bestVisibility and noise > bestNoise)
                then
                    best = candidate
                    bestDistance = distance
                    bestVisibility = visibility
                    bestNoise = noise
                end
            end
        end
    end
    return best
end

local function selectBlueNoise(candidates, seed, target)
    local chosen = {}
    local occupiedEdges = {}
    local occupiedEndpoints = {}
    local softDistanceSquared = BRAND_SOFT_SPACING_CELLS * BRAND_SOFT_SPACING_CELLS

    -- Pass one: strong two-cell spacing. This is what creates a believable, evenly
    -- distributed industrial-yard impression instead of random deserts and clusters.
    while #chosen < target do
        local candidate = pickBestCandidate(
            candidates, chosen, occupiedEdges, occupiedEndpoints,
            seed, softDistanceSquared
        )
        if not candidate then break end
        candidate.selected = true
        reserveCandidate(candidate.instance, occupiedEdges, occupiedEndpoints)
        chosen[#chosen + 1] = candidate
    end

    -- Pass two: fill toward the visual-density target if necessary, but NEVER relax
    -- physical contact. This only relaxes the aesthetic two-cell cushion.
    while #chosen < target do
        local candidate = pickBestCandidate(
            candidates, chosen, occupiedEdges, occupiedEndpoints,
            seed, 0
        )
        if not candidate then break end
        candidate.selected = true
        reserveCandidate(candidate.instance, occupiedEdges, occupiedEndpoints)
        chosen[#chosen + 1] = candidate
        relaxedSpacingCount = relaxedSpacingCount + 1
    end

    return chosen
end

local function rebuildBrandPlacement(world)
    brandedCount = 0
    brandableCount = 0
    geometryBlockedCount = 0
    targetBrandCount = 0
    relaxedSpacingCount = 0

    local byFloor = {}
    for index, instance in ipairs(world or {}) do
        instance.companyBranded = false
        if instance.fullSurfaceEligible ~= true then
            geometryBlockedCount = geometryBlockedCount + 1
        elseif not instance.marked then
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
    local floors = {}
    for floor in pairs(byFloor) do floors[#floors + 1] = floor end
    table.sort(floors)

    for _, floor in ipairs(floors) do
        local candidates = byFloor[floor]
        table.sort(candidates, placementSort)
        local target = math.floor(#candidates * BRAND_TARGET_FRACTION + 0.5)
        if #candidates >= 4 then target = math.max(1, target) end
        targetBrandCount = targetBrandCount + target

        local floorSeed = LOD.Seeds.Derive(seed, "container-brand-coverage:v3:floor:" .. tostring(floor))
        local chosen = selectBlueNoise(candidates, floorSeed, target)
        for _, item in ipairs(chosen) do
            item.instance.companyBranded = true
            brandedCount = brandedCount + 1
        end
    end

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
                        and instance.fullSurfaceEligible == true and not instance.marked
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
        "[LOD] container brand: seed=%s brand=%s atlas=%s cell=%s,%s material=%s path=%s mode=vertexlit-spray-v8-alphatest-dither width=%.2f height=%.2f placement=%d/%d target=%.0f%% targetCount=%d separation=touching-never distribution=blue-noise softSpacing=%dcells lowerBias=%.2f geometryBlocked=%d relaxed=%d",
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
        BRAND_TARGET_FRACTION * 100,
        targetBrandCount,
        BRAND_SOFT_SPACING_CELLS,
        BRAND_LOWER_TIER_BIAS,
        geometryBlockedCount,
        relaxedSpacingCount
    ))
end)
