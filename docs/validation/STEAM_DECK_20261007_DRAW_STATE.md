# Scoped generated-geometry render state

Parent main: `d582729d123b80225d50ae228b78776c7eb88518`. All four parent
Actions workflows pass. Live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
normalized 07 `LOD-IMPL-001` through `-005`, governs this bounded performance
checkpoint. No authored rule, graphics setting or tuning value changes.

## New native evidence

The complete exact-source 20261007-183415 capture averages 26.3639 active FPS
over 149.8261 seconds / 3,950 frames: median 32.715 ms, p95 65.523 ms,
p99 92.424 ms and maximum 220.741 ms. Client presentation verification reports
14 matching sources; the 44 population module fingerprints are independently
compared with the exact Git commit. Client/server Lua error counts are zero;
all 42 recorded VR snapshots remain idle. Both CPU profiles finish.

There are 1,486 native wall models and 36 living wanderers, versus 1,684 and
64 in the previous capture. During recording, third person changes from 0 to 1,
map size from 1 to 1.48 and opacity from 1 to 0.51. These changes and the
different generated workload preclude attributing the FPS difference to source
optimization. Options values are runtime-observed; camera/visual acceptance is
not inferred from their use. Sustained >=40 FPS remains unmet.

Generated static geometry is the largest measured custom client callback:
142.898 ms/second, mean 2.731 ms over 9,420 invocations. Server EntrySafety.BeforeAI
is 34.651 ms/second and EnemyRoster.TickCloseDefense 30.311 ms/second.
Inclusive wall-clock rows overlap, include diagnostic overhead and omit GPU
and unwrapped engine work. Do not sum them into an overall CPU cost.

## Bounded implementation and finite gate

Extend the existing TexturedBox drawing authority with a render-pass-local
state scope. Consecutive native mesh draws with identical material, tint and
alpha should reuse the applied state. Preserve every mesh, matrix, vertex/UV,
draw order, culling decision, material/color value and collision. Wireframe and
fallback drawing require neutral state and invalidate the borrowed material.
Ordinary direct API calls retain their existing set/draw/restore behavior.
Helper replacements must fall back to that ordinary path. A nested scope owns
its own state, restores its outer scope and cannot retain a retired native mesh.
Successful and throwing callbacks must unwind only their own model matrix and
render state. Empty and fully culled scopes leave incoming addon state untouched,
including callbacks that throw before their first draw. Refresh/cleanup and
malformed-view fallbacks remain protected.

Extend the existing production renderer validator, already registered in the
complete matrix. A paired warmed 120-floor / 120-pass scene must retain exact
default draw submissions while reducing native render-state calls from 72,000
to at most 600. Preserve inherited camera, geometry mutation, culling, mesh
eviction, native cleanup and owner-snapshot tests. Add meaningful material/tint/
alpha transitions, neutral wireframe boundaries, nested/error cleanup and
missing/replaced-helper cases. The exact parent must fail the new work gate.
Counts are engine-boundary operations, not native memory, GPU or FPS claims.

Freeze the candidate, run focused regressions plus the complete repository
matrix and Lua syntax, and retain canonical commands, raw logs/receipts,
source hashes, paired/negative-control evidence and original native uploads.
Publish verified main immediately after this finite source gate. No Workshop
or VPS operation is included.

## Completed frozen source gate

All 313/313 repository suites and 884 Lua syntax files pass, with no changes
among the 2,548 frozen source files. Thread interruption left the post-repair
matrix incomplete. Recovery independently verified its complete source manifest,
62 canonical passing commands/receipts and their raw stream hashes, preserved
that original directory, and executed all 251 remaining suites. The completed
coverage retains all 313 canonical commands/individual receipts and 626 verified
raw stream hashes; it is a recovered frozen gate, not an uninterrupted run.

The paired 14,400-floor-draw probe preserves submissions and reduces native state
writes from 72,000 to 600 (99.17%). Mixed floor/stair/grate/false-floor submissions
match the exact parent. Focused renderer/resource checks, nested and throwing
state cleanup, untouched empty/culled scopes and replaced-helper fallbacks pass;
the exact parent fails the new work bound. The earlier empty-scope defect and
both interrupted matrices remain preserved rather than counted as completed gates.

See the [independently verified checks](STEAM_DECK_20261007_DRAW_STATE_checks.json)
and [complete raw evidence](STEAM_DECK_20261007_DRAW_STATE_complete.zip), including
the exact recovery driver and manifest. Final changes after the source gate are
documentation and evidence packaging; the three tested Lua files retain their
verified hashes. The live governing GDD revision was read again and matches the
recovered rule snapshot. Native acceptance of this new renderer remains open.

## Next native gate

Fully quit GMod, update/install the published candidate and restart gm_flatgrass.
Check concrete floors/ceilings, stairs, grates and false-floor outlines under
ordinary and third-person views. For the usual three-minute comparison, retain
the established Proton/windowed/graphics settings and use:

`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`

Keep these preferences unchanged during capture, keep GMod open through the
final server reply, and return performance_client_latest.txt plus console_latest.txt.
Require clean exact source, complete profiles, idle VR, zero new Lua errors and
intact geometry/population/safety. Native visual and >=40 FPS acceptance remain
separate from the source gate.
