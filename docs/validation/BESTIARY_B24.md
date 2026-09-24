# Bestiary B24 — planned homes and enforceable campaign closure

Base: verified `main` `76e54e95ebb487c5dd2dc3c63847ef8295651fe1`.
The finite gate in `BESTIARY_B24_GATE.md` preceded production/test edits.
Live GDD00→01→05/06/07 governed work; LOD-BESTIARY-B24-001 was amended and
read back. No new normal identities:63 normal/4 named, frozen baseline18.
No VPS or Steam Workshop operation occurred.

## Production closure

A dormant discretionary squad has no native hull. The previous roaming candidate
filter could therefore reserve the squad's exact home despite physical collision
checks. WanderingDirector now derives a local set from the current graph's
EncounterPlan.encounters and excludes those cells before shuffling candidates.
All planned homes remain reserved, including after a squad has spawned; there
is no live occupancy cache or new release/lifecycle owner. Plan replacement or
in-place list changes take effect on the next attempt. Missing legacy plans/lists
retain compatibility. Exact-cell reservation does not impose4-cell spacing on
roamers or constrain their later patrol/pursuit. Fully reserved floors defer.

The change preserves target16/floor,4 specialists/floor, singleton specialist
identities,20-second replacement, near-Hero distance4,24-candidate native bound,
max-body hull/support checks, current Placement, shared96 ceiling, exact ownership
and successful-build receipts. No new runtime hook, actor, attack, status, reward,
asset, density multiplier or history service. Manual remains164 chapters/32chunks;
its ecology chapter explains reserved homes without promising empty corridors.

Focused `tools/test_bestiary_b24.lua` executes production initial/replacement
spawning, dormant homes, all-reserved deferral, fresh plan/list reservations,
legacy no-plan/list compatibility and immutable plan/receipt checks. Existing
B23 population bounds now enforce no planned/roaming home overlap in every sample.

## Campaign method and frozen gates

Both existing32-campaign×20-level samples retain seed=campaign*7919 and rotating
parties1–4. Encounter control disables only template memory, retaining the same
motif schedule. Roaming control disables only motif pool choice, retaining the
same plans, seeds, physical/cap/count/no-repeat rules and B24 home reservation.
Neither control is the full old game. All54 exposure floors25planned/20legal/
5early, minimum36/54 campaign coverage, coverage lift and B21/B22/B23 gates remain.

New encounter gate requires>=25% fewer adjacent-dungeon discretionary template
returns than the memory-disabled control. Combined-population measurement counts
planned ordinary encounters (including ordinary objective squads) plus initial
native-boundary roamers; it excludes named bosses/event actors. It is potential
population, not concurrent actor count, sightings, kills or Source spawn success.
Require max basic-identity share<=50% and>=10/14 families per campaign in both
arms, legal motif/template membership, all6 motifs changing aggregate family
distributions, and zero shared planned/roaming home cells. Report consecutive
roster Jaccard and within-dungeon repeats even when they do not improve.

## Validation evidence

One fresh final canonical integration run passed **all214 suites with zero
failures**. No gameplay/config/test edits followed. Its two campaign suites
produced the final reports described below. Manual generation/checks and Lua
syntax/static gates passed in the same matrix.

The final canonical population run reproduces the completed initial sample:28,342 initial roamers per arm over
640 dungeons/1,789 floors;1,747 floors fill16 initially,42 defer282 total slots.
This is47 fewer admitted slots than B23's historical28,389, entirely attributable
to protecting planned homes; no unsafe fallback or threshold relaxation. Combined
planned+initial bodies54,762 per arm. Every campaign covers at least13/14 families;
max basic share0.306147 motif versus0.353621 legacy; mean adjacent roster
Jaccard0.243567 versus0.523944 across608 pairs. All640 roaming populations differ.
Six autonomous additions retain exposure>=25: Siphoner225,Caromer227,Reaper266,
Redliner235,Drubber247,Afterburst249. Raw initial report and terminal transcript
are retained as BESTIARY_B24_POPULATION_INITIAL*.txt.

Final encounter campaign:6,233 encounters/4,313 discretionary; specialist coverage
mean47.250/min39 versus40.156/min31 without template memory. All54 exposure floors
pass. Adjacent-dungeon template returns191 versus310 (38.3871% reduction; required
>=25%). Within-level repeats576 in both arms; encounter-only roster Jaccard0.209819
versus0.207373 is slightly worse, so no universal repetition-improvement claim.
Exact consecutive template-set repeats0 in both arms. Geometry/spacing/budget
checks pass;635/640 dungeons contain probe+pressure/spike, all32 campaigns have
branch spikes, and all prior phrase/admission gates remain unchanged.

Final reports: `BESTIARY_B24_CAMPAIGN_FINAL.txt` and
`BESTIARY_B24_ENCOUNTER_FINAL.txt`; complete terminal matrix:
`BESTIARY_B24_INTEGRATION.txt`. No B24 trial failed. Earlier
failed checkpoint evidence remains untouched; no gate was weakened.

## Whole-phase status and native limits

`BESTIARY_B24_EXIT.md` reconciles all14 brief exit conditions and substantive
requirements. Roster breadth, systemic tactical families, memory, topology,
syntax, pacing and diagnostics are implemented and automatically exercised.
B24 closes home interference and enforces measured campaign claims rather than
merely repeating roster counts. It does not declare the entire phase complete.

B25 remains a bounded motif-intensity closure: explicit theme influence on
reinforcement/elite probability and pacing is absent, and composition-driven
density is partial evidence. Reconcile elite influence against canonical60/30/10
tier law before dependent edits. Named example niches/themes are illustrative;
these explicit influence dimensions are not. No Big Loot/Events/later audits.

Engine entities, traces and clocks are doubled. Native acceptance must still
verify motifs/phrases and full/reduced tells/audio, actual hull/support/escape/
substitution around gates/stairs/Walls/false floors, patrol/pursuit convergence,
1–4-player combat/balance/networking, death/revival/disconnect/late join,
freeze/reset/rebuild, HP/XP/drops, Gordon→Hector→Deborah, sole staging successor,
Abundance and Level21 cash. Per roadmap this occurs after ordered phases/audits,
not as a fabricated blocker to B25. Deployment needs separate authorization.
