#!/usr/bin/env python3
"""Finite SPOT-16 gate retaining all 90 SPOT-15 selections."""
import sys
import test_spot15_gate as inherited

gate = inherited.gate
gate.LABEL = 'SPOT16_GATE'
gate.SCOPE = 'SPOT-16 selected production/regression suites, not full campaign matrix'
gate.LUA += ['test_spot16_soldier_rifle.lua', 'test_spot16_rifle_client.lua', 'test_burst_authority_cleanup.lua']
if __name__ == '__main__':
    sys.exit(gate.main())
