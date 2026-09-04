#!/usr/bin/env python3
"""Validate the V6+ container presentation pipeline invariants."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SURFACE = ROOT / "gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_surfaces"
RECOLOR = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua"
BRANDING = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua"
WALLS = ROOT / "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua"
DOCS = ROOT / "docs/CONTAINER_BRANDING.md"


def require_tokens(text: str, tokens: tuple[str, ...], label: str) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        raise SystemExit(f"{label} missing tokens: {missing}")


def forbid_tokens(text: str, tokens: tuple[str, ...], label: str) -> None:
    present = [token for token in tokens if token in text]
    if present:
        raise SystemExit(f"{label} contains forbidden tokens: {present}")


def main() -> None:
    detail = SURFACE / "container_grit_detail.png"
    image = Image.open(detail).convert("L")
    if image.size != (1024, 1024) or detail.stat().st_size < 100000:
        raise SystemExit("invalid grit detail asset")
    low, high = image.getextrema()
    if low > 90 or high < 160:
        raise SystemExit(f"grit detail is too flat: {low}..{high}")

    for number in range(1, 5):
        path = SURFACE / f"container_brand_spray_atlas_{number:02d}.png"
        atlas = Image.open(path).convert("RGBA")
        if atlas.size != (4096, 1024):
            raise SystemExit(f"{path.name}: wrong dimensions {atlas.size}")
        if path.stat().st_size < 60000:
            raise SystemExit(f"{path.name}: suspiciously small")
        if atlas.getchannel("A").getextrema()[1] < 220:
            raise SystemExit(f"{path.name}: weak alpha")

    recolor = RECOLOR.read_text(encoding="utf-8")
    require_tokens(
        recolor,
        (
            'DETAIL_FALLBACK_TEXTURE = "vgui/white"',
            'DETAIL_BLEND_FACTOR = 0.64',
            'local MATERIAL_VERSION =',
            '["$detail"] = DETAIL_FALLBACK_TEXTURE',
            'material:SetTexture("$detail", detailTexture)',
            'material:SetFloat("$detailblendfactor", DETAIL_BLEND_FACTOR)',
            '[LOD:CONTAINER-DETAIL]',
            '["$phong"] = "1"',
        ),
        "recolor",
    )
    forbid_tokens(
        recolor,
        (
            'detailTexture:GetName()',
            'params["$detail"] = DETAIL_TEXTURE',
            'local DETAIL_TEXTURE =',
            'v11_gritty_neutral',
        ),
        "recolor",
    )

    branding = BRANDING.read_text(encoding="utf-8")
    require_tokens(
        branding,
        (
            'mesh.Begin(MATERIAL_QUADS, 1)',
            'mesh.TexCoord(0, u, v)',
            'side > 0 and -model:GetRight() or model:GetRight()',
            'SIDE_WIDTH_FRACTION = 0.86',
        ),
        "branding",
    )
    forbid_tokens(branding, ('$basetexturetransform', 'render.DrawQuad('), "branding")

    walls = WALLS.read_text(encoding="utf-8")
    require_tokens(
        walls,
        (
            'STACK_VISUAL_GAP = 4',
            'local stackCount = 2',
            'stack * (GC.ContainerHeight + STACK_VISUAL_GAP)',
            'stackIndex = stack',
            'expectedVisuals = #(Wall.logical or {}) * 2',
        ),
        "wall stack",
    )

    docs = DOCS.read_text(encoding="utf-8")
    if "## V6 safe grit texture binding" not in docs:
        raise SystemExit("V6 documentation missing")

    print(
        "V6+ validated: safe runtime grit ITexture binding, full-side sprays, "
        "and exact two-container wall stacks."
    )


if __name__ == "__main__":
    main()
