# Equipment completion assessment — 2026-09-15

Equipment was substantially implemented on `astra/equipment-update`, but was
not finished: its world comparison transport could not carry the complete
procedural item records. This checkpoint repairs that blocker. It does not claim
Garry's Mod runtime acceptance or promote the development branch to main.

Assessment baseline: equipment commit
`6f635257acef2617de15719c1b8dba446b4ccd39`; main
`8978796e886cdb5505d24ed0de085265fa99bac8`. The live GDD revision was unchanged
from the authored LOD-EQUIP-016 checkpoint. Navigation: 00, 01, 90 and the relevant
05 staging/roadmap rules. No game-design values changed.

| Area | Assessment |
|---|---|
| Shared weapon/wearable generation | Present on development branch: 13 families, 60 properties, rarity, variance, actual-effect naming, drawback accounting and depth budgets. |
| Equip and acquisition | Present: occupancy masks, paired gloves, active-weapon contributions, native replacement, ammo preservation, ownership and stored-record restoration. |
| Combat and item actions | Present: shared damage/status/save/element adapters, attack snapshots, Block, Quickstep, Rebuff and Throwable transactions. |
| World pickup comparison | Defective at baseline; repaired here with complete owner-only records and server/client request tests. |
| Automated validation | All 66 integrated suites pass, including the previous 65 and the new inspection test. |
| In-game acceptance | Pending. No fresh GMod engine, multiplayer logs or visual evidence was available. |
| Enemy Update | Not started in this repair checkpoint; Equipment was not complete when assessed. |

## Repaired defect and proof

`SyncPickup` previously serialized the complete item into one `SetNW2String`.
The client parsed that string before showing its comparison. The engine documents
a [511-character value limit](https://wiki.facepunch.com/gmod/Entity:SetNW2String);
the procedural record includes the identity, name, metadata and up to eight
property records. Losing that payload prevents a valid comparison.

The server now replies to an inspection request with the full authoritative item.
Only the nearby owner may receive a current, uncollected, unexpired pickup. The
request contains an entity reference, has a strict bit limit and is throttled.
The client retains the item on the entity object, so a reused entity index does
not inherit an old view. Lost/unavailable responses can be requested again.
No inspection request invokes item generation, equipment mutation or loot collection.

`tools/test_equipment_inspection.lua` runs the actual server and client handlers
with Source/net doubles. It covers full record delivery, ownership, range,
level/expiry/collection guards, oversized requests, rate limits, retry, invalid
records and entity reuse. The full gate also retains generation distribution,
combat, loot, lifecycle, Block, moves, Throwables and accepted RPG regressions.
This is headless evidence, not a native Source networking or visual test.

## Remaining acceptance

Use the installation and playtest in [the economy handoff](PROCEDURAL_ITEM_ECONOMY.md).
On `gm_flatgrass`, deploy a Hero, then run:

```text
lod_equipment_economy_testkit; lod_equipment_economy_status
```

Aim at the D1/D25/D100 comparisons, verify complete names/properties, accept one
with E, and confirm unchanged ammunition. Continue the existing combat,
weapon-switch, Block/move and transition checks. Multiplayer must confirm that
each owner sees their own comparison. Finish with:

```text
lod_equipment_economy_status; lod_rpg_validate; lod_rpg_test_finish equipment_economy
```

Evidence remains `console_latest.txt` and `rpg_summary_latest.txt`; use a screenshot
for any clipped or missing comparison. Main promotion and deployment remain held.

## Enemy intake observation

The live LOD-STAGE-001 requires recurring Hermit gifts. The inspected staging
module implements the one-time starter, but no repeat-gift resolver was found.
This should be reconciled in the Enemy Update's explicitly required remaining
core-feature inventory; it must not be silently counted as completed based on the
GDD's accepted-foundation description. This checkpoint makes no broader claim
that every historical core-game requirement is already present at runtime.
