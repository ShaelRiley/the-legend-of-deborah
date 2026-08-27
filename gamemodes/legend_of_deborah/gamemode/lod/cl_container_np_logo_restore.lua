LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- The stock cargo diffuse does not contain an NP-specific tint mask. Rather than
-- flattening the whole texture to force one, retain the proven full-albedo section
-- shader and redraw the Northern Petrol identity at the original side-branding zone
-- on unmarked containers only. Marked containers intentionally cover that zone with
-- their plywood floor/quadrant board, so the two presentation systems never overlap.
--
-- This is a nearby-only 3D2D pass over the already bucketed wall manifest: no extra
-- ClientsideModels, no networking, no collision changes, and no work for distant
-- containers where the baked logo remains sufficient visual texture.
local LOGO_MAX_DISTANCE = 1050
local LOGO_MAX_DISTANCE_SQR = LOGO_MAX_DISTANCE * LOGO_MAX_DISTANCE
local LOGO_BUCKET_CELLS = 4
local LOGO_SCALE = 0.16
local LOGO_SURFACE_OFFSET = 2.0
local LOGO_Y_FRACTION = 0.72
local LOGO_Z_FRACTION = 0.59

local NP_GREEN = Color(126, 174, 111, 238)
local NP_GREEN_DARK = Color(45, 72, 42, 205)
local NP_TEXT = Color(22, 27, 22, 225)

surface.CreateFont("LOD_NPLogoLarge", {
    font = "Roboto Condensed",
    size = 118,
    weight = 1000,
    italic = true,
    antialias = true,
    extended = false
})

surface.CreateFont("LOD_NPLogoSmall", {
    font = "Roboto Condensed",
    size = 30,
    weight = 700,
    italic = true,
    antialias = true,
    extended = false
})

local function labelBucketKey(x, y)
    local bx = math.floor((x - 1) / LOGO_BUCKET_CELLS)
    local by = math.floor((y - 1) / LOGO_BUCKET_CELLS)
    return bx, by
end

local function gridPosition(pos)
    local origin = Wall.origin or MC.Origin or vector_origin
    local gx = math.floor(((pos.x - origin.x) / MC.CellSize) + ((MC.Width + 1) * 0.5) + 0.5)
    local gy = math.floor(((pos.y - origin.y) / MC.CellSize) + ((MC.Height + 1) * 0.5) + 0.5)
    local gz = math.floor(((pos.z - origin.z) / MC.LevelHeight) + 0.5)
    return math.Clamp(gx, 1, MC.Width), math.Clamp(gy, 1, MC.Height), math.Clamp(gz, 0, 7)
end

local function drawRestoredNP(model, instance, eyePos)
    if not IsValid(model) or not instance or instance.marked then return end

    local mins, maxs = model:GetRenderBounds()
    local spanY = maxs.y - mins.y
    local spanZ = maxs.z - mins.z

    -- Broad side normal is local X / model Forward. Use the corridor-facing face,
    -- but keep a fixed +Y branding position so the mark feels printed on the prop,
    -- not camera-centered UI.
    local forward = model:GetForward()
    local side = forward:Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + LOGO_SURFACE_OFFSET)
        or (mins.x - LOGO_SURFACE_OFFSET)
    local localY = mins.y + spanY * LOGO_Y_FRACTION
    local localZ = mins.z + spanZ * LOGO_Z_FRACTION
    local logoPos = model:LocalToWorld(Vector(localX, localY, localZ))

    local ang = model:GetAngles()
    ang = Angle(ang.p, ang.y, ang.r)
    ang:RotateAroundAxis(ang:Right(), side > 0 and -90 or 90)
    ang:RotateAroundAxis(ang:Up(), 90)
    if side < 0 then ang:RotateAroundAxis(ang:Up(), 180) end

    cam.Start3D2D(logoPos, ang, LOGO_SCALE)
        -- A dark offset underprint hides most of the procedurally tinted baked logo
        -- beneath this registration pass, then the original-style green/black mark
        -- is redrawn crisply enough to read down a corridor.
        draw.SimpleText("NP", "LOD_NPLogoLarge", 4, 5,
            NP_GREEN_DARK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("NP", "LOD_NPLogoLarge", 0, 0,
            NP_GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText("Northern Petrol", "LOD_NPLogoSmall", 2, 57,
            Color(0, 0, 0, 135), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Northern Petrol", "LOD_NPLogoSmall", 0, 55,
            NP_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

hook.Add("PostDrawOpaqueRenderables", "LOD_RestoreContainerNPBranding", function()
    local world = Wall.world or {}
    if #world == 0 then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local eyePos = EyePos()
    local gx, gy, gz = gridPosition(eyePos)
    local floorBuckets = Wall.labelBuckets and Wall.labelBuckets[gz]
    if not floorBuckets then return end

    local bucketWorld = LOGO_BUCKET_CELLS * MC.CellSize
    local bucketRadius = math.ceil(LOGO_MAX_DISTANCE / bucketWorld) + 1
    local centerBX, centerBY = labelBucketKey(gx, gy)

    for bx = centerBX - bucketRadius, centerBX + bucketRadius do
        for by = centerBY - bucketRadius, centerBY + bucketRadius do
            local bucket = floorBuckets[tostring(bx) .. ":" .. tostring(by)]
            if bucket then
                for _, index in ipairs(bucket) do
                    local instance = world[index]
                    local model = Wall.models and Wall.models[index]
                    if instance and not instance.marked and IsValid(model)
                        and eyePos:DistToSqr(model:GetPos()) <= LOGO_MAX_DISTANCE_SQR
                    then
                        drawRestoredNP(model, instance, eyePos)
                    end
                end
            end
        end
    end
end)

concommand.Add("lod_container_logo_restore_status", function()
    local nearby = 0
    local eligible = 0
    local eyePos = IsValid(LocalPlayer()) and EyePos() or vector_origin
    for index, instance in ipairs(Wall.world or {}) do
        if not instance.marked then
            eligible = eligible + 1
            local model = Wall.models and Wall.models[index]
            if IsValid(model) and eyePos:DistToSqr(model:GetPos()) <= LOGO_MAX_DISTANCE_SQR then
                nearby = nearby + 1
            end
        end
    end
    print(string.format(
        "[LOD:NP-LOGO-RESTORE] eligible=%d nearbyDrawCandidates=%d maxDistance=%d",
        eligible, nearby, LOGO_MAX_DISTANCE
    ))
end)
