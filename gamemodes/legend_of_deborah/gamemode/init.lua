AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("lod/sh_config.lua")
AddCSLuaFile("lod/sh_rng.lua")
AddCSLuaFile("lod/cl_textured_box.lua")
AddCSLuaFile("lod/cl_wall_visuals.lua")
AddCSLuaFile("lod/cl_debug.lua")
AddCSLuaFile("lod/cl_hud.lua")
AddCSLuaFile("lod/cl_magic_hud.lua")
AddCSLuaFile("lod/cl_dev_testing.lua")
AddCSLuaFile("lod/cl_hit_confirm.lua")
AddCSLuaFile("lod/cl_combat_roll_feed.lua")
AddCSLuaFile("lod/cl_minimap.lua")
AddCSLuaFile("lod/cl_soldier_shot_contract.lua")
AddCSLuaFile("lod/cl_player_weapon_specials.lua")
AddCSLuaFile("lod/cl_magnum_aim_state.lua")
AddCSLuaFile("lod/cl_watcher.lua")
AddCSLuaFile("lod/cl_magic.lua")
AddCSLuaFile("lod/cl_pushback_fx.lua")

include("shared.lua")
include("lod/sv_saverestore_safety.lua")
include("lod/sv_midnight_sky.lua")
include("lod/sv_maze_generator.lua")
include("lod/sv_graph_integrity.lua")
include("lod/sv_wall_visuals.lua")
include("lod/sv_maze_builder.lua")
include("lod/sv_maze_builder_static_walls.lua")
include("lod/sv_maze_builder_floor_anchor.lua")
-- Back the raised level-0 labyrinth with one continuous recessed steel underdeck
-- so container-base/corner sightlines can never reveal the host map surface.
include("lod/sv_ground_perimeter_seals.lua")
include("lod/sv_m1_stair_geometry.lua")
include("lod/sv_maze_navigator.lua")
include("lod/sv_faction_manager.lua")
include("lod/sv_m3_enemy_config.lua")
-- One server roll service owns outgoing player dice and incoming hostile dice.
-- Load it before any runtime combat can occur and before feedback wrappers.
include("lod/sv_combat_rolls.lua")
-- Narrow ordinary Shambler/Runner melee dice from full-run balance evidence while
-- preserving the existing size/stat multiplier and the shared combat-roll feed.
include("lod/sv_enemy_melee_dice_balance.lua")
include("lod/sv_dice_ammo.lua")
-- Preserve stock HL2 weapon entities for inventory/loot compatibility while
-- layering the GDD-authored SMG heat and player AR2 burst contracts on top.
include("lod/sv_player_weapon_specials.lua")
include("lod/sv_player_weapon_specials_input.lua")
include("lod/sv_progression_director.lua")
include("lod/sv_m2_progression_safety.lua")
include("lod/sv_progression_builder.lua")
include("lod/sv_maze_geometry_audit.lua")
include("lod/sv_vertical_transition_audit.lua")
include("lod/sv_encounter_director.lua")
include("lod/sv_m3_dense_testing.lua")
include("lod/sv_m3_run_integration.lua")
include("lod/sv_run_manager.lua")
-- Production LootDirector wraps the final maze/encounter build chain and the
-- RunManager activation path, so it must load after both authorities exist.
include("lod/sv_loot_director.lua")
include("lod/sv_loot_context_rules.lua")
include("lod/sv_loot_catchup.lua")
include("lod/sv_loot_budget_validation.lua")
-- Firearms are peers rather than power tiers: equal acquisition weighting,
-- depletion-driven ammo support, and one AR2 ammo unit per three-round burst.
include("lod/sv_firearm_economy_equalization.lua")
-- One canonical minimap server module owns entitlement, canonical graph
-- serialization, runtime-origin sync, and the compact map network protocol.
include("lod/sv_minimap.lua")
include("lod/sv_combat_audio.lua")

-- Motion V2 is the one production ground-movement authority. Load it before
-- archetype/variance wrappers so their existing state machines wrap the new
-- graph-authoritative kinematic kernel rather than CLuaLocomotion:Approach.
include("lod/sv_hostile_motion_v2.lua")
include("lod/sv_deadcrab.lua")
-- Deadcrab face-latches follow players without becoming Source-engine children,
-- preventing parented-entity push warnings during player movement.
include("lod/sv_deadcrab_latch_parent_safety.lua")
include("lod/sv_bioblaster.lua")
include("lod/sv_enemy_variance.lua")
include("lod/sv_wandering_director.lua")
include("lod/sv_encounter_spawn_variance.lua")
include("lod/sv_hostile_separation.lua")

-- The former planar/ground-bridge/stair/no-progress recovery modules remain in
-- the repository for rollback/history but are intentionally NOT loaded. They all
-- attempted to repair Source NextBot ground locomotion after the fact and must
-- not compete with Motion V2.
include("lod/sv_m3_ground_probe.lua")
include("lod/sv_hostile_combat_hulls.lua")
include("lod/sv_m3_hit_feedback.lua")
-- Current Shotgun identity uses the universal natural-6 d6 explosion rule, an
-- exploding pellet-count d6, and shell-level stun up to the authored 4x tier.
include("lod/sv_shotgun_identity_balance.lua")
-- One reusable Motion-V2-safe push authority owns displacement and wall-crush
-- resolution for Shotgun today and later elemental/weapon/environmental effects.
include("lod/sv_pushback.lua")
-- Basic pre-release Magic reuses the same push authority: RMB casts one bounded
-- exploding-dice cone shout and regenerates a 0-100 personal Magic resource.
include("lod/sv_magic.lua")
include("lod/sv_shotgun_pushback.lua")
-- Load after hit feedback so generated-cover rejection can also suppress false
-- hit-confirm/flinch events, independent of EntityTakeDamage hook order.
include("lod/sv_generated_geometry_ballistics.lua")
-- Magnum penetration validates each post-body segment against the same generated
-- geometry authority, so aligned enemies can be pierced but walls cannot.
include("lod/sv_magnum_piercing.lua")
-- Final Magnum balance identity: global d12 boomchains lower their explosion
-- threshold toward the Boomchain Floor, while later cylinder chambers gain
-- damage and the last two trigger pulls become two-/three-round bursts.
include("lod/sv_magnum_super_explosive.lua")
-- Magnum Aim State is layered last among Magnum combat wrappers so its x2
-- multiplier applies to the already-resolved cylinder/Boomchain contract and is
-- inherited by every projectile generated by the focused trigger pull.
include("lod/sv_magnum_aim_state.lua")
-- Phase Zero replaces repeated graph BFS/global hostile scans with bounded
-- caches while preserving Motion V2 and generated geometry as authorities.
include("lod/sv_phase_zero_runtime_optimization.lua")
-- Gate-D Watcher support reuses Motion V2, the canonical wanderer registry, and
-- graph-distance caches. It broadcasts target acquisition only to already-live
-- wanderers and never creates reinforcements as part of its scan.
include("lod/sv_watcher.lua")
include("lod/sv_hostile_death_audio.lua")
include("lod/sv_hostile_death_pose.lua")
include("lod/sv_hostile_hurt_pose.lua")
include("lod/sv_m3_damage_audit.lua")
include("lod/sv_campaign_restart.lua")
include("lod/sv_respawn_hud.lua")

-- Soldier warning/firing is intentionally installed LAST among production combat
-- wrappers. It owns one immutable server-authored world-space shot line and prevents Motion V2,
-- live animation bones, client-only visual scaling, or bolt initialization from
-- becoming competing trajectory authorities.
include("lod/sv_soldier_shot_contract.lua")

-- Audits, seed harnesses, teleports, and the infinite-ammo testkit are not
-- production runtime dependencies. Read the archived startup value once: a
-- development server retains its full tool surface, while a fresh installation
-- avoids loading eight large test modules and their hooks entirely.
local cvDeveloperMode = GetConVar("lod_developer_mode")
LOD.DeveloperToolsLoaded = cvDeveloperMode and cvDeveloperMode:GetBool() or false
LOD.DeveloperToolModuleCount = 0
if LOD.DeveloperToolsLoaded then
    include("lod/sv_debug_tools.lua")
    include("lod/sv_m1_floor_support.lua")
    include("lod/sv_m1_traversal.lua")
    include("lod/sv_m2_debug.lua")
    include("lod/sv_m2_seed_test_incremental.lua")
    include("lod/sv_m3_debug.lua")
    include("lod/sv_m3_testkit_qol.lua")
    include("lod/sv_m3_roster_debug.lua")
    LOD.DeveloperToolModuleCount = 8
end
