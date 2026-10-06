# Measured static geometry and profile transport checkpoint

Parent: clean main `a4ecb4bbf0dc2442d54f1454935a44b982535b0d`, tree
`50f1001e5f64a7e97b35e167471a10061b7c8797`. Live GDD 00 -> 01 -> 07,
LOD-IMPL-001–004, revision
`ANLCKQmUlHpIXlUgqqjCRjeDq_RX5wfx7ceBkFwsdpnj5ZxQkzwWH2SxmdIiMnmRGrSLjqw2kDKEAZWGg9e2Cg8ohbKLMunfHqqeJwdRdA`.
Preserve approved floor material/color/UVs, exact meshes and native wall bodies,
stairs/grates/false-floor states, collision, authored population and gameplay.
No GDD change or authored tuning change is required.

## Native evidence that selects this seam

The complete 180-second profiled capture on this exact source measures 21.3748
active FPS over 171.1828 active seconds, median 40.164 ms and p95 79.436 ms.
All 42 installed/mounted authorities match the clean parent independently.
The scene has 1,406 wall models and 40 initial roamers across two floors. It
differs from prior captures; no controlled source-regression comparison is claimed.
Wall appearances remain idle and no native originals are hidden.

`LOD.DrawGeneratedStaticGeometry` uses 22,143.471 inclusive CPU milliseconds over
7,810 calls (2.835 ms/call); the enclosing render phase uses 70,923.568 ms over
3,904 calls. Nested rows overlap. Static-box Think is called 3,572,160 times,
although its bounds refresh already occurs only once per game second. The server
reply explicitly failed with `profile exceeds transport limit`; missing timings
do not establish negligible server cost. GPU and unwrapped engine work are not
measured. Source improvements below cannot certify 40 FPS.

## Finite gate defined before implementation

Extend the existing static renderer and profiler validators. Require exact
visible-corner preservation across pose/FOV/aspect/nested and unknown views,
camera-enclosing and intersecting large slabs, tangent planes, immediate native
bounds/pose/kind/hidden-state changes and full-update recovery. A fixed elongated
floor/stair scene must omit more definitely off-camera submissions than the
parent while keeping every visible surface; shared meshes, transforms, UVs,
colors, grates and warning outlines must remain identical.

Count native geometry getters in repeated visible static scenes and require one
snapshot per drawable box per pass. Schedule existing bounds Think at its existing
one-second refresh deadline, retaining immediate retries while datatables are
incomplete and waking on transmission/full-update recovery.

Keep the existing admin lease, tokens, progress/final ordering and 60,000-byte
wire ceiling. Oversized but bounded profile JSON must round-trip all rows and
timings through native compression; decompression has an explicit memory ceiling.
Missing/failing/oversized codecs, malformed/truncated packets, stale replies and
default idle behavior retain their existing safe outcomes. Native codec/renderer
acceptance remains the next exact-source three-minute capture, not a static claim.

Retain the affected capture, population, renderer, geometry, palette, native
resource, entry-safety, Hair Trigger and combat regressions, complete Lua syntax
and the full frozen integration matrix. Preserve failed attempts and exact bytes.

## Implemented candidate and paired work evidence

The renderer uses the greatest support of the actual oriented box against each
camera plane, with the previous one-world-unit conservative tolerance. Cached
pose/bounds scalars invalidate immediately on native mutation; draw calls and
warning outlines borrow the same per-pass values. Exact meshes and their shared
cache remain untouched. The existing weak registry belongs to TexturedBox across
Lua refresh so scheduling cannot delay floor registration.

Paired execution of parent/candidate production code in the same boundary
harness gives these work counts, not native FPS or GPU timings:

| Fixed scene | Parent | Candidate |
| --- | ---: | ---: |
| Native geometry getters, 120 boxes × 120 passes | 129,600 | 57,600 |
| Native-scheduled Think, 120 boxes × 600 frames | 72,000 | 1,200 |
| Draw submissions, 301 mixed visible/elongated boxes | 301 | 101 |

The candidate retains all 101 visible surfaces in the elongated scene and all
100 visible surfaces in the original 600-box scene. It passes 173 independent
visible-corner and 73 independent conservative-plane cases, including three
large intersections without a corner inside the entire frustum. Camera changes,
unknown/ortho/offcenter views, exact tangency, depth/sky passes, floor hidden-state,
full-update and Lua-refresh recovery, shared UVs/meshes/materials and lifetime
checks remain. The parent's new getter and compressed-report regressions fail;
the candidate passes both. The first inherited harness attempt expected one
wholly off-camera rotated box to remain because its enclosing sphere intersected
the view. The exact eight-corner plane oracle confirms this was an obsolete
false-positive expectation, not visible geometry; that initial harness failure is
recorded here.

The first complete-matrix attempt then caught a real fallback regression in the
unchanged conservative-geometry validator: incomplete angle accessors submitted
600 boxes instead of rejecting the 300 rear boxes. That attempt was interrupted
after the failure and is not a completed gate. The repaired production path keeps
the previous rotation-independent origin sphere for the rear-plane fallback when
oriented axes are unavailable. The unchanged validator now passes its rear-only,
large/asymmetric/intersecting bounds, arbitrary rotation and unknown-view cases.
The complete-matrix attempt and logs are retained separately from the final gate.

Dense profiles use the existing binary net payload with an unambiguous NUL prefix
for compressed JSON only when needed. Every row and numeric timing is retained.
Native compression/decompression have guarded error handling, a 60,000-byte wire
ceiling and a 262,144-byte uncompressed memory ceiling. Tokens, permissions,
partial/final merging, finite lease duration and restoration remain unchanged.
Compression/decompression run only in an explicit profiling capture. Tests double
the native codec boundary; the target GMod codec and rasterized visibility still
require the next native capture. API contracts were checked against the primary
[SetNextClientThink](https://wiki.facepunch.com/gmod/Entity:SetNextClientThink),
[Compress](https://wiki.facepunch.com/gmod/util.Compress) and
[Decompress](https://wiki.facepunch.com/gmod/util.Decompress) documentation.

Native evidence is retained in
[the source-verified receipt](STEAM_DECK_20261006_STATIC_native.json).

## Completed source gate and next native action

The corrected frozen candidate passes **309/309 complete integration suites**
and **879/879 Lua syntax files**, with no source changes during the gate. The
independent check verifies all 309 canonical commands and suite receipts, all
618 raw stdout/stderr hashes, all 2,508 frozen source hashes and all 562 production
Lua hashes. Frozen source digest:
`d499f347ba70cac572a76fa29811af20a4dfc0993ba0e097e8f97a4400bb9516`.

The [complete evidence archive](STEAM_DECK_20261006_STATIC_complete.zip) contains
every final suite log/receipt, exact tested changed-source bytes, parent/candidate
work and negative controls, and the interrupted failed attempt. The interrupted
attempt completed only 56 suite rows, changed after failure before interruption,
and has no final receipt; it cannot establish a passing gate. Its eight changed
source files independently match its original manifest. The outer final runner
log is a partial capture; the complete 309 suite receipts and 618 matching raw
streams establish the completed result. The [verification receipt](STEAM_DECK_20261006_STATIC_matrix.json)
records the archive checksum and exact source/work facts. Only evidence and
coordination documents are finalized after the frozen gate; production and test
sources remain identical to the validated candidate.

After publishing, fully quit GMod, update/install main, then repeat on gm_flatgrass:
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Keep the established Proton/windowed/graphics configuration and play the entire
three-minute capture. Leave the game open through the final server reply. Return
performance_client_latest.txt + console_latest.txt and report any missing floor,
stair or wall surfaces. Require exact source verification, no new Lua errors and
nonempty server timings with `server_status=received`. Measure sustained >=40 FPS;
this checkpoint is statically validated, not natively accepted. Workshop/VPS
operations remain outside this pass.
