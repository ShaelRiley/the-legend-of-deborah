LOD = LOD or {}

local Wall = LOD.WallVisualsClient
if not Wall then return end

-- Shader-native section recoloring for the existing Northern Petrol cargo model.
--
-- The stock diffuse is strongly red, so ordinary SetColor multiplication cannot
-- produce clean teal/green/violet sections. Source's VertexLitGeneric color-
-- replacement path solves that while preserving the exact model, UVs, diffuse
-- artwork, grime and normal map. Runtime testing established that the stock diffuse
-- alpha is NOT an NP-logo paint mask, so production deliberately tints the complete
-- stock albedo. The Northern Petrol logo remains part of that authentic texture and
-- is allowed to share the section tint rather than being replaced by a fake overlay.
local NP_BASE_TEXTURE = "models/props_wasteland/cargo_container01"
local NP_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"
local COLOR_REPLACE_BLEND = 0.84
local MIN_SECTION_SATURATION = 0.86
local MIN_SECTION_VALUE = 0.82
local RECONCILE_BATCH_SIZE = 192
local MATERIAL_VERSION = "v5_textured_unmasked"

local materialNames = {}
local reconcileCursor = 1
local reconcileModelsRef = nil
local stablePasses = 0
local reconcileComplete = false
local appliedCount = 0

local function clamp01(value)
    return math.Clamp(tonumber(value) or 0, 0, 1)
end

local function colorKey(c)
    return string.format("%03d_%03d_%03d",
        math.Clamp(math.floor(c.r or 0), 0, 255),
        math.Clamp(math.floor(c.g or 0), 0, 255),
        math.Clamp(math.floor(c.b or 0), 0, 255))
end

local function vividSectionColor(c)
    -- Preserve the authored hue while enforcing saturation/value floors before it
    -- reaches the replacement shader. This keeps A/B/C/D readable under Deborah's
    -- midnight lighting without turning the weathered containers into flat neon.
    local h, s, v = ColorToHSV(Color(c.r or 255, c.g or 255, c.b or 255))
    s = math.Clamp(math.max(s, MIN_SECTION_SATURATION), 0, 1)
    v = math.Clamp(math.max(v, MIN_SECTION_VALUE), 0, 1)
    return HSVToColor(h, s, v)
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

    -- $blendtintcoloroverbase interpolates between ordinary multiplicative tint and
    -- replacing the base hue. Keeping base-alpha masking OFF preserves the full
    -- weathered albedo contribution, while the untouched bump map retains the
    -- container's corrugation and surface depth.
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
    -- Derive signage from the same vivid body hue actually sent to the shader.
    local vivid = vividSectionColor(c)
    local h, s, v = ColorToHSV(vivid)
    h = (h + 180) % 360
    s = math.Clamp(math.max(s, 0.82), 0, 1)

    -- The mark is painted on light plywood, so a moderately dark opposite hue is
    -- more legible than a pastel complement while remaining chromatically exact.
    v = 0.62
    return HSVToColor(h, s, v)
end

local function reconcileModel(index, model, instance)
    if not IsValid(model) or not instance or not instance.sectionColor then
        return false
    end

    local section = instance.sectionColor
    local matName = sectionMaterialName(section)
    local wanted = "!" .. matName

    -- The older presentation hook still owns sparse mark selection and runs its
    -- one-time batching pass. It may briefly restore the stock material and apply
    -- SetColor while that batch is in flight. Reconciliation intentionally runs
    -- alongside it until every model settles on this shader material.
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

    if models ~= reconcileModelsRef then
        reconcileModelsRef = models
        reconcileCursor = 1
        stablePasses = 0
        reconcileComplete = false
        appliedCount = 0
    end
    if reconcileComplete then return end

    -- Do not race initial ClientsideModel creation/retry. Once construction has
    -- finished, run bounded cyclic passes until two complete passes find nothing
    -- left for the older appearance hook to overwrite, then become fully idle.
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
    local world = Wall.world or {}
    local models = Wall.models or {}
    local correct = 0
    local wrong = 0
    local bySection = {}

    for index, instance in ipairs(world) do
        if instance.sectionColor then
            local key = colorKey(instance.sectionColor)
            bySection[key] = (bySection[key] or 0) + 1
            local model = models[index]
            local wantedName = instance.sectionMaterialName or sectionMaterialName(instance.sectionColor)
            if IsValid(model) and model:GetMaterial() == ("!" .. wantedName) then
                correct = correct + 1
            else
                wrong = wrong + 1
            end
        end
    end

    local sections = {}
    for key, count in pairs(bySection) do
        sections[#sections + 1] = key .. "=" .. tostring(count)
    end
    table.sort(sections)

    print(string.format(
        "[LOD:CONTAINER-RECOLOR] total=%d correct=%d wrong=%d materials=%d blend=%.2f satFloor=%.2f valueFloor=%.2f materialVersion=%s complete=%s stablePasses=%d applied=%d sections={%s}",
        #world, correct, wrong, table.Count(materialNames), COLOR_REPLACE_BLEND,
        MIN_SECTION_SATURATION, MIN_SECTION_VALUE, MATERIAL_VERSION,
        tostring(reconcileComplete), stablePasses, appliedCount, table.concat(sections, " ")
    ))
end)
