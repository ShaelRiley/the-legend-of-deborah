# Procedural Container Branding

## Production rule

The project-supplied `legend_of_deborah_container_brands_256.zip` is the authoritative source for shipping-container company art.

- Exactly one brand ID from `001` through `256` is selected deterministically from each generated labyrinth's level seed.
- All ordinary containers in that labyrinth use the same fictional company.
- A new generated labyrinth reselects from the catalog using its new level seed.
- Branding is presentation-only. It does not alter collision, topology, progression, RPG state, or encounter logic.
- Gameplay-authoritative floor/quadrant hull coloration remains independently owned by `cl_container_section_recolor.lua`.
- Containers chosen for sparse `1A`, `1B`, etc. wayfinding keep the stronger plywood location plate instead of the company plate.
- Brand `256` remains **Deborah Logistics Unlimited**, as authored in the source set.

This makes the company identity vary between labyrinth generations without chaotic per-container mixing.

## Runtime asset location

The importer copies the original, unmodified 1024x512 RGBA source PNGs to:

`gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_brands/`

Files remain:

`container_brand_001.png` ... `container_brand_256.png`

Garry's Mod mounts a gamemode's `content/materials` tree with the active gamemode. The existing development symlink, dedicated-server deployment, and Workshop build all copy the complete `gamemodes/` tree; their existing `content/html` exclusion does not remove these materials.

The full source catalog is retained in:

- `docs/CONTAINER_BRAND_MANIFEST.json`
- `docs/CONTAINER_BRAND_SOURCE_README.md`
- `docs/CONTAINER_BRAND_GENERATION_NOTES.md`

## Import/reproducibility

`tools/assets/import_container_brands.py` validates before importing:

- exactly 256 texture IDs, `001..256`;
- canonical file naming;
- PNG signature and IHDR;
- 1024x512 dimensions;
- 8-bit RGBA color type;
- a 256-row manifest with the same complete ID set.

The one-time GitHub workflow `.github/workflows/import-container-brands.yml` fetches the project source archive, runs that validator/importer, and fast-forwards the generated asset commit onto `main`. It triggers only when the importer/workflow itself changes, so generated asset commits cannot recursively retrigger it.

Authoritative project source:

`https://drive.google.com/file/d/163r5QM5sffdD0gi5uqQk-XC6nKvn9hDa/view?usp=sharing`

## Renderer

`cl_container_marking_panel.lua` owns final side-panel presentation.

For an ordinary container it:

1. derives a brand ID from `LOD.Seeds.Derive(levelSeed, "container-brand:v1")`;
2. loads only that PNG as a cached GMod material for the current level;
3. aligns an opaque paint patch over the baked Northern Petrol branding zone;
4. derives the patch color from the already-authoritative procedural section color;
5. composites the transparent fictional-company art over the patch.

For a wayfinding-marked container it draws the existing plywood location stencil instead.

The same model-space anchor is used on both mirrored broad faces. This replaces the baked stock branding without replacing the validated cargo-container mesh, collision, normal map, or floor/quadrant recolor shader.

## Runtime validation

After entering a generated labyrinth:

`lod_container_brand_status`

Expected:
- `brand=001..256`
- `material=ok`
- `path=legend_of_deborah/container_brands/container_brand_NNN.png`

Also run:

`lod_container_recolor_status`

Expected:
- `wrong=0`

Visual acceptance:
1. Ordinary nearby containers show the selected fictional company rather than stock Northern Petrol.
2. All ordinary containers in one generated labyrinth use the same company.
3. A different level seed deterministically reselects the company.
4. The same explicit level seed reproduces the same company.
5. Floor/quadrant hull colors remain unchanged.
6. Sparse wayfinding containers still show their alphanumeric plywood plate.
7. Branding does not alter maze geometry, collision, minimap topology, gates, hostiles, or navigation.
