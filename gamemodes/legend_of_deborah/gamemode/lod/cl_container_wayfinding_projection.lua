LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Production quadrant presentation correction. The stock cargo-container mesh is
-- still the validated client-only wall model and retains the unbranded material
-- override from cl_wall_visuals.lua. This module owns only presentation: section
-- tint plus readable floor/quadrant stencil projection.

local LABEL_MAX_DISTANCE = 1550
local LABEL_MAX_DISTANCE_SQR = LABEL_MAX_DISTANCE * LABEL_MAX_DISTANCE
local LABEL_BUCKET_CELLS = 4
local LABEL_SCALE = 0.20
local LABEL_SURFACE_OFFSET = 1.5
local TINT_BATCH_SIZE = 128

local function labelBucketKey(x, y)
    local bx = math.floor((x - 1) / LABEL_BUCKET_CELLS)
    local by = math.floor((y - 1) / LABEL_BUCKET_CELLS)
    return bx, by
end

local function gridPosition(pos)
    local origin = Wall.origin or MC.Origin or vector_origin
    local gx = math.floor(((pos.x - origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local gy = math.floor(((pos.y - origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local gz = math.floor(((pos.z - origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(gx, 1, MC.Width), math.Clamp(gy, 1, MC.Height), math.Clamp(gz, 0, 7)
end

local function sectionBodyColor(c)
    -- Keep enough white in the base for the cargo geometry/corrugation to remain
    -- readable, but make quadrant identity unmistakable at corridor distance.
    local mix = 0.78
    local white = 48
    return Color(
        math.Clamp(math.floor(c.r * mix + white + 0.5), 0, 255),
        math.Clamp(math.floor(c.g * mix + white + 0.5), 0, 255),
        math.Clamp(math.floor(c.b * mix + white + 0.5), 0, 255),
        255
    )
end

-- Wait for the existing batched renderer to finish constructing its client models,
-- then tint them once in bounded batches. After completion this hook costs only a
-- table-reference comparison per frame; a new level replaces Wall.models and
-- automatically re-arms the pass.
local tintModelsRef = nil
local tintCursor = 1
local tintComplete = false

hook.Add("Think", "LOD_ApplyContainerSectionColors", function()
    local models = Wall.models or {}
    local world = Wall.world or {}

    if models ~= tintModelsRef then
        tintModelsRef = models
        tintCursor = 1
        tintComplete = false
    end
    if tintComplete or #world == 0 then return end

    -- Do not chase models while the validated wall renderer is still building or
    -- retrying them. This avoids color work fighting the existing construction path.
    if (Wall.nextModel or 1) <= #world then return end
    if Wall.retryQueue and #Wall.retryQueue > 0 then return end

    local last = math.min(#world, tintCursor + TINT_BATCH_SIZE - 1)
    for index = tintCursor, last do
        local model = models[index]
        local instance = world[index]
        if IsValid(model) and instance and instance.sectionColor then
            model:SetColor(sectionBodyColor(instance.sectionColor))
        end
    end

    tintCursor = last + 1
    if tintCursor > #world then tintComplete = true end
end)

local function drawSprayStencil(model, instance, eyePos)
    if not IsValid(model) or not instance or not instance.sectionColor then return end

    local mins, maxs = model:GetRenderBounds()
    local centerY = (mins.y + maxs.y) * 0.5
    local centerZ = mins.z + (maxs.z - mins.z) * 0.57

    -- cargo_container01's broad side-panel normal is local X / model Forward.
    -- Pick the corridor-facing side so only one stencil per stacked container is
    -- rendered from the player's current view.
    local forward = model:GetForward()
    local side = forward:Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + LABEL_SURFACE_OFFSET)
        or (mins.x - LABEL_SURFACE_OFFSET)
    local labelPos = model:LocalToWorld(Vector(localX, centerY, centerZ))

    -- First lay the 3D2D plane onto the broad vertical panel (plane normal becomes
    -- +/- model Forward). The additional 90-degree twist around that panel normal
    -- makes text baseline horizontal; the previous build stopped before this twist,
    -- which is why the screenshot showed vertical "1C" markings.
    local ang = model:GetAngles()
    ang = Angle(ang.p, ang.y, ang.r)
    ang:RotateAroundAxis(ang:Right(), side > 0 and -90 or 90)
    ang:RotateAroundAxis(ang:Up(), 90)
    if side < 0 then
        -- Reverse-face correction keeps the code readable rather than mirrored.
        ang:RotateAroundAxis(ang:Up(), 180)
    end

    local c = instance.sectionColor
    cam.Start3D2D(labelPos, ang, LABEL_SCALE)
        -- Loose rectangular overspray plus a crisp alphanumeric stencil. Color is
        -- redundant reinforcement; the floor/quadrant code remains primary.
        surface.SetDrawColor(c.r, c.g, c.b, 54)
        surface.DrawRect(-150, -72, 300, 144)
        surface.SetDrawColor(c.r, c.g, c.b, 92)
        surface.DrawRect(-142, -78, 284, 8)
        surface.DrawRect(-136, 70, 272, 7)
        surface.DrawRect(-148, 62, 20, 4)
        surface.DrawRect(130, -66, 17, 4)

        draw.SimpleText(instance.code or "?", "LOD_ContainerStencil", 3, 4,
            Color(20, 22, 23, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(instance.code or "?", "LOD_ContainerStencil", 0, 0,
            Color(c.r, c.g, c.b, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

-- Replace the original axis-assumption hook installed by cl_wall_visuals.lua.
hook.Remove("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding")

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
                    local model = Wall.models and Wall.models[index]
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
