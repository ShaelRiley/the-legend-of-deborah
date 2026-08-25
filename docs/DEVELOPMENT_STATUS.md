# Development Status — 2026-08-25 Dice-Era Reconciliation

## Current execution phase

**Gate C8 — Complete-Dungeon Dice-Era Validation.**

This status is reconciled against current GitHub `main`, the live production GDD, and accepted Steam Deck runtime evidence through the Crowbar runtime checkpoint. The older description of the project as waiting to begin the dice-combat foundation is obsolete.

The live GDD remains design authority. GitHub `main` remains implementation authority. Milestone labels describe capability groups; the immediate execution gate is determined by the actual build and accepted runtime evidence.

## Accepted complete-dungeon checkpoint

Gate A is closed unless new regression evidence appears.

Accepted runtime evidence includes:

- three consecutive complete dungeons;
- successful generation and release of Level 4;
- legal Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah progression;
- Deborah touch rescue, level clear, intermission, and next-level generation;
- `lod_m2_seed_test 100` completing 100/100 with zero failures;
- accepted minimap-cache diagnostics and complete canonical breadcrumb routing through cards, gates, stairs, Jail Key, jail door, and Deborah;
- correction of the misleading stair-presentation defect;
- developer H kit granting full health, Crowbar, Pistol, and intentionally infinite developer Pistol ammunition;
- colored progression and rescue state surviving the tested level loop.

Do not reopen this gate without new runtime evidence of regression.

## Accepted v1 dice-combat foundation

The dice foundation is now implemented and has passed subsystem-level runtime checks.

### Combat roll authority and feed

- `sv_combat_rolls.lua` is the server-authoritative roll service for player weapon damage, hostile-originated dice damage, and deterministic hostile health dice.
- `cl_combat_roll_feed.lua` renders the bounded event-driven lower-right feed between ammunition and the minimap.
- Attributed damage entries preserve source, formula, applied total, target, and damage source, e.g. `ShaelRiley dealt 1d4 (3) damage to Shambler, via pistol`.
- Player and monster damage both use the dice-era authority.

### Weapon dice

Implemented v1 rules:

- Crowbar: `1d3`
- Pistol: `1d4`
- SMG: `1d8`
- AR2: `1d10`
- Grenade: `1d20`
- .357 Magnum: exploding `1d12`; natural 10, 11, or 12 recursively explodes
- Shotgun: one shared exploding `1d6`, per-die floor 3, natural 6 explosions, six guaranteed pellets, independent 33% checks for pellets 7/8/9, and one aggregate damage resolution per target

Crowbar runtime contract is accepted: the dedicated LOD Crowbar owns authoritative melee collision/damage, uses a 96-unit player reach, emits an audible miss whoosh, uses the accepted soft body-impact cue on hit, and adds the same local hit-confirm beep used by ranged weapons. The 96-unit reach intentionally gives careful backpedaling/timing only a narrow spacing advantage over variance-scaled ordinary melee enemies.

XP, character levels, procedural affixes/equipment, elements, Magic, and Luck Ring remain deferred post-release systems and are not part of this v1 gate.

### Enemy health dice

Deterministic health dice replace the former independent HP jitter while retaining visible hostile size as a monotonic durability cue.

Current profiles:

- Deadcrab: `2d4+1`
- Runner: `3d4+3`
- Shambler / Soldier / Blitzer: `4d4+5`
- Bio Blaster: `5d4+6`

Accepted diagnostic:

`[LOD:DICE-HEALTH] active=32 diceApplied=32 missing=0 legacyHPJitter=0 clearSizePairs=88 inversions=0 healthRolls=32 result=PASS`

### Finite-ammo economy

`sv_dice_ammo.lua` owns the shared bounded 4 Hz regeneration timer. Combined loaded-plus-reserve caps and one-reload floors are:

- Pistol: cap 54, floor 18, 60-second empty-to-floor recovery
- Shotgun: cap 18, floor 6, 90 seconds
- SMG: cap 135, floor 45, 120 seconds
- AR2: cap 90, floor 30, 150 seconds
- .357: cap 18, floor 6, 180 seconds

Grenades are excluded. The H-key developer Pistol intentionally bypasses the cap.

Accepted diagnostic:

`[LOD:DICE-AMMO] capTotal=54 capExpected=54 cap=PASS regenTotal=1 regenExpected=1 regen=PASS result=PASS`

### Shotgun hit stun

Each damaged target receives one doubled 0.60-second stun per resolved shell, with a 0.66-second retrigger lockout. Pellet-level stuns are suppressed.

Accepted diagnostic:

`[LOD:DICE-SHOTGUN] pelletSuppressed=true shellApplied=true duplicateRejected=true duration=0.60 lockout=0.66 result=PASS`

`durationMultiplier` propagation through both `sv_hostile_hurt_pose.lua` and the final `sv_soldier_shot_contract.lua` wrapper is an accepted invariant. Do not regress Soldier/Blitzer shot cancellation or the immutable Soldier shot contract.

## Telemetry incident and disposition

An automatic dice-run telemetry experiment caused a severe startup regression when its server module was added to the normal gamemode loader: the custom loading screen disappeared and Garry's Mod entered ordinary Sandbox Flatgrass. Removing only that loader restored normal The Legend of Deborah startup in runtime testing.

Repository history proves that the telemetry experiment's surviving footprint consisted only of:

- `sv_dice_run_telemetry.lua`;
- three custom lifecycle `hook.Run` calls in `sv_run_manager.lua`;
- one guarded sampling callback in `sv_dice_ammo.lua`.

No useful Garry's Mod runtime exception was captured, so the exact internal Lua fault is **not proven**. Static syntax success is not sufficient evidence. The safe disposition is therefore complete removal of the failed telemetry experiment rather than speculative repair or automatic re-enablement.

The first dice-era full-dungeon validation uses existing bounded diagnostics, ordinary console/runtime evidence, screenshots, and manual observations. If telemetry is revisited later, it must be a minimal developer-only tool that is explicitly armed after successful gamemode startup and cannot participate in the normal startup path.

## Immediate gate — one complete dice-era dungeon

Before any further enemy-roster breadth, complete and inspect a full dice-era dungeon. Record or observe:

- completion time against the GDD's Level-1 20–35 minute target;
- deaths and remaining lives;
- outgoing and incoming lethality;
- ammunition pressure across progression stages;
- fights that feel excessively slow, cheap, or trivial;
- whether visible hostile size remains a trustworthy durability cue;
- Steam Deck performance and obvious entity/runtime spikes;
- whether the combat-roll feed remains useful rather than noisy;
- successful Deborah rescue, intermission, and next-level release.

Tune only from runtime evidence. Do not optimize expected-value arithmetic in isolation.

## After the dice full-run gate

Once complete-dungeon dice play is accepted, resume remaining roster breadth in the current GDD order:

`Watcher → Seeker → Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper`

Then continue the remaining Milestone-4 expedition work, including production loot/resource systems and the Brute + Neil / Map path, followed by Gordon the Warden in Milestone 5 and dedicated multiplayer integration/testing in Milestone 6.

## Preserved hard constraints

- `gm_flatgrass` is the required base map.
- The canonical generated 3D graph is authoritative for topology, progression legality, routing, minimap interpretation, gates, and stairs.
- Generated physical geometry must agree with that graph.
- Motion V2 remains the sole ordinary hostile ground-movement authority.
- Validated stairs are the sole ordinary elevation-changing route.
- Do not restore retired CLuaLocomotion recovery layers as competing authorities.
- The Soldier warning/projectile contract remains one immutable server-authored world-space origin and direction committed at beam-on; animation bones and client-only visual scaling are not trajectory authorities.
- Preserve compact/chunked networking, cached minimap topology/floor/reachability/routes, bounded ballistic/player queries, generated-geometry cover, the shared hostile registry, client-only visual hostile scaling, bounded death scheduling, and developer-only heavy audits.
- Do not introduce per-frame global BFS or large entity scans.
