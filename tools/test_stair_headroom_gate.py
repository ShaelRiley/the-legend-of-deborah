#!/usr/bin/env python3
"""Bounded stair repair gate retaining every SPOT-17 selection."""
import sys
import test_spot17_gate as inherited

gate = inherited.gate
gate.LABEL = 'STAIR_HEADROOM_GATE'
gate.SCOPE = 'Standing stair clearance and all inherited SPOT-17 selected regressions; native acceptance pending'
for name in ('test_stair_headroom.lua', 'test_maze_overhead_walls.lua',
             'test_navigation_recovery.lua', 'test_size_shifter_collision.lua'):
    if name not in gate.LUA:
        gate.LUA.append(name)
if __name__ == '__main__':
    sys.exit(gate.main())
