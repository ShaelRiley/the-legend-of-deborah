#!/usr/bin/env python3
"""Build the shipping-container surface assets used by The Legend of Deborah.

The runtime deliberately separates two concerns:

* The cargo model receives a neutral, logo-free diffuse derived from the *stock
  cargo-container UV layout*.  This preserves Valve's authored face/door/top UV
  structure instead of replacing it with a generic square metal tile.
* Company identity is a transparent spray-paint mask.  When the authoritative
  256-brand ZIP is supplied, spray atlases are rebuilt directly from the original
  1024x512 brand sources; no tiny intermediate atlas is upscaled.

The stock normal map remains engine-provided and unchanged.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import random
from pathlib import Path
from zipfile import ZipFile

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps
from srctools.vtf import VTF

REPO_ROOT = Path(__file__).resolve().parents[2]
BRAND_COUNT = 256
ATLAS_COUNT = 4
BRANDS_PER_ATLAS = 64
ATLAS_COLUMNS = 8
ATLAS_ROWS = 8
SPRAY_CELL_SIZE = (256, 128)
SPRAY_ATLAS_SIZE = (
    SPRAY_CELL_SIZE[0] * ATLAS_COLUMNS,
    SPRAY_CELL_SIZE[1] * ATLAS_ROWS,
)
RUNTIME_DIR = REPO_ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_surfaces"
)
RECOLOR_PATH = REPO_ROOT / (
    "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


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
    gray = np.clip((gray - low) / (high - low), 0.0, 1.0)
    return gray


def build_blank_from_stock(stock_paths: list[Path], output: Path) -> None:
    """Derive a neutral diffuse while preserving the cargo model's native UV map.

    Multiple stock cargo skins are normalized and median-combined.  This keeps UV-
    stable structure shared by the skins while suppressing skin-specific paint.
    A deliberate low-pass pass removes remaining readable markings.  Low-amplitude
    metal grain is then restored without changing the UV layout.
    """
    if not stock_paths:
        raise SystemExit("at least one --stock-vtf is required to build the blank base")

    images = [load_vtf(path) for path in stock_paths]
    size = images[0].size
    if any(image.size != size for image in images):
        raise SystemExit(f"stock VTF dimensions disagree: {[image.size for image in images]}")
    if min(size) < 512:
        raise SystemExit(f"stock cargo diffuse unexpectedly small: {size}")

    stack = np.stack([normalized_luma(image) for image in images], axis=0)
    structural = np.median(stack, axis=0)
    structural_u8 = Image.fromarray(np.uint8(np.clip(structural * 255.0, 0, 255)), "L")

    # Down/up sampling plus a soft blur intentionally destroys readable lettering
    # while retaining large authored UV regions (sides, ends, top/bottom and doors).
    low_size = (max(128, size[0] // 6), max(128, size[1] // 6))
    low = structural_u8.resize(low_size, Image.Resampling.BOX)
    low = low.filter(ImageFilter.GaussianBlur(2.2))
    blank = low.resize(size, Image.Resampling.BICUBIC)

    # Retain only restrained medium-scale relief from the median stock image.  The
    # clamp prevents high-contrast logo/text strokes from being reconstructed.
    medium = structural_u8.filter(ImageFilter.GaussianBlur(3.0))
    base_arr = np.asarray(blank, dtype=np.int16)
    med_arr = np.asarray(medium, dtype=np.int16)
    detail = np.clip(med_arr - base_arr, -9, 9)
    result = np.clip(base_arr + detail, 0, 255).astype(np.uint8)

    # Compress the tonal range around neutral steel. $color2 remains authoritative
    # for section hue; the diffuse contributes weathering and UV-aware light/dark.
    result = np.clip(104 + result.astype(np.float32) * 0.34, 104, 191).astype(np.uint8)

    rng = np.random.default_rng(0xD3B0A4)
    grain = rng.normal(0.0, 1.8, result.shape)
    result = np.clip(result.astype(np.float32) + grain, 96, 198).astype(np.uint8)
    neutral = Image.fromarray(result, "L")
    rgb = Image.merge("RGB", (neutral, neutral, neutral))

    output.parent.mkdir(parents=True, exist_ok=True)
    rgb.save(output, optimize=True, compress_level=9)
    print(f"blank source size={size} from {len(stock_paths)} stock skin(s)")


def locate_brand_prefix(names: list[str]) -> str:
    suffix = "textures/container_brand_001.png"
    matches = [name[: -len(suffix)] for name in names if name.endswith(suffix)]
    if len(matches) != 1:
        raise SystemExit("could not uniquely locate textures/container_brand_001.png")
    return matches[0]


def foreground_mask(image: Image.Image) -> Image.Image:
    """Extract paintable logo/text while discarding authored plaque backgrounds.

    Some source companies are already transparent marks; others are dark technical
    placards with white artwork.  High-alpha placards are converted to a bright-
    foreground mask and their outer frame is cropped away.  Transparent marks keep
    their authored alpha directly.
    """
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    alpha_arr = np.asarray(alpha, dtype=np.uint8)
    coverage = float(np.count_nonzero(alpha_arr > 12)) / float(alpha_arr.size)

    if coverage > 0.52:
        # Remove the outer technical-card frame first.  The actual logo/name lives
        # safely inside this inset on the placard-style authored variants.
        inset_x = max(1, int(rgba.width * 0.065))
        inset_y = max(1, int(rgba.height * 0.075))
        rgba = rgba.crop((inset_x, inset_y, rgba.width - inset_x, rgba.height - inset_y))
        alpha = rgba.getchannel("A")
        luma = ImageOps.grayscale(rgba)
        lum = np.asarray(luma, dtype=np.float32)
        a = np.asarray(alpha, dtype=np.float32) / 255.0
        # Technical placards use light logo/text against a charcoal field.
        mask = np.clip((lum - 118.0) / 96.0, 0.0, 1.0) * a
        mask = np.uint8(np.clip(mask * 255.0, 0, 255))
        return Image.fromarray(mask, "L")

    return alpha


def fit_brand_mask(mask: Image.Image, brand_id: int) -> Image.Image:
    bbox = mask.getbbox()
    if not bbox:
        raise SystemExit(f"brand {brand_id:03d}: empty foreground mask")
    mask = mask.crop(bbox)

    pad_x = int(SPRAY_CELL_SIZE[0] * 0.045)
    pad_y = int(SPRAY_CELL_SIZE[1] * 0.075)
    avail_w = SPRAY_CELL_SIZE[0] - pad_x * 2
    avail_h = SPRAY_CELL_SIZE[1] - pad_y * 2
    scale = min(avail_w / mask.width, avail_h / mask.height)
    resized = mask.resize(
        (max(1, round(mask.width * scale)), max(1, round(mask.height * scale))),
        Image.Resampling.LANCZOS,
    )

    core = resized.point(lambda value: min(238, int(value * 0.94)))
    mist = resized.filter(ImageFilter.GaussianBlur(0.85)).point(
        lambda value: int(value * 0.11)
    )
    sprayed = ImageChops.lighter(core, mist)

    # Sparse deterministic abrasion: enough to read as paint, not enough to destroy
    # company names after Source filtering.
    rng = random.Random(0xD3B0A4 + brand_id)
    draw = ImageDraw.Draw(sprayed)
    for _ in range(3):
        x = rng.randrange(sprayed.width)
        y = rng.randrange(sprayed.height)
        if sprayed.getpixel((x, y)) > 180:
            draw.ellipse((x - 1, y - 1, x + 1, y + 1), fill=rng.randrange(20, 75))

    cell = Image.new("L", SPRAY_CELL_SIZE, 0)
    x = (SPRAY_CELL_SIZE[0] - sprayed.width) // 2
    y = (SPRAY_CELL_SIZE[1] - sprayed.height) // 2
    cell.paste(sprayed, (x, y))
    return cell


def indexed_paint_atlas(alpha: Image.Image) -> Image.Image:
    """Encode soft alpha compactly without throwing away the 256x128 cell detail."""
    raw = alpha.tobytes()
    indexed = bytearray(len(raw))
    for index, value in enumerate(raw):
        if value < 8:
            indexed[index] = 0
        else:
            indexed[index] = max(1, min(15, round(value / 255.0 * 15)))

    image = Image.frombytes("P", alpha.size, bytes(indexed))
    palette: list[int] = []
    for palette_index in range(256):
        if palette_index <= 15:
            palette.extend((244, 242, 232))
        else:
            palette.extend((0, 0, 0))
    image.putpalette(palette)
    transparency = bytes(
        [0]
        + [round(index / 15.0 * 255) for index in range(1, 16)]
        + [255] * (256 - 16)
    )
    image.info["transparency"] = transparency
    return image


def build_spray_from_zip(source_zip: Path, output_dir: Path) -> None:
    with ZipFile(source_zip) as archive:
        names = archive.namelist()
        prefix = locate_brand_prefix(names)
        expected = {
            f"{prefix}textures/container_brand_{brand_id:03d}.png"
            for brand_id in range(1, BRAND_COUNT + 1)
        }
        present = {
            name
            for name in names
            if name.startswith(f"{prefix}textures/container_brand_") and name.endswith(".png")
        }
        if present != expected:
            raise SystemExit(
                f"source brand set mismatch: missing={len(expected - present)} "
                f"extra={len(present - expected)}"
            )

        for atlas_index in range(ATLAS_COUNT):
            alpha_atlas = Image.new("L", SPRAY_ATLAS_SIZE, 0)
            for cell_index in range(BRANDS_PER_ATLAS):
                brand_id = atlas_index * BRANDS_PER_ATLAS + cell_index + 1
                name = f"{prefix}textures/container_brand_{brand_id:03d}.png"
                source = Image.open(io.BytesIO(archive.read(name))).convert("RGBA")
                if source.size != (1024, 512):
                    raise SystemExit(f"brand {brand_id:03d}: expected 1024x512, got {source.size}")
                mask = fit_brand_mask(foreground_mask(source), brand_id)
                x = (cell_index % ATLAS_COLUMNS) * SPRAY_CELL_SIZE[0]
                y = (cell_index // ATLAS_COLUMNS) * SPRAY_CELL_SIZE[1]
                alpha_atlas.paste(mask, (x, y))

            atlas = indexed_paint_atlas(alpha_atlas)
            output = output_dir / f"container_brand_spray_atlas_{atlas_index + 1:02d}.png"
            atlas.save(
                output,
                optimize=True,
                compress_level=9,
                transparency=atlas.info["transparency"],
            )
            print(f"built {output.name} directly from original brand sources")


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
    blank_image = Image.open(blank)
    if min(blank_image.size) < 512 or blank_image.width != blank_image.height:
        raise SystemExit(f"blank metal texture has unexpected dimensions {blank_image.size}")

    for atlas_index in range(1, ATLAS_COUNT + 1):
        atlas = output_dir / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        if not atlas.exists():
            raise SystemExit(f"missing spray atlas: {atlas.name}")
        image = Image.open(atlas).convert("RGBA")
        if image.size != SPRAY_ATLAS_SIZE:
            raise SystemExit(f"{atlas.name}: expected {SPRAY_ATLAS_SIZE}, got {image.size}")
        lo, hi = image.getchannel("A").getextrema()
        if lo != 0 or hi < 192:
            raise SystemExit(f"{atlas.name}: invalid transparency range {lo}..{hi}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=RUNTIME_DIR)
    parser.add_argument("--stock-vtf", type=Path, action="append", default=[])
    parser.add_argument("--source-zip", type=Path)
    parser.add_argument("--patch-runtime", action="store_true")
    args = parser.parse_args()

    output_dir = args.output_dir
    if not output_dir.is_absolute():
        output_dir = REPO_ROOT / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.stock_vtf:
        build_blank_from_stock(args.stock_vtf, output_dir / "container_blank_metal.png")
    if args.source_zip:
        build_spray_from_zip(args.source_zip, output_dir)
    if args.patch_runtime:
        patch_recolor(RECOLOR_PATH)

    validate_outputs(output_dir)
    for path in sorted(output_dir.glob("*.png")):
        print(f"{path}: {path.stat().st_size} bytes sha256={sha256(path)}")


if __name__ == "__main__":
    main()
