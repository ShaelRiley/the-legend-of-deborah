# Steam Deck optimization iterations — 2026-10-21

Target: **unmet / full acceptance unverified**. This record does not certify40FPS.

**Cadence correction:** the earlier53–54FPS dedicated diagnostics used a slower
native NextBot cadence and cannot prove equal-workload performance. See the
server-cadence section below before citing those results.

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


### Native-call, validity and collector follow-up; launch guard correction

The31a09219 follow-up found that stock restart resets multicore to0. Its native
call/index samples and28.502FPS control used **multicore0**, unlike the previous
multicore1 series. The earlier df106dc1 combat profile likewise used0. These are
condition corrections, not equivalent performance comparisons. A direct audit
of archived runtime markers verifies all Soldier alternating/source comparisons,
the ff166895 unprofiled27.111FPS gameplay run, dedicated comparisons, Windows32
and Windows beta comparisons used multicore1 as recorded. Their evidence remains
unchanged; no poor result is discarded.

The finite native-call sampler restored737/737 bindings. Locomotion desired-speed
and velocity setter samples total about2.77ms/s including timing overhead, too
small to justify changing movement suppression. Per-instance overrides did not
intercept native entity methods, so their zero counts are a coverage limitation,
not evidence those methods are free. A separate20s NextBot metamethod sampler
restored2/2 bindings and counted9.88million reads/760,373 writes. Its per-call
sampling/lookup wrappers perturb a very hot path; timing estimates are not
a calibrated native CPU budget or FPS evidence. Exact scripts and receipts:
`~/deborah-benchmarks/native-index-diagnostic/31a09219/`.

Restoring multicore1 produced33.213FPS, p9536.328ms, p9945.344ms. A finite cached
native-validity mechanism probe measured33.288FPS, p9537.015ms, p9949.435ms:
within noise with worse tails; rejected. The original global predicate restored
after50.00s (5,354,389 fast calls,2,164,018 fallback calls,61 known native actors).
No such global replacement is production code. Raw/script/restoration receipts:
`~/deborah-benchmarks/validity-diagnostic/31a09219/`.

A separate bounded pause of both Lua collectors measured32.621FPS,
p9534.187ms/p9939.366ms: no average gain and still far below target. Server Lua
memory grew29,156→294,011KiB before the256MiB growth guard restarted its
collector at38.50s; client53,047→267,361KiB by its45.04s restart. Both restored before
further work; no collector pause/tuning is retained. Raw/script/receipts:
`~/deborah-benchmarks/gc-cost-diagnostic/31a09219/`.

The task-local launcher now executes the13-setting benchmark config after map
load. Its fresh restart passed runtime preflight with no manual multicore command:
x64, Windows/P10,1280×800, multicore1, queue2, threaded bones1, fps300/vsync0,
focus true. That early-session30s configuration check measured32.284FPS,
p9537.593ms/p9945.703ms; it is not thermal/gameplay acceptance. Exact config bytes
are published as `tools/steam_deck_benchmark.cfg`, optional copy/launch instructions
in the protocol. A deliberately wrong expected-multicore value was rejected
before capture. Harness/launcher snapshot, byte hash and failed/successful guards:
`~/deborah-benchmarks/auto-settings-launch/31a09219/` and
`~/deborah-benchmarks/preflight-guard/31a09219/`.

GitHub's complete31a09219 matrix finished325/334; all nine failure anchors,
not only suite names, match the previously reproduced parent1335/cec10 failures.
Source bytes stayed unchanged during the gate. Low-end source, native-boundary,
full Lua syntax, VR and audio gates pass. Full receipt, every suite log and exact
comparison: `~/deborah-recovery/evidence/checkpoint31-ci/`; workflow
https://github.com/ShaelRiley/the-legend-of-deborah/actions/runs/39696097231 .
The nine failures remain unresolved; no green full-matrix or40FPS claim is made.
No additional production Lua optimization was retained from this follow-up.


### Local loopback and server-cadence correction

Both client/server installed cleancd484ffa. A fresh four-slot native server on
127.0.0.1 and fresh publicWin64/P10 client could not connect with default socket
mode, including a client explicitly bound to127.0.0.1. Both processes use the same
network namespace. A PTY and file logging made server readiness observable; no
cause is inferred from the earlier closed-stdin launch. Two client startup
attempts briefly overlapped before any FPS capture and were stopped. The helper
now locks launches and refuses an existing GMod client. Failed logs/screenshot:
`~/deborah-recovery/local-candidate-loopback/`.

Setting net_usesocketsforloopback1 on both ends allowed the clean loopback pair to
connect: actual localhost endpoint, four available slots, one real authenticated
player, normal frozen Wizard/equipment/seed and60 roamers. This removes the LAN
address dependency for that tested combination. Source query packets still time
out; a launcher must not treat A2S silence as proof that this local server is dead.
The setting is documented in the official Facepunch CVar reference:
https://wiki.facepunch.com/gmod/ConVars_In_Garrysmod .

A new workload mismatch was then identified: native default nb_update_frequency
0.1 gives seven ticks/0.105s, while the prior listen-host log gives one tick/0.015s.
The cheat-protected variable refused a normal console change. For a separately
labelled unranked mechanism test, sv_cheats1 permitted0.015; no godmode, HP,
damage, resource or enemy-count change was used. This is not a validated normal
production hosting configuration.

| Server cadence counter | Movement calls | Aggregate travel | Wall / simulation seconds | Moving / valid bodies |
| --- | ---: | ---: | --- | --- |
| One tick, configured0.015 |67,066|217,257.52|20.0125 /20.0100|56 /61|
| Stock0.1, seven ticks |10,756|98,691.11|20.0087 /20.0100|56 /61|

The stock cadence produced only45.4% of the one-tick travel; unchanged actor
counts/profile fields did not prove equivalent AI execution. Earlier dedicated
53.79–54.23FPS results must not be used as same-workload improvement evidence.
With one-tick cadence, a new30s uncapped actual-Deck diagnostic measured51.566FPS,
median18.590ms, p9523.887ms, p9928.753ms,1%low27.800FPS, max49.750ms,1.639s below40,
no two-second drop (longest0.056871s). Source51client/111server hashes match;
1280×800, P10, multicore1/queue2/bones1, native walls and normal60 roamers remain.
This passes only short numeric thresholds, not any required gameplay/thermal/
three-repeat/capped/multiplayer gate. Raw scripts, counters, exact conditions and
full client/server console:
`~/deborah-benchmarks/dedicated-loopback-cadence/cd484ffa/`.

The new diagnostic support records server_runtime from the server's own APIs:
engine/OS/VM, dedicated/singleplayer, configured slots versus actual humans,
tick interval/time scale and an allowlist of cheat, hibernation, NextBot,
AI-disable and socket-loopback cvars. Unknown native APIs remain unavailable;
server values are never synthesized from a client's nonreplicated defaults.
Runtime metadata survives bounded console summaries and full DATA/net/performance
transport. The client capture now tracks multicore, threaded bones and socket
mode, including changes during a capture. No per-frame work or gameplay mutation
is added. Targeted capture, transport, profile, installer-manifest and B28 suites
pass, with changed-file syntax/diff checks. Native readback of these new fields is
pending the clean-source install; no diagnostic-support code is a40FPS claim.

## Remaining acceptance

All six required scenarios in `docs/STEAM_DECK_BENCHMARK.md` remain unverified.
No ordinary traversal/combat/boss/interactions/co-op scenario has completed its
three warmed uncapped repeats, and40FPS capped verification has not started.
Freeze physical routes/checkpoints before accepting comparative scenario runs.
Next: isolate the remaining simulation/rendering cost, inspect stair/false-floor/
full-update visibility, finish physical gameplay checkpoints, and repeat the
focused optimization loop. Do not publish a completed40FPS claim.


### Normal-cadence native startup and representative gameplay failure

Clean68597112 native readback confirms111server/51client files, no mismatches,
normal60roamers,1736cargo models,1280×800, Windows64/Proton10 client and native
Linux32 dedicated server on this Deck. A startup argument+nb_update_frequency0.015
before+map emits a protected-cvar warning but the post-map, post-join native
readback and engine report show one tick withsv_cheats0. No protected flag, engine
API or gameplay resource was altered. A20s movement counter recorded71,868calls,
194,051travel units,57moving/61valid actors and restored its original function.
The different timing/path state prevents interpreting travel totals as exact
parity with a different run; this corroborates active one-tick behavior.
Socket-loopback1 is set at both ends. Settled server status reports one actual
human, four available slots,40ms ping and0loss. The native metadata survives the
full client capture and valid JSON in the physical console file.

| Separate local-dedicated diagnostic | Active seconds | FPS | Median ms | p95 ms | p99 ms | 1%low FPS | Below40 seconds | Longest slow seconds |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| normal cadence, stationary30s |29.965|48.456|19.717|25.897|33.160|25.268|2.706|0.151|
| same frozen first-sector input, unprofiled |80.886|46.856|19.146|33.534|51.083|13.295|31.174|3.454|
| first-sector profile after map reload |50.472|44.342|21.593|33.661|50.635|14.657|20.616|2.601|

Every row fails an acceptance condition. The180s unprofiled request ended with
ordinary death at80.463s, route node34; only80.886active seconds were captured.
The profiled repeat died earlier and includes post-death time in its60s inclusive
profile rows. Startup/staging dwell and patrol phase differ, so its FPS is not a
matched comparison. Rendering submission, floor geometry, feed text, hostile
bodies and server entry/close-defense queries remain costly. No enemy, AI,
collision, damage, HP, resource or effect reduction is retained. These are partial
first-sector hosting diagnostics; they cannot replace the frozen listen-host or
full six-scenario acceptance. Full raw captures, analysis, normal-input receipts,
console files, native movement counters and launch arguments:
`/home/deck/deborah-benchmarks/dedicated-startup-cadence/68597112/`.

### Direct live NextBot progression lookup candidate

The profile and prior bounded samples identify repeated progression lookup in
AI/status/movement. A finite external prototype borrows the documented native
Entity.GetTable result only for NextBots with a nonnil instance progression field;
all other cases call the original resolver. It stores no profile across calls.
It uses the same unchanged production68597112 source and a controlled external
runtime substitution, not a claimed installed-source improvement.
Four sequential30s listen-host arrival arms use1280×800/P10/multicore1/queue2/bones1,
normal60roamers/1736models, HP100/Wizard/AR2 and the same yaw90 view.

| Ordered arm | FPS | p95 ms | p99 ms |
| --- | ---: | ---: | ---: |
| control1 |32.646|37.530|44.384|
| prototype1 |33.352|36.226|43.822|
| prototype2 |33.217|36.277|45.213|
| control2 |32.729|36.956|45.574|

Mean prototype FPS is1.827% higher with disjoint short-run FPS ranges. All fail40FPS.
The wrapper restored the original after all four arms; its240s guard also bounds
unexpected interruption. Native sanity checks cover61NextBots plus the real Player
andNULL; all61live NextBots own the exact original profile in their Lua table.
An immediate Remove probe still reported the temporary entity valid because native
removal is deferred; it is not proof of post-removal behavior. The source candidate
therefore retains the existing IsValid check before any native table access.
Do not equate the outer runtime prototype with the source candidate: the latter
preserves the human-Soldier provider and optimizes only the base canonical lookup.
It requires fresh installed-source measurements before a retain decision.
Raw scripts, restoration receipt and captures:
`/home/deck/deborah-benchmarks/state-lookup-diagnostic/68597112/`.

The source uses one live native table per call, retaining ordinary fallback for
missing/inherited fields or missing API and all Player/Hero/Soldier semantics.
Expanded existing progression tests verify in-place and whole-table replacement,
false/nil/inherited values, invalid-actor rejection before the native boundary,
and an API-unavailable run. Lifecycle, AI/sanctuary, profile, manifest and syntax
checks pass. The selected dodge test fails at its existing177migration assertion,
reproduced on parent1335 and matching the prior325/334 matrix record; it is not a
new failure or a green full matrix. Static receipt/logs:
`/home/deck/deborah-recovery/evidence/nextbot-live-state-gate/`.


The fresh installed4a6b4aa2 source comparison completed in one uninterrupted
Deck listen-host session. New arms use the actual unmodified production binding;
old arms reconstruct the exact68597112 base function plus the unchanged human
Soldier wrapper from git. The finite330s guard and final restoration preserve the
production binding. No source file changed while running.

| Ordered installed-source comparison | FPS | p95 ms | p99 ms |
| --- | ---: | ---: | ---: |
| current1 |33.159|36.586|45.454|
| old1 |32.907|36.806|43.103|
| old2 |32.655|36.650|45.075|
| current2 |33.754|36.316|43.404|
| current3 |34.034|35.187|42.351|
| old3 |32.963|36.809|43.670|

Current mean33.649 versus old32.842FPS, +2.458%, with disjoint FPS ranges.
Retain the focused live lookup; tail latency is not consistently improved and all
six short diagnostics fail40FPS. Every capture confirms matching51client/111server
fingerprints, unchanged settings, normal60roamers,1736cargo models and focus.
A separate native check confirms61owned NextBot profiles and a temporary native
NextBot's live identity. After0.2s its deferred removal completes; native GetTable
returns nil and the production authority returns no stale state. The production
validity check remains. These finite lifecycle observations and short arrival
comparisons do not accept later gameplay or full multiplayer.
Raw captures, reconstructed control source, exact arm conditions, restoration,
native boundary readback and comparison.json:
`/home/deck/deborah-benchmarks/state-lookup-source/4a6b4aa2/`.


### Rejected runtime and accessor experiments after 5969f57e

All results below are actual Deck diagnostics, not acceptance scenarios. Source
remains 5969f57e (runtime code 4a6b4aa2). Normal native cargo rendering, population,
AI and the frozen thresholds remain required. No experiment in this section is
retained in production.

| Condition / finite comparison | Measured result | Decision |
| --- | --- | --- |
| Public native Linux32 listen host | 30.649 / 30.474 FPS; p95 38.156 / 38.325 ms | Slower; reject runtime switch |
| Live-table NextBot LOD-field index wrapper, three arms each | 32.592 vs 33.118 FPS mean (−1.590%) | Reject |
| Close-defense adjacent field borrowing, two arms each | 33.287 vs 33.056 FPS (+0.699%); p95 worse | Useful gain not established; reject |
| Cached-table index mechanism, two arms each | 32.306 vs 32.329 FPS (−0.069%) | Reject; whole lifecycle correctness also unverified |
| Native progression lookup before duplicate validity check | One pair 32.158 vs 31.893 FPS | Incomplete after host ACK-reader failure; no gain accepted |
| One hardware thread per physical core, two arms each | 31.138 vs 31.166 FPS (−0.091%) | Reject; all original thread affinities restored |
| Proton10 Xalia paused, two arms each | 30.554 vs 30.582 FPS (−0.090%) | Reject; process resumed |
| Existing experimental wall batches enabled | 32.540 FPS, p95 38.932 ms, p99 50.299 ms | Reject: large missing faces and native bump lighting omitted |

The accessor prototypes reached the real native NextBot path: a separate two-second
coverage sample observed 1,008,392 lookups, including 569,719 LOD fields, all matching
cached actor rows. This confirms hot-path coverage, not a performance gain. The
native progression removal probe observed validity/table identity through deferred
OnRemove/EntityRemoved and nil after removal completed. The production validity
check is unchanged. All prototype function/metatable/setter bindings were restored.

Native32's startup hang was an SDL locale-warning modal behind its main window.
A task-local child debugger identified that modal without changing security or
ASLR; acknowledging it allowed gameplay. A private generated locale did not remove
the warning. This runtime uses OpenGL dxlevel92 versus Windows95; fallback glyph
coverage and full visual parity remain unverified. The second capture directory
is named netgraph-off, but that requested Lua console change was blocked: net_graph3
remained active. Three helper errors preceded that second capture; none accrued
during it. Native shutdown returned139; the cause is unverified. Native32 is not
accepted or recommended. Its copied stale Windows console was preserved and replaced
with a link to actual native stdout; no stale console is treated as fresh evidence.

The progression guard comparison ended after a host command-reader failure despite
a true engine ACK; a partial JSON read is suspected, not proven. The local reader
now retries transient partial reads within its existing deadline; explicit failed
ACKs still fail. This helper repair is outside production source. All prototype
scripts remain inert outside explicit task-local dispatch. The final wall-batch
capture is separately labelled and fails both performance and visual constraints;
the ordinary lod_wall_batches0 path was restored before quitting.

Across the long Windows session stationary FPS drifted from33–34 toward30–31.
Available temperatures/clocks do not establish thermal throttling. Small late
signals cannot be compared to fresh early controls; restart before the next baseline.
All six full scenarios, warmed180s triplicates, capped play and four actual players
remain unverified. Same-Deck dedicated hosting is still a separate diagnostic;
it does not silently replace the frozen listen-host scenario.

Raw captures, scripts, conditions and restoration receipts are under
`/home/deck/deborah-benchmarks/`, respectively:
`native32-listen-diagnostic/5969f57e/`, `lod-index-diagnostic/5969f57e/`,
`close-fields-diagnostic/5969f57e/`, `cached-index-mechanism/5969f57e/`,
`native-accessor-coverage/5969f57e/`, `profile-native-guard-diagnostic/5969f57e/`,
`physical-core-affinity/5969f57e/`, `xalia-paused-p10/5969f57e/`, and
`experimental-wall-batches/5969f57e/`.


### Missing-target close-defense candidate

Fresh Windows64/P10 source8a012398 listen-host arrival baseline is32.431FPS,
p9537.459ms/p9944.027ms. The separate full profile reaches29.172FPS, so its
inclusive timings are diagnostic only. A separate15s one-in64 service sample
restored all29bindings; movement, entry admission and close-defense calls remain
prominent. Raw baseline/profile/sample:
`/home/deck/deborah-benchmarks/fresh-broader-profile/8a012398/`.
A two-second target counter observes2,880 BeginCloseDefense calls, all with invalid
targets. TickCloseDefense already services actor status/life before this second
permission/geometry pass. A finite early-invalid-target wrapper comparison gives
controls32.602/32.434FPS versus candidate33.303/32.809FPS; mean33.056versus32.518
(+1.655%), disjoint short ranges. It restored the original. No valid-target combat
path or timing changes; no source performance acceptance yet.
Raw scripts, captures and comparison:
`/home/deck/deborah-benchmarks/close-target-diagnostic/8a012398/`.

The source candidate rejects native-invalid targets at the start of the canonical
BeginCloseDefense; valid targets follow the existing commitment path. The existing
AI harness verifies nil/NULL/removed targets do not repeat permissions or query
body geometry, while retaining first-pass status expiry/callback behavior. Seven
selected checks pass: close-defense commitments/Watcher router, AI work, entry
hotpath, B7 visuals, status/element matrix, changed-file syntax and diff check.
Receipt: `/home/deck/deborah-recovery/evidence/close-target-gate/receipt.json`.
Live GDD00→01→03 B7/status rules retain canonical combat, exact lives, fixed warning,
interruption, defenses and multiplayer authority. Fresh installed-source/control
Deck comparison is the next gate; target remains unmet.


Fresh installed4d0a6d80 source comparison completed all six30s arms. The candidate
is the actual unmodified production function; controls reconstruct the exact old
8a012398 function with the same local copy/flat helpers. No source files changed
while the game ran. A330s guard and final restoration bound the substitutions.

| Ordered arm | FPS | p95 ms | p99 ms |
| --- | ---: | ---: | ---: |
| candidate-1 | 33.734 | 35.883 | 42.227 |
| control-1 | 33.152 | 36.370 | 47.079 |
| control-2 | 33.327 | 36.260 | 43.682 |
| candidate-2 | 33.972 | 35.118 | 46.245 |
| candidate-3 | 34.230 | 35.243 | 44.438 |
| control-3 | 33.452 | 36.724 | 44.218 |

Current mean33.979 versus old33.310FPS (+2.007%); FPS ranges are disjoint. Retain
the focused early-invalid-target check. All captures fail40FPS; tail latency is
not consistently improved. All retain51client/111server source matches, normal
60roamers/1736cargo models, unchanged graphics/focus, zero Lua errors and idle VR.
Native NextBot sanity confirms nil/NULL perform zero repeated actor checks; a
valid distant Player still performs the existing permission check and cannot
commit an out-of-range strike. Raw captures, source reconstruction, restoration,
comparison, fingerprints and native sanity:
`/home/deck/deborah-benchmarks/close-target-source/4d0a6d80/`.

A separate actual readback found net_graph1 in this fresh process, rather than an
assumed screenshot-derived value3. A four-arm console/readback comparison gives
net_graph1:34.100/34.534FPS; net_graph0:34.332/34.244FPS. Mean34.288vs34.317
(−0.086%), overlapping ranges: no useful gain established. Original1 restored.
No frozen setting change is adopted. Source comparisons retain identical native
settings within each comparison; do not infer historical net_graph values from
this fresh readback. Raw:
`/home/deck/deborah-benchmarks/network-overlay-overhead/4d0a6d80/`.

Dungeon10 preparation uses the existing admin dungeon command, canonical XP13
threshold, first legal offered feat at each ordinary slot, ordinary starter and
normal deployment. No direct HP/Magic/ammo grants: Wizard13 has164/164HP and a
normal Magnum/clip6. Campaign654759232, levelSeed1217158872, layout306806046;
normal generation selects36roamers,59planned bodies/18groups and1348cargo models.
These differ legitimately from Dungeon1 and cannot be presented as an isolated
source gain. Exact initial profile/equipment/choices, graph/actor/encounter snapshot
and preparation scripts are preserved before further optimization under
`/home/deck/deborah-benchmarks/frozen-scenarios/d10-normal-13/`.
The first arrival30s capture was interrupted before saving: all Steam/GMod/Wine
processes disappeared around03:38:42UTC and Steam assertion dumps were written.
No completed capture or FPS is accepted; cause is unverified. The inspected kernel
interval has no OOM/GPU reset. Logs, queued-command preservation and failure record:
`/home/deck/deborah-benchmarks/dungeon10-diagnostic/4d0a6d80/interrupted-arrival/`.
Restart Steam, reproduce the normal fixture, finish/freeze physical combat inputs,
then profile heavier gameplay. All six complete scenario gates remain unverified.


### Current recovery and coverage checkpoint

Latest complete GitHub matrix on ea19fbeb finishes325/334 with source_changed0.
All nine failing suite names and exact assertion anchors match the previously
reproduced parent1335/cec10/31a09219 record; no green full-matrix claim. Low-end
source, VR and audio workflows pass. Full downloaded334-suite artifact and exact
comparison: `/home/deck/deborah-recovery/evidence/ea19-complete-matrix/`,
workflow39718368154. The seven selected close-defense checks and native dispatch
observations remain the relevant passing gates for the focused change.

The recovery launch loads the exact ea19fbeb fingerprints (same runtime code as
4d0a6d80), then records an orderly server shutdown atCurTime6.36 before any task
bridge ACK. Steam remains alive. The inspected task autorun and launch config
contain no automatic exit. Its cause is unverified; the user has been asked whether
the exits were external or spontaneous. No game is currently running; do not
restart/refocus repeatedly while that device-state question is unresolved.
Recovery console and observations:
`/home/deck/deborah-benchmarks/dungeon10-diagnostic/ea19fbeb/recovery-exit/`.
A newly present YouTube session was paused with existing authorization and verified
Paused before this launch. It was already Playing on the later restoration check,
with the same track identity; no additional Play was needed. Current playback is
unpaused. The capture helper now records actual task-paused media evidence rather
than the earlier no-MPRIS condition. These later conditions must remain separate
from the completed source comparisons made before Chrome appeared.

Unaffected preparation uses the archived native graph and actual production
Navigator with float32 Vector boundary doubles: Dungeon10's proposed four-destination
route has89waypoints,52on two stair traversals. Native compilation/equality, actual
combat inputs, loot and phase coverage remain unverified. Dungeon1's partial
progression plan has101cell edges and three vertical transitions toward the three
keys/gates and Neil console. One snapshot-blocked non-gate edge requires ordinary
clearance; no runtime gate/event flag is changed by these offline plans. Normal
Dungeon14/20 XP/feat/starter/deployment and boss-entrance preparation scripts pass
syntax only and have not executed. No HP/Magic/ammo boost, forced phase or AI
reduction is prepared. Files are in `frozen-scenarios/d10-normal-13/`,
`frozen-scenarios/d1-progression-route-PREPARATION.json` and
`frozen-scenarios/preparation-only-later-levels/` under
`/home/deck/deborah-benchmarks/`. These are preparation, not accepted scenarios.
The exact operational resume instructions are in
`/home/deck/deborah-recovery/RESUME.md`. All six scenario gates remain unverified;
canonical main is not promoted as completed40FPS work.


### October22: native Dungeon10 gameplay, coverage and current baseline

After an overnight OS reboot, a persistent user service runs the actual Windows64/Proton10 game independently of tool sessions. A180s capture completed; the earlier unexplained exits remain historical, not a current access blocker. No media session survived reboot. For matched conditions external DP1 was changed from75 to60Hz; restore75 after benchmarks. Internal1280x800@60,15W/autoGPU/AC remain fixed. Actual runtime remains SteamOS3.8.28/Jupiter LCD512GB/GMod2026.09.17/build25375506/public/P10.0-4b/sniper/LuaJIT2.1.

Fresh canonical Dungeon1 class/feat/starter/deploy followed by normal Dungeon10 XP/feat/starter/deploy produces Wizard13,HP164/164,AR2clip20, exactly3 canonical equipment items. No direct HP/Magic/ammo or timer override. Campaign654759232/level1217158872/layout306806046;36roamers,18planned groups,59planned bodies,1348native cargo models. Native Navigator output initially matched the prepared89point route exactly. Return-path cycles extend ordinary movement beyond180s (303waypoints), frozen before first combat input. The old six-item/Magnum fixture contains unexplained extra equipment; its normal-resource provenance is UNVERIFIED. Do not compare across those fixtures as a source gain or restore those extras.

| Installed label/runtime | Measurement | Avg FPS | Median ms | p95 ms | p99 ms | Max ms | 1% low FPS | Time below40 s | Longest drop s | >=2s episodes |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|282451f5/4d0a6d80|30s stationary arrival diagnostic|56.004|17.088|21.837|27.759|62.572|27.309|0.911|0.124|0|
|same|180s initial normal-input combat, coverage FAILED|42.899|21.841|31.420|50.403|139.567|14.105|49.367|2.721|4|
|same|30s corrected-route gameplay diagnostic|40.120|23.584|33.413|68.715|176.489|11.794|14.159|2.782|1|
|same|60s corrected-route gameplay baseline|39.251|24.349|34.561|53.708|95.298|14.045|32.293|1.957|0|
|same|60s separate full profile, instrumentation overhead included|33.502|26.724|53.553|86.708|200.887|8.983|43.356|4.404|6|

These are different diagnostic conditions, not a before/after source comparison. All gameplay runs fail timing thresholds. Hardware was under normal load for at least10min before the initial180s capture. The first180s playback hit an authored thin stair guard at waypoint60 after65s and then stalled; it also fails scenario coverage. Actual PlayerHull trace identifies lod_static_box kind3. Private playback replaces six upper-stair cell centers across the three cycles with existing Navigator-authored upper landings. Two actual hull sweeps are clear; ordinary input traverses the local guard/landing/corridor in2.612s with HP164. Production collision and AI are unchanged. No performance improvement is attributed to this route preparation. Later playback stalls at waypoint90, so complete physical coverage remains unverified; the first60s supports short iteration only.

The full profile reports inclusive, overlapping client costs of349.395ms/s PreRender-to-PostRender,70.987ms/s generated geometry,35.319ms/s combat feed,25.927ms/s branding and14.300ms/s status portrait. Server entry safety is45.477ms/s/160673calls, close defense24.169ms/s/79829calls. Profile overhead is material and its FPS is not acceptance. Further bounded detail is required before a focused optimization. A mid-profile hardware observation is66C/APU9.061W with15W caps; one sysfs GPU-busy sample is0%, insufficient alone to attribute the bottleneck. The native process loads RADV/Vulkan and the Proton d3d9 DLL; no software-rendering claim is made.

A desktop Spectacle capture selected the external wallpaper and is unusable for scene evidence. An engine JPEG includes the open console and an unexpected stock “Menu Failed” dialog; clean scene visibility and menu-runtime status require investigation. Zero tracked client/server Lua errors does not certify the separate menu realm.

Raw captures: `/home/deck/deborah-benchmarks/dungeon10-diagnostic/282451f5/session1/` and `session2/`. Normal fixture/playback freeze: `/home/deck/deborah-benchmarks/frozen-scenarios/d10-normal-13-verified-20261022/`. Guard traces/walk receipt: `session1/landing-correction/`. Private finite controller: `/home/deck/deborah-recovery/run-dense-arm.py`; its source snapshots accompany captures. ACKtrue only proves dispatch: actual receipts and assertions are separately checked.

No production runtime source changes follow4d0a6d80. Target UNMET, all six complete scenarios UNVERIFIED; PR7 stays draft, main remainscec10dc54. Next: isolate the measured heavy cost, focused source change/regressions and equivalent uninstrumented repeats. Preserve complete routes/content/normal AI, then complete the frozen triplicates/capped checks and actual four-player coverage before final integration.


### Detailed heavy profile and bounded component-read candidate

An equivalent60s detailed diagnostic profile measures65.318ms/s generated geometry, including4.809ms/s TexturedBox.DrawSlab (137740calls) and3.285ms/s Draw (65738calls). Traversal/visibility/native component work dominates those mesh calls. Server detail: Claim24.575ms/s, ExactCell17.902, Service8.939, Context3.333; these inclusive rows overlap. Raw `dungeon10-diagnostic/282451f5/session2/corrected-deep60/` under the benchmark root. No profile FPS is accepted as ordinary timing.

A finite private HUD cache prototype is rejected after its initial performance gate:38.513FPS/p9535.754/p9969.856/longest2.509s over60s, versus the prior39.251/p9534.561/p9953.708 baseline. This does not establish a statistical slowdown, but supplies no improvement sufficient to retain it. Actual native offscreen image tests preserve text/roles/positions and fading; alpha clearing required an explicit transparent draw because the initial clear left an opaque rectangle. After correction, sample maximum rounding error5/255 on a bright background, zero for the fading fallback. Those visuals do not offset the failed performance gate. Exact source, images, comparisons and restoration receipt: `/home/deck/deborah-benchmarks/hud-cache-probe/`. All313builds/25219hits/821fallbacks were restored after193.75s; no production HUD source changed.

The next focused candidate uses the observed native C Vector.Unpack/Angle.Unpack component order in visualSnapshot, with existing scalar access retained for custom values or unavailable APIs. Every pose/bounds value remains fresh per pass; existing owner/cache/culling rules remain unchanged. The existing renderer harness also runs through a simulated native API route, covering its mutations, nested cameras, partial datatables, kind changes, cleanup and refresh. These are regression/operation checks, not proof of Deck FPS. Native timing is PENDING; retain or revert only after equivalent uninstrumented source captures.

Static candidate gate: corrected dependency environment finishes28/29, syntax923Lua files; the remaining geometry_fullupdate failure is the exact unchanged keycard/cl_init.lua:6 missing hook.Remove test double. Substituting the parent static-box source reproduces the same failure. The separate native-component mode passes the full existing renderer harness (173visible-corner/73conservative cases plus300parity passes). Initial missing node/Pillow environment failures were resolved and their original logs retained. Gate artifacts: `/home/deck/deborah-recovery/evidence/native-components-corrected-env-gate/`; native-path final log and parent source under `native-components-gate/`. No full-green or native-FPS claim.


### Component candidate native result: reverted

Installed b04e1224, actual1280x800/Windows64/Proton10 normal Dungeon10 first60s:38.458FPS,median24.658ms,p9534.995,p9964.834,max123.790,1%low12.667FPS,below4033.820s,longest3.460s/two episodes>=2s. Compared with the earlier39.251/p9534.561/p9953.708 unmodified baseline, this gives no useful improvement. Different short runs/noise prevent claiming a statistically proven slowdown. The component candidate and its test-mode changes are reverted to exact e8c8afd3 source rather than retained without gain.

Before capture, scalar parity passes on968native boxes. A proposed exact-parent function control then fails before any capture because debug.setupvalue is unavailable. The helper's fresh-receipt check catches the error despite ACKtrue. No bypass, parent FPS or completed six-arm comparison is claimed. Candidate raw capture, source parity and setup failure: `/home/deck/deborah-benchmarks/native-components-source/b04e1224/`. The game was fully quit before source restoration. Next profile targets movement/collision-safety; all six complete gates remain unverified.


### Physical playback completion, frozen v5 and warmed baseline

Ordinary Hero movement exposes two additional preparation defects in the NPC kinematic route: returning directly beneath a descending staircase climbs it again, and a loose upper-landing tolerance can clip the east corner on a later circuit. No game collision/AI changes were made. Native feet-hull support and PlayerHull sweeps validate the north-side lower bypass; a30node ordinary-input walk completes in8.578674s,HP140. A fixed upper east clearance point has clear sweeps in both directions and nine±4unit landing samples; landing tolerances are5. The315point v5 preserves all destinations/actions/counts. Its native180s input receipt reaches node179 alive with HP102, clearing the previous obstructions.

Canonical NewCampaign now resets the same normal D1/D10 fixture without resetting the warmed Lua VM/JIT. Each run still verifies Wizard13/HP164/AR2clip20/exactly3canonical equipment items/seeds/counts. A fresh client receipt verifies1348native cargo models and completed materials before playback; gameplay begins at the existing audit's sample start instead of ending several seconds before its window. Every bridge lease remains finite1800s and is explicitly renewed during active benchmark work. These are infrastructure/physical-coverage corrections before any retained new performance source; no threshold is relaxed or gain attributed to them.

| Installed/runtime | Run | Avg FPS | Median ms | p95 ms | p99 ms | Max ms | 1% low FPS | Below40 s | Longest s | >=2s episodes |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|68a6a9d3/4d0a6d80|v4,180s,second-circuit obstruction; coverage FAIL|35.833|25.439|42.546|80.443|142.434|10.282|113.539|8.709|11|
|same|v5,aligned warmed180s ordinary movement alive; timing FAIL|36.460|25.276|41.771|80.233|160.627|10.586|112.473|5.788|13|

V4 start metadata already confirms1348models/material completion; its earlier setup image was taken before publication and is not scene acceptance. V5's post-readiness image shows the cargo corridor, HUD and ordinary weapon without the stock menu-error overlay. The separate stock console/main-menu error remains unverified, not silently declared repaired. V5 has actual beam Magic casts, shots, damage, ordinary reloads/ammo pickups and continued enemy behavior in the RPG logs. Complete required-content enumeration and repetitions remain; no whole-scenario acceptance.

Raw: `/home/deck/deborah-benchmarks/dungeon10-physical-v4/68a6a9d3/` and `dungeon10-physical-v5/68a6a9d3/`; freezes under `frozen-scenarios/d10-normal-13-verified-20261022/physical-route-version4/` and `physical-route-version5/`. The helper now refuses incomplete scene receipts and aligns normal input to audit sampling. All previous failures are retained.

### Swept-entry scalar prototype: rejected

A separate native diagnostic measures HostileMotionV2.MoveToward66.699ms/s and EntrySafety.MovementAllowed17.331ms/s, inclusive/instrumented. A private scalar slab-intersection candidate removes temporary bound/axis tables while preserving the exact epsilon, boundary inclusion, destination apron, withdrawal and denial counters. The production B29 harness passes with that private method injected. Each native arm additionally matches2916position-pair/actor cases against the exact current method using isolated counters, without changing gameplay/resource state.

Four matched aligned60s arms retain the same v5 first segment and canonical warm-VM reset: parent35.435949/37.144629FPS (mean36.290289); scalar35.862408/33.319343 (mean34.590876). Ranges overlap and one scalar run has markedly worse stalls; no reliable gain. All four fail40FPS. The candidate is rejected, every120s public-method lease restores the exact original after capture, and no production source changes follow4d0a6d80. Raw/proof/restoration records and comparison: `/home/deck/deborah-benchmarks/swept-entry-probe/68a6a9d3/`.

### Native engine scope and broader diagnostic

Native engine commands verify `vprof_generate_report` and `_hierarchy`; `vprof_dump` is unsupported on this build and the helper's original dump attempt is preserved as a tooling error. The retained report covers1519frames/37.97s including preparation; its40.00FPS aggregate is NOT the active-gameplay result or acceptance. The actual30s capture is37.104FPS/p9537.840/p9974.747, with native profiling active.

Inclusive scope averages: Lua protected calls15.561ms/frame (Lua execution/calls dominate), server10.964, rendering9.454, NextBot behavior4.711, opaque renderables4.285. Nested scopes overlap and cannot be added. PhysicsSystem.PhysicsSimulate0.014ms/frame and file-read scope0.020 are small in this sample; no major GPU/wait or disk bottleneck is proved. Active cores read approximately3.5GHz despite powersave policy; GameMode is inactive. Raw report/hierarchy, CPU policy and gameplay capture: `/home/deck/deborah-benchmarks/native-vprof/68a6a9d3/gameplay30/`.

For broader function/peak attribution, task-local FPtje/FProfiler gather code at165a49907da8432d091289f961941aad75becb11 is reviewed and loaded from DATA only, with no addon/UI installed. A10s server call/return trace is armed during the same route; the preexisting debug hook is nil and must be restored. JIT-hook coverage and substantial observer overhead limit these diagnostics; never treat their FPS or inclusive function totals as uninstrumented budget proof. Native API probes generated one tracked tooling error per realm by assuming absent timer.GetTable; original errors are retained and do not belong to the preceding clean v5 baseline. No restricted debug.setupvalue/jit.attach bypass is used.


### Corroborated status cost and native bounds API constraints

A30s one-in64 diagnostic records355711BindActorLife calls/5557samples, estimated34.642ms/s; all life entries remain unchanged (zero new/replaced, zero ResetActorLife calls). ProgressionState24.760ms/s, Has23.835ms/s andCanInitiateAttack11.531ms/s overlap those bindings. Distance1.955ms/s; PathToWaypoints only117calls/onesample and no demonstrated large budget. All bindings restore. Raw `/home/deck/deborah-benchmarks/sparse-status/68a6a9d3/gameplay30/`. FProfiler's huge path/life peaks are not corroborated and are not treated as CPU-budget evidence.

The actual native floor probe confirms GetBoxMins returns copies and SetBoxMins notifies, while raw SetDTVector is available and does NOT fire that proxy. Original bounds are restored synchronously. A cache of bounds across frames is therefore rejected. Receipt `data/legend_of_deborah/bench_bounds_notifications.json` under the live game; copy into final candidate evidence. The exact mounted core NetworkVar source captures its typed native reader in the getter descriptor.

The next candidate retains every getter on every selected pass. It batches Vector components only when the declared getter descriptor proves the native GetDTVector return type, and pose components only for exact native GetPos/GetAngles function identities. Missing/custom/replaced methods use the previous scalar path. This avoids b04e1224's added per-value type checks while preserving raw writes, in-place custom values and current cache invalidation. Existing renderer/geometry checks pass; native branch/mutation proof and equivalent Deck source timing are pending. No gain or acceptance claim.

### Typed component candidate: six native comparisons, rejected

Candidate a76ef534 proves native NetworkVar reader and pose method identities while retaining live getter calls. Native parity passes1209boxes, plus raw SetDTVector writes, custom bounds and Entity metatable GetPos/GetAngles overrides; original methods/bounds are restored synchronously. The first private instance-GetPos override assertion was invalid because native method dispatch ignores that instance field; it was corrected to an actual metatable provider and passed. This is a tooling assertion, not a production regression. Scoped gate28/29 matches the known parent keycard hook.Remove test-double failure; existing renderer/geometry checks and923-file syntax pass.

Both comparison arms use the same reconstructed draw/paint kernels and public hook.Add, with only the snapshot function exchanged. Read-only upvalue inspection verifies bindings. Each installation has a fresh receipt, a120-second restoration lease and explicit restoration after60seconds. No restricted debug.setupvalue is used. Same warmedVM, canonical fixture reset, v5 aligned normal input, source/seeds/counts/settings and focus are verified. These short isolated diagnostic hooks do not replace full acceptance of the unmodified installed renderer.

| Arm | Snapshot | FPS | Median ms | p95 ms | p99 ms | Longest below40 s |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | candidate | 37.985 | 23.842 | 41.883 | 83.676 | 2.411 |
| 2 | parent | 35.589 | 26.996 | 39.132 | 60.830 | 6.144 |
| 3 | parent | 37.491 | 24.461 | 39.684 | 81.119 | 4.584 |
| 4 | candidate | 37.420 | 25.500 | 36.524 | 64.329 | 3.502 |
| 5 | candidate | 37.012 | 25.965 | 38.437 | 73.954 | 3.018 |
| 6 | parent | 35.719 | 26.135 | 40.843 | 75.320 | 4.540 |

Candidate mean37.472FPS versus parent36.266 (+3.325% arithmetic), but observed ranges overlap and the middle adjacent pair is slightly slower. Tails do not improve consistently and all arms fail. There is no demonstrated repeatable gain, so both changed runtime files are restored exactly to5889d8bf/runtime4d0a6d80 after quitting GMod. No proven slowdown is asserted. Compact records: [comparison JSON](STEAM_DECK_TYPED_COMPONENTS_20261022.json). Raw captures, exact private hook/script copies, installation and restoration proofs remain under `/home/deck/deborah-benchmarks/typed-components-source/a76ef534/`. Target and every full scenario remain unmet/unverified; no main promotion.

### Normal Dungeon14 baseline exposes native boss draw defect

A fresh canonical NewCampaign→D1starter/three-item checkpoint→D10XP/feats→D14XP/feats/starter/deploy, with no intervening combat or resource override, proves Wizard17 HP180/180 AR2clip20/3items, campaign654759232/level1217158876/layout1761773386,54roamers and1748native models. Before capture only, the documented developer entrance checkpoint opens prior gates and positions the Hero at the authored entrance; normal encounter Service owns once-only resupply. It does not change boss HP/phase/AI. A320point radius700 ground court circuit has native PlayerHull-clear first-cycle segments before boss-owned hazards spawn; ordinary CreateMove retains normal movement, aim/fire/reload/Magic.

The first60s original-hook diagnostic averages37.585FPS,median24.165ms,p9539.403,p9956.940,max1227.957,1%low7.653FPS,below4029.596s,longest3.702s. It fails. Input advances multiple ordinary circuits and logs normal wood projectiles/shooting/Jane damage, but onlyphase1 is observed. The raw capture also records two production client errors: util.GetModelBounds is absent at cl_boss_encounter.lua:91. Its visual signature was written before the error, so bounds/matrix setup was left incomplete. This is no clean or full boss acceptance. Raw `/home/deck/deborah-benchmarks/boss-baseline/cb90f2e7/d14-route60-run1/` includes native API receipt confirming Entity:GetModelBounds C method for citizen and propane models.

Repair uses Entity:GetModelBounds, the native unscaled model-bounds API ([Facepunch reference](https://wiki.facepunch.com/gmod/Entity%3AGetModelBounds)), and marks the signature only after matrix/render bounds apply. All18bosses pass both snapshot presentation transports; the new draw seam check covers absent util API, negative model-origin offset, scale/expanded bounds, unchanged reuse and live model/size invalidation. Exact parent source fails this new gate; candidate bytes are restored. This is a correctness repair, not an FPS improvement claim. Native restart/appearance/bounds proof and clean repeated boss profiling remain pending. All full acceptance criteria and workloads remain unchanged.

### Native boss repair confirmation and measured encounter scope

Fresh77db9cfe actual Dungeon14 reproduces normal source/settings/54roamers/1748models and identical320point court input. Its60s is37.533FPS,median24.077ms,p9538.551,p9959.781,max1197.560,1%low7.577FPS,below4029.714s,longest2.659s: FAIL. Both realms subsequently report zeroLuaerrors. A finite read-only wrapper observes51successful normal DrawActor returns, records Chuck/Jane exact expanded native render bounds and proper beaver flag, then restores in0.970s. The postcapture scene shows native court geometry/HUD and distant bodies; close face/tail and all phases remain unverified. Raw `/home/deck/deborah-benchmarks/boss-bounds-source/77db9cfe/d14-unprofiled60-run1/`. This accepts only the finite native bounds/API repair gate, never the whole scenario or a performance gain.

A separate75.026s method profile with allbindings restored attributes7.594inclusive ms/s to BossEncounter.Service,2.608ServiceMoves,1.320ServiceObjects,0.926Chuck.Think,0.662Targets. ValidateRoutes has7calls,0.471ms/s,max12.590ms. Nestedrows overlap. This phase1scope does not justify optimizing route validation. Its60s capture is37.715FPS,p9539.260,p9957.080,max122.870,longest4.055s and is diagnostic, not acceptance. Firstentry~1.2s stall disappears in thisrepeat; native coldscope is stillneeded toprove cause. Raw `boss-bounds-source/77db9cfe/d14-profile60-run1/`.

### Ordinary behavior dispatch prototype: rejected after four comparisons

Mounted base_nextbot code and actual suspended threads are inspected read-only. Of57actors,54suspend in the exact native non-yielding ordinary loop,3in the special Watcher loop. A finite per-instance prototype replaces only verified ordinary BehaveUpdate callbacks with pcall of the identical BeforeAI→TickCloseDefense→_BehaviourTick step at the existing engine callback. Watchers/newactors keep original coroutines. Matchingcontrolwrappers/counters, canonicalD10reset/warmVM/315pointalignedinput, source/settings/counts/focus remain. No native cadence cvar ischanged and no protectedAPI bypass isused.

| Arm | Mode | FPS | p95 ms | p99 ms | Longest below40 s |
| --- | --- | ---: | ---: | ---: | ---: |
| 1 | parent | 33.869 | 49.402 | 81.521 | 8.633 |
| 2 | direct | 36.989 | 37.404 | 70.843 | 4.206 |
| 3 | direct | 36.019 | 44.361 | 80.940 | 2.749 |
| 4 | parent | 36.720 | 38.419 | 71.316 | 5.248 |

Directmean36.504versusparent35.295 (+3.427%arithmetic) is notseparated fromobservedvariation; finalcontrol overlapsbothdirectruns. Allfail. The34directordinaryactors produce94585/94137callbacks andexactlythesamecompletedstepcounts,zeroerrors, andallbindingsrestore. Reject; no productionAIchange or gainclaim. Raw `/home/deck/deborah-benchmarks/behaviour-dispatch-probe/77db9cfe/`, compact [comparisonJSON](STEAM_DECK_BEHAVIOUR_DISPATCH_20261022.json). An earlier nativePlayer-onlydispatchmicroprototype preserves59actor/NULL/profile-replacement cases but savesonly~0.3ms/10kqueries; italso remainsprivate/unadopted, withno whole-gameFPSclaim.

### Boss V1 coverage correction and canonical V2 preparation

The developerentrance teleport in the first3D14captures omitted EntrySafety:Deployed. The previous D14spawn had registered a fresh entrytutorial life; boss teleport alone didnot transition that record to checkpoint deployment. Opening reservations can therefore reject bossincomingdamage. Mark V1normalcombatcoverage INVALID/UNVERIFIED. RawFPS andsource/APIproofremainunchanged; `coverage-correction.json` accompanies all3captures. Native Entity bounds/renderer repair remains independently proved and is not revoked by thiscombatfixturedefect. The current plan/PRcarry thiscorrection; no FPSgain isattributed.

V2 calls the existing EntrySafety:Deployed(p,state) after positioningat the authored entrance before capture and asserts its derived checkpointflagtrue. It writes no directorrecord,HP,Magic,ammo orbossphase. The same320point radius700route,normalcounts/settings andacceptancecriteria remainfrozen; oldV1 isarchived. V2nativeguardpasses; ordinarybossattacksreduceHP180→170. This remainsphase1iterationcoverage,notfullbossacceptance. Freeze `/home/deck/deborah-benchmarks/frozen-scenarios/boss14-preparation-v2-canonical-deployment/`.

### First-entry stall: measured model loads and loading-phase candidate

Fresh V2nativeengineprofile60s:35.938FPS,p9543.620ms,p9971.259ms,max1199.008ms,longest2.689s,FAIL/diagnosticonly. Fullyflushed reports attribute1155ms to serverLua, including703.65ms fileopening and345.17ms size/345msnestedopening; renderingmax48.52ms. The initial hierarchycopyendedbefore serverrows because RunConsoleCommand ACK precedes consoleflush; complete report/hierarchy nowpreserved. FileREADtimeitself is small; do notrepeat the earlier partialreportdiagnosis. Raw `/home/deck/deborah-benchmarks/boss-cold-vprof/28cc1b69/d14-v2-native60/`.

A fresh75s exact-call profile identifies Boss.Commit1175.624ms, primarySpawnActor901.212ms, Chuck.Start266.995ms, while progression forbothactors totals19.998ms. Allbindingsrestore. Raw `/home/deck/deborah-benchmarks/boss-commit-profile/28cc1b69/d14-v2-source60/`. NativeAPIprobe of a newmale03model takes161.869ms, repeated0.0475ms; previouslyloadedmodelsare~0.05ms.

A newfreshprocess privateprecache probe loads onlyexistingassets using a detachedbossstream toidentifythe samecitizen, leavingactualc.rng nil. Eightmodels cost1158.104ms total: base male07 855.393ms, selectedmale02 146.161ms, Jane25.309ms, rack36.206ms, barrier30.952ms, plank25.605ms, timber19.183ms, panel19.276ms. Commitmentafterward57.548ms. The sourceunchanged60s capturemaxfalls1218.346→115.186ms. Average37.186→37.825FPS is notclaimed asasteadygain; p9540.955→41.235ms/longest3.179→3.200s stillFAIL. This is an asset-cache diagnostic, not acceptance of an optimized installedsource. Raw `/home/deck/deborah-benchmarks/boss-precache-probe/28cc1b69/d14-v2-precache60-run1/`.

The firstprofileexport used an absentinputreceiptmtime zero and copiedthe oldbaseline beforethe75sleasefinished. Thatstaleexportis preserved, the genuinelyfreshnative receipt/restoreproofiscopiedaftercompletion, and `profile-export-correction.json` explainsthetoolingdefect. Retrievalnowcomparesagainstthe correspondingprofilefile's own previousmtime.

The focusedsourcecandidate calls a bossmodule's optionalprecache seam while BuildCurrentLevel holdsplayers andBuildReady=false. It reports bossPrecacheSeconds separately andincludesit intotal loadingtime. OnlyChuckimplements the seam, warming the exactbase/selectedcitizen,Jane,rack,barrier andthreewoodassets. A sharedselector previews adetachedRNG andrealStart retainsits ownunchangedstream; noactors,combatvalues,counts,cadenceorgraphicschange. Missing/failedoptionalprecache fallsbacktonormalfirstuse. The realframeworkpasses76checks includingzeroactorcreation,citizen/futureRNGidentity,loadingstate,unaffectedmodules andfailurefallback;companions118assertionsandsyntaxpass. Broadbootstrapandfreshsource-nativecomparisonpending. No completed40FPSclaim/mainpromotion.

Precachecandidate staticfinal: bossframework76/76, companion118assertions pass. Bootstrapgate30/33with923Lua syntax/no source mutation; skeletonblockadeseedgenerationhit45sbudgetunderconcurrencyandpassesalonewithin120s. The remainingquiz164andB29/crossdodge177matchtheexactpreviousparentfailureanchors; nofullgreenclaim. Chuck'smoduleisaddedtotheexisting116sourceinstaller/serverobservermanifest; repeatinstall/exacthash/symlink/atomicwrite/childretirementgatepasses andchangedobserversyntaxpasses. Localcompactreceipt `/home/deck/deborah-recovery/evidence/boss-precache-gate/receipt.json`. Nativeinstalled-sourceperformance remainspending.

Firstinstalledb19bccfb nativeoriginal-source60s (no privateprecache/functionprofiling):38.156FPS,median24.149ms,p9539.502,p9962.301,max117.762,1%low12.807FPS,below4029.730s,longest2.690s/twoepisodes>=2s. Itstillfails. Normalproductionloadreportsbossassets1.196263s,total3.705080s;112serverfingerprintsmatchwithzero mismatches/missing,54roamers/68planned/1748models andnormalWizard17HP180→170/clip20. Firstcoldentryhitchreductionissupported, not a steadyFPSgain orcompleteacceptance. Raw `/home/deck/deborah-benchmarks/boss-precache-source/b19bccfb/d14-v2-unprofiled60-run1/`. Source-watchandpopulationtransportfixturesareupdatedfortheintentional112serverhashmanifestandbothpass,includingcachedhashing/payloadbounds/noadditionalcensus. Runtimeimplementationisunchangedbythatfixturecorrection;freshprocessrepeatsremainpending.


## 2026-10-22: two native source preload confirmations and current Dungeon10 reference

Retain b19bccfb as an asset-stall improvement, with no steady FPS claim. Two fresh native source runs (no private precache or extra profiling) move the same eight Chuck/Jane models into the existing held loading period. Loading records 1.196/1.164 seconds of boss asset work; maximum gameplay frames are 117.762/134.200 ms, versus the 1,218.346 ms baseline with the cold commitment measured at 1,175.624 ms. The selected citizen, real encounter RNG, canonical checkpoint, actor counts and render bounds remain correct. Both short runs still fail steady timing: 38.156/37.015 FPS, p95 39.502/40.467 ms, p99 62.301/66.257 ms. Full phases and warmed acceptance remain unverified.

Current runtime b19bccfb (label 0070179c changes tests/docs only) completes the frozen Dungeon10 v5 input for 180.041 seconds through waypoint198. Its unprofiled capture averages36.331FPS, median25.929ms, p9539.986ms, p9973.949ms, max159.411ms and longest below40 episode13.179seconds: FAIL. Compared with the older36.460FPS baseline this supplies no steady gain; do not attribute route/preparation differences to source performance. Raw captures and thresholds remain unchanged.

Model-preload framework76cases and companion118assertions pass. Source-watch and population transport pass after updating their manifest expectation to112server/116total sources. Bootstrap recovers its skeleton timeout in isolation; known quiz164/dodge177 failures remain. No full green matrix is claimed. Native bounds proof and ordinary incoming damage are observed; V1 coverage correction below remains binding.

Next: measure a separate same-Deck dedicated configuration with identical normal AI cadence and source, while retaining the frozen listen-host acceptance. Continue later-level/full-phase preparation. Target UNMET; all six complete gates UNVERIFIED; PR7 remains draft and canonical maincec10dc54 is unchanged. Four actual players remain missing. ExternalDP1 must return to75Hz after benchmarks. [Compact measurements](validation/STEAM_DECK_BOSS_PRECACHE_20261022.json).

## 2026-10-22: separate dedicated diagnostic and exact recurring JSON cost

A separate same-Deck dedicated diagnostic preserves normal one-tick AI (41,831 movement calls/20s, wrapper restored), source hashes, counts and Dungeon10 v5 inputs. Its180s result is51.925FPS,p9528.629ms,p9940.791ms,longest5.428s: FAIL. This does not replace frozen listen-host acceptance or establish a delivered configuration.

Paired native profiles isolate a client timer spike, but exact-call measurement corrects the apparent file-I/O diagnosis:27writes total41.679ms/max1.919ms, whereas39JSON encodes total1028.736ms/max53.799ms, with21slow calls. Rewriting1000feedback rows every2seconds is a recurring serialization hitch. Source candidate caches canonical per-row JSON outside the rows, compares all persisted scalar fields and nested semantic text/roles, and rebuilds the ordered JSON array from live history at the same save cadence. Existing rows warm during loading; weak keys release evicted rows. History-page layout is not persisted. No combat, delivery, retention limit, audio or gameplay schedule changes.

Existing feedback/audio/ACK tests and76spot05assertions pass. A new native-shaped string contract covers loading/unchanged rows, scalar/in-place span mutation, replacement/order/eviction, transient layout and reload; exact parent fails it. Source-watch, transport,117source manifest (113server/52client expected), changed-file syntax and diff pass. Native JSON round-trip/source performance is PENDING. Both processes were explicitly stopped before edits; next fresh runtime returns to the original Deck listen-host configuration.

Target UNMET; all six complete acceptance gates UNVERIFIED; PR7draft/maincec10dc54 unchanged. [Candidate evidence](validation/STEAM_DECK_HISTORY_CACHE_20261022.json). Prior retained asset-stall result and failed full listen-host reference remain below.

## 2026-10-22: original-source native history cache proof and failed full listen-host measurement

Retain c11c3567 as a recurring history-save hitch improvement. Six alternating same-process native comparisons preserve identical decoded1000-row history and equal payload sizes: parent44.004–50.333ms (mean46.068), cached3.900–5.600ms (mean4.613). The actual native JSON mutation/order/replacement gate passes320452assertions; originalhistory/writer/encoder restore, and no test rows reach the preferred disk file. Source I/O profiling shows151JSONcalls total10.751ms/max5.251ms(reportexportaftercapture), with no active-gameplay encode>=1ms, versus the earlier1028.736ms/max53.799ms. All three profiling bindings restore.

The original Deck listen-host180s uninstrumented route still FAILS:36.343FPS,median26.121ms,p9539.632ms,p9962.382ms,max168.912ms,longest9.489s/13episodes>=2s. The older36.331FPS average is indistinguishable within noise; do not claim steady FPS or full-tail acceptance from one before/after run. Input completes180s. Exact raw paths and data are in [native cache evidence](validation/STEAM_DECK_HISTORY_CACHE_20261022.json).

A separate68s same-call server diagnostic records1122tiny log appends/305866bytes at1039.757ms total/max33.367ms;233JSONcalls total19.232ms/max1.107ms. Logging cost is observed, not changed. All APIs restore. Next: narrow the normal AI phase cost without changing cadence/condition servicing; remaining bosses/finale/fullphase and four actual players remain unverified. Existing/static cache gates below pass, current CI is tracked separately. Target UNMET, all six full acceptance gates UNVERIFIED, PR7draft/maincec10 unchanged.

## 2026-10-22: sparse AI phases and local native vector candidate

Sparse normal Dungeon10 AI phase profiling restores all103bindings. Inclusive estimates point to MoveToward67.431ms/s, EntrySafety.BeforeAI53.293ms/s and EnemyRoster.Tick56.685ms/s; these overlap and the instrumented34.973FPS run is diagnostic. The four irrelevant ordinary boss-dispatch methods together cost under6ms/s, so no dispatch rewrite is justified.

A focused MoveToward candidate reuses only locally owned native vectors for normalization, next-position translation, facing and velocity. Native float operations retain their order; all movement speed/dt limits, authored waypoints, collision/entry/magic-wall checks, animation, status servicing and wrapper dispatch remain. Published velocity never becomes scratch memory for a later tick. Old arithmetic remains available if mutable APIs are absent. Native math proof matches12000ground/stair/facing/velocity/travel cases exactly, with zero component mismatches/input mutations. This is correctness evidence only.

B7/full production, B29dispatch, magicwall, entrysafety, bossframework, companion and physical-boss regressions pass; the new mutable-branch/input/velocity-ownership gate passes and fails on the exact parent. Syntax/diff pass. Next: alternating fresh original-source candidate/parent60s Deck runs; preserve the existing visibility/device/Watcher motion wrappers by testing actual installed source rather than replacing the exposed method. No FPS improvement or acceptance is claimed. Target UNMET; six whole gatesUNVERIFIED; PR7draft/maincec10 unchanged. [Candidate receipt](validation/STEAM_DECK_MOTION_VECTORS_20261022.json).

## 2026-10-22: native vector source comparison rejected

Six frozen fresh-process actualDeck source comparisons finish with no repeatable benefit. Current39.014/36.561/35.921FPS averages37.166; parent37.469/37.877/36.318 averages37.221. Ranges overlap, two adjacent pairs are slower, tails are inconsistent and every run fails the budget. Revert51d8a5a0 movement/B7test changes exactly to32d82a82; no gain or proven slowdown is claimed. Native12000case exact math/input proof and all focused correctness gates remain valid historical evidence, not FPS acceptance.

The sequence was frozen parent/current/current/parent/parent/current before its first parent result, with external sensor monitoring OFF uniformly. Earlier sampler-on/off source runs remain as exploratory diagnostics; one pair does not prove observer overhead and is not mixed into the source comparison. Every source arm verifies its actual native motion algorithm/wrapper chain, normalWizard13/3items/seeds/population/1348models, source hashes and complete60s input/capture; eachprocess is explicitly quit. [Raw metrics, conditions and decision](validation/STEAM_DECK_MOTION_VECTORS_20261022.json).

Candidate51 CI lowend/VR/audio passes. Fullmatrix325/334 has the same9knownparent suite/anchor signatures (raw39841156806), notgreen. Earlier two fixture omissions were repaired in32d82a82; assertions retained. Runtime now keeps the validatedc11historycache/b19modelpreload/77bossdraw repair and earlierCPU/render improvements, with no Motioncandidate. TargetUNMET; sixfullgatesUNVERIFIED; PR7draft/maincec10unchanged. Next: inspect remainingCPU/render scheduling cost and continue fullboss/finale coverage without changing the frozen workload or acceptance limits.


### Native finale composition retry caused by floor support ray misses

The first clean Deck Dungeon 20 lower-court run fails: 5.447 FPS, median 196.041 ms, p95 305.864 ms, p99 334.240 ms, maximum 387.357 ms, longest drop 58.818 seconds. Input reaches waypoint 187 with zero Lua errors. No encounter commits: 263 complete-group retries each reject all four required Sentries. Combat and phase coverage remain unverified. The private route's incorrect cell-size assumption was corrected before its first timing capture; the clear 640-point, 288-unit-radius route is now frozen.

A bounded native admission probe records 44 support refusals and restores both methods. Native rays miss the generated floors; zero-width, one-unit-tall hulls hit all 20 footprint samples within 0.03125 units of the expected height. Change only T:Supported's query. Preserve its five points, mask, filter, range, normal, height tolerance and non-actor support checks, plus full route, stair and occupancy checks. Preserve the complete composition and existing retry cadence.

SPOT-08 passes 262 assertions; the exact parent fails the new native BBOX floor case. Warden, SPOT-06 (116), SPOT-07 (130), Hector/finale lifecycle, manifest/transport, B28 and syntax checks pass. The manifest now covers 118 total / 114 server / 52 client files. Next: install the committed candidate and repeat the same Deck route. No source FPS gain or encounter acceptance is claimed yet. [Evidence](validation/STEAM_DECK_FINALE_SUPPORT_20261022.json).

bc95 CI source/VR/audio checks pass; the full matrix remains failed at 325/334 (run 39845300211). SteamOS authorization policy denies the optional GameMode governor test; CPU settings remain unchanged. Continue unaffected work. Target UNMET; all six full gates UNVERIFIED; PR 7 stays draft and main remains cec10dc54. Four actual players remain unavailable. Restore external DP1 to 75 Hz after benchmarks.

### Installed native finale floor-support repair

Retain 8b0b531e's native floor-support repair. The same frozen Deck route now commits one Gordon, four clones and all four Sentries exactly once, with zero composition retries and zero Lua errors. All four real Sentries pass the post-capture ownership and five-point support gate. Ordinary incoming damage reduces HP211 to192 during the run. The baseline could not commit combat, so its 5.447→22.934 FPS change measures the repaired retry pathology, not identical functioning-fight workloads or acceptance.

The functioning fight still FAILS: 22.934 FPS, median36.877ms, p9576.116ms, p9998.104ms, max468.224ms, longest drop25.195s. Only phase1/lower-court coverage is observed. The later native ownership probe finds the player dead after the capture; that is not hidden or used as performance acceptance. Next: same-route native VProf diagnostic on the functioning fight, preserving source, resources, counts, AI and graphics. [Raw results and coverage](validation/STEAM_DECK_FINALE_SUPPORT_20261022.json).

Target UNMET; all six full gates UNVERIFIED. PR7 stays draft and canonical main remains cec10dc54. Continue measured optimizations and missing upper-floor, full-phase, Hector/rescue and real four-player coverage. Restore external DP1 to75Hz after benchmarks.

### Separate dedicated finale and native floor fixture follow-up

A separate same-Deck dedicated Dungeon20 diagnostic averages42.003FPS, median19.822ms, p9543.540ms, p9955.264ms, max275.124ms, longest drop4.619s/four episodes>=2s: FAIL. Preserve the frozen listen-host failure at22.934FPS; this variant does not replace it. Exact source,1820clientmodels,normalWizard20/seeds/resources,one human/four slots,66HznativeAI,57roamers and allninebossactors are verified. Native ownership/support passes; one commit and zero retries. Full phases, upper floor, Hector/rescue and four actual humans remain unverified.

Native profiling attributes25.000ms/frame inclusive to server simulation,11.320ms to NextBotLua and12.772ms to rendering; preparation and overlapping scopes are included, so these are diagnostic only. Sparse samples restore173bindings, then detailed entry samples restore162. Movement and entry checks are the larger measured shared costs. Do not cache across callback-bearing admission paths or change cadence without proof. No further runtime candidate follows8b0b531e yet.

The8d478035 full CI run is324/334: one NEW boss-framework fixture failure plus the nine known parent failures. The two finale integration fixtures supplied floors only to ray queries. They now provide native-style point-width vertical hull support; every composition, rollback, exactly-once handoff and rescue assertion remains. All76boss-framework cases pass locally. This is test-only repair; runtime/source8b remains unchanged. New full CI is pending, not claimed green. [Raw evidence and results](validation/STEAM_DECK_FINALE_SUPPORT_20261022.json).

Both local game/server processes are explicitly stopped after the diagnostic. Next: continue measured shared CPU/client-cost investigation and required coverage. TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10unchanged. Restore externalDP1to75Hzafterbenchmarks.

## 2026-10-22: both displays required and broad CI comparison complete

Explicit user requirement: keep BOTH monitors ON at all times and achieve40FPS in that configuration. Session idle inhibition is held; external1920×1080@75 is restored and internal1280×800@60 retained. No future monitor-off arm is allowed. Historical off data remains diagnostic only. The final both-on short Dungeon20 arm is21.129FPS,p9587.416ms,p99120.272ms,longest drop15.186s: FAIL. No source improvement is inferred from the display series.

f889bf95 full CI completes325/334FAIL. All nine failing suite names AND exact file/line anchors match bc95; the new8d boss-framework fixture failure is cleared. Source/VR/audio checks pass. No full green matrix or performance acceptance is claimed. [Display/CI evidence](STEAM_DECK_BOTH_DISPLAYS_20261022.json).

No game/server remains active. Next: bounded before/after process/thread CPU and scheduler accounting around the same ordinary gameplay route, preserving both displaysON and all workload/settings. TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10 unchanged. Continue measured optimization and missing gameplay/multiplayer coverage.

## 2026-10-22: main CPU boundary counters and animation cache candidate

Both displays remain ON at all times, external1080p75/internal1280×800@60. The normal60s Deck D20 route is22.329FPS,p9577.102ms,p99116.449ms,longest drop25.236s: FAIL. Boundary counters show the main task96.17%ofonecore and0.420srunqueuewait in64.917s; gameGPUgraphicsengine6.28%busy. This points to main-thread CPU work without changing monitor power or graphics.

A bounded broad Lua diagnostic restores2244bindings after skipping68duplicatealiases. Inclusive estimates overlap; wrapping CellCenter changes its identity fallback, so that timing is excluded. The first alias lease failed restoration and its game was stopped; raw failure remains. Animation resolution is a frequent shared query. Candidate borrows the current native instance table only for an owned cache hit; currentmodel/razor/hold checks and original miss/inherited/missing fallback remain. No actor, animation, combat or AI timing changes.

Focused animation/skeleton/fallen/entry/hurt/Razor/lifecycle gates pass; exact parent fails the new native-shaped owned-cache test. Native original-source timing remains PENDING. Next: finite native microdiagnostic, then matched fresh source gameplay measurements; retain only supported benefit. [Evidence](STEAM_DECK_ANIMATION_CACHE_20261022.json). TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10 unchanged.

## 2026-10-22: animation candidate source comparison rejected

Keep BOTH displays ON always: internal1280×800@60/external1080p75; session blanking inhibition remains held. Six original-source attempts preserve the frozen P,C,C,P,P,C order. Valid controls21.247/22.322/21.942FPS average21.837; valid candidates21.113/21.352 average21.232. Ranges overlap, tails are inconsistent and every run fails. Candidate03 dies ordinarily at47.315s/node157 and has only47.275active seconds; retain it as failed/incomplete with no replacement. This is three valid controls/two valid candidates/one failure, not three complete pairs. No statistically established slowdown is claimed.

The installed native resolver microprobe passes5763checks across57realactors and reduces114000queries from183.576–184.547ms to96.994–99.490ms with equal results and restored cache fields. That narrow cost reduction does not supply a whole-game FPS gain. Reject the candidate and restore sv_hostile_animation.lua exactly to62d587cb. Retain behavior-only cache invalidation tests and source coverage119total/115server/52client. The five completed FPS runs verify actual function/filehashes, normal resources/1820models andbothON. Console ticks>=60s andmanualhookstop corroborate physical input; manual stop produces no structured end receipt. Fullphases remainunverified.

eb1 fullCI is318/334FAIL: seven NEW sharedB28fixture count failures plus nine known parent failures. Repair the fixture to115 and explicitly require the animation source; keep all gameplay assertions. All seven affected gates pass locally, plus animation/skeleton/manifest/transport/syntax/diff checks. NewCI pending; no fullgreen claim. [Complete decision and raw paths](STEAM_DECK_ANIMATION_CACHE_20261022.json).

All owned game processes are stopped. Next: finite native measurement of repeated per-call player/deployment queries; no persistent identity/state cache or skipped callback checks. TargetUNMET; allsixfullacceptancegatesUNVERIFIED; PR7draft/maincec10 unchanged. Continue required ordinary gameplay/fullphase/fourhuman coverage.

## 2026-10-22: guarded per-call active-player query candidate

Both monitors stay ON at all times, external1080p75/internal1280×800@60. The native deployed-Hero probe confirms3identity lookups/1profile query per IsActivePlayer call. Private within-call prototype100kqueries150→47ms; guardedprototype189–192→79–81ms in a separate process. Both pass1006checks andrestoreproviders; this is microevidence only, not gameplayFPS or wholeacceptance.

Candidate shares only original function identities from RunManager, then reads current identity/slot/profile/deployment once per call. It caches no identity, PlayerState or eligibility across calls. Custom provider/validity/nativeAPI/tablemetatable/registry changes retain the existing path, order and results. Staging.IsDeployed and role/life/progression rules remain. LiveGDD06 revision is unchanged;4Hero+6Soldiercap and20srespawn remain. No tuning/GDD edits.

The production-query contract passes17cases/78assertions including removal/reconnect, same-seed state/map replacement, staging, roles, bots, mutable-registry tampering, custom callbacks and native/globalvalidity. Existing SharedEnemyAIWork includes this gate. Deployment, inventory transition, Damsel staging,196Soldierqueue assertions, TimeManagement, stagingevent/SQLite, Crypto/SQLite and syntax/diff gates pass. Next: fresh installed-source nativepath/transition/counter proof, then matched original-source gameplay comparisons. [Evidence](STEAM_DECK_PLAYER_QUERY_20261022.json). TargetUNMET; allsixfullgatesUNVERIFIED; PR7draft/maincec10 unchanged. Prior animation candidate remains rejected.

## 2026-10-22: installed player-query native gate and parent CI comparison

Installed73bcd0c0 passes1007native value/state-transition checks with all default/nativeAPI/table guards true. Slot, deployment, missing-profile and same-seed State replacement remain fresh; originals restore. Six100kquery microarms preserve results: parent155.155–158.439ms versus installedcandidate55.448–58.131ms. This is narrow query timing, not gameplayFPS. The first debugcallhook counter undercounts eventheknownparent; retain it as an INVALIDdiagnostic with full restoration/gameStop, neveractualcallcount evidence.

afff7087 fullCI returns325/334FAIL with the same nine names AND allfivefile/lineanchors asf889. The seven sharedB28fixture failures are cleared. Source/VR/audio pass. Current73bcd0c0 CI remains a separate pending gate. [Evidence](STEAM_DECK_PLAYER_QUERY_20261022.json).

Next: frozen freshoriginalsourceP,C,C,P,P,C gameplay comparison with BOTHdisplaysONalways, internal1280×800@60/external1080p75. Preserve normalsource/seed/counts/AI/input/graphics andfailedattempts. No profiler or in-window device sampler. TargetUNMET; allsixfullacceptancegatesUNVERIFIED; PR7draft/maincec10 unchanged.

## 2026-10-22: player-query candidate rejected after six complete native arms

All six original-source D20 attempts complete with native source/function receipts, normal resources/counts/AI, structured60s+ input endings and BOTHdisplaysON. Controls21.943/22.025/21.671FPS average21.880; candidates21.397/21.046/21.030 average21.158 (arithmetic−3.30%). Every candidate is slower than its adjacent control, tails vary and allcapturesFAIL. No statistical significance or CPUcause is inferred from three pairs. Reject the candidate; restore RunManager and Staging runtime files exactly toafff7087. Keep15behavior-only query cases/55assertions; existingSharedEnemyAIWork/syntax/diff pass.

The native1007case/value/guard/microtiming proof remains valid historical evidence, not a gameplaygain. No private counters, debughooks, provider replacements or device samplers ran in the FPS windows. The manual-stop metadata change only exposes/invokes the existing stop callback afterFPS; CreateMove body is byte-identical. [Raw results/conditions/decision](STEAM_DECK_PLAYER_QUERY_20261022.json).

TargetUNMET; allsixfullacceptancegatesUNVERIFIED; PR7draft/maincec10 unchanged. Allownedgames stopped. Next: native collision callback/broad-phase attribution, then a focused measured change if warranted. BothmonitorsONalways/internal1280×800@60/external1080p75. No unvalidated query/animation candidate remains.

## 2026-10-22: native collision gates reject both alternatives

Both monitors remain ON: internal 1280×800@60, external 1920×1080@75. Sparse callback classification restored both bindings after 68.02 seconds. Separation ran 3,573 calls/s and latch handling 3,068 calls/s; most sampled pairs involved static geometry. Callback-body estimates total 13.2 ms/s and do not measure native bridge or broadphase overhead. The diagnostic capture still fails at 22.43 FPS.

The predefined native trace gate rejects group 19 with custom checks disabled: all four NPC-pair traces change, although four player shots, four movement hulls and floor support match. Exact groups, flags, health and positions were restored; no production change follows. Native constraint.NoCollide is unavailable because both actual actors lack the required physics bodies. No constraint was created and state was restored. [Evidence](STEAM_DECK_COLLISION_20261022.json).

Next: sample the main thread at 99 Hz with native user cpu-clock events and no Lua wrappers to separate execution, GC and engine costs. Sampling is diagnostic only. Source 3cf2e875 retains no animation or player-query candidate. Target UNMET; all six full acceptance gates UNVERIFIED. PR 7 remains draft and canonical main remains cec10dc54. CI is 325/334 with the same nine failing names and five leaf anchors as the preceding runs; source, VR and audio checks pass.

## 2026-10-22: native CPU sampling and callback return gate

Both displays stay ON at internal 1280×800@60 and external 1920×1080@75. A native 99 Hz main-thread diagnostic saves 5,890 samples with zero loss. Saved PE image ranges map 42.65% to lua_shared.dll, 15.84% to client.dll, 10.66% to server.dll and 9.95% to engine.dll. These are module shares, not exact Lua-function, realm or GC attribution. Instrumented gameplay still fails: 21.212 FPS, p95 83.325 ms, p99 123.191 ms, longest drop 23.338 seconds. Sampling overhead is unmeasured.

The collector rejected the requested profiler SIGINT after flushing. Intact raw FPS was recovered before another launch; no post-capture CPU snapshot or display check is fabricated. The standard public jit.profile module is unavailable in both realms. No disabled API or native-module workaround was used. Failed startup harness attempts are preserved; their private bridge and stock menu edits are restored exactly. Native launcher command forwarding now resumes the paused failed-menu overlay, with actual client ACK and readiness gates.

A combined collision-callback prototype passes 6,400 return comparisons over 80 cases with zero mismatches and unchanged registrations. A predeclared fresh-game parent/candidate/candidate/parent 60-second screening comparison is running with no profiling or device sampler. Native collision flags/groups, AI, counts, normal resources and frozen actions remain. No source candidate or performance gain follows the value gate alone. [Raw evidence and limitations](STEAM_DECK_NATIVE_CPU_20261022.json).

Target UNMET; all six full acceptance scenarios UNVERIFIED. PR 7 remains draft; main remains cec10dc54. Finish the comparison, check complete receipts and restoration, then retain or reject on measured evidence before the next focused change.

## 2026-10-23: callback screening inconclusive; JIT capacity under measurement

Both displays remain ON at internal 1280×800@60 and external 1920×1080@75. Four fresh-game private callback arms complete: parent 21.559, candidate 22.881, candidate 22.914, parent 22.812 FPS. The arithmetic mean difference is +3.209%, but the final control nearly matches both candidates and control spread exceeds the mean difference. Do not retain a source gain from this screen. All captures fail the budget. Both leases restore original callbacks; all source, normal resource, physical-input, focus and display receipts complete. [Measurements and limits](STEAM_DECK_COLLISION_COALESCE_20261023.json).

End health differs (parents 188/191, candidates 211/211), without an established cause. The direct return matrix does not prove complete hook precedence, physical contacts or multiplayer correctness. The prepared source edits were never installed or committed; they are archived privately and the isolated worktree is clean. Mounted gameplay remains unchanged from 3cf2e875.

The public jit.opt.start API accepts maxtrace=32768 in both realms while reported optimization flags remain identical. No jit.on/off/flush or disabled reflection/profiler workaround is used. Stock numeric capacity is not publicly exposed; saturation or eviction is a hypothesis, not an observed cause. A predeclared fresh-process stock/32768/32768/stock D20 comparison is running with normal gameplay/settings and boundary-only counters. The first stock arm is 21.117 FPS, p95 85.610 ms: FAIL. No JIT configuration or gain is retained yet.

Target UNMET; all six full scenarios UNVERIFIED. PR 7 remains draft; canonical main remains cec10dc54. Finish the capacity comparison, inspect complete source/resource/input/display/flag and memory evidence, then retain or reject on measured effect and continue.

## 2026-10-23: cell-key component source candidate

A pure native prototype passes 12,864 key comparisons, including all 690 actual graph cells, signed zero, non-integers, strings, invalid inputs and concatenation metamethods. Six alternating 100,000-call measurements average 12.740 ms for the parent and 5.792 ms for the fixed component lookup. This is narrow prototype evidence, not installed-source or gameplay FPS proof.

The generator now borrows 255 fixed positive integer strings when the runtime uses unified numeric string representations. It retains original operands for zero and all uncached inputs; it stores no graph or actor state. The source manifest now covers the generator: 120 total / 116 server / 52 client. All affected count fixtures explicitly cover the new authority. Key contracts pass 28,062 cases on both Lua and standalone LuaJIT; existing transport, B28 replay/source, shared AI, route and entrance-safety gates pass. [Evidence and limitations](STEAM_DECK_CELL_KEYS_20261023.json).

Next: installed-source value/function receipt, then a fresh original-source parent/candidate/candidate/parent/parent/candidate D20 comparison with matching manifests. Both monitors remain ON at internal 1280×800@60 and external 1920×1080@75; normal graphics, AI, resources, population and frozen physical actions remain.

The JIT-capacity screen is complete with no useful effect (stock mean 20.930 FPS, requested32768 mean 20.913); reject the setting. The later instruction-hook diagnostic severely perturbs gameplay to about 1 FPS and misses capture-duration tolerance. Its hook interval was requested but not independently verified, and no sample/restoration file was collected before the owned process stopped. Do not use it for timing or coverage attribution; no hook survives process cleanup. No callback-coalescing or JIT candidate is retained.

Target UNMET; all six full scenarios UNVERIFIED. PR 7 remains draft; canonical main remains cec10dc54. Source candidate is pending native source/FPS verification and is not a completed performance claim.

## 2026-10-23: reject the cell-key source cache

Both monitors remain ON at internal 1280×800@60 and external 1920×1080@75. Controls21.539/21.033/22.529FPS average21.700; candidates21.446/20.664/19.703 average20.604 (arithmetic−5.05%). All six60s captures complete and fail. Ranges overlap; no general slowdown cause or statistical significance is claimed. The installed key function passes12,864 native comparisons and halves100k-call microcost, but that does not supply a gameplay gain. Reject the cache and restore the generator byte-exactly to1ce30e75. Keep28,062 behavior cases and source coverage120total/116server/52client. [Measurements and decision](STEAM_DECK_CELL_KEYS_20261023.json).

All source/function, normal resources/seeds/population, physical input, focus and display gates pass. End health156/201/160/206/211/211 varies without a demonstrated cause; structured ends60.452–61.420s include post-FPS time. Full fight phases and multiplayer behavior remain unverified. All owned games stop. Candidate43821d1a CI is325/334 with the same nine failing suite names and five file/line anchors as3cf; source, VR and audio pass. No full green claim.

Next: compare stock thread placement with mainCPU2/workers0,1,4,5,6,7, using actual2–3 SMT siblings and boundary-only counters. Earlier D1 all-threads-four-core masking had no benefit; this distinct experiment tests separating the main thread from its own workers, not a measured SMT cause. Preserve normal gameplay, graphics, power and both monitors.

Target UNMET; all six full acceptance scenarios UNVERIFIED. PR7 stays draft; canonical main remainscec10dc54. No key-cache, callback-coalescing, animation, player-query or JIT-setting candidate remains.

## 2026-10-23: reject main/worker thread placement

Both monitors stay ON at internal1280×800@60/external1920×1080@75. Four fresh D20 arms complete: stock21.344, separated22.525, separated20.065, stock21.398FPS. Stock mean21.371 versus candidate21.295 (−0.355% arithmetic) supplies no supported gain; reject the masks. Main CPU2 and worker0,1,4,5,6,7 masks remain exact over both candidate captures; actual siblings2–3 are verified. All owned games stop, clearing masks. Source/function, normal seeds/resources/population, physical input, focus and display gates pass. All four captures fail; end health153/211/154/163 varies without a demonstrated cause. [Full measurements](STEAM_DECK_THREAD_PLACEMENT_20261023.json).

Next: public jit.opt.start maxrecord16000 versus untouched stock, four fresh stock/candidate/candidate/stock60s arms. Native Lua module CPU/table-lookup evidence motivates a trace-length hypothesis; trace aborts and native default numeric limits are not observed. The prior maxtrace cache-count change had no benefit and stays rejected. Require both-realm API/unchanged-flag receipts, source proof and ordinary workload; no disabled API, JIT on/off/flush, profiling wrapper, affinity or active sampler. Boundary counters are uniform. No JIT setting is retained without measured benefit and regressions.

Cell-key runtime remains restored exactly to1ce30e75, with useful28062case tests and120/116/52sourcewatch coverage retained. Target UNMET; all six full scenarios UNVERIFIED. PR7 remains draft; canonical main stayscec10dc54.

## 2026-10-23: reject recorded-trace length setting

Four fresh D20 arms finish at22.073stock/22.252candidate/20.755candidate/20.883stockFPS. Means21.478stock and21.504candidate (+0.122% arithmetic) overlap without useful benefit. All captures fail. Public maxrecord16000 requests succeed in both realms with identical optimization flags; no JIT on/off/flush, disabled API, affinity, profiler or active sampler is used. Source, normal seeds/resources/population, physical input, focus and both-display gates pass. Both monitors stay ON at1280×800@60/external1920×1080@75. All four owned games stop, clearing the setting. Reject it. [Evidence](STEAM_DECK_JIT_RECORD_20261023.json).

Next: guarded reuse of the context already serviced by BeforeAI, with current owner/state/graph/seed/level/epoch/run, deadline, original-function and plain-table checks. The isolated candidate passes19cases/65assertions plus existing shared AI/B29 contracts; the exact parent fails its redundant-work gate. This is source preparation and operation evidence only, not a Deck gain. Keep public callbacks, admission decisions, fresh positions and normal service cadence. Native source verification and matched source FPS remain required.

Target UNMET; all six full scenarios UNVERIFIED. PR7 stays draft; canonical main remainscec10dc54. No JIT setting or affinity remains.

## 2026-10-23: guarded entry-context source candidate

BeforeAI currently services entry ownership, then Claim repeats Service and Context. Candidate extracts the same admission core and borrows the serviced context only while native function/C-clock identities, plain tables, current owner/state/graph/seed/level/epoch/run and future deadline match. Custom providers, metatables, inherited methods, clock changes and lifecycle/deadline changes keep public Claim. Admission results and actor positions are never cached; service cadence, quotas, movement and combat remain.

21cases/71assertions pass; the exact parent fails the redundant-work gate. Existing shared AI, B29 quotas/lifecycle/production coroutine/withdrawal/routes/freeze/UI and spatial/config/refresh gates pass. The selected42check checkpoint has38initial passes, three known parent failures and one missingNode failure; that manual-reader check passes after installing official checksum-verified Node24.22.1. No full green matrix is claimed. [Candidate scope and gates](STEAM_DECK_ENTRY_CONTEXT_20261023.json).

Next: verify actual source/function locations, native clock and metadata, then fixed fresh source P,C,C,P,P,C60s D20 runs. Both monitors remain ON at1280×800@60/external1920×1080@75; same normal resources, counts, AI, actions, graphics and power. No private wrappers/profilers/samplers during FPS. Keep or revert only on supported performance and regression evidence.

Target UNMET; all six full scenarios UNVERIFIED. PR7 stays draft; main remainscec10dc54. Both JIT settings, affinity, key-cache, animation and per-call player-query candidates remain rejected.

## 2026-10-23: first entry-source comparison mixed

Six fresh source runs complete: controls20.954/20.624/21.109FPS average20.896; candidates21.107/22.298/22.450 average21.952 (+5.053% arithmetic). Two candidates exceed the control range and one overlaps. Every capture fails. All three candidate longest drops below40 are longer than their paired controls; average p99 is similar. Do not retain a validated gain from this mixed first series. [All metrics/receipts](STEAM_DECK_ENTRY_CONTEXT_20261023.json).

Actual file CRC, four public function locations, nativeCclock/plain metadata, normal seeds/resources/population, physical input, focus and both-display gates pass. End health211/168/211/160/211/211 varies without a demonstrated cause. All owned games stop and the candidate is reinstalled while quit. CI74e8ec47 is325/334/source_changed0, with the same nine failing names and five file/line anchors as9d2/438/3cf; source, VR and audio pass.

Next: unchanged source/conditions in another fixed fresh P,C,C,P,P,C60s comparison to check repeatability and the pacing concern. Both monitors stay ON1280×800@60/external1920×1080@75; normal AI/resources/counts/actions/graphics/power remain. No active profiler/wrappers/device sampler/JIT setting/affinity. No source gain or full-scenario acceptance is claimed.

Target UNMET; all six full scenarios UNVERIFIED. PR7 remains draft; main stayscec10dc54.
