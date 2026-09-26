# Resume The Legend of Deborah — SPOT-05 Die Logger audit

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
SPOT-04 parent: `780d3d3b50f1026ba4a15a535b7569b6b09e0f71`.
The delivery receipt supplies the verified SPOT-04 child SHA. Fetch current main
and preserve intervening/uncommitted work before editing. Never use a local
source-reconstruction anchor as the upstream parent.

## Orientation

Read AGENTS.md, DEVELOPMENT_PLAN.md, briefs/SPOT_UPDATES.md,
validation/SPOT_04_ENEMY_AUDIO.md and TEST_LOGGING.md. Live GDD:
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
SPOT-04 used live 00 -> 01 -> 06 lifecycle rules and the explicit author audio
contract; existing design was repaired without changing the live GDD. For
SPOT-05 use 00 -> 01 -> 06 shared RPG-event/live/history parity, then only needed
subsystem rules; exact HUMAN detail only where the index requires it.

## Just banked — SPOT-04

Client LoopAudio rejects corpse/dormant/retired owners, stops before lease
expiry on replicated death, and rejects stale build owners using the existing
ClientTopologyIdentity/BuildSerial. PVS/full-update suspension is reversible for
living owners; true removal, shutdown and superseded module references cannot
restart loops. Strong native-handle ownership, limits gas2/watcher2/fuse4,
volumes, pitches and ordinary leases remain. Fuse ownership stays with the
projectile rather than the caster.

Server HostileDeathAudio tracks the existing Beam warning/sweep's emitted sound
identifier and exact attack/actor/run/graph/build. Cancellation, timeout, death,
removal, builder cleanup, regeneration, campaign reset and shutdown retire only
owned audio. Native StopSound and new retirement replication occur outside the
lethal-damage stack. Existing generation and Seeker asset filters allow SND_STOP,
including combined flags. Intentional death one-shots and ordinary living cues
remain. Razor/Redliner's shared dive warning now uses NPC_Manhack.ChargeAnnounce;
the reported-missing mh_engine_start1.wav was also removed from Razor footsteps.
Mounted asset decoding and audible playback are still native-unverified.

Fresh checks: 74/74 focused audio; 55/55 Razor; 44/44 Climber; 50/50 SPOT-01
identity checks; 731 Lua-file syntax.
**227 passing suites, one unchanged-parent harness failure, and two campaign-wide suites not run** (coverage across the bounded matrix and explicit reruns, not a full 230-suite pass). The unchanged parent's teammate-identity test still lacks Color.
Initial harness failures and bounded/omitted campaign sampling are preserved in
the SPOT-04 gate, not converted to passes. Native GMod audibility, corpse silence,
living-neighbor isolation, regeneration/reset and multiplayer remain unaccepted.
Use the compact local procedure in SPOT_04_ENEMY_AUDIO.md. Fully restart GMod
for the added audio lifetime fields; do not validate an old/new hot-load mixture.

## Updated SPOT-03 observations and sequencing

Shael's third controlled spawn succeeded after two legal-placement refusals.
That Razor was visible, attacked, dealt/took damage and was defeatable: visibility
and basic combat passed only for that instance. No natural Razor was noticed
before the test, including play past Red Gate. Status changed from all-zero
Razor counts to one live non-roaming encounter actor. The reported population
upload was Occupation, 60 roamers, zero planned/roaming Razor, developerMode=true
and developerDense=true, with all34 installed/mounted source hashes matching.
It is not release exposure/pacing evidence; the RPG summary recorded no validator
result. The blade=0 row's timing is unresolved. Prior uploads were summarized by
the author in the handoff, not independently re-read in SPOT-04; preserve that
provenance. Details remain in the dated SPOT_03_RAZOR.md supplement.

**Move on.** No dedicated Razor retest or natural sighting is prerequisite.
Collect natural sightings opportunistically during ordinary play, optionally
`lod_razor_status; lod_population_evidence`; separate developer-dense from release
sessions. Full Razor absence resolution, stairs/blades/Held/safety/co-op remain
unverified. Do not force spawns or retune density merely to manufacture exposure.

## Next single checkpoint — SPOT-05

Audit actual canonical server RPG events, producers, routing/recipient rules and
shared live/history formatting before changing code. Restore important omitted
events; remove routine noise such as Magic reaching100 through the canonical
stream rather than independently filtering one surface. Preserve complete
underlying authoritative gameplay dice, meaningful resource/life/status outcomes,
causal grouping, semantic identity colors and bounded retained history. Reconcile
the explicit author noise-removal direction with the current live parity law.
Define a finite production-module gate for representative missing/noisy events,
shared parity/order/history, life/reset/late-join ownership and bounded work.
Implement only this bullet; native readout observation remains distinct from
headless event assertions. Validate, non-force push and verify the remote SHA.
Existing-feat rebalances require approval; this is not a feat-balance task.

## Preserved constraints and release order

Preserve SPOT01/02/03/04, B28 physical queries, B29 sanctuary/graduated combined
pressure, population limits/Bestiary variety, Crate appearance and P1-P4. Earlier
native acceptance limits remain explicit. Do not publish Workshop or deploy or
restart VPS. Local acceptance -> Workshop item3791535712 package/source parity
-> matching VPS remains the release order. No Workshop/VPS operation happened
in SPOT-04. Default audio evidence: console_latest.txt + rpg_summary_latest.txt
and a brief listening report/clip; logs alone cannot establish sound audibility.

After spot queue: Low-End PC Optimization, September28-October4,2026 -> Big Loot
-> Event System -> comprehensive systems audit. At context pressure finish and
preserve the checkpoint, verify its remote result and supply a current-state
handoff for a new conversation; never promise background development.
