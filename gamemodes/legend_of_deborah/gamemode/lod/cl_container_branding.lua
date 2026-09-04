LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Presentation-only company decals. cl_container_section_recolor.lua remains the
-- authority for floor/quadrant hull color, while cl_container_marking_panel.lua
-- remains the authority for sparse plywood wayfinding plates.
local DRAW_DISTANCE = 1550
local DRAW_DISTANCE_SQR = DRAW_DISTANCE * DRAW_DISTANCE
local BUCKET_CELLS = 4
local PANEL_SCALE = 0.22
local SURFACE_OFFSET = 2.1
local LOGO_Y_FRACTION = 0.69
local LOGO_Z_FRACTION = 0.58

local BRAND_COUNT = 256
local BRANDS_PER_ATLAS = 64
local ATLAS_COLUMNS = 8
local ATLAS_ROWS = 8
local BRAND_WIDTH = 470
local BRAND_HEIGHT = 235
local PATCH_WIDTH = 520
local PATCH_HEIGHT = 255
local PATCH_EDGE = 7
local U_INSET = 0.0004
local V_INSET = 0.0007

local selectedSeed
local selectedId
local selectedAtlas
local selectedMaterial
local selectedPath
local u0, v0, u1, v1 = 0, 0, 1, 1

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
    local column = cell % ATLAS_COLUMNS
    local row = math.floor(cell / ATLAS_COLUMNS)
    u0 = column / ATLAS_COLUMNS + U_INSET
    v0 = row / ATLAS_ROWS + V_INSET
    u1 = (column + 1) / ATLAS_COLUMNS - U_INSET
    v1 = (row + 1) / ATLAS_ROWS - V_INSET

    selectedPath = string.format(
        "legend_of_deborah/container_brands/container_brand_atlas_%02d.png",
        selectedAtlas
    )
    selectedMaterial = Material(selectedPath, "smooth")
    return selectedMaterial and not selectedMaterial:IsError()
end

local function patchColors(instance)
    local c = instance.bodyColor or instance.sectionColor or Color(110, 110, 110, 255)
    local fill = Color(
        math.Clamp(math.floor(c.r * 0.52 + 18), 0, 255),
        math.Clamp(math.floor(c.g * 0.52 + 18), 0, 255),
        math.Clamp(math.floor(c.b * 0.52 + 18), 0, 255),
        255
    )
    local edge = Color(
        math.Clamp(math.floor(fill.r * 0.58), 0, 255),
        math.Clamp(math.floor(fill.g * 0.58), 0, 255),
        math.Clamp(math.floor(fill.b * 0.58), 0, 255),
        255
    )
    return fill, edge
end

local function sideTransform(model, eyePos)
    local mins, maxs = model:GetRenderBounds()
    local side = model:GetForward():Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + SURFACE_OFFSET) or (mins.x - SURFACE_OFFSET)
    local yFraction = side > 0 and LOGO_Y_FRACTION or (1 - LOGO_Y_FRACTION)
    local localY = mins.y + (maxs.y - mins.y) * yFraction
    local localZ = mins.z + (maxs.z - mins.z) * LOGO_Z_FRACTION
    local pos = model:LocalToWorld(Vector(localX, localY, localZ))

    local ang = model:GetAngles()
    ang = Angle(ang.p, ang.y, ang.r)
    ang:RotateAroundAxis(ang:Right(), side > 0 and -90 or 90)
    ang:RotateAroundAxis(ang:Up(), 90)
    if side < 0 then ang:RotateAroundAxis(ang:Up(), 180) end
    return pos, ang
end

local function drawBrand(model, instance, eyePos)
    if not ensureSelection() then return end
    local pos, ang = sideTransform(model, eyePos)
    local fill, edge = patchColors(instance)

    cam.Start3D2D(pos, ang, PANEL_SCALE)
        -- Opaque same-hue repaint fully masks the baked Northern Petrol mark without
        -- changing the authoritative hull color used for navigation.
        surface.SetDrawColor(edge)
        surface.DrawRect(
            -PATCH_WIDTH * 0.5 - PATCH_EDGE,
            -PATCH_HEIGHT * 0.5 - PATCH_EDGE,
            PATCH_WIDTH + PATCH_EDGE * 2,
            PATCH_HEIGHT + PATCH_EDGE * 2
        )
        surface.SetDrawColor(fill)
        surface.DrawRect(-PATCH_WIDTH * 0.5, -PATCH_HEIGHT * 0.5, PATCH_WIDTH, PATCH_HEIGHT)
        surface.SetDrawColor(edge.r, edge.g, edge.b, 185)
        surface.DrawRect(-PATCH_WIDTH * 0.5, -PATCH_HEIGHT * 0.5, PATCH_WIDTH, 4)
        surface.DrawRect(-PATCH_WIDTH * 0.5, PATCH_HEIGHT * 0.5 - 4, PATCH_WIDTH, 4)

        surface.SetMaterial(selectedMaterial)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectUV(
            -BRAND_WIDTH * 0.5, -BRAND_HEIGHT * 0.5,
            BRAND_WIDTH, BRAND_HEIGHT,
            u0, v0, u1, v1
        )
    cam.End3D2D()
end

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
                    -- Wayfinding plates deliberately supersede company branding.
                    if instance and not instance.marked and IsValid(model)
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
    local ok = ensureSelection()
    print(string.format(
        "[LOD] container brand: seed=%s brand=%s atlas=%s material=%s path=%s uv=%.4f,%.4f..%.4f,%.4f",
        tostring(Wall.seed or 0),
        selectedId and string.format("%03d", selectedId) or "none",
        selectedAtlas and string.format("%02d", selectedAtlas) or "none",
        ok and "ok" or "error",
        tostring(selectedPath or "none"),
        u0, v0, u1, v1
    ))
end)
