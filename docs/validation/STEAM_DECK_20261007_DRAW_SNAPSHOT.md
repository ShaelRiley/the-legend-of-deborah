# Static geometry draw snapshot checkpoint

Parent: verified clean main `8f6667098481dbcd034efe9013b05a95086f386b`.
The stalled thread's Magic/Q/M/toolgun correction is already published; all four
Actions workflows pass on that exact commit. Continue the author-authorized
Steam Deck optimization rather than repeating that completed work.

Live GDD navigation: 00 -> 01 -> 07, LOD-IMPL-001 through -004, revision
`ANLCKQn7d-0muOCBGrHxJZ-shoI_Yvc0LXT2Tt_EkfyBDDkUHTdJFncQC8CWpGDv3yesApEO0O5wBPR-vHKFlvLi0w2D5-CQrk7BKIzGhQ`.
No new design or tuning values. Preserve native walls and all geometry, collision,
population, combat, materials, warning outlines, meshes, UVs and current controls.

## Evidence and finite source gate

The latest exact-source `9f88e54` native capture measures 23.7135 active FPS
over 129.082559 active seconds; sustained >=40 FPS remains unmet. Idle VR has
zero recurring work/resources in all 42 snapshots. Static geometry is the largest
measured custom client callback at 138.412 inclusive milliseconds per second.
Nested profiler rows overlap; this is neither GPU timing nor a controlled
before/after comparison. The intervening cost/input correction does not change
the static geometry authority.

Before implementation, define this bounded change: reuse the generated box's
already-validated scalar snapshot in the existing owner mesh/transform cache,
avoiding a second set of native vector/angle component reads in the same pass.
The entity renderer must still read bounds and pose on every pass; immediate
mutations, cameras and culling are not deferred. General direct mesh APIs retain
their existing behavior when no matching snapshot is provided.

Extend the existing production renderer probe with native vector-boundary doubles
and run the exact parent/candidate modules through that same probe. In the fixed
120-box/120-pass scene, require identical draws, meshes, matrices, UV/material/tint
and resource ceilings, while reducing native vector component reads to one set
per box/pass. Retain visible-corner and conservative-plane oracles, nested views,
geometry/pose/kind/hidden mutations, malformed views, datatable/full-update and
Lua-refresh recovery, direct API behavior, cache eviction and cleanup. Exercise
all three production floor/stair/grate routes plus unmatched snapshot fallback.

Run focused renderer/geometry/palette/native-lifetime/capture/profile/population
and accepted Magic/Q/M/VR regressions, full Lua syntax and the complete frozen
integration matrix. Verify unchanged source during the frozen gate and the exact
published tree/parent. Source operation counts do not certify hardware FPS.
The next native gate is the existing three-minute gm_flatgrass capture with native
walls and Reduced Effects, retaining the same Proton/windowed/graphics settings.
No Workshop publication or VPS deployment is included.

## Implemented source and paired results

The existing scalar box snapshot is passed through Draw/DrawSlab/DrawGrate into
the canonical weak-owner cache. Raw owner/vector/angle identity is checked without
native equality metamethods. Bounds, UV displacement/yaw and transform values
share the already-validated scalars; the entity renderer still obtains all four
native geometry getters every pass. Cache compilation, LRU renewal, eviction,
materials, model matrices and draw submission remain the same authorities.

| Fixed 120 boxes / 120 passes | Exact parent | Candidate |
| --- | ---: | ---: |
| Native vector component reads | 273,600 | 129,600 |
| Native geometry getters | 57,600 | 57,600 |
| Repeated mesh-key formats / matrix allocations | 0 / 0 | 0 / 0 |
| Camera absolute-value operations | 1,800 | 1,800 |
| Cached native axis component reads | 1,080 | 1,080 |
| Initial peak native meshes | 61 | 61 |

The 120 sorted submission records are byte-identical (positions, orientations,
mesh vertices/normals/UVs, tint and blend), SHA256
`2ca01812775223408159fa32f182cea61241a0020fdb96d26fee0601be2929a1`.
Both sources pass all 173 visible-corner and 73 conservative-plane cases,
including three intersections without an inside corner. The exact parent fails
the new repeated-native-read requirement as an explicit negative control.
All floor/stair/underdeck/grate routes and unmatched-owner/argument fallback are
exercised; direct APIs, mutations, eviction, cleanup and refresh retain their gates.
The decrease is 52.63% of measured vector component accesses, not total rendering
time or measured FPS. Complete integration validation remains the publication gate.


## Completed frozen source gate

The final candidate passes **313/313 complete integration suites**, **29/29
focused checks** and **884 Lua syntax files**, including the existing Magic,
Q/M, VR, Hair Trigger, geometry, native-resource and campaign regressions.
All canonical commands, 313 individual receipts, 626 raw stream hashes and
2,537 frozen source hashes are independently verified by the receipt
finalizer. Before/after source digests match, with zero changes during the full
matrix. Frozen source digest: `14b9b86f7f1f7a6db9d630fd29be32dcb18e5e5ba7838338d30b933385966ae7`.

The [verification receipt](STEAM_DECK_20261007_DRAW_SNAPSHOT_checks.json) and
[complete raw archive](STEAM_DECK_20261007_DRAW_SNAPSHOT_complete.zip) retain
the commands/results, every raw stream/receipt, source manifest, both original
native uploads, parent/candidate submission records, negative control and exact
changed code. Archive: 728,535 bytes; SHA256 `dd65f7dc8b04b9362e0b2070eb202c8a6c86f54e354a3924c61aded9a0d2c4c3`.
Only these coordination/evidence outputs and the plan's result sentence are
finalized after the frozen gate; all production and test code retains the tested
hashes. This is headless source validation, not native Source/FPS acceptance.

## Next native gate

Fully quit GMod, update/install published main, restart on gm_flatgrass, and use
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Play all three minutes with the same Proton/windowed/graphics configuration;
keep the game open through the final server reply. Return performance_client_latest.txt
and console_latest.txt. Require the exact clean installed/mounted source,
complete server attribution, zero new Lua errors, intact floors/stairs/walls and
idle VR. Check the inherited Q/M map and cheaper magic during ordinary play and
confirm the toolgun startup warning is gone. Sustained >=40 FPS is still open;
no Workshop publication or VPS deployment is part of this checkpoint.
