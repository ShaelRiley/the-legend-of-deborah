#!/usr/bin/env python3
"""Validate V14/V19 minimal stock Source cargo materials and runtime wiring."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SECTIONS = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_sections"
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"
BASE = "metal/metalwall001a"
NORMAL = "models/props_wasteland/cargo_container01_normal"
VERSION = "v19_stock_hl2_minimal"


def require(text: str, tokens: tuple[str, ...], label: str) -> None:
    missing = [x for x in tokens if x not in text]
    if missing:
        raise SystemExit(f"{label} missing: {missing}")


def forbid(text: str, tokens: tuple[str, ...], label: str) -> None:
    found = [x for x in tokens if x in text]
    if found:
        raise SystemExit(f"{label} forbidden: {found}")


def validate_materials() -> None:
    files = sorted(SECTIONS.glob("v19_h???_s?.vmt"))
    if len(files) != 360:
        raise SystemExit(f"V19 VMT count={len(files)}, expected=360")
    if any(SECTIONS.glob("v1[678]_h???_s?.vmt")):
        raise SystemExit("stale V16/V17/V18 section materials remain")
    for path in (files[0], files[137], files[-1]):
        text = path.read_text(encoding="utf-8")
        require(text, ('"VertexLitGeneric"', f'"$basetexture" "{BASE}"', f'"$bumpmap" "{NORMAL}"', '"$color2" "[', '"$blendtintcoloroverbase" "0.680"'), path.name)
        forbid(text, ('$detail', '$phong', '$envmap', 'container_blank_hull', 'container_grit_detail', 'Northern', 'Petroleum'), path.name)


def validate_runtime() -> None:
    recolor = RECOLOR.read_text(encoding="utf-8")
    require(recolor, (f'local HULL_PATH = "{BASE}"', f'local MATERIAL_VERSION = "{VERSION}"', 'materialKey = string.format("v19_h%03d_s%d", hue, shellIndex)', 'model:SetSubMaterial()', 'model:SetMaterial(matName)', 'instance.appliedSectionMode = "file-backed-global"', 'mode=stock-hl2-minimal', '[LOD:CONTAINER-GLOBAL]', '[LOD:CONTAINER-STOCK]', '[LOD:CONTAINER-DETAIL] mode=disabled-by-design'), "recolor")
    forbid(recolor, ('DETAIL_PATH', 'DETAIL_BLEND_FACTOR', 'DETAIL_SCALE', 'CreateMaterial(', 'runtime-texture', 'container_blank_hull_v12', 'container_grit_detail_v12', 'v18_h%03d_s%d'), "recolor")

    branding = BRANDING.read_text(encoding="utf-8")
    require(branding, ('mode=vertexlit-spray-v8-alphatest-dither', '["$alphatest"] = "1"', 'SIDE_WIDTH_FRACTION = 0.86'), "branding")

    walls = WALLS.read_text(encoding="utf-8")
    require(walls, ('local STACK_VISUAL_GAP = 4', 'local stackCount = 2', 'local expectedVisuals = #(Wall.logical or {}) * 2'), "walls")

    docs = DOCS.read_text(encoding="utf-8")
    require(docs, ('## V14 minimal stock Source hull', BASE, NORMAL, VERSION, 'disabled-by-design'), "docs")


def main() -> None:
    validate_materials()
    validate_runtime()
    print("V14 validated: 360 minimal stock Source VMTs, no detail/phong/custom textures, global override, V8 sprays, two-container invariant.")


if __name__ == "__main__":
    main()
