#!/usr/bin/env python3
"""Prepare a complete six-role music library offline, then publish it once.

The input is music/<block>/<role>.ogg or a ZIP with that layout. No authored
manifest is necessary. This uses CatalogStore and validate_folder, the same
authorities as the legacy authenticated single-block uploader.
"""
from __future__ import annotations
import contextlib
import copy
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import tempfile
import zipfile

from catalog_service import (MAX_FILE, ROLES, atomic_json, identity, number,
                             probe, require, text, validate_folder)
from section_cues import infer_grid

MAX_LIBRARY = 1024 * 1024 * 1024
MAX_BLOCKS = 256
FORMAT = 'six-role-v1'
FILES = dict(T0='chill', T1='tension2', T2='tension3', T3='tension4',
             BOSS='boss', VICTORY='fanfare')
ALIASES = {name: role for role, name in FILES.items()}
ALIASES.update(tension1='T0', attention1='T0', attention2='T1',
               attention3='T2', attention4='T3', t0='T0', t1='T1',
               t2='T2', t3='T3', victory='VICTORY')


def digest_json(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':'),
                                     allow_nan=False).encode()).hexdigest()


def natural_key(name):
    # Tuple tags keep mixed numeric/alphabetic prefixes comparable.
    return tuple((0, int(s)) if s.isdigit() else (1, s)
                 for s in re.split(r'(\d+)', name))


def regular(path):
    return stat.S_ISREG(path.lstat().st_mode)


@contextlib.contextmanager
def library_source(source):
    """Stream a whitelisted archive into a disposable private directory."""
    source = Path(source).absolute()
    require(not source.is_symlink(), 'music source cannot be a symlink')
    if source.is_dir():
        yield source
        return
    require(source.is_file() and source.stat().st_size <= MAX_LIBRARY,
            'expected a music folder or ZIP of at most 1 GiB')
    with zipfile.ZipFile(source) as archive, tempfile.TemporaryDirectory(prefix='lod-music-') as tmp:
        infos = archive.infolist()
        require(len(infos) <= 1 + MAX_BLOCKS * 8, 'too many ZIP members')
        require(sum(i.file_size for i in infos) <= MAX_LIBRARY, 'expanded library exceeds 1 GiB')
        seen = set()
        for info in infos:
            name = info.filename.rstrip('/')
            parts = PurePosixPath(name).parts
            mode = (info.external_attr >> 16) & 0o170000
            require(name and not info.filename.startswith('/') and '\\' not in name
                    and all(p not in ('', '.', '..') for p in name.split('/'))
                    and len(parts) <= 3 and name not in seen, 'unsafe/duplicate ZIP path')
            seen.add(name)
            require(not info.flag_bits & 1 and mode in (0, stat.S_IFREG, stat.S_IFDIR)
                    and (mode != stat.S_IFDIR or info.is_dir()), 'ZIP links/special files/encryption forbidden')
            for part in parts[:-1] if not info.is_dir() else parts:
                identity(part)
            if not info.is_dir():
                leaf = parts[-1]
                require(leaf == 'block.json' or leaf.endswith('.ogg') and leaf[:-4] in ALIASES,
                        f'unknown music ZIP file: {leaf}')
                require(info.file_size <= (65536 if leaf == 'block.json' else MAX_FILE), 'ZIP member too large')
            target = Path(tmp).joinpath(*parts)
            if info.is_dir():
                require(info.file_size == 0, 'directory has data')
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(info) as inp, target.open('xb') as out:
                    shutil.copyfileobj(inp, out, 65536)
                require(target.stat().st_size == info.file_size, 'incomplete ZIP member')
        root = Path(tmp)
        if (root / 'music').is_dir():
            require(set(p.name for p in root.iterdir()) == {'music'}, 'ZIP must contain only music/')
            root /= 'music'
        yield root


def inventory(root):
    folders = list(root.iterdir())
    require(0 < len(folders) <= MAX_BLOCKS, 'music must contain 1–256 block folders')
    result, total = [], 0
    for folder in sorted(folders, key=lambda p: (natural_key(p.name), p.name)):
        identity(folder.name)
        require(folder.is_dir() and not folder.is_symlink(), f'{folder.name}: expected a block folder')
        roles, hashes, metadata = {}, {}, {}
        for path in sorted(folder.iterdir()):
            require(regular(path), f'{folder.name}/{path.name}: links/subfolders/special files forbidden')
            size = path.stat().st_size
            total += size
            require(total <= MAX_LIBRARY, 'library exceeds 1 GiB')
            if path.name == 'block.json':
                require(size <= 65536, 'block.json too large')
                metadata = json.loads(path.read_text())
                require(isinstance(metadata, dict) and not set(metadata) -
                        {'title', 'credits', 'bpm', 'boss_bpm', 'cues'}, 'unknown block.json fields')
                continue
            require(path.suffix == '.ogg' and path.stem in ALIASES,
                    f'{folder.name}/{path.name}: use named Ogg Vorbis role files')
            role = ALIASES[path.stem]
            require(role not in roles, f'{folder.name}: duplicate aliases for {FILES[role]}')
            require(0 < size <= MAX_FILE, f'{path.name}: recording exceeds 4 MiB or is empty')
            roles[role] = path
            hashes[role] = hashlib.sha256(path.read_bytes()).hexdigest()
        fingerprint = digest_json(dict(format=FORMAT, hashes=hashes, metadata=metadata))
        result.append((folder.name, roles, hashes, metadata, fingerprint))
    missing = set(FILES) - set(result[0][1])
    require(not missing, 'first block needs all six defaults; missing: ' +
            ', '.join(FILES[r] + '.ogg' for r in sorted(missing)))
    return result


def prepare_block(entry, destination, known_assets=None):
    bid, paths, hashes, meta, fingerprint = entry
    title = text(meta.get('title', bid.replace('_', ' ').replace('-', ' ')), 128)
    credits = text(meta.get('credits', 'Operator-supplied music'))
    overrides = meta.get('cues', {})
    require(isinstance(overrides, dict) and not set(overrides) - set(FILES.values()), 'unknown cue override role')
    require('fanfare' not in overrides, 'fanfare is one-shot and has no looping section cues')
    require(all(FILES[r] not in overrides or r in paths for r in FILES), 'cue override without a recording')
    durations = {}
    for role, path in paths.items():
        try:
            durations[role] = probe(path)
        except (ValueError, subprocess.SubprocessError) as exc:
            raise ValueError(f'{path.name}: not a valid stereo 44.1 kHz Vorbis recording: {exc}') from exc
    known_assets = known_assets or {}
    def grid_for(role, hint):
        known = known_assets.get(hashes[role])
        if hint is None and known:
            return known['bpm'], known['beats']
        return infer_grid(paths[role], durations[role], hint)
    tensions = [r for r in ('T3', 'T2', 'T1', 'T0') if r in paths]
    grid = None
    if tensions:
        reference = tensions[0]
        require(max(durations[r] for r in tensions) - min(durations[r] for r in tensions) < .025,
                'custom tension recordings must have the same duration')
        grid = grid_for(reference, meta.get('bpm'))
    elif 'bpm' in meta:
        number(meta['bpm'], 40, 240)
    boss_grid = None
    if 'BOSS' in paths:
        shared_tension = any(hashes['BOSS'] == hashes[r] for r in tensions)
        boss_grid = grid if shared_tension and 'boss_bpm' not in meta else grid_for('BOSS', meta.get('boss_bpm'))
    roles = {}
    destination.mkdir()
    for role, path in paths.items():
        duration = durations[role]
        if role == 'VICTORY':
            bpm, beats = 120, max(1, round(duration * 2))
        else:
            bpm, beats = boss_grid if role == 'BOSS' else grid
        name = FILES[role] + '.ogg'
        shutil.copyfile(path, destination / name)
        spec = dict(file=name, hash=hashes[role], bytes=path.stat().st_size,
                    duration=duration, codec='vorbis', rate=44100, channels=2,
                    loop=role != 'VICTORY', loopStart=0, loopEnd=duration,
                    bpm=bpm, beats=beats, phase=0, grid='auto-' + digest_json([bpm, beats])[:16],
                    handoff='envelope', gain=1, headroom=0,
                    credits=credits, source='Operator folder library')
        if FILES[role] in overrides:
            spec['cues'] = overrides[FILES[role]]
            require(isinstance(spec['cues'], dict) and spec['cues'].get('source') == 'authored',
                    'cue overrides must be marked source: authored')
        roles[role] = spec
    # The compatibility role is an alias, including inheritance from block one.
    roles['INTERLUDE'] = copy.deepcopy(roles.get('T0', 'inherit'))
    manifest = dict(schema=1, kind='block', id=bid, version='preparing', title=title,
                    credits=credits, roles=roles)
    atomic_json(destination / 'manifest.json', manifest)
    manifest, assets, block = validate_folder(destination)
    version = 'v-' + digest_json({k:v for k,v in manifest.items() if k != 'version'})[:32]
    manifest['version'] = block['version'] = version
    for asset in assets.values():
        asset['path'] = f'music/blocks/{bid}/{version}/{Path(asset["path"]).name}'
    atomic_json(destination / 'manifest.json', manifest)
    return manifest, assets, block


def prepare_library(store, source, rebuild_cues=False, validate_only=False):
    """A complete folder snapshot is the new pool; immutable old media stays.

    Preparation is outside the lock. A concurrent catalog edit is detected at
    commit, so a slow import cannot silently overwrite another operator's work.
    """
    old = store.catalog()
    require(old['origin'] == store.origin, 'origin is immutable; migrate explicitly')
    with library_source(source) as root, tempfile.TemporaryDirectory(dir=store.root / 'staging') as tmp:
        entries = inventory(root)
        prepared, fingerprints, reused, known_assets = [], {}, 0, {}
        for entry in entries:
            bid, paths, hashes, meta, fingerprint = entry
            fingerprints[bid] = fingerprint
            prior = old.get('folderSources', {}).get(bid)
            block = old['blocks'].get(bid)
            if not rebuild_cues and prior == fingerprint and block:
                folder = store.root / 'music' / 'blocks' / bid / block['version']
                # Reuse only published prepared metadata. Audio hashes are still
                # checked by chunks() before a catalog can be made visible.
                manifest = json.loads((folder / 'manifest.json').read_text())
                assets = {}
                for spec in manifest['roles'].values():
                    if isinstance(spec, dict):
                        asset = copy.deepcopy(old['assets'][spec['hash']])
                        asset['path'] = f'music/blocks/{bid}/{block["version"]}/{spec["file"]}'
                        assets[spec['hash']] = asset
                prepared.append((folder, manifest, assets, copy.deepcopy(block)))
                known_assets.update(assets)
                reused += 1
                continue
            folder = Path(tmp) / bid
            try:
                manifest, assets, block = prepare_block(entry, folder, known_assets)
            except (ValueError, KeyError) as exc:
                raise ValueError(f'{bid}: {exc}') from exc
            prepared.append((folder, manifest, assets, block))
            known_assets.update(assets)
        catalog = copy.deepcopy(old)
        catalog['blocks'] = {manifest['id']: block for _, manifest, _, block in prepared}
        catalog['defaultBlock'] = entries[0][0]
        catalog['folderSources'] = fingerprints
        # This is a complete library snapshot. Legacy default profiles must not
        # compete with the first block or impose stale metadata on shared bytes.
        catalog['profiles'] = {}
        catalog['assets'] = {}
        catalog.pop('projectDefault', None)
        for spec in catalog['sets'].values():
            require(all(bid in catalog['blocks'] for bid in spec['members']),
                    'library would remove a saved set member; update that set before removing its folder')
        # Check batch collisions before using the shared merge authority. Each
        # fresh snapshot may update prepared metadata; frozen plans own copies.
        seen = {}
        for _, _, assets, _ in prepared:
            for key, asset in assets.items():
                comparable = {k:v for k,v in asset.items() if k not in ('path', 'delivery')}
                require(key not in seen or seen[key] == comparable, 'conflicting shared recording metadata within library')
                seen[key] = comparable
        report = dict(blocks=len(entries), default_block=entries[0][0], reused_blocks=reused,
                      prepared_blocks=len(entries)-reused, validated=True, published=False)
        if validate_only:
            return report
        with store.lock():
            require(store.catalog()['revision'] == old['revision'], 'catalog changed during preparation; rerun import')
            for folder, manifest, assets, block in prepared:
                store.merge_assets(catalog, assets, folder)
            # Drop unreachable metadata only. Old files/chunks still serve frozen
            # plans, reconnects and pending downloads at their immutable URLs.
            referenced = {key for collection in ('blocks', 'profiles') for b in catalog[collection].values()
                          for key in b['roles'].values() if key != 'inherit'}
            catalog['assets'] = {key: asset for key, asset in catalog['assets'].items() if key in referenced}
            require(len(catalog['assets']) <= 1792 and len(json.dumps(catalog).encode()) <= 2*1024*1024,
                    'catalog capacity reached')
            for folder, manifest, _, _ in prepared:
                target = store.root / 'music' / 'blocks' / manifest['id'] / manifest['version']
                if target.exists():
                    require(json.loads((target / 'manifest.json').read_text()) == manifest,
                            'immutable prepared manifest differs')
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    os.rename(folder, target)
                store.expose_block(target)
            unchanged = catalog == old
            if not unchanged:
                catalog['revision'] = digest_json({k:v for k,v in catalog.items() if k != 'revision'})
                store.commit_catalog(catalog)
            else:
                # Recover a missing game-data mirror without another analysis.
                store.mirror(catalog)
            report.update(published=True, unchanged=unchanged, revision=catalog['revision'])
        return report
