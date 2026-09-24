# Great Crate C2 — stock-derived hull candidate

Baseline: clean local and fetched remote main
`bdfaf6c860a24934d348dbb46b8fc31251455b2c`. No intervening commits at start.
No VPS or Steam Workshop deployment. C2 banks the repaired assets and reversible
native test path; **Great Crate is not yet complete**. C3 remains the final pass.

## Source provenance and actual model inspection

The author supplied `LoD-Crate-Stock-Sources-20260924-123319.zip`, exported by the
C1 standalone command from local Sandbox/gm_flatgrass. All 11 manifest lengths
and CRCs verify; total 2,854,873 bytes, no missing paths. The original archive is
preserved at `tools/fixtures/crate_stock/source_export.zip`; SHA-256 receipts for
all bytes are in `CRATE_HULL_C2.json`. The game log included mounted local addons,
so the manifest alone was not treated as independent stock provenance.

Independent stock inventory:
https://github.com/SteamTracking/GameTracking-TF2/blob/b6d0d7c104db22f520f5608e25aec4a7580a5fd2/hl2/hl2_textures_dir.txt
The active red diffuse `dc126984`, normal `f33bf1e9` and blue diffuse `5d6d407f`
match the inventory's CRC32 and 699,256-byte size. Orange diffuse and model
companions have export CRC/SHA receipts and internal consistency validation;
no independent stock checksum match is claimed for those files. The candidate
uses the independently matched red diffuse and shared stock normal.

Inspected all three 1024-square DXT1 diffuse atlases and their VMTs: each skin has
NP at the same coordinates. The only active additional sampler in all three is
`cargo_container01_normal`; envmap/mask lines are comments. The normal was decoded
and visually inspected: corrugation and door relief, no NP letters. Leave it
unchanged; do not synthesize an unnecessary replacement normal.

MDL version44, VVD version4, VTX version7 share checksum162890868. The model has
one mesh, material index0, 664 LOD0 vertices and three textures/skin families.
Skin table is [0,1,2; 1,1,2; 2,1,2]. Actual vertex bounds (not guessed model axes):
X -63.051464..64.947823; Y -192.100876..195.440399; Z -60.343300..67.656700.
Long sides are local X faces; the C1 brand renderer already uses that convention.
All actual UVs are within the stock atlas (exact ranges in receipt). One global
neutral atlas override therefore preserves the model's physical UV mapping across
all returned slots/skins without introducing per-slot native state.

## Repair and encoding

`python3 tools/assets/build_crate_hull.py` reproduces every candidate artifact.
Source bytes remain unchanged. At 1024-square resolution, repair rectangle
[136,44,432,194) contains the entire NP logo and company name. Clone clean stock
corrugation from the same X columns at [136,200,432,282), preserving groove phase.
Resample only its vertical extent. Match its vertical illumination trend using
an unbranded reference band X450..680; blend the outer14 pixels, with the entire
logo/name inside the fully replaced core. The donor excludes the conspicuous
lower-panel scratch to avoid duplicating that identifiable feature. No blur,
flat fill, recreated lettering or new art replaces the physical stock detail.

Apply Rec.709 luminance and the monotonic curve
`min(245,235*(luminance/white)^0.65)`, rounded to equal RGB channels. `white` is the
95th percentile of the repaired side's paint region (recorded in receipt).
This preserves physical value structure, dark recesses, seams and weathering
while adding multiplicative tint headroom. Cargo serial markings remain;
intrinsic company branding does not. UV layout is untouched.

Runtime artifact: VTF7.2, BGR888, 1024x1024, one frame/depth, complete11 mips,
trilinear/anisotropic flags, no alpha and no thumbnail. Payload is4,194,303 bytes
plus80 header bytes. This is one shared diffuse (~4MiB payload; conservatively
~5.33MiB if the driver expands to32-bit), not360 copies. File-backed lit-model
VMTs preserve all360 exact inherited palette color vectors; candidate blend-over
is0, ordinary multiplicative tint, with the stock normal and no detail/phong/envmap.
The PNG is an offline inspection source, never loaded by the runtime shader.

`GREAT_CRATE_C2_SURFACES.png` shows decoded source, repaired atlas with real UV
vertices, unchanged normal, and ten offline tint samples. This is **not** a
Source-engine screenshot, shader acceptance or measured video memory.

## Integration and safe native gate

The existing section-material authority owns the candidate switch; no additional
per-container hook, network state, trace, entity, model or gameplay RNG stream.
`lod_crate_hull_candidate 0` is the default; the convar is not archived or sent to
the server. `1` opts the current local client into the candidate section files.
The existing <=192-model reconciliation batch handles both directions. Missing
material, wrong shader, absent/error/wrong-size diffuse falls back to the matching
existing V19 section material. This detects missing samplers, not black shader
output; native inspection remains mandatory. Existing source collision is unchanged.

`lod_crate_preview` now opens unbranded on the candidate with a candidate/fallback
checkbox, orbit/zoom, all10 tints, all256 original brands and existing floor/grate
samples. Its mutable preview material is isolated from production section VMTs.
`lod_crate_status` reports the candidate request, sample override/shader/sampler,
errors and fallback. Normal default summaries do not load the candidate texture.
Recolor diagnostics retain exact actual override readback and fallback counts.

## Automated evidence

Targeted source/UV/encoding gate passes: all11 receipts, all3 skin/VMT mappings,
664 UVs, all11 decoded BGR mip levels, equal RGB, useful value variation,
all360 exact palette vectors,10 independent tint ratios, byte-identical rebuild.
Production Lua harness passes with600 client models: default-off, on/off,
unchanged palette, <=192 writes/batch,5 distinct material/sampler failure modes,
restoration, replacement-model reconciliation and idle quiescence. Syntax passes.
C1 original-art/fit/render/floor gates remain in the canonical matrix unchanged.

Preserved development failure: an initial new test assumed generic X-long bounds
(-192..192). The actual VVD is Y-long with an offset origin. The test was corrected
to the inspected stock bounds; no production geometry was changed and no existing
assertion was weakened. No native failure/success is inferred from that harness.

Canonical integration result and GDD readback receipt are recorded below.

## One compact native procedure before C3

Use this C2 repository candidate locally on gm_flatgrass. No server deployment.
Run `lod_crate_preview; lod_crate_status`. Leave unbranded first; orbit both long
sides, both ends and roof. Inspect white, all saturated tints, dark and earth:
no black/missing surface, residual NP, obvious patch, hue bias or lost corrugation.
Compare the fallback checkbox. Select brands001,232,256 and a long name; inspect
full text/keylines, low-angle offset, distance/mips and the concrete/grate samples.

Then in a generated maze run `lod_crate_hull_candidate 1`; after the bounded
reconciliation settles, run `lod_container_recolor_status; lod_crate_status`.
Require correct overrides/no unintended fallback, independently colored sections
and unchanged branding. Cross a concrete seam/rotated apron; look above/below a
grate, walk/drop an item, check cover/rails. Include one reset and full-update/rejoin.
Return screenshots plus console_latest.txt and rpg_summary_latest.txt. Compare
same-seed/settings dense-view frame time and texture residency across successive
seeds; neither the Python estimate nor Lua heap usage measures Source GPU residency.
`lod_crate_hull_candidate 0` restores the inherited presentation immediately.

C3 must address native defects, promote the verified hull only after evidence,
finish residency/visual-cost evidence and original brief reconciliation, update
live GDD/docs, run applicable gates and verify a non-forced push. No C4. Existing
native engine/material/performance evidence gaps are not silently declared done.
The unchanged roadmap follows Great Crate with low-end optimization, focused
fatal/game-breaking safety and native playtest; Big Loot then Events then the
comprehensive audit remain deferred to September28–October4,2026.

## Live GDD reconciliation

Read the live entrypoint/index and required05/07 rules; fresh trusted full-structure
read detected no protected controls. Updated00/01 routing and05/07 stock-hull
contract/tuning without changing the immediate/deferred roadmap. All four targeted
tabs were read back successfully at revision:
`ANLCKQnM1Bn8EQJaR53BbIePjWFjbssafHXaI5ljI-_PcbsiixYcU3zz_VK2myurxeb0RMRBe-4wOWNYl3FFzwCUc9RB9aeK37tDp01v8A`.
Candidate implementation, default fallback, native boundaries and final C3 scope
are explicit; earlier source-unavailable paragraphs are marked superseded.

## Recovery and automated closure — September 24, 2026

Recovered the original C2 workspace after its thread stalled before commit.
Remote main still matched the C1 parent; all staged changes were preserved.
The original canonical gate had finished: **220 suites passed, zero failures**.
Its complete log is committed as GREAT_CRATE_C2_INTEGRATION.log; this is the
recovered C2 run, not a newly repeated full matrix. No production code changed
during recovery. Fresh recovery runs of test_great_crate_hull.py and
test_great_crate_hull_runtime.lua passed, including byte-identical reproduction
and the 600-model candidate/fallback lifecycle. Staged and working diff checks pass.

Live GDD entrypoint, index and relevant 05/07 rules were read back during recovery
at the same revision recorded above; C2 design edits survived the stalled thread.
The native gate and C3 scope remain unchanged. No VPS/Workshop deployment.

Integration-log SHA-256: `ef3498aeaa499f832a15d672cf77671dbd4fb73f8423491bad131818200de557`.
