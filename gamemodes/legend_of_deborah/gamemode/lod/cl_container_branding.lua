LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Company identity is presentation-only. cl_container_section_recolor.lua owns the
-- gritty neutral hull and procedural section hue. This pass adds one true-RGBA,
-- vertex-lit company stencil over most of the broad side of each ordinary container.
-- Marked wayfinding containers deliberately suppress company paint.
local DRAW_DISTANCE = 1650
local DRAW_DISTANCE_SQR = DRAW_DISTANCE * DRAW_DISTANCE
local BUCKET_CELLS = 4
local SURFACE_OFFSET = 0.80
local LOGO_Y_FRACTION = 0.50
local LOGO_Z_FRACTION = 0.55
local SIDE_WIDTH_FRACTION = 0.86
local SIDE_HEIGHT_FRACTION = 0.66

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
        string.format("lod_container_spray_atlas_%02d_v7", atlasIndex),
        "VertexLitGeneric",
        {
            -- Start from a guaranteed built-in texture, then bind the mounted PNG's
            -- ITexture directly. Never round-trip texture:GetName() through Source's
            -- VTF resolver: that was the source of the opaque black broad-side card.
            ["$basetexture"] = "vgui/white",
            ["$model"] = "1",
            ["$translucent"] = "1",
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
        "[LOD] container brand: seed=%s brand=%s atlas=%s cell=%s,%s material=%s path=%s mode=vertexlit-spray-v7-rgba-direct width=%.2f height=%.2f",
        tostring(Wall.seed or 0),
        selectedId and string.format("%03d", selectedId) or "none",
        selectedAtlas and string.format("%02d", selectedAtlas) or "none",
        tostring(selectedColumn or "none"),
        tostring(selectedRow or "none"),
        ok and "ok" or "error",
        tostring(selectedPath or "none"),
        SIDE_WIDTH_FRACTION,
        SIDE_HEIGHT_FRACTION
    ))
end)
