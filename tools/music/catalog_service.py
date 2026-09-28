#!/usr/bin/env python3
"""Authenticated, data-only music ingestion behind an operator's HTTPS proxy.

Nothing in this service uses GMod's game socket. Published audio is served by the
proxy from ROOT/music; uploads use a separate bearer token, never a game snapshot.
"""
from __future__ import annotations
import argparse
import contextlib
import fcntl
import hashlib
import hmac
import io
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import uuid
import zipfile

ROLES = ('T0', 'T1', 'T2', 'T3', 'BOSS', 'VICTORY', 'INTERLUDE')
MAX_FILE = 4 * 1024 * 1024
MAX_UPLOAD = 30 * 1024 * 1024
MAX_DURATION = 180
IDENTITY = re.compile(r'[a-z0-9][a-z0-9_-]{0,63}\Z')
ORIGIN = re.compile(r'https://[a-zA-Z0-9][a-zA-Z0-9.-]*(?::[0-9]+)?\Z')

def require(ok, message):
    if not ok:
        raise ValueError(message)

def identity(value):
    require(isinstance(value, str) and IDENTITY.fullmatch(value), 'unsafe ID/version')
    return value

def text(value, limit=512):
    require(isinstance(value, str) and 0 < len(value.encode()) <= limit and all(ord(c) >= 32 and ord(c) != 127 for c in value), 'invalid title/credits/source')
    return value

def number(value, lo, hi):
    require(type(value) in (int, float) and math.isfinite(value) and lo <= value <= hi, 'invalid numeric metadata')
    return value

def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as f:
        json.dump(value, f, sort_keys=True, indent=2)
        f.write('\n'); f.flush(); os.fsync(f.fileno())
        name = f.name
    os.replace(name, path)

def probe(path):
    info = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(path)], timeout=15))
    streams = info['streams']
    require(len(streams) == 1 and streams[0]['codec_name'] == 'vorbis' and streams[0]['codec_type'] == 'audio', 'expected one Vorbis audio stream')
    stream = streams[0]
    require(int(stream['sample_rate']) == 44100 and stream['channels'] == 2, 'expected stereo 44.1 kHz')
    duration = float(stream.get('duration') or info['format']['duration'])
    number(duration, 1, MAX_DURATION)
    subprocess.run(['ffmpeg', '-v', 'error', '-xerror', '-i', str(path), '-f', 'null', '-'], check=True, timeout=30, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    return duration

def validate_folder(folder):
    manifest_path = folder / 'manifest.json'
    require(manifest_path.is_file() and manifest_path.stat().st_size <= 65536, 'manifest missing/too large')
    manifest = json.loads(manifest_path.read_text())
    require(isinstance(manifest, dict) and not set(manifest) - {'schema','kind','id','version','title','credits','roles'}, 'unknown manifest fields')
    require(manifest.get('schema') == 1 and manifest.get('kind') in ('block', 'profile'), 'unsupported manifest schema/kind')
    bid, version = identity(manifest.get('id')), identity(manifest.get('version'))
    title, credits = text(manifest.get('title'), 128), text(manifest.get('credits'))
    roles = manifest.get('roles')
    require(isinstance(roles, dict) and not set(roles) - set(ROLES), 'invalid roles')
    # Deliberate omissions inherit; a declared but absent file always fails.
    assets, resolved, declared, siblings = {}, {}, set(), []
    for role in ROLES:
        spec = roles.get(role, 'inherit')
        if spec == 'inherit':
            resolved[role] = 'inherit'
            continue
        require(isinstance(spec, dict), 'role must be an asset or inherit')
        require(not set(spec) - {'file','hash','bytes','duration','codec','rate','channels','loop','loopStart','loopEnd',
            'bpm','beats','phase','gain','headroom','grid','handoff','credits','source'}, 'unknown asset fields')
        name = spec.get('file')
        require(isinstance(name, str) and re.fullmatch(r'[a-z0-9_-]{1,80}\.ogg', name), 'unsafe audio filename')
        path = folder / name
        require(path.is_file() and not path.is_symlink() and 0 < path.stat().st_size <= MAX_FILE, 'declared asset missing/too large')
        data = path.read_bytes(); digest = hashlib.sha256(data).hexdigest()
        require(spec.get('hash') == digest and spec.get('bytes') == len(data), 'asset hash/size mismatch')
        duration = probe(path)
        number(spec.get('duration'), 1, MAX_DURATION)
        require(abs(duration - spec['duration']) < .025, 'decoded duration mismatch')
        require(spec.get('codec') == 'vorbis' and spec.get('rate') == 44100 and spec.get('channels') == 2, 'invalid encoding metadata')
        require(type(spec.get('loop')) is bool and spec['loop'] == (role != 'VICTORY'), 'invalid role loop policy')
        require(spec.get('loopStart') == 0 and abs(number(spec.get('loopEnd'), 1, MAX_DURATION) - duration) < .025, 'master full-file loop boundaries before import')
        require(spec.get('handoff') == 'envelope', 'missing authored envelope handoff')
        bpm = number(spec.get('bpm'), 40, 240)
        beats = number(spec.get('beats'), 1, 720)
        require(int(beats) == beats, 'beat count must be integral')
        phase = number(spec.get('phase'), 0, duration)
        grid = identity(spec.get('grid'))
        if role != 'VICTORY':
            require(abs(beats * 60 / bpm - duration) < .025, 'loop duration does not match grid')
        else:
            require(5 <= duration <= 12, 'fanfare must have a finite 5–12 second phrase/tail')
        if role.startswith('T'):
            siblings.append((grid, bpm, beats, phase, round(duration, 2)))
        gain = number(spec.get('gain'), 0, 1)
        headroom = number(spec.get('headroom'), 0, 24)
        asset = dict(spec)
        asset.pop('file')
        asset.update(path=f'music/blocks/{bid}/{version}/{name}', duration=duration, loopEnd=duration,
                     credits=text(spec.get('credits', credits)), source=text(spec.get('source')),
                     gain=gain, headroom=headroom)
        # One hash may be reused, but cannot claim incompatible timing/loop policy.
        if digest in assets:
            require({k:v for k,v in assets[digest].items() if k != 'path'} == {k:v for k,v in asset.items() if k != 'path'}, 'inconsistent shared asset metadata')
        else:
            assets[digest] = asset
        resolved[role] = digest; declared.add(name)
    require(len(set(siblings)) <= 1, 'custom tension siblings must share a transport')
    require(set(p.name for p in folder.iterdir()) == declared | {'manifest.json'}, 'undeclared bundle files')
    return manifest, assets, {'title': title, 'version': version, 'credits': credits, 'roles': resolved}

class CatalogStore:
    def __init__(self, root, origin, game_data=None):
        self.root = Path(root).resolve()
        require(ORIGIN.fullmatch(origin), 'public origin must be HTTPS with no credentials/path/query')
        self.origin = origin
        self.game_data = Path(game_data).resolve() if game_data else None
        self.root.mkdir(parents=True, exist_ok=True)
        (self.root / 'staging').mkdir(exist_ok=True)

    @contextlib.contextmanager
    def lock(self):
        with (self.root / 'catalog.lock').open('a') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            yield

    def catalog(self):
        path = self.root / 'catalog.json'
        return json.loads(path.read_text()) if path.exists() else dict(schema=1, revision='empty', origin=self.origin, assets={}, blocks={}, profiles={}, sets={})

    def stage(self, body):
        require(len(body) <= MAX_UPLOAD, 'upload too large')
        # Flat whitelisted ZIP only: no paths, links, encryption or expansion bombs.
        with zipfile.ZipFile(io.BytesIO(body)) as z:
            infos = z.infolist()
            require(len(infos) <= 8 and len({i.filename for i in infos}) == len(infos), 'invalid bundle members')
            require(sum(i.file_size for i in infos) <= MAX_UPLOAD, 'expanded upload too large')
            for i in infos:
                require(i.filename == 'manifest.json' or re.fullmatch(r'[a-z0-9_-]{1,80}\.ogg', i.filename), 'unsafe ZIP path')
                require(not i.flag_bits & 1 and (i.external_attr >> 16) & 0o170000 in (0, 0o100000), 'links/directories/encryption forbidden')
                require(i.file_size <= (65536 if i.filename == 'manifest.json' else MAX_FILE), 'member too large')
            upload_id = uuid.uuid4().hex
            destination = self.root / 'staging' / upload_id
            with tempfile.TemporaryDirectory(dir=self.root / 'staging') as tmp:
                folder = Path(tmp)
                for i in infos:
                    (folder / i.filename).write_bytes(z.read(i))
                validate_folder(folder)
                with self.lock():
                    require(len(list((self.root / 'staging').iterdir())) <= 16, 'staging full; operator must prune abandoned uploads')
                    os.rename(folder, destination)
        return upload_id

    def publish(self, upload_id):
        identity(upload_id)
        folder = self.root / 'staging' / upload_id
        require(folder.is_dir() and not folder.is_symlink(), 'unknown staged upload')
        with self.lock():
            manifest, assets, block = validate_folder(folder)
            bid, version = manifest['id'], manifest['version']
            catalog = self.catalog()
            require(catalog['origin'] == self.origin, 'origin is immutable; migrate explicitly')
            target = self.root / 'music' / 'blocks' / bid / version
            require(not target.exists(), 'immutable version already exists')
            collection = 'profiles' if manifest['kind'] == 'profile' else 'blocks'
            catalog[collection][bid] = block
            for key, asset in assets.items():
                old = catalog['assets'].get(key)
                if old:
                    require({k:v for k,v in old.items() if k != 'path'} == {k:v for k,v in asset.items() if k != 'path'}, 'existing hash metadata conflict')
                else:
                    catalog['assets'][key] = asset
            require(len(catalog['blocks']) <= 256 and len(catalog['profiles']) <= 64 and len(catalog['assets']) <= 1792, 'catalog capacity reached')
            catalog['revision'] = uuid.uuid4().hex
            require(len(json.dumps(catalog).encode()) <= 2 * 1024 * 1024, 'catalog too large')
            target.parent.mkdir(parents=True, exist_ok=True)
            os.rename(folder, target)
            # A crash here may leave an unreferenced immutable folder, never a
            # published manifest pointing at a partly uploaded file.
            atomic_json(self.root / 'catalog.json', catalog)
            self.mirror(catalog, upload_id)
            return catalog['revision']

    def mirror(self, catalog, upload_id=None):
        if self.game_data:
            if upload_id:
                atomic_json(self.game_data / 'imports' / f'{upload_id}.json', catalog)
            atomic_json(self.game_data / 'catalog.json', catalog)
            atomic_json(self.game_data / 'reload.json', {'revision': catalog['revision']})

    def configure(self, metadata):
        """Local operator-only metadata edit: references existing assets/blocks."""
        with self.lock():
            c = self.catalog()
            if 'projectDefault' in metadata:
                profile = identity(metadata['projectDefault'])
                require(profile in c['profiles'], 'unknown project default profile')
                require(all(c['profiles'][profile]['roles'].get(role) in c['assets'] for role in ROLES), 'project defaults must cover all seven roles')
                c['projectDefault'] = profile
            if 'sets' in metadata:
                require(isinstance(metadata['sets'], dict) and len(metadata['sets']) <= 128, 'invalid sets')
                for sid, spec in metadata['sets'].items():
                    identity(sid);require(sid != 'all', 'all is reserved')
                    identity(spec['revision']);text(spec['title'],128)
                    require(isinstance(spec['members'], list) and len(spec['members']) <= 256, 'invalid member list')
                    for bid in spec['members']:
                        identity(bid);require(bid in c['blocks'], 'unknown set member')
                    spec['members'] = sorted(set(spec['members']))
                    require(spec['members'], 'empty set')
                c['sets'] = metadata['sets']
            c['revision'] = uuid.uuid4().hex
            atomic_json(self.root / 'catalog.json', c);self.mirror(c)
            return c['revision']

def application(store, token):
    require(len(token) >= 32, 'set a strong MUSIC_UPLOAD_TOKEN (at least 32 characters)')
    def app(env, start):
        status, response = '200 OK', {}
        try:
            auth = env.get('HTTP_AUTHORIZATION', '')
            if not hmac.compare_digest(auth, 'Bearer ' + token):
                start('401 Unauthorized', [('Content-Type','application/json')]);return [b'{"error":"unauthorized"}']
            require(env.get('REQUEST_METHOD') == 'POST', 'POST required')
            path = env.get('PATH_INFO','')
            if path == '/v1/uploads':
                length = int(env.get('CONTENT_LENGTH','0'))
                require(0 < length <= MAX_UPLOAD, 'bounded Content-Length required')
                body = env['wsgi.input'].read(length)
                require(len(body) == length, 'interrupted upload')
                response = {'upload_id': store.stage(body)}
            elif re.fullmatch(r'/v1/imports/[a-z0-9_-]{1,64}', path):
                response = {'revision': store.publish(path.rsplit('/',1)[1])}
            else:
                raise ValueError('unknown endpoint')
        except (ValueError, KeyError, OSError, zipfile.BadZipFile, subprocess.SubprocessError) as e:
            status, response = '400 Bad Request', {'error': str(e)[:240]}
        data = json.dumps(response).encode()
        start(status, [('Content-Type','application/json'),('Content-Length',str(len(data))),('Cache-Control','no-store')])
        return [data]
    return app

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, required=True);p.add_argument('--origin',required=True)
    p.add_argument('--game-data',type=Path);p.add_argument('--port',type=int,default=8787)
    p.add_argument('--import-folder',type=Path);p.add_argument('--configure',type=Path)
    args = p.parse_args();store=CatalogStore(args.root,args.origin,args.game_data)
    if args.configure:
        print(store.configure(json.loads(args.configure.read_text())));return
    if args.import_folder:
        from lod_music_upload import bundle
        uid=store.stage(bundle(args.import_folder));print(json.dumps({'upload_id':uid,'revision':store.publish(uid)}));return
    from wsgiref.simple_server import make_server
    app=application(store,os.environ.get('MUSIC_UPLOAD_TOKEN',''))
    with make_server('127.0.0.1',args.port,app) as server:
        server.serve_forever()
if __name__ == '__main__':
    main()
