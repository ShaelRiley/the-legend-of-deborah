# Great Crate C1 — full compositions, coherent decks and bounded vistas

Baseline: verified clean local and remote main
`2afd214a44f539764a25aed7a116eb0e23400d77`. C1 is a substantial implementation
checkpoint, **not full Great Crate completion**. C2 is required; C3 is the final
available implementation pass. No VPS deployment or Workshop publication.

## Implemented

- Kept the already-canonical HL2 `models/props_wasteland/cargo_container01.mdl`;
  no model/collision substitution. Recovered the original 6,446,083-byte archive
  from the exact Drive link in the supplied Shipping Container source. Restored
  all 256 original 1024×512 RGBA images, manifest and author notes; source images
  remain byte-for-byte originals. SHA-256/alpha-bound receipts are in
  `CRATE_ASSET_INDEX.json`.
- Replaced the V8 reconstructed/re-typeset spray atlas with complete compositions.
  Brand 001 is Northern Petrol; 256 is Deborah Logistics Unlimited. Selection
  still uses the dungeon's `container-brand:v1` stream. No gameplay RNG change.
- Found a pre-existing archive defect in 232: its final N runs beyond the canvas.
  The surviving 18-column portion exactly matches the first N in that same title.
  One deterministic derivative preserves every original pixel and clones only the
  missing eight columns onto an expanded canvas. No font/art regeneration, renamed
  company, cropped line or substitute library. The original stays untouched.
- Alpha bounds include every nonzero-alpha pixel plus two transparent pixels where
  available. Uniform min-axis fit uses a 240×78-unit local long-face safe region,
  0.94 margin and 0.8-unit offset; no end-face branding. Existing model bounds and
  transforms drive both sides. Text is neither mirrored nor multiplied by hull hue.
  Marked wayfinding containers are excluded so physical boards cannot cover text.
  Existing coverage ordering, no-touching constraint and global 40% cap remain.
- Production/preview use at most two shared brand shader instances. Texture requests
  are lazy, by selected ID. Same-floor buckets/distance culling and a nearest-first
  ceiling of 64 brand quads bound the render pass. Placement changes are keyed to
  world/seed/wayfinding revision, eliminating the former whole-world marked-count
  walk on every Think. No per-container hook, trace, material or network table.
- One medium neutral concrete floor identity, stock texture through a project
  VertexLitGeneric VMT; 512-unit tiling and global XY UV alignment for row runs,
  partial slabs and rotated stair aprons. Existing 32-unit physical slabs, local
  upper floor entities, floor heights and hidden false-floor behavior are retained.
- At most one existing stair side apron per upper floor becomes a steel grate.
  Selection requires an occupied solid cell immediately below and excludes stacked
  stair apertures/void. Each is one shared cached 192-quad opaque geometry mesh with
  rim and undersides, no translucent floor. Every original collider/railing remains;
  no extra entities, traversable opening, bullet hole or progression link.
- `lod_crate_preview`: orbit/zoom model, unbranded mode, all 256 brands, ten tint
  samples, both sides via orbit, safe-area outline, concrete and grated samples.
  It explicitly labels the inherited unfinished hull material. `lod_crate_status`
  and once-per-world summaries expose model/stock slots/override/tint, company,
  material fallback, fit, selected textures, mesh count, grates and current timings.
- Updated the canonical manual. Replaced the old CI **write/patch/auto-push** job
  with read-only validation; it cannot reinstall obsolete V14/V19 rendering.

## Exact incomplete requirement and recovery evidence

The classic mesh was already in config. The actual historical loss of character is
its global `metal/metalwall001a` replacement. That workaround and existing section
palette are deliberately unchanged in C1. This is **not** a verified restored,
UV-aligned, neutral cargo hull. Prior custom-hull versions have recorded native
black-material failures; they were not reinstated on the strength of header checks.

The workspace contains no original cargo MDL/VVD/VTX, diffuse or normal-map bytes.
A bounded local asset search found only the project's previous generated hulls.
Public asset searches did not recover verified source bytes. Read-only access to
the documented server's SSH port failed with `Network is unreachable`; nothing was
executed or modified on the VPS. This is a source-access blocker, not a claimed
technical impossibility of restoring the preferred container.

C1 adds `lod_crate_export_sources`, which reads the mounted stock model companions,
all returned stock material slots and their diffuse/bump/detail/mask dependencies.
It writes exact bytes as `.dat` plus original paths/CRC/lengths in a manifest under
`garrysmod/data/legend_of_deborah/crate_sources/`. It sends nothing anywhere,
changes no game state, and caps individual/total output at 8/32 MiB. Optional absent
model companions are reported. Use this on a local installed candidate and provide
that directory for C2; no full campaign/playtest or server deployment is necessary.

C2 must inspect the actual UVs and every material channel, clone/reconstruct the NP
region from clean physical cargo detail, remove chroma with luminance headroom,
produce/source-validate supported file-backed materials, verify every slot and
independent section tint, and finish the corresponding material/preview/GDD gates.
Record any C3 remainder exactly. Native appearance/FPS acceptance remains separate.
No feature requirement in the original brief is deleted or deferred by implication.

## Automated evidence

- Original assets: 256 source hashes preserved; **53,469,122** nonzero-alpha runtime
  pixels retained by the UV bounds (includes the exact N continuation); zero runtime
  canvas-edge clipping; deterministic metadata regeneration; sane dimensions/scales.
- Fit/render: **2,048** brand × yaw × side cases execute the production draw path;
  outward winding, transform bounds, UV bounds and independent white vertex tint.
  Lazy material creation, two shader slots, 64-draw cap under 1,000 candidates,
  depth-pass skip, rotated/shared UV seams and grate cache/undersides/cleanup pass.
- Real generator/floor builder: 2,048 brand seeds visit all 256 IDs; **16** generated
  mazes produce **4,948** collision boxes identical with grates enabled/disabled;
  **26** grates total, peak **3**. Missing/stacked lower floors rejected.
- Existing geometry full-update and native resource lifecycle tests pass. Release
  wiring and changed Lua syntax pass. Canonical gate results are recorded below.
- Test-development failure retained: initial geometry test lacked the Source
  `table.Count` boundary double and failed before generation; the harness was
  corrected. No production gate or assertion was weakened.

## Cost comparison (automated accounting, not Source FPS)

| Surface/resource | Baseline | C1 |
| --- | --- | --- |
| Wall models / wall physics | Existing per-instance client models / merged collision | Identical |
| Floor collision count in 16 samples | 4,948 | 4,948 |
| One solid slab | 2 opaque quads / one draw | Same |
| One selected apron | 2 opaque quads / one draw | 192 opaque quads / one draw |
| Maximum observed grate increase | 0 | 570 quads / 1,140 triangles; no added floor draws |
| One ordinary active brand texture, RGBA estimate with mips | 4096×1024: 21.33 MiB atlas | 1024×512: 2.67 MiB; repaired 232: 5.33 MiB |
| Branding shaders across dungeon changes | Up to four atlas shaders | One production shader; one optional preview shader |
| Brand quads per pass | Every eligible near candidate | At most 64, closest first |
| Placement invalidation idle cost | Full-world marked-count walk each Think | Constant-time revision check |
| Shared mesh cache ceiling | 256 | 256, existing eviction/cleanup |

PNG decode/mip allocation and Source texture residency require native measurement.
The engine may retain previously selected source textures; the conservative entire
256-brand uncompressed/mipped catalog is about 685 MiB, rather than an assertion
that only the current texture remains resident. Normal generation loads one brand,
not the catalog. `loadedTextures` and `estimatedTextureMiB` expose this cumulative
bound. C2/low-end work must measure actual residency and evaluate supported compressed
runtime derivatives if necessary, retaining full compositions and legibility. The
preview must not be used to preload all 256 brands as a normal workload. Real frame
latency, Source occlusion/PVS behavior and dense multilevel GPU cost are unobserved.

## Compact native acceptance (pending)

On a local gm_flatgrass candidate: `lod_crate_preview; lod_crate_status`.
Orbit both sides; inspect 001, 232, 256 and a long-name brand under all tint samples;
check full words/slogans/keylines, clipping, sheen, mip legibility and low-angle
z-fighting. The hull is visibly labelled unfinished until C2. Enter one generated
maze, cross a concrete row/rotated stair apron, view a grate from above/below, walk
and drop an item on it, verify cover and the adjacent rails, and compare dense-view
frame/memory timings against the baseline with the same seed/settings/hardware.
Include one full-update/rejoin and reset. This does not authorize VPS/Workshop work.
Capture screenshots for appearance and `console_latest.txt` +
`rpg_summary_latest.txt` for state; session log only if order/timing needs diagnosis.

## Live GDD reconciliation

Read00→01 and relevant05/07 only; full document structure/control scan was saved
without loading the human monolith. No protected controls detected. Updated and
read back00/01 checkpoint routing,05 composition/floor rules and07 exact tuning,
source boundary, native gaps and residency caveat. Readback revision:
`ANLCKQkI61d1UAVGqyK47iaP6sw-8ZojTRRaeymz9XwVnZMQ7u4vT3YT1Gl2r-bifcRryGEDiePbT22YOvZ7I9crEnM-DIrs2AD_zkXfdw`.
Existing deferred briefs and next-week ordering remain unchanged. Final closure
result/implementation readback revision:
`ANLCKQk2sofVSRlUUIL-T7Z4e-N2X8rY2aOIHWJyAYIqZbNICFzpEwucDHMLiMe_RzPm1cZjnCMhW6UP2kqRVbOZPwMD0IzYtq3WlhMDVg`.

## Canonical closure result

`python3 tools/test_checkpoint_g_integration.py` completed successfully:
**218 suites, zero failures**, including the three new Crate suites and all215
inherited regressions. Full output: `GREAT_CRATE_C1_INTEGRATION.log`.
After the bounded timing/memory-diagnostic additions, the affected render suite,
preview syntax, geometry full-update and generated-manual checks were rerun and
passed. Final diff check is clean. These are automated/headless results only.
