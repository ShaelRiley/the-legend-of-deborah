#!/usr/bin/env python3
"""Production wallet Lua against real SQLite; only Source/JSON bindings are bridged."""
import ctypes as ct
import ctypes.util
import json
import sqlite3
import tempfile
from pathlib import Path


def main():
    lib = ct.CDLL(ct.util.find_library('lua5.4'))
    P = ct.c_void_p
    signatures = {
        'luaL_newstate': ([], P), 'luaL_openlibs': ([P], None), 'lua_close': ([P], None),
        'lua_type': ([P, ct.c_int], ct.c_int), 'lua_toboolean': ([P, ct.c_int], ct.c_int),
        'lua_tonumberx': ([P, ct.c_int, P], ct.c_double), 'lua_tolstring': ([P, ct.c_int, P], ct.c_char_p),
        'lua_gettop': ([P], ct.c_int), 'lua_settop': ([P, ct.c_int], None),
        'lua_pushnil': ([P], None), 'lua_pushboolean': ([P, ct.c_int], None),
        'lua_pushnumber': ([P, ct.c_double], None), 'lua_pushstring': ([P, ct.c_char_p], P),
        'lua_createtable': ([P, ct.c_int, ct.c_int], None), 'lua_settable': ([P, ct.c_int], None),
        'lua_next': ([P, ct.c_int], ct.c_int), 'lua_setglobal': ([P, ct.c_char_p], None),
        'lua_pushcclosure': ([P, P, ct.c_int], None),
        'luaL_loadfilex': ([P, ct.c_char_p, P], ct.c_int),
        'lua_pcallk': ([P, ct.c_int, ct.c_int, ct.c_int, ct.c_longlong, P], ct.c_int),
    }
    for name, (args, restype) in signatures.items():
        f = getattr(lib, name); f.argtypes = args; f.restype = restype
    state = lib.luaL_newstate(); lib.luaL_openlibs(state)
    def read(index):
        kind = lib.lua_type(state, index)
        if kind <= 0: return None
        if kind == 1: return bool(lib.lua_toboolean(state, index))
        if kind == 3:
            n = lib.lua_tonumberx(state, index, None)
            return int(n) if n.is_integer() else n
        if kind == 4: return lib.lua_tolstring(state, index, None).decode()
        if kind != 5: raise ValueError(f'Unsupported Lua type {kind}')
        if index < 0: index = lib.lua_gettop(state) + index + 1
        values = {}; lib.lua_pushnil(state)
        while lib.lua_next(state, index):
            values[read(-2)] = read(-1); lib.lua_settop(state, -2)
        if values and set(values) == set(range(1, len(values) + 1)):
            return [values[i] for i in range(1, len(values) + 1)]
        return values
    def push(value):
        if value is None: lib.lua_pushnil(state)
        elif isinstance(value, bool): lib.lua_pushboolean(state, value)
        elif isinstance(value, (int, float)): lib.lua_pushnumber(state, value)
        elif isinstance(value, str): lib.lua_pushstring(state, value.encode())
        else:
            lib.lua_createtable(state, 0, 0)
            for k, v in (enumerate(value, 1) if isinstance(value, list) else value.items()):
                push(k); push(v); lib.lua_settable(state, -3)
    callbacks = []
    callback_errors = []
    def bind(name, function):
        @ct.CFUNCTYPE(ct.c_int, P)
        def callback(_):
            try: push(function(read(1)))
            except Exception as exc:
                callback_errors.append(f'{name}: {exc}')
                lib.lua_pushnil(state)
            return 1
        callbacks.append(callback); lib.lua_pushcclosure(state, callback, 0); lib.lua_setglobal(state, name.encode())
    with tempfile.TemporaryDirectory(prefix='lod-wallet-test-') as directory:
        db_path = str(Path(directory) / 'sv.db')
        connection = sqlite3.connect(db_path, isolation_level=None)
        failure, last_error = None, ''
        def execute(statement):
            nonlocal failure, last_error
            try:
                if failure and failure in statement:
                    failure = None; raise sqlite3.OperationalError('injected write failure')
                result = connection.execute(statement)
                if not result.description: return None
                names = [x[0] for x in result.description]
                rows = [dict(zip(names, (str(v) for v in row))) for row in result.fetchall()]
                return rows or None
            except sqlite3.Error as exc:
                last_error = str(exc); return False
        def fail(pattern):
            nonlocal failure
            failure = pattern
        def reconnect(_):
            nonlocal connection
            connection.close(); connection = sqlite3.connect(db_path, isolation_level=None)
            return True
        bind('WalletSQLQuery', execute); bind('WalletSQLError', lambda _: last_error)
        bind('WalletJSONEncode', lambda x: json.dumps(x, ensure_ascii=False, separators=(',', ':'), sort_keys=True))
        bind('WalletJSONDecode', lambda x: json.loads(x) if x else None)
        bind('WalletSQLFail', fail); bind('WalletSQLReconnect', reconnect)
        status = lib.luaL_loadfilex(state, b'tools/test_crypto_runtime.lua', None)
        if status == 0: status = lib.lua_pcallk(state, 0, 0, 0, 0, None)
        if status:
            print(lib.lua_tolstring(state, -1, None).decode())
        connection.close(); lib.lua_close(state)
        if callback_errors: print(callback_errors)
        return int(status != 0 or bool(callback_errors))


if __name__ == '__main__':
    raise SystemExit(main())
