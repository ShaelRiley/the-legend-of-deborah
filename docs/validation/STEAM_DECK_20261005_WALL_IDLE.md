# Native wall appearance quiescence — October 5, 2026

The author accepts native wall visibility on clean main
`6dc145db623fcd7643e3c1a4519ec9f0f2009dfa`: "Walls look good again."
The [new native receipt](STEAM_DECK_20261005_WALL_IDLE_native.json) preserves
the supplied file hashes, exact-source verification, renderer windows, resource
counts, pacing and configuration. Replacement batches are off and no originals
are hidden throughout the live windows. This accepts the native visibility
repair, not the experimental batching path or the FPS target.

The capture requested 180 seconds and ended at shutdown after 49.77 seconds,
with 572 active frames / 41.797669 seconds = 13.685 FPS, median 68.93 ms,
p95 137.926 ms and maximum 1,724.128 ms. Seven full active windows, excluding
deployment and the last partial window, remain around 8.5–13.4 FPS. It contains
1,868 wall models and 3,171–3,312 client entities; the previous batched capture
had 1,448 walls and a different generated maze. No controlled before/after FPS
comparison is claimed. Both renderer and server population sources verify;
there are no recorded Lua errors and settings do not change.

## Demonstrated waste and bounded repair

The section reconciler's application counter rises from 32,640 to 138,048 during
this short capture: 105,408 extra applications. Its completion remains false.
The native material getter reports an empty override despite successful setter
calls. The previous code treated this readback as perpetual invalidation and
also rewrote skin/color while reconciling. This proves redundant work, without
establishing how much of the total frame time it caused.

The existing sole appearance owner now caches its exact client model and an
invalidation token. It applies the same material, clears stale submaterials and
sets the same white modulation/skin zero once per owner/lifetime. Ownership is
recorded only after every setter returns. World/count/palette/model-owner/mode
changes and Lua refresh create a fresh token, even if a material name is equal.
The existing <=192-model batch and two stable passes remain unchanged. Getter
readback remains available to explicit diagnostics; completion means the owner
finished its writes, not that the engine acknowledged them or FPS was accepted.

Native wall rendering stays enabled. Geometry, collision, palette, materials,
stack count, brand/stencil placement, population, rules and audio are unchanged.
The current live GDD remains `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
using the already-read 00/01/07 route and the author-directed engineering mandate.
No new tuning value or live design amendment is required.

## Finite source and native gates

The regression reproduces 1,868 models whose material AND color getters never
acknowledge successful setters. Each receives every native setter once, then
600 steady ticks perform zero appearance writes. Explicit same-mode resets,
model-owner changes and Lua refresh reapply all setters. Existing world/count/
seed, palette fingerprint, candidate failure/recovery, mesh fallback and native
default regressions remain. The [negative control](STEAM_DECK_20261005_WALL_IDLE_negative_control.json)
fails against parent main because it never becomes idle; the repaired source
passes. These counts are not a target-hardware FPS measurement.

The complete frozen gate passed **307/307** suites and **877** Lua syntax checks;
all stdout/stderr hashes verify and the test tree remained unchanged. Publication
retains these exact production/test bytes and appends only documentation/evidence.
See [matrix](STEAM_DECK_20261005_WALL_IDLE_matrix.json),
[production manifest](STEAM_DECK_20261005_WALL_IDLE_production.json),
[proof](STEAM_DECK_20261005_WALL_IDLE_proof.json) and
[complete gate logs](STEAM_DECK_20261005_WALL_IDLE_gate_logs.tar.gz).

The prior ambient audio CI job was cancelled before any step ran and had no
retrievable job log; its failed-job retry completed successfully. All four parent
CI checks now pass, and the current local audio-only gate passes. There is no
demonstrated audio-code regression. These checks are separate from native FPS.

Fully quit/update/install main using the established command, then deploy on
gm_flatgrass and run `lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180`.
Keep the same Proton/windowed Arch Desktop configuration, graphics settings and
loaded population. Verify visible wall bodies and inspect live section counters:
after setup they should become complete and stop accumulating applications.
Return performance_client_latest.txt + console_latest.txt. The capture already
includes population status. No additional manual setup or separate population
file is needed. Native FPS acceptance and the >=40 FPS target remain open.
Workshop/VPS remain outside this source checkpoint.

## Subsequent native observation

The October 5, 19:20 Chicago submission runs clean f657913. All 1,364 native wall
models are complete before sampling; applications stay at 1,364 in all 19 live
windows, with no retries and no hidden originals. This passes the finite native
quiescence gate. The author reports that performance improved but needs more
work. Active throughput is 28.96 FPS over 92.95 seconds, p95 56.397 ms, on a
smaller maze than the earlier 1,868-wall capture; it is not a controlled FPS
comparison or 40 FPS acceptance. See [preserved native receipt](STEAM_DECK_20261005_OVERLAYS_native.json).

Four parent CI workflows pass. Complete-matrix run 37377319992 instead fails
the installer test's temporary cleanup with `Directory not empty` before its
full matrix starts. This does not erase the frozen local 307-suite pass above.
The subsequent overlay checkpoint repairs the demonstrated test-child lifetime.
