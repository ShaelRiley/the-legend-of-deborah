#!/usr/bin/env python3
"""Fail closed on canonical inventory gaps; this is not a gameplay certification.

The fixture preserves exact targeted live-GDD rows plus evidenced author overrides.
Refresh it from the live document for the next audit, not from the runtime registry.
"""
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def values(table):
    return list(table.values()) if isinstance(table, dict) else table

def audit():
    source = json.loads((ROOT / 'tools/fixtures/live_gdd_feats.json').read_text())
    result = subprocess.run([sys.executable, 'tools/run_lua54.py', 'tools/export_feat_inventory.lua'],
                            cwd=ROOT, text=True, capture_output=True)
    if result.returncode:
        print(result.stdout + result.stderr)
        return 1
    payload = next((s.partition('=')[2] for s in result.stdout.splitlines()
                    if s.startswith('FEAT_INVENTORY_JSON=')), None)
    if payload is None:
        raise RuntimeError('Production inventory exporter returned no inventory')
    inventory = json.loads(payload)
    errors, expected, seen = [], {}, set()
    by_name = {}
    for row in source['rows']:
        by_name.setdefault(row['name'], []).append(row['id'])
    for row in source['rows']:
        ident = row['id']
        if ident in seen:
            errors.append(f'DUPLICATE_GDD_ID {ident}')
        seen.add(ident)
        override = source['overrides'].get(ident, {})
        if override.get('deferred'):
            if ident in inventory['ordinary']:
                errors.append(f'DEFERRED_EXPOSED {ident}')
            continue
        runtime_id = override.get('runtimeId', ident)
        expected[runtime_id] = row
        group = 'fallback' if ident.startswith('FALLBACK_') else 'ordinary'
        definition = inventory[group].get(runtime_id)
        if not definition:
            errors.append(f'MISSING_CANONICAL {ident} ({row["name"]})')
            continue
        if definition['displayName'] != row['name']:
            errors.append(f'NAME_MISMATCH {runtime_id}')
        if group == 'ordinary':
            requirements = {ability.lower(): int(score) for ability, score in
                            re.findall(r'(STR|DEX|CON|INT|WIS|CHA)\s*(\d+)',
                                       override.get('requirement', row['requirement']))}
            if definition.get('abilityRequirements', {}) != requirements:
                errors.append(f'REQUIREMENT_MISMATCH {runtime_id}')
            if any(v not in (13, 15, 17) for v in definition.get('abilityRequirements', {}).values()):
                errors.append(f'DEPRECATED_ABILITY_GATE {runtime_id}')
            actors = row['actors'].lower()
            expected_actors = set()
            if 'hero' in actors: expected_actors.add('hero')
            if 'soldier' in actors: expected_actors.add('human_soldier')
            if re.search(r'\bai\b', actors): expected_actors.add('ai')
            if 'player-controlled actors' in actors: expected_actors.update(('hero', 'human_soldier'))
            if set(values(definition.get('allowedActorTypes', {}))) != expected_actors:
                errors.append(f'ACTOR_SCOPE_MISMATCH {runtime_id}')
            prereqs = values(definition.get('prerequisiteFeatIds', {}))
            if row['prerequisite'] == 'None' and prereqs:
                errors.append(f'UNAUTHORED_PREREQUISITE {runtime_id}')
            # Preserve dynamic capabilities/item prerequisites as such; never
            # mistake them for a feat ID. Duplicate display names are legitimate.
            for name in row['prerequisite'].split('; '):
                candidates = by_name.get(name, [])
                if candidates and not set(candidates).intersection(prereqs):
                    errors.append(f'PREREQUISITE_MISMATCH {runtime_id}: {name}')
    all_ids, blank = set(), 0
    groups = [inventory['ordinary'], inventory['fallback'], *inventory['capstones'].values()]
    for group in groups:
        for ident, definition in group.items():
            if ident in all_ids:
                errors.append(f'DUPLICATE_RUNTIME_ID {ident}')
            all_ids.add(ident)
            if ident != definition.get('featId'):
                errors.append(f'ID_MISMATCH {ident}')
            text = definition.get('effectParams', {}).get('description', '')
            if not isinstance(text, str) or not text.strip():
                blank += 1
                errors.append(f'BLANK_DESCRIPTION {ident}')
            elif re.search(r'\b(TODO|TBD|placeholder)\b', text, re.I):
                errors.append(f'PLACEHOLDER_DESCRIPTION {ident}')
            if not definition.get('effectHandlerId'):
                errors.append(f'MISSING_HANDLER_ID {ident}')
            for prerequisite in values(definition.get('prerequisiteFeatIds', {})):
                if prerequisite not in inventory['ordinary']:
                    errors.append(f'ORPHAN_PREREQUISITE {ident}: {prerequisite}')
    for ident in set(inventory['ordinary']) | set(inventory['fallback']):
        if ident not in expected:
            errors.append(f'NONCANONICAL_EXPOSED {ident}')
    # Preserve the original authored row; explicit presentation overrides may
    # shorten its card without changing the separately tested spatial footprint.
    spatial = inventory['ordinary']['WIS_SPATIAL_AWARENESS']
    spatial_text = source['overrides'].get('WIS_SPATIAL_AWARENESS', {}).get(
        'cardText', expected['WIS_SPATIAL_AWARENESS']['effect'])
    if spatial['effectParams']['description'] != spatial_text:
        errors.append('SPATIAL_AWARENESS_DESCRIPTION_RULE_MISMATCH')
    evasion = inventory['capstones']['rogue']['ROG_CAP_NOW_YOU_SEE_ME']
    if evasion['effectParams'].get('evasionChance') is not None:
        errors.append('NONCANONICAL_DODGE: Now You See Me still declares independent evasion')
    print(f'Live GDD: {len(expected)-6} ordinary including cross feats, 6 fallbacks; '
          f'loaded {len(inventory["ordinary"])} ordinary, {len(all_ids)} total; blank descriptions={blank}')
    for error in errors:
        print('BLOCKER:', error)
    if errors:
        print('FEAT_RELEASE_GATE_BLOCKED — no human-acceptance candidate may be claimed.')
        return 1
    print('FEAT_INVENTORY_GATE_PASS — semantic behavior/actor coverage and Source acceptance still required.')
    return 0

if __name__ == '__main__':
    sys.exit(audit())
