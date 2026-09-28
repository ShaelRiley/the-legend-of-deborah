#!/usr/bin/env python3
"""Finite discrete-system optimization gate; native performance remains pending."""
import sys
import test_spot10_gate as gate

gate.LABEL = 'SYSTEM_QUANTIZATION_GATE'
gate.SCOPE = 'Discrete routes, exact loot budgets, near-look queries, projectile presentation and retained startup/render regressions'
gate.SQLITE_LUA = {'test_event_skeleton_blockade.lua', 'test_event_skeleton_lifecycle.lua',
                   'test_event_bootstrap.lua', 'test_staging_event_spawn.lua'}
gate.LUA = [
    'test_system_quantization.lua', 'test_quantized_routes.lua',
    'test_equipment_economy.lua', 'test_equipment_economy_runtime.lua',
    'test_big_loot_ecology.lua', 'test_equipment_crash_replay.lua',
    'test_equipment_jit_guard.lua', 'test_big_loot_catalog.lua',
    'test_big_loot_inventory.lua', 'test_loot_class_refresh.lua',
    'test_equipment_inspection.lua', 'test_checkpoint_d_wis_information.lua',
    'test_event_skeleton_blockade.lua', 'test_event_skeleton_lifecycle.lua',
    'test_navigation_recovery.lua', 'test_bestiary_b29_combat.lua',
    'test_bestiary_b5.lua', 'test_bestiary_b5_production.lua',
    'test_bestiary_b6_visual.lua', 'test_bestiary_b7_visual.lua',
    'test_bestiary_b11_visual.lua', 'test_enemy_roster.lua',
    'test_low_end_render.lua', 'test_low_end_geometry.lua',
    'test_low_end_palette.lua', 'test_geometry_fullupdate.lua',
    'test_campaign_timeout.lua', 'test_bootstrap_failure.lua',
    'test_event_bootstrap.lua', 'test_staging_event_spawn.lua',
    'test_cleanup_lifecycle.lua', 'test_cleanup_contracts.lua',
]
if __name__ == '__main__':
    sys.exit(gate.main())
