#!/usr/bin/env python3
"""Build the V9 truly blank shipping-container hull texture.

This texture is deliberately company-free. It supplies the visual information that a
uniform white diffuse could not: broad corrugated steel ridges, frame seams, grime,
water streaks, abrasion and scratches. The runtime shader applies the authoritative
floor/quadrant hue on top, and the stock HL2 cargo-container normal map remains the
physical relief source.

The design is deterministic and UV-agnostic on purpose. There are no large semantic
blocks or logos that can land on the wrong model island; only repeating metal detail
plus subdued seams/wear. This makes it safe with the stock cargo_container01 UVs.
"""

from __future__ import annotations

import argparse
import hashlib
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
RUNTIME_DIR = ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_surfaces"
)
SIZE = (1024, 1024)
SEED = 0xD3B0B1A9


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_blank_hull(path: Path) -> None:
    width, height = SIZE
    rr = random.Random(SEED)
    rng = np.random.default_rng(SEED)

    yy, xx = np.mgrid[0:height, 0:width]

    # Neutral painted steel. The repeating vertical waveform survives arbitrary UV
    # islands without introducing company-specific silhouettes or checkerboards.
    period = 28.0
    phase = (xx % period) / period
    corrugation = (
        18.0 * np.cos(phase * math.tau)
        + 6.5 * np.cos(phase * math.tau * 2.0)
        + 2.0 * np.cos(phase * math.tau * 3.0)
    )

    # Low/mid-frequency paint and dirt variation. Keep the range centered around
    # neutral gray so $color2 can own hue while luminance detail remains visible.
    coarse = rng.normal(0.0, 1.0, (64, 64)).astype(np.float32)
    medium = rng.normal(0.0, 1.0, (256, 256)).astype(np.float32)
    coarse_img = Image.fromarray(np.uint8(np.clip(128 + coarse * 34, 0, 255)), "L")
    medium_img = Image.fromarray(np.uint8(np.clip(128 + medium * 24, 0, 255)), "L")
    coarse_arr = np.asarray(
        coarse_img.resize(SIZE, Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(8.0)),
        dtype=np.float32,
    ) - 128.0
    medium_arr = np.asarray(
        medium_img.resize(SIZE, Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(2.4)),
        dtype=np.float32,
    ) - 128.0

    grain = rng.normal(0.0, 2.8, (height, width))
    value = 132.0 + corrugation + coarse_arr * 0.34 + medium_arr * 0.24 + grain
    value = np.clip(value, 70, 190).astype(np.uint8)
    image = Image.fromarray(value, "L")

    # Repeating frame/seam language. These are intentionally thin and periodic,
    # unlike the old texture's large logo/card regions, so UV reuse stays benign.
    draw = ImageDraw.Draw(image)
    for x in range(0, width, 256):
        draw.rectangle((x, 0, min(width - 1, x + 4), height - 1), fill=91)
        if x + 9 < width:
            draw.line((x + 9, 0, x + 9, height - 1), fill=164, width=1)
    for y in (8, 126, 512, 896, 1015):
        y0 = max(0, min(height - 1, y))
        draw.rectangle((0, y0, width - 1, min(height - 1, y0 + 3)), fill=88)
        if y0 + 5 < height:
            draw.line((0, y0 + 5, width - 1, y0 + 5), fill=158, width=1)

    # Dark oily blooms and vertical drainage streaks.
    grime = Image.new("L", SIZE, 0)
    gd = ImageDraw.Draw(grime)
    for _ in range(100):
        cx = rr.randrange(width)
        cy = rr.randrange(height)
        rx = rr.randrange(18, 120)
        ry = rr.randrange(8, 74)
        gd.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=rr.randrange(14, 66))
    grime = grime.filter(ImageFilter.GaussianBlur(18.0))

    streaks = Image.new("L", SIZE, 0)
    sd = ImageDraw.Draw(streaks)
    for _ in range(115):
        x = rr.randrange(width)
        y0 = rr.randrange(height)
        length = rr.randrange(45, 480)
        sd.line(
            (x, y0, x + rr.randrange(-4, 5), min(height - 1, y0 + length)),
            fill=rr.randrange(12, 54),
            width=rr.randrange(1, 7),
        )
    streaks = streaks.filter(ImageFilter.GaussianBlur(4.8))

    arr = np.asarray(image, dtype=np.float32)
    arr -= np.asarray(grime, dtype=np.float32) * 0.38
    arr -= np.asarray(streaks, dtype=np.float32) * 0.42
    arr = np.clip(arr, 52, 196).astype(np.uint8)
    image = Image.fromarray(arr, "L")

    # Scratches and chipped paint. Paired bright/dark marks give a shallow scored
    # metal impression even before the stock normal map contributes lighting.
    draw = ImageDraw.Draw(image)
    for _ in range(310):
        x0 = rr.randrange(width)
        y0 = rr.randrange(height)
        length = rr.randrange(5, 92)
        rise = rr.choice((-2, -1, 0, 0, 0, 0, 1, 2))
        x1 = min(width - 1, x0 + length)
        y1 = max(0, min(height - 1, y0 + rise))
        draw.line((x0, y0, x1, y1), fill=rr.randrange(154, 205), width=1)
        if y0 + 1 < height and y1 + 1 < height:
            draw.line((x0, y0 + 1, x1, y1 + 1), fill=rr.randrange(58, 96), width=1)

    image = image.filter(ImageFilter.GaussianBlur(0.22)).convert("RGB")
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True, compress_level=9)

    gray = image.convert("L")
    low, high = gray.getextrema()
    stddev = float(np.asarray(gray, dtype=np.float32).std())
    print(
        f"{path.name}: {width}x{height} blank corrugated hull "
        f"range={low}..{high} stddev={stddev:.2f} bytes={path.stat().st_size} "
        f"sha256={sha256(path)}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        type=Path,
        default=RUNTIME_DIR / "container_blank_hull_v9.png",
    )
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    build_blank_hull(output)


if __name__ == "__main__":
    main()
