#!/usr/bin/env python3
"""Install/verify the bundled VRMod Lua/content dependency, without native DLLs."""
import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import tempfile
from zipfile import ZipFile

REVISION = "2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc"
SHA256 = "bc6077185fe7fb84aa5be8f853633e5c86210cf12e9a55f05342fb0c32f73367"
SOURCE = "https://github.com/Abyss-c0re/vrmod-x64"
BUNDLE = Path(__file__).resolve().parents[1] / "third_party/vrmod-x64/upstream.zip"


def payload(data: bytes) -> dict[str, bytes]:
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise ValueError("VRMod archive checksum does not match the pinned dependency")
    files = {}
    with ZipFile(BytesIO(data)) as archive:
        prefix = f"vrmod-x64-{REVISION}"
        for member in archive.infolist():
            path = PurePosixPath(member.filename)
            if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] != prefix:
                raise ValueError("Unexpected path in VRMod archive")
            relative = PurePosixPath(*path.parts[1:])
            if not relative.parts or member.is_dir():
                continue
            if str(relative) in files:
                raise ValueError("Duplicate path in VRMod archive")
            files[str(relative)] = archive.read(member)
    if "lua/autorun/vrmod_init.lua" not in files or "LICENSE" not in files:
        raise ValueError("VRMod archive is missing its loader or license")
    return files


def verify(target: Path, files: dict[str, bytes]) -> None:
    for name, expected in files.items():
        path = target / name
        if path.is_symlink() or not path.is_file() or path.read_bytes() != expected:
            raise ValueError(f"Existing VRMod file differs from bundled revision: {path}")
    expected_lua = {name for name in files if name.startswith("lua/")}
    actual_lua = {p.relative_to(target).as_posix() for p in (target / "lua").rglob("*") if p.is_file()}
    if actual_lua != expected_lua:
        raise ValueError(f"Existing VRMod contains extra Lua files: {target}")


def install(garrysmod: Path, data: bytes, ensure: bool = False) -> Path:
    files = payload(data)
    if not (garrysmod / "gameinfo.txt").is_file():
        raise ValueError("--garrysmod must name the garrysmod directory containing gameinfo.txt")
    addons = garrysmod / "addons"
    addons.mkdir(exist_ok=True)
    target = addons / "vrmod-x64"
    # Another unpacked loader would mount a second implementation over this one.
    for other in addons.iterdir():
        if other != target and ((other / "lua/autorun/vrmod_init.lua").exists()
                                or (other / "lua/vrmod/loader.lua").exists()):
            raise ValueError(f"Duplicate VRMod addon left intact: {other}. Keep only one installation.")
    if (garrysmod / "lua/autorun/vrmod_init.lua").exists():
        raise ValueError("A loose VRMod loader already exists in garrysmod/lua; reconcile duplicate copies first")
    if target.exists() or target.is_symlink():
        if not ensure:
            raise FileExistsError(f"Existing addon left intact: {target}. Use --ensure to verify it.")
        if target.is_symlink():
            raise ValueError(f"Existing VRMod addon is a symlink; left intact: {target}")
        verify(target, files)
        return target
    with tempfile.TemporaryDirectory(prefix=".lod-vrmod-", dir=addons) as staging:
        folder = Path(staging) / "vrmod-x64"
        folder.mkdir()
        for name, content in files.items():
            output = folder / name
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(content)
        (folder / ".lod-vrmod.json").write_text(json.dumps({
            "source": SOURCE, "revision": REVISION, "sha256": SHA256,
        }, indent=2) + "\n")
        verify(folder, files)
        folder.rename(target)
    return target


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--garrysmod", type=Path, required=True)
    parser.add_argument("--archive", type=Path, default=BUNDLE, help="Override the bundled, pinned ZIP")
    parser.add_argument("--ensure", action="store_true", help="Verify an existing identical addon without replacing it")
    args = parser.parse_args()
    try:
        data = args.archive.read_bytes()
        print(f"VRMod ready: {install(args.garrysmod.resolve(), data, args.ensure)} at {REVISION}")
        print("Restart the game/server. Headset clients also need the gVRMod native module.")
        return 0
    except (OSError, ValueError) as error:
        parser.exit(1, f"VRMod install failed: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
