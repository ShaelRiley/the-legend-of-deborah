#!/usr/bin/env python3
"""Build compact Garry's Mod runtime atlases from the authored 256-brand source ZIP.

Requires Pillow. The source archive remains authoritative; these atlases are a
presentation/runtime derivative that keeps transparent decal pixels so the game's
procedural floor/quadrant hull coloration remains visible beneath each brand.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import struct
from pathlib import Path
from zipfile import ZipFile

from PIL import Image

BRAND_COUNT = 256
ATLAS_COUNT = 4
BRANDS_PER_ATLAS = 64
ATLAS_COLUMNS = 8
ATLAS_ROWS = 8
CELL_SIZE = (64, 32)
ATLAS_SIZE = (512, 256)
SOURCE_SIZE = (1024, 512)
PALETTE_COLORS = 7
ALPHA_THRESHOLD = 64


def locate_prefix(names: list[str]) -> str:
    suffix = "textures/container_brand_001.png"
    matches = [name[: -len(suffix)] for name in names if name.endswith(suffix)]
    if len(matches) != 1:
        raise SystemExit("could not uniquely locate textures/container_brand_001.png")
    return matches[0]


def validate_png(payload: bytes, brand_id: int) -> Image.Image:
    if payload[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"brand {brand_id:03d}: invalid PNG signature")
    if len(payload) < 24:
        raise SystemExit(f"brand {brand_id:03d}: truncated PNG")
    width, height = struct.unpack(">II", payload[16:24])
    if (width, height) != SOURCE_SIZE:
        raise SystemExit(
            f"brand {brand_id:03d}: expected {SOURCE_SIZE[0]}x{SOURCE_SIZE[1]}, "
            f"got {width}x{height}"
        )
    return Image.open(io.BytesIO(payload)).convert("RGBA")


def quantize_with_transparency(image: Image.Image) -> Image.Image:
    """Reduce RGB entropy while reserving palette index 0 for transparency."""
    alpha = image.getchannel("A")
    quantized = image.convert("RGB").quantize(
        colors=PALETTE_COLORS,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.FLOYDSTEINBERG,
    )

    qbytes = quantized.tobytes()
    abytes = alpha.tobytes()
    indexed = bytes(
        (q + 1) if a >= ALPHA_THRESHOLD else 0
        for q, a in zip(qbytes, abytes)
    )

    out = Image.frombytes("P", image.size, indexed)
    palette = [0, 0, 0] + quantized.getpalette()[: PALETTE_COLORS * 3]
    palette.extend([0, 0, 0] * (256 - (PALETTE_COLORS + 1)))
    out.putpalette(palette)
    out.info["transparency"] = 0
    return out


def build(source_zip: Path, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    with ZipFile(source_zip) as archive:
        names = archive.namelist()
        prefix = locate_prefix(names)
        expected = {
            f"{prefix}textures/container_brand_{brand_id:03d}.png"
            for brand_id in range(1, BRAND_COUNT + 1)
        }
        present = {
            name
            for name in names
            if name.startswith(f"{prefix}textures/container_brand_")
            and name.endswith(".png")
        }
        if present != expected:
            missing = sorted(expected - present)
            extra = sorted(present - expected)
            raise SystemExit(
                f"source texture set mismatch: missing={len(missing)} extra={len(extra)}"
            )

        for atlas_index in range(ATLAS_COUNT):
            canvas = Image.new("RGBA", ATLAS_SIZE, (0, 0, 0, 0))
            for cell in range(BRANDS_PER_ATLAS):
                brand_id = atlas_index * BRANDS_PER_ATLAS + cell + 1
                name = f"{prefix}textures/container_brand_{brand_id:03d}.png"
                decal = validate_png(archive.read(name), brand_id)
                decal = decal.resize(CELL_SIZE, Image.Resampling.LANCZOS)
                x = (cell % ATLAS_COLUMNS) * CELL_SIZE[0]
                y = (cell // ATLAS_COLUMNS) * CELL_SIZE[1]
                canvas.alpha_composite(decal, (x, y))

            atlas = quantize_with_transparency(canvas)
            output = output_dir / f"container_brand_atlas_{atlas_index + 1:02d}.png"
            atlas.save(output, optimize=True, compress_level=9, transparency=0)
            digest = hashlib.sha256(output.read_bytes()).hexdigest()
            print(f"{output.name}: {output.stat().st_size} bytes sha256={digest}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_zip", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    build(args.source_zip, args.output_dir)


if __name__ == "__main__":
    main()
