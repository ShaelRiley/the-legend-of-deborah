"""Exercise checksum, atomic install, license retention and existing-addon safety."""
import hashlib
import json
from io import BytesIO
from pathlib import Path
import tempfile
import runpy
import subprocess
import sys
from zipfile import ZipFile

import install_vrmod as installer


def archive(paths):
    data = BytesIO()
    with ZipFile(data, "w") as z:
        for name, content in paths.items():
            z.writestr(f"vrmod-x64-{installer.REVISION}/{name}", content)
    return data.getvalue()


def rejected(callback, error):
    try:
        callback()
    except error:
        return
    raise AssertionError(f"Expected {error.__name__}")


with tempfile.TemporaryDirectory() as work:
    game = Path(work) / "garrysmod"
    game.mkdir()
    (game / "gameinfo.txt").write_text("fixture")
    data = archive({"lua/autorun/vrmod_init.lua": "-- fixture", "LICENSE": "upstream license"})
    rejected(lambda: installer.install(game, data), ValueError)
    assert not (game / "addons").exists(), "Bad checksum must leave installation unchanged"
    installer.SHA256 = hashlib.sha256(data).hexdigest()
    target = installer.install(game, data)
    assert (target / "LICENSE").read_text() == "upstream license"
    assert (target / ".lod-vrmod.json").is_file()
    rejected(lambda: installer.install(game, data), FileExistsError)
    assert (target / "lua/autorun/vrmod_init.lua").read_text() == "-- fixture"
    rejected(lambda: installer.install(Path(work), data), ValueError)

with tempfile.TemporaryDirectory() as work:
    game = Path(work)
    (game / "gameinfo.txt").touch()
    data = archive({"../escaped.lua": "bad"})
    installer.SHA256 = hashlib.sha256(data).hexdigest()
    rejected(lambda: installer.install(game, data), ValueError)
    assert not (game / "addons/vrmod-x64").exists(), "Failed extraction must not publish partial addon"
    assert not (game / "addons/escaped.lua").exists()
    assert not (game / "addons").exists(), "Invalid archive must not create staging"

# Run the production CLI with the real committed bundle; no network is available
# or needed. Repeat starts verify every runtime byte and leave it untouched.
installer.SHA256 = "bc6077185fe7fb84aa5be8f853633e5c86210cf12e9a55f05342fb0c32f73367"
with tempfile.TemporaryDirectory() as work:
    game = Path(work)
    (game / "gameinfo.txt").touch()
    command = [sys.executable, str(Path(installer.__file__)), "--garrysmod", str(game), "--ensure"]
    first = subprocess.run(command, capture_output=True, text=True)
    assert first.returncode == 0, first.stderr
    target = game / "addons/vrmod-x64"
    loader = target / "lua/autorun/vrmod_init.lua"
    before = loader.stat().st_mtime_ns
    second = subprocess.run(command, capture_output=True, text=True)
    assert second.returncode == 0 and loader.stat().st_mtime_ns == before
    assert (target / "models/player/vr_hands.mdl").is_file()
    assert (target / "materials/vrmod/tpbeam.vtf").is_file()
    assert not list(target.rglob("*.dll")), "Server payload must not install client native modules"
    loader.write_text("operator modification")
    failed = subprocess.run(command, capture_output=True, text=True)
    assert failed.returncode != 0 and loader.read_text() == "operator modification"

with tempfile.TemporaryDirectory() as work:
    game = Path(work)
    (game / "gameinfo.txt").touch()
    duplicate = game / "addons/other-vrmod/lua/autorun/vrmod_init.lua"
    duplicate.parent.mkdir(parents=True)
    duplicate.write_text("preserve")
    rejected(lambda: installer.install(game, installer.BUNDLE.read_bytes(), ensure=True), ValueError)
    assert duplicate.read_text() == "preserve" and not (game / "addons/vrmod-x64").exists()

print("PASS VRMod installer: verified dependency, license, atomic write and existing-addon preservation")

# The previous pristine pinned installation upgrades offline and atomically;
# unverified extra files must never disappear during that migration.
data = installer.BUNDLE.read_bytes()
upstream = installer.payload(data)
for extra in (False, True):
    with tempfile.TemporaryDirectory() as work:
        game = Path(work); (game / 'gameinfo.txt').touch()
        target = game / 'addons/vrmod-x64'
        for name, content in upstream.items():
            path = target / name; path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(content)
        loader = target / 'lua/autorun/vrmod_init.lua'
        if extra:
            custom = target / 'operator.cfg'; custom.write_text('preserve me')
            rejected(lambda: installer.install(game, data, ensure=True), ValueError)
            assert custom.read_text() == 'preserve me' and loader.read_bytes() == upstream['lua/autorun/vrmod_init.lua']
        else:
            installer.install(game, data, ensure=True)
            assert b'LODIdle:FinishLoad' in loader.read_bytes()
            assert (target / 'lua/vrmod/lod_idle.lua').is_file()
            manifest = game / 'data/legend_of_deborah/dev_vr_sources.txt'
            assert manifest.read_text().splitlines()[0] == 'deborah-vr-idle-20261007-r2 139'
            before = manifest.stat().st_mtime_ns
            installer.install(game, data, ensure=True)
            assert manifest.stat().st_mtime_ns == before, 'identical repeat verification rewrote the receipt'
print('VRMOD_MIGRATION_PASS pristine old copy migrated; extra operator files preserved; complete 139-source receipt; repeat no writes')

# Reconstruct the actual published predecessor from its retained source evidence.
# Validate every old byte against the migration manifest before exercising it.
root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as work:
    old = Path(work)
    with ZipFile(root / 'docs/validation/STEAM_DECK_20261007_VR_IDLE_complete.zip') as archive:
        for name in ('patch.py', 'idle.lua'):
            (old / name).write_bytes(archive.read('matrix/changed-source/third_party/vrmod-x64/deborah/' + name))
    previous = runpy.run_path(str(old / 'patch.py'))['apply'](upstream)
    hashes = json.loads(installer.PREVIOUS_OVERLAY.read_text())['lua_sha256']
    assert hashes == {name: hashlib.sha256(content).hexdigest() for name, content in previous.items()
                      if name.startswith('lua/') and name.endswith('.lua')}
    for change in ('none', 'lua', 'extra-lua', 'extra-content', 'content', 'symlink'):
        game = old / change; game.mkdir(); (game / 'gameinfo.txt').touch()
        target = game / 'addons/vrmod-x64'
        for name, content in previous.items():
            path = target / name; path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(content)
        loader = target / 'lua/autorun/vrmod_init.lua'
        old_tool = target / 'lua/weapons/gmod_tool/stools/vrmod_pickup_list.lua'
        if change == 'lua':
            loader.write_text('operator Lua modification')
        elif change == 'extra-lua':
            (target / 'lua/operator.lua').write_text('operator addition')
        elif change == 'extra-content':
            (target / 'operator.cfg').write_text('operator addition')
        elif change == 'content':
            (target / 'LICENSE').write_text('operator content modification')
        elif change == 'symlink':
            loader.unlink(); loader.symlink_to(old_tool)
        before = loader.read_bytes()
        if change != 'none':
            rejected(lambda: installer.install(game, data, ensure=True), ValueError)
            assert loader.read_bytes() == before and old_tool.is_file(), 'Rejected migration changed the installation'
            if change == 'symlink':
                assert loader.is_symlink()
            continue
        installer.install(game, data, ensure=True)
        assert not (target / 'lua/weapons/gmod_tool').exists(), 'Weapon loader would still request missing toolgun shared.lua'
        assert (target / 'lua/vrmod/optional_sandbox/vrmod_pickup_list.lua').is_file()
        assert (target / 'LICENSE').read_bytes() == upstream['LICENSE']
        assert 'deborah-vr-idle-20261007-r2' in (target / '.lod-vrmod.json').read_text()
        manifest = game / 'data/legend_of_deborah/dev_vr_sources.txt'
        assert manifest.read_text().splitlines()[0] == 'deborah-vr-idle-20261007-r2 139'
        assert 'lua/weapons/gmod_tool/' not in manifest.read_text()
        before = loader.stat().st_mtime_ns
        installer.install(game, data, ensure=True)
        assert loader.stat().st_mtime_ns == before, 'Verified current overlay was needlessly rewritten'
print('VRMOD_TOOLGUN_UPGRADE_PASS exact published predecessor migrated; six safety cases; no toolgun registration; retained optional tool, content and 139-source receipt')
