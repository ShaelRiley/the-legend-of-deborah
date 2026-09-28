#!/usr/bin/env python3
"""Finite Big Skeleton gate, reusing production suites and the evidence runner."""
import test_checkpoint_g_integration as matrix

FILES = {
    "test_fallen_heroes.lua", "test_skeleton_frequency.lua", "test_skeleton_hero.lua",
    "test_event_skeleton_blockade.lua", "test_event_skeleton_lifecycle.lua",
    "test_event_services.lua", "test_event_incidents.lua", "test_event_ecology.lua",
    "sample_event_ecology.lua", "test_event_expansion_generation.lua",
    "test_bestiary_b29.lua", "test_bestiary_b29_dispatch.lua", "test_bestiary_b29_combat.lua",
    "test_equipment_economy_runtime.lua", "test_equipment_catalog.lua",
    "test_equipment_block.lua", "test_equipment_loot.lua", "test_big_loot_ecology.lua",
    "test_hostile_death_handoff.lua", "test_native_resource_lifecycle.lua",
    "test_shared_damage_lifetime.lua", "test_shotgun_native_path.lua",
    "test_cleanup_lifecycle.lua", "test_cleanup_contracts.lua", "test_campaign_timeout.lua",
    "test_human_soldier_progression.lua", "test_human_soldier_lifecycle.lua",
    "test_spot15_soldier_queue.lua", "test_spot16_soldier_rifle.lua",
    "test_checkpoint_d_closure.lua", "test_checkpoint_c_headless.lua",
    "test_wizard_balance.lua", "test_magic_wall.lua", "test_wall_placement_preview.lua",
    "test_super_ball.lua", "test_watermelon_bounces.lua", "test_wand.lua",
    "test_instruction_manual.lua", "test_manual_transport.lua", "test_manual_document.py",
    "export_manual_catalog.lua", "validate_spot05_die_logger.lua",
    "test_enemy_update.lua", "test_cross_feats_dodge.lua", "test_monster_identity.lua",
    "test_burst_authority_cleanup.lua", "test_gate_e_magic_recovery.lua",
}

if __name__ == "__main__":
    matrix.SUITES = [(name, command) for name, command in matrix.SUITES
                     if name in {"Git Diff Check", "Lua Syntax Audit"}
                     or any(part.rsplit("/", 1)[-1] in FILES
                            or part.rsplit("/", 1)[-1].startswith("test_faction")
                            for part in command)]
    print("BIG SKELETON TARGETED REGRESSIONS (not the full repository matrix)", flush=True)
    raise SystemExit(matrix.main())
