"""Installer records exact bytes; runtime mismatch detection lives in B28 Lua."""
import hashlib
import ctypes
import os
import re
from pathlib import Path
import signal
import subprocess
import tempfile
import time

repo = Path(__file__).resolve().parents[1]
# Keep the installer coverage equal to the union of the two actual consumers,
# with separately reviewed sizes. Counts alone cannot catch a replaced or
# duplicated path; do not weaken either consumer's runtime verification.
def literal_paths(path, declaration):
    source = (repo / path).read_text()
    block = re.search(r"local " + declaration + r"\s*=\s*\{(.*?)\}", source, re.S)
    assert block, f'missing source declaration: {path}:{declaration}'
    paths = re.findall(r'"([^"\n]+\.lua)"', block[1])
    assert len(paths) == len(set(paths)), f'duplicate source in {path}:{declaration}'
    return set(paths)


population_paths = literal_paths('lua/autorun/server/lod_population_observability.lua', 'watched')
render_paths = literal_paths('gamemodes/legend_of_deborah/gamemode/lod/sh_runtime_audit.lua', 'renderSources')
assert len(population_paths) == 54
assert len(render_paths) == 19
expected_paths = population_paths | render_paths
assert len(expected_paths) == 58
assert {f'gamemodes/legend_of_deborah/gamemode/lod/{name}.lua' for name in (
    'cl_equipment_inventory', 'cl_spellbook', 'sv_magic_progression',
    'sv_magic_forms', 'sv_identity_perks', 'sv_enemy_melee', 'sv_enemy_variance')} <= expected_paths


def verify_rows(rows):
    paths = [row.split(None, 1)[1] for row in rows]
    assert len(paths) == len(set(paths)), 'duplicate installer source'
    assert set(paths) == expected_paths, (
        f'installer source mismatch: missing={sorted(expected_paths-set(paths))} '
        f'extra={sorted(set(paths)-expected_paths)}')
    for row in rows:
        digest, relative = row.split(None, 1)
        assert hashlib.sha256((repo / relative).read_bytes()).hexdigest() == digest, relative


# Linux installer integration: adopt its background mirror/startup descendants
# so native waitpid can prove retirement. /proc may expose another PID namespace
# in a managed executor and cannot safely establish that a child has exited.
PR_SET_CHILD_SUBREAPER = 36
assert ctypes.CDLL(None).prctl(PR_SET_CHILD_SUBREAPER, 1, 0, 0, 0) == 0, 'cannot own installer descendants'
with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp)
    game = home / 'garrysmod'
    game.mkdir()
    (game / 'gameinfo.txt').touch()
    data = game / 'data/legend_of_deborah'
    env = dict(os.environ, HOME=str(home), GMOD_GARRYSMOD_DIR=str(game))
    groups = []
    try:
        for _ in range(2):
            # Own the installer's mirror and startup children. Killing only the
            # mirror PID raced its initial mkdir against TemporaryDirectory's
            # removal in the October 5 complete-matrix CI run.
            with subprocess.Popen(['bash', 'tools/install_dev.sh'], cwd=repo,
                                  env=env, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, text=True,
                                  start_new_session=True) as process:
                groups.append(process.pid)
                stdout, stderr = process.communicate()
                assert process.returncode == 0, stdout + stderr
            rows = (data / 'dev_population_sources.txt').read_text().splitlines()
            verify_rows(rows)
            # Prove every missing entry, duplicate/substitution, and byte mismatch
            # is rejected without touching the installed or production files.
            corruptions = [rows[:i] + rows[i+1:] for i in range(len(rows))]
            corruptions += [rows + [rows[0]], [rows[0]] + rows[:-1]]
            corruptions += [[rows[0].split(None, 1)[0] + '  tools/not-a-runtime-source.lua'] + rows[1:]]
            corruptions += [[('0'*64 + '  ' + rows[0].split(None, 1)[1])] + rows[1:]]
            for corrupted in corruptions:
                try:
                    verify_rows(corrupted)
                except AssertionError:
                    pass
                else:
                    raise AssertionError('manifest validator accepted corrupted fixture')
            assert (game / 'addons/the-legend-of-deborah-dev').resolve() == repo
            vr_rows = (data / 'dev_vr_sources.txt').read_text().splitlines()
            assert vr_rows[0] == 'deborah-vr-idle-20261007-r2 139'
            for row in vr_rows[1:]:
                if row.startswith('bridge '):
                    _, digest, relative = row.split(None, 2)
                    path = repo / relative
                else:
                    digest, relative = row.split(None, 1)
                    path = game / 'addons/vrmod-x64' / relative
                assert hashlib.sha256(path.read_bytes()).hexdigest() == digest
            assert len(vr_rows) == 142
            assert 'population_latest.txt' in stdout
            assert not (data / 'dev_population_sources.txt.tmp').exists()
    finally:
        for group in groups:
            try:
                os.killpg(group, signal.SIGTERM)
            except ProcessLookupError:
                pass
        deadline = time.monotonic() + 5
        remaining = set(groups)
        while remaining:
            for group in list(remaining):
                try:
                    os.waitpid(-group, os.WNOHANG)
                except ChildProcessError:
                    remaining.remove(group)
            if remaining:
                assert time.monotonic() < deadline, 'owned installer children failed to retire'
                time.sleep(0.01)
print('DEV_POPULATION_MANIFEST_PASS exact 58-source consumer union (54 population, 19 client); complete distinct membership and hashes; missing/duplicate/substitution/hash negatives; equipment, Magic and identity authorities; repeat install; actual symlink; atomic manifest; owned children retired before temporary cleanup')
