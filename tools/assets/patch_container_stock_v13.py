#!/usr/bin/env python3
"""Wire V13 stock HL2 metal textures into the live container recolor path."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"

VERSION = "v18_stock_hl2_metalwall"
BASE = "metal/metalwall001a"
NORMAL = "models/props_wasteland/cargo_container01_normal"
DETAIL = "detail/detail_noise1"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one occurrence, found {count}")
    return text.replace(old, new, 1)


def patch_recolor() -> bool:
    text = RECOLOR.read_text(encoding="utf-8")
    if f'MATERIAL_VERSION = "{VERSION}"' in text:
        required = (
            f'local HULL_PATH = "{BASE}"',
            f'local DETAIL_PATH = "{DETAIL}"',
            'materialKey = string.format("v18_h%03d_s%d", hue, shellIndex)',
            'model:SetSubMaterial()',
            'model:SetMaterial(matName)',
            'mode=stock-hl2-vtf',
            '[LOD:CONTAINER-STOCK]',
        )
        missing = [token for token in required if token not in text]
        if missing:
            raise SystemExit(f"partial V13 runtime wiring: {missing}")
        return False

    text = replace_once(
        text,
        'local HULL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v12.vtf"',
        f'local HULL_PATH = "{BASE}"',
        "stock base texture",
    )
    text = replace_once(
        text,
        'local DETAIL_PATH = "legend_of_deborah/container_surfaces/container_grit_detail_v12.vtf"',
        f'local DETAIL_PATH = "{DETAIL}"',
        "stock detail texture",
    )
    text = replace_once(text, 'local DETAIL_BLEND_FACTOR = 0.40', 'local DETAIL_BLEND_FACTOR = 0.12', "detail blend")
    text = replace_once(text, 'local DETAIL_SCALE = 1.00', 'local DETAIL_SCALE = 4.00', "detail scale")
    text = replace_once(text, 'local COLOR_REPLACE_BLEND = 0.78', 'local COLOR_REPLACE_BLEND = 0.72', "color blend")
    text = replace_once(
        text,
        'local MATERIAL_VERSION = "v17_filebacked_global_bgr888"',
        f'local MATERIAL_VERSION = "{VERSION}"',
        "material version",
    )

    # The finite deterministic palette remains identical; only its material file
    # generation changes from custom VTF-backed V17 to stock-HL2-backed V18.
    count = text.count('v17_h%03d_s%d')
    if count < 1:
        raise SystemExit("no V17 material-key format found")
    text = text.replace('v17_h%03d_s%d', 'v18_h%03d_s%d')

    text = text.replace('mode=file-backed-bgr888', 'mode=stock-hl2-vtf')
    text = text.replace('[LOD:CONTAINER-VTF]', '[LOD:CONTAINER-STOCK]')

    old_intro = '''-- V9 removes the final Northern Petroleum diffuse dependency. The repository ships
-- a deterministic company-free corrugated steel texture, while the stock normal map
-- remains solely for physical surface relief. Company identity is rendered later as
-- an alpha-tested spray mask and therefore never has to conceal baked stock branding.'''
    new_intro = '''-- V13 removes custom hull texture decoding from the runtime entirely. Online and
-- stock-content audits found that the three HL2 cargo-container skins are all branded,
-- so the hull uses guaranteed stock neutral HL2 metalwall001a as its diffuse while the
-- exact stock cargo normal map supplies corrugation relief. Company identity remains
-- a separate alpha-tested spray and never has to conceal baked stock branding.'''
    if old_intro in text:
        text = text.replace(old_intro, new_intro, 1)

    old_material_comment = '''-- File-backed Source VTF/VMT materials replace V10's runtime PNG ITexture binding.
-- The authored neutral hull still owns luminance/grime while each prebuilt VMT owns
-- one deterministic section tint from the finite maximin candidate set.'''
    new_material_comment = '''-- V18 VMTs reference only mounted stock HL2/GMod textures. There is no custom VTF
-- in the live hull path: metalwall001a supplies neutral worn steel, the cargo normal
-- map supplies the model-specific ridges, and detail_noise1 adds restrained grime.'''
    if old_material_comment in text:
        text = text.replace(old_material_comment, new_material_comment, 1)

    # Add an explicit source diagnostic next to the global override verification.
    needle = '''    print(string.format(
        "[LOD:CONTAINER-STOCK] material=%s shader=%s expected=%s actual=%s",
        sampleMaterialOK and "ok" or "error",
        sampleShader,
        sampleName,
        sampleActual
    ))
end)'''
    replacement = '''    print(string.format(
        "[LOD:CONTAINER-STOCK] material=%s shader=%s expected=%s actual=%s base=%s normal=%s detail=%s",
        sampleMaterialOK and "ok" or "error",
        sampleShader,
        sampleName,
        sampleActual,
        HULL_PATH,
        "''' + NORMAL + '''",
        DETAIL_PATH
    ))
end)'''
    text = replace_once(text, needle, replacement, "stock diagnostic")

    forbidden = (
        "container_blank_hull_v12",
        "container_grit_detail_v12",
        "file-backed-bgr888",
        "v17_filebacked_global_bgr888",
    )
    found = [token for token in forbidden if token in text]
    if found:
        raise SystemExit(f"V13 runtime still references custom V12 hull path: {found}")

    RECOLOR.write_text(text, encoding="utf-8")
    return True


def patch_docs() -> bool:
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V13 stock HL2 neutral-metal hull"
    if marker in text:
        return False

    appendix = f'''

{marker}

The V12 Steam Deck test still produced black broad faces. For V13 the implementation
stopped iterating on custom hull encoders and audited mounted Source/Garry's Mod assets
instead. Core Half-Life 2 ships `cargo_container01`, `cargo_container02`, and
`cargo_container03`, but all three are Northern Petrol-branded skins; Counter-Strike:
Source's `de_port` cargo family is also branded and is not a safe base-game dependency.
There is therefore no verified, guaranteed, truly blank stock shipping-container skin.

V13 uses a stronger stock-only composition. The procedural section VMTs use
`{BASE}` as a neutral worn industrial diffuse, retain
`{NORMAL}` for the cargo model's exact corrugation and frame relief, and add the
very restrained `{DETAIL}` detail texture. These are mounted stock Source textures,
so the live hull no longer depends on any hand-built VTF or runtime PNG texture path.
The V8 alpha-tested company spray remains separate and unchanged.

The finite maximin palette is unchanged, but its generated files are now `v18_*` and
`materialVersion={VERSION}`. The runtime continues to clear stale submaterials and
uses one global file-backed `VertexLitGeneric` override for the entire cargo model.
Expected diagnostics include `mode=stock-hl2-vtf`, `[LOD:CONTAINER-GLOBAL] ...
override=ok`, `[LOD:CONTAINER-STOCK] material=ok`, and `wrong=0`.
'''
    DOCS.write_text(text.rstrip() + appendix.rstrip() + "\n", encoding="utf-8")
    return True


def main() -> None:
    changed_runtime = patch_recolor()
    changed_docs = patch_docs()
    print(f"V13 patch complete runtime_changed={changed_runtime} docs_changed={changed_docs}")


if __name__ == "__main__":
    main()
