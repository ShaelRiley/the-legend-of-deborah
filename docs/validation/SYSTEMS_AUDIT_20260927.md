# Systems audit — September 27, 2026

The author's current request promotes the comprehensive systems audit ahead of
historical deferrals and authorizes improvements. Baseline: main
`4e7d67bee1a5ccecc08e3741f9ecbbbc822dbc73`. Preserve current gameplay, accepted
Crate assets, B28/B29 and all SPOT/September 27 repairs. Native local acceptance,
Workshop parity, then matching VPS remains the release sequence.

## Confirmed repairs

- **Minimap topology:** the server cached only campaign epoch, level and seed.
  A same-seed replacement could therefore resend a retired layout after the
  client correctly invalidated it. Cache ownership now includes the exact weakly
  referenced graph and existing topology build serial. Retired graphs remain
  collectible.
- **Map request amplification:** repeated client requests synchronously resent the
  complete map without a bound. The existing receiver now sends immediately,
  coalesces further requests into one 0.35-second recovery callback per player,
  and resolves current topology at dispatch. Malformed oversized requests and
  disconnected work cannot send. No map entitlement or geometry rule changes.
- **Map resource/lifecycle:** map-open drain and movement benefits could outlive
  their Magic pool, body or dungeon. Sessions now bind exact pool/run/graph,
  campaign epoch, run ID, level/seed and spawn serial. Stale sessions cannot debit
  a replacement pool, retain a movement bonus or suppress regeneration. The
  existing service retires them; a fresh open can bind the current owner.
- **Muted versus potion input:** the generic spell lock stripped RMB even when
  the owned Throwable used it to drink. It now preserves the nonspell Throwable
  action. Spells still obey the existing Muted authority. The actual input,
  SecondaryAttack, inventory debit, healing and status cure path is exercised.
- **Inventory synchronization:** equip, unequip and discard receivers no longer
  recompute/synchronize twice before returning through their shared final sync.

## Design and evidence

Read the exact live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, following
00, 01 and normalized tabs 02–07. Relevant rules: Magic capacity remains 100;
map-open suppression precedes regeneration; statuses, inventory ownership and
player lifecycle retain their existing authorities. Exact HUMAN Muted paragraph
347712–349110 at the retrieved revision defines a spell lock and explicitly
preserves nonspell Magic consumers and passive defenses. No balance/formula,
content expansion or live design amendment was needed.

Both new minimap cases and the extended eight-transition map-life regression
failed on the baseline at the intended assertions, then passed on the repair.
The Muted/potion production regression likewise failed before and passed after.
Targeted map, status, equipment, snapshot/unread and B14 Magic-resource checks
passed. Raw pre-repair failures are retained in the external audit evidence.
Final complete-matrix and publication results belong in the audit closeout.

Engine networking, native input/physics, rendering and human co-op acceptance are
not established by these headless tests. No Workshop or VPS deployment has
occurred. Focused local observation: drink a Healing Potion while Muted, and
reopen the map after a same-seed rebuild/respawn; retain existing stair, stomp,
arrow-input, faction/Reckless and Soldier release acceptance checks.
