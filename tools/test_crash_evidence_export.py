"""Crash export must work after termination and retain the original session tail."""
from pathlib import Path
import os
import subprocess
import tempfile

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    game = root / 'garrysmod'
    data = game / 'data/legend_of_deborah'
    data.mkdir(parents=True)
    (game / 'console.log').write_text('native console tail\n')
    (data / 'rpg_test_session.txt').write_text('final event 1465\n')
    (data / 'rpg_session_latest.txt').write_text('stale mirror event 1386\n')
    (data / 'stability_server_latest.txt').write_text('reward inputs\n')
    environment = dict(os.environ, GMOD_GARRYSMOD_DIR=str(game),
                       LOD_EVIDENCE_EXPORT_DIR=str(root / 'exports'))
    for _ in range(2):
        subprocess.run(['bash', 'tools/export_current_evidence.sh', '--crash'],
                       env=environment, check=True)
    exports = list((root / 'exports').iterdir())
    assert len(exports) == 2, 'previous crash export overwritten'
    for export in exports:
        assert (export / 'rpg_test_session.txt').read_text() == 'final event 1465\n'
        assert (export / 'rpg_session_latest.txt').read_text() == 'stale mirror event 1386\n'
        assert (export / 'stability_server_latest.txt').exists()
print('CRASH_EXPORT_PASS: no marker/watcher/game required; final tail and prior exports retained')
