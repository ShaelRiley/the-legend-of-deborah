# Steam Deck exact repeated-view frustum reuse — October 8, 2026

Recovered from clean published main `8868d20629ddd89e4503b2fafc036e5766402d1e`.
The latest supplied capture is the exact published parent, not the new candidate:
30.3866 active FPS over 179.421 seconds, median 30.271 ms, p95 50.162 ms,
p99 84.058 ms and maximum 408.685 ms. Two five-second windows reach 40 FPS;
sustained >=40 FPS remains unmet. It reports 15 verified client sources; all
46 recorded population source hashes independently match the published parent.
Client/server profiles complete with final server status `received`, fixed
preferences, fully idle verified VR and no Lua errors. The scene starts with
1,270 native walls and 36 living wanderers. Different generated layouts and
workloads prevent isolated FPS attribution against earlier captures. Inclusive
profile timings overlap and do not measure GPU work.

The generated static-geometry callback runs 10,904 times for 5,452 rendered
frames and averages 1.8719 ms per invocation. Its existing geometry snapshot
now retains only the pure frustum result for an exact repeated camera input.
Native bounds, position and angles are still read on every pass, as are current
camera axes and projection. A geometry/pose change replaces the snapshot; the
immutable plane identity changes on any basis/projection coefficient change;
all three exact eye scalars are checked. No frame lease, rounding, distance
guess, population/graphics/timing/tuning change or omitted native submission.
The original evaluator and its arithmetic/tolerances remain unchanged.

The result is owned by the existing per-box snapshot. Removal, full update,
transmission recovery and renderer refresh retain their existing invalidation.
Nested cameras keep immutable plane identities and check the current eye.
Orthographic/off-center/unavailable setups retain the original conservative
fallback. Hidden state, kind, hazards, grates, wireframes, materials, mesh
ownership, draw state, collision and gameplay retain their existing authorities.

The production-backed paired probe compares exact parent and candidate native
mesh/wireframe/fallback values over 330 scenarios: translating cameras, all
axes and FOV/aspect, mutable/replaced native bounds/pose, live getter overrides,
hidden/revealed/kind/life states, false floors/grates, full update/transmission,
incomplete/nested views, renderer refresh/removal, 1e-10 eye changes at the
one-unit rear-plane boundary, tiny projection changes and changed native
basis getters with unchanged angle scalars. Both complete 18,736,156-byte
traces have SHA256 `63db5f417eb5cd107ef8e4e60e93324cbd63ec92a1e10a3df3e1a6c44df047d1`.

Across 120 translating-camera frames with two matching-view submissions each,
calls to the actual production evaluator fall 28,800→14,400. All 115,200 native
geometry getters, 2,160 camera-basis component reads, 28,800 mesh draws and
9,600 wireframes remain. The exact published parent fails the new work bound.
These are headless operation counts, not measured native time/FPS savings.

Fresh live GDD navigation 00 → 01 → 05/07 governs this implementation-only
checkpoint. LOD-IMPL-001/004 require existing authorities and presentation
caching; LOD-CRATE rules preserve the concrete, cargo geometry, brand and
collision appearance. No authored design or tunable value changes. Recovery
also confirms all four parent CI workflows completed successfully. The new
checkpoint has separate source/static evidence and awaits native acceptance.

Validation: frozen focused renderer/startup/geometry gate 29/29, passing coverage
of all 315 canonical suites and 885 Lua syntax files. The initial full run used
a shorter 120-second timeout; its campaign-test timeouts are retained as failures.
Those exact unchanged commands pass on the same frozen source with the canonical
600-second timeout. The archive records both attempts; this is combined passing
coverage, not a claim that the initial full run passed. The new probe is registered
in the canonical matrix; existing culling oracle, cache and lifecycle assertions
remain. Source before/after digests, individual matrix commands/receipts,
every raw stream and 29 focused logs are independently checked. Only evidence
and coordination packaging follows; production/test hashes are rechecked before
non-force publication. Raw captures, source manifests, full paired traces,
parent/changed source, commands, receipts and the expected failed control are in
[the evidence archive](STEAM_DECK_20261008_EXACT_VIEW.tar.xz).

Next native gate: fully quit GMod, pull/install verified main, restart
`gm_flatgrass`, then run the usual fixed-preference capture:

`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`

Leave GMod open through the final server reply. Return
`performance_client_latest.txt` and `console_latest.txt`; require exact source,
complete profiles, idle VR, no new Lua errors, unchanged world visuals/gameplay
and sustained >=40 FPS. No Workshop or VPS operation occurred.
