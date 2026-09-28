#!/usr/bin/env python3
import os
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import re
import time
import subprocess
import sys
from pathlib import Path

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def get_lua_files():
    lua_files = []
    for dirpath in ["gamemodes", "lua", "tools"]:
        abs_dir = os.path.join(REPO_ROOT, dirpath)
        if os.path.exists(abs_dir):
            for root, _, files in os.walk(abs_dir):
                for f in files:
                    if f.endswith(".lua"):
                        lua_files.append(os.path.relpath(os.path.join(root, f), REPO_ROOT))
    return sorted(lua_files)

LUA_FILES = get_lua_files()

SUITES = [
    ("Low-end Static Draw Cache & Perspective Culling", ["python3", "tools/run_lua54.py", "tools/test_low_end_render.lua"]),
    ("Low-end Immutable Palette & Reconciliation", ["python3", "tools/run_lua54.py", "tools/test_low_end_palette.lua"]),
    ("Low-end Conservative Geometry & Material Batching", ["python3", "tools/run_lua54.py", "tools/test_low_end_geometry.lua"]),
    ("Low-end Saved Options & Screen Bounds", ["python3", "tools/run_lua54.py", "tools/test_low_end_options.lua"]),
    ("Music Policy & Catalog Contracts", ["python3", "tools/run_lua54.py", "tools/test_music_policy.lua"]),
    ("Music Server Permission & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_music_server.lua"]),
    ("Music Client Bounded Streaming", ["python3", "tools/run_lua54.py", "tools/test_music_client.lua"]),
    ("Music Crossfade Transitions", ["python3", "tools/run_lua54.py", "tools/test_music_transitions.lua"]),
    ("Music Paced Media & Cache", ["python3", "tools/run_lua54.py", "tools/test_music_media.lua"]),
    ("Music Gameplay Resource Priority", ["python3", "tools/run_lua54.py", "tools/test_music_resources.lua"]),
    ("Player Options Movement Invariants", ["python3", "tools/run_lua54.py", "tools/test_player_options.lua"]),
    ("Music Ingestion Validation", ["python3", "tools/test_music_ingestion.py"]),
    ("Big Event Services & Atomic Resources", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_services.lua"]),
    ("Big Event Incidents & Body Lifecycles", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_incidents.lua"]),
    ("Big Event Campaign Ecology & Determinism", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_ecology.lua"]),
    ("Big Event Campaign Coverage & Novelty", ["python3", "tools/test_crypto_sqlite.py", "tools/sample_event_ecology.lua"]),
    ("Big Event Full Catalog & Production Generation", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_expansion_generation.lua"]),
    ("Big Event Native Presentation & Client Prompts", ["python3", "tools/run_lua54.py", "tools/test_event_expansion_ui.lua"]),
    ("Big Loot Authored Catalog & Budget", ["python3", "tools/run_lua54.py", "tools/test_big_loot_catalog.lua"]),
    ("Big Loot Inventory Finality", ["python3", "tools/run_lua54.py", "tools/test_big_loot_inventory.lua"]),
    ("Big Loot Reward Ecology & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_big_loot_ecology.lua"]),
    ("Big Loot Natural Campaign Coverage", ["python3", "tools/run_lua54.py", "tools/test_big_loot_campaign.lua"]),
    ("Standing Stair Headroom & Upper Crossover", ["python3", "tools/run_lua54.py", "tools/test_stair_headroom.lua"]),
    ("SPOT-05 Canonical Die Logger", ["python3", "tools/run_lua54.py", "tools/validate_spot05_die_logger.lua"]),
    ("SPOT-04 Enemy Loop Audio Lifecycle", ["python3", "tools/run_lua54.py", "tools/validate_spot04_audio.lua"]),
    ("SPOT-03 Razor Presentation, Pursuit & Release Diagnostics", ["python3", "tools/run_lua54.py", "tools/validate_spot03_razor.lua"]),
    ("Bestiary B29 Full Build & Opening Safety", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b29.lua"]),
    ("Bestiary B29 Native Dispatch & Withdrawal", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b29_dispatch.lua"]),
    ("Bestiary B29 Bilateral Combat Seams", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b29_combat.lua"]),
    ("Development Population Source Manifest", ["python3", "tools/test_dev_population_manifest.py"]),
    ("Bestiary B28 Native Population Boundaries", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b28.lua"]),
    ("Bestiary B27 Autonomous Patrols & Adventure Pacing", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b27.lua"]),
    ("Bestiary B26 Production Population Recovery", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b26.lua"]),
    ("Great Crate Stock Gates & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_great_crate_gates.lua"]),
    ("Great Crate Stock Hull Assets", ["python3", "tools/test_great_crate_hull.py"]),
    ("Great Crate Hull Candidate Reconciliation", ["python3", "tools/run_lua54.py", "tools/test_great_crate_hull_runtime.lua"]),
    ("Great Crate Original Assets & Safe Fit", ["python3", "tools/test_great_crate_assets.py"]),
    ("Great Crate Deterministic Floor & Collision", ["python3", "tools/run_lua54.py", "tools/test_great_crate_geometry.lua"]),
    ("Great Crate Rendering, UV & Resource Bounds", ["python3", "tools/run_lua54.py", "tools/test_great_crate_render.lua"]),
    ("Bestiary B25 Motif Intensity & Tier Exposure", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b25.lua"]),
    ("Bestiary B24 Encounter and Wandering Homes", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b24.lua"]),
    ("Bestiary B23 Wandering Population & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b23.lua"]),
    ("Bestiary B23 Campaign Wandering Ecology", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b23_campaign.lua"]),
    ("Bestiary B22 Route Pacing & Production Effects", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b22.lua"]),
    ("Bestiary B21 Topology & Spatial Admission", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b21.lua"]),
    ("Bestiary B20 Ecology Selection & Receipts", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b20.lua"]),
    ("Bestiary B20 Campaign Ecology Coverage", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b20_campaign.lua"]),
    ("Bestiary B20 Campaign Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b20_lifecycle.lua"]),
    ("Bestiary B19 Companion Links & Exact Ownership", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b19.lua"]),
    ("Bestiary B19 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b19_production.lua"]),
    ("Bestiary B19 Readable Companion Links", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b19_visual.lua"]),
    ("Bestiary B18 Attack Restraint & Displaced Refuge", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b18.lua"]),
    ("Bestiary B18 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b18_production.lua"]),
    ("Bestiary B18 Readable Edicts", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b18_visual.lua"]),
    ("Bestiary B17 Companion Commitments & Exact Ownership", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b17.lua"]),
    ("Bestiary B17 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b17_production.lua"]),
    ("Bestiary B17 Readable Bodyguard & Oath", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b17_visual.lua"]),
    ("Bestiary B16 Movement Discipline & Exact Ownership", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b16.lua"]),
    ("Bestiary B16 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b16_production.lua"]),
    ("Bestiary B16 Readable Movement Demands", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b16_visual.lua"]),
    ("Bestiary B15 Careless Fire & Exact Ownership", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b15.lua"]),
    ("Bestiary B15 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b15_production.lua"]),
    ("Bestiary B15 Readable Careless Fire", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b15_visual.lua"]),
    ("Bestiary B14 Canonical Resource Pressure", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b14.lua"]),
    ("Bestiary B14 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b14_production.lua"]),
    ("Bestiary B14 Readable Resource Commitments", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b14_visual.lua"]),
    ("Deborah Finale Client Presentation & Cleanup", ["python3", "tools/run_lua54.py", "tools/test_deborah_finale_presentation.lua"]),
    ("Deborah Staging Succession & Canonical Services", ["python3", "tools/run_lua54.py", "tools/test_deborah_succession.lua"]),
    ("Hector Encounter, Native Death & Level-20 Rescue Gate", ["python3", "tools/run_lua54.py", "tools/test_hector_encounter.lua"]),
    ("Hector Canonical Actor Health & Defenses", ["python3", "tools/run_lua54.py", "tools/test_hector_health.lua"]),
    ("Hector Horizon & Telegraph Presentation", ["python3", "tools/run_lua54.py", "tools/test_hector_presentation.lua"]),
    ("Equipment Quiz Lifecycle & Atomic Settlement", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_equipment_quiz.lua"]),
    ("Active Event Catalog, Bribe Removal & Quiz Placement", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_quiz_generation.lua"]),
    ("Minigame Shell & Equipment UI Restrictions", ["python3", "tools/run_lua54.py", "tools/test_minigame_ui.lua"]),
    ("Skeleton Hero Generation & Shared Combat", ["python3", "tools/run_lua54.py", "tools/test_skeleton_hero.lua"]),
    ("Fallen Player Skeletons & Shared Combat", ["python3", "tools/run_lua54.py", "tools/test_fallen_heroes.lua"]),
    ("Frequent Skeleton Events & Natural Builds", ["python3", "tools/test_crypto_sqlite.py", "tools/test_skeleton_frequency.lua"]),
    ("Skeleton Blockade Historical Mixed-Catalog Regression", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_skeleton_blockade.lua"]),
    ("Skeleton Blockade Death & Rewards", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_skeleton_lifecycle.lua"]),
    ("Warp Hole Utility & Safe Traversal", ["python3", "tools/test_crypto_sqlite.py", "tools/test_warp_hole.lua"]),
    ("False Floor Hazard & Native Geometry Boundaries", ["python3", "tools/test_crypto_sqlite.py", "tools/test_false_floor.lua"]),
    ("Combined Event Population & Rarity", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_population.lua"]),
    ("Vending Machine Wallet & Potion Settlement", ["python3", "tools/test_crypto_sqlite.py", "tools/test_vending_machine.lua"]),
    ("Treasure Chest DFT Transactions", ["python3", "tools/test_crypto_sqlite.py", "tools/test_treasure_chest.lua"]),
    ("Chest Keys & Locked Loot Claims", ["python3", "tools/test_crypto_sqlite.py", "tools/test_locked_chest.lua"]),
    ("Dungeon Events & Transactional Slot Machine", ["python3", "tools/test_crypto_sqlite.py", "tools/test_dungeon_events.lua"]),
    ("Live Ranking Boards & Pagination", ["python3", "tools/run_lua54.py", "tools/test_live_boards.lua"]),
    ("Magic Hourglass & Shared Clock", ["python3", "tools/run_lua54.py", "tools/test_magic_hourglass.lua"]),
    ("Moon Boots Gravity", ["python3", "tools/run_lua54.py", "tools/test_moon_boots.lua"]),
    ("Finite Wand Weapon", ["python3", "tools/run_lua54.py", "tools/test_wand.lua"]),
    ("Tanuki Statue", ["python3", "tools/run_lua54.py", "tools/test_tanuki_ring.lua"]),
    ("Heavy Plumber Stomp", ["python3", "tools/run_lua54.py", "tools/test_heavy_plumber.lua"]),
    ("Stomp Movement Contact", ["python3", "tools/run_lua54.py", "tools/test_stomp_contact.lua"]),
    ("Thunder Hat Charge", ["python3", "tools/run_lua54.py", "tools/test_thunder_charge.lua"]),
    ("Ring of Invisibility", ["python3", "tools/run_lua54.py", "tools/test_invisibility_ring.lua"]),
    ("Fighting Streets Techniques", ["python3", "tools/run_lua54.py", "tools/test_fighting_streets.lua"]),
    ("Feather & Canonical Hero Revival", ["python3", "tools/run_lua54.py", "tools/test_resurrection_feather.lua"]),
    ("Safe Teleport & Summon Card", ["python3", "tools/run_lua54.py", "tools/test_summon_card.lua"]),
    ("Responsive Character Sheet & Canonical Feat Text", ["python3", "tools/run_lua54.py", "tools/test_character_sheet_layout.lua"]),
    ("Equipment Combo Abilities", ["python3", "tools/run_lua54.py", "tools/test_equipment_combo_abilities.lua"]),
    ("Monster Defense Balance & Tactical Feedback", ["python3", "tools/run_lua54.py", "tools/test_monster_defenses.lua"]),
    ("Invisible Overhead Walls & Free Movement", ["python3", "tools/run_lua54.py", "tools/test_maze_overhead_walls.lua"]),
    ("September 22 Navigation Recovery", ["python3", "tools/run_lua54.py", "tools/test_navigation_recovery.lua"]),
    ("Spell Availability", ["python3", "tools/run_lua54.py", "tools/test_refresh_ui.lua"]),
    ("Deterministic Encounter Distribution", ["python3", "tools/run_lua54.py", "tools/test_encounter_distribution.lua"]),
    ("Integrated Combat, Remedy & Derived UI", ["python3", "tools/run_lua54.py", "tools/test_integrated_refresh.lua"]),
    ("Client Geometry Full-Update Recovery", ["python3", "tools/run_lua54.py", "tools/test_geometry_fullupdate.lua"]),
    ("Dungeon Transition Inventory", ["python3", "tools/run_lua54.py", "tools/test_dungeon_transition.lua"]),
    ("Exact Native-Crash Reward Replay", ["python3", "tools/run_lua54.py", "tools/test_equipment_crash_replay.lua"]),
    ("Equipment LuaJIT Compatibility Boundary", ["python3", "tools/run_lua54.py", "tools/test_equipment_jit_guard.lua"]),
    ("Force-close Evidence Export", ["python3", "tools/test_crash_evidence_export.py"]),
    ("Canonical Blue Minimap Marker", ["python3", "tools/run_lua54.py", "tools/test_minimap_player_marker.lua"]),
    ("Shared Native DamageInfo Lifetime", ["python3", "tools/run_lua54.py", "tools/test_shared_damage_lifetime.lua"]),
    ("Durable Stability Diagnostics", ["python3", "tools/run_lua54.py", "tools/test_stability_diagnostics.lua"]),
    ("Release Include & Registration Wiring", ["python3", "tools/validate_release_wiring.py"]),
    ("Shotgun Native Bullet Aggregation", ["python3", "tools/run_lua54.py", "tools/test_shotgun_native_path.lua"]),
    ("Canonical Manual & Portable Menu", ["python3", "tools/run_lua54.py", "tools/test_instruction_manual.lua"]),
    ("Canonical Manual Server Transport", ["python3", "tools/run_lua54.py", "tools/test_manual_transport.lua"]),
    ("Manual Source & Reader Navigation", ["python3", "tools/test_manual_document.py"]),
    ("Campaign Clock & TIME OVER Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_campaign_timeout.lua"]),
    ("Bootstrap Failure & Explicit Recovery", ["python3", "tools/run_lua54.py", "tools/test_bootstrap_failure.lua"]),
    ("Event-Safe Campaign Bootstrap & Staging", ["python3", "tools/test_crypto_sqlite.py", "tools/test_event_bootstrap.lua"]),
    ("Staging Event Spawn & Deferred Native Deletion", ["python3", "tools/test_crypto_sqlite.py", "tools/test_staging_event_spawn.lua"]),
    ("Dedicated Server Deployment Preservation", ["python3", "tools/test_server_launcher.py"]),
    ("Complete Enemy Roster & Animation Safety", ["python3", "tools/run_lua54.py", "tools/test_enemy_roster.lua"]),
    ("Bestiary B1 Content Enemies & Exact Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b1.lua"]),
    ("Bestiary B2 Ally Support & Production Progression", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b2.lua"]),
    ("Bestiary B3 Flank Pursuit & Production Progression", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b3.lua"]),
    ("Bestiary B4 Self Defense & Reaction Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b4.lua"]),
    ("Bestiary B4 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b4_production.lua"]),
    ("Bestiary B5 Projectile Patterns & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b5.lua"]),
    ("Bestiary B5 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b5_production.lua"]),
    ("Bestiary B6 Trap Geometry & Exact Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b6.lua"]),
    ("Bestiary B6 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b6_production.lua"]),
    ("Bestiary B6 Readable Trap Presentation", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b6_visual.lua"]),
    ("Bestiary B7 Melee Spacing & Lifetimes", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b7.lua"]),
    ("Bestiary B7 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b7_production.lua"]),
    ("Bestiary B7 Readable Melee Presentation", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b7_visual.lua"]),
    ("Bestiary B13 Party Spacing & Exact Lifetimes", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b13.lua"]),
    ("Bestiary B13 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b13_production.lua"]),
    ("Bestiary B13 Readable Party Commitments", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b13_visual.lua"]),
    ("Bestiary B12 Exact Condition Strike", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b12.lua"]),
    ("Bestiary B12 Canonical Ally Cleansing", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b12_support.lua"]),
    ("Bestiary B12 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b12_production.lua"]),
    ("Bestiary B12 Readable Condition Commitments", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b12_visual.lua"]),
    ("Bestiary B11 Perception & Exact Lifetimes", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b11.lua"]),
    ("Bestiary B11 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b11_production.lua"]),
    ("Bestiary B11 Readable Sensory Commitments", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b11_visual.lua"]),
    ("Bestiary B10 Mobile Hazards & Lifetimes", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b10.lua"]),
    ("Bestiary B10 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b10_production.lua"]),
    ("Bestiary B10 Readable Moving Zones", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b10_visual.lua"]),
    ("Bestiary B9 Tether, Screen & Shared Authorities", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b9.lua"]),
    ("Bestiary B9 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b9_production.lua"]),
    ("Bestiary B9 Readable Tether & Screen", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b9_visual.lua"]),
    ("Bestiary B8 Corpse Receipts & Scavenging", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b8.lua"]),
    ("Bestiary B8 Production Progression & Spawn", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b8_production.lua"]),
    ("Bestiary B8 Readable Remains Presentation", ["python3", "tools/run_lua54.py", "tools/test_bestiary_b8_visual.lua"]),
    ("Gordon Arena & Encounter Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_warden.lua"]),
    ("Gordon Ordered Health Scaling", ["python3", "tools/run_lua54.py", "tools/test_warden_health.lua"]),
    ("Neil, Brute & Black Gate Hunt", ["python3", "tools/run_lua54.py", "tools/test_neil_brute.lua"]),
    ("Native Resource Ownership & Error Unwinding", ["python3", "tools/run_lua54.py", "tools/test_native_resource_lifecycle.lua"]),
    ("Native WeaponEquip Settlement", ["python3", "tools/run_lua54.py", "tools/test_weapon_equip_settlement.lua"]),
    ("GPS Cadence & Voice Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_gps_cadence.lua"]),
    ("Pickup Native Creation & Touch Handoff", ["python3", "tools/run_lua54.py", "tools/test_pickup_native_handoff.lua"]),
    ("Procedural Weapon Visual Identity", ["python3", "tools/run_lua54.py", "tools/test_weapon_appearance.lua"]),
    ("Loot/Class/Identification Refresh", ["python3", "tools/run_lua54.py", "tools/test_loot_class_refresh.lua"]),
    ("Fighter Strength / Constitution Bypass", ["python3", "tools/run_lua54.py", "tools/test_fighter_strength.lua"]),
    ("Monster Class, Affinity & Aura", ["python3", "tools/run_lua54.py", "tools/test_monster_identity.lua"]),
    ("Size Shifter Collision & Growth", ["python3", "tools/run_lua54.py", "tools/test_size_shifter_collision.lua"]),
    ("Hostile Native Death Handoff", ["python3", "tools/run_lua54.py", "tools/test_hostile_death_handoff.lua"]),
    ("Equipment/Area/Statue Presentation", ["python3", "tools/run_lua54.py", "tools/test_presentation_polish.lua"]),
    ("Magic Spectacle, Weapon Stowing & Natural Drops", ["python3", "tools/run_lua54.py", "tools/test_magic_inventory_refresh.lua"]),
    ("Final Loot Override Wearables & Potions", ["python3", "tools/run_lua54.py", "tools/test_equipment_drop_mix.lua"]),
    ("Equipment Body Map & Drag Inventory", ["python3", "tools/run_lua54.py", "tools/test_equipment_inventory_ui.lua"]),
    ("Reactive Character Status Portrait", ["python3", "tools/run_lua54.py", "tools/test_status_portrait.lua"]),
    ("Persistent Wallet, DFTs & SQLite Rollback", ["python3", "tools/test_crypto_sqlite.py"]),
    ("Wizard Summon & Starting Content", ["python3", "tools/run_lua54.py", "tools/test_wizard_balance.lua", "."]),
    ("Wallet Client & Navigation", ["python3", "tools/run_lua54.py", "tools/test_wallet_ui.lua"]),
    ("Equipment Network Delta & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_equipment_delivery.lua"]),
    ("Recurring Hermit Gifts & Staging Board", ["python3", "tools/run_lua54.py", "tools/test_hermit_return.lua"]),
    ("Enemy Variety & Shared Combat Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_enemy_update.lua"]),
    ("Equipment Owner-Only Pickup Inspection", ["python3", "tools/run_lua54.py", "tools/test_equipment_inspection.lua"]),
    ("Procedural Economy Distribution & Versioning", ["python3", "tools/run_lua54.py", "tools/test_equipment_economy.lua"]),
    ("Procedural Economy Production Integration", ["python3", "tools/run_lua54.py", "tools/test_equipment_economy_runtime.lua"]),
    ("Equipment Keyboard & UI Isolation", ["python3", "tools/run_lua54.py", "tools/test_equipment_input.lua"]),
    ("Equipment Real Loot Transactions", ["python3", "tools/run_lua54.py", "tools/test_equipment_loot.lua"]),
    ("Equipment Catalog, Swaps & Derived Stats", ["python3", "tools/run_lua54.py", "tools/test_equipment_catalog.lua"]),
    ("Equipment Shared Block", ["python3", "tools/run_lua54.py", "tools/test_equipment_block.lua"]),
    ("Equipment Special Moves & Input", ["python3", "tools/run_lua54.py", "tools/test_equipment_moves.lua"]),
    ("Equipment Wire Transport", ["python3", "tools/run_lua54.py", "tools/test_equipment_transport.lua"]),
    ("Special Move Keyboard To Combat", ["python3", "tools/run_lua54.py", "tools/test_special_move_end_to_end.lua"]),
    ("Potion Projectile Collision & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_potion_projectile.lua"]),
    ("Equipment Ownership & Throwable Transactions", ["python3", "tools/run_lua54.py", "tools/test_equipment.lua"]),
    ("Git Diff Check", ["git", "diff", "--check"]),
    ("Lua Syntax Audit", ["python3", "tools/run_lua54.py", "--syntax"] + LUA_FILES),
    ("Checkpoint C Python Validator", ["python3", "tools/validate_checkpoint_c.py"]),
    ("Actor Core & Level Progression", ["python3", "tools/run_lua54.py", "tools/test_actor_progression.lua"]),
    ("Magic Forms & Contents Schema", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_c_headless.lua", "."]),
    ("Implemented Feats & Capstones (135+9)", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_d_closure.lua"]),
    ("Human Soldier RPG & XP Progression", ["python3", "tools/run_lua54.py", "tools/test_human_soldier_progression.lua"]),
    ("Human Soldier Lifecycle & Isolation", ["python3", "tools/run_lua54.py", "tools/test_human_soldier_lifecycle.lua"]),
    ("Death Tetris Deadline & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_tetris_lifecycle.lua"]),
    ("Checkpoint E Closure & Parity", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_e_closure.lua"]),
    ("Soldier P-Sheet & Renderer Contract", ["python3", "tools/run_lua54.py", "tools/test_soldier_character_sheet.lua"]),
    ("Checkpoint F Run-End & Leaderboard", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_f_closure.lua"]),
    ("Status & Element Matrix", ["python3", "tools/run_lua54.py", "tools/test_status_elements.lua"]),
    ("Protected: Deadeye Stabilization", ["python3", "tools/run_lua54.py", "tools/test_deadeye_stabilization.lua"]),
    ("Protected: Crowbar Mechanics", ["python3", "tools/run_lua54.py", "tools/test_gate_e_crowbar.lua"]),
    ("Protected: Pusher Feat & Impulse", ["python3", "tools/run_lua54.py", "tools/test_gate_e_pusher.lua"]),
    ("Protected: Map Movement & Navigation", ["python3", "tools/run_lua54.py", "tools/test_map_movement.lua"]),
    ("Protected: Quantum Cost Seam", ["python3", "tools/run_lua54.py", "tools/test_quantum.lua"]),
    ("Protected: Strafe Movement", ["python3", "tools/run_lua54.py", "tools/test_strafe.lua"]),
    ("Protected: Backpedal Movement", ["python3", "tools/run_lua54.py", "tools/test_backpedal.lua"]),
    ("Protected: Winning Personality", ["python3", "tools/run_lua54.py", "tools/test_winning_personality.lua"]),
    ("Protected: Deadcrab Dispatch", ["python3", "tools/run_lua54.py", "tools/test_deadcrab_dispatch.lua"]),
    ("Protected: Dev Ingress", ["python3", "tools/run_lua54.py", "tools/test_dev_ingress.lua"]),
    ("Protected: Control Magic", ["python3", "tools/run_lua54.py", "tools/test_gate_e_control_magic.lua"]),
    ("Protected: Magic Recovery", ["python3", "tools/run_lua54.py", "tools/test_gate_e_magic_recovery.lua"]),
    ("Protected: Behavioral Regressions Gate", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_g_protected_regressions.lua"]),
    ("Feedback Language & Die Logger", ["python3", "tools/run_lua54.py", "tools/test_feedback_language.lua"]),
    ("Wizard Reaction Sound & Particles", ["python3", "tools/run_lua54.py", "tools/test_wizard_reaction_fx.lua"]),
    ("Canonical Burst & Error Cleanup", ["python3", "tools/run_lua54.py", "tools/test_burst_authority_cleanup.lua"]),
    ("AG-011 Big Playtest Repairs Gate", ["python3", "tools/run_lua54.py", "tools/test_ag011_repairs.lua"]),
]

# Complete existing deterministic feat-family coverage rather than a handler-name
# whitelist. These use production seams and remain distinct from Source acceptance.
for path in sorted(Path(REPO_ROOT, "tools").glob("test_checkpoint_d_*.lua")):
    if path.name != "test_checkpoint_d_closure.lua":
        SUITES.append(("Feat: " + path.stem.removeprefix("test_checkpoint_d_"),
                       ["python3", "tools/run_lua54.py", str(path.relative_to(REPO_ROOT))]))
SUITES.append(("Feat Descriptions & Stabilization", ["python3", "tools/run_lua54.py", "tools/test_feat_stabilization.lua"]))
SUITES.append(("Hero Weakness & Identity Perks", ["python3", "tools/run_lua54.py", "tools/test_identity_perks_weakness.lua"]))
SUITES.append(("Snapshot Burst & Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_snapshot_delivery.lua"]))
SUITES.append(("Watcher Scan Dispatch", ["python3", "tools/run_lua54.py", "tools/test_watcher_dispatch.lua"]))
SUITES.append(("Watermelon Bounce and Shatter Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_watermelon_bounces.lua"]))
SUITES.append(("Multiple Mouse Magic Bindings", ["python3", "tools/run_lua54.py", "tools/test_magic_mouse_bindings.lua"]))
SUITES.append(("Wall Placement and Preview", ["python3", "tools/run_lua54.py", "tools/test_wall_placement_preview.lua"]))
SUITES.append(("Wall Form and Magic Testkit", ["python3", "tools/run_lua54.py", "tools/test_magic_wall.lua"]))
SUITES.append(("Super Ball Ricochet Lifecycle", ["python3", "tools/run_lua54.py", "tools/test_super_ball.lua"]))
SUITES.append(("Ordinary Procedural Pistol and Crowbar Loot", ["python3", "tools/run_lua54.py", "tools/test_weapon_loot_roster.lua"]))
SUITES.append(("Looping Audio Ownership", ["python3", "tools/run_lua54.py", "tools/test_loop_audio.lua"]))
SUITES.append(("Adventure Presentation", ["python3", "tools/run_lua54.py", "tools/test_adventure_presentation.lua"]))
SUITES.append(("Original Adventure Audio", ["python3", "tools/test_adventure_audio.py"]))
SUITES.append(("Damsel Campaign & Endless Progression", ["python3", "tools/run_lua54.py", "tools/test_damsel_progression.lua"]))
SUITES.append(("Damsel Staging, Late Join & Dialogue", ["python3", "tools/run_lua54.py", "tools/test_damsel_staging.lua"]))
SUITES.append(("Feedback Audio Lifecycle & Coalescing", ["python3", "tools/run_lua54.py", "tools/test_damsel_audio.lua"]))
SUITES.append(("Feedback Audio Assets", ["python3", "tools/test_feedback_audio.py"]))
SUITES.append(("Cross Feats & Shared Dodge", ["python3", "tools/run_lua54.py", "tools/test_cross_feats_dodge.lua"]))
SUITES.append(("Live-GDD Feat Release Gate", ["python3", "tools/audit_live_gdd_feats.py"]))

# Recent checkpoint gates must also execute in the complete matrix. Syntax-only
# inclusion does not exercise a regression. Retired Bribe fixtures stay archival;
# current event-catalog/Bribe-removal tests above cover the shipped replacement.
executed = {part for _, command in SUITES if "--syntax" not in command for part in command}
for pattern in ("test_spot*.lua", "validate_spot*.lua", "test_faction*.lua"):
    for path in sorted(Path(REPO_ROOT, "tools").glob(pattern)):
        relative = path.relative_to(REPO_ROOT).as_posix()
        if relative not in executed:
            SUITES.append((path.stem, ["python3", "tools/run_lua54.py", relative]))
            executed.add(relative)
SUITES += [
    ("Pulse-first Music Section Playback", ["python3", "tools/run_lua54.py", "tools/test_music_sections.lua"]),
    ("Offline Pulse-first Music Analysis", ["python3", "tools/test_music_sections.py"]),
    ("Player Target Identity", ["python3", "tools/run_lua54.py", "tools/tests/player_target_identity.lua"]),
    ("Cleanup Campaign, Loot & Party Contracts", ["python3", "tools/run_lua54.py", "tools/test_cleanup_contracts.lua"]),
    ("Cleanup Body-Lifetime & Jump Claims", ["python3", "tools/run_lua54.py", "tools/test_cleanup_lifecycle.lua"]),
    ("Minimap Cache & Request Ownership", ["python3", "tools/run_lua54.py", "tools/test_minimap_transport.lua"]),
    ("Muted Potion Input & Cure", ["python3", "tools/run_lua54.py", "tools/test_muted_potion.lua"]),
    ("Manual Catalog Parity", ["python3", "tools/run_lua54.py", "tools/export_manual_catalog.lua", "--check"]),
    ("Workshop Native & Proton Tools", ["python3", "tools/test_workshop_tools.py"]),
    ("Verified Server Deploy & Rollback", ["python3", "tools/test_server_deploy.py"]),
]


def source_snapshot():
    root = Path(REPO_ROOT)
    names = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=root
    ).decode().split("\0")
    return {name: hashlib.sha256((root / name).read_bytes()).hexdigest()
            for name in sorted(set(names)) if name and (root / name).is_file()
            and "__pycache__" not in Path(name).parts}


def snapshot_digest(snapshot):
    return hashlib.sha256(json.dumps(snapshot, sort_keys=True).encode()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description="Complete headless system/regression matrix; not native GMod acceptance.")
    parser.add_argument("--workers", type=int, default=1, choices=range(1, 5))
    parser.add_argument("--output", type=Path, help="New evidence directory outside the source checkout")
    parser.add_argument("--suite-timeout", type=int, default=600)
    args = parser.parse_args()
    if args.suite_timeout <= 0:
        parser.error("--suite-timeout must be positive")
    output = args.output.resolve() if args.output else None
    if output:
        if output == Path(REPO_ROOT) or Path(REPO_ROOT) in output.parents:
            parser.error("Store evidence outside the source checkout")
        if output.exists() and any(output.iterdir()):
            parser.error("Preserve earlier evidence; use a new output directory")
        output.mkdir(parents=True, exist_ok=True)
    before = source_snapshot()
    if output:
        (output / "source_manifest.json").write_text(json.dumps(before, indent=2)+"\n")
    print(f"COMPLETE SYSTEMS MATRIX: {len(SUITES)} suites; native acceptance remains separate", flush=True)

    def run(entry):
        index, (name, command) = entry
        start = time.monotonic()
        try:
            result = subprocess.run(command, cwd=REPO_ROOT, capture_output=True,
                                    timeout=args.suite_timeout)
            code, stdout, stderr = result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired as error:
            code, stdout = 124, error.stdout or b""
            stderr = (error.stderr or b"") + f"\nTIMEOUT: {args.suite_timeout}s\n".encode()
        stem = f"{index:03d}-" + re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
        row = dict(index=index, name=name, command=command, returncode=code,
                   seconds=round(time.monotonic()-start, 3), log_prefix=stem,
                   stdout_sha256=hashlib.sha256(stdout).hexdigest(),
                   stderr_sha256=hashlib.sha256(stderr).hexdigest())
        if output:
            (output / (stem+".stdout.txt")).write_bytes(stdout)
            (output / (stem+".stderr.txt")).write_bytes(stderr)
            (output / (stem+".json")).write_text(json.dumps(row, indent=2)+"\n")
        return row, stdout, stderr

    rows = []
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(run, entry) for entry in enumerate(SUITES, 1)]
        for future in as_completed(futures):
            row, stdout, stderr = future.result()
            rows.append(row)
            print(f"[{'PASS' if row['returncode']==0 else 'FAIL'}] {row['index']}/{len(SUITES)} "
                  f"{row['name']} ({row['seconds']}s)", flush=True)
            if row['returncode']:
                print((stdout+stderr).decode(errors="replace")[-6000:], flush=True)
    after = source_snapshot()
    changed = sorted(name for name in before.keys() | after.keys() if before.get(name) != after.get(name))
    report = dict(total=len(rows), passed=sum(row['returncode']==0 for row in rows),
                  source_before=snapshot_digest(before), source_after=snapshot_digest(after),
                  changed_during_gate=changed, lua_files=len(LUA_FILES), native_gmod_accepted=False,
                  results=sorted(rows, key=lambda row: row['index']))
    if output:
        (output / "receipt.json").write_text(json.dumps(report, indent=2)+"\n")
    print(f"SYSTEMS_MATRIX {report['passed']}/{report['total']}; source_changed={len(changed)}", flush=True)
    return 0 if report['passed']==report['total'] and not changed else 1


if __name__ == "__main__":
    sys.exit(main())
