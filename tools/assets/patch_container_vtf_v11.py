#!/usr/bin/env python3
"""Move the runtime cargo hull from dynamic PNG materials to file-backed VTF/VMT."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"

VERSION = "v16_filebacked_vtf"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label} replacement count={count}")
    return text.replace(old, new, 1)


def patch_recolor() -> bool:
    text = RECOLOR.read_text(encoding="utf-8")
    if f'MATERIAL_VERSION = "{VERSION}"' in text:
        required = (
            'SECTION_MATERIAL_PREFIX = "legend_of_deborah/container_sections/"',
            'appliedSectionMode = "file-backed-submaterials"',
            'model:GetSubMaterial(slot)',
            '[LOD:CONTAINER-VTF]',
        )
        missing = [token for token in required if token not in text]
        if missing:
            raise SystemExit(f"partial V11 runtime wiring: {missing}")
        return False

    header_pattern = re.compile(
        r'local HULL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v9\.png"\n'
        r'.*?'
        r'local MATERIAL_VERSION = "v15_blank_hull_submaterials"\n',
        re.S,
    )
    header = '''local HULL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v11.vtf"
local DETAIL_PATH = "legend_of_deborah/container_surfaces/container_grit_detail_v11.vtf"
local SECTION_MATERIAL_PREFIX = "legend_of_deborah/container_sections/"
local DETAIL_BLEND_FACTOR = 0.40
local DETAIL_SCALE = 1.00
-- File-backed Source VTF/VMT materials replace V10's runtime PNG ITexture binding.
-- The authored neutral hull still owns luminance/grime while each prebuilt VMT owns
-- one deterministic section tint from the finite maximin candidate set.
local COLOR_REPLACE_BLEND = 0.78
local MIN_SECTION_SATURATION = 0.82
local MIN_SECTION_VALUE = 0.80
local RECONCILE_BATCH_SIZE = 192
local MATERIAL_VERSION = "v16_filebacked_vtf"
'''
    text, count = header_pattern.subn(header, text, count=1)
    if count != 1:
        raise SystemExit(f"V11 header replacement count={count}")

    text = replace_once(
        text,
        'local sectionPalette = {}\n',
        'local sectionPalette = {}\nlocal sectionMaterialKeys = {}\nlocal materialAvailability = {}\n',
        "section material state",
    )

    old_candidates = '''    for hue = 0, 355, CANDIDATE_HUE_STEP do
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
'''
    new_candidates = '''    for hue = 0, 355, CANDIDATE_HUE_STEP do
        for shellIndex, sv in ipairs(CANDIDATE_SV) do
            local color = HSVToColor(hue, sv[1], sv[2])
            local key = colorKey(color)
            if not seen[key] then
                seen[key] = true
                candidates[#candidates + 1] = {
                    color = color,
                    lab = colorToLab(color),
                    hue = hue,
                    materialKey = string.format("v16_h%03d_s%d", hue, shellIndex)
                }
            end
        end
    end
'''
    text = replace_once(text, old_candidates, new_candidates, "candidate material keys")

    old_fallback = '''            local fallbackHue = (#selected * 137.507764 + seed) % 360
            local fallbackColor = HSVToColor(fallbackHue, 0.90, 0.90)
            chosen = {
                color = fallbackColor,
                lab = colorToLab(fallbackColor),
                hue = fallbackHue
            }
'''
    new_fallback = '''            local rawHue = (#selected * 137.507764 + seed) % 360
            local fallbackHue = (math.floor(rawHue / CANDIDATE_HUE_STEP + 0.5)
                * CANDIDATE_HUE_STEP) % 360
            local fallbackShell = 2
            local fallbackSV = CANDIDATE_SV[fallbackShell]
            local fallbackColor = HSVToColor(fallbackHue, fallbackSV[1], fallbackSV[2])
            chosen = {
                color = fallbackColor,
                lab = colorToLab(fallbackColor),
                hue = fallbackHue,
                materialKey = string.format("v16_h%03d_s%d", fallbackHue, fallbackShell)
            }
'''
    text = replace_once(text, old_fallback, new_fallback, "fallback material key")

    text = replace_once(
        text,
        '    local palette = {}\n    for floor = 0, floorCount - 1 do\n        palette[floor] = {}\n',
        '    local palette = {}\n    local materialKeys = {}\n    for floor = 0, floorCount - 1 do\n        palette[floor] = {}\n        materialKeys[floor] = {}\n',
        "palette key table",
    )
    text = replace_once(
        text,
        '                palette[floor][quadrant] = chosen.color\n                floorChosen[#floorChosen + 1] = chosen\n',
        '                palette[floor][quadrant] = chosen.color\n                materialKeys[floor][quadrant] = chosen.materialKey\n                floorChosen[#floorChosen + 1] = chosen\n',
        "palette key assignment",
    )
    text = replace_once(
        text,
        '    sectionPalette = palette\n    paletteSeed = seed\n',
        '    sectionPalette = palette\n    sectionMaterialKeys = materialKeys\n    paletteSeed = seed\n',
        "palette key publish",
    )

    material_pattern = re.compile(
        r'local function sectionMaterialName\(c\)\n.*?\nend\n\nlocal function complementaryColor',
        re.S,
    )
    material_block = '''local function materialKeyForInstance(instance)
    if not instance or instance.floor == nil or not instance.quadrant then return nil end
    ensureSectionPalette()
    local floor = math.Clamp(math.floor(instance.floor), 0, MAX_FLOORS - 1)
    local quadrant = math.Clamp(math.floor(instance.quadrant), 1, QUADRANTS_PER_FLOOR)
    return sectionMaterialKeys[floor] and sectionMaterialKeys[floor][quadrant] or nil
end

local function sectionMaterialName(instance)
    local key = materialKeyForInstance(instance)
    if not key then return nil end
    local name = SECTION_MATERIAL_PREFIX .. key
    materialNames[name] = true
    return name
end

local function sectionMaterialAvailable(name)
    if not name then return false, "missing" end
    local cached = materialAvailability[name]
    if cached then return cached.ok, cached.shader end

    local material = Material(name)
    local ok = material ~= nil and not material:IsError()
    local shader = ok and tostring(material:GetShader() or "") or "error"
    ok = ok and string.lower(shader) == "vertexlitgeneric"
    materialAvailability[name] = {ok = ok, shader = shader}
    return ok, shader
end

local function complementaryColor'''
    text, count = material_pattern.subn(material_block, text, count=1)
    if count != 1:
        raise SystemExit(f"V11 material function replacement count={count}")

    slots_pattern = re.compile(
        r'local function applySectionMaterialSlots\(model, matName, instance\)\n.*?\nend\n\nlocal function reconcileModel',
        re.S,
    )
    slots_block = '''local function allSectionSlotsMatch(model, matName)
    if not IsValid(model) or not matName then return false, 0 end
    local slots = model:GetMaterials() or {}
    local slotCount = #slots
    if slotCount <= 0 then return false, 0 end
    for slot = 0, slotCount - 1 do
        if tostring(model:GetSubMaterial(slot) or "") ~= matName then
            return false, slotCount
        end
    end
    return true, slotCount
end

local function applySectionMaterialSlots(model, matName, instance)
    local available = sectionMaterialAvailable(matName)
    if not available then
        instance.appliedSectionMode = "file-backed-missing"
        instance.appliedSectionSlotCount = 0
        return false
    end

    local slots = model:GetMaterials() or {}
    local slotCount = #slots
    if slotCount > 0 then
        local matches = allSectionSlotsMatch(model, matName)
        local changed = instance.appliedSectionMaterialName ~= matName
            or instance.appliedSectionMode ~= "file-backed-submaterials"
            or instance.appliedSectionSlotCount ~= slotCount
            or not matches

        if changed then
            for slot = 0, slotCount - 1 do
                model:SetSubMaterial(slot, matName)
            end
            -- cl_wall_visuals.lua constructs with a temporary debugwhite override.
            -- Clear it only after every stock cargo material slot has a real VMT.
            model:SetMaterial("")
            instance.appliedSectionMaterialName = matName
            instance.appliedSectionMode = "file-backed-submaterials"
            instance.appliedSectionSlotCount = slotCount
        end
        return changed
    end

    local changed = instance.appliedSectionMaterialName ~= matName
        or instance.appliedSectionMode ~= "file-backed-global-fallback"
        or tostring(model:GetMaterial() or "") ~= matName
    if changed then
        model:SetMaterial(matName)
        instance.appliedSectionMaterialName = matName
        instance.appliedSectionMode = "file-backed-global-fallback"
        instance.appliedSectionSlotCount = 0
    end
    return changed
end

local function reconcileModel'''
    text, count = slots_pattern.subn(slots_block, text, count=1)
    if count != 1:
        raise SystemExit(f"V11 slot replacement count={count}")

    text = replace_once(
        text,
        '    local matName = sectionMaterialName(section)\n    local changed = applySectionMaterialSlots(model, matName, instance)\n',
        '    local matName = sectionMaterialName(instance)\n    if not matName then return false end\n    local changed = applySectionMaterialSlots(model, matName, instance)\n',
        "reconcile material lookup",
    )

    status_pattern = re.compile(
        r'local function normalizedMaterialOverride\(model\)\n.*?\nconcommand\.Add\("lod_container_recolor_status", function\(\)\n.*?\nend\)\s*$',
        re.S,
    )
    status = '''concommand.Add("lod_container_recolor_status", function()
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
            local wantedName = instance.sectionMaterialName or sectionMaterialName(instance)
            local slotsMatch, slotCount = allSectionSlotsMatch(model, wantedName)
            local materialOK = sectionMaterialAvailable(wantedName)
            if IsValid(model)
                and materialOK
                and slotsMatch
                and slotCount > 0
                and instance.appliedSectionMaterialName == wantedName
                and instance.appliedSectionMode == "file-backed-submaterials"
            then
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
    print(string.format(
        "[LOD:CONTAINER-HULL] source=%s mode=file-backed-vtf blend=%.2f",
        HULL_PATH, COLOR_REPLACE_BLEND
    ))
    print(string.format(
        "[LOD:CONTAINER-DETAIL] source=%s mode=file-backed-vtf blend=%.2f",
        DETAIL_PATH, DETAIL_BLEND_FACTOR
    ))

    local sampleSlots = 0
    local sampleMode = "none"
    local sampleName = "none"
    local sampleShader = "none"
    local sampleMaterialOK = false
    local sampleOverridesOK = false
    for index, instance in ipairs(world) do
        local model = models[index]
        if IsValid(model) then
            sampleSlots = #(model:GetMaterials() or {})
            sampleMode = tostring(instance.appliedSectionMode or "none")
            sampleName = instance.sectionMaterialName or sectionMaterialName(instance) or "none"
            sampleMaterialOK, sampleShader = sectionMaterialAvailable(sampleName)
            sampleOverridesOK = select(1, allSectionSlotsMatch(model, sampleName))
            break
        end
    end
    print(string.format(
        "[LOD:CONTAINER-SLOTS] mode=%s sampleSlots=%d materialVersion=%s",
        sampleMode, sampleSlots, MATERIAL_VERSION
    ))
    print(string.format(
        "[LOD:CONTAINER-VTF] material=%s shader=%s override=%s sample=%s",
        sampleMaterialOK and "ok" or "error",
        sampleShader,
        sampleOverridesOK and "ok" or "wrong",
        sampleName
    ))
end)
'''
    text, count = status_pattern.subn(status, text, count=1)
    if count != 1:
        raise SystemExit(f"V11 status replacement count={count}")

    forbidden = (
        'CreateMaterial(',
        'material:SetTexture("$basetexture"',
        'material:SetTexture("$detail"',
        '"!" .. matName',
        'runtime-texture',
    )
    found = [token for token in forbidden if token in text]
    if found:
        raise SystemExit(f"V11 runtime still contains dynamic material path: {found}")

    RECOLOR.write_text(text, encoding="utf-8")
    return True


def patch_docs() -> bool:
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V11 file-backed Source materials"
    if marker in text:
        return False
    text = text.rstrip() + '''

## V11 file-backed Source materials

The V10 Steam Deck playtest isolated the remaining material failure. Explicit
`SetSubMaterial` replacement worked: `sampleSlots=3`, `wrong=0`, and the stock
Northern Petroleum art disappeared. The replacement hull itself, however, rendered
black even while the mounted PNGs reported `mode=runtime-texture`. That proves the
remaining fault is the dynamic `CreateMaterial` + runtime PNG `ITexture` composition,
not the cargo mesh, UVs, spray renderer, or submaterial indexing.

V11 removes that runtime texture indirection entirely. The deterministic V9 blank
steel and neutral grit images are compiled during the repository build into ordinary
Source **VTF 7.2 / DXT1** textures with complete mip chains. The finite 72-hue x
5-shell palette is compiled into 360 tiny file-backed `VertexLitGeneric` VMT files.
The runtime maximin palette algorithm still chooses the same candidate colours, but
each chosen section now points directly at a normal material path under
`legend_of_deborah/container_sections/`. `SetSubMaterial` receives that file-backed
path with no `!` dynamic-material prefix and no runtime `IMaterial:SetTexture` calls.

The V11 renderer verifies the real state rather than cached calls: every material
slot must return the expected path through `GetSubMaterial`, the selected VMT must
load without `IsError()`, and its shader must be `VertexLitGeneric` before a container
counts as correct.

Expected V11 diagnostics:

- `materialVersion=v16_filebacked_vtf`
- `[LOD:CONTAINER-HULL] ... mode=file-backed-vtf`
- `[LOD:CONTAINER-DETAIL] ... mode=file-backed-vtf`
- `[LOD:CONTAINER-SLOTS] mode=file-backed-submaterials sampleSlots=>0`
- `[LOD:CONTAINER-VTF] material=ok shader=VertexLitGeneric override=ok`
- `wrong=0`

Visual acceptance remains unchanged: no stock NP art, vivid deterministic section
colour, dirty/corrugated steel instead of a black slab, two visibly distinct stacked
containers, and the existing alpha-tested procedural company spray intact.
'''
    DOCS.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    recolor_changed = patch_recolor()
    docs_changed = patch_docs()
    print(f"V11 patch applied: recolor_changed={recolor_changed} docs_changed={docs_changed}")


if __name__ == "__main__":
    main()
