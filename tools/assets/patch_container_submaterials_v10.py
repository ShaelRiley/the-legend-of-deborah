#!/usr/bin/env python3
"""Apply V10 cargo-container material-slot replacement.

V9 proved that the repository-owned blank hull texture loads correctly, but the
Steam Deck playtest also proved that a single Entity:SetMaterial override is not a
sufficient guarantee that every material slot on the stock cargo model stops using
its baked Northern Petroleum diffuse. V10 binds the generated section material to
every model material slot with SetSubMaterial, then clears the temporary global
construction override.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def patch_recolor() -> None:
    text = RECOLOR.read_text(encoding="utf-8")

    text = text.replace(
        'local MATERIAL_VERSION = "v14_blank_hull_v9"',
        'local MATERIAL_VERSION = "v15_blank_hull_submaterials"',
        1,
    )

    helper_anchor = '''local function reconcileModel(index, model, instance)\n'''
    helper = '''local function applySectionMaterialSlots(model, matName, instance)\n    local wanted = "!" .. matName\n    local slots = model:GetMaterials() or {}\n    local slotCount = #slots\n\n    -- The stock cargo model can expose multiple material slots. A single global\n    -- override proved insufficient in V9: the baked Northern Petroleum diffuse\n    -- survived even while our cached diagnostic claimed success. Replace every\n    -- slot explicitly, then clear the temporary debugwhite/global override that\n    -- cl_wall_visuals.lua uses while the client model is being constructed.\n    if slotCount > 0 then\n        local changed = instance.appliedSectionMaterialName ~= matName\n            or instance.appliedSectionMode ~= "submaterials"\n            or instance.appliedSectionSlotCount ~= slotCount\n\n        if changed then\n            for slot = 0, slotCount - 1 do\n                model:SetSubMaterial(slot, wanted)\n            end\n            model:SetMaterial("")\n            instance.appliedSectionMaterialName = matName\n            instance.appliedSectionMode = "submaterials"\n            instance.appliedSectionSlotCount = slotCount\n        end\n        return changed\n    end\n\n    -- Defensive fallback for an unexpected model with no enumerated slots. This\n    -- should never be the production cargo path, but it keeps presentation safe.\n    local changed = instance.appliedSectionMaterialName ~= matName\n        or instance.appliedSectionMode ~= "global-fallback"\n    if changed then\n        model:SetMaterial(wanted)\n        instance.appliedSectionMaterialName = matName\n        instance.appliedSectionMode = "global-fallback"\n        instance.appliedSectionSlotCount = 0\n    end\n    return changed\nend\n\nlocal function reconcileModel(index, model, instance)\n'''
    if 'local function applySectionMaterialSlots' not in text:
        if helper_anchor not in text:
            raise SystemExit("V10 reconcile helper anchor missing")
        text = text.replace(helper_anchor, helper, 1)

    old_apply = '''    local matName = sectionMaterialName(section)\n    local wanted = "!" .. matName\n    local changed = false\n\n    -- ClientSideModel:GetMaterial() does not reliably echo dynamic !material names.\n    -- Cache our own applied material identity so reconciliation can actually settle.\n    if instance.appliedSectionMaterialName ~= matName then\n        model:SetMaterial(wanted)\n        instance.appliedSectionMaterialName = matName\n        changed = true\n    end\n'''
    new_apply = '''    local matName = sectionMaterialName(section)\n    local changed = applySectionMaterialSlots(model, matName, instance)\n'''
    if old_apply in text:
        text = text.replace(old_apply, new_apply, 1)
    elif new_apply not in text:
        raise SystemExit("V10 material application anchor missing")

    old_correct = '''            if IsValid(model) and instance.appliedSectionMaterialName == wantedName then\n                correct = correct + 1\n            else\n                wrong = wrong + 1\n            end\n'''
    new_correct = '''            if IsValid(model)\n                and instance.appliedSectionMaterialName == wantedName\n                and instance.appliedSectionMode == "submaterials"\n                and (instance.appliedSectionSlotCount or 0) > 0\n            then\n                correct = correct + 1\n            else\n                wrong = wrong + 1\n            end\n'''
    if old_correct in text:
        text = text.replace(old_correct, new_correct, 1)
    elif new_correct not in text:
        raise SystemExit("V10 diagnostic correctness anchor missing")

    detail_status = '''    print(string.format(\n        "[LOD:CONTAINER-DETAIL] source=%s mode=%s blend=%.2f",\n        DETAIL_PATH,\n        DETAIL_AVAILABLE and "runtime-texture" or "flat-fallback",\n        DETAIL_AVAILABLE and DETAIL_BLEND_FACTOR or 0\n    ))\n'''
    slot_status = '''    print(string.format(\n        "[LOD:CONTAINER-DETAIL] source=%s mode=%s blend=%.2f",\n        DETAIL_PATH,\n        DETAIL_AVAILABLE and "runtime-texture" or "flat-fallback",\n        DETAIL_AVAILABLE and DETAIL_BLEND_FACTOR or 0\n    ))\n\n    local sampleSlots = 0\n    local sampleMode = "none"\n    for index, instance in ipairs(world) do\n        local model = models[index]\n        if IsValid(model) then\n            sampleSlots = #(model:GetMaterials() or {})\n            sampleMode = tostring(instance.appliedSectionMode or "none")\n            break\n        end\n    end\n    print(string.format(\n        "[LOD:CONTAINER-SLOTS] mode=%s sampleSlots=%d materialVersion=%s",\n        sampleMode, sampleSlots, MATERIAL_VERSION\n    ))\n'''
    if '[LOD:CONTAINER-SLOTS]' not in text:
        if detail_status not in text:
            raise SystemExit("V10 slot diagnostic anchor missing")
        text = text.replace(detail_status, slot_status, 1)

    RECOLOR.write_text(text, encoding="utf-8")


def patch_docs() -> None:
    text = DOCS.read_text(encoding="utf-8").rstrip()
    if "## V10 explicit cargo material-slot replacement" in text:
        DOCS.write_text(text + "\n", encoding="utf-8")
        return

    text += r'''

## V10 explicit cargo material-slot replacement

The V9 Steam Deck playtest produced a decisive runtime result: the generated blank
hull and grit textures both reported `mode=runtime-texture`, but the stock `NP /
Northern Petroleum` art still appeared unchanged on the physical cargo model. The
old `wrong=0` diagnostic was not proof of the rendered material because it only
verified our cached call state.

V10 therefore stops treating a single `Entity:SetMaterial` call as authoritative.
For every clientside cargo model, `cl_container_section_recolor.lua` now enumerates
`model:GetMaterials()` and applies the generated blank-hull section material to each
slot with `SetSubMaterial(slot, "!<dynamic material>")`. Only after every material
slot is replaced does it clear the temporary global `models/debug/debugwhite`
construction override. This closes the path through which any stock Northern
Petroleum diffuse/material slot can survive.

The runtime status command now counts a container as correct only when it has a
non-zero material-slot count and reports `appliedSectionMode=submaterials`. It also
prints `[LOD:CONTAINER-SLOTS]`; production should report `mode=submaterials` and a
positive `sampleSlots` value.

Expected V10 diagnostics:

- `materialVersion=v15_blank_hull_submaterials`
- `[LOD:CONTAINER-HULL] ... mode=runtime-texture`
- `[LOD:CONTAINER-DETAIL] ... mode=runtime-texture`
- `[LOD:CONTAINER-SLOTS] mode=submaterials sampleSlots=>0`
- `wrong=0`
'''
    DOCS.write_text(text + "\n", encoding="utf-8")


def main() -> None:
    patch_recolor()
    patch_docs()
    print("V10 explicit cargo submaterial replacement patch applied.")


if __name__ == "__main__":
    main()
