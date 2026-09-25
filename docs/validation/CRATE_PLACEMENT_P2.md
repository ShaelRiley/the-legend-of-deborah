# P2 — exact-output branding noise cache

Baseline: fetched clean main `890a73fbe6452599bfca9f08bc20f0a62817f5d9`.
Live GDD read in order 00 → 01 → relevant 05/07 Crate rules and
LOD-IMPL-001–005. No game law, tuning, player-facing behavior or manual change;
no GDD write required. Published P1 and Bribe removal remain intact.

Finite gate fixed before editing: preserve exact selected indices, company
identity, coverage, eligibility, wayfinding exclusions, physical no-touching,
40% placement cap, 64-draw cap and lazy two-slot resource ceiling on P1's three
fixed representative/dense manifests. Change only a measured bottleneck and
require comparable before/after improvement plus the canonical integration gate.

The unchanged tools/profile_crate_placement.lua ran the real maze generator,
server wall manifest compiler, client wall metadata compiler and production
rebuild hook. Fixture/native limitations and fixed every-17th wayfinding mask
are unchanged from CRATE_PLACEMENT_P1.md. Timing is sequential on the same host,
Lua 5.4 CPU time, one warmup then median of three rebuilds, GC collected before
each. Instruction sampling is a separate untimed rebuild at every 1000 VM
instructions. No other test matrix ran concurrently with the timed fixtures.

Fresh baseline sampling put RNG hashing first on all three manifests:
107114 / 102917 / 105944 samples, versus 12957 / 12170 / 12664 in
pickCoverageCandidate and 11928 / 11334 / 11896 in coverageGain. These are VM
instruction samples, not wall-time percentages. The pure Seeds.Derive hash is
recomputed for unchanged candidate identity and fixed floor seed on every scan.

Only change: lazily retain that exact numeric noise value on the existing
temporary candidate table. An explicit nil check also caches zero. Candidate
tables are recreated each rebuild and discarded afterward; no cross-world,
cross-seed or persistent cache. Hash token, hash arithmetic, RNG authority,
iteration order and score/tie comparisons are unchanged. At most one additional
number per eligible candidate exists during rebuild; no new models, materials,
textures, hooks, messages or unbounded retained resources.

| Manifest | Containers | Before median ms | After median ms | Reduction |
| --- | ---: | ---: | ---: | ---: |
| representative7719 | 1800 | 1123.079 | 376.045 | 66.5% |
| dense15438 | 1896 | 1061.657 | 388.059 | 63.4% |
| dense successor23157 | 1978 | 1104.540 | 403.777 | 63.4% |

Raw min/median/max, cached-hook costs and before/after sampling:
CRATE_PLACEMENT_P2_BEFORE.log and CRATE_PLACEMENT_P2_AFTER.log.
Both output receipts match CRATE_PLACEMENT_P1_RECEIPT.txt byte-for-byte:
SHA-256 `d10cc2e033d45335ba8d934f9550f22538a9cf0536c067cd5b4b553a2d5a9443`.
Each of four timed/warmup rebuilds per manifest matched; eligibility, exclusion,
separation and resource assertions passed. The existing harness is unchanged.
P1's historical 61–64% result is inherited evidence; this table is a fresh
comparison against the already optimized P1 implementation after Bribe removal.

Reproduce from repository root:
```sh
git show 890a73fbe6452599bfca9f08bc20f0a62817f5d9:gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua > /tmp/crate-p2-baseline.lua
python3 -u tools/run_lua54.py tools/profile_crate_placement.lua docs/validation/CRATE_PLACEMENT_P1_RECEIPT.txt /tmp/p2-before.txt profile /tmp/crate-p2-baseline.lua
python3 -u tools/run_lua54.py tools/profile_crate_placement.lua docs/validation/CRATE_PLACEMENT_P1_RECEIPT.txt /tmp/p2-after.txt profile
```

Fresh canonical integration: **219 suites passed, zero failures**, including
the affected Crate gates, active catalog/Bribe-removal gate and Lua syntax gate.
Log: CRATE_PLACEMENT_P2_INTEGRATION.log; SHA-256 `746d36874b9b4ca78d007dc9545ae354599dbf5d1a4045de7501d8356cba073f`.
This is a fresh invocation against P2, not the inherited Bribe-removal result.
No production or test changes followed it.
Tested production blob: `489c1d97cb7b0051729fae743b1dc7cfb2b29c38`.

Headless CPU timings are not Source/LuaJIT native FPS, GPU texture residency,
whole-maze build time or low-end hardware acceptance. Uncached rebuild still
costs about 0.4 seconds here. The next bounded profiling target is repeated
coverageGain traversal inside pickCoverageCandidate: after P2 it contributes
11998 / 11389 / 11778 samples, close to the scan's own cost. Measure its exact
contribution before changing it; preserve the same receipt and resource gate.
No speculative coverage refactor is included in P2.

Every native Crate exit in GREAT_CRATE_C3.md remains open: broader hull/tints,
brand offset/mips/legibility, stock gates, floor/grate traversal and cover/rails,
reset/rejoin, and dense successive-seed frame-time/texture residency. Preserve
the approved concrete/restored hull and source-front-face-20260924 renderer;
limited native branding visibility remains established. Bribe remains unloaded
and must not return without explicit author instruction. No VPS deployment or
Steam Workshop publication. Active and deferred roadmap/order/dates unchanged.
