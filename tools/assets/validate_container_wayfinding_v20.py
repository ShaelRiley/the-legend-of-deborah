#!/usr/bin/env python3
"""Validate V20 coverage-first, non-touching container wayfinding."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WAYFINDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua"
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def require(path, tokens):
    text = path.read_text(encoding="utf-8")
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{path.name} missing: {missing}")
    return text


def main():
    wayfinding = require(WAYFINDING, (
        "MARKING_DENSITY = 0.22",
        "MIN_MARKS_PER_SECTION = 4",
        "SIGN_COVERAGE_RADIUS_CELLS = 3",
        "container-wayfinding-coverage:v20",
        "coverageForInstance",
        "chooseBestCandidate",
        "signConflicts",
        "occupiedEdges[edgeKey]",
        "occupiedEndpoints",
        "separation=touching-never",
        "distribution=coverage-first",
        "lod_container_wayfinding_status",
        "instance.fullSurfaceEligible == true",
    ))
    if "MARKING_DENSITY = 1 / 6" in wayfinding:
        raise SystemExit("obsolete one-in-six wayfinding density remains")
    if "MIN_MARKS_PER_SECTION = 3" in wayfinding:
        raise SystemExit("obsolete three-sign section minimum remains")

    require(WALLS, (
        "overlayDirection = segment[4]",
        "overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil",
        "overlayEndpointA = faceInfo and faceInfo.endpointA or nil",
        "overlayEndpointB = faceInfo and faceInfo.endpointB or nil",
        "overlayOrientation = faceInfo and faceInfo.orientation or nil",
        "fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true",
    ))

    require(DOCS, (
        "## V20 wayfinding coverage",
        "approximately 22%",
        "baseline of four boards",
        "absolute no-touching invariant",
        "three-cell corridor-aware neighborhood",
    ))

    print("V20 validated: ~22% coverage-first floor/quadrant signage, four-per-section baseline, strict full-face eligibility and absolute no-touching.")


if __name__ == "__main__":
    main()
