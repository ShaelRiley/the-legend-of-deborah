# Equipment access, capacity and Debbie exchange

Author-directed continuation from `cace700324ceda5372de81468928c7a4ab91ef1b`
on `main`. Live GDD 06 UI/economy rules govern the shared menu, server-local
wallet and token accounting; the current author direction supersedes the old
decorative minimum grid rows and extends exchanges to carried/equipped gear.

## Changes

- O uses the same PlayerButtonDown, PlayerBindPress fallback, focused-page router
  and debounced toggle approach as P/I. Removed the extra prediction and blanket
  keyboard-focus gates that prevented Equipment access. The embedded booklet now
  forwards O and the rebound key through its restricted navigation bridge too. Console/chat/text entry
  retain their input. `lod_equipment` and `lod_equipment_key` remain rebindable.
- The admission authority exposes its stored-equipment count to the inventory.
  The existing 32-record cap includes equipped gear; only actual vacancies get
  empty tiles. Consumable stacks have a separately labelled area with their own
  limits. Equipping gear does not manufacture a free storage slot.
- Debbie opens Carried Equipment, with a separate DFTs — Recreate / Sell page.
  Drag or click ordinary gear into/out of an exchange pile, choose Sell or Fuse,
  review quantity/value, then confirm. Equipped items are labelled and may be
  exchanged. The prepared inventory removes their slot references only on a
  successful database commit. Failed transactions retain equipment and wallet.
- Requests send IDs and a response correlation number, never prices or payloads.
  The server rechecks ownership, eligibility and statue access. Pending actions
  reject double confirmation; stale responses cannot complete another request.
  The UI preserves scroll positions and pressed/dragged panels during snapshots.
  Late packets never reopen a closed menu. A bounded response timeout requests
  fresh state without guessing that an exchange succeeded.
- DFT recreations are explicitly excluded at item admission, in addition to the
  existing token provenance and legacy recreated-ID checks. They remain visible
  with an explanation and cannot enter a pile. Server validation rejects even
  mixed ordinary/DFT piles atomically. Selling the actual persistent token remains
  a separate, permanent operation; it cannot make its recreated equipment sellable.

## Retained tuning and lifecycle

Sale uses canonical Equipment.Value, one-for-one $DEB, without lifetime-score
inflation. Up to eight inputs; fusion requires at least two and returns one valid
procedural item worth 85–100% of combined value. Unsupported combinations fail
without consumption. No rescue payout change, new assets, dependencies, recurring
server work or deployment. Per-owner snapshots and the existing rate-limited,
synchronous SQLite ledger remain authoritative. Generated manual synchronized.

## Verification

All 114 suites in `python3 -u tools/test_checkpoint_g_integration.py` pass,
including Lua syntax, canonical manual checks and protected regressions.
Focused production-path tests cover native-event input/fallback and false
single-player prediction; exact full/one-free inventory capacity; independent
consumable limits; real drag/drop/click piles and return drops; selection cap;
DFT disabled state; ID-only requests; response correlation; duplicate submit;
drag/scroll preservation; narrow/normal layouts; SQLite failure rollback with
equipped gear; equipped sale/fusion; real DFT recreations across campaigns;
legacy exclusion; mixed-pile rejection; private denial response; and existing
multiplayer ownership/replay isolation. `git diff --check` is clean.

Headless tests do not establish native GMod acceptance. In one ordinary ranked
staging session, switch among P/I/O and Wallet, inspect a full bag, then use Debbie
to sell ordinary equipment and fuse two pieces by dragging into the pile. Check
wallet credit/new inventory item, clear pending state, and comfortable text/drop
targets at the target resolution. Recreate a DFT and verify its equipment stays
disabled for both actions even after unequipping it. Repeat with a second player
to confirm each receives only their own inventory/wallet changes.
