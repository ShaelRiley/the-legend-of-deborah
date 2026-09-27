#!/usr/bin/env python3
"""Bounded faction/Reckless repair gate retaining the standing-stair selections."""
import sys
import test_stair_headroom_gate as inherited

gate = inherited.gate
gate.LABEL = 'FACTION_DAMAGE_GATE'
gate.SCOPE = 'Faction/Reckless repair and inherited standing-stair selected regressions; native acceptance pending'
for name in ('test_faction_damage.lua', 'test_faction_geometry.lua', 'test_faction_roles.lua',
             'test_ag011_repairs.lua', 'test_bestiary_b15.lua', 'test_magic_wall.lua',
             'test_super_ball.lua', 'test_watermelon_bounces.lua', 'test_integrated_refresh.lua'):
    if name not in gate.LUA:
        gate.LUA.append(name)
if __name__ == '__main__':
    sys.exit(gate.main())
