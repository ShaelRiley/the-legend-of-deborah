# Handoff — Bestiary B21

Resume **The Legend of Deborah** and complete **Bestiary checkpoint B21 only**,
including authorized design, implementation, validation, documentation, commit
and verified non-forced push to `main`.

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
Latest checkpoint: **Add campaign-aware encounter themes and novelty memory**.
The publication response supplies the exact verified SHA; fetch current main,
confirm this checkpoint and preserve intervening work. B20's parent is
`902678fad48142059841e8ad9849dd21e79695bc`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.

I authorize implementation, necessary refactoring, design/tuning decisions,
compatible existing assets, naming, UX, tests, diagnostics, documentation, live
GDD amendments, focused parallel delegation, commits and non-forced pushes to
main. Resolve ordinary ambiguities. **Do not deploy to the VPS or publish to
Steam Workshop.**

Read AGENTS.md, active/newest DEVELOPMENT_PLAN.md checkpoint, this handoff,
BESTIARY_EXPANSION.md and briefs/BESTIARY_UPDATE.md. Live GDD00→01→needed tabs,
including LOD-ROADMAP-ECOSYSTEM-001 and LOD-BESTIARY-B20-001 in05/06/07.
Exact HUMAN anchors only for required missing detail. Missing historical art
is not blocking. No chat archaeology or repeated broad roster audit.

## Current B20 implementation

EncounterDirector chooses one dungeon motif: Hunting Grounds, Occupation,
Corruption, Crossfire, Quarantine or Funeral Retinue. Each has nine of54 specialist
identities plus appropriate legacy templates. Catalog60 themed+6common templates;
all63 normal identities have one of14 tactical families. No roster additions.
Exact existing eligibility sets survive removal of960 lines of duplicate weighting
history. Guaranteed objectives, wanderers, bosses and events retain their owners.

Exclude the last two committed motifs, choose uniformly among eligible least-used
motifs, then select from that motif's eligible templates; common fallback only
where the motif has no eligible choice. Unseen-template weight3 else1; sectors1–2
use early-template history, sectors3–4 all-template history. Divide by1+4*current
uses, unseen specialist x2, recent enemy x0.7, recent family x0.8, most recent
matching template x0.2, two older retained matching templates x0.6. Basic escorts
do not mask specialist novelty; common squads score their entire cast. Exclude
an immediate template repeat where alternatives exist. Stable named RNG streams.

RunManager.State owns before/after receipts and three recent primitive summaries.
Commit only after the entire physical builder succeeds, graph/report assigned,
before readiness/release. Exact graph/plan/previous receipt/state/level/seed/epoch/
run guards; failed builds do not consume history. Same-level rebuild/seed override
reuses before and replaces current receipt; next level uses after; cleanup retains
memory; new campaign resets even same seed. Counts saturate1,000,000. No graph/
entity refs in history. This accounts planned squads, not actual sightings.

Threat scaling, first-encounter exception/0.5 allowance, sector maximums,
physical admission and ordinary-body fallback, target80/ceiling96 unchanged.
`lod_encounter_ecology` reports theme, roster/templates/families, fallback/novelty
and per-encounter cell/threat. Manual164 chapters/32chunks. Registry63 normal+4
named; breadth63/63 is complete, **the Bestiary phase is not**.

## Complete B21 — topology-aware composition and spatial pacing

Define and implement the next coherent production slice through existing
EncounterDirector, graph tags/navigation and physical admission authorities.
Reconcile actual alternate routes, junctions/corners, corridors, vertical
transitions, approach/retreat options and objective proximity with the expanded
roster's tactical roles and current motif selection. Prefer complete usable
selection/admission behavior over unused metadata or more roster breadth.

Author finite scope/tuning/measurable gate before edits. Preserve motif/history
ownership and independent RNG, avoid duplicate placement/selection authorities,
and keep entity/threat/solvability/progression guarantees. Investigate the actual
candidate/spacing path before assuming precomputed candidate eligibility remains
valid after an encounter is placed. Do not weaken existing physical escape or
cohort restrictions to improve statistical exposure. Retain all failed evidence.

Macro-pacing, wandering-population ecology and full campaign-scale coverage
remain Bestiary obligations; record portions beyond bounded B21 honestly. A single
dungeon need not show every family. No “whole Bestiary complete” claim until every
brief exit condition has proof. **Do not begin Big Loot, Events or later audits.**
Preserve all prior cohort mechanics, finite warnings/recovery/solo escape, native
life/callback/packet ownership, ordinary statuses/defenses/HP/XP/drops, genuine
movement, no hidden tracking/catch-up, and Gordon→Hector→Deborah, sole staging
successor, Abundance and Level21 cash.

## Validation truth and cadence

One fresh final canonical run passed **all209 suites with zero failures**; no
gameplay/config/test edits followed. Matrix: BESTIARY_B20_INTEGRATION.txt. Earlier
failed/incomplete integration output is retained separately, not rewritten.
B20's final full-template paired sample:32 campaigns x20 dungeons, parties1–4,
6247 encounters; average48.500/54 specialists (minimum41), control41.844. All54
pass25planned/20legal/5early. Pacer34/33/8. Cross-level template returns154 versus
280; within-level repeats528 versus536; consecutive roster Jaccard0.201329 versus
0.197180 (not an improvement claim). Six motif counts109/104/114/99/106/108, no
repeat within two committed levels. Sample loads all60 themed+6common production
providers. Initial omitted legacy modules, failed weighting trials and repairs
are retained in BESTIARY_B20_EXPOSURE.md. No threshold or seed weakening.

The old512 independent-floor sample retains all geometry/companion gates and
comparable count output (4792 encounters); its exposure assertions moved explicitly
to sequential campaigns because independent floors do not exercise history.
Native Source acceptance remains pending; boundary doubles are not observations.

Reserve final third for validation, repair, docs and publication. Targeted tests
while editing, then `python3 tools/test_checkpoint_g_integration.py` once stable.
Repair attributable failures; broaden only for concrete shared-authority risk.
Update/read-back verify live GDD, manual, ledger, plan and handoff with evidence,
counts/native checks/next slice. Keep validator registry synchronized. Commit and
publish immediately after green validation.

After ordered phases/audits, gm_flatgrass validates recognizable ecology, real
placement/ordinary fallback, solo routes/support/hulls/gates/Walls/false floors,
full/reduced warnings/audio, HP/XP/drops, death/revival/disconnect/late join,
freeze/reset/same-seed rebuild,1–4-player balance/network and complete campaign.
Evidence console_latest.txt+rpg_summary_latest.txt; session log only for ordering.
No human runtime/deployment gate precedes ordered phases.

If CLI push credentials are unavailable, use authenticated GitHub blob/tree/
commit/ref tools; verify each blob and complete tested tree, advance non-forced,
fetch and verify SHA/parent/tree. Preserve newer work; never force.
Order: Bestiary→Big Loot→Event System→systems integration/emergence audit→low-end
PC performance audit→final crash/progression-safety audit→human playtest.
Finish B21 only. End with verified SHA, scope/tests/progress/native checks and
next continuation prompt.
