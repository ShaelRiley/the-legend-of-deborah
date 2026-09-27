#!/usr/bin/env python3
"""Finite SPOT-14 gate: all 85 SPOT-13 selections plus actual clock boundaries."""
import sys
import test_spot13_gate as inherited

gate = inherited.gate
gate.LABEL = 'SPOT14_GATE'
gate.SCOPE = 'SPOT-14 selected production/regression suites, not full campaign matrix'
gate.LUA += ['test_campaign_timeout.lua', 'test_spot14_time_management.lua']
if __name__ == '__main__':
    sys.exit(gate.main())
