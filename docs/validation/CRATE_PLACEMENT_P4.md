# P4 — exact-output conflict cache

Baseline: fetched clean main `52eb96434af76d0ead341cc9b53386b0a57d23da`.
Live GDD read 00 → 01 → relevant 05/07 Crate rules and LOD-IMPL-001–005.
No design, tuning, manual or live-GDD write is required.

## Finite gate fixed before editing

Preserve byte-identical selected indices, company identity and coverage on P1's
fixed 1800/1896/1978-container manifests, with eligibility, wayfinding exclusions,
physical separation, 40% placement cap, 64 draws and lazy two-slot resource ceiling.
Preserve P1 nearest-distance, P2 deterministic-noise and P3 zero-coverage caches.
Only the measured conflict helper changes; no asset, geometry, render, gameplay,
RNG, network or persistent resource authority changes.

## Measurement and bounded change

The unchanged tools/profile_crate_placement.lua exercises the real generator,
wall manifest, client metadata compiler and production placement hook. Fixture
boundaries remain those in CRATE_PLACEMENT_P1.md. Same-host sequential Lua 5.4 CPU
runs use one warmup and three timed rebuilds per manifest, GC before each, with
instruction sampling separate from timing. No other test ran during timings.
Fresh P3 baseline candidateConflicts instruction samples: 8520 / 8231 / 8392,
behind pickCoverageCandidate at 12285 / 11761 / 12005. These count sampled VM
instructions, not a percentage of elapsed CPU time.

A separate scratch-only instrumented baseline counted calls, repeated known-true
conflicts and executions of the helper's stack-key concatenation. Four rebuilds
per manifest (warmup included; no sampling hook) produced:

| Containers | Helper calls | Repeated known conflicts | Stack keys constructed |
| --- | ---: | ---: | ---: |
| 1800 | 1629292 | 705680 | 1118660 |
| 1896 | 1558212 | 673128 | 1069488 |
| 1978 | 1614352 | 706724 | 1121700 |

Counting recorded the occupiedEdges table for each instance on each true return;
a later call counted as repeated only if that exact reservation table still
matched. Thus the counts exclude previous rebuilds. Stack counts exclude the
once-per-selection reserveCandidate call. Instrumented timing is deliberately
excluded from the comparison; CRATE_PLACEMENT_P4_COUNTS.log preserves counts and
the exact-receipt pass. Approximately 43% of helper calls revisit known conflicts.

P4 passes the temporary candidate to candidateConflicts, caches its exact
stack/orientation string and marks true conflicts. The scan skips marked
candidates thereafter. Reservations only accumulate within selectCoverageOrder;
a true conflict cannot clear. A false result is never cached: a previously clear
candidate must still see new reservations. Missing required geometry stays
ineligible. Fields are on newly allocated candidate tables, not world instances;
mark revisions and seed/world rebuilds cannot inherit stale state. At most one
boolean and one string reference per temporary candidate are added. Full coverage,
selection order, score/tie comparisons and reserveCandidate remain intact.

| Manifest | Containers | Before median ms | After median ms | Reduction |
| --- | ---: | ---: | ---: | ---: |
| representative7719 | 1800 | 252.189 | 202.249 | 19.8% |
| dense15438 | 1896 | 249.071 | 204.842 | 17.8% |
| dense successor23157 | 1978 | 255.314 | 212.443 | 16.8% |

After helper samples: 5154 / 4960 / 4987 (about 40% fewer). Raw samples and
min/median/max: CRATE_PLACEMENT_P4_BEFORE.log and CRATE_PLACEMENT_P4_AFTER.log.
P3's historical timings are inherited evidence, distinct from this fresh P3→P4
comparison. Headless CPU timings do not establish Source/LuaJIT FPS, whole-maze
build time, native texture residency or low-end hardware acceptance.

## Fresh validation

Both before/after receipts match CRATE_PLACEMENT_P1_RECEIPT.txt byte-for-byte:
SHA-256 `d10cc2e033d45335ba8d934f9550f22538a9cf0536c067cd5b4b553a2d5a9443`.
Every warmup/timed rebuild matches; all eligibility/exclusion/separation/cap and
lazy-resource assertions pass. Existing focused render/UV/resource checks pass
all 2048 orientation/composition cases. Production blob:
`7ba5820365e8f4538d71c5889e60281acb8b8824`.
Fresh canonical integration: **219 suites passed, zero failures**.
Log: CRATE_PLACEMENT_P4_INTEGRATION.log; SHA-256
`746d36874b9b4ca78d007dc9545ae354599dbf5d1a4045de7501d8356cba073f`.
This was a fresh invocation against P4, not an inherited pass. No production
or test changes followed it; only evidence and coordination text were finalized.

Reproduce from repository root:
```sh
git show 52eb96434af76d0ead341cc9b53386b0a57d23da:gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua > /tmp/crate-p4-baseline.lua
python3 -u tools/run_lua54.py tools/profile_crate_placement.lua docs/validation/CRATE_PLACEMENT_P1_RECEIPT.txt /tmp/p4-before.txt profile /tmp/crate-p4-baseline.lua
python3 -u tools/run_lua54.py tools/profile_crate_placement.lua docs/validation/CRATE_PLACEMENT_P1_RECEIPT.txt /tmp/p4-after.txt profile
python3 -u tools/test_checkpoint_g_integration.py
```

## Next bounded action and native boundary

Profile the remaining full pickCoverageCandidate scan, specifically visits to
selected/conflicted candidates versus still-active candidates. It now contributes
12023 / 11546 / 11822 instruction samples, more than twice the largest helper.
Measure before proposing a stable active-candidate traversal; retain exact original
iteration/tie order, receipts and resource ceilings. Publish one demonstrated
optimization or findings only. P4 does not implement that next change.

Preserve Bribe's authored removal, approved concrete/restored hull, stock blast-door
gates and renderer source-front-face-20260924. Inherited native TRANS-PIEDMONT BULK
visibility is established only for the reported sample. All broader native C3 exits
remain open: hull/tint sampling; branding offset, mips and legibility; stock gate
appearance; floor/grate traversal and cover/rails; reset/rejoin; dense successive-seed
frame time and texture residency. No fresh native acceptance is claimed.

Active: Great Crate → low-end optimization → focused fatal/game-breaking audit →
native playtest. Deferred September 28–October 4, 2026: Big Loot → Event System →
comprehensive systems audit. No VPS deployment or Steam Workshop publication.
