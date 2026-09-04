#!/usr/bin/env python3
"""Build production shipping-container surface assets for The Legend of Deborah.

Two independent presentation assets are generated:

* a neutral, logo-free diffuse derived from the stock cargo-container UV layout;
* high-resolution transparent company spray masks.

The committed compact 256-brand atlases remain the authored icon source. Company
names are retained in ``container_brand_names.tsv``. V3 rebuilds each company at
256x128 effective resolution: the original icon is preserved while the company
name is re-typeset at native resolution instead of enlarging the old 64x32 text.
This keeps the supplied company identities while making them readable in Source.
"""

from __future__ import annotations

import argparse
import hashlib
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps
from srctools.vtf import VTF

REPO_ROOT = Path(__file__).resolve().parents[2]
BRAND_COUNT = 256
ATLAS_COUNT = 4
BRANDS_PER_ATLAS = 64
ATLAS_COLUMNS = 8
ATLAS_ROWS = 8
SOURCE_CELL_SIZE = (64, 32)
SOURCE_ATLAS_SIZE = (512, 256)
SPRAY_CELL_SIZE = (256, 128)
SPRAY_ATLAS_SIZE = (2048, 1024)
RUNTIME_DIR = REPO_ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_surfaces"
)
COMPACT_BRAND_DIR = REPO_ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_brands"
)
BRAND_NAMES_PATH = REPO_ROOT / "tools/assets/container_brand_names.tsv"
RECOLOR_PATH = REPO_ROOT / (
    "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
)

FONT_BOLD_CANDIDATES = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf",
    "/usr/share/fonts/dejavu/DejaVuSansCondensed-Bold.ttf",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def resolve_font_path() -> str:
    for candidate in FONT_BOLD_CANDIDATES:
        if Path(candidate).exists():
            return candidate
    raise SystemExit("DejaVu Sans Condensed Bold is required to build container paint")


def load_vtf(path: Path) -> Image.Image:
    with path.open("rb") as stream:
        vtf = VTF.read(stream)
        vtf.load()
        image = vtf.get().to_PIL().convert("RGBA")
    return image


def normalized_luma(image: Image.Image) -> np.ndarray:
    gray = np.asarray(ImageOps.grayscale(image), dtype=np.float32)
    low = float(np.percentile(gray, 3.0))
    high = float(np.percentile(gray, 97.0))
    if high <= low + 1.0:
        high = low + 1.0
    return np.clip((gray - low) / (high - low), 0.0, 1.0)


def build_blank_from_stock(stock_paths: list[Path], output: Path) -> None:
    """Build neutral metal without destroying the cargo model's authored UV map."""
    if not stock_paths:
        raise SystemExit("at least one --stock-vtf is required")

    images = [load_vtf(path) for path in stock_paths]
    size = images[0].size
    if any(image.size != size for image in images):
        raise SystemExit(f"stock VTF dimensions disagree: {[image.size for image in images]}")
    if size != (1024, 1024):
        raise SystemExit(f"stock cargo diffuse must be 1024x1024, got {size}")

    # The four stock skins share one UV layout but differ in paint/company treatment.
    # Median-combining normalized luminance preserves shared panel/door/top structure
    # while suppressing skin-specific color and signage.
    stack = np.stack([normalized_luma(image) for image in images], axis=0)
    structural = np.median(stack, axis=0)
    structural_u8 = Image.fromarray(
        np.uint8(np.clip(structural * 255.0, 0, 255)), "L"
    )

    # Remove remaining readable lettering without replacing the texture with a tile.
    # Down/up filtering operates in the original UV coordinate system, so model faces
    # continue sampling the regions Valve authored for them.
    low = structural_u8.resize((256, 256), Image.Resampling.BOX)
    low = low.filter(ImageFilter.GaussianBlur(1.65))
    blank = low.resize(size, Image.Resampling.BICUBIC)

    medium = structural_u8.filter(ImageFilter.GaussianBlur(3.2))
    base_arr = np.asarray(blank, dtype=np.int16)
    med_arr = np.asarray(medium, dtype=np.int16)
    detail = np.clip(med_arr - base_arr, -10, 10)
    result = np.clip(base_arr + detail, 0, 255).astype(np.uint8)

    # Keep a mid-value neutral substrate. $color2 remains the authoritative section
    # hue while this map contributes believable UV-aware metal/weathering variation.
    result = np.clip(100 + result.astype(np.float32) * 0.38, 100, 196).astype(np.uint8)
    rng = np.random.default_rng(0xD3B0A4)
    grain = rng.normal(0.0, 1.4, result.shape)
    result = np.clip(result.astype(np.float32) + grain, 94, 202).astype(np.uint8)

    neutral = Image.fromarray(result, "L")
    rgb = Image.merge("RGB", (neutral, neutral, neutral))
    output.parent.mkdir(parents=True, exist_ok=True)
    rgb.save(output, optimize=True, compress_level=9)
    print(f"blank cargo: stock UV {size[0]}x{size[1]} from {len(images)} skins")


def load_brand_names(path: Path) -> dict[int, str]:
    rows: dict[int, str] = {}
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        parts = line.split("\t", 2)
        if len(parts) != 3:
            raise SystemExit(f"{path}:{line_number}: expected id, name, slogan")
        brand_id = int(parts[0])
        rows[brand_id] = parts[1].strip()

    expected = set(range(1, BRAND_COUNT + 1))
    if set(rows) != expected:
        raise SystemExit(
            f"brand-name manifest mismatch: missing={sorted(expected - set(rows))} "
            f"extra={sorted(set(rows) - expected)}"
        )
    return rows


def extract_icon_mask(cell: Image.Image) -> Image.Image:
    """Recover the supplied left-hand company emblem from one 64x32 source cell."""
    # All authored treatments reserve the left side for the emblem. This crop avoids
    # the old tiny name copy and most technical card framing.
    icon = cell.convert("RGBA").crop((1, 2, 18, 30))
    alpha = np.asarray(icon.getchannel("A"), dtype=np.float32) / 255.0
    coverage = float(np.count_nonzero(alpha > 0.08)) / float(alpha.size)

    if coverage < 0.70:
        mask = alpha
    else:
        # Opaque technical-card variants use light artwork on a dark plate. Preserve
        # only that bright emblem and discard the plate itself.
        luma = np.asarray(ImageOps.grayscale(icon), dtype=np.float32) / 255.0
        mask = np.power(luma, 1.55) * alpha

    out = Image.fromarray(np.uint8(np.clip(mask * 255.0, 0, 255)), "L")
    bbox = out.getbbox()
    return out.crop(bbox) if bbox else Image.new("L", (1, 1), 0)


def wrap_company_name(
    draw: ImageDraw.ImageDraw,
    company_name: str,
    font_path: str,
    max_width: int,
) -> tuple[list[str], ImageFont.FreeTypeFont]:
    """Prefer one strong line, otherwise split into two strong stencil lines."""
    text = company_name.upper()
    words = text.split()
    for size in range(31, 15, -1):
        font = ImageFont.truetype(font_path, size)
        one = draw.textbbox((0, 0), text, font=font)
        if one[2] - one[0] <= max_width:
            return [text], font

        for cut in range(1, len(words)):
            lines = [" ".join(words[:cut]), " ".join(words[cut:])]
            widths = [draw.textbbox((0, 0), line, font=font)[2] for line in lines]
            if max(widths) <= max_width:
                return lines, font

    # Very long names remain complete; final fallback is merely smaller, never
    # truncated. This is uncommon but preferable to silently losing company identity.
    return [text], ImageFont.truetype(font_path, 13)


def build_spray_cell(
    source_cell: Image.Image,
    brand_id: int,
    company_name: str,
    font_path: str,
) -> Image.Image:
    cell = Image.new("L", SPRAY_CELL_SIZE, 0)
    draw = ImageDraw.Draw(cell)

    icon = extract_icon_mask(source_cell)
    icon_scale = min(76 / icon.width, 76 / icon.height)
    icon = icon.resize(
        (
            max(1, round(icon.width * icon_scale)),
            max(1, round(icon.height * icon_scale)),
        ),
        Image.Resampling.LANCZOS,
    )
    icon_x = 10
    icon_y = 26 + (76 - icon.height) // 2
    cell.paste(icon, (icon_x, icon_y))

    text_x = 96
    max_width = SPRAY_CELL_SIZE[0] - text_x - 9
    lines, font = wrap_company_name(draw, company_name, font_path, max_width)
    if len(lines) == 1:
        draw.text((text_x, 63), lines[0], font=font, fill=242, anchor="lm")
    else:
        draw.text((text_x, 45), lines[0], font=font, fill=242, anchor="lm")
        draw.text((text_x, 78), lines[1], font=font, fill=242, anchor="lm")

    # Minimal deterministic paint wear. We deliberately avoid broad grunge because
    # legibility is the first V3 acceptance criterion after the blurry V2 playtest.
    rng = random.Random(0xD3B0A4 + brand_id)
    for _ in range(4):
        x = rng.randrange(8, SPRAY_CELL_SIZE[0] - 8)
        y = rng.randrange(20, SPRAY_CELL_SIZE[1] - 16)
        if cell.getpixel((x, y)) > 100:
            draw.ellipse((x - 1, y - 1, x + 1, y + 1), fill=30)

    mist = cell.filter(ImageFilter.GaussianBlur(0.65)).point(lambda value: int(value * 0.08))
    return ImageChops.lighter(cell, mist)


def indexed_paint_atlas(alpha: Image.Image) -> Image.Image:
    """Store sixteen useful alpha levels while retaining the 2048x1024 geometry."""
    raw = alpha.tobytes()
    indexed = bytearray(len(raw))
    for index, value in enumerate(raw):
        indexed[index] = (
            0 if value < 8 else max(1, min(15, round(value / 255.0 * 15)))
        )

    image = Image.frombytes("P", alpha.size, bytes(indexed))
    palette: list[int] = []
    for palette_index in range(256):
        palette.extend((244, 242, 232) if palette_index <= 15 else (0, 0, 0))
    image.putpalette(palette)
    transparency = bytes(
        [0]
        + [round(index / 15.0 * 255) for index in range(1, 16)]
        + [255] * (256 - 16)
    )
    image.info["transparency"] = transparency
    return image


def build_spray_from_compact_sources(
    source_dir: Path,
    names_path: Path,
    output_dir: Path,
) -> None:
    """Rebuild readable spray masks from supplied icons + authoritative names."""
    company_names = load_brand_names(names_path)
    font_path = resolve_font_path()

    for atlas_index in range(1, ATLAS_COUNT + 1):
        source_path = source_dir / f"container_brand_atlas_{atlas_index:02d}.png"
        if not source_path.exists():
            raise SystemExit(f"missing compact brand source: {source_path}")
        source = Image.open(source_path).convert("RGBA")
        if source.size != SOURCE_ATLAS_SIZE:
            raise SystemExit(
                f"{source_path.name}: expected {SOURCE_ATLAS_SIZE}, got {source.size}"
            )

        alpha_atlas = Image.new("L", SPRAY_ATLAS_SIZE, 0)
        for cell_index in range(BRANDS_PER_ATLAS):
            brand_id = (atlas_index - 1) * BRANDS_PER_ATLAS + cell_index + 1
            source_x = (cell_index % ATLAS_COLUMNS) * SOURCE_CELL_SIZE[0]
            source_y = (cell_index // ATLAS_COLUMNS) * SOURCE_CELL_SIZE[1]
            source_cell = source.crop(
                (
                    source_x,
                    source_y,
                    source_x + SOURCE_CELL_SIZE[0],
                    source_y + SOURCE_CELL_SIZE[1],
                )
            )
            spray_cell = build_spray_cell(
                source_cell,
                brand_id,
                company_names[brand_id],
                font_path,
            )
            out_x = (cell_index % ATLAS_COLUMNS) * SPRAY_CELL_SIZE[0]
            out_y = (cell_index // ATLAS_COLUMNS) * SPRAY_CELL_SIZE[1]
            alpha_atlas.paste(spray_cell, (out_x, out_y))

        atlas = indexed_paint_atlas(alpha_atlas)
        output = output_dir / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        atlas.save(
            output,
            optimize=True,
            compress_level=9,
            transparency=atlas.info["transparency"],
        )
        print(
            f"{output.name}: 2048x1024, 256x128/cell, "
            "supplied icon + native-resolution company text"
        )


def patch_recolor(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    changed = False

    old_version = 'local MATERIAL_VERSION = "v8_blank_metal_surface"'
    new_version = 'local MATERIAL_VERSION = "v9_stock_uv_blank"'
    if old_version in text:
        text = text.replace(old_version, new_version, 1)
        changed = True
    elif new_version not in text:
        raise SystemExit("recolor material-version anchor not found")

    if 'local COLOR_REPLACE_BLEND = 0.84' in text:
        text = text.replace(
            'local COLOR_REPLACE_BLEND = 0.84',
            'local COLOR_REPLACE_BLEND = 0.80',
            1,
        )
        changed = True

    old_comment = "-- Shader-native section recoloring for the logo-free neutral cargo surface."
    new_comment = "-- Shader-native section recoloring for the stock-UV-derived blank cargo surface."
    if old_comment in text:
        text = text.replace(old_comment, new_comment, 1)
        changed = True

    if changed:
        path.write_text(text, encoding="utf-8")
    return changed


def validate_outputs(output_dir: Path) -> None:
    blank = output_dir / "container_blank_metal.png"
    if not blank.exists():
        raise SystemExit("blank metal texture is missing")
    if Image.open(blank).size != (1024, 1024):
        raise SystemExit(f"blank metal texture has unexpected dimensions {Image.open(blank).size}")

    for atlas_index in range(1, ATLAS_COUNT + 1):
        path = output_dir / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        if not path.exists():
            raise SystemExit(f"missing spray atlas: {path.name}")
        image = Image.open(path).convert("RGBA")
        if image.size != SPRAY_ATLAS_SIZE:
            raise SystemExit(f"{path.name}: expected {SPRAY_ATLAS_SIZE}, got {image.size}")
        low, high = image.getchannel("A").getextrema()
        if low != 0 or high < 192:
            raise SystemExit(f"{path.name}: invalid transparency range {low}..{high}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=RUNTIME_DIR)
    parser.add_argument("--stock-vtf", type=Path, action="append", default=[])
    parser.add_argument("--brand-source-dir", type=Path, default=COMPACT_BRAND_DIR)
    parser.add_argument("--brand-names", type=Path, default=BRAND_NAMES_PATH)
    parser.add_argument("--patch-runtime", action="store_true")
    args = parser.parse_args()

    output_dir = args.output_dir
    if not output_dir.is_absolute():
        output_dir = REPO_ROOT / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    build_blank_from_stock(args.stock_vtf, output_dir / "container_blank_metal.png")
    build_spray_from_compact_sources(
        args.brand_source_dir,
        args.brand_names,
        output_dir,
    )
    if args.patch_runtime:
        patch_recolor(RECOLOR_PATH)

    validate_outputs(output_dir)
    for path in sorted(output_dir.glob("*.png")):
        print(f"{path}: {path.stat().st_size} bytes sha256={sha256(path)}")


if __name__ == "__main__":
    main()
