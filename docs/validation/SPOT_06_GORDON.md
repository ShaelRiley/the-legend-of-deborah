# SPOT-06 — Gordon phase one

## Scope and authority

Recovered September 26, 2026 from the stalled SPOT-06 thread. Actual upstream
parent `664762a55d096c628ed5a2faff6da6c97c16cf03`, tree
`9faba937d888b33079719aa9b20d719fc01fbbd7`. Main was still SPOT-05. A recovery-only
branch produced a full source archive via GitHub run **36256682642**; every tracked
blob, tree, and the original commit object was reconstructed and verified before
editing. It was not a new synthetic upstream anchor. No prior uncommitted SPOT-06
code was available in this checkout. The prior thread's candidate design survives
in live GDD 05/07 and was read, not replaced or duplicated.

[The finite gate](SPOT_06_GORDON_GATE.md) was defined before gameplay changes.
Only `sv_warden.lua`, the narrow ordinary-stun admission seam in
`sv_m3_hit_feedback.lua`, `cl_warden.lua`, canonical manual/renderings, tests and
checkpoint documentation change. No SPOT-07 tells, turrets, Damsel's Revenge,
feat rebalance, new external assets, native force-spawn test or deployment.

## Implemented behavior

The first effective hit during a visible attack appearance or taunt creates a
fixed 1.2-second follow-up deadline, capped by reveal+4 seconds. Later damage
cannot renew it. Pre-hit ordinary stun admission clamps to that available window;
only the existing positive native damage observation opens the window. Hidden or
arriving Gordon cannot be pinned by ordinary hit-stun; damage still applies and
shared Held/Muted/Push remain authoritative. The independent existing Warden
service expires presentation even when outer AI wrappers suppress behavior ticks.

Unreleased shots cancel on interruption. Released orbs/bombs retain their original
record/fuse until ordinary expiry or existing phase/death/reset cancellation.
Three-second invisible physical graph/MotionV2 travel remains, not teleportation.
Departure has a contracting ring and .45-second lifetime. Arrival stops voluntary
travel, fixes a square/chevron warning at the actual position for .45 seconds, and
restarts that complete warning if displaced. The ordinary .65-second visible
attack warning and four-orb scheduling follow it. No catch-up volley is introduced.

Taunts last .8 seconds. A 6-second encounter-wide cooldown admits only one speaker,
and an ordinary attack appearance must occur between taunts. Four-second recent
incoming/outgoing damage context selects “Lucky shot.” / “Too slow.”; an idle
party yields “Still aiming?” and active attack input yields “Keep dancing.”
Positive native damage, not an attempted attack or zero mitigation result, marks
successful outgoing damage. Existing `boss_taunt`, `portal_depart`, `portal_arrive`
Audio events are reused; network snapshots do not play sound.

New phase work and cues bind exact run object, campaign epoch/seed/run ID, dungeon
level/seed, graph, Warden record, actor-state, native owner and phase cycle. Phase
exit, stale ownership, death/removal, failed/cleared/unready world and cleanup
retire work. Freeze/no visible targets cancel presentation without healing or
resetting progression. Two finite cues per actor, ten total, use existing
.2-second snapshots, fixed timestamps/positions, two-second client timeout and
6000-unit culling. Full/reduced effects preserve distinct semantic shapes; no new
client model or per-actor render hook is allocated.

Phases two/three, clone count/HP, sixteen-hazard ceiling, shared RPG damage and
statuses, resupply, native lethal-callback ordering, Gordon→Hector transfer,
Jail Key/rescue, XP and currency remain on their existing authorities.

## Source evidence, not native acceptance

First complete local selected gate: **47/47**, including **116/116 focused
production assertions** and **733 Lua-file syntax checks**. Source-before/after
snapshot was identical:
`c325afaf6aaf1ed0b1bfe832c45433aaca95d0e76bda83ae57e4ef1100e6ef2d`.
That first snapshot predates these documentation receipts; rerun the unchanged
final candidate and independently gate the exact tree before publication. Final
run ID, parent/tree/child SHA and source snapshot belong to the delivery receipt.
The test runner writes per-suite logs/receipts immediately, rejects reuse of a
nonempty output directory, and retains source-before/after hashes. Four workers,
45 seconds per suite. The fixed 47-suite list is in `tools/test_spot06_gate.py`.
B29 uses `--runtime`, not the extra twenty-seed exposure sweep. This is **not a
full campaign-matrix pass**. Prior SPOT-05/SPOT-04 incomplete broader attempts and
all prior native limits remain unchanged.

Focused assertions execute the real Warden, installed hit-stun/hurt-pose wrappers,
actual snapshot encoder/decoder, HUD and geometric render functions. They cover
rapid follow-up hits, exact deadlines, displaced warnings, magic interruption,
phase transitions, all ownership components, no-target/frozen/reset/death paths,
shared taunt admission/context, clone retirement, cue bounds, expiry/culling,
late snapshots and existing model cleanup. Boundary doubles do not emulate the
Source engine, reproduce actual sounds or prove cooperative gameplay feel.

`SPOT_06_ATTEMPTS.txt` preserves actual partial logs. The initial Warden test
expected the retired immediate reveal; after aligning the arrival timing, a
leftover literal Neil-test clock failed. Those are fixture changes, not hidden
production successes. The first focused run lacked a native sequence-method
double. The next run caught a real missing clone-death cue retirement; the death
branch was repaired before the complete 116-assertion and 47-suite passes.

Manual: `docs/manual/book.json` is canonical. `python3 tools/build_manual.py`
regenerated printable HTML and all changed client chunks; both content and
transport tests pass. No PDF or external asset generation is involved.

## Native acceptance remains open

Fully quit/restart GMod rather than mixing protocol/module revisions. During an
ordinary legitimate Gordon encounter, assess the useful first-hit follow-up,
nonrenewal under sustained co-op hits, actual arrival/departure cue readability
and audibility, full/reduced effects, contextual caption timing and combat cadence.
Verify warning displacement under existing Push, shared Held/Muted behavior,
late join, no-target/Tetris waiting, phase changes, clone death and dungeon reset.
Read-only `lod_warden_status` now includes phase-one stage, deadline and cue count;
collect `console_latest.txt` and `rpg_summary_latest.txt` plus a listening/visual
report. A force-spawn test is not required or performed here.

Keep all earlier B29, Crate, audio, Razor/Climber and cooperative native gates.
No dedicated Razor sighting/retest prerequisite. Release remains local acceptance
→ Workshop 3791535712 package/source parity → matching VPS with rollback and
health checks. No Workshop/VPS operation occurs in this checkpoint. Next single
queue bullet is SPOT-07; no future/background execution is implied.
