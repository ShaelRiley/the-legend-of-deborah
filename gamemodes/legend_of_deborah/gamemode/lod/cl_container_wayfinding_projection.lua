LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
if not Wall or not MC then return end

-- Presentation-only quadrant pass. The validated cargo-container mesh, wall
-- manifest, merged collision, maze graph, stairs, gates, and Motion V2 remain
-- untouched. We replace debugwhite with a stock unbranded industrial metal
-- material so the container keeps visible surface texture, then tint that texture
-- by section. Wayfinding marks are drawn as dependency-free industrial stencil
-- glyphs so Linux/Steam Deck font substitution cannot change their appearance.
local CONTAINER_TEXTURE_MATERIAL = "models/props_c17/FurnitureMetal001a"
local LABEL_MAX_DISTANCE = 1650
local LABEL_MAX_DISTANCE_SQR = LABEL_MAX_DISTANCE * LABEL_MAX_DISTANCE
local LABEL_BUCKET_CELLS = 4
local LABEL_SCALE = 0.25
local LABEL_SURFACE_OFFSET = 1.6
local APPEARANCE_BATCH_SIZE = 128

-- Neutral painted-metal base. Section hue is mixed into this rather than flooding
-- the model, preserving the stock material's grain/wear and the cargo mesh's
-- corrugation. These are intentionally muted industrial colors, not gate colors.
local BASE_PAINT = Color(224, 225, 218, 255)
local BODY_SECTION_MIX = 0.52

local function clamp255(value)
    return math.Clamp(math.floor(value + 0.5), 0, 255)
end

local function sectionBodyColor(c)
    if not c then return BASE_PAINT end
    local inv = 1 - BODY_SECTION_MIX
    return Color(
        clamp255(BASE_PAINT.r * inv + c.r * BODY_SECTION_MIX),
        clamp255(BASE_PAINT.g * inv + c.g * BODY_SECTION_MIX),
        clamp255(BASE_PAINT.b * inv + c.b * BODY_SECTION_MIX),
        255
    )
end

local function rgbToHSV(c)
    local r, g, b = c.r / 255, c.g / 255, c.b / 255
    local maximum = math.max(r, g, b)
    local minimum = math.min(r, g, b)
    local delta = maximum - minimum
    local h = 0

    if delta > 0.00001 then
        if maximum == r then
            h = 60 * (((g - b) / delta) % 6)
        elseif maximum == g then
            h = 60 * (((b - r) / delta) + 2)
        else
            h = 60 * (((r - g) / delta) + 4)
        end
    end
    if h < 0 then h = h + 360 end

    local s = maximum <= 0 and 0 or delta / maximum
    return h, s, maximum
end

local function hsvToColor(h, s, v)
    h = h % 360
    s = math.Clamp(s, 0, 1)
    v = math.Clamp(v, 0, 1)

    local c = v * s
    local x = c * (1 - math.abs(((h / 60) % 2) - 1))
    local m = v - c
    local r, g, b = 0, 0, 0

    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end

    return Color(
        clamp255((r + m) * 255),
        clamp255((g + m) * 255),
        clamp255((b + m) * 255),
        255
    )
end

local function relativeLuma(c)
    return c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
end

local function complementaryStencilColor(body)
    local h = rgbToHSV(body)
    local opposite = (h + 180) % 360

    -- Body tints are deliberately light. Use a saturated opposite hue and choose
    -- brightness from measured body luma, preserving both true complementary hue
    -- and readable contrast at several corridor cells of distance.
    local value = relativeLuma(body) >= 188 and 0.42 or 0.94
    return hsvToColor(opposite, 0.90, value)
end

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

-- Apply material+tint once after the existing bounded wall-model build completes.
-- The models table is replaced for each level, automatically re-arming the pass.
local appearanceModelsRef = nil
local appearanceCursor = 1
local appearanceComplete = false

hook.Remove("Think", "LOD_ApplyContainerSectionColors")
hook.Add("Think", "LOD_ApplyContainerSectionColors", function()
    local models = Wall.models or {}
    local world = Wall.world or {}

    if models ~= appearanceModelsRef then
        appearanceModelsRef = models
        appearanceCursor = 1
        appearanceComplete = false
    end
    if appearanceComplete or #world == 0 then return end

    -- Let the validated renderer finish construction/retries first. The complete
    -- appearance pass is then amortized across small batches and becomes idle.
    if (Wall.nextModel or 1) <= #world then return end
    if Wall.retryQueue and #Wall.retryQueue > 0 then return end

    local last = math.min(#world, appearanceCursor + APPEARANCE_BATCH_SIZE - 1)
    for index = appearanceCursor, last do
        local model = models[index]
        local instance = world[index]
        if IsValid(model) and instance and instance.sectionColor then
            local body = sectionBodyColor(instance.sectionColor)
            instance.bodyColor = body
            instance.stencilColor = complementaryStencilColor(body)
            model:SetMaterial(CONTAINER_TEXTURE_MATERIAL)
            model:SetColor(body)
        end
    end

    appearanceCursor = last + 1
    if appearanceCursor > #world then appearanceComplete = true end
end)

-- A small hard-edged bitmap alphabet produces a consistent stencil language on
-- every platform. Filled cells are separated by narrow paint-free bridges, which
-- gives enclosed glyphs the practical cut-stencil character used for industrial
-- inventory/location marking without relying on a host-installed font.
local GLYPHS = {
    ["1"] = {"00100","01100","00100","00100","00100","00100","01110"},
    ["2"] = {"01110","10001","00001","00010","00100","01000","11111"},
    ["3"] = {"11110","00001","00001","01110","00001","00001","11110"},
    ["4"] = {"00010","00110","01010","10010","11111","00010","00010"},
    ["5"] = {"11111","10000","10000","11110","00001","00001","11110"},
    ["6"] = {"01110","10000","10000","11110","10001","10001","01110"},
    ["7"] = {"11111","00001","00010","00100","01000","01000","01000"},
    ["8"] = {"01110","10001","10001","01110","10001","10001","01110"},
    ["A"] = {"01110","10001","10001","11111","10001","10001","10001"},
    ["B"] = {"11110","10001","10001","11110","10001","10001","11110"},
    ["C"] = {"01111","10000","10000","10000","10000","10000","01111"},
    ["D"] = {"11110","10001","10001","10001","10001","10001","11110"}
}

local STENCIL_CELL = 24
local STENCIL_CELL_INSET = 2
local STENCIL_CHAR_GAP = 18
local STENCIL_ROWS = 7
local STENCIL_COLS = 5

local function glyphWidth()
    return STENCIL_COLS * STENCIL_CELL
end

local function codeWidth(code)
    local count = math.max(1, #code)
    return count * glyphWidth() + (count - 1) * STENCIL_CHAR_GAP
end

local function drawGlyph(pattern, x, y, color, seed)
    if not pattern then return end
    surface.SetDrawColor(color.r, color.g, color.b, color.a or 255)

    for row = 1, STENCIL_ROWS do
        local line = pattern[row]
        for col = 1, STENCIL_COLS do
            if string.sub(line, col, col) == "1" then
                local px = x + (col - 1) * STENCIL_CELL + STENCIL_CELL_INSET
                local py = y + (row - 1) * STENCIL_CELL + STENCIL_CELL_INSET
                local size = STENCIL_CELL - STENCIL_CELL_INSET * 2

                -- Deterministic narrow bridge/cut gaps mimic a reusable metal
                -- stencil and a little paint wear without per-frame randomness.
                if ((row * 11 + col * 7 + seed * 3) % 6) == 0 then
                    local half = math.floor((size - 4) * 0.5)
                    surface.DrawRect(px, py, size, half)
                    surface.DrawRect(px, py + half + 4, size, size - half - 4)
                else
                    surface.DrawRect(px, py, size, size)
                end
            end
        end
    end
end

local function drawStencilCode(code, mainColor)
    code = tostring(code or "?")
    local width = codeWidth(code)
    local startX = -width * 0.5
    local startY = -(STENCIL_ROWS * STENCIL_CELL) * 0.5

    -- A tiny dark underprint is plausible on weathered steel and dramatically
    -- improves long-range silhouette without replacing the complementary paint.
    local shadow = Color(12, 14, 15, 190)
    for index = 1, #code do
        local ch = string.sub(code, index, index)
        local pattern = GLYPHS[ch]
        local x = startX + (index - 1) * (glyphWidth() + STENCIL_CHAR_GAP)
        drawGlyph(pattern, x + 4, startY + 4, shadow, index + #code)
    end

    for index = 1, #code do
        local ch = string.sub(code, index, index)
        local pattern = GLYPHS[ch]
        local x = startX + (index - 1) * (glyphWidth() + STENCIL_CHAR_GAP)
        drawGlyph(pattern, x, startY, mainColor, index)
    end

    -- Sparse registration bars make the mark read as a deliberately applied
    -- industrial location stencil, not floating HUD text or graffiti.
    surface.SetDrawColor(mainColor.r, mainColor.g, mainColor.b, 210)
    surface.DrawRect(startX, startY - 16, math.floor(width * 0.34), 5)
    surface.DrawRect(startX + math.floor(width * 0.66), startY - 16,
        math.ceil(width * 0.34), 5)
    surface.DrawRect(startX, startY + STENCIL_ROWS * STENCIL_CELL + 11,
        math.floor(width * 0.22), 4)
end

local function drawIndustrialStencil(model, instance, eyePos)
    if not IsValid(model) or not instance or not instance.sectionColor then return end

    local mins, maxs = model:GetRenderBounds()
    local centerY = (mins.y + maxs.y) * 0.5
    -- Upper-middle placement mirrors real industrial identification marks: clear
    -- of the floor grime band, readable above nearby clutter, and consistent on
    -- every container rather than scattered like graffiti.
    local centerZ = mins.z + (maxs.z - mins.z) * 0.66

    -- cargo_container01's broad side-panel normal is local X / model Forward.
    local forward = model:GetForward()
    local side = forward:Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + LABEL_SURFACE_OFFSET)
        or (mins.x - LABEL_SURFACE_OFFSET)
    local labelPos = model:LocalToWorld(Vector(localX, centerY, centerZ))

    -- Lay the 3D2D plane onto the broad vertical panel, then rotate its baseline
    -- horizontal. The reverse-face correction prevents mirroring.
    local ang = model:GetAngles()
    ang = Angle(ang.p, ang.y, ang.r)
    ang:RotateAroundAxis(ang:Right(), side > 0 and -90 or 90)
    ang:RotateAroundAxis(ang:Up(), 90)
    if side < 0 then ang:RotateAroundAxis(ang:Up(), 180) end

    local body = instance.bodyColor or sectionBodyColor(instance.sectionColor)
    local stencil = instance.stencilColor or complementaryStencilColor(body)

    cam.Start3D2D(labelPos, ang, LABEL_SCALE)
        drawStencilCode(instance.code or "?", stencil)
    cam.End3D2D()
end

-- Replace the original generic text projection installed by cl_wall_visuals.lua.
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
                        drawIndustrialStencil(model, instance, eyePos)
                    end
                end
            end
        end
    end
end)
