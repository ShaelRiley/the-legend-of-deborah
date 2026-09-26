# SPOT-10 D–J attempt provenance

Exact aggregate hashes and unchanged-source checks are in
SPOT_10_SECOND_PASS_GATE_ATTEMPTS.json. Available focused/aggregate transcripts
and their SHA-256 identities are in SPOT_10_SECOND_PASS_ATTEMPTS.txt.

1. Authentic unchanged parent: 64/64 selected suites, 741 Lua syntax checks.
2. First candidate: 63/64, 741 syntax. SPOT05 logger assertion 53 had a fixture
   which replaced the actor/graph and manually set readiness before binding the
   new life. The production fix correctly erased that stale readiness. The
   fixture now binds the current life before admitting its intentionally elapsed
   test delay. Its 76 reporting assertions remain intact. A first fixture edit
   used the CombatRolls alias R instead of AbilityRules; that failed and was
   corrected to Rules, not counted as a pass.
3. New focused harness attempt 1 had an unclosed nested loop; attempt 2 lacked
   the native scripted_ents boundary; attempt 3 lacked the DamageInfo boundary.
   Attempt 4 passed 758 assertions. No per-attempt source snapshots were captured
   for these focused development runs; no hashes for missing snapshots are invented.
4. Expanded candidate: 71/72, 742 syntax. The independent B14 resource integration
   assertion still expected the old six-Magic refund. Its paid-cast test now expects
   twelve (pool 60→72), matching approved E, without weakening event/source gates.
5. Final mechanical checks added release/landing fractional payment, exact Float
   pool replacement, and source retirement within an aura pulse. Focused attempt
   5 passed 765 assertions; the third aggregate passed 72/72, 742 syntax, with
   unchanged source. Final documentation closeout and independent publication
   receipts are separate; a later failure must remain a failure.

The strict local patch helper initially stopped on an unmatched movement-validator
literal. It did not discard earlier applied edits or claim test success. The
corrected helper applied the remaining exact edits. No Workshop/VPS command ran.

## Publication preflight — retained failure

Independent run **36277978005**, attempt 1, stopped at `git diff HEAD --check`
before the independent suite gate or publication. The sparse source transport,
manual rebuild and expected candidate tree matched; one embedded historical
transcript line ended with a space. The original line is retained in that run's
source-patch artifact and in the external unmodified transcript. Only its trailing
space is normalized in this repository; recorded original transcript hashes still
identify original logs, not the normalized embedding.

The preceding local 72/72 frozen receipt remains a record of the commands actually
run, not proof of a staged whitespace-clean diff: the newly added transcript was
not yet staged, so that invocation of `git diff HEAD --check` did not inspect it.
The corrected candidate is staged **before** the new frozen local gate. Preserve
the old receipt and failed independent run; do not relabel either as a successful
publication. Gameplay, tests, manual and GDD are unchanged by this correction.
