# Active roadmap — author-directed spot updates

## Current checkpoint — SPOT-04 enemy loop-audio cleanup

The September 25, 2026 author-directed [spot queue](briefs/SPOT_UPDATES.md)
precedes the scheduled roadmap. One bullet equals one coherent, independently
validated, non-forced push. High-level design authority is delegated;
existing-feat rebalances remain approval-gated.

SPOT-04 repairs the existing client LoopAudio owner and shared server hostile
sound/death authority. Valid corpses and dormant/retired actors cannot renew
ambience. Beam warning/sweep sound is bound to its exact finite attack and
stopped on cancellation, death, removal and retirement. Reset/rebuild uses the
existing topology build identity, including same-seed regeneration. Native
SND_STOP events pass generation/legacy filters; living loop limits, loudness,
attack cues and intentional one-shot death sounds remain. New sound mutation
stays outside the synchronous lethal-damage stack. The reported missing Manhack
startup path is replaced by the stock charge soundscript, not a new engine loop.

Fresh focused evidence: **74/74 audio lifecycle checks**, **55/55 Razor** and
**44/44 Climber**. The final audio harness against the unchanged parent gives
18 passes/56 failures, including absent new ownership APIs; these are not 56
independent gameplay defects. All 731 Lua files pass syntax. Bounded integration:
**227 passing suites, one unchanged-parent harness failure, and two campaign-wide suites not run** (coverage across the bounded matrix and explicit reruns, not a full 230-suite pass). Failures and unavailable checks remain explicit in
[SPOT-04 validation](validation/SPOT_04_ENEMY_AUDIO.md) and its exact gate receipt.
Headless assertions do not establish audible native playback or silence.

SPOT-03 now has author-observed visibility and basic combat for one controlled
Razor after two placement refusals, not natural exposure or full native
acceptance. Its Occupation/60-roamer session was developer-dense, with no planned
or roaming Razor. **Move on; no further dedicated Razor test is prerequisite.**
See the dated supplement in [SPOT-03 validation](validation/SPOT_03_RAZOR.md).
SPOT-01's separate 50 focused checks also freshly pass; its native two-player
readout and SPOT-02's full native acceptance remain open.

Next ordered development bullet: **SPOT-05 — Die Logger audit**. Audit actual
server events and shared live/history rendering; propose the finite gate before
repairing missing meaningful events or routine Magic-at-100 noise. SPOT-04's
compact native audio gate remains open and does not become a Razor retest.

## Existing release gates — unchanged

Preserve B28 physical-query repairs, B29 safe arrival/graduated opening,
author-approved Crate visuals, and completed P1–P4 optimization/evidence.
B29's historical 42 selected headless passes remain distinct from the fresh
integration results recorded above and from native acceptance. Its safe-arrival,
controlled-departure and inhabited-exploration native checks remain open.

The established sequence remains focused fatal-crash/game-ending-bug repairs,
local playtest/acceptance of the exact candidate, Steam Workshop item 3791535712
publication with package/source parity, then matching VPS deployment with backup,
rollback and service/listing/connectivity checks. This commit does not publish
the Workshop or change/restart the VPS. Obtain local evidence before those gates.

## Scheduled work — unchanged

| Order | Deferred work | Preserved scope |
| --- | --- | --- |
| 1 | Low-End PC Optimization, September 28–October 4, 2026 | Preserve P1–P4; resume measured active-scan profiling. Native dense frame-time/texture-residency acceptance remains pending. |
| 2 | [Big Loot](briefs/BIG_LOOT_UPDATE.md) | Existing meaningful baseline/approximately 3.5× target; preserve inventory, persistence, sell/fuse and wallet transactions. |
| 3 | [Event System](briefs/EVENT_SYSTEM_UPDATE.md) | Existing meaningful baseline/approximately 3.5× target; preserve exactly non-exploding 1d4 count, deterministic ownership, placement and solvability. |
| 4 | Comprehensive systems integration and emergence audit | Generation through encounters, combat/status, equipment/loot, events/rewards, progression/lifecycle/UI; deterministic, transaction and interaction contracts. |

## Checkpoint practice and preserved history

Read AGENTS → this current section → active brief; live GDD 00 → 01 → relevant
subsystem rules only. State the finite scope, implement at the existing authority,
run targeted checks and the available applicable integration gate, and distinguish
fresh, inherited and unavailable validation. Normally the canonical gate is
`python3 tools/test_checkpoint_g_integration.py`. Never substitute a headless pass
for native acceptance. Update player guidance, live GDD, evidence and handoff;
verify pushed source hashes and preserve newer/uncommitted work without force.

The entire previous development plan, including all historical acceptance records,
Crate constraints, detailed roadmap and checkpoint policies, is retained byte for
byte as [the B29 plan archive](history/DEVELOPMENT_PLAN_B29_20f6ecc.md). Only its
old active-queue precedence is superseded by the new author request. Historical
relative paths in that verbatim archive retain their original `docs/` context.
