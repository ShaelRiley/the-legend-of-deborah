#!/usr/bin/env python3
"""Exercise the actual development mount against a drive-link recursion trap."""
from pathlib import Path
import tempfile
from install_dev_mount import install


with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    repo = base / 'repo'
    for name in ('gamemodes', 'lua', 'sound', '.git', 'docs', '.build/private/pfx/dosdevices'):
        (repo / name).mkdir(parents=True)
    (repo / '.build/private/pfx/dosdevices/z:').symlink_to('/', target_is_directory=True)
    (repo / '.build/private/pfx/dosdevices/repo').symlink_to(repo, target_is_directory=True)
    code = repo / 'lua/live.lua'
    code.write_text('original')
    target = base / 'garrysmod/addons/the-legend-of-deborah-dev'
    target.parent.mkdir(parents=True)
    target.symlink_to(repo, target_is_directory=True)
    view = install(repo, target)
    assert target.resolve() == view
    assert {p.name for p in target.iterdir()} == {'gamemodes', 'lua', 'sound'}
    assert not (target / '.build').exists() and not (target / '.git').exists()
    assert not (target / 'docs').exists()
    code.write_text('edited')
    assert (target / 'lua/live.lua').read_text() == 'edited'
    assert install(repo, target) == view  # Repeat install retains live source.
    extra = view / 'operator-file'
    extra.write_text('preserve')
    try:
        install(repo, target)
    except ValueError:
        pass
    else:
        raise AssertionError('Unexpected operator content was accepted')
    assert extra.read_text() == 'preserve' and target.resolve() == view
    physical = base / 'existing-addon'
    physical.mkdir()
    (physical / 'save').write_text('preserve')
    try:
        install(repo, physical)
    except ValueError:
        pass
    else:
        raise AssertionError('Existing physical addon was overwritten')
    assert (physical / 'save').read_text() == 'preserve'
print('DEV_MOUNT_PASS: legacy migration, runtime-only reachability, live edits, repeat install and operator-data preservation')
