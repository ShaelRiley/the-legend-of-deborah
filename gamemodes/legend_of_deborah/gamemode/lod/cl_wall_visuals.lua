LOD = LOD or {}
LOD.WallVisualsClient = LOD.WallVisualsClient or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config.Maze
local GC = LOD.Config.Geometry
local MESSAGE = "LOD_WallVisuals"
local PROTOCOL = 2
local CONTAINER_VISUAL_EMBED = 16
local STACK_VISUAL_GAP = 4
local MODEL_BATCH_SIZE = 128
local RETRY_BATCH_SIZE = 16
local MODEL_RETRY_LIMIT = 8

-- Production container presentation is deliberately centralized here rather than
-- distributed across the graph, collision, or Motion V2 code. The stock cargo
-- mesh remains the validated batched wall model, but one material override removes
-- the recognizable Northern Petroleum/red-container branding. Spatial metadata is
-- derived only from the immutable wall manifest and its level seed.
local CONTAINER_BODY_MATERIAL = "models/debug/debugwhite"
local CONTAINER_BODY_COLOR = Color(224, 226, 226, 255)
local LABEL_MAX_DISTANCE = 1550
local LABEL_MAX_DISTANCE_SQR = LABEL_MAX_DISTANCE * LABEL_MAX_DISTANCE
local LABEL_BUCKET_CELLS = 4
local LABEL_SCALE = 0.20
local LABEL_SURFACE_OFFSET = 0.85

-- Exactly four deliberately non-progression hues are used on every floor, with a
-- seeded permutation assigning them to A/B/C/D. This guarantees within-floor
-- distinction while keeping Red/Blue/Yellow reserved for progression.
local SECTION_PALETTE = {
    Color(151, 86, 202, 255),  -- violet
    Color(43, 166, 151, 255),  -- teal
    Color(91, 174, 91, 255),   -- green
    Color(201, 88, 169, 255)   -- magenta
}
local QUADRANT_LETTERS = {"A", "B", "C", "D"}

surface.CreateFont("LOD_ContainerStencil", {
    font = "DejaVu Sans",
    size = 180,
    weight = 1000,
    antialias = false,
    extended = true
})

Wall.logical = Wall.logical or {}
Wall.world = Wall.world or {}
Wall.models = Wall.models or {}
Wall.dirty = Wall.dirty ~= false
Wall.nextModel = Wall.nextModel or 1
Wall.retryQueue = Wall.retryQueue or {}
Wall.retryAttempts = Wall.retryAttempts or {}
Wall.failedModels = Wall.failedModels or 0
Wall.labelBuckets = Wall.labelBuckets or {}
Wall.sectionColors = Wall.sectionColors or {}
Wall.seed = Wall.seed or 0

local DIRS = {
    {dx = 0, dy = 1, yaw = 90},
    {dx = 1, dy = 0, yaw = 0},
    {dx = 0, dy = -1, yaw = 90},
    {dx = -1, dy = 0, yaw = 0}
}

local function resetRetries()
    Wall.retryQueue = {}
    Wall.retryAttempts = {}
    Wall.failedModels = 0
end

local function removeModels()
    for _, model in pairs(Wall.models or {}) do
        if IsValid(model) then model:Remove() end
    end
    Wall.models = {}
    Wall.nextModel = 1
    resetRetries()
end

local function clearManifest()
    removeModels()
    Wall.logical = {}
    Wall.world = {}
    Wall.labelBuckets = {}
    Wall.sectionColors = {}
    Wall.seed = 0
    Wall.origin = nil
    Wall.dirty = true
    Wall.lastOrigin = nil
end

local function rebuildSectionColors()
    Wall.sectionColors = {}
    local levelSeed = tonumber(Wall.seed) or 0

    -- Precompute all representable floors. The maze normally owns 2-3 floors and
    -- rarely four, but the wall protocol reserves three bits for z.
    for floor = 0, 7 do
        local order = {1, 2, 3, 4}
        local rng = LOD.RNG.New(LOD.Seeds.Derive(levelSeed,
            "container-sections:floor:" .. tostring(floor + 1)))
        rng:Shuffle(order)
        Wall.sectionColors[floor] = {}
        for quadrant = 1, 4 do
            Wall.sectionColors[floor][quadrant] = SECTION_PALETTE[order[quadrant]]
        end
    end
end

net.Receive(MESSAGE, function()
    local byteCount = net.ReadUInt(16)
    if byteCount <= 0 then
        clearManifest()
        return
    end

    local compressed = net.ReadData(byteCount)
    local json = compressed and util.Decompress(compressed) or nil
    local data = json and util.JSONToTable(json) or nil
    if not istable(data) or tonumber(data.v) ~= PROTOCOL
        or not istable(data.segments) or not istable(data.origin)
    then
        ErrorNoHalt("[LOD] rejected invalid wall visual manifest\n")
        clearManifest()
        return
    end

    local originX = tonumber(data.origin[1])
    local originY = tonumber(data.origin[2])
    local originZ = tonumber(data.origin[3])
    if not originX or not originY or not originZ then
        ErrorNoHalt("[LOD] rejected wall visual manifest without resolved origin\n")
        clearManifest()
        return
    end

    local logical = {}
    for _, segment in ipairs(data.segments) do
        if istable(segment) then
            local x = math.floor(tonumber(segment[1]) or 0)
            local y = math.floor(tonumber(segment[2]) or 0)
            local z = math.floor(tonumber(segment[3]) or -1)
            local direction = math.floor(tonumber(segment[4]) or 0)
            if x >= 1 and x <= MC.Width
                and y >= 1 and y <= MC.Height
                and z >= 0 and z < 8
                and DIRS[direction]
            then
                logical[#logical + 1] = {x, y, z, direction}
            end
        end
    end

    removeModels()
    Wall.logical = logical
    Wall.world = {}
    Wall.labelBuckets = {}
    Wall.seed = tonumber(data.seed) or 0
    rebuildSectionColors()
    Wall.origin = Vector(originX, originY, originZ)
    Wall.dirty = true
    Wall.lastOrigin = nil
end)

local function originChanged(origin)
    local previous = Wall.lastOrigin
    return not previous or previous:DistToSqr(origin) > 0.0001
end

local function quadrantForSegment(segment, direction)
    -- Classify the physical center of the wall rather than whichever graph cell
    -- happened to enumerate the undirected edge first. The odd 21x21 footprint
    -- has a true centerline; exact ties deterministically belong left/up.
    local midpointX = segment[1] + direction.dx * 0.5
    local midpointY = segment[2] + direction.dy * 0.5
    local centerX = (MC.Width + 1) * 0.5
    local centerY = (MC.Height + 1) * 0.5
    local left = midpointX <= centerX
    local upper = midpointY >= centerY

    if upper then return left and 1 or 2 end
    return left and 3 or 4
end

local function labelBucketKey(x, y)
    local bx = math.floor((x - 1) / LABEL_BUCKET_CELLS)
    local by = math.floor((y - 1) / LABEL_BUCKET_CELLS)
    return bx, by, tostring(bx) .. ":" .. tostring(by)
end

local function addLabelBucket(instanceIndex, instance)
    local floor = instance.floor
    Wall.labelBuckets[floor] = Wall.labelBuckets[floor] or {}
    local _, _, key = labelBucketKey(instance.gridX, instance.gridY)
    local bucket = Wall.labelBuckets[floor][key]
    if not bucket then
        bucket = {}
        Wall.labelBuckets[floor][key] = bucket
    end
    bucket[#bucket + 1] = instanceIndex
end

-- Overlay-safe containers must expose their entire long face. A perpendicular
-- wall meeting either endpoint clips some portion of that face in corners, T-junctions,
-- short dead ends and related maze edge cases. Classify those cases once from the
-- immutable logical wall manifest rather than tracing visibility every render frame.
local function segmentFaceInfo(segment)
    if not segment then return nil end
    local x = math.floor(tonumber(segment[1]) or 0)
    local y = math.floor(tonumber(segment[2]) or 0)
    local z = math.floor(tonumber(segment[3]) or -1)
    local direction = math.floor(tonumber(segment[4]) or -1)
    if z < 0 or not DIRS[direction] then return nil end

    local ax, ay, bx, by, orientation
    -- DIRS is a normal Lua array: 1=north, 2=east, 3=south, 4=west.
    if direction == 1 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y + 1, 2 * x + 1, 2 * y + 1, "h"
    elseif direction == 3 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y - 1, 2 * x + 1, 2 * y - 1, "h"
    elseif direction == 2 then
        ax, ay, bx, by, orientation = 2 * x + 1, 2 * y - 1, 2 * x + 1, 2 * y + 1, "v"
    elseif direction == 4 then
        ax, ay, bx, by, orientation = 2 * x - 1, 2 * y - 1, 2 * x - 1, 2 * y + 1, "v"
    else
        return nil
    end

    local a = string.format("%d:%d:%d", z, ax, ay)
    local b = string.format("%d:%d:%d", z, bx, by)
    local first, second = a < b and a or b, a < b and b or a
    return {
        endpointA = a,
        endpointB = b,
        orientation = orientation,
        edgeKey = first .. ">" .. second
    }
end

local function buildFullSurfaceEligibility(logical)
    local infoByIndex = {}
    local endpointUse = {}
    local edgeCounts = {}

    for index, segment in ipairs(logical or {}) do
        local info = segmentFaceInfo(segment)
        infoByIndex[index] = info
        if info then
            edgeCounts[info.edgeKey] = (edgeCounts[info.edgeKey] or 0) + 1
            for _, endpoint in ipairs({info.endpointA, info.endpointB}) do
                local use = endpointUse[endpoint]
                if not use then
                    use = {h = 0, v = 0}
                    endpointUse[endpoint] = use
                end
                use[info.orientation] = use[info.orientation] + 1
            end
        end
    end

    local eligible = {}
    for index, info in ipairs(infoByIndex) do
        if info and edgeCounts[info.edgeKey] == 1 then
            local perpendicular = info.orientation == "h" and "v" or "h"
            local a = endpointUse[info.endpointA]
            local b = endpointUse[info.endpointB]
            eligible[index] = a and b and a[perpendicular] == 0 and b[perpendicular] == 0
        else
            eligible[index] = false
        end
    end
    return eligible
end

local function rebuildWorldCache()
    local origin = Wall.origin or MC.Origin or vector_origin
    if not Wall.dirty and not originChanged(origin) then return false end

    removeModels()
    local out = {}
    Wall.labelBuckets = {}
    local halfWidth = (MC.Width + 1) * 0.5
    local halfHeight = (MC.Height + 1) * 0.5
    local configuredStackCount = math.floor(tonumber(GC.WallStack) or 2)
    if configuredStackCount ~= 2 then
        ErrorNoHalt(string.format("[LOD] WallStack=%d overridden: production walls require exactly two containers\n", configuredStackCount))
    end
    local stackCount = 2

    local fullSurfaceEligibility = buildFullSurfaceEligibility(Wall.logical or {})
    for segmentIndex, segment in ipairs(Wall.logical or {}) do
        local direction = DIRS[segment[4]]
        if direction then
            local faceInfo = segmentFaceInfo(segment)
            local baseX = (segment[1] - halfWidth) * MC.CellSize
                + direction.dx * MC.CellSize * 0.5
            local baseY = (segment[2] - halfHeight) * MC.CellSize
                + direction.dy * MC.CellSize * 0.5
            local baseZ = segment[3] * MC.LevelHeight
            local angle = Angle(0, direction.yaw, 0)
            local quadrant = quadrantForSegment(segment, direction)
            local code = tostring(segment[3] + 1) .. QUADRANT_LETTERS[quadrant]
            local sectionColor = Wall.sectionColors[segment[3]]
                and Wall.sectionColors[segment[3]][quadrant]
                or SECTION_PALETTE[quadrant]

            for stack = 0, stackCount - 1 do
                local instance = {
                    pos = origin + Vector(
                        baseX,
                        baseY,
                        baseZ + GC.ContainerHeight * 0.5
                            + stack * (GC.ContainerHeight + STACK_VISUAL_GAP)
                            - CONTAINER_VISUAL_EMBED
                    ),
                    ang = angle,
                    gridX = segment[1],
                    gridY = segment[2],
                    floor = segment[3],
                    quadrant = quadrant,
                    code = code,
                    sectionColor = sectionColor,
                    stackIndex = stack,
                    stackCount = stackCount,
                    fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true,
                    overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil,
                    overlayEndpointA = faceInfo and faceInfo.endpointA or nil,
                    overlayEndpointB = faceInfo and faceInfo.endpointB or nil,
                    overlayOrientation = faceInfo and faceInfo.orientation or nil
                }
                out[#out + 1] = instance
                addLabelBucket(#out, instance)
            end
        end
    end

    local expectedVisuals = #(Wall.logical or {}) * 2
    if #out ~= expectedVisuals then
        ErrorNoHalt(string.format("[LOD] two-container visual invariant failed: expected=%d actual=%d\n", expectedVisuals, #out))
    end

    Wall.world = out
    Wall.lastOrigin = Vector(origin.x, origin.y, origin.z)
    Wall.dirty = false
    Wall.nextModel = 1
    resetRetries()
    return true
end

local function spawnModel(instance)
    local model = ClientsideModel(GC.ContainerModel, RENDERGROUP_OPAQUE)
    if not IsValid(model) then return nil end

    -- Keep construction invisible until the transform is complete. Authoritative
    -- collision remains the merged server wall boxes; these client models are
    -- presentation only.
    model:SetNoDraw(true)
    model:SetPos(instance.pos)
    model:SetAngles(instance.ang)
    model:SetSkin(GC.Skin or 0)
    model:SetMaterial(CONTAINER_BODY_MATERIAL)
    model:SetColor(CONTAINER_BODY_COLOR)
    model:DrawShadow(false)

    -- Cache the actual mounted model bounds once so the stencil can sit on the
    -- corrugated side panel without assuming where this model's origin lives.
    local mins, maxs = model:GetRenderBounds()
    instance.labelCenterX = (mins.x + maxs.x) * 0.5
    instance.labelPositiveY = maxs.y + LABEL_SURFACE_OFFSET
    instance.labelNegativeY = mins.y - LABEL_SURFACE_OFFSET
    instance.labelCenterZ = mins.z + (maxs.z - mins.z) * 0.57

    model:SetNoDraw(false)
    return model
end

local function queueRetry(index)
    if Wall.retryAttempts[index] then return end
    Wall.retryAttempts[index] = 0
    Wall.retryQueue[#Wall.retryQueue + 1] = index
end

local function buildModelBatch()
    rebuildWorldCache()
    local total = #(Wall.world or {})
    local first = Wall.nextModel or 1
    if first > total then return end

    local last = math.min(total, first + MODEL_BATCH_SIZE - 1)
    for index = first, last do
        local model = spawnModel(Wall.world[index])
        Wall.models[index] = model
        if not IsValid(model) then queueRetry(index) end
    end
    Wall.nextModel = last + 1
end

local function retryFailedModels()
    if (Wall.nextModel or 1) <= #(Wall.world or {}) then return end
    if not Wall.retryQueue or #Wall.retryQueue == 0 then return end

    local processed = 0
    while processed < RETRY_BATCH_SIZE and #Wall.retryQueue > 0 do
        local index = table.remove(Wall.retryQueue, 1)
        local instance = Wall.world and Wall.world[index]
        if instance and not IsValid(Wall.models[index]) then
            local model = spawnModel(instance)
            Wall.models[index] = model
            if not IsValid(model) then
                local attempts = (Wall.retryAttempts[index] or 0) + 1
                Wall.retryAttempts[index] = attempts
                if attempts < MODEL_RETRY_LIMIT then
                    Wall.retryQueue[#Wall.retryQueue + 1] = index
                else
                    Wall.failedModels = (Wall.failedModels or 0) + 1
                    ErrorNoHalt(string.format(
                        "[LOD] client wall model failed after %d retries: index=%d\n",
                        MODEL_RETRY_LIMIT, index
                    ))
                end
            else
                Wall.retryAttempts[index] = nil
            end
        else
            Wall.retryAttempts[index] = nil
        end
        processed = processed + 1
    end
end

hook.Add("Think", "LOD_BuildProceduralContainerWalls", function()
    if not Wall.logical or #Wall.logical == 0 then return end
    buildModelBatch()
    retryFailedModels()
end)

local function gridPosition(pos)
    local origin = Wall.origin or MC.Origin or vector_origin
    local gx = math.floor(((pos.x - origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local gy = math.floor(((pos.y - origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local gz = math.floor(((pos.z - origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(gx, 1, MC.Width), math.Clamp(gy, 1, MC.Height), math.Clamp(gz, 0, 7)
end

local function drawSprayStencil(model, instance, eyePos)
    if not instance.labelCenterX or not instance.sectionColor then return end

    local right = model:GetRight()
    local toEye = eyePos - model:GetPos()
    local side = right:Dot(toEye) >= 0 and 1 or -1
    local localY = side > 0 and instance.labelPositiveY or instance.labelNegativeY
    local labelPos = model:LocalToWorld(Vector(instance.labelCenterX, localY, instance.labelCenterZ))

    local ang = model:GetAngles()
    ang = Angle(ang.p, ang.y, ang.r)
    ang:RotateAroundAxis(ang:Forward(), side > 0 and 90 or -90)
    if side < 0 then
        -- Keep the reverse side readable rather than mirrored/upside-down.
        ang:RotateAroundAxis(ang:Up(), 180)
    end

    local c = instance.sectionColor
    cam.Start3D2D(labelPos, ang, LABEL_SCALE)
        -- A restrained, slightly ragged color field reads as a sprayed/stencilled
        -- location mark rather than a modern sign panel. The alphanumeric code is
        -- always foregrounded so hue is never required for identification.
        surface.SetDrawColor(c.r, c.g, c.b, 34)
        surface.DrawRect(-150, -72, 300, 144)
        surface.SetDrawColor(c.r, c.g, c.b, 62)
        surface.DrawRect(-142, -78, 284, 8)
        surface.DrawRect(-136, 70, 272, 7)
        surface.DrawRect(-148, 62, 20, 4)
        surface.DrawRect(130, -66, 17, 4)

        draw.SimpleText(instance.code, "LOD_ContainerStencil", 3, 4,
            Color(20, 22, 23, 185), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(instance.code, "LOD_ContainerStencil", 0, 0,
            Color(c.r, c.g, c.b, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding", function()
    if not Wall.world or #Wall.world == 0 then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local eyePos = EyePos()
    local gx, gy, gz = gridPosition(eyePos)
    local floorBuckets = Wall.labelBuckets and Wall.labelBuckets[gz]
    if not floorBuckets then return end

    local bucketWorld = LABEL_BUCKET_CELLS * MC.CellSize
    local bucketRadius = math.ceil(LABEL_MAX_DISTANCE / bucketWorld) + 1
    local centerBX, centerBY = labelBucketKey(gx, gy)

    for bx = centerBX - bucketRadius, centerBX + bucketRadius do
        for by = centerBY - bucketRadius, centerBY + bucketRadius do
            local bucket = floorBuckets[tostring(bx) .. ":" .. tostring(by)]
            if bucket then
                for _, index in ipairs(bucket) do
                    local model = Wall.models[index]
                    local instance = Wall.world[index]
                    if IsValid(model) and instance
                        and eyePos:DistToSqr(model:GetPos()) <= LABEL_MAX_DISTANCE_SQR
                    then
                        drawSprayStencil(model, instance, eyePos)
                    end
                end
            end
        end
    end
end)

hook.Add("ShutDown", "LOD_WallVisualsClientCleanup", removeModels)

concommand.Add("lod_wall_visuals_status", function()
    rebuildWorldCache()
    local active = 0
    for _, model in pairs(Wall.models or {}) do
        if IsValid(model) then active = active + 1 end
    end
    local total = #(Wall.world or {})
    local palette = {}
    for quadrant = 1, 4 do
        local c = Wall.sectionColors[0] and Wall.sectionColors[0][quadrant]
        palette[#palette + 1] = c and string.format("%s=%d,%d,%d",
            QUADRANT_LETTERS[quadrant], c.r, c.g, c.b) or (QUADRANT_LETTERS[quadrant] .. "=?")
    end
    print(string.format(
        "[LOD:WALL-VISUALS] logical=%d instances=%d clientModels=%d pending=%d retryQueued=%d hardFailed=%d originZ=%.2f seed=%s floor1={%s}",
        #(Wall.logical or {}), total, active, math.max(0, total - active),
        #(Wall.retryQueue or {}), Wall.failedModels or 0,
        (Wall.origin or MC.Origin or vector_origin).z,
        tostring(Wall.seed or 0), table.concat(palette, " ")
    ))
end)
