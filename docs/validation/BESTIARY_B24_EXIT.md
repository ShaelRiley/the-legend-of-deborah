# B24 — whole-Bestiary exit reconciliation

**Bestiary remains open.** B24 closes planned-encounter/roaming-home overlap and
adds enforceable comparative campaign evidence. B25 must resolve motif-driven
intensity, including the conflict between requested elite probability variation
and the existing universal tier law. Native acceptance remains a separate later
evidence stage; it is not the reason to defer this production requirement.

Authority: `docs/briefs/BESTIARY_UPDATE.md`; frozen roster and authored identity
evidence: `docs/BESTIARY_EXPANSION.md`. Paths below beginning `sv_`/`cl_` are
relative to `gamemodes/legend_of_deborah/gamemode/lod/`.

## Definition-of-done accounting

| Brief exit | Implemented evidence and remaining obligation |
| --- | --- |
| 1. Approximately 3.5× normal roster | Implemented: frozen18→63,45 additions,14 counterplay families. Ledger counting contract excludes cosmetic/tier/class permutations and named bosses. No recount in B24. |
| 2. Existing assets; distinct learnable identities | Implemented: B1–B19 ledger specifies stock models, warning geometry, colors and counterplay; `sv_enemy_roster.lua`, `cl_enemy_roster.lua` and cohort production/visual suites cover the shared behavior/presentation. Actual silhouette, tell and audio readability remains native-unaccepted. |
| 3. Broader use of existing systems | Implemented: ledger cohorts exercise control, support, reactions, projectile geometry, traps, remains, positioning, ambush, resource pressure and ally links. Existing cohort tests validate their production boundaries; emergent combat quality still needs native observation. |
| 4. Campaign-aware ecology | Implemented: `sv_encounter_ecology.lua` and catalog own motif/template selection; RunManager owns successful-build before/after receipts. B20 lifecycle/campaign tests execute those authorities. Motif intensity is incomplete. |
| 5. Recognizable nondeterministic themes | Partial: six motif template pools and B23 roaming pools materially change generated populations. B24 measures aggregate family influence. Recognition is a native question; explicit intensity dimensions remain B25. |
| 6. History suppresses repetition | Implemented: last-two motif exclusion, recent enemy/family/template penalties, novelty weights and within-dungeon anti-repeat. B24 adds a fixed minimum25% reduction in adjacent-dungeon template returns against the same-motif memory-disabled control. Final measured result belongs to the evidence files below. |
| 7. Maze topology affects placement | Implemented: B21 physical preflight plus real graph/trace preferences and refreshed4-cell encounter spacing. `sv_enemy_roster_placement.lua` remains admission authority; actual engine hull/geometry behavior is a native gate. |
| 8. Coherent tactical syntax | Implemented compositions:60 themed templates plus6 common fallbacks preserve specialist/escort and companion contracts. B24 asserts motif membership and protects dormant squad homes. Natural pursuit/roaming convergence can still mix groups; perceptual coherence is not proven by a composition table. |
| 9. Strong coverage and substantially reduced repetition | Existing B20–B23 gates retain54 specialist exposure floors and minimum36/54 per campaign. B24 adds the comparative repeat gate and combined-population domination/family gates. Publication requires the fresh final reports; no claim that every repetition statistic improves. |
| 10. Determinism/progression/multiplayer/performance preserved | Shared authorities retain receipt ownership, seed streams, eligibility, activation/hostile ceilings and lifecycle rules. B24 adds no Think hook, new owner, actor, reward or density increase. Canonical integration is the static regression gate; real1–4-player balance/network/progression remains native-unaccepted. |
| 11. Relevant automated suites pass | Focused `tools/test_bestiary_b24.lua` exercises production home reservations. Final canonical matrix, including inherited cohort/campaign suites, is required before publication; see evidence links below. |
| 12. GDD and checkpoint documentation accurate | B24 publication requires live GDD amendment/readback plus manual, ledger, plan and handoff updates. This reconciliation explicitly leaves intensity unresolved rather than documenting it as implemented. |
| 13. Committed | Publication obligation; resulting commit is recorded in the publication response/checkpoint evidence, not inferred from this file. |
| 14. Verified remote main contains commit | Publication obligation; verify non-forced push and remote containment, preserving intervening work. No VPS/Workshop action is authorized. |

## Substantive requirements beyond the exit checklist

Brief §§2–6 require meaningful stable identities, systemic roles, readable
counterplay and economical asset reuse. The ledger and cohort suites are their
implemented/static evidence. The niche list explicitly says not to implement
every idea; the sample family pattern and named floor themes are illustrations,
not missing-content tickets. A summoner, darkness specialist or every listed
ecology label is not automatically required. Soft answers and shared status/
combat authorities must remain; static tests do not establish player learning.

The §8 influence list is substantive and must be reconciled dimension by
dimension:

| Theme influence | Current production | Exit status |
| --- | --- | --- |
| Family prevalence | Motif-restricted templates plus explicit solitary roaming pools | Implemented; B24 quantifies combined family distributions. |
| Template availability | Legal motif intersection; common fallback only if no legal motif template survives | Implemented; retain geometry/role restrictions. |
| Squad composition | Authored specialist/escort templates and shared enrichment | Implemented; companion contracts remain mandatory. |
| Density | Templates have different body/threat costs under existing budgets; roaming target remains16/floor | Indirect influence only; explicit motif intensity/density contract remains B25. |
| Reinforcement probability | Roaming replacement remains one/20s, with existing endless scaling; no motif-dependent scheduling | Unresolved B25; identify a lawful bounded interpretation through the existing owner. |
| Elite probability | `sv_character_progression.lua:TierForRoll` retains typical/elite/champion60/30/10, with a separate deterministic tier stream | Unresolved design reconciliation in B25; do not silently retune this universal law or equate specialist identity with elite tier. |
| Environmental positioning | Template membership feeds B21 topology preferences and physical Placement | Implemented; native firing lanes, escape routes and support remain acceptance work. |
| Pacing | B22 sector phrases are seeded independently of motif | Macro-pacing exists, but explicit motif influence remains B25. |
| Occasional visual treatment where supported | Stable identity visuals change the visible cast | No new external assets. Do not claim a separate floor-wide visual treatment; optional conditional treatment is not a mandatory art expansion. |

Brief §§7,9–13 require ecology, history, campaign visibility, tactical syntax,
topology and breathing room. B20–B23 implement these through existing authorities.
B24 addresses a concrete interference: `_SpawnCandidates` now rereads all planned
encounter home cells on each scan, including dormant discretionary squads. It
excludes exact cells, not a new four-cell roaming perimeter. Fully reserved
floors defer. `tools/test_bestiary_b24.lua` verifies initial/replacement exclusion,
changed plans/lists, missing-plan compatibility and unchanged receipts. Idle
patrol and pursuit may still enter quiet/recovery bands or converge with squads;
home reservations are not invulnerable resting zones or guaranteed separate
combat events. Native observation must assess the resulting phrase readability.

Brief §§14–16 and19 require reproducibility, server authority, finite entity
cost and protected game systems. Production selection/spawning stays server-side;
RunManager owns history, EncounterDirector owns squads, WanderingDirector owns
roamers, and Placement/Navigator retain geometry/traversal authority. B24 creates
only a local reservation set during an existing scan. Existing successful-build,
failed-build/rebuild/reset, specialist/companion/singleton, ceiling and progression
regressions remain required. No automatic test proves native performance or all
multiplayer timing outcomes.

Brief §17 diagnostics are implemented through `lod_encounter_ecology` and
`lod_m3_wanderers`: motif, roster subset, templates, family counts, per-encounter
cell/threat/objective data, prior-template appearances, candidate/fallback/
topology decisions, pacing bands, roaming identity counts/caps and defer reasons.
Named specialist encounters can be identified from these template/roster records;
there is no separate universal rare-encounter scheduler or claimed native sighting
counter. B25 should expose its chosen intensity/tier decisions through these
existing commands, without inventing a parallel diagnostic service.

Brief §18 requires multiple quantitative indicators. The B24 gate retains the
fixed32×20 sequential sample and all earlier thresholds, while checking actual
basic IDs (`shambler`, `runner`, `soldier`, `deadcrab`, `bioblaster`) in combined
planned ordinary squads plus initial roaming bodies. Each campaign must keep its
largest basic share at or below50%, expose at least10/14 families, and preserve
motif membership. All six motifs must change aggregate family distributions
against the legacy-weight roaming arm. These are gross-pathology guards, not a
claim that common actors disappear, that every floor is diverse, or that each
actor is simultaneously alive. Roster Jaccard and within-dungeon repetition are
reported even when they do not improve. The paired encounter-memory control and
paired roaming-pool control isolate different interventions; neither represents
the complete pre-Bestiary game.

Brief §20 canonicalization is a publication obligation, including honest open
requirements. B24 must update/read back the live GDD; this repository document
does not substitute for that design authority.

## Evidence and finite next checkpoint

Acceptance thresholds were fixed before edits in `BESTIARY_B24_GATE.md`.
Final publication evidence is linked by `BESTIARY_B24.md`, with the fresh matrix
in `BESTIARY_B24_INTEGRATION.txt` and campaign reports in
`BESTIARY_B24_CAMPAIGN_FINAL.txt` / `BESTIARY_B24_ENCOUNTER_FINAL.txt`. The final canonical run passed214 suites with zero failures. Its measured
campaign results are in those final artifacts; do not substitute the initial
run for the canonical matrix. Earlier failed evidence remains preserved. Source entities, traces and clocks are doubled in these harnesses.

**B25: bounded motif-intensity closure.** Reconcile the live GDD's theme influence
requirements with its universal60/30/10 tier law before editing. Resolve whether
lawful encounter selection can satisfy the intended elite influence or whether
an explicit authorized design amendment is necessary; never silently change tier
odds, actor Levels, rewards or existing guaranteed squads. Define finite seeded
comparisons for motif-driven density, reinforcement and pacing through current
EncounterDirector/WanderingDirector/CharacterProgression authorities, preserve
every exposure/spacing/geometry/receipt/cap threshold, and extend existing
diagnostics. No second director/history owner and no Big Loot, Events, later
audits or deployment. Native `gm_flatgrass` readability, convergence, collision,
combat, lifecycle, network and progression acceptance remains separately pending.
