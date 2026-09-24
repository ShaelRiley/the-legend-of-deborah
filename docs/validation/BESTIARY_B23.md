# Bestiary B23 — bounded wandering-population ecology

Base: verified `main` `b731d8b42933076b223f8607d1067486eb937cc9`.
Scope/gate was frozen before gameplay edits in `BESTIARY_B23_GATE.md`.
GDD00→01→05/06/07 and the exact HUMAN wandering paragraph were reconciled;
LOD-BESTIARY-B23-001 records the author-delegated exception to older universal
Shambler weighting and six cohorts' encounter-only selection restriction.
No new normal identities:63 normal/4 named; baseline18 remains frozen.

## Production slice

The existing WanderingDirector reads EncounterPlan.ecology.theme. Six explicit
solitary pools expose14 eligible identities: eight actual legacy roamers plus
Siphoner, Caromer, Reaper, Redliner, Drubber and Afterburst. Sniper/Blitzer were
listed in old HUMAN prose but never registered in production wandering weights;
this checkpoint records that discrepancy and leaves them excluded. Every other
identity stays excluded, especially stationary/trap, support, companion-link,
corpse-consumer and named-boss actors. No mandatory escort is silently discarded
from an encounter template: these are separately authored solitary pools.

Weights and exact policy are in the gate and live tab07. At most4 specialists
per floor,1 per specialist identity; the five original basics are exempt. New
six specialists require sector2+ arena/ambush homes; Flamer sector2+. Existing
Placement and runtime attacks/escape/support checks remain. Divide weights by
1+current same-ID living count; exclude last successful ID with alternatives.
Keep existing endless weighting,16/floor target, one replacement/20s with endless
cadence, same-floor acquire4/disengage6, patrol3–8 and phased route/target work.

No fallback beside Heroes or into safe/boss/objective/gate/stair/reserved pacing
homes. Exclude occupied roaming homes and distance<4 traversable cells from
Heroes. At most24 shuffled candidate checks; require max1.33 hull clearance,
physical support and live specialist Placement. Native Spawn/SnapSpawn/Activate
must leave a valid body; settlement failure or native callback reset cannot
register a stale actor. Canonical shared hostile registry enforces ceiling96
before and after native calls, and per-floor target is checked again. Deficits
wait for existing replacement service. No higher density or new attack tuning.

Exact state/graph/level/seed/campaign/epoch/run ownership guards spawning and
service. EncounterDirector.Cleanup retires wandering bodies and resets local
ordinals, choices, timers and diagnostics. Replaced state, including same-seed
rebuild, is not the old owner. Campaign receipts remain untouched. RNG remains
named floor/attempt/candidate streams, never plan/history/global consumption.
No new recurring hook, combat, navigation, placement or history authority.

lod_m3_wanderers now shows motif, actual living identity counts, specialist cap
and last spawn/defer result. Manual ecology chapter explains changing roamers,
solitary eligibility, finite replacement and possible convergence into respite.
Manual remains164 chapters/32 client chunks.

## Validation and limitations

One fresh final canonical run passed **all213 suites with zero failures**;
no gameplay/config/test edits followed. Complete terminal matrix is retained.
The unchanged encounter campaign gate retains all54 exposure floors25/20/5 and
minimum36/54; measured mean47.250/min39 versus control40.156/min31, identical to
B22.6,233 encounters/4,313 discretionary; all geometry/spacing/budget,635/640
mixed pacing and32/32 branch-campaign gates remain green. Manual checks passed.

Production fixtures execute actual selection, spawn, Think, patrol-route and
cleanup methods with Source entity/trace/clock boundaries doubled. They cover
motif membership, role/sector gates, singleton/floor/shared caps, last-ID
suppression, geometry/support failure, player clearance,24-candidate bound,
phased schedules,20-second one-body replacement, freeze/failure/clear/not-ready,
native create/spawn/settle/activate failure, reentrant reset, exact owner changes,
canonical cleanup and unchanged receipt/plan replay. Earlier cohort suites retain
attack, physical escape/support, progression/HP/XP and finale contracts.

The fixed32x20 sequential campaign sample cycles parties1–4, commits real plans
through existing receipts, then invokes real native-boundary spawn service for
motif and legacy-weight control on identical plans/seeds. Control disables only
motif pool choice; it retains all new safety/cap/no-repeat/live-count rules. This
is not a measurement of the complete old wandering implementation, sightings,
combat difficulty, native timing or total campaign enemy diversity/repetition.

The final32x20 sequential campaign sample spawns28,389 motif-selected bodies
and28,389 legacy-weight control bodies. All640 dungeon populations change under
motif selection.1,752/1,789 floors fill16 slots initially;37 floors defer235 total
slots under the same safety rules in both arms. No unsafe fallback is used.
New-specialist exposure: Siphoner229,Caromer241,Reaper261,Redliner238,Drubber255,
Afterburst255 (each required>=25). All floor/singleton/specialist/shared caps,
geometry/role rules, exact plan/receipt identity and deterministic replay pass.

The existing encounter campaign gate remains unchanged: all54 specialists meet
25planned/20legal/5early, minimum36/54 per campaign, paired memory-control coverage,
B21 spacing/admission and B22 probe/pressure/reservation gates. No threshold,
seed schedule, geometry condition, or companion contract was weakened.

Retained evidence: `BESTIARY_B23_FIXTURES_INITIAL.txt` records a fixture failure
(the support trace double omitted Fraction, required by real planning LOS).
The corrected fixture passed in SECOND. The initial campaign passed before the
final native callback ownership guard; FINAL fixtures and canonical integration
validate that guard. No failed production case was hidden or threshold relaxed.

Native Source acceptance remains outstanding: model/animation/tells, actual
floor/hull/Wall/false-floor interactions, pursuit/wanderer convergence and motif
legibility,1–4-player balance/networking, death/revival/late join/disconnect,
freeze/reset/rebuild, and complete Gordon→Hector→Deborah/staging/Abundance/Level21
continuity. No VPS or Workshop operations occurred.

Next B24: reconcile the entire Bestiary brief against production/campaign
coverage, close demonstrated remaining gaps in a bounded slice, and declare the
phase complete only if all exit conditions have evidence. Do not automatically
advance to Big Loot, Events or later audits. Human testing follows ordered phases
and audits; retained native gaps do not block the authorized next checkpoint.
