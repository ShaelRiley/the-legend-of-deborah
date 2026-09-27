#!/usr/bin/env python3
"""Bounded equipment-activation gate preserving the faction/stair selections."""
import sys
import test_faction_damage_gate as inherited

gate = inherited.gate
gate.LABEL = 'EQUIPMENT_ACTIVATION_GATE'
gate.SCOPE = 'Equipment contact/input repair plus inherited faction/stair selected regressions; native acceptance pending'
for name in ('test_heavy_plumber.lua', 'test_stomp_contact.lua', 'test_equipment_input.lua',
             'test_equipment_transport.lua', 'test_special_move_end_to_end.lua',
             'test_fighting_streets.lua', 'test_equipment_moves.lua',
             'test_thunder_charge.lua'):
    if name not in gate.LUA:
        gate.LUA.append(name)
if __name__ == '__main__':
    sys.exit(gate.main())
