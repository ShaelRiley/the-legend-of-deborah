# Bestiary B22 — route-based macro-pacing

Base: verified main `35351d7ee24fda7ba65be65f865c3c1e8bcd3555`.
Finite design/gate fixed before gameplay edits in BESTIARY_B22_GATE.md.
Roster unchanged:63 normal/4 named, frozen baseline18. Bestiary remains open.
No VPS deployment, Workshop publication, new assets or later-phase work.

## Implemented production slice

EncounterDirector computes a spatial phrase for each progression sector, using
its existing Navigator-backed planning BFS filtered to that sector. Entrances:
Start, then preceding gate.afterCell. Goals: corresponding keycards, then CoreCell.
For entry distance a, goal distance b and entrance→goal length L, route progress
is clamp((a-b+L)/2,0,L)/L; branch detour is max(0,(a+b-L)/2). This classifies branch
attachment position using actual routes, not Euclidean proximity or cell ordinals.
A shortcut through another sector, locked gate or event-blocked edge cannot count.

One uniform independently seeded phrase per sector:

| Phrase | Quiet | Probe | Pressure | Recovery |
| --- | --- | --- | --- | --- |
| Surge | [0,0.10) | [0.10,0.35) | [0.35,0.80) | [0.80,1] |
| Ambush | [0,0.20) | [0.20,0.45) | [0.45,0.85) | [0.85,1] |
| Gauntlet | [0,0.10) | [0.10,0.25) | [0.25,0.85) | [0.85,1] |

Quiet/recovery forbid discretionary homes, including fallback. Probe composition
uses scale1 through the existing resolver: authored specialists, companions and
base variation remain. Pressure uses unchanged party/depth scale; detour>=4 in
an active band becomes a full-scale branch spike. No extra scaling, budget
transfer, actor-level change or density increase. Within seeded candidate order,
offer probes until one is admitted, then pressure/spikes, then legacy unavailable
candidates, then remaining probes. Existing budgets/maxima and spacing still bind.

Missing entrance/goal metadata retains ordinary legacy/developer planning with
status unavailable. Existing endpoints without a path are disconnected; entrance
coincident with goal has no positive phrase span and reports coincident. Both
fail closed for discretionary homes. These cases never remove guaranteed fights.

No new Think, combat, navigation, placement or campaign-history authority.
Distance tables are local to planning; primitive tag facts and diagnostic counts
remain on the plan. B20 motifs, isolated ecology RNG and guarded successful-build
history commits remain unchanged. B21 physical preflight/spawn-time revalidation,
4-cell home spacing, safe/objective/escape/role/singleton/companion restrictions,
sector budgets/maxima, first-admission exception,0.5 allowance,target80/ceiling96
remain intact. Objective compositions and locations are unchanged.

This is spatial home placement, not adaptive timed pacing or guaranteed silence.
Wanderers/pursuit, player backtracking and split parties can interrupt respite.
Native recognizability and balance remain unobserved.

## Automated evidence

One fresh final canonical run passed **all211 suites with zero failures**; no
gameplay/config/test edits followed. Complete terminal matrix is retained.

The new production fixture suite proves all three ordered phrases/exact band
boundaries, branch threshold, same-sector distance isolation, wrong-sector origin,
closed gates/event edges, coincident/no-path behavior, missing-metadata fallback,
replay and actual placement/composition consequences. Twelve enriched production
plans all differ from pacing-disabled controls;43 probes have fewer bodies than
full-scale equivalents,46 probes and34 pressure/spike squads are observed.
Authored specialist/companion membership and exact objective/motif invariants pass.
The B21 stale-candidate/collision/selector fixtures also continue to pass.

The unchanged32x20 sequential campaigns with parties1–4 retain all54 exposure
floors25planned/20legal/5early, minimum36/54 each campaign, aggregate memory
coverage above paired control and every topology/admission/spacing/budget check.
B22 adds reservation and composition-scale assertions to both paths, plus its
predeclared pacing thresholds. Existing512 independent plans retain full
geometry/companion/singleton contracts. Final campaign and integration output:
BESTIARY_B22_CAMPAIGN_FINAL.txt and BESTIARY_B22_INTEGRATION.txt.

| Metric | Memory | Same motifs/pacing; template history disabled |
| --- | ---: | ---: |
| Encounters | 6233 | 6235 |
| Mean specialist coverage /54 | 47.250 | 40.156 |
| Minimum coverage /54 | 39 | 31 |
| Cross-level template returns | 191 | 310 |
| Within-level template repeats | 576 | 576 |
| Exact consecutive template sets | 0 | 0 |
| Consecutive roster Jaccard | 0.209819 | 0.207373 |

Memory coverage is17.67% above control. Coverage is slightly below B21's47.562/
minimum43, still above the unchanged finite gate. No universal diversity
improvement claim. Motif counts remain109/104/114/99/106/108 with no repeat in the
last two committed dungeons. Of4313 discretionary selections,2400 receive geometry
preferences; selected-candidate preflights reject647 motif templates.

Pacing:635/640 dungeons(99.22%) contain probes and pressure/spikes; all32 campaigns
contain branch spikes.2425 probes mean threat4.350165;1888 pressure/spikes mean
6.528549(919 pressure,969 spikes). Phrase counts: Surge816,Ambush884,Gauntlet860.
Cell classifications across all2560 sectors: quiet69584,probe39407,pressure79934,
recovery43034,spike151505,unreachable565. These count all tagged cells, including
safe/objective locations; they are not usable-cell or traversal-time estimates.
2555 sectors have a positive route span;5 have coincident entrance/goal. No
sampled sector is disconnected. Coincident sectors retain objectives but no
discretionary homes; their565 tags appear in the unreachable-band count.
All reserved-band admissions remain zero. No native entities/traces measured.

## Retained intermediate evidence and limits

- BESTIARY_B22_TARGETED_INITIAL.txt: existing B20/B21 fixtures pass initial pacing.
- BESTIARY_B22_FIXTURES_INITIAL.txt: new fixture failed on misspelled corridor
  helper, before its assertions ran. Production behavior was unaffected; typo
  repaired. SECOND then FINAL outputs preserve passing evidence and final added
  wrong-sector/coincident-route checks. No weakened threshold.
- BESTIARY_B22_CAMPAIGN_INITIAL.txt: unchanged campaign gate passes before adding
  B22 measurements. BESTIARY_B22_CAMPAIGN_PACING.txt adds passing pacing thresholds.
  The initial diagnostic called every nonpositive route disconnected; final
  diagnostics distinguish coincident endpoints. No placement or sample change.
- All engine traces/entities are doubles. No Source observation, runtime
  acceptance, native collision proof, combat-free traversal or FPS claim.

## Design, presentation and continuation

Live GDD00→01→05/06/07 under LOD-BESTIARY-B22-001 records implemented design,
exact tuning, ownership and evidence. Trusted read found no protected controls.
Final connector readbacks verified every added/refined B22 paragraph and current
00/01 routing across05/06/07. Live revision:
`ANLCKQmNNkdAZ_gyqHPJmVz7rUNzjvAhy29PLFEvq8LC4fVUxHGf6JiceLAsxpH-OmGAxIY5q-nZQJY4zRi6-QdO2VJDYuuCehNaWGGBAA`.
Manual164 chapters/32chunks, source SHA256
`8d54caf1587b9b18801f0db2fe6f876d213376b3e92ce878b3ec05a62536e738`.
Existing ecology chapter explains spatial rhythm/probes/branches and its limits.
The canonical integration suite registry includes B22; actor registry unchanged.

Next B23: bounded wandering-population ecology through the existing wandering
owner and current motif context, with explicit compatibility/RNG/lifecycle/ceiling
proof. Full campaign and whole-Bestiary exit evidence remains before Big Loot,
Events or later audits. Do not declare the phase complete from roster breadth.
Native gm_flatgrass after ordered phases/audits: motif/topology/phrase legibility,
actual support/hulls/gates/stairs/Walls/false floors, spawn substitutions, pursuit/
wanderer convergence, full/reduced tells/audio,1–4-player balance/network,
HP/XP/drops and death/revival/disconnect/late join/reset/rebuild; preserve
Gordon→Hector→Deborah, sole staging successor, Abundance and Level21 cash.
Evidence console_latest.txt+rpg_summary_latest.txt; session only for event order.
