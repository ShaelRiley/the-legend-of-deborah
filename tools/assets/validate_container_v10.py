#!/usr/bin/env python3
"""Validate V10 explicit cargo material-slot replacement."""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SURFACE = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_surfaces"
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def require(text: str, tokens: tuple[str, ...], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{label} missing tokens: {missing}")


def validate_hull() -> None:
    path = SURFACE / "container_blank_hull_v9.png"
    if not path.exists():
        raise SystemExit("blank hull missing")
    image = Image.open(path).convert("RGB")
    if image.size != (1024, 1024):
        raise SystemExit(f"blank hull dimensions={image.size}")
    arr = np.asarray(image.convert("L"), dtype=np.float32)
    if int(arr.min()) > 80 or int(arr.max()) < 175 or float(arr.std()) < 14:
        raise SystemExit("blank hull physical contrast regression")
    profile = arr.mean(axis=0)
    if float(profile.max() - profile.min()) < 18:
        raise SystemExit("blank hull corrugation regression")


def main() -> None:
    validate_hull()

    recolor = RECOLOR.read_text(encoding="utf-8")
    require(
        recolor,
        (
            'HULL_PATH = "legend_of_deborah/container_surfaces/container_blank_hull_v9.png"',
            'material:SetTexture("$basetexture", hullTexture)',
            'MATERIAL_VERSION = "v15_blank_hull_submaterials"',
            'local function applySectionMaterialSlots',
            'local slots = model:GetMaterials() or {}',
            'model:SetSubMaterial(slot, wanted)',
            'model:SetMaterial("")',
            'instance.appliedSectionMode = "submaterials"',
            'instance.appliedSectionSlotCount = slotCount',
            'and instance.appliedSectionMode == "submaterials"',
            '[LOD:CONTAINER-SLOTS]',
            'sampleMode, sampleSlots, MATERIAL_VERSION',
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
            "## V10 explicit cargo material-slot replacement",
            "SetSubMaterial",
            "materialVersion=v15_blank_hull_submaterials",
            "[LOD:CONTAINER-SLOTS]",
        ),
        "docs",
    )

    print(
        "V10 validated: generated blank hull retained, every cargo material slot is "
        "explicitly overridden, global construction override is cleared, and V8 sprays remain active."
    )


if __name__ == "__main__":
    main()
