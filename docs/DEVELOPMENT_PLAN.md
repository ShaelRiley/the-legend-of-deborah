# Active roadmap — author-directed spot updates

## Current checkpoint — SPOT-05 canonical Die Logger audit

The September 25 author-directed [spot queue](briefs/SPOT_UPDATES.md) precedes the
scheduled roadmap. One bullet equals one independently validated, non-forced
push. High-level design authority is delegated; existing-feat rebalances remain
approval-gated. SPOT-05 changes presentation/event reporting, not gameplay balance.

The canonical server stream now removes routine passive Magic/full-cap noise,
restores omitted defense/status/duration/recovery/Morale/HP-growth dice and
meaningful outcomes, and uses one event serial for the union of combat
participants and eligible nearby listeners. Private progression remains private.
Life observers bind exact Hero/run ownership; human Soldiers do not display the
dormant Hero name. Both client views retain identical semantic records and order,
with bounded history and ordered long-dice parts. The GDD's explicit passive-Magic
exception and the canonical manual are reconciled.

Final local evidence: **76/76 focused assertions, 38/38 selected suites,
732 Lua-file syntax**, including manual content/transport and unchanged source
during the gate. Its frozen-tree independent result and published child SHA
belong to the delivery receipt. See [SPOT-05 validation](validation/SPOT_05_DIE_LOGGER.md), the stored
receipt and preserved initial attempts. This is not a full campaign-matrix pass
or native rendering/multiplayer acceptance. B29 uses its recorded-layout runtime
mode; the extra 20-seed exposure sweep is not claimed.

SPOT-04 audio remains implemented and native-unaccepted. Its historical gate is
227 passing suites, one unchanged-parent Color-fixture failure and two omitted
campaign suites, not a full 230-suite pass. Fresh SPOT-05 regressions pass
SPOT-04 74/74, Razor 55/55 and Climber 44/44; the separate SPOT-01 50-check result
is inherited from SPOT-04. Earlier validation records are not rewritten.

Shael's one controlled Razor proves only that instance's visibility/basic combat.
Its Occupation/60-roamer upload was developer-dense, not natural release exposure.
**No dedicated Razor retest or natural sighting is prerequisite.** Collect natural
sightings opportunistically; keep the documented native limits and provenance.

Next ordered development bullet: **SPOT-06 — Gordon phase one**. Read current
Gordon rules and code, define one finite gate, and improve the follow-up-hit
window without infinite loops, teleport cues and contextual taunts. Do not batch
SPOT-07 fakes, SPOT-08 turrets or SPOT-09 Damsel's Revenge into it.

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
