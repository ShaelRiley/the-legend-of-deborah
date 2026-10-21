# Steam Deck optimization iterations — 2026-10-21

Target: **unmet / full acceptance unverified**. This record does not certify40FPS.

## Recovered hardware baseline

Full host access is now available. Complete clean checkout and installed source:
`cec10dc5426e2ee3e2137f68de0ef4a321772413`. Steam Deck LCD/Jupiter,
SteamOS3.8.28, kernel6.18.50-valve2-1-neptune-618-gc7289a96b14d,
Windows x64 GMod2026.09.17 (10175), Steam build25375506, Proton Experimental
`experimental-11.0-20261014-x86_64`. Actual viewport1280×800, native walls,
Reduced Effects1, first person, fps_max300, vsync0,15W, automatic GPU clocks.
Internal display60Hz plus external1920×1080/60Hz; browser video remained active.
One player; Deck listen host. Campaign654759237 quantizes to654759232;
layout236920976, population1463751064,60 ordinary roamers, no AI/count changes.
Wizard, normal offered CON_RUSSIAN_ASSET feat, assigned AR2 starter. Setup used
canonical class/feat/prop-Use/deployment functions; no resource testkit/godmode.

| Build / diagnostic | Active seconds | Average FPS | Median ms | p95 ms | p99 ms | 1% low FPS | Below40 seconds |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cec10dc5, entry wall, unprofiled |179.96|23.40|39.769|61.595|78.322|9.83|179.96|
| cec10dc5, stationary overhead baseline |29.93|24.05|39.511|57.507|69.292|12.02|29.93|
| cec10dc5, matched profiled leg |29.95|22.10|41.771|62.529|81.074|10.23|29.95|

The180s run was diagnostic, **not traversal acceptance**: server-only view setup
reverted on subsequent client input and the player mostly faced the entry wall.
Client camera setup plus bounded canonical input commands were subsequently
verified with actual position changes, ordinary damage and ammunition use.
The sampler also recorded a terminal gap above its acceptance budget. All failed
captures are retained. Profiler overhead in the stationary pair was8.1% FPS.

Raw files: `/home/deck/deborah-benchmarks/cec10dc5-baseline/`, including
`d1-entry-corridor-180s/performance_client_latest.txt`,
`entry-same-scene-profile-comparison.txt`, `diagnostic-deep-profile-30s.txt`,
`diagnostic-batches-rejected.txt`, host telemetry and `native-cpu.data`.
Native CPU samples were mapped to loaded PE module headers: Lua shared29.3%,
client14.2%, engine8.6%, server7.0%; these are samples, not additive frame timers.
GPU telemetry did not establish saturation; non-VR receipts remained idle.

The existing experimental batch renderer was rejected after missing surfaces,
changed appearance and startup stalls. `lod_wall_batches0` was restored.

## Candidate1: native selection of generated floors

Hypothesis: avoid repeated native geometry reads for boxes already rejected by
Source's current opaque view. The deeper diagnostic measured about5.5ms/frame
in the generated geometry scope but only about1.1ms in its slab/box helpers.
The native visibility probe selected166 renderable boxes versus591 checked by
Lua in that view. Inclusive instrumented timings overlap and carry overhead.

Implementation retains the original draw/material/frustum authorities and adds
native-view candidates. Only initialized or observed current callbacks with
verified declared render bounds may borrow a rejection. Bound notifications,
reentrant native writes, custom accessors/callbacks, refreshed instances and
unknown/different views use the existing path. No content, collision, population,
AI, resolution or quality preference changes. The opt-in profiler records its
wrapped callback identity so attribution preserves the same visibility path.

Static checks: focused geometry/native-selection and profiler tests pass;
full923-file Lua syntax pass. The broader renderer gate initially lacked Node
and Pillow; task-local dependencies have been installed, and the asset check passes with
the task virtual environment.28/29 checks pass after those dependency checks.
The full-update fixture
fails identically on the parent at the obsolete keycard hook stub; the new floor
checks cover pending/reentrant bounds, full update, hidden state and removal.
Hardware comparison: **pending**. Retain/revert decision: **pending measurement**.

## Remaining acceptance

All six required scenarios in `docs/STEAM_DECK_BENCHMARK.md` remain unverified.
No ordinary traversal/combat/boss/interactions/co-op scenario has completed its
three warmed uncapped repeats, and40FPS capped verification has not started.
Freeze physical routes/checkpoints before accepting comparative scenario runs.
Next: fresh equivalent baseline/candidate launches, measure the focused change,
inspect floor/stair/false-floor/full-update visibility, retain or revert, and
continue profiling the remaining bottleneck. Do not publish a completed40FPS claim.
