"""Actual pinned runtime overlay plus bounded production lifecycle regression."""
from pathlib import Path
import runpy
import re
import subprocess
import sys
import tempfile

import install_vrmod as installer

ROOT = Path(__file__).resolve().parents[1]
upstream = installer.payload(installer.BUNDLE.read_bytes())
files = runpy.run_path(str(installer.OVERLAY))["apply"](upstream)
scoped = b"local hook, timer = vrmod.LODIdle.Hook, vrmod.LODIdle.Timer\n"
optional_tool = 'lua/vrmod/optional_sandbox/vrmod_pickup_list.lua'
assert optional_tool in files
assert not any(name.startswith('lua/weapons/gmod_tool/') for name in files), 'Sandbox tools must not register an absent toolgun'
bootstrap = files['lua/autorun/vrmod_init.lua']
assert b'AddCSLuaFile("vrmod/optional_sandbox/vrmod_pickup_list.lua")' in bootstrap, 'Joining clients must receive the retained Lua source'
assert b'include("vrmod/optional_sandbox/vrmod_pickup_list.lua")' not in bootstrap, 'Passive distribution must not execute the Sandbox editor'
lua = [name for name in files if name.startswith('lua/') and name.endswith('.lua')]
assert len(lua) == 139
for name in lua:
    if name not in ('lua/autorun/vrmod_init.lua', 'lua/vrmod/lod_idle.lua'):
        assert (files[name].startswith(scoped) or
                ((name.startswith('lua/weapons/') or name == optional_tool) and scoped in files[name][:300])), name
for name, data in upstream.items():
    if not name.startswith('lua/'):
        assert files[name] == data, name
assert files['LICENSE'] == upstream['LICENSE']
core = files['lua/vrmod/core/cl_vrmod.lua'].decode()
assert 'local function LoadModuleOnRequest()' in core
assert core.count('LoadModuleOnRequest()') == 2
assert 'vrutil_hook_joincreatemove' not in files['lua/vrmod/network/sh_network.lua'].decode()
with tempfile.TemporaryDirectory() as work:
    addon = Path(work)
    for name, data in files.items():
        if name.endswith('.lua'):
            path = addon / name; path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(data)
    syntax = []
    for name in lua:
        path = addon / 'syntax' / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(re.sub(r'\bcontinue\b', '__GLUA_CONTINUE_NOT_EXECUTED()', files[name].decode()))
        syntax.append(str(path))
    parsed = subprocess.run([sys.executable, 'tools/run_lua54.py', '--syntax', *syntax],
                            cwd=ROOT, capture_output=True, text=True)
    assert parsed.returncode == 0, parsed.stdout[-3000:] + parsed.stderr[-3000:]
    print('VR_OVERLAY_SYNTAX_PASS 139 mounted Lua files (GLua continue uses an unexecuted test trap)', flush=True)
    network = files['lua/vrmod/network/sh_network.lua'].decode()
    common = network[:network.index('\nif CLIENT then')]
    server = network[network.index('\nif SERVER then'):]
    (addon / 'server_network.lua').write_text(common + server)
    pickup = files['lua/vrmod/pickup/sh_pickup.lua'].decode()
    (addon / 'server_pickup.lua').write_text(pickup[:pickup.index('\nif CLIENT then')]
                                           + pickup[pickup.index('\nif SERVER then'):])
    # Plain Lua lacks GLua's continue token. None of the pose loops are used by
    # this failed-start test; a trap makes accidental execution fail explicitly.
    (addon / 'core_lua54.lua').write_text(re.sub(r'\bcontinue\b', '__GLUA_CONTINUE_NOT_EXECUTED()', core))
    proxies = files['lua/vrmod/physics/sv_collision_proxies.lua'].decode()
    (addon / 'proxies_lua54.lua').write_text(re.sub(r'\bcontinue\b', '__GLUA_CONTINUE_NOT_EXECUTED()', proxies))
    for realm in ('server', 'client'):
        subprocess.run([sys.executable, 'tools/run_lua54.py', 'tools/fixtures/vr_idle_harness.lua', str(addon), realm], cwd=ROOT, check=True)
print('VR_IDLE_GATE_PASS pinned ZIP unchanged; all 139 mounted Lua files scoped; server/client production lifecycle and zero idle work')
