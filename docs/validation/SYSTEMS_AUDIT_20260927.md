# Systems audit — September 27, 2026

The author's current request promotes the comprehensive systems audit ahead of
historical deferrals and authorizes improvements. Baseline: main
`4e7d67bee1a5ccecc08e3741f9ecbbbc822dbc73`. Preserve current gameplay, accepted
Crate assets, B28/B29 and all SPOT/September 27 repairs. Native local acceptance,
Workshop parity, then matching VPS remains the release sequence.

## Final result

**262/262 automated suites pass, including syntax checks for all 765 Lua files.**
The complete gate ran on the exact tree published as
`864cdf36854c3671926a9473221c74b7ca727fa5` (tree
`b7ae56adce42bac90a02499ead3acfb86da1eb05`). Before/after source-manifest SHA-256
is identical: `fb88666c43fcfc7a252785ff9fb7d9707377a96fc461235f640c6fd1dca76750`.
The subsequent closeout changes documentation only. Remote publication was
verified; no forced branch update or deployment was used.

| Run | Result |
| --- | --- |
| Original main, original matrix | 228/235; seven pre-existing validation failures. |
| Gameplay fixes, expanded matrix, attempt 1 | 254/262; the same seven plus the newly invalid synthetic map fixture. |
| Reconciled validation, expanded matrix, attempt 2 | **262/262**, zero timeouts/failures, source unchanged. |

The passing gate includes the 640-dungeon wandering-ecology campaign, complete
encounter campaign coverage, 584 literal include/asset paths, current 136 ordinary
feats plus 6 fallbacks/9 capstones, and the 50-case target-identity contract.
Raw baseline, failed and final outputs, per-suite receipts and full source hash
manifests are preserved in `LOD_SYSTEMS_AUDIT_20260927_EVIDENCE.zip`.
No contradictory automated result remains open. Native acceptance remains open.

Reproduce from the checkout with a new evidence directory outside it:

```sh
python3 tools/test_checkpoint_g_integration.py --workers 4 --suite-timeout 1200 --output ../lod-audit-evidence
```

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
Gameplay repair checkpoint: `c0c911ad2b0a4466f2dfaec6342ba517df6f0866`, verified
on remote main. Its tree is `3adbd956a58c9c5e8e79dfe5c9f9a88dd9820685`.

## Validation-system repairs

The first complete expanded run finished **254/262**, with identical before/after
source digest `0c9e2eedcd48109d1984d66984d533a3373714c380a4720c2f7bb2cfcf6bb38c`.
All eight failed suite logs are preserved. Seven reproduce on original main; one
used an unowned synthetic map session invalidated by this audit's lifecycle fix.
No failing suite was removed from the matrix to obtain a green result.

| Failure | Reconciliation |
| --- | --- |
| Locked Chest reward stream; final loot mix | Include the approved SPOT-09 Revenge reservation after Keys; retain every earlier deterministic outcome, assert natural Revenge availability, and account for its 1/16 share of remaining potion opportunities. No drop rule changed. |
| Old refresh UI test | Retain its spell availability assertions. The existing 50-case SPOT-01 target-identity suite now supplies the current two-line/Soldier contract in the complete matrix, replacing obsolete three-line expectations. |
| Checkpoint E Soldier fixture | Implement native clip mutation/weapon selection in the boundary double and assert the current zero-ammo Pulse Rifle contract. All prior lifecycle/parity checks remain. |
| Winning Personality and protected RPG validator | Correct the shared diagnostic's negative-CHA expected multiplier from 1.22 to 1.10. Exact current HUMAN Academic Achievement row 581632–582573 confirms clamp(1 + 0.10 × effective modifier, 0.50, 2.00); gameplay calculation was already correct. |
| Feat inventory release gate | Add Time Management from current normalized tab 04, with revision/anchor provenance. Preserve the older base extraction's identity; label the check as a fixture audit, not an online fetch. |
| SPOT-10 map suppression fixture | Enter/close maps through the real server receiver; assert admitted player ownership and no AI minimap entitlement. Haste and map still debit independently. |

The matrix now executes recent SPOT/faction checks that were previously only
syntax-listed, plus target identity, minimap transport, Muted potion, manual
catalog, Workshop packaging and deployment/rollback tool tests. It contains 262
unique commands, supports bounded workers and per-suite timeouts, retains raw
outputs/exit codes/hashes, and rejects source changes during the gate. The complete
rerun and targeted repaired checks now pass; see the final result above.

## Audit coverage and limits

| System boundary | Automated evidence |
| --- | --- |
| Dungeon generation, navigation, geometry, opening safety | Full production builds, B28/B29, hull queries, standing stairs, wandering/encounter campaigns and topology ownership. |
| Combat, Magic, statuses, feats, equipment | Shared damage/faction authority, sealed attacks, Soldier/Reckless, costs/regeneration, potions, stomp, input recipes and all retained feat regressions. |
| Campaign, progression and multiplayer lifecycle | Hero/Soldier transitions, clock/Time Management, bosses/rescue, identity, late joins, snapshots, stale callbacks and exact-life ownership. |
| Events, loot and persistence | Event claims, staged inventory operations, real SQLite transactions, duplicate settlement/recovery and wallet/DFT invariants. |
| Client presentation and transport | UI contracts, unread/drag epochs, semantic die feed, spell availability, minimap encoding/request bursts, audio/assets and manual parity. |
| Build and release tooling | Lua syntax, literal include/asset wiring, source-manifest integrity, packaging and deploy/rollback simulations. |

This is a source/automated systems audit, not a claim that every possible native
play sequence is bug-free. The serial baseline matrix completed at 228/235. Its unsuccessful stop attempt
and status corrections remain in the raw log; it is not represented as a pass.

Engine networking, native input/physics, rendering and human co-op acceptance are
not established by these headless tests. No Workshop or VPS deployment has
occurred. Focused local observation: drink a Healing Potion while Muted, and
reopen the map after a same-seed rebuild/respawn; retain existing stair, stomp,
arrow-input, faction/Reckless and Soldier release acceptance checks.
