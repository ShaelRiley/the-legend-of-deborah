#!/usr/bin/env python3
"""Validate V22 deterministic container overlay layering."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PANEL = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_marking_panel.lua"
BRAND = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def require(path, tokens):
    text = path.read_text(encoding="utf-8")
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{path.name} missing: {missing}")
    return text


def main():
    panel = require(PANEL, (
        "SURFACE_OFFSET = 2.6",
        "LOD_V22_WAYFINDING_TOP_LAYER",
        'hook.Remove("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding")',
        'hook.Remove("PostDrawTranslucentRenderables", "LOD_DrawContainerWayfinding")',
        'hook.Add("PostDrawTranslucentRenderables", "LOD_DrawContainerWayfinding"',
        "if bDrawingDepth or bDrawingSkybox then return end",
    ))
    if 'hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding"' in panel:
        raise SystemExit("wayfinding still registers an opaque render hook")

    brand = require(BRAND, (
        'hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerBranding"',
        "instance.companyBranded == true",
    ))
    if 'hook.Add("PostDrawTranslucentRenderables", "LOD_DrawContainerBranding"' in brand:
        raise SystemExit("branding unexpectedly moved into the late wayfinding pass")

    require(DOCS, (
        "## V22 overlay layer order",
        "physical board is always the top visual layer",
        "PostDrawTranslucentRenderables",
        "2.6-unit surface offset",
    ))

    print("V22 validated: company spray renders first; depth-tested wayfinding boards render later and physically in front.")


if __name__ == "__main__":
    main()
