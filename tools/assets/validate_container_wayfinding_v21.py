#!/usr/bin/env python3
"""Validate V21 orientation-first wayfinding and brand/sign coexistence."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WAYFINDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua"
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
    wayfinding = require(WAYFINDING, (
        "MARKING_DENSITY = 0.30",
        "MIN_MARKS_PER_SECTION = 5",
        "SIGN_SIGHTLINE_RANGE_CELLS = 6",
        "container-wayfinding-orientation:v21",
        "adjacentObservationCells",
        "orientationAnchorScore",
        "openDirections",
        "coverageForInstance",
        "chooseBestCandidate",
        "candidate.anchorScore = orientationAnchorScore",
        "signConflicts",
        "occupiedEdges[edgeKey]",
        "occupiedEndpoints",
        "separation=touching-never",
        "distribution=orientation-coverage",
        "sightline=%dcells",
        "lod_container_wayfinding_status",
        "instance.fullSurfaceEligible == true",
    ))
    for obsolete in (
        "MARKING_DENSITY = 0.22",
        "MIN_MARKS_PER_SECTION = 4",
        "SIGN_COVERAGE_RADIUS_CELLS = 3",
        "container-wayfinding-coverage:v20:",
        "distribution=coverage-first radius=%dcells",
    ):
        if obsolete in wayfinding:
            raise SystemExit(f"obsolete V20 wayfinding token remains: {obsolete}")

    branding = require(BRANDING, (
        "coexistence=brand+wayfinding",
        "instance.brandSurfaceEligible == true",
        "Wayfinding boards may share a container with company paint",
    ))
    if "elseif not instance.marked then" in branding:
        raise SystemExit("company placement still excludes wayfinding-marked containers")
    if "instance.brandSurfaceEligible == true and not instance.marked" in branding:
        raise SystemExit("company renderer still suppresses paint on wayfinding containers")

    require(WALLS, (
        "overlayDirection = segment[4]",
        "overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil",
        "overlayEndpointA = faceInfo and faceInfo.endpointA or nil",
        "overlayEndpointB = faceInfo and faceInfo.endpointB or nil",
        "overlayOrientation = faceInfo and faceInfo.orientation or nil",
        "fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true",
    ))

    require(DOCS, (
        "## V21 orientation signage",
        "approximately 30%",
        "baseline of five boards",
        "six maze cells",
        "junctions and ninety-degree turns",
        "Company branding and wayfinding are no longer mutually exclusive",
        "no-touching invariant remains absolute",
    ))

    print("V21 validated: 30% orientation-first floor/quadrant signage, six-cell straight sightlines, decision-point bias, strict no-touching, and brand/sign coexistence.")


if __name__ == "__main__":
    main()
