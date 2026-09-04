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

## V3 blank substrate: preserve the stock UV layout

The V2 experiment proved that an arbitrary square metal texture cannot replace the cargo model's authored diffuse. The model samples specific regions for broad sides, doors, ends, top and bottom. A generic tile therefore produced nearly black walls and broken-looking ceiling/container-top surfaces.

V3 fixes that architectural error. `tools/assets/build_container_surface_assets.py` obtains four pinned 1024x1024 stock cargo skins that share the same UV layout, converts them to normalized luminance, median-combines their shared structural information, and removes remaining readable markings with low-pass filtering performed **inside the original UV coordinate system**.

The generated runtime diffuse is:

`gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_surfaces/container_blank_metal.png`

Properties:

- 1024x1024, matching the stock cargo diffuse layout;
- neutral gray metal suitable for procedural recoloring;
- no company identity is intentionally retained;
- broad face / door / end / top UV organization remains compatible with the cargo model;
- the existing stock `cargo_container01_normal` normal map remains in use for physical surface relief.

`cl_container_section_recolor.lua` resolves this blank diffuse as the `$basetexture` of the existing per-section `VertexLitGeneric` materials. Section hue remains authoritative through `$color2`; V3 identifies this path as `v9_stock_uv_blank`.

## V3 high-resolution company paint

The V2 spray atlases inherited 64x32 company cells and then enlarged them. That preserved the general silhouette but permanently discarded enough text detail that Source filtering reduced company names to fuzzy white bars at play distance.

V3 does not enlarge the old tiny company text. Instead:

- the four committed 512x256 company atlases remain the supplied icon source;
- `tools/assets/container_brand_names.tsv` preserves the canonical 256 company names (and source slogans as metadata);
- each company is reconstructed into a **256x128** spray cell;
- the supplied left-hand company icon is retained from the authored atlas;
- the company name is re-typeset at native cell resolution in a condensed industrial face;
- runtime output deliberately omits slogans so only the logo and company name must survive gameplay-distance filtering;
- only restrained abrasion and a slight overspray fringe are applied;
- there is no rectangular backing plate.

Four transparent runtime atlases are generated:

- `container_brand_spray_atlas_01.png` — brands `001..064`
- `container_brand_spray_atlas_02.png` — brands `065..128`
- `container_brand_spray_atlas_03.png` — brands `129..192`
- `container_brand_spray_atlas_04.png` — brands `193..256`

Each atlas is 2048x1024 in an 8x8 grid. The PNGs use a compact indexed representation with sixteen useful alpha levels, retaining the 256x128 geometry while keeping repository/runtime size reasonable.

## Runtime renderer

`gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua` owns company-paint presentation.

For an ordinary container it:

1. derives a brand ID from `LOD.Seeds.Derive(levelSeed, "container-brand:v1")`;
2. maps that ID to one of the four V3 spray atlases and one 8x8 UV cell;
3. creates/caches a `VertexLitGeneric` material whose `$basetexturetransform` selects that cell;
4. deliberately avoids the old generated-mipmap request used by V2, preventing needless additional loss of company-name detail;
5. draws the selected transparent mask as a lit world-space quad immediately above the broad metal face;
6. uses a larger portion of the broad container side than V2 (`spanY * 0.62`) so the name is readable without becoming a signboard;
7. chooses light or charcoal paint from the already-authoritative hull luminance for contrast;
8. draws no opaque rectangle behind the company art.

The reverse broad face mirrors the horizontal basis so company text remains readable. The paint remains surface-adjacent to avoid z-fighting while reading as applied paint rather than a floating panel.

For a wayfinding-marked container, `cl_container_marking_panel.lua` remains authoritative and company paint is skipped.

## Reproducible asset build

The production build no longer depends on anonymous Google Drive access from GitHub Actions.

The company portion of the build is repository-local: committed company icons plus `container_brand_names.tsv` generate the four high-resolution spray atlases. The blank cargo substrate is derived from four full-resolution stock cargo VTFs pinned to commit `472d4cb9ac7a32a8a408ac8cfeff6d978e70a75f` of the public `bouletmarc/hl2_ep2_content` archive. CI validates each stock source as 1024x1024 before using it.

The builder requires Pillow, NumPy and `srctools`:

```bash
python -m pip install Pillow numpy srctools
python tools/assets/build_container_surface_assets.py \
  --stock-vtf /path/to/cargo_container01.vtf \
  --stock-vtf /path/to/cargo_container01c.vtf \
  --stock-vtf /path/to/cargo_container02.vtf \
  --stock-vtf /path/to/cargo_container03.vtf \
  --patch-runtime
```

`.github/workflows/import-container-brands.yml` performs this build and validation automatically and commits generated binary assets only when they differ from the repository.

## Runtime validation

After pulling the build and entering a generated labyrinth, run:

`lod_container_brand_status`

Expected:

- `brand=001..256`
- `atlas=01..04`
- `material=ok`
- `path=legend_of_deborah/container_surfaces/container_brand_spray_atlas_NN.png`
- `mode=vertexlit-spray-v3-hires`

Also run:

`lod_container_recolor_status`

Expected:

- `wrong=0`
- `materialVersion=v9_stock_uv_blank`

Visual acceptance:

1. Ordinary containers contain no visible Northern Petrol company art.
2. Container sides, ends, doors and top/bottom surfaces read coherently rather than as a generic tiled texture.
3. The hull accepts the existing procedural floor/quadrant color system clearly.
4. Company art has transparent surroundings with no rectangle/plaque.
5. The logo and company name are legible at ordinary play distance and read as worn paint attached to the lit physical surface.
6. All ordinary containers in one labyrinth use the same deterministic company.
7. A different seed reselects the company; repeating a seed repeats it.
8. Sparse wayfinding containers keep their clear alphanumeric plywood plates.
9. Branding changes presentation only and does not affect maze geometry, collision, gates, minimap topology, hostiles, or navigation.
