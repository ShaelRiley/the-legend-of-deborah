"""Installer records exact bytes; runtime mismatch detection lives in B28 Lua."""
import hashlib
import os
from pathlib import Path
import signal
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp)
    game = home / 'garrysmod'
    game.mkdir()
    data = game / 'data/legend_of_deborah'
    env = dict(os.environ, HOME=str(home), GMOD_GARRYSMOD_DIR=str(game))
    pid = None
    try:
        for _ in range(2):
            result = subprocess.run(['bash', 'tools/install_dev.sh'], cwd=repo,
                                    env=env, capture_output=True, text=True, check=True)
            pid = int((data / '.console_mirror.pid').read_text())
            rows = (data / 'dev_population_sources.txt').read_text().splitlines()
            assert len(rows) == 8
            for row in rows:
                digest, relative = row.split(None, 1)
                assert hashlib.sha256((repo / relative).read_bytes()).hexdigest() == digest, relative
            assert (game / 'addons/the-legend-of-deborah-dev').resolve() == repo
            assert 'population_latest.txt' in result.stdout
            assert not (data / 'dev_population_sources.txt.tmp').exists()
    finally:
        if pid:
            try:
                command = Path(f'/proc/{pid}/cmdline').read_bytes()
                if b'console_log_mirror.sh' in command and str(game).encode() in command:
                    os.kill(pid, signal.SIGTERM)
            except (ProcessLookupError, FileNotFoundError):
                pass
print('DEV_POPULATION_MANIFEST_PASS exact eight-source hashes; repeat install; actual symlink; atomic manifest; observer instructions')
