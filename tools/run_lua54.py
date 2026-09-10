#!/usr/bin/env python3
"""Run a Lua file through the system Lua 5.4 shared library.

The CI/work container ships liblua without the command-line interpreter. This
small runner keeps finite headless validators executable without vendoring Lua.
"""

import ctypes
import ctypes.util
import pathlib
import sys


def main() -> int:
    syntax_only = len(sys.argv) >= 3 and sys.argv[1] == "--syntax"
    scripts = sys.argv[2:] if syntax_only else sys.argv[1:]
    if not scripts or (not syntax_only and len(scripts) != 1):
        print("usage: tools/run_lua54.py [--syntax] <script.lua> [...]", file=sys.stderr)
        return 2
    library = ctypes.util.find_library("lua5.4") or "liblua5.4.so.0"
    lua = ctypes.CDLL(library)
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    lua.luaL_loadfilex.restype = ctypes.c_int
    lua.lua_pcallk.argtypes = [
        ctypes.c_void_p,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_longlong,
        ctypes.c_void_p,
    ]
    lua.lua_pcallk.restype = ctypes.c_int
    lua.lua_tolstring.argtypes = [
        ctypes.c_void_p,
        ctypes.c_int,
        ctypes.POINTER(ctypes.c_size_t),
    ]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_close.argtypes = [ctypes.c_void_p]

    state = lua.luaL_newstate()
    lua.luaL_openlibs(state)
    try:
        for item in scripts:
            script = pathlib.Path(item).resolve()
            status = lua.luaL_loadfilex(state, str(script).encode(), None)
            if status == 0 and not syntax_only:
                status = lua.lua_pcallk(state, 0, -1, 0, 0, None)
            if status != 0:
                size = ctypes.c_size_t()
                message = lua.lua_tolstring(state, -1, ctypes.byref(size))
                print(f"{item}: " + message[: size.value].decode(errors="replace"), file=sys.stderr)
                return 1
            if syntax_only:
                print(f"PASS {item}")
        return 0
    finally:
        lua.lua_close(state)


if __name__ == "__main__":
    raise SystemExit(main())
