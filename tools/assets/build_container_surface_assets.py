#!/usr/bin/env python3
"""Build V5 shipping-container presentation assets for The Legend of Deborah.

The runtime hull is intentionally company-neutral. A deterministic grayscale detail
map supplies dirt, streaks, abrasion and chipped-paint variation while the Source
cargo mesh and stock normal map supply the physical corrugation. Section hue remains
shader-owned at runtime.

Company identity is rebuilt into four transparent 4096x1024 spray atlases. Each
512x128 cell uses the authored compact emblem plus native-resolution company name
and slogan, producing a wide stencil treatment designed to occupy most of one real
container side without an opaque signboard.
"""

from __future__ import annotations

import argparse
import hashlib
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps

REPO_ROOT = Path(__file__).resolve().parents[2]
BRAND_COUNT = 256
ATLAS_COUNT = 4
BRANDS_PER_ATLAS = 64
ATLAS_COLUMNS = 8
ATLAS_ROWS = 8
SOURCE_CELL_SIZE = (64, 32)
SOURCE_ATLAS_SIZE = (512, 256)
SPRAY_CELL_SIZE = (512, 128)
SPRAY_ATLAS_SIZE = (4096, 1024)
DETAIL_SIZE = (1024, 1024)
RUNTIME_DIR = REPO_ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_surfaces"
)
COMPACT_BRAND_DIR = REPO_ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_brands"
)
BRAND_NAMES_PATH = REPO_ROOT / "tools/assets/container_brand_names.tsv"

FONT_BOLD_CANDIDATES = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf",
    "/usr/share/fonts/dejavu/DejaVuSansCondensed-Bold.ttf",
)
FONT_REGULAR_CANDIDATES = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf",
    "/usr/share/fonts/dejavu/DejaVuSans.ttf",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def resolve_font_path(candidates: tuple[str, ...], label: str) -> str:
    for candidate in candidates:
        if Path(candidate).exists():
            return candidate
    raise SystemExit(f"{label} font is required to build container paint")


def build_grit_detail(output: Path) -> None:
    """Create deterministic neutral grime with 128 gray as the Mod2X neutral point."""
    width, height = DETAIL_SIZE
    rng = np.random.default_rng(0xD3B0A5)

    coarse = rng.normal(128.0, 34.0, (64, 64)).clip(0, 255).astype(np.uint8)
    medium = rng.normal(128.0, 24.0, (256, 256)).clip(0, 255).astype(np.uint8)
    coarse_image = Image.fromarray(coarse, "L").resize(
        DETAIL_SIZE, Image.Resampling.BICUBIC
    ).filter(ImageFilter.GaussianBlur(5.0))
    medium_image = Image.fromarray(medium, "L").resize(
        DETAIL_SIZE, Image.Resampling.BICUBIC
    ).filter(ImageFilter.GaussianBlur(1.8))

    coarse_arr = np.asarray(coarse_image, dtype=np.float32) - 128.0
    medium_arr = np.asarray(medium_image, dtype=np.float32) - 128.0
    grain = rng.normal(0.0, 4.0, (height, width))
    base = 128.0 + coarse_arr * 0.70 + medium_arr * 0.38 + grain
    image = Image.fromarray(np.uint8(np.clip(base, 74, 178)), "L")

    # Broad oily/rust-dark grime blooms. They stay grayscale so arbitrary section
    # hues remain authoritative rather than inheriting one fixed rust color.
    grime = Image.new("L", DETAIL_SIZE, 0)
    grime_draw = ImageDraw.Draw(grime)
    rr = random.Random(0xD3B0A5)
    for _ in range(82):
        cx = rr.randrange(width)
        cy = rr.randrange(height)
        rx = rr.randrange(12, 92)
        ry = rr.randrange(7, 66)
        value = rr.randrange(22, 78)
        grime_draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=value)
    grime = grime.filter(ImageFilter.GaussianBlur(13.0))

    streaks = Image.new("L", DETAIL_SIZE, 0)
    streak_draw = ImageDraw.Draw(streaks)
    for _ in range(64):
        x = rr.randrange(width)
        y0 = rr.randrange(height)
        length = rr.randrange(70, 520)
        strength = rr.randrange(18, 60)
        streak_draw.line((x, y0, x + rr.randrange(-3, 4), min(height, y0 + length)),
                         fill=strength, width=rr.randrange(2, 9))
    streaks = streaks.filter(ImageFilter.GaussianBlur(5.5))

    arr = np.asarray(image, dtype=np.float32)
    arr -= np.asarray(grime, dtype=np.float32) * 0.58
    arr -= np.asarray(streaks, dtype=np.float32) * 0.46
    arr = np.clip(arr, 62, 182).astype(np.uint8)
    image = Image.fromarray(arr, "L")

    # Fine scratches and chipped edges stay sharp enough to survive Source filtering.
    scratch = ImageDraw.Draw(image)
    for _ in range(230):
        x0 = rr.randrange(width)
        y0 = rr.randrange(height)
        length = rr.randrange(5, 74)
        slope = rr.choice((-1, 0, 0, 0, 0, 1))
        x1 = min(width - 1, x0 + length)
        y1 = max(0, min(height - 1, y0 + slope * rr.randrange(0, 5)))
        scratch.line((x0, y0, x1, y1), fill=rr.randrange(148, 188),
                     width=rr.choice((1, 1, 1, 2)))
        if rr.random() < 0.58 and y0 + 1 < height and y1 + 1 < height:
            scratch.line((x0, y0 + 1, x1, y1 + 1), fill=rr.randrange(68, 106), width=1)

    image = image.filter(ImageFilter.GaussianBlur(0.30))
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, optimize=True, compress_level=9)
    print(f"{output.name}: {width}x{height} neutral grime detail extrema={image.getextrema()}")


def load_brand_catalog(path: Path) -> dict[int, tuple[str, str]]:
    rows: dict[int, tuple[str, str]] = {}
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        parts = line.split("\t", 2)
        if len(parts) != 3:
            raise SystemExit(f"{path}:{line_number}: expected id, name, slogan")
        brand_id = int(parts[0])
        rows[brand_id] = (parts[1].strip(), parts[2].strip())

    expected = set(range(1, BRAND_COUNT + 1))
    if set(rows) != expected:
        raise SystemExit(
            f"brand catalog mismatch: missing={sorted(expected - set(rows))} "
            f"extra={sorted(set(rows) - expected)}"
        )
    return rows


def _components(mask: np.ndarray) -> list[list[tuple[int, int]]]:
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    found: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if not mask[y, x] or seen[y, x]:
                continue
            stack = [(x, y)]
            seen[y, x] = True
            points: list[tuple[int, int]] = []
            while stack:
                px, py = stack.pop()
                points.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if (0 <= nx < width and 0 <= ny < height
                            and mask[ny, nx] and not seen[ny, nx]):
                        seen[ny, nx] = True
                        stack.append((nx, ny))
            found.append(points)
    return found


def extract_icon_mask(cell: Image.Image) -> Image.Image:
    """Recover authored emblem strokes while discarding tiny card borders/text."""
    crop = cell.convert("RGBA").crop((0, 0, 24, 32))
    alpha = np.asarray(crop.getchannel("A"), dtype=np.float32) / 255.0
    luma = np.asarray(ImageOps.grayscale(crop), dtype=np.float32) / 255.0
    binary = (alpha > 0.08) & (luma > 0.36)

    kept: list[tuple[int, int]] = []
    for points in _components(binary):
        if len(points) < 3:
            continue
        xs = [p[0] for p in points]
        ys = [p[1] for p in points]
        x0, x1 = min(xs), max(xs) + 1
        y0, y1 = min(ys), max(ys) + 1
        w, h = x1 - x0, y1 - y0
        cx = (x0 + x1) * 0.5
        cy = (y0 + y1) * 0.5

        # Full-card variants contribute long one-pixel frame lines and corner bolts.
        if h >= 20 and w <= 3:
            continue
        if w >= 18 and h <= 3:
            continue
        if cx < 4 and (cy < 7 or cy > 25) and len(points) < 24:
            continue
        if cx > 21:
            continue
        kept.extend(points)

    mask = Image.new("L", crop.size, 0)
    if kept:
        pixels = mask.load()
        for x, y in kept:
            pixels[x, y] = int(max(96, min(255, luma[y, x] * alpha[y, x] * 255)))
    else:
        # Safe fallback for unusually fragmented emblems.
        fallback = np.power(luma, 1.4) * alpha
        mask = Image.fromarray(np.uint8(np.clip(fallback * 255.0, 0, 255)), "L")

    bbox = mask.getbbox()
    return mask.crop(bbox) if bbox else Image.new("L", (1, 1), 0)


def fit_name(draw: ImageDraw.ImageDraw, text: str, font_path: str, max_width: int) -> ImageFont.FreeTypeFont:
    for size in range(48, 21, -1):
        font = ImageFont.truetype(font_path, size)
        bbox = draw.textbbox((0, 0), text, font=font)
        if bbox[2] - bbox[0] <= max_width:
            return font
    return ImageFont.truetype(font_path, 21)


def fit_slogan(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont,
               max_width: int) -> str:
    candidate = text
    while candidate and draw.textbbox((0, 0), candidate, font=font)[2] > max_width:
        if len(candidate) <= 8:
            return ""
        candidate = candidate[:-4].rstrip() + "..."
    return candidate


def build_spray_cell(source_cell: Image.Image, brand_id: int, company_name: str,
                     slogan: str, bold_path: str, regular_path: str) -> Image.Image:
    width, height = SPRAY_CELL_SIZE
    cell = Image.new("L", SPRAY_CELL_SIZE, 0)
    draw = ImageDraw.Draw(cell)

    icon = extract_icon_mask(source_cell)
    icon_scale = min(94 / icon.width, 94 / icon.height)
    icon = icon.resize((max(1, round(icon.width * icon_scale)),
                        max(1, round(icon.height * icon_scale))), Image.Resampling.LANCZOS)
    icon_x = 12
    icon_y = 17 + (94 - icon.height) // 2
    cell.paste(icon, (icon_x, icon_y))

    text_x = 124
    max_width = width - text_x - 18
    name = company_name.upper()
    name_font = fit_name(draw, name, bold_path, max_width)
    draw.text((text_x, 46), name, font=name_font, fill=248, anchor="lm")
    draw.line((text_x, 69, width - 18, 69), fill=224, width=3)

    slogan_font = ImageFont.truetype(regular_path, 15)
    slogan_text = fit_slogan(draw, slogan, slogan_font, max_width)
    if slogan_text:
        draw.text((text_x, 91), slogan_text, font=slogan_font, fill=210, anchor="lm")

    # Light deterministic abrasion and a restrained overspray fringe keep the mark
    # physical without sacrificing the company name at ordinary gameplay distance.
    rr = random.Random(0xD3B0A5 + brand_id)
    for _ in range(12):
        x = rr.randrange(8, width - 8)
        y = rr.randrange(10, height - 10)
        if cell.getpixel((x, y)) > 100:
            radius_x = rr.choice((1, 1, 2))
            draw.ellipse((x - radius_x, y - 1, x + radius_x, y + 1), fill=30)

    mist = cell.filter(ImageFilter.GaussianBlur(0.70)).point(lambda value: int(value * 0.055))
    return ImageChops.lighter(cell, mist)


def indexed_paint_atlas(alpha: Image.Image) -> Image.Image:
    """Store 32 alpha levels while retaining the 4096x1024 atlas geometry."""
    raw = alpha.tobytes()
    indexed = bytearray(len(raw))
    for index, value in enumerate(raw):
        indexed[index] = 0 if value < 6 else max(1, min(31, round(value / 255.0 * 31)))

    image = Image.frombytes("P", alpha.size, bytes(indexed))
    palette: list[int] = []
    for palette_index in range(256):
        palette.extend((244, 242, 232) if palette_index <= 31 else (0, 0, 0))
    image.putpalette(palette)
    transparency = bytes(
        [0]
        + [round(index / 31.0 * 255) for index in range(1, 32)]
        + [255] * (256 - 32)
    )
    image.info["transparency"] = transparency
    return image


def build_spray_atlases(source_dir: Path, catalog_path: Path, output_dir: Path) -> None:
    catalog = load_brand_catalog(catalog_path)
    bold_path = resolve_font_path(FONT_BOLD_CANDIDATES, "bold condensed")
    regular_path = resolve_font_path(FONT_REGULAR_CANDIDATES, "regular condensed")

    for atlas_index in range(1, ATLAS_COUNT + 1):
        source_path = source_dir / f"container_brand_atlas_{atlas_index:02d}.png"
        if not source_path.exists():
            raise SystemExit(f"missing compact brand source: {source_path}")
        source = Image.open(source_path).convert("RGBA")
        if source.size != SOURCE_ATLAS_SIZE:
            raise SystemExit(f"{source_path.name}: expected {SOURCE_ATLAS_SIZE}, got {source.size}")

        alpha_atlas = Image.new("L", SPRAY_ATLAS_SIZE, 0)
        for cell_index in range(BRANDS_PER_ATLAS):
            brand_id = (atlas_index - 1) * BRANDS_PER_ATLAS + cell_index + 1
            source_x = (cell_index % ATLAS_COLUMNS) * SOURCE_CELL_SIZE[0]
            source_y = (cell_index // ATLAS_COLUMNS) * SOURCE_CELL_SIZE[1]
            source_cell = source.crop((source_x, source_y,
                                       source_x + SOURCE_CELL_SIZE[0],
                                       source_y + SOURCE_CELL_SIZE[1]))
            company_name, slogan = catalog[brand_id]
            spray_cell = build_spray_cell(source_cell, brand_id, company_name, slogan,
                                          bold_path, regular_path)
            out_x = (cell_index % ATLAS_COLUMNS) * SPRAY_CELL_SIZE[0]
            out_y = (cell_index // ATLAS_COLUMNS) * SPRAY_CELL_SIZE[1]
            alpha_atlas.paste(spray_cell, (out_x, out_y))

        atlas = indexed_paint_atlas(alpha_atlas)
        output = output_dir / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        atlas.save(output, optimize=True, compress_level=9,
                   transparency=atlas.info["transparency"])
        print(f"{output.name}: 4096x1024, 512x128/cell, full-side V5 stencil")


def validate_outputs(output_dir: Path) -> None:
    detail = output_dir / "container_grit_detail.png"
    if not detail.exists():
        raise SystemExit("container grit detail is missing")
    detail_image = Image.open(detail).convert("L")
    if detail_image.size != DETAIL_SIZE:
        raise SystemExit(f"detail dimensions={detail_image.size}")
    low, high = detail_image.getextrema()
    if low > 90 or high < 160:
        raise SystemExit(f"detail contrast too weak: {low}..{high}")

    for atlas_index in range(1, ATLAS_COUNT + 1):
        path = output_dir / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        if not path.exists():
            raise SystemExit(f"missing spray atlas: {path.name}")
        image = Image.open(path).convert("RGBA")
        if image.size != SPRAY_ATLAS_SIZE:
            raise SystemExit(f"{path.name}: expected {SPRAY_ATLAS_SIZE}, got {image.size}")
        alpha_low, alpha_high = image.getchannel("A").getextrema()
        if alpha_low != 0 or alpha_high < 220:
            raise SystemExit(f"{path.name}: invalid transparency {alpha_low}..{alpha_high}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=RUNTIME_DIR)
    parser.add_argument("--brand-source-dir", type=Path, default=COMPACT_BRAND_DIR)
    parser.add_argument("--brand-names", type=Path, default=BRAND_NAMES_PATH)
    args = parser.parse_args()

    output_dir = args.output_dir
    if not output_dir.is_absolute():
        output_dir = REPO_ROOT / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    legacy_blank = output_dir / "container_blank_metal.png"
    if legacy_blank.exists():
        legacy_blank.unlink()

    build_grit_detail(output_dir / "container_grit_detail.png")
    build_spray_atlases(args.brand_source_dir, args.brand_names, output_dir)
    validate_outputs(output_dir)

    for path in sorted(output_dir.glob("*.png")):
        print(f"{path}: {path.stat().st_size} bytes sha256={sha256(path)}")


if __name__ == "__main__":
    main()
