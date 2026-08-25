# Implementation Map — 2026-08-25 Dice-Era Reconciliation

This file maps the current production architecture. The live GDD defines intended design; GitHub `main` defines what is actually implemented.

| Responsibility | Current implementation / status |
|---|---|
| Campaign/level seeds, campaign state, character/life/inventory/session state, regeneration/transitions | `gamemode/lod/sv_run_manager.lua`, `sv_campaign_restart.lua`, `sv_respawn_hud.lua` |
| Central tuning / models / encounter and progression constants | `gamemode/lod/sh_config.lua`, `sv_m3_enemy_config.lua` |
| Deterministic RNG/substreams | `gamemode/lod/sh_rng.lua` |
| Canonical 3D maze graph, occupancy, loops, vertical transitions, generation validation | `gamemode/lod/sv_maze_generator.lua`, `sv_graph_integrity.lua` |
| Generated maze geometry, walls, floors, stairs, underdeck/perimeter sealing | `sv_maze_builder*.lua`, `sv_wall_visuals.lua`, `sv_ground_perimeter_seals.lua`, `sv_m1_stair_geometry.lua`, `entities/entities/lod_static_box/` |
| Ordered Red/Blue/Yellow progression, checkpoints, Jail Key, jail door, Deborah rescue | `gamemode/lod/sv_progression_director.lua`, `sv_m2_progression_safety.lua`, `sv_progression_builder.lua`, `entities/entities/lod_keycard/`, `lod_gate/`, `lod_jail_key/`, `lod_jail_door/`, `lod_deborah/` |
| Logical hostile routing | `gamemode/lod/sv_maze_navigator.lua` |
| Hostile target/faction authority | `gamemode/lod/sv_faction_manager.lua` |
| Encounter planning/activation | `gamemode/lod/sv_encounter_director.lua`, `sv_encounter_spawn_variance.lua`, `sv_m3_run_integration.lua` |
| Persistent wandering population / spacing | `sv_wandering_director.lua`, `sv_hostile_separation.lua` |
| Sole production ground-motion kernel | `gamemode/lod/sv_hostile_motion_v2.lua` |
| Core hostile entity/state machine | `entities/entities/lod_hostile/` |
| Deadcrab / Bio Blaster specializations | `gamemode/lod/sv_deadcrab.lua`, `sv_bioblaster.lua`, `entities/entities/lod_bio_bolt/` |
| Soldier/Blitzer warning and projectile truth | `gamemode/lod/sv_soldier_shot_contract.lua`, `cl_soldier_shot_contract.lua`, `entities/entities/lod_soldier_bolt/` |
| Per-instance hostile size/stat variance and size/durability resolution | `gamemode/lod/sv_enemy_variance.lua` plus health contracts from `sv_combat_rolls.lua` |
| Generated-cover LOS/ballistics and projectile collision safety | `sv_generated_geometry_ballistics.lua`, projectile entities |
| Server-authoritative player/hostile combat dice | `gamemode/lod/sv_combat_rolls.lua` |
| Authoritative player melee / Crowbar | `entities/weapons/weapon_lod_crowbar/`; accepted `1d3`, 96-unit reach, miss whoosh, soft impact, and ranged-style hit-confirm beep |
| Deterministic hostile health dice | `gamemode/lod/sv_combat_rolls.lua`, resolved through `sv_enemy_variance.lua` so visible size remains monotonic with durability |
| Bounded lower-right combat-roll feed | `gamemode/lod/cl_combat_roll_feed.lua`, fed only by authoritative resolved server events |
| Finite firearm caps and one-reload regeneration floor | `gamemode/lod/sv_dice_ammo.lua`; one shared 4 Hz server timer |
| Player firearm hit fallback / hit confirmation | `sv_hostile_combat_hulls.lua`, `sv_m3_hit_feedback.lua`, `cl_hit_confirm.lua` |
| Ordinary and Shotgun hit stun | `sv_m3_hit_feedback.lua`; duration propagation preserved through `sv_hostile_hurt_pose.lua` and final `sv_soldier_shot_contract.lua` wrappers |
| Hostile hurt/death presentation and combat audio | `sv_hostile_hurt_pose.lua`, `sv_hostile_death_pose.lua`, `sv_hostile_death_audio.lua`, `sv_combat_audio.lua` |
| Source-style run HUD | `gamemode/lod/cl_hud.lua` |
| Server-authoritative map entitlement / compact topology serialization | `sv_minimap.lua`, `sv_minimap_canonical.lua`, `sv_minimap_safety.lua` |
| Client minimap, origin sync, floor/reachability/breadcrumb caches | `cl_minimap.lua`, `cl_minimap_origin_sync.lua`, `cl_minimap_safety.lua` |
| Low-end hot-path reductions / bounded runtime work | `gamemode/lod/sv_phase_zero_runtime_optimization.lua` plus cached/bounded logic in motion, minimap, projectile, and death systems |
| Production geometry/traversal audits | `sv_maze_geometry_audit.lua`, `sv_vertical_transition_audit.lua`, `sv_m3_ground_probe.lua`, `sv_m3_damage_audit.lua` |
| Heavy developer-only test surface | `sv_debug_tools.lua`, `sv_m1_floor_support.lua`, `sv_m1_traversal.lua`, `sv_m2_debug.lua`, `sv_m2_seed_test_incremental.lua`, `sv_m3_debug.lua`, `sv_m3_testkit_qol.lua`, `sv_m3_roster_debug.lua`, `cl_dev_testing.lua`, `cl_debug.lua` |
| Automatic dice-run telemetry | **Not part of production or developer startup. Failed experiment retired after startup regression.** First full-run validation uses existing diagnostics plus manual runtime evidence. |
| LootDirector / individualized production loot | Remaining Milestone 4 work; not yet implementation authority |
| Remaining expanded normal roster | Deferred until the complete-dungeon dice balance gate passes |
| Brute + Neil / production Map acquisition | Remaining Milestone 4 work |
| Gordon the Warden / production Jail Key source / final rescue presentation | Milestone 5; must reuse the already-proven Jail Key/jail-door/Deborah pipeline |
| Dedicated multiplayer integration / multiplayer-specific QA | Milestone 6 |

## Accepted dice contracts

### Weapon families

- Crowbar `1d3`, 96-unit player melee reach
- Pistol `1d4`
- SMG `1d8`
- AR2 `1d10`
- Grenade `1d20`
- .357 Magnum `1d12`, recursively exploding on natural 10/11/12
- Shotgun: shared exploding `1d6`, floor 3 on every die, natural 6 explosion, six guaranteed pellets plus independent 33% checks for pellets 7/8/9, aggregate once per target

### Health profiles

- Deadcrab `2d4+1`
- Runner `3d4+3`
- Shambler/Soldier/Blitzer `4d4+5`
- Bio Blaster `5d4+6`

Independent legacy HP jitter is disabled once health dice apply.

### Ammo profiles

- Pistol 54 cap / 18 floor / 60 s empty-to-floor
- Shotgun 18 / 6 / 90 s
- SMG 135 / 45 / 120 s
- AR2 90 / 30 / 150 s
- .357 18 / 6 / 180 s

Grenades do not regenerate. The developer infinite Pistol is an intentional testkit bypass.

### Shotgun stun

One 0.60-second stun per damaged target per shell with 0.66-second retrigger lockout. Never apply a separate doubled stun per pellet.

## Retired architectures that must not silently return

- Source `CLuaLocomotion:Approach` plus layered recovery systems as competing hostile movement authorities.
- Live animation-bone reconstruction as Soldier trajectory authority.
- Independent legacy HP jitter layered on top of enemy health dice.
- Large unbounded generic state payloads when compact/chunked state is sufficient.
- Per-frame global BFS/entity scans where cached/bounded implementations already removed them.
- Automatic dice-run telemetry in the normal gamemode loader. Any future telemetry must be explicitly developer-armed after successful startup.
