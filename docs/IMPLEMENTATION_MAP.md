# Implementation Map — 2026-08-25 Dice-Era Reconciliation

The live GDD defines intended design; GitHub `main` defines current implementation.

| Responsibility | Current implementation / status |
|---|---|
| Campaign/level seeds, lives, inventory, respawn, transitions | `gamemode/lod/sv_run_manager.lua`, `sv_campaign_restart.lua`, `sv_respawn_hud.lua`, `gamemode/shared.lua` |
| Canonical 3D maze graph / validation | `sv_maze_generator.lua`, `sv_graph_integrity.lua` |
| Generated geometry / walls / floors / stairs | `sv_maze_builder*.lua`, `sv_wall_visuals.lua`, `sv_ground_perimeter_seals.lua`, `sv_m1_stair_geometry.lua`, `entities/entities/lod_static_box/` |
| Red/Blue/Yellow progression, Jail Key, jail door, Deborah | `sv_progression_director.lua`, `sv_m2_progression_safety.lua`, `sv_progression_builder.lua`, progression entities |
| Encounter planning / wandering population | `sv_encounter_director.lua`, `sv_encounter_spawn_variance.lua`, `sv_wandering_director.lua`, `sv_hostile_separation.lua` |
| Sole production hostile ground motion | `sv_hostile_motion_v2.lua` |
| Core hostile state machine | `entities/entities/lod_hostile/` |
| Deadcrab / Bio Blaster | `sv_deadcrab.lua`, `sv_bioblaster.lua`, projectile entities |
| Soldier/Blitzer immutable warning/projectile contract | `sv_soldier_shot_contract.lua`, `cl_soldier_shot_contract.lua`, `entities/entities/lod_soldier_bolt/` |
| Enemy size/stat variance + monotonic durability | `sv_enemy_variance.lua`, `sv_combat_rolls.lua` |
| Narrowed Shambler/Runner melee dice | `sv_enemy_melee_dice_balance.lua` |
| Generated-cover LOS / bullet authority | `sv_generated_geometry_ballistics.lua` |
| Server-authoritative combat dice / combat feed | `sv_combat_rolls.lua`, `cl_combat_roll_feed.lua` |
| Crowbar | `entities/weapons/weapon_lod_crowbar/`: `1d3`, 96-unit reach, miss/hit audio and hit-confirm |
| SMG overheat + AR2 laser/burst | `sv_player_weapon_specials.lua`, `sv_player_weapon_specials_input.lua`, client mirror |
| Equal firearm acquisition / ammo weighting / AR2 one-unit burst economy | `sv_firearm_economy_equalization.lua` |
| Magnum multi-hostile penetration | `sv_magnum_piercing.lua`; post-body segments revalidate against generated/world collision |
| Shotgun 5–6 explosion + 4× shell stun | `sv_shotgun_identity_balance.lua`, `sv_m3_hit_feedback.lua` |
| Generic collision-safe pushback + `1d3` wall crush | `sv_pushback.lua` |
| Shotgun 168-unit shell push | `sv_shotgun_pushback.lua` |
| Finite ammo caps / regeneration floor | `sv_dice_ammo.lua`; shared 4 Hz server timer |
| Production individualized LootDirector | `sv_loot_director.lua`, `sv_loot_context_rules.lua`, `sv_loot_catchup.lua`, `sv_loot_budget_validation.lua`, loot pickup entity |
| Hit confirm / hurt-death presentation / combat audio | `sv_m3_hit_feedback.lua`, `cl_hit_confirm.lua`, `sv_hostile_hurt_pose.lua`, `sv_hostile_death_pose.lua`, `sv_hostile_death_audio.lua`, `sv_combat_audio.lua` |
| HUD / minimap | `cl_hud.lua`, `sv_minimap*.lua`, `cl_minimap*.lua` |
| Low-end runtime optimization | `sv_phase_zero_runtime_optimization.lua` plus bounded/cached work in motion, minimap, ballistics, loot, projectiles, death systems |
| Automatic dice-run telemetry | **Retired; not loaded.** Use existing diagnostics + manual runtime evidence. |
| Remaining expanded normal roster | Blocked until complete-dungeon dice balance gate passes |
| Brute + Neil / production Map acquisition | Remaining Milestone 4 work |
| Gordon the Warden | Milestone 5 |
| Dedicated multiplayer integration / QA | Milestone 6 |

## Current weapon contracts

- Crowbar: `1d3`, 96-unit reach.
- Pistol: `1d4`.
- SMG: `1d8`, six-shot heat threshold, 0.25 s per heat cooling, 2.0 s overheat lock.
- AR2: `1d10` per projectile, 0.45 s committed laser tell, exactly three projectiles, **one AR2 ammo unit per complete burst**.
- .357 Magnum: exploding `1d12` on natural 10/11/12; **one cartridge; penetrates aligned hostiles with the same resolved shot total** until blocked.
- Shotgun: shared `1d6`, floor 3, natural **5 or 6** recursively explodes, six guaranteed pellets + independent 33% checks for 7/8/9, one aggregate resolution per target, **4× ordinary hit stun**, **168-unit nominal push**.
- Grenade: `1d20`, separate consumable reward.

## Firearm availability contract

Shotgun, SMG, Magnum, and AR2 are peer firearms rather than rarity tiers.

- all available from Dungeon 1;
- equal weighting in randomized firearm acquisition;
- Level 1 guarantees two distinct uniformly selected upgrades from the four;
- join-in-progress catch-up grants two deterministic distinct guns from the same four;
- contextual ammo-family selection is driven by depletion, not weapon-tier scarcity;
- Grenades remain separate consumables.

## Hostile health / ordinary melee

Health:
- Deadcrab `2d4+1`
- Runner `3d4+3`
- Shambler/Soldier/Blitzer `4d4+5`
- Bio Blaster `5d4+6`

Ordinary melee before existing size/stat scaling:
- Shambler `3d4+8`
- Runner `2d4+2`

## Ammo profiles

- Pistol 54 cap / 18 floor / 60 s
- Shotgun 18 / 6 / 90 s
- SMG 135 / 45 / 120 s
- AR2 90 / 30 / 150 s
- .357 18 / 6 / 180 s

Grenades do not regenerate.

## Retired architectures that must not silently return

- CLuaLocomotion recovery layers as competing ground-motion authorities.
- animation-bone reconstruction as Soldier trajectory authority.
- independent HP jitter on top of health dice.
- weapon power-tier rarity gating for Shotgun/SMG/Magnum/AR2.
- HL2 suit/armor as a production LOD resource pool.
- unbounded generic state/network payloads, global BFS/entity scans, or automatic startup telemetry.
