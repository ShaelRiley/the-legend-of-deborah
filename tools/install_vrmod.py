#!/usr/bin/env python3
"""Install the pinned optional VRMod Lua/content dependency, without native DLLs."""
import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import tempfile
from urllib.request import urlopen
from zipfile import ZipFile

REVISION = "2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc"
SHA256 = "bc6077185fe7fb84aa5be8f853633e5c86210cf12e9a55f05342fb0c32f73367"
SOURCE = "https://github.com/Abyss-c0re/vrmod-x64"
URL = f"https://codeload.github.com/Abyss-c0re/vrmod-x64/zip/{REVISION}"


def install(garrysmod: Path, data: bytes) -> Path:
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise ValueError("VRMod archive checksum does not match the pinned dependency")
    if not (garrysmod / "gameinfo.txt").is_file():
        raise ValueError("--garrysmod must name the garrysmod directory containing gameinfo.txt")
    addons = garrysmod / "addons"
    addons.mkdir(exist_ok=True)
    target = addons / "vrmod-x64"
    if target.exists() or target.is_symlink():
        raise FileExistsError(f"Existing addon left intact: {target}. Keep only one VRMod installation.")
    with tempfile.TemporaryDirectory(prefix=".lod-vrmod-", dir=addons) as staging:
        folder = Path(staging) / "vrmod-x64"
        folder.mkdir()
        with ZipFile(BytesIO(data)) as archive:
            prefix = f"vrmod-x64-{REVISION}"
            for member in archive.infolist():
                path = PurePosixPath(member.filename)
                if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] != prefix:
                    raise ValueError("Unexpected path in VRMod archive")
                relative = Path(*path.parts[1:])
                if not relative.parts or member.is_dir():
                    continue
                output = folder / relative
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_bytes(archive.read(member))
        if not (folder / "lua/autorun/vrmod_init.lua").is_file() or not (folder / "LICENSE").is_file():
            raise ValueError("VRMod archive is missing its loader or license")
        (folder / ".lod-vrmod.json").write_text(json.dumps({
            "source": SOURCE, "revision": REVISION, "sha256": SHA256,
        }, indent=2) + "\n")
        folder.rename(target)
    return target


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--garrysmod", type=Path, required=True)
    parser.add_argument("--archive", type=Path, help="Use an already downloaded, checksum-verified ZIP")
    args = parser.parse_args()
    try:
        if args.archive:
            data = args.archive.read_bytes()
        else:
            with urlopen(URL, timeout=60) as response:
                data = response.read()
        print(f"Installed {install(args.garrysmod.resolve(), data)} at {REVISION}")
        print("Restart the game/server. Headset clients also need the gVRMod native module.")
        return 0
    except (OSError, ValueError) as error:
        parser.exit(1, f"VRMod install failed: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
