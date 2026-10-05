# Steam Deck wall-visibility repair — October 5, 2026

Author video and capture on clean main
`438c3d8114e932ddb7de6a6488048b9df8c1a6d4` show missing container wall surfaces.
All seven mounted renderer sources verify, so this is contradictory native
evidence against the batched candidate, not an inferred stale installation.
The [native receipt](STEAM_DECK_20261005_WALL_VISIBILITY_native.json) preserves
configuration, pacing, renderer states, resources and hashes of all supplied files.

The successful capture measured 1,529 active frames over 81.724601 seconds:
18.709 FPS, median 42.525 ms, p95 113.06 ms, p99 178.2 ms, maximum 263.743 ms.
It requested 180 seconds but ended at shutdown. At sample start batching was
ready: 110 chunks, 1,448 hidden originals and 1,859,232 uploaded vertices.
End-of-capture off/zero counters are cleanup, not proof of inactive batching
during play. Both observed visibility and performance fail acceptance.

No recorded Lua/upload/draw exception identifies the precise native missing-face
cause. The bundled stock model has one static bone with identity bind transform,
one mesh and three material/skin entries. Bounds and triangle-count checks alone
do not prove visible surfaces. Do not claim a guessed bone, winding or camera
change repaired the demonstrated native failure.

## Implementation

- Reduced Effects retains native wall models by default. Its route caching,
  floor/box/render caches, overlay culling and other existing savings remain.
- Replacement batching requires explicit `lod_wall_batches 1` and Reduced
  Effects. The new switch defaults to zero and is not archived across restarts.
  Opt-out/refresh/map cleanup restores all original models and frees each mesh.
- The experimental draw owns an identity model matrix for world-space vertices,
  balances that matrix on errors, and restores every native wall after an IMesh
  draw exception. It stays in fallback until an explicit reset, avoiding repeated
  uploads of the same failing geometry. These are defensive native-boundary
  repairs, not a claim that the exact missing-face cause is established.
- Capture records the new preference and one live renderer snapshot per existing
  five-second window, even outside active play. Native mode starts normally
  without a batch-preparation delay; teardown cannot erase the renderer history.

Geometry, two-container stacks, UVs, section palette, overlays, collision,
population, game rules and audio are unchanged. The live GDD identity remains
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, navigated through 00/01 and
07 for the author-directed engineering mandate. No live GDD edit is needed.

## Finite gate

Focused regressions exercise native visibility with Reduced Effects alone,
explicit experimental activation/deactivation, an inherited entity transform,
draw exceptions after successful uploads, restoration of every original,
balanced matrices, zero repeated uploads after failure, native capture readiness
and live renderer evidence surviving shutdown. Existing hull/UV/tint, resource,
palette, population, lifecycle and complete system regressions remain required.

The complete frozen gate passed **307/307** suites and **877** Lua syntax checks.
All 307 stdout/stderr hashes were verified; no file changed during the gate.
The validated production and test bytes are unchanged by the publication's
documentation/evidence additions. Source validation is separate from native
visual and sustained-FPS acceptance.

Evidence: [matrix receipt](STEAM_DECK_20261005_WALL_VISIBILITY_matrix.json),
[production manifest](STEAM_DECK_20261005_WALL_VISIBILITY_production.json),
[proof](STEAM_DECK_20261005_WALL_VISIBILITY_proof.json), and
[complete logs/source manifest](STEAM_DECK_20261005_WALL_VISIBILITY_gate_logs.tar.gz).
The [interrupted first attempt](STEAM_DECK_20261005_WALL_VISIBILITY_interrupted.json)
is preserved separately: documentation was written after its whole-tree freeze
started, so it was stopped and restarted. It is not a complete/frozen pass.

## One native check

Fully quit GMod, then update/install main using the established checkout:

~~~bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin main && git switch main && git pull --ff-only origin main && bash tools/install_dev.sh
~~~

Start the same Proton/windowed Arch Desktop configuration on gm_flatgrass,
deploy, and run:

~~~text
lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180
~~~

Move through corridors and turn past the affected walls; bodies should remain
visible. Keep the same resolution, graphics settings and loaded population.
Return performance_client_latest.txt + console_latest.txt. If surfaces still
disappear, include a short video. Population status is included automatically.

Native visual acceptance and the sustained >=40 FPS target remain open. Do not
promote experimental batches, publish Workshop or deploy VPS from source checks.
