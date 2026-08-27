LOD = LOD or {}

local Wall = LOD.WallVisualsClient
if not Wall then return end

-- Shader-native section recoloring for the existing Northern Petrol cargo model.
--
-- The stock diffuse is strongly red, so ordinary SetColor multiplication cannot
-- produce clean section hues. Source's VertexLitGeneric color-replacement path
-- preserves the exact model, UVs, weathered diffuse and normal map while allowing
-- procedural paint colors. Runtime testing established that the stock diffuse alpha
-- is NOT an NP-logo paint mask, so the authentic baked branding shares the body tint
-- except on marked containers, where the separate plywood wayfinding plate covers it.
--
-- Section colors are no longer drawn from a repeating four-color palette. A seeded
-- maximin palette generator creates 32 unique colors (8 representable floors x four
-- quadrants), rejects progression Red/Blue/Yellow hue bands, then greedily maximizes
-- CIE Lab distance globally and especially within each floor quartet. No section
-- color repeats anywhere in the representable dungeon.
local NP_BASE_TEXTURE = "models/props_wasteland/cargo_container01"
local NP_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"
local COLOR_REPLACE_BLEND = 0.84
local MIN_SECTION_SATURATION = 0.82
local MIN_SECTION_VALUE = 0.80
local RECONCILE_BATCH_SIZE = 192
local MATERIAL_VERSION = "v6_maximin_unique"
local MAX_FLOORS = 8
local QUADRANTS_PER_FLOOR = 4
local MAX_SECTIONS = MAX_FLOORS * QUADRANTS_PER_FLOOR

-- Reserve broad neighborhoods around progression Red, Yellow and Blue. These are
-- intentionally wider than a single exact hue so a location color cannot plausibly
-- read as a gate/keycard color under Deborah's dark lighting.
local FORBIDDEN_HUES = {
    {center = 0, radius = 24},
    {center = 58, radius = 21},
    {center = 220, radius = 25}
}

-- Multiple saturation/value shells give the maximin solver enough perceptual space
-- to produce 32 unique colors without resorting to near-duplicates in hue alone.
local CANDIDATE_SV = {
    {0.82, 0.82},
    {0.92, 0.90},
    {0.76, 0.96}
}

local materialNames = {}
local reconcileCursor = 1
local reconcileModelsRef = nil
local stablePasses = 0
local reconcileComplete = false
local appliedCount = 0

local paletteSeed = nil
local sectionPalette = {}
local paletteMinDeltaE = 0

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

local function progressionSafeHue(h)
    for _, forbidden in ipairs(FORBIDDEN_HUES) do
        if hueDistance(h, forbidden.center) <= forbidden.radius then
            return false
        end
    end
    return true
end

local function vividSectionColor(c)
    local h, s, v = ColorToHSV(Color(c.r or 255, c.g or 255, c.b or 255))
    s = math.Clamp(math.max(s, MIN_SECTION_SATURATION), 0, 1)
    v = math.Clamp(math.max(v, MIN_SECTION_VALUE), 0, 1)
    return HSVToColor(h, s, v)
end

-- CIE Lab is used only while a new level palette is being built. This is a tiny,
-- one-time computation (well under 100 candidates) and gives a materially better
-- approximation of human-visible color separation than raw RGB or hue distance.
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

local function buildSectionPalette(seed)
    local candidates = {}
    for hue = 0, 350, 10 do
        if progressionSafeHue(hue) then
            for _, sv in ipairs(CANDIDATE_SV) do
                local color = HSVToColor(hue, sv[1], sv[2])
                candidates[#candidates + 1] = {
                    color = color,
                    lab = colorToLab(color),
                    hue = hue
                }
            end
        end
    end

    local rng = LOD.RNG.New(LOD.Seeds.Derive(seed,
        "container-section-maximin-palette-v1"))
    rng:Shuffle(candidates)

    local palette = {}
    local allChosen = {}

    for floor = 0, MAX_FLOORS - 1 do
        palette[floor] = {}
        local floorChosen = {}

        for quadrant = 1, QUADRANTS_PER_FLOOR do
            local bestIndex = nil
            local bestScore = -math.huge

            for index, candidate in ipairs(candidates) do
                local globalDistance = minimumDistance(candidate, allChosen)
                local floorDistance = minimumDistance(candidate, floorChosen)

                -- The floor quartet carries the immediate spatial-navigation burden,
                -- so within-floor separation receives extra weight while global
                -- distance still prevents any two dungeon sections becoming twins.
                local score = globalDistance + floorDistance * 1.35
                if score > bestScore then
                    bestScore = score
                    bestIndex = index
                end
            end

            local chosen = table.remove(candidates, bestIndex or 1)
            if not chosen then
                -- This should never occur with the candidate grid above, but retain
                -- a deterministic emergency color rather than leaving a section nil.
                local fallbackHue = ((floor * 4 + quadrant) * 137.507764) % 360
                chosen = {
                    color = HSVToColor(fallbackHue, 0.88, 0.88),
                    lab = colorToLab(HSVToColor(fallbackHue, 0.88, 0.88))
                }
            end

            palette[floor][quadrant] = chosen.color
            floorChosen[#floorChosen + 1] = chosen
            allChosen[#allChosen + 1] = chosen
        end
    end

    local minimum = math.huge
    for i = 1, #allChosen - 1 do
        for j = i + 1, #allChosen do
            minimum = math.min(minimum, deltaE(allChosen[i].lab, allChosen[j].lab))
        end
    end

    paletteMinDeltaE = minimum == math.huge and 0 or minimum
    sectionPalette = palette
    paletteSeed = seed
end

local function ensureSectionPalette()
    local seed = tonumber(Wall.seed) or 0
    if paletteSeed == seed and sectionPalette[0] then return false end
    buildSectionPalette(seed)
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
            local code = tostring((instance.floor or 0) + 1) .. string.char(64 + (instance.quadrant or 1))
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
        "[LOD:CONTAINER-RECOLOR] total=%d correct=%d wrong=%d uniqueSections=%d maxSections=%d minDeltaE=%.1f materials=%d blend=%.2f materialVersion=%s complete=%s sections={%s}",
        #world, correct, wrong, table.Count(sectionCodes), MAX_SECTIONS,
        paletteMinDeltaE, table.Count(materialNames), COLOR_REPLACE_BLEND,
        MATERIAL_VERSION, tostring(reconcileComplete), table.concat(sections, " ")
    ))
end)
