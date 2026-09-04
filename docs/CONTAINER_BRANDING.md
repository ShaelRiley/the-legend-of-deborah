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


## V6 safe grit texture binding

The V5 Steam Deck playtest proved the 4096x1024 full-side spray atlas and orientation fix: company text became readable and correctly oriented. It also exposed a Source-material interoperability bug. Garry's Mod can mount the committed `container_grit_detail.png` as an `ITexture`, but passing that texture's internal name back into a dynamic material's `$detail` string caused Source to reinterpret it as a standalone `.vtf` path. The missing sampler rendered the hull black.

V6 keeps the PNG asset and removes that failure mode. `cl_container_section_recolor.lua` creates every section material with a guaranteed-valid white detail fallback, then assigns the already-loaded PNG `ITexture` directly with `IMaterial:SetTexture("$detail", detailTexture)`. No generated texture name is round-tripped through Source's filesystem resolver. If the grit texture is unavailable for any reason, detail blending remains zero and the hull degrades to the colored, normal-mapped flat fallback instead of black.

`lod_container_recolor_status` also prints `[LOD:CONTAINER-DETAIL]`. Production should report `mode=runtime-texture`; `mode=flat-fallback` is safe but indicates the optional grime layer did not bind.

## V9 truly blank cargo hull

The V8 Steam Deck playtest proved the alpha-tested spray system: company marks are
legible, deterministic, full-side, correctly oriented and no longer create an opaque
black card. It also made the remaining limitation explicit: using the stock Northern
Petroleum diffuse underneath still leaves the baked `NP / Northern Petrol` art visible.

V9 removes that dependency completely. `tools/assets/build_container_blank_hull_v9.py`
deterministically generates `container_blank_hull_v9.png`, a 1024x1024 company-free
painted-steel substrate containing only physical surface information: repeating
corrugation luminance, thin frame/seam language, dirty blooms, drainage streaks,
scratches and chipped-paint scoring. It contains no company name, logo, serial block
or other semantic rectangle that can land on the wrong UV island.

`cl_container_section_recolor.lua` mounts that PNG and binds its loaded `ITexture`
directly to `$basetexture`. Procedural floor/quadrant `$color2` tint remains
authoritative, but the blend is intentionally below total replacement so the blank
steel luminance survives. The stock `cargo_container01_normal` is retained because it
contains physical corrugation/frame relief rather than branding. The existing neutral
`container_grit_detail.png` remains a lower-strength secondary dirt layer.

The production composition is now:

1. repository-owned truly blank corrugated steel hull;
2. deterministic procedural floor/quadrant hue;
3. neutral grime/scratch detail and stock normal-map relief;
4. V8 alpha-tested company spray on ordinary containers only;
5. plywood wayfinding plate instead of company spray on marked containers.

There is no stock Northern Petroleum diffuse or runtime concealment rectangle in the
ordinary-container presentation path.

Runtime diagnostics should report:

- `materialVersion=v14_blank_hull_v9`
- `[LOD:CONTAINER-HULL] ... mode=runtime-texture blend=0.78`
- `[LOD:CONTAINER-DETAIL] ... mode=runtime-texture blend=0.40`
- `mode=vertexlit-spray-v8-alphatest-dither`
- `wrong=0`

## V10 explicit cargo material-slot replacement

The V9 Steam Deck playtest produced a decisive runtime result: the generated blank
hull and grit textures both reported `mode=runtime-texture`, but the stock `NP /
Northern Petroleum` art still appeared unchanged on the physical cargo model. The
old `wrong=0` diagnostic was not proof of the rendered material because it only
verified our cached call state.

V10 therefore stops treating a single `Entity:SetMaterial` call as authoritative.
For every clientside cargo model, `cl_container_section_recolor.lua` now enumerates
`model:GetMaterials()` and applies the generated blank-hull section material to each
slot with `SetSubMaterial(slot, "!<dynamic material>")`. Only after every material
slot is replaced does it clear the temporary global `models/debug/debugwhite`
construction override. This closes the path through which any stock Northern
Petroleum diffuse/material slot can survive.

The runtime status command now counts a container as correct only when it has a
non-zero material-slot count and reports `appliedSectionMode=submaterials`. It also
prints `[LOD:CONTAINER-SLOTS]`; production should report `mode=submaterials` and a
positive `sampleSlots` value.

Expected V10 diagnostics:

- `materialVersion=v15_blank_hull_submaterials`
- `[LOD:CONTAINER-HULL] ... mode=runtime-texture`
- `[LOD:CONTAINER-DETAIL] ... mode=runtime-texture`
- `[LOD:CONTAINER-SLOTS] mode=submaterials sampleSlots=>0`
- `wrong=0`

## V11 file-backed Source materials

The V10 Steam Deck playtest isolated the remaining material failure. Explicit
`SetSubMaterial` replacement worked: `sampleSlots=3`, `wrong=0`, and the stock
Northern Petroleum art disappeared. The replacement hull itself, however, rendered
black even while the mounted PNGs reported `mode=runtime-texture`. That proves the
remaining fault is the dynamic `CreateMaterial` + runtime PNG `ITexture` composition,
not the cargo mesh, UVs, spray renderer, or submaterial indexing.

V11 removes that runtime texture indirection entirely. The deterministic V9 blank
steel and neutral grit images are compiled during the repository build into ordinary
Source **VTF 7.2 / DXT1** textures with complete mip chains. The finite 72-hue x
5-shell palette is compiled into 360 tiny file-backed `VertexLitGeneric` VMT files.
The runtime maximin palette algorithm still chooses the same candidate colours, but
each chosen section now points directly at a normal material path under
`legend_of_deborah/container_sections/`. `SetSubMaterial` receives that file-backed
path with no `!` dynamic-material prefix and no runtime `IMaterial:SetTexture` calls.

The V11 renderer verifies the real state rather than cached calls: every material
slot must return the expected path through `GetSubMaterial`, the selected VMT must
load without `IsError()`, and its shader must be `VertexLitGeneric` before a container
counts as correct.

Expected V11 diagnostics:

- `materialVersion=v16_filebacked_vtf`
- `[LOD:CONTAINER-HULL] ... mode=file-backed-vtf`
- `[LOD:CONTAINER-DETAIL] ... mode=file-backed-vtf`
- `[LOD:CONTAINER-SLOTS] mode=file-backed-submaterials sampleSlots=>0`
- `[LOD:CONTAINER-VTF] material=ok shader=VertexLitGeneric override=ok`
- `wrong=0`

Visual acceptance remains unchanged: no stock NP art, vivid deterministic section
colour, dirty/corrugated steel instead of a black slab, two visibly distinct stacked
containers, and the existing alpha-tested procedural company spray intact.

## V12 global BGR888 Source material

The V11 Steam Deck test reported `material=ok shader=VertexLitGeneric` but also
`override=wrong` and `wrong=<all containers>`. This proved that the V11 file-backed
VMT parser path existed while the per-slot override state itself was not authoritative.
The visible hull remained black.

V12 removes both remaining uncertainties. Because every cargo material island should
share the same procedurally coloured blank hull, the client now clears all stale
submaterial overrides and applies one ordinary file-backed `VertexLitGeneric` VMT with
`Entity:SetMaterial`. Runtime verification compares `Entity:GetMaterial` directly.

The VTF high-resolution payload is also changed from custom DXT1 compression to plain
BGR888. This is larger but intentionally simple and deterministic. The build validator
decodes the committed largest BGR888 mip and compares it byte-for-byte with the source
PNG, ensuring the mounted Source texture contains the authored gritty blank hull rather
than merely possessing a syntactically valid header.

Expected runtime diagnostics are `materialVersion=v17_filebacked_global_bgr888`,
`[LOD:CONTAINER-GLOBAL] ... override=ok`, and `wrong=0`.

## V13 stock HL2 neutral-metal hull

The V12 Steam Deck test still produced black broad faces. For V13 the implementation
stopped iterating on custom hull encoders and audited mounted Source/Garry's Mod assets
instead. Core Half-Life 2 ships `cargo_container01`, `cargo_container02`, and
`cargo_container03`, but all three are Northern Petrol-branded skins; Counter-Strike:
Source's `de_port` cargo family is also branded and is not a safe base-game dependency.
There is therefore no verified, guaranteed, truly blank stock shipping-container skin.

V13 uses a stronger stock-only composition. The procedural section VMTs use
`metal/metalwall001a` as a neutral worn industrial diffuse, retain
`models/props_wasteland/cargo_container01_normal` for the cargo model's exact corrugation and frame relief, and add the
very restrained `detail/detail_noise1` detail texture. These are mounted stock Source textures,
so the live hull no longer depends on any hand-built VTF or runtime PNG texture path.
The V8 alpha-tested company spray remains separate and unchanged.

The finite maximin palette is unchanged, but its generated files are now `v18_*` and
`materialVersion=v18_stock_hl2_metalwall`. The runtime continues to clear stale submaterials and
uses one global file-backed `VertexLitGeneric` override for the entire cargo model.
Expected diagnostics include `mode=stock-hl2-vtf`, `[LOD:CONTAINER-GLOBAL] ...
override=ok`, `[LOD:CONTAINER-STOCK] material=ok`, and `wrong=0`.

## V14 minimal stock Source hull

V14 is the black-texture containment build. The stock-asset audit found no verified blank cargo skin, so ordinary container hulls use only `metal/metalwall001a` plus the cargo model's native `models/props_wasteland/cargo_container01_normal` normal map. The section VMTs contain no `$detail`, phong, envmap, custom VTF, PNG binding, or dynamic material creation. This deliberately minimizes Source shader dependencies while preserving procedural `$color2` section hue and physical cargo corrugation.

Generated materials are `v19_*` and runtime reports `materialVersion=v19_stock_hl2_minimal`. Expected diagnostics: `[LOD:CONTAINER-GLOBAL] ... override=ok`, `[LOD:CONTAINER-STOCK] material=ok`, `[LOD:CONTAINER-DETAIL] mode=disabled-by-design`, and `wrong=0`. The V8 alpha-tested company sprays and exact two-container wall stack are unchanged.

## V15 sparse full-face-only overlays

Company identity is intentionally sparse. After wayfinding containers are reserved,
ordinary overlay-safe containers are sorted deterministically and divided into complete
blocks of five; exactly one container from each block receives the run's selected
company stencil. Incomplete trailing blocks receive no company paint, so branding can
never exceed 20% of eligible ordinary containers.

Every overlay now shares a conservative full-surface eligibility rule. The client wall
cache classifies each logical wall edge from its grid endpoints. If a perpendicular wall
meets either endpoint, the container is treated as geometrically clipped (corner,
T-junction, short dead end, or related edge case) and receives neither company paint nor
a plywood wayfinding plate. Duplicate logical edges are also ineligible. Collinear
end-to-end walls remain eligible because they do not occlude the broad face.

This classification is presentation-only and is computed once when the immutable wall
manifest is expanded. It does not alter collision, maze topology or navigation.

## V16 one-in-three non-touching company branding

After V15 removes clipped geometry and reserves wayfinding containers, company paint now
targets one third of the remaining eligible ordinary containers. Selection is seeded and
deterministic for a labyrinth. The target count is `floor(eligible / 3)`.

Brand separation is a hard invariant. The upper and lower containers in the same logical
wall stack may never both carry company paint, because they directly touch. In addition,
two collinear containers in the same stack tier may never both carry company paint when
their wall edges share an endpoint. The selector searches deterministic shuffled orders
for an independent set up to the one-third target. If an unusual topology cannot reach
the target, separation wins and the run remains slightly under one third rather than ever
placing two branded containers next to or directly touching one another.

V15 full-surface eligibility remains authoritative: clipped corners, T-junctions, short
dead-end edge cases, duplicate logical faces, and wayfinding-marked containers are excluded
before the one-third target is calculated.

## V17 verisimilitude-oriented brand coverage

Raw one-in-N branding quotas are retired. Footage review showed that the V16 independent
set could satisfy a global numerical target while still leaving long first-person views
visually empty. V17 therefore treats *coverage* as the presentation goal.

After full-face geometry filtering and wayfinding reservation, each dungeon floor targets
approximately 26% of its remaining ordinary containers. Placement uses deterministic
farthest-point (blue-noise-like) sampling in maze-grid space, with a two-cell soft spacing
cushion and a small lower-tier preference so marks are more likely to enter the player's
natural first-person sight line. The intent is typically one visible company mark, with two
or occasionally three in long views, rather than either blank corridors or logo walls.

The no-touching rule remains absolute. Upper/lower partners on one logical wall edge can
never both be branded, and same-tier collinear neighbors that share an endpoint can never
both be branded. If the two-cell aesthetic cushion prevents reaching the target, V17 may
relax that cushion while preserving the physical no-touching invariant. Full-surface
eligibility remains authoritative, so clipped corners and other partial faces stay clean.
