# $DEB / Debbie Fund Token checkpoint — 2026-09-15

Candidate: `astra/equipment-update`, based on remote `302d177e2e1b99cc5a41b425f7e6b25af8b26726`.
`main` remains `8978796e886cdb5505d24ed0de085265fa99bac8`. This is a test-branch
implementation, not a main promotion, public deployment or Source acceptance.

## Authority

The author explicitly accepted every default in [the proposal](DEB_DFT_PROPOSAL.md).
The live [GDD](https://docs.google.com/document/d/1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY/edit)
was updated in 01/02/03/06 and the corresponding HUMAN rules. LOD-ECON-001 governs
wallets/DFTs; LOD-FORM-001 and the Wizard class rules govern starting Content and
Summon. Normalized 03 and 06 were read back after the update.

## Implemented behavior

- Successful rescue settles `100 × Dungeon Level` $DEB. After the Soldier share,
  Heroes split half equally and half by effective enemy HP damage plus actual
  healing of another Hero's hostile-caused HP loss. Zero contribution splits
  equally. Integer largest-remainder allocation has stable account ties.
- Each qualifying life-consuming Hero death reserves another 11%, capped at 33%,
  for human Soldiers. One contribution unit per consumed life is split by their
  effective damage during that life. Later deaths still affect that split.
  Switching into Soldier forfeits the account's Hero share for that dungeon.
  Eliminated/disconnected eligible Heroes keep their earned participation.
- Stable SteamID64 wallets retain balance and a separate lifetime gameplay score.
  Rescue earnings increase both; DFT sales increase balance only.
- Hero Combat Levels 1/5/10/20 each mint one DFT once per account on this server.
  Its complete procedural weapon/wearable record is generated at the earning
  dungeon depth and frozen immediately. A full eight-token collection retains
  milestone records pending; selling promotes the oldest milestone without reroll.
- The existing once-only enemy loot handoff rolls an independent deterministic
  1/1,000 DFT opportunity per eligible Hero. Full collections leave rare pickups
  uncollected, subject to ordinary world-loot lifetime and entity caps.
- The Debbie statue in the recurring staging hut opens WALLET with Use (normally
  E). Player-menu navigation opens the same pane. It displays all eight slots,
  frozen attributes, provenance/value, milestone state and recent transactions.
- Recreate and equip for free once per DFT per campaign RunID. The token persists;
  the new run-owned item preserves its frozen rolls. Normal inventory admission
  and replacement rules apply. Sale permanently removes a token for Equipment.Value.
- Ownership, current staging/run, live Hero role, distance, line of sight and
  request rate are checked on the server. Client messages contain an action and
  token ID, never equipment records, prices, contribution or balances. Unranked
  gameplay cannot change persistent currency/tokens or use recreation.
- Wizards gain one free distinct deterministic Content when selected at Combat
  Level 1, in addition to the existing 4/8/14 grants. Summon costs 12 before
  Content surcharges and is restricted to Wizards at grant, selection, feat
  eligibility and cast authorities. Legacy non-Wizard Summon ownership converts
  once to an eligible unowned Form, when one remains.

## Persistence and performance

`sv_crypto_store.lua` uses Garry's Mod's server SQLite database. Account records,
immutable event ledger and per-account history commit in one transaction. A
persistent autoincrement sequence gives campaigns unique IDs across restarts.
Keep that server database with normal backups; replacing it loses this server's
wallet history. No external crypto service or private wallet keys are involved.

Failures roll back account/ledger writes. Failed recreation restores inventory,
weapons/ammunition and HP before allowing retry. A failed rescue settlement holds
advancement and retries at most once per second. Corrupt account records produce
visible errors and remain untouched. Persistence covers committed transactions;
an outage followed by server termination before rescue settlement cannot guarantee
an uncommitted reward will survive.

Contribution accounting runs on damage/healing/lifecycle events, with no new player
polling loop. Wallet snapshots use the existing bounded presentation queue and
only query the current account and eight recent history rows. Full frozen records
are sent only to that player's pane; existing equipment deltas remain intact.

## Verification

`python3 tools/test_checkpoint_g_integration.py`: **72/72 pass**, including all
prior equipment, perk, enemy, progression, lifecycle and performance regressions.

New checks execute production Lua with Source boundary doubles:

- Real SQLite connection reopen, store reload, unique campaign IDs, idempotent
  payouts and SQL fault injection; multi-account rollback holds advancement until
  successful retry. Corrupt data is not silently reset.
- Overkill/healing exclusions, Soldier life attribution and role changes;
  frozen milestone/pending records, eight-slot capacity, same/new-run recreation,
  real equipment admission failures, engine-state compensation and sale/score separation.
- 10,000 rare opportunities plus deterministic replay; repeated death handoff
  produces only one opportunity. Statue distance/LOS/role checks and oversized,
  rate-limited and foreign-token network requests are rejected.
- 300 progression seeds across all classes; non-Wizards cannot acquire Summon even
  after exhausting their Form catalog; starting Content is distinct/idempotent.
- Production Wallet client: eight slots, ID-only requests, sale confirmation,
  availability buttons, navigation at 640px, and no focus theft by late snapshots.

These do not measure actual Source rendering, physics, live SQL bindings, network
latency or full server-process restart behavior.

## One combined runtime gate

Play the existing Equipment/Enemy candidate normally on `gm_flatgrass` with two
Heroes contributing differently. At staging, use the Debbie statue, recreate a
DFT and inspect its frozen item. Rescue Deborah, verify both Heroes receive $DEB
and the greater contributor receives more, then return through staging before the
next maze. The same DFT must remain used until a new campaign. Verify a sale frees
a slot without changing lifetime score. After an ordinary server restart, check
that balances, milestones and frozen records persist. A new Wizard should own one
Content immediately; non-Wizards must never see/use Summon.

Retain `console_latest.txt` and `rpg_summary_latest.txt` from the normal data
directory; use a screenshot for statue/pane layout issues. No extra promotion or
deployment is implied by this test. Broader Instruction Booklet reconciliation and
the existing RPG release gates remain separate pre-deployment work.
