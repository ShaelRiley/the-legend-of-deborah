#!/usr/bin/env python3
"""Validate V13 stock-HL2 container hull presentation."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MATERIAL_ROOT = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah"
SECTIONS = MATERIAL_ROOT / "container_sections"
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"

BASE = "metal/metalwall001a"
NORMAL = "models/props_wasteland/cargo_container01_normal"
DETAIL = "detail/detail_noise1"
VERSION = "v18_stock_hl2_metalwall"


def require(text: str, tokens: tuple[str, ...], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{label} missing tokens: {missing}")


def forbid(text: str, tokens: tuple[str, ...], label: str) -> None:
    found = [token for token in tokens if token in text]
    if found:
        raise SystemExit(f"{label} forbidden tokens: {found}")


def validate_materials() -> None:
    files = sorted(SECTIONS.glob("v18_h???_s?.vmt"))
    if len(files) != 360:
        raise SystemExit(f"V18 section VMT count={len(files)}, expected=360")

    expected = {
        f"v18_h{hue:03d}_s{shell}.vmt"
        for hue in range(0, 360, 5)
        for shell in range(1, 6)
    }
    actual = {path.name for path in files}
    if actual != expected:
        raise SystemExit(
            f"V18 identity mismatch missing={sorted(expected-actual)[:8]} "
            f"extra={sorted(actual-expected)[:8]}"
        )

    if list(SECTIONS.glob("v16_h???_s?.vmt")) or list(SECTIONS.glob("v17_h???_s?.vmt")):
        raise SystemExit("stale V16/V17 section VMTs remain")

    required = (
        '"VertexLitGeneric"',
        f'"$basetexture" "{BASE}"',
        f'"$bumpmap" "{NORMAL}"',
        f'"$detail" "{DETAIL}"',
        '"$blendtintcoloroverbase" "0.720"',
        '"$detailblendfactor" "0.120"',
        '"$detailscale" "4.000"',
        '"$color2" "[',
    )
    forbidden = (
        "container_blank_hull_v11",
        "container_blank_hull_v12",
        "container_grit_detail_v11",
        "container_grit_detail_v12",
        "Northern",
        "Petroleum",
    )
    for path in (files[0], files[137], files[-1]):
        text = path.read_text(encoding="utf-8")
        require(text, required, path.name)
        forbid(text, forbidden, path.name)


def validate_runtime() -> None:
    recolor = RECOLOR.read_text(encoding="utf-8")
    require(
        recolor,
        (
            f'local HULL_PATH = "{BASE}"',
            f'local DETAIL_PATH = "{DETAIL}"',
            f'local MATERIAL_VERSION = "{VERSION}"',
            'materialKey = string.format("v18_h%03d_s%d", hue, shellIndex)',
            'model:SetSubMaterial()',
            'model:SetMaterial(matName)',
            'instance.appliedSectionMode = "file-backed-global"',
            'mode=stock-hl2-vtf',
            '[LOD:CONTAINER-GLOBAL]',
            '[LOD:CONTAINER-STOCK]',
            f'"{NORMAL}"',
        ),
        "recolor",
    )
    forbid(
        recolor,
        (
            "CreateMaterial(",
            "runtime-texture",
            "file-backed-bgr888",
            "container_blank_hull_v12",
            "container_grit_detail_v12",
            "v17_h%03d_s%d",
        ),
        "recolor",
    )

    branding = BRANDING.read_text(encoding="utf-8")
    require(
        branding,
        (
            "mode=vertexlit-spray-v8-alphatest-dither",
            '["$alphatest"] = "1"',
            "SIDE_WIDTH_FRACTION = 0.86",
        ),
        "branding",
    )

    walls = WALLS.read_text(encoding="utf-8")
    require(
        walls,
        (
            "local STACK_VISUAL_GAP = 4",
            "local stackCount = 2",
            "local expectedVisuals = #(Wall.logical or {}) * 2",
        ),
        "wall visuals",
    )

    docs = DOCS.read_text(encoding="utf-8")
    require(
        docs,
        (
            "## V13 stock HL2 neutral-metal hull",
            "cargo_container01",
            BASE,
            NORMAL,
            DETAIL,
            VERSION,
        ),
        "docs",
    )


def main() -> None:
    validate_materials()
    validate_runtime()
    print(
        "V13 validated: 360 stock-HL2-backed VertexLitGeneric section materials; "
        "neutral metalwall diffuse, exact cargo normal, restrained stock detail, "
        "global model override, two-container invariant, V8 sprays retained."
    )


if __name__ == "__main__":
    main()
