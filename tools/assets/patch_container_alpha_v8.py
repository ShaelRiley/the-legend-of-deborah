#!/usr/bin/env python3
"""Make full-side container branding impossible to render as an opaque card.

V8 converts the spray atlas alpha into a deterministic binary dither mask and uses
VertexLitGeneric alpha testing instead of translucency. Transparent pixels are
therefore discarded by Source rather than blended, while the high-resolution dither
preserves a physical overspray/abrasion character.

It also stabilizes section-material reconciliation using the material name cached on
the presentation instance. Garry's Mod does not reliably echo dynamic !material
names through GetMaterial() on these clientside models, which previously kept the
reconciler running forever and made the status command report every model as wrong.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SURFACE = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_surfaces"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"

BAYER4 = np.array(
    [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]],
    dtype=np.float32,
)


def dither_atlases() -> None:
    for number in range(1, 5):
        path = SURFACE / f"container_brand_spray_atlas_{number:02d}.png"
        image = Image.open(path).convert("RGBA")
        rgba = np.asarray(image, dtype=np.uint8).copy()
        alpha = rgba[:, :, 3].astype(np.float32)
        h, w = alpha.shape
        threshold = np.tile((BAYER4 + 0.5) * (255.0 / 16.0), (h // 4 + 1, w // 4 + 1))[:h, :w]
        binary = np.where(alpha > threshold, 255, 0).astype(np.uint8)
        # White RGB everywhere avoids dark filtering halos at discarded texels.
        rgba[:, :, 0:3] = 255
        rgba[:, :, 3] = binary
        out = Image.fromarray(rgba, "RGBA")
        out.save(path, optimize=True, compress_level=9)
        coverage = float((binary > 0).mean())
        print(f"{path.name}: V8 binary alpha dither coverage={coverage:.4f} bytes={path.stat().st_size}")


def patch_branding() -> None:
    text = BRANDING.read_text(encoding="utf-8")
    text = text.replace(
        "-- gritty neutral hull and procedural section hue. This pass adds one true-RGBA,\n"
        "-- vertex-lit company stencil over most of the broad side of each ordinary container.",
        "-- gritty neutral hull and procedural section hue. This pass adds one alpha-tested,\n"
        "-- dithered company stencil over most of the broad side of each ordinary container.",
    )
    text = text.replace(
        'string.format("lod_container_spray_atlas_%02d_v7", atlasIndex)',
        'string.format("lod_container_spray_atlas_%02d_v8", atlasIndex)',
    )
    text = text.replace(
        '["$translucent"] = "1",\n            ["$vertexcolor"] = "1",',
        '["$alphatest"] = "1",\n            ["$alphatestreference"] = "0.500",\n            ["$vertexcolor"] = "1",',
    )
    text = text.replace(
        "mode=vertexlit-spray-v7-rgba-direct",
        "mode=vertexlit-spray-v8-alphatest-dither",
    )
    text = text.replace(
        'hook.Add("PostDrawTranslucentRenderables", "LOD_DrawContainerBranding", function()',
        'hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerBranding", function()',
    )
    if '["$alphatest"] = "1"' not in text or '["$translucent"] = "1"' in text:
        raise SystemExit("V8 branding alpha-test patch did not converge")
    BRANDING.write_text(text, encoding="utf-8")


def patch_recolor() -> None:
    text = RECOLOR.read_text(encoding="utf-8")
    text = text.replace(
        'local MATERIAL_VERSION = "v12_grit_runtime_binding"',
        'local MATERIAL_VERSION = "v13_grit_stable_apply"',
    )
    old = '''    local matName = sectionMaterialName(section)\n    local wanted = "!" .. matName\n    local changed = false\n\n    if model:GetMaterial() ~= wanted then\n        model:SetMaterial(wanted)\n        changed = true\n    end\n'''
    new = '''    local matName = sectionMaterialName(section)\n    local wanted = "!" .. matName\n    local changed = false\n\n    -- ClientSideModel:GetMaterial() does not reliably echo dynamic !material names.\n    -- Cache our own applied material identity so reconciliation can actually settle.\n    if instance.appliedSectionMaterialName ~= matName then\n        model:SetMaterial(wanted)\n        instance.appliedSectionMaterialName = matName\n        changed = true\n    end\n'''
    if old in text:
        text = text.replace(old, new, 1)
    elif "instance.appliedSectionMaterialName ~= matName" not in text:
        raise SystemExit("V8 recolor application anchor missing")

    old_status = '''            if normalizedMaterialOverride(model) == wantedName then\n                correct = correct + 1\n            else\n                wrong = wrong + 1\n            end\n'''
    new_status = '''            if IsValid(model) and instance.appliedSectionMaterialName == wantedName then\n                correct = correct + 1\n            else\n                wrong = wrong + 1\n            end\n'''
    if old_status in text:
        text = text.replace(old_status, new_status, 1)
    elif "instance.appliedSectionMaterialName == wantedName" not in text:
        raise SystemExit("V8 recolor status anchor missing")
    RECOLOR.write_text(text, encoding="utf-8")


def main() -> None:
    dither_atlases()
    patch_branding()
    patch_recolor()
    print("V8 alpha-test/dither branding and stable recolor application patched.")


if __name__ == "__main__":
    main()
