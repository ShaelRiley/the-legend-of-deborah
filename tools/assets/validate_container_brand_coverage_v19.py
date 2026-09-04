#!/usr/bin/env python3
"""Validate V19 coverage-first container branding."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
WAYFINDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua"
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
        "BRAND_COVERAGE_RADIUS_CELLS = 3",
        "BRAND_COVERAGE_GOAL = 0.92",
        "container-brand-coverage:v5",
        "buildBlockedPassages",
        "coverageForInstance",
        "passageKey",
        "coverageGain",
        "pickCoverageCandidate",
        "selectCoverageOrder",
        "distribution=coverage-first",
        "separation=touching-never",
        "instance.brandSurfaceEligible == true",
        "coveragePrefixCount",
        "relaxedGeometryCount",
    ))
    if "BRAND_SOFT_SPACING_CELLS" in branding:
        raise SystemExit("obsolete V17/V18 soft-spacing quota remains in V19 runtime")
    if "instance.fullSurfaceEligible == true and not instance.marked" in branding:
        raise SystemExit("company render guard still incorrectly requires strict full-face eligibility")

    walls = require(WALLS, (
        "buildBrandSurfaceEligibility",
        "brandSurfaceEligible = brandSurfaceEligibility[segmentIndex] == true",
        "overlayDirection = segment[4]",
        "fullSurfaceEligible = fullSurfaceEligibility[segmentIndex] == true",
        "counts[info.edgeKey] == 1",
    ))
    if walls.count("brandSurfaceEligible = brandSurfaceEligibility[segmentIndex] == true") != 1:
        raise SystemExit("brand-surface metadata must be assigned exactly once")

    # Wayfinding must remain on the stricter V15 classifier even though company paint
    # can use the inset decal-safe face.
    require(WAYFINDING, (
        "instance.fullSurfaceEligible == true",
    ))

    require(DOCS, (
        "## V19 coverage-first company branding",
        "three-cell neighborhood",
        "roughly 92%",
        "global ceiling of 40%",
        "decal-safe eligibility",
        "Physical separation remains absolute",
    ))

    print("V19 validated: corridor-aware coverage-first placement, decal-safe company faces, 40% global cap, and absolute no-touching.")


if __name__ == "__main__":
    main()
