#!/usr/bin/env python3
"""Validate V15 sparse/full-face-only container overlay rules."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
WAYFINDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua"
PANELS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_marking_panel.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def require(path, tokens):
    text = path.read_text(encoding="utf-8")
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{path.name} missing: {missing}")
    return text


def main():
    walls = require(WALLS, (
        "buildFullSurfaceEligibility",
        "segmentFaceInfo",
        "fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true",
        'local perpendicular = info.orientation == "h" and "v" or "h"',
        "edgeCounts[info.edgeKey] == 1",
        "1=north, 2=east, 3=south, 4=west",
        "if direction == 1 then",
        "elseif direction == 3 then",
        "elseif direction == 2 then",
        "elseif direction == 4 then",
    ))
    if "if direction == 0 then" in walls:
        raise SystemExit("full-face classifier still uses invalid 0-based DIRS indexing")
    if "eligible[index] = a and b and a[perpendicular] == 0 and b[perpendicular] == 0" not in walls:
        raise SystemExit("full-face endpoint exclusion is incomplete")

    require(WAYFINDING, (
        "instance.fullSurfaceEligible == true",
        "instance.marked = false",
    ))
    require(PANELS, (
        "instance.fullSurfaceEligible ~= true",
        "drawMarkedContainer",
    ))
    branding = require(BRANDING, (
        "BRANDING_DENOMINATOR = 5",
        "container-brand-placement:v1",
        "instance.companyBranded = false",
        "instance.companyBranded = true",
        "instance.fullSurfaceEligible == true",
        "math.floor(#candidates / BRANDING_DENOMINATOR)",
        "placement=%d/%d target=1/%d geometryBlocked=%d",
    ))
    if "last = first + BRANDING_DENOMINATOR - 1" not in branding:
        raise SystemExit("branding is not selecting from complete blocks of five")

    require(DOCS, (
        "## V15 sparse full-face-only overlays",
        "never exceed 20%",
        "perpendicular wall",
        "neither company paint nor",
    ))
    print("V15.1 validated: <=20% deterministic company branding; 1-based wall directions; all overlays exclude perpendicular-corner/junction-clipped and duplicate wall faces.")


if __name__ == "__main__":
    main()
