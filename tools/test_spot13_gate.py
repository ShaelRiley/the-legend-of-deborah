#!/usr/bin/env python3
"""SPOT-13 unread-page gate, retaining all 83 SPOT-12 selected regressions."""
import sys
import test_spot12_gate as inherited

gate = inherited.gate
gate.LABEL = 'SPOT13_GATE'
gate.SCOPE = 'SPOT-13 selected production/regression suites, not full campaign matrix'
gate.LUA += ['test_spot13_unread.lua', 'test_instruction_manual.lua']
if __name__ == '__main__':
    sys.exit(gate.main())
