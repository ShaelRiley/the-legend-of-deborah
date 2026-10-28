#!/usr/bin/env python3
"""Mount only runtime content; never expose build trees or drive links to Source."""
import argparse
from pathlib import Path

RUNTIME_DIRS = ('gamemodes', 'lua', 'sound', 'materials', 'models', 'resource', 'particles')


def install(repo: Path, target: Path) -> Path:
    repo = repo.resolve()
    view = repo / '.build' / 'dev-addon'
    if target.exists() and not target.is_symlink():
        raise ValueError(f'Refusing to replace existing non-symlink: {target}')
    if view.is_symlink() or (view.exists() and not view.is_dir()):
        raise ValueError(f'Refusing non-directory runtime view: {view}')
    wanted = {name: repo / name for name in RUNTIME_DIRS if (repo / name).is_dir()}
    if not {'gamemodes', 'lua'} <= wanted.keys():
        raise ValueError('Required gamemodes/lua directories missing')
    # Existing operator content is preserved, not silently deleted or overwritten.
    if view.exists():
        for entry in view.iterdir():
            if entry.name not in wanted or not entry.is_symlink() or entry.resolve() != wanted[entry.name].resolve():
                raise ValueError(f'Unexpected runtime-view entry; left intact: {entry}')
    for name, source in wanted.items():
        if source.is_symlink() or source.resolve().parent != repo:
            raise ValueError(f'Runtime source must be a directory in this checkout: {source}')
    view.mkdir(parents=True, exist_ok=True)
    for name, source in wanted.items():
        entry = view / name
        if not entry.is_symlink():
            entry.symlink_to(source, target_is_directory=True)
    target.parent.mkdir(parents=True, exist_ok=True)
    # Atomic replacement of the legacy whole-repository link; no save/config work.
    temporary = target.with_name(target.name + '.runtime-mount')
    if temporary.exists() or temporary.is_symlink():
        raise ValueError(f'Stale temporary mount left intact: {temporary}')
    temporary.symlink_to(view, target_is_directory=True)
    temporary.replace(target)
    return view


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--target', type=Path, required=True)
    args = parser.parse_args()
    print(f'Runtime-only development mount: {args.target} -> {install(args.repo, args.target)}')
