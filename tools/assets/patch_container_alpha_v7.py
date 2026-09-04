#!/usr/bin/env python3
"""Patch V7 container spray transparency and recolor diagnostics.

V7 keeps the V5/V6 presentation architecture but fixes the last broad-face failure:
Garry's Mod was receiving the indexed PNG atlas through a material-name round trip,
which rendered the transparent card background as opaque black on some clients.

The patch converts the generated atlases to true RGBA PNGs, binds their loaded
ITexture objects directly to the dynamic VertexLitGeneric, and normalizes the
material-name comparison used by the recolor diagnostic.
"""

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


def convert_atlases_to_rgba() -> None:
    for atlas_index in range(1, 5):
        path = SURFACE_DIR / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        image = Image.open(path).convert("RGBA")
        image.save(path, optimize=True, compress_level=9)
        alpha = image.getchannel("A")
        low, high = alpha.getextrema()
        print(
            f"{path.name}: RGBA {image.size[0]}x{image.size[1]} "
            f"alpha={low}..{high} bytes={path.stat().st_size}"
        )


def patch_branding() -> None:
    text = BRAND_LUA.read_text(encoding="utf-8")

    old_material = '''    local material = CreateMaterial(
        string.format("lod_container_spray_atlas_%02d_v5", atlasIndex),
        "VertexLitGeneric",
        {
            ["$basetexture"] = texture:GetName(),
            ["$model"] = "1",
            ["$translucent"] = "1",
            ["$vertexcolor"] = "1",
            ["$vertexalpha"] = "1",
            ["$nocull"] = "1",
            ["$halflambert"] = "1"
        }
    )
    if not material or material:IsError() then return nil, path end

    atlasMaterialCache[atlasIndex] = material
'''

    new_material = '''    local material = CreateMaterial(
        string.format("lod_container_spray_atlas_%02d_v7", atlasIndex),
        "VertexLitGeneric",
        {
            -- Start from a guaranteed built-in texture, then bind the mounted PNG's
            -- ITexture directly. Never round-trip texture:GetName() through Source's
            -- VTF resolver: that was the source of the opaque black broad-side card.
            ["$basetexture"] = "vgui/white",
            ["$model"] = "1",
            ["$translucent"] = "1",
            ["$vertexcolor"] = "1",
            ["$vertexalpha"] = "1",
            ["$nocull"] = "1",
            ["$halflambert"] = "1"
        }
    )
    if not material or material:IsError() then return nil, path end
    material:SetTexture("$basetexture", texture)
    if material.Recompute then material:Recompute() end

    atlasMaterialCache[atlasIndex] = material
'''

    if 'lod_container_spray_atlas_%02d_v7' not in text:
        if old_material not in text:
            raise SystemExit("V7 branding material anchor not found")
        text = text.replace(old_material, new_material, 1)

    text = text.replace(
        "mode=vertexlit-spray-v5-fullside",
        "mode=vertexlit-spray-v7-rgba-direct",
    )
    text = text.replace(
        "-- Company identity is presentation-only. cl_container_section_recolor.lua owns the\n"
        "-- gritty neutral hull and procedural section hue. This pass adds one transparent,\n"
        "-- vertex-lit company stencil over most of the broad side of each ordinary container.",
        "-- Company identity is presentation-only. cl_container_section_recolor.lua owns the\n"
        "-- gritty neutral hull and procedural section hue. This pass adds one true-RGBA,\n"
        "-- vertex-lit company stencil over most of the broad side of each ordinary container.",
    )

    BRAND_LUA.write_text(text, encoding="utf-8")


def patch_recolor_diagnostic() -> None:
    text = RECOLOR_LUA.read_text(encoding="utf-8")

    helper = '''local function normalizedMaterialOverride(model)
    if not IsValid(model) then return "" end
    local actual = tostring(model:GetMaterial() or "")
    return string.gsub(actual, "^!", "")
end

'''
    anchor = 'concommand.Add("lod_container_recolor_status", function()\n'
    if "local function normalizedMaterialOverride(model)" not in text:
        if anchor not in text:
            raise SystemExit("V7 recolor diagnostic anchor not found")
        text = text.replace(anchor, helper + anchor, 1)

    old_check = '''            if IsValid(model) and model:GetMaterial() == ("!" .. wantedName) then
                correct = correct + 1
            else
                wrong = wrong + 1
            end
'''
    new_check = '''            if normalizedMaterialOverride(model) == wantedName then
                correct = correct + 1
            else
                wrong = wrong + 1
            end
'''
    if "normalizedMaterialOverride(model) == wantedName" not in text:
        if old_check not in text:
            raise SystemExit("V7 recolor status comparison anchor not found")
        text = text.replace(old_check, new_check, 1)

    RECOLOR_LUA.write_text(text, encoding="utf-8")


def main() -> None:
    convert_atlases_to_rgba()
    patch_branding()
    patch_recolor_diagnostic()
    print("V7 RGBA/direct-texture spray patch applied.")


if __name__ == "__main__":
    main()
