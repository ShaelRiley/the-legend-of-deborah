# Maze deployment: LuaJIT generator crash

Developed on `main` from `eb20c8fe5546677c4efd09135befb0a8f62b6298`.
Runtime identity: `generator-jit-20260917-01`.
Live design: 00 → 01 → 07, especially deterministic generation, shared
authorities and native/static evidence separation. This is an execution repair;
no item, economy, encounter, ability or presentation rule changes.

## Native evidence

The supplied `gmod_win64_20260917_153345_1_accessviolation.mdmp` is a Windows
x64 minidump from GMod under Wine/Proton on `gm_flatgrass` (engine
`2026.09.17`, AMD VANGOGH, 1280×800). SHA-256:
`26a6c3b611f22bcefb8593ad49d39ab42d601946147b0b0574b6a744a2c2e08e`.

The exception is `0xC0000005`, reading address `0x30`, at
`lua_shared.dll+0x20f3b`, thread 320. The dump's embedded Lua stack identifies:

```
Equipment:Generate (sh_equipment_economy.lua)
  PrepareReward.generate (sv_equipment_economy.lua:199)
  PrepareReward (sv_equipment_economy.lua:219)
  pcall
  LootDirector:SpawnPickup (sv_loot_director.lua:490)
  LootDirector:EnsureStaticForPlayer (sv_loot_director.lua:761)
  staging deployment → equipment deployment → crypto deployment transaction
```

The embedded build receipts report `LuaJIT 2.1.0-beta3`, architecture `x64`,
`equipment_generation=default`, zero recorded Lua errors, and no client Lua
call at the fault. Maze generation had already reported ready; the failing
boundary is static loot allocation on player deployment. Native pickup
creation follows only after preparation returns. This points to the server
generator, not the renderer, initial feat selection or spawn audio.

The installer stamp is `0ef180a…`, while component receipts still say
`geometry-init-20260916-01`. Both can remain unchanged after a symlinked checkout
is pulled, so they **do not conclusively identify the running source commit**.
The implicated generator and its version-gated safeguard are present in the
current baseline as well. The dump does not record the final reward's complete
seed/context, so an exact replay of this September 17 reward is not claimed.
The raw dump is retained as the supplied attachment, not committed to Git.

## Defect and repair

The earlier workaround only interpreted the generator when
`jit.version_num <= 20004`. It excluded the embedded 2.1 beta runtime.
Passing a modern rolling 2.1 build did not establish that this beta was safe.

The module now calls `jit.off(E.Generate, true)` on every runtime that exposes
the function, once when the generator loads. This protects the generator and
its nested closures. It leaves the engine-wide compiler and independent
RNG/combat/rendering functions alone. The [upstream scope contract](https://luajit.org/ext_jit.html)
also specifies that this flushes existing compiled code for affected functions.
No global compiler toggle, optimizer setting, timer or dependency is introduced.
Seeds, draw order, names, IDs, affixes and valuation are unchanged.

Both realms report `equipment_generation=interpreter-generator`. Component
receipts advance to `generator-jit-20260917-01`; the shared generator now has
its own required receipt so a mixed/older generator cannot pass the runtime
audit merely because the inventory module is current.

## Validation

All **108 integrated suites pass**, including syntax, whitespace and accepted
gameplay regressions. The new `tools/test_equipment_jit_guard.lua` checks both
realms against seven compiler capability/version cases: 2.0.4, 2.1 beta,
future, string-valued, unknown, absent compiler API and absent library. It
requires the exact function and recursive flag, one load-time call, unchanged
corpus results, a generator receipt, and unchanged global compiler status.

The existing corpus provides 14 exact recorded September 16 rewards repeated
100 times with periodic collection. Upstream release `2.1.0-beta3`, commit
`8271c643c21d1b2f344e339f559f2de6f3663191`, was built in a disposable Linux x64
test directory. With only the generator re-enabled using the standalone
`--unsafe-jit` control, that process terminates with SIGSEGV (return `-11`).
With the safeguard, the replay passes with every signature identical; the
existing distribution/valuation suite and production pickup-preparation
harness also pass. No unsafe toggle is available in-game.

The same unguarded SIGSEGV and guarded success also reproduce on upstream
2.0.4 (`69e5342eb893815b18a1ec84ba74b0e0d1cc9beb`) and a separate 2.1.0-beta3
build using `XCFLAGS=-DLUAJIT_ENABLE_GC64`. On both, the guarded exact replay,
distribution/valuation, new compatibility matrix and production pickup harness
pass. The 1,400-item replay takes approximately 0.05–0.06 seconds in this
container; this is not a Steam Deck frame-time measurement. Test VMs and
build logs are outside the repository and are not runtime dependencies.

Reproduce in a disposable process using either historical VM:

```sh
/path/to/luajit tools/test_equipment_crash_replay.lua --unsafe-jit
/path/to/luajit tools/test_equipment_crash_replay.lua
/path/to/luajit tools/test_equipment_jit_guard.lua
/path/to/luajit tools/test_equipment_economy.lua
/path/to/luajit tools/test_pickup_native_handoff.lua
python3 tools/test_checkpoint_g_integration.py
```

The first command deliberately re-enables the known-crashing compilation path.

## One native acceptance action

Fully quit GMod, update `main`, rerun `tools/install_dev.sh`, and launch a fresh
`gm_flatgrass` game. Choose the initial feat, take the Hermit's weapon, and use
the blue portal. Confirm deployment completes and ordinary loot can be collected.
The automatic receipt must show `build=generator-jit-20260917-01`,
`missing=none`, and `equipment_generation=interpreter-generator` on both realms.

If it closes again, run `bash tools/export_current_evidence.sh --crash --open`
before relaunching and retain the new minidump. Native GMod acceptance is still
pending: the standalone crash reproduces the dangerous compilation path, but
is not the exact engine binary or proof that all force-closes are fixed.
No public-server deployment or Workshop publication is implied by this repair.
