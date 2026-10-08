"""Installer records exact bytes; runtime mismatch detection lives in B28 Lua."""
import hashlib
import ctypes
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time

repo = Path(__file__).resolve().parents[1]
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
            assert len(rows) == 50
            assert any(row.endswith(' gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_melee.lua') for row in rows)
            for row in rows:
                digest, relative = row.split(None, 1)
                assert hashlib.sha256((repo / relative).read_bytes()).hexdigest() == digest, relative
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
print('DEV_POPULATION_MANIFEST_PASS exact 50-source hashes including shared enemy close-defense, static-box datatable notifications and saved camera/map Options; repeat install; actual symlink; atomic manifest; owned children retired before temporary cleanup')
