# Steam Deck — exact plane-support reuse

This checkpoint reuses direction-dependent culling arithmetic while keeping
camera and entity values live. All **300 published-parent/candidate render-pass
traces match**. In 240 warmed passes, repeated plane/support absolute-value
operations fall **111,600→0**, with every native geometry query and submission
retained. Hardware FPS benefit is unmeasured. The latest installed-parent
capture averages **26.7192 active FPS**; sustained >=40 FPS remains unmet.

The baseline is main `30d180fdb07da51001e3f029c72ff05e8deaa7c2`, tree
`b0c8b44d3ce2b51ca84fe1755779a64c366abd9b`. Fresh live GDD 00 → 01 → 05/07,
revision `AHj4eMRd4acJKKEDgqukO9zGvoMQvxlbUMdF6nZCAXYFhQm-CNvzGIub5PLIO_oXk6fEWbrk_V-_2bJc4m1wqQvkXjzdDNhY5wQfHSd7Pg`,
governs this implementation-only work. No design or tuning value changes.

The October 8 UTC/local capture verifies clean `30d180f`, all 15 client and
46 population hashes, complete 180-second profiles, fixed preferences, fully
idle VR and zero Lua errors. It records 4,452 active frames over 166.621711
seconds, median 32.779 ms, p95 63.844 ms and p99 108.667 ms. The scene starts
with 1,338 native walls and 40 bodies / 36 living wanderers, versus 1,284 walls
and 36 bodies previously. This difference prevents isolated attribution of
FPS or portrait-time changes to the preceding HUD optimization.

Generated geometry averages 1.88920 ms per recorded hook invocation / 100.3602
CPU ms per recorded second. Portrait paint averages 0.82868 ms versus 0.94064
previously. Timings are inclusive, overlapping, include profiler overhead and
do not measure GPU time or distinguish included/excluded hook flags. Console
evidence records 12,339 sanctuary admission denials and a deployed Hero; it
does not accept every admission branch. Four duplicated material `$flags`
warnings remain distinct from the zero recorded Lua errors.

The existing static renderer now retains immutable plane coefficients only
while all current basis/projection scalars match exactly. Each existing box
snapshot retains at most five plane/value pairs. A geometry/pose/refresh change
replaces that snapshot; changed view coefficients replace the plane identities.
The camera eye, entity bounds and pose are still queried every pass. Visibility
is recomputed from live positions; no visibility result, rounded key or TTL is
cached. Nested views retain their own immutable coefficients. Culling math,
evaluation order, tolerance, meshes, UVs, colors, wireframes, fallback, native
walls, collision, population, gameplay and saved graphics settings are unchanged.
Experimental wall batching stays disabled.

The production-backed probe loads the exact parent/candidate renderer, mesh
authority and shared entity declarations. It records full-precision native
mesh, wireframe and fallback values across translating cameras, orientation,
FOV/aspect, mutable/replaced bounds/pose, live accessor overrides, hazards/grates,
kind/life, full update/transmission, incomplete/nested views, refresh and removal.
Trace SHA-256:
`bd7532831b3d2a97349e8f9cb1ffa71eb8830c106807117dbf9d4a5b02e318b7`.

| Work across 240 warmed passes / 120 boxes, 30 rotated | Parent | Candidate |
| --- | ---: | ---: |
| Plane/support absolute-value operations | 111,600 | 0 |
| Native geometry getters | 115,200 | 115,200 |
| Current camera-basis component reads | 2,160 | 2,160 |
| Native mesh submissions | 28,800 | 28,800 |
| Native wireframe submissions | 9,600 | 9,600 |

The exact parent fails the new work bound. The existing independent 173
visible-corner and 73 conservative-plane oracle cases remain green. These
counts measure eliminated headless arithmetic, not native elapsed time or FPS.
Three preliminary fixture failures concerned class initialization, independent
eye APIs and restoring outer state in nested views; they are preserved and
contribute no accepted results.

The frozen final source passes **29/29 focused checks, 314/314 canonical suites and 885 Lua parses**. All 2,566 source files remain unchanged during both gates. Every canonical and focused command/receipt and all 628 matrix stream hashes plus 29 focused log hashes are independently checked. Only documentation/evidence packaging follows; both changed code/test hashes are rechecked before publication. The adjacent checks JSON and ZIP preserve raw native uploads, fresh live normalized GDD tabs, exact parent/candidate sources, paired traces/work counts, the expected failing parent work gate, all three fixture failures, complete full/focused commands, receipts, raw streams and source manifests. No failed fixture contributes accepted results.


Fully quit GMod, update/install main, restart gm_flatgrass and use:

```bash
cd ~/Downloads/the-legend-of-deborah && git pull --ff-only origin main && bash tools/install_dev.sh
```

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile
```

Leave the game open through the final server reply. Return
performance_client_latest.txt and console_latest.txt. Require verified final
source, complete profiles, idle VR, no new Lua errors, unchanged floors, stairs,
grates, hazards, walls and overlays, intact gameplay and sustained >=40 FPS.
Native acceptance remains open. No Workshop or VPS action is included.
