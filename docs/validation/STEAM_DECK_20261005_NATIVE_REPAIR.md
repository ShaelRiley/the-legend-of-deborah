# Steam Deck native capture repair — October 5, 2026

## Observed failure

The supplied performance and console files identify source
8fa634426d3fd1bf9f8dd8028866a24622488bad. The six mounted renderer source checks
passed with zero missing or mismatched files. The requested 180-second capture
ended with reason renderer-timeout, zero all/active frame samples, and wall batch
status off: 1,542 native wall models, zero batched vertices/chunks/hidden models.
This is an unmeasured FPS result; zero frames must not be reported as zero FPS.
The old elapsed/wait fields also failed to distinguish preparation from sampling.

Recorded engine settings: 1280x800, Windows x64 LuaJIT 2.1.0-beta3 through Proton,
engine 2026.09.17, fps_max 60, mat_vsync 0, mat_dxlevel 95, mat_queue_mode -2,
mat_antialias 0, mat_hdr_level 2, mat_picmip 0, r_shadows 1 and viewport scale 1.
The engine cannot identify the Proton release or window mode.

The console contains nine population records, proving the existing observer ran.
Each long JSON line reaches 4,095 characters and is truncated in its source-module
list. The user could not find population_latest.txt. The precise reason the
server DATA file was unavailable is unconfirmed; the prior observer neither
verified persistence nor mirrored its records to the client. The native workload
included developer-dense population (roughly 59–64 living actors and 20 roaming
actors per floor); this repair does not reduce that workload.

The exact native cause of material reconciliation remaining unready is not
established. Source inspection demonstrates an unnecessary batching prerequisite
and two appearance writers, rather than proving which native operation stalled.

## Canonical repairs

- The existing section material owner exposes its chosen validated sampler to
  the existing mesh compiler. Compiling exact stock hulls no longer waits for
  native material setters to settle. Construction/retry guards, stock bounds,
  geometry/UV/tint transforms, fallback visibility and resource limits remain.
- Wayfinding keeps sparse physical mark placement and stencil rendering. The
  section material owner alone writes skin, material and body/stencil tints.
- The opt-in capture waits at most 30 seconds for preparation, then warms up for
  three seconds and records the requested period even if batching remains blocked.
  It preserves preparation status, actual wait, material cursor/retries, registered
  hook bindings and Think-call counters. An actual no-render timeout stays bounded
  at 120 seconds and reports no measured FPS.
- Starting a capture requests one snapshot from the existing server census. The
  full snapshot is mirrored to client population_latest.txt and embedded in the
  performance report. Admin-only requests are limited to one per two seconds and
  60,000 payload bytes. This adds no census, polling timer, spawning or RNG changes.
- Both DATA writers verify persistence and contain throwing/silent failures.
  Console summaries omit the long module hash list and remain complete JSON below
  the observed line ceiling; full source detail remains in DATA and the transport.
  The installer/server manifest now covers 41 files; the client renderer verifies
  seven, including the former competing wayfinding owner.

## Finite source gate

The complete integration matrix retains all 306 previous suites and adds the
population transport suite. Relevant production regressions cover 1,542 models
whose native overrides never settle; exact stock geometry and conservative
fallback; preparation blocked for 30 seconds followed by measured rendered
frames; true no-render timeout; valid bounded console summaries; source caching;
admin/rate/map/payload bounds; malformed packets; and silent/throwing disk failure.
These are headless/native-boundary checks, not Steam Deck measurements.

The complete frozen gate passed **307/307** suites and **877** Lua syntax checks
on candidate 94e5a4d80362b9212aa1f985891284afe585ed5f, tree
5800548c1ab3839701599ecc362ccc797055d0d2. All 307 stdout/stderr log hashes were
verified by the runner. No source file changed during the gate (2,461 files;
before/after digest 948b2b3e7cd89c16f46dbf234ec088c6e372e445199e656ff094a3be0bfb0f22).

The 562-production-Lua digest is
7846ec6c115930b88863a6f42c8ea579b83afbe8c5bc952218b54a1905cd9b48.
Receipt SHA256 is 467b557aab890f40814f81ac3f67809950288e1fb86796c15c2c28903df9dbe6.
The receipt bytes and modified module hashes were independently checked after
retrieval. Evidence: [complete matrix](STEAM_DECK_20261005_NATIVE_REPAIR_matrix.json),
[production manifest](STEAM_DECK_20261005_NATIVE_REPAIR_production.json),
[proof and preserved failed attempts](STEAM_DECK_20261005_NATIVE_REPAIR_proof.json),
and [runner logs/artifact](https://github.com/ShaelRiley/the-legend-of-deborah/actions/runs/37342766921).

Preserved failures: the first focused run omitted a native concommand fixture
boundary; the next full run passed 306/307 but lacked NumPy for the existing stock
hull asset validator. Neither is a full pass. The corrected dependency run above
is the complete gate. Exported stock metadata confirms one mesh and three skin/
material entries; no speculative multi-mesh or guessed geometry rewrite was made.

The live GDD identity remains
1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY, navigated through 00 — AI ENTRYPOINT,
01 — AI RULE INDEX and 07 — IMPLEMENTATION & TUNING for this engineering mandate.
Game law and earlier native acceptance debts remain unchanged. The local command
runner was offline, so this gate executed the exact immutable candidate through
a validation-only workflow on main, without a development branch. The resulting
source publication adds only documentation/receipts to this validated production.
All native acceptance remains open.

## One native retest

Fully quit Garry's Mod, then update/install the canonical main checkout:

~~~bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin main && git switch main && git pull --ff-only origin main && bash tools/install_dev.sh
~~~

Start the same Proton/windowed Arch Desktop configuration and graphics settings
on gm_flatgrass, deploy normally, and run this one console batch:

~~~text
lod_reduced_effects 1; lod_perf_start 180
~~~

Play through combat, gate progression and a boss during the capture. Return
performance_client_latest.txt and console_latest.txt from the already established
data folder. The performance file carries population evidence/status automatically;
finding a separate population file is not a prerequisite. Preserve resolution,
graphics settings, population, original geometry and safety/progression behavior.

40 FPS target: native validation pending. Source publication is authorized;
Workshop publication and VPS deployment remain outside this work.
