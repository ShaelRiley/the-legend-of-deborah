#!/usr/bin/env python3
"""Build blank-metal and spray-paint container runtime assets.

The committed four brand atlases are the self-contained source for this runtime
pass. This builder never downloads project assets. It derives:

- one neutral, logo-free metal diffuse used by the cargo model; and
- four higher-resolution transparent spray-paint atlases (64 brands each).

It can also patch cl_container_section_recolor.lua so the stock Northern Petrol
diffuse is no longer used as the model's color texture. The stock normal map is
retained because it contains surface relief, not company branding.
"""

from __future__ import annotations

import argparse
import hashlib
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

REPO_ROOT = Path(__file__).resolve().parents[2]
ATLAS_COUNT = 4
SOURCE_ATLAS_SIZE = (512, 256)
SPRAY_ATLAS_SIZE = (1024, 512)
ATLAS_COLUMNS = 8
ATLAS_ROWS = 8
SPRAY_CELL_SIZE = (128, 64)
BLANK_SIZE = (512, 512)
RUNTIME_DIR = REPO_ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_surfaces"
)
SOURCE_DIR = REPO_ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_brands"
)
RECOLOR_PATH = REPO_ROOT / (
    "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_blank_metal(output: Path) -> None:
    """Create a neutral, seamless-looking diffuse with no authored markings."""
    rng = random.Random(0xD3B0A4)

    # Low-frequency rolled-steel mottling. Keep the source neutral so the existing
    # section-color shader can own hue without fighting a red baked diffuse.
    coarse = Image.new("L", (32, 32))
    coarse.putdata([rng.randint(118, 154) for _ in range(32 * 32)])
    coarse = coarse.resize(BLANK_SIZE, Image.Resampling.BICUBIC)
    fine = Image.new("L", BLANK_SIZE)
    fine.putdata([rng.randint(126, 150) for _ in range(BLANK_SIZE[0] * BLANK_SIZE[1])])
    metal = Image.blend(coarse, fine, 0.22)
    metal = metal.filter(ImageFilter.GaussianBlur(0.35))

    draw = ImageDraw.Draw(metal)
    for _ in range(54):
        y = rng.randrange(BLANK_SIZE[1])
        x = rng.randrange(BLANK_SIZE[0])
        length = rng.randrange(18, 120)
        shade = rng.choice((96, 104, 168, 176))
        draw.line((x, y, min(BLANK_SIZE[0] - 1, x + length), y + rng.choice((-1, 0, 1))),
                  fill=shade, width=1)

    # Faint broad vertical handling bands; these are material variation, not logos.
    overlay = Image.new("L", BLANK_SIZE, 128)
    odraw = ImageDraw.Draw(overlay)
    for x in range(0, BLANK_SIZE[0], 48):
        odraw.rectangle((x, 0, min(x + 8, BLANK_SIZE[0]), BLANK_SIZE[1]), fill=122)
    metal = ImageChops.multiply(metal, overlay)
    metal = Image.eval(metal, lambda value: max(92, min(188, int(value * 1.32))))

    rgb = Image.merge("RGB", (metal, metal, metal))
    output.parent.mkdir(parents=True, exist_ok=True)
    rgb.save(output, optimize=True, compress_level=9)


def distress_cell(alpha: Image.Image, seed: int) -> Image.Image:
    """Turn a clean decal alpha into a restrained stencil/spray-paint mask."""
    rng = random.Random(seed)
    core = alpha.point(lambda value: min(232, int(value * 0.91)))
    mist = alpha.filter(ImageFilter.GaussianBlur(1.15)).point(
        lambda value: int(value * 0.19)
    )
    combined = ImageChops.lighter(core, mist)

    # Small deterministic chips and wipe marks. Damage is deliberately sparse so
    # long company names survive the compact runtime representation.
    draw = ImageDraw.Draw(combined)
    width, height = combined.size
    for _ in range(9):
        x = rng.randrange(width)
        y = rng.randrange(height)
        radius = rng.choice((1, 1, 2))
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=0)
    for _ in range(2):
        x = rng.randrange(width)
        y = rng.randrange(height)
        draw.line((x, y, min(width - 1, x + rng.randrange(5, 18)), y), fill=35, width=1)

    return combined


def build_spray_atlas(source: Path, output: Path, atlas_index: int) -> None:
    source_image = Image.open(source).convert("RGBA")
    if source_image.size != SOURCE_ATLAS_SIZE:
        raise SystemExit(
            f"{source.name}: expected {SOURCE_ATLAS_SIZE}, got {source_image.size}"
        )

    # Upscale before alpha treatment. This cannot invent source detail, but it gives
    # the spray fringe and wear enough resolution to avoid the previous pixel-card look.
    source_image = source_image.resize(SPRAY_ATLAS_SIZE, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", SPRAY_ATLAS_SIZE, (0, 0, 0, 0))

    for cell in range(ATLAS_COLUMNS * ATLAS_ROWS):
        x = (cell % ATLAS_COLUMNS) * SPRAY_CELL_SIZE[0]
        y = (cell // ATLAS_COLUMNS) * SPRAY_CELL_SIZE[1]
        region = source_image.crop(
            (x, y, x + SPRAY_CELL_SIZE[0], y + SPRAY_CELL_SIZE[1])
        )
        alpha = distress_cell(region.getchannel("A"), atlas_index * 1000 + cell)

        # Store a neutral paint mask. Runtime chooses light or charcoal paint from
        # the already-authoritative section/body luminance.
        paint = Image.new("RGBA", SPRAY_CELL_SIZE, (244, 242, 232, 0))
        paint.putalpha(alpha)
        canvas.alpha_composite(paint, (x, y))

    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output, optimize=True, compress_level=9)


def patch_recolor(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "CONTAINER_BLANK_BASE_PATH" in text:
        return False

    old = (
        'local NP_BASE_TEXTURE = "models/props_wasteland/cargo_container01"\n'
        'local NP_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"\n'
    )
    new = (
        'local CONTAINER_BLANK_BASE_PATH = '
        '"legend_of_deborah/container_surfaces/container_blank_metal.png"\n'
        'local blankBaseMaterial = Material(CONTAINER_BLANK_BASE_PATH, '
        '"vertexlitgeneric mips smooth")\n'
        'local blankBaseTexture = blankBaseMaterial and '
        'blankBaseMaterial:GetTexture("$basetexture")\n'
        'local NP_BASE_TEXTURE = blankBaseTexture and blankBaseTexture:GetName() '
        'or "color/white"\n'
        'local NP_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"\n'
    )
    if old not in text:
        raise SystemExit("recolor patch anchor not found")

    text = text.replace(old, new, 1)
    text = text.replace(
        'local MATERIAL_VERSION = "v7_full_spectrum_maximin"',
        'local MATERIAL_VERSION = "v8_blank_metal_surface"',
        1,
    )
    text = text.replace(
        "-- Shader-native section recoloring for the existing Northern Petrol cargo model.",
        "-- Shader-native section recoloring for the logo-free neutral cargo surface.",
        1,
    )
    text = text.replace(
        "-- The stock diffuse is strongly red, so ordinary SetColor multiplication cannot",
        "-- The runtime diffuse is a neutral, logo-free metal texture. The existing",
        1,
    )
    text = text.replace(
        "-- produce clean section hues. Source's VertexLitGeneric color-replacement path",
        "-- VertexLitGeneric color-replacement path retains deterministic section hue",
        1,
    )
    text = text.replace(
        "-- preserves the exact model, UVs, weathered diffuse and normal map while allowing",
        "-- while retaining the validated cargo mesh and stock relief normal map.",
        1,
    )
    text = text.replace(
        "-- procedural paint colors. Runtime testing established that the stock diffuse alpha",
        "-- Company identity is no longer baked into the diffuse; it is rendered separately",
        1,
    )
    text = text.replace(
        "-- is NOT an NP-logo paint mask, so the authentic baked branding shares the body tint",
        "-- as a vertex-lit spray-paint mask on ordinary containers.",
        1,
    )
    text = text.replace(
        "-- except on marked containers, where the separate plywood wayfinding plate covers it.\n",
        "\n",
        1,
    )
    path.write_text(text, encoding="utf-8")
    return True


def validate_outputs(output_dir: Path) -> None:
    blank = output_dir / "container_blank_metal.png"
    if Image.open(blank).size != BLANK_SIZE:
        raise SystemExit("blank metal texture has wrong dimensions")

    for atlas_index in range(1, ATLAS_COUNT + 1):
        atlas = output_dir / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        image = Image.open(atlas).convert("RGBA")
        if image.size != SPRAY_ATLAS_SIZE:
            raise SystemExit(f"{atlas.name}: wrong dimensions")
        alpha = image.getchannel("A")
        lo, hi = alpha.getextrema()
        if lo != 0 or hi < 128:
            raise SystemExit(f"{atlas.name}: invalid transparency range {lo}..{hi}")


def build(output_dir: Path, patch_runtime: bool) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    build_blank_metal(output_dir / "container_blank_metal.png")

    for atlas_index in range(1, ATLAS_COUNT + 1):
        source = SOURCE_DIR / f"container_brand_atlas_{atlas_index:02d}.png"
        if not source.exists():
            raise SystemExit(f"missing committed source atlas: {source}")
        output = output_dir / f"container_brand_spray_atlas_{atlas_index:02d}.png"
        build_spray_atlas(source, output, atlas_index)

    validate_outputs(output_dir)
    if patch_runtime:
        patch_recolor(RECOLOR_PATH)

    for path in sorted(output_dir.glob("*.png")):
        print(f"{path}: {path.stat().st_size} bytes sha256={sha256(path)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=RUNTIME_DIR)
    parser.add_argument("--patch-runtime", action="store_true")
    args = parser.parse_args()
    output_dir = args.output_dir
    if not output_dir.is_absolute():
        output_dir = REPO_ROOT / output_dir
    build(output_dir, args.patch_runtime)


if __name__ == "__main__":
    main()
