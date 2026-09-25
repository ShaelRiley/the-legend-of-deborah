#!/usr/bin/env python3
"""Exercise real package/publish shell scripts with isolated native/Proton doubles."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
args=sys.argv[1:]
proton=Path(sys.argv[0]).name=='proton'
if proton:
    assert args.pop(0)=='run'
    tool=args.pop(0)
else:
    tool=sys.argv[0]
record={'tool':tool,'args':args,'proton':proton,'app':os.getenv('SteamAppId'),
        'game':os.getenv('SteamGameId'),'prefix':os.getenv('STEAM_COMPAT_DATA_PATH')}
with open(os.environ['LOD_WORKSHOP_TEST_LOG'],'a') as f: f.write(json.dumps(record)+'\n')
if os.environ.get('LOD_WORKSHOP_TEST_FAIL') in Path(tool).name:
    sys.exit(13)
if 'gmad' in Path(tool).name:
    out=args[args.index('-out')+1]
    if out.startswith('Z:'): out=out[2:].replace('\\','/')
    Path(out).write_bytes(b'test package')
'''

with tempfile.TemporaryDirectory(prefix='lod workshop ') as temp:
    base = Path(temp)
    root = base / 'repo with spaces'
    scripts = root / 'tools/workshop'
    scripts.mkdir(parents=True)
    for name in ('build_workshop.sh','publish_workshop.sh','workshop_tools.sh','addon.json'):
        shutil.copy2(ROOT / 'tools/workshop' / name, scripts / name)
    content = root / 'gamemodes/legend_of_deborah/content'
    (content / 'html').mkdir(parents=True)
    (content / 'html/excluded.html').write_text('excluded')
    (content / 'keep.txt').write_text('preserved')
    (root / 'lua').mkdir()
    (root / 'lua/test.lua').write_text('-- fixture')
    game = base / 'GarrysMod'
    native = game / 'bin/linux64'
    windows = game / 'bin/win64'
    native.mkdir(parents=True)
    windows.mkdir(parents=True)
    for name in ('gmad','gmpublish'):
        (windows / (name+'.exe')).write_text('Windows tool fixture')
    proton = base / 'Proton - Experimental/proton'
    proton.parent.mkdir()
    proton.write_text(MOCK)
    proton.chmod(0o755)
    log = base / 'calls.jsonl'
    env = dict(os.environ)
    for name in ('GMAD','GMPUBLISH'):
        env.pop(name, None)
    env.update(LOD_GMOD_DIR=str(game), LOD_PROTON=str(proton),
               STEAM_COMPAT_CLIENT_INSTALL_PATH=str(base/'Steam'),
               STEAM_COMPAT_DATA_PATH=str(base/'compatdata/4000'),
               LOD_WORKSHOP_TEST_LOG=str(log), LOD_WORKSHOP_TEST_FAIL='not-a-tool')
    notes = 'Great Crate / safety — spaces and $literal'

    def publish():
        log.write_text('')
        result = subprocess.run(['bash',str(scripts/'publish_workshop.sh'),notes],
                                env=env, text=True, capture_output=True)
        records = [json.loads(line) for line in log.read_text().splitlines()]
        return result, records

    result, records = publish()
    assert result.returncode == 0, result.stderr
    assert len(records) == 2 and all(r['proton'] for r in records)
    assert all(r['app']=='4000' and r['game']=='4000' and r['prefix']==env['STEAM_COMPAT_DATA_PATH'] for r in records)
    assert records[0]['args'][2].startswith('Z:') and records[0]['args'][4].startswith('Z:')
    assert records[1]['args'][2].startswith('Z:')
    assert records[1]['args'][4]=='3791535712' and records[1]['args'][-1]==notes
    stage = root / '.build/workshop/the_legend_of_deborah'
    assert (stage/'gamemodes/legend_of_deborah/content/keep.txt').read_text()=='preserved'
    assert not (stage/'gamemodes/legend_of_deborah/content/html').exists()
    assert (root/'dist/the_legend_of_deborah.gma').read_bytes()==b'test package'

    for name in ('gmad','gmpublish'):
        tool=native/name
        tool.write_text(MOCK)
        tool.chmod(0o755)
    result, records = publish()
    assert result.returncode == 0, result.stderr
    assert len(records)==2 and all(not r['proton'] for r in records), 'native tools should remain preferred'
    assert records[0]['args'][2].startswith('/') and records[1]['args'][-1]==notes

    env['LOD_WORKSHOP_TEST_FAIL']='gmad'
    result, records = publish()
    assert result.returncode==13 and len(records)==1 and 'Workshop update complete' not in result.stdout
    env['LOD_WORKSHOP_TEST_FAIL']='gmpublish'
    result, records = publish()
    assert result.returncode==13 and len(records)==2 and 'Workshop update complete' not in result.stdout

    env['GMPUBLISH']=str(windows/'gmpublish.exe')
    env['GMAD']=str(windows/'gmad.exe')
    env['LOD_WORKSHOP_TEST_FAIL']='not-a-tool'
    result, records = publish()
    assert result.returncode==0 and all(r['proton'] for r in records), 'explicit overrides ignored'
    env['LOD_PROTON']=str(base/'missing-proton')
    result, records = publish()
    assert result.returncode!=0 and not records and 'Proton Experimental is unavailable' in result.stderr
    env['GMAD']=str(base/'missing-gmad')
    result, records = publish()
    assert result.returncode!=0 and not records and 'GMAD does not identify' in result.stderr
print('PASS Workshop shell flow: native/Proton discovery, explicit paths, Windows arguments, staging, app/prefix, failures and missing tools')
