# Steam Deck checkpoint — same-scene profile diagnostic

## Verified native result

The October 9 18:40:50 capture tests clean published main
`3d3c05ce8c4aedf498ecfbb698548a087bbfe16a`, including the aura orbit cache.
All **49** recorded installed/mounted population-module hashes independently
match that published commit. The client verifier reports **17/17**, zero missing
or mismatched sources. Both profiles are complete: **273 client rows** and
**376 server rows**, with no incomplete calls and final server status `received`.
Preferences are fixed, VR is fully idle, and all client/server endpoint Lua-error
counts are zero. The raw uploads remain in the adjacent evidence archive.

Active FPS is **19.5371** over 179.9655 seconds: median **42.486 ms**, p95
**86.115 ms**, p99 **121.525 ms**, maximum **228.571 ms**. All **36** five-second
windows fall below 40 FPS; their maximum is 28.5794. The >=40 FPS gate fails.
Appearance/gameplay acceptance also needs the tester's observation.

This generated scene has **1,792 native wall models** and **60 initial living
wanderers** across three floors with no initial deficit. The preceding capture
had 1,434 walls and 36 wanderers across two floors. The differing scenes and play
paths prevent assigning the FPS change to the aura cache or preceding changes.
This is runtime observation of the published aura build, not isolated regression
evidence or native acceptance of a performance improvement.

## Why the next gate is diagnostic

| Inclusive profiled row | Calls | Mean ms | ms per second |
| --- | ---: | ---: | ---: |
| Client generated static geometry | 7,032 | 2.391885 | 93.4484 |
| Client hostile Draw | 39,414 | 0.100375 | 21.9801 |
| Server EntrySafety.BeforeAI | 569,730 | 0.016161 | 51.1572 |
| Server EnemyRoster.TickCloseDefense | 286,109 | 0.027611 | 43.8914 |

Rows overlap, include instrumentation overhead and do not measure GPU time.
For example, the profiler also times 747,917 hostile-deadlock and 587,394
Climber-latch collision-hook invocations. Source inspection found the shared
safety check at both the native coroutine and MotionV2 dispatch; those calls
have intervening status/attack/controller callbacks and cannot simply be skipped.
No unprofiled capture of this build was supplied. The cost of profiling itself
is therefore unresolved. A paired stationary diagnostic is a more useful next
gate than claiming that another small arithmetic cache will close this FPS gap.

## Bounded implementation and verification

Live design navigation followed **00 -> 01 -> 05/07**, including B29 spatial
safety, accepted presentation/population constraints and LOD-IMPL-001 through
-006. Extend only the existing `sh_runtime_audit.lua` observer with
`lod_perf_compare [seconds]` (default 60 seconds per phase). It runs unprofiled
then profiled in the same live scene, using the existing preparation, warmup,
sampler, source/settings/population/resource evidence and profile transport.

The final `performance_client_latest.txt` contains the original profiled report
plus the full unprofiled report under `comparison.baseline`. Copy that baseline
through the existing JSON codec before phase two so live renderer counters
cannot rewrite it. Camera scalars are copied at the first/last sample and each
five-second window. This is a fixed-order stationary diagnostic: actors and
clocks continue, and sampled camera equality does not prove a frozen workload.
Compare both source identities, configurations, camera samples, population,
errors and VR state before drawing a timing conclusion. No automatic gameplay
acceptance or >=40 FPS certification is added.

Regular captures retain their established behavior. The comparison adds no idle
hooks, baseline profiler bindings, per-frame hashing or per-frame I/O. Retired
frame/deadline callbacks cannot stop a newer phase. Any interruption, failed
save or invalid baseline codec ends the pair; the matching final server reply
preserves the frozen baseline in the same file. Gameplay, graphics preferences,
models, population, movement, attack rules and tuning are unchanged. Installer
and source coverage remain **53 installed / 49 population / 17 client capture**.

**7/7 selected checks pass** on the final unchanged **2,582-file** snapshot,
SHA256 `a788d305842e290c1d5e57f19b7cd446b84b0c59475569899152aba8951cd893`:
capture; expanded client/server profile and pair; population transport;
installer manifest; native resource lifetime; saved options; and syntax of the
three changed Lua files. All 14 raw streams and command receipts are independently
hash-verified. The pair fixture retains 769 baseline and 468 profiled synthetic
frames and exercises full final transport, view mutations, baseline alias
retirement, stale callbacks/replies, 12 interruption cases, three active-profile
native lifecycle events, restart, codec/save failures and duration/idle bounds.
Those synthetic timings are not hardware measurements.

The exact published parent completes the legacy profile assertions and is
rejected at the new diagnostic-presence gate. Earlier green development runs
and the earlier seven-check snapshot are retained, but only the final frozen
gate is claimed here. The completed hostile-scale/aura work gates and full
317-check/887-file evidence are not rerun. Production/tool hashes are rechecked
after documentation/evidence packaging before non-force publication.

Evidence: adjacent `_native.json`, `_checks.json` and `.tar.xz`. Archive SHA256:
`d52cf47d0af4c10cc91510a38b671b085aff052087dbf1680d0ec08109b409c2`. Reproduce with
`python3 tools/run_lua54.py tools/test_performance_profile.lua` and the exact
commands/raw receipts in `pair_frozen_checks`. The archive also preserves the
published parent, patch and expected negative control.

## Next native action

Fully quit GMod, pull/install verified main, restart `gm_flatgrass` and remain
in the arrival sanctuary. Face into the maze, then run:

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_compare 60
```

Close the console and stay still with the same view and menus closed through
both 60-second phases. Do not reset the world or change preferences between
them. Keep GMod open through the second completion and final server reply
(`server_status=received`). Return `performance_client_latest.txt` and
`console_latest.txt`; no manual intermediate file copy is needed.

This diagnostic tests profile overhead and the recorded same-scene controls,
not sustained combat/traversal FPS. Native execution of this new command is
unverified. The final acceptance gate still requires exact source, complete
profiles, idle VR, no new Lua errors, unchanged appearance/gameplay and sustained
>=40 FPS in representative active play. No Workshop or VPS operation.
