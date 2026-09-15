# Low-end and distant-player performance checkpoint

2026-09-15. Candidate branch: `astra/equipment-update`. This extends the combined
Equipment, Enemy and recurring-staging candidate; `main` and public deployment
remain unchanged. Authority: live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 06/07, especially bounded state, cached presentation and low-end delivery.
No combat, loot, AI, scoring or other game-balance values change.

## Implemented

- Equipment joins the existing snapshot authority and its 100 ms presentation
  window. One timer per player, one pending builder/cache per registered channel.
  Repeated changes coalesce; identical snapshots produce no packet. Held weapon,
  counts, derived stats, health and transactions still apply immediately.
- The first equipment snapshot is complete. Subsequent reliable, ordered messages
  carry changed items, removed IDs, slots and current metadata. Unchanged item
  rolls remain on the client. Explicit requests invalidate only the equipment
  baseline and send it in full; a client missing its baseline requests recovery.
- Dispatch resolves the current Hero record/role instead of a captured retired
  record. Role changes remove old items; disconnect/map cleanup cancels pending
  work and releases delivery caches. Recipient identity remains server-owned.
- A pickup comparison validates, formats and wraps once per item/snapshot/entity/
  screen-width combination. Only the current layout is retained, and it is cleared
  when leaving the target, opening UI, receiving equipment or cleaning up the map.
  Drawing and range checks still run every frame. Cached colors avoid per-line
  Color allocations. Client delta application copies the item index and shares
  unchanged immutable records instead of reparsing all rolls.
- Derived equipment contributions are aggregated only after the existing equipped
  IDs/active-weapon guard detects change. Item rolls remain immutable; a new roll
  receives a new ID. No new stat-cache invalidation convention was introduced.

## Automated evidence

`python3 tools/test_checkpoint_g_integration.py`: **69/69 suites pass**, including
Lua syntax and all protected regressions. New delivery tests execute the production
server writer and client receiver; Source entities, timers and net are doubled.

| Case | Observed result |
| --- | --- |
| 32 generated Dungeon-999 rings plus potion, 101 Sync calls before flush | One final equipment packet; 19,842 estimated bytes |
| 100 subsequent identical Sync calls | Zero equipment packets |
| Active weapon changes in that inventory | 119 estimated bytes; zero unchanged rolls resent |
| 601 identical pickup HUD frames | One text/layout build; identical drawn text |
| One initial stat refresh plus 100 unchanged Sync calls | One aggregate computation; weapon change recomputes immediately |

Byte counts conservatively model net.WriteTable types/strings/numbers; they exclude
UDP/reliability overhead and are not captured network measurements. The earlier
full-table path resends the inventory for each Sync. The weapon-switch fixture's
payload reduction is about 99.4%; this is not a claim about total game bandwidth.
The capacity fixture is representative, not a proof of the largest legal record.
Actual message bytes continue to be captured by existing `SNAPSHOT_SEND` logging.
The [engine documentation](https://wiki.facepunch.com/gmod/net.WriteTable) describes
typed-table overhead and its 64 KB message buffer.

Tests cover nested count changes, added/removed records, occupancy, latest role and
character state, owner isolation, reconnect, map cleanup, missing-baseline recovery,
explicit full resync without invalidating the character sheet, and comparison
invalidation on each dependency. Existing loot and combat validators remain green.

## Runtime gate and limits

Use the updated combined candidate for the next ordinary `gm_flatgrass` equipment
and enemy playtest. Switch weapons, inspect and replace gear, and return through
staging. Verify inventory names/counts and comparisons remain current after a
reconnect. Preserve `console_latest.txt` and `rpg_summary_latest.txt`; their existing
snapshot logging supplies actual payload sizes alongside errors and gameplay.

No Source runtime, constrained-RAM machine or impaired-network session was available
in this checkpoint. FPS, peak RAM, packet-loss behavior and end-to-end latency are
not measured or runtime-accepted. This removes demonstrated recurring work and
allocation/transport churn; it does not claim lower base asset memory, faster
geographical ping, or completion of every potential renderer/AI optimization.
