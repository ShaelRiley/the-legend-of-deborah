# Active roadmap — author-directed spot updates

## Current checkpoint — SPOT-02 Climber junction traversal

The September 25, 2026 author-directed [spot queue](briefs/SPOT_UPDATES.md)
precedes the existing scheduled roadmap. One bullet equals one coherent,
independently validated, non-forced push. High-level design decisions are
delegated; existing-feat rebalances remain explicitly approval-gated.

SPOT-02 repairs reproduced Climber wall-route discontinuity at four-way junctions
and permanent return-to-wall stalls after a leap/latch ends in such a cell.
Route-only clear junction connectors never become spawn/attachment lanes.
Pursuit and recovery retain the same swept movement, graph, gates, leash and
B29 sanctuary checks. A release-safe admin diagnostic separates current
composition, dormant units, living actors, placement counters and movement state.
No population, motif, attack, damage, loot or balance change is included.

Fresh focused validation: 44/44 production-module checks; the same final harness
against the original module gives 25 passes/19 failures, including absent new
diagnostics. Both Lua files pass syntax loading under Lua 5.4. Full integration,
native Source collision/presentation and release sightings were not run. This
repairs demonstrated navigation failures; it does not establish that they were
the sole cause of the author's reported absence. Climber remains directed-only
in Hunting Grounds. Live GDD 05/07 and HUMAN Climber placement were consulted;
the existing geometry-valid traversal contract is repaired, not redesigned.

Evidence and finite native gate: [SPOT-02 validation](validation/SPOT_02_CLIMBER.md).
Next development action: **SPOT-03, diagnose and repair absent Manhack types**.
SPOT-01 remains implemented with its inherited 50 focused passes, not rerun in
this checkpoint; native two-player target-readout acceptance is still pending.
Other queue bullets are not implemented or accepted by SPOT-02.

## Existing release gates — unchanged

Preserve B28 physical-query repairs, B29 safe arrival/graduated opening,
author-approved Crate visuals, and completed P1–P4 optimization/evidence.
B29 has 42 selected headless passes recorded in its earlier checkpoint, not
native acceptance and not a fresh result from this spot update. Its safe-arrival,
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
