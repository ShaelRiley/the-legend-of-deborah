# Steam Deck performance implementation — October 5, 2026

Baseline: verified remote main `c8a6ad9233e78cfddb72cb046d3f947d6234a1a5`.
Target: sustained >=40 FPS / normal frame times <=25 ms on Proton in a window
under Arch Linux Desktop mode. The author's ~15 FPS baseline is reported, not
independently measured. No target client, Proton or native GMod binary is available
in this implementation environment. Source checks cannot certify target FPS.

Live design navigation: GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 -> 01 -> 07, LOD-IMPL-001/004 and tuning permission. The current explicit
mandate and source plan preserve music extraction despite older GDD music rows.
No combat timing, density, encounter budget, damage, resource or game rule changes.

## Checkpoint 1 — sanctuary route caching

Ordinary hostile routing allocated a fresh identical sanctuary predicate for every
request, sending every route through uncached BFS. `FindHostilePath` now shares
the canonical graph-owned predicate in the existing cache. Both tree modes compete
within the original 72-tree total. Arbitrary/actor-specific predicates remain live
and uncached; shortest-path tie order is identical to start-rooted legacy BFS.

Production Lua with doubled native boundaries: 9,072 exact path comparisons pass.
The same 1,920 requests on a 21x21 cyclic graph perform 749,190 -> 28,224 predicate
visits (96.2% fewer). One container run took 2.125 -> 0.059 Lua seconds; this is a
synthetic workload, not native FPS or a claim of the real game's dominant cost.
The exact graph/cells/filter replacement, gates, event blocks, unknown cells,
combined cap and arbitrary mutable predicate cases pass. Existing quantized routes,
B29 dispatch/sanctuary and gate-enemy-engagement regressions pass.

Checkpoint 1 was published as `9f89d527295ece0d3187c1426279b926b968eec2`.
Its stable-source result did not cover mixed sources. A subsequent paired probe
interleaved 64 home-distance sources with 64 moving-position route sources:
the original baseline took 1.166 seconds / 65 general tree builds, while the
shared-tree candidate took 1.854 seconds / 3,841 total tree builds. The common
72-tree FIFO thrashed. This contradictory evidence is retained, and the final
candidate supersedes that implementation below. None of these times are FPS.

## Checkpoint 2 — bounded routes, container batches and frame evidence

### Implemented behavior

- `FindHostilePath` now retains at most 72 completed route results in the same
  graph-owned navigation cache. Existing general trees keep their 72-entry
  capacity. Misses preserve legacy early-exit BFS and sorted ties while reusing
  cached neighbors and one invalidation context. Returned arrays are copies;
  arbitrary mutable predicates remain uncached. Gate/event/sanctuary/graph/filter
  replacement invalidates both. This additional compact path budget is an
  implementation resource choice under the explicit performance mandate.
- Existing saved `lod_reduced_effects 1` batches LOD-0 triangles from the mounted
  stock cargo model in 4x4-cell, floor/stack/material chunks. Positions, yaw, UVs
  and section tint remain; diffuse UnlitGeneric replaces model bump lighting.
  Sprays, signs, gate warnings and branding retain their existing owners. No
  server entity, collision, navigation, enemy, physics or progression is removed.
  `lod_reduced_effects 0` restores native container model rendering.
- At most one mesh upload occurs per Think, including failed uploads. Each mesh
  has at most 60,000 vertices; at most 512 chunks / 4,000,000 total vertices are
  reserved. Excess, pending or failed chunks retain visible native models.
  Missing/changed stock mesh bounds or diffuse assets fail back to native models.
  These resource bounds and four-cell tiles are implementation choices, not
  changes to authored world density. Unknown views fail open; normal views use
  current-pass sphere/frustum culling without distance/floor/occlusion guesses.
- Appearance/world/preferences/map/shutdown/refresh destroy obsolete meshes and
  restore native models. Two shared diffuse shader slots survive Lua refresh
  with their texture identity; no per-container shader is introduced.
- Invisible collision-only static boxes skip per-pass visibility/bounds/transform
  work. Bounds setters run only on actual change or transmission/full-update
  recovery. Collision and data-table recovery remain unchanged.
- `lod_perf_start [seconds]` (default 180, bounded 30–300) temporarily samples
  SysTime intervals between rendered PreRender calls. It automatically excludes
  wall preparation and three seconds of warmup, keeps all frames separately from
  deployed/alive/no-menu/no-cinematic frames, and records median/p95/p99/max,
  >25/50/100ms counts and dense five-second pacing windows. At most 65,536 samples
  are retained. No idle frame hook or per-frame disk work is added. Timeout,
  restart, stop, shutdown, refresh and disk-error cleanup are tested.
- The capture records actual viewport/settings/runtime and beginning/end resource
  snapshots. It verifies six client rendering sources against actual mounted
  file hashes; the installer/server manifest expands from 34 to 40 files.
  Engine output cannot expose Proton version/window mode or process/GPU memory;
  those remain explicitly unknown/user-recorded. Lua KB is not process memory.

### Evidence and limits

Production Lua with doubled native boundaries passes 9,072 exact sanctuary path
comparisons, deterministic cyclic ties, mutable generic filters, unreachable
results, invalidation, caller mutation, independent bounds and continuous misses.
The repeated 1,920 requests now perform 749,190 -> 24,973 filter visits (96.7%
fewer). The mixed home/roaming workload performs 514,200 -> 17,140 visits (96.7%
fewer), with 64 home-tree builds in both versions. One container run took
1.114 -> 0.047 Lua seconds for that mixed workload. Timings are synthetic and
host/load-dependent; work counts are the stronger evidence.

The renderer harness submits the same 600 synthetic stock-sized instances in
95 chunks instead of 600 model submissions (84.2% fewer), retaining 256,800
triangles. A detailed eight-instance oracle checks every transformed vertex, UV,
normal, tangent and tint. Upload-failure, texture-order refresh, resource ceilings,
invalid views, culling and lifecycle gates pass. This is an operation-count
comparison, not a native GPU measurement; the mounted model is checked at runtime.

The capture harness deliberately injects 120ms hitches into 25ms frames and
records ~37.14 FPS with p95=25ms/p99=120ms rather than declaring success. Staging,
death/menu exclusion, settings/source mismatch, setup timeout, limits, no per-frame
I/O and cleanup are covered. Earlier targeted full-update/upload failures were
repaired before publication. Audio extraction and ambient/cue regressions pass.

The first full matrix passed 306/306 with no source changes, then the mixed-cache
probe required the refinement above. The final frozen-source matrix also passes
**306/306**, including syntax for 876 Lua files, with zero changes during the gate.
All 306 stdout/stderr hashes and the post-gate source snapshot were independently
checked before recording the receipts. Full tested-source snapshot digest:
`fe83bb10f814145da74c7657e6acef33515c75c48bc3d791d9ca3ca3eb2a1aee`.

The 562 production Lua files have digest
`6fb47e6def126afa5fbbfbda7d20aec18d8ab6b36706b900e386d108f88ad8eb`;
only evidence/documentation is added after the frozen matrix. See
[final matrix receipt](STEAM_DECK_20261005_matrix.json),
[earlier matrix receipt](STEAM_DECK_20261005_prior_matrix.json),
[production file hashes](STEAM_DECK_20261005_production.json) and
[targeted output](STEAM_DECK_20261005_targeted.txt). The earlier shared-tree
candidate's mixed-workload regression is retained above, not treated as a native
success. The low-end source tests also run independently on push in GitHub Actions.

No Steam Deck/Proton/GMod client, GPU frame timings, power/thermal data or native
loaded-play measurements are available here. Suspected remaining costs include
native entity/physics/animation work, server simulation and GPU/material work
outside container hulls. Their relative contribution is unmeasured. Compare the
loaded capture first; do not infer a dominant cost from these synthetic results.

### One minimal native action

Fully quit GMod, then in the existing checkout run:

```bash
cd ~/Downloads/the-legend-of-deborah
git fetch origin main
git switch main
git pull --ff-only origin main
bash tools/install_dev.sh
```

Start the updated Legend of Deborah on `gm_flatgrass`, using the same Proton
version, windowed Arch Linux Desktop mode, resolution, graphics settings, sync
and frame limits as the reported baseline. Deploy and paste one console batch:

```text
lod_reduced_effects 1; lod_perf_start 180
```

Continue loaded play for three minutes through dense combat, gate opening and
boss activity where reached. Setup/warmup is excluded automatically; keep menus
brief. Do not lower resolution/graphics settings during the capture. The log
reports wall fallback if batching cannot be used, source mismatch, configuration
changes and active time; a short/inactive or unstable-settings capture is not
acceptance. Record the Proton version and confirm windowed Desktop mode when
returning evidence. The capture preserves the saved Reduced Effects setting.

Return `performance_client_latest.txt`, `console_latest.txt` and the existing
`population_latest.txt` from:

```text
/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/
```

The five-second windows must show sustained >=40 FPS during representative active
play with normal frames around <=25ms and materially improved pacing, rather than
an average hiding repeated collapses. Later loaded-play/resource trend acceptance
remains open. An optional same-route repeat at `lod_reduced_effects 0` isolates the
preset's rendering gain; it is not required for the one next native action.

40 FPS target: native validation pending. Workshop and VPS are untouched.
