LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Company identity is presentation-only. cl_container_section_recolor.lua supplies
-- a neutral, stock-UV-compatible cargo diffuse and owns floor/quadrant hull color.
-- This pass adds only the selected company's transparent distressed paint mask as a
-- lit world-space surface decal. Sparse plywood wayfinding plates remain authoritative
-- on marked containers and therefore suppress company paint there.
local DRAW_DISTANCE = 1450
local DRAW_DISTANCE_SQR = DRAW_DISTANCE * DRAW_DISTANCE
local BUCKET_CELLS = 4
local SURFACE_OFFSET = 0.90
local LOGO_Y_FRACTION = 0.69
local LOGO_Z_FRACTION = 0.58

local BRAND_COUNT = 256
local BRANDS_PER_ATLAS = 64
local ATLAS_COLUMNS = 8
local ATLAS_ROWS = 8
local CELL_U = 1 / ATLAS_COLUMNS
local CELL_V = 1 / ATLAS_ROWS
local UV_INSET = 0.00055

local selectedSeed
local selectedId
local selectedAtlas
local selectedMaterial
local selectedPath
local materialCache = {}

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

local function materialForBrand(brandId, atlasIndex, column, row)
    local cached = materialCache[brandId]
    if cached then return cached end

    local path = string.format(
        "legend_of_deborah/container_surfaces/container_brand_spray_atlas_%02d.png",
        atlasIndex
    )

    -- Do not request generated mipmaps for the company mask. The previous tiny-cell
    -- pipeline became unreadable chiefly because the already-small 128x64 cells were
    -- filtered down again at ordinary play distances. V3 cells are 256x128 and stay
    -- crisp while bilinear filtering still softens the stencil edge.
    local atlas = Material(path, "vertexlitgeneric smooth nocull")
    if not atlas or atlas:IsError() then return nil, path end

    local texture = atlas:GetTexture("$basetexture")
    if not texture then return nil, path end

    local scaleU = CELL_U - UV_INSET * 2
    local scaleV = CELL_V - UV_INSET * 2
    local translateU = column * CELL_U + UV_INSET
    local translateV = row * CELL_V + UV_INSET
    local transform = string.format(
        "center 0 0 scale %.6f %.6f rotate 0 translate %.6f %.6f",
        scaleU, scaleV, translateU, translateV
    )

    local name = string.format("lod_container_spray_brand_%03d_v3", brandId)
    local material = CreateMaterial(name, "VertexLitGeneric", {
        ["$basetexture"] = texture:GetName(),
        ["$basetexturetransform"] = transform,
        ["$model"] = "1",
        ["$translucent"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
        ["$nocull"] = "1",
        ["$halflambert"] = "1"
    })

    if not material or material:IsError() then return nil, path end
    materialCache[brandId] = material
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
    local column = cell % ATLAS_COLUMNS
    local row = math.floor(cell / ATLAS_COLUMNS)
    selectedMaterial, selectedPath = materialForBrand(
        selectedId, selectedAtlas, column, row
    )
    return selectedMaterial and not selectedMaterial:IsError()
end

local function sprayPaintColor(instance)
    local c = instance.bodyColor or instance.sectionColor or Color(110, 110, 110, 255)
    local luminance = (c.r or 0) * 0.2126 + (c.g or 0) * 0.7152 + (c.b or 0) * 0.0722
    if luminance < 148 then
        return Color(242, 239, 224, 244)
    end
    return Color(28, 28, 27, 235)
end

local function drawBrand(model, instance, eyePos)
    if not ensureSelection() then return end

    local mins, maxs = model:GetRenderBounds()
    local spanY = maxs.y - mins.y
    local spanZ = maxs.z - mins.z
    local side = model:GetForward():Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + SURFACE_OFFSET) or (mins.x - SURFACE_OFFSET)
    local yFraction = side > 0 and LOGO_Y_FRACTION or (1 - LOGO_Y_FRACTION)
    local localY = mins.y + spanY * yFraction
    local localZ = mins.z + spanZ * LOGO_Z_FRACTION
    local center = model:LocalToWorld(Vector(localX, localY, localZ))

    -- The real 3D quad participates in scene lighting and has no opaque background.
    -- It sits close to the broad metal face and reads as stencil/spray paint rather
    -- than the superseded rectangular 3D2D plaque. Mirror the reverse face so text
    -- remains readable from either side of a container wall.
    local horizontal = model:GetRight()
    if side < 0 then horizontal = -horizontal end
    local up = model:GetUp()

    -- V3 uses more of the broad side. The authored company name is the primary read;
    -- fine ISO/tagline copy may naturally disappear at distance, as real stencil copy
    -- would, but the logo and company name should remain recognizable.
    local width = math.Clamp(spanY * 0.62, 120, 150)
    local height = math.min(spanZ * 0.50, width * 0.5)
    local halfW = width * 0.5
    local halfH = height * 0.5

    local v1 = center - horizontal * halfW + up * halfH
    local v2 = center + horizontal * halfW + up * halfH
    local v3 = center + horizontal * halfW - up * halfH
    local v4 = center - horizontal * halfW - up * halfH

    render.SetMaterial(selectedMaterial)
    render.DrawQuad(v1, v2, v3, v4, sprayPaintColor(instance))
end

hook.Remove("PostDrawOpaqueRenderables", "LOD_DrawContainerBranding")
hook.Remove("PostDrawTranslucentRenderables", "LOD_DrawContainerBranding")
hook.Add("PostDrawTranslucentRenderables", "LOD_DrawContainerBranding", function()
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
        "[LOD] container brand: seed=%s brand=%s atlas=%s material=%s path=%s mode=vertexlit-spray-v3-hires",
        tostring(Wall.seed or 0),
        selectedId and string.format("%03d", selectedId) or "none",
        selectedAtlas and string.format("%02d", selectedAtlas) or "none",
        ok and "ok" or "error",
        tostring(selectedPath or "none")
    ))
end)
