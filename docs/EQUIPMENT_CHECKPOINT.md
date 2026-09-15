# Equipment checkpoint: unified procedural economy

Current scope is Shael's 2026-09-15 procedural-weapon/economy expansion under live
GDD LOD-EQUIP-016. [Current rules, integration evidence and one test procedure](PROCEDURAL_ITEM_ECONOMY.md).
All six Hero weapon families and seven wearable families now use the same versioned
generator. It has 60 properties, four to seven benefits plus one drawback, rarity
and quality rolls, dungeon budgets through D999, actual-effect names and shared
combat/status/stat adapters. Older equipment remains readable without rerolling.

The previous checkpoint below is historical: its D100 cap, three-affix limit and
25% wearable conversion are superseded. Its runtime observations are not upgraded
by the new headless results.

## Historical checkpoint: approved initial catalog

Development branch: `astra/equipment-update`.
Baseline remote main: `8978796e886cdb5505d24ed0de085265fa99bac8`.
Previous equipment branch HEAD: `894d22183b2ac851b5c350875567632922e1dfc9`.
Shael approved the proposal on 2026-09-14; live GDD rule LOD-EQUIP-015 records it.

The approved catalog is implemented on the development branch: deterministic
wearables, one value/property economy, atomic hand/glove swaps, real RPG ability
deltas, shared Block after Dodge, simultaneous Quickstep/Rebuff recognition,
keyboard rebinding, and throw-only Stink Bomb using canonical Poisoned.

Implementation checkpoint verified remotely:
`6b790481209e49ec2701ee4830cce404d4372ae4`.
The subsequent finalization commit carries the testkit, manual and final evidence.

## Verification

Final integrated gate: **63/63 suites passed**, with no failures.
Run `python3 tools/test_checkpoint_g_integration.py` from the repository root.
The five new equipment suites cover real catalog generation/derived stats, the
real LootDirector collection transaction, shared Dodge/Block ordering and event
caching, Special Move transactions, and the actual client keyboard adapter.
Existing Throwable/projectile tests now exercise the production Stink Bomb too.
The generator gate tests 2,500 samples over Dungeon Levels 1–999; every initial
property is reachable, ranks/refunds stay bounded, and D100 clamps generation.
All accepted RPG regression and nonblank feat-description suites remain green.

No Garry's Mod engine was available. Prediction, collision feel, native Use,
multiplayer delivery, mounted stock effects and UI/booklet layout still require
human runtime acceptance. No exhaustive new runtime feat certification is claimed.

## Scope and integration

- Headwear, vest, trousers, boots, rings, paired gloves and shield use shared
  property records. Six ability deltas update `equipmentAbilityDelta`; gear does
  not change permanent feat qualification. Block contributes through one shared
  defender roll after Dodge, before Magic diversion and effective-hit observers.
- Budget/value/naming and pickup comparison use the same catalog. Optional
  weapon/cache rewards independently convert at 25%; mandatory starters and the
  outer useful-drop RNG are preserved. A free compatible position auto-equips;
  native E accepts occupied-position replacements. Both displaced rings are
  included in a glove comparison and removed in the committed swap.
- Quickstep and Rebuff listen simultaneously. Duplicate grants expose one move.
  Quickstep changes native movement data and relies on Source collision/gravity;
  it creates no teleport or special Dodge exemption. Rebuff reuses graph-cell
  targeting, shared Magic dice/damage and Push. Existing offensive-cost and
  discrete-Magic-spend feat authorities apply where eligible.
- Healing Potion remains drinkable/throwable. Stink Bomb is throw-only and uses
  shared Poisoned, including normal source/defender CON and recovery. Each cloud
  attempts application once per target, including saved targets. Both forms expire
  across death, retirement, replacement identity, disconnect or dungeon change.
- Stink Bomb is playable through the catalog testkit. Its normal drop frequency
  was not defined in the approved proposal, so ordinary Healing Potion rewards
  were preserved. This is a remaining release-design choice, not an inert effect.
- The booklet gained equipment/Block/move/consumable guidance. This scoped update
  does not certify the broader outstanding RPG manual release reconciliation.
- The initial catalog deliberately excludes additional elemental/property families
  and weapon/magic-item variants pending their own authored rules.

Keyboard source limitation: GLua accepts keyboard codes and excludes native
controller codes. Steam Input/OS software that synthesizes keyboard events is
indistinguishable at this boundary; do not map controller directions to the move
keys. The keyboard range follows the official [KEY enum](https://wiki.facepunch.com/gmod/Enums/KEY).
The dash uses native movement data, consistent with [GMod movement guidance](https://wiki.facepunch.com/gmod/GM:Move).

## One integrated human playtest

Fully quit Garry's Mod. This works whether the local development branch already
exists or is created from its remote tracking branch:

```bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin astra/equipment-update && git switch astra/equipment-update && git pull --ff-only origin astra/equipment-update && bash tools/install_dev.sh
```

Start `gm_flatgrass`, complete staging and deploy as a Hero. Use a physical
keyboard for the move test. Run:

```text
lod_equipment_catalog_testkit; lod_equipment_catalog_status
```

The kit marks the run unranked. It equips generated Quickstep boots, a Rebuff
ring, a second ring and a shield, restores 100 Magic, supplies three of each
consumable, and creates a real individualized glove pickup. The gear is generated
at the D100 budget for inspection; it does not change the actual dungeon level.

1. Before accepting the gloves, try **↑ ↑ ↑** near clear floor and a wall, then
   **← ↓ →** near enemies. Check costs, cooldowns, collision, damage/Push and the
   Die Log. Try the punctuation mirror and a rebind. Menus/chat/Throwable holding
   must prevent recognition. Ordinary weapons, Magic and movement should work.
2. Inspect the glove comparison. It should list both rings. Touching must leave
   them intact; one **E** replaces them. Check updated abilities on **P**, both
   occupied hands on **I**, and disappearance of Rebuff when its ring is replaced.
   Look for Block results/metallic cue/shield flash during ordinary physical combat.
3. In **I → View Equipment**, equip/hold Stink Bomb. Confirm only **LMB: THROW**;
   RMB must not consume. Throw near enemies and observe cloud/CON/Poisoned output.
   Switch to Healing Potion and check drinking, throwing to a second Hero, missing,
   and last-unit Magic restoration. Walls/allies must respect the existing rules.
4. Check death/respawn, next dungeon and reconnect: gear/unspent stacks persist,
   consumed units and accepted pickups do not return, and each Hero remains
   independent. Check Inventory and the new booklet page at Steam Deck resolution.

Finish with:

```text
lod_equipment_catalog_status; lod_rpg_validate; lod_rpg_test_finish equipment_catalog
```

Upload `console_latest.txt` and `rpg_summary_latest.txt` from:

`/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`

Add video for movement, cloud or layout defects; add `rpg_session_latest.txt` only
if detailed event order is needed. Do not rerun the kit during persistence checks,
because replenishment is the kit's explicit purpose.

## Recommendation and release state

Ready for the approved catalog's integrated playtest. Equipment is not yet
runtime-accepted or approved for promotion. Complete that gate and settle the
remaining release-design/catalog scope before starting Enemy implementation.
Main remains the accepted RPG baseline at `8978796e886cdb5505d24ed0de085265fa99bac8`.
Workshop was not updated. Public VPS was not deployed or restarted.

## Earlier checkpoint (historical evidence)

## Throwable consumables

Starting remote main: `8978796e886cdb5505d24ed0de085265fa99bac8`.
Development branch: `astra/equipment-update`.
Implementation commit: `e01d32be5b7fa45b01c06a1d8774966e9ca0e5f8`.
Remote verification: all 36 changed files were expected; no baseline files were
deleted; remote main remained at the starting SHA.

This is a testable partial Equipment checkpoint, not completion of the Equipment
milestone. Main remains the accepted RPG baseline. No Workshop publication,
public VPS deployment or server restart is authorized or performed.

## Implemented

- Character-specific item stacks live inside existing RunManager state.
- Shared slot occupancy supports the seven wearable positions plus Throwable,
  including rings and atomic two-hand occupancy. Production item catalog currently
  contains Healing Potion only; wearable effects/generation are not implemented.
- Inventory + Spellbook exposes equipment and owned-item actions.
- Selecting Hold Throwable activates a dedicated input adapter; it is excluded
  from inventory snapshots. Merely storing a potion does not suppress casting.
- Healing Potion: 25 HP maximum, no overfill/Magic cost, three-unit stack. RMB
  drinks; full-health attempts do not spend a unit. LMB throws a visible bottle
  whose first direct living allied-Hero impact heals; misses/walls/enemies break
  it without healing. No splash or explosion. Cap one live projectile per caster.
- Capability-based drink permission and persistent HUD prompts. Throw-only
  capability is tested with a test-only item; no inert Stink Bomb is shipped.
- Stock grenade reward, random late-dungeon result, static reward, kit and
  inventory-restoration routes removed. Stock weapon/ammo pickups are denied.
- Grenade-derived identity perk/capability entries and ammo-feat wording updated.
- Relevant booklet potion/Magic guidance updated. This is not certification of
  the entire booklet's remaining RPG release reconciliation.

## Persistence and authority

Consumed units are deleted on the server. Unspent stacks survive death, checkpoint
respawn, elimination, same-campaign reconnect and dungeon transition on the
existing Hero record. Soldier control cannot access Hero equipment. New campaign
state starts empty. In-flight bottles expire on death, disconnect, role change,
campaign replacement or dungeon transition; they never create refundable loot.

Magic suppression is derived from a valid selected Throwable and nonempty owned
stack, not a persistent boolean. Switching weapons, unequipping and depletion
restore casting; lifecycle application resets activation. Existing Magic resource
regeneration, progression data and selected Form/Content are retained.

## Grenade references intentionally retained

Defensive rejection/migration checks still spell `weapon_frag` and `Grenade`.
Existing explosion-event caching and aim-origin compatibility code remain for
externally spawned Source projectiles; they grant no weapon or ammunition.
Stock particle/model asset paths containing “grenade”, BOMB Magic Form presentation
and authored enemy explosive hazards are not ordinary grenade acquisition.
Historical regression cases for the explosion cache remain to protect that seam.

## Validation

Executed result: **58/58 integrated suites passed**, including both new equipment
and projectile suites. The two conventional SWEP include adapters added afterward
also passed Lua parsing. No GMod engine test was run.

Run `python3 tools/test_checkpoint_g_integration.py` from the repository root.
The two added suites execute actual shared item/server transaction and projectile
code with bounded GMod doubles. The suite includes Lua parsing, established RPG
regressions and the existing feat inventory/nonblank-description checks.

Headless tests do not certify GMod prediction, SWEP registration, model mounting,
first-person placement, Source trace behavior, real multiplayer networking or UI
layout. This environment has no running GMod engine. Human runtime acceptance is
still required. Full RPG feat behavior is covered only to the extent established
by the existing finite suites; this checkpoint does not claim a new exhaustive
runtime certification of every feat.

## Human playtest

Fully quit GMod. On the Steam Deck:

```bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin astra/equipment-update && git switch --track origin/astra/equipment-update && bash tools/install_dev.sh
```

For subsequent pulls on this already-created branch:

```bash
cd ~/Downloads/the-legend-of-deborah && git pull --ff-only origin astra/equipment-update && bash tools/install_dev.sh
```

Start `gm_flatgrass`, complete staging and deploy as a Hero. Then run:

```text
lod_equipment_testkit; lod_equipment_status
```

The kit marks the run unranked, sets HP to half maximum, fills three Healing
Potions and holds the Throwable. Check the persistent prompt; drink once; switch
to a firearm and cast the selected spell. Use I → View Equipment → Hold Throwable
to return. Throw into a wall, then spend the final unit and verify normal Magic
returns. A second Hero should receive direct thrown healing; walls, enemies and
human Soldiers should not. Check ordinary death/respawn and next-dungeon/reconnect
retention without stack refill, and confirm both players' inventories remain
independent. Inspect I, the held bottle and prompt at Steam Deck resolution.

Return `console_latest.txt` and `rpg_summary_latest.txt` using the normal exporter
in `docs/TEST_LOGGING.md`; include video for projectile or HUD presentation defects.

## Remaining blocker / recommendation

Do not proceed to Enemy Update as though Equipment were complete. The procedural
property/value/naming economy, real wearable effects and comparisons, shared Block,
Special Move catalog/runtime and Stink Bomb effect remain outstanding. The GDD
leaves essential rules unset and prohibits inventing them. Review
`docs/EQUIPMENT_DESIGN_PROPOSAL.md` to authorize a concrete initial design tranche.
