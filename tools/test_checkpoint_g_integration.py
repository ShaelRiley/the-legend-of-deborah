#!/usr/bin/env python3
import os
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
    ("Spell Availability & Teammate Identity", ["python3", "tools/run_lua54.py", "tools/test_refresh_ui.lua"]),
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
    ("Complete Enemy Roster & Animation Safety", ["python3", "tools/run_lua54.py", "tools/test_enemy_roster.lua"]),
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

def main():
    print("=== CHECKPOINT G INTEGRATED AUTOMATED RPG VALIDATION GATE ===")
    print(f"Repository Root: {REPO_ROOT}")
    print(f"Registered Test Suites: {len(SUITES)}\n")

    results = []
    failed_any = False

    for idx, (name, cmd) in enumerate(SUITES, 1):
        res = subprocess.run(cmd, cwd=REPO_ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        passed = (res.returncode == 0)
        status_str = "PASS" if passed else "FAIL"
        results.append((idx, name, status_str, res.returncode, res.stdout, res.stderr))
        print(f"[{status_str}] {idx:2d}/{len(SUITES)} - {name}")
        if not passed:
            failed_any = True
            print(f"  --> ERROR output for '{name}':")
            if res.stdout:
                print("STDOUT:\n" + res.stdout.strip())
            if res.stderr:
                print("STDERR:\n" + res.stderr.strip())
            print("-" * 60)

    print("\n" + "=" * 60)
    print("CHECKPOINT G SUITE MATRIX SUMMARY:")
    print("=" * 60)
    for idx, name, status_str, code, _, _ in results:
        print(f"  [{status_str}] {idx:2d}. {name:<45} (exit code {code})")
    print("=" * 60)

    if failed_any:
        print("\n[FAIL] CHECKPOINT_G_AUTOMATED_GATE_FAILED — One or more test suites failed.")
        sys.exit(1)
    else:
        print(f"\nCHECKPOINT_G_AUTOMATED_GATE_PASS — All {len(SUITES)} test suites verified cleanly with 0 failures.")
        sys.exit(0)

if __name__ == "__main__":
    main()
