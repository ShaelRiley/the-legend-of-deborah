# Active roadmap — ecology expansions, integration, performance and safety

The author's current direction supersedes the earlier “P10 native acceptance
next” sequencing. Complete the phases below **in this order**, banking substantial
validated implementation checkpoints within each. Human playtesting follows the
three audits; outstanding native acceptance is retained, not silently accepted
or used to halt the authorized feature work. Do not deploy to the VPS or Workshop.

B21 builds on verified remote `main` `27853c2f7fde54ad377c86c398456b5b9ba33ce8`,
`Add campaign-aware encounter themes and novelty memory`.
The current B21 checkpoint below is the newest implementation record. Its exact
published SHA is returned after remote verification; always fetch current main
and preserve intervening work. Native Source acceptance remains pending.

## Ordered phases and exit conditions

| Order | Phase | Implementation chunks and finite exit condition |
| --- | --- | --- |
| 1 | **Bestiary Update** | Freeze the actual meaningful normal-enemy baseline and target; expand related tactical families through shared combat/AI authorities, then integrate campaign-aware encounter ecology, topology, novelty memory and pacing. Exit at approximately 3.5× the frozen baseline with production-available enemies, reproducible campaign sampling, bounded threat/entities and preserved progression. See [author brief](briefs/BESTIARY_UPDATE.md). |
| 2 | **Big Loot Update** | Freeze the actual meaningful item baseline; expand coherent effect/slot families, then upgrade loot selection, motifs, history, need/novelty and risk-aware placement. Exit at approximately 3.5× that baseline with legible production items, validated exposure/repetition/value and intact inventory, persistence, sell/fuse and wallet transactions. See [author brief](briefs/BIG_LOOT_UPDATE.md). |
| 3 | **Event System Update** | Freeze the actual meaningful production-event baseline; implement related event families through current placement/transaction authorities, then integrate event ecology with the already expanded encounter and loot systems. Exit at approximately 3.5× that baseline with campaign sampling and complete lifecycle proofs. Preserve the exact non-exploding 1d4 count and solvability; breadth does not inflate density. See [author brief](briefs/EVENT_SYSTEM_UPDATE.md). |
| 4 | **Full systems integration and emergence audit** | Trace generation → encounter → combat/status → equipment/loot → events/rewards → progression/lifecycle/UI across real production paths. Consolidate demonstrated duplicate authorities, remove redundant work, reconcile conflicting contracts and test representative cross-system combinations. Exit with one owner per state/transaction, preserved independent RNG/ownership where required, measurable interaction coverage and no known contradictory or redundant authority. Optimize for varied, legible, emergent decisions; do not add content merely to grow the audit. |
| 5 | **Low-end PC performance audit** | Establish reproducible representative and worst-case scenarios and explicit budgets from available evidence. Profile/measure server AI, traces, generation, client render/model/particle work, memory/resource retention and networking; repair demonstrated hot spots using shared scheduling, bounds and existing reduced-effects paths. Exit with documented before/after evidence and workload limits, no gameplay-authority regressions, and explicit hardware/native measurement gaps. Container timing or operation counts are not native FPS acceptance. |
| 6 | **Final pre-playtest crash and progression-safety audit** | Stress build failures, campaign resets, same-seed regeneration, native entity/damage lifetimes, missing assets, delayed callbacks, persistence/transaction failures, concurrent interactions, death/revival/disconnect/late join, all-Hero absence, gates/keys/rescue, Hector/finale/Abundance and Level21+. Repair concrete crash, leak, deadlock, stranded-control and progression-softlock paths. Exit with all required automated gates green, no known unresolved game-ending blocker, durable diagnostics and one concise human playtest plan. Do not claim proof that unobserved native crashes are impossible. |
| 7 | **Shael's human playtest** | Exercise the integrated build after phases1–6. Include outstanding native Source visuals/collision/controls/audio/real-network checks, low-end hardware measurements, Hector 1–4-player tuning, finale/succession and campaign continuity. Capture evidence, then repair demonstrated issues in separate bounded checkpoints. Deployment remains separately authorized. |

The 3.5× targets apply to each **whole update**, not every chunk. Count stable,
mechanically meaningful identities; exclude cosmetics, numerical roll permutations
and renamed duplicates. Record baseline IDs, inclusions/exclusions and target once
at the start of each phase. Do not rebase the denominator as additions ship.
The source briefs' whole-update definitions of done remain in force; their request
to finish one enormous checkpoint is superseded only by this chunking policy.

## Checkpoint size and compute policy

- **One coherent production result per checkpoint:** usually a small cohort of
  several related meaningful enemies/items/events sharing an authority, or one
  complete director/lifecycle integration. Prefer multiple related behaviors to
  one-file or cosmetic microcommits. Do not combine the three major updates.
- Before edits, state the finite scope, exclusions, affected authorities and
  observable pass condition. The first checkpoint may combine necessary baseline
  discovery with a real playable cohort; it must not stop at a taxonomy or unused
  framework. Select cohort size from actual complexity, not a fabricated quota.
- Reserve roughly the final third of the available session budget for testing,
  fixes, documentation, commit and remote verification. At rising context/time
  pressure, stop adding scope and close the coherent slice already underway.
  If it proves too large, reduce scope at a clean boundary while preserving the
  remaining work explicitly; do not weaken acceptance or push broken work.
- Read AGENTS, this current section and only the active brief. Follow live GDD
  00 → 01 → relevant subsystem tabs; exact HUMAN anchors only when necessary.
  Reuse the recorded baseline, accepted tests and sampling harnesses. No repeated
  broad equipment/event/bestiary audit without contradictory evidence.
- Reuse shared authorities and deterministic streams; introduce abstractions only
  when the current slice demonstrates their need. Focus parallel delegation on
  independent work with clear file ownership; avoid duplicate investigations.
- Run targeted tests during editing. For each gameplay checkpoint run the required
  canonical integration gate once the slice is stable:
  `python3 tools/test_checkpoint_g_integration.py`. Repeat only the affected tests
  after bounded fixes unless a shared-authority risk requires another full run.
  Documentation-only checkpoints require reference/content review and diff checks,
  not an unrelated gameplay rerun. Never describe an inherited pass as a new run.
- Record substantive decisions in relevant live GDD tabs and verify by readback;
  update the manual for changed player-facing behavior. Prepend the new checkpoint
  below this roadmap with scope, coverage, results, native gaps and the next slice.
  Keep this phase order intact until the author changes it.
- Commit and non-force-push each coherent green checkpoint immediately. Recheck
  remote main first. If CLI credentials remain unavailable, use authenticated
  GitHub blobs/tree/commit/ref operations, compare every blob and the complete tree
  with the tested local tree, update the ref non-forced, fetch and verify. Preserve
  newer work; never force-push or hold completed work for another feature.
- A phase ends only when its full brief/exit condition is met. Move to the next
  phase at a checkpoint boundary. Do not use anticipated future audits to defer a
  concrete bug or safety/performance regression introduced by the current chunk.

## Current checkpoint — B21: topology-aware composition and spatial pacing

Built on verified remote `27853c2f7fde54ad377c86c398456b5b9ba33ce8`.
Roster remains **63/63 normal**, frozen baseline18,45 additions,4 named bosses.
Bestiary remains open; no VPS deployment or Steam Workshop publication.

EncounterDirector now uses real traversable approaches, corners/junctions,
bounded straight corridors/physical firing lanes, existing alternate-route proof,
vertical approaches and objective distance to prefer tactically suitable squads
within B20's current motif. Existing specialist Placement filters templates
before selection. Common fallback only applies when no admitted motif remains;
spawn-time admission still rechecks geometry and substitutes ordinary bodies.
Existing role/sector/escape/companion/singleton restrictions remain intact.

The stale candidate-list spacing defect is repaired: each discretionary placement
rechecks minimum4 graph cells from all previously placed encounters/objectives.
No new actors, Think hooks, navigation/placement/combat/history owner or density.
Retain B20 independent RNG and successful-build receipts, threat scaling,
first-encounter exception,0.5 allowance, sector maxima and target80/ceiling96.

**Validation:** one fresh final canonical run passed **all210 suites with zero failures**;
no gameplay/config/test edits followed. Complete terminal matrix retained.
New production fixtures
prove real loops versus branches, closed gates/event edges, vertical/objective
reach, blocked firing lanes, actual selection influence, physical rejection/
fallback/revalidation and a counterfactual affordable stale-candidate regression.
The unchanged32x20 campaigns/parties1–4 pass54 exposure floors25/20/5 and
minimum36/54 per campaign, with new per-plan spacing/admission assertions on both
memory and control paths. Measured mean47.562/min43 versus control40.750;
6232 encounters,4312 discretionary,2372 preferred by geometry. Mean coverage is
slightly below historical B20, minimum higher; no universal improvement claim.
Full evidence/failed trials: `validation/BESTIARY_B21.md` and its linked logs.
Source native acceptance remains pending; automated boundary doubles are not play.

**Design/presentation:** live GDD05/06/07 LOD-BESTIARY-B21-001 records exact
preference tuning/ownership and diagnostics;00/01 route current continuation.
Manual remains164 chapters/32chunks with player-facing geometry/home-spacing
explanation. Registry63+4 unchanged; new B21 suite registered with integration.
All prior cohort/progression obligations remain, including Gordon/Hector/Deborah,
sole staging successor, Abundance and Level21 cash.

**Next B22:** one bounded macro-pacing slice through the existing director.
Define finite quiet/probe/pressure/recovery phrases and optional/objective context,
then prove them with deterministic sampling while retaining B20/B21 safeguards.
Wandering-population ecology and complete campaign/whole-Bestiary exit proof also
remain obligations; do not begin Big Loot, Events or the later audits yet.
Human native testing follows the ordered phases/audits.

## Previous checkpoint — B20: campaign-aware motifs and novelty

Built on verified remote `902678fad48142059841e8ad9849dd21e79695bc`.
Roster remains **63/63 normal**, baseline18,45 additions,4 separately counted
named bosses. Six dungeon motifs now select themed discretionary squads through
EncounterDirector: Hunting Grounds, Occupation, Corruption, Crossfire, Quarantine,
Funeral Retinue. Catalog60 themed+6common templates;63 identities/14 families.
The role/sector membership set is unchanged;960 lines of accumulated duplicate
weighting history are replaced by one motif/history selector.

Exclude the last two committed motifs and choose uniformly among eligible least-used
motifs. Within a motif use unseen template/identity, recent enemy/family/template
history and current-dungeon suppression; separate early-template history prevents
late-only encounters from suppressing early introductions. Keep common fallback,
objective fights, physical admission, companion/singleton composition and existing
threat/count/activation ceilings. No changes to wanderer selection or density.

RunManager commits primitive history only after complete physical builder success,
with exact state/graph/plan/seed/level/epoch/run guards. Failed builds consume no
history; same-level rebuild/seed overrides replace from the same before snapshot;
next level uses after; cleanup preserves history and new campaigns reset it even
with identical seeds. Three recent summaries and bounded counters, independent RNG;
no new bodies, Think hooks, combat pools or progression authorities.

**Validation:** One fresh final canonical run passed **all209 suites with zero failures**;
no gameplay/config/test edits followed. Complete terminal matrix retained.
All54 sampled specialists pass25planned/20legal/5early in32x20 sequential campaigns
(parties1–4, all60 themed+6common providers). Mean coverage48.500/54,min41, versus
control41.844; cross-level template returns154 versus280. Full counts, failed
trials, sample migration and exact limitations: `validation/BESTIARY_B20.md` and
`BESTIARY_B20_EXPOSURE.md`. Old512 independent plans retain geometry/composition
checks and comparable count output (4792 encounters). Native Source acceptance
remains pending; no VPS deployment or Workshop publication.

**Presentation/design:** `lod_encounter_ecology` reports motif/roster/families,
novelty/fallback choices and encounter cell/threat. Manual164 chapters/32chunks.
Live GDD00/01/05/06/07 LOD-BESTIARY-B20-001 records design, tuning, ownership and
measured evidence with readback. All prior cohort and complete campaign regression
contracts remain binding, including Gordon/Hector/Deborah/staging/Abundance/Level21.

**Next B21:** bounded topology-aware composition and spatial pacing through
current director/geometry seams. Macro-pacing, wandering-population ecology and
full campaign exit evidence remain within Bestiary. Numerical breadth and B20
memory are complete, not the whole phase. Do not begin Big Loot/Events or audits.
Native testing follows all ordered phases/audits.

## Previous checkpoint — B19: relay and living-link cohort

Built on verified remote `74798e4202e9095f8d94232196c42411ffe484a6`.
**Relay and Lacemaker** reach **63/63 meaningful normal identities**:
frozen baseline18, **45/45 additions banked**. Native Source acceptance remains
pending. No VPS deployment or Workshop publication. This completes roster breadth,
not the Bestiary phase; campaign-aware encounter ecology remains next.

**Playable scope:** Relay freezes a fully warned shot from one ordinary ally's
position; Lacemaker warns a finite damaging ribbon whose second endpoint follows
an ordinary moving ally. Counterplay changes firing origin, target priority and
enemy-to-enemy geometry. Interrupt/defeat either participant, break their tether,
evade the shot or leave/bait the living ribbon. Ward AI is not commandeered.
Without a qualifying ally both retain a full warned fixed source shot.

**Canonical boundaries:** one bounded EnemyRoster commitment module, ordinary
EnemySupport eligibility/cached registry, exact source/Hero/ward life and dungeon
scope, guarded native damage and unchanged defenses/HP/XP/drops. One B19 ward
reservation, maximum16 links; no extra bodies, private pools/statuses, homing,
retrospective swept damage or reward authority. Physical support/actual Hero-hull
lateral escape checks, bounded ward displacement and finite service/recovery
retire unsafe work. Full design/tuning is in the ledger and live GDD03/05/07
`LOD-BESTIARY-B19-001`.

**Validation:** one fresh canonical run passed **all206 suites with zero failures**
after final repairs; no gameplay/config/test edits followed. The unchanged512
plans produced4949 encounters; all54 identities pass25planned/20legal/5early
(Relay34/34/6; Lacemaker27/27/6). Five trials/four failures are retained.
The complete matrix and exposure measurements are recorded
in `validation/BESTIARY_B19.md`, `BESTIARY_B19_INTEGRATION.txt` and
`BESTIARY_B19_EXPOSURE.md`. The three B19 suites exercise actual behavior/native
combat boundary, generated progression/production and client Draw against boundary
doubles. These are automated proofs, not Source runtime acceptance.
Manual163 chapters/32chunks. Registry63 normal+4 named; append ordinals60/61.

**Next B20:** bounded campaign-aware EncounterDirector integration. Reconcile and
author themes/roster subsets, campaign history/novelty, topology and macro-pacing
through existing deterministic planning authorities; define a finite production
and campaign-sampling gate. Preserve breadth/exposure and all prior safety,
combat, lifecycle, boss/finale/succession/Abundance/Level21 contracts. Do not
begin Big Loot or Events. Native testing follows the ordered phases/audits.

## Previous checkpoint — B18: prison-edict cohort

Built on verified remote `4b4c730a5d813ca3b8c6f6e877c0dc1192fe63dd`.
**Censor and Surveyor** bring the meaningful normal roster to **61/63**:
frozen baseline18, **43/45 additions banked**, **2 remain**. Native Source
acceptance remains pending. No VPS deployment or Workshop publication.

**Playable scope:** Censor warns a cease-fire, watches canonical attack commits,
and responds to the first new armed-window attack with a separate full warned
fixed shot. Surveyor freezes a threatened disc containing a displaced refuge;
the Hero may enter the refuge, leave the disc, take cover or interrupt the caster.
The two add attack restraint and directional safe-space decisions. Full design
and authored tuning: ledger and live GDD03/05/07 `LOD-BESTIARY-B18-001`.

**Canonical boundaries:** EnemyRoster commitments/service, shared Halter/Pacer/
Censor/Surveyor Hero-order token, canonical CommitAttack observer, exact actor
progression/status lives and dungeon/campaign scope, guarded native damage,
ordinary status/HP/XP/drops. No private pools, bodies or input spying. Deferred
Magic Forms/Wand observations capture the original order and settle only after
successful activation; failed/refunded casts and replacement lives/orders cannot
inherit retaliation. Watch service grace never extends its armed interval.
Actual Hero-hull supported refuge/outer escape and Censor lateral routes, finite
snapshot full/reduced tells, manual162 chapters/32chunks, registry61+4 named,
append ordinals58/59. B16 preflight now preserves a reentrant cross-mode order.

**Validation:** One fresh canonical integration run passed **all203 suites with zero failures** after final repairs; no gameplay/config/test edits followed. Full results are recorded in
[validation](validation/BESTIARY_B18.md) and
[integration matrix](validation/BESTIARY_B18_INTEGRATION.txt). Three B18 suites
exercise actual AI/shared service/CommitAttack/native combat against boundary
doubles, production progression/feats/HP/XP/spawn and actual client Draw.
Magic Forms refund and Wand settlement regression coverage also extended.
Unchanged512 plans/32mazes/parties1–4/dungeons1–5 produce4942 encounters; all52
sampled identities pass25planned/20legal/5early. Censor32/32/8, Surveyor30/30/6.
[Exposure record](validation/BESTIARY_B18_EXPOSURE.md) retains all six trials,
five failures, exact ordered donor transfers and every identity's counts.
No resampling, threshold relaxation or prior geometry weakening.

**Native checks retained:** gm_flatgrass real cease-fire/attack/retaliation
alignment, failed-cast behavior, refuge/outer escape with actual hulls/support/
gates/Walls/false floors, Raw mitigation and physical Block/Dodge, HP/XP/drops,
full/reduced warnings/audio, 1–4-player balance/network/late join, death/revival/
disconnect/freeze/reset/same-seed rebuild. Preserve all earlier cohorts and
Gordon→Hector→Deborah, sole staging successor, Abundance and Level21 cash.
Evidence console_latest.txt+rpg_summary_latest.txt after ordered phases/audits;
session log only for event order. No pre-sequence human/deployment gate.

**Next:** B19 only: targeted remaining-niche review, author/implement/validate the
final meaningful pair; target63/63. Whole-phase campaign-aware themes, novelty
memory, topology, pacing and quantitative coverage remain within Bestiary even
after the numerical roster target is met. Then Big Loot, Events and the audits.

## Previous checkpoint — B17: companion-interaction cohort

Built on verified remote `aff47575413f077505006a88ff94ff0df04c5e40`.
**Interposer and Mourner** bring the meaningful normal roster to **59/63**:
frozen baseline18, **41/45 additions banked**, **4 remain**. Source acceptance
remains pending; no VPS deployment or Workshop publication.

**Playable scope:** Interposer warns a frozen route between one ordinary ally
and the observed Hero, then places its actual body in the firing line for a
finite hold. No defense bonus or damage redirection. Mourner visibly swears a
finite oath to one ally; only that ally's legitimate exact-life defeat during
the armed oath starts a new full warning against the original Hero. Both retain
an ordinary warned fixed-lane shot when unpaired. Change angle, pierce, prioritize
the supporter, break the tether, wait or trigger-and-evade. Full design/tuning:
ledger and live GDD03/05/07 `LOD-BESTIARY-B17-001`.

**Canonical boundaries:** EnemyRoster service/commitments, EnemySupport bounded
ordinary selection, EnemyRemains sealed/open living-life receipt, MotionV2
movement, native packet/combat/status/progression/reward authorities. One exact
ward reservation across both modes, cap16; no bodies, private pools, resurrection,
kill-credit invention or general faction exception. Native callback reentry,
replacement lives, source/ward drift, hidden tracking, unsupported routes,
stalls, replay and stale corpse reuse fail closed. Full/reduced snapshot tells;
manual161 chapters/32chunks; append ordinals56/57; registry59 normal+4 named.

**Validation:** One fresh canonical integration run passed **all200 suites with zero failures** after final repairs; no gameplay/config/test edits followed. Three new suites exercise actual AI/shared
service, guarded native combat, MotionV2, canonical death receipts, production
spawn/class/feats/HP/XP and native Draw against boundary doubles. See
[validation](validation/BESTIARY_B17.md) and
[integration matrix](validation/BESTIARY_B17_INTEGRATION.txt). Unchanged512 plans/
32mazes/parties1–4/dungeons1–5 produce4950 encounters; all50 sampled identities
pass25planned/20legal/5early. Interposer39/37/6, Mourner34/34/6. All five trials,
four failures and exact in-place donor transfers are retained in
[exposure](validation/BESTIARY_B17_EXPOSURE.md). No thresholds, seeds or prior
geometry rules weakened. Whole-phase campaign-aware ecology remains required.

**Native checks retained:** gm_flatgrass real bodyguard alignment/interception,
piercing/area/flank responses, warning/oath/death timing, scaled actor hulls and
support/gates/Walls/false floors, full/reduced audio/visuals, Block/Dodge/HP/rewards,
1–4-player network/late join, death/revival/disconnect/freeze/reset/same-seed rebuild.
Preserve every prior cohort and Gordon→Hector→Deborah/sole staging successor/
Abundance/Level21. Evidence console_latest.txt+rpg_summary_latest.txt after
ordered phases/audits; session log only for ordering. No pre-sequence human gate.

**Next:** B18 only: targeted remaining-niche review, author/implement/validate the
next meaningful coherent pair; target61/63. Four additions plus campaign-aware
encounter ecology remain inside Bestiary before Big Loot/Events/audits.

## Previous checkpoint — B16: movement-discipline cohort

Built on verified remote `5f817c2eb3e99a14156fd3d783359a998d4f5fbb`.
**Halter and Pacer** bring the meaningful normal roster to **57/63**:
frozen baseline18, **39/45 additions banked**, **6 remain**. Source acceptance
remains pending; no VPS deployment or Workshop publication.

**Playable scope:** Halter demands STOP, Pacer KEEP MOVING. Both warn1.6s, then
judge every canonical voluntary-motion observation during the final0.4s against
25% of legitimate walk speed. Any violation permits one physical1d6+2 hit;
insufficient/stale/forced/impossible motion cancels. Obey, interrupt, break cover,
leave360 range or the legal room. Exclusive per-Hero ownership prevents opposing
orders. Shared EnemyRoster commitments/service, canonical FinishMove/DodgeMovement,
status lives and existing native packet/mitigation/HP/reward authorities. No
additional motion classifier, faction exception, status/resource pool or bodies.
Full authored parameters: ledger and live GDD03/05/07 LOD-BESTIARY-B16-001.

**Ownership and readability:** exact source/Hero progression/status-life and
run/graph/progression/campaign;16-cap, fresh0.3s observed final-window coverage,
maximum0.15s observation gap/final sample age0.1s, fixed0.2s release grace,
0.25s service gap,4-unit source drift,3s recovery. Actual Hero hull/support/escape
checks, including native callback changes. Claim before callbacks, preserve new
attacks/tokens, reject failed authorization, replay and stale/native mitigation
replacement. Full/reduced STOP/KEEP MOVING glyph/text/countdown/tether uses only
visible server snapshots. Manual160 chapters/32 chunks, append ordinals54/55,
progression registry57 normal+4 named bosses.

**Validation:** one fresh canonical run passed **all197 suites with zero failures**; no gameplay/config/test edits followed. See [B16 validation](validation/BESTIARY_B16.md) and
[integration output](validation/BESTIARY_B16_INTEGRATION.txt) for the fresh canonical
result. Three new suites exercise real AI/service, canonical movement and combat,
production/progression/spawn, and native Draw with boundary doubles. Unchanged
512-plan/32-maze/parties1–4/dungeons1–5 sample produces4939 encounters;
all48 sampled identities retain25 planned/20 legal/5 early gates. Halter30/28/5,
Pacer33/33/6. Four trials including three failures and exact fixed-length donor
transfers are preserved in [exposure](validation/BESTIARY_B16_EXPOSURE.md).
No seed/geometry/threshold/ceiling/companion relaxation. Whole-phase director
ecology remains required. Live GDD updates/readback and final results are in the
validation record. Boundary doubles are not native observation or acceptance.

**Native checks retained:** gm_flatgrass actual movement/force/Held/slow/crouch,
warning timing and visibility, real support/collision/gates/Walls/false floors,
STOP/GO and companion-pressure balance, Block/Dodge/HP/rewards, lifecycle/reset/
late join, full/reduced audio/visuals and1–4-player networking. Preserve prior
cohorts and campaign/finale/succession/Abundance/Level21. Evidence
console_latest.txt+rpg_summary_latest.txt; session log only for ordering after
ordered phases/audits. No new pre-sequence human gate.

**Next:** B17 only: targeted remaining-niche review, author/implement/validate the
next meaningful coherent pair; target59/63. Six additions plus whole-phase
campaign-aware ecology remain inside Bestiary before Big Loot/Events/audits.

## Previous checkpoint — B15: careless-fire interaction cohort

Built on verified remote `b6cb650f32c40ed5bd4b04e2fcf3bd40f4d9945e`.
**Fusilier and Bombardier** bring the meaningful normal roster to **55/63**:
frozen baseline18, **37/45 additions banked**, **8 remain**. Source acceptance
remains pending; no VPS deployment or Workshop publication.

**Playable scope:** Fusilier commits a1.25s fixed physical lane that strikes the
first native body, including a captured ordinary hostile. Bait a companion into
the line or sidestep. Bombardier warns1.6s over a frozen radius72 blast that can
hit both Heroes and captured ordinary enemies; lure enemies into it and escape.
Body interception protects against the single shot, not the area; solid cover
protects against both. Both physical1d6+2/range360, recovery3s/3.5s. No source
self-hit or general AI infighting. Full authored design/tuning: ledger and live
GDD03/05/07 `LOD-BESTIARY-B15-001`. Manual159 chapters/31 chunks.

**Ownership/safety:** EnemyRoster shared commitment/service/packet; FactionManager
exact single-use native-packet exception; canonical mitigation, HP/death/earned
XP and loot. Named bosses/clones, event Skeletons, friendly summons and human
Soldiers cannot be friendly-fire recipients. Source/primary/recipient exact
status-life/progression plus dungeon/campaign scope, no late-arrival or replacement
warning transfer. Native first obstruction absorbs the lane even if ineligible.
Area admission is sealed before callbacks and shares one roll; primary death does
not suppress already-admitted companions, while source replacement cancels them.
Packet target/attacker/inflictor and one GM admission are checked across canonical
mitigation callbacks; replay, reentry and stale lifetimes cannot grant a second
hit. Claimed errors expire; fixed recovery cannot extend. Actual/changed/diagonal
Hero hulls, source/mark support, legal cell, two96-unit escape routes,16 commitments,
32 Hero/128 hostile cached candidates,0.2s grace/0.25s service gap/4 drift.
No synthetic Hero killing-blow XP: only prior earned contributions settle, once;
ordinary drops retain their deferred native-death handoff.

**Production:** singleton sector2+ arena/ambush templates Fusilier+Shambler and
Bombardier+Runner, append ordinals52/53, explicit registry55 normal+4 named bosses.
Preserved seeds, caps, threat, fallback and legal geometry. Full/reduced finite
lane/body-bracket and blast/fragment warnings, bounded trace/render work.
**Fresh validation:** all194 canonical integration suites pass with zero failures;
no gameplay/config/test edits followed. Unchanged512 plans/32 mazes/parties1–4/
dungeons1–5 produce4947 encounters; all46 sampled identities retain25/20/5 gates.
Fusilier54/54/14, Bombardier32/32/8. All23 trials (22 failures), exact262 broad+329
sector2-only ticket additions and final in-place donor transfers are preserved.
Pool-length churn prompted wider measured margins and then fixed-length transfers;
the later campaign-aware director remains required. Complete evidence:
[validation](validation/BESTIARY_B15.md),
[integration output](validation/BESTIARY_B15_INTEGRATION.txt) and
[exposure](validation/BESTIARY_B15_EXPOSURE.md). Final results are recorded there.
Live GDD00/01/03/05/07 updates are verified by readback; boundary doubles are not
native Source observation or acceptance.

**Native checks retained:** gm_flatgrass model/pose, actual first-body interception,
allied blast bait/cover, Hero collision/support/gates/Walls/false floors, native
Block/Dodge/HP/XP/drop attribution, status/morale, death/revival/disconnect/late join,
freeze/reset/same-seed rebuild, full/reduced warnings/audio and1–4-player networking/
balance. Retain prior cohorts and full campaign/finale/succession/Abundance/Level21.
Evidence console_latest.txt+rpg_summary_latest.txt; session log only for ordering,
after ordered phases/audits. No new pre-sequence human gate.

**Next:** B16 only: select and author a coherent pair from remaining tactical gaps,
then implement/validate through canonical authorities. Target57/63 only for two
meaningful production identities. Eight additions and whole-phase campaign-aware
encounter ecology remain within Bestiary before Big Loot or Events.

## Previous checkpoint — B14: resource-pressure cohort

Built on verified remote `e8279b1bf904e9a3954436d50063da6a5533e4bf`.
**Siphoner and Accumulator** bring the meaningful normal roster to **53/63**:
frozen baseline18, **35/45 additions banked**, **10 remain**. Source acceptance
remains pending; no VPS deployment or Workshop publication.

**Playable scope:** Siphoner's1.25s frozen radius64 Raw mark drains up to12 Magic
only after positive final HP damage on the surviving captured Hero, after normal
defenses/Arcane Shield. Accumulator pays base40 canonical Magic per warned Raw
mark; below affordability it instead channels2s to restore45, capped100. Interrupt,
mute, break sight or exploit the stationary window; escape the fixed attack mark.
Recovery3.5s/2.5s. Both use Raw1d6+2/range360. Accumulator's generated Aura Burst
is ordinary supplemental cast damage, separate from the captured mark; no aura
from drain/recharge. Full design/tuning and canonical capabilities: ledger and
live GDD03/05/07 `LOD-BESTIARY-B14-001`. Manual158 chapters/31 chunks.

**Ownership/safety:** EnemyRoster shared commitment/service/target/damage;
Magic canonical100-capacity pools, synchronization and regeneration; Status life,
defenses and conditions. Exact source/Hero progression/status-life/pool plus
run/graph/progression/campaign scope. Real Hero-hull escape and floor support,
cap16, fixed0.2s grace/0.25s service gap/4-unit drift; no catch-up or private timers.
Claim before native sync/damage/observer callbacks; no stale-life debit/drain/
refill/hit, newer-attack erasure or forever-pinned spent callback. Held permits
stationary actions, Muted/morale/stun cancel. Canonical Quantum, pre-cost full-Magic
snapshot, Feedback Loop and discrete-spend observer are integrated. Explicit
pure-Magic capability templates prevent inert physical feats, without changing
previous actors. Spawn ordinals50/51; explicit registry53 normal+4 named bosses.

**Validation:** one fresh canonical run passed **all191 suites with zero failures**
after final repairs; no gameplay/config/test edits followed. Full output and
coverage: validation/BESTIARY_B14.md and BESTIARY_B14_INTEGRATION.txt. Live GDD
00/01/03/05/07 design/tuning/evidence/continuation read-back verified. Three B14
suites cover real
AI Tick/shared Think, resource/combat/status/lifecycle/callback boundaries,
production progression/spawn and native Draw. Unchanged512-plan/32-maze/
parties1–4/dungeons1–5 sample produces4943 encounters, all44 sampled identities
passing25 planned/20 legal/5 early gates. Siphoner45/43/9, Accumulator46/42/9.
Eleven trials including all failures, exact26 broad+30 sector2-only ticket
additions and final full counts: validation/BESTIARY_B14_EXPOSURE.md. No threshold,
seed, geometry, population-ceiling or companion relaxations. Canonical manual,
live GDD, ledger, active plan and handoff document scope and evidence honestly.

**Native checks retained:** gm_flatgrass actual Stalker/Vortigaunt poses and
full/reduced warnings/audio; mark escape and recharge denial; native support,
collision/gates/Walls/false floors; damage/Arcane Shield/Magic meter and utilities;
generated Quantum/Feedback Loop/Aura Burst; Held/Muted/morale; death/revival/
disconnect/late join; reset/same-seed rebuild;1–4-player HP/rewards/network/balance.
Retain prior cohorts and full campaign/finale/succession/Abundance/Level21 checks.
Boundary doubles are not Source observation/acceptance. Evidence console_latest.txt
+rpg_summary_latest.txt; session log only for ordering, after the ordered phases.

**Next:** B15 only: choose the next coherent pair from underrepresented remaining
roster niches via targeted ledger/shared-authority review, author finite counterplay
and production gates, then implement and validate. Target55/63 only for two
meaningful production identities. Remaining roster breadth and campaign-aware
director ecology remain inside Bestiary before Big Loot/Events; no new phase.

## Previous checkpoint — B13: party-spacing pressure cohort

Built on verified remote `998c99dcafbb96fd89fd0b73d0c1a6ad6b4cfb8a`.
**Outrider and Conductor** bring the normal roster to **51/63**: frozen baseline18,
**33/45 additions banked**, **12 remain**. Native Source acceptance is pending.

**Playable scope:** Outrider warns1.1s before a frozen112-unit/60-degree physical
melee strike against an isolated Hero. Regroup within192 with same-floor LOS,
sidestep, retreat or interrupt. Conductor freezes two radius64 ground marks for
nearby Heroes, warns1.4s, then attempts one shared-roll Raw Magic hit per Hero.
Separate beyond160, leave either circle, break sight or mute/interrupt to cancel
both. Solo has a fully warned fixed Raw projectile; only its captured Hero takes
that bolt's damage. Soldier/Shambler companions preserve complementary pressure.
Both use1d6+2 through canonical combat. Design/tuning: BESTIARY_EXPANSION.md and
live GDD03/05/07 LOD-BESTIARY-B13-001. Manual157 chapters/31 chunks; also repaired
B11/B12 omitted descriptions caused by wrong source keys.

**Ownership/safety:** FactionManager bounded cooperative queries; EnemyRoster
existing melee/projectile/shared service and canonical physical/Magic settlement.
No private targeting, resource, status, reward or timer owner. Exact source and
participant progression/status-life plus dungeon/campaign identity, cap16,
cached32 fail-closed candidates, actual Hero-hull lateral escape/support/cover,
finite warning/service/recovery and source drift. Pair predicates qualify before
damage so first-victim death alone cannot suppress a valid second settlement;
source/recipient replacement still blocks stale hits. Native callback replacement
cannot erase newer attacks; source-life changes retire spent links instead of
pinning the actor. Held permits stationary actions; Muted cancels Conductor but
permits Outrider. Ordinary morale dispatch remains intact.

**Validation:** one fresh canonical integration run passes **all188 suites with
zero failures** after final gameplay/exposure/manual repairs. No gameplay/config/
test edits followed that pass. Three B13 behavior/production/native-Draw suites
pass;32 seeded generated actor replays, exact-life/callback/lifecycle/geometry
matrix, solo and1–4-Hero counterplay.512 plans/4945 encounters/32 mazes/parties1–4/
dungeons1–5: Outrider49 planned/48 legal/11 early; Conductor39/38/8. Every retained
25/20/5 exposure threshold passes. Seventeen failed trials and all measured
weights are preserved:70 broad+six sector2 repair tickets above new base and
retained prior tickets. Prior cohorts, combat/status/progression, bosses/finale/
succession/Abundance/cash, Lua syntax, release wiring and manual reader/transport
pass. Evidence: validation/BESTIARY_B13.md, BESTIARY_B13_INTEGRATION.txt and
BESTIARY_B13_EXPOSURE.md. Live GDD00/01/03/05/07 design, tuning, final evidence and
continuation amended/read-back verified.

**Native checks retained:** after ordered phases, gm_flatgrass actual regroup/
separate/solo counterplay, models/poses/full-reduced warnings/audio, native
support/collision/escape/gates/Walls/false floors, statuses/morale, death/revival/
disconnect/late join, freeze/reset/same-seed rebuild, actual HP/XP/drops and
1–4-player networking/balance, plus prior cohorts and complete campaign continuity.
Boundary doubles do not establish Source observation/acceptance. Evidence
console_latest.txt+rpg_summary_latest.txt; session log only for ordering.
No VPS deployment or Workshop publication.

**Next:** B14 only, provisional resource-pressure pair: telegraphed Magic-drain
attacker and interruptible self-recharging caster. Reconcile canonical pools,
Arcane Shield, combat/status settlement and generated capabilities before design.
No duplicate pools, permanent loss, currency/loot theft or unavoidable drain;
retain solo counterplay and finite exact-life service. Substitute comparably
bounded identities if redundant. Target53/63 only after meaningful production
validation; remaining breadth and whole-phase campaign-aware ecology stay inside
Bestiary before Big Loot/Events.

## Previous checkpoint — B12: condition-interaction cohort

Built on verified remote `5c38f7dcdb062064d942967998c375460e593ee1`.
**Absolver and Exactor** bring the normal roster to **49/63**: frozen baseline18,
**31/45 additions banked**, **14 remain**. Native Source acceptance is pending.

**Playable scope:** Absolver channels1.5s to cure one exact negative condition on
an ordinary ally; no HP/revival/self-cure. Exactor marks an ailing Hero's frozen
radius64 position for1.25s, attempts one physical1d6+2 hit and consumes the exact
Bleeding/Immolated/Poisoned entry only after positive damage on the surviving
captured life. Cure, leave the circle, separate support, break cover, mute the
Absolver or interrupt either source. Exactor without an ailment fires a warned
physical fallback. Companions: two Shamblers / one Flamer. Canonical manual156
chapters/31 chunks. Full design/tuning: BESTIARY_EXPANSION.md, GDD03/05/07
LOD-BESTIARY-B12-001. Live design, tuning, evidence, index and continuation are
amended and read-back verified.

**Ownership/safety:** EnemySupport channels and canonical status reservations;
RPGStatusElements exact-entry selection/removal/expiry; EnemyRoster finite
physical marks through shared combat/Block/Dodge/HP/XP/drop. No private status
clock, stat theft, new bodies or reward owner. Exact source/recipient/Hero lives,
progression and dungeon/campaign identities; fixed service/release deadlines,
16 channels/marks, source drift checks, supported escape paths using Hero native
hulls, identity-safe callbacks, finite recovery. Ordinary support explicitly
excludes player-controlled Soldiers. Held permits stationary actions; Muted
cancels cleansing Magic but allows physical attacks. All prior cohorts remain.

**Validation:** four B12 suites pass: real behavior/status/combat, support,
production and native-Draw boundary.32 seeded actor generations/replays, exact
life/entry/dungeon matrix, reentrant callbacks, lethal/blocked damage, support/
hull/cover/escape, caps/retries and fixed deadlines.512 plans/4944 encounters/
32 mazes/parties1–4/dungeons1–5: Absolver27/25/12, Exactor29/28/8; all retained
25/20/5 exposure gates pass. Six measured+1 tickets repair dilution; failed trials
remain in validation/BESTIARY_B12_EXPOSURE.md.

One fresh185-suite canonical integration run passed184 and failed only the stale
explicit progression-registry assertion (`must be 51`). Added Absolver/Exactor
to that diagnostic list (now49 ordinary+4 named bosses), then reran the affected
Protected Behavioral Regressions suite: all six families plus Overall RPG
Subsystem Validation pass. **Final185-suite coverage is green across integration
plus targeted rerun**, not one all-green integrated run. No gameplay edits
followed integration. Exact evidence: validation/BESTIARY_B12.md. Prior cohorts,
combat/status/progression, bosses/finale/succession/Abundance/cash, Lua syntax,
release wiring and manual reader/transport passed in the integrated run.

**Native checks retained:** after ordered phases, gm_flatgrass actual statuses,
tethers/marks/escape/Block/Dodge, support/collision/gates/Walls/false floors,
interruptions, death/revival/disconnect, freeze/reset/same-seed rebuild, full/
reduced visuals/audio, actual HP/rewards and1–4-player networking/balance, plus
all prior cohort/boss/campaign regressions. Boundary doubles are not Source
observation or acceptance. Evidence console_latest.txt+rpg_summary_latest.txt;
session log only for ordering. No VPS deployment or Workshop publication.

**Next:** B13 only, provisional party-spacing pressure cohort: isolated-target
predator and crowd-link punisher. Reconcile canonical targeting, cooperative
proximity and damage before authoring; require regroup/separate counterplay,
solo viability and finite exact-life warnings. Target51/63 only for two meaningful
validated production identities. Keep remaining breadth and whole-phase
campaign-aware ecology within Bestiary before Big Loot/Events.

## Previous checkpoint — B11: perception cohort

Built on verified remote `86ec5ff6f2fbf84a36ad1521c5a728b69de64f72`.
**Listener and Shy** bring the implemented normal roster to **47/63**:
frozen baseline18, **29/45 additions banked**, **16 remain**.

**Playable scope:** Listener investigates an actual non-crouching footstep's
frozen same-room position; quiet/crouching Heroes deny its acquisition. Shy
remembers a directly visible Hero and advances toward that last-seen position
only while no eligible same-floor Hero within480 has geometric LOS to its body.
No camera-facing demand or invisibility grant. Both warn0.8s, travel at most128
units within another1.4s, and deal no investigation damage. Fresh sensory
eligibility plus a separate0.9s narrow melee warning precede physical1d6+2.
Flee, sidestep, keep sight, reposition or interrupt. Soldier escorts supply
complementary pressure. Exact design/tuning: BESTIARY_EXPANSION.md and live
GDD03/05/07 LOD-BESTIARY-B11-001. Manual155 chapters/31 chunks.

**Ownership and safety:** FactionManager owns event receipts and sensory
selection; EnemyRoster owns exact life-bound commitments, canonical melee and
existing service; MotionV2 owns effective physical travel. Hearing TTL1.5s,
sight memory2s, source/target/run/graph/progression/campaign bindings; canonical
invisibility forget clears cached knowledge immediately. At most32 sound
receipts/Hero candidates and16 simultaneous investigations; no world scan,
per-enemy timer, extra bodies, private statuses or rewards. Full scaled hull
and<=24-unit support probes constrain each step to its legal supported cell.
Missed release/service forfeits. Held/interruptions cancel investigation;
Muted allows it; finite recovery never extends. Review repaired a guard ordering
that could swallow canonical morale-flee movement; a real-handler regression
proves memory retirement preserves normal fleeing.

**Validation:** focused behavior, real progression/spawn and native-Draw boundary
suites pass, including actual server footstep event, quiet/crouch/concealment,
cooperative LOS independent of view direction, snapshot-only navigation, shared
cloak source/forget dispatch, real MotionV2, ordinary melee/GM mitigation/HP
boundary, exact lifetime matrix, native-geometry/support denial, statuses,
finite service/recovery and caps. Production tests32 seeded generations/replays,
usable physical classes/feats/growth/HP/XP once, spawn variance/ordinals,
ceiling/idempotence/retry/fallback and room admission. Exposure tuning retains the
unchanged512-plan/32-maze/parties1–4/dungeons1–5 gate and25/20/5 thresholds.
Final4952 encounters: Listener43 planned/41 legal/6 early, Shy33/30/5;
every prior identity remains green. All failed sampling trials and exact final
tickets are retained in validation/BESTIARY_B11.md.

One fresh final canonical integration run passed **all181 suites with zero
failures**, after the morale-dispatch repair and its new regression. No gameplay
edits followed that final integrated pass. An earlier181-suite pass preceded
completion of that repair and is not the final acceptance evidence. All prior
cohorts, combat/status/progression, bosses/finale/succession/Abundance/Level21,
repository Lua syntax, release wiring and manual readers/transport remain green.
Live GDD00/01/03/05/07 design, tuning, evidence and continuation were amended and
read-back verified.

**Native acceptance retained:** after ordered phases, test gm_flatgrass footsteps
versus crouching, cooperative sight/occlusion, actual full-hull motion/support/
gates/Walls/false floors, statuses and morale, death/revival/disconnect,
freeze/reset/same-seed rebuild, warning/audio/full-reduced clarity, actual HP/
rewards,1–4-player networking/balance, plus prior cohorts and complete campaign
regressions. Boundary doubles do not establish Source observation/acceptance.
Evidence: console_latest.txt+rpg_summary_latest.txt; session log only for ordering.
No VPS deployment or Workshop publication.

**Next:** B12 only, a bounded condition-interaction cohort provisionally covering
an ally-condition cleanser and a condition-reactive opportunist; these are design
proposals to reconcile with canonical status ownership, not authored mechanics.
Target49/63 for two distinct production identities. Keep the remaining breadth
and campaign-aware director ecology within Bestiary before Big Loot and Events.

## Previous checkpoint — B10: mobile-hazard cohort

Built on verified remote `a5ab25e00491795491cd5d89384202c6cb25d1fd`.
**Censer and Trailmaker** bring the implemented normal roster to **45/63**:
frozen baseline18, **27/45 additions banked**, **18 remain**.

**Playable scope:** Censer warns a fixed144-unit approach then carries a radius64
physical zone; Trailmaker warns a fixed144-unit retreat and leaves up to three
radius44 patches at reached start/mid/end points. Both warn1.2s before movement,
use canonical effective MotionV2 speed and have a1.8s movement deadline. Censer
ends on arrival/deadline; each trail patch warns another0.8s then lasts1.2s within
a fixed ready+3.8s lifetime. Physical1d6+2, one canonical attack roll and at most
one hit per captured Hero for the entire commitment. Full design/tuning is in
BESTIARY_EXPANSION.md and live GDD03/05/07, LOD-BESTIARY-B10-001.
Canonical manual154 chapters/31 chunks. Live GDD00/01/03/05/07 amendments
and evidence were read-back verified after writing.

**Safety and ownership:** reuse EnemyRoster scheduling, exact source/Hero status-
life/progression and dungeon/campaign scope, canonical damage/Block/Dodge/status/
HP/XP/drop owners. At most16 mobile commitments, three patches and32 captured
Hero incarnations per source; no recurring target/world scans. Same-cell support,
scaled hull and six lateral escape routes are revalidated; route support probes
prevent floor-gap travel. Review exposed an interior lateral-floor gap missed by
endpoint-only support; bounded escape-route probes and regression tests now
close it. Source drift, Held/morale/hit-stun, invalid life/run/geometry or expiry
cancel every attached hazard. Missed service/release forfeits, never catches up.
Fixed stationary recovery cannot extend. No native bodies, private status timers,
homing, unavoidable spawn damage or additional rewards.

**Validation:** targeted real AI/service/MotionV2/combat and native-Draw boundary
harnesses pass. Coverage includes warning exclusion, actual moving radius, all
three reached patches, escape/cover/height/floor, full hull, interior source and
escape-route holes, late/missed service, slow travel, fixed recovery, exact life/
run/graph/progression/campaign retirement before/during/after movement, statuses,
multiplayer admission/lethal-primary order, reentrancy and finite caps. Production
proves32 seeded actor generations/replay, usable feats/classes, HP/XP once, actual
spawn/variance, idempotence, stable ordinals, cap/retry/fallback and admission.
Initial512-plan sample: Censer40/39/9, Trailmaker27/27/7; retained Waylayer19/17/4
failed25/20/5 after selection-pool dilution. A single additional Waylayer ticket
restores established exposure without changing mechanics/admission/RNG scope.
Revised512 plans/4927 encounters/32 mazes/parties1–4/dungeons1–5: Censer35 planned/
34 legal/8 early, Trailmaker25/25/6, Waylayer53/45/12; all retained thresholds pass.
An early integration run was deliberately stopped for the escape-support repair;
it is not counted as a pass. One fresh final canonical integration run passed **all178 suites with zero failures**,
including prior cohorts, combat/status/progression, bosses/finale/succession/
Abundance/cash, repository Lua syntax, release wiring and manual readers/transport.
No gameplay edits followed that integrated pass.

**Native acceptance retained:** after ordered phases, gm_flatgrass must establish
actual movement/collision/support and gate/Wall/false-floor interaction; warning,
moving ring and individual patch clarity; statuses/interruptions; death/revival/
disconnect; freeze/reset/same-seed rebuild; native HP/rewards; full/reduced effects,
audio,1–4-player networking/balance/performance and all prior cohort/boss/campaign
regressions. Automated native entity/collision/HP/render/network boundaries remain
doubles, not Source observation or acceptance. Evidence: console_latest.txt+
rpg_summary_latest.txt; session log only for event ordering. No VPS deployment
or Workshop publication.

## Next checkpoint — B11: perception cohort

Provisional bounded two-identity perception cohort: a sound-cued hunter and a
visibility-conditioned stalker. These are proposals, not authored mechanics.
Reconcile FactionManager acquisition, invisibility, LOS, existing sound/combat
signals, MotionV2 and finite life-bound commitments before choosing identities.
Distinguish them from Watcher recruitment, Lurker ambush, Pincer routing and
ordinary pursuit. Require readable warnings, exploitable counterplay and bounded
cached/event-driven work; no hidden omniscience, compulsory camera behavior,
permanent invisibility, new targeting authority or extra summoned bodies.
Substitute a comparably bounded identity if needed. Target47/63 only for two
validated meaningful production identities. Preserve remaining roster breadth
and whole-phase campaign-aware director ecology; do not begin Big Loot or Events.

## Previous checkpoint — B9: tether and projected cover

Built on verified remote `d4a9700b250ad894e45e0aa9dc680e81009c3a89`.
**Towline and Screenwright** bring the implemented normal roster to **43/63**:
frozen baseline18,**25/45 additions banked**,**20 remain**.

**Playable scope:** Towline warns a frozen lane before a physical hit and short
resistible inward pull. Screenwright warns then channels a finite passable guard
plane for up to three captured ordinary allies. Positive final HP loss gates the
pull; canonical Pushback owns save/modifiers/immunity and movement. Shared Block
owns screen mitigation,one roll per attack and33% aggregate cap. A projected
screen replaces the provisional solid cover engineer to preserve route freedom
and native entity bounds. Details/tuning are in BESTIARY_EXPANSION.md and live
GDD03/05/07,LOD-BESTIARY-B9-001. Canonical manual153 chapters/31 chunks.

**Safety and ownership:** same-cell supported commitments,full native target-hull
pull preflight,<=64 displacement/standoff64,finite source drift and no wall crush
on a denied constrained pull. Screen admission and release recheck actual
lateral pockets; no collision bodies. At most16 screens,128 cached candidates
once,three captured recipients. Exact source/target/recipient incarnations and
run/graph/progression/campaign scope retire stale work at service and use. Held/
Muted preserve physical channeling; hit-stun/attack prohibition/morale cancel.
Missed beats forfeit and stationary recovery cannot extend. Released fallback
shots retain finite exact lifetimes. Prior cohorts,shared reward ownership,
bosses,finale,sole staging successor,Abundance and Level21 cash are retained.

**Validation:** targeted behavioral,production and presentation suites pass.
Real roster AI/service,damage→GM mitigation→native-doubled HP,shared Pushback
contest/movement and Block settlement are exercised. Coverage includes escape,
cover/void/full hull/changed geometry,Block/save/zero HP denial,hard travel cap,
reentrancy,exact lifetime matrices,recipient admission,front/side/rear/height,
nonstacking and aggregate caps,one roll per attack,Magic bypass,global/scan caps,
missed release,fixed recovery,Held/Muted/morale and stale fallback projectiles.
Production proves32 seeded actor generations and replay,usable feats/classes,
HP/XP once,real unified spawn/variance,stable ordinals,ceiling,retry and fallback.
Native Draw tests full/reduced fixed warnings,countdowns,expiry and conservative
render bounds including fallback fire.

Initial512-plan sample retained as failed evidence: Screenwright23 planned/9
legal/3 early,below25/20/5. One Soldier escort and clear in-cell lateral pockets
replace two Soldiers and unnecessary graph-cycle admission for passable cover.
Revised512 plans/4941 encounters/32 mazes/parties1–4/dungeons1–5:
Towline34/32/7; Screenwright32/32/8; all earlier exposure thresholds green.
One fresh canonical integration run passed **all175 suites with zero failures**,
including retained prior cohorts,combat/status/progression,bosses/finale/succession/
Abundance/cash,repository Lua syntax,release wiring and manual readers/transport.
No gameplay edits followed this integrated pass.

**Native acceptance retained:** after ordered phases,on gm_flatgrass observe
actual pull/save feedback,full body collision/gates/false floors,screen clarity
and physical/Magic defenses,interruptions,death/revival/disconnect,freeze/reset/
same-seed replacement,full/reduced effects/audio,1–4-player networking,rewards
and balance,plus retained prior cohort/boss/campaign checks. Native entities,
collision,HP application,rendering and networking remain boundary doubles;
automated evidence is not Source observation or acceptance. Capture
console_latest.txt+rpg_summary_latest.txt; session log only for event ordering.
No deployment or Workshop publication.

## Previous checkpoint — B8: volatile-and-remains cohort

Built on verified remote `1f56389ea096766fae09a69fa31e2811ed2064dd`.
**Afterburst and Carrion** bring the implemented normal roster to **41/63**:
frozen baseline18,**23/45 additions banked**,**22 remain**.

**Playable scope:** Afterburst leaves a fixed warned post-defeat physical burst;
Carrion exclusively consumes nearby ordinary remains through interruptible
stationary feeding for capped recovery. Consuming Afterburst before release
extinguishes the burst. Both retain ordinary narrow physical melee and existing
canonical class/feat/HP/XP/drops. Production pairs Afterburst+Soldier and
Carrion+two Shamblers in sector2+ arena/ambush,with singleton specialists and
ordinary companion scaling. No new bodies,wandering weights or director rewrite.
Design/tuning readback: live GDD03/05/07,LOD-BESTIARY-B8-001. Canonical manual
regenerated:152 chapters/31 transport chunks.

**Ownership:** canonical lethal callback seals once; deferred native corpse
scheduler opens the exact receipt and retains its one-second lifetime and loot
conversion. Explicit corpse status-life plus source/progression/entity/death
record and exact run/graph/progression/campaign distinguish death effects from
living attacks. Ordinary Damage/ValidSourceLife reject dead owners unchanged;
the receipt-controlled burst alone shares packet construction. Source removal,
revival/replacement,stale scope,freeze/failure/clear and invalid geometry retire
work. At most96 receipts,128 cached candidates per opening,32 captured Heroes;
no world corpse scans,new timers,native bodies or chain reactions. Claim before
callbacks;one irreversible attempt per corpse;normal XP and drops settle once.
Reward handoff also rejects same-seed graph or source incarnation replacement.
Native corpse Draw preserves the burst warning;full/reduced semantics match.

**Validation:** B8 behavioral,production and presentation gates pass. Real lethal
callback/deferred corpse service,canonical XP/loot handoff and capped health grant
are exercised with native entities/HP/trace/spawn/render/network boundaries
doubled. Coverage includes living fallback,burst escape/cover/height,missed
service,consumption-before-burst,competing claims,source/Hero and dungeon lifetime
matrices,interruption/Held/Muted/morale,late join/revival/disconnect,one shared
multiplayer roll and lethal-first order independence. Production validates32
actor generation seeds,replay after unrelated RNG,class/feat eligibility,HP/XP,
unified spawn/variance,ceiling,retry,placement/fallback and old ordinals.
512 deterministic plans/4936 encounters across32 mazes,parties1–4,dungeons1–5:
Afterburst planned/legal/early47/44/7;Carrion40/40/8;all prior thresholds pass.
One fresh canonical integration run passed **all172 suites with zero failures**,
including all prior cohorts,protected combat/status/progression,bosses/finale/
succession/Abundance/cash,repository Lua syntax,release wiring and manual readers/
transport. No gameplay edits followed this integrated pass.

**Native acceptance retained:** after ordered phases,on gm_flatgrass observe
actual corpse pulse/burst timing and loot,feeding tether/interruption/consumption,
physical health/Block/Dodge,scaled poses and audio,full/reduced effects,cover,
locked gates/false floors,same-seed reset/freeze/removal,death/revival/disconnect,
1–4-player rewards/networking and practical encounter balance. Preserve all
prior cohort,boss and campaign checks. Automated evidence is not Source
observation or acceptance. Capture console_latest.txt + rpg_summary_latest.txt;
request session log only for event ordering. No deployment or Workshop update.

## Previous checkpoint — B7: melee spacing-and-commitment cohort

Built on verified remote `0ceeed48a6cb703711716ec31951eae2fdf5cf96`.
**Reaper, Drubber and Fencer** bring the implemented normal roster to **39/63**:
frozen baseline18, **21/45 additions banked**, **24 remain**.

**Playable scope:** Reaper commits a broad frontal sweep; Drubber commits two
fixed narrow strikes with a real escape interval; Fencer makes a bounded,
non-damaging backstep before a fixed narrow thrust. Retreat/rear approach,
waiting out both beats, and refusing a straight chase are distinct responses.
Production compositions pair them with Soldier, Runner and Shambler respectively
in sector2+ arena/ambush. Canonical generated classes, usable physical feats,
HP, XP and ordinary rewards remain authoritative. Exact tuning and frozen count
are in BESTIARY_EXPANSION.md; design is read-back verified in live GDD03/05/07
under LOD-BESTIARY-B7-001. Manual151 chapters/31 transport chunks regenerated.

**Authorities/lifecycle:** no director rewrite, projectile/native bodies, new
status clock, damage or reward owner. EnemyRoster's service owns finite frozen
commitments; MotionV2 owns Fencer's ordinary-speed backstep, with scaled native
swept hull, cell/gate/transition and floor-support preflight. A slow/blocked
retreat forfeits instead of teleporting or extending the tell. Each beat has one
canonical physical melee roll and one settlement per admitted Hero. Drubber's
second beat owns a new attack contract. Exact source/target progression and
status-life plus run/graph/progression/campaign retire stale work, including
same-seed replacements. Captured participants prevent late-join/revival warning
inheritance. One pulse's own lethal primary hit cannot skip other Heroes.
Stationary recovery is finite and cannot be shortened/extended by further hits.
Held permits stationary strikes but cancels the backstep; Muted permits melee.

**Validation:** targeted behavioral, production and full/reduced presentation
gates pass. Behavioral proof includes real interleaved roster AI/service and
MotionV2 retreat, frozen counterplay, missed-deadline forfeiture, scaled hull
obstruction, changed native support/cover, exact lifetime matrix, Held/Muted/
morale, multiplayer admission and canonical roll→GM mitigation→native-doubled
HP application. Production proves48 generated actor seeds, replay after unrelated
RNG consumption, every granted feat's capability eligibility, normal HP/XP once,
real unified spawn/variance, ceiling preflight, mixed old/new stable ordinals,
retry idempotence, safe/objective/transition/hull admission and bounded fallback.
512 deterministic plans/4935 encounters across32 mazes,parties1–4,dungeons1–5:
Reaper planned/legal/early36/36/9; Drubber39/38/11; Fencer55/54/12. All earlier
cohort exposure thresholds remain green. One fresh canonical integration run
passed **all169 suites with zero failures**, including prior cohorts, protected
combat/status/progression, bosses/finale/succession/Abundance/cash, repository
Lua syntax, release wiring and manual readers/transport. No broad rerun needed.

**Native checks retained:** after the ordered phases,on gm_flatgrass observe
paired encounters, practical sweep/rear spacing, both Drubber beats, Fencer
backstep/thrust, scaled zombie/Metrocop poses, audio and full/reduced tells.
Test actual hull/cover/gate/false-floor changes, interruptions, slow/Held
retreat, death/revival/disconnect, freeze/reset/same-seed rebuild,1–4-player
networking and health/reward balance. Preserve all prior cohorts,bosses,
Gordon→Hector→Deborah,sole staging successor,Abundance andLevel21 cash. Native
entities/collision/HP application/rendering/networking remain boundary doubles;
automated evidence is not Source observation or acceptance. Capture
console_latest.txt + rpg_summary_latest.txt at the scheduled playtest.

## Previous checkpoint — B6: trap-and-escape cohort

Built on verified remote `0616d9d0582687e6112152737d59964f8aedca6d`.
**Wirewright, Snarer and Cordon** bring the normal roster to **36/63**:
frozen baseline18, **18/45 additions banked**, **27 remain**.

**Playable scope:** Wirewright warns then channels a finite, jumpable low
tripwire across a frozen observed cell. Snarer arms a frozen proximity circle;
entry starts a separate1.25s escape countdown before canonical Ice/Held.
Cordon is a destructible pressure node itself, warning then pulsing an annulus
with a safe inner pocket and exterior. Break cover/contact, move, interrupt or
destroy the source; waiting out a trap also works. Pairs: Wirewright+Runner,
Snarer+Soldier, Cordon+Shambler, sector2+ arena/ambush and one specialist per
composition. All own canonical classes/usable feats/HP/XP and unified spawning.
No new wandering weights. Exact tuning lives in BESTIARY_EXPANSION.md.

**Authorities/lifecycle:** trap policy extends EnemyRoster's existing attack
record and25ms scheduler, shared combat/status/Block/Dodge and exact actor-life
helpers. No new native bodies, world scan, status timer, reward path or RNG.
At most16 pending/live traps,one per source,32 captured Hero records each.
Finite warning,live and snap deadlines cannot extend or catch up after a stall.
All charges/traps retire on source/primary-Hero progression/status-life and exact
run/graph/progression/campaign replacement, including same-seed rebuilds, as well
as interruption/freeze/failure/clear/death/removal. Incidental Hero incarnations
are frozen at commitment and revalidated separately; late joins and revivals
cannot inherit an unseen warning. Muted disarms Snarer; Held does not forbid
stationary physical/Ice attacks. Source displacement beyond32 disarms.

**Review repairs:** reset wire samples on arming so warning-tail crossings are
never retroactively damaged. A pulse's own lethal hit on its primary Hero cannot
skip other admitted Heroes due to participant ordering; shared source-life
validation remains immediate. Require native floor support at circle center or
wire center/endpoints on admission and every service, so an opened false floor
retires its trap despite an unchanged graph. Detached records cannot settle.

**Design/manual:** live GDD00→01→02/03/05/07 governed the checkpoint.
LOD-BESTIARY-B6-001 records mechanics, production, tuning and refinements in
03/05/07; amendments and current summaries are read-back verified. The canonical
manual has150 chapters/31 transport chunks. Full/reduced tells preserve exact
wire capsule/end-height, snare boundary/teeth/countdown and unfilled double ring;
all hide on death/cancel/deadline and use existing rendering/snapshot owners.

**Validation:** one required `python3 tools/test_checkpoint_g_integration.py`
run passed **all166 suites,zero failures**. No broad rerun was needed.
Targeted B6 behavior,production and rendering gates passed. Actual AI→warning→arm→shared service→
shared combat/GM mitigation/native-doubled HP tests prove swept wire counterplay,
no retroactive contact,ring safe center/exterior,snare bait/save/immunity/zero/
lethal behavior,fixed deadlines,interruption,caps and no fresh participant scans.
Exact source/primary-Hero life/progression and dungeon/campaign replacement cases
include same-seed rebuilds; multiplayer proves single settlement,lethal-primary
order independence and no incidental late-join/revival inheritance. Native
support removal and illegal geometry cases pass with bounded support/LOS work.
Production gate covers48 generated actor seeds,real class/usable feats/HP/XP,
unified spawn/variance/capacity preflight/retry idempotence and singleton pairing.

Sampling passed **512 deterministic plans /4935 encounters**,32 generated mazes,
parties1–4,dungeons1–5. Planned/legal/early: **Wirewright40/40/9,
Snarer35/33/14,Cordon57/53/12**. Prior cohort exposure thresholds still pass.
No deployment or Workshop publication. Native collision,entities,health
application,rendering and networking remain boundary doubles; these results
are automated evidence,not Source runtime observation or acceptance.

**Native checks retained:** after the ordered phases,on gm_flatgrass observe
actual paired encounters,practical wire jumping/end clearance and sweep heights,
proximity bait/snap readability,ring center/outer counterplay,turret/Vortigaunt
poses,audio and full/reduced tells. Test changing cover,gates and false floors,
interruption,death/revival/disconnect,freeze/reset/same-seed replacement,and1–4
Hero health/reward balance and networking. Preserve all prior cohorts,bosses,
Gordon→Hector→Deborah,sole Deborah staging succession,Abundance andLevel21 cash.
Evidence:console_latest.txt + rpg_summary_latest.txt; runtime acceptance pending.

## Historical proposal — B7 (implemented above): melee spacing-and-commitment cohort

Complete one coherent cohort,provisionally a lateral melee sweep,a two-beat
strike with a real escape window,and a backstep-then-thrust specialist. These
are proposals,not authored rules: reconcile against Shambler,Runner,Razor,
Redliner and existing close-combat authorities before choosing identities.
Require genuinely distinct movement/spacing decisions,visible frozen tells,
canonical damage/control/locomotion,legal swept geometry,finite commitments,
exact actor/dungeon lifetimes and complementary production compositions.
Target39/63 only if three meaningful identities pass production validation.
Do not rewrite the director here or begin Big Loot/Events. Whole-phase
campaign-aware ecology remains required after the roster cohorts.

## Previous checkpoint — B5: projectile-pattern cohort

Built on verified remote `7c625e074d2921f30e0303d96d3d0d093bf11d8e`.
**Caromer, Reeler and Forker** bring the normal roster to **33/63**:
frozen baseline18, **15/45 additions banked**, **30 remain**.

**Playable scope:** Caromer warns a frozen shot path with one possible reflected
wall leg; absent suitable geometry it fires straight. Reeler sends a shot beyond
the observed Hero, pauses0.75s, then retraces the exact path to its original
launch point. Forker fires two warned parallel lanes with128-unit separation and
an open center. Cover and pre-release interruption remain counterplay. Production
pairs: Caromer+Shambler, Reeler+Runner, Forker+Soldier; sector2+ arena/ambush,
one specialist per composition. Each owns canonical generated classes, usable
physical feats, HP, XP, normal rewards and unified spawning. No wandering weights.
Exact tuning and frozen counting contract are in BESTIARY_EXPANSION.md.

**Authorities/lifecycle:** trajectory policy extends EnemyRoster's existing
projectile list and service. No native projectile entities, scheduler, damage/
status/reward authority or gameplay RNG is added. Shared64-shot ceiling with
atomic two-slot admission; at most4 planning hull traces+2 release checks, then
one sweep per moving shot per service. One pattern attack/dice contract and
per-Hero ledger prevent double settlement across volley lanes. Incoming direction
uses the actual swept segment origin. Fixed hard expiry is path length/speed+
pause+0.2s; warning release grace0.2s; invalid preflight retries after0.5s.
B4's exact source/Hero life binding moved to shared roster helpers and remains
behaviorally intact. Charge/flight retire on actor life/progression and exact
run/graph/progression/campaign replacement, including same-seed rebuilds.
Emitted shots survive ordinary interruption; Held/Muted permit physical fire.
New cover absorbs; no target tracking, recursive banks or catch-up trace loops.

**Review repairs:** clear pending attacks when dead valid actors leave the active
registry. Cancel B5 warnings when canonical morale fleeing begins. Preserve
actual frozen path parity in client rendering and hide a bank diamond when no
reflected leg exists. Forker rechecks both launch offsets before any emission,
so changed cover or insufficient capacity cannot produce a half-volley.

**Design/manual:** live GDD00→01→02/03/05/07 governed B5.
LOD-BESTIARY-B5-001 records mechanics, production and tuning in03/05/07;
substantive amendments and current roadmap summaries are read-back verified.
Canonical manual149 chapters/31 transport chunks explains the bank, return and
parallel-gap tactics. Exact server paths, return arrow, bank/turnaround diamonds,
full/reduced geometry and finite tell expiry use the existing render/transport
owners. Type3 fits the existing two-bit projectile field.

**Validation:** one required `python3 tools/test_checkpoint_g_integration.py`
run passed **all163 suites, zero failures**. No broad rerun was needed.
Fresh coverage includes B1–B4, all retained bosses/finale/succession/Abundance/
cash regressions, shared combat/status/progression/rewards, syntax/release wiring
and manual readers/transport. Final `git diff --check` passes.

B5 tests exercise actual roster AI→warning→release→shared projectile service;
one bank with matching/removed/changed/second-wall cases, fixed return and pause,
real swept safe center and side-lane hits, shared physical roll→GM mitigation→
one native-doubled HP settlement, duplicate-lane rejection, atomic pool cap,
blocked/newly-covered offsets, fixed deadlines and bounded work. Full cohort
charge/flight lifecycle cases include source/Hero progression/status-life,
exact state/graph/progression/campaign/seed, freeze/failure/clear/death/removal/
disconnect, interruption, Held/Muted and expiry. Client snapshot geometry, death/
cancel/deadline hiding and paused-return diamond pass at full/reduced effects.
Production gate covers48 generated actor seeds, real unified spawn/variance/
class/usable feats/HP/XP, ceiling preflight, retries and singleton enrichment.

Targeted sampling passed **512 deterministic plans /4930 encounters**,32
independently generated mazes, parties1–4, dungeons1–5. Planned/legal/early:
**Caromer65/65/23, Reeler62/61/19, Forker50/47/13**. All prior cohort exposure
thresholds remain passing; intended companions and single specialists persist.
Collision/entities/native HP application/rendering/network transport remain
boundary doubles. Automated evidence does not imply native Source acceptance.

**Native checks retained:** after the ordered phases, on gm_flatgrass observe
actual paired encounters, one-bank collision normals, missed bank geometry,
changing container/gate cover, delayed return timing and frozen destination,
parallel-gap readability/practical width, scaled actor poses/audio, full/reduced
warnings, real networking and1–4-player balance. Exercise source/target death,
revival/reconnect, interruption/freeze/reset/same-seed replacement and single
XP/loot settlement. Retain previous cohorts, all bosses/finale/sole Deborah
succession/Abundance/Level21 cash progression. Capture console_latest.txt +
rpg_summary_latest.txt. No VPS deployment or Workshop publication.

## Previous checkpoint — B4: self-defense and reaction cohort

Built on verified remote `965d857e8dbbb62a0dfbf313e3d366741cef9ce2`.
**Pavise, Repriser and Redliner** bring the normal roster to **30/63**:
frozen baseline18, **12/45 additions banked**, **33 remain**. Each has its own
canonical progression/class/usable-feat/HP/XP and unified production spawning.

**Playable scope:** Pavise warns then anchors a fixed-facing self-guard, adding
25 percentage points to the shared physical Block roll within its frontal cone,
retaining the33% cap. Flank, cast Magic, interrupt or wait. Repriser responds to
actual direct hostile Hero HP damage with a1s warned nonhoming physical shot;
cover, sidestep and another hit interrupt it. Redliner changes from ordinary
ranged fire to a once-per-wounded-episode approach/lunge at<=40% HP, with1s warning
and3s stationary recovery; healing>=60% rearms. No new damage/speed multiplier.
Pairs: Pavise+Runner, Repriser+Soldier, Redliner+Shambler. Sector2+ arena/ambush
production, one specialist per composition, no new wandering weights or bodies.
Exact tunings and the frozen counting contract are in BESTIARY_EXPANSION.md.

**Authorities/lifecycle:** one EnemyReactions policy uses the existing roster
scheduler, canonical Block, damage, status, morale and navigation/motion owners.
The post-native observer requires actual surviving HP loss after mitigation;
zero/blocked/lethal/passive/status/reactive/environmental damage cannot arm a
reaction. Fixed pending, warning, approach, guard and recovery deadlines prevent
unbounded commitment. Exact source/Hero progression/status-life and run/graph/
progression/campaign bindings reject replacement, including same-seed rebuilds.
Block uses committed incoming origins and a single cached roll; its cache now
also distinguishes actor status-life and exact graph/campaign identity. Ordinary
physical fire remains available while Held; guard/lunge require voluntary motion.
Released bullets survive ordinary interruption but retire on life/dungeon changes.
No duplicate damage/reward/status authority or global entity scans.

**Review repairs:** preserve Redliner's original recovery deadline when another
hit interrupts it, rather than shortening or extending recovery. Re-arm its
wounded episode when healing occurred between AI ticks. Validate directional
Block against committed attack origin rather than the attacker's later position.
Preserve exact-incarnation retirement without recalling already-emitted bullets.
Native shotgun damage precedes its final4× stun; Magic/crowbar can also stun after
HP settlement. Forward the committed event so only the triggering attack may
adopt its own late stun within the unchanged2s pending deadline. A later different
attack still interrupts normally; stun strength/tuning remains unchanged.

**Design/manual:** live GDD00→01→02/03/05/07 governed B4. LOD-BESTIARY-B4-001
records mechanics, production and tuning in03/05/07; amendments are read-back
verified. The canonical manual has148 chapters/31 transport chunks, including
self-guard, reprisal, wounded lunge and recovery counterplay. Shield/front arc,
hooked return arrow, jagged chevron/lunge lane and open recovery bars retain
semantic geometry with reduced effects and finite deadlines.

**Validation:** one required `python3 tools/test_checkpoint_g_integration.py`
run passed **all161 suites, zero failures**. Final targeted B4, shotgun native
aggregation, crowbar and Magic Wall checks passed after the late-stun closures;
no second full gate was run. Final changed-authority Lua syntax and
`git diff --check` pass. The gate covers prior B1–B3, all retained bosses/finale/
succession/Abundance/cash regressions, canonical combat/status/progression/XP,
manual readers/transport and release wiring.

B4 tests exercise real canonical capped Block, committed-origin direction and
one-roll caching; native-doubled HP loss after mitigation; actual warned
projectile/dive→shared physical roll→GM mitigation→one native HP settlement;
source/Hero progression and status-life plus exact dungeon/campaign retirement;
freeze/expiry/death/reconnect identities; passive/reactive rejection and duplicate
post callbacks;40/60 wounded hysteresis, bounded approach and fixed recovery;
shared64-projectile ceiling and active-only scheduling without world scans or RNG.
Actual production4× shotgun aggregate feed, Wall Form damage and Crowbar
PrimaryAttack prove trigger-owned late-stun ordering. Production tests exercise
48 generated actor seeds, unified spawn/variance/HP/class/usable feats/XP once,
ceiling preflight, retry idempotence, singleton enrichment and legal placement.
Full/reduced client geometry, direction, finite expiry and death/cancel hiding
pass. Canonical manual148 chapters/31 chunks passes.
Targeted production sampling passed **512 deterministic plans /4932 encounters**,
32 generated mazes, parties1–4 and dungeons1–5. Planned/legal/early appearances:
**Pavise64/64/16, Repriser47/46/14, Redliner74/71/18**. All prior cohort exposure
thresholds remain passing, with correct companions and singleton specialists.
Source collision, entities, networking and health application remain doubled;
automated evidence is not native Source acceptance.

**Native checks retained:** after the ordered expansions/audits, on gm_flatgrass
observe actual paired compositions, front/flank/Magic guard behavior, Repriser
hit→stun→warning→shot and interrupted response, and Redliner threshold→approach→
lunge→fixed recovery→healing rearm. Check scaled hulls/container/gate clearance,
model poses/audio, full/reduced glyphs, native shotgun hit timing, real networking
and1–4-player balance. Include death/revival/reconnect/freeze/reset/same-seed
replacement, single XP/loot settlement and prior cohorts/bosses/finale/sole Deborah
succession/Abundance/Level21 cash progression. Capture console_latest.txt +
rpg_summary_latest.txt. No VPS deployment or Workshop publication.

## Previous checkpoint — B3: flank and pursuit cohort

Built on verified remote `660c42284b0fae4073380214502bcdc731b17558`.
**Pincer, Harrier and Waylayer** bring the implemented normal roster to **27/63**:
frozen baseline18, **9/45 additions banked**, **36 remain**. Every addition owns
canonical progression/class/usable-feat/HP/XP and ordinary unified production
spawning. No cosmetics, bosses, events or friendly summons enter the count.

**Playable scope:** Pincer signals then takes a bounded alternate graph approach,
or a hull-clear two-leg local flank around the observed Hero lane. Harrier fires
one warned physical projectile before withdrawing to reachable cover or greater
separation. Waylayer warns for1s at a reachable escape junction adjacent to the
observed Hero cell, walks there and holds1.5s. Shared physical1d6+2 fire remains
dodgeable. Production pairs are Pincer+Soldier, Harrier+Shambler, Waylayer+Runner;
sector2+ arena/ambush admission, at most one specialist, no added wandering weight.

**Authorities/lifecycle:** one EnemyPursuit policy extends EnemyRoster; Navigator
owns graph edges/waypoints and MotionV2 owns locomotion. Selection uses a visible
acquired Hero and freezes its observed position; hidden movement never updates
routes. Search32 nodes/depth4, at most8 candidate routes; sorted choices consume
no shared RNG. Full legal-edge and scaled-hull checks prevent unsafe/objective/
transition travel, closed-gate bypass and displaced-actor shortcuts. Local flank
requires64 lateral and32 forward movement inside its source cell. Waylayer does
not create a damaging marker. Exact run/graph/progression/campaign and source/
Hero progression+life bindings retire stale route/attack work, including same-seed
replacement. Held cancels movement while allowing canonical physical fire;
released bullets retain their finite trajectory through source hit-stun/Held.
The fixed6–16s deadline uses route distance/current canonical movement speed,
plus1s and authored hold, without later extension. Ending/cancelling a commitment
starts8s cooldown, preserving time to fire after a long route.

**Findings repaired before closure:** loop-only Pincer admission produced only
8 legal/0 early appearances from66 planned; merely increasing route depth did
not solve exposure. The bounded local flank supplies actual behavior in ordinary
maze rooms without lowering distribution thresholds. A fixed6s route timeout
could not complete the1536-unit square; the computed hard-capped deadline now
passes real MotionV2 traversal. Cooldown was moved to commitment end to prevent
endless immediate reflanking. Life/charge/movement validation was separated so
Held does not suppress physical attacks or erase already released projectiles.

**Design/manual:** live GDD00→01→02/03/05/07 governed this checkpoint.
LOD-BESTIARY-B3-001 records implementation and tuning in03/05/07; roadmap summaries
advance to B4. Canonical manual147 chapters/31 transport chunks documents tactics,
with split/backward chevrons and the junction cross/square retained in reduced
effects. BESTIARY_EXPANSION.md is the frozen ledger; NEXT_DEVELOPMENT_HANDOFF.md
contains the complete B4 continuation prompt.

**Validation:** one required `python3 tools/test_checkpoint_g_integration.py`
run passed **all159 suites, zero failures**. No broad rerun was needed. This
fresh gate includes B1/B2, B3, production distribution, progression/rewards,
status/combat, all retained boss/finale/succession/Abundance/cash regressions,
manual transport/readers and repository Lua syntax/release wiring. Targeted B3
proofs include48 generated actor seeds, actual unified spawn→variance→progression,
class/usable feats/HP/XP and single settlement; graph and local two-leg flanking,
cover preference, adjacent escape junction, bounded search/route candidates,
canonical gate/event blockades and physical obstruction; warnings, exact
incarnation/dungeon/campaign retirement, interruption/displacement/freeze/expiry;
actual roster shot/service/finite projectile limits and real MotionV2 completion
of both Pincer paths. Held permits physical fire while cancelling movement;
released bullets survive ordinary hit-stun/invisibility and expire on life reset.
Client B3 glyph/destination/expiry tests pass at full/reduced effects.

Production sampling passed **512 plans /4923 encounters**,32 generated mazes,
parties1–4 and dungeons1–5. Planned/legal/early: **Pincer66/64/16,
Harrier89/87/25, Waylayer64/58/12**. All prior cohort exposure thresholds remain
passing; every B3 composition has its intended companion and one specialist.
Canonical manual147 chapters/31 chunks and `git diff --check` pass. Live GDD
B3 amendments and all updated roadmap summaries were read-back verified.
Native traces/entities/networking remain test doubles; this is automated evidence.

**Native checks retained:** after the ordered expansions and audits, on
`gm_flatgrass` observe actual generated compositions: Pincer alternate/local
flank and firing recovery; Harrier warned shot then clear retreat/cover;
Waylayer marked escape junction, warning, walk and hold. Verify native scaled
hull/container/gate collision, attack/route interruption, full/reduced glyphs,
models/animation/audio, real network behavior and1–4-player balance. Exercise
death/revival/reconnect, freeze/reset/same-seed replacement and ordinary XP/loot.
Capture console_latest.txt + rpg_summary_latest.txt. Retain prior B1/B2, all bosses,
Hector/finale, sole Deborah succession, Abundance and Level21 checks. Headless
trace/entity doubles do not establish Source runtime acceptance.
No VPS deployment or Steam Workshop publication.

## B3 handoff at publication — B4 (now completed above)

Proposed directional self-guard, interruptible warned retaliation and legible
wounded-state aggression; target30/63 subject to genuinely distinct mechanics.
Reconcile canonical Block/mitigation, damage events, statuses, morale and actor
lifetimes. Differentiate from Bulwark support and numerical variants. Supply
complementary production compositions, explicit progression and finite lifecycle
proofs. No absolute immunity, unavoidable damage, duplicated settlement or extra
bodies. These proposed roles are not implemented. Finish B4 only next; retain the
full Bestiary ecology exit before Big Loot, Events and the three audits.

## Previous checkpoint — B2: prison support detail

Built on verified remote `4e20da5f93d06b9707c93979bb191915a937c503`.
**Stitcher, Bulwark and Cantor** bring the implemented normal roster to **24/63**:
frozen baseline18, **6/45 additions banked**, **39 remain**. Each has an ordinary
production composition, distinct tactical response and full progression identity;
no cosmetics, bosses, event actors or friendly summons enter the denominator.

**Playable scope:** Stitcher channels one bounded ally heal (1.5s, 12% MaxHP,
ceil/cap24) with a nonstacking mending reservation; Bulwark grants one breakable
6s/240-unit LOS tether adding25 percentage points to canonical physical Block,
capped33%; Cantor focuses up to3 nearby allies on one visible Hero for4s through
FactionManager target selection. Use interruption/cover, sever the guard or use
Magic, and break the rally's sightlines respectively. Existing physical1d4+1
fallback attacks keep all three functional without an eligible support target.
Green cross, blue shield and gold chevrons/tethers identify commitments and
beneficiaries in full/reduced effects. No reinforcement bodies, revival,
private status timers, extra mitigation roll or director rewrite.

**Production/lifecycle:** own canonical schema templates wire deterministic
class/feat eligibility, abilities, HP growth, XP and real unified spawning.
Support-only Magic does not grant offensive-Magic feat capability. Sector2+
arena/ambush templates pair Stitcher+2 Shamblers, Bulwark+Soldier, Cantor+2 Runners;
enrichment caps the support source at1. Independent RNG, spawn ordinals, threat,
hostile ceilings, progression solvability and common rewards are preserved.
At most128 cached candidates, same floor/depth2 traversable local graph, range
and LOS; no world scan. Exact state/graph/progression/campaign scope plus source/
recipient incarnation (and rally Hero life) invalidate stale work. Canonical
status expiration and use-time validation retire benefits on death/removal,
interruption, cover/range failure, freeze/reset and same-seed replacement.
Mending release claims once; a service hitch beyond the0.2s grace forfeits the
heal safely. Beneficial support survives ordinary negative-condition cleansing.

**Design/manual:** followed live GDD00→01→02/03/05/07, including roadmap and B1
rules. LOD-BESTIARY-B2-001 is written and read-back verified in03/05/07 with exact
mechanics, actor generation and tuning. Canonical manual now146 chapters/31
transport chunks; both readers consume identical regenerated bytes. See
BESTIARY_EXPANSION.md for ledger and NEXT_DEVELOPMENT_HANDOFF.md for B3 prompt.

**Validation:** the required `python3 tools/test_checkpoint_g_integration.py`
run exercised **158 suites**:155 passed initially. Three stale integration
assumptions failed: remedy expected beneficial statuses to be cured; the isolated
Block fixture lacked Status:Has; the canonical validator expected25 progression
templates. Corrected the two fixtures and made validation require all28 explicit
stable progression IDs (24 normal +4 bosses), preserving existing template checks.
All three affected suites pass on fresh targeted reruns; the finalized B2 suite
also passes again. **Zero remaining failures** across the158-suite coverage; no
claim of a second full integration run. Following the compute policy, unchanged
passing suites were not repeated after these fixture/validator-only repairs.
B2 tests exercise actual spawn→variance→progression, class/feat capabilities,
HP growth, canonical XP and idempotence; production healing/Block/status/targeting;
nonstacking/expiry, actor and Hero life, cover/range/closed gates/separate floors,
128-candidate bound and exact same-seed dungeon replacement. B1 client tests now
also assert distinct B2 shapes/tethers and expired-state cleanup at full/reduced
effects. Manual source/reader verification and `git diff --check` pass.
Production distribution:512 plans /4910 encounters,32 generated mazes, parties1–4,
dungeons1–5. Planned/legal/early: Stitcher83/78/24, Bulwark70/69/22, Cantor78/75/19.
All three have companions, legal sector/role admission and one support source.
Native traces/entities/transport are doubled in the headless tests: these results
do not establish native collision, presentation, co-op balance or Source stability.

**Native checks retained:** after the authorized expansions and audits, on
`gm_flatgrass` verify actual support pairs in generated encounters: healing
wind-up/HP feedback and no overlapping heal; guard physical Block/Magic bypass,
cover/range severance; rally target switch, pathing and source interruption.
Verify models/animations/audio/tethers at full/reduced effects and1–4-player
balance, death/revival/reconnect, freeze/reset/same-seed replacement and ordinary
XP/loot. Existing single-enemy roster testkits prove actor presentation/fallback
only, not ally support; use production compositions for support acceptance.
Capture console_latest.txt + rpg_summary_latest.txt. Retain all prior B1,
Hector/finale, sole Deborah succession, Abundance and Level21 checks.
No VPS deployment or Workshop publication.

## Previous checkpoint — B1: prison control cohort

Built on verified remote `main` `855b3b9709675b5b035b12c58658eb74f3037fa9`.
The actual production baseline is frozen at **18 normal identities**; see
[BESTIARY_EXPANSION.md](BESTIARY_EXPANSION.md) for the counted IDs, code evidence,
exclusions and tactical-gap matrix. Whole-phase target **63** (=18 × 3.5).
B1 adds **Gaoler, Silencer and Repulsor**: **21/63**, **3/45 additions** banked,
**42 additions remain**. No cosmetic, class, tier, affinity or stat permutations
inflate this count. This is implementation progress, not native acceptance.

**Playable scope:** Gaoler commits an icy floor mark with canonical Held;
Silencer fires a warned, finite nonhoming Light bolt with canonical Muted;
Repulsor commits a short-range Earth pulse and outward shared Push. They pair
with Runner, Shambler and Soldier respectively in production sector-2+ arena/
ambush templates. All use the existing roster service, canonical actor progression
and class/feat/affinity generation, shared combat/dice/status/XP/drop authorities,
physical placement and deterministic unified spawner. No wandering additions,
new assets, private control timers, extra native projectile entities or director
rewrite. Canonical Content does not force defensive elemental affinity.

**Lifecycle/bounds:** each attack/projectile binds exact state, graph, progression,
campaign epoch/seed/run ID and dungeon seed. Same-seed graph replacement cannot
carry a prior attack forward. Mute/hit-stun cancels unreleased custodian magic;
released nonhoming bolts persist only within their finite owner/dungeon lifetime.
Held retains shared voluntary-movement restrictions. Per-target attack dedup,
cover, faction validity and positive-damage/surviving-target riders remain shared.
Earth push direction follows the frozen pulse origin even if the caster moves.
Preserved64-projectile service cap,0.025s service/0.1s snapshots,96-hostile ceiling,
80 target and16 wanderers/floor. The existing partial native-create policy retains
successfully spawned actors with stable ordinals and never replays an encounter.

**Design/manual:** live GDD00 →01 → relevant02/03/05/07, including
LOD-ROADMAP-ECOSYSTEM-001, governed this checkpoint. Added/read-back verified
LOD-BESTIARY-B1-001 in03/05/07 plus actor-generation tuning in07. Its authored
abilities, weights, growth dice, XP, warning/cooldown/range and Content values
are recorded there. Added “The control detail” to the canonical manual:145
chapters,31 regenerated transport chunks, both readers use the same bytes.

**Validation:** `python3 tools/test_checkpoint_g_integration.py` passed all
**157 suites with zero failures**. The new B1 suite exercises attacks, canonical
saves/riders/push, interruption, exact-dungeon cleanup, projectile bounds, partial
native spawn failure, full/reduced-effects presentation, seeded actor progression
and single-settlement XP. Existing combat/loot, boss/finale, Abundance and Level-21
regressions remain green. `git diff --check` is clean. The expanded512-plan production sample
across32 generated mazes, party1–4 and dungeon1–5 produced4906 encounters:
Gaoler170 planned/168 legal/44 early; Silencer115/113/42; Repulsor136/132/40.
Identical relevant seeds reproduce the same full plan. Geometry traces are Source
boundary doubles; these are not observed native spawns or native performance.
Review caught missing progression-template wiring and a displaced-pulse push
vector; both were repaired before the integrated gate, without loosening tests.

**Remaining native checks:** on a local gm_flatgrass campaign, enable developer
mode and use the existing `lod_enemy_roster_testkit gaoler`, `silencer` and
`repulsor` one at a time. Verify visible names/paint/model poses, exact tells at
full/reduced effects, cover/escape/interrupt counterplay, Held/Muted saves and
Earth push near walls/stairs, ordinary XP/loot and1–4-player balance. Reconnect,
death/revival, reset and same-seed rebuild must not replay attacks or rewards.
The kit marks the run unranked and preserves reserve/placement checks. Capture
console_latest.txt + rpg_summary_latest.txt. All earlier Hector/finale/staging/
Abundance/Level-21 native obligations remain pending for the planned human
playtest. No VPS deployment or Workshop publication.

## Historical B1 handoff — superseded by implemented B2

B2 is complete as recorded above; continue with B3.

## Roadmap checkpoint evidence

Planning-only change based on current author sequencing. Retained the three source
briefs byte-for-byte, reviewed links and precedence, and checked the diff. No game
code changed and no new gameplay-suite run is claimed. The live GDD sequencing
amendment is LOD-ROADMAP-ECOSYSTEM-001 in 00/07/90 and HUMAN, verified by readback.

---

# Last gameplay checkpoint — Deborah finale and staging succession

Built on verified remote main `5d05f3e372bd158fb6d49d3e5ce1094f84aa64c7`.
Read AGENTS.md, the preceding checkpoint, P10 in SEPTEMBER22_MASTER_BRIEF.md,
and live GDD 00 → 01 → relevant 05/06/07/90. Before implementation, recorded
and read-back verified **LOD-FINALE-001** in 05/06/07/90 and HUMAN under explicit
author design delegation. This supersedes older finale deferrals and the Hermit's
continued presence after Deborah's rescue. No VPS or Workshop deployment.

**Activation and timing:** only the accepted Level-20 rescue after the legitimate
Hector defeat receipt starts the expanded finale. Existing rescue XP, currency,
roster and Abundance settlement remain authoritative. The first **6.5 seconds**
of the unchanged **20-second** victory/Tetris interval show Deborah, actually
rescued damsels and up to four surviving participating Heroes: rescue title
0–1.5s; four one-second affectionate lean/cheek-kiss or wave/gratitude slots
1.5–5.5s; finite-story victory and Level-21 invitation 5.5–6.5s. Optional F/Tetris
remains available immediately and dismisses the local finale presentation.

**Presentation/lifecycle:** cosmetic client doubles use canonical models and
palettes; actual Heroes never move for choreography. Supported native bone/sequence
animation has a gratitude fallback. Reduced effects retain normal view and titles.
Exact accepted transition, campaign state/epoch/seed/run, dungeon seed, graph and
progression bind snapshots and callbacks. Captured Hero state, identity, spawn
and equipment life bind participants. Death, disconnect and role/life changes
retire participants; late join/reconnect receives the elapsed phase without
opening audio, replacement kiss slots, reward replay or clock extension. Reset,
failure, same-seed rebuild, advance, stale snapshots and map cleanup retire the
camera, actors, local target override, HUD and short movement lock. Cosmetic
failure cannot reject settlement or obstruct progression. Levels 1–19 and 21+
retain their ordinary celebration and objective rules.

**Presentation bounds:** server snapshots every 0.25s; client lease 0.75s.
The tableau uses the open court center, with 48-unit Hero spacing and two damsel
rows (up to ten per row, 34-unit columns, 48/90 units behind center). The full
view traces a 6-unit hull from court focus at +52 Z to a camera about 245 units
forward and 65 units higher, with a 6-unit drift. Supported spine/head lean is
12 degrees with a one-second sine envelope; unsupported models use wave/gratitude.
Render or trace failure restores the original view and leaves readable titles.
Death or a not-yet-ready local player suspends view/models; revival may observe
the elapsed phase without restoring a retired receiving slot or opening cue.

**Succession/services:** the Hermit has always been Hector. Pre-reveal guide names
and lines remain secret; accepted reveal records campaign knowledge. Canonical
RescuedDamsels[20] replaces him with the roster's **single Deborah** at the old
guide anchor immediately after rescue and through subsequent staging rebuilds.
Fresh campaigns restore the unrevealed Hermit. Deborah inherits the existing
pedestal starter and stored repeat-gift services with their unchanged identity,
claim IDs and settlement; her Use remains the existing Abundance account claim
with its rolling 24-hour cooldown. The portal, manual, mirror, statue exchange,
boards and other damsel services remain intact. Missing cosmetic guides retry
without blocking deployment. The manual now contains 144 chapters; both readers
share the same regenerated 31-chunk source.

**Validation:** `python3 tools/test_checkpoint_g_integration.py` passed all **156
automated suites with zero failures**; `git diff --check` is clean. Two new
production-path suites cover client presentation and staging succession; the
Hector suite now also executes real rescue, victory and intermission/Tetris
through Level 21. Existing SQLite tests retain Abundance/cooldown and gift
settlement coverage. A final focused regression additionally proves cosmetic
inactive-notification failure cannot block advancement. An interim run during
protocol/test construction had two stale-fixture failures (opening-cue schema
and retired-participant expectations); both were corrected and the full gate
rerun green. No native Source acceptance is claimed.

**One native acceptance procedure:** in a fresh local gm_flatgrass campaign with
two Heroes, run server-console `lod_developer_mode 1; lod_damsel_test_stage 20`.
This existing unranked fixture supplies the nineteen previously rescued damsels.
Redeploy; use `lod_rpg_gate_c_level 20` and resolve pending choices if needed,
then run `lod_warden_testkit` as each admin Hero. Defeat Gordon and Hector normally,
checking the core's aimability, collision, horizon presentation and marked attacks;
collect the key and rescue Deborah. Confirm one finale, the correct rescued cast
and surviving Heroes, readable affectionate beats, immediate reward settlement,
F/Tetris and reduced-effects behavior. Reconnect one client during the finale:
no replay or extra rewards. At the normal 20-second handoff, confirm SECURE THE BAG
and one Deborah at the old guide position, no Hermit, retained pedestal gift and
Abundance feedback (this unranked fixture must refuse wallet minting). Rebuild
staging and progress once more, then start a fresh
campaign and confirm the secret Hermit returns. Repeat a short finale with a
reset/death during presentation and verify ordinary camera/input/HUD recovery.
Capture console_latest.txt + rpg_summary_latest.txt; screenshots only for framing
or animation defects. Native Source animation, lineup/camera composition,
real-network synchronization, Hector core aimability/collision/horizon visibility,
and 1–4-player balance remain pending.

**Historical next-gate note, superseded by the author roadmap above:** the P10
native procedure remains an outstanding acceptance obligation. It is scheduled
within the later human playtest and no longer blocks the Bestiary, Big Loot or
Event System updates. Public deployment still requires separate authority.

---

# Previous checkpoint — Hector the Director and Level-20 rescue gate

Built on verified remote main `25147e4c769c337bd5269a45f7a18dc8d84bc69e`;
no intervening work replaced. Read AGENTS.md, retained P10 and live GDD
00 → 01 → relevant 02/03/05/06/07/90. Under explicit author design delegation,
recorded/read-back LOD-HECTOR-001 in 03/05/06/07/90 and HUMAN before implementation;
retained current monster-grade inflation and canonical combat/lifecycle authorities.
No VPS deployment or Steam Workshop publication.

**Scope/activation:** automatic at Dungeon Level 20 only. The exact legitimate
Gordon death hands off, after the native lethal stack, to one Hector encounter:
Gordon → Hector → ordinary center Jail Key → Deborah → existing victory/Tetris,
staging and Level 21+ SECURE THE BAG. Levels 1–19 and 21+ retain their prior rules.
Expanded finale celebration and other Game Master minigames are not implemented.

The generated Warden court/gallery/stairs and overhead containment remain intact.
A red Hermit upper body and titanic crowbar dominate the elevated Flattywood
bearing; two client models, ordinary depth testing, no giant navigation entity.
The plainly labeled Director's Heart at court center is one real stationary
lod_hostile, the only HP/damage/reward authority, linked to the giant by an energy
tether. Ordinary weapons, Magic, summons and melee attack that reachable body.
The protected entry permits neither outgoing nor incoming Hector damage; normal
join/respawn and once-per-Hero Warden resupply remain available.

**Combat/tuning:** three-second invulnerable reveal; canonical Champion Level 28
at Dungeon 20, reference starting HP 420 plus d20/CON/feat progression; frozen
party HP ×1/1.2/1.4/1.6 for one to four Heroes. Core size 1, displacement immunity,
no regeneration; ordinary affinity, enemy defense caps and applicable feats remain.
Monotonic phases at 60% and 25% add attack families and shorten recovery from
2.2 to 1.6 to 1 second. Four slow homing missiles; fixed three-second bomb marks;
1.5-second titanic-crowbar marks; straight purple Villain of Lore magic volleys.
Missile/lore wind-ups last one second. Ground impacts have 180-unit radii and LOS
checks. Shared Warden traced ordnance and CombatRolls own movement/damage; at most
one pending attack, four released shots/marks and twelve live hazards; five small
snapshots per second while active. Wind-up commits the attack: hit stun/status
blocks new commitments without erasing every warned strike under automatic fire.
Muted blocks new magical commitments. Target/life loss, phase change, absence,
freeze and teardown retire pending/live hazards. No-target waits retain HP/phase
and do not pause or replace the existing dungeon deadline.

**Ownership/progression:** bind the state, campaign epoch/seed/run ID, Dungeon
Level/seed, exact graph/progression/Warden, Gordon/core and native lock/jail/rescue
entities. Native lethal acceptance precedes existing XP/loot hooks; immutable
encounter receipts authorize deferred progression exactly once. Persistent
Level-20 Gordon markers reject late deaths/corpse rewards even after Level 21 or
same-seed regeneration. Invalid resources reject damage/rewards immediately.
Core removal is failure, never defeat. Partial creation invalidates/removes owned
work through ordinary campaign failure. Reset/build/cleanup invalidate before
native removal. Key creation/collection, jail use, rescue and CompleteLevel all
require the Hector receipt; no new wallet, rescue timer or reward pool. A valid
receipt survives ordinary corpse retirement. Late joins receive current reveal,
combat/defeated phase, canonical HP and bounded telegraphs; client input grants no
rescue permission. The objective HUD/map and canonical 143-chapter manual explain
the gate; both manual readers share 31 regenerated transport chunks.

**Validation:** `python3 tools/test_checkpoint_g_integration.py` passed all **154
automated suites with zero failures**. `git diff --check` is clean.
Three new production-path suites exercise native lethal callbacks, real
contributor XP/loot handoff, exactly-once defeat/key/rescue, Level-20-only gating,
Level-21 advance, reveal/telegraphs/damage tags/LOS/ordnance bounds, target loss,
death/revival/disconnect, committed attacks under hit stun/Muted, late joins,
partial Create/Spawn failure, replaced entities/state/graphs, same-seed reset,
old Gordon corpse rewards, timeout/failure and cleanup. Health tests use actual
monster generation/variance; client tests run actual packet/render/cleanup paths
with supported native API doubles. No native Source acceptance is claimed.

First full run exposed two attributable legacy assumptions: RPG validation still
expected 21 templates (now 22 with Hector), and the campaign-only damsel fixture
assumed direct Level-20 completion without boss/rescue permission. Both were
updated; the fixture now explicitly proves both denied boundaries, while the
Hector suite executes the complete actual combat-to-rescue sequence.

**One native procedure:** on a fresh local gm_flatgrass test campaign with two
Heroes, use the server-console batch `lod_developer_mode 1; lua_run local r=LOD.RunManager r.State.Level=20 r:Regenerate()`.
Redeploy, use the existing `lod_rpg_gate_c_level 20` acceleration if needed and
resolve Character Sheet choices, then run `lod_warden_testkit` as each admin Hero.
Defeat Gordon normally: no Jail Key, one three-second Hector reveal. Confirm the
tethered center core is aimable from the court, inspect the giant from the upper
gallery, dodge each marked attack, and check entrance immunity. Have one Hero die,
revive and reconnect: phase/HP persist and stale attacks do not follow the new
life. Defeat Hector, take the single key, rescue Deborah and verify the existing
victory/staging flow reaches SECURE THE BAG at Level 21. On a fresh test encounter,
regenerate or fail during a warning and confirm immediate cleanup/no reward.
Capture console_latest.txt + rpg_summary_latest.txt; screenshots only for framing
or visual defects. Native 1–4-player tuning, Source collision/aimability, projection
sightlines, animation and real-network acceptance remain pending.

**Next bounded checkpoint:** expanded Level-20 finale celebration presentation,
using the existing rescue/victory/staging authorities. Reconcile exact Deborah,
damsel and Hero choreography with the live GDD; never postpone or duplicate
rescue settlement, intermission or Level-21 progression. Validate and publish
separately; retain all earlier native acceptance obligations.

---

# Previous checkpoint — Game Master Equipment Quiz

Built on verified remote main `c0526c9f5a4ebe68af890131ed888899183eb45e`;
no intervening work replaced. Read AGENTS.md, retained P9 Game Master brief and
live GDD 00 → 01 → relevant 05/06/07/90 rules plus the exact HUMAN crypto anchor.
Recorded and read-back verified LOD-EVENT-QUIZ-001 in 05/06/07/90 and HUMAN under
explicit author design delegation. File-backed read found no protected controls.
No VPS deployment or Steam Workshop publication.

**Scope/activation:** `equipment_quiz` is one common optional REWARD from Dungeon
Level 1: eight archetypes before Level 5, nine thereafter. Preserve exact ordinary
non-exploding 1d4, unique types, rare fourth slot, independent streams, default-on
population and saved operator opt-outs. Only Equipment Quiz is implemented; the
lightweight VGUI shell can host later challenges without implementing them now.

The Game Master uses the grinning red Staging Hermit model/pose without revealing
Hector. His ordinary flat off-critical-path dead-end alcove and flat approach
mouth reserve against encounters and other events. The mouth may meet an ordinary
critical route, but not an objective/encounter cell. Existing ordered route proofs
and combined hazards/blockades/shortcuts remain authoritative. Candidate exhaustion
rejects the entire build within 64 candidates without dropping/rerolling selected
events. Optional access may follow already-proven blockade resolution.

**Challenge/consent:** each Steam account gets one accepted attempt per campaign
dungeon, retained across reconnects, replacement Heroes and same-dungeon layout
regeneration. Simultaneous Heroes play independently. Use opens a 30-second offer
with explicit loss risk; decline is free. Acceptance starts a separate 30-second
answer window. Select uniformly among distinct worn procedural items in the seven
wearable positions; paired gloves count once. Canonical exchange protections
exclude weapons, consumables, starter/protected/bound/economy-excluded gear and
DFT recreations. No eligible item, full eight-token collection, unavailable store
or failed decoy construction spends no attempt.

Three uniformly styled cards show the real item and two plausible canonical
same-family/same-depth decoys. At most 32 deterministic generation trials produce
distinct cards, then deterministic shuffle. Cards contain only name, slot and
mechanical description; dungeon metadata, seed, ownership, item ID and correct
marker are omitted. Decoys never enter inventory, drops or trade.

**Settlement/lifecycle:** exact current event/native entity/graph/state/generation,
account, Hero object/identity, body spawn serial, equipment life, item record,
nested owners, complete selected-item contents and occupied slots bind the session.
Wrong answers stage canonical UnequipItem/Discard, revalidate the complete live
inventory against callback changes, then seal theft once and refresh canonical
stats/effects through Equipment Sync. Correct answers use GenerateToken and shared
CryptoDirector:SettleDungeonToken with existing CryptoStore account/receipt/history
transaction. Treasure delegates to that same authority; no parallel inventory,
wallet, currency or progression system. Success requires canonical commit or
verified exact-token durable receipt recovery. Duplicate/reentrant inputs cannot
award or steal twice.

Reward storage failure retains the same correct answer and frozen token as pending;
Use/retry only retries settlement while the exact life/item/event remains valid.
Pending releases UI/equipment restrictions. No reward reroll or second guess.
Cancel, close, answer timeout, death, disconnect, range/LOS loss or lifecycle/item
invalidation spends the accepted attempt but takes nothing and awards nothing.
An unaccepted offer ends freely. Cleanup invalidates sessions and clears locks;
0.25-second maintenance reuses the EventDirector Tick dispatch. Terminal NPC
visibility is per account; other Heroes and unplayed late joiners still see him.
A new dungeon/campaign resets attempts; regenerated layouts do not.

**UI boundary:** the reusable shell closes existing sensitive pages/popups and
blocks supported Player Menu tabs, direct opens, keys, commands and request paths
while answering. Server rejects ordinary equipment management and suppresses
inventory snapshot/inspection delivery during play. Combat and movement remain
available; the world never pauses or grants invulnerability. This enforces normal
UI use, not secrecy against modified clients retaining prior snapshots. Phase
ordering rejects stale/duplicate/downgraded UI packets. Pending is never shown as
success. The canonical manual now contains 142 chapters in 31 transport chunks.

Validation: `python3 tools/test_checkpoint_g_integration.py` passed all **151
automated suites**, zero failures. A final focused lifecycle rerun also passed
the receipt-recovery and adversarial callback refinements completed during the
full run. The three new suites exercise actual native
API boundaries with engine doubles: production generation, real equipment and
SQLite settlement, and actual client shell/routes. The production suite covers
10 accepted full quiz builds and 1 bounded rejection, every catalog partner, all
four count outcomes, actual encounter reservations, independent ordered progression,
deterministic retry, partial/failed Spawn cleanup, late joins and exact teardown.
Lifecycle tests cover eligibility, same-family deterministic secret-free cards,
paired gear, stat refresh, simultaneous Heroes, failed item staging, full collections,
SQL ledger/COMMIT rollback, pre/postcommit exceptions and receipt recovery, reentry,
range/LOS/clock/freeze cancellation, exact owner replacement, reconnect and cleanup.
Client tests cover supported open/console/request routes, modal/packet semantics,
pending/cancel unlock and per-recipient exact-entity disappearance. No native Source
acceptance is claimed.

One native procedure: on gm_flatgrass with two deployed Heroes wearing expendable
ordinary gear and room for one DFT, enable developer mode and run
`lod_event_preview_generate equipment_quiz`; redeploy and visit the printed locator.
Both accept: confirm readable three-card layout and blocked P/I/O/Wallet routes;
one answer correctly and the other incorrectly. Verify exactly one DFT versus
exact worn-item loss/stat refresh, independent disappearance, and reconnect no
replay. On a fresh dungeon repeat with cancel/30-second timeout and regeneration:
no theft/reward, no lingering UI lock, no renewed same-dungeon attempt. Check
Hermit grounding/grin, alcove approach and ordinary objective order. Capture
console_latest.txt + rpg_summary_latest.txt; screenshots only for visual defects.
Native Source multiplayer, collision, animations and ordinary input acceptance
remain pending, along with earlier native acceptance obligations.

Next bounded checkpoint: **Hector the Director encounter and Level-20 rescue gate**.
Reconcile the retained P10/live GDD exact combat contract before implementation;
reuse canonical boss/projectile/status/lifecycle authorities and enforce
Gordon → Hector → Deborah, preserving Levels 1–19 and Level 21+ cash progression.
Keep finale presentation as a separately scoped follow-up if needed. Do not start
other Game Master minigames during that gate. Validate, commit and push separately.

---

# Previous checkpoint — Skeleton of a Hero combat blockade

Built on verified remote main `7427922b2ee6bfc93a01a41e0abc9d847a66953f`;
no intervening work replaced. Read AGENTS.md, retained P9 Skeleton brief and live
GDD 00 → 01 → relevant 02/03/04/05/06/07/90 rules. Recorded and read-back verified
LOD-EVENT-SKELETON-001 in those tabs and HUMAN under explicit author design
delegation. File-backed read found no protected controls. No VPS deployment or
Steam Workshop publication.

**Scope/activation:** `skeleton_blockade` is one common BLOCKADE from Dungeon
Level 1; catalog size seven before Level 5, eight thereafter. Exact ordinary
non-exploding 1d4, unique types, rare fourth slot, independent streams, default-on
population and saved operator opt-outs remain unchanged.

The hostile is a canonical `lod_hostile` generated from the Hero ability/naming/
identity framework, with uniform seeded Fighter/Rogue/Wizard choice and Combat
Level `min(20,D+2)`. It has 100 starting HP plus class d10/d8/d4 progression dice,
canonical growth/derived stats, identity perks, eligible automatic AI drafts at
1/3/6/9/12/15/18 and a Level-20 class capstone. It earns no XP and has no extra
party/size/HP/damage jitter. Ordinary enemy defense tuning remains. AI actor and
actual-capability restrictions exclude unusable player UI, movement, equipment
and spell-form grants. Hero and ordinary enemy generation are unchanged.

Fighter reuses Runner melee, Rogue Soldier SMG bursts, Wizard Arc Caster warnings
and ground arcs. Shared class/dice/defense/status/navigation/health regeneration
and death authorities execute the generated profile. Skeleton DEX movement and
Rogue Dodge use matching shared locomotion targets. Wizard retains normal owned
Content milestones (1/4/8/14), cycles them, and pays 12 base offensive Magic plus
Content surcharge at release through canonical cost/pool rules. Interrupted or
unfunded casts do not release; ordinary regeneration supplies subsequent casts.
Content context, saves, status/Morale and Earth Push use existing authorities.
Stock skeleton model/class tint has no mechanical color bonus or gear inventory.

**Solvability:** hostile occupies the approachable flat endpoint of one required
horizontal route; its tall gate uses the same physical event-barrier constructor
as the bribe. Both endpoints and edge reserve against existing encounters/events.
Closed-mask proof guarantees approach before opening, with every other blockade
and future objective boundary closed. Fully resolved ordered routes, combined
shortcut and hazard proofs remain mandatory. Since two cuts of the same required
route cannot both be approached with all blockades closed, a dual-bribe/Skeleton
selection deliberately rejects the whole build within the existing bounds. It
never drops or rerolls selected types/count to manufacture success.

**Lifecycle/rewards:** canonical lethal callback seals one exact-hostile receipt
before kill hooks. XP uses existing effective-damage 40/60 attribution and normal
archetype values; ordinary individualized enemy drops apply once, without bonus
cash/DFT/guaranteed item. The existing shared death scheduler opens native collision
after the damage stack. Revalidate exact event/graph/state/epoch/entity ownership
around opening and between reward recipients; seal shared resolution before sync.
Accepted deaths finish through a later temporary pause, while new attacks/deaths
remain frozen. Stale same-seed callbacks, replaced entities, removal and cleanup
cannot resolve or reward. Lost required live resources abort through canonical
campaign failure/cleanup instead of leaving an orphan barrier. Partial/zero-HP
creation rejects and cleans every resource. Late joins receive shared name/class/
level and defeated/open state. Ordinary and optimized navigation refresh at once.

Manual regenerated: 141 chapters, 31 transport chunks, with new encounter rules,
class attacks, rewards, shared passage and administrator preview.

Validation: `python3 tools/test_checkpoint_g_integration.py` passed all **148
automated suites**, zero failures. New profile suite covers 180 seeded profiles
plus deterministic repeats, actual shared class damage/Content/Magic regeneration,
DEX movement/Dodge, canonical native spawn, stale attacks and reentrant cast
payment. Production suite covers 11 accepted full builds and 2 bounded rejects,
all eight archetypes/count outcomes, actual encounter reservations, independent
combat/objective proofs, partial/zero-HP creation, late joins and path refresh.
Lifecycle suite exercises actual deferred hostile death, two-Hero XP attribution,
ordinary loot handoff, duplicate lethal events, opening failure, missing/replaced
resources, paused accepted death, stale outgoing damage and same-seed callbacks.
A final targeted lifecycle rerun also passed the post-sync teardown guard: an
opening snapshot callback cannot continue corpse mutation on a removed actor.
Initial full integration passed147/148; the older stabilization fixture omitted
native DamageInfo:GetAttacker and a nil-input passthrough needed preservation.
Corrected both, then the full148 passed. This is automated evidence only; no
native Source acceptance is claimed.

One native procedure: on gm_flatgrass with two deployed Heroes and developer mode,
run `lod_event_preview_generate skeleton_blockade`, redeploy, follow the printed
locator and fight from the approachable side. Both Heroes contribute; verify
class-appropriate attacks and defenses, visible skeleton/telegraphs, one XP/drop
settlement and one tall-gate opening. Reconnect to check shared open state; repeat
preview to observe the other class adapters and fresh reset. Check ordinary key,
boss and rescue order. Capture console_latest.txt + rpg_summary_latest.txt;
screenshots only for model/telegraph/label/collision defects. Native Source
multiplayer, collision, animations, targeting and prior acceptance remain pending.

Next bounded checkpoint: **one Game Master minigame** from retained P9. Reconcile
its exact wager/challenge/win/loss/reward contract with the live GDD; use existing
event, equipment/economy and lifecycle authorities. Prove optional approachable
placement, server-owned challenge/settlement, simultaneous Heroes, cleanup and
late joins; validate, commit and push. Hector remains a separate later gate.

---

# Previous checkpoint — Solvable item-value bribe blockade

Built on verified remote main `290668078f26f13276e1af05b4ab675de8ddb165`;
no intervening work replaced. Read AGENTS.md, retained P9 bribe brief and live
GDD 00 → 01 → relevant 05/06/07/90 rules. Added and read-back verified
LOD-EVENT-BRIBE-001 in those subsystem tabs and mirrored into HUMAN under the
current explicit design delegation. File-backed read found no protected controls.

**Scope/activation:** `bribe_blockade` joins the common pool from Dungeon Level 1.
Catalog size is six before Level 5, seven thereafter. Exact non-exploding 1d4,
unique types, rare fourth slot, existing RNG streams, default-on population and
archived operator opt-outs remain. No VPS or Steam Workshop deployment.

One physical toll closes a required ordinary horizontal route. Price: 50 $DEB
of canonical equipment value; no wallet debit, payout or change. One Hero may
confirm 1–8 owned unequipped procedural wearables. Existing exchange restrictions
exclude weapons, consumables, equipped/protected/free-starting gear and DFT
recreations. No partial contributions or escrow. The entire selected item value
is surrendered. One payment opens the route for every Hero for this generation.

**Guaranteed payment:** each toll owns a distinct reserved optional lost-property
cache containing one frozen ordinary generated ring worth at least the price.
Use at that cache earmarks its ring as shared collateral; it remains there, cannot
be sold/equipped/discarded, and any Hero may later confirm its surrender at the
toll. It is an event reward record staged through existing Equipment storage and
discard, never a second inventory store or a freely spendable item faucet. Full
bags do not block this zero-net-capacity payment. No starting inventory, random
drop, distant locked reward or another blockade is assumed by the solvability proof.

**Placement:** EventDirector proves the earliest legitimately reachable approach,
requiring each earlier key/reader before hypothetically opening its gate. The
cache must be reachable with this and all other blockades, future progression
locks and the arena/jail boundary closed. Both edge endpoints and cache reserve
against other events. Fully resolved ordered routes and combined shortcut/hazard
proofs remain mandatory. Candidate placement receives current masks/reservations
and revalidates the growing plan before accepting. Blockade candidates come from
the canonical critical path; at most64 sources, bounded adjacent/cache searches.
Warp partner search now considers those same masks. Exhaustion rejects/cleans the
whole build without changing selected types/count; not every seed must be accepted.

**Settlement/UX:** Use opens a server-owned 45-second itemized review. Explicit
confirm pays; cancel/close/expiry spends nothing. Revalidate exact native terminal,
cache and captured barrier; Hero/account/body life; inventory pointer, nested
owners and complete contents; current graph/campaign/dungeon, clock, role,
range/LOS and shared state. An instance-wide lock serializes all Heroes. Prepare
native opening reversibly, recheck after native/LOS callbacks, then seal inventory,
collateral and shared result synchronously before presentation. Rollback restores
only the captured barrier still owned by the same dungeon, independently of an
invalidated terminal/cache. Postcommit sync failure cannot charge again. Existing
snapshots supply both endpoints and shared state to late joins. Partial creation
and teardown invalidate reviews and remove every owned entity.

Native geometry reuses the existing tall progression gate collision/rendering;
its index0 toll presentation cannot invoke keycard progression. Existing ordinary
and optimized navigation consult current event edges; event-state signatures
invalidate cached paths immediately on opening/reset. Manual regenerated to140
chapters/31 chunks and documents payment, collateral, cancellation and preview.

Validation: `python3 tools/test_checkpoint_g_integration.py` passed all **145
automated suites**, zero failures, on the final source/test tree after native API
correction. The preceding full run also passed145; final rerun covers the
corrected native boundary explicitly. Initial integration
passed144/145; only the new test incorrectly requiring seed32 to succeed failed.
It now explicitly proves bounded whole-build rejection and cleanup. Native API
verification replaced an unsupported getter with IsSolid; both new fixtures
explicitly remove the unsupported method. Focused payment
checks pass exact49/50 boundary, excess value, eligible source ownership, duplicate
IDs, cancel/retry, full bag collateral, simultaneous Heroes, inventory/life/account
replacement, partial native opening/rollback, post-LOS movement/reclosure, late
joins, cleanup and client confirmation/cancel packets including narrow UI width.
Production tests use actual RunManager, encounter reservations and all seven
archetypes: eleven valid sampled layouts cover counts1–4; seed32 explicitly
proves clean bounded rejection without selected-event changes. Independent graph
walks prove payment access and full objective order.
Independent review found the terminal/cache-invalidated rollback gap; fixed and
covered. Automated boundaries do not establish native Source acceptance.

One native procedure: on gm_flatgrass with two deployed Heroes in developer mode,
run `lod_event_preview_generate bribe_blockade`, redeploy and follow the printed
cache/terminal locators. Recover the shared ring, cancel a review, then have both
Heroes review and confirm: only one settles and both pass the open tall barrier.
Reconnect to verify shared opening; regenerate and instead review/cancel/pay eligible
unequipped gear, checking the exact items disappear once, excess gives no change,
and ordinary gate/objective order remains intact. Capture console_latest.txt +
rpg_summary_latest.txt; screenshots for collision/label/review defects. Native
collision, Use/controller/VGUI, concurrent packet delivery and earlier multiplayer
acceptance remain pending.

Next bounded checkpoint: **one Skeleton of a Hero BLOCKADE** from retained P9.
Reconcile authored class/stat/feat/level/reward rules with the live GDD; reuse
canonical Hero generation/combat, shared blockade placement/progression and event
lifecycle. Prove combat resolution opens the exact obstacle once, combined catalog
solvability, cleanup and late joins; validate, commit and push. Game Master
minigames and Hector remain later gates.

---

# Previous checkpoint — Permanent paired warp-hole shortcut

Built on verified remote main `943d33a2c7a58461fc95a62e561b6c6188d58b5c`;
no intervening work replaced. Read AGENTS.md, retained P9 warp-hole brief and
live GDD 00 → 01 → relevant 05/06/07/90 rules. Added and read-back verified
LOD-EVENT-WARP-001 in those subsystem tabs and HUMAN under the current explicit
design delegation. File-backed GDD read found no protected controls.

**Scope/activation:** `warp_hole` is one optional common UTILITY archetype from
Dungeon Level 5 onward. Two endpoints count once. Earlier dungeons retain the
five-entry catalog; later dungeons select from six. Exact non-exploding 1d4,
three common plus rare treasure on four, named RNG streams, default-on population
and saved operator opt-outs remain. The explicit unranked single-event preview
may bypass the level threshold. No VPS deployment or Steam Workshop publication.

**Pairing/play:** two dormant cyan stock-asset endpoints occupy distinct ordinary
flat optional cells on different physical floors. Both reserve their cells and
exclude protected/safe/objective/encounter/critical/stair/void locations. Shared
EventDirector endpoint validation proves equivalent reachability at each ordered
progression stage, including jail/arena locks, and ordinary bidirectional return
routes. Combined event masks must preserve that proof. Canonical navigation
receives no extra graph edge. Search is deterministic and bounded to 64 source
candidates and 64 partners per source; exhausted placement rejects the build,
without truncating or rerolling its event count.

Press E at either end: the first successful safe traversal links both for the
current dungeon. Traversal is free and repeatable for every deployed living Hero,
with a one-second per-Hero debounce and no account claim. SafeTeleport validates
the fixed cell-center landing using the full standing hull, generated floor,
unsafe contents and occupancy. Unsafe or stale arrivals leave the Hero in place
and cannot activate the pair. Exact Hero/account/body-life, both native endpoint
bindings, source cell, current route, clock and generation are revalidated at
movement commit. Existing relocation authority clears incompatible movement and
momentum while retaining facing. No displacement of occupants or queued teleport.

Existing event snapshots include both native endpoint identities, cells, destination
floors and shared linked state for late joins. HUD presents dormant/linked state,
endpoint number, destination floor and Use action at either end. Both locators
print in preview. Generation replacement resets the pair to dormant; normal
teardown invalidates ownership before removing both entities. Partial creation
rejects and cleans the entire build. The manual reflects selection and traversal;
regenerated 139 chapters/31 transport chunks.

Validation: actual production/encounter generation exercises all 1d4 count
outcomes, early-level exclusion and 12 warp-selected six-catalog seeds with
independent endpoint reservations and deterministic regeneration. Production-code
warp tests cover independent ordered-stage and ordinary-return proofs, endpoint
and combined-mask rejection, bounded rejection, full standing-hull/generated-floor
support, water/hurt/occupancy, vehicle/noclip rejection, native Use/repeated return,
independent Heroes, cooldown, exact body-life/account/native ownership, both-end
HUD matching, stale client rows, late joins, partial creation failure and teardown.

Focused callback tests exposed two attributable gaps: cleanup could clear the
repeatable interaction table before release, and native movement teardown could
invalidate an initially clear arrival. Capture the original admission table and
recheck landing after movement teardown/LOS, followed by a pure ownership guard
immediately before SetPos. Both regressions pass. Focused independent review found
no further concrete blocker. Manual byte/content/reader checks pass.

Final required gate: `python3 tools/test_checkpoint_g_integration.py` passed all
**143 suites**, zero failures, after the callback fixes and final test additions.
The earlier integration also passed; the final rerun verifies the finished tree.
Native Source collision, Use/controller, visual presentation and packet-delivery
acceptance remain pending; automated boundary doubles do not establish them.

One native procedure: on gm_flatgrass with two deployed Heroes in developer mode,
run `lod_event_preview_generate warp_hole`, redeploy and follow either printed
locator. Press E to link/traverse, return after one second, and have the second
Hero traverse independently. Occupy the arrival center to verify refusal without
movement, reconnect to check both linked endpoints, then regenerate to verify
old props disappear and the new pair is dormant. Check ordinary stair return and
unchanged gate/objective order. Capture console_latest.txt + rpg_summary_latest.txt;
use screenshots for endpoint/HUD defects. Earlier native multiplayer/economy
acceptance obligations remain open.

Next bounded checkpoint: **one item-value bribe BLOCKADE** from retained P9.
Reconcile payment threshold, eligible items, party ownership and cancellation with
the live GDD before implementation. Prove payment is realistically available from
the approachable side without circular progression dependencies; use existing
equipment/value and transaction authorities. Validate solvability, exact inventory
ownership, multiplayer settlement, retry and teardown, then commit/push. Skeleton
blockades, Game Master minigames and Hector remain separate subsequent gates.

---

# Previous checkpoint — Optional physical False-floor hazard

Built on verified remote main `d87ac3a4a7483c41c3dbc06c8f298c9e999b2590`;
no intervening work replaced. Read AGENTS.md, retained P9 false-floor brief and
live GDD 00 → 01 → relevant 05/06/07/90 rules. Added and read-back verified
LOD-EVENT-FALSE-FLOOR-001 in those subsystem tabs and HUMAN under the current
explicit design delegation. The fresh file-backed read found no protected controls.

**Scope/activation:** one optional `false_floor` HAZARD joins the approved
production catalog as its fourth common archetype. Existing non-exploding 1d4
selects one to three unique common entries, or three common plus rare DFT treasure
on four. No count truncation, extra roll, economy change or population-setting
reset. Default-on population and saved operator opt-outs remain. No VPS deployment
or Steam Workshop publication.

**Placement and play:** a centered 128×128-unit physical panel in an ordinary
upper-floor cell opens beneath a grounded deployed Hero whose standing footprint
fits inside it. The directly aligned destination is exactly one floor down. Both
cells reserve distinct optional locations outside protected objectives, encounters,
stairs, voids and critical routes. Every ordered gate/jail stage must give both
endpoints equivalent reachability and an ordinary bidirectional route between them.
Combined hazards/blockades must preserve that proof. The surrounding rim stays
solid, so players can avoid the panel. Canonical graph topology remains unchanged.

The builder splits only the selected existing slab into four rim boxes and a lid.
The shared SafeTeleport standing-hull/generated-floor authority checks the landing
and full drop column. Exact Hero/body life/account, event entity and current
campaign/dungeon ownership are revalidated before activation. Native gravity and
ordinary fall consequences apply; no teleport, velocity rewrite or deferred
player-displacement callback. Shared opening lasts at least three seconds and
closes/rearms only when the aperture is empty. No claim, reward or account lockout.

Existing EventDirector owns the shared tick, lifecycle, snapshots, preview and
cleanup. Partial creation leaves the original slab solid. Cleanup restores it only
when safe; an occupied open assembly loses all event bindings and remains inert
under the existing builder until full geometry teardown, avoiding entombment. Armed/open state and lower endpoint reach late joins through current
snapshots; native geometry stays transmitted while custom rendering hides the
open lid. The manual reflects the five-entry catalog and physical hazard;
regenerated 138 chapters/31 transport chunks.

Validation: production-code tests exercise the real floor compiler/anchor,
independent ordered-stage and return-route proofs, invalid/reserved/critical
endpoints, bounded placement rejection, partial slab-creation failure and retry,
actual generated floor support/standing hull/drop column, obstructed/water/occupied
landing rejection, grounded/role/life eligibility, shared reset and physics-object
occupancy, repeat use by a second Hero, late-join snapshots, regeneration, stale
open/reset callbacks and ownership replacement during clearance. Occupied cleanup
transfers inert geometry to builder ownership without closing through a body.
The combined five-entry catalog passes all count outcomes and the first 12
hazard-selected production/encounter seeds; prior four-entry settlement tests remain.
Native geometry rendering tests preserve hidden/rearmed state through full updates.
Manual byte/content/reader checks pass. Focused review found no remaining concrete
geometry, progression or lifecycle defect.

Initial integrated run: 141/142 passed; the existing full-update fixture lacked
native GetNW2Bool, newly consumed by floor rendering. Added real stored getter/setter
semantics and hide/full-update/rearm assertions; the focused suite then passed.
Final integrated gate: `python3 tools/test_checkpoint_g_integration.py` passed
all **142 suites**, zero failures.
Native Source gravity, collision, presentation and packet transport acceptance
remain pending; automated boundary doubles do not establish native acceptance.

One native procedure: on gm_flatgrass with two deployed Heroes, run
`lod_event_preview_generate false_floor`, redeploy and follow the printed locator.
Walk around the rim, then step onto the center: verify one-floor descent, ordinary
stair return, shared opening and safe reset after at least three seconds. Have the
second Hero occupy the landing/opening to verify refusal/delayed closure; join or
reconnect while it is open, then regenerate to verify no old panel remains. Capture
console_latest.txt + rpg_summary_latest.txt; screenshots for geometry/prompt defects.
Earlier native multiplayer/economy obligations remain open.

Next bounded checkpoint: **one permanent warp-hole UTILITY shortcut**, from retained
P9. Reconcile exact use/pairing/reset/tuning with the live GDD first; extend current
event endpoint validation and SafeTeleport rather than add navigation or movement
authorities. Prove both ends preserve progression/objective order and safe arrival,
validate combined-catalog lifecycle/cleanup, then commit/push. Bribe/skeleton
blockades, Game Master minigames and Hector remain separate subsequent gates.

---

# Previous checkpoint — Combined Dungeon Events activation

Built on verified remote main `2354e81d5a95dbe99f93b1c84713f9d5941120e7`;
no intervening work replaced. Read AGENTS.md/current checkpoint and live GDD
00 → 01 → relevant 05/06/07/90 rules. Fresh file-backed read found no protected
controls. Added and read-back verified LOD-EVENT-POPULATION-001 in 05/06/07/90 and
HUMAN under retained design delegation. No new event archetype in this checkpoint.

**Implemented/activation decision:** the four existing production definitions now
populate ordinary dungeons. `EventRegistry.PopulationReady=true` approves the
catalog; `lod_events_enabled` defaults to 1 for new configurations. Existing
archived/operator-selected 0 remains respected; operators can set 1 for subsequent
builds. No live VPS or Workshop configuration/deployment occurred. Approval is
based on the finite automated gate below, not native Source acceptance.

Selection retains the exact authoritative non-exploding 1d4 count. Counts 1–3
choose distinct common archetypes (Debbie Slots, locked loot chest and Debbie
Vending). Count 4 adds one rare archetype; the current sole rare entry is DFT
Treasure. Treasure therefore appears on 25% of unbiased count rolls, the minimum
possible with four entries and no count truncation/repetition. This is selection
frequency, not a claim of extreme rarity or exact observed frequency after build
failures. Common entries use the existing catalog stream; a separate named
rare-catalog:v1 stream isolates rare choices. Future rare entries share the fourth
slot. A catalog with any rare entry requires at least 3 common entries; incomplete
pools fail closed. Catalogs without rare entries retain prior selection behavior.

All actual archetypes/members reserve distinct validated cells against the real
maze/progression/safe-cell/required-route authorities. Treasure still selects 1–2
physical members while counting once. Existing 64-candidate/member placement bound
and generation authorities remain. Rejected placement or partial creation cleans
and rejects the complete build, never reduces its event count. Same-seed retry
reproduces the complete selected plan and unrelated graph; no new layout/count
reroll machinery was introduced. Existing transaction, reward and per-account
claim authorities remain intact across coexisting events.

Combined-path testing identified and repaired two lifecycle gaps: Slots previously
lacked final exact-Hero/native-entity authorization after SQL writes; Chest.Open
could continue after lockpick feedback removed its entity. Shared
EventDirector:InteractionCurrent now checks exact Hero/account, tracked native
entity/binding, deployed cooperative role, lives, live clock, range/LOS and current
generation. Slots uses a validate-only existing CryptoStore participant immediately
before COMMIT. Ordinary/DFT chests reuse the guard after lockpick feedback and
before delivery. Both retain exact life and resolving-claim bindings. Rejected
successful lockpicks keep their immutable result for a valid retry.

Added admin/server developer command `lod_event_population_preview [levelSeed]`:
one-shot full-catalog generation with the actual count, unranked campaign, all
member locators and a warning about actual keys/persistent $DEB/DFTs. It grants no
funds/items and does not change the saved population setting. Optional integer
seed uses existing debug regeneration, never overrides the d4 outcome. Individual
previews remain supported. Manual reflects ordinary activation and operator opt-out;
regenerated 137 chapters/31 chunks. Remaining catalog, minigames and Hector are not
claimed complete.

Validation: focused real-production/SQLite tests cover all 1–4 counts and both
Treasure member counts through RunManager generation, deterministic plans and
unchanged unrelated maze/progression, all four native-Use settlement paths for
two accounts, independent inventory/wallet/DFT results, receipt hydration/reconnect,
late joins, exact same-seed failure/retry, bounded rejected placement, partial
creation cleanup, stale SQL/callback ownership, default-on/saved-off/release-gate
behavior, and one-shot preview authorization. Prior event/chest/wallet/vending
and manual regressions remain green. A focused actual encounter-planner/m3 build
seam check preserves all 10 encounters and avoids 23 protected cells while
reproducing seed 2 with four archetypes/five entities. Native geometry, traces
and packet transport remain test doubles; hostile AI/native collision are not
claimed accepted.
`python3 tools/test_checkpoint_g_integration.py` passed all **141 suites** with
zero failures, including the combined encounter/event check.

Native acceptance pending: on gm_flatgrass with two deployed Heroes (one Rogue),
run `lod_event_population_preview 2`, redeploy and follow the printed locators.
This tested seed gives 4 archetypes/5 entities without overriding the count roll.
Exercise all four events independently,
verify inventory/wallet deltas and reconnect/replay rejection, then regenerate
and confirm cleanup. Preview uses real funds/keys and may award persistent DFTs;
use ordinary play funds and the existing one-key testkit if needed. Capture
console_latest.txt + rpg_summary_latest.txt; screenshots for collision/prompt/model
defects. Controller/Use, native collision/presentation and multiplayer acceptance
remain pending, alongside earlier native obligations.

Next bounded checkpoint: **False-floor HAZARD event**, the retained P9 example.
Use one modest optional floor that drops a Hero to a validated lower level; prove
both endpoints preserve gate/objective order and a route back, with no stranding
or unsafe/stale displacement. Reconcile exact interaction/reset/tuning in live GDD,
reuse maze collision/movement/lifecycle authorities, and test the combined catalog
before commit/push. Do not expand into bribe/skeleton blockades, warp networks,
Game Master minigames or Hector. Native acceptance remains a separate open gate.

---

# Previous checkpoint — Debbie Vending and explicit population activation gate

Built on verified remote main `d250ac903afcb5060272cbaf560de49266483f9f`;
no intervening work replaced. Read AGENTS.md, current checkpoint, retained P9 and
live GDD 00 → 01 → relevant 05/06/07/90 rules. Fresh file-backed read found no
protected controls. Under retained author delegation, added and read-back verified
LOD-EVENT-VENDING-001 in 05/06/07/90 and HUMAN. Existing equipment, chest, DFT,
wallet and generation behavior remain regression constraints.

**Implemented:** `vending_machine`, one optional nonblocking UTILITY machine.
Native Use buys one existing Healing Potion for10 server-local $DEB, once per
Steam account per campaign dungeon. Teammates have independent purchases. The
standard potion enters run-owned Equipment; it does not immediately heal. Existing
25 HP healing, negative-status cure, drink/throw controls, Throwable occupancy,
auto-equipping an empty Throwable slot and stack maximum3 are unchanged. Wearable
bag capacity does not replace the consumable-stack rule. No new food/item family,
DFT, currency, random reward conversion or separate purchase network request.

`Equipment:AddConsumable` stages inventory admission on a detached copy. Existing
`CryptoStore:Transaction` and its inventory participant commit price debit,
immutable receipt/history and the staged inventory together. Revalidate exact
account/Hero, equipment pointer/content/life, deployment/role, clock, native entity
and generation after SQL serialization/writes; assignment immediately precedes
COMMIT. Storage failure restores only the owned staged reference. No native Give,
network or feedback divides settlement; postcommit sync failures do not reopen
purchases. Normal inventory synchronization restores native representation if
needed. Full potion stack, insufficient funds and invalid/stale state spend
nothing. Persistent receipts survive reconnect, replacement Heroes, same-dungeon
regeneration and SQLite reconnect. Drinking/throwing/discarding/losing the potion
never refreshes that purchase. A new campaign/dungeon permits a new purchase.
Lifetime score, DFT collection and other wallet rules remain unchanged.

Uses the stock HL2 vending-machine model, existing Use/range/LOS and cleanup,
confirmation cue and Equipment/Wallet sync. Recipient snapshots/HUD show offer,
price, stack, funds/full/storage refusal and purchased state; current inventory/
wallet snapshots refresh counts. Manual regenerated:137 chapters,31 chunks.

**Activation:** four production archetypes now exist, but automatic population
remains OFF. New explicit `EventRegistry.PopulationReady=false` gate rejects full
planning even if a saved `lod_events_enabled 1` requests it. A fourth registration
cannot silently activate unreviewed population. Registry selection remains exact
1d4 with distinct archetypes; representative tests deliberately enable the gate
only inside their fixtures. Single-event previews still work. Admin/developer
`lod_event_preview_generate vending_machine` runs actual generation, marks the
campaign unranked, prints the locator and warns that purchases spend actual
persistent $DEB. No free-currency testkit was added. No VPS or Workshop deployment.

Validation: focused production-code/real-SQLite vending suite passes actual
generation/native Use and potion consumption; deterministic1–4 selection with
the real four-entry catalog; incomplete and complete catalog activation rejection;
funds/full-stack retries; detached admission rejection/throw; receipt/account reads
and history/account/ledger/COMMIT failures; exact inventory rollback; stale Hero,
account, inventory contents/reference/life, role, deployment, native entity and
campaign/dungeon; duplicate/reentrant interactions, consumed-item replay,
independent accounts, postcommit feedback failure, late-join/reconnect snapshots,
actual HUD and cleanup. Prior chest/DFT/foundation/manual regressions pass.
Integrated gate: `python3 tools/test_checkpoint_g_integration.py` passes all
140 suites with zero failures. Independent review found no remaining purchase-loss,
duplication, stale-state or activation-gate defect. Native Source acceptance is
not inferred from automated results.

Native acceptance pending: on gm_flatgrass, use two deployed Heroes with at least
10 $DEB from ordinary play and fewer than3 potions. Run
`lod_event_preview_generate vending_machine`, redeploy and follow its locator.
Verify posted price, one purchase debiting10 and adding one usable potion, independent
teammate purchase, full-stack refusal, and no repurchase after consumption/reconnect/
same-dungeon regeneration. Check model, collision, Use/controller and Wallet UI.
Preview spends actual persistent funds. Capture console_latest.txt +
rpg_summary_latest.txt; screenshot presentation defects. Earlier native checks
remain pending; automated evidence is not native Source acceptance.

Next bounded checkpoint: **Complete-catalog activation readiness**. Exercise the
actual four-archetype catalog together across every1d4 count, placement retry,
member cleanup and lifecycle path. Resolve and record treasure rarity before any
activation: with four unique entries, count4 necessarily includes treasure, so
its inclusion probability cannot be below25% without expanding the catalog or
explicitly revising design. Choose and document a coherent finite activation path,
then validate/commit/push that checkpoint. Do not flip PopulationReady merely
because catalog size is four. Further blockade/hazard/shortcut catalog, Game Master
minigames and Hector remain deferred; do not implement them opportunistically.

---

# Previous checkpoint — DFT treasure chests and atomic key settlement

Built on verified remote main `25263756da7ab548aae0ad02a33a1fdba700b4cd`;
no intervening work replaced. Read AGENTS.md, the current handoff, retained P9,
and live GDD 00 → 01 → relevant 03/05/06/07/90 rules. A fresh file-backed GDD read
found no protected controls. Under the retained author delegation, added and
read-back verified LOD-EVENT-TREASURE-001 in 05/06/07/90 and HUMAN. This explicitly
promotes active-dungeon treasure minting as an exception to the older rescue-only
DFT restriction; existing rescue, milestone and Abundance authorities remain.

**Implemented:** `treasure_chest`, one nonblocking REWARD archetype with one
uniform non-exploding 1d2 determining one or two physical chests. The selected
archetype counts once toward event count. Each member has its own stable ordinal,
entity, validated optional cell, account claims and snapshots. Registry accepts
maxInstances=2 only for nonblocking REWARD definitions. Dedicated instance-count
and per-member placement streams preserve singleton generation. Every member
gets at most64 placement candidates; a rejected second placement/creation rejects
and cleans the whole group. Build reports distinguish archetypes from instances;
developer preview prints every member locator.

Each Steam account receives one persistent DFT per member per campaign dungeon.
Ordinary and treasure chests share one lock/key admission path and actual Rogue
derived device-use odds. Normal Use spends one finite Chest Key; Rogue without
a key picks once, and sprint+Use deliberately picks while carrying keys. Failure
spends only that attempt; a later key still works. Treasure capacity is the existing
eight-token collection, independent of equipment bag capacity. Full/unavailable
collection before admission spends no key or attempt. Successful interrupted picks
retain their unlocked state and identical frozen token for free retry. Stored
attempts/rewards survive replacement Heroes and same-dungeon layout changes;
member identities never include replacement layout seed or selected event order.
A seed override may change the generated member count, never renew either claim.

CryptoDirector generates the existing versioned equipment-backed token and owns
TreasureCapacity/SettleTreasureChest; CryptoStore remains the only database writer.
Its additive optional transaction participant validates exact account/Hero,
equipment pointer/content/life, role, deployment, clock and dungeon after fallible
SQL writes/serialization, applies detached key/claim references immediately before
COMMIT, and compensates owned references on failure. No native grant, network or
presentation divides settlement. Account/token/immutable receipt/history commit
together. Repeated Use, token sale/recreation, reconnect and volatile claim loss
cannot remint. Existing balance/lifetime score are unchanged. Ordinary inventory
remains run-owned; wallet receipts persist across ordinary server restarts.

Owner snapshots/HUD show member ordinal, keys, actual Rogue odds, spent/unlocked
attempt, collection-full/storage failure and recorded Wallet reward. Reuse stock
crate presentation, normal Use, Die Log, equipment and wallet sync. Manual updated
and regenerated (136 chapters,31 chunks). Independent focused review found no
remaining loss, duplication, stale lifecycle or solvability defect.

**Activation:** `lod_events_enabled 0` remains the default. Three production
archetypes cannot satisfy full1d4 unique selection, so enabling full population
still fails closed. `lod_event_preview_generate treasure_chest` is a developer-only
unranked real generation preview. It explicitly warns that it spends actual keys
and awards persistent server-local DFTs. Existing `lod_chest_key_testkit` supplies
one key only when none is held; no direct DFT mint command was added. Production
rarity/frequency tuning remains deferred until catalog activation. No VPS or
Workshop deployment.

Validation: focused production-code/real-SQLite tests pass for both generated
member counts, distinct optional cells, solvability and rejected-member cleanup;
key and frozen-token identity; full equipment bag vs full DFT collection;
receipt/account reads and history/account/ledger/COMMIT failure rollback and retry;
actual Rogue success/failure and retained attempts; duplicate replay after sale
and SQLite reconnect; replacement Hero, changed layout seed, lifecycle/account/
equipment invalidation; late joins, actual HUD, and campaign/dungeon cleanup.
Ordinary chest, wallet, foundation event and manual regressions remain green.
Integrated gate: `python3 tools/test_checkpoint_g_integration.py` passes all
139 suites with zero failures. No native Source acceptance is inferred from this
automated gate.

Native acceptance pending: on gm_flatgrass with two deployed Heroes (one Rogue),
run `lod_event_preview_generate treasure_chest`, redeploy, and use the printed
locator(s). Use `lod_chest_key_testkit` for one key if needed. Verify one key → one
Wallet DFT, Rogue sprint+Use outcome/retained attempt, independent teammate/member
claims, full-collection refusal, and replay after reconnect/regeneration. Preview
awards are persistent. Capture console_latest.txt + rpg_summary_latest.txt;
screenshot prompt/model defects. Native collision, model, controller/Use, Wallet
presentation and co-op acceptance remain pending; prior native checks stay open.

Next bounded checkpoint: **Vending machine UTILITY event**, a modest fourth
archetype from retained P9. Reconcile/record consumable choice and transparent price
in the live GDD, reuse wallet/inventory transaction participation, prove capacity
and storage failures spend nothing, independent purchases, stale lifecycle and
late-join feedback, then validate/commit/push. Keep automatic population OFF until
an explicit complete-catalog activation gate proves actual four-archetype count/
uniqueness/placement and resolves production rarity tuning. Bribe/skeleton
blockades, hazards/warp shortcuts, Game Master minigames and Hector stay deferred.

---

# Previous checkpoint — Chest Key and ordinary locked-loot chest

Built on verified remote main `e380dbbfdcb86cd9f65a8849a8bd99a4f56322e5`;
no intervening work replaced. Read AGENTS.md, current checkpoint, retained P9 and
live GDD 00 → 01 → relevant 03/05/06/07/90 rules. Existing normalized Wand rule
supplies Rogue device-use probability; no new class formula. Under the retained
author delegation, added and verified LOD-EVENT-CHEST-001 in 05/06/07/90 and HUMAN
after a fresh file-backed read (no protected controls). P7/P8 and event foundation
remain regression constraints.

**Implemented:** `locked_chest`, one nonblocking REWARD chest in a validated
optional side branch, using the existing registry, generation, native Use,
lifecycle, snapshots and cleanup. Each Steam account gets one ordinary procedural
wearable per dungeon chest, retaining existing rarity, innate-family opportunity,
value and dungeon scaling. Rewards are individualized; no shared first-come race.
This is the ordinary locked-loot chest, not the deferred DFT treasure event.

Chest Keys use the existing finite inventory-stack, world pickup and snapshot
pipeline: cap9, bag-only, no Equip/Hold/throw action. The independent chest-key-v1
stream converts 1/16 of remaining eligible healing-potion outcomes after existing
Card/Feather/Hourglass and bomb decisions; those earlier outcomes and unrelated
streams stay unchanged. Inventory displays quantity, description and a key icon.
Shared pure `Equipment:StoreWearable` now owns bag admission for ordinary world
pickups and detached chest transactions; existing placement/capacity rules remain.

Use spends one Chest Key only when its reward is admitted. A Rogue without a key
uses one lockpick attempt; sprint-binding + Use chooses lockpicking while carrying
keys. Actual derived arcaneItemUseChance supplies the current 5% × Combat Level,
max95%, threshold; one named non-exploding d100. Fighters/Wizards require keys.
A failed pick spends the account's attempt but no key; later ordinary Use can pay
with a key. Full inventory or invalid preflight spends neither key nor attempt.
A successful pick interrupted before reward commitment retains the same success
and frozen item for free retry; changing Hero Combat Level, replacing a Hero or
regenerating the same dungeon cannot reroll it.

Key debit and item admission occur on a detached inventory via existing Consume
and StoreWearable. Revalidate exact Hero state, equipment pointer/content, life
serial, current dungeon token/graph, role, deployment and clock before the single
inventory-and-claim commit. No native grants/network callbacks divide that commit.
Postcommit feedback cannot reopen it. Attempt/reward records live outside the
replaceable Hero state, in one current-dungeon account map, surviving reconnect,
Hero replacement and same-dungeon regeneration/seed overrides. New campaign or
next dungeon gets new entitlement. No currency or DFT transaction is added here.
Owner-specific snapshots report keys, current Rogue chance, attempted/unlocked
and claimed state. Existing equipment snapshots keep the HUD key count current.

**Activation:** full population remains OFF (`lod_events_enabled 0`): two playable
archetypes cannot satisfy exact 1d4 unique selection. Admin/server developer preview
`lod_event_preview_generate locked_chest` marks unranked, runs the actual generation
path and prints a locator. Player-admin `lod_chest_key_testkit` supplies one key
only if none is held, requires normal grant eligibility and marks unranked; it
mints no funds/DFTs. No VPS or Workshop publication.

Validation: focused locked-chest, foundation event, equipment-runtime, Hourglass,
inventory UI and generated-manual suites pass. New coverage uses real production
inventory/RPG/loot/graph/director code, including 1,024 deterministic drop cases,
finite stacks, full pickup/inventory retry, rejected and throwing staged admission,
exact one-key debit, normal item validation, genuine Rogue success/failure and
class thresholds, one-attempt retention, interrupted-success retry, reentrancy,
stale Hero/inventory/life/role/dungeon, rebuilt-layout reward identity, late joins,
actual client prompts and developer authorization. Shared native test-boundary
setup is extracted from the prior event suite; its existing assertions remain.
Integrated gate: `python3 tools/test_checkpoint_g_integration.py` passes all
138 suites with zero failures. The first run passed 136/138: updated the old
healing-drop expectation for the explicit key conversion, and repaired a test-only
Character Sheet lookup that confused two feats sharing a display name. The latter
now follows actual offer order, retains exact text checks, and covers duplicate
names explicitly. Focused reruns and the complete final gate are green.

Native acceptance pending: on gm_flatgrass with two deployed Heroes (one Rogue),
run `lod_event_preview_generate locked_chest`, redeploy and use the printed locator.
Run `lod_chest_key_testkit` for the key user. Check bag-only key UI, one key/one item,
full-bag refusal, Rogue sprint+Use odds/result, independent teammate rewards,
reconnect/repeated Use and same-dungeon regeneration. Capture console_latest.txt
+ rpg_summary_latest.txt, plus a screenshot for prompt/model defects. Native model,
collision, Use/controller interaction and co-op acceptance remain unproven;
earlier native obligations remain open.

Next bounded checkpoint: **DFT treasure chest event**, one unique archetype capable
of spawning1–2 individually identified chests, each awarding one DFT. Reuse this
key/lockpick/event spine; establish atomic, verifiable key/DFT settlement through
existing inventory and CryptoStore authorities, full-collection/no-spend retry,
per-chest attempt/claim snapshots and lifecycle cancellation. Keep full population
gated with fewer than four production archetypes. Remaining utility/hazard/blockade
catalog, Game Master minigames and Hector stay deferred.

---

# Previous checkpoint — Dungeon Events foundation and Debbie Slots

Built on independently verified remote main
`62bacda9f0736825f68894f1731d09acf5215910`; no newer work replaced.
Read AGENTS.md, the retained P9 brief and live GDD 00 → 01 → 05/06/07/90.
The current author explicitly delegated missing mechanics and tuning. After a
protected-control-aware file-backed read, added and verified LOD-EVENTS-001 and
LOD-EVENT-SLOTS-001 in relevant 05/06/07/90 tabs and HUMAN. P7/P8 were preserved.

Implemented one server EventRegistry/EventDirector through the ordinary
RunManager → progression/graph → MazeBuilder pipeline. Registered REWARD,
BLOCKADE, HAZARD and UTILITY contracts use separate named count, selection,
placement and outcome streams. Full selection rolls exactly non-exploding 1d4
and chooses distinct archetypes. Planning permits at most 64 candidate cells per
selected archetype; rejected placement/creation fails the build and cleans it
instead of silently dropping events or accepting an unsolvable dungeon.
Canonical graph integrity and ordered gate/key/jail reachability protect safe,
objective, gate, transition, encounter and Warden cells. Combined hazards must
preserve the route; blockade resolution proofs cannot borrow access through
locked gates or other unresolved events. Placement callbacks receive isolated
copies; topology/proof mutation or exceptions reject the plan. New shortcut edges
remain unsupported until their endpoint contract ships with the travel catalog.

Lifecycle states cover planning, creation, active use, per-account resolving and
resolved claims, shared resolution and cleanup. Bind state, campaign epoch/run,
level/seed, graph, generation token and tracked entities. Require a living deployed
Hero, range/line of sight and a live dungeon; canonical timeout wins at expiry.
Invalidate ownership before teardown, including build failure, campaign replacement
and campaign failure. Compact current snapshots hydrate durable claims for late
joins/reconnects; old client tokens cannot restore a retired event. No client
payout request or invented inventory/DFT authority was introduced.

**Activation: full production population is OFF (`lod_events_enabled 0`).**
Enabling it with fewer than four production archetypes rejects generation with
an explicit catalog-gate error. The only playable archetype is **Debbie Slots**,
an optional nonblocking UTILITY machine. Developer-mode admin/server command
`lod_event_preview_generate slot_machine` runs an explicitly unranked, single-event
preview through real generation and prints its cell/world locator. This is not
complete P9 or a capped substitute for the 1–4 production contract. Ordinary
campaign generation remains event-free while the catalog is incomplete.

Slot tuning: one wager per Steam account per campaign dungeon, including after
reconnect, replacement Hero or same-dungeon regeneration/seed override. Stake
5 $DEB; one utility d4 returns 15 gross on 4 (+10 net) and zero on 1–3 (−5 net).
Expected net is −1.25. The immutable ledger key uses run/level/account; outcome
uses a separate campaign/dungeon/account stream, independent of regenerated
layout. Existing CryptoStore owns debit, payout, receipt and history in one SQL
transaction. Insufficient funds or storage failure spends nothing; retry cannot
reroll. Wallet sync, Die Log, confirmation cue, visible odds and both canonical
manual readers disclose the mechanic. Lifetime score, inventory and DFT holdings
are unchanged. Uses a stock receiver prop with player-passable collision.

Validation: the focused production event/real-SQLite suite passes. Four
representative test definitions exercise all four contracts and exact 1–4 full
plans; no fixture definitions ship in the production catalog. Tests cover named
stream determinism/uniqueness, protected/invalid placement, route solvability,
bounded rejection, immutable callback proofs, real RunManager generation through
native entity Use, insufficient funds, win/loss, failed ledger insert and COMMIT,
retry, reentrant/duplicate settlement, lifecycle replacement, cleanup, reconnect,
late-join packets and the actual client prompt/receiver. Existing wallet SQLite
regressions and generated manual parity also pass. Initial integrated result was
136/137: the new event fixture needed native-equivalent cycle/shared-reference
copying after callback isolation; assertions were retained and the focused suite
is green. **Final integrated gate: all 137 suites pass, zero failures**, including
syntax, release wiring, generated manual and existing P7/P8 regressions. These
are automated/headless results; native multiplayer acceptance remains pending.

Native Source acceptance remains pending: on gm_flatgrass with a teammate and
existing game funds, enable developer mode and run
`lod_event_preview_generate slot_machine`. Deploy normally, then use the printed
locator to reach the machine on this unranked test run. Check visible odds,
player-passable geometry, one debit/payout/Die Log result, denied repeat use,
independent teammate use, reconnect receipt and teardown after regeneration.
Check no-funds rejection without minting production balances. Capture
console_latest.txt + rpg_summary_latest.txt, plus a screenshot for visual defects.
No VPS deployment or Workshop publication; earlier native obligations remain open.

Next bounded checkpoint: **Chest Key + locked-loot chest REWARD vertical slice**.
Reconcile exact chest/lockpick/DFT rules, integrate finite keys into existing drops
and inventory and atomic chest claims into this director, prove key debit/reward
rollback and one Rogue attempt per chest. Keep full population gated until at
least four distinct playable archetypes pass their shared placement/lifecycle
contracts. Remaining events, Game Master minigames and Hector are deferred.

---

# Previous checkpoint — live rankings and complete party history

Built on independently verified remote main
`f85bac96e5662e676cd960462de656c4d06521e1`. The stalled Magic Hourglass
checkpoint was recovered from local `4bec7d2` and published with the exact same
Git tree `3b9c503256228a484dbfdbf8dfdfb0e8bc8655c3`; its retained 135-suite
integrated pass was not repeated merely to recover publication. No newer remote
work was replaced. Read AGENTS.md and live GDD 00 → 01 → relevant 06/07/90;
06's current live-ranking amendment, LOD-LB participation/ranked eligibility,
LOD-RETENTION-001 and the retained September 22 P8 brief govern this checkpoint.
No new game law or tuning was introduced, so no GDD amendment was needed.

The earlier progression checkpoint already implemented all positive persisted
$DEB/DFT holdings, current-session names, deterministic value/account ordering,
ten holders per page and a ranked live party row. Preserved that implementation.
Closed the actual remaining participation/lifecycle defects: BEGIN A NEW HERO
now archives the retired Hero's canonical display identity and admission order
only after successful replacement. No inventory, lives or usable progression is
retained. A repeated request or failed creation cannot duplicate the archive;
a new campaign starts empty. Live and completed rankings now use one RunManager
party projection, so all participating Hero generations survive in consistent
admission order, including disconnected/eliminated/Soldier-role participants.

Processed immutable runs cannot be projected as live again, even if finalization
flags lag. Loading completed storage filters duplicate run IDs and clears stale
live labels. A run-ID fallback makes equal legacy sequence ties deterministic.
Stakeholder late joins read current holdings rather than a possibly stale
broadcast cache. Corrected the board footer to describe its actual highest-dungeon
ranking. Existing top-ten party cutoff, ranked eligibility, holdings valuation,
12-second automatic pages and two-second update cadence remain authoritative.

Validation: the focused lifecycle, ranking, client-board and real-SQLite suites
pass. **All 136 integrated suites pass with zero failures**, including syntax,
release wiring, generated manual, P7 items, campaign clock, accepted movement and
Hero/Soldier lifecycle regressions. These are automated/headless results, not
native Source acceptance. New coverage runs
the actual board renderer and client receiver for 23 holders across 10/10/3-row
pages, continuous ranks, page cycling, empty/shrinking data, long names and live
completion. Real SQLite covers additional holders, ties, current names, account
deduplication, transaction cache invalidation and fresh late-join delivery.
Lifecycle tests cover replacement/replay/failure and resource-free retired
identity snapshots; ranking tests cover admission ordering, immutable completion,
processed-run suppression and duplicate persisted records. The first expanded
SQLite fixture used the pre-reload store instance after its intentional database
restart; corrected it to the current exchange store without relaxing assertions.

Native acceptance remains pending: on gm_flatgrass inspect both boards with a
teammate, confirm a qualifying ranked live run and an online positive holder,
then compare party membership after BEGIN A NEW HERO and at timer completion.
Observe pages with more than ten qualifying holders when available; do not mint
production balances for a visual test. Capture console_latest.txt and
rpg_summary_latest.txt, plus a board screenshot for layout defects. Earlier P7
native acceptance obligations remain open. No VPS or Workshop deployment.

Next bounded checkpoint: retained P9 **Dungeon Events framework**. Reconcile the
live GDD and existing generation/graph/reward/lifecycle authorities, then implement
one registered event pipeline with deterministic 1d4 unique archetype selection,
validated placement classes, lifecycle cleanup and late-join state. Establish a
finite solvability/seed/repeat/cleanup gate before stacking authored event content;
the brief's chest/Game Master/other event requirements remain unimplemented.
Do not repeat completed P7/P8 audits absent contradictory runtime evidence.

---

# Previous checkpoint — Magic Hourglass

Built on independently verified remote main
`1455c867fe630ebfcfa81ad0a6c5fce1ea890aee`; clean working tree, no newer work
replaced. Read AGENTS.md and live GDD 00 → 01 → relevant 05/06/07/90. The retained
P7 author brief fixes **2d4 minutes** and delegates missing design/balancing and
GDD synchronization. After a fresh protected-control-aware file-backed read,
recorded `LOD-HOURGLASS-001` in 05/06/07/90 and HUMAN and verified 07 readback.
This is the explicit item exception to the ordinary no-clock-extension lifecycle
law; deployments, reconnects and regeneration still cannot extend the clock.

**Magic Hourglass** is a rare finite Throwable stack, maximum three. Equip/hold
and press either LMB or RMB to consume one for exactly two non-exploding utility
d4 rolls, adding their sum × 60 seconds to the current shared deadline. All Hero
classes may use it; no Wand permission roll, personal Magic cost, damage/Boom
modifiers or projectile. The shared successful item cooldown remains 0.6 seconds.
Additional legitimate units accumulate even above 30:00. This does not refill
items on spawn or confer a permanent feat.

Extended the existing equipment source binding to retain the slot's actual item
key, allowing finite consumables to use the same ownership/lifecycle validation
as procedural equipment. Bind the exact item/slot/native weapon/owner, Hero
identity/state/life, run/seed/graph and current clock/deadline. CampaignTimeout
owns the synchronous validation → source debit → utility roll → extension
transaction; CombatRolls owns utility RNG and Die Log delivery. No client-supplied
duration or deferred callback. Failed debit and invalid/stale source or clock
roll/spend nothing. At or after expiry, canonical TIME OVER finalization wins.

The ordinary clock packet broadcasts the new remaining time immediately and
supplies late joins. Die Log records both dice and minutes added. Only warning
thresholds now below the extended remaining time are rearmed. Successful rescue
discards bonus time and resets/pauses the next dungeon at 30:00; unused stacks
follow existing Hero inventory persistence. Existing movement, barriers, rescue
and Hero/Soldier queue authorities are unchanged.

Equipment-eligible Healing Potion opportunities that selected neither Summon
Card nor Feather roll the independent magic-hourglass-v1 substream at 1/16
(49/1024 overall in that input category). Prior Card/Feather results, unrelated
conversion/affix streams, authored non-eligible rewards and frozen records remain
intact. Reuse the stock bottle with gold held tint, a code-native hourglass
inventory icon, contextual USE prompt and ordinary confirmation cue. The model
is provisional until native visual acceptance. Both manual readers share the
new chapter. `lod_hourglass_testkit` fills/equips three, marks unranked and changes
neither clock nor Magic by itself.

Validation: **135 integrated suites pass, zero failures**, including Lua syntax,
release wiring, generated manual, loot/JIT/crash replay, shared equipment/combat,
movement/overhead barriers, rescue and Hero/Soldier queue regressions. Focused
Hourglass, canonical campaign-timer and whitespace checks pass as well.
First integrated run passed 134/135; its only
failure was the old Healing Potion distribution floor before Hourglasses took
1/16 of the remaining pool. Scaled the existing healing/bomb coverage bounds by
15/16, retained Card/Feather thresholds and added explicit natural Hourglass
coverage. The corrected loot-mix suite passes. No production behavior changed
to satisfy that expectation. New coverage executes real inventory, source binding,
clock transaction, deterministic rewards and client packet receiver. It proves
minimum/maximum/intermediate dice, one debit/two rolls, cooldown/depletion,
failed-debit and ownership/role/life/clock rejection, stale source/clock records,
accumulation, warnings, rescue reset and late-join snapshots. The existing timer
suite now proves an extension postpones its original deadline, then rejects
another at expiry through real once-only campaign finalization. Initial focused
fixtures lacked native Vector addition and retained a frozen flag after their
stubbed deployment; corrected those boundaries without weakening production
guards. These are automated/headless results, not native Source acceptance.

Native gate pending: developer-mode admin on gm_flatgrass, deployed with a
teammate, run `lod_hourglass_testkit`; consume once and compare both HUD clocks
with the two Die Log dice. Repeat to depletion, swap/remove the stack, and verify
paused/expired clocks reject use. Capture console_latest.txt and
rpg_summary_latest.txt; visual/held-model and co-op acceptance remain open.
No VPS or Workshop deployment; earlier native obligations remain pending.

Next bounded checkpoint: retained brief **P8 live Stakeholders / Heroes of Legend
boards**. Reconcile live GDD and existing board/ledger authorities first. Prove
all qualifying current-session $DEB holders, ten rows/page, deterministic order,
live versus completed runs and no duplicate identities when a run completes.
Do not re-audit completed P7 items absent contradictory runtime evidence.

---

# Previous checkpoint — Boots of the Moon

Built on independently verified remote main
`0534845b185739f1a67e3bff0f5a900a1bc8da83`; clean working tree, no newer work
replaced. Read AGENTS.md and live GDD 00 → 01 → relevant 03/06/07/90.
The normalized tabs had no Moon Boots tuning. The retained P7 author brief
expressly delegates design/balancing and GDD synchronization; recorded
`LOD-MOON-BOOTS-001` in 03/06/07/90 and HUMAN after a fresh file-backed,
protected-control-aware read, then verified the 07 readback. No unrelated HUMAN
catalog audit or repeated completed checkpoint work.

Minimum-Rare Feet-slot **Boots of the Moon** grant passive **Moon Gravity**:
**25% lower gravity**, no recipe, Magic cost or cooldown. Innate allowance is
floor(50 × quality / 100); the existing independent 1/8 innate reward pool now
includes these boots. Normal generator, owned inventory, occupancy, valuation,
frozen records and derived grant descriptions remain authoritative. Equipment
uses the existing boots icon; the stock pickup box remains provisional. Both
manual readers share the new Moon Boots chapter.

The ordinary SetupMove authority and equipment refresh apply one native player
gravity multiplier to a living deployed walking Hero in a ready dungeon, outside
a vehicle. Native zero is handled as default gravity. The source composes with
the existing player multiplier and server gravity without compounding per tick.
Later native gravity changes become the new baseline while equipped. Cleanup
restores the saved baseline only when the current value still belongs to this
source; it does not overwrite a later external change. Held/Muted and attacking
do not turn off this passive. No Magic debit or refill.

Exact item/Feet-slot, equipment state, identity/life, run/seed/graph bind the effect
through the existing equipment-move source authority. Unequip/re-equip and source
replacement retire it immediately. Death, respawn, disconnect, Soldier/staging,
freeze/failure/level/graph changes and map cleanup reject the old binding. Stale
cleanup cannot clear a fresh binding; a fresh valid update can reapply surviving
equipped boots. No new timer or recurring actor scan. No teleport, extra jump,
forced velocity, invulnerability or fall-damage exception. Existing horizontal
control, jump/Cloud Step/Wall Jump impulses, Float On and Push remain shared;
accepted overhead wall and locked-gate collision still owns maze boundaries.

Validation: **134 integrated suites pass, zero failures**, including Lua syntax,
release wiring, generated manual, generator/JIT/crash replay, shared combat and
equipment, accepted movement/overhead barriers, rescue and Hero/Soldier queues.
The focused production Moon Boots suite and whitespace checks also pass.
The new suite covers real generated items/rewards, ownership/slot admission,
free passive activation, default and nondefault native gravity, noncompounding,
external changes and restoration, same-tick replacement, stale callbacks,
identity/life/state/run/seed/graph, Soldier/dead/inactive/build/freeze/failure/
vehicle/noclip rejection, map cleanup and native death/disconnect hooks.
These automated/headless results are distinct from native Source acceptance.

Native gate pending: as a developer-mode admin on gm_flatgrass, run
`lod_moon_boots_testkit`; compare jumps, descent and steering, then remove/swap
boots in midair. Check Cloud Step, Wall Jump, Float On, crate/locked-gate barriers
and legitimate upper routes. Confirm death/role/dungeon transition restoration
and co-op movement prediction. The kit preserves displaced inventory, does not
refill Magic, and marks the run unranked. Capture console_latest.txt and
rpg_summary_latest.txt. No VPS or Workshop deployment; prior native obligations
remain open.

Next bounded P7 checkpoint: **Magic Hourglass**. Reconcile the rare consumable's
2d4-minute extension with canonical server dice, current dungeon timer and
TIME OVER authority. Define finite owned-unit spending, one roll/extension,
stale lifecycle/deadline rejection and synchronized UI checks before implementing.
Preserve rescue progression, Hero/Soldier queues and accepted movement/barriers.

---

# Previous checkpoint — Wand weapon category

Built on independently verified remote main
`320034957fa998d768b87211972be421391c9660`; working tree was clean and no newer
work was replaced. Read AGENTS.md and live GDD 00 → 01 → relevant 02/03/06/07/90.
Retrieved only the exact HUMAN Arcane-item class-permission detail needed to
resolve the brief's existing Rogue success roll. A fresh protected-control-aware
read preceded GDD synchronization; recorded and read back `LOD-WAND-001` in
02/03/06/07/90 and HUMAN under the retained September22 author's express design,
balancing and synchronization delegation. The finite Beam weapon supersedes the
old guided-orb Magic Wand concept for this category.

`weapon_lod_wand` is a procedural weapon in the existing generator, inventory,
selection, acquisition, persistence and appearance-stamping paths. Each distinct
item starts with **12 charges** stored on its owned record. **LMB attempts Beam;
0 personal Magic; 0.65s cadence shared across copies**. Native clip/reserve is not
authoritative: no reload, ammo refill, ammo regeneration, copy swap or weapon
recreation can replenish charges. Zero remains a valid stored record; frozen
recreation preserves the frozen count. Mandatory starter families and frozen
records are unchanged. After established wearable conversion, eligible optional
weapon rewards use an independent named1/8 substream for Wand selection.

Canonical class permissions are executable, not just a derived label. Wizard
activation is automatic. Rogue rolls one deterministic non-exploding utility
d100, succeeding at min(95,5 × Combat Level)%:5/50/95/95 at Levels1/10/19/20.
A committed failed Rogue attempt consumes one charge and cooldown but creates no
Beam and spends no Magic. Fighter/other classes may carry but cannot activate.
Missing ownership, wrong native owner/active weapon, blocked status, empty pool,
cooldown, invalid aim and invalid lifecycle spend and roll nothing. Muted and
Intimidated use canonical status checks. The class roll and result use the shared
RNG and combat feed; it never enters damage dice or Boom logic.

Successful activation uses the existing Beam resolver: **3d6 plus shared WIS**,
ordered one-hit-per-body piercing, blocking architecture,1152-unit base range
plus existing spatial reach, shared global work/dice limits and cyan-core VFX.
The new Wand contract explicitly records3d6 while leaving ordinary Spellbook
Beam gameplay untouched. Each Wand's rolled affinity provides element/accent.
Its existing procedural weapon-hit rider chances use the shared equipment rider
resolver after effective HP damage to a survivor; no second automatic Content
rider is added. Compatible damage-side class/feat/gear/status/defense/attribution
and XP authorities remain shared. Charged activation grants no Form or Content,
spends no personal Magic, and emits no Magic-spent event, Quantum refund, Aura
Burst or scheduled Aftershock. RMB remains the ordinary Spellbook binding.

Bind the exact item/slot, native weapon, Hero identity/state/life and run/seed/graph
through the existing equipment-move source authority. Revalidate before spending
and before every subsequent Beam contact, so a synchronous death, role, equipment
or dungeon change cannot continue damaging later targets. Native Wand attempts
reveal Veil and end Statue. No delayed Wand entity, timer or second combat system.
Inventory descriptions show remaining/max charges; the held Wand has a persistent
charge/depleted HUD. Character Sheet directed stats now show the exact class-use
chance or PROHIBITED. Both manual readers document finite use and failure rules.
Presentation uses a bundled baton silhouette and shared Beam/cast cue; native
first-person model and co-op presentation acceptance remain pending.

Validation: **133 integrated suites pass, zero failures**, including Lua syntax,
release wiring, generator distribution/crash replay, shared combat/Magic/gear,
accepted movement/overhead barriers, rescue and Hero/Soldier queues. The new suite
executes actual item generation/admission/selection, class utility thresholds,
Beam damage and ordered contacts, world blockers, shared procedural status riders,
no duplicate automatic rider, per-copy charge consumption and serialized restore,
native weapon adapter/HUD, cooldown across copies, and stale identity/life/role/
run/graph/equipment rejection. The initial focused harness exposed recursive
copying of fake native entities through their owner references; corrected the
native boundary double to preserve entity identity, without changing production
logic or weakening assertions. After the integrated pass, strengthened live-charge
ownership/lifecycle negatives so empty-charge denial cannot mask a defect; focused
Wand tests pass again. Generated manual and whitespace checks pass. These are
automated/headless results, not native Source acceptance.

Native gate pending: on gm_flatgrass, as a developer-mode admin with a Wizard
Hero, run `lod_wand_testkit`; fire through two aligned enemies toward a wall.
Confirm both are hit once, the Beam ends at the blocker, charges decrement once,
Magic stays unchanged and reload does nothing. Swap/stow/reselect, respawn and
transition: each copy must retain its count. Repeat as Rogue to observe logged
success/failure and charge loss on failures; Fighter activation must fail free.
Check another player's view, first-person baton, charge HUD and Veil/Statue break.
The testkit selects an already-owned Wand without refilling it and marks the run
unranked. Capture console_latest.txt and rpg_summary_latest.txt. No VPS or Workshop
deployment; prior native acceptance obligations remain open.

Next bounded P7 checkpoint: **Boots of the Moon**. Reconcile lower-gravity equipment
with live movement/lifecycle authorities and the accepted overhead-wall constraint.
Define finite equipped ownership, gravity composition/restoration, source removal,
role/death/level change and maze-boundary checks before implementation. Preserve
fun ordinary movement, rescue progression and Hero/Soldier queues. Then Magic
Hourglass; do not begin either as part of this completed Wand checkpoint.

---

# Previous checkpoint — Tanuki's Ring

Built on independently verified remote main
`c29e372617380de753c1b11547891dbea75d496e`; clean working tree, no newer work
replaced. Followed live GDD 00 → 01 → relevant 03/06/07/90. The retained
September 22 P7 author brief delegates missing implementation/balancing and GDD
synchronization. Recorded and read back `LOD-TANUKI-RING-001` in 03/06/07/90 and
HUMAN after a fresh protected-control-aware document read.

The minimum-Rare, one-hand **Tanuki's Ring** grants passive **Statue** after two
continuous seconds of server-observed stillness on solid non-actor ground.
No arrow recipe, Magic spending, cooldown or fixed duration. Innate allowance
is floor(50 x quality / 100); the existing independent 1/8 innate wearable pool
includes the ring without changing original seven-family RNG or frozen records.
Ordinary equipment ownership, occupancy, inventory and derived grants apply.

Canonical status authority owns the positive, source-bound Statue state outside
the curable negative-condition registry. Its damage gate runs before native
Dodge/Block, mitigation, Magic diversion, status observation and attribution.
Valid Statue takes no direct, ambient, AOE or damaging-status HP loss. Incoming
hits do not end it; existing ailments keep their clocks and recovery rolls.
Scripted death and campaign TIME OVER remain authoritative. Canonical Invisible
sources own enemy acquisition; the shared bounded pursuit cleanup now serves both
Statue and Veil. Damage factions are unchanged, and unrelated concealment survives
Statue cleanup. Human observers see the stone body.

Normal SetupMove samples the wait and FinishMove confirms actual position and
velocity before activation. Require deployed, living, walking Hero, ready graph,
no vehicle, moving/actor support, dash or forced displacement. Maximum sample gap
0.25s, maximum drift1 unit from the initial anchor, maximum velocity/base velocity
1 unit/s. Missing observations reset instead of crediting idle time. Movement,
jump/crouch, attack/use input, any Magic/technique/item-use attempt and effective
outgoing HP damage reset the full wait; looking around alone is permitted. Shared
input suppressors notify Statue before removing Held/weapon/Magic keys, so blocked
attempts cannot preserve invulnerability. Actual motion is rechecked at every
damage/acquisition decision, and safe teleport retires the state before moving.
No motion clamp, extra jump, wall traversal or per-item timer was added.

Wait and activation bind the exact item and hand slot, Hero state/identity/life,
run/seed/graph. Source mutation, same-tick remove/re-equip, death/respawn/disconnect,
role/staging/freeze/failure/level changes and map cleanup invalidate both. Expected
source tokens reject stale callbacks. Source-owned stone material restores its
prior value without overwriting an intervening external material change. Shared
Invisible maintenance also retires invalid protection without new recurring scans.
The HUD's existing beneficial-condition path shows STATUE. An original generated
0.24-second four-note cue and 0.3-second procedural stone flourish accompany the
bundled granite material. No third-party assets. Item descriptions and both manual
readers explain activation and breaks. `lod_tanuki_testkit` equips the ring,
preserves displaced inventory and marks the run unranked without refilling Magic.

Validation: **132 integrated suites pass, zero failures**; Lua syntax, generated
manual and whitespace gates pass. The focused suite exercises real equipment
ownership/rewards, exact two-second timing, free activation, real GM damage denial
before defense spending, an actual scheduled Immolated tick with unchanged HP,
Magic and ailment clock, canonical enemy target loss, input/physics breaks,
source-safe concealment/material cleanup and lifecycle rejection. Existing Ring,
Gloves, Hat, Boots, Quickstep, LuaJIT/crash replay, overhead barriers, rescue and
Hero/Soldier queues remain passing. Original audio is reproducible mono PCM,
bounded in duration/size and within the existing 6-bit cue transport. First
integrated run:131/132; only the audio test's fixed59-cue expectation failed after
the new60th cue. Updated that catalog expectation and retained all behavior checks.
Focused Statue/audio checks and the final integrated run pass. Final review then
moved technique cancellation after the existing session guard so a stale callback
cannot cancel a fresh Statue; the new assertion and all six equipment-move family
suites pass on that final tree. These results are
automated/headless evidence, not native Source acceptance.

Native gate pending: as a developer-mode admin on gm_flatgrass, run
`lod_tanuki_testkit`. Stop on solid ground for two seconds; verify stone appearance,
STATUE HUD, one brief chime/flourish, target loss and no HP/Magic loss from enemy
hits or ambient/AOE damage. Move or attack: protection must end immediately, with
a fresh two-second wait. Check forced push, moving support, ring removal, death,
dungeon transition and another player's view. Capture console_latest.txt and
rpg_summary_latest.txt. Check stone material restoration and co-op audiovisual
readability; the stock pickup representation remains provisional. No VPS or Steam
Workshop deployment; prior native acceptance obligations remain open.

Next bounded P7 checkpoint: **Wand weapon category**. Reconcile the retained
Wizard/Rogue/class restrictions, Beam delivery, finite charges/no reload and
procedural element/Content/status brief with live GDD and the existing weapon,
Magic, item identity and resource authorities before implementation. Define finite
ownership/class/resource/delivery/lifecycle checks; preserve accepted movement,
overhead barriers, rescue progression and Hero/Soldier queues. Do not re-audit
completed checkpoints without new contradictory evidence.

---

# Previous checkpoint — Boots of the Heavy Plumber

Built on verified remote `61f5577f3d7c1a19c2eb7797a6ed3cb2b5950920`.
Clean local main matched remote; no newer work was overwritten. Read AGENTS.md
and live GDD 00 → 01 → relevant 03/06/07/90. The Boots' exact author brief is
retained in `docs/SEPTEMBER22_MASTER_BRIEF.md`, including express authority for
missing design/balancing and GDD synchronization. Recorded and read back
`LOD-HEAVY-PLUMBER-001` in normalized 03/06/07/90 and HUMAN. This is an automatic
landing attack, not an added directional recipe.

Minimum-Rare feet-slot Boots grant **Heavy Stomp: 2d6 + STR physical contact damage,
no Magic cost, one attempt per airborne excursion, 0.65-second minimum interval**.
The independent 1/8 innate reward pool now includes Boots; original seven-family
RNG, frozen records and normal item economics remain intact. Innate allowance is
floor(50 x quality / 100). Definition grants and passive descriptions use the
existing equipment registry without permanent feat ownership or input listeners.

The ordinary SetupMove authority samples an armed Hero's movement; FinishMove
checks actual first-hit native swept-hull contact. Arming requires equipped Boots
and server-observed solid non-actor ground. Require downward speed at least120,
upward contact normal >=0.7, feet above the collision top before movement and
within3 units at contact. Samples expire after0.1s and reject displacement >128.
No target scan or per-item recurring timer. The bounce belongs to the same
excursion; actor standing, contact spam and midair item swaps cannot rearm it.

The canonical combat-roll module now exposes an innate physical-contact adapter,
using existing actor dice, STR/CON, class/gear modifiers, native Dodge/Block,
status observation, attribution, XP and combat feed. It does not cast Magic or
impersonate the held weapon. Native firearm hit feedback excludes that explicit
contact tag, avoiding an accidental gun-stun while holding a firearm. A committed
stomp reveals Veil. Muted and holding a throwable do not disable this physical
ability; voluntary movement denial does. No built-in element, Content rider,
extra stun or displacement of the victim was introduced.

Safe travel validates projected full-footprint generated support, exact cells,
normal/Warden/jail transitions, void/stair/hazard rejection and the standing hull's
upward clearance. Native overhead geometry bounds a nominal56-unit rebound with
4-unit margin and minimum8-unit clearance; launch speed uses actual server/player
gravity. Preserve horizontal momentum, ordinary Source gravity/collision and all
accepted movement/overhead barriers. No teleport, old jump-height clamp, extra
Dodge, invulnerability or fall-damage exemption. Unsafe bounce preflight consumes
that contact's latch but produces no stomp or bounce. A valid defended contact
still self-bounces once. Damage reactions revalidate the actor before rebound.

Exact source/feet slot, Hero identity/state/life and run/seed/graph bind arming to
landing through shared equipment and safe-travel authorities. Removal/replacement,
role/death/staging/freeze, forced displacement, teleport and stale commands cannot
revive an old descent. Only a fresh solid-ground observation rearms after
invalidation. Shared safe relocation explicitly retires the airborne record.
The shared impact cue, feedback feed, item text and both manual readers describe
the passive. `lod_heavy_plumber_testkit` equips Boots, preserves displaced gear
and marks the run unranked without changing Magic.

Validation: all **131 integrated suites pass, zero failures**. The focused suite
executes real item generation/grants, graph locks, source binding, contact resolver,
physical combat and rebound preflight with native trace/entity boundaries. It
covers ownership/value/rewards, no resource spending, actual top contact versus
side/upward/slow/covered/ally/dead contact, ceiling clipping, unsafe footprints,
locked-edge corner and swept crossings, one-per-flight/cooldown, held throwable,
Muted/Held, source mutation and stale identity/life/role/run/graph/teleport rejection.
Existing Hat, Ring, Gloves, Quickstep, LuaJIT/crash replay, overhead movement,
rescue and Hero/Soldier queues pass unchanged. The first integrated run passed
131/131. An added held-throwable focused case then exposed an incomplete native
weapon double (missing SetNW2String); reused the existing actor Give fixture and
reran it without weakening assertions. Final integrated run verifies the complete
tree; syntax and whitespace gates pass. These are automated/headless results,
not native Source acceptance. Movement-hook placement was checked against the
[official FinishMove documentation](https://wiki.facepunch.com/gmod/GM:FinishMove).

Native gate pending: as a developer-mode admin on gm_flatgrass, run
`lod_heavy_plumber_testkit`; touch solid ground, then drop onto a living enemy
from a ledge or suitable jump. Confirm one physical hit, unchanged Magic and a
short upward rebound; landing on an actor again must not repeat it before touching
solid non-actor ground. Check a low ceiling, an ally, side contact and removing
the Boots during descent. With another player, verify damage attribution and
bounce/impact readability; check death and dungeon transition cleanup. Capture
console_latest.txt and rpg_summary_latest.txt. Stock pickup remains provisional.
No VPS or Steam Workshop deployment; earlier native acceptance obligations remain.

Next bounded P7 checkpoint: Tanuki's Ring. Reconcile the retained two-second
stationary Statue/invulnerability brief with live GDD and canonical perception,
status/damage and movement/lifecycle authorities. Define finite activation,
movement-break, damage denial, acquisition, equipment removal and stale-state
checks before implementation. Preserve accepted movement/overhead barriers,
rescue progression and Hero/Soldier queues; do not repeat completed audits.

---

# Previous checkpoint — Hat of the Thunder God

Built on independently verified remote `c821113b33358460ea3b537f77e109dd18e0f089`.
The working tree was clean and remote main contained no newer work. Followed
live GDD 00 → 01 → relevant 03/06/07/90, with exact HUMAN hit-stun detail.
The retained September 22 master brief explicitly authors UP DOWN UP lightning
travel and delegates remaining design/balancing/GDD synchronization. Recorded
`LOD-THUNDER-HAT-001` in 03/06/07/90 and HUMAN, read back the contract in 07.

The minimum-Rare head-slot item grants **Thunder Charge: UP DOWN UP; 24 base
offensive Magic; six-second cooldown**. A quarter-second warning precedes up to
three blocks (1152 units) of straight movement at 1440 units/second, at most
0.8 seconds. Aim is frozen at activation. The existing dispatcher owns input,
grants, cost modifiers, one resource/cooldown commit and Veil reveal. Preflight
failure is free; a committed miss or cancellation does not refund Magic.

Extended canonical safe travel with continuous flat-floor support and full-hull
sweeps. Exact cells, generated-floor center/corner support, harmful/wet-space
rejection and the existing normal/Warden/jail traversal authority are checked
before every movement step. Probes are at most 16 units apart; runtime lookahead
is at most 32 units. A clipped activation needs at least 32 safe units. Standing
footprint checks remain conservative even when crouched. Stairs, voids, walls,
actors, closed locks and unsafe floors stop the charge. Source still owns gravity
and collision through the ordinary SetupMove dash seam; no SetPos, flight,
invulnerability, new Dodge or forced-motion exemption was added.

First opposing body contact deals one canonical 2d8 + WIS electric Magic packet,
including its normal Morale rider, regardless of procedural item affinity.
The shared Magic post-damage stun seam now accepts an authored form multiplier;
this move requests ordinary eligible hit-stun, including elemental weakness,
CHA, immunity and retrigger limits. It cannot stun on zero effective HP damage
or death. Existing wall stun remains unchanged. Allies stop travel unharmed.

Delayed attacks now bind the source's actual equipped slot as well as paired
occupancy. Thunder also binds Hero identity/life/state, run/seed/graph and safe
travel eligibility. Removal/re-equipping within one tick, source replacement,
role/death/respawn/staging/level change, freeze, forced movement, air travel,
Held/Muted or teleport ends the charge. Shared dash cancellation clears horizontal
charge momentum and replicated feedback; stale cancellation cannot stop a fresh
charge. Quickstep retains its accepted expiry and ordinary movement behavior.

The existing independent 1/8 innate reward pool adds the Hat; original seven-family
RNG draws and frozen records are unchanged. The quality-scaled 60-point innate
allowance uses normal value/sale/recreation. Stock pickup remains provisional.
A dedicated bounded visual packet draws a depth-tested blue warning path and
short trail, with sound and no extra entities, particles or dynamic lights.
Reduced effects retains the same two draw primitives. The canonical manual and
both readers include the Hat. `lod_thunder_hat_testkit` equips it, preserves the
displaced item, fills Magic and marks the run unranked.

Validation: all **130 integrated suites pass, zero failures**, including unchanged
crash replay/LuaJIT, movement/overhead barriers, safe travel, rescue progression,
Hero/Soldier queues, earlier combos, Ring, manual and release wiring. Focused
production checks cover generated ownership/economics, actual recipe/cost/cooldown,
warning/frozen direction/range, native and graph barriers, support/hazards,
electric damage, eligible/immune/retrigger/defended/lethal stun, ally exclusion,
source/lifecycle rejection, stale cancellation and client packet/draw budgets.
The first focused run exposed a cyclic charge/combat context during shared damage
copying; removed the back-reference before commit and reran successfully. Initial
integrated run passed 130/130; final integrated run verifies the complete tree.
Lua syntax and whitespace gates pass. These are automated/headless results;
native Source acceptance remains pending.

Native gate: on gm_flatgrass, developer-mode admin runs `lod_thunder_hat_testkit`,
then UP DOWN UP on a flat corridor. Confirm one 24-base-Magic spend, warning,
straight travel and six-second cooldown; then charge at a wall/closed gate, an
enemy and an ally. Check one electric hit with eligible stun, no ally damage,
no unsafe-floor/locked-edge traversal and cancellation when removing the Hat,
dying or changing dungeon. Another player verifies warning/audio/trail readability.
Capture console_latest.txt and rpg_summary_latest.txt; screenshots only for visual
defects. No VPS or Steam Workshop deployment; prior native obligations remain.

Next bounded P7 checkpoint: Boots of the Heavy Plumber. Reconcile the retained
stomp/bounce brief with live GDD and shared landing/contact/damage/safe movement
before choosing delegated tuning. Finite gate: equipped source, valid downward
contact, one damage event, safe bounded bounce, spam prevention and stale lifecycle
rejection. Preserve accepted movement/overhead barriers, rescue and Hero/Soldier
queues. Do not restart prior completed audits.

---

# Previous checkpoint — Ring of Invisibility

Built on verified remote `5d3f837223f433f8b07705cfc4c9dd832e553c8d`.
Fresh main checkout; no newer remote work was present. The recovered local Gloves
commit was not reapplied. Read AGENTS.md, the checkpoint and live GDD 00 → 01 →
relevant 03/06/07/90 rules, then exact Invisible/HUMAN fallback. The live GDD had
no ring contract. `docs/SEPTEMBER22_MASTER_BRIEF.md` explicitly delegates the
ring's break/end conditions and P7 design/balancing/GDD synchronization. Exercised
that delegation in `LOD-INVISIBILITY-RING-001`, written and read back in 03/06/07/90
and HUMAN. No unrelated design rules were changed.

Ring of Invisibility is a minimum-Rare procedural single-hand item granting
**Veil: LEFT UP LEFT; fixed 20 Magic; maximum 12 seconds; 20-second cooldown**.
Its quality-scaled 50-point innate allowance participates in ordinary item value,
sale and recreation. The independent 1/8 innate reward pool now contains Crown,
Gloves and Ring; the original seven-family stream and frozen records are intact.
Two rings expose one recipe; paired gloves displace rings under normal occupancy.
The shared dispatcher validates grants, status, resources and preflight before
committing once. Active Veil cannot refresh or spend again.

Canonical perception now supports individually owned invisibility sources,
composing with its existing permanent/timed state. Veil binds source record/slot,
Hero state/identity/life, run, level seed and graph. Removal/moving/replacement,
death/disconnect/respawn/role/staging/level transition, failure/freeze or expiry
ends that source only; stale callbacks cannot clear a newer activation. Existing
perception maintenance owns expiry, with no new per-item recurring timer.

AI acquisition and directed attack adapters consult canonical Invisible, including
wanderer retention, Watcher scans, Soldier windups, roster/Climber, Brute and
Warden paths. Activation drops existing target/pursuit knowledge. Faction/damage
eligibility stays distinct: released shots, committed area hazards and manually
aimed human Soldiers can still hurt the Hero. Warden homing loses the concealed
target without deleting the projectile. Sixth Sense retains its authorized halo
pass. Client body/held-weapon concealment reads the replicated deadline.

Attack input (including dry/blocked attempts), Magic on any bound button, offensive
item techniques, throw attempts and effective incoming/outgoing HP damage reveal.
Movement, reloading, menu access and drinking alone do not reveal. Ending neither
refunds Magic nor resets cooldown. Activation/end feedback uses the shared RPG
feed; the canonical manual and both readers document the item.

Validation: all **129 integrated suites pass, zero failures**, including unchanged
exact crash replay, LuaJIT, movement/overhead barriers, rescue, Hero/Soldier queue,
Feather, safe travel, earlier combos, manual and release wiring. Focused production
checks cover ownership, ordinary generated rewards/value, one-hand grants, cost,
status denial, actual recipes, target-versus-damage membership, reveal/expiry,
source composition, item/identity/life/role/run/graph rejection and stale cleanup.
Extended existing sniper and render/input checks cover windup cancellation, body
concealment, Sixth Sense halo permission and held-gun draw suppression. Initial
integrated run passed 121/129: eight dependent fixtures lacked the new faction
acquisition method. Their common fixture now loads the production faction module
while retaining its existing actor-membership double; no acceptance assertions
were relaxed. Lua syntax and whitespace gates pass. These are automated/headless
checks, not native Source acceptance.

Native gate pending: on gm_flatgrass as a developer-mode admin, run
`lod_invisibility_testkit`, then LEFT UP LEFT. It equips one ring, fills Magic,
preserves displaced items and marks the run unranked. Confirm exactly 20 spent,
loss of directed AI pursuit, 12-second expiry and 20-second cooldown; attack,
remove the ring and take a released shot/hazard to check reveal. With another
player, inspect body/held-gun disappearance/restoration, Sixth Sense and manually
aimed human-Soldier damage. Check death/respawn and dungeon transition cleanup.
Capture console_latest.txt and rpg_summary_latest.txt; screenshots only for
appearance defects. Stock pickup model remains provisional.

Next bounded P7 checkpoint: Hat of the Thunder God. Reconcile its retained
UP DOWN UP lightning-charge brief with live GDD, shared movement/collision,
electrical damage/status and safe-travel authorities before choosing delegated
values. Finite gate: equipped source, single resource commit, wall/gate/floor-safe
path, enemy/ally hit handling and stale lifecycle rejection. Preserve accepted
movement and overhead barriers, rescue progression and Hero/Soldier queue behavior.
Earlier native acceptance obligations remain open. No VPS or Workshop deployment.

---

# Previous checkpoint — Gloves of the Fighting Streets

Built on verified remote `1a7d351b33bde23c3c792623dcb5e33b8c85f0b1`.
No newer remote work was present. Read AGENTS.md, the current checkpoint and
live GDD 00/01, relevant 03/06/07/90 rules. The live GDD lacked the named glove
contract; the retained September 22 master brief explicitly supplies both recipes
and delegates balancing/design decisions and GDD synchronization. Added and read
back `LOD-FIGHTING-STREETS-001` in 03/07/90, with the same contract appended to
HUMAN. No repetition of the completed Feather audit was required.

The minimum-Rare v2 paired gloves occupy both hands once, with doubled ordinary
glove affix opportunity plus a quality-scaled 80-point innate allowance. Existing
frozen items and the original seven-family generation stream remain unchanged;
the independent 1/8 innate reward pool now selects Crown or Gloves. Inventory,
affinity, naming, value, sale and recreation use the existing item authorities.

- Ember Fist: LEFT DOWN RIGHT; 12 base Magic; two-second cooldown; one straight
  1200-unit/second projectile, maximum 1920 units and 1.6 seconds. Direct hit
  deals 2d6 plus canonical WIS Magic with the gloves' sealed affinity and its
  existing Content rider. No splash or piercing. The native swept hull starts
  at the shoot origin; blocked placement or failed entity creation spends nothing.
- Cinder Rise: RIGHT DOWN RIGHT; 18 base Magic; four-second cooldown; current
  graph square with line of effect. Deals 2d8 plus canonical WIS Magic using
  the gloves' affinity, then canonical Immolated on a surviving damaged target
  subject to its ordinary save. Rising elemental presentation does not relocate
  the Hero. A successfully committed empty shot/area spends Magic.

Both use the existing combo dispatcher, offensive cost modifiers (no Content
surcharge), shared damage/dice/equipment/defense/status/feed authorities and
bounded work. No new Spellbook Form, input listener or permanent feat. Rebuff
shares Ember Fist's recipe but requires a ring displaced by the paired gloves;
only currently equipped grants compete. Delayed impacts reject changed Hero,
life, run, level, graph, source record, equipped occupancy or active role, and
expire without refund. Only one technique projectile per caster can be active.
The canonical manual and both generated readers now explain both techniques.

Validation: production-path tests cover generated rarity/value/paired slots,
natural reward families, descriptions, actual combo recognition, projectile
Initialize/Think/impact, blocked/failed launch, no-splash misses, cooldown and
Magic commit, shared elemental damage and Immolated save/application, cover and
local-square exclusion, source/life/role/run/graph/expiry rejection, and the
Rebuff collision. Initial fixture runs exposed missing entity/faction doubles
and an incorrect test assumption that Held prevents stationary casting; the
fixture now follows the existing shared rule. A ring-swap fixture also exposed
that the runtime testkit needed explicit occupied-slot acceptance; displaced
items remain in the bag. No production rule was changed to satisfy these tests.
All 128 integrated suites pass with zero failures, including unchanged exact
crash replay, LuaJIT, movement/overhead barriers, Feather/queue, safe travel,
Crown/Quickstep/Rebuff, manual and release-wiring regressions. Lua syntax and git
whitespace checks pass. Automated checks are not native Source acceptance.

Native gate remains pending: on gm_flatgrass as a developer-mode admin, run
`lod_fighting_streets_testkit`. It equips one generated pair, fills Magic and
marks the run unranked; displaced rings remain owned. Use both displayed recipes
against an exposed enemy, then cover/adjacent-square exclusions. Check Magic,
shared damage/save feedback, two-hand occupancy and cancellation after stowing.
With another player, confirm ally exclusion and shared projectile/strike visuals.
Capture console_latest.txt and rpg_summary_latest.txt; add screenshots only for
appearance defects. The pickup uses the existing stock equipment-box placeholder.

Next bounded P7 checkpoint: Ring of Invisibility through the shared equipment
combo and canonical Invisible/target-acquisition authorities. Reconcile live
GDD break/end rules and missing delegated tuning before implementing. Then
remaining P7 items precede events/minigames and Hector/finale. Preserve all
accepted movement, overhead barriers, rescue and queue behavior. Feather,
Crown, responsive-sheet and safe-travel native acceptance remain pending.
No VPS or Workshop deployment performed.

---

# Previous checkpoint — Feather of Resurrection and canonical revival

Built on verified remote `8e132f9fb0a0228e271c9e4d8ec29b444432b3d7`.
Recovered that published tree in a fresh main checkout; no surviving unpushed
Feather implementation was found. Live GDD 00/01 then relevant 06/07/90 rules
were read. Existing `LOD-RESURRECTION-FEATHER-001` in 06/07 already specifies
the behavior and tuning from the interrupted session; no GDD changes were needed.

Feather of Resurrection occupies the canonical finite Throwable slot, stacks to
three and uses either mouse button. The existing oldest-eligible elimination
timestamp/ordinal selector excludes Soldier control, Soldier respawn waits and
ordinary positive-life respawns. `RunManager:ReviveIdentity` validates eligibility
before invoking an optional synchronous debit, then restores exactly one life.
No eligible target, invalid owner, inactive item, timeout or failed debit spends
anything. Success spends one Feather, no Magic, and applies the 0.6-second cooldown.
Queue return preserves the original elimination timestamp. Full Hero slots defer
admission; reconnect does not grant another life. Identity, progression and surviving
inventory remain unchanged; this does not create gear, wallet value or claims.

The shared deferred revival callback now spawns an alive former-Soldier spectator
through normal Hero spawning, and rejects changed run, graph, level, identity,
body serial, death, Soldier state or disconnected player. Summon Card drops keep
their original independent draw. Feather draws 1/8 of eligible potion opportunities
that did not select a Card, using resurrection-feather-v1 (7/64 overall). Other
conversion/affix streams and authored non-eligible rewards remain unchanged.
The pale newspaper charm is a stock-model placeholder pending native appearance
acceptance. The canonical manual source and both readers document Cards/Feathers.

Targeted production checks pass queue ordering, both controls, debit failure,
empty queue, Soldier exclusion/return, slot/reconnect handling, stale callbacks,
inventory references, cooldown/no-Magic spending, stack exhaustion and seeded
natural rewards. Initial fixture execution lacked the Source CreateConVar boundary;
that double was supplied. The first integrated run passed 126/127: the old final
drop-mix test required a healing share predating Feathers. Its category thresholds
now account for the 49/64 remaining ordinary pool and explicitly require natural
Cards and Feathers, retaining the native reward-creation failure checks.
Final integrated regression: all 127 suites pass with zero failures, including
unchanged recorded crash replay, LuaJIT, Hero/Soldier lifecycle, safe travel,
manual synchronization and release-wiring gates. Changed Lua syntax and git
whitespace checks pass. These are headless/static checks, not Source acceptance.

Native multiplayer/appearance acceptance remains pending. On gm_flatgrass, as a
developer-mode admin, run `lod_feather_testkit` with an eliminated teammate in the
Hero Queue. Use either mouse button: one Feather spent, one restored life and a
normal Hero body. Repeat with no eligible teammate, then with Soldier control and
return to the queue; only the eligible queue use succeeds. The testkit marks the
run unranked. Capture console_latest.txt and rpg_summary_latest.txt; screenshots
are only needed for appearance defects. No VPS or Workshop deployment performed.

Next bounded P7 checkpoint: Gloves of the Fighting Streets through the existing
equipment-combo and shared combat authorities. Reconcile its live-GDD attack and
cost rules first; the finite gate is both authored recipes with equipped ownership,
resource commit, authoritative hit/status handling and lifecycle rejection. Remaining
P7 items precede event/minigame and Hector/finale work. Preserve the accepted movement,
overhead barriers, rescue progression and queue semantics; native Crown, responsive
Character Sheet and safe-travel acceptance remain pending.

---

# Previous checkpoint — safe Hero relocation and Summon Card

Built on verified remote `5bbc6088eaafb9f6d8314dee3fe349b20fb441ea`.
`LOD.SafeTeleport` now owns exact graph-cell membership, unlocked-route checks,
standing-hull clearance and generated-floor support for Hero relocation. It calls
the live navigator, retaining progression, Warden and jail locks. Destination
checks reject voids, stair-transition cells, unsupported footprint corners,
occupied hulls, water/slime and damage triggers. It revalidates both Heroes and
the landing at commit, then clears carried velocity and dash/forced-motion state.
Existing normal movement, spawn/deployment and Magic summons are unchanged.

Summon Card uses the canonical finite throwable inventory, held adapter and
LMB/RMB controls. LMB selects another deployed Hero for an adjacent safe square;
RMB selects one for the current square or nearest safe equivalent. The server
owns the target list and position. A one-shot 15-second selection binds owner,
target, identity state, life, run, level, graph and held record. Failures/cancel
spend nothing; success consumes one card and no Magic. Stack cap is three and
the ordinary 0.6-second cooldown applies. New eligible potion opportunities use
an independent 1/8 card draw; existing conversion/affix streams and authored
non-eligible rewards remain intact. The stock clipboard provides the visual.

Live GDD navigation used 00/01, relevant 05/06/07 and deferred item rules in 90,
reconciled with the superseding September 22 master brief. New rule
`LOD-SAFE-TRAVEL-001` is written and read back in tabs 06 and 07, including the
candidate search, collision tolerances, lifetime, stack, cooldown and drop tuning.

`tools/test_summon_card.lua` exercises production navigation including the real
Warden/jail wrapper, hull/support/hazard failures, oversized Heroes, stale life,
level, graph, identity, inventory and control state; net bounds/replay; precise
spending, cooldown, velocity reset, no Magic cost, deterministic natural rewards
and atomic stack overflow. The actual client picker is checked at small/large
viewport boundaries, with intact names, target/nonce requests, cancellation,
expiry and page/death close. Initial tests caught a missing Source boundary
double and an item slot registration error; both were corrected. Headless checks
are not native Source collision or visual acceptance.

Validation: targeted server and picker checks pass. All 126 integrated suites
pass with zero failures, including unchanged crash-replay, JIT, movement,
progression, queue, inventory and release-wiring regressions.
Native acceptance remains pending: on `gm_flatgrass`, with two deployed Heroes,
run `lod_summon_card_testkit` as a developer-mode admin, then use LMB/RMB and
check occupied landing fallback, closed gates and stale/dead target cancellation.
The command marks the run unranked. Capture `console_latest.txt` and
`rpg_summary_latest.txt`; add a screenshot only for picker/visual defects.

Next bounded P7 checkpoint: Feather of Resurrection through canonical Hero
Queue/life admission, with exactly one restored life and atomic consumption;
then remaining P7 items before event/minigame and Hector/finale work. Preserve
movement, overhead barriers, rescue progression and queue semantics. Native
responsive-sheet and Crown acceptance is still pending. No deployment performed.

---

# Current checkpoint — recovered equipment and responsive feat selection

Recovery published as `62141883fa4b888c6e29a47812d06de3c6cdda4f`, directly
on top of `af10212ebdce87bc7f5ddda31bb1e16e823c2f77`. The surviving local
`4ea6edb095d7337240e984c552b4192d5fd91177` was clean and retained; its exact
file tree (`c356fd7c3e3072eebec3b8e46fbce26ebb1c1836`) was published through
the GitHub connector because command-line Git had no write credentials. No
reconstruction, reset or discard was needed. All 124 recovered integrated suites
passed again, including targeted Crown/combo, Quickstep/Rebuff and unchanged
recorded crash-replay checks. The full September 22 main chain is preserved.

The next bounded checkpoint repairs the Character Sheet selection surface.
Ordinary feats and capstones now share one responsive renderer: one to three
columns with a 280-pixel preferred minimum card width, 12-pixel gaps and measured
row heights. Full names, eligibility and canonical descriptions remain intact.
Short Choose Feat / Choose Capstone buttons retain full-name tooltips and the
original feat ID/earned-level request contracts. Resolved and read-only cards
remain inert. Owned-feat text still comes from the canonical server snapshot.

Below 900 pixels of body width the main sheet columns stack, preventing narrow
identity and draft panels. Section headings wrap and contribute their actual
height. The header uses its short title when measured text would clip.
Screen-size changes rebuild the existing snapshot without requesting a
new hand. Same-identity snapshot refreshes retain the scroll position; a new
identity starts at the top, and stale layout callbacks cannot affect newer frames.
No gameplay, eligibility, draft RNG, feat text or server choice behavior changed.

Live GDD navigation: 00, 01, then relevant rules in 03/04/06/07; recovery matches
LOD-EQUIPMENT-COMBO-001, and presentation retains LOD-FEAT-CARDS-001 and the
LOD-UI shared-menu rules. No design-law correction or manual rewrite is needed.
The existing edited manual and feat catalog remain unchanged.

New production-path coverage builds real Hero snapshots and verifies ordinary,
owned and capstone descriptions against their registered authorities. It opens
the actual Character Sheet for all 150 registered descriptions (135 ordinary,
9 capstones, 6 fallbacks) at 640x480, 800x600, 980x720, 1024x768, 1280x800 and
1920x1080; checks card/section bounds, nonoverlap and intact text; exercises exact
choice messages, resolved/read-only states, refresh/resize and identity changes.
An initial test selector confused identically named ordinary-test and capstone
cards; it now selects the actual draft by its action control. Assertions remain
intact. All 125 integrated suites pass with zero failures: the recovered 124
plus the new Character Sheet suite. The final header-fit refinement also passes
the targeted six-resolution suite after the integrated run.

Native GMod font metrics, visual scrolling/selection and multiplayer acceptance
remain pending; the headless VGUI boundary is not native rendering evidence.
Next tranche: canonical safe-cell / safe-teleport resolution and its blocker,
occupied-hull and level/life-change gates, then Summon Card and remaining P7
items. Event/minigame dependencies and Hector/finale follow that equipment work.
Keep full movement, overhead barriers, rescue progression and queue semantics.
Shadow flicker remains unreproduced/nonblocking. No VPS or Workshop deployment.

---

# Current checkpoint — shared combo abilities and Psychic Crown

Built on verified remote `af10212ebdce87bc7f5ddda31bb1e16e823c2f77`.
The existing keyboard/mirror listener and three-bit transport feed one server
ability dispatcher. Only equipped grants compete; bounded suffix matching supports
up to eight tokens, selects the longest completed recipe then registry order,
and attempts just one move. Timeout, reset, capability changes, Hero/life/run/level
changes invalidate input. Resource/cooldown commit follows successful preflight.
Quickstep/Rebuff retain their original handlers, restrictions and costs.

Crown of Psychic Crushing is an innate head item, minimum Rare, with a quality-scaled
50-point innate value plus ordinary procedural affix value. DOWN UP DOWN costs
18 Magic with four-second cooldown; the nearest visible hostile within two graph
edges receives 2d8 plus canonical WIS Magic and a shared WIS save for half. Graph
locks, cover, shared equipment/class/element/damage/defense and attribution stay
canonical. No valid target spends nothing. The feed names target and save/DC;
a brief impact marks the selected target. No permanent feat mutation.

New world wearable rewards choose the current innate pool at 1/8 probability using
an independent named seed stream. The original seven-family generator stream and
frozen generic economics remain exact. Innate items require v2 validation. The
first full run passed 122/124: extending the original random-family list broke the
recorded crash corpus and JIT compatibility replay. Corrected production reward
selection; both old fixtures pass unchanged. An initial implementation typo in the
innate value helper caused recursion and was fixed before integration. New fixture
runs initially lacked Source game/net boundaries; corrected those doubles.

Targeted production checks pass 300 generated Crowns, natural reward admission,
price/rarity, effective ownership, shared WIS damage/save feedback, actual graph
locks/cover, no-target/no-Magic/Muting/cooldown rejection, stale life sessions,
unowned recipe collisions and four-token suffixes. Quickstep/Rebuff and the real
client input adapter pass. Live GDD 03/06/07 records LOD-EQUIPMENT-COMBO-001;
manual source and readers rebuilt. Final full regression: all 124 registered suites
pass with zero failures.
Native multiplayer targeting, visual/sound and combat acceptance remain pending.

Next: author-prioritized Character Sheet feat selection readability and snapshot
coverage, then shared safe travel before Summon Card; remaining P7 wearables/consumables,
then events/minigames and finale. Shadow flicker remains unreproduced/nonblocking.
Full-strength movement and invisible overhead collision remain regression constraints.
No VPS deployment or Workshop publication.

---

# Current checkpoint — readable, less oppressive monster defenses

Built on verified remote `e004e9a1999da5f895281a7e24f0027a4b46a503`, preserving
full-strength Cloud Step and invisible overhead walls. Enemy-side AI and possessed
Soldiers use the same canonical derived/damage/status systems with CON reduction
capped at 1 per die, Arcane Diversion capped at 30% without whole-HP rounding,
and Feedback capped at 15% with a two-second cooldown. Hero rules remain intact.

Enemy shield breaks receive +4 DC and last 1.5 times their rolled duration, at
least 24 seconds. A break or defeat cancels deferred Feedback from the same hit.
Attacker-facing feed messages identify Constitution, Arcane Shield, Feedback,
failed/successful breaks, True Faith and Mind Over Matter, with a relevant tactic.
Existing semantic feedback families and 1.5-second per-reason throttles avoid spam;
a shield-break success has its own key so an earlier resistance message cannot hide it.
Other immunity, Dodge/Block, element, equipment, save and Hero feat rules remain.

Targeted production checks cover AI/Soldier parity, unchanged Hero caps/rounding,
small-hit leakage, Magic affordability, Poison, 24/45-second break windows, attacker
messages, same-hit break/death cancellation and the actual Mind Over Matter recovery.
The first Fighter regression failed its old enemy-CON expectations; those explicit
enemy results now reflect the authorized cap while its Hero/pure arithmetic matrix
is retained. A new fixture's nonexistent status Get accessor was corrected to the
production Has return contract. The first full run passed 122/123: an obsolete
source-text assertion expected one universal Arcane clamp. It now recognizes the
role-specific clamp, and the existing runtime validator covers both roles.
Its standalone fixture now loads real shared tuning rather than an incomplete
RPG table; the targeted Checkpoint C runtime and source validators pass.
Final full regression: all 123 registered suites pass with zero failures.
Live GDD 02/03/07 and the rebuilt manual record LOD-ENEMY-DEFENSE-001.
Native multiplayer damage feel and feedback readability remain pending.

Next: Priority 7 shared equipment/input-combo/safe-travel systems, then event and
minigame dependencies before the finale. Shadow flicker remains unreproduced and
nonblocking. No VPS deployment or Workshop publication.

---

# Current checkpoint — free Cloud Step movement and invisible overhead walls

Built on verified remote `d2faa8497732468e8c5167d29a72cfe54713d04d`.
The author's later direction replaces the unpushed apex-clamp prototype: preserve
full expressive movement and contain the maze using invisible walls above crates.
Cloud Step costs 3 Magic, targets twice the former vertical takeoff impulse and
adds a normalized 120-unit boost in the held direction while preserving horizontal
momentum. Spring Heel and subsequent Wall Jumps retain full strength at any altitude.
The ordinary locomotion cap remains separate. Wall Jump priority, once-per-airborne
state, shared capabilities, movement restrictions and Meteor Strike remain intact.
An original 130 ms cue and eight-sprite 0.35-second cloud ring identify success.

Existing invisible merged wall boxes extend through overhead void to world Z 16384.
Lower columns stop beneath legal upper-floor crossings and the gallery overlook;
merge keys include top height. Closed gates and the jail door extend their own
collision upward; opening clears the entire column. Visual sizes remain authored,
with no additional VPhysics, per-frame traces, lights or recurring timers.

The earlier clamp prototype passed 121 suites but was superseded before any main
push. The revised production checks preserve full jump combinations and verify
walls at five vault heights, 4,759 legal crossings and 38 stairs over eight generated
seeds, split-height merging, gallery openings, and complete gate/jail opening.
An initial gallery fixture incorrectly retained a Cell inside WardenVoid; corrected
to match the real arena topology. Peak wall count in those seeds: 616 merged boxes.
Full revised regression: all 122 registered suites pass with zero failures. Manual/catalog/readers rebuilt.
Live GDD 04/05/07 records LOD-CLOUD-STEP-003 and LOD-WORLD-OVERHEAD-001.
Native collision, traversal and audiovisual acceptance remain pending.

Next: monster defense readability/rebalancing, then shared equipment/input/travel
before event/minigame and finale dependencies. Shadow flicker is unreproduced and
nonblocking. No VPS deployment or Workshop publication.

---

# Current checkpoint — full-trajectory Magnum and Beam

Built on verified remote `4520bedf744b5bf72f027d1ab9a7be71f6062593`.
Both attacks now continue beyond the previous eight/four target limits through
living opponents, corpses and friendly combat bodies to their fixed range/world
endpoint. The first Magnum impact is captured before an earlier callback can
kill/remove it. Shared factions still govern damage; each actor is hit at most
once. Generated-geometry obstruction, cumulative Magnum Boomchains, Aim scaling
and the shared attack-event dice budget remain intact.

The shared 128-target safeguard exceeds supported simultaneous actors, with a
512-iteration guard for malformed traces. Magnum range no longer extends after
each body. The manual already describes the full-line behavior; live GDD 03/07
records the correction and authorized safeguards as LOD-PIERCING-002.

Validation: production trajectory tests pass fourteen bodies, lethal first
callback, dead intermediate body, fixed range, wall stop and repeated-entity
guard. All 121 registered integrated suites pass with zero failures. Native aligned
multiplayer actors and generated-wall acceptance remain pending.

Next: Cloud Step and monster defense readability/rebalancing, then the shared
equipment/input/travel systems. Shadow flicker remains unreproduced/nonblocking.
No deployment or Workshop publication.

---

# Current checkpoint — Gordon/Neil feedback and Fake Gordon Clones

Built on verified remote `eccb286d4a7341c0b044d1dd2d79be0d74888192`.
Gordon's first phase reveals a two-second taunt after twelve damage-free seconds
while cloaked, with a sixteen-second repeat gate and interruption on damage.
An original bounded square-wave laugh and procedural arm/torso pose identify it.
Neil receives a 0.4-second recoil pose on actual damage. Death clears these poses.

The actual procedural Crowbar tags its shared stagger request as melee. Gordon and
clones accept melee stagger once every three seconds; damage and firearm stun
remain intact. All three installed stun wrappers now forward the form multiplier
and source kind, preserving Wall's intended stun as well as the new melee gate.

Dungeon Levels 4/8/12/16 add 1/2/3/4 Fake Gordon Clones, capped at four. Each uses
the existing actor/phase/damage/navigation authorities at floor(real MaxHP / 3),
minimum 1. Legal distinct court cells, individual route seeds, separation scoring
and target offsets distribute the actors. Pending spawn reservations persist;
creation is idempotent and dead clones are not replenished. Main and clones share
sixteen hazards with unique IDs. Only the real boss owns the HUD and Jail Key;
clone death retires its ordnance, and real-boss death retires all clone attacks.
Two client props are reused for all actors, including differing clone phases.

Validation: all 121 integrated suites pass with zero failures. Expanded production
boss tests additionally pass clone thresholds, exact HP and legal spawn cells,
independent phase execution, shared caps/IDs, separate Hero targeting, pending
reservations, death/HUD isolation, taunt interruption and the installed stun wrapper
chain. Ordered real-boss health, Neil/Brute, Wall and audio regressions also pass.
Manual source/readers rebuilt; live GDD 03/07 records LOD-GORDON-EXPANSION-001.
Native multiplayer boss, animation and sound acceptance remains pending.

Next: Priority 6 Cloud Step, guaranteed full-trajectory Magnum/Beam piercing and
monster defense readability/rebalancing, then shared equipment/input/travel systems
before the event and finale framework. No public deployment or Workshop publication.

---

# Current checkpoint — enemy death pulse and defeat cue

Built on GitHub main `efb2a4c2ef68f5b142c42ebece6d041c56de2410`.
Dead hostile bodies smoothly interpolate normal → red silhouette → normal → red
through their existing one-second presentation. A single replicated timestamp
replaces repeated server hide/show updates. Cloaked Gordon corpses become visible.
The shared scheduler, deferred native mutations, one-time loot handoff and level-seed
isolation are preserved. The 60 ms original defeat cue is coalesced per listener
with a 120 ms cooldown; it never overlaps itself during simultaneous kills.

Validation: production death handoff/batching and interpolation bounds, audio
lifecycle/coalescing, deterministic audio assets, monster identity and changed-file
Lua syntax checks pass. This follows the complete 121-suite pass on the parent UI
checkpoint. Native silhouette appearance and audible mix remain unobserved.
Live GDD 03/07 records the presentation and tuning under LOD-DEATH-PULSE-001.

Next: finish Priority 5 Gordon/Neil feedback, melee stagger protection and clones;
then Priority 6 Cloud Step, full-trajectory piercing and monster defenses.
The staging shadow remains unreproduced/nonblocking. No deployment is included.

---

# Current checkpoint — Debbie review and feat card text

Built on verified GitHub main `5d0d0f5f51636d8267de5ad2f7565338519462c8`.
The recovery and navigation checkpoints remain intact. The author cannot currently
reproduce the staging shadow flicker; it is unreproduced and nonblocking. Existing
DFT rollback/award, black-gate, audio-owner cleanup and damsel roster checks remain
regression constraints; this pass found no contradictory evidence requiring a rewrite.

Debbie now displays item statistics and displaced equipped-item comparisons inside
exchange cards. Source/pile targets, numbered review steps, pending state, explicit
sale/fusion consequences and a local CLEAR PILE action clarify the transaction.
Pending exchanges cannot be cleared or confirmed twice. Sell All visually protects
equipped rows as well as enforcing the existing authoritative transaction rules.

All 135 ordinary feats, nine capstones and six fallback feats have edited card text.
One presentation module populates the existing catalog descriptions after registration;
character sheet, offers and manual keep their existing shared consumers. Ranked values
come from mechanical parameters. A comparison against the previous catalog confirms
all 150 descriptions changed and every other catalog field stayed identical. Manual
source, HTML and distributed client chunks were rebuilt.

Live GDD 00 → 01 → 04/06 governs this checkpoint. LOD-FEAT-CARDS-001 and
LOD-DEBBIE-READABILITY-001 record the authorized presentation revisions. The first
complete run passed 120/121 suites: the release audit's verbatim Spatial Awareness
expectation rejected the edited text. The fixture retains the old authored row and
records an explicit presentation override; the targeted release audit then passed.
Final complete regression: all 121 registered suites pass with zero failures.

Next: Priority 5 enemy-death feedback and Gordon/Neil boss polish, then Cloud Step,
full-trajectory piercing and enemy-defense readability before dependent equipment and
events. Native GMod visual/multiplayer acceptance remains pending. No VPS deployment
or Workshop publication is authorized by this checkpoint.

---

# Current checkpoint — committed stair travel and Climber placement

Developed from verified remote main `2ea2c4a3c0ca13df24f9a2563a1551c7e8d17c6f`,
which durably contains the September 22 recovery checkpoint above `4942c43`.
The recovery tree passed all 120 registered suites with zero failures.

Summons now complete the authored stair flight before periodic replanning,
charging or retreat can replace it. Climbers retain unfinished wall routes,
retry blocked routes after 0.8 seconds, and spawn directly in a validated wall
lane preserved by shared spawn settlement. Local humanoid pursuit reserves the
actual container half-width plus hull clearance instead of entering the wall.
The canonical maze graph and movement authority remain in use.

Validation: all 121 integrated suites pass with zero failures. The new navigation
suite executes the production waypoint compiler, motion kernel and summon route
refresh across four stair orientations in both directions. It checks monotonic
route progress, completion, landing elevation, charge exclusion, container hull
clearance and Climber spawn settlement. Roster tests verify wall-route retention.
Live GDD 00 → 01 → 05/07; tab 07 records LOD-NAV-20260922.
Native GMod stair/collision/render acceptance remains pending; static tests are
not a claim of observed multiplayer behavior.

Next: complete the remaining Priority 2 audit (DFT announcements/persistence,
black-gate collision, ambient-owner cleanup, staging flickering shadow and unique
damsel services), then Priority 4 UI/feat wording and subsequent combat/content
work in SEPTEMBER22_MASTER_BRIEF.md. Existing tests cover DFT rollback, gate
routing, loop leases, ordinary pistol/crowbar loot and the damsel roster; do not
rewrite those systems absent contradictory evidence. The native staging shadow
cause is not yet established. Later combat, items, events and Hector remain open.
No public-server deployment or Workshop publication is included.

---

# Current checkpoint — progression, sales and live rankings

Second checkpoint in the active ten-priority brief: doubled Hero XP thresholds,
stronger bounded INT/DEX curves, three-dungeon monster scaling, a 520-unit ordinary
movement cap, atomic Sell All Unequipped, persisted/live Stakeholders and live
Heroes of Legend. Procedural look-at identity and same-floor Hero map markers
improve multiplayer readability. Open gates reassert collision removal; rolling
summons use travel-driven rotation and model ground offset; damsel materials retain
source shading and the stray blue brooch sphere is removed. DFT collection reports
success only after storage accepts the token.

GDD 00 → 01 → 02/06/07 and HUMAN amendment LOD-PROGRESSION-002 govern these changes.
Existing earned Hero levels survive the XP threshold change. Ordinary movement
bonuses combine before the safety cap; special movement remains independently
validated. Bulk sale rejects the complete transaction if a reviewed item becomes
equipped; DFT-created and protected gear remain excluded.

Validation: targeted Lua movement, actor progression/Warden HP, wallet UI,
look-at UI, minimap, snapshot, protected regressions and real SQLite economy
checks pass. SQLite tests cover twelve-item sale, newly equipped selection,
DFT exclusion, rollback, exact payout and replay. Leaderboard tests cover live
participants, immutable completed storage and completion without duplication.
Recovery validation: all 120 registered suites passed together with zero failures.
Additional production-path regressions prove worn Bloodletting and regeneration
on a featless non-Fighter, removal on unequip, and all-or-nothing rejection when
inventory changes inside the sale transaction (equipped/protected/removed). Native GMod
multiplayer, lighting, stairs, summon rotation and 4K visual acceptance are pending.

Shared item capabilities are verified through the existing Equipment.Contributions,
derived-state, attack-snapshot and status/regeneration pathways; no parallel feat
system was added. Recovery preserves local commit c9d96c6 above remote 4942c43.
The complete author brief is preserved in SEPTEMBER22_MASTER_BRIEF.md.

Next: finish Priority 2 navigation/stairs/Climber/summon and persistence/cleanup
checks before combat/piercing/defense revisions, procedural items/events and Hector.
Those later requirements remain incomplete; follow the preserved brief in order.
No public-server deployment or Workshop publication is included.

---

# Current checkpoint — persistent dungeon and Hero queues

Active author brief: implement the ten-priority retention, combat, equipment,
events and Hector expansion from main. Completed first checkpoint: final-life
choices, new Level-1 Hero in the same dungeon, persistent queue selection,
model reuse and removal of total-party-wipe failure. Account claims stay outside
the replaced character. F3 reopens the choices. Live GDD 00 → 01 → 06 and the
HUMAN opening amendment record LOD-RETENTION-001; this supersedes old wipe law.

Validation: all 120 registered suites covered successfully (118 passed the
full run; corrected obsolete closure assertions and syntax rechecked separately).
Manual source/readers and new replacement/lifecycle tests pass.

Next: critical navigation/collision/DFT defects, then shared progression and
capabilities, equipment/events, and Hector. This checkpoint does not claim those
remaining requirements implemented. Native GMod multiplayer acceptance pending.

---

# Current candidate — damsel progression, endless cash and audio cleanup

Current author direction replaces repeat-Deborah rescues with the finite 20-damsel
arc, followed by endless cash objectives. The candidate also addresses staging
equipment access, Poison diversion, Climber clearance, Arc Caster recovery,
Nodule combat bounds, ambient loop ownership and gold allied summons.

See [DAMSEL_PROGRESSION_AND_AUDIO.md](DAMSEL_PROGRESSION_AND_AUDIO.md) for the
roster, reward/persistence rules, audio decisions, regression coverage and finite
native playtest commands. GDD navigation used 00 → 01 → 02/03/05/06/07. Beam
Sweepers retain their authored stationary role. The current request supplies the
new roster, rewards, palette and endless-mode design discretion.

Validation: `python3 tools/test_checkpoint_g_integration.py` passes all 120
suites with zero failures; staged diff whitespace checks pass. Native Garry's Mod
audiovisual/multiplayer acceptance is pending a fresh build playtest.
Do not deploy the public server or publish Workshop as part of this checkpoint.

---

# Previous candidate — auxiliary mouse Magic dispatch repair

Author-reported M3/M4/M5 casts repeated RMB's Form on `6e136b3`. The installed
Wizard feedback wrapper dropped the requested button for every class. Forward
that argument through both wrapper paths; keep the existing cast resolver and
full-Magic snapshot/error cleanup. No rules or tuning change. Current author
direction governs independent bindings; live GDD 00 → 01 → 03/06 preserves the
shared Magic authority (older single-Form UI wording is superseded by that direction).

The expanded mouse-binding regression reproduced the failure before the fix
(`fighter M3 must cast beam, not RMB`) and now passes all 78 eligible
class/Form/auxiliary-button combinations through the real network receiver,
installed Wizard wrapper and cast transaction. Terminal world effects are
doubled; costs, cooldowns, binding ownership, unbound/invalid request rejection,
RMB/legacy requests and snapshot cleanup remain real. All 116 integrated suites
pass with zero failures. Native acceptance: on `gm_flatgrass`, assign four different Forms to
RMB/M3/M4/M5 and cast each; Wall retains hold-to-aim/release-to-place. No public
server deployment or Workshop publication is included.

# Previous candidate — integrated equipment, exchanges and Magic

Author-directed six-part continuation preserves `402ecb2` and extends the server
inventory/SQLite/UI/Magic authorities: four Debbie drag-and-drop actions, durable
DFT exclusions and fusion recreation inheritance, authoritative capacity snapshots,
feet-hull Wall placement with Wisdom duration, server-rolled Watermelon bounces,
and persisted RMB/M3/M4/M5 bindings. Wall now holds to aim and releases to cast;
idle selection shows no guide. All 116 automated suites pass. See
[implementation, tuning and native acceptance](EQUIPMENT_MAGIC_INTEGRATION_20260918.md).
Native multiplayer acceptance remains pending; no server deployment is included.

# Previous candidate — Equipment access, real capacity and Debbie exchange

Author-directed continuation from `cace700`: O matches P/I menu input mechanics;
the inventory displays actual equipment capacity and separate consumable stacks;
Debbie has prominent carried-equipment and DFT pages, drag/drop sell/fuse piles,
atomic equipped-item exchange and enforced DFT-recreation exclusion.
All 114 automated suites pass. See [implementation and native check](EQUIPMENT_EXCHANGE_REPAIR_20260918.md).
Native menu/drop feel and multiplayer visual acceptance remain pending.
No server deployment is included.

# Previous candidate — usable Wall placement, aiming preview, offensive starters

Author-directed repair from `3e7a83b`: forgiving bounded Wall fitting, an owner-only
server-calculated aiming preview with rejection reasons, and direct-damage first
Forms for every Wizard. Wall and Summon remain available through later grants.
All 114 automated suites pass, including 84 aiming cases and 3,000 Wizard starts.
See [correction, evidence and finite native check](WALL_PLACEMENT_REPAIR_20260918.md).
Native placement/preview feel remains pending. No server deployment is included.

# Previous candidate — Equipment O toggle, Watcher scan and Wizard Wall

The 2026-09-18 author-directed continuation from `c6bd155` fixes focused Equipment
toggling and Watcher dispatch, adds the tenth Form (Wizard-only Wall, Heroes pass
through) and an admin all-Forms test command. All 113 automated suites pass.
See [implementation, tuning, evidence and native session](EQUIPMENT_WATCHER_WALL_20260918.md).
Native Wall rendering/collision and Watcher scan/retreat acceptance remain pending.
No server deployment or Workshop publication is included.

# Previous candidate — wielded colors, ordinary pistol/crowbar loot, Super Ball

The 2026-09-18 author-directed continuation from `d7fe92a` repairs the held
render path and hand completion, adds starter-family variants to ordinary
Dungeon-1 loot, and integrates Super Ball as the ninth Form. All 111 automated
suites pass, including 4,800 loot samples and geometric ricochet/lifecycle tests.
See [implementation, tuning, evidence and one native action](WIELDED_LOOT_SUPER_BALL_20260918.md).
Native wielded colors, multiplayer presentation and bounce feel remain pending.
Prior crash safeguards and newer gameplay systems are preserved; no deployment
or Workshop publication is included.

# Previous candidate — audio ownership, weapon regions and Watermelon

The 2026-09-18 author-directed pass is implemented from `6aba7b0` on `main`.
See [changes, tuning and finite native acceptance](AUDIO_WEAPONS_WATERMELON_20260918.md).
Looping ambience has finite ownership; the Hermit shares the original musical
cue lane; six stock weapons have three real color regions; Watermelon is an
integrated eighth magic Form. All 109 automated suites pass. Native GMod sound,
animated region placement and multiplayer visual acceptance remain pending.
The prior maze-deployment crash repair is preserved. No deployment or Workshop
publication is included.

# Previous candidate — maze-deployment generator crash repair

`generator-jit-20260917-01`, developed on `main` from `eb20c8f`.
The supplied x64 minidump identifies Equipment.Generate during initial maze
loot allocation and reports LuaJIT 2.1.0-beta3 with the old safeguard skipped.
The recorded reward corpus independently segfaults on upstream 2.1.0-beta3
with generator compilation enabled. Extend the function-only interpreter
safeguard to every LuaJIT; preserve loot determinism and the integrated refresh.
The generator now has its own loaded-component receipt. All 108 suites pass.
See [evidence and the single deployment acceptance action](GENERATOR_CRASH_REPAIR_20260917.md).
Native acceptance remains pending; no deployment or Workshop publication.

# Previous candidate — integrated gameplay refresh

The 2026-09-17 author-directed 26-part pass is implemented on `main` from
`aeaa6b3e24a53b9578be35cae2238f916eebb9e0`. See
[the checkpoint and finite native checklist](INTEGRATED_REFRESH_20260917.md).
All 107 integrated suites pass, including 512 deterministic encounter plans,
real SQLite sale/fusion rollback, Haste input, status remedies/procs, vertical
Magic cover, derived UI, observer range and identity presentation. Native
GMod composition, stock material topology, feel and multiplayer acceptance
remain pending. No server deployment or Workshop publication is included.
The newer geometry/full-update repair below remains a regression constraint.

# Previous candidate — client geometry initialization repair

`geometry-init-20260916-01`, developed directly on `main` from verified
`0ef180ae886fd91b8a5e9ebbd6502c084de63f17`.

The reported repeated GetBoxMins error is reproduced by notifying transmission
before SetupDataTables supplies the client accessors. The previous full-update
harness assumed these accessors already existed and missed this lifecycle order.
Static-box transmission recovery now only restores membership and schedules a
bounds refresh. Bounds and all four affected entity render paths wait for their
required accessors; incomplete entities remain registered and recover on the
next ready frame without another Initialize or transmission notification.

Live GDD: 00/01 and 07 client presentation/reconnection authority. Routine
implementation correction; no design or tuning changes. Finite automated gate:
actual notification/render hooks with absent and individually missing accessors,
deferred bounds retry, full-update recovery and genuine removal; integrated gate.
Validation: the expanded regression fails with the reported GetBoxMins error on
the prior implementation and passes with this repair. All 104 integrated suites
pass, including the Lua syntax audit.
Native gate remains pending: join the updated server, then perform one client
full update and verify floors/gates remain visible with no recurring Lua errors.
No server installation or Workshop publication is included.

# Previous candidate — collapse restart, camera and client recovery

`collapse-recovery-20260916-01`, developed directly on `main` from verified
`4e0aad2497aa5a20172a4b1493c826bf6151b9ad`, preserving the newer server listing,
loading artwork and client branding delivery commits.

Collapse completion starts server-owned deadlines: automatic new campaign after
20 seconds; fresh E press allowed after 5 seconds. Periodic aftermath snapshots
show both countdowns. The existing epoch-guarded restart transaction owns manual
and automatic requests. Server hibernation ownership lasts until restart, so an
empty server cannot strand an already-started aftermath.

The camera now faces the native Flattywood sign from its opposite side, pitched
40 degrees down with FOV110, horizontal stand-off 1.6 times prison radius and
a 160,000-unit far plane covering the distant skybox sign.
Stock BSP sign geometry/skybox conversion was inspected; 4:3 visible-frame tests
cover the prison footprint and full sign height. Native composition remains a
visual acceptance gate.

Source full updates may call OnRemove(true) without a subsequent Initialize.
Floor, gate, keycard and jail-door render registries now retain that membership
and recover it on NotifyShouldTransmit. A production draw-hook regression proves
reappearance after temporary invalidity and genuine removal without ghost draws.
No every-frame entity scans or network polling are added.

Live GDD: 00/01, 05 LOD-TIMER-001, 06 lifecycle and 07 tuning. The explicit new
restart/camera direction is recorded in 05/07. Finite gate: timer deadline/race,
manual key lockout, empty-server auto restart, camera projection and full-update
render recovery. All 104 integrated suites pass. GMod check: trigger a collapse,
inspect the sign/prison framing, let the countdown restart unaided; verify the
five-second E shortcut and client cl_fullupdate recovery in a separate run.
No server installation or Workshop publication is included.

# Previous candidate — Brute attack restoration

`brute-attacks-20260916-01`, developed on `main` from verified
`15387a51366b6f7e2343736a9cb2519d24afdc25`.

Reproduced: the ordinary Brute Tick refused attacks while a Neil defense order
existed; hits on Neil cancelled the Brute's telegraph; Neil's death could leave
that defense order permanently set while the Brute continued pursuit. Defense
routing now permits the authored charge. Further damage to Neil replans routing
without cancelling a committed Brute attack. Neil death clears obsolete defense
routing and refreshes survivor pursuit. Charge damage/timing, ordinary hit stun,
control cancellation, stairs, gates and wall-impact vulnerability are retained.

Live GDD: entrypoint/index, 05 LOD-OBJ-002 / LOD-ENEMY-003, exact HUMAN Neil/Brute
paragraphs, and 07 existing charge/hunt tuning. No design or tuning changes.
Finite automated gate: reproduce the old failure through ordinary Tick; prove
warning, one charge hit, cooldown and attacks after Neil's death; reuse existing
charge/wall/stair/control tests and the integrated gate.
Validation: all 103 integrated suites pass; the new ordinary-Tick regression
failed against the prior build and passes with this correction.
Finite GMod gate: damage Neil, let the Brute finish his warning, and confirm a
charge; kill Neil first and confirm the surviving Brute can still attack.
Native GMod acceptance remains pending; no server deployment is included.

# Previous candidate — dungeon transition retention

`dungeon-return-20260916-01`, developed directly on `main` after promoting the
accepted weapon build `fdea1ac0bc1e69765cff7e629a7590f85eeef5a2`.

Successful rescue resets the collapse clock to 30:00 and pauses it through
intermission, generation and staging. The next dungeon's first Hero deployment
starts its deadline; an expired rescue still loses before rewards. Native Hero
inventory snapshots reject Soldier and pending respawn bodies. Restoring owned
weapons bypasses new-item capacity admission with scoped exception cleanup.
Equipment records, slots and stacks remain bound to the same Hero state.

Finite automated gate: real completion/advancement/build/deferred-spawn test with
a full bag, exact weapon/clips/ammo/active selection, stored rolls and consumables,
Soldier retirement, overlapping builds and failed-Give cleanup; timer regression
for reset, paused staging, next start and deadline race; integrated suite.
Validation: all 103 integrated suites pass, including the new transition harness.
Finite GMod gate: complete one dungeon with carried gear, wait in next staging,
confirm 30:00 and retained weapons/items, then deploy and confirm countdown.
Native GMod acceptance of these transition fixes remains pending. No server
installation or Workshop publication is included.

# Accepted weapon visuals — promoted to main

Author request: remove procedural cosmetic gun attachments; represent stored
properties with tint, partial procedural textures, radiant aura and muzzle color.
Use **Wintery** as the Ice flavor adjective. Candidate runtime identity:
`weapon-surfaces-20260916-01`, based on verified remote main/dev
`55c48d5152a3847c9b93f8078b85fc6ded95d7f3`.

Implementation uses sparse bundled detail maps over the native gun texture,
scoped gun-only submaterials, bounded soft sprites and observed native shots.
No attachment geometry or extra model entities. Frozen records are preserved;
legacy Watery names migrate only when displayed. The live GDD tuning/economy
rules and generated canonical manual now reflect the author correction.
All 102 integrated suites pass; the historical LuaJIT 2.0.4 crash replay still
passes 1,400 exact rewards (with the authorized adjective substitution).
See `docs/WEAPON_SURFACES.md` for implementation boundaries and the visual gate.
Shael accepted the weapon visuals on 2026-09-16. Verified main was fast-forwarded
to `fdea1ac0bc1e69765cff7e629a7590f85eeef5a2`. The equipment branch is closed;
all subsequent work is on main unless Shael explicitly directs otherwise.

# Previous stabilization candidate

Candidate `stability-20260916-08` repairs a **reproduced native LuaJIT 2.0.4
equipment-generation SIGSEGV**. The new 3960-event original session ends during
wearable generation after an SMG Deadcrab kill; its mirror omits 53 final events.
Both realms load 07 on x86 LuaJIT 2.0.4. The exact reward corpus crashes a
standalone historical 2.0.4 VM with compilation enabled and passes when only
`Equipment:Generate` and its closures are interpreted. Apply that scoped
workaround on legacy LuaJIT; keep global JIT, deterministic item contents and
all gameplay systems intact. Modern 2.0/2.1 tests alone missed this defect.

All **102 integrated suites pass**, plus historical-VM exact-corpus, 16,000-item
distribution and production pickup/preparation tests. Re-enabling generator
compilation restores SIGSEGV in the standalone regression control. This proves
the defect/workaround outside GMod; **fresh x86 GMod acceptance remains required**
before attributing the user's termination conclusively or promoting the build.
See `docs/GENERATOR_CRASH_REPAIR_20260916.md` for evidence, reproduction and the
single sustained-playtest gate. Preserve the map/timer and earlier stabilization
repairs in `docs/CRASH_MAP_REPAIR_20260916.md` and
`docs/RELEASE_STABILITY_20260915.md`. No main promotion or live deployment.

# Current development plan

`main` is the canonical development baseline. Shael explicitly approved candidate
`87920e5ba3b27d46ff096f5a85cd41030a77f964` for promotion on 2026-09-14;
that exact commit was fast-forwarded to remote `main` without code changes.

Astra / Work is the primary implementation and senior-engineering environment.
Sol complements it with architecture, review, planning, and bounded implementation
where useful. Antigravity and `hybrid/antigravity` are retired as active development
workers/workflows. See [Development workflow](DEVELOPMENT_WORKFLOW.md).

## Current checkpoint — native manual payload transport

The 2026-09-15 native console proves why both manual entry points appeared inert:
`cl_instruction_manual.lua` aborted on startup because the client could not
include `lod/manual/manifest.lua`. The earlier lifecycle regression exercised a
local filesystem double and therefore proved the reader after initialization,
not the actual server-to-client delivery prerequisite that failed in GMod.

The client no longer includes the generated manifest or HTML chunks. The server
loads the one canonical generated document, compresses it once, and streams it
on demand in ordered messages capped at 60,000 bytes. P → Manual and staging E
now create the visible frame immediately, request the same payload, validate and
reassemble it, and cache it for subsequent openings. A failed or malformed
transfer leaves a visible retry control rather than an absent reader. Runtime
identity is `stability-20260915-04` and now requires `manual` and
`manual_reader` receipts. All 95 integrated suites pass, including production
client-launch and server-transport regressions. Native GMod acceptance remains
pending; no main promotion or public deployment is included. See
[Canonical instruction manual](INSTRUCTION_MANUAL.md).

## Previous checkpoint — Hermit starter-weapon crash repair

The first 2026-09-15 force-close report ended without a Lua traceback immediately
after class/feat setup. Candidate `stability-20260915-02` moved the whole starter
transaction beyond Touch and added durable breadcrumbs. A subsequent native test
still force-closed and proves that candidate did not resolve the defect: the last
stage is `before_native_give` for `weapon_smg1`, with no `after_native_give`.
The remaining native seam is therefore synchronous `Player:Give`, including the
project's `WeaponEquip` and pickup-policy callbacks fired from that call.

Every project `WeaponEquip` hook now performs zero synchronous weapon/player
inspection or mutation and schedules its complete work for the next tick. This
includes SMG capacity, shotgun capacity/seventh-shell, AR2 balance, procedural
equipment recording and grenade rejection. The protected one-time starter grant
also bypasses the project's capacity callback without interrogating the
half-constructed weapon. The native grant is protected against Lua errors and
retains the existing stage breadcrumbs. Runtime identity is now
`stability-20260915-03`. All 94 integrated suites pass, including a real SMG-hook
regression that throws on any access before simulated native settlement. Native
GMod acceptance remains pending; no main promotion or public deployment is
included.
See [Hermit starter crash repair](HERMIT_STARTER_CRASH_REPAIR.md).

## Previous checkpoint — Hero respawn loadout retention

The author explicitly corrected the older death-loss rule: consuming a Hero life
must not empty that Hero's run inventory. `PlayerDeath` now captures the native
loadout at the authoritative death seam even though Source already reports the
victim as dead. The saved state includes ordinary weapon classes, both magazine
values, reserve ammunition, armor and the actively wielded ordinary weapon.
Respawn restores that snapshot and reselects the wielded weapon.

The identity-owned equipment bag is no longer replaced on death, so equipped
wearables, stored items and grenade-slot potions survive unchanged, including
final-life elimination followed by a later campaign revival. Human Soldier deaths
remain isolated and cannot overwrite the stored Hero loadout. The manual now
teaches the corrected retention rule. Deterministic lifecycle coverage exercises
death capture through the real hook and the subsequent spawn restore. Native
Garry's Mod multiplayer acceptance remains pending; no main promotion or public
deployment is included.

## Previous checkpoint — manual launch and HUD layout repair

The portable reader had installed its JavaScript-to-Lua bridge before Chromium
loaded the manual document, contrary to the DHTML lifecycle contract. A document
replacement could therefore discard every callback and leave the launched reader
nonfunctional. Bridge installation and bookmark restoration now happen from
`OnDocumentReady`; both staging E and Player Menu continue to use that one reader.

The campaign clock has its own upper-left row below the run/card block instead of
sharing the objective's upper-right band. The status portrait stays bottom-aligned
with the stock HP/Magic row, even when a weapon is equipped, and the wielded weapon
name is now centered vertically to the portrait's right. All 93 integrated suites
pass, including engine-lifecycle and six-viewport layout regressions. Native
Garry's Mod input/rendering acceptance remains pending; no main promotion or
public deployment is included.

## Previous checkpoint — wearable and potion drop repair

The final campaign-assistance override had retained an older category table and
enemy-spawn routine, shadowing the Equipment Update logic loaded earlier. Natural
enemy loot could therefore produce procedural weapon records but never select a
wearable category; it also omitted the equipment-eligible identity needed for
wearable conversion and the Healing Potion/Stink Bomb split. The final authority
now preserves the authored 75% useful band and relative wearable 24, consumable
12 and weapon 12 weights at every campaign-assistance depth. All seven wearable
families and both throwable consumables reach world pickups.

Prepared rewards are validated before native entity creation, generator errors
are contained at that boundary, pickup naming no longer dereferences unchecked
consumable records, and loot pickups retain native model scale rather than
requesting a collision-adjacent scale mutation. All 93 integrated automated
suites pass. Native Garry's Mod collection and force-close acceptance remain
pending; no public deployment or main promotion is included. See
[wearable drop repair](WEARABLE_DROP_REPAIR.md).

## Previous checkpoint — canonical illustrated instruction manual

The author requested a revised console-booklet-style guide and one canonical
in-game reader shared by staging E and the portable P → Manual tab. The reader
now loads independently of the physical book, remembers its page and scroll,
and uses the shared menu lifecycle. The guide covers the current continuation,
with original Deborah and antagonist art plus the complete feat/equipment
reference. See [manual authority, evidence, and native check](INSTRUCTION_MANUAL.md).
Native Garry's Mod rendering/input acceptance and the existing crash release hold
remain pending. No public deployment is included.

## Previous checkpoint — campaign clock and TIME OVER

Implements the author's explicit 2026-09-15 continuation over `af5b4f7` on
`astra/equipment-update`: one 1,800-second campaign clock, first-Hero portal
commit start, continuous cross-level timing, global destruction cinematic,
persistent aftermath and canonical E restart. The handoff supersedes the live
GDD's older per-dungeon timer and rescue exemption. All 90 integrated automated
suites pass; Source camera/physics/audio and multiplayer acceptance remain pending.
The existing native-crash release hold remains open. See
[TIME OVER checkpoint and one integrated playtest](CAMPAIGN_TIMEOUT.md).

## Previous checkpoint — complete ordinary enemy roster

Implements all nine missing v1 ordinary enemies over development baseline
`90477d7acc61091710c9ba18e49f1920073b1bc0`: Climber, Nodule, Flamer, Big Crab,
Sentry, Razor, Arc Caster, Lurker and Beam Sweeper. Existing ordinary enemies and
Neil/Brute/Gordon remain intact. Fix model-unsupported Sniper activity requests
and retreat animation selection at the shared activity/Motion V2 authorities.
Author-approved tuning is recorded in live GDD 07; the manual teaches the roster.
All 89 automated suites pass. Native visual/co-op acceptance and the fatal-crash
release hold remain open. Heavy remains explicitly deferred beyond v1.
See [roster, validation and finite test](ENEMY_UPDATE.md).

## Previous checkpoint — Gordon the Warden

Implements Gordon over development baseline
`253af3b273f53d5c6910931fc4c5d738f8418be8`, on `astra/equipment-update`.
The two-level arena, three combat phases, protected co-op entry/respawn,
ordered party health scaling and death-only center Jail Key replace the temporary
Core shortcut. Author-approved tuning is in live GDD 07. All 88 automated suites
pass. Gordon uses a seeded stock male citizen with a heavy build and procedural
pig mask, requiring no external model download. The adaptive
soundtrack remains dependent on its unshipped MusicDirector/suite system;
Gordon publishes its tension hooks and supplies entrance/phase/victory cues.
Native visual/co-op acceptance and the fatal-crash release hold remain open.
See [implementation, dependencies and finite playtest](WARDEN_CHECKPOINT.md).

## Previous checkpoint — Neil and the Brute

Implements the post-Yellow hunt over development baseline
`e7576355967084b9fca246022ce9a4b3a7da6148`, on `astra/equipment-update`.
Neil uses legal multi-floor escape routes; the Brute escorts him, responds to
damage, and has a committed charge with wall-stun counterplay. Neil alone
releases the physical Black Keycard. The fourth gate establishes checkpoint 4
before the explicitly permitted temporary Core Jail Key. Gordon remains next.
The author's follow-up approved choosing the missing encounter tuning; values
are recorded in live GDD 07. All 86 automated suites pass; native combat feel,
multiplayer acceptance and the outstanding fatal-crash gate are not yet accepted.
See [implementation and finite playtest](NEIL_BRUTE_CHECKPOINT.md).

## Previous checkpoint — native crash audit repair candidate

Audit of dev HEAD `d59d2df2274cd11fb6311b7c3d89bef2a6b8ed9e` completed;
all 366 production sources match remote content. Latest detailed log again
ends at `loot_enter` (Shambler #1272), without the preceding candidate's new
loot/profile markers. Actual loaded build and native fault remain unproven.

Direct hostile-to-LootDirector handoff replaces the load-order class patch and
native placeholder fallback. Remove twelve additional unnecessary activation
calls, defer starter-pickup retirement beyond touch, bound/reclaim native mesh
and afterimage caches, and unwind mirror render state after Lua errors.
Installer/build receipts now identify loaded components and resource trends.
All 85 automated suites pass. Main/public release remains held for fresh native
acceptance. See [native audit, evidence and acceptance](NATIVE_CRASH_AUDIT_20260915.md).

## Previous checkpoint — consistent GPS and loot crash candidate

Starting dev HEAD `a671934496c51a2306e7e5634642e3bbfcee781c` on
`astra/equipment-update`. GPS retains its voice, WIS 17 gate and G toggle,
but triggers after 1 second stationary and repeats after phrase duration plus
4 seconds. Two-cell same-floor proximity uses the existing faction opponent
registry, including human Soldiers and enemies behind walls. Movement, combat
input, staging/death/spectating and lost ownership cancel speech and reset the
idle trigger. Shared voice tokens/durations, one channel and generation checks
prevent delayed file opens or timers reviving canceled speech. No random wait,
new pathfinder or enemy replication. Missing routes retry at most once a second.
Live GDD 04 and the exact HUMAN GPS row are reconciled.

Crash evidence: `rpg_test_session(20260915-151547).txt` reaches sequence 308,
time 142.245, Soldier #1174 at `loot_enter`, without `loot_complete`. Its death
callback and corpse presentation completed; a separate nonlethal Bio Blaster
hit and client feedback also completed. The periodically copied summary is
older (sequence 263), so use the full session for event order. These logs show
the older percentage-stat build, not acceptance evidence for the flat-stat patch.
There is no native stack trace; the exact crash cause remains unconfirmed.

The loot path called Activate after an anim pickup's SetModelScale. Facepunch
explicitly documents potential collision-rebuild crashes for that combination:
https://wiki.facepunch.com/gmod/Entity:SetModelScale
Remove unnecessary activation from real pickups and the fallback decoration.
Arm touch collection next tick, after metadata/transmission registration; defer
successful pickup removal beyond touch traversal. Keep automatic collection and
existing grant idempotence. Add bounded LOOT_NATIVE_STAGE breadcrumbs around
handoff/category selection, model validation, spawn and registration. Profile
logs now include the new flat STR/WIS bonuses; summaries retain legacy fields
for older evidence. This is a repair candidate, not a proven native-crash fix.

All 84 automated suites pass. New tests exercise production GPS cadence and
async cancellation plus real pickup initialization/registration with simulated
spawn overlap and duplicate touches. Headless checks cannot validate native
collision behavior or audible timing. Next finite native gate: play normally,
stand still in a safe corridor to hear GPS, and collect a killed Soldier's drop.
If force-close recurs, preserve console_latest.txt and rpg_test_session.txt before
relaunch. No main promotion or public deployment.

## Previous checkpoint — flat Strength and Wisdom damage

Starting dev HEAD `2a098bc73080ba69bd3653da412730058c34a422` on
`astra/equipment-update`. Author rebalance replaces percentage STR/WIS damage
with the effective ability modifier as one flat addition per resolved attack
contract per target. Live GDD 02/03 now replace the superseded full-positive-STR
penetration rule. Only physical Fighter attacks protect ceil(max(STR_MOD,0)/2)
from CON. The remaining modifier joins the first positive damage contribution
before its usual CON subtraction and minimum-1 floor; the protected portion is
added afterward. Other original contributions retain per-die CON, and existing
separate flat bonuses retain their treatment. No positive contribution means
no invented hit. WIS uses the same flat addition without Fighter penetration;
wisScaled=false keeps its existing exemption. Negative modifiers have no bypass.

STR 20 adds 5, with 3 protected for a Fighter. A base roll of 1 against CON
reduction 3 resolves to 4 for that Fighter, versus 3 for another class or a
WIS 20 magic attack, before later modifiers. Exploding chains and shotgun shares
do not multiply the number of additions. Existing aim/backstab multiples,
capstones, equipment, element resistance and downstream defenses still apply.
Committed attacks preserve firing-time STR/WIS and class. Killer Instinct now
shares the pure base arithmetic without changing combat telemetry. Class cards,
Character Sheet tooltips/passive text and developer status reflect flat bonuses.

All 82 automated suites pass, including real shared damage dispatch, flat/odd/
negative modifiers, low/zero dice, WIS, class isolation, explosions, shotgun
shares, aim/backstab stacks, committed stats, gear/elements and Hero/AI/Soldier
parity. The all-class staging snapshot regression remains green. Next finite
native gate: play the high-STR Fighter again and check low physical rolls against
a CON-resistant enemy; inspect the STR tooltip and damage log. Actual in-game
balance acceptance remains pending. No main promotion or deployment.

## Previous checkpoint — procedural weapon visual identity

Starting dev HEAD `5125fb03310529f5319b7c3755ee21da09161654` on
`astra/equipment-update`. Author direction permits a broad visual system. Live
GDD 07 now records the grammar and performance limits. Shared appearance data
projects all 60 catalog properties, magnitudes, quality, rarity and seed into
stable fittings, labeled glyphs, magnitude bars, penalty fractures, a dominant
element core and procedural machining/finish. Receiver plates have brushed,
ceramic, carbon-weave or hammered detailing; stat and rider silhouettes use
anvils, fins, coils, plates, lenses, crests, buds, fangs, shards and cages.
First-person, visible third-person active weapons, owner-visible world pickups
and inventory share the grammar. Equipment details and the canonical booklet
teach the visual key; exact values remain on the item sheet. Conditional marks
use existing HP/Magic/movement state. No gameplay or animation authority changes.

A versioned compact descriptor is stamped only when the selected immutable
record changes. Same-family copy selection updates appearance; merely collecting
a copy does not. DFT recreation preserves the frozen appearance. No weapon/hand
material mutations, extra entities, emitters, dynamic lights or entity scans.
Weak caches, fixed materials, near/distant detail tiers and per-frame world caps
bound work; reduced effects keep meaningful marks while stopping the pulse.
Attachment-less melee viewmodels follow the hand bone when available.

All 82 automated suites pass. The new validator covers every property/shape,
2,500 distinct sampled appearance fingerprints, deterministic frozen/reordered
records, malformed payloads, actual copy selection, unchanged sends, renderer
quality/distance/frame limits, balanced render contexts and cache cleanup.
Largest sampled wire descriptor: 78 bytes, under the 480-character ceiling.
These checks cannot establish native aesthetic quality. Next finite in-game
gate: inspect two same-family guns, equip each, and compare their element core,
rider fittings, glyphs, hand/sight clearance and the Equipment Visual Key.
Viewmodel attachment positioning, surface lighting and readability need native
visual acceptance. No main promotion or deployment.

## Previous checkpoint — Fighter feat-draft delivery blocker

Starting dev HEAD `0902ab038902c763d94ed28be9c95995ad370458` on
`astra/equipment-update`. Fresh evidence: `console_latest(20260915-143951).txt`
and `rpg_session_latest(20260915-143950).txt`. Fighter commits at session time
18.030, followed by repeated snapshot failures at sv_character_progression.lua
1609: bad argument #6 to format (no value). The class description introduced
in the loot/class checkpoint contained an unescaped literal percent in a
string.format template. Draft generation succeeded, but the deferred snapshot
producer failed, leaving the client without its offers and staging correctly
blocked on the uncommitted feat. Escape the percent; no eligibility, draft,
class balance or portal rule changes.

The production snapshot test now covers Fighter, Rogue and Wizard from class
commit through three delivered choices, stable refresh, feat commit and the
actual IsDeploymentEligible predicate used by the portal. It reproduced the
exact logged formatting failure before repair. The prior test exercised Rogue
and missed the Fighter-specific template. The same console also identifies an
independent statue timer error from invoking client-only SetupBones on the
server. Guard that call; a server-realm test verifies pose selection, frozen
sequence/cycle and scowl finish without that method.

All 81 automated suites pass after repair. Native acceptance remains pending:
pull/install, restart, choose Fighter and confirm the three feats appear; choose
one, collect the starter and enter the portal. Existing valid offers are retained
on refresh. No live GDD correction is needed for these implementation defects.
No main promotion/deployment; earlier native-crash diagnosis remains unconfirmed.

## Previous checkpoint — four working Wall Jumps

Starting dev HEAD `e22fd90c8ab96d5ccb2790963a4cac8961c97348` on
`astra/equipment-update`. The user reported Wall Jump had no effect. Its brush-only
trace and HitWorld-only acceptance excluded the labyrinth's `lod_static_box`
collision architecture. Use MASK_PLAYERSOLID with the actual standing/crouched
hull and accept map world, generated static boxes, gates and jail doors. Reject
actors, props, cosmetics, embedded starts, floors and ceilings.

Wall Jump now permits four successful kicks before landing, each on a fresh
jump press. Set ordinary vertical takeoff and the existing 160-unit outward
normal speed so falling/inward momentum cannot cancel the jump; preserve
horizontal tangential velocity. Spring Heel scales only vertical takeoff. The
shared feed reports the used count. Cloud Step stays independent and lower
priority; failures do not spend uses. Ground contact resets the counter, including
when a landing jump press precedes Think. Death/actor lifecycle resets remain.

Live GDD 04 LOD-FEAT-005 and the exact HUMAN DEX_WALL_JUMP row are updated, as are
the feat description and exact-row test fixture. All 81 automated suites pass.
The expanded movement suite exercises input, generated-wall probes, four/fifth
kick behavior, crouch, falling/inward velocity, ground/death reset, Cloud Step,
Spring Heel and invalid/held cases. Native acceptance remains pending: with Wall
Jump owned, jump alongside a labyrinth wall and release/repress Jump for each
kick; the feed should count 1/4 through 4/4 before landing restores the allowance.
No main promotion or deployment; previous crash diagnostics remain.

## Previous checkpoint — ordinary loot, carried copies and class combat

Author direction is reconciled in live GDD 03 LOD-CBT-007, 06 inventory/DFT rules
and LOD-UI-010, and 07 tuning. Starting dev HEAD:
`5892fe2a68bd239d4977f64b0b66304f4fdd5e0d` on `astra/equipment-update`.

Ordinary useful-drop chance is 75% (90% at the existing dry-streak threshold).
Wearables, guns and consumables have increased category weights; all seven
wearable families are reachable. Auto pickup stores distinct rolls, including
multiple copies of a weapon family, without replacing equipped gear. Copies
share the family's existing ammunition. Dragging in/out works across snapshot
arrival, and any unequipped item can be trashed. Full bags preserve the drop.
Equipment remains through mazes/reconnects and is cleared at Hero death. DFTs
are separate persistent rewards minted only during rescue settlement, retaining
transactional rollback/replay protection and the eight-token cap.

Pickup comparison is deprecated in favor of large full names. Drops and
Omniscience use bounded near-look selection with line of sight and cloak guards.
Rogues add one damage multiple and bypass CON resistance from the rear; Fighters
add positive STR modifier percentage points to shield Block under the shared
33% cap. Debbie is frozen client/server, 1.2 scale, with stone wings and soft
blue/gold light, preserving the granite Deborah pose and staging placement.

All 81 automated suites pass, including SQLite rollback, actual acquisition,
copy selection/ammo, all-family loot, trash/death, snapshot/drag protection,
backstab multipliers, shield gating, near-look visibility and bounded statue FX.
The field manual and class UI describe the revised rules. In-game acceptance is
pending. Next finite gate: collect two same-family guns and a wearable, drag
them in/out, trash a stored copy, and verify the equipped roll/ammunition remain
correct. The crash diagnostics are retained; this pass provides no fresh native
crash evidence. No main promotion or deployment.

## Previous checkpoint — Fighter Strength bypasses Constitution resistance

The author buffed every Fighter-class actor's positive Strength damage bonus:
calculate that bonus from the physical roll before CON reduction, while base
damage still receives the existing per-die resistance. If U is the unreduced
aggregate, R the reduced aggregate and S the STR multiplier above 1, resolve
R + U × (S − 1). Keep the existing behavior for penalties, non-Fighters and Magic.
Apply authored scale, capstone, shotgun shares, gear, elements and subsequent
defenses normally. The class flag follows committed equipment snapshots; class
choice and Character Sheet text explain the benefit. Live GDD 02 LOD-CLS-006 and
03 LOD-CBT-006 contain the author's correction. Starting dev HEAD:
`574c032ca3e1c7411f91c57732871fc430215469` on `astra/equipment-update`.
`tools/test_fighter_strength.lua` tests the real derived-state and damage paths,
class/actor parity, low and exploding dice, flat bonuses, penalties, scaling,
shotgun shares, elemental/gear defenses and committed attack identity. All 80
automated regression suites pass; the identity-perk expectation now includes the
Fighter bypass while preserving its single flat favored-weapon bonus.
Native acceptance remains pending: attack a resistant enemy as a Fighter and
compare the final damage with the die readout. Existing crash diagnostics remain;
this balance change provides no new native-crash evidence. No main promotion or deployment.

## Previous checkpoint — monster class and elemental identity

The author's monster-readability request adds subtle class modulation: Fighter
keeps its archetype paint, Rogue adds pale green, Wizard adds pale violet.
An independent seeded one-in-three roll assigns one of the six existing elements
to generated monsters, including human-controlled Soldier incarnations. Matching
resistance and reciprocal weakness use the shared damage ladders. Separate
depth-tested elemental motes and aimed element words respect cloaking and reduced
effects. No dynamic lights, emitters, added entities or monster-list scans.
Live GDD 03 LOD-ELEM-002, 07 and the exact HUMAN spawn paragraph reconcile the
former 50% rule with the author's one-third direction. Automated validation and
the finite native playtest are recorded in [Monster identity](MONSTER_IDENTITY.md).
Next runtime gate: meet ordinary enemies, compare class tints and elemental cues,
then hit a typed monster with matching and opposing Magic. Prior native crash
causes remain unresolved; preserve existing diagnostics. No main promotion or deployment.

## Previous checkpoint — Size Shifter wall-entrapment repair

The player reported becoming stuck in a wall with Size Shifter. The old code
changed native model scale without an explicit movement-hull authority, and
routine derived-stat sync briefly restored baseline size before reapplying the
current transformation. Shared client/server movement now installs ordinary
standing/crouched hulls; server size changes preserve those hulls and reject
blocked growth. A blocked transition retains its progress and resumes smoothly
when clear. Derived-stat sync applies the current size once, without the baseline
snap. The live INT_SIZE_SHIFTER rule already requires legal ordinary movement;
no GDD redesign was needed. All 78 automated suites pass. Native runtime
acceptance remains pending: crouch, move along a wall/corner, then release crouch;
repeat below a low ceiling. See [Size Shifter repair](SIZE_SHIFTER_REPAIR.md).

## Previous checkpoint — elemental magic and equipment inventory

The latest author request restores the procedural weapon name below the HUD face,
adds weapon stow/re-equip with empty inventory tiles, and mixes wearables/potions
into ordinary enemy drops. Six Forms now share original elemental impact
choreography; detonation cores/lobes/smoke supplement the existing accurate area
indicators. Bolt/Missile use enchanted comet visuals; Summon has an elemental
aura and contact effects. Work is bounded and supports reduced effects.
Live GDD 03 LOD-FX-001, 06 LOD-UI-008/009 and 07 record the current direction.
77 automated suites pass. GMod visual/interaction acceptance remains pending.
Next gate: ordinary gm_flatgrass run, cast equipped spells, stow/re-equip a gun
through Equipment, and collect mixed ordinary enemy drops. Preserve prior native
crash diagnostics; this checkpoint supplies no new evidence resolving that crash.
See [magic and inventory checkpoint](MAGIC_INVENTORY_CHECKPOINT.md).
No main promotion or deployment.

## Previous checkpoint — labyrinth-entry crash candidate and granite Deborah

The fresh staging playtest force-closed on reported labyrinth entry. Its 139-event
session ends after successful DFT recreation, without combat, death or a native
fault trace. The portal now queues its native teleport/pickup work outside the
input callback, coalesces duplicate Use requests, and cancels stale player/run
state. Bounded deployment-stage logs identify the next failure boundary.
The statue is beyond the portal opposite the Hermit, offset from its approach,
with the configured Deborah model, gray granite, frozen folded-arm idle selection
and scowl flexes. Live GDD LOD-UI-009 records the revised presentation direction.
All 76 automated suites pass; native crash resolution and statue visual acceptance
remain pending. Next gate: fresh-start gm_flatgrass, inspect the statue and enter
the labyrinth normally. See [entry-crash evidence](LABYRINTH_ENTRY_REPAIR.md).
No main promotion or deployment.

## Previous checkpoint — status portrait beside Magic

The author's latest HUD direction explicitly supersedes the earlier face-position
hold. The portrait now sits immediately right of the scaled Magic readout, aligned
to its bottom, with the character-name/status caption wrapped above it. Remove
the persistent carried-weapon name and always suppress stock secondary-ammo/ALT
FIRE; retain primary ammo, Equipment item names and functional Magic/potion prompts.
Live GDD LOD-UI-009 and tab 07 record the correction. All 76 integrated suites pass,
including responsive layout checks at 640×480, Steam Deck, 4:3, 16:9 and ultrawide.
Source visual acceptance remains pending. See [portrait checkpoint update](STATUS_PORTRAIT_CHECKPOINT.md).

The preceding native crash remains unresolved: no fresh playtest evidence was
provided. Preserve its repair/diagnostic candidate and finite Soldier-kill retest
below. No main promotion or deployment.

## Open runtime checkpoint — Soldier crash investigation and wallet repair

The 2026-09-15 playtest force-closed. The full log records a successful Raw Bolt
hit followed by a lethal AR2 hit on the same Soldier; it ends before death/XP
completion. The native fault is not established. Repair the independently
reproduced wallet SQL-quoting defect, defer native corpse mutations out of the
death callback, guard duplicate kill settlement and add bounded death-stage
diagnostics. All 76 integrated automated suites pass. Source crash resolution
remains pending: repeat only Bolt → AR2 Soldier kill on a fresh application start.
See [evidence, repair and finite gate](CRASH_REPAIR_2026_09_15.md). No main
promotion or deployment; retain the combined candidate's feature scope.

## Previous checkpoint — Equipment tab, filled Magic areas and rear statue

The author's follow-up presentation direction is implemented on the same combined
`astra/equipment-update` candidate under live GDD LOD-UI-009. Equipment is now a
first-class sibling tab with its own frame; Magic areas have solid outer boundaries
and approximately 40%-opaque interiors; the Deborah statue is behind the Hermit
and uses the portal/manual prompt style. The author's subsequent correction
explicitly retains the existing face HUD position. All 75 integrated automated
suites pass; Source visual acceptance is pending. See
[presentation checkpoint](PRESENTATION_POLISH.md).

## Previous checkpoint — visual equipment inventory

The author's CRPG equipment direction is implemented on the combined
`astra/equipment-update` candidate under live GDD LOD-UI-008. A left body map and
right icon grid support compatible drag/drop and click-to-equip, paired gloves,
weapon selection and consumable stacks. Owner snapshots preserve the window and
active drag; stale requests cannot remove a replacement item. All 74 integrated
automated suites pass; Source visual acceptance remains pending.
See [equipment inventory checkpoint](EQUIPMENT_INVENTORY_UI.md).

## Previous checkpoint — reactive character status portrait

The author's Doom-inspired HUD direction is implemented on the same combined
`astra/equipment-update` candidate. The live GDD LOD-UI-007 records the local HUD's
character-name-only exception, shared Character Sheet face, status replacement and
reactive expressions; tab 07 records cosmetic timing/layout choices.
See [portrait checkpoint](STATUS_PORTRAIT_CHECKPOINT.md) for implementation and the
finite visual gate. This preserves the equipment, enemy, wallet and Wizard changes
below. All 73 integrated automated suites pass; Source visual acceptance is pending.

## Previous checkpoint — persistent $DEB / DFT economy and Wizard balance

Shael accepted all [proposed wallet/DFT defaults](DEB_DFT_PROPOSAL.md) on 2026-09-15
and requested completion. The live GDD now records LOD-ECON-001 and the Wizard
changes in normalized tabs 02/03/06 and their HUMAN counterparts.

The combined `astra/equipment-update` candidate contains server-local transactional
wallets, rescue contribution allocation, persistent lifetime score, once-per-server
Combat Level 1/5/10/20 DFTs, rare drops, eight-slot collections and pending milestones,
and free once-per-token-per-run recreation or permanent sale at the staging statue.
Wizards gain one distinct starting Content; Summon is Wizard-only with base cost 12.
See [current evidence and finite runtime gate](CRYPTO_CHECKPOINT.md).
All 72 integrated automated suites pass. Source multiplayer/restart acceptance
remains pending; do not equate automated checks with a live-server acceptance.

The same candidate preserves the equipment, perk, enemy, recurring-staging, Hermit
and leaderboard changes for one combined playtest. The low-end/distant-player
[performance checkpoint](PERFORMANCE_CHECKPOINT.md) also remains intact: equipment
snapshot coalescing/deltas, retained pickup layouts and unchanged-stat caching.
Source FPS/RAM and real-network performance acceptance remain pending.

## Next scope

Shael's Equipment handoff explicitly promotes Equipment implementation ahead of
public deployment. Work is isolated on `astra/equipment-update`; main remains the
accepted RPG baseline. Workshop and public VPS are held until Equipment and Enemy
are both complete, followed by separately authorized deployment.

Shael's 2026-09-15 direction expands the approved first equipment catalog into a
unified procedural weapon/wearable economy and explicitly authorizes its missing
formulas. Live GDD LOD-EQUIP-016 owns the new 60-property catalog, budget/rarity
curves, active-weapon contributions, statuses and acquisition behavior. Earlier
LOD-EQUIP-015 Block, Throwable and Special Move semantics remain in force.
See [economy rules and handoff](PROCEDURAL_ITEM_ECONOMY.md) and
[checkpoint](EQUIPMENT_CHECKPOINT.md). Equipment runtime acceptance remains pending. The later explicit user direction
authorizes Enemy development alongside the Equipment playtest; main promotion
still requires appropriate runtime acceptance.

The subsequent 2026-09-15 completion assessment found and repaired a real
Equipment blocker: full procedural pickup records exceeded the engine's
NW2String limit, breaking comparison data. Owner-checked inspection messages now
carry the complete record, with production server/client transport tests; all
66 integrated suites pass. See [completion assessment](EQUIPMENT_ASSESSMENT.md).
The subsequent user direction explicitly supersedes the conditional Enemy hold.
Equipment and Enemy can now be tested together on the same development branch.

Preserve accepted RPG behavior and the current workflow. Do not restart the old
hybrid/Antigravity process. The broader Instruction Booklet reconciliation and
outstanding RPG multiplayer release validation remain required before deployment.

## Combined Equipment / Enemy checkpoint

Shael explicitly requested Enemy variety while testing Equipment. The first
combined checkpoint adds the Sniper graph-retreat/crossbow controller, Sniper and
Blitzer variants of eligible Firing Line encounters, and repairs the unified
spawner's missing Blitzer entry. Existing equipment and perk changes are retained.
See [Enemy update checkpoint](ENEMY_UPDATE.md) for the finite playtest and remaining
scope. All 67 integrated suites pass; this is a development-branch candidate,
not in-game acceptance or completion of the full Enemy milestone.

Continue the missing canonical enemies and final hunt/boss/timer work. The live
GDD leaves required attack tuning unresolved for Flamer, Big Crab, Razor and Arc
Caster; do not fabricate those numbers. Sniper tuning is explicitly delegated and
is recorded in tab 07. Authored Climber behavior and the remaining explicitly
specified work can continue independently of those gaps.

## History

The subsequent user-requested [identity perk correction](PERK_UPDATE.md) is a
bounded detour on the same Equipment development branch. Independent category
rolls and duplicate stacking are retained and explicitly tested; new ability
perks support +2 or +1/+1, and every visible title/flavor follows the resolved
mechanics. Existing Heroes keep their permanent rolls. All 66 integrated suites
pass; Equipment runtime acceptance remains pending.

The [pre-promotion plan](DEVELOPMENT_PLAN_HISTORICAL_2026_09_14.md) preserves earlier
checkpoint sequencing and candidate handoffs. It is historical evidence, not the
current task queue. [Development status](DEVELOPMENT_STATUS.md) records promotion
and validation. The live GDD remains design authority.
