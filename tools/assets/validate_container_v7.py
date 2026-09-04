#!/usr/bin/env python3
"""Validate V7 true-alpha branding and safe gritty hull presentation."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[2]
SURFACE_DIR = REPO_ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_surfaces"
)
BRAND_LUA = REPO_ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
RECOLOR_LUA = REPO_ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"


def validate_rgba_atlases() -> None:
    for atlas_index in range(1, 5):
        path = SURFACE_DIR / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        image = Image.open(path)
        if image.mode != "RGBA":
            raise SystemExit(f"{path.name}: expected true RGBA, got {image.mode}")
        if image.size != (4096, 1024):
            raise SystemExit(f"{path.name}: wrong dimensions {image.size}")
        alpha = image.getchannel("A")
        lo, hi = alpha.getextrema()
        if lo != 0 or hi < 220:
            raise SystemExit(f"{path.name}: invalid alpha range {lo}..{hi}")
        histogram = alpha.histogram()
        total = image.width * image.height
        transparent = histogram[0]
        if transparent < total * 0.50:
            raise SystemExit(
                f"{path.name}: too little transparent area ({transparent}/{total})"
            )
        if path.stat().st_size < 100000:
            raise SystemExit(f"{path.name}: suspiciously small RGBA output")


def validate_branding_lua() -> None:
    text = BRAND_LUA.read_text(encoding="utf-8")
    required = (
        'lod_container_spray_atlas_%02d_v7',
        '["$basetexture"] = "vgui/white"',
        'material:SetTexture("$basetexture", texture)',
        'mode=vertexlit-spray-v7-rgba-direct',
        '["$translucent"] = "1"',
        '["$vertexalpha"] = "1"',
        'mesh.TexCoord(0, u, v)',
    )
    for token in required:
        if token not in text:
            raise SystemExit(f"branding Lua missing token: {token}")
    if '["$basetexture"] = texture:GetName()' in text:
        raise SystemExit("legacy texture-name round trip is still live")


def validate_recolor_lua() -> None:
    text = RECOLOR_LUA.read_text(encoding="utf-8")
    required = (
        'MATERIAL_VERSION = "v12_grit_runtime_binding"',
        'material:SetTexture("$detail", detailTexture)',
        'DETAIL_AVAILABLE and "runtime-texture" or "flat-fallback"',
        'local function normalizedMaterialOverride(model)',
        'normalizedMaterialOverride(model) == wantedName',
    )
    for token in required:
        if token not in text:
            raise SystemExit(f"recolor Lua missing token: {token}")


def main() -> None:
    validate_rgba_atlases()
    validate_branding_lua()
    validate_recolor_lua()
    print("V7 true-RGBA branding, direct ITexture binding, and recolor diagnostics validated.")


if __name__ == "__main__":
    main()
