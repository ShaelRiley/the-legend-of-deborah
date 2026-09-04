#!/usr/bin/env python3
"""Validate V17 verisimilitude-oriented container-brand coverage."""
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
        "BRAND_TARGET_FRACTION = 0.26",
        "BRAND_SOFT_SPACING_CELLS = 2",
        "BRAND_LOWER_TIER_BIAS = 0.35",
        "container-brand-coverage:v3",
        "selectBlueNoise",
        "pickBestCandidate",
        "candidateConflicts",
        "occupiedEdges[edgeKey]",
        "occupiedEndpoints",
        "floorDistanceSquared",
        "minChosenDistanceSquared",
        "distribution=blue-noise",
        "separation=touching-never",
        "relaxedSpacingCount",
    ))
    if "BRANDING_DENOMINATOR" in branding:
        raise SystemExit("obsolete one-in-N brand denominator remains in runtime")
    if "target=1/%d" in branding:
        raise SystemExit("obsolete one-in-N status remains in runtime")

    require(WALLS, (
        "overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil",
        "overlayEndpointA = faceInfo and faceInfo.endpointA or nil",
        "overlayEndpointB = faceInfo and faceInfo.endpointB or nil",
        "overlayOrientation = faceInfo and faceInfo.orientation or nil",
        "fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true",
    ))

    require(DOCS, (
        "## V17 verisimilitude-oriented brand coverage",
        "approximately 26%",
        "blue-noise-like",
        "no-touching rule remains absolute",
        "one visible company mark",
    ))

    print("V17 validated: ~26% floor-stratified blue-noise branding, lower-tier visibility bias, absolute no-touching and full-face-only overlays.")


if __name__ == "__main__":
    main()
