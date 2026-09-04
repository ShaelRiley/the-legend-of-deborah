#!/usr/bin/env python3
"""Build file-backed VTF/VMT cargo-container materials for Source/Garry's Mod.

V10 proved that explicit SetSubMaterial() replacement is the correct way to evict the
stock Northern Petroleum skins, but it also proved that our Lua CreateMaterial()+PNG
ITexture path can render black on the actual client model. V11 removes both runtime
texture indirection and dynamic material creation from the hull path.

This script converts the already-authored blank hull and neutral grime PNGs into
standard VTF 7.2 / DXT1 textures, then emits one tiny file-backed VertexLitGeneric
VMT for every finite section-colour candidate used by cl_container_section_recolor.lua.
The runtime therefore selects ordinary Source materials by path, exactly like the
stock cargo container does, while keeping the same deterministic palette logic.
"""

from __future__ import annotations

import colorsys
import math
import struct
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MATERIAL_ROOT = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah"
SURFACES = MATERIAL_ROOT / "container_surfaces"
SECTIONS = MATERIAL_ROOT / "container_sections"

HULL_PNG = SURFACES / "container_blank_hull_v9.png"
GRIT_PNG = SURFACES / "container_grit_detail.png"
HULL_VTF = SURFACES / "container_blank_hull_v11.vtf"
GRIT_VTF = SURFACES / "container_grit_detail_v11.vtf"

HULL_MATERIAL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v11"
GRIT_MATERIAL_PATH = "legend_of_deborah/container_surfaces/container_grit_detail_v11"
NORMAL_PATH = "models/props_wasteland/cargo_container01_normal"

CANDIDATE_HUE_STEP = 5
CANDIDATE_SV = (
    (0.82, 0.80),
    (0.88, 0.90),
    (0.96, 0.98),
    (0.98, 0.82),
    (0.84, 0.98),
)
COLOR_REPLACE_BLEND = 0.78
DETAIL_BLEND_FACTOR = 0.40
DETAIL_SCALE = 1.00

VTF_HEADER_SIZE = 80
IMAGE_FORMAT_DXT1 = 13
TEXTUREFLAGS_TRILINEAR = 0x00000002
TEXTUREFLAGS_ANISOTROPIC = 0x00000010


def _gray565(value: int) -> int:
    value = max(0, min(255, int(value)))
    r5 = round(value * 31 / 255)
    g6 = round(value * 63 / 255)
    return (r5 << 11) | (g6 << 5) | r5


def _rgb_from_565(value: int) -> np.ndarray:
    r5 = (value >> 11) & 31
    g6 = (value >> 5) & 63
    b5 = value & 31
    return np.array(
        [round(r5 * 255 / 31), round(g6 * 255 / 63), round(b5 * 255 / 31)],
        dtype=np.int16,
    )


def encode_dxt1_grayscale(image: Image.Image) -> bytes:
    """Encode an opaque grayscale/RGB PIL image into deterministic DXT1 blocks."""
    arr = np.asarray(image.convert("L"), dtype=np.uint8)
    height, width = arr.shape
    padded_height = max(4, ((height + 3) // 4) * 4)
    padded_width = max(4, ((width + 3) // 4) * 4)
    padded = np.empty((padded_height, padded_width), dtype=np.uint8)
    padded[:height, :width] = arr
    if height < padded_height:
        padded[height:, :width] = arr[height - 1 : height, :]
    if width < padded_width:
        padded[:height, width:] = arr[:, width - 1 : width]
    if height < padded_height and width < padded_width:
        padded[height:, width:] = arr[height - 1, width - 1]

    out = bytearray()
    for by in range(0, padded_height, 4):
        for bx in range(0, padded_width, 4):
            block = padded[by : by + 4, bx : bx + 4].reshape(-1)
            c0 = _gray565(int(block.max()))
            c1 = _gray565(int(block.min()))
            if c0 <= c1:
                if c1 < 0xFFFF:
                    c0 = c1 + 1
                elif c0 > 0:
                    c1 = c0 - 1

            p0 = _rgb_from_565(c0)
            p1 = _rgb_from_565(c1)
            p2 = (2 * p0 + p1 + 1) // 3
            p3 = (p0 + 2 * p1 + 1) // 3
            palette = np.array(
                [p0.mean(), p1.mean(), p2.mean(), p3.mean()], dtype=np.float32
            )
            indices = np.argmin(
                np.abs(block[:, None].astype(np.float32) - palette[None, :]), axis=1
            )
            bits = 0
            for pixel_index, palette_index in enumerate(indices):
                bits |= int(palette_index) << (2 * pixel_index)
            out.extend(struct.pack("<HHI", c0, c1, bits))
    return bytes(out)


def build_vtf(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGB")
    width, height = image.size
    if width & (width - 1) or height & (height - 1):
        raise SystemExit(f"VTF source must be power-of-two, got {image.size}: {source}")

    mip_count = int(math.log2(max(width, height))) + 1
    low_w = min(16, width)
    low_h = min(16, height)
    low_res = encode_dxt1_grayscale(
        image.resize((low_w, low_h), Image.Resampling.LANCZOS)
    )

    mip_payloads: list[bytes] = []
    for shift in range(mip_count - 1, -1, -1):
        mip_w = max(1, width >> shift)
        mip_h = max(1, height >> shift)
        mip = image if (mip_w, mip_h) == image.size else image.resize(
            (mip_w, mip_h), Image.Resampling.LANCZOS
        )
        mip_payloads.append(encode_dxt1_grayscale(mip))

    reflectivity = tuple(
        float(value) / 255.0 for value in np.asarray(image).mean(axis=(0, 1))
    )
    flags = TEXTUREFLAGS_TRILINEAR | TEXTUREFLAGS_ANISOTROPIC

    header = bytearray()
    header.extend(b"VTF\0")
    header.extend(struct.pack("<II", 7, 2))
    header.extend(struct.pack("<I", VTF_HEADER_SIZE))
    header.extend(struct.pack("<HHIHH", width, height, flags, 1, 0))
    header.extend(b"\0" * 4)
    header.extend(struct.pack("<3f", *reflectivity))
    header.extend(b"\0" * 4)
    header.extend(struct.pack("<f", 1.0))
    header.extend(struct.pack("<I", IMAGE_FORMAT_DXT1))
    header.extend(struct.pack("<B", mip_count))
    header.extend(struct.pack("<I", IMAGE_FORMAT_DXT1))
    header.extend(struct.pack("<BBH", low_w, low_h, 1))
    if len(header) > VTF_HEADER_SIZE:
        raise SystemExit(f"VTF header overflow: {len(header)}")
    header.extend(b"\0" * (VTF_HEADER_SIZE - len(header)))

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(bytes(header) + low_res + b"".join(mip_payloads))

    expected_full = max(4, width) * max(4, height) // 2
    if len(mip_payloads[-1]) != expected_full:
        raise SystemExit(
            f"unexpected full DXT1 payload for {output.name}: {len(mip_payloads[-1])}"
        )
    print(
        f"built {output.relative_to(ROOT)} size={output.stat().st_size} "
        f"mips={mip_count} format=DXT1"
    )


def section_material_name(hue: int, shell_index: int) -> str:
    return f"v16_h{hue:03d}_s{shell_index}"


def build_section_materials() -> None:
    SECTIONS.mkdir(parents=True, exist_ok=True)
    for old in SECTIONS.glob("v16_*.vmt"):
        old.unlink()

    count = 0
    for hue in range(0, 360, CANDIDATE_HUE_STEP):
        for shell_index, (sat, val) in enumerate(CANDIDATE_SV, start=1):
            r, g, b = colorsys.hsv_to_rgb(hue / 360.0, sat, val)
            name = section_material_name(hue, shell_index)
            text = f'''"VertexLitGeneric"
{{
    "$basetexture" "{HULL_MATERIAL_PATH}"
    "$bumpmap" "{NORMAL_PATH}"
    "$surfaceprop" "metal"
    "$model" "1"
    "$allowdiffusemodulation" "1"
    "$blendtintbybasealpha" "0"
    "$blendtintcoloroverbase" "{COLOR_REPLACE_BLEND:.3f}"
    "$color2" "[{r:.6f} {g:.6f} {b:.6f}]"
    "$detail" "{GRIT_MATERIAL_PATH}"
    "$detailblendmode" "0"
    "$detailblendfactor" "{DETAIL_BLEND_FACTOR:.3f}"
    "$detailscale" "{DETAIL_SCALE:.3f}"
    "$phong" "1"
    "$phongexponent" "18"
    "$phongboost" "0.16"
    "$phongfresnelranges" "[0.02 0.08 0.35]"
}}
'''
            (SECTIONS / f"{name}.vmt").write_text(text, encoding="utf-8")
            count += 1
    expected = (360 // CANDIDATE_HUE_STEP) * len(CANDIDATE_SV)
    if count != expected:
        raise SystemExit(f"section material count={count}, expected={expected}")
    print(f"built {count} file-backed section VMTs")


def validate_vtf(path: Path, expected_size: tuple[int, int]) -> None:
    data = path.read_bytes()
    if len(data) < VTF_HEADER_SIZE or data[:4] != b"VTF\0":
        raise SystemExit(f"invalid VTF signature/header: {path}")
    major, minor = struct.unpack_from("<II", data, 4)
    header_size = struct.unpack_from("<I", data, 12)[0]
    width, height = struct.unpack_from("<HH", data, 16)
    image_format = struct.unpack_from("<I", data, 52)[0]
    mip_count = data[56]
    low_format = struct.unpack_from("<I", data, 57)[0]
    low_w, low_h = struct.unpack_from("<BB", data, 61)
    depth = struct.unpack_from("<H", data, 63)[0]
    if (major, minor) != (7, 2) or header_size != VTF_HEADER_SIZE:
        raise SystemExit(f"unsupported VTF header: {(major, minor)} size={header_size}")
    if (width, height) != expected_size:
        raise SystemExit(f"VTF dimensions={(width, height)} expected={expected_size}")
    if image_format != IMAGE_FORMAT_DXT1 or low_format != IMAGE_FORMAT_DXT1:
        raise SystemExit(f"VTF is not DXT1: high={image_format} low={low_format}")
    if mip_count != int(math.log2(max(width, height))) + 1:
        raise SystemExit(f"VTF mip count={mip_count}")
    if (low_w, low_h) != (min(16, width), min(16, height)) or depth != 1:
        raise SystemExit(f"VTF thumbnail/depth invalid: {(low_w, low_h, depth)}")


def main() -> None:
    if not HULL_PNG.exists() or not GRIT_PNG.exists():
        raise SystemExit("source PNG assets missing")
    build_vtf(HULL_PNG, HULL_VTF)
    build_vtf(GRIT_PNG, GRIT_VTF)
    validate_vtf(HULL_VTF, Image.open(HULL_PNG).size)
    validate_vtf(GRIT_VTF, Image.open(GRIT_PNG).size)
    build_section_materials()


if __name__ == "__main__":
    main()
