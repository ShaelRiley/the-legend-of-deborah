# Great Crate C3 — rejected presentation repaired; native retest outstanding

## September 24 follow-up — submitted branding faces were reversed

Baseline: clean, fetched `ccc6535e0db22943185fa4b1fb6ca50d1a880432`.
The author now approves the shown restored hull, but reports no company sprays.
Their native `lod_container_brand_status` receipt reports brand140, Atlas Tire
Pyrolysis, valid UnlitGeneric material, 716 branded / 1792 containers, 36 emitted
draws, zero skips, one shader slot/texture, and 1173/1323 coverage observations.
The reported render time is 1.2051ms for that sample, not a performance baseline.
This establishes selection/material lookup/submission, not visible rasterization.

The renderer submitted each quad in the opposite order to native Source front
faces with `$nocull=0`. Independent inspection of the checksum-verified stock
cargo VTX/VVD found all428 nondegenerate triangles have
`cross(v2-v1,v3-v1) dot outwardNormal < 0`; the old branding test erroneously
required `> 0`. Facepunch's upward-facing `render.DrawQuad` example independently
uses the same negative-cross order:
https://wiki.facepunch.com/gmod/render.DrawQuad
The generic mesh-primitives prose had been interpreted the other way; native
stock triangle indices and the concrete API example resolve that ambiguity.

Bounded repair: reverse only quad traversal, preserving each corner's original
UV, physical anchor, independent shader, depth testing, culling, complete artwork,
selection, fit, two material slots and64-draw ceiling. Add diagnostic renderer
receipt `source-front-face-20260924` to identify an updated installed build.
Hull, concrete, gates, collision, gameplay, networking and RNG are unchanged.
This is the author's explicitly requested repair of the remaining C3 defect,
not a new Crate feature pass or permission to expand the original scope.

The corrected regression failed on the old production code with
`Source front-face winding is reversed`, then passed after the repair for all
2048 brand/side/yaw combinations. New UV-direction assertions prevent mirrored
or upside-down text. The focused asset check also passes for all256 originals.
Fresh `python3 tools/test_checkpoint_g_integration.py` completed after the repair:
**221 suites passed, zero failures**, including the Lua syntax gate. Tested blobs:
- Renderer: `7ccad11e996b6d5f1b54cbf064c15cf0875e81f0`.
- Regression: `33285752855ef581addaff110bea839d2e18fa2a`.

The captured matrix summary is byte-identical to the preserved
`GREAT_CRATE_C3_INTEGRATION.log` (SHA-256
`e5df3426ff68cf78004748ff6a117e7924decedd742152f66353704bf2c5bfb6`):
this runner prints suite names/pass states rather than successful test stdout,
and its suite list/cwd are unchanged. This was a fresh invocation against the
changed blobs above, not an inherited pass. No production/test changes followed.

**Next native action:** fully quit GMod, pull/install this repair and inspect
company sprays in the maze. Return one screenshot showing a complete composition;
if still absent, return `lod_container_brand_status` output from that same view.
Its renderer field must read `source-front-face-20260924`. No full log package
is required for this isolated retest unless it exposes a further concrete defect.
Native visibility is pending, not inferred from the corrected static test.

All unfinished original exits in the reconciliation table below remain open:
broader hull/tint sampling, brand offset/mips/legibility, stock gate appearance,
floor/grate traversal/cover/rails, reset/rejoin and dense successive-seed native
frame-time/residency. The approved hull/floor samples are preserved. The roadmap
remains Crate → low-end optimization → focused fatal/game-breaking safety → native
playtest; deferred September28–October4: Big Loot → Events → comprehensive audit.
No VPS or Workshop deployment.

## Original C3 recovery record

Baseline: verified clean main `655ca0c7c126a66bacc5c39f67cffbd810cd4089`.
Author feedback: **failed** overall; old hull still displayed, no company sprays,
and gates looked like concrete. Floor appearance explicitly approved. Preserve
that approval without extrapolating to every floor seed, collision or performance.
The two supplied screenshots are retained verbatim as
GREAT_CRATE_C3_REJECTED_HULL.png and GREAT_CRATE_C3_REJECTED_GATE.png.

## Diagnosis and changes

1. C2 deliberately defaulted `lod_crate_hull_candidate` to0, so ordinary maze play
   continued to display the rejected V19 generic material. The screenshots do not
   prove that the opt-in repaired texture failed to decode. The current author
   request supersedes that default-off decision: the next build starts on1,
   preserving0 as an explicit recovery comparison. Exact C2 texture, palette,
   sampler checks and <=192-model reconciliation remain unchanged. This is an
   implementation default, **not** a claim of native visual acceptance.
2. The company renderer submitted immediate quads through VertexLitGeneric,
   dependent on model lighting state. Facepunch documents mesh shading issues
   with that shader. C3 uses independent UnlitGeneric alpha-tested quads, retaining
   the exact authored compositions, alpha fit, outward winding and depth testing.
   It anchors to inspected cargo VVD bounds rather than render-culling bounds;
   noncanonical models are rejected. The old counter counted candidate submissions
   even if Draw returned before emitting a quad; diagnostics now count actual
   emitted quads and report skips/shader. Missing material retries are limited to
   once per2s. Without the original console/status log, the precise native cause
   of absent sprays cannot be uniquely proven; these repairs remove the exposed
   shader/bounds failure paths, with native retest still required.
3. The gate renderer called GetIndustrialMaterial, which now resolves concrete.
   This is the confirmed cross-system material leak. Gates now draw the real stock
   HL2 `models/props_lab/blastdoor001c.mdl`, with its own materials and geometry.
   One reusable client model serves every gate. Mounted model bounds determine
   thin axis, scaling and origin correction for both gate orientations. The door
   fits the existing384-wide,384-high,28-thick blocker volume. Dedicated
   `models/props_c17/FurnitureMetal001a` fallback and128-unit UVs never consult the
   floor resolver. Existing keycard bands/readers/signs, rise animation, server
   collision and all event/progression ownership remain unchanged. Model cleanup
   covers map cleanup, shutdown and Lua refresh; allocation retries use2s backoff.
4. Approved concrete VMT, texture, color, world UVs, floor geometry/collision and
   grate selection are unchanged. No gameplay/network/RNG authority changed.

Technical references used for the bounded shader/bounds repair:
- https://wiki.facepunch.com/gmod/Global.Mesh
- https://wiki.facepunch.com/gmod/mesh_primitives
- https://wiki.facepunch.com/gmod/Entity:GetModelBounds
These describe engine APIs, not runtime proof of this candidate.

## Validation

Targeted production harnesses pass: default repaired hull and reversible fallback;
600-model bounded reconciliation;2048 brand fit/orientation cases with zero culling
bounds; wrong-model rejection and truthful emitted draw counts; real wall compiler
→ eligibility → deterministic/no-touching/40%-bounded placement → bucket rendering;
64-draw limit, unchanged floor UV seams/grate cache; both gate axes and model thin
axes with off-center origins; closed/moving/open gates; one shared model; failed
allocation backoff; cleanup/shutdown/refresh; independent fallback and depth skip.
The existing full-update recovery test passes unchanged.

Preserved harness development failure: the expanded wall-compiler test initially
omitted Remove on its old model double. Adding that native method to the fixture
fixed the harness; no production condition or gameplay assertion was weakened.

Canonical integration result and final GDD readback are recorded at closure below.

## Original brief exit reconciliation

| Brief exits | State at C3 |
| --- | --- |
| 1: canonical HL2 cargo model | Implemented; source identity/UV inspected in C2. |
| 2–5: intrinsic NP repair, retained detail, neutral tint and clean colors | Reproducible source-derived assets and repaired default implemented; native appearance/decoder acceptance pending. |
| 6–8: procedural NP,256 original brands, coherent seed selection | Implemented and statically validated; unchanged identities/RNG. |
| 9–14: whole compositions, safe placement, no clipping/leak/floating, legibility | Fit/UV/winding and production placement validated; shader repaired; native sprays, offset/mips/legibility require retest. |
| 15–17: coherent concrete, continuity and restrained variation | Implemented; author approves shown floor appearance. Broader seed/lighting sample remains open. |
| 18–22: floor collision, selective vertical vistas, occlusion and no bypass | Existing collision/topology/geometry gates preserved; native traversal, cover/rails and dense-view GPU cost pending. |
| 23–26: deterministic/compact/shared/lazy rendering | Static gates retained;1 shared gate model,2 brand shader slots,64 brand draws; actual successive-seed texture residency pending. |
| 27–30: preview, diagnostics, automated and integration tests | Updated preview/actual draw diagnostics; gate diagnostics; targeted and canonical results below. |
| 31–34: GDD, roadmap, commit and verified main | Updated/read back; publication response supplies exact verified commit. |
| 35: no VPS/Workshop deployment | Preserved. |

## Finite native retest and remaining boundary

Fully quit GMod, update/install the candidate locally, reopen Legend of Deborah
on gm_flatgrass. The corrected hull is now enabled automatically. In a generated
maze inspect unbranded cargo detail/tints, complete sprays and an actual gate,
then run `lod_crate_status; lod_container_brand_status; lod_progression_render_status`.
Require repaired hull overrides with no unintended fallback, emitted brand draws,
stock gate bodies and no concrete on gates. Return the screenshots and canonical
console_latest.txt + rpg_summary_latest.txt; no full session log unless needed.
`lod_crate_hull_candidate 0` remains the local recovery switch.

C3 is the third and final implementation pass. Great Crate remains **not fully
accepted** until native hull/spray/gate appearance, brand offset/mips, multi-seed
residency/frame time, concrete/grate traversal/rails/cover and reset/rejoin checks
pass. No fourth implementation pass is silently authorized. Any required further
feature repairs are explicit carryover for the deferred week before dependent work;
known fatal/game-breaking regressions may never be deferred. The approved immediate
optimization/safety/native-playtest and deferred Big Loot→Events→comprehensive audit
sequence is preserved. No engine acceptance or performance measurement is invented.

## Recovery — September 24, 2026

The stalled C3 workspace retained its complete staged repair but had no published
C3 commit. Remote main still matched the C2 baseline. Recovery copied the staged
binary patch into a fresh checkout without changing production code; its SHA-256
was `680d3a712f1e87260d79b189d506380741233ca330e89900c598ff5abafbbdb0`.
The original workspace and its failed visual evidence remain intact.

Fresh focused gate, branding-render and hull-reconciliation harnesses passed.
Live GDD 00/01 and relevant 05/07 C3 rules were read back; the prior design edits
survived the stall and agree with this implementation. The provided face and title
PNG attachments both exist and decode correctly in the recovered workspace.
No floor asset, floor geometry, collision or gameplay authority changed.

Fresh canonical integration completed during recovery: **221 suites passed,
zero failures**, including the six Crate suites and the full Lua syntax gate.
Full log: `GREAT_CRATE_C3_INTEGRATION.log`; SHA-256:
`e5df3426ff68cf78004748ff6a117e7924decedd742152f66353704bf2c5bfb6`.
No production or test changes followed this run. This closes automated C3
validation, not the outstanding native acceptance described above.
