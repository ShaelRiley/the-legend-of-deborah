# Player Options and bounded map presentation work

Parent main: `bed0d45645a082583a5b42d92617742355fb3fce`. All four parent
Actions workflows pass. The author scope is in
[the brief](../briefs/PLAYER_OPTIONS_20261007.md) and its exact GDD amendment receipt.

## Latest native evidence

The new complete three-minute gm_flatgrass capture runs clean
`00dd5ea74c4df55bc013fe4a5d94cc273a151c8d`. All 44 installed/mounted population
module hashes are independently compared with that exact Git commit; ten
client rendering sources verify. Idle VR passes in all 42 snapshots, with
139 addon sources and two bridges verified and zero players, runtime hooks,
recurring timers, method overrides, pending work or native resources. Client
and server report zero Lua errors.

Active gameplay averages **17.0759 FPS** over 163.9157 seconds and 2,799 frames;
median 48.249 ms, p95 108.677 ms, p99 153.849 ms and maximum 487.797 ms.
There are 1,684 wall models and 64 living wanderers; the separate encounter
plan reports 43 planned bodies. Configuration stays unchanged at 1280×800,
native walls (`lod_wall_batches 0`), Reduced Effects 1 and the established
Proton/windowed graphics settings. This run precedes the parent safety-coordinate
optimization and these new options. It cannot establish their native benefit
or a controlled regression against earlier captures with different workloads.

Client generated static geometry remains the largest measured custom rendering
callback at 103.183 ms/second; server EntrySafety.BeforeAI is 51.558 ms/second
and EnemyRoster.TickCloseDefense 50.846 ms/second. Measurements are nested
inclusive wall-clock time, overlap and omit GPU/engine attribution; do not add
them into a total. Sustained >=40 FPS remains unmet.

## Finite source gate

Execute the actual Options, saved preference, camera, map and quadrant sources
through engine-boundary doubles. Require six unique saved UI bindings, native
slider ranges, wrapped/scrolled 1280×800 and 640×480 bounds, no writes when
opening Options and retained minigame lock. Camera checks retain native base
view/weapon FOV/clipping, reuse placement, stop at obstructions and inside
solids, yield to every existing special view, resume afterward and produce no
camera trace or geometry allocation while disabled. Movement regressions remain.

Map checks cover 81 combinations of window, requested scale, opacity and
expanded grid width. Require panel/text/marker/quadrant alignment and multiplied
alpha, unchanged access/Q/M/VR input and Magic expiry, cached Matrix identity,
no presentation-driven topology rebuild/transfer, and restoration of drawing
state after ordinary, loading/preparation and deliberately throwing callbacks.
The exact parent quadrant callback must fail the new presentation gate.

Paired warmed 10,000-draw callbacks retain 90,000 exact default drawing
submissions. Compare Lua allocation while collection is paused; the parent
allocates about 10,859.472 KiB and the candidate about 1.503 KiB. The removed
rectangle records, shared transform and fixed fallback color reduce recurring
map allocation. This is headless Lua allocation, not native memory or FPS.

The complete frozen repository matrix, Lua syntax pass, installer source
manifest and booklet regeneration must pass with unchanged production/test
source before publication. Preserve every command, individual receipt, raw
stdout/stderr, source manifest, paired/negative-control output and original
native capture. Native visual/camera and FPS acceptance are separate.

## Next native gate

Fully quit GMod, update/install published main and restart on gm_flatgrass.
Open Player Menu → Options and try third person plus both map slider endpoints;
check nearby walls, aiming/zoom, overlay alignment and saved settings after
reopening. Return to first person and the usual map size/opacity for the
comparable capture. Run this single console batch:

`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`

Play three minutes in the established configuration and keep GMod open through
the final server reply. Return performance_client_latest.txt and console_latest.txt.
Require 14 exact client presentation sources, the retained 44 population
sources, complete client/server profiles, idle VR, unchanged safety/population
and zero new Lua errors. No Workshop or VPS operation is included.


## Completed frozen source gate

The complete matrix passes **313/313 suites and 884 Lua syntax
files**. Every canonical command, individual receipt and all 626 raw stream
hashes are independently checked. Source digest `42654d55253e2e30f8f87e4ad33d2bad753f5872f98d165201951f85e8bfe7dc`
covers 2,545 files with zero changes during the gate. Movement,
camera/Options, map input/caches/Magic, booklet, opt-in profile transport,
installer, population/AI/safety, lifecycle and existing VR regressions pass.
The Options camera/movement gate passes 4,768 assertions; the map gate covers
81 combined scenarios. No duplicate matrix suite is added.

The exact parent negative control fails at transparent-map painting; the
candidate passes. The paired 10,000-callback probe preserves 90,000 identical
default submissions and records 10,859.472 KiB versus
1.503 KiB Lua allocation. Timings in this doubled headless
environment are retained as raw evidence and are not native FPS claims.

The interrupted first inspection is preserved: its CPU-profile fixture still
listed the previous ten client sources. Extending that fixture to the same
fourteen sources passes the focused gate and this complete frozen rerun.
Only coordination/evidence files are finalized afterward; all production,
booklet and test bytes retain their tested hashes. Native visual/camera and
sustained >=40 FPS acceptance remain open.


The [independent verification receipt](PLAYER_OPTIONS_20261007_checks.json) and
[complete raw evidence](PLAYER_OPTIONS_20261007_complete.zip) retain the source
manifest, all 313 command receipts and stdout/stderr, the interrupted inspection,
paired/negative-control proof, exact parent/candidate sources, author amendment,
baseline CI and original native uploads. Archive: 2,040,412 bytes;
SHA256 `3942fd038e71806d83bd3b049b91de9a891b19407c2f00fc6230fb574639af1e`.
