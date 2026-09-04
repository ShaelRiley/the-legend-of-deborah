#!/usr/bin/env python3
"""Wire V14/V19 minimal stock Source materials into the live cargo recolor path."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"
VERSION = "v19_stock_hl2_minimal"
BASE = "metal/metalwall001a"
NORMAL = "models/props_wasteland/cargo_container01_normal"


def one(text: str, old: str, new: str, label: str) -> str:
    n = text.count(old)
    if n != 1:
        raise SystemExit(f"{label}: expected 1 occurrence, found {n}")
    return text.replace(old, new, 1)


def patch_recolor() -> bool:
    text = RECOLOR.read_text(encoding="utf-8")
    if f'MATERIAL_VERSION = "{VERSION}"' in text:
        return False

    text = one(text, 'local DETAIL_PATH = "detail/detail_noise1"\n', '', "detail path")
    text = one(text, 'local DETAIL_BLEND_FACTOR = 0.12\n', '', "detail blend")
    text = one(text, 'local DETAIL_SCALE = 4.00\n', '', "detail scale")
    text = one(text, 'local COLOR_REPLACE_BLEND = 0.72', 'local COLOR_REPLACE_BLEND = 0.68', "color blend")
    text = one(text, 'local MATERIAL_VERSION = "v18_stock_hl2_metalwall"', f'local MATERIAL_VERSION = "{VERSION}"', "version")
    text = text.replace('v18_h%03d_s%d', 'v19_h%03d_s%d')
    text = text.replace('mode=stock-hl2-vtf', 'mode=stock-hl2-minimal')

    old_comment = '''-- V18 VMTs reference only mounted stock HL2/GMod textures. There is no custom VTF
-- in the live hull path: metalwall001a supplies neutral worn steel, the cargo normal
-- map supplies the model-specific ridges, and detail_noise1 adds restrained grime.'''
    new_comment = '''-- V19 deliberately uses the smallest safe Source shader stack: one guaranteed stock
-- HL2 metal diffuse plus the stock cargo normal map. No custom texture, detail sampler,
-- phong, envmap, or runtime texture binding can turn the hull black.'''
    if old_comment in text:
        text = text.replace(old_comment, new_comment, 1)

    old_detail_diag = '''    print(string.format(
        "[LOD:CONTAINER-DETAIL] source=%s mode=stock-hl2-minimal blend=%.2f",
        DETAIL_PATH, DETAIL_BLEND_FACTOR
    ))
'''
    if old_detail_diag in text:
        text = text.replace(old_detail_diag, '    print("[LOD:CONTAINER-DETAIL] mode=disabled-by-design")\n', 1)
    else:
        old_detail_diag = '''    print(string.format(
        "[LOD:CONTAINER-DETAIL] source=%s mode=stock-hl2-vtf blend=%.2f",
        DETAIL_PATH, DETAIL_BLEND_FACTOR
    ))
'''
        text = one(text, old_detail_diag, '    print("[LOD:CONTAINER-DETAIL] mode=disabled-by-design")\n', "detail diagnostic")

    old_stock = '''    print(string.format(
        "[LOD:CONTAINER-STOCK] material=%s shader=%s expected=%s actual=%s base=%s normal=%s detail=%s",
        sampleMaterialOK and "ok" or "error",
        sampleShader,
        sampleName,
        sampleActual,
        HULL_PATH,
        "models/props_wasteland/cargo_container01_normal",
        DETAIL_PATH
    ))'''
    new_stock = '''    print(string.format(
        "[LOD:CONTAINER-STOCK] material=%s shader=%s expected=%s actual=%s base=%s normal=%s detail=disabled",
        sampleMaterialOK and "ok" or "error",
        sampleShader,
        sampleName,
        sampleActual,
        HULL_PATH,
        "models/props_wasteland/cargo_container01_normal"
    ))'''
    text = one(text, old_stock, new_stock, "stock diagnostic")

    forbidden = ("DETAIL_PATH", "DETAIL_BLEND_FACTOR", "DETAIL_SCALE", "v18_h%03d_s%d", "container_blank_hull_v12", "container_grit_detail_v12")
    found = [token for token in forbidden if token in text]
    if found:
        raise SystemExit(f"V14 runtime still contains risky/stale texture tokens: {found}")
    RECOLOR.write_text(text, encoding="utf-8")
    return True


def patch_docs() -> bool:
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V14 minimal stock Source hull"
    if marker in text:
        return False
    appendix = f'''\n\n{marker}\n\nV14 is the black-texture containment build. The stock-asset audit found no verified blank cargo skin, so ordinary container hulls use only `{BASE}` plus the cargo model's native `{NORMAL}` normal map. The section VMTs contain no `$detail`, phong, envmap, custom VTF, PNG binding, or dynamic material creation. This deliberately minimizes Source shader dependencies while preserving procedural `$color2` section hue and physical cargo corrugation.\n\nGenerated materials are `v19_*` and runtime reports `materialVersion={VERSION}`. Expected diagnostics: `[LOD:CONTAINER-GLOBAL] ... override=ok`, `[LOD:CONTAINER-STOCK] material=ok`, `[LOD:CONTAINER-DETAIL] mode=disabled-by-design`, and `wrong=0`. The V8 alpha-tested company sprays and exact two-container wall stack are unchanged.\n'''
    DOCS.write_text(text.rstrip() + appendix, encoding="utf-8")
    return True


def main() -> None:
    print(f"V14 patch runtime_changed={patch_recolor()} docs_changed={patch_docs()}")


if __name__ == "__main__":
    main()
