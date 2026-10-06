LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Original complete compositions, fitted to the corridor-clear center of the
-- stock HL2 long face. Section hue and location boards have separate authorities.
local C = LOD.CrateVisuals
-- Enclose both physical faces and every fitted composition independently of
-- native culling bounds, which may be empty/expanded before the first draw.
local bx=math.max(math.abs(C.CargoMins.x),math.abs(C.CargoMaxs.x))
local by=math.max(math.abs(C.CargoMins.y),math.abs(C.CargoMaxs.y))
local bz=math.max(math.abs(C.CargoMins.z),math.abs(C.CargoMaxs.z))
local BRAND_BOUND_RADIUS=math.sqrt(bx*bx+by*by+bz*bz)+C.SurfaceOffset
local DRAW_DISTANCE = C.DrawDistance
local DRAW_DISTANCE_SQR = DRAW_DISTANCE * DRAW_DISTANCE
local BUCKET_CELLS = 4
local BRAND_GLOBAL_CAP_FRACTION = 0.40
local BRAND_COVERAGE_RADIUS_CELLS = 3
local BRAND_COVERAGE_GOAL = 0.92
local BRAND_LOWER_TIER_BIAS = 0.35
local selectedSeed, selectedId, selectedMaterial, selectedPath
local materialSlots = {}
local loadedBrands = {}
LOD.CrateBranding = LOD.CrateBranding or {}
local Brand = LOD.CrateBranding

-- Source owns PNG texture lifetimes; these two shader slots never grow with crates,
-- frames or dungeons. Only the selected texture is requested, never the full catalog.
function Brand.MaterialFor(id, slot)
    if not LOD.CrateBrandMetadata[id] then return nil, "invalid-brand" end
    slot = slot == "preview" and "preview" or "world"
    local cached = materialSlots[slot]
    if cached and cached.id == id then return cached.material, cached.path end
    local path = "legend_of_deborah/container_brands/"..LOD.CrateBrandMetadata[id].path
    local source = Material(path, "smooth mips")
    if not source or source:IsError() then return nil, path end
    local texture = source:GetTexture("$basetexture")
    if not texture or texture:IsError() then return nil, path end
    local material = cached and cached.material or CreateMaterial("lod_crate_brand_c3_"..slot,
        "UnlitGeneric", {["$basetexture"]="vgui/white",
        ["$alphatest"]="1", ["$alphatestreference"]="0.1", ["$vertexcolor"]="1",
        ["$vertexalpha"]="1", ["$nocull"]="0"})
    if not material or material:IsError() then return nil, path end
    material:SetTexture("$basetexture", texture)
    if material.Recompute then material:Recompute() end
    materialSlots[slot] = {id=id, material=material, path=path}
    loadedBrands[id] = true
    return material, path
end

local retrySelectionAt = 0
local function ensureSelection()
    local seed = tonumber(Wall.seed) or 0
    if selectedSeed == seed and selectedId and selectedMaterial then return true end
    local now = CurTime()
    if selectedSeed == seed and not selectedMaterial and now < retrySelectionAt then return false end
    retrySelectionAt = now + 2
    selectedSeed, selectedId = seed, C.BrandID(seed)
    selectedMaterial, selectedPath = Brand.MaterialFor(selectedId)
    return selectedMaterial ~= nil
end

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

-- Physical contact is always forbidden: vertical partners on one logical wall edge
-- touch, and same-tier collinear neighbors sharing an endpoint touch end-to-end.
local function candidateConflicts(candidate, occupiedEdges, occupiedEndpoints)
    local instance = candidate.instance
    local edgeKey = instance.overlayEdgeKey
    local endpointA = instance.overlayEndpointA
    local endpointB = instance.overlayEndpointB
    local orientation = instance.overlayOrientation
    -- Reservations only accumulate during this selection. A conflict cannot
    -- clear; remember it on the temporary candidate, never on the world instance.
    if not edgeKey or not endpointA or not endpointB or not orientation
        or occupiedEdges[edgeKey]
    then
        candidate.conflicted = true
        return true
    end

    local stackKey = candidate.endpointStackKey
    if not stackKey then
        stackKey = tostring(instance.stackIndex or 0) .. ":" .. orientation
        candidate.endpointStackKey = stackKey
    end
    local endpoints = occupiedEndpoints[stackKey]
    local conflict = endpoints and (endpoints[endpointA] or endpoints[endpointB]) or false
    if conflict then candidate.conflicted = true end
    return conflict
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

local function coverageGain(candidate, covered)
    -- Covered only grows during this selection. Once every observation is
    -- covered, this temporary candidate can never gain coverage again. Keep
    -- its full coverage set intact for final allocation/summary accounting.
    if candidate.coverageExhausted then return 0 end
    local gain = 0
    for key in pairs(candidate.coverage or {}) do
        if not covered[key] then gain = gain + 1 end
    end
    if gain == 0 then candidate.coverageExhausted = true end
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
            and not candidate.conflicted
            and not candidateConflicts(candidate, occupiedEdges, occupiedEndpoints)
        then
            local gain = coverageGain(candidate, covered)
            -- Chosen only grows by one between scans. Conflicts only grow too,
            -- so every still-eligible candidate has seen every prior choice.
            -- Cache the exact minimum within this rebuild, not across worlds.
            local distance = candidate.nearestChosenDistance or math.huge
            local latest = chosen[#chosen]
            if latest then
                distance = math.min(distance, floorDistanceSquared(instance, latest.instance))
            end
            candidate.nearestChosenDistance = distance
            local visibility = (instance.stackIndex or 0) == 0 and BRAND_LOWER_TIER_BIAS or 0
            -- Seed and candidate identity are fixed for this rebuild. Keep the
            -- exact tie-break value on its temporary candidate, never across worlds.
            local noise = candidate.placementNoise
            if noise == nil then
                noise = deterministicNoise(seed, candidate)
                candidate.placementNoise = noise
            end
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
        if instance.brandSurfaceEligible ~= true or instance.marked then
            geometryBlockedCount = geometryBlockedCount + 1
        else
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
    placementMarkedCount = Wall.markRevision or 0
end

local function ensureBrandPlacement(world)
    local seed = tonumber(Wall.seed) or 0
    local marked = Wall.markRevision or 0
    if placementWorldRef ~= world or placementSeed ~= seed or placementMarkedCount ~= marked then
        rebuildBrandPlacement(world)
    end
end

hook.Add("Think", "LOD_RebuildSparseContainerBrandPlacement", function()
    local world = Wall.world or {}
    if #world == 0 then return end
    ensureBrandPlacement(world)
end)

local function addVertex(position, normal, u, v, color)
    mesh.Position(position)
    mesh.Normal(normal)
    mesh.TexCoord(0, u, v)
    mesh.Color(color.r, color.g, color.b, color.a)
    mesh.AdvanceVertex()
end

-- One latest projection per live model, with at most its two physical faces.
-- Keep the immediate quad renderer; only its unchanged math is retained. Weak
-- ownership lets cleanup/replacement/preview retirement release every corner.
local projections=setmetatable({},{__mode="k"})
local function projection(model,id,eyePos)
    local metadata=LOD.CrateBrandMetadata[id]
    if not metadata then return end
    local bounds=metadata.bounds
    local pos=model:GetPos()
    local ang=model.GetAngles and model:GetAngles()
    local scale=model.GetModelScale and model:GetModelScale() or 1
    local mins,maxs=C.CargoMins,C.CargoMaxs
    local cached=ang and projections[model]
    if not cached or cached.id~=id or cached.metadata~=metadata
        or cached.fitFunction~=C.FitBrand or cached.width~=metadata.width or cached.height~=metadata.height
        or cached.b1~=bounds[1] or cached.b2~=bounds[2] or cached.b3~=bounds[3] or cached.b4~=bounds[4]
        or cached.safeWidth~=C.SafeWidth or cached.safeHeight~=C.SafeHeight or cached.margin~=C.FitMargin
        or cached.minX~=mins.x or cached.minY~=mins.y or cached.minZ~=mins.z
        or cached.maxX~=maxs.x or cached.maxY~=maxs.y or cached.maxZ~=maxs.z or cached.offset~=C.SurfaceOffset
        or cached.x~=pos.x or cached.y~=pos.y or cached.z~=pos.z or cached.scale~=scale
        or cached.p~=ang.p or cached.yaw~=ang.y or cached.roll~=ang.r
        or cached.forwardGetter~=model.GetForward or cached.rightGetter~=model.GetRight
        or cached.upGetter~=model.GetUp or cached.transform~=model.LocalToWorld then
        local fit=C.FitBrand(id)
        if not fit then return end
        cached={id=id,metadata=metadata,fitFunction=C.FitBrand,fit=fit,faces={},
            width=metadata.width,height=metadata.height,b1=bounds[1],b2=bounds[2],b3=bounds[3],b4=bounds[4],
            safeWidth=C.SafeWidth,safeHeight=C.SafeHeight,margin=C.FitMargin,
            minX=mins.x,minY=mins.y,minZ=mins.z,maxX=maxs.x,maxY=maxs.y,maxZ=maxs.z,offset=C.SurfaceOffset,
            x=pos.x,y=pos.y,z=pos.z,scale=scale,p=ang and ang.p,yaw=ang and ang.y,roll=ang and ang.r,
            forwardGetter=model.GetForward,rightGetter=model.GetRight,upGetter=model.GetUp,transform=model.LocalToWorld,
            forward=model:GetForward(),right=model:GetRight(),up=model:GetUp()}
        if ang then projections[model]=cached end
    end
    local side=cached.forward:Dot(eyePos-pos)>=0 and 1 or -1
    local face=cached.faces[side]
    if not face then
        local fit=cached.fit
        local x=side>0 and maxs.x+C.SurfaceOffset or mins.x-C.SurfaceOffset
        local center=model:LocalToWorld(Vector(x,(mins.y+maxs.y)*.5,mins.z+(maxs.z-mins.z)*.55))
        local horizontal=side>0 and -cached.right or cached.right
        local up=cached.up
        local hw,hh=fit.width*.5,fit.height*.5
        face={center=center,horizontal=horizontal,up=up,normal=cached.forward*side,
            center-horizontal*hw+up*hh,center+horizontal*hw+up*hh,
            center+horizontal*hw-up*hh,center-horizontal*hw-up*hh}
        cached.faces[side]=face
    end
    return face,cached.fit
end

function Brand.Draw(model, id, material, eyePos, showSafeArea)
    if not LOD.CrateBrandMetadata[id] or not material or not IsValid(model) then return false, "invalid-input" end
    if model:GetModel() ~= LOD.Config.Geometry.ContainerModel then return false, "wrong-model" end
    -- GetRenderBounds is a culling volume and can be zero/expanded before drawing.
    -- Use the inspected stock mesh bounds for physical anchors, never that volume.
    local face,fit=projection(model,id,eyePos)
    if not face then return false,"invalid-input" end
    render.SetColorModulation(1,1,1)
    render.SetBlend(1)
    render.SetMaterial(material)
    -- Source's front-face order has cross(edge1, edge2) opposite the outward
    -- normal (also true of the stock cargo VTX). Keep each UV with its corner;
    -- the former reverse order submitted valid but backface-culled sprays.
    mesh.Begin(MATERIAL_QUADS,1)
        addVertex(face[1],face.normal,fit.u0,fit.v0,color_white)
        addVertex(face[2],face.normal,fit.u1,fit.v0,color_white)
        addVertex(face[3],face.normal,fit.u1,fit.v1,color_white)
        addVertex(face[4],face.normal,fit.u0,fit.v1,color_white)
    mesh.End()
    if showSafeArea then
        local center,horizontal,up=face.center,face.horizontal,face.up
        local w,h=C.SafeWidth*0.5,C.SafeHeight*0.5
        local points={center-horizontal*w+up*h,center+horizontal*w+up*h,
            center+horizontal*w-up*h,center-horizontal*w-up*h}
        for i=1,4 do render.DrawLine(points[i],points[i%4+1],Color(255,200,40),true) end
    end
    return true
end

local function nearer(distance,index,other)
    if distance~=other.distance then return distance<other.distance end
    return index<other.index
end
local function siftWorst(candidates,entry,slot,count)
    while slot*2<=count do
        local child=slot*2
        if child<count and nearer(candidates[child].distance,candidates[child].index,candidates[child+1]) then child=child+1 end
        local other=candidates[child]
        if not nearer(entry.distance,entry.index,other) then break end
        candidates[slot]=other;slot=child
    end
    candidates[slot]=entry
end
-- The worst admitted candidate is the root of this bounded max-heap. Reject
-- farther candidates immediately, reusing an entry on replacement; sort only
-- the admitted prefix to preserve exact historical distance/index draw order.
local function admit(candidates,model,distance,index)
    local count=#candidates
    if C.MaxBrandDraws<=0 then return end
    if count<C.MaxBrandDraws then
        candidates[count+1]={model=model,distance=distance,index=index}
        return
    end
    -- Ordinary small scenes keep the original append/sort path. Heap work only
    -- begins when the draw ceiling is actually exceeded.
    if not candidates.heapReady then
        for slot=math.floor(count*.5),1,-1 do siftWorst(candidates,candidates[slot],slot,count) end
        candidates.heapReady=true
    end
    if nearer(distance,index,candidates[1]) then
        local entry=candidates[1];entry.model,entry.distance,entry.index=model,distance,index
        siftWorst(candidates,entry,1,count)
    end
end

hook.Remove("PostDrawOpaqueRenderables", "LOD_DrawContainerBranding")
hook.Remove("PostDrawTranslucentRenderables", "LOD_DrawContainerBranding")
hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerBranding", function(depth,sky,sky3d)
    if depth or sky or sky3d then return end
    Brand.lastDrawCount, Brand.lastSkippedCount, Brand.lastSkipReason = 0, 0, nil
    Brand.lastCulledCount, Brand.lastRenderMilliseconds = 0, 0
    Brand.lastCandidateCount,Brand.lastAdmittedCount=0,0
    local world = Wall.world or {}
    if #world==0 or not IsValid(LocalPlayer()) or not ensureSelection() then return end
    local started=SysTime and SysTime() or 0
    local view=Wall.OverlayView and Wall:OverlayView()
    local eyePos=view and view.eye or EyePos()
    local gx,gy,gz=gridPosition(eyePos)
    local buckets=Wall.labelBuckets and Wall.labelBuckets[gz]
    if not buckets then return end
    local radius=math.ceil(DRAW_DISTANCE/(BUCKET_CELLS*MC.CellSize))+1
    local cx,cy=bucketKey(gx,gy)
    local candidates={}
    for bx=cx-radius,cx+radius do
        for by=cy-radius,cy+radius do
            for _,index in ipairs(buckets[bx..":"..by] or {}) do
                local instance,model=world[index],Wall.models[index]
                if instance and instance.companyBranded and not instance.marked
                    and instance.brandSurfaceEligible and IsValid(model) then
                    local distance=eyePos:DistToSqr(model:GetPos())
                    if distance<=DRAW_DISTANCE_SQR then
                        Brand.lastCandidateCount=Brand.lastCandidateCount+1
                        admit(candidates,model,distance,index)
                    end
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.distance~=b.distance then return a.distance<b.distance end
        return a.index<b.index
    end)
    Brand.lastAdmittedCount=#candidates
    for i=1,math.min(#candidates,C.MaxBrandDraws) do
        local model=candidates[i].model
        -- Keep the original nearest-64 selection before rejecting submissions;
        -- culling does not fill its slots with farther brands.
        if Wall.OverlaySphereVisible and not Wall:OverlaySphereVisible(view,model:GetPos(),BRAND_BOUND_RADIUS) then
            Brand.lastCulledCount=Brand.lastCulledCount+1
        else
            local drawn, reason = Brand.Draw(model,selectedId,selectedMaterial,eyePos)
            if drawn then Brand.lastDrawCount = Brand.lastDrawCount + 1
            else Brand.lastSkippedCount = Brand.lastSkippedCount + 1; Brand.lastSkipReason = reason end
        end
    end
    Brand.lastRenderMilliseconds=SysTime and (SysTime()-started)*1000 or nil
end)

function Brand.Summary()
    local world=Wall.world or {}
    if #world>0 then ensureBrandPlacement(world) end
    local ok=ensureSelection()
    return {brandID=selectedId,company=selectedId and LOD.CrateBrandMetadata[selectedId].name,
        renderer="source-front-face-20260924",
        shader=selectedMaterial and selectedMaterial:GetShader() or "missing",
        skipped=Brand.lastSkippedCount or 0,skipReason=Brand.lastSkipReason,culled=Brand.lastCulledCount or 0,
        material=selectedPath,materialOK=ok,loadedTextures=table.Count(loadedBrands),
        shaderSlots=table.Count(materialSlots),branded=brandedCount,containers=#world,
        cap=globalBrandCap,geometryBlocked=geometryBlockedCount,safeWidth=C.SafeWidth,
        safeHeight=C.SafeHeight,margin=C.FitMargin,draws=Brand.lastDrawCount or 0,
        maxDraws=C.MaxBrandDraws,renderMilliseconds=Brand.lastRenderMilliseconds,
        candidates=Brand.lastCandidateCount or 0,admitted=Brand.lastAdmittedCount or 0,
        estimatedTextureMiB=table.Count(loadedBrands)*(8/3)+(loadedBrands[232] and 8/3 or 0),
        coverage=coverageCoveredCount,observations=coverageObservedCount}
end
concommand.Add("lod_container_brand_status",function()
    print("[LOD:CRATE-BRAND] "..util.TableToJSON(Brand.Summary()))
end)
