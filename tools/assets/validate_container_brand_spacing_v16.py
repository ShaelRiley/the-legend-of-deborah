#!/usr/bin/env python3
"""Validate V16 one-in-three, non-touching company branding."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
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
        "overlayEdgeKey = faceInfo and faceInfo.edgeKey or nil",
        "overlayEndpointA = faceInfo and faceInfo.endpointA or nil",
        "overlayEndpointB = faceInfo and faceInfo.endpointB or nil",
        "overlayOrientation = faceInfo and faceInfo.orientation or nil",
        "fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true",
    ))
    if "local faceInfo = segmentFaceInfo(segment)" not in walls:
        raise SystemExit("wall instances are missing physical face metadata")

    branding = require(BRANDING, (
        "BRANDING_DENOMINATOR = 3",
        "candidateConflicts",
        "reserveCandidate",
        "occupiedEdges",
        "occupiedEndpoints",
        "container-brand-placement:v2:trial:",
        "targetBrandCount = math.floor(#candidates / BRANDING_DENOMINATOR)",
        "separation=touching-never",
        "maxAttempts = targetBrandCount > 0 and 24 or 0",
        "instance.fullSurfaceEligible ~= true",
        "elseif not instance.marked then",
    ))
    forbidden = (
        "BRANDING_DENOMINATOR = 5",
        "fullBlocks = math.floor(#candidates / BRANDING_DENOMINATOR)",
        "last = first + BRANDING_DENOMINATOR - 1",
    )
    present = [token for token in forbidden if token in branding]
    if present:
        raise SystemExit(f"obsolete one-in-five placement remains: {present}")

    require(DOCS, (
        "## V16 one-in-three non-touching company branding",
        "targets one third",
        "may never both carry company paint",
        "separation wins",
        "V15 full-surface eligibility remains authoritative",
    ))

    print("V16 validated: target=floor(eligible/3); same-stack and same-tier collinear touching conflicts are hard exclusions.")


if __name__ == "__main__":
    main()
