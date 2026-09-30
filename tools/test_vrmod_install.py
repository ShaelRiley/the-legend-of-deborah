"""Exercise checksum, atomic install, license retention and existing-addon safety."""
import hashlib
from io import BytesIO
from pathlib import Path
import tempfile
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
    assert not list((game / "addons").iterdir()), "Staging must be cleaned on failure"

print("PASS VRMod installer: verified dependency, license, atomic write and existing-addon preservation")
