#!/usr/bin/env python3
"""Validate the V9 truly blank cargo-container hull integration."""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SURFACE = ROOT / (
    "gamemodes/legend_of_deborah/content/materials/"
    "legend_of_deborah/container_surfaces"
)
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def require(text: str, tokens: tuple[str, ...], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{label} missing tokens: {missing}")


def forbid(text: str, tokens: tuple[str, ...], label: str) -> None:
    found = [token for token in tokens if token in text]
    if found:
        raise SystemExit(f"{label} forbidden tokens: {found}")


def validate_hull() -> None:
    path = SURFACE / "container_blank_hull_v9.png"
    if not path.exists():
        raise SystemExit("V9 blank hull missing")
    image = Image.open(path).convert("RGB")
    if image.size != (1024, 1024):
        raise SystemExit(f"blank hull dimensions={image.size}")
    arr = np.asarray(image.convert("L"), dtype=np.float32)
    low = int(arr.min())
    high = int(arr.max())
    stddev = float(arr.std())
    if low > 80 or high < 175 or stddev < 14:
        raise SystemExit(
            f"blank hull lacks physical contrast: range={low}..{high} stddev={stddev:.2f}"
        )

    # A strong repeating corrugation signal should survive averaging over height.
    column_profile = arr.mean(axis=0)
    corrugation_span = float(column_profile.max() - column_profile.min())
    if corrugation_span < 18:
        raise SystemExit(f"blank hull corrugation too weak: {corrugation_span:.2f}")

    if path.stat().st_size < 180000:
        raise SystemExit(f"blank hull suspiciously small: {path.stat().st_size}")


def main() -> None:
    validate_hull()

    recolor = RECOLOR.read_text(encoding="utf-8")
    require(
        recolor,
        (
            'HULL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v9.png"',
            'HULL_FALLBACK_TEXTURE = "vgui/white"',
            'HULL_NORMAL_TEXTURE = "models/props_wasteland/cargo_container01_normal"',
            'material:SetTexture("$basetexture", hullTexture)',
            'MATERIAL_VERSION = "v14_blank_hull_v9"',
            'COLOR_REPLACE_BLEND = 0.78',
            'DETAIL_BLEND_FACTOR = 0.40',
            '[LOD:CONTAINER-HULL]',
            'HULL_AVAILABLE and "runtime-texture" or "white-fallback"',
        ),
        "recolor",
    )
    forbid(
        recolor,
        (
            'local NP_BASE_TEXTURE =',
            '["$basetexture"] = "models/props_wasteland/cargo_container01"',
            'lod_np_section_',
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
            "## V9 truly blank cargo hull",
            "There is no stock Northern Petroleum diffuse",
            "materialVersion=v14_blank_hull_v9",
        ),
        "docs",
    )

    print(
        "V9 validated: truly blank corrugated hull, procedural tint, gritty detail, "
        "V8 alpha-tested sprays, and no stock NP diffuse dependency."
    )


if __name__ == "__main__":
    main()
