LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Projection correction for the production container wayfinding pass.
-- props_wasteland/cargo_container01.mdl is mounted with its long dimension on
-- local Y in LOD's validated wall renderer. Therefore the corridor-facing broad
-- side panels live on local +/-X, not local +/-Y. The first implementation put
-- its 3D2D stencil on the container end caps and it was effectively invisible in
-- normal corridors. Keep the existing white batched models and spatial buckets;
-- replace only the presentation hook that projects the stencil.

local LABEL_MAX_DISTANCE = 1550
local LABEL_MAX_DISTANCE_SQR = LABEL_MAX_DISTANCE * LABEL_MAX_DISTANCE
local LABEL_BUCKET_CELLS = 4
local LABEL_SCALE = 0.20
local LABEL_SURFACE_OFFSET = 1.5

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

local function drawSprayStencil(model, instance, eyePos)
    if not IsValid(model) or not instance or not instance.sectionColor then return end

    local mins, maxs = model:GetRenderBounds()
    local centerY = (mins.y + maxs.y) * 0.5
    local centerZ = mins.z + (maxs.z - mins.z) * 0.57

    -- Broad side-panel normal is local X / model Forward. Pick only the side
    -- facing the player so the same location code is readable from either
    -- corridor without doubling draw work.
    local forward = model:GetForward()
    local side = forward:Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + LABEL_SURFACE_OFFSET)
        or (mins.x - LABEL_SURFACE_OFFSET)
    local labelPos = model:LocalToWorld(Vector(localX, centerY, centerZ))

    -- Start with the model's horizontal plane (normal = Up), then rotate that
    -- normal onto +/-Forward so the 3D2D plane lies flush on the broad side.
    local ang = model:GetAngles()
    ang = Angle(ang.p, ang.y, ang.r)
    ang:RotateAroundAxis(ang:Right(), side > 0 and -90 or 90)
    if side < 0 then
        ang:RotateAroundAxis(ang:Up(), 180)
    end

    local c = instance.sectionColor
    cam.Start3D2D(labelPos, ang, LABEL_SCALE)
        -- Spray/stencil field: deliberately irregular and subordinate to the
        -- alphanumeric code. Color is redundant reinforcement, never the only
        -- location information.
        surface.SetDrawColor(c.r, c.g, c.b, 42)
        surface.DrawRect(-150, -72, 300, 144)
        surface.SetDrawColor(c.r, c.g, c.b, 78)
        surface.DrawRect(-142, -78, 284, 8)
        surface.DrawRect(-136, 70, 272, 7)
        surface.DrawRect(-148, 62, 20, 4)
        surface.DrawRect(130, -66, 17, 4)

        draw.SimpleText(instance.code or "?", "LOD_ContainerStencil", 3, 4,
            Color(20, 22, 23, 205), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(instance.code or "?", "LOD_ContainerStencil", 0, 0,
            Color(c.r, c.g, c.b, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

-- Remove the original axis-assumption hook installed by cl_wall_visuals.lua.
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
