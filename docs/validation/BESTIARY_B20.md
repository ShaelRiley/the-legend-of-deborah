# Bestiary B20 — campaign-aware encounter ecology

Base: verified remote main `902678fad48142059841e8ad9849dd21e79695bc`.
Scope/gates were authored before implementation in BESTIARY_B20_GATE.md.
Registry remains **63 normal +4 named**, baseline18; no new identities.

## Result and evidence

Six dungeon motifs now restrict discretionary squad selection through the existing
EncounterDirector. Unique eligibility replaces historical duplicate tickets;
exact membership was preserved across154 sector/role combinations. The catalog
covers60 themed+6 common templates and63 identities in14 tactical families.
RunManager owns successful-build history, rebuild replacement and campaign reset.
The live design is LOD-BESTIARY-B20-001 in GDD05/06/07, routed through00/01.

One fresh final canonical run passed **all209 suites with zero failures**. No
gameplay/config/test edits followed. The earlier run failed campaign exposure
and ended without a terminal matrix after suite206; its log is retained as
BESTIARY_B20_INTEGRATION_INITIAL.txt. The fresh final run completed every suite
and the terminal matrix: BESTIARY_B20_INTEGRATION.txt.

| Gate | Evidence |
| --- | --- |
| B20 selection/receipts | Real planning; no history mutation before commit; exact state/graph/plan/prior receipt/level/master-layout seeds/campaign seed/epoch/run binding; one-time commit; same-level rebuild replacement; cleanup preservation; same-seed reset; bounded history through21; primitive-only history and transient reference release. |
| B20 campaign sample | Actual60 themed+6 common provider paths,32 campaigns x20 dungeons, parties1–4; canonical layout retries;640 memory plans paired with640 controls plus32 history-populated replay checks; same motifs/objectives, seeded randomness, budgets and encounter count caps. All54 exposure floors25/20/5 retained, each campaign>=36/54, aggregate memory coverage must exceed control. |
| B20 production lifecycle | Real NewCampaign, BuildCurrentLevel, Regenerate and AdvanceLevel with native construction/release boundaries doubled; no commit on generation or post-plan loot/event build failure; commit after graph/report assignment and before readiness/release; same-seed new owner resets even when first build fails. |
| Retained independent-floor sample | Same512 plans/32 mazes/parties1–4/dungeons1–5,4792 encounters. All existing geometry/companion/singleton restrictions remain. Per-identity count output retained; statistical exposure gating explicitly moved to sequential campaigns, not silently relaxed. |
| Membership reduction | Old and new eligibility functions evaluated side by side for154 combinations; equal membership, new uniqueness. No hard sector/role restrictions removed. |
| Existing regressions | Prior cohorts, registry, defenses/status/HP/XP/drops, spatial admissions, native lifetime/packet ownership, multiplayer/party scaling, gates/rescues, Gordon/Hector/Deborah, sole staging successor, Abundance and Level21. |

The harness loads real Deadcrab/Bio Blaster/Watcher/Seeker providers, in addition
to the existing roster/update harness. Their native timer registration alone is
doubled. Maze and progression generation, template/novelty selection and receipt
semantics are production code. Physical traces and engine actors are boundary
doubles. These results are not Source runtime observation or acceptance.

## Quantitative results

| Metric | Campaign memory | Same motif schedule without template history |
| --- | ---: | ---: |
| Planned encounters | 6247 | 6258 |
| Mean54-specialist coverage | 48.500 | 41.844 |
| Minimum per-campaign coverage | 41 | 36 |
| Cross-level template returns within recent window | 154 | 280 |
| Within-level repeated templates | 528 | 536 |
| Exact consecutive discretionary template sets | 0 | 0 |
| Consecutive roster Jaccard | 0.201329 | 0.197180 |

Coverage improves15.91%; recent template returns fall45%. Jaccard is slightly
higher, not an improvement claim. Common escorts and fallback squads remain
shared. All six motifs occur (109/104/114/99/106/108); none repeats within two
committed dungeons. All54 identities pass25planned/20legal/5early; Pacer34/33/8.
Counts describe planned encounters and legal trace-double placements, not actual
spawn/sighting coverage. The supplied Bestiary attachment is byte-identical to the retained source brief.
Raw counts, failed trials, sample migration and tuning
rationale are in BESTIARY_B20_EXPOSURE.md.

## Design decisions and bounds

- Six disjoint motifs; last two excluded; uniform choice among remaining
  least-used motifs. No change to density, elite tiers or reinforcement probability.
- Unseen template weight3 otherwise1, with separate early-sector appearance memory
  for sectors1–2. Divide by1+4*uses in the current dungeon. Unseen specialist x2,
  recent identity x0.7, recent tactical family x0.8; previous-dungeon template x0.2,
  each of the two older retained occurrences x0.6. Ignore basic escorts for
  themed-squad identity/family scoring; common squads score their entire cast.
- Immediate discretionary-template repeat excluded if an alternative exists.
  Common fallback only if the motif has no eligible template for that sector/role.
  Existing physical admission and spawn-time ordinary-body fallback remain.
- Before/after receipt plus three recent summaries; counts saturate at1,000,000.
  No graphs/entities retained in committed history; no new recurring service.
- Independent named theme and per-cell selection streams; stable sorted IDs.
  Full build success commits once; failed builds do not consume novelty.
- Planned discretionary content alone populates history. Guaranteed objective
  squads, wanderers, named bosses, events and summons remain separate.
- Existing threat formulas, first-encounter exception,0.5 allowance and global
  target80/ceiling96 remain unchanged; no added body or private combat authority.

Manual: **164 chapters/32 chunks**, SHA256
`c83c7a2a2b6f6a181ef1308757cb5d40c12f1a9afc4857decdbee61a65a4aa77`.
`lod_encounter_ecology` reports motif/history/roster/templates/families, each
planned cell/threat, fallback and novelty decisions. The explicit progression
validator registry stays63+4: there are no new actor identities to register.

## Live GDD and remaining work

Read00→01→needed05/06/07 and relevant earlier cohort rules from the live GDD,
not an old export. Trusted read found no protected controls. Wrote delegated
B20 design/lifecycle/tuning; later amendments record balanced theme recurrence
and separate early introduction memory. Final readback/revision recorded below.

Final00/01/05/06/07 connector readbacks confirmed B20 rules, final209-suite evidence,
least-used theme selection, early-introduction tuning and B21 continuation.
Revision: `ANLCKQkGP_StUdL9uxqCV-U7bmh23IboxgbCFGGUFrEUkBGP-gJCI90ygxoR2ZEedrvmnzOwdTP-b2M4Lwd3hCUT53SKbGqccFaAfsrNYw`.

B20 completes this bounded motif/history slice, not the whole Bestiary update.
Next B21: topology-aware composition and spatial pacing at existing director/
geometry seams. Full macro-pacing, wandering-population ecology and complete
campaign-scale exit proof remain before Big Loot/Events and the three audits.
No VPS deployment or Steam Workshop publication occurred.

Native checks after the ordered phases/audits: gm_flatgrass recognizable motifs,
actual squad placement/substitution, counters/coverage and threat reports versus
observed play, theme/rebuild/failure/reset/late join continuity, actual hulls/
support/gates/Walls/false floors, full/reduced tells/audio,1–4-player balance and
networking, prior cohorts and Gordon→Hector→Deborah/staging/Abundance/Level21.
Evidence console_latest.txt+rpg_summary_latest.txt; session log only for ordering.
