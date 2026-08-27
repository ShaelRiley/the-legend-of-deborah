LOD = LOD or {}

local Wall = LOD.WallVisualsClient
local MC = LOD.Config and LOD.Config.Maze
local GC = LOD.Config and LOD.Config.Geometry
if not Wall or not MC or not GC then return end

-- Presentation-only quadrant pass. Keep the validated stock HL2 cargo-container
-- mesh/material/skin so the Northern Petrol texture, corrugation, grime, seams and
-- normal map all survive. Section identity is applied as a restrained modulation,
-- not a replacement material. Only a sparse balanced subset receives a physical-
-- looking plywood cover panel over the NP side logo plus an industrial stencil.
-- Graph, collision, stairs, gates, minimap and Motion V2 remain untouched.
local LABEL_MAX_DISTANCE = 1800
local LABEL_MAX_DISTANCE_SQR = LABEL_MAX_DISTANCE * LABEL_MAX_DISTANCE
local LABEL_BUCKET_CELLS = 4
local LABEL_SCALE = 0.22
local LABEL_SURFACE_OFFSET = 1.8
local APPEARANCE_BATCH_SIZE = 128
local MARKING_DENSITY = 1 / 6
local MIN_MARKS_PER_SECTION = 3

-- Real freight/offshore-container marking practice favors prominent, contrasting,
-- sparse identification marks rather than centered decorative graphics. This panel
-- sits high and toward the model's +Y/door-end side, which also corresponds closely
-- to the stock NP logo zone on the long face. Its dimensions are large enough to
-- obscure that branding while remaining plausible as a bolted retrofit board.
local PANEL_WIDTH = 440
local PANEL_HEIGHT = 188
local PANEL_Y_FRACTION = 0.72
local PANEL_Z_FRACTION = 0.68
local PANEL_BORDER = 10
local PANEL_COLOR = Color(198, 168, 120, 255)
local PANEL_EDGE = Color(72, 55, 38, 235)
local PANEL_SHADOW = Color(18, 15, 12, 205)
local PANEL_MATERIAL = Material("models/props_c17/FurnitureWood001a")

-- GMod ships Roboto Condensed on every client. DIN 1451 research points toward a
-- low-contrast condensed grotesk/sans for legible technical signage; Roboto
-- Condensed is the dependency-free shipped surrogate. Small bridge cuts applied
-- after drawing convert the glyphs into a reusable-stencil treatment.
surface.CreateFont("LOD_ContainerDINStencil", {
    font = "Roboto Condensed",
    size = 172,
    weight = 900,
    antialias = true,
    extended = false
})

local function clamp255(value)
    return math.Clamp(math.floor(value + 0.5), 0, 255)
end

-- Preserve the original NP red texture. A pale section modulation changes the cast
-- of the painted steel without flattening or replacing its baked texture detail.
local function sectionModelColor(c)
    if not c then return color_white end
    local strength = 0.32
    return Color(
        clamp255(255 - (255 - c.r) * strength),
        clamp255(255 - (255 - c.g) * strength),
        clamp255(255 - (255 - c.b) * strength),
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

local function complementaryStencilColor(bodyTint)
    local h = rgbToHSV(bodyTint)
    local opposite = (h + 180) % 360

    -- Keep the requested true opposite hue, then set value from measured luma so
    -- it remains readable on weathered plywood and against the tinted container.
    local value = relativeLuma(bodyTint) >= 190 and 0.43 or 0.96
    return hsvToColor(opposite, 0.92, value)
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

local function sectionKey(instance)
    return string.format("%d:%d", instance.floor or 0, instance.quadrant or 0)
end

local function sortSectionCandidates(a, b)
    local ia, ib = a.instance, b.instance
    if ia.gridY ~= ib.gridY then return ia.gridY < ib.gridY end
    if ia.gridX ~= ib.gridX then return ia.gridX < ib.gridX end
    if ia.pos.z ~= ib.pos.z then return ia.pos.z < ib.pos.z end
    if ia.pos.x ~= ib.pos.x then return ia.pos.x < ib.pos.x end
    if ia.pos.y ~= ib.pos.y then return ia.pos.y < ib.pos.y end
    return a.index < b.index
end

-- Build an exact-size, deterministic stratified sample. The global target stays at
-- roughly one mark per six visible containers. Counts are first equalized across
-- every populated floor/quadrant section (minimum three where possible), so sparse
-- upper-floor sections remain noticeable instead of losing the random lottery.
-- Within each section, candidates are divided into spatial bins and one index is
-- seeded-randomly chosen from each bin, preventing ugly local clumps.
local selectionWorldRef = nil
local markedCount = 0
local markedBySection = {}

local function rebuildMarkedSelection(world)
    markedCount = 0
    markedBySection = {}

    local byKey = {}
    for index, instance in ipairs(world or {}) do
        instance.marked = false
        if instance.floor ~= nil and instance.quadrant then
            local key = sectionKey(instance)
            local group = byKey[key]
            if not group then
                group = {
                    key = key,
                    floor = instance.floor,
                    quadrant = instance.quadrant,
                    candidates = {}
                }
                byKey[key] = group
            end
            group.candidates[#group.candidates + 1] = {index = index, instance = instance}
        end
    end

    local groups = {}
    local capacity = 0
    for _, group in pairs(byKey) do
        table.sort(group.candidates, sortSectionCandidates)
        groups[#groups + 1] = group
        capacity = capacity + #group.candidates
    end
    table.sort(groups, function(a, b)
        if a.floor ~= b.floor then return a.floor < b.floor end
        return a.quadrant < b.quadrant
    end)

    if #groups == 0 or capacity == 0 then return end

    local desiredTotal = math.floor(capacity * MARKING_DENSITY + 0.5)
    local allocation = {}
    local allocated = 0

    -- Guarantee a visible baseline in every section before distributing the rest.
    for _, group in ipairs(groups) do
        local minimum = math.min(MIN_MARKS_PER_SECTION, #group.candidates)
        allocation[group.key] = minimum
        allocated = allocated + minimum
    end
    desiredTotal = math.min(capacity, math.max(desiredTotal, allocated))

    -- Round-robin allocation keeps populated sections within one mark of each
    -- other until a small section reaches capacity.
    while allocated < desiredTotal do
        local progressed = false
        for _, group in ipairs(groups) do
            local current = allocation[group.key] or 0
            if current < #group.candidates then
                allocation[group.key] = current + 1
                allocated = allocated + 1
                progressed = true
                if allocated >= desiredTotal then break end
            end
        end
        if not progressed then break end
    end

    local seed = tonumber(Wall.seed) or 1
    for _, group in ipairs(groups) do
        local candidates = group.candidates
        local count = math.min(allocation[group.key] or 0, #candidates)
        if count > 0 then
            local rng = LOD.RNG.New(LOD.Seeds.Derive(seed,
                "container-wayfinding-marks:" .. group.key))

            -- Each chosen item comes from its own portion of the spatially sorted
            -- candidate list. Result: random-looking but evenly distributed signs.
            for ordinal = 1, count do
                local first = math.floor((ordinal - 1) * #candidates / count) + 1
                local last = math.floor(ordinal * #candidates / count)
                last = math.max(first, math.min(last, #candidates))
                local chosen = candidates[rng:Int(first, last)]
                if chosen and chosen.instance then
                    chosen.instance.marked = true
                    chosen.instance.markOrdinal = ordinal
                    markedCount = markedCount + 1
                end
            end
        end
        markedBySection[group.key] = count
    end
end

-- Restore the stock Northern Petrol appearance after the existing batched renderer
-- finishes constructing its client models. The old renderer currently starts them
-- with a debug-white override; clearing SetMaterial here returns the model to its
-- original cargo_container01 skin/material, then SetColor supplies a restrained
-- section cast while retaining the NP art and normal-map detail.
local appearanceModelsRef = nil
local appearanceCursor = 1
local appearanceComplete = false

hook.Remove("Think", "LOD_ApplyContainerSectionColors")
hook.Add("Think", "LOD_ApplyContainerSectionColors", function()
    local models = Wall.models or {}
    local world = Wall.world or {}

    if world ~= selectionWorldRef then
        selectionWorldRef = world
        rebuildMarkedSelection(world)
    end

    if models ~= appearanceModelsRef then
        appearanceModelsRef = models
        appearanceCursor = 1
        appearanceComplete = false
    end
    if appearanceComplete or #world == 0 then return end

    if (Wall.nextModel or 1) <= #world then return end
    if Wall.retryQueue and #Wall.retryQueue > 0 then return end

    local last = math.min(#world, appearanceCursor + APPEARANCE_BATCH_SIZE - 1)
    for index = appearanceCursor, last do
        local model = models[index]
        local instance = world[index]
        if IsValid(model) and instance and instance.sectionColor then
            local bodyTint = sectionModelColor(instance.sectionColor)
            instance.bodyColor = bodyTint
            instance.stencilColor = complementaryStencilColor(bodyTint)

            model:SetSkin(GC.Skin or 0)
            model:SetMaterial("")
            model:SetColor(bodyTint)
        end
    end

    appearanceCursor = last + 1
    if appearanceCursor > #world then appearanceComplete = true end
end)

local function drawPlywoodPanel()
    -- Dark edge/shadow gives the 2D plane the visual thickness of a board bolted
    -- over an older logo rather than a floating HUD rectangle.
    surface.SetDrawColor(PANEL_SHADOW)
    surface.DrawRect(-PANEL_WIDTH * 0.5 - PANEL_BORDER,
        -PANEL_HEIGHT * 0.5 - PANEL_BORDER,
        PANEL_WIDTH + PANEL_BORDER * 2,
        PANEL_HEIGHT + PANEL_BORDER * 2)

    if PANEL_MATERIAL and not PANEL_MATERIAL:IsError() then
        surface.SetMaterial(PANEL_MATERIAL)
        surface.SetDrawColor(PANEL_COLOR)
        surface.DrawTexturedRect(-PANEL_WIDTH * 0.5, -PANEL_HEIGHT * 0.5,
            PANEL_WIDTH, PANEL_HEIGHT)
    else
        surface.SetDrawColor(PANEL_COLOR)
        surface.DrawRect(-PANEL_WIDTH * 0.5, -PANEL_HEIGHT * 0.5,
            PANEL_WIDTH, PANEL_HEIGHT)
    end

    -- Rough edge lines and four dark fasteners keep it industrial/field-retrofit.
    surface.SetDrawColor(PANEL_EDGE)
    surface.DrawRect(-PANEL_WIDTH * 0.5, -PANEL_HEIGHT * 0.5, PANEL_WIDTH, 5)
    surface.DrawRect(-PANEL_WIDTH * 0.5, PANEL_HEIGHT * 0.5 - 5, PANEL_WIDTH, 5)
    surface.DrawRect(-PANEL_WIDTH * 0.5, -PANEL_HEIGHT * 0.5, 5, PANEL_HEIGHT)
    surface.DrawRect(PANEL_WIDTH * 0.5 - 5, -PANEL_HEIGHT * 0.5, 5, PANEL_HEIGHT)

    local bolt = 11
    local inset = 22
    for _, x in ipairs({-PANEL_WIDTH * 0.5 + inset, PANEL_WIDTH * 0.5 - inset - bolt}) do
        for _, y in ipairs({-PANEL_HEIGHT * 0.5 + inset, PANEL_HEIGHT * 0.5 - inset - bolt}) do
            surface.DrawRect(x, y, bolt, bolt)
        end
    end
end

local STENCIL_BRIDGE_CHARS = {
    ["A"] = true, ["B"] = true, ["D"] = true,
    ["6"] = true, ["8"] = true
}

local function drawDINStencil(code, color)
    code = tostring(code or "?")
    surface.SetFont("LOD_ContainerDINStencil")
    local totalW, totalH = surface.GetTextSize(code)

    -- Underprint separates complementary paint from variable plywood grain while
    -- keeping the colored stencil itself dominant.
    draw.SimpleText(code, "LOD_ContainerDINStencil", 5, 6,
        Color(18, 18, 17, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(code, "LOD_ContainerDINStencil", 0, 0,
        color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Practical reusable stencils need bridges across enclosed counters. Redraw a
    -- small strip of the board over A/B/D/6/8 so the otherwise modern condensed
    -- sans becomes convincingly cut-stencil lettering without shipping font files.
    local charW = totalW / math.max(1, #code)
    for index = 1, #code do
        local ch = string.sub(code, index, index)
        if STENCIL_BRIDGE_CHARS[ch] then
            local cx = -totalW * 0.5 + (index - 0.5) * charW
            local bridgeW = math.max(8, math.floor(charW * 0.10))
            local bridgeH = math.max(18, math.floor(totalH * 0.16))
            local bridgeX = cx - bridgeW * 0.5
            local bridgeY = -bridgeH * 0.15

            if PANEL_MATERIAL and not PANEL_MATERIAL:IsError() then
                surface.SetMaterial(PANEL_MATERIAL)
                surface.SetDrawColor(PANEL_COLOR)
                surface.DrawTexturedRect(bridgeX, bridgeY, bridgeW, bridgeH)
            else
                surface.SetDrawColor(PANEL_COLOR)
                surface.DrawRect(bridgeX, bridgeY, bridgeW, bridgeH)
            end
        end
    end

    -- Small registration bars are common stencil-shop/maintenance cues and make
    -- the code read as deliberately applied industrial wayfinding rather than UI.
    surface.SetDrawColor(color.r, color.g, color.b, 220)
    surface.DrawRect(-totalW * 0.5, totalH * 0.44, math.floor(totalW * 0.22), 5)
    surface.DrawRect(totalW * 0.28, totalH * 0.44, math.floor(totalW * 0.22), 5)
end

local function drawMarkedContainer(model, instance, eyePos)
    if not instance.marked or not IsValid(model) or not instance.sectionColor then return end

    local mins, maxs = model:GetRenderBounds()
    local spanY = maxs.y - mins.y
    local spanZ = maxs.z - mins.z

    -- Broad side-panel normal is local X / model Forward. Pick the corridor-facing
    -- side but retain the same physical +Y end so the board remains intentionally
    -- off-center instead of following the viewer like centered HUD text.
    local forward = model:GetForward()
    local side = forward:Dot(eyePos - model:GetPos()) >= 0 and 1 or -1
    local localX = side > 0 and (maxs.x + LABEL_SURFACE_OFFSET)
        or (mins.x - LABEL_SURFACE_OFFSET)
    local localY = mins.y + spanY * PANEL_Y_FRACTION
    local localZ = mins.z + spanZ * PANEL_Z_FRACTION
    local panelPos = model:LocalToWorld(Vector(localX, localY, localZ))

    local ang = model:GetAngles()
    ang = Angle(ang.p, ang.y, ang.r)
    ang:RotateAroundAxis(ang:Right(), side > 0 and -90 or 90)
    ang:RotateAroundAxis(ang:Up(), 90)
    if side < 0 then ang:RotateAroundAxis(ang:Up(), 180) end

    local bodyTint = instance.bodyColor or sectionModelColor(instance.sectionColor)
    local stencil = instance.stencilColor or complementaryStencilColor(bodyTint)

    cam.Start3D2D(panelPos, ang, LABEL_SCALE)
        drawPlywoodPanel()
        drawDINStencil(instance.code or "?", stencil)
    cam.End3D2D()
end

-- Replace the original all-container generic text projection. Unmarked containers
-- now remain authentic Northern Petrol props with only their procedural section
-- cast; marked containers get exactly one board/stencil on the currently visible
-- long side.
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
                    if instance and instance.marked and IsValid(model)
                        and eyePos:DistToSqr(model:GetPos()) <= LABEL_MAX_DISTANCE_SQR
                    then
                        drawMarkedContainer(model, instance, eyePos)
                    end
                end
            end
        end
    end
end)

concommand.Add("lod_container_marking_status", function()
    local world = Wall.world or {}
    if world ~= selectionWorldRef then
        selectionWorldRef = world
        rebuildMarkedSelection(world)
    end

    local sections = {}
    for key, count in pairs(markedBySection) do
        sections[#sections + 1] = key .. "=" .. tostring(count)
    end
    table.sort(sections)
    print(string.format(
        "[LOD:CONTAINER-MARKS] total=%d marked=%d ratio=1:%.2f sections={%s}",
        #world, markedCount,
        markedCount > 0 and (#world / markedCount) or 0,
        table.concat(sections, " ")
    ))
end)
