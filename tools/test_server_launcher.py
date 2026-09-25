"""Real shell/copy failure tests; srcds alone is replaced by a harmless fixture."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as tmp:
    base = Path(tmp)
    repo, server, config = base / 'repo', base / 'server', base / 'config'
    script = repo / 'tools/server/run_public_server.sh'
    script.parent.mkdir(parents=True)
    shutil.copy2(ROOT / 'tools/server/run_public_server.sh', script)
    for name in ('gamemodes/legend_of_deborah/content/html', 'lua'):
        (repo / name).mkdir(parents=True)
        (repo / name / 'sample').write_text('new')
    subprocess.run(['git', 'init', '-q', str(repo)], check=True)
    subprocess.run(['git', '-C', str(repo), 'add', '.'], check=True)
    subprocess.run(['git', '-C', str(repo), '-c', 'user.name=Test', '-c',
                    'user.email=test@example.invalid', 'commit', '-qm', 'fixture'], check=True)
    sha = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip()
    addon = server / 'garrysmod/addons/the_legend_of_deborah'
    addon.mkdir(parents=True)
    (addon / 'old').write_text('old build')
    cfg = server / 'garrysmod/cfg/lod_public_server.cfg'
    cfg.parent.mkdir(parents=True)
    cfg.write_text('hostname "operator config"\n')
    data = server / 'garrysmod/data/legend_of_deborah/wallet-sentinel'
    data.parent.mkdir(parents=True)
    data.write_text('persistent player data')
    config.mkdir()
    token = config / 'gslt.token'
    token.write_text('test-placeholder-not-a-secret')
    native = server / 'srcds_run'
    native.write_text('#!/bin/sh\nexit 0\n')
    native.chmod(0o755)
    env = dict(os.environ, LOD_SERVER_ROOT=str(server), LOD_SERVER_CONFIG_DIR=str(config))
    # The second copy fails after the first staged copy succeeded.
    fakebin = base / 'bin'
    fakebin.mkdir()
    cp = fakebin / 'cp'
    cp.write_text('#!/bin/bash\nfor arg in "$@"; do [[ "$arg" == */lua ]] && exit 42; done\nexec /bin/cp "$@"\n')
    cp.chmod(0o755)
    failed = subprocess.run(['bash', str(script)], env=dict(env, PATH=str(fakebin)+':'+env['PATH']), capture_output=True)
    assert failed.returncode != 0 and (addon / 'old').read_text() == 'old build'
    assert cfg.read_text() == 'hostname "operator config"\n'
    assert not list((server / '.lod-deploy').glob('stage.*'))
    good = subprocess.run(['bash', str(script)], env=env, capture_output=True)
    assert good.returncode == 0, good.stderr.decode()
    assert not (addon / 'old').exists()
    assert (server / '.lod-deploy/previous/old').read_text() == 'old build'
    assert not (addon / 'gamemodes/legend_of_deborah/content/html').exists()
    assert (addon / 'lua/sample').read_text() == 'new'
    assert (addon / 'lod-build.txt').read_text() == sha + ' clean\n'
    assert (data.parent / 'dev_build.txt').read_text() == sha + ' clean\n'
    assert data.read_text() == 'persistent player data' and token.read_text() == 'test-placeholder-not-a-secret'
    assert cfg.read_text() == 'hostname "operator config"\n'
    assert b'test-placeholder-not-a-secret' not in good.stdout + good.stderr
    # Initial installation still generates the public defaults.
    cfg.unlink()
    subprocess.run(['bash', str(script)], env=env, check=True, capture_output=True)
    assert 'sv_visiblemaxplayers 12' in cfg.read_text() and 'host_info_show 2' in cfg.read_text()
print('PASS launcher failed-copy preservation, staged swap, rollback bytes, config/data/token preservation and exact revision receipt')
subprocess.run([sys.executable, str(ROOT / 'tools/test_server_deploy.py')], check=True)
