# Big Skeleton update

Author-directed design and implementation, extending main
`f0b7a66d0e87c18ad18b45a6449b613b7f8ee11d`. The author explicitly delegates
skeleton design and tuning. Live GDD 00 → 01 → 05/06/07 supplied the existing
event, progression, faction and lifecycle constraints. Google rejected the
revision-guarded amendment; final proposed changes remain in
`validation/BIG_SKELETON_GDD_AMENDMENTS.json`. They are not live-GDD synchronization.

## Frequent Skeleton Blockades

Bribe removal did not unregister Skeleton Blockade. The expanded 28-event
catalog and novelty weighting made it easy to miss. The existing selector now
gives Skeleton Blockade an independent 65% priority draw into its first common
slot. Two completed event-populated dungeons without one force the next
selection to include it. Ordinary selection may also choose it when priority
misses. No extra event slot is created: exact non-exploding 1d4 density,
distinct identities and the rare fourth slot remain intact.

Only successfully completed event populations advance existing campaign
history. Previews, failures and a same-level rebuild do not consume the drought
guarantee. Normal feasibility proofs, required-route placement, barrier death
receipt, ordinary event XP/drops and Bribe retirement are preserved.

In paired deterministic samples across 64 twenty-dungeon campaigns, Skeleton
selection increased from 228/1280 (17.8%) to 833/1280 (65.1%). The longest gap
was two populated dungeons. This is selector evidence, not live-player telemetry.
Twenty natural full-catalog builds succeeded; sixteen actually created a
Skeleton and barrier and passed the independent route/progression proof.

## Fallen players

Every accepted player death in the active dungeon queues a detached snapshot
before life, role and progression retirement. Heroes copy their Hero build;
human Soldiers copy the current Soldier incarnation rather than their saved
Hero. This service has no event-director or event-enabled dependency.

The copy retains identity, class, level, abilities, feats, equipment, known forms
and Contents, native weapons/magazines/reserves, remaining Magic and armor,
maximum HP and movement speed. It rises at full copied maximum HP, using the
stock skeleton model and the copied class color and weapon model. Its new
runtime identity and hostile faction belong to the AI; the original progression
actor type remains intact so Hero defense caps are not replaced by enemy caps.
Nothing aliases the owner's live profile or inventory.

The controller uses shared faction targeting, graph navigation, damage dice,
defenses, status saves, equipment riders, Magic and corpse cleanup. It chooses
usable copied weapons and spells, reloads from its own finite ammunition,
preserves the AR2 burst count/cadence rules and Soldier-only unlimited AR2,
and spends copied Wand charges. All ten ordinary offensive forms are eligible,
including enemy-aligned Summons and Walls. Wizards prefer Magic; other classes
weave Magic into weapon combat. No native player connection or fake player input
is created. This is an exact detached build with an AI action policy: it does
not autonomously open menus, consume bag potions, perform directional equipment
combos, scope weapons, or execute every player-input-only feat. Those require
separate AI behaviors; owning them does not grant invented passive bonuses.

Rattling bones and a violet three-second rise warning announce the consequence.
A red warning precedes attacks. Named Die Logger messages mark the rise and
distinguish defeating your own skeleton from avenging someone else. Copies stay
after owner respawn, disconnect or gear changes. Dungeon reset, completion,
failure and campaign expiry invalidate the body and its delayed attacks.

Death copies grant no XP, loot, currency, DFTs or equipment. Intentional deaths
cannot duplicate rewards. They never own an event barrier or a required key.
Staging, retirement and completed-dungeon deaths are excluded. Defeating an
event Skeleton continues to open its barrier and award ordinary combat rewards.

## Bounds and ownership

- Capture deduplicates the exact player life. Native creation runs after the
  lethal stack, through a 0.25-second service, with two spawn attempts per tick.
- Placement uses the shared supported standing-hull landing proof within a
  twelve-cell traversable search, rejecting sanctuary and locked shortcuts.
  Occupied/unsafe placements retry once per second.
- At most 32 records are retained. Excess oldest copies retire without rewards,
  outside native lethal callbacks. Invalid graph/run/epoch/seed records retire.
- Frozen worlds stop movement and damage, cancel pending attack releases and
  pause the rise countdown. Delayed spells cannot hit from a stale/dead copy.
- Attack warning: 0.65 seconds. Recovery: at least 0.35 seconds (default 0.8)
  divided by the copied rate-of-fire multiplier. Reload delay: 1.5 seconds.
  AR2 projectiles use the existing shared burst count, spacing and recovery.

## Finite native acceptance

Static/headless evidence is in `validation/BIG_SKELETON_UPDATE.md`. Native Source
physics, rendering, actual spells and multiplayer acceptance are still required.
Use the exact published source on local `gm_flatgrass`; keep the established
local acceptance → Workshop parity → matching VPS sequence.

1. First action: `lod_developer_mode 1; lod_event_preview_generate skeleton_blockade`.
   Redeploy, follow the printed locator, defeat the Skeleton, and confirm its
   passage opens once for both Heroes and a late arrival. Test all three classes.
2. With a survivor still deployed, let a Hero die with a known weapon/build.
   Confirm one named copy rises nearby after its warning, uses that weapon and
   its copied spell/gear effects, survives owner respawn and grants no rewards.
   Repeat with a human Soldier and a Wizard using Wall/Summon.
3. Start an events-disabled dungeon (`lod_events_enabled 0` before generating),
   repeat a death, and confirm the copy still rises. Restore events afterward.
   `lod_skeleton_status` reports live/pending copies. Use staging/menu freeze,
   blocked death sites and a dungeon reset to verify safe pause/retry/cleanup.

Capture `console_latest.txt` + `rpg_summary_latest.txt`; add the session log for
ordering failures and screenshots for warning/model defects. No Workshop or VPS
deployment is part of this source update.
