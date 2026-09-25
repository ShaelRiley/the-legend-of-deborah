# P1 — exact-output branding placement optimization

Baseline: fetched clean main `eb319079f7e1b494851300e3465792cba88b5f2c`.
Live GDD00→01→05/07: existing Crate selection/resource and deterministic rules;
no design, tuning, asset, geometry or rendering contract changes.

Finite gate fixed before editing: preserve exact selected container indices,
company identity, coverage, eligibility/wayfinding exclusion, physical no-touching,
40% placement cap, 64-draw cap and lazy two-slot ceiling on fixed representative
and dense deterministic manifests. Optimize one measured bottleneck only.

The headless fixture runs the real maze generator, server wall manifest compiler,
client wall metadata compiler and production rebuild hook. Native collision/model
allocation is doubled and outside timing. Seed7719 uses normal occupancy (3 floors);
15438/23157 force the rare fourth floor and configured occupancy upper bounds,
without changing production configuration. A fixed every17th-instance wayfinding
mask exercises exclusions; this is not native wayfinding projection.

Initial instruction sampling at every1000 Lua VM instructions put repeated
floorDistanceSquared/minChosenDistanceSquared scans first (representative333172
and145132 samples, versus107172 in RNG hashing). Each eligible candidate rescanned
all previous choices on every choice: unnecessary cubic work. Cache its exact
nearest distance and compare only the latest choice. Choices and conflicts only
grow, so every still-eligible candidate has observed all prior choices. The cache
is per rebuild and discarded with candidate tables; no cross-seed resources.
Only this bottleneck changes; repeated deterministic-noise hashing remains.

Sequential same-host Lua5.4 CPU timings, one warmup then median of three rebuilds,
GC collected before each, profiling hook disabled for timed runs:

| Manifest | Containers | Before ms | After ms | Reduction |
| --- | ---: | ---: | ---: | ---: |
| representative7719 | 1800 | 2877.285 | 1024.585 | 64.4% |
| dense15438 | 1896 | 2803.493 | 1020.054 | 63.6% |
| dense successor23157 | 1978 | 2702.052 | 1048.485 | 61.2% |

Raw min/median/max and unchanged cached-hook costs: CRATE_PLACEMENT_P1_BEFORE.log
and CRATE_PLACEMENT_P1_AFTER.log. Exact receipts match byte-for-byte against the
baseline (CRATE_PLACEMENT_P1_RECEIPT.txt), including every selected index, identity
and coverage. Each of four rebuilds per manifest matched; physical separation and
resource bounds passed. These are CPU microbenchmarks, not Source/LuaJIT native
FPS, GPU residency, whole-maze build or target-hardware certification. About1s
remains in this host's uncached path, so low-end optimization is not complete.

Reproduce from repository root:
```sh
git show eb319079f7e1b494851300e3465792cba88b5f2c:gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua > /tmp/crate-baseline.lua
python3 tools/run_lua54.py tools/profile_crate_placement.lua docs/validation/CRATE_PLACEMENT_P1_RECEIPT.txt /tmp/before.txt timing /tmp/crate-baseline.lua
python3 tools/run_lua54.py tools/profile_crate_placement.lua docs/validation/CRATE_PLACEMENT_P1_RECEIPT.txt /tmp/after.txt
```

Fresh canonical integration: **221 suites passed, zero failures**. Full fresh log:
CRATE_PLACEMENT_P1_INTEGRATION.log (SHA256 e5df3426ff68cf78004748ff6a117e7924decedd742152f66353704bf2c5bfb6).
The previous221-suite branding-repair result is inherited evidence, not this run.
Next performance checkpoint: profile repeated deterministic-noise hashing inside
pickCoverageCandidate against these same receipts; change only if measurement
justifies it. First complete the separately requested removal of Bribe. Native
Crate gaps remain in GREAT_CRATE_C3.md. No VPS/Workshop publication.
