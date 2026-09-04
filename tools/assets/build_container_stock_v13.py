#!/usr/bin/env python3
"""Build V13 section materials from guaranteed stock HL2/GMod textures.

The stock HL2 cargo skins are branded Northern Petrol variants, so V13 deliberately
stops trying to manufacture a replacement cargo diffuse. Instead, every procedural
section VMT uses a neutral stock HL2 industrial-metal diffuse, the stock cargo normal
map for the model's exact corrugation relief, and a restrained stock detail texture.
No custom VTF decoder or runtime texture binding is involved.
"""

from __future__ import annotations

import colorsys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SECTIONS = (
    ROOT
    / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_sections"
)

BASE_TEXTURE = "metal/metalwall001a"
CARGO_NORMAL = "models/props_wasteland/cargo_container01_normal"
DETAIL_TEXTURE = "detail/detail_noise1"
CANDIDATE_HUE_STEP = 5
CANDIDATE_SV = (
    (0.82, 0.80),
    (0.88, 0.90),
    (0.96, 0.98),
    (0.98, 0.82),
    (0.84, 0.98),
)
COLOR_REPLACE_BLEND = 0.72
DETAIL_BLEND_FACTOR = 0.12
DETAIL_SCALE = 4.00


def material_name(hue: int, shell: int) -> str:
    return f"v18_h{hue:03d}_s{shell}"


def build() -> None:
    SECTIONS.mkdir(parents=True, exist_ok=True)

    # Remove the two experimental custom-VTF generations. Only V18 is live after
    # this builder. Deleting stale V16/V17 VMTs also prevents accidental fallback.
    for pattern in ("v16_h???_s?.vmt", "v17_h???_s?.vmt", "v18_h???_s?.vmt"):
        for path in SECTIONS.glob(pattern):
            path.unlink()

    count = 0
    for hue in range(0, 360, CANDIDATE_HUE_STEP):
        for shell, (sat, val) in enumerate(CANDIDATE_SV, start=1):
            r, g, b = colorsys.hsv_to_rgb(hue / 360.0, sat, val)
            name = material_name(hue, shell)
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
    "$detail" "{DETAIL_TEXTURE}"
    "$detailblendmode" "0"
    "$detailblendfactor" "{DETAIL_BLEND_FACTOR:.3f}"
    "$detailscale" "{DETAIL_SCALE:.3f}"
    "$phong" "1"
    "$phongexponent" "18"
    "$phongboost" "0.10"
    "$phongfresnelranges" "[0.02 0.08 0.30]"
}}
'''
            (SECTIONS / f"{name}.vmt").write_text(vmt, encoding="utf-8")
            count += 1

    expected = (360 // CANDIDATE_HUE_STEP) * len(CANDIDATE_SV)
    if count != expected:
        raise SystemExit(f"V18 section material count={count}, expected={expected}")
    print(
        f"built {count} V18 stock-backed section VMTs: "
        f"base={BASE_TEXTURE} normal={CARGO_NORMAL} detail={DETAIL_TEXTURE}"
    )


if __name__ == "__main__":
    build()
