#!/usr/bin/env python3
"""SPOT-12 card-state gate, retaining all 79 SPOT-11 selected regressions."""
import sys
import test_spot11_gate as inherited

gate = inherited.gate
gate.LABEL = 'SPOT12_GATE'
gate.SCOPE = 'SPOT-12 selected production/regression suites, not full campaign matrix'
gate.LUA += [
    'test_spot12_spellbook.lua', 'test_magic_mouse_bindings.lua',
    'test_magic_inventory_refresh.lua', 'test_minigame_ui.lua',
]
if __name__ == '__main__':
    sys.exit(gate.main())
