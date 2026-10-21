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

### Candidate3 installed measurements and follow-up diagnostics

Clean source `da4e9597cbc80823dfbbd7dfe2aca3ad09b78994` was installed after a
full quit. Proton10/no-HUD/fullscreen1280×800 and the normal seed/60-roamer
arrival fixture match the fresh control condition above. All capture source
checks pass, including111 server and51 client authorities. These remain short
stationary diagnostics, never required scenario acceptance.

| Candidate3 / repeat | Average FPS | Median ms | p95 ms | p99 ms | 1% low FPS |
| --- | ---: | ---: | ---: | ---: | ---: |
|1 |33.49|28.902|36.495|42.340|21.15|
|2 |33.31|29.233|35.966|44.679|19.12|
|3 |33.21|29.053|36.695|44.382|16.90|

The mean is1.58% above the fresh controls; the repeat ranges do not overlap.
The same bounded1-in64-call instrumentation estimates Soldier StateFor cost at
13.10ms/s versus25.68ms/s previously, with similar call counts. Inclusive sampled
timers overlap and cannot be added. These observations support less query work,
but a later restored-source control at about25minutes reached only32.06FPS.
Ordinary AI positions and session age vary. Retain the candidate provisionally;
a fresh alternating comparison is needed to separate a small FPS effect from
this larger session variation. Every run fails the40FPS frame budget.

Normal200-unit input playback completed the frozen17-node red-card route in
34.55s, with ordinary combat reducing health100→96. All65 live actor queries
(including newly encountered actors) retained their own progression state and
returned no human-Soldier incarnation. Standing idle afterward led to normal
enemy death. A subsequent client full update recovered1209 registered/bounds-ready
boxes,591 renderable/618 NoDraw, and1736 cargo models; this was a recovery check,
not an active gameplay performance run. Raw captures, query observations and the
full engine console are under
`/home/deck/deborah-benchmarks/soldier-lookup-comparison/candidate-da4e9597/`.

Separate mechanism diagnostics, all outside production and restored:

- Engine fullscreen at the same viewport:32.96FPS, no benefit; restored the
  prior windowed-engine/KWin-fullscreen mode.
- Temporarily hiding1736 client cargo models:37.64FPS/p9532.582ms. This isolates
  rendering cost, removes required visuals and still fails; it is neither an
  optimization result nor acceptance. All models restored by the finite timer.
- Combining existing slab submissions:26.79FPS with incorrect per-frame cache
  invalidation; corrected mounted-material identity yielded31.64FPS. Even the
  one-build cache was slower; rejected, exact methods/resources restored.
- Native GetRenderMesh submission for423 ordinary slabs:32.64FPS, rejected;
  restored each Draw/GetRenderMesh/registry owner. Screenshot is limited view
  evidence, not whole-game visual acceptance.
- Compiler-cache reset in both Proton realms:31.59FPS versus the later32.06
  control; no benefit. No compiler setting or rendering prototype is shipped.

Raw mechanism records: `presentation-mode-diagnostic/`, `render-isolation/`,
`floor-submit-diagnostic/`, `native-floor-mesh-diagnostic/` and
`proton-jit-diagnostic/` beneath `/home/deck/deborah-benchmarks/`.
The main-thread native sample, mapped to PE modules, attributes about40.6% of
samples to Lua shared,19.8% client,10.7% engine,9.8% server and10.8% unmapped
(including generated code); these are CPU samples, not additive frame durations.
The Proton syscall trace does not show the native-Linux compiler mapping loop.
Artifacts: `cpu-da4e9597/`. During the floor diagnostic AC was online, CPU sensor
77°C, GPU68°C and both power caps15W; raw host telemetry is retained.

Next: fresh alternating Soldier-provider comparison and continued simulation
profiling. A separately labelled local dedicated-server diagnostic is being
prepared to isolate hosting cost; it does not replace the frozen listen-host
requirements or the still-unverified four-actual-player condition.

### Candidate3 alternating confirmation

A fresh public-Windows/P10 single-instance session alternated candidate / old /
old / candidate / candidate / old logic, using the same viewport, settings,
normal60-roamer seed and arrival position. The old arms injected the exact
previous StateFor function; candidate arms restored the original installed
function identity. All six are30s mechanism diagnostics, explicitly marked as
external function comparisons, not final source-build acceptance.

| Arm sequence | Average FPS | p95 ms | p99 ms |
| --- | ---: | ---: | ---: |
| Candidate1 |32.873|36.695|43.332|
| Old1 |32.195|37.154|46.135|
| Old2 |32.298|37.468|46.129|
| Candidate2 |33.102|36.801|50.060|
| Candidate3 |33.318|36.271|44.215|
| Old3 |32.754|36.617|44.132|

Candidate mean33.098 versus old32.416FPS, +2.104%; FPS ranges do not overlap.
Together with reduced sampled query cost, this supports retaining candidate3.
Tail latency is not consistently improved and all40FPS gates still fail. The
original source function was restored before quitting the game. Raw comparison,
exact injected scripts, per-arm metadata/ACKs, captures and full console:
`/home/deck/deborah-benchmarks/soldier-alternating-comparison/b5295459/`.

An isolated local dedicated test server (app4020) is installed and stopped,
prepared for a separately labelled hosting-cost comparison. No public-server
process or token was changed. The next runtime comparison is Windows x86-64
beta under Proton10; this Windows combination was not covered by the earlier
native-Linux beta investigation. Resolution, workload and quality remain fixed.

### Windows beta and local dedicated comparison

Windows x86-64 beta build25936581/GMod2026.10.14 under the same Proton10 prefix
was slower:31.63/31.83/31.65FPS, p9537.800/37.721/38.606ms,
p9952.344/45.027/46.141ms. Capture configuration differs from public only in
engine/branch. Same normal seed,60 roamers,1280×800, native walls and source
fingerprints. Rejected; restored Default Public Version/build25375506. The beta
uses `bin/win64/gmod.exe`; public uses `gmod_win64.exe`. An automatically launched
beta instance and the explicit instance briefly overlapped before measurement;
both were stopped, then one fresh verified64-bit instance produced these captures.
Raw: `/home/deck/deborah-benchmarks/windows-beta64-diagnostic/b5295459/`.

A separate process on the **same Deck** then hosted a native Linux32 dedicated
server, GMod2026.09.17/network2026.04.29/protocol24, LuaJIT2.0.4, tick interval
0.015s. The client remained public Windows64/Proton10, LuaJIT2.1.0-beta3.
Four available server slots, **one actual player**,60 ordinary roamers,
identical seeds/arrival view/equipment/graphics; all51 client/111 server source
checks pass. Both processes share the device and15W budget. The local server uses
its own task directory, sv_lan1 and no persistent GSLT. It ultimately connected
through the Deck's private LAN address; loopback query/connection attempts failed.
One-slot dedicated startup was invalid and was replaced with four available slots.
Packet tracing was removed before captures. No public-server process was modified.

| Separate dedicated diagnostic | Average FPS | Median ms | p95 ms | p99 ms | 1% low FPS |
| --- | ---: | ---: | ---: | ---: | ---: |
| Warmup |53.29|18.234|22.548|26.662|30.94|
| Repeat1 |53.79|18.118|22.071|26.893|30.69|
| Repeat2 |53.96|18.025|22.116|26.515|30.38|
| Repeat3 |54.23|17.907|21.540|26.644|29.98|

All are30s stationary diagnostics; numeric short thresholds pass with no prolonged
drop. **They do not satisfy the frozen listen-host condition or any required
180-second gameplay scenario.** This comparison changes process topology and
server OS/VM together, so it does not isolate either contribution. Frame/resource
receipts confirm1736 native cargo models/3131 client entities, no batches,
idle non-VR and zero Lua errors. Player health100, Wizard, AR2 clip20, measured
ping5ms; no HP/AI/resources override. Raw captures and fixture:
`/home/deck/deborah-benchmarks/dedicated-local-diagnostic/b5295459/`.

Next compare the public32-bit Windows listen host under Proton10. It may reduce
VM/lookup cost while preserving the original hosting condition. Retain all frozen
criteria; a different accepted hosting requirement would need an explicit decision.
The remaining simulation profile should include MotionV2 and target/route helpers,
which have not yet been deeply attributed. All six required scenarios remain open.


### Windows32 and focused movement probes

Public Windows32 under Proton10, on the same Deck, graphics and normal seeded
listen-host population, measured29.77FPS warm and29.60FPS repeat (p9539.862/
39.519ms, p9950.334/48.641ms). This was slower than Windows64 and was rejected.
The client is restored to public Windows64/Proton10, installed cleanff166895.
Raw: `/home/deck/deborah-benchmarks/windows32-listen-diagnostic/ff166895/`.

A separate bounded1-in64 sampled profile on that restored build attributes about
95.2ms/s inclusive to MotionV2.MoveToward,46.9ms/s to EntrySafety.BeforeAI,
26.9ms/s to ExactCell,25.8ms/s to Rules.ProgressionState,23.1ms/s to _SetActivity,
19.6ms/s to MovementAllowed and18.9ms/s to Animation.Apply. These overlap; do not
sum them or interpret them as FPS. Every wrapper restored its original binding.
Raw/script: `/home/deck/deborah-benchmarks/motion-cost-diagnostic/ff166895/`.

Two external finite mechanism probes were rejected; neither changes source:

| Mechanism diagnostic | Control FPS | Prototype FPS | Prototype p95/p99 ms | Decision |
| --- | ---: | ---: | --- | --- |
| Temporarily suppress native movement on53 active ordinary non-boss/non-deadcrab actors |33.194|33.552|36.009/47.510| No useful gain; original53 move types restored |
| Allocation-free scalar sanctuary segment clipping |33.194 before /32.675 nearby after|32.967|36.212/47.445| Within session variation; original function restored |

The first probe retained ordinary AI calls/travel (85,101 MoveToward calls and
357,623 aggregate travel units over45.03s,48 actors moving). This does not prove
native collision/interpolation equivalence, and no such change is retained.
Original native type was11/MOVETYPE_CUSTOM. Exact scripts, restoration receipts,
conditions and failed raw captures are retained under
`/home/deck/deborah-benchmarks/native-motion-diagnostic/ff166895/` and
`/home/deck/deborah-benchmarks/entry-sweep-diagnostic/ff166895/`.

The existing public dedicated server answers the normal Source query but has
zero actual players. Four-player native acceptance remains unavailable. A pending
explicit hosting decision separates the frozen solo listen-host criterion from
the faster same-Deck dedicated diagnostic; no acceptance condition was changed.

A longer partial first-sector route is frozen before further source edits in
`/home/deck/deborah-benchmarks/frozen-scenarios/d1-first-sector-180.json` with its
input script and SHA256 receipt. It uses normal movement/aim/fire/reload/Magic,
real AI/resources/collision and timed map toggles. It does not cover stairs,
later sectors/objectives or the full required traversal scenario. Retain its
result with that limited scope, including any death, stall or input failure.


The first180-second attempt on the restored listen host completed only83.951
active seconds:27.111FPS, median31.026ms, p9571.044ms, p99115.296ms,1%low7.292FPS,
max207.967ms,81.806 active seconds below40 and nine drops lasting at least2s
(longest14.916s). The controller reached33 complete waypoints, then was blocked
by normal combat and died at84.534s (waypoint34); a later environment-only hull
trace found no surviving static blocker at that location. Ordinary ammo was
spent, loot collected and enemies killed/replaced. No health/AI override occurred.
The incomplete capture fails both performance and duration and cannot be accepted
as any required scenario. Exact route/input, gameplay receipt, full engine log,
raw performance and failed analyzer result:
`/home/deck/deborah-benchmarks/gameplay-first-sector-diagnostic/ff166895/listen-1/`.
This reveals much worse gameplay tails than the stationary profile. Next isolate
combat/encounter/update spikes in a separately labelled diagnostic before making
any further performance change. Do not infer sustained40FPS from arrival views.


### Combat attribution follow-up and current checkpoint

A fresh publicWin64/P10 listen host repeated the same ordinary first-sector
input route. A separate60-second CPU profile started25s after playback dispatch;
the Hero died at41.132s of route playback, leaving only16.412 active seconds.
Profiled22.118FPS/p9597.689ms/p99148.948ms are not an equivalent unprofiled
performance comparison. Profile rows span59.97s including post-death simulation:
EntrySafety.BeforeAI54.85ms/s, TickCloseDefense52.72ms/s, native runner behavior
32.27ms/s, shambler27.38ms/s (max49.96ms), bioblaster23.04ms/s and deadcrab22.74ms/s.
Client combat-feed drawing33.76ms/s (mean0.964ms, max4.74ms) and persistent HUD
17.40ms/s add cost. Existing production text/layout caches already cover these
paths; no duplicate cache or timing-changing AI shortcut was introduced.

The temporary route's1Hz logger hit Clip1 on an invalid native weapon during the
death transition. Its original input and error are preserved beside this capture;
the external logger now guards that transition. This is a diagnostic error, not
a production source regression. Neither this mixed active/dead profile nor its
FPS certifies any acceptance scenario. Raw/script/full console:
`/home/deck/deborah-benchmarks/gameplay-profile/df106dc1/listen-first-sector/`.
A host sample during this diagnostic shows CPU cores up to3.5GHz, GPU200MHz/68°C
and APU10.1W under its unchanged15W caps; this does not establish GPU saturation.

Current source changes remain the three retained measured candidates above.
No further source optimization was retained from the movement/combat follow-up.
The frozen solo listen-host condition still fails. Same-Deck dedicated hosting
remains a separately measured alternative awaiting the explicit hosting choice;
three additional real clients are required for the four-player gate, and no
server SSH configuration/key is available on this Deck. The existing public
server is reachable but reports zero players. No public deployment occurred.
Temporary benchmark-controller files are archived and removed from client/server
autorun while waiting; game/test processes are stopped. Resume from the clean
published perf/deck-20261021 checkpoint, reinstall only after full quit, restore
the archived finite controller only for diagnostics, then continue the measured
loop under the confirmed hosting condition. Do not merge a completed40FPS claim.

## Remaining acceptance

All six required scenarios in `docs/STEAM_DECK_BENCHMARK.md` remain unverified.
No ordinary traversal/combat/boss/interactions/co-op scenario has completed its
three warmed uncapped repeats, and40FPS capped verification has not started.
Freeze physical routes/checkpoints before accepting comparative scenario runs.
Next: isolate the remaining simulation/rendering cost, inspect stair/false-floor/
full-update visibility, finish physical gameplay checkpoints, and repeat the
focused optimization loop. Do not publish a completed40FPS claim.
