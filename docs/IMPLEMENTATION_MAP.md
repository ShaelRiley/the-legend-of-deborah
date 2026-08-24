# Implementation map

This file maps the current production architecture, not the original milestone placeholders.

| Responsibility | Current implementation |
|---|---|
| Campaign/level seeds, campaign state, character/life/inventory/session state, regeneration/transitions | `gamemode/lod/sv_run_manager.lua`, `sv_campaign_restart.lua`, `sv_respawn_hud.lua` |
| Central tuning / models / encounter and progression constants | `gamemode/lod/sh_config.lua`, `sv_m3_enemy_config.lua` |
| Deterministic RNG/substreams | `gamemode/lod/sh_rng.lua` |
| Canonical 3D maze graph, occupancy, loops, vertical transitions, generation validation | `gamemode/lod/sv_maze_generator.lua`, `sv_graph_integrity.lua` |
| Generated maze geometry, walls, floors, stairs, underdeck/perimeter sealing | `sv_maze_builder*.lua`, `sv_wall_visuals.lua`, `sv_ground_perimeter_seals.lua`, `sv_m1_stair_geometry.lua`, `entities/entities/lod_static_box/` |
| Ordered Red/Blue/Yellow progression, keycards, checkpoints, current objective, provisional Deborah clear | `gamemode/lod/sv_progression_director.lua`, `sv_m2_progression_safety.lua`, `sv_progression_builder.lua`, `entities/entities/lod_keycard/`, `lod_gate/`, `lod_deborah/` |
| Logical hostile routing | `gamemode/lod/sv_maze_navigator.lua` |
| Hostile target/faction authority | `gamemode/lod/sv_faction_manager.lua` |
| Encounter planning/activation | `gamemode/lod/sv_encounter_director.lua`, `sv_encounter_spawn_variance.lua`, `sv_m3_run_integration.lua` |
| Persistent wandering population / spacing | `sv_wandering_director.lua`, `sv_hostile_separation.lua` |
| Sole production ground-motion kernel | `gamemode/lod/sv_hostile_motion_v2.lua` |
| Core hostile entity/state machine | `entities/entities/lod_hostile/` |
| Deadcrab / Bio Blaster specializations | `gamemode/lod/sv_deadcrab.lua`, `sv_bioblaster.lua`, `entities/entities/lod_bio_bolt/` |
| Soldier/Blitzer warning and projectile truth | `gamemode/lod/sv_soldier_shot_contract.lua`, `cl_soldier_shot_contract.lua`, `entities/entities/lod_soldier_bolt/` |
| Per-instance hostile size/stat variance | `gamemode/lod/sv_enemy_variance.lua` |
| Generated-cover LOS/ballistics and projectile collision safety | `sv_generated_geometry_ballistics.lua`, projectile entities |
| Player firearm hit fallback / hit confirm / hit stun | `sv_hostile_combat_hulls.lua`, `sv_m3_hit_feedback.lua`, `cl_hit_confirm.lua` |
| Hostile hurt/death presentation and combat audio | `sv_hostile_hurt_pose.lua`, `sv_hostile_death_pose.lua`, `sv_hostile_death_audio.lua`, `sv_combat_audio.lua` |
| Source-style run HUD | `gamemode/lod/cl_hud.lua` |
| Server-authoritative map entitlement / compact topology serialization | `sv_minimap.lua`, `sv_minimap_canonical.lua`, `sv_minimap_safety.lua` |
| Client minimap, origin sync, reachability cache | `cl_minimap.lua`, `cl_minimap_origin_sync.lua`, `cl_minimap_safety.lua` |
| Low-end hot-path reductions / bounded runtime work | `gamemode/lod/sv_phase_zero_runtime_optimization.lua` plus cached/bounded logic in the motion, minimap, projectile, and death systems |
| Production geometry/traversal audits | `sv_maze_geometry_audit.lua`, `sv_vertical_transition_audit.lua`, `sv_m3_ground_probe.lua`, `sv_m3_damage_audit.lua` |
| Heavy developer-only test surface | `sv_debug_tools.lua`, `sv_m1_floor_support.lua`, `sv_m1_traversal.lua`, `sv_m2_debug.lua`, `sv_m2_seed_test_incremental.lua`, `sv_m3_debug.lua`, `sv_m3_testkit_qol.lua`, `sv_m3_roster_debug.lua`, `cl_dev_testing.lua`, `cl_debug.lua` |
| LootDirector / individualized production loot | Milestone 4; not yet the current implementation authority |
| Dice-combat foundation | Next major system after the complete-dungeon integration gate; GDD now assigns this to v1 Milestone 4 |
| Gordon the Warden / production Jail Key source / final rescue presentation | Milestone 5 |
| Dedicated multiplayer integration / multiplayer-specific QA | Milestone 6 |

## Retired architectures that must not silently return

- Source `CLuaLocomotion:Approach` plus layered recovery systems as competing hostile movement authorities.
- Live client/server animation-bone reconstruction as Soldier trajectory authority.
- Large unbounded generic state payloads when compact/chunked state is sufficient.
- Per-frame global BFS/entity scans where the current cached/bounded implementations already removed them.
