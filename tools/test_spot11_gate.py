#!/usr/bin/env python3
"""Finite four-choice draft gate, retaining all 72 selected D-J regressions."""
import sys
import test_spot10_second_pass_gate as inherited

gate = inherited.gate
gate.SQLITE_LUA = {'test_event_skeleton_blockade.lua', 'test_event_skeleton_lifecycle.lua'}
gate.LABEL = 'SPOT11_GATE'
gate.SCOPE = 'SPOT-11 selected production/regression suites, not full campaign matrix'
gate.LUA += [
    'validate_spot11_drafts.lua', 'test_spot11_draft_ui.lua',
    'test_character_sheet_layout.lua', 'test_checkpoint_d_magic_grant_feats.lua',
    'test_skeleton_hero.lua', 'test_event_skeleton_blockade.lua',
    'test_event_skeleton_lifecycle.lua',
]
if __name__ == '__main__':
    sys.exit(gate.main())
