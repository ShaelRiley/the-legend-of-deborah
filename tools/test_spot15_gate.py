#!/usr/bin/env python3
"""Finite SPOT-15 gate retaining all 87 SPOT-14 production/regression selections."""
import sys
import test_spot14_gate as inherited

gate = inherited.gate
gate.LABEL = 'SPOT15_GATE'
gate.SCOPE = 'SPOT-15 selected production/regression suites, not full campaign matrix'
gate.LUA += ['test_spot15_soldier_queue.lua', 'test_spot15_team_menu.lua', 'test_resurrection_feather.lua']
if __name__ == '__main__':
    sys.exit(gate.main())
