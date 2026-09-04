#!/usr/bin/env python3
"""Build robust file-backed BGR888 VTF/VMT cargo materials for V12.

V11 proved ordinary file-backed VMTs load, but runtime readback showed the per-slot
SetSubMaterial overrides were not actually sticking on the client model. V12 removes
that unnecessary layer: every cargo model uses one global file-backed VertexLitGeneric
material, because every stock material island should share the same blank hull.

The high-resolution VTF payload is also changed from custom DXT1 to simple BGR888.
That costs a few MB but removes block-compression/decoder ambiguity while we finish
this presentation system. The low-resolution VTF thumbnail remains valid DXT1.
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
HULL_VTF = SURFACES / "container_blank_hull_v12.vtf"
GRIT_VTF = SURFACES / "container_grit_detail_v12.vtf"

HULL_MATERIAL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v12"
GRIT_MATERIAL_PATH = "legend_of_deborah/container_surfaces/container_grit_detail_v12"
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
IMAGE_FORMAT_BGR888 = 3
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
    return np.array([
        round(r5 * 255 / 31),
        round(g6 * 255 / 63),
        round(b5 * 255 / 31),
    ], dtype=np.int16)


def encode_dxt1_grayscale(image: Image.Image) -> bytes:
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
                else:
                    c1 = max(0, c0 - 1)
            p0 = _rgb_from_565(c0)
            p1 = _rgb_from_565(c1)
            p2 = (2 * p0 + p1 + 1) // 3
            p3 = (p0 + 2 * p1 + 1) // 3
            palette = np.array([p0.mean(), p1.mean(), p2.mean(), p3.mean()], dtype=np.float32)
            indices = np.argmin(
                np.abs(block[:, None].astype(np.float32) - palette[None, :]), axis=1
            )
            bits = 0
            for pixel_index, palette_index in enumerate(indices):
                bits |= int(palette_index) << (2 * pixel_index)
            out.extend(struct.pack("<HHI", c0, c1, bits))
    return bytes(out)


def encode_bgr888(image: Image.Image) -> bytes:
    rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)
    return rgb[:, :, ::-1].tobytes(order="C")


def build_vtf(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGB")
    width, height = image.size
    if width & (width - 1) or height & (height - 1):
        raise SystemExit(f"VTF source must be power-of-two, got {image.size}: {source}")

    mip_count = int(math.log2(max(width, height))) + 1
    low_w = min(16, width)
    low_h = min(16, height)
    low_res = encode_dxt1_grayscale(image.resize((low_w, low_h), Image.Resampling.LANCZOS))

    mip_payloads: list[bytes] = []
    for shift in range(mip_count - 1, -1, -1):
        mip_w = max(1, width >> shift)
        mip_h = max(1, height >> shift)
        mip = image if (mip_w, mip_h) == image.size else image.resize(
            (mip_w, mip_h), Image.Resampling.LANCZOS
        )
        payload = encode_bgr888(mip)
        expected = mip_w * mip_h * 3
        if len(payload) != expected:
            raise SystemExit(f"BGR888 mip size={len(payload)} expected={expected}: {output.name}")
        mip_payloads.append(payload)

    reflectivity = tuple(float(v) / 255.0 for v in np.asarray(image).mean(axis=(0, 1)))
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
    header.extend(struct.pack("<I", IMAGE_FORMAT_BGR888))
    header.extend(struct.pack("<B", mip_count))
    header.extend(struct.pack("<I", IMAGE_FORMAT_DXT1))
    header.extend(struct.pack("<BBH", low_w, low_h, 1))
    header.extend(b"\0" * (VTF_HEADER_SIZE - len(header)))

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(bytes(header) + low_res + b"".join(mip_payloads))
    print(
        f"built {output.relative_to(ROOT)} size={output.stat().st_size} "
        f"mips={mip_count} high=BGR888 low=DXT1"
    )


def section_material_name(hue: int, shell_index: int) -> str:
    return f"v17_h{hue:03d}_s{shell_index}"


def build_section_materials() -> None:
    SECTIONS.mkdir(parents=True, exist_ok=True)
    for old in list(SECTIONS.glob("v16_*.vmt")) + list(SECTIONS.glob("v17_*.vmt")):
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
    if count != 360:
        raise SystemExit(f"section material count={count}, expected=360")
    print("built 360 V17 file-backed section VMTs")


def main() -> None:
    if not HULL_PNG.exists() or not GRIT_PNG.exists():
        raise SystemExit("source PNG assets missing")
    build_vtf(HULL_PNG, HULL_VTF)
    build_vtf(GRIT_PNG, GRIT_VTF)
    build_section_materials()


if __name__ == "__main__":
    main()
