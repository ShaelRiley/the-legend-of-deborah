#!/usr/bin/env python3
"""Validate V8 alpha-tested full-side container branding."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SURFACE = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_surfaces"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"


def main() -> None:
    for number in range(1, 5):
        path = SURFACE / f"container_brand_spray_atlas_{number:02d}.png"
        image = Image.open(path)
        if image.mode != "RGBA" or image.size != (4096, 1024):
            raise SystemExit(f"{path.name}: expected RGBA 4096x1024, got {image.mode} {image.size}")
        alpha = image.getchannel("A")
        values = set(alpha.getdata())
        if not values.issubset({0, 255}) or values != {0, 255}:
            raise SystemExit(f"{path.name}: V8 alpha must be binary, got sample={sorted(values)[:8]}")

    branding = BRANDING.read_text(encoding="utf-8")
    required = (
        '["$alphatest"] = "1"',
        '["$alphatestreference"] = "0.500"',
        'lod_container_spray_atlas_%02d_v8',
        'mode=vertexlit-spray-v8-alphatest-dither',
        'hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerBranding"',
        'material:SetTexture("$basetexture", texture)',
        'SIDE_WIDTH_FRACTION = 0.86',
    )
    for token in required:
        if token not in branding:
            raise SystemExit(f"branding missing V8 token: {token}")
    if '["$translucent"] = "1"' in branding:
        raise SystemExit("translucent spray path still active")

    recolor = RECOLOR.read_text(encoding="utf-8")
    required_recolor = (
        'v13_grit_stable_apply',
        'instance.appliedSectionMaterialName ~= matName',
        'instance.appliedSectionMaterialName = matName',
        'instance.appliedSectionMaterialName == wantedName',
        'DETAIL_BLEND_FACTOR = 0.64',
        'material:SetTexture("$detail", detailTexture)',
    )
    for token in required_recolor:
        if token not in recolor:
            raise SystemExit(f"recolor missing V8 token: {token}")

    print("V8 validated: binary alpha-tested spray cards, direct atlas texture binding, gritty hull, stable material reconciliation.")


if __name__ == "__main__":
    main()
