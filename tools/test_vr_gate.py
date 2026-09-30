#!/usr/bin/env python3
"""Finite VR compatibility gate; headset and multiplayer acceptance remain separate."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
LUA = ["test_vr.lua", "test_tetris_lifecycle.lua", "test_campaign_timeout.lua",
       "test_deborah_finale_presentation.lua", "test_player_options.lua",
       "test_magic_mouse_bindings.lua", "test_minimap_player_marker.lua",
       "test_manual_transport.lua"]


def main():
    files = sorted(str(p.relative_to(ROOT)) for folder in ("gamemodes", "lua", "tools")
                   if (ROOT / folder).exists() for p in (ROOT / folder).rglob("*.lua"))
    result = subprocess.run([sys.executable, "tools/run_lua54.py", "--syntax", *files],
                            cwd=ROOT, capture_output=True, text=True)
    if result.returncode:
        print(result.stdout + result.stderr)
        return result.returncode
    print(f"PASS syntax: {len(files)} Lua files", flush=True)
    commands = [[sys.executable, "tools/run_lua54.py", f"tools/{name}"] for name in LUA]
    commands += [[sys.executable, "tools/test_vrmod_install.py"],
                 [sys.executable, "tools/test_manual_document.py"],
                 [sys.executable, "tools/validate_release_wiring.py"]]
    for command in commands:
        print("CHECK " + command[-1], flush=True)
        result = subprocess.run(command, cwd=ROOT)
        if result.returncode:
            return result.returncode
    print(f"VR_GATE_PASS: {len(commands)} checks plus syntax; native acceptance pending")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
