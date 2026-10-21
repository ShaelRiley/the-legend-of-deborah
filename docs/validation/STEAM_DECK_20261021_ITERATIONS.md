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


## Candidate2: remove invisible collision boxes from the client draw queue

Hypothesis: known invisible collision walls/rails still incur Source render-queue
work even though their Draw callback submits nothing. A bounded runtime prototype
hid only618 nonvisual client entities, retaining transmission, solidity, normal
AI and the identical floor/wall models. In alternating30s stationary runs after
a normal red pickup/respawn and full-update check, original/prototype FPS was
21.773→22.565 and21.700→22.621; p95 was64.118→61.813ms and65.772→62.681ms.
All samples were focused, mcore0, same view/settings; all still failed40FPS.
Raw captures: `/home/deck/deborah-benchmarks/invisible-collision-diagnostic/`.

The source prototype applies NoDraw **only on the client** to declared kinds3/4/7
at initialization or the existing one-second bounds refresh. It releases its own
flag immediately before a newly visible kind commits, including reentrant native
notifications, and invalidates the old native Draw ownership until the new view
actually observes it. Unknown/custom kind accessors use the original path;
preexisting external NoDraw flags retain their ownership. Native NoDraw also
forces the manual-floor fallback rather than pretending missing ENT:Draw proves
a frustum rejection. No server collision/transmission/AI/resource change.
Focused tests pass for those transitions, same-pass visibility, full update,
custom kinds, external flags and weak native-closure cleanup. The renderer gate
passes28/29 plus all923 Lua syntax checks; its sole failure is the same inherited
keycard hook stub recorded above. Client/server profiler regressions pass. Fresh installed
source comparison and final retain decision remain pending; the runtime flag
experiment is not a validated source-build result.

The fresh installed b8d2af54 build retained1209 collision entities and1736 native
wall models. Its618 invisible boxes had client NoDraw, while591 boxes remained
renderable. Normal movement into a closed wall stopped after111.97 units.
`cl_fullupdate` recovered all1209 boxes with ready bounds and the same618 NoDraw
flags. The17-node red-card route completed in34.72s with ordinary enemy damage
(100→85HP) and normal pickup. These are finite collision/lifecycle observations;
they do not cover all later geometry or certify performance.

## Runtime comparison and next CPU investigation

All following runs use b8d2af54, the same frozen Dungeon1 arrival camera,
1280×800,60 ordinary roamers, one-player Deck listen hosting, uncapped gameplay,
native walls, unchanged quality and no background browser/MPRIS playback.
MangoHUD/DXVK telemetry was enabled in this diagnostic series. These conditions
differ from the earlier source-only comparison; do not attribute their full gain
to candidate2. The original Proton prefix and Windows installation are preserved.

| Runtime / settings | Average FPS | Median ms | p95 ms | p99 ms |
| --- | ---: | ---: | ---: | ---: |
| Experimental11, mcore0/queue−2/bone0 |23.85|40.304|57.144|64.922|
| Proton10.0-4b, mcore0/queue−2/bone0 |28.54|34.030|41.046|52.218|
| Proton10.0-4b, mcore1/queue2/bone1 |33.31|29.094|36.180|43.555|
| Fresh Proton10 threaded / repeat1 |33.28|29.142|36.495|43.584|
| Fresh Proton10 threaded / repeat2 |33.40|28.983|36.399|43.009|
| Fresh Proton10 threaded / repeat3 |33.61|28.682|36.002|46.444|

Proton10 uses SteamLinuxRuntime_sniper and FSYNC with an isolated cloned prefix;
Experimental uses SteamLinuxRuntime_4 and NTSYNC. All repeats remain below40 for
recurring episodes longer than2s and fail acceptance. They are stationary30s
diagnostics, not the three repeats of each required gameplay scenario. The
threaded corridor screenshot retains floor/container colors, branding, HUD and
fonts; full visual/input/campaign regressions for that mode remain unverified.

Independent telemetry reports approximately20–26% GPU use, not GPU saturation.
A30s native CPU sample attributes30.6% of user CPU samples to main-thread
lua_shared.dll,14.2% to client.dll,8.7% to engine.dll and7.9% to server.dll.
These are CPU sample proportions, not additive frame timers. The existing
instrumented profile places close-defense eligibility and arrival safety among
the largest server scopes; a bounded1-in64 nested sample further identifies
frequent progression/life/status queries. Preserve status expiry, ownership and
fresh reads after callbacks when investigating them. `jit.status()` reports on,
but the runtime disables the JIT event API and does not expose usable trace
reflection; no JIT-cache conclusion or tuning change follows from those probes.
The two unsupported diagnostic probes produced errors; they are excluded from
performance captures and cleared by a full restart.

A runtime experiment disabling native client Think on1736 static wall models
measured33.47→33.28FPS, within repeat noise. Rejected; no production change was
made, and a full restart restored native defaults. A brief Xalia pause was also
diagnostic only; the process was resumed before the old game session ended.

Raw captures, console excerpts, runtime receipts and native samples:
`/home/deck/deborah-benchmarks/mangohud-diagnostic/b8d2af54/`,
`/home/deck/deborah-benchmarks/wall-model-think-diagnostic/`, and
`/home/deck/deborah-benchmarks/ai-lookup-diagnostic/b8d2af54/`.
Nested query sample:
`/home/deck/deborah-recovery/evidence/sampled-ai-cost-b8.json`.
No browser video was paused, and no paused media/process requires restoration.

## Native Linux runtime investigation

The standard native32 depot4003/5169228716831564971 was downloaded using the
authorized Steam client and assembled in a separate full game copy. Soldier
alone lacked libgconf; the bundled legacy scout runtime resolved that dependency,
but native32 then hung before the world/console initialized. Those processes were
terminated. There is no native32 FPS result. The full copy preserves the previous
Windows public binaries and assets at
`/home/deck/deborah-recovery/GarrysMod-native/`.

Steam's normal public-branch selector then installed x86-64 build25936581,
GMod2026.10.14, common depot4001/2716471719602828132 and Linux
depot4003/7620157547366035543. The actual process was ELF64/x86_64 under
scout-on-soldier (soldier2.0.20260928.262391 and scout1.0.20260714.251828).
The unchanged source was reinstalled with clean documentation commit962be884;
its runtime bytes match b8d2af54. Native captures have no MangoHUD overlay.

This runtime retains integer convar seeds that the previous Windows build had
rounded. Setup explicitly used the baseline's **actual** campaign654759232 and
roster2084084480, reproducing layout236920976/population1463751064,60 roamers,
1209 boxes,1736 walls, the same Wizard/feat/equipment and identical starting
ability roll (STR11/DEX6/CON13/INT17/WIS9/CHA15). The first wrong-seed trial and a
capture with lost input focus are excluded. Graphics were applied through the
normal startup cfg after several Lua graphics commands proved API-blocked;
a full restart cleared those diagnostic errors. Native settings retain
1280×800, native walls, shadows/shadow textures/water1, HDR2, picmip0, AA0,
vsync0, fps_max300, mcore1/queue2/bone1. Its OpenGL backend reports DXlevel92
despite requesting95; this is a recorded runtime difference from Windows95.
Corridor/portrait screenshots appear intact; full visual/controls acceptance
for this runtime is still unverified. The hull-material/stock-gate fallback
diagnostic flags also occur in the Windows baseline and are not new Linux proof.

| Native stationary diagnostic | Average FPS | Median ms | p95 ms | p99 ms |
| --- | ---: | ---: | ---: | ---: |
| Default allocator /1 |13.24|65.300|148.391|195.388|
| Default allocator /2 |9.60|103.419|157.634|176.496|
| One compiler-cache reset |9.47|98.304|180.374|214.429|
| Larger code arena, rejected |0.94|1050.783|1158.646|1162.710|
| Compilation disabled, diagnostic only |30.55|31.666|39.601|47.717|
| Fresh MALLOC_ARENA_MAX=2 /1 |31.24|30.988|39.064|48.688|
| Fresh MALLOC_ARENA_MAX=2 /2 |31.40|30.779|37.281|49.001|
| Allocator2 +16MiB code capacity |31.50|30.724|38.199|47.145|
| Also4096 traces |31.30|31.046|39.103|47.115|

All are30s diagnostics, not acceptance scenarios. The larger-arena attempt had
only28.86 active seconds and major actual stalls; it is a failed experiment.
Every result fails40FPS. Native CPU samples placed46.6% of user samples in
lua_shared_client.so. A bounded syscall trace found approximately16000 mmap /
munmap pairs per second: the LuaJIT code allocator requested64KiB at addresses
in its jump range, received the same unsuitable address and immediately freed
it. Stacks identify the Lua shared library. Compiler-cache reset did not help;
increasing arena size to1MiB made the rejected-allocation loop worse. Temporarily
disabling compilation improved FPS, supporting that diagnosis. All such compiler
changes were outside production and removed by a fresh process.

Many neighboring64MiB allocator reservations motivated a fresh launch with the
standard glibc `MALLOC_ARENA_MAX=2` setting. This eliminated the failed mapping
loop while retaining normal compilation, and produced the31.24/31.40 results.
The observations agree with [LuaJIT's code-allocation implementation](https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lj_mcode.c);
they do not prove the interpreter/runtime is otherwise optimal. Raising code
capacity and trace count afterward produced no gain beyond repeat noise and is
rejected. No security protections were changed. The equipment generator's
existing interpreter-only crash workaround remained in place throughout.

The native alternative does not beat the measured Proton10 condition. Restore
Steam's Default Public Version and Proton10, then continue the source loop.
Artifacts: `/home/deck/deborah-benchmarks/native64-diagnostic/` contains captures,
excluded attempts, source/configuration receipts, native CPU data and syscall
stacks. Task-local launch/controller scripts and cfg are under
`/home/deck/deborah-recovery/` and the game's cfg/DATA directories; these are
diagnostic preparation, not a shipped optimization preset.

## Candidate3: ordinary NPC queries through Soldier progression

Restored Windows public x64 build25375506/GMod2026.09.17 under Proton10.0-4b,
SRT sniper and the isolated task prefix. Fresh controls have no MangoHUD/DXVK
HUD. KWin fullscreen removes window-border clipping while preserving the actual
1280×800 engine viewport. This is a separate presentation condition from the
older windowed/Mango measurements; compare only within this new control group.
Same seed, position/view, equipment,60 normal roamers, quality,15W and threaded
rendering settings; all focus samples true, clean92cc64bc source (runtime b8).

| Stationary control / repeat | Average FPS | Median ms | p95 ms | p99 ms | 1% low FPS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Fullscreen /1 |32.84|29.409|37.436|44.197|20.28|
| Fullscreen /2 |32.93|29.417|36.810|46.307|19.09|
| Fullscreen /3 |32.68|29.566|37.451|44.327|20.35|

These30s stationary controls all fail; they do not satisfy any frozen scenario.
Raw: `/home/deck/deborah-benchmarks/soldier-lookup-comparison/baseline-92cc64bc/`.

Bounded prior query timing observed about20k Soldier StateFor calls/second,
including queries for ordinary NPCs that cannot own the Player-only incarnation.
Hypothesis: reject those native kinds before IsValid/optional human-state field
lookups. Preserve plain profile tables, Player admission, retirement and normal
NPC progression authority. No cross-tick cache or timing/count changes. The
provider is now covered by the server source fingerprint/installer; client-only
render-source coverage stays separate.

Fourteen targeted checks including Soldier lifecycle, AI, statuses and full923-file
Lua syntax passed before instrumentation changes. Seven expanded source coverage,
transport/installer/capture/profiler and syntax checks pass; exact receipts are
`/home/deck/deborah-recovery/evidence/soldier-provider-gate/receipt.json` and
`/home/deck/deborah-recovery/evidence/soldier-source-manifest-gate-final/receipt.json`.
Fresh installed Deck
comparison and retain/revert decision are pending. This is a hypothesis, not a
measured performance improvement.

## Remaining acceptance

All six required scenarios in `docs/STEAM_DECK_BENCHMARK.md` remain unverified.
No ordinary traversal/combat/boss/interactions/co-op scenario has completed its
three warmed uncapped repeats, and40FPS capped verification has not started.
Freeze physical routes/checkpoints before accepting comparative scenario runs.
Next: isolate the remaining simulation/rendering cost, inspect stair/false-floor/
full-update visibility, finish physical gameplay checkpoints, and repeat the
focused optimization loop. Do not publish a completed40FPS claim.
