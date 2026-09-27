#!/usr/bin/env python3
"""Finite SPOT-17 gate retaining all 93 SPOT-16 selections."""
import sys
import test_spot16_gate as inherited

gate = inherited.gate
gate.LABEL = 'SPOT17_GATE'
gate.SCOPE = 'SPOT-17 selected production/regression suites, not full campaign matrix'
gate.LUA += ['test_spot17_movement_server.lua', 'test_spot17_movement_client.lua']
if __name__ == '__main__':
    sys.exit(gate.main())
