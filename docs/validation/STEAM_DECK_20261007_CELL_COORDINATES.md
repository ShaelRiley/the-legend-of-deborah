# Exact cell-centre coordinate reuse

Parent: clean main `00dd5ea74c4df55bc013fe4a5d94cc273a151c8d`; all five
Actions workflows, including the complete frozen matrix, passed on that source.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, navigation
00 -> 01 -> 07, LOD-IMPL-001 through -004, revision
`ANLCKQn7d-0muOCBGrHxJZ-shoI_Yvc0LXT2Tt_EkfyBDDkUHTdJFncQC8CWpGDv3yesApEO0O5wBPR-vHKFlvLi0w2D5-CQrk7BKIzGhQ`.
This implementation-preserving optimization adds no tuning or game rules.

## Native evidence governing this checkpoint

The complete three-minute October 7 13:35 local capture verifies clean
`00dd5ea` in both realms. Client renderer fingerprints pass 10/10;
population fingerprints pass 44/44, independently compared with Git objects.
No Lua errors occur; the prior missing toolgun shared.lua warning is absent.
Native wall rendering is enabled with 1,552 wall models; experimental batches
and hidden originals remain zero. The r2 VR overlay is idle with no players,
runtime hooks, recurring timers, method overrides, pending work or native
resources. Mounted VR sources verify 139 addon files and both bridges.

Active rendering averages **18.3706 FPS** over 171.36077 active seconds
(3,148 frames), median 45.822 ms, p95 96.975 ms and p99 133.512 ms.
The population snapshot has 54 living bodies/wanderers and 38 planned encounter bodies;
the earlier 23.7135-FPS capture had 40 living bodies and 36 planned wanderers,
with 1,366 walls. These different generated workloads do not establish a
controlled before/after performance regression. Sustained >=40 FPS remains unmet.

Largest measured custom client callback: generated static geometry,
108.502 inclusive ms/second. Server EntrySafety.BeforeAI costs 50.512
inclusive ms/second across 519,060 calls; EnemyRoster.TickCloseDefense costs
43.202 across 260,436 calls. Nested profiler timings overlap; opt-in timing
overhead, GPU work and unwrapped engine work prevent treating this as a complete
frame-cost accounting. The prior 52.63% renderer vector-read reduction was a
source operation result, never a guaranteed hardware FPS gain.

## Finite change and source gate

ExactCell repeatedly obtains a native cell-centre Vector, constructing an offset
Vector and the native addition result for unchanged cells. Extend the existing
MazeBuilder centre authority with a read-only coordinate accessor, delegated
through MazeNavigator. Cache the original native result's scalar coordinates
under weak cell keys. Validate cell x/y/z, maze width/height/cell size/level height
and origin x/y/z on every query. Any changed value rebuilds immediately. Unknown
builder/navigation overrides use their live resolver every time. Ordinary
CellCenter still returns an independent mutable Vector. Preserve native float
rounding by obtaining cached coordinates from that exact original calculation.

Only EntrySafety.ExactCell adopts this accessor. Actor positions, membership,
graph ownership, arrival service, attack/target selection, quotas, AI cadence,
population, rendering and graphics remain under their existing authorities.

Extend tools/test_entry_safety_hotpath.lua, already in the complete matrix.
Require exact parent/candidate agreement over 5,145 sanctuary boundary/padding
checks, 343 additional float32 exact-cell boundary cases and existing immediate
ownership/config mutations. Require zero repeated centre Vector constructions
over 10,000 warmed queries, versus the unmodified parent's work. Retain four-hop
source ownership, life/context/service and live distance checks. Exercise all
cached scalar mutations, replacement origin, custom resolver hidden-input changes,
ordinary mutable-vector isolation, float32 versus double differences, weak cell
collection, missing-helper fallback and production Lua refresh. The exact parent
must fail the new zero-construction requirement as a negative control.

Run the complete frozen integration matrix, full Lua syntax and paired evidence.
Preserve canonical commands, raw receipts/streams, immutable source hashes,
original native uploads and changed source. Verify the exact published parent/tree.
Operation counts and doubled Lua allocation measurements are source evidence;
native runtime/FPS acceptance requires the usual three-minute gm_flatgrass capture.
No Workshop or VPS operation is part of this checkpoint.


## Completed finite source gate

The exact parent and candidate agree over all 5,145 existing boundary/padding
checks and 343 additional float32 cell boundaries. Fifty fractional-coordinate
cases demonstrate why replacing the native calculation with Lua double
arithmetic would change results. The warmed 10,000-query probe constructs
**0 centre Vectors versus the parent's 20,000**; doubled Lua allocation is
0.026 KiB versus 2,968.839 KiB. This is a headless operation/allocation probe,
not a native memory or FPS measurement. The exact parent fails the new zero-
construction condition. Resolver overrides, live mutations, weak cell lifetime,
independent mutable vectors, missing-helper fallback and builder refresh pass.

The complete frozen matrix passes **313/313 suites and 884 Lua syntax files**,
including full B29 generation/dispatch/combat, exact navigation routes, population
and lifecycle, hostile attacks, rendering and the inherited VR/Magic/Q/M gates.
The existing matrix covers all changed authorities; no duplicate suite is added.
All canonical commands, individual receipts, raw stream hashes and immutable
source fingerprints are independently checked before publication.


Frozen source digest: `37fe0a3c28636aa8589a261b64d251e09168817357009750ae7461cd5401b596`, 2,540 files,
with zero changes during the full gate. The [verification receipt](STEAM_DECK_20261007_CELL_COORDINATES_checks.json)
and [complete raw archive](STEAM_DECK_20261007_CELL_COORDINATES_complete.zip)
retain every command, raw stream, source manifest, paired/negative-control evidence,
original native upload and exact changed code. Archive: 721,605
bytes; SHA256 `5ab011c5fa2825ce8ec41c8533fd1ed1432154a121d4d08601c43996ad77df0c`. Only coordination/evidence outputs are finalized
after the gate; production and test code retains its tested hashes.

## Next native gate

Fully quit GMod, update/install published main and restart on gm_flatgrass.
Run `lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Play three minutes under the same Proton/windowed/graphics configuration and
keep the game open through the final server reply. Return performance_client_latest.txt
and console_latest.txt. Require exact clean installed/mounted sources, complete
client/server attribution, intact safety/population/geometry, idle VR and zero
new Lua errors. Sustained >=40 FPS and this change's actual timing benefit
remain open native gates. No Workshop or VPS deployment is authorized here.
