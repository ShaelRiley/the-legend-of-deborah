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

40 FPS target: native validation pending. Workshop and VPS are untouched.
