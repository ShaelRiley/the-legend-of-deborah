#!/usr/bin/env python3
"""Finite SPOT-05 gate; deliberately not the full campaign-wide suite registry."""
import argparse
import concurrent.futures
import json
import hashlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LUA = [
    'validate_spot05_die_logger.lua', 'test_feedback_language.lua',
    'test_status_elements.lua', 'test_equipment_block.lua', 'test_cross_feats_dodge.lua',
    'test_actor_progression.lua', 'test_human_soldier_progression.lua',
    'test_human_soldier_lifecycle.lua', 'test_checkpoint_d_closure.lua',
    'test_wizard_balance.lua', 'test_gate_e_control_magic.lua',
    'test_gate_e_magic_recovery.lua', 'test_gate_e_crowbar.lua', 'test_gate_e_pusher.lua',
    'test_enemy_update.lua', 'test_monster_defenses.lua', 'test_snapshot_delivery.lua',
    'test_potion_projectile.lua', 'test_fighting_streets.lua', 'test_equipment_moves.lua',
    'test_checkpoint_c_headless.lua', 'test_bestiary_b28.lua', 'test_bestiary_b29.lua',
    'test_bestiary_b29_dispatch.lua', 'test_bestiary_b29_combat.lua',
    'validate_spot02_climber.lua', 'validate_spot03_razor.lua', 'validate_spot04_audio.lua',
    'test_great_crate_geometry.lua', 'test_great_crate_hull_runtime.lua',
    'test_soldier_character_sheet.lua', 'test_damsel_audio.lua', 'test_manual_transport.lua',
]

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True, help='Receipt/log directory outside the source tree')
    parser.add_argument('--workers', type=int, default=4, choices=range(1, 5))
    args = parser.parse_args()
    output = args.output.resolve()
    if output == ROOT or ROOT in output.parents:
        parser.error('Keep generated gate receipts outside the source tree.')
    if output.exists() and any(output.iterdir()):
        parser.error("Preserve earlier evidence; choose an empty output directory.")
    output.mkdir(parents=True, exist_ok=True)
    suites = [(p, ['python3', 'tools/run_lua54.py', 'tools/' + p] +
               (['.'] if p == 'test_checkpoint_c_headless.lua' else ['--runtime'] if p == 'test_bestiary_b29.lua' else [])) for p in LUA]
    suites += [('test_manual_document.py', ['python3','tools/test_manual_document.py']),
               ('test_dev_population_manifest.py', ['python3','tools/test_dev_population_manifest.py']),
               ('test_great_crate_assets.py', ['python3','tools/test_great_crate_assets.py']),
               ('git_diff_check', ['git','diff','--check'])]
    lua_files = sorted(str(p.relative_to(ROOT)) for base in ('gamemodes','lua','tools')
                       for p in (ROOT / base).rglob('*.lua'))
    suites += [('lua_syntax', ['python3','tools/run_lua54.py','--syntax', *lua_files])]

    def snapshot():
        names = subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=ROOT).decode().split('\0')
        return {n:hashlib.sha256((ROOT/n).read_bytes()).hexdigest() for n in sorted(set(names))
                if n and '__pycache__' not in n and (ROOT/n).is_file()}
    before = snapshot()

    def run(suite):
        name, command = suite
        try:
            result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=45)
            code, text = result.returncode, result.stdout
        except subprocess.TimeoutExpired as exc:
            code, text = 124, (exc.stdout or b'')
            if isinstance(text, bytes): text = text.decode('utf-8', errors='replace')
            text += '\nTIMEOUT: finite 45-second per-suite budget\n'
        path = output / (name + '.log')
        path.write_text(text, encoding='utf-8')
        row = {'name':name, 'command':command, 'returncode':code, 'passed':code==0,
               'log':path.name, 'log_sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
        (output / (name + '.json')).write_text(json.dumps(row,indent=2)+'\n')
        print(('PASS' if row['passed'] else 'FAIL') + ' ' + name, flush=True)
        return row

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        results = list(pool.map(run, suites))
    for row in results:
        if not row['passed']: print((output / row['log']).read_text()[-4000:], flush=True)
    after = snapshot()
    changed = sorted(n for n in before.keys() | after.keys() if before.get(n)!=after.get(n))
    receipt = {'source_before':hashlib.sha256(json.dumps(before,sort_keys=True).encode()).hexdigest(),
               'source_after':hashlib.sha256(json.dumps(after,sort_keys=True).encode()).hexdigest(),
               'changed_during_gate':changed,
               'sampling':'B29 --runtime: recorded native layout/lifecycle, not the extra 20-seed exposure sweep',
               'scope':'SPOT-05 selected production/regression suites, not full campaign matrix',
               'passed':sum(row['passed'] for row in results), 'total':len(results),
               'lua_files':len(lua_files), 'native_gmod_accepted':False, 'results':results}
    (output / 'receipt.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    print(f"SPOT05_GATE {receipt['passed']}/{receipt['total']}; syntax {len(lua_files)} Lua files")
    return 0 if receipt['passed']==receipt['total'] and not changed else 1

if __name__ == '__main__':
    sys.exit(main())
