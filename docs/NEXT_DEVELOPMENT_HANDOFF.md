# Handoff — P2 noise cache complete; bounded coverage profiling next

Repository: ShaelRiley/the-legend-of-deborah; branch: main.
Baseline verified remote HEAD: `890a73fbe6452599bfca9f08bc20f0a62817f5d9`.
Resume from published main containing this handoff, not the baseline. Fetch and
verify HEAD; preserve intervening/uncommitted work. The publication response
supplies P2's exact new SHA; do not reset to P1 or the Bribe-removal baseline.

Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
Read 00 → 01 → relevant 05/07 Crate and deterministic/performance rules.
P2 changes no design, tuning or player-facing behavior; no GDD/manual edit.

P2 profiles repeated deterministic-noise hashing using the unchanged
`tools/profile_crate_placement.lua` and P1's fixed 1800/1896/1978-container
manifests. The pure hash dominated instruction samples. Cache the exact numeric
noise once per temporary candidate during rebuild; no persistent cache or
changed hash/score/tie ordering. Fresh same-host CPU medians fall 63–67%, from
1123.079/1061.657/1104.540ms to 376.045/388.059/403.777ms. All exact P1 receipts
match byte-for-byte; eligibility, wayfinding exclusions, physical no-touching,
placement caps and lazy resource gates pass. Evidence and fresh canonical
closure: `docs/validation/CRATE_PLACEMENT_P2.md` and its three logs. Fresh
canonical integration: 219 suites, zero failures. Headless CPU
measurements do not certify native FPS or complete low-end optimization.

Next coherent checkpoint: profile repeated coverageGain traversal inside the
existing placement scan. After P2 this and scan overhead are the largest sampled
costs. Reuse P1 receipts/manifests; define exact-output and resource gates before
editing, measure contribution, change one demonstrated bottleneck only if
worthwhile, compare before/after, validate and publish/verify immediately. If
not justified, keep the evidence and name the next bounded target. Do not rerun
old matrices merely for orientation, broaden into deferred work, or use agents.

Published P1 `08d887ba5ffaf07c25bea2d400fb7cacc536ebd0` remains intact. Its
61–64% historical improvement and 221-suite pass are inherited evidence.
Bribe removal `890a73fbe6452599bfca9f08bc20f0a62817f5d9` remains intact:
`bribe_blockade` server registration/payment and client dialog/distribution stay
unloaded. Dormant rollback code is not permission to restore it, including in
next week's Event System work. GDD05 LOD-EVENT-BRIBE-001 and manual remain
synchronized. Its historical canonical result is 219 suites, zero failures;
two Bribe-only suites were retired. Applying that removal requires a full
restart; already running old dungeons were not migrated.

Native evidence establishes TRANS-PIEDMONT BULK, emblem and slogan on one
restored teal container. Preserve limited sample success; do not reopen absent
branding without contradictory evidence. Preserve approved concrete/restored
hull, stock blast-door gates and renderer `source-front-face-20260924`.
Outstanding native Crate requirements: broader hull/tint sampling; brand
offset/mips/legibility; stock gate appearance; floor/grate traversal and
cover/rails; reset/rejoin; dense successive-seed frame-time/texture residency.
Full acceptance reconciliation remains in `docs/validation/GREAT_CRATE_C3.md`.

Roadmap: Great Crate → low-end PC optimization → focused fatal-crash/game-breaking
bug audit → native playtest. Deferred September 28–October 4, 2026, in order:
Big Loot → Event System → comprehensive systems audit. Do not deploy to the VPS
or publish to Steam Workshop. No new user evidence is needed for the next
headless profiling checkpoint; native tests remain for the planned playtest.
