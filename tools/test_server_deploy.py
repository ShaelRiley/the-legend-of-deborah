"""Exercise real git/filesystem deployment with a simulated systemd boundary."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
def run(*args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, text=True, **kwargs).stdout.strip()

# Independently exercise the actual A2S parser/challenge, including wrong identity.
spec = importlib.util.spec_from_file_location('query', ROOT / 'tools/server/query_server.py')
query = importlib.util.module_from_spec(spec)
spec.loader.exec_module(query)
packet = b'\xff'*4 + b'I\x11The Legend of Deborah\0gm_flatgrass\0garrysmod\0The Legend of Deborah\0'
packet += struct.pack('<HBBB', 4000, 2, 12, 0) + b'dl\0\1'
class Socket:
    def __enter__(self): return self
    def __exit__(self, *args): pass
    def settimeout(self, value): pass
    def connect(self, value): pass
    def send(self, value): self.sent.append(value)
    def recv(self, value): return self.responses.pop(0)
sock = Socket()
sock.sent, sock.responses = [], [b'\xff'*4+b'A1234', packet]
with patch.object(query.socket, 'socket', return_value=sock):
    info = query.query('fixture')
assert info['players'] == 2 and info['max_players'] == 12 and sock.sent[-1].endswith(b'1234')
sock.responses = [packet.replace(b'gm_flatgrass', b'gm_construct')]
with patch.object(query.socket, 'socket', return_value=sock):
    try: query.query('fixture')
    except ValueError: pass
    else: raise AssertionError('wrong map accepted')

with tempfile.TemporaryDirectory() as tmp:
    base = Path(tmp)
    repo, remote, server = base/'repo', base/'remote.git', base/'server'
    script = repo/'tools/server/deploy_verified.sh'
    script.parent.mkdir(parents=True)
    shutil.copy2(ROOT/'tools/server/deploy_verified.sh', script)
    shutil.copy2(ROOT/'tools/server/run_public_server.sh', script.parent/'run_public_server.sh')
    for name in ('gamemodes/legend_of_deborah/gamemode', 'lua'):
        (repo/name).mkdir(parents=True)
        (repo/name/'fixture').write_text('old')
    run('git','init','-q','-b','main',str(repo))
    run('git','-C',str(repo),'config','user.name','Test')
    run('git','-C',str(repo),'config','user.email','test@example.invalid')
    run('git','-C',str(repo),'add','.')
    run('git','-C',str(repo),'commit','-qm','old')
    before=run('git','-C',str(repo),'rev-parse','HEAD')
    (repo/'lua/fixture').write_text('new')
    run('git','-C',str(repo),'commit','-qam','new')
    target=run('git','-C',str(repo),'rev-parse','HEAD')
    run('git','clone','--bare','-q',str(repo),str(remote))
    run('git','-C',str(repo),'remote','add','origin',str(remote))
    run('git','-C',str(repo),'switch','--detach',before)
    data=server/'garrysmod/data/legend_of_deborah/player-record'
    data.parent.mkdir(parents=True)
    data.write_text('preserve')
    cfg=server/'garrysmod/cfg/lod_public_server.cfg'
    cfg.parent.mkdir(parents=True)
    cfg.write_text('operator configuration')
    native=server/'srcds_run';native.write_text('#!/bin/sh\nexit 0\n');native.chmod(0o755)
    config=base/'config';config.mkdir();(config/'gslt.token').write_text('test-token')
    state=base/'service';state.write_text('active')
    bins=base/'bin';bins.mkdir()
    scripts={
        'sudo':'#!/bin/sh\n[ "$1" = -v ] && exit 0\nexec "$@"\n',
        'sleep':'#!/bin/sh\nexit 0\n',
        'journalctl':'#!/bin/sh\nif [ -n "$LOD_TEST_BAD_LOG" ]; then echo "Lua Error"; else echo "Connection to Steam servers successful"; fi\n',
        'python3':f'#!/bin/sh\ncase "$1" in */query_server.py) echo \'{{"map":"gm_flatgrass"}}\'; exit 0;; esac\nexec "{sys.executable}" "$@"\n',
        'systemctl':'''#!/bin/bash
case "$1" in
show) if [[ "$4" == WorkingDirectory ]]; then echo "$LOD_REPO_ROOT"; else echo 0; fi;;
is-active) [[ "$(cat "$LOD_TEST_STATE")" == active ]];;
stop) echo stopped > "$LOD_TEST_STATE";;
start) bash "$LOD_REPO_ROOT/tools/server/run_public_server.sh" >/dev/null && echo active > "$LOD_TEST_STATE";;
*) exit 1;;
esac
'''}
    for name, text in scripts.items():
        p=bins/name;p.write_text(text);p.chmod(0o755)
    env=dict(os.environ, PATH=str(bins)+':'+os.environ['PATH'], LOD_REPO_ROOT=str(repo),
             LOD_SERVER_ROOT=str(server),LOD_SERVER_CONFIG_DIR=str(config),
             LOD_RELEASE_BACKUP_ROOT=str(base/'backups'),LOD_TEST_STATE=str(state))
    result=subprocess.run(['bash',str(script),target],env=env,capture_output=True,text=True)
    assert result.returncode==0, result.stdout+result.stderr
    assert 'DEPLOYED '+target in result.stdout
    assert data.read_text()=='preserve' and cfg.read_text()=='operator configuration'
    assert run('git','-C',str(repo),'rev-parse','HEAD')==target
    backups=list((base/'backups').iterdir())
    assert len(backups)==1 and (backups[0]/'previous-commit.txt').read_text().strip()==before
    assert (backups[0]/'data/legend_of_deborah/player-record').read_text()=='preserve'
    # A bad fresh startup log rolls source back, restarts and keeps player records.
    run('git','-C',str(repo),'switch','--detach',before)
    result=subprocess.run(['bash',str(script),target],env=dict(env,LOD_TEST_BAD_LOG='1'),capture_output=True,text=True)
    assert result.returncode!=0 and run('git','-C',str(repo),'rev-parse','HEAD')==before
    assert state.read_text().strip()=='active' and data.read_text()=='preserve'
    # Uncommitted operator work is rejected before service interruption.
    (repo/'operator-work').write_text('keep')
    result=subprocess.run(['bash',str(script),target],env=env,capture_output=True,text=True)
    assert result.returncode!=0 and (repo/'operator-work').read_text()=='keep'
    assert state.read_text().strip()=='active'
print('PASS pinned deployment, stopped-data backup, startup-failure rollback, dirty-work refusal and A2S challenge/identity parsing')
