#!/usr/bin/env python3
"""Finite regression gate for event-aware campaign generation and staging."""
import sys
import test_spot10_gate as gate

gate.LABEL = 'BOOTSTRAP_GATE'
gate.SCOPE = 'Event placement recovery, startup, staging and affected lifecycle regressions; native acceptance pending'
gate.SQLITE_LUA = {
    'test_event_bootstrap.lua', 'test_staging_event_spawn.lua', 'test_event_expansion_generation.lua',
    'test_skeleton_frequency.lua', 'test_event_ecology.lua',
    'test_event_population.lua', 'test_event_skeleton_blockade.lua',
    'test_event_skeleton_lifecycle.lua', 'test_dungeon_events.lua',
    'test_event_quiz_generation.lua',
}
gate.LUA = sorted(gate.SQLITE_LUA) + [
    'test_bootstrap_failure.lua', 'test_skeleton_hero.lua', 'test_checkpoint_c_headless.lua',
    'test_campaign_timeout.lua', 'test_dungeon_transition.lua',
    'test_cleanup_lifecycle.lua', 'test_cleanup_contracts.lua',
    'test_native_resource_lifecycle.lua', 'test_snapshot_delivery.lua',
    'test_damsel_progression.lua', 'test_damsel_staging.lua',
    'test_warden.lua', 'test_hector_encounter.lua',
    'test_bestiary_b29.lua', 'test_bestiary_b29_dispatch.lua',
    'test_bestiary_b29_combat.lua', 'test_great_crate_geometry.lua',
    'test_music_server.lua', 'test_music_transitions.lua',
]
if __name__ == '__main__':
    sys.exit(gate.main())
