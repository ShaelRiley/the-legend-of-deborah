#!/usr/bin/env python3
"""Finite low-end renderer, native lifetime and current startup regression gate."""
import sys
import test_spot10_gate as gate

gate.LABEL = 'LOW_END_RENDER_GATE'
gate.SCOPE = 'Static renderer/cache plus affected geometry, camera, hazard and startup regressions; native performance pending'
gate.SQLITE_LUA = {'test_false_floor.lua', 'test_event_bootstrap.lua', 'test_staging_event_spawn.lua'}
gate.LUA = [
    'test_low_end_render.lua', 'test_low_end_geometry.lua',
    'test_low_end_palette.lua', 'test_low_end_options.lua',
    'test_great_crate_render.lua', 'test_great_crate_geometry.lua',
    'test_great_crate_gates.lua', 'test_great_crate_hull_runtime.lua',
    'test_geometry_fullupdate.lua', 'test_false_floor.lua',
    'test_native_resource_lifecycle.lua', 'test_campaign_timeout.lua',
    'test_deborah_finale_presentation.lua', 'test_dungeon_transition.lua',
    'test_cleanup_lifecycle.lua', 'test_cleanup_contracts.lua',
    'test_bootstrap_failure.lua', 'test_event_bootstrap.lua',
    'test_staging_event_spawn.lua', 'test_stair_headroom.lua',
    'test_maze_overhead_walls.lua', 'test_snapshot_delivery.lua',
    'test_player_options.lua',
]
if __name__ == '__main__':
    sys.exit(gate.main())
