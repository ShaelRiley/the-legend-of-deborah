#!/usr/bin/env python3
"""Approved D-J exact-source gate, retaining every prior SPOT-10 selection."""
import sys
import test_spot10_gate as gate

gate.LUA += [
    'validate_spot10_second_pass.lua', 'test_checkpoint_d_wall_jump.lua',
    'test_checkpoint_d_personality_aura.lua', 'test_checkpoint_d_aura_burst.lua',
    'test_moon_boots.lua', 'test_bestiary_b14.lua', 'test_bestiary_b14_production.lua',
    'test_fighter_strength.lua',
]
if __name__ == '__main__':
    sys.exit(gate.main())
