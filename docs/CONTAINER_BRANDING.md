# Procedural Container Branding

## Production rule

The project-supplied `legend_of_deborah_container_brands_256.zip` remains the authored source for shipping-container company art.

- Exactly one brand ID from `001` through `256` is selected deterministically from each generated labyrinth's level seed.
- All ordinary containers in that labyrinth use the same fictional company.
- A new generated labyrinth reselects from the catalog using its new level seed.
- Branding is presentation-only. It does not alter collision, topology, progression, RPG state, encounters, or maze generation.
- Gameplay-authoritative floor/quadrant hull coloration remains owned by `cl_container_section_recolor.lua`.
- Sparse `1A`, `1B`, etc. wayfinding containers keep the stronger plywood location plate instead of company paint.
- Brand `256` remains **Deborah Logistics Unlimited**.

## Blank substrate

Ordinary containers no longer use the Northern Petrol diffuse as their color texture.

The production build generates and mounts:

`gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_surfaces/container_blank_metal.png`

This is a neutral, logo-free metal diffuse: no company name, no logo, no serial branding, and no colored baked paint. `cl_container_section_recolor.lua` loads this PNG, resolves its generated Garry's Mod texture, and uses it as the `$basetexture` of the existing per-section `VertexLitGeneric` materials.

The validated cargo mesh is retained. The stock `cargo_container01_normal` normal map is also retained because it provides physical surface relief rather than company identity. The neutral diffuse therefore accepts the existing procedural floor/quadrant hue cleanly without the legacy red Northern Petrol art underneath it.

## Spray-paint brand assets

The committed four compact source atlases under `container_brands/` remain the self-contained company-art input. `tools/assets/build_container_surface_assets.py` derives four higher-resolution transparent spray masks:

- `container_brand_spray_atlas_01.png` — brands `001..064`
- `container_brand_spray_atlas_02.png` — brands `065..128`
- `container_brand_spray_atlas_03.png` — brands `129..192`
- `container_brand_spray_atlas_04.png` — brands `193..256`

The spray atlases are 1024x512 8x8 sheets. Each 128x64 cell is converted to a neutral paint mask with a soft overspray fringe plus restrained deterministic chips/scuffs. There is no rectangular backing plate in these images.

The builder is deterministic and repository-local. It requires Pillow but performs no Drive/network download:

```bash
python -m pip install Pillow
python tools/assets/build_container_surface_assets.py --patch-runtime
```

`--patch-runtime` also migrates `cl_container_section_recolor.lua` from the baked stock diffuse to the blank neutral base.

## Runtime renderer

`gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua` owns company-paint presentation.

For an ordinary container it:

1. derives a brand ID from `LOD.Seeds.Derive(levelSeed, "container-brand:v1")`;
2. maps that ID to one spray atlas and one 8x8 cell;
3. creates/caches a `VertexLitGeneric` material whose `$basetexturetransform` selects that cell;
4. draws the selected transparent paint mask as a world-space quad immediately above the broad metal face;
5. lets scene lighting affect the paint material rather than rendering it as flat 3D2D UI;
6. chooses light or charcoal paint from the already-authoritative hull luminance for contrast;
7. draws no opaque rectangle behind the company art.

The reverse broad face mirrors the horizontal basis so company text remains readable. The paint is deliberately surface-adjacent (`SURFACE_OFFSET`) to avoid z-fighting while still reading as applied directly to the container.

For a wayfinding-marked container, `cl_container_marking_panel.lua` remains authoritative and company paint is skipped.

## Why this replaces the previous approach

The superseded renderer painted an opaque rectangular same-hue patch over the baked Northern Petrol logo and then drew a 3D2D company image on top. That was useful for proving deterministic brand selection, but visually read as a sign/plaque.

The production pipeline instead starts from truly blank neutral metal and adds only distressed, lit company paint. There is no legacy Northern Petrol diffuse to cover and no rectangular company panel.

## Runtime validation

After pulling the build and entering a generated labyrinth, run:

`lod_container_brand_status`

Expected:

- `brand=001..256`
- `atlas=01..04`
- `material=ok`
- `path=legend_of_deborah/container_surfaces/container_brand_spray_atlas_NN.png`
- `mode=vertexlit-spray-v2`

Also run:

`lod_container_recolor_status`

Expected:

- `wrong=0`
- `materialVersion=v8_blank_metal_surface`

Visual acceptance:

1. Ordinary containers contain no visible Northern Petrol art.
2. The hull itself is neutral metal before procedural recoloring; no logo/text is baked into that base.
3. Company art has transparent surroundings with no rectangle/plaque.
4. Company text/logo reads as worn spray/stencil paint attached to the lit physical surface.
5. All ordinary containers in one labyrinth use the same deterministic company.
6. A different seed reselects the company; repeating a seed repeats it.
7. Floor/quadrant hull colors remain unchanged in gameplay semantics.
8. Sparse wayfinding containers keep their clear alphanumeric plywood plates.
9. Branding changes presentation only and does not affect maze geometry, collision, gates, minimap topology, hostiles, or navigation.
