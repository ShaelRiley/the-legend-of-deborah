# Handoff — Bestiary B23

Resume **The Legend of Deborah** and complete **Bestiary checkpoint B23 only**,
including authorized design, implementation, validation, documentation, commit
and verified non-forced push to `main`.

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
Latest checkpoint: **Add route-based encounter macro-pacing**.
The publication response supplies its exact verified SHA; fetch current main,
confirm this checkpoint and preserve intervening work. B22's parent is
`35351d7ee24fda7ba65be65f865c3c1e8bcd3555`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.

I authorize implementation, necessary refactoring, design/tuning decisions,
compatible existing assets, naming, UX, tests, diagnostics, documentation, live
GDD amendments, focused parallel delegation, commits and non-forced pushes to
main. Resolve ordinary ambiguities. **Do not deploy to the VPS or publish to
Steam Workshop.**

Read AGENTS.md, active/newest DEVELOPMENT_PLAN.md checkpoint, this handoff,
BESTIARY_EXPANSION.md and briefs/BESTIARY_UPDATE.md. Live GDD00→01→needed tabs,
including LOD-ROADMAP-ECOSYSTEM-001 and LOD-BESTIARY-B20/B21/B22-001 in05/06/07.
Exact HUMAN anchors only for required missing detail. Missing historical art
is not blocking. No chat archaeology or repeated broad roster audit.

## Current B22 implementation

EncounterDirector owns spatial macro-pacing in BuildPlan, using existing planning
BFS with same-sector Navigator traversal. Entrances=Start/preceding gate.afterCell;
goals=corresponding keycards/CoreCell. Entry distance a, goal distance b and path
length L give progress=clamp((a-b+L)/2,0,L)/L and detour=max(0,(a+b-L)/2).
Uniform named pacing:sector RNG chooses Surge/Ambush/Gauntlet, with cumulative
quiet/probe/pressure boundaries10/35/80%,20/45/85%,10/25/85%; remainder recovery.
Quiet/recovery forbid discretionary homes with no reservation fallback. Probes
retain full base template/companions at composition scale1; pressure and active-
band detour>=4 branch spikes use existing full party/depth scale. Offer one probe,
then pressure/spikes, then legacy unavailable candidates and remaining probes,
within existing budgets/maxima. No actor-level/attack/reward changes.

Missing endpoint metadata is diagnosed unavailable and retains legacy planning;
disconnected path or coincident entrance/goal has no positive span and fails
closed for discretionary homes. Guaranteed objective placement/composition stays
exact. Distance maps are local; primitive pacing facts/counters remain on plan.
No new Think/history/combat owner or density cap. lod_encounter_ecology adds
LOD:PACING phrase/path status, entry/goal/length, band-cell/squad/threat counts
and per-encounter band/progress/detour/scale. Manual164 chapters/32chunks.
These are home reservations, not guaranteed silence: wanderers, pursuit,
backtracking and separated Heroes can interrupt respite.

B21 retains specialist Placement preflight before motif selection, common fallback
only when no legal motif survives, and spawn-time geometry revalidation/ordinary
substitution. Real same-sector approaches, corners/junctions, straight reach3,
same-direction240-unit physical lane at48 height, conservative256-node alternate
proof, adjacent vertical access and objective distance affect weights. Strongest
preference only2/1.5/1.25/1, never stacked; ignore basic specialist escorts.
Every discretionary admission rechecks4-cell home spacing against current plan,
including objectives. Preserve all physical escape/transition/safe/role/sector/
singleton/companion restrictions, budgets/first-admission exception/0.5 allowance,
sector maxima,target80/ceiling96. Closed gates/events are not traversable routes.

B20 remains six motifs,60 themed+6 common templates,63 normal identities/14
families,4 separately counted named bosses, frozen baseline18. Last two committed
motifs excluded; uniform choice among eligible least-used. Template weight3 unseen
else1, early-history sectors1–2/all-history later; divide1+4*current uses; unseen
specialist x2, recent enemy x0.7, family x0.8, last-dungeon template x0.2, older two
x0.6. Immediate repeat excluded when alternative exists. Isolated named streams.
RunManager.State owns guarded before/after receipts, committed only after full
physical build succeeds, graph/report assigned and before readiness/release.
Failed builds consume nothing; same-level rebuild replaces from before; successor
uses after; cleanup retains; new campaign resets even with same seed. Three recent
primitive summaries, counts cap1,000,000; no graph/entity references in history.
Counts describe planned squads, not successful native spawns, sightings or kills.

## Complete B23 — bounded wandering-population ecology

Integrate the existing WanderingDirector with current encounter ecology in one
coherent production slice. Inspect its real roster/weights, spawn/placement,
activation, cap and lifecycle seams before choosing exact scope. Use current
motif/context where compatible; author explicit conservative specialist inclusion/
exclusion and composition policy. Do not blindly expose encounter-only stationary,
trap or companion-dependent actors as solitary wanderers. Preserve accepted
cohort physical escape/support, progression safe zones, shared hostile ceilings,
server authority, deterministic RNG separation and campaign receipt ownership.
Define finite scope/tuning/campaign gate before edits, with real production
selection/spawn/cleanup effects, not unused metadata. No competing wandering or
history authority. Do not weaken geometry or statistical thresholds for exposure.
Reserve final third for validation, documentation and immediate publication.

Complete campaign/whole-phase brief coverage remains after this slice unless
all exit conditions actually have evidence. Numerical breadth and B20–B22 do
not complete Bestiary. **Do not begin Big Loot, Events or later audits.** No
human runtime/deployment gate precedes the ordered phases/audits.

## Validation truth and cadence

One fresh final canonical run passed **all211 suites with zero failures**; no
gameplay/config/test edits followed. Complete terminal matrix is retained.
Final matrix and campaign measurements: validation/BESTIARY_B22_INTEGRATION.txt
and BESTIARY_B22_CAMPAIGN_FINAL.txt; scope/failures/native limits in BESTIARY_B22.md.
New fixtures prove three ordered phrases, branches, closed gates/event edges,
wrong-sector/coincident/missing routes, deterministic replay, actual placement/
body-enrichment effects and exact objective/motif preservation.12/12 production
counterfactuals change;43 lighter probes,46 probes/34 pressure-spikes observed.

Unchanged32x20 sequential paired campaigns/parties1–4 retain all54 exposure floors
25planned/20legal/5early, minimum36/54 and aggregate memory coverage above control.
Measured mean47.250/min39 versus control40.156/min31;6233 total/4313 discretionary,
2400 geometry preferences,647 selected-candidate preflight rejections. Template
returns191 versus310; within-level repeats576 each; Jaccard0.209819 versus0.207373.
Historical B21 coverage47.562/min43 is slightly higher; no universal improvement
claim. All spacing/admission/budget and existing512-plan companion checks retained.

Pacing:635/640 mixed probe+pressure/spike dungeons, all32 campaigns with branch
spikes;2425 probes mean threat4.350165 versus1888 pressure/spikes6.528549.
Phrase counts816 Surge/884 Ambush/860 Gauntlet. No reserved home admissions.
Retained failed fixture typo repaired; no weakened gates. Engine boundaries are
doubles, not native Source observations. Exact sector diagnostics are in report.

Targeted checks while editing, then `python3 tools/test_checkpoint_g_integration.py`
once stable. Repair attributable failures; broaden only for concrete shared-
authority risk. Update/readback live GDD, manual, ledger, plan, this handoff and
suite registry; commit/publish immediately after green. Retain failed evidence.

After ordered phases/audits, gm_flatgrass tests motif/topology/phrase legibility,
actual spawn substitutions/support/hulls/gates/stairs/Walls/false floors, pursuit/
wanderer convergence, full/reduced tells/audio, HP/XP/drops, death/revival/
disconnect/late join, freeze/reset/rebuild,1–4-player balance/network and
Gordon→Hector→Deborah, sole staging successor, Abundance and Level21 cash.
Evidence console_latest.txt+rpg_summary_latest.txt; session only for ordering.

If CLI push credentials are unavailable, use authenticated GitHub blob/tree/
commit/ref tools; verify every blob and complete tested tree, advance non-forced,
fetch and verify SHA/parent/tree. Preserve newer work; never force.
Order: Bestiary→Big Loot→Event System→systems integration/emergence audit→low-end
PC performance audit→final crash/progression-safety audit→human playtest.
Finish B23 only. End with verified SHA, scope/tests/progress/native checks and
next continuation prompt.
