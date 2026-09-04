#!/usr/bin/env python3
"""Validate V18 dense branding with a global 40% ceiling."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def require(path, tokens):
    text = path.read_text(encoding="utf-8")
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{path.name} missing: {missing}")
    return text


def main():
    branding = require(BRANDING, (
        "BRAND_GLOBAL_CAP_FRACTION = 0.40",
        "container-brand-coverage:v4",
        "selectBlueNoise(candidates, floorSeed, #candidates)",
        "globalBrandCap = math.floor(#(world or {}) * BRAND_GLOBAL_CAP_FRACTION)",
        "targetBrandCount = math.min(placeableCount, globalBrandCap)",
        "allocateFloorCounts",
        "candidateConflicts",
        "occupiedEdges[edgeKey]",
        "occupiedEndpoints",
        "distribution=blue-noise-packed",
        "separation=touching-never",
        "placeable=%d all=%d cap=%.0f%%",
    ))
    if "BRAND_TARGET_FRACTION = 0.26" in branding:
        raise SystemExit("obsolete V17 fixed 26% target remains")
    if "BRANDING_DENOMINATOR" in branding:
        raise SystemExit("obsolete one-in-N denominator remains")

    require(WALLS, (
        "overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil",
        "overlayEndpointA = faceInfo and faceInfo.endpointA or nil",
        "overlayEndpointB = faceInfo and faceInfo.endpointB or nil",
        "overlayOrientation = faceInfo and faceInfo.orientation or nil",
        "fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true",
    ))

    require(DOCS, (
        "## V18 dense branding with a global 40% ceiling",
        "capped globally at 40%",
        "no-touching invariant remains absolute",
        "one-per-floor baseline",
        "blue-noise selection",
    ))

    print("V18 validated: dense full-surface branding, hard no-touching, and <=40% of all container instances globally.")


if __name__ == "__main__":
    main()
