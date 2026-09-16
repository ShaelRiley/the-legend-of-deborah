# Unified procedural equipment economy

Authored 2026-09-15 under Shael's explicit request to invent and implement the missing economy formulas. Live GDD rule LOD-EQUIP-016 supersedes the initial LOD-EQUIP-015 catalog limits, conversion rate and scaling formula; its Block, Throwable, input and Special Move laws remain intact. This document records implementation and validation; the live GDD remains design authority.

## Generation and value

All Hero weapons (Pistol, Crowbar, Shotgun, SMG, Revolver, Pulse Rifle) and all seven wearable families use generator version 2. Existing version 1 items keep their original effects and value. Potions, ammunition and other resource pickups retain their resource rules; they are not permanent equipment.

Each item has one elemental affinity, four to seven positive properties, and exactly one drawback. A weapon also always has a hit rider. No duplicate property or opposing benefit/drawback on the same mechanic is allowed. An elemental ward and weakness of the same type are incompatible. All items are generated on demand from independent deterministic generation/name streams. Their full source identity includes campaign, dungeon, owner and reward identity/serial; hash collisions cannot alias item ownership. Stored rewards and owned items never reroll on inspection, reconnect or restore. New runs use their campaign seed and run epoch; replaying a complete saved generation context intentionally reproduces its items. Reusing only a world seed may reproduce geometry while the new run epoch gives fresh loot.

Let D = clamp(floor(DungeonLevel), 1, 999). Base budget B = 100 + floor(12 sqrt(D−1) + 4 log2(D)). Multiply B by 2 for paired gloves, otherwise 1; by the rarity factor; and by integer quality Q/100 where Q is uniform 90..110. Floor once to get the item budget. Dungeon depth is independent of Hero Level; power continues growing past 20 and through 999, then safely clamps. Generation remains available beyond the cap. Random later items need not dominate earlier build-specific gear.

| Rarity | Probability | Budget factor | Positive properties |
|---|---:|---:|---:|
| Unusual | 65% | 1.00 | 4 |
| Rare | 25% | 1.20 | 5 |
| Exalted | 9% | 1.45 | 6 |
| Legendary | 1% | 1.75 | 7 |

Each scalable positive starts with 6 power points; fixed grants cost their authored price. Pick compatible properties uniformly without replacement. The drawback gets floor(Budget × U/100) power, U uniform 10..20, or its fixed price. Refund is min(drawback power, floor(0.20 × Budget)). Distribute all remaining positive power proportionally to independent integer weights 100..1000, flooring each share and assigning rounding residue to the first scalable property. Value = positive power − capped drawback refund, exactly the item budget. Value is an approximate comparison, not a promise of build superiority; no sell/buy currency or vendor is introduced.

For scalable properties with maximum M and half-power H, magnitude = round(M × power/(H+power), precision), with a minimum of one precision step. Apply a negative sign for drawbacks. This saturating curve gives stronger rolled stats at larger budgets while bounding individual properties. One item may combine combat, defense, utility and conditional properties. A limited finite catalog permits a very large combination space, not a mathematical guarantee that an effect combination never repeats.

## Property catalog and exact weights

| Property | M | H | Precision | Drawback allowed |
|---|---:|---:|---:|---|
| Each STR/DEX/CON/INT/WIS/CHA score | 12 | 100 | 1 point | Yes |
| Each of six condition-save bonuses | 6 | 100 | 1 point | Yes |
| Physical or Magic damage | 60% | 80 | 0.1% | Yes |
| Movement | 25% | 100 | 0.1% | Yes |
| Dodge contribution | 20 percentage points | 150 | 0.1 | No |
| Physical damage reduction | 25% | 120 | 0.1% | Yes |
| Health regeneration ceiling | 50 percentage points | 100 | 0.1 | No |
| Health or Magic regeneration rate | 100% | 80 | 0.1% | Yes |
| Outgoing Push distance / incoming Push reduction | 50% | 80 | 0.1% | Yes |
| Map drain reduction | 35% | 80 | 0.1% | Yes |
| Summon lifetime | 50% | 100 | 0.1% | Yes |
| Conditional damage (injured physical, stationary physical, charged Magic) | 50% | 80 | 0.1% | Yes |
| Breadcrumb distance | 12 cells | 80 | 1 cell | No |
| Shield Block contribution | 33 percentage points | 120 | 0.1 | No |
| Each elemental damage affinity | 50% | 80 | 0.1% | No |
| Each hit-rider application chance | 25% | 100 | 0.1% | No |

Fixed properties: +1 summon cap costs 45; each elemental resistance costs 25; each elemental weakness drawback costs 15; Quickstep costs 20 and remains Boots-only; Rebuff costs 30 and remains Ring-only. All other listed properties are legal on weapons and wearables except Shield-only Block. No Magic-capacity property exists.

Elements: Earth, Fire, Dark, Ice, Light, Electric. Each item rolls exactly one affinity. A weapon's affinity types its entire ordinary physical hit without turning it into a spell or adding a second damage event; matching affinity bonuses on all active gear increase that typed hit. Wearable affinities also increase matching explicitly typed Magic. Wintery is the flavor adjective for Ice, not a seventh element. A weapon always has at least one of ten rider families: Clumsy, Immolated, Poisoned, Bleeding, Muted, Held, Reckless, Arcane Shattered, Intimidated/Morale, Push. Other equipment may also grant those riders.

Names: thematic provenance (Deborah's, Neil's, Hermit's, Wayfarer's, Dockworker's, Warden's, Pilgrim's, Cartographer's), actual affinity adjective, family noun, and “of” the first actual rider or another positive effect plus a second actual positive effect. Provenance does not imply literal NPC ownership. Full descriptions disclose every property, penalty, chance, condition, element, rarity, depth, value, move recipe/cost/cooldown and active-weapon restriction. Charm means CHA score, not an invented mind-control status.

## Runtime composition and safeguards

Wearable contributions are always active while equipped; only the currently held weapon contributes. One stored procedural record per weapon family accompanies the existing engine weapon. Holstered guns never stack stats. Paired gloves contribute once. Swapping equipment updates effective stats through the shared progression authority, never intrinsic scores or feat qualification, and never heals by changing MaxHP.

Gear aggregation caps (apply to the sum before composing with existing class/feat laws): physical/Magic damage −35..+75%; movement −25..+35%; physical damage reduction −35..+35%; matching elemental damage 0..+50%; condition-save bonus −6..+6 per ability; health/Magic regen rate −50..+100%; outgoing Push −50..+50%; incoming Push reduction −50..+50%; map drain reduction −35..+35%; summon lifetime −50..+50%; each conditional damage contribution −35..+50%; each status/Push chance 0..35%. Health-regeneration ceiling contribution caps at +60 percentage points and final ceiling at 100% MaxHP. An item ceiling enables the canonical five-second damage-free regeneration scheduler at its existing 1%-MaxHP-per-second baseline; rate alone grants no new regeneration. Summon gear adds at most 2 active slots to the existing feat cap (total at most 6). Breadcrumbs preserve the shared 2..24-cell cap. Dodge and Block retain their absolute caps and shared single-roll authorities.

Physical and Magic bonuses multiply their already authored corresponding damage stage, not raw dice. Physical defense applies before Dodge, Block and HP-to-Magic diversion; it excludes environmental, status, aura and reactive damage. Gear saves add through ConditionSave and the canonical Morale save; STR contributes to the existing shared Push save. These are bonuses to the original roll, not second saving throws. Gear elemental weaknesses/resistances participate in the existing single ladder selection: weakness takes precedence, matching gear resistance permits one same-element resistance ladder, never stacked copies. Typed physical hits remain eligible for Block.

Conditional states are sampled when an attack is committed: injured means HP ≤ 50% MaxHP, stationary means horizontal speed <5 units/s, charged means Magic ≥75. Weapon identity, active contributions and source state are sealed into its attack contract so swapping weapons during delayed shotgun settlement or Magnum penetration cannot change the attack. Gear does not alter dice counts, explosion rules, shot cadence, ammunition costs/caps or hit geometry.

On actual positive HP damage to a surviving hostile by a direct Hero weapon attack, consider each active rider in a deterministically shuffled order. Roll its capped chance once per target per committed attack; at most two successful chance rolls may attempt riders. Successful chance is an application attempt, not a failed save: use the shared status catalog, normal immunity/save/duration/reapply rules; Intimidated uses AttemptMorale and Push uses the ordinary 96-unit physical Push contest. Block/Dodge/fully diverted/filtered hits, misses, corpse hits, status ticks, spells, summons, aura, reactive, self and friendly damage produce no equipment riders. No immediate extra damage event is spawned by a rider. Chance rolls and application outcomes appear in the shared Die Log. Event deduplication is weakly held and lifecycle-bound.

## Acquisition, persistence and comparison

All Hero weapon issuance becomes procedural, including loadout pistol/crowbar, Hermit starter, individualized drops, direct scripted grants, and restored legacy inventory. A missing legacy item record is created once and retained; an existing record survives weapon-entity replacement. Soldier incarnations keep their separately authored weapons/progression.

On a natural optional weapon/cache opportunity, 35% becomes a wearable and 65% remains a procedural weapon opportunity. Mandatory weapon opportunities preserve the requested family. Same-family weapon drops are real variant comparisons rather than silently becoming ammunition. Free slots auto-equip; occupied slots require native E acceptance; replacing a weapon preserves its current magazine/reserve rather than refilling it. A failed engine grant leaves the old equipment and pickup intact. Restoring, viewing or declining never rolls a replacement. Existing individualized loot ownership, consumed-reward ledger, transition rules and source drop cadence remain authoritative. Optional Healing Potion rewards split 80% Healing Potion / 20% Stink Bomb; mandatory sustain is preserved. No old grenade is reintroduced.

Inventory bounds: at most 32 stored permanent equipment records, plus the two finite consumable stacks. Replacing occupied slots is permitted at capacity; a free-slot acquisition is rejected before any engine grant when full. The inventory provides Discard for owned, unequipped wearables. Equipped items and weapons cannot be discarded through that action. Item IDs are at most 220 characters; equipment requests cap at 4,096 bits and retain the existing per-player rate limit. A dropped/missing engine gun with an existing record is not a fresh magazine entitlement. Optional weapon rewards continue selecting a variant when all firearm families are owned.

Pickup comparison records travel in an owner-only net message requested while nearby. They do not use NW2String, whose 511-character value limit cannot carry a complete procedural item. The server checks owner, range, current level, collection/expiry and action eligibility; requests accept only the entity field and are rate-limited. The client caches the full record on the entity object and retries after a missing response. Inspecting never generates or acquires equipment.

## Verification status

Development branch: `astra/equipment-update`; parent checkpoint `3951f0a681deca7679cb4a6a715e3c43263ab476`.
Main remains `8978796e886cdb5505d24ed0de085265fa99bac8`.

Live GDD: [The Legend of Deborah — Garry's Mod Game Design Document](https://docs.google.com/document/d/1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY).
Navigation used 00/01, 02/03/07/90; new author-directed rule 016 is mirrored into HUMAN and indexed in 01/07.

Implemented on the development branch and statically/headlessly validated. The integrated gate has 66 suites, including the complete previous 63 regression suites, two economy suites and the pickup inspection transport suite. Run `python3 tools/test_checkpoint_g_integration.py`.

The distribution gate validates 16,000 items, reachability of all 60 properties, version-1 retention, signed-value integrity, every family, glove occupancy and depth scaling. Among 10,000 D20 revolvers it found zero duplicate mechanical property/magnitude combinations (names and IDs excluded); observed rarity counts were 6,490 / 2,515 / 892 / 103. This is sample evidence, not a uniqueness guarantee. Mean budget per single-slot opportunity at D1/D20/D21/D100/D500/D999 was 109.53 / 184.81 / 187.04 / 268.19 / 441.42 / 567.55.

The production integration gate executes real LootDirector collection and weapon-Give paths, first acquisition, native acceptance, failed grant, ammo-preserving replacement, restoration, six-family issuance, active-only contribution, shared progression/save/element/summon-cap composition, firearm contract creation, burst/pierce snapshots, Magic separation, and real Held application/save/nonstack/lifecycle checks. Source entities, transport and selected die outcomes are bounded test doubles. These tests do not establish Garry's Mod runtime acceptance.

### Finite human playtest

Quit Garry's Mod, then update and install the development branch:

```bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin astra/equipment-update && git switch astra/equipment-update && git pull --ff-only origin astra/equipment-update && bash tools/install_dev.sh
```

Launch `gm_flatgrass`, deploy a Hero and run:

```text
lod_equipment_economy_testkit; lod_equipment_economy_status
```

This marks the run unranked, equips six procedural weapons and representative wearables, and places D1/D25/D100 revolver comparisons nearby without changing the dungeon. Fire and switch weapons; inspect the actual modifiers in I; accept one comparison with E. Confirm names/readability, changing active stats, unchanged ammo on replacement, elemental/status outcomes, shared Block and existing moves. On the next ordinary death/dungeon transition verify the same item names/properties remain. Multiplayer still needs native ownership/transmission confirmation.

Finish with:

```text
lod_equipment_economy_status; lod_rpg_validate; lod_rpg_test_finish equipment_economy
```

Evidence: `console_latest.txt` and `rpg_summary_latest.txt` from `/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`. Use `rpg_session_latest.txt` if rider order needs diagnosis. No Garry's Mod engine was available here; feel, native UI layout and multiplayer runtime acceptance remain pending. No main promotion, Workshop upload or VPS deployment is included.
