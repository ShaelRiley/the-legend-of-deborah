# Handoff — P4 conflict cache complete; active-scan profiling next

Repository: ShaelRiley/the-legend-of-deborah; branch: main.
Baseline verified remote HEAD: `52eb96434af76d0ead341cc9b53386b0a57d23da`.
Resume from published main containing this handoff; publication response supplies
the exact new SHA. Fetch/verify remote HEAD and preserve intervening/uncommitted
work. The tested tree and every changed blob must match publication.

Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
Read 00 → 01 → relevant 05/07 Crate and deterministic/performance rules.
P4 changes no design, tuning or player-facing behavior; no GDD/manual write.

P4 caches true conflicts and exact endpoint stack keys on temporary placement
candidates. Reservations only grow; false results remain live. P1 nearest-distance,
P2 noise, P3 exhausted coverage, full coverage sets and score/tie order remain intact.
Fresh same-host CPU medians improve 17–20% against published P3:
252.189/249.071/255.314ms → 202.249/204.842/212.443ms. Exact P1 receipts,
eligibility/exclusion/separation/caps and lazy-resource gates pass. Evidence:
docs/validation/CRATE_PLACEMENT_P4.md and before/after/count/integration logs.
Fresh canonical integration: **219 suites passed, zero failures**. Historical P3's pending-closure typo was
corrected against its preserved 219-pass log; that is inherited evidence.
Headless timings do not establish FPS, whole-maze build time, texture residency
or low-end hardware acceptance.

Next coherent checkpoint: profile full pickCoverageCandidate scan visits to
selected/conflicted versus active candidates. After P4 the scan contributes
12023 / 11546 / 11822 instruction samples, over twice the largest helper.
Reuse tools/profile_crate_placement.lua, fixed P1 manifests/receipt and P4 logs.
Before edits define exact selected indices, identity, coverage, eligibility,
wayfinding exclusions, physical separation, 40% placement, 64 draws and lazy
two-slot gates. Measure first; consider stable active-candidate traversal only if
warranted, preserving exact iteration/tie order. Compare before/after, run affected
checks and canonical integration, then commit/non-force-publish and verify.
Otherwise publish findings and the next bounded target. No new user evidence is
needed for that headless checkpoint. CLI fetch works; use authenticated GitHub
blob/tree/commit/ref publication if push credentials remain unavailable.

Bribe registration/payment and client dialog/distribution remain unloaded. Preserve
approved concrete/restored hull, stock blast-door gates and renderer
source-front-face-20260924. Native TRANS-PIEDMONT BULK visibility is established
only for the reported sample. All other native exits remain open: broader hull/tints;
branding offset/mips/legibility; stock gate appearance; floor/grate traversal and
cover/rails; reset/rejoin; dense successive-seed frame-time/texture residency.
Full reconciliation: docs/validation/GREAT_CRATE_C3.md. No fresh native acceptance.

Active: Great Crate → low-end PC optimization → focused fatal-crash/game-breaking
bug audit → native playtest. Deferred September 28–October 4, 2026, in order:
Big Loot → Event System → comprehensive systems audit. No VPS deployment or
Steam Workshop publication. Publish the next small coherent checkpoint promptly.
