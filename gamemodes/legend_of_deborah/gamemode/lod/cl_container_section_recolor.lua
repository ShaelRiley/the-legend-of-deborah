LOD = LOD or {}

local Wall = LOD.WallVisualsClient
if not Wall then return end

-- Shader-native section recoloring for the UV-agnostic neutral cargo surface.
--
-- The runtime diffuse is uniform and logo-free. VertexLitGeneric color replacement
-- owns the full hull hue while the validated cargo mesh and stock normal map retain relief.
-- Company identity is no longer baked into the diffuse; it is rendered separately
-- as a vertex-lit spray-paint mask on ordinary containers.

--
-- Section colors are generated uniquely for the ACTUAL sections in this maze. The
-- entire hue circle is legal: Red, Yellow and Blue are no longer reserved. A seeded
-- hybrid maximin solver combines CIE Lab perceptual distance with circular hue
-- distance, so every maze uses a broad spectrum rather than several brightness
-- variants of the same few hues. No section color repeats within a generated maze.
-- The diffuse is deliberately UV-agnostic. Mesh geometry plus the stock normal map
-- provide container relief; a uniform white base guarantees that no baked company
-- art, source-image blocks, or checkerboard structure can leak into the hull color.
local NP_BASE_TEXTURE = "vgui/white"
local NP_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"
local COLOR_REPLACE_BLEND = 1.00
local MIN_SECTION_SATURATION = 0.82
local MIN_SECTION_VALUE = 0.80
local RECONCILE_BATCH_SIZE = 192
local MATERIAL_VERSION = "v10_uniform_neutral"
local MAX_FLOORS = 8
local QUADRANTS_PER_FLOOR = 4
local CANDIDATE_HUE_STEP = 5
local HUE_DISTANCE_WEIGHT = 0.22

-- Several high-chroma brightness shells enlarge the usable sRGB volume while
-- retaining enough luminance for Deborah's midnight lighting. Every hue from 0 to
-- 355 degrees is represented; nothing is excluded for progression semantics.
local CANDIDATE_SV = {
    {0.82, 0.80},
    {0.88, 0.90},
    {0.96, 0.98},
    {0.98, 0.82},
    {0.84, 0.98}
}

local materialNames = {}
local reconcileCursor = 1
local reconcileModelsRef = nil
local stablePasses = 0
local reconcileComplete = false
local appliedCount = 0

local paletteSeed = nil
local paletteFloorCount = nil
local sectionPalette = {}
local paletteMinDeltaE = 0
local paletteMinHueDistance = 0

local function clamp01(value)
    return math.Clamp(tonumber(value) or 0, 0, 1)
end

local function colorKey(c)
    return string.format("%03d_%03d_%03d",
        math.Clamp(math.floor(c.r or 0), 0, 255),
        math.Clamp(math.floor(c.g or 0), 0, 255),
        math.Clamp(math.floor(c.b or 0), 0, 255))
end

local function hueDistance(a, b)
    local d = math.abs((a or 0) - (b or 0)) % 360
    return math.min(d, 360 - d)
end

local function vividSectionColor(c)
    local h, s, v = ColorToHSV(Color(c.r or 255, c.g or 255, c.b or 255))
    s = math.Clamp(math.max(s, MIN_SECTION_SATURATION), 0, 1)
    v = math.Clamp(math.max(v, MIN_SECTION_VALUE), 0, 1)
    return HSVToColor(h, s, v)
end

-- CIE Lab is used only while a new level palette is being built. Even the maximum
-- eight-floor case considers only a few hundred candidates once per generated maze.
-- This better approximates human-visible color separation than raw RGB distance.
local function srgbLinear(channel)
    local c = math.Clamp(channel / 255, 0, 1)
    if c <= 0.04045 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end

local function labPivot(t)
    if t > 0.008856 then return t ^ (1 / 3) end
    return 7.787 * t + (16 / 116)
end

local function colorToLab(c)
    local r = srgbLinear(c.r or 0)
    local g = srgbLinear(c.g or 0)
    local b = srgbLinear(c.b or 0)

    local x = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047
    local y = (r * 0.2126729 + g * 0.7151522 + b * 0.0721750) / 1.00000
    local z = (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) / 1.08883

    local fx = labPivot(x)
    local fy = labPivot(y)
    local fz = labPivot(z)
    return {
        l = 116 * fy - 16,
        a = 500 * (fx - fy),
        b = 200 * (fy - fz)
    }
end

local function deltaE(a, b)
    local dl = a.l - b.l
    local da = a.a - b.a
    local db = a.b - b.b
    return math.sqrt(dl * dl + da * da + db * db)
end

local function minimumDistance(candidate, chosen)
    if #chosen == 0 then return 200 end
    local minimum = math.huge
    for _, other in ipairs(chosen) do
        minimum = math.min(minimum, deltaE(candidate.lab, other.lab))
    end
    return minimum
end

local function minimumHueDistance(candidate, chosen)
    if #chosen == 0 then return 180 end
    local minimum = math.huge
    for _, other in ipairs(chosen) do
        minimum = math.min(minimum, hueDistance(candidate.hue, other.hue))
    end
    return minimum
end

local function maximinScore(candidate, chosen)
    return minimumDistance(candidate, chosen)
        + minimumHueDistance(candidate, chosen) * HUE_DISTANCE_WEIGHT
end

local function actualFloorCount()
    local highest = -1
    for _, instance in ipairs(Wall.world or {}) do
        if instance.floor ~= nil then
            highest = math.max(highest, math.floor(tonumber(instance.floor) or -1))
        end
    end
    return math.Clamp(highest + 1, 1, MAX_FLOORS)
end

local function buildCandidates()
    local candidates = {}
    local seen = {}

    for hue = 0, 355, CANDIDATE_HUE_STEP do
        for _, sv in ipairs(CANDIDATE_SV) do
            local color = HSVToColor(hue, sv[1], sv[2])
            local key = colorKey(color)
            if not seen[key] then
                seen[key] = true
                candidates[#candidates + 1] = {
                    color = color,
                    lab = colorToLab(color),
                    hue = hue
                }
            end
        end
    end

    return candidates
end

local function buildSectionPalette(seed, floorCount)
    local candidates = buildCandidates()
    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed,
        "container-section-full-spectrum-maximin-v2:" .. tostring(floorCount)))
    rng:Shuffle(candidates)

    local sectionCount = floorCount * QUADRANTS_PER_FLOOR
    local selected = {}

    -- Farthest-point sampling across the full sRGB candidate cloud. The CIE Lab
    -- term maximizes perceptual difference; the hue term explicitly forces broad
    -- traversal of the circular spectrum instead of exploiting lightness alone.
    for _ = 1, sectionCount do
        local bestIndex = nil
        local bestScore = -math.huge

        for index, candidate in ipairs(candidates) do
            local score = maximinScore(candidate, selected)
            if score > bestScore then
                bestScore = score
                bestIndex = index
            end
        end

        local chosen = table.remove(candidates, bestIndex or 1)
        if not chosen then
            local fallbackHue = (#selected * 137.507764 + seed) % 360
            local fallbackColor = HSVToColor(fallbackHue, 0.90, 0.90)
            chosen = {
                color = fallbackColor,
                lab = colorToLab(fallbackColor),
                hue = fallbackHue
            }
        end
        selected[#selected + 1] = chosen
    end

    -- The selected set is globally optimized. Assignment is a second deterministic
    -- maximin pass so each floor's own A/B/C/D quartet also spans that selected set
    -- as widely as possible rather than receiving four adjacent selections.
    local remaining = {}
    for _, candidate in ipairs(selected) do remaining[#remaining + 1] = candidate end
    rng:Shuffle(remaining)

    local palette = {}
    for floor = 0, floorCount - 1 do
        palette[floor] = {}
        local floorChosen = {}

        for quadrant = 1, QUADRANTS_PER_FLOOR do
            local bestIndex = nil
            local bestScore = -math.huge
            for index, candidate in ipairs(remaining) do
                local score = maximinScore(candidate, floorChosen)
                if score > bestScore then
                    bestScore = score
                    bestIndex = index
                end
            end

            local chosen = table.remove(remaining, bestIndex or 1)
            if chosen then
                palette[floor][quadrant] = chosen.color
                floorChosen[#floorChosen + 1] = chosen
            end
        end
    end

    local minDelta = math.huge
    local minHue = math.huge
    for i = 1, #selected - 1 do
        for j = i + 1, #selected do
            minDelta = math.min(minDelta, deltaE(selected[i].lab, selected[j].lab))
            minHue = math.min(minHue, hueDistance(selected[i].hue, selected[j].hue))
        end
    end

    paletteMinDeltaE = minDelta == math.huge and 0 or minDelta
    paletteMinHueDistance = minHue == math.huge and 0 or minHue
    sectionPalette = palette
    paletteSeed = seed
    paletteFloorCount = floorCount
end

local function ensureSectionPalette()
    local seed = tonumber(Wall.seed) or 0
    local floorCount = actualFloorCount()
    if paletteSeed == seed
        and paletteFloorCount == floorCount
        and sectionPalette[0]
    then
        return false
    end

    buildSectionPalette(seed, floorCount)
    return true
end

local function colorForInstance(instance)
    if not instance or instance.floor == nil or not instance.quadrant then return nil end
    ensureSectionPalette()
    local floor = math.Clamp(math.floor(instance.floor), 0, MAX_FLOORS - 1)
    local quadrant = math.Clamp(math.floor(instance.quadrant), 1, QUADRANTS_PER_FLOOR)
    return sectionPalette[floor] and sectionPalette[floor][quadrant] or nil
end

local function sectionMaterialName(c)
    local key = colorKey(c)
    local cached = materialNames[key]
    if cached then return cached end

    local vivid = vividSectionColor(c)
    local r = clamp01((vivid.r or 0) / 255)
    local g = clamp01((vivid.g or 0) / 255)
    local b = clamp01((vivid.b or 0) / 255)
    local name = "lod_np_section_" .. MATERIAL_VERSION .. "_" .. key

    CreateMaterial(name, "VertexLitGeneric", {
        ["$basetexture"] = NP_BASE_TEXTURE,
        ["$bumpmap"] = NP_NORMAL_TEXTURE,
        ["$surfaceprop"] = "metal",
        ["$model"] = "1",
        ["$allowdiffusemodulation"] = "1",
        ["$blendtintbybasealpha"] = "0",
        ["$blendtintcoloroverbase"] = string.format("%.3f", COLOR_REPLACE_BLEND),
        ["$color2"] = string.format("[%.5f %.5f %.5f]", r, g, b)
    })

    materialNames[key] = name
    return name
end

local function complementaryColor(c)
    local vivid = vividSectionColor(c)
    local h, s, _ = ColorToHSV(vivid)
    h = (h + 180) % 360
    s = math.Clamp(math.max(s, 0.82), 0, 1)
    return HSVToColor(h, s, 0.62)
end

local function reconcileModel(index, model, instance)
    if not IsValid(model) or not instance then return false end

    local section = colorForInstance(instance)
    if not section then return false end

    -- Make the generated color authoritative for every downstream presentation
    -- consumer, including the sparse plywood stencil renderer.
    instance.sectionColor = Color(section.r, section.g, section.b, 255)

    local matName = sectionMaterialName(section)
    local wanted = "!" .. matName
    local changed = false

    if model:GetMaterial() ~= wanted then
        model:SetMaterial(wanted)
        changed = true
    end

    local current = model:GetColor()
    if current.r ~= 255 or current.g ~= 255 or current.b ~= 255 or current.a ~= 255 then
        model:SetColor(color_white)
        changed = true
    end

    model:SetSkin(0)

    local vivid = vividSectionColor(section)
    instance.bodyColor = Color(vivid.r, vivid.g, vivid.b, 255)
    instance.stencilColor = complementaryColor(section)
    instance.sectionMaterialName = matName

    if changed then appliedCount = appliedCount + 1 end
    return changed
end

hook.Add("Think", "LOD_ReconcileContainerSectionMaterials", function()
    local models = Wall.models or {}
    local world = Wall.world or {}
    local total = #world
    if total == 0 then return end

    if ensureSectionPalette() then
        reconcileCursor = 1
        stablePasses = 0
        reconcileComplete = false
        appliedCount = 0
    end

    if models ~= reconcileModelsRef then
        reconcileModelsRef = models
        reconcileCursor = 1
        stablePasses = 0
        reconcileComplete = false
        appliedCount = 0
    end
    if reconcileComplete then return end

    if (Wall.nextModel or 1) <= total then return end
    if Wall.retryQueue and #Wall.retryQueue > 0 then return end

    local changedThisBatch = false
    local processed = 0
    while processed < RECONCILE_BATCH_SIZE and total > 0 do
        if reconcileCursor > total then
            reconcileCursor = 1
            if changedThisBatch then
                stablePasses = 0
            else
                stablePasses = stablePasses + 1
            end
            changedThisBatch = false
            if stablePasses >= 2 then
                reconcileComplete = true
                break
            end
        end

        local index = reconcileCursor
        if reconcileModel(index, models[index], world[index]) then
            changedThisBatch = true
            stablePasses = 0
        end
        reconcileCursor = reconcileCursor + 1
        processed = processed + 1
    end
end)

concommand.Add("lod_container_recolor_status", function()
    ensureSectionPalette()

    local world = Wall.world or {}
    local models = Wall.models or {}
    local correct = 0
    local wrong = 0
    local sectionCodes = {}

    for index, instance in ipairs(world) do
        local section = colorForInstance(instance)
        if section then
            local code = tostring((instance.floor or 0) + 1)
                .. string.char(64 + (instance.quadrant or 1))
            sectionCodes[code] = colorKey(section)
            local model = models[index]
            local wantedName = instance.sectionMaterialName or sectionMaterialName(section)
            if IsValid(model) and model:GetMaterial() == ("!" .. wantedName) then
                correct = correct + 1
            else
                wrong = wrong + 1
            end
        end
    end

    local sections = {}
    for code, rgb in pairs(sectionCodes) do
        sections[#sections + 1] = code .. "=" .. rgb
    end
    table.sort(sections)

    print(string.format(
        "[LOD:CONTAINER-RECOLOR] total=%d correct=%d wrong=%d floors=%d uniqueSections=%d minDeltaE=%.1f minHueDeg=%.1f candidatesHueStep=%d materials=%d blend=%.2f materialVersion=%s complete=%s sections={%s}",
        #world, correct, wrong, paletteFloorCount or 0, table.Count(sectionCodes),
        paletteMinDeltaE, paletteMinHueDistance, CANDIDATE_HUE_STEP,
        table.Count(materialNames), COLOR_REPLACE_BLEND, MATERIAL_VERSION,
        tostring(reconcileComplete), table.concat(sections, " ")
    ))
end)
