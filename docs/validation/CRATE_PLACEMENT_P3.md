# P3 — exact-output exhausted-coverage cache

Baseline: fetched clean main `ec2cb1be2b03455d2966eabefb773eb65e19f1bc`.
Live GDD read 00 → 01 → relevant 05/07 Crate rules and LOD-IMPL-001–005.
No game law, tuning, manual or live-GDD change is needed.

## Finite gate fixed before editing

Preserve exact selected indices, company identity, coverage, eligibility,
wayfinding exclusions, physical separation, 40% placement cap, 64-draw cap and
lazy two-slot material ceiling on P1's fixed 1800/1896/1978-container manifests.
Optimize only demonstrated repeated coverage traversal; preserve P1's nearest
minimum, P2's deterministic-noise cache and every other production authority.
No extra persistent cache, model, texture, hook, network message or entity.

## Measurement and change

The unchanged tools/profile_crate_placement.lua runs the actual generator, wall
manifest compiler, client metadata compiler and production placement hook.
Fixture/native exclusions and every-17th wayfinding mask remain as documented
in CRATE_PLACEMENT_P1.md. Sequential same-host Lua 5.4 CPU measurements use one
warmup and three timed rebuilds, GC before each; no other test ran concurrently.
Separate untimed instruction sampling runs every 1000 VM instructions.

Fresh P2 baseline coverageGain samples: 11998 / 11389 / 11778, close to
pickCoverageCandidate's 12413 / 11839 / 12121. These are instruction samples,
not percentages of CPU time. Repeated coverage traversal warrants a bounded fix.

Five production lines cache only the fact that a candidate has zero remaining
coverage gain. Covered observations only accumulate within selectCoverageOrder,
so zero cannot become positive again. Positive gains are still recomputed exactly.
The full coverage set remains intact for final allocation and summary accounting;
score/tie comparisons, iteration order, selection and all RNG are unchanged.
Candidates are newly allocated each rebuild, so mark revisions, seed changes and
new world tables cannot reuse the flag. At most one extra boolean per candidate
exists during that rebuild; it leaves no retained resource or cross-world state.

| Manifest | Containers | Before median ms | After median ms | Reduction |
| --- | ---: | ---: | ---: | ---: |
| representative7719 | 1800 | 376.922 | 284.978 | 24.4% |
| dense15438 | 1896 | 372.013 | 247.369 | 33.5% |
| dense successor23157 | 1978 | 378.675 | 271.178 | 28.4% |

After coverageGain samples: 3382 / 3159 / 3324 (about 72% fewer).
Raw min/median/max, cached-hook costs and samples: CRATE_PLACEMENT_P3_BEFORE.log
and CRATE_PLACEMENT_P3_AFTER.log. P1/P2 historical timing results are inherited;
this table is a fresh before/after comparison against published P2 on this host.
Headless CPU timing is not Source/LuaJIT FPS, GPU texture residency, whole-maze
build time or low-end hardware acceptance. Uncached rebuild still costs 247–285ms.

## Validation

Both fresh receipts match CRATE_PLACEMENT_P1_RECEIPT.txt byte-for-byte:
SHA-256 `d10cc2e033d45335ba8d934f9550f22538a9cf0536c067cd5b4b553a2d5a9443`.
Every warmup/timed rebuild per manifest matched, with eligibility, exclusions,
separation, placement/draw caps and lazy-resource assertions passing. Existing
focused render/UV/resource gate also passed all 2048 orientation/composition cases.
Production blob: `75ebd645ee48eafb2d7a04b385fefee6c9d49034`.
Canonical integration: pending closure;
Log: CRATE_PLACEMENT_P3_INTEGRATION.log; SHA-256
`746d36874b9b4ca78d007dc9545ae354599dbf5d1a4045de7501d8356cba073f`.
This is a fresh invocation against P3. No production or test changes followed it.

Reproduce from repository root:
```sh
git show ec2cb1be2b03455d2966eabefb773eb65e19f1bc:gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua > /tmp/crate-p3-baseline.lua
python3 -u tools/run_lua54.py tools/profile_crate_placement.lua docs/validation/CRATE_PLACEMENT_P1_RECEIPT.txt /tmp/p3-before.txt profile /tmp/crate-p3-baseline.lua
python3 -u tools/run_lua54.py tools/profile_crate_placement.lua docs/validation/CRATE_PLACEMENT_P1_RECEIPT.txt /tmp/p3-after.txt profile
python3 -u tools/test_checkpoint_g_integration.py
```

## Next bounded action and native boundary

Profile repeated candidateConflicts checks inside the existing scan, including
endpoint-key construction and candidates already known to conflict. After P3,
its 8520 / 8231 / 8392 samples are the largest named helper cost, behind the
scan itself (12285 / 11761 / 12005). Measure first; optimize only if warranted
and preserve the same exact receipts and resource gate. No further optimization
is included in P3 and no new user evidence is needed for that headless checkpoint.

Preserve Bribe's authored removal, approved concrete/restored hull, stock blast-door
gates and renderer source-front-face-20260924. Native TRANS-PIEDMONT BULK visibility
is established only for the reported sample. Every broader native Crate exit in
GREAT_CRATE_C3.md remains open: hull/tint sampling; branding offset, mips and
legibility; stock gate appearance; floor/grate traversal, cover/rails; reset/rejoin;
dense successive-seed frame-time and texture residency. No new native acceptance.

Active: Great Crate → low-end optimization → focused fatal/game-breaking audit →
native playtest. Deferred September 28–October 4, 2026: Big Loot → Event System →
comprehensive systems audit. No VPS deployment or Steam Workshop publication.
