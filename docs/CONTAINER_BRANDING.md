# Procedural Container Branding

## Production rule

The authored 256-company catalog remains the source of shipping-container identity.

- Exactly one brand ID from `001` through `256` is selected deterministically from each generated labyrinth's level seed.
- All ordinary containers in that labyrinth use the same fictional company.
- A new generated labyrinth reselects from the catalog using its new level seed.
- Branding is presentation-only. It does not alter collision, topology, progression, RPG state, encounters, or maze generation.
- Gameplay-authoritative floor/quadrant hull coloration remains owned by `cl_container_section_recolor.lua`.
- Sparse `1A`, `1B`, etc. wayfinding containers keep the stronger plywood location plate instead of company paint.
- Brand `256` remains **Deborah Logistics Unlimited**.

## V5 hull: neutral color plus physical grime

V4 proved that a uniform white diffuse is a safe way to eliminate legacy Northern Petroleum art, but it also removed too much of the shipping container's visual character. The hull became clean, flat and cel-shaded even though the stock normal map remained present.

V5 separates color from surface dirt:

- the authoritative hull base remains company-neutral and UV-agnostic;
- procedural section hue remains fully owned by `$color2`;
- `container_grit_detail.png` adds deterministic grayscale grime through `VertexLitGeneric` `$detail` / Mod2X blending;
- 128 gray is the neutral point, so the detail texture darkens oily/rusty patches and brightens scratches without forcing one fixed paint hue;
- the stock `models/props_wasteland/cargo_container01_normal` normal map remains mounted for physical corrugation and frame relief;
- restrained phong response makes the normal-map ridges and chipped steel catch light instead of reading as a flat color field.

Runtime material version:

`v11_gritty_neutral`

The former `container_blank_metal.png` experiment is removed from runtime assets. It is not needed to hide Northern Petroleum branding and is no longer an authority for hull appearance.

## V5 full-side company paint

The V3 spray renderer exposed two playtest failures: one broad side read backwards, and the stencil occupied too little of the actual shipping-container wall while clipping near one end.

V5 fixes both the source asset and the world-space transform:

- each company receives a **512x128** wide stencil cell;
- four 4096x1024 atlases retain the canonical 8x8 / 64-brand organization;
- the authored compact company emblem remains the logo source;
- card-border fragments are filtered from full-card variants before the emblem is enlarged;
- the canonical company name is re-typeset at native resolution in a condensed industrial face;
- the canonical slogan is included as secondary copy when it fits;
- a divider line, restrained abrasion and faint overspray create a physical stencil/spray treatment;
- no opaque rectangle or placard is drawn.

`cl_container_branding.lua` selects one brand through:

`LOD.Seeds.Derive(levelSeed, "container-brand:v1")`

The selected 8x8 atlas cell is now addressed with explicit mesh UV coordinates instead of `$basetexturetransform`. This prevents transform-dependent clipping. The reverse broad side uses the opposite outward tangent so text reads left-to-right from either side of the wall.

The rendered paint occupies approximately 86% of the container's broad-side length and is centered on the side rather than anchored near one end. The 4:1 authored stencil aspect is matched to the physical broad-side quad.

Runtime renderer mode:

`vertexlit-spray-v5-fullside`

## Two-container wall invariant

Every logical maze wall edge is visually represented by **exactly two separate cargo-container models stacked vertically**. V5 makes this explicit rather than merely trusting configuration defaults:

- runtime presentation enforces a stack count of two;
- lower and upper containers remain independent clientside models;
- a small presentation-only vertical seam separates the two models so their frames do not visually fuse into one stretched slab;
- authoritative server collision remains unchanged and continues to block the full anti-bypass wall height.

The seam is presentation-only. It does not create a traversable gameplay gap.

## Reproducible asset build

`tools/assets/build_container_surface_assets.py` deterministically generates:

- `container_grit_detail.png` — 1024x1024 neutral grime/detail;
- `container_brand_spray_atlas_01.png` — brands `001..064`;
- `container_brand_spray_atlas_02.png` — brands `065..128`;
- `container_brand_spray_atlas_03.png` — brands `129..192`;
- `container_brand_spray_atlas_04.png` — brands `193..256`.

The company build is repository-local. It uses the committed compact authored emblems plus `tools/assets/container_brand_names.tsv`; it does not depend on anonymous Google Drive downloads.

Dependencies:

```bash
python -m pip install Pillow numpy
python tools/assets/build_container_surface_assets.py
```

`.github/workflows/import-container-brands.yml` rebuilds and validates the generated assets and runtime wiring on relevant changes.

## Runtime validation

After pulling the build and entering a generated labyrinth, run:

`lod_container_brand_status`

Expected:

- `brand=001..256`
- `atlas=01..04`
- `material=ok`
- `mode=vertexlit-spray-v5-fullside`

Also run:

`lod_container_recolor_status`

Expected:

- `wrong=0`
- `materialVersion=v11_gritty_neutral`

Visual acceptance:

1. No Northern Petroleum logo/text survives on ordinary containers.
2. Section colors remain vivid and deterministic but no longer look like clean cel-shaded slabs.
3. Grime, scratches, dirty streaking and normal-map relief remain visible through every legal section hue.
4. Company logo/name read left-to-right on either broad face.
5. Company paint is centered, unclipped and occupies most of one individual container side.
6. All ordinary containers in one generated labyrinth share the same deterministic company; a new seed may select any of the 256 companies.
7. Each logical wall clearly reads as two separate 128-unit cargo containers stacked vertically, with a visible midpoint seam.
8. Sparse wayfinding containers retain the stronger plywood alphanumeric plate.
9. Branding and presentation do not alter maze topology, collision, gates, minimap topology, hostiles, progression or navigation.
