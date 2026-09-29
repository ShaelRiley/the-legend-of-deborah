#!/usr/bin/env python3
"""Real six-role ZIP preparation, first defaults, cue rebuild and atomic failure."""
import copy
import json
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
from unittest.mock import patch
import wave
import zipfile
import numpy as np

sys.path.insert(0, str(Path(__file__).parent / 'music'))
from catalog_service import CatalogStore, CHUNK_BYTES
from folder_catalog import FILES, prepare_library, library_source
from section_cues import infer_grid

checks = 0
def check(ok, why):
    global checks
    checks += 1
    assert ok, why

def reject(fn, why):
    try:
        fn()
    except (ValueError, KeyError, OSError, zipfile.BadZipFile):
        check(True, why)
    else:
        raise AssertionError(why)

def encode(path, role, tempo=120, duration=16):
    sr = 11025
    t = np.arange(round(sr*duration))/sr
    freq = 170 + list(FILES).index(role)*31
    samples = .08*np.sin(2*np.pi*freq*t)
    if role not in ('T0', 'VICTORY'):
        for start in np.arange(0, duration-.25, 60/tempo):
            a = round(start*sr); n = round(.24*sr); x = np.arange(n)/sr
            samples[a:a+n] += .45*np.sin(2*np.pi*70*x)*np.exp(-18*x)
    wav = path.with_suffix('.wav')
    with wave.open(str(wav), 'wb') as stream:
        stream.setnchannels(2); stream.setsampwidth(2); stream.setframerate(sr)
        stream.writeframes(np.repeat(np.round(samples*32767).astype('<i2')[:, None], 2, axis=1).tobytes())
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(wav), '-ar', '44100',
                    '-c:a', 'libvorbis', '-b:a', '128k', str(path)], check=True)
    wav.unlink()

def pack(root, zip_path, wrapper=True):
    with zipfile.ZipFile(zip_path, 'w') as archive:
        for path in sorted(root.rglob('*')):
            name = ('music/' if wrapper else '') + path.relative_to(root).as_posix()
            archive.write(path, name)

def lua(value):
    if isinstance(value, dict):
        return '{' + ','.join('['+json.dumps(k)+']='+lua(v) for k,v in value.items()) + '}'
    if isinstance(value, list):
        return '{' + ','.join(map(lua, value)) + '}'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    return json.dumps(value)

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp); music = root/'music'; first = music/'1-default'; first.mkdir(parents=True)
    for role, filename in FILES.items():
        encode(first/(filename+'.ogg'), role, duration=6.5 if role == 'VICTORY' else 16)
    second = music/'2-cavern'; second.mkdir()
    shutil.copy(first/'tension3.ogg', second/'attention3.ogg')
    third = music/'10-echo'; third.mkdir()
    shutil.copy(first/'chill.ogg', third/'tension1.ogg')
    empty = music/'20-inherited'; empty.mkdir()
    archive = root/'music.zip'; pack(music, archive)
    store = CatalogStore(root/'host', 'https://music.example.test', root/'game')
    preview = prepare_library(store, archive, validate_only=True)
    check(not preview['published'] and not (store.root/'catalog.json').exists(), 'check prepares without publishing')
    report = prepare_library(store, archive)
    check(report['blocks'] == 4 and report['default_block'] == '1-default', 'natural ordering chooses block one')
    c = store.catalog()
    check(c['blocks']['2-cavern']['roles']['T0'] == 'inherit', 'missing Chill inherits')
    check(c['blocks']['2-cavern']['roles']['T2'] == c['blocks']['1-default']['roles']['T2'], 'attention3 alias and shared bytes')
    check(all(role == 'inherit' for role in c['blocks']['20-inherited']['roles'].values()), 'empty later folder inherits all roles')
    check(len(c['assets']) == 6, 'Chill and interlude share one recording; fallback never copies audio')
    check(all(b['roles']['INTERLUDE'] == b['roles']['T0'] for b in c['blocks'].values()), 'every block aliases Chill for staging')
    for asset in c['assets'].values():
        check(asset['delivery'] == 1, 'chunks prepared before publication')
        check((store.root/'music/chunks'/asset['hash']).stat().st_mode & 0o777 == 0o755,
              'published chunk directories traversable by nginx worker')
        parts = sorted((store.root/'music/chunks'/asset['hash']).glob('*.dat'), key=lambda p:int(p.stem))
        check(all(p.stat().st_size <= CHUNK_BYTES for p in parts), 'delivery chunks bounded')
        check(all(p.stat().st_mode & 0o777 == 0o644 for p in parts), 'public chunks readable outside importer account')
        check(b''.join(p.read_bytes() for p in parts) == (store.root/asset['path']).read_bytes(), 'exact chunks reproduce Ogg')
        if asset['loop']:
            check(asset['cues']['source'] == 'analyzed-v1', 'real offline cues generated automatically')
        else:
            check('cues' not in asset and 5 <= asset['duration'] <= 12, 'finite one-shot fanfare has no section loop')
    check(json.loads((root/'game/catalog.json').read_text()) == c, 'whole catalog mirrored once')
    check(json.loads((root/'game/reload.json').read_text())['revision'] == c['revision'], 'future-plan reload queued')
    with patch('folder_catalog.prepare_block', side_effect=AssertionError('unchanged block reanalyzed')):
        again = prepare_library(store, music)
    check(again['unchanged'] and again['revision'] == c['revision'] and again['reused_blocks'] == 4, 'folder/ZIP reimport is idempotent and skips analysis')
    # Validate the actual generated payload through production Lua, then exercise
    # first-block inheritance, universal themes and frozen source metadata.
    harness = root/'catalog.lua'
    harness.write_text("local e=dofile('tools/music_test_fixture.lua'); local M=LOD.Music\nlocal c="+lua(c)+"\n"+'''
assert(M.ValidateCatalog(c))
assert(M.RoleNames.T0 == 'Chill (Tension 1)' and M.RoleNames.T3 == 'Tension 4')
for _,role in ipairs(M.Roles) do
 local r=M.Candidates(c,c.blocks['20-inherited'],role,{profile='obsolete'})
 assert(#r==1 and r[1].asset==c.blocks['1-default'].roles[role] and r[1].source=='first-block-default')
end
for _,role in ipairs({'BOSS','VICTORY','INTERLUDE'}) do
 local r=M.Candidates(c,c.blocks['1-default'],role,{['universal_'..role:lower()]=true})
 assert(#r==1 and r[1].source=='first-block-default')
end
local p=assert(M.Plan(c,{set='all'},17,'run:1',4,1))
local original=c.assets[c.blocks['1-default'].roles.T0].cues.quiet[1].energy
c.assets[c.blocks['1-default'].roles.T0].cues.quiet[1].energy=.123
assert(p.assets[c.blocks['1-default'].roles.T0].cues.quiet[1].energy==original)
local bad=table.Copy(c);bad.blocks['1-default'].roles.BOSS='inherit';assert(not M.ValidateCatalog(bad))
bad=table.Copy(c);bad.blocks['10-echo'].roles.INTERLUDE='inherit';assert(not M.ValidateCatalog(bad))
bad=table.Copy(c);bad.assets[bad.blocks['1-default'].roles.T0].cues=nil;assert(not M.ValidateCatalog(bad))
bad=table.Copy(c);bad.assets[bad.blocks['1-default'].roles.T0].delivery=nil;assert(not M.ValidateCatalog(bad))
SERVER=true;LOD.RunManager={};player={GetAll=function() return {} end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_music.lua')
local D=LOD.MusicDirector;D.Settings.profile='obsolete'
file.Read=function() return util.TableToJSON(c) end
assert(D:LoadCatalog());assert(not D.Warning)
assert(not D:Configure('profile','obsolete'))
assert(not D:Enabled())
print('GENERATED_FOLDER_CATALOG_LUA PASS')
''')
    subprocess.run(['python3','tools/run_lua54.py',str(harness)], check=True)
    check(True, 'generated catalog accepted by actual runtime; exact fallback, freezes and offline readiness enforced')
    original_manifest = (store.root/'music/blocks/1-default'/c['blocks']['1-default']['version']/'manifest.json').read_bytes()
    # Explicit cue rebuild makes new metadata for the same immutable media.
    cue = copy.deepcopy(c['assets'][c['blocks']['1-default']['roles']['T1']]['cues'])
    cue['source'] = 'authored';cue['pulse'][0]['energy'] = .5
    (first/'block.json').write_text(json.dumps({'cues':{'tension2':cue}}))
    rebuilt = prepare_library(store, music, rebuild_cues=True)
    after = store.catalog()
    check(rebuilt['prepared_blocks'] == 4 and after['revision'] != c['revision'], 'explicit rebuild prepares and versions complete cue maps')
    check(after['assets'][c['blocks']['1-default']['roles']['T1']]['cues'] == cue, 'auditioned authored overrides retained')
    check((store.root/'music/blocks/1-default'/c['blocks']['1-default']['version']/'manifest.json').read_bytes() == original_manifest, 'previous version not overwritten')
    check(c['assets'][c['blocks']['1-default']['roles']['T1']]['cues']['source'] == 'analyzed-v1', 'previous plan snapshot unchanged')
    before = (store.root/'catalog.json').read_bytes(); mirror = (root/'game/catalog.json').read_bytes()
    def intact():
        check((store.root/'catalog.json').read_bytes() == before and (root/'game/catalog.json').read_bytes() == mirror,
              'failure leaves both published catalogs intact')
    (second/'boss.ogg').write_bytes(b'corrupt recording')
    reject(lambda:prepare_library(store, music), 'bad declared media rejected')
    intact();(second/'boss.ogg').unlink()
    shutil.copy(first/'chill.ogg', first/'attention1.ogg')
    reject(lambda:prepare_library(store, music), 'duplicate aliases reject');intact();(first/'attention1.ogg').unlink()
    (first/'boss.ogg').rename(root/'boss.ogg')
    reject(lambda:prepare_library(store, music), 'incomplete first block rejects');intact();(root/'boss.ogg').rename(first/'boss.ogg')
    (second/'chill.ogg').symlink_to(first/'chill.ogg')
    reject(lambda:prepare_library(store, music), 'local symlinks reject');intact();(second/'chill.ogg').unlink()
    malicious = root/'bad.zip'
    for names in (['../escaped.ogg'], ['/music/1/a.ogg'], ['music/1/../chill.ogg'],
                  ['music/1/chill.ogg','music/1/chill.ogg'], ['music/1/unknown.exe']):
        with zipfile.ZipFile(malicious,'w') as z:
            for name in names:z.writestr(name,b'bad')
        reject(lambda:prepare_library(store, malicious), 'unsafe ZIP rejected');intact()
    with zipfile.ZipFile(malicious,'w') as z:
        info=zipfile.ZipInfo('music/1/chill.ogg');info.external_attr=(stat.S_IFLNK|0o777)<<16
        z.writestr(info,'/etc/passwd')
    reject(lambda:prepare_library(store, malicious), 'ZIP symlink rejects');intact()
    with zipfile.ZipFile(malicious,'w') as z:
        z.writestr('music/1/chill.ogg',b'a'*(4*1024*1024+1))
    reject(lambda:prepare_library(store, malicious), 'oversize member rejects before extraction');intact()
    # A later block failure must not register any earlier prepared block.
    (first/'block.json').write_text(json.dumps({'title':'Changed title', 'cues':{'tension2':cue}}))
    shutil.copy(first/'chill.ogg', second/'boss.ogg')
    reject(lambda:prepare_library(store, music), 'loudness cannot make a quiet drone a combat cue');intact()
    (second/'boss.ogg').unlink()
    # Saved set loss and concurrent catalog edits also fail before registration.
    old = store.catalog();old['sets']={'keep':dict(title='Keep',revision='v1',members=['missing'])}
    from catalog_service import atomic_json
    atomic_json(store.root/'catalog.json',old)
    reject(lambda:prepare_library(store,music),'cannot silently remove a saved set member')
    (store.root/'catalog.json').write_bytes(before)
    tempo = root/'tempo.ogg';encode(tempo, 'T3', tempo=150, duration=12.8)
    bpm,beats=infer_grid(tempo,12.8)
    check(abs(bpm-150)<.01 and beats==32, 'onset grid discovers non-default tempo')
    reject(lambda:infer_grid(tempo,12.8,121),'invalid authored timing fails clearly')
    # Exercise the documented user command, not just its imported functions.
    config = root/'config.json'
    cmd = ['python3','tools/music/lod_music_catalog.py','--config',str(config)]
    subprocess.run(cmd+['setup','--root',str(store.root),'--origin',store.origin,'--game-data',str(root/'game')],check=True,stdout=subprocess.DEVNULL)
    status = json.loads(subprocess.check_output(cmd+['status']))
    check(status['default_block']=='1-default' and not status['unprepared_assets'],'operator status confirms prepared library')
    pack(music, archive, wrapper=False)
    done = json.loads(subprocess.check_output(cmd+['import',str(archive)]))
    check(done['published'] and done['blocks']==4, 'documented CLI accepts ZIP without optional music wrapper')
print(f'MUSIC_FOLDER_CATALOG PASS {checks}')
