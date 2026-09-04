# Procedural Container Branding

## Production rule

The project-supplied `legend_of_deborah_container_brands_256.zip` is the authoritative source for shipping-container company art.

- Exactly one brand ID from `001` through `256` is selected deterministically from each generated labyrinth's level seed.
- All ordinary containers in that labyrinth use the same fictional company.
- A new generated labyrinth reselects from the catalog using its new level seed.
- Branding is presentation-only. It does not alter collision, topology, progression, RPG state, encounters, or maze generation.
- Gameplay-authoritative floor/quadrant hull coloration remains independently owned by `cl_container_section_recolor.lua`.
- Containers chosen for sparse `1A`, `1B`, etc. wayfinding keep the stronger plywood location plate instead of the company decal.
- Brand `256` remains **Deborah Logistics Unlimited**, as authored in the source set.

This makes company identity vary between labyrinth generations without chaotic per-container mixing.

## Runtime assets

The production build uses four transparent 512x256 indexed PNG atlases under:

`gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_brands/`

Files:

- `container_brand_atlas_01.png` — brands `001..064`
- `container_brand_atlas_02.png` — brands `065..128`
- `container_brand_atlas_03.png` — brands `129..192`
- `container_brand_atlas_04.png` — brands `193..256`

Each atlas is an 8x8 grid, so each company occupies one 64x32 cell with the original 2:1 aspect ratio. Transparency is retained so the procedural hull color remains visible around and through the authored decal rather than being replaced by a fixed logo background.

The runtime atlases are deliberately compact derivatives of the 256 original 1024x512 RGBA source textures. The originals remain source authority; the atlas files are the shipped presentation assets.

Garry's Mod mounts the gamemode's `content/materials` tree with the active gamemode. The existing development symlink, dedicated-server deployment, and Workshop build copy the complete `gamemodes/` tree, so these materials travel with normal builds.

## Rebuilding the atlases

`tools/assets/build_container_brand_atlases.py` rebuilds the four runtime atlases from the authoritative ZIP. It validates the complete `001..256` source set and original 1024x512 dimensions before packing the textures.

The builder requires Pillow:

```bash
python -m pip install Pillow
python tools/assets/build_container_brand_atlases.py \
  /path/to/legend_of_deborah_container_brands_256.zip \
  gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_brands
```

The older `tools/assets/import_container_brands.py` remains useful for validating/staging the full-resolution source set, but the four atlases above are the production runtime representation.

`.github/workflows/import-container-brands.yml` now validates the committed runtime assets and renderer wiring on relevant pushes; it no longer depends on anonymous Google Drive downloading.

## Renderer

`gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua` owns company-decal presentation.

For an ordinary container it:

1. derives a brand ID from `LOD.Seeds.Derive(levelSeed, "container-brand:v1")`;
2. maps that ID to one of four atlases and one 8x8 UV cell;
3. loads only the selected atlas as a cached Garry's Mod material for the current level seed;
4. aligns an opaque same-hue repaint patch over the baked Northern Petrol branding zone;
5. derives that patch from the already-authoritative procedural section/body color;
6. composites the selected transparent fictional-company decal over the patch.

For a wayfinding-marked container, `cl_container_marking_panel.lua` draws the existing plywood location stencil and `cl_container_branding.lua` deliberately skips company branding.

Both systems use the same mirrored broad-face logo anchor. This replaces the baked stock branding without replacing the validated cargo-container mesh, collision, normal map, or floor/quadrant recolor shader.

## Runtime validation

After entering a generated labyrinth, run:

`lod_container_brand_status`

Expected:

- `brand=001..256`
- `atlas=01..04`
- `material=ok`
- `path=legend_of_deborah/container_brands/container_brand_atlas_NN.png`

Also run:

`lod_container_recolor_status`

Expected:

- `wrong=0`

Visual acceptance:

1. Ordinary nearby containers show the selected fictional company rather than stock Northern Petrol.
2. All ordinary containers in one generated labyrinth use the same company.
3. A different level seed deterministically reselects the company.
4. The same explicit level seed reproduces the same company.
5. Floor/quadrant hull colors remain unchanged and readable.
6. Sparse wayfinding containers still show their alphanumeric plywood plate instead of a company decal.
7. Branding does not alter maze geometry, collision, minimap topology, gates, hostiles, or navigation.
