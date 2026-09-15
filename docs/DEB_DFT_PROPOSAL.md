# $DEB and Debbie Fund Tokens — implementation proposal

Status: **all proposed defaults accepted by the author on 2026-09-15**.
The replacement rules are recorded in the live GDD, principally LOD-ECON-001.
The wallet/DFT implementation and Wizard balance changes are on the combined
`astra/equipment-update` candidate. See [implementation and validation](CRYPTO_CHECKPOINT.md).
In-game acceptance and promotion to `main` remain pending.

The approved $DEB and item-backed **Debbie Fund Tokens** supersede the older
six-currency and cosmetic-DFT rules. Transferable sponsored assets remain deferred.

## Accepted requirements

- A server-owned CryptoDirector and wallet keyed to the stable Steam account.
  $DEB and lifetime score survive death, new Heroes, campaign resets and ordinary
  server restarts. This is internal game currency with no external wallet or cash.
- Cooperative participants all receive a share; greater team contribution earns
  more. Lifetime gameplay score remains visible separately from the wallet balance.
- One DFT milestone at each of Levels 1, 5, 10 and 20, once per account per server.
  Selling a milestone token never makes that milestone eligible again.
- At most eight owned DFTs. Additional DFTs are very rare ordinary gameplay drops.
- Each DFT preserves a complete generated item record, including its name,
  properties, numerical rolls, generation version and provenance.
- In staging, press the actual +use binding (normally E) at a Debbie statue to
  inspect the collection, recreate a token's item once per run, or sell the token
  for $DEB to free its slot. Recreating does not consume the DFT.
- Return through the shared hut between every successful maze. The Hermit issues
  the starter firearm once; later visits give one stored ordinary drop, without
  another firearm. The HEROES OF LEGEND board sits beside the mirror and matches
  its 64 × 132 world-unit surface.

## Approved defaults

| Decision | Approved implementation |
| --- | --- |
| Reward pool and settlement | Preserve the existing GDD pool of **100 × Dungeon Level** units and successful-rescue settlement. Failed rescues pay nothing for that dungeon. Use $DEB exclusively. |
| Cooperative allocation | Divide **50% equally** among eligible cooperative accounts and **50% by contribution**. Contribution = effective enemy HP damage + effective healing of another Hero's hostile-caused HP loss. Exclude overkill, overhealing, self/friendly/environmental damage loops, and extra credit for touching Deborah. If total contribution is zero, divide that portion equally too. Use deterministic integer apportionment so allocations sum to the pool. |
| Human Soldiers | Preserve the separate GDD rescue-gated mercenary accounting: 11% per qualifying Hero elimination, collectively capped at 33%, split by attributable contribution. An account that switches roles cannot claim both pools. Apply the cooperative 50/50 split to the remaining Hero pool. |
| DFT milestone meaning | Interpret 1/5/10/20 as **Hero Combat Levels**. Award when first reached in normal play, including Level 1. Human-Soldier reincarnations do not remint them. |
| What a new DFT contains | Mint a new item from the existing procedural generator at the earning dungeon's depth. Freeze that complete item immediately; it does not copy or confiscate an existing equipped item. |
| Rare DFT drop | **1 in 1,000** eligible ordinary enemy-drop opportunities per participating account, in a separate deterministic reward stream; no Boom, drop-chance feat or repeated death callback can reroll it. |
| Full collection | Never exceed eight. An earned milestone freezes immediately as a persistent pending entitlement until a slot opens. A rare world token stays uncollected when full; no automatic sale or replacement. |
| Recreation | Free, once **per DFT per campaign RunID**, not once per maze. Recreate the exact frozen stats into a new run-owned item identity through normal inventory/equipment admission. A full inventory or failed grant does not consume the entitlement. |
| Selling | Permanently remove the DFT and credit **its existing Equipment.Value in $DEB**, one-for-one. Sale proceeds change wallet balance but do not inflate the separate lifetime gameplay score. |
| Test/cheat provenance | Progression-affecting unranked test runs do not mint persistent currency or milestone/rare DFTs. Sales and recreation are also disabled in unranked gameplay; automated tests use an isolated SQLite store. |

These defaults keep the existing procedural equipment generator and item-value
catalog authoritative. No new item stat, affix, combat bonus, or item-scaling curve
is required for DFT recreation.

## Persistence and implementation contract

Use one server-local transactional account store with an immutable reward ledger.
Every rescue settlement, milestone award, rare token source, sale and recreation
has a stable unique identifier. Idempotency checks and balance/collection changes
commit atomically; a corrupt profile fails visibly rather than silently resetting
an account. No client supplies balances, contribution totals, item payloads, sale
prices or eligibility.

Statue transactions validate account ownership, live Hero role, staging state,
current run, actual statue proximity/LOS, inventory capacity and request rate.
Store the entire versioned item snapshot, not merely a seed that would reroll after
an equipment-generator update. Preserve pending grants across retriable failures.
Expose WALLET through the existing player-menu navigation and open that same pane
from the statue; show balance, lifetime score, milestone status, all eight slots,
item details, provenance, sale value and per-run recreation availability.

Finite acceptance: earn a rescue allocation with two differently contributing
Heroes; prove both receive $DEB and the greater contributor receives more; restart
the server; reconnect and verify balances and DFT records; attempt duplicate
settlement, milestone, sale and recreation; test a full collection/inventory; enter
a later maze via staging and a new run to verify the appropriate resets. Retain
all current equipment, perk, enemy and RPG regression suites.

## Completed accompanying repairs

- AdvanceLevel clears deployment completion before next-maze generation; it
  retains each identity's starter claim and existing life-revival rules.
- Later Hermit visits resolve once through the standard LootDirector category and
  reward authority, then store the gift payload. Reconnects respawn that payload;
  collecting it marks the visit claimed. Firearm categories become ordinary ammo;
  if no ammo family can accept any, a standard healing potion prevents an empty,
  rerollable promised gift. The original first-starter flow remains intact.
- The leaderboard uses a 64 × 132 world-unit panel, top-aligned with the mirror,
  offset beside it with a positive frame gap. Pagination fits the taller panel.

The accompanying staging/Hermit/board repairs remain intact. The combined build
now passes all 72 integrated automated suites, including SQLite persistence and
rollback, wallet controls, Wizard-only Summon and starting Content. These are
headless checks, not Source runtime acceptance; see the current checkpoint.
