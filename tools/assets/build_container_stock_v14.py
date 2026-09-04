#!/usr/bin/env python3
"""Build V14/V19 cargo section materials from the minimum safe stock Source stack."""

from __future__ import annotations

import colorsys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SECTIONS = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_sections"
BASE_TEXTURE = "metal/metalwall001a"
CARGO_NORMAL = "models/props_wasteland/cargo_container01_normal"
CANDIDATE_HUE_STEP = 5
CANDIDATE_SV = ((0.82, 0.80), (0.88, 0.90), (0.96, 0.98), (0.98, 0.82), (0.84, 0.98))
COLOR_REPLACE_BLEND = 0.68


def material_name(hue: int, shell: int) -> str:
    return f"v19_h{hue:03d}_s{shell}"


def build() -> None:
    SECTIONS.mkdir(parents=True, exist_ok=True)
    for pattern in ("v16_h???_s?.vmt", "v17_h???_s?.vmt", "v18_h???_s?.vmt", "v19_h???_s?.vmt"):
        for path in SECTIONS.glob(pattern):
            path.unlink()

    count = 0
    for hue in range(0, 360, CANDIDATE_HUE_STEP):
        for shell, (sat, val) in enumerate(CANDIDATE_SV, start=1):
            r, g, b = colorsys.hsv_to_rgb(hue / 360.0, sat, val)
            vmt = f'''"VertexLitGeneric"
{{
    "$basetexture" "{BASE_TEXTURE}"
    "$bumpmap" "{CARGO_NORMAL}"
    "$surfaceprop" "metal"
    "$model" "1"
    "$allowdiffusemodulation" "1"
    "$blendtintbybasealpha" "0"
    "$blendtintcoloroverbase" "{COLOR_REPLACE_BLEND:.3f}"
    "$color2" "[{r:.6f} {g:.6f} {b:.6f}]"
}}
'''
            (SECTIONS / f"{material_name(hue, shell)}.vmt").write_text(vmt, encoding="utf-8")
            count += 1

    expected = (360 // CANDIDATE_HUE_STEP) * len(CANDIDATE_SV)
    if count != expected:
        raise SystemExit(f"V19 section material count={count}, expected={expected}")
    print(f"built {count} V19 minimal stock VMTs base={BASE_TEXTURE} normal={CARGO_NORMAL}")


if __name__ == "__main__":
    build()
