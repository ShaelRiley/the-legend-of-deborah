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
### Focused comparison after correcting the environment

A subsequent focus monitor found unfocused gameplay with the engine's20FPS
background limit. The older video-active captures above lack continuous focus
proof and cannot establish the focused comparative baseline. They remain raw
diagnostic evidence. The user authorized pausing YouTube; by this comparison no
browser process or MPRIS media session existed, so there was no playback to pause
or restore. Both builds used the same finite, task-local1Hz controller outside
the gamemode and the same saved, normally acquired three-item equipment.

Fresh Windows x64 launches used Proton Experimental through
SteamLinuxRuntime_4 `4.0.20260928.262390`. The Steam launch selectors unexpectedly
selected32bit; those launches were discarded. The tested executable was explicitly
`gmod_win64.exe`; source receipts reported x64 and the expected clean commit.
All runs below used the same arrival position `(-3840,-1536,-12271.38)`,
view `(0,90,0)`, seed/layout,60 ordinary roamers,1280×800/native walls, mcore0,
unchanged quality and fps_max300. Five-second focus samples stayed true through
all captures. These are30s stationary diagnostics, **not required scenarios**.

| Build / repeat | Average FPS | Median ms | p95 ms | p99 ms | 1% low FPS |
| --- | ---: | ---: | ---: | ---: | ---: |
| cec10dc5 /1 |21.68|42.939|62.378|72.769|12.07|
| cec10dc5 /2 |21.81|43.040|62.001|72.210|13.48|
| cec10dc5 /3 |21.70|42.967|62.964|70.078|12.18|
|48740b24 /1 |23.13|41.308|59.508|68.797|12.57|
|48740b24 /2 |22.67|41.507|60.282|69.782|12.45|
|48740b24 /3 |23.11|41.257|59.449|68.199|13.91|

Mean FPS improved5.70%; repeat ranges did not overlap. Every run remained below40
throughout and failed the performance thresholds. In separate matched profiles,
generated-floor drawing fell from5.296 to3.538ms/frame; the whole render-submission
interval fell from19.824 to18.447ms/frame. Inclusive timers overlap, profiles add
overhead, and neither interval measures GPU time. Retain the candidate for further
validation: its local cost and repeat FPS changes agree, but this is not final
acceptance. A normal200-unit movement-input playback crossed17 route nodes and
collected the red keycard through the normal hull pickup. Floor/corner screenshots
showed intact surfaces. No movement, collision, health, AI or resource override
was used. Standing idle afterward led to ordinary enemy damage and death.
Stairs, later geometry and client full-update visibility still require runtime
coverage before canonical integration.

A separate engine-setting diagnostic changed only `gmod_mcore_test` from0 to1:
cec10dc5 reached25.38FPS/p9551.821ms;48740b24 reached26.77FPS/p9546.147ms.
This is a distinct rendering-mode condition, not a source-only gain or acceptance.
The original mcore0 condition was restored. Native vprof commands were present
but produced no timing report; `jit.profile` was unavailable. Existing client /
server attribution remains the useful profiler. Continue investigating the
remaining CPU/rendering cost without lowering content or graphics.

Raw artifacts: `/home/deck/deborah-benchmarks/focused-no-video/`; its
`comparison.json` summarizes the repeats, each run retains the native capture
and focus logs. Frozen graph and first normal route:
`/home/deck/deborah-benchmarks/frozen-scenarios/`.


## Remaining acceptance

All six required scenarios in `docs/STEAM_DECK_BENCHMARK.md` remain unverified.
No ordinary traversal/combat/boss/interactions/co-op scenario has completed its
three warmed uncapped repeats, and40FPS capped verification has not started.
Freeze physical routes/checkpoints before accepting comparative scenario runs.
Next: isolate the remaining simulation/rendering cost, inspect stair/false-floor/
full-update visibility, finish physical gameplay checkpoints, and repeat the
focused optimization loop. Do not publish a completed40FPS claim.
