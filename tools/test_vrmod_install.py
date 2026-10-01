"""Exercise checksum, atomic install, license retention and existing-addon safety."""
import hashlib
from io import BytesIO
from pathlib import Path
import tempfile
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
