# Wearable and potion drop repair

Development baseline: `astra/equipment-update` at
`963c1c78ca7ae0f60407a4d17346f6b74a8a6fd9`. Remote `main` remains
`8978796e886cdb5505d24ed0de085265fa99bac8`.

## Root cause

`sv_loot_director.lua` contained the current Equipment Update table, but
`sv_loot_campaign_decay.lua` loads later and replaced both `_DropCategory` and
`_SpawnEnemyResult` with the pre-equipment versions. Consequently, normal enemy
loot could become a procedural weapon through later equipment preparation, but
the final runtime category table had no `wearable` or `consumable` entries. Its
spawn call also omitted `equipmentEligible` and the stable hostile equipment
seed, bypassing wearable conversion and the 80% Healing Potion / 20% Stink Bomb
split. Earlier equipment tests loaded the base director without this late
override, so they did not exercise the production authority that failed.

## Repair

- Preserve the current authored 75% ordinary useful-drop probability, 90%
  dry-streak path and guaranteed-useful path through campaign-assistance decay.
- Add fixed relative weights 24 for wearables and 12 for consumables; use weight
  12 times the existing need factor for procedural weapons.
- Send every natural enemy equipment result through `equipmentEligible=true`
  with a stable hostile seed. Natural wearables now generate Cap, Vest,
  Trousers, Boots, Ring, Gloves and Shield records. Consumables now resolve to
  Healing Potions and Stink Bombs through the canonical 80/20 split.
- Validate each prepared reward before `ents.Create`. Contain generator errors,
  reject malformed equipment and consumable records, and use guarded pickup
  labels rather than indexing an unchecked definition.
- Keep pickup entities at native model scale and retain their explicit fixed
  trigger bounds. This removes the remaining cosmetic model-scale mutation from
  the loot creation path implicated by earlier force-close evidence.

The crash protections eliminate identified Lua and native-risk boundaries; they
do not prove the historical native crash's root cause without a fresh Garry's Mod
run.

## Validation

`python3 tools/test_checkpoint_g_integration.py` passes **93/93** suites. The new
final-load-order regression samples Dungeons 1, 6 and 11; proves that wearables,
consumables and procedural weapons remain reachable after assistance decay;
generates every wearable family; observes both potion types; preserves stable
equipment identity; and proves generator or payload failure cannot reach native
entity creation. The pickup-native suite rejects any attempted `SetModelScale`.

## Finite native playtest

Install this development build and start a fresh `gm_flatgrass` campaign. Kill
ordinary enemies until you have collected at least one wearable and one potion.
Open P → Equipment and verify the wearable is in the bag/equippable; equip the
potion in Throwable and confirm its LMB throw / RMB drink prompt (Stink Bomb is
throw-only). Continue through several additional enemy deaths. Acceptance is:
normal wearable and potion drops appear and collect, the game remains open, and
the detailed log advances through `reward_prepare`, `spawn_complete`,
`registered` and `loot_complete` for those drops.
