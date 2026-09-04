#!/usr/bin/env python3
"""Patch V11 cargo presentation to V12 global file-backed BGR888 materials."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"
VERSION = "v17_filebacked_global_bgr888"


def replace_all_checked(text: str, old: str, new: str, minimum: int, label: str) -> str:
    count = text.count(old)
    if count < minimum:
        raise SystemExit(f"{label} replacement count={count}, expected>={minimum}")
    return text.replace(old, new)


def patch_recolor() -> bool:
    text = RECOLOR.read_text(encoding="utf-8")
    if f'MATERIAL_VERSION = "{VERSION}"' in text:
        required = (
            'model:SetSubMaterial()',
            'model:SetMaterial(matName)',
            'instance.appliedSectionMode = "file-backed-global"',
            '[LOD:CONTAINER-GLOBAL]',
        )
        missing = [token for token in required if token not in text]
        if missing:
            raise SystemExit(f"partial V12 runtime wiring: {missing}")
        return False

    text = replace_all_checked(
        text,
        'container_blank_hull_v11.vtf',
        'container_blank_hull_v12.vtf',
        1,
        'hull path',
    )
    text = replace_all_checked(
        text,
        'container_grit_detail_v11.vtf',
        'container_grit_detail_v12.vtf',
        1,
        'detail path',
    )
    text = replace_all_checked(text, 'v16_filebacked_vtf', VERSION, 1, 'material version')
    text = replace_all_checked(text, 'v16_h%03d_s%d', 'v17_h%03d_s%d', 2, 'material key')

    block_pattern = re.compile(
        r'local function allSectionSlotsMatch\(model, matName\)\n.*?\nend\n\nlocal function reconcileModel',
        re.S,
    )
    block = '''local function normalizedMaterialName(value)
    local name = string.lower(tostring(value or ""))
    name = string.gsub(name, "^!", "")
    name = string.gsub(name, "^materials/", "")
    name = string.gsub(name, "%.vmt$", "")
    return name
end

local function globalMaterialMatches(model, matName)
    if not IsValid(model) or not matName then return false end
    return normalizedMaterialName(model:GetMaterial()) == normalizedMaterialName(matName)
end

local function applySectionMaterial(model, matName, instance)
    local available = sectionMaterialAvailable(matName)
    if not available then
        instance.appliedSectionMode = "file-backed-missing"
        instance.appliedSectionSlotCount = 0
        return false
    end

    local slotCount = #(model:GetMaterials() or {})
    local matches = globalMaterialMatches(model, matName)
    local changed = instance.appliedSectionMaterialName ~= matName
        or instance.appliedSectionMode ~= "file-backed-global"
        or instance.appliedSectionSlotCount ~= slotCount
        or not matches

    if changed then
        -- Every stock material island on the cargo mesh should use the same blank
        -- hull. A single file-backed global override is both simpler and stronger
        -- than V11's per-slot replacement. Clear stale submaterial state first.
        model:SetSubMaterial()
        model:SetMaterial(matName)
        instance.appliedSectionMaterialName = matName
        instance.appliedSectionMode = "file-backed-global"
        instance.appliedSectionSlotCount = slotCount
    end
    return changed
end

local function reconcileModel'''
    text, count = block_pattern.subn(block, text, count=1)
    if count != 1:
        raise SystemExit(f"V12 material-application block replacement count={count}")

    text = text.replace(
        'local changed = applySectionMaterialSlots(model, matName, instance)',
        'local changed = applySectionMaterial(model, matName, instance)',
        1,
    )

    status_pattern = re.compile(
        r'concommand\.Add\("lod_container_recolor_status", function\(\)\n.*?\nend\)\s*$',
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
            local materialOK = sectionMaterialAvailable(wantedName)
            if IsValid(model)
                and materialOK
                and globalMaterialMatches(model, wantedName)
                and instance.appliedSectionMaterialName == wantedName
                and instance.appliedSectionMode == "file-backed-global"
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
        "[LOD:CONTAINER-HULL] source=%s mode=file-backed-bgr888 blend=%.2f",
        HULL_PATH, COLOR_REPLACE_BLEND
    ))
    print(string.format(
        "[LOD:CONTAINER-DETAIL] source=%s mode=file-backed-bgr888 blend=%.2f",
        DETAIL_PATH, DETAIL_BLEND_FACTOR
    ))

    local sampleSlots = 0
    local sampleMode = "none"
    local sampleName = "none"
    local sampleActual = "none"
    local sampleShader = "none"
    local sampleMaterialOK = false
    local sampleOverrideOK = false
    for index, instance in ipairs(world) do
        local model = models[index]
        if IsValid(model) then
            sampleSlots = #(model:GetMaterials() or {})
            sampleMode = tostring(instance.appliedSectionMode or "none")
            sampleName = instance.sectionMaterialName or sectionMaterialName(instance) or "none"
            sampleActual = tostring(model:GetMaterial() or "")
            sampleMaterialOK, sampleShader = sectionMaterialAvailable(sampleName)
            sampleOverrideOK = globalMaterialMatches(model, sampleName)
            break
        end
    end
    print(string.format(
        "[LOD:CONTAINER-GLOBAL] mode=%s sampleSlots=%d materialVersion=%s override=%s",
        sampleMode, sampleSlots, MATERIAL_VERSION,
        sampleOverrideOK and "ok" or "wrong"
    ))
    print(string.format(
        "[LOD:CONTAINER-VTF] material=%s shader=%s expected=%s actual=%s",
        sampleMaterialOK and "ok" or "error",
        sampleShader,
        sampleName,
        sampleActual
    ))
end)
'''
    text, count = status_pattern.subn(status, text, count=1)
    if count != 1:
        raise SystemExit(f"V12 status replacement count={count}")

    forbidden = (
        'model:SetSubMaterial(slot, matName)',
        'model:GetSubMaterial(slot)',
        'file-backed-submaterials',
        'allSectionSlotsMatch',
    )
    found = [token for token in forbidden if token in text]
    if found:
        raise SystemExit(f"V12 per-slot path survived: {found}")

    RECOLOR.write_text(text, encoding="utf-8")
    return True


def patch_docs() -> bool:
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V12 global BGR888 Source material"
    if marker in text:
        return False
    text = text.rstrip() + '''

## V12 global BGR888 Source material

The V11 Steam Deck test reported `material=ok shader=VertexLitGeneric` but also
`override=wrong` and `wrong=<all containers>`. This proved that the V11 file-backed
VMT parser path existed while the per-slot override state itself was not authoritative.
The visible hull remained black.

V12 removes both remaining uncertainties. Because every cargo material island should
share the same procedurally coloured blank hull, the client now clears all stale
submaterial overrides and applies one ordinary file-backed `VertexLitGeneric` VMT with
`Entity:SetMaterial`. Runtime verification compares `Entity:GetMaterial` directly.

The VTF high-resolution payload is also changed from custom DXT1 compression to plain
BGR888. This is larger but intentionally simple and deterministic. The build validator
decodes the committed largest BGR888 mip and compares it byte-for-byte with the source
PNG, ensuring the mounted Source texture contains the authored gritty blank hull rather
than merely possessing a syntactically valid header.

Expected runtime diagnostics are `materialVersion=v17_filebacked_global_bgr888`,
`[LOD:CONTAINER-GLOBAL] ... override=ok`, and `wrong=0`.
'''
    DOCS.write_text(text + "\n", encoding="utf-8")
    return True


def main() -> None:
    print(f"V12 patch: recolor_changed={patch_recolor()} docs_changed={patch_docs()}")


if __name__ == "__main__":
    main()
