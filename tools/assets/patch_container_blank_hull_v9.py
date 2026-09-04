#!/usr/bin/env python3
"""Patch the runtime to use the generated truly blank V9 cargo hull.

V9 removes the final Northern Petroleum dependency from the hull diffuse. The new
blank RGB texture is loaded as an ITexture and bound directly to every dynamic
section material. The stock normal map remains because it contains only physical
surface relief, not company art.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def patch_recolor() -> None:
    text = RECOLOR.read_text(encoding="utf-8")

    old_intro = '''-- Shader-native section recoloring with safely bound gritty metal detail.
--
-- The runtime diffuse is uniform and logo-free. VertexLitGeneric color replacement
-- owns the full hull hue while the validated cargo mesh and stock normal map retain relief.
-- Company identity is no longer baked into the diffuse; it is rendered separately
-- as a vertex-lit spray-paint mask on ordinary containers.

--
-- Section colors are generated uniquely for the ACTUAL sections in this maze. The
-- entire hue circle is legal: Red, Yellow and Blue are no longer reserved. A seeded
-- hybrid maximin solver combines CIE Lab perceptual distance with circular hue
-- distance, so every maze uses a broad spectrum rather than several brightness
-- variants of the same few hues. No section color repeats within a generated maze.
-- The diffuse is deliberately UV-agnostic. Mesh geometry plus the stock normal map
-- provide container relief; a uniform white base guarantees that no baked company
-- art, source-image blocks, or checkerboard structure can leak into the hull color.
local NP_BASE_TEXTURE = "vgui/white"
local NP_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"
local DETAIL_PATH = "legend_of_deborah/container_surfaces/container_grit_detail.png"
local DETAIL_FALLBACK_TEXTURE = "vgui/white"
local detailSourceMaterial = Material(DETAIL_PATH, "smooth mips")
local detailTexture = nil
if detailSourceMaterial and not detailSourceMaterial:IsError() then
    detailTexture = detailSourceMaterial:GetTexture("$basetexture")
end
local DETAIL_AVAILABLE = detailTexture ~= nil
local DETAIL_BLEND_FACTOR = 0.64
local DETAIL_SCALE = 1.00
local COLOR_REPLACE_BLEND = 1.00
local MIN_SECTION_SATURATION = 0.82
local MIN_SECTION_VALUE = 0.80
local RECONCILE_BATCH_SIZE = 192
local MATERIAL_VERSION = "v13_grit_stable_apply"
'''

    new_intro = '''-- Shader-native section recoloring over a truly blank gritty cargo hull.
--
-- V9 removes the final Northern Petroleum diffuse dependency. The repository ships
-- a deterministic company-free corrugated steel texture, while the stock normal map
-- remains solely for physical surface relief. Company identity is rendered later as
-- an alpha-tested spray mask and therefore never has to conceal baked stock branding.
--
-- Section colors are generated uniquely for the ACTUAL sections in this maze. The
-- entire hue circle is legal: Red, Yellow and Blue are no longer reserved. A seeded
-- hybrid maximin solver combines CIE Lab perceptual distance with circular hue
-- distance, so every maze uses a broad spectrum rather than several brightness
-- variants of the same few hues. No section color repeats within a generated maze.
local HULL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v9.png"
local HULL_FALLBACK_TEXTURE = "vgui/white"
local HULL_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"
local hullSourceMaterial = Material(HULL_PATH, "smooth mips")
local hullTexture = nil
if hullSourceMaterial and not hullSourceMaterial:IsError() then
    hullTexture = hullSourceMaterial:GetTexture("$basetexture")
end
local HULL_AVAILABLE = hullTexture ~= nil

local DETAIL_PATH = "legend_of_deborah/container_surfaces/container_grit_detail.png"
local DETAIL_FALLBACK_TEXTURE = "vgui/white"
local detailSourceMaterial = Material(DETAIL_PATH, "smooth mips")
local detailTexture = nil
if detailSourceMaterial and not detailSourceMaterial:IsError() then
    detailTexture = detailSourceMaterial:GetTexture("$basetexture")
end
local DETAIL_AVAILABLE = detailTexture ~= nil
local DETAIL_BLEND_FACTOR = 0.40
local DETAIL_SCALE = 1.00
-- Preserve authored steel luminance while the procedural section color remains
-- unmistakable. Full replacement made the safe white-base experiment look cel-shaded.
local COLOR_REPLACE_BLEND = 0.78
local MIN_SECTION_SATURATION = 0.82
local MIN_SECTION_VALUE = 0.80
local RECONCILE_BATCH_SIZE = 192
local MATERIAL_VERSION = "v14_blank_hull_v9"
'''

    if 'MATERIAL_VERSION = "v14_blank_hull_v9"' not in text:
        if old_intro not in text:
            raise SystemExit("V9 recolor intro anchor not found")
        text = text.replace(old_intro, new_intro, 1)

    text = text.replace(
        'local name = "lod_np_section_" .. MATERIAL_VERSION .. "_" .. key',
        'local name = "lod_container_section_" .. MATERIAL_VERSION .. "_" .. key',
        1,
    )
    text = text.replace(
        '["$basetexture"] = NP_BASE_TEXTURE,',
        '["$basetexture"] = HULL_FALLBACK_TEXTURE,',
        1,
    )
    text = text.replace(
        '["$bumpmap"] = NP_NORMAL_TEXTURE,',
        '["$bumpmap"] = HULL_NORMAL_TEXTURE,',
        1,
    )

    old_bind = '''    local material = CreateMaterial(name, "VertexLitGeneric", params)
    if material and not material:IsError() and DETAIL_AVAILABLE then
        -- The mounted PNG is already a valid ITexture. Bind that object directly;
        -- never feed its internal name back through Source's .vtf resolver.
        material:SetTexture("$detail", detailTexture)
        material:SetFloat("$detailblendfactor", DETAIL_BLEND_FACTOR)
        material:SetFloat("$detailscale", DETAIL_SCALE)
        if material.Recompute then material:Recompute() end
    end
'''
    new_bind = '''    local material = CreateMaterial(name, "VertexLitGeneric", params)
    if material and not material:IsError() then
        -- Mounted PNGs are valid ITextures. Bind the blank hull directly so Source
        -- never reinterprets its internal name as a missing .vtf path.
        if HULL_AVAILABLE then
            material:SetTexture("$basetexture", hullTexture)
        end
        if DETAIL_AVAILABLE then
            material:SetTexture("$detail", detailTexture)
            material:SetFloat("$detailblendfactor", DETAIL_BLEND_FACTOR)
            material:SetFloat("$detailscale", DETAIL_SCALE)
        end
        if material.Recompute then material:Recompute() end
    end
'''
    if 'material:SetTexture("$basetexture", hullTexture)' not in text:
        if old_bind not in text:
            raise SystemExit("V9 material binding anchor not found")
        text = text.replace(old_bind, new_bind, 1)

    detail_print = '''    print(string.format(
        "[LOD:CONTAINER-DETAIL] source=%s mode=%s blend=%.2f",
        DETAIL_PATH,
        DETAIL_AVAILABLE and "runtime-texture" or "flat-fallback",
        DETAIL_AVAILABLE and DETAIL_BLEND_FACTOR or 0
    ))
'''
    hull_and_detail = '''    print(string.format(
        "[LOD:CONTAINER-HULL] source=%s mode=%s blend=%.2f",
        HULL_PATH,
        HULL_AVAILABLE and "runtime-texture" or "white-fallback",
        COLOR_REPLACE_BLEND
    ))
    print(string.format(
        "[LOD:CONTAINER-DETAIL] source=%s mode=%s blend=%.2f",
        DETAIL_PATH,
        DETAIL_AVAILABLE and "runtime-texture" or "flat-fallback",
        DETAIL_AVAILABLE and DETAIL_BLEND_FACTOR or 0
    ))
'''
    if '[LOD:CONTAINER-HULL]' not in text:
        if detail_print not in text:
            raise SystemExit("V9 diagnostic anchor not found")
        text = text.replace(detail_print, hull_and_detail, 1)

    RECOLOR.write_text(text, encoding="utf-8")


def patch_docs() -> None:
    text = DOCS.read_text(encoding="utf-8")
    if "## V9 truly blank cargo hull" in text:
        return

    addition = r'''

## V9 truly blank cargo hull

The V8 Steam Deck playtest proved the alpha-tested spray system: company marks are
legible, deterministic, full-side, correctly oriented and no longer create an opaque
black card. It also made the remaining limitation explicit: using the stock Northern
Petroleum diffuse underneath still leaves the baked `NP / Northern Petrol` art visible.

V9 removes that dependency completely. `tools/assets/build_container_blank_hull_v9.py`
deterministically generates `container_blank_hull_v9.png`, a 1024x1024 company-free
painted-steel substrate containing only physical surface information: repeating
corrugation luminance, thin frame/seam language, dirty blooms, drainage streaks,
scratches and chipped-paint scoring. It contains no company name, logo, serial block
or other semantic rectangle that can land on the wrong UV island.

`cl_container_section_recolor.lua` mounts that PNG and binds its loaded `ITexture`
directly to `$basetexture`. Procedural floor/quadrant `$color2` tint remains
authoritative, but the blend is intentionally below total replacement so the blank
steel luminance survives. The stock `cargo_container01_normal` is retained because it
contains physical corrugation/frame relief rather than branding. The existing neutral
`container_grit_detail.png` remains a lower-strength secondary dirt layer.

The production composition is now:

1. repository-owned truly blank corrugated steel hull;
2. deterministic procedural floor/quadrant hue;
3. neutral grime/scratch detail and stock normal-map relief;
4. V8 alpha-tested company spray on ordinary containers only;
5. plywood wayfinding plate instead of company spray on marked containers.

There is no stock Northern Petroleum diffuse or runtime concealment rectangle in the
ordinary-container presentation path.

Runtime diagnostics should report:

- `materialVersion=v14_blank_hull_v9`
- `[LOD:CONTAINER-HULL] ... mode=runtime-texture blend=0.78`
- `[LOD:CONTAINER-DETAIL] ... mode=runtime-texture blend=0.40`
- `mode=vertexlit-spray-v8-alphatest-dither`
- `wrong=0`
'''
    DOCS.write_text(text.rstrip() + addition + "\n", encoding="utf-8")


def main() -> None:
    patch_recolor()
    patch_docs()
    print("V9 blank hull runtime patch applied.")


if __name__ == "__main__":
    main()
