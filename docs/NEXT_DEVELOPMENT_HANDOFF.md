# Handoff — P3 exhausted-coverage cache complete; conflict profiling next

Repository: ShaelRiley/the-legend-of-deborah; branch: main.
Baseline verified remote HEAD: `ec2cb1be2b03455d2966eabefb773eb65e19f1bc`.
Resume from published main containing this handoff. The publication response
supplies the exact new SHA; fetch/verify HEAD and preserve intervening or
uncommitted work. Do not reset to the baseline.

Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
Read 00 → 01 → relevant 05/07 Crate and deterministic/performance rules.
P3 changes no design, tuning or player-facing behavior; no GDD/manual write.

P3 adds only an exhausted-coverage flag to each temporary placement candidate.
Covered observations only grow; zero gain therefore stays zero. Full coverage
sets, score/tie order, P1 nearest-distance and P2 noise caches remain intact.
Fresh same-host CPU medians improve 24–34% against published P2:
376.922/372.013/378.675ms → 284.978/247.369/271.178ms. Unchanged P1 fixed
manifests, exact receipts and eligibility/exclusion/separation/resource gates pass.
Evidence: docs/validation/CRATE_PLACEMENT_P3.md and three logs.
Fresh canonical integration: **219 suites passed, zero failures**. Headless timings do not establish FPS,
whole-maze build time, native residency or low-end hardware acceptance.

Next coherent checkpoint: profile repeated candidateConflicts checks inside the
placement scan, including endpoint-key construction and already-conflicting
candidates. After P3 it is the largest named helper cost, behind the scan itself.
Reuse tools/profile_crate_placement.lua, P1 fixed manifests/receipt and P3 logs.
Before edits define exact selected indices, identity, coverage, eligibility,
wayfinding exclusions, physical separation, 40% cap, 64 draws and lazy two-slot
resource gates. Measure contribution, optimize one demonstrated bottleneck only
if worthwhile, compare before/after, run affected checks and canonical integration,
then commit/non-force-publish and verify immediately. Otherwise publish findings
and the next bounded target. No new user evidence is needed for headless profiling.

Bribe removal remains binding: bribe_blockade server registration/payment and
client dialog/distribution stay unloaded; dormant code is not permission to restore
it. Preserve approved concrete/restored hull, stock blast-door gates and renderer
source-front-face-20260924. Native TRANS-PIEDMONT BULK composition visibility is
established only for the reported sample. All remaining native exits stay open:
broader hull/tints; branding offset/mips/legibility; stock gate appearance;
floor/grate traversal and cover/rails; reset/rejoin; dense successive-seed native
frame-time/texture residency. Full reconciliation: docs/validation/GREAT_CRATE_C3.md.
P1/P2 historical validation is inherited evidence, distinct from fresh P3 checks.

Active: Great Crate → low-end PC optimization → focused fatal-crash/game-breaking
bug audit → native playtest. Deferred September 28–October 4, 2026, in order:
Big Loot → Event System → comprehensive systems audit. No VPS deployment or
Steam Workshop publication. Keep the next checkpoint small and publish it before
starting another. Native evidence remains for the planned playtest.
