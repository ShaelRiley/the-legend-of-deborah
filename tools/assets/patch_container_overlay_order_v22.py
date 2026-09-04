#!/usr/bin/env python3
"""Apply V22 deterministic overlay layering for container branding + wayfinding.

Company spray remains in PostDrawOpaqueRenderables. Wayfinding boards move to the
later PostDrawTranslucentRenderables pass and sit slightly farther off the cargo face,
so a location board always reads as a physical layer above company paint when both
appear on the same shipping container.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PANEL = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_marking_panel.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one occurrence, found {count}")
    return text.replace(old, new, 1)


def patch_panel():
    text = PANEL.read_text(encoding="utf-8")
    if "LOD_V22_WAYFINDING_TOP_LAYER" in text:
        return False

    text = replace_once(
        text,
        "local SURFACE_OFFSET = 2.1",
        "local SURFACE_OFFSET = 2.6\nlocal LOD_V22_WAYFINDING_TOP_LAYER = true",
        "wayfinding physical offset",
    )

    old = '''hook.Remove("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding")
hook.Add("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding", function()
    local world = Wall.world or {}
'''
    new = '''-- V22 owns deterministic overlay order. Company spray is rendered in the opaque
-- pass; location boards render afterward in the translucent-world pass. The board
-- still depth-tests normally, so it remains a physical world object rather than HUD.
hook.Remove("PostDrawOpaqueRenderables", "LOD_DrawContainerWayfinding")
hook.Remove("PostDrawTranslucentRenderables", "LOD_DrawContainerWayfinding")
hook.Add("PostDrawTranslucentRenderables", "LOD_DrawContainerWayfinding", function(bDrawingDepth, bDrawingSkybox)
    if bDrawingDepth or bDrawingSkybox then return end

    local world = Wall.world or {}
'''
    text = replace_once(text, old, new, "wayfinding render-pass hook")

    PANEL.write_text(text, encoding="utf-8")
    return True


def patch_docs():
    text = DOCS.read_text(encoding="utf-8")
    marker = "## V22 overlay layer order"
    if marker in text:
        return False

    appendix = r'''

## V22 overlay layer order

When company spray and a floor/quadrant wayfinding board share one container, the
physical board is always the top visual layer. Company paint remains in the opaque
world pass; plywood locator boards render later in `PostDrawTranslucentRenderables`
and use a 2.6-unit surface offset versus the spray's smaller face offset. The board
continues to depth-test against world geometry, so this ordering does not turn signs
into through-wall HUD elements.
'''
    DOCS.write_text(text.rstrip() + appendix + "\n", encoding="utf-8")
    return True


def main():
    changed = {
        "panel": patch_panel(),
        "docs": patch_docs(),
    }
    print("V22 overlay-order patch:", changed)


if __name__ == "__main__":
    main()
