# Equipment checkpoint: Throwable consumables

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
