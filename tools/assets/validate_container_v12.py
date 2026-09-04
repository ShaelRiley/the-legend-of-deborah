#!/usr/bin/env python3
"""Validate V12 global file-backed BGR888 Source cargo materials."""

from __future__ import annotations

import math
import struct
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MATERIAL_ROOT = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah"
SURFACES = MATERIAL_ROOT / "container_surfaces"
SECTIONS = MATERIAL_ROOT / "container_sections"
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"

VTF_HEADER_SIZE = 80
BGR888 = 3
DXT1 = 13


def require(text: str, tokens: tuple[str, ...], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{label} missing tokens: {missing}")


def forbid(text: str, tokens: tuple[str, ...], label: str) -> None:
    found = [token for token in tokens if token in text]
    if found:
        raise SystemExit(f"{label} forbidden tokens: {found}")


def validate_vtf(path: Path, source_png: Path) -> None:
    if not path.exists():
        raise SystemExit(f"missing VTF: {path}")
    data = path.read_bytes()
    if len(data) < VTF_HEADER_SIZE or data[:4] != b"VTF\0":
        raise SystemExit(f"invalid VTF signature/header: {path}")

    major, minor = struct.unpack_from("<II", data, 4)
    header_size = struct.unpack_from("<I", data, 12)[0]
    width, height = struct.unpack_from("<HH", data, 16)
    high_format = struct.unpack_from("<I", data, 52)[0]
    mip_count = data[56]
    low_format = struct.unpack_from("<I", data, 57)[0]
    low_width, low_height = struct.unpack_from("<BB", data, 61)
    depth = struct.unpack_from("<H", data, 63)[0]

    source = Image.open(source_png).convert("RGB")
    if (width, height) != source.size:
        raise SystemExit(f"VTF dimensions={(width, height)} source={source.size}: {path.name}")
    if (major, minor) != (7, 2) or header_size != VTF_HEADER_SIZE:
        raise SystemExit(f"VTF header invalid version={major}.{minor} size={header_size}")
    if high_format != BGR888 or low_format != DXT1:
        raise SystemExit(f"VTF formats high={high_format} low={low_format}: {path.name}")
    expected_mips = int(math.log2(max(width, height))) + 1
    if mip_count != expected_mips:
        raise SystemExit(f"VTF mips={mip_count} expected={expected_mips}: {path.name}")
    if (low_width, low_height, depth) != (16, 16, 1):
        raise SystemExit(f"VTF thumbnail/depth={(low_width, low_height, depth)}")

    # The largest mip is last in VTF 7.2 disk order. Decode BGR888 and compare it
    # exactly with the source PNG. This catches malformed-but-parseable VTF output.
    largest_bytes = width * height * 3
    if len(data) < largest_bytes:
        raise SystemExit(f"VTF too small for largest BGR888 mip: {path.name}")
    payload = data[-largest_bytes:]
    bgr = np.frombuffer(payload, dtype=np.uint8).reshape((height, width, 3))
    decoded = bgr[:, :, ::-1]
    source_arr = np.asarray(source, dtype=np.uint8)
    if not np.array_equal(decoded, source_arr):
        delta = np.abs(decoded.astype(np.int16) - source_arr.astype(np.int16))
        raise SystemExit(
            f"VTF largest mip differs from source: max={int(delta.max())} mean={float(delta.mean()):.4f}"
        )

    if not 4_190_000 <= len(data) <= 4_200_000:
        raise SystemExit(f"VTF suspicious BGR888 size={len(data)}: {path.name}")


def validate_section_materials() -> None:
    files = sorted(SECTIONS.glob("v17_h???_s?.vmt"))
    if len(files) != 360:
        raise SystemExit(f"V17 section VMT count={len(files)} expected=360")
    if list(SECTIONS.glob("v16_h???_s?.vmt")):
        raise SystemExit("stale V16 section VMTs survived V12 build")

    required = (
        '"VertexLitGeneric"',
        '"$basetexture" "legend_of_deborah/container_surfaces/container_blank_hull_v12"',
        '"$bumpmap" "models/props_wasteland/cargo_container01_normal"',
        '"$detail" "legend_of_deborah/container_surfaces/container_grit_detail_v12"',
        '"$detailblendfactor" "0.400"',
        '"$blendtintcoloroverbase" "0.780"',
        '"$color2" "[',
    )
    for path in (files[0], files[137], files[-1]):
        text = path.read_text(encoding="utf-8")
        require(text, required, path.name)
        forbid(text, ("Northern", "Petroleum"), path.name)


def validate_runtime() -> None:
    recolor = RECOLOR.read_text(encoding="utf-8")
    require(
        recolor,
        (
            'HULL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v12.vtf"',
            'DETAIL_PATH = "legend_of_deborah/container_surfaces/container_grit_detail_v12.vtf"',
            'MATERIAL_VERSION = "v17_filebacked_global_bgr888"',
            'materialKey = string.format("v17_h%03d_s%d", hue, shellIndex)',
            'model:SetSubMaterial()',
            'model:SetMaterial(matName)',
            'model:GetMaterial()',
            'instance.appliedSectionMode = "file-backed-global"',
            '[LOD:CONTAINER-GLOBAL]',
            'mode=file-backed-bgr888',
        ),
        "recolor",
    )
    forbid(
        recolor,
        (
            'model:SetSubMaterial(slot, matName)',
            'model:GetSubMaterial(slot)',
            'file-backed-submaterials',
            'allSectionSlotsMatch',
            'CreateMaterial(',
            'runtime-texture',
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
            "## V12 global BGR888 Source material",
            "materialVersion=v17_filebacked_global_bgr888",
            "override=ok",
            "BGR888",
        ),
        "docs",
    )


def main() -> None:
    validate_vtf(
        SURFACES / "container_blank_hull_v12.vtf",
        SURFACES / "container_blank_hull_v9.png",
    )
    validate_vtf(
        SURFACES / "container_grit_detail_v12.vtf",
        SURFACES / "container_grit_detail.png",
    )
    validate_section_materials()
    validate_runtime()
    print(
        "V12 validated: exact BGR888 VTF/source roundtrip, 360 V17 file-backed section "
        "materials, global model override, V8 sprays retained, no per-slot runtime path."
    )


if __name__ == "__main__":
    main()
