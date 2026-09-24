# Handoff — Bestiary B24

Resume **The Legend of Deborah** and complete **Bestiary checkpoint B24 only**,
including authorized design, implementation, validation, documentation, commit
and verified non-forced push to `main`.

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
Latest checkpoint: **Integrate motif-aware wandering population ecology**.
The publication response supplies its exact verified SHA; fetch current main,
confirm this checkpoint and preserve intervening work. B23's parent is
`b731d8b42933076b223f8607d1067486eb937cc9`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.

I authorize implementation, necessary refactoring, design/tuning decisions,
compatible existing assets, naming, UX, tests, diagnostics, documentation, live
GDD amendments, focused parallel delegation, commits and non-forced pushes to
main. Resolve ordinary ambiguities. **Do not deploy to the VPS or publish to
Steam Workshop.**

Read AGENTS.md, active/newest DEVELOPMENT_PLAN.md checkpoint, this handoff,
BESTIARY_EXPANSION.md and briefs/BESTIARY_UPDATE.md. Live GDD00→01→needed tabs,
including LOD-ROADMAP-ECOSYSTEM-001 and LOD-BESTIARY-B20/B21/B22/B23-001 in05/06/07.
Exact HUMAN anchors only for required missing detail. Missing historical art
is not blocking. Do not restart broad roster archaeology or prior work.

## Current B23 implementation

WanderingDirector remains the sole roaming owner; it reads the current plan
motif without mutating campaign receipts. Explicit solitary pools contain the
actual8 legacy roamers plus Siphoner/Caromer/Reaper/Redliner/Drubber/Afterburst.
These6 are not new counted identities. Prior no-wandering exclusions are
superseded only for these autonomous actors; no escort-dependent support,
stationary/trap, ally-link, corpse-consumer or boss actor becomes a solo wanderer.
Older HUMAN named Sniper/Blitzer but production never registered their roaming
weights; they remain excluded in B23, with discrepancy documented in live GDD.

Motif weights: corruption shambler20/runner10/deadcrab30/bioblaster25/siphoner10/
flamer5; crossfire soldier40/bioblaster25/runner15/seeker10/caromer10; hunting
runner50/deadcrab30/watcher10/reaper10; occupation soldier60/runner20/redliner20;
quarantine shambler30/soldier30/runner20/drubber20; retinue shambler60/deadcrab20/
afterburst20. Unknown motif uses actual legacy45/25/12/10/8/4/4/3 table. Divide
by1+living same-ID count; omit last successful ID with alternatives; retain
endless non-Shambler/non-Runner weight. Specialist cap4/floor and1/identity;
five original basics exempt. Six new specialists require sector2+ arena/ambush
homes, Flamer sector2+. Existing attacks and runtime escape/support remain.

Target16/floor,1 replacement/20s with existing endless scaling, acquire4/
disengage6 on same floor, patrol3–8 and phased schedules remain. No unsafe
fallback: exclude safe/boss/objective/gate/stair, occupied roaming homes, nearby
Heroes within4 reachable cells and quiet/recovery/disconnected/coincident home
bands. At most24 shuffled candidates/attempt, max1.33 hull clearance/support and
live EnemyRoster.Placement. Spawn/SnapSpawn/Activate survival plus exact-owner,
floor cap and shared96 ceiling checks precede registry admission. Native callback
reset cannot leak a new actor. Failed admission defers; roaming/pursuit can still
interrupt quiet bands. No altered stats, rewards, density target or new hook.

Exact state/graph/level/seed/campaign/epoch/run binds local service. Replaced
state/same-seed rebuild clears old bodies; canonical EncounterDirector.Cleanup
resets roaming ordinals/choices/timers/diagnostics without erasing receipts.
Named floor/attempt/candidate RNG does not consume plan/history/global streams.
lod_m3_wanderers reports motif, living identity counts, specialist cap and defer
reason. Manual164 chapters/32chunks explains actual behavior.

## Retained B20–B22 constraints

B20: six motifs,60 themed+6 common templates,63 normal identities/14 families,
4 named bosses, frozen baseline18. Exclude last2 committed motifs, uniform among
eligible least-used. Template unseen weight3 else1, early-history sectors1–2/
all-history later; divide1+4*current uses; unseen specialist x2, recent enemy x0.7,
family x0.8, last-dungeon template x0.2, older2 x0.6. Exclude immediate template
repeat with alternatives. RunManager owns successful-build before/after receipts,
committed after full physical build/graph/report assignment and before release.
Failed builds consume nothing; same-level rebuild replaces from before; successor
uses after; cleanup retains; new campaign resets even with same seed. History
contains3 primitive recent summaries, counts cap1,000,000, no graph/entity refs.

B21: physical Placement preflight before motif selection, common fallback only
when no legal motif survives, native geometry revalidation/ordinary substitution.
Real same-sector topology, clear firing lanes, alternate routes, vertical and
objective access affect weights; strongest preference only2/1.5/1.25/1. Recheck
4-cell home spacing after every discretionary admission, including objectives.
Keep safe/transition/role/sector/singleton/companion/escape contracts, budgets,
first-admission exception/0.5 allowance, sector maxima and target80/ceiling96.

B22: route entrance→keycard/CoreCell distance maps use same-sector Navigator.
Progress=clamp((a-b+L)/2,0,L)/L; detour=max(0,(a+b-L)/2). Surge/Ambush/Gauntlet
cumulative quiet/probe/pressure boundaries10/35/80%,20/45/85%,10/25/85%.
Quiet/recovery forbid discretionary homes; probes retain full base template at
scale1, pressure and active-band detour>=4 spikes use existing full enrichment.
Prefer one probe then pressure/spikes; guaranteed objectives stay exact.
Missing endpoint metadata retains diagnosed legacy planning; no positive span
fails closed. Local distance maps only, no recurring phase/history service.

## Validation truth

One fresh final canonical run passed **all213 suites with zero failures**;
no gameplay/config/test edits followed. Complete terminal matrix is retained.
The unchanged encounter campaign gate retains all54 exposure floors25/20/5 and
minimum36/54; measured mean47.250/min39 versus control40.156/min31, identical to
B22.6,233 encounters/4,313 discretionary; all geometry/spacing/budget,635/640
mixed pacing and32/32 branch-campaign gates remain green. Manual checks passed.
The final32x20 sequential campaign sample spawns28,389 motif-selected bodies
and28,389 legacy-weight control bodies. All640 dungeon populations change under
motif selection.1,752/1,789 floors fill16 slots initially;37 floors defer235 total
slots under the same safety rules in both arms. No unsafe fallback is used.
New-specialist exposure: Siphoner229,Caromer241,Reaper261,Redliner238,Drubber255,
Afterburst255 (each required>=25). All floor/singleton/specialist/shared caps,
geometry/role rules, exact plan/receipt identity and deterministic replay pass.

Final matrix/campaign files: validation/BESTIARY_B23_INTEGRATION.txt,
BESTIARY_B23_CAMPAIGN_FINAL.txt and BESTIARY_B23_ENCOUNTER_FINAL.txt.
Finite scope/failures/native limits: BESTIARY_B23_GATE.md and BESTIARY_B23.md.
The new campaign comparison changes only motif pool versus legacy weights,
retaining new safety/count/no-repeat policies. It is not native combat/sighting
or full old-system comparison. Engine entities/traces/clocks are doubled.
Retain the initial fixture Fraction error and pre-final-guard sample honestly.

## Complete B24 — whole-Bestiary exit reconciliation and bounded closure

Reconcile the full brief/phase exit against implemented production behavior and
existing campaign evidence. Identify concrete unmet requirements, contradictions
or unproven coverage; distinguish required closure from illustrative examples.
Define a finite B24 production/campaign gate before edits, implement any necessary
bounded closure through existing authorities, and prove the result. Do not spend
the checkpoint merely recounting63 identities or restating B20–B23.

Preserve all existing thresholds and native gaps. Do not weaken physical escape,
support, companion, progression, RNG, receipt or entity rules to improve exposure.
Use fixed reproducible comparative metrics for remaining campaign novelty/
repetition/coherence claims; generated plans and native-boundary spawns are not
player sightings or Source runtime acceptance. Consider interaction between
encounter homes, wandering convergence and theme/pacing guarantees without
inventing a second director/history owner. Phase completion requires evidence
for every actual brief exit condition; if gaps remain, state the next bounded
Bestiary slice. **Do not begin Big Loot, Events or later audits in B24.**

Reserve final third for validation, docs and immediate publication. Targeted
checks while editing, then `python3 tools/test_checkpoint_g_integration.py` once
stable. Use LOD_B23_REPORT_PATH and LOD_B20_REPORT_PATH to retain final campaign
measurements. Repair attributable failures; broaden only for concrete risk.
Update/readback GDD, manual when needed, ledger, plan, handoff and suite registry;
commit/publish immediately after green. No human/deployment gate before phases.

Later gm_flatgrass acceptance covers motif/topology/phrase readability, actual
spawn support/substitution/hulls/gates/stairs/Walls/false floors, pursuit/wanderer
convergence, full/reduced tells/audio, HP/XP/drops, death/revival/disconnect/late
join, freeze/reset/rebuild,1–4-player balance/network and Gordon→Hector→Deborah,
sole staging successor, Abundance and Level21 cash. Evidence console_latest.txt
+rpg_summary_latest.txt; session only for ordering. Deployment needs authorization.

If CLI push credentials are unavailable, use authenticated GitHub blob/tree/
commit/ref tools; verify every blob and complete tested tree, advance non-forced,
fetch and verify SHA/parent/tree. Preserve newer work; never force.
Order: Bestiary→Big Loot→Event System→systems integration/emergence audit→low-end
PC performance audit→final crash/progression-safety audit→human playtest.
Finish B24 only. End with verified SHA, scope/tests/progress/native checks and
next continuation prompt.
