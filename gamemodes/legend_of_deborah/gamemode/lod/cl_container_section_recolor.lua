LOD = LOD or {}

local Wall = LOD.WallVisualsClient
if not Wall then return end

-- Shader-native section recoloring for the existing Northern Petrol cargo model.
--
-- The former SetColor-only pass multiplied a strongly red diffuse texture by the
-- desired section hue. Multiplication cannot invent missing color channels, so a
-- teal/green/violet request mostly produced darker red containers. Source's
-- VertexLitGeneric shader already has the correct mechanism: color-replacement
-- tinting via $blendtintcoloroverbase. We keep the exact stock NP diffuse and
-- normal map, then create one cached Lua material per section hue. This preserves
-- the logo, grime, scratches, UVs, lighting and corrugation while allowing the
-- painted steel to move toward the authored A/B/C/D hue.
local NP_BASE_TEXTURE = "models/props_wasteland/cargo_container01"
local NP_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"
local COLOR_REPLACE_BLEND = 0.72
local RECONCILE_BATCH_SIZE = 192

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

local function sectionMaterialName(c)
    local key = colorKey(c)
    local cached = materialNames[key]
    if cached then return cached end

    local r = clamp01((c.r or 0) / 255)
    local g = clamp01((c.g or 0) / 255)
    local b = clamp01((c.b or 0) / 255)
    local name = "lod_np_section_" .. key

    -- $blendtintcoloroverbase interpolates between ordinary multiplicative tint
    -- and replacing the base hue. At 0.72 the section hue becomes unmistakable,
    -- while 28% of the original albedo contribution plus the untouched normal map
    -- retain the weathered Northern Petrol material character.
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
    -- The sparse plywood labels already use a complementary stencil. Their old
    -- appearance pass derived it from a pale multiplicative tint; now that the
    -- container body genuinely uses the section hue, derive the opposite directly
    -- from that authoritative section color instead.
    local h, s, v = ColorToHSV(Color(c.r or 255, c.g or 255, c.b or 255))
    h = (h + 180) % 360
    s = math.Clamp(math.max(s, 0.78), 0, 1)

    -- The mark is painted on light plywood, so a moderately dark opposite hue is
    -- more legible than a pastel complement while remaining chromatically exact.
    v = math.Clamp(math.min(v, 0.56), 0.30, 0.56)
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
    -- alongside it until every model settles on this shader material, avoiding any
    -- coupling to its local state or changing the successful 1-in-6 marking logic.
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

    -- Preserve the original red NP skin/model identity. The material itself still
    -- references the stock NP diffuse/normal textures; only shader tint behavior
    -- changes.
    model:SetSkin(0)

    instance.bodyColor = Color(section.r, section.g, section.b, 255)
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
        "[LOD:CONTAINER-RECOLOR] total=%d correct=%d wrong=%d materials=%d blend=%.2f complete=%s stablePasses=%d applied=%d sections={%s}",
        #world, correct, wrong, table.Count(materialNames), COLOR_REPLACE_BLEND,
        tostring(reconcileComplete), stablePasses, appliedCount, table.concat(sections, " ")
    ))
end)
