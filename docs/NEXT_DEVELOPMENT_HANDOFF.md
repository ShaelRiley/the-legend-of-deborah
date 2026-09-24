# Handoff — Bestiary B22

Resume **The Legend of Deborah** and complete **Bestiary checkpoint B22 only**,
including authorized design, implementation, validation, documentation, commit
and verified non-forced push to `main`.

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
Latest checkpoint: **Add topology-aware encounter composition and spatial spacing**.
The publication response supplies the exact verified SHA; fetch current main,
confirm this checkpoint and preserve intervening work. B21's parent is
`27853c2f7fde54ad377c86c398456b5b9ba33ce8`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.

I authorize implementation, necessary refactoring, design/tuning decisions,
compatible existing assets, naming, UX, tests, diagnostics, documentation, live
GDD amendments, focused parallel delegation, commits and non-forced pushes to
main. Resolve ordinary ambiguities. **Do not deploy to the VPS or publish to
Steam Workshop.**

Read AGENTS.md, active/newest DEVELOPMENT_PLAN.md checkpoint, this handoff,
BESTIARY_EXPANSION.md and briefs/BESTIARY_UPDATE.md. Live GDD00→01→needed tabs,
including LOD-ROADMAP-ECOSYSTEM-001 and LOD-BESTIARY-B20/B21-001 in05/06/07.
Exact HUMAN anchors only for required missing detail. Missing historical art
is not blocking. No chat archaeology or repeated broad roster audit.

## Current B21 implementation

EncounterDirector measures real traversable same-sector planar approaches,
corners/junctions, straight corridor reach up to3 edges, same-direction clear
240-unit physical lane at48-unit height, existing conservative256-node same-floor
HasAlternate proof, reachable vertical edges at/one planar edge from candidate,
and navigable objective distance. Closed gates/event edges and disconnected
upper cells cannot masquerade as approaches. Existing specialist landing/escape/
safe/objective/role/sector/singleton/companion restrictions remain binding.

Inside B20's current motif, filter specialist templates through existing
EnemyRoster.Placement before selection. Use common fallback only if no legal
motif template remains. Actual spawn rechecks geometry and retains budget-safe
ordinary-body substitution. Strongest preference only:2 for ambush/corner,
pursuit/alternate, Climber/vertical or line fire/clear corridor;1.5 for area/trap
at two-exit chokepoints or support/companion at junctions/objective distance4–6;
1.25 for control/position/projectile/reaction/melee with2+ planar approaches;
otherwise1. Ignore basic escorts in specialist scoring. No stored admission cache,
new recurring hook or duplicate navigation/placement authority.

The stale candidate-list defect is repaired: recheck minimum4 graph-cell spacing
against every previously planned objective/discretionary encounter before each
new discretionary placement. Precomputed eligibility is not sufficient after
placement changes the plan. Retain threat scaling, first-encounter exception,
0.5 allowance, sector maxima, physical admission, target80/ceiling96 and objective
owners. Pursuit/wanderers can still converge; this is home spacing, not live
combat exclusion. lod_encounter_ecology reports geometry, fit multiplier/reason
and rejected motif-template count. Manual164 chapters/32chunks. Roster63 normal
plus4 named, frozen baseline18; breadth complete, **Bestiary phase incomplete**.

B20 remains six motifs,60 themed+6 common templates,63 identities/14 families.
Last two committed motifs excluded; choose uniformly among eligible least-used.
Unseen-template weight3 else1; sectors1–2 use early-template history, later sectors
all-template history. Divide by1+4*current uses; unseen specialist x2, recent enemy
x0.7, recent family x0.8, last dungeon matching template x0.2, older two x0.6.
Immediate template repeat excluded when an alternative exists. Named RNG streams.
RunManager.State owns guarded before/after receipts; commit only after complete
physical build succeeds, graph/report assigned and before readiness/release.
Failed builds consume nothing; same-level rebuild replaces from before; successor
uses after; cleanup retains; new campaign resets even with same seed. Three recent
primitive summaries, counts cap1,000,000; no graph/entity references in history.
These are planned squads, not sightings, kills or successful native spawns.

## Complete B22 — bounded macro-pacing

Author the next coherent production slice through the existing EncounterDirector:
quiet traversal, probes, pressure/spikes and recovery phrasing, with optional
branches/objective context where suitable. Define finite scope, exact tuning and
measurable campaign gate before edits. Preserve B20 motif/history ownership and
independent RNG, B21 topology/admission/spacing, objective guarantees, count/threat
ceilings, physical escape and all accepted cohort/progression contracts.
Prefer complete production behavior over unused pacing metadata; do not change
geometry/escape restrictions or statistical thresholds just to improve exposure.
Retain failed evidence and reserve final third for validation/publication.

Wandering-population ecology and full campaign/whole-phase coverage remain
Bestiary obligations; explicitly record anything beyond B22. A single dungeon
need not display every family. No whole-Bestiary completion claim before all brief
exit conditions have evidence. **Do not begin Big Loot, Events or later audits.**
No human runtime/deployment gate precedes the ordered phases/audits.

## Validation truth and cadence

One fresh final canonical run passed **all210 suites with zero failures**; no
gameplay/config/test edits followed. Complete terminal matrix retained in
BESTIARY_B21_INTEGRATION.txt. Earlier failed/incomplete
outputs are retained separately. The final fixture proves the spacing bug with
affordable patrols: production admits one, spacing-disabled control admits two.
Topology fixtures also cover real loops/branches, gates/event edges, vertical and
objective reach, blocked lanes, actual selector effects and native-spawn boundary
revalidation. The unchanged32x20 paired campaigns retain all54 exposure floors
25planned/20legal/5early and minimum36/54 per campaign. Measured mean47.562/min43,
control40.750;6232 encounters,4312 discretionary,2372 geometry preferences,
432 rejected motif-template candidates at selected cells. All sampled spacing/
admission assertions pass. Cross-level template returns164 versus277; within-level
repeats571 versus574; consecutive roster Jaccard0.206213 versus0.199360 (not an
improvement claim). Six motifs109/104/114/99/106/108, no two-level repeats.
Mean coverage slightly below B20's48.500, minimum above41; all thresholds retained.
Existing512 independent plans retain geometry/companion restrictions and count
reporting. Native traces/entities are doubles, not Source observations.

Targeted tests while editing, then `python3 tools/test_checkpoint_g_integration.py`
once stable. Repair attributable failures; broaden only for concrete shared-
authority risk. Update/readback live GDD, manual, ledger, plan and this handoff;
keep validator registry synchronized. Commit/publish immediately after green.

After ordered phases/audits, gm_flatgrass tests motif/topology recognizability,
actual placement/substitution, solo support/hulls/gates/stairs/Walls/false floors,
pursuit/wanderer convergence, full/reduced tells/audio, HP/XP/drops, death/revival/
disconnect/late join, freeze/reset/same-seed rebuild,1–4-player balance/network and
Gordon→Hector→Deborah, sole staging successor, Abundance and Level21 cash.
Evidence console_latest.txt+rpg_summary_latest.txt; session log only for ordering.

If CLI push credentials are unavailable, use authenticated GitHub blob/tree/
commit/ref tools; verify every blob and complete tested tree, advance non-forced,
fetch and verify SHA/parent/tree. Preserve newer work; never force.
Order: Bestiary→Big Loot→Event System→systems integration/emergence audit→low-end
PC performance audit→final crash/progression-safety audit→human playtest.
Finish B22 only. End with verified SHA, scope/tests/progress/native checks and
next continuation prompt.
