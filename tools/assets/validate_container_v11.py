#!/usr/bin/env python3
"""Validate V11 file-backed Source cargo materials and runtime wiring."""

from __future__ import annotations

import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MATERIAL_ROOT = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah"
SURFACES = MATERIAL_ROOT / "container_surfaces"
SECTIONS = MATERIAL_ROOT / "container_sections"
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"

VTF_HEADER_SIZE = 80
DXT1 = 13


def require(text: str, tokens: tuple[str, ...], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{label} missing tokens: {missing}")


def forbid(text: str, tokens: tuple[str, ...], label: str) -> None:
    found = [token for token in tokens if token in text]
    if found:
        raise SystemExit(f"{label} forbidden tokens: {found}")


def validate_vtf(path: Path, expected_width: int = 1024, expected_height: int = 1024) -> None:
    if not path.exists():
        raise SystemExit(f"missing VTF: {path}")
    data = path.read_bytes()
    if len(data) < VTF_HEADER_SIZE or data[:4] != b"VTF\0":
        raise SystemExit(f"invalid VTF signature/header: {path}")
    major, minor = struct.unpack_from("<II", data, 4)
    header_size = struct.unpack_from("<I", data, 12)[0]
    width, height = struct.unpack_from("<HH", data, 16)
    image_format = struct.unpack_from("<I", data, 52)[0]
    mip_count = data[56]
    low_format = struct.unpack_from("<I", data, 57)[0]
    low_width, low_height = struct.unpack_from("<BB", data, 61)
    depth = struct.unpack_from("<H", data, 63)[0]
    expected_mips = int(math.log2(max(expected_width, expected_height))) + 1
    if (major, minor) != (7, 2):
        raise SystemExit(f"VTF version={major}.{minor}: {path.name}")
    if header_size != VTF_HEADER_SIZE:
        raise SystemExit(f"VTF header size={header_size}: {path.name}")
    if (width, height) != (expected_width, expected_height):
        raise SystemExit(f"VTF dimensions={(width, height)}: {path.name}")
    if image_format != DXT1 or low_format != DXT1:
        raise SystemExit(f"VTF formats high={image_format} low={low_format}: {path.name}")
    if mip_count != expected_mips:
        raise SystemExit(f"VTF mips={mip_count} expected={expected_mips}: {path.name}")
    if (low_width, low_height, depth) != (16, 16, 1):
        raise SystemExit(
            f"VTF thumbnail/depth={(low_width, low_height, depth)}: {path.name}"
        )
    # 1024 DXT1 full mip chain plus thumbnail should be close to the stock cargo
    # VTF size. This catches a header-only or accidentally uncompressed output.
    if not 690_000 <= len(data) <= 710_000:
        raise SystemExit(f"VTF suspicious byte size={len(data)}: {path.name}")


def validate_section_materials() -> None:
    files = sorted(SECTIONS.glob("v16_h???_s?.vmt"))
    if len(files) != 360:
        raise SystemExit(f"section VMT count={len(files)} expected=360")
    expected_names = {
        f"v16_h{hue:03d}_s{shell}.vmt"
        for hue in range(0, 360, 5)
        for shell in range(1, 6)
    }
    actual_names = {path.name for path in files}
    if actual_names != expected_names:
        missing = sorted(expected_names - actual_names)[:8]
        extra = sorted(actual_names - expected_names)[:8]
        raise SystemExit(f"section VMT identity mismatch missing={missing} extra={extra}")

    required = (
        '"VertexLitGeneric"',
        '"$basetexture" "legend_of_deborah/container_surfaces/container_blank_hull_v11"',
        '"$bumpmap" "models/props_wasteland/cargo_container01_normal"',
        '"$detail" "legend_of_deborah/container_surfaces/container_grit_detail_v11"',
        '"$detailblendfactor" "0.400"',
        '"$blendtintcoloroverbase" "0.780"',
        '"$color2" "[',
    )
    for path in (files[0], files[137], files[-1]):
        text = path.read_text(encoding="utf-8")
        require(text, required, path.name)
        forbid(text, ("Northern", "Petroleum", "cargo_container01\""), path.name)


def validate_runtime() -> None:
    recolor = RECOLOR.read_text(encoding="utf-8")
    require(
        recolor,
        (
            'HULL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v11.vtf"',
            'DETAIL_PATH = "legend_of_deborah/container_surfaces/container_grit_detail_v11.vtf"',
            'SECTION_MATERIAL_PREFIX = "legend_of_deborah/container_sections/"',
            'MATERIAL_VERSION = "v16_filebacked_vtf"',
            'materialKey = string.format("v16_h%03d_s%d", hue, shellIndex)',
            'model:SetSubMaterial(slot, matName)',
            'model:GetSubMaterial(slot)',
            'instance.appliedSectionMode = "file-backed-submaterials"',
            '[LOD:CONTAINER-VTF]',
            'mode=file-backed-vtf',
        ),
        "recolor",
    )
    forbid(
        recolor,
        (
            "CreateMaterial(",
            'material:SetTexture("$basetexture"',
            'material:SetTexture("$detail"',
            '"!" .. matName',
            "runtime-texture",
        ),
        "recolor",
    )

    branding = BRANDING.read_text(encoding="utf-8")
    require(
        branding,
        (
            'mode=vertexlit-spray-v8-alphatest-dither',
            '["$alphatest"] = "1"',
            'SIDE_WIDTH_FRACTION = 0.86',
        ),
        "branding",
    )

    docs = DOCS.read_text(encoding="utf-8")
    require(
        docs,
        (
            "## V11 file-backed Source materials",
            "sampleSlots=3",
            "materialVersion=v16_filebacked_vtf",
            "file-backed-submaterials",
        ),
        "docs",
    )


def main() -> None:
    validate_vtf(SURFACES / "container_blank_hull_v11.vtf")
    validate_vtf(SURFACES / "container_grit_detail_v11.vtf")
    validate_section_materials()
    validate_runtime()
    print(
        "V11 validated: file-backed VTF/VMT hull and grit, 360 deterministic section "
        "materials, real submaterial verification, V8 sprays retained, no dynamic hull material."
    )


if __name__ == "__main__":
    main()
