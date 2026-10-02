#!/usr/bin/env python3
"""Focused Lua 5.4 headless gate; engine/physics/rendering boundaries are mocked.
Run from any directory: python3 tools/test_warden_dancefloor.py
Requires a system Lua 5.4 shared library, not Garry's Mod or third-party Python.
"""
from pathlib import Path
import argparse
import ctypes
import ctypes.util
import re

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / 'gamemodes/legend_of_deborah/gamemode'
METHODS = ('State','SetPhase','ActorOwner','PhaseOwner','RetirePhaseOne',
           'RetirePhaseRoot','PhaseCue','BeginHidden','PhaseTargets','TauntCaption',
           'StartArrival','ServicePhaseOne','HitStunDeadline','Interrupt','Tick')


def phase_source(text: str) -> str:
    config = re.search(r'local C=\{.*?\}\s*W.Config=C', text, re.S)
    if not config:
        raise AssertionError('Missing production Warden configuration')
    pieces = ['local W=LOD.Warden;local P,N,R=LOD.ProgressionDirector,LOD.MazeNavigator,LOD.RunManager',
              'local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end',
              'local function alive(e) return IsValid(e) and not e.LODDead and e:Health()>0 end',
              'local function hero(e) return IsValid(e) and e:IsPlayer() and e:Alive() and R:IsActivePlayer(e) end',
              'local function log(...) end', config.group()]
    for name in METHODS:
        match = re.search(r'^function W:' + name + r'\(.*?(?=^function W:|\Z)', text, re.S | re.M)
        if not match:
            raise AssertionError('Missing production Warden method: '+name)
        # Stop at the function's final end before any later top-level registration.
        segment = match.group()
        end = segment.rfind('\nend')
        pieces.append(segment[:end+4])
    return '\n'.join(pieces)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--phase-source', type=Path, default=GAME/'lod/sv_warden.lua',
                        help='Optional retrieved production-method excerpt for offline review')
    args = parser.parse_args()
    name = ctypes.util.find_library('lua5.4')
    if not name:
        raise SystemExit('Lua 5.4 shared library not found; install liblua5.4-0 or equivalent.')
    lua = ctypes.CDLL(name)
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lua.luaL_loadbufferx.argtypes = [ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
    lua.lua_pcallk.argtypes = [ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
    lua.lua_tolstring.argtypes = [ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_settop.argtypes = [ctypes.c_void_p,ctypes.c_int]
    lua.lua_close.argtypes = [ctypes.c_void_p]
    state = lua.luaL_newstate()
    if not state:
        raise MemoryError('Lua state allocation failed')
    lua.luaL_openlibs(state)
    def run(code: str, label: str, execute: bool = True) -> None:
        data = code.encode()
        result = lua.luaL_loadbufferx(state,data,len(data),label.encode(),None)
        if not result and execute:
            result = lua.lua_pcallk(state,0,0,0,0,None)
        if result:
            raise AssertionError((lua.lua_tolstring(state,-1,None) or b'Lua failure').decode())
        lua.lua_settop(state,0)
    try:
        for relative in ('init.lua','cl_init.lua','lod/sv_warden_dancefloor.lua','lod/cl_warden_dancefloor.lua'):
            run((GAME/relative).read_text(),relative,False)
        init=(GAME/'init.lua').read_text(); client=(GAME/'cl_init.lua').read_text()
        assert init.index('include("lod/sv_warden.lua")') < init.index('include("lod/sv_warden_dancefloor.lua")')
        assert 'AddCSLuaFile("lod/cl_warden_dancefloor.lua")' in init
        assert client.index('include("lod/cl_warden.lua")') < client.index('include("lod/cl_warden_dancefloor.lua")')
        suite=(ROOT/'tools/test_warden_dancefloor.lua').read_text()
        setup, checks = suite.split('-- BEGIN CHECKS --',1)
        run(setup,'test setup')
        run(phase_source(args.phase_source.read_text()),'production Warden methods')
        server=(GAME/'lod/sv_warden_dancefloor.lua').read_text()
        run(server,'server dancefloor')
        run(server,'idempotent server reload')
        run((GAME/'lod/cl_warden_dancefloor.lua').read_text(),'client dancefloor')
        run(checks,'dancefloor checks')
        print('PASS: four Lua syntax checks; server/client load-order and distribution checks')
    finally:
        lua.lua_close(state)

if __name__ == '__main__':
    main()
