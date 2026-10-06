# Static geometry camera-plane checkpoint

Parent: clean main `8b895179fbc8661ed87553015dcd4b00638eeb64`.
Live GDD 00 -> 01 -> 07, LOD-IMPL-001–004, revision
`ANLCKQmUlHpIXlUgqqjCRjeDq_RX5wfx7ceBkFwsdpnj5ZxQkzwWH2SxmdIiMnmRGrSLjqw2kDKEAZWGg9e2Cg8ohbKLMunfHqqeJwdRdA`.
Preserve current native walls, floor/stair/grate meshes, material/color/UVs,
warning outlines, collision, population, gameplay and graphics configuration.
No authored rule or tuning changes.

## Native evidence

The exact-source three-minute capture averages 18.4158 active FPS over 166.2163
active seconds, median 46.331 ms, p95 87.786 ms. It contains 1,696 wall models
and 54 initial roamers over three floors; the previous capture contained 1,406
walls and 40 roamers over two floors. These differ in workload and do not
establish a controlled source regression. All eight renderer and 42 population
source authorities match the installed clean parent. Native walls remain enabled,
with zero hidden originals and no further appearance writes during sampling.

Server attribution now arrives completely (`server_status=received`). Client
static geometry accounts for 30,950.173 inclusive CPU milliseconds across 6,456
calls; PreRender-to-PostRender accounts for 73,885.924 milliseconds across 3,227
calls. Nested rows overlap; GPU and unwrapped engine work are unmeasured. Server
EntrySafety.BeforeAI and EnemyRoster.TickCloseDefense account for 9,689.914 and
8,154.815 milliseconds respectively; these remain measured future candidates.
Both realms report zero Lua errors. The capture is retained in
[the native receipt](STEAM_DECK_20261006_PLANES_native.json).

## Finite gate defined before implementation

Extend the existing production renderer validator and run parent/candidate code
against the same native-boundary doubles. Require identical submitted surfaces,
transforms, mesh/UV/material/tint/warning output and native resource lifetime.
Retain all independent visible-corner and conservative-plane tests, camera/FOV/
aspect/roll/nested-view changes, large intersecting slabs, tangency, unknown/
ortho/offcenter views, rear-plane fallback, immediate scalar bounds/pose/kind/
hidden mutations, datatable recovery, transmission, full update and Lua refresh.

The candidate must resolve camera planes once per pass and avoid repeated native
axis-vector reads for unchanged boxes. The fixed 120-box/120-pass scene must
retain all surfaces and substantially reduce repeated absolute-value operations
against the parent. Rotated boxes must retain oriented support rather than fall
back to broad axis-aligned bounds. No cross-pass camera/visibility cache or
distance/occlusion/floor/draw cap is allowed.

Run affected renderer/geometry/palette/native-lifetime/capture/profile/population
and Hair Trigger regressions, all Lua syntax and the complete frozen integration
matrix before verified non-force main publication. The next native gate remains
the exact-source three-minute capture on gm_flatgrass with
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`, checking
floor/stair/wall visibility, complete server attribution and the >=40 FPS target.
Source operation counts are not native FPS acceptance. No Workshop/VPS operation.

## Implemented candidate and paired work

The current view owns one scalar camera/plane snapshot. Native angle axes are
copied into the existing per-box geometry snapshot only when its bounds or pose
change. Exact identity axes use precomputed absolute plane coefficients;
arbitrary rotations retain the original oriented support formula, plane order,
arithmetic grouping and one-world-unit tolerance. A per-file snapshot owner
rebuilds retained entity snapshots after Lua refresh. The renderer still reads
native geometry once per drawable box per pass and observes all mutations
immediately. No visibility result is retained across views or frames.

The same parent/candidate production harness measures:

| 120 unchanged visible boxes, 120 passes | Parent | Candidate |
| --- | ---: | ---: |
| Doubled native axis-component reads | 1,166,400 | 1,080 |
| Absolute-value operations | 216,000 | 1,800 |
| Native bounds/pose getters | 57,600 | 57,600 |
| Submitted surfaces in 600-box view scene | 100 | 100 |
| Submitted surfaces in 301-box elongated scene | 101 | 101 |

All 173 independent visible-corner and 73 conservative plane cases pass,
including three large intersecting boxes with no corner inside the entire
frustum. The inherited mesh/UV/color/lifetime, malformed-view rear fallback,
immediate mutation, transmission and full-update tests pass. The new retained
entity/Lua-refresh case also passes. The unchanged parent fails the new repeated
axis/plane work requirement as an explicit negative control. Native vector
accessors are doubled; these counts assign no hardware time or FPS improvement.

## Completed frozen source gate

The candidate passes **309/309 complete integration suites** and **879/879 Lua
syntax files**, with no source changes during testing. Independent verification
matches all canonical commands, 309 individual receipts, 618 raw stdout/stderr
hashes, all 2,512 frozen source hashes and all 562 production Lua files. Frozen
source digest:
`a3d7ee5ce99197717fb8a5dfe4b2a81ecdb800e88d69bf6aa86601995d0fee4b`.

[The complete archive](STEAM_DECK_20261006_PLANES_complete.zip) retains every
suite stream/receipt, both original native uploads, parent/candidate work and
negative controls, and exact changed source bytes tested. Its SHA256 is
`41205caa76f4cd0e493cc10028b8c681de15281471caaf378568c667dfe41051`.
[The verification receipt](STEAM_DECK_20261006_PLANES_matrix.json) records the
exact source and production hashes. Only coordination/evidence documents are
finalized after this gate; production and validator bytes remain identical.

Next: fully quit GMod, update/install verified main, and repeat on gm_flatgrass:
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Keep the current Proton/windowed/graphics configuration, play all three minutes,
and keep the game open through the final server reply. Return
performance_client_latest.txt + console_latest.txt and any missing floor/stair/
wall surfaces. Require exact source, zero new Lua errors and complete server
attribution. Native FPS improvement and sustained >=40 FPS remain unaccepted.
