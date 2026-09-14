# Playtest disconnect repair — 2026-09-14

Parent candidate: `b082e0708a7e523554f58744b93bd27b4086fd4b`,
`hybrid/antigravity`. Shael supplied the console, current session/summary and
DIE-LOGGER history after `Client 0 overflowed reliable channel`.

## Evidence and defect

The final session tick, 1129.785, records one Blast hitting seven targets, killing
five, and awarding ten contribution/killing-blow XP shares. It emits 24 feedback
records (serials 637–660); none has a client receipt acknowledgement before the
disconnect. Prior records were being acknowledged. No gamemode Lua traceback
appears at the disconnect. Startup addon/material warnings are separate evidence.

Each XP award called AdvanceHeroToLevel, whose base and Magic wrapper both called
SyncPlayer, even when the level did not change. Each sync immediately serialized
the whole character sheet plus spellbook: **40 full snapshots in one tick**.
These packets were not counted in the old telemetry.

Replaying the ten logged XP amounts through production progression on a generated
Level-4 Rogue produces 40 packets / approximately **191,380 snapshot bytes** with
the old sender. This estimate models net.WriteTable encoding; it is not a capture
of Shael's exact character or Source wire. Combat packets, NW2/entity changes and
other traffic add to that burst. This is a demonstrated flooding defect consistent
with the observed disconnect, not proof that it was the only contributor.

Facepunch documents the roughly 256 KiB reliable buffer and recommends reducing or
spreading traffic: https://wiki.facepunch.com/gmod/Networking_Usage.

## Repair

- One delivery authority for the existing sheet/book snapshot channels. Repeated
  sync requests coalesce into one latest snapshot per channel per 100 ms window;
  unchanged snapshots are omitted. Snapshot construction is deferred too.
- Gameplay, XP, grants and existing semantic event observers remain synchronous.
  DIE-LOGGER records retain their order, complete text/dice spans, reliability,
  history and audio cues. No gameplay event is coalesced or switched to unreliable.
- The replay now sends one final sheet / approximately **8,322 bytes** with all
  ten awards included; the unchanged book is omitted (~96% snapshot reduction).
- Two fixed cache/pending slots per player; one callback only while work is pending;
  no recurring polling. Deep-copied caches detect nested Soldier-state changes.
  Deferred builders resolve the current actor; disconnect and pre-map-cleanup
  invalidate stale callbacks. Explicit client requests force resync, including
  recovery from a first snapshot sent before client InitPostEntity.
- Corrected a neighboring derived-stat wrapper that omitted `self` when forwarding
  SyncPlayer, skipping the base breadcrumb/Ace readiness synchronization.
- Developer logs now record actual net.BytesWritten for SNAPSHOT_SEND; summaries
  include request/coalescing/dedup/send/byte totals and largest snapshot flush.

## Gate and retest

Live GDD read via 00 → 01 → 06/07: preserve server authority, compact event-driven
snapshots and faithful live/history feedback. No design or tuning law changed;
100 ms is a transport batching window only. Existing client wire schemas remain.

Integrated gate: **53/53 suites**, including project-wide Lua syntax, diff check,
150-entry feat audit with zero blank descriptions, existing feedback/presentation
regressions and the new production snapshot-burst/lifecycle suite. The latter
checks exact XP, immediate level/Form grants, latest state, dedup, explicit resync,
mutable nested state, cleanup, reconnect and recipient isolation.

This is statically validated, **not Source-runtime accepted**. Fully quit GMod,
install the exact replacement SHA, restart on gm_flatgrass and resume normal play.
Emphasize repeated Blast casts into groups (especially multi-kills), then open P/I/L
to check XP/feat/Form state and dice history. Include a death/respawn and reconnect
if practical. Return console_latest.txt and rpg_summary_latest.txt; the new snapshot
section should expose traffic directly. If it disconnects again, also return
rpg_session_latest.txt for timing. Main promotion and live deployment remain gated.
