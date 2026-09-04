#!/usr/bin/env python3
"""Apply the V6 runtime-safe grime binding to the Garry's Mod client material.

Garry's Mod can mount PNG material assets and expose their $basetexture as an
ITexture. Source cannot reliably round-trip that ITexture's internal name through
a dynamic material's string-valued $detail parameter: it may reinterpret the name
as a standalone .vtf path. V6 establishes a valid white detail sampler first and
then binds the already-loaded ITexture object directly with IMaterial:SetTexture.
"""

from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
RECOLOR_PATH = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
DOCS_PATH = ROOT / "docs/CONTAINER_BRANDING.md"


def patch_recolor() -> bool:
    text = RECOLOR_PATH.read_text(encoding="utf-8")
    if 'v12_grit_runtime_binding' in text:
        required = (
            'DETAIL_FALLBACK_TEXTURE = "vgui/white"',
            'material:SetTexture("$detail", detailTexture)',
            'material:SetFloat("$detailblendfactor", DETAIL_BLEND_FACTOR)',
            '[LOD:CONTAINER-DETAIL]',
        )
        missing = [token for token in required if token not in text]
        if missing:
            raise SystemExit(f"partial V6 recolor wiring: {missing}")
        return False

    header_pattern = re.compile(
        r'local NP_BASE_TEXTURE = "vgui/white"\n'
        r'local NP_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"\n'
        r'.*?'
        r'local MATERIAL_VERSION = "v11_gritty_neutral"\n',
        re.S,
    )
    header = '''local NP_BASE_TEXTURE = "vgui/white"
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
local MATERIAL_VERSION = "v12_grit_runtime_binding"
'''
    text, count = header_pattern.subn(header, text, count=1)
    if count != 1:
        raise SystemExit(f"V6 grit header replacement count={count}")

    material_pattern = re.compile(
        r'    local params = \{\n.*?CreateMaterial\(name, "VertexLitGeneric", params\)\n',
        re.S,
    )
    material = '''    local params = {
        ["$basetexture"] = NP_BASE_TEXTURE,
        ["$bumpmap"] = NP_NORMAL_TEXTURE,
        ["$surfaceprop"] = "metal",
        ["$model"] = "1",
        ["$allowdiffusemodulation"] = "1",
        ["$blendtintbybasealpha"] = "0",
        ["$blendtintcoloroverbase"] = string.format("%.3f", COLOR_REPLACE_BLEND),
        ["$color2"] = string.format("[%.5f %.5f %.5f]", r, g, b),
        ["$detail"] = DETAIL_FALLBACK_TEXTURE,
        ["$detailblendmode"] = "0",
        ["$detailblendfactor"] = "0.000",
        ["$detailscale"] = string.format("%.3f", DETAIL_SCALE),
        ["$phong"] = "1",
        ["$phongexponent"] = "18",
        ["$phongboost"] = "0.16",
        ["$phongfresnelranges"] = "[0.02 0.08 0.35]"
    }
    local material = CreateMaterial(name, "VertexLitGeneric", params)
    if material and not material:IsError() and DETAIL_AVAILABLE then
        -- The mounted PNG is already a valid ITexture. Bind that object directly;
        -- never feed its internal name back through Source's .vtf resolver.
        material:SetTexture("$detail", detailTexture)
        material:SetFloat("$detailblendfactor", DETAIL_BLEND_FACTOR)
        material:SetFloat("$detailscale", DETAIL_SCALE)
        if material.Recompute then material:Recompute() end
    end
'''
    text, count = material_pattern.subn(material, text, count=1)
    if count != 1:
        raise SystemExit(f"V6 material replacement count={count}")

    text = text.replace(
        '-- Shader-native section recoloring for the gritty neutral cargo surface.',
        '-- Shader-native section recoloring with safely bound gritty metal detail.',
        1,
    )

    status_anchor = '    ))\nend)'
    status = '''    ))
    print(string.format(
        "[LOD:CONTAINER-DETAIL] source=%s mode=%s blend=%.2f",
        DETAIL_PATH,
        DETAIL_AVAILABLE and "runtime-texture" or "flat-fallback",
        DETAIL_AVAILABLE and DETAIL_BLEND_FACTOR or 0
    ))
end)'''
    index = text.rfind(status_anchor)
    if index < 0:
        raise SystemExit("V6 detail status anchor missing")
    text = text[:index] + status + text[index + len(status_anchor):]

    forbidden = ('detailTexture:GetName()', 'params["$detail"] = DETAIL_TEXTURE', 'local DETAIL_TEXTURE =')
    present = [token for token in forbidden if token in text]
    if present:
        raise SystemExit(f"unsafe V5 detail binding survived patch: {present}")

    RECOLOR_PATH.write_text(text, encoding="utf-8")
    return True


def patch_docs() -> bool:
    text = DOCS_PATH.read_text(encoding="utf-8")
    marker = "## V6 safe grit texture binding"
    if marker in text:
        return False
    text += '''

## V6 safe grit texture binding

The V5 Steam Deck playtest proved the 4096x1024 full-side spray atlas and orientation fix: company text became readable and correctly oriented. It also exposed a Source-material interoperability bug. Garry's Mod can mount the committed `container_grit_detail.png` as an `ITexture`, but passing that texture's internal name back into a dynamic material's `$detail` string caused Source to reinterpret it as a standalone `.vtf` path. The missing sampler rendered the hull black.

V6 keeps the PNG asset and removes that failure mode. `cl_container_section_recolor.lua` creates every section material with a guaranteed-valid white detail fallback, then assigns the already-loaded PNG `ITexture` directly with `IMaterial:SetTexture("$detail", detailTexture)`. No generated texture name is round-tripped through Source's filesystem resolver. If the grit texture is unavailable for any reason, detail blending remains zero and the hull degrades to the colored, normal-mapped flat fallback instead of black.

`lod_container_recolor_status` also prints `[LOD:CONTAINER-DETAIL]`. Production should report `mode=runtime-texture`; `mode=flat-fallback` is safe but indicates the optional grime layer did not bind.
'''
    DOCS_PATH.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    recolor_changed = patch_recolor()
    docs_changed = patch_docs()
    print(f"V6 patch applied: recolor_changed={recolor_changed} docs_changed={docs_changed}")


if __name__ == "__main__":
    main()
