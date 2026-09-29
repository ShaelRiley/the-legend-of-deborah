#!/usr/bin/env python3
"""One-time VPS setup, then: import music.zip / rebuild-cues music.zip / status."""
import argparse
import json
from pathlib import Path
import subprocess
import zipfile

from catalog_service import CatalogStore, atomic_json, require
from folder_catalog import prepare_library


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path,
                        default=Path.home()/'.config/legend_of_deborah/music-catalog.json')
    commands = parser.add_subparsers(dest='command', required=True)
    setup = commands.add_parser('setup', help='Save VPS paths and the public HTTPS origin once')
    setup.add_argument('--origin', required=True)
    setup.add_argument('--root', type=Path, default=Path('/srv/lod-music'))
    setup.add_argument('--game-data', type=Path,
                       default=Path.home()/'Servers/the-legend-of-deborah/garrysmod/data/legend_of_deborah/music')
    for name in ('import', 'rebuild-cues', 'check'):
        commands.add_parser(name).add_argument('source', type=Path)
    commands.add_parser('status')
    args = parser.parse_args()
    try:
        if args.command == 'setup':
            store = CatalogStore(args.root, args.origin, args.game_data)
            store.game_data.mkdir(parents=True, exist_ok=True)
            config = dict(root=str(store.root), origin=store.origin, game_data=str(store.game_data))
            atomic_json(args.config, config)
            print(json.dumps(dict(configured=True, **config), indent=2))
            return
        require(args.config.is_file(), 'run setup --origin https://YOUR-MUSIC-HOST first')
        config = json.loads(args.config.read_text())
        store = CatalogStore(config['root'], config['origin'], config['game_data'])
        if args.command == 'status':
            catalog = store.catalog()
            missing = [key for key, asset in catalog['assets'].items()
                       if asset.get('delivery') != 1 or asset['loop'] and not asset.get('cues')]
            print(json.dumps(dict(revision=catalog['revision'], blocks=len(catalog['blocks']),
                                  default_block=catalog.get('defaultBlock'),
                                  unprepared_assets=missing, **config), indent=2))
            return
        report = prepare_library(store, args.source, rebuild_cues=args.command == 'rebuild-cues',
                                 validate_only=args.command == 'check')
        print(json.dumps(report, indent=2))
    except (ValueError, KeyError, TypeError, OSError, zipfile.BadZipFile, subprocess.SubprocessError) as exc:
        parser.exit(1, f'Music catalog failed: {exc}\n')


if __name__ == '__main__':
    main()
