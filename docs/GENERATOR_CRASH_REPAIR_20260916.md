# Legacy LuaJIT equipment-generation crash repair

**Follow-up:** the [September 17 native dump and beta-runtime reproduction](GENERATOR_CRASH_REPAIR_20260917.md)
supersede the version-limited safeguard below. The generator is now interpreted
on all LuaJIT builds. This document retains the original evidence and conclusions.

Development branch: `astra/equipment-update`; starting remote HEAD
`e09434522e5b96e3c3d7537386fe991bb7ac8655`. Remote main was verified as
`8978796e886cdb5505d24ed0de085265fa99bac8`. Candidate identity:
`stability-20260916-08`. No main promotion or deployment.

Live design navigation: 00 AI ENTRYPOINT → 01 AI RULE INDEX → 07 IMPLEMENTATION
& TUNING (shared authorities, determinism, low-end performance, validation) and
90 DEFERRED / FUTURE, LOD-EQUIP-016 (promoted equipment generation). The repair
changes execution strategy, not loot law, stored records, RNG streams or tuning.

## New evidence actually inspected

The supplied files are the **010524–010528 exports**, including both
`stability_*_latest(1).txt` journals. These supersede the handoff's list of
004417 exports for this investigation. The prior workspace connection failure
is unrelated to the game termination.

- Both realms load `stability-20260916-07`, all component receipts present,
  engine `2026.05.08`, architecture `x86`, **LuaJIT 2.0.4**, zero reported Lua
  errors. Installer stamp `09fe056…` is older symlink-install metadata.
- Original `rpg_test_session(20260916-010524).txt`: **3960 events**. Summary and
  session mirror stop at **3907**. Original rolling log agrees with the final
  session; archive mirror also lacks the last 53 events.
- SMG kills Deadcrab #1321 at session 765.105. Encounter/XP/kill settlement and
  deferred death presentation complete. At 766.125 (journal RealTime 872.717):
  `loot_enter → loot_hidden → handoff_begin → category_resolved wearable →
  reward_prepare → reward_inputs → equipment_generate_begin`. No completion,
  preparation return or native pickup creation follows.
- Exact final input: seed `996257890`, level `1`, random wearable family,
  context `campaign:26:1504071172:76561198025505071:660600545`.
  Thirteen earlier recorded generation calls complete; all fourteen inputs are
  retained in `tools/fixtures/equipment_crash_20260916.lua`.
- Server snapshots: 1347–1402 entities, Lua heap 20654–41784 KB, transient loot
  0–42. Client: construction starts at 1626 entities; maximum 3154, final 3107;
  wall models settle at **1786**, mesh cache 46→47, Lua heap 18618–37008 KB.
  These are bounded observed counts, **not** native RAM/VRAM measurements or
  evidence of OOM. Final client heartbeat is RealTime 857.759.
- Console shader warnings occur during loading, including DebugLuxels and
  Eyeball. No crash-adjacent Lua traceback or native stack is supplied. Manual
  delivery reaches `MANUAL_READY`; its canonical source/reader is preserved.

## Confirmed defect, repair and attribution limit

The equipment corpus and the existing distribution test **segfault in upstream
LuaJIT 2.0.4 with JIT compilation enabled**. They succeed when interpreted. This
is an actual process SIGSEGV (subprocess return -11), not an assertion failure
or a simulated engine callback. The same tests pass on modern LuaJIT 2.0 and 2.1,
explaining why the previous 2.1-only check did not reveal it.

The historical VM was built locally from the upstream release commit
[`69e5342eb893815b18a1ec84ba74b0e0d1cc9beb`](https://github.com/LuaJIT/LuaJIT/commit/69e5342eb893815b18a1ec84ba74b0e0d1cc9beb),
using GCC 13 on Linux **x64**. It is not the user's x86 GMod binary; 32-bit build
libraries and a running GMod engine are unavailable here.

The failure depends on trace history: the isolated final seed succeeds, while
the ordered corpus crashes (in the simple printed replay, on its third item).
Compiler tracing reaches the generator's property-selection loops before the
crash. The seed itself is not malformed. Do not claim the final breadcrumb,
third replay item or last native operation alone is the cause.

**Production repair:** when `jit.version_num <= 20004`, disable compilation
only for `Equipment:Generate` and its nested closures with
`jit.off(E.Generate, true)`. The engine-wide compiler remains enabled; the
shared RNG, combat, networking and rendering retain their execution paths.
Modern runtimes retain ordinary compilation. This is a scoped compatibility
workaround for a reproduced native failure, not a replacement generator.
The [upstream API contract](https://luajit.org/ext_jit.html) documents function
and recursive-subfunction scope. No per-call global compiler toggling is used.

The original generator is still the single authority for rewards, starter
equipment, restored missing records and ordinary grants. Every captured item
has identical ID, name, rarity, quality, budget, property order, power and
magnitude after the repair. The final reward is Rare, quality 93, budget 223:
**Wayfarer's Watery Gloves of Poisoning and Repulsion**.

This establishes a release-blocking defect and a successful standalone repair.
Its agreement with the loaded VM and recorded boundary makes it the leading
explanation of this run, **not proof that every previous GMod hard-close has
the same cause**. Native GMod acceptance remains open. The prior shotgun,
pickup/WeaponEquip, damage-metadata, death/respawn, manual, map and timeout
repairs remain intact. No evidence justifies replacing those authorities or
removing major features in this pass.

## Validation

- Integrated runner: **102/102 suites pass**, including Lua syntax/loading,
  include/hook/timer/net wiring and accepted gameplay regressions.
- Historical LuaJIT 2.0.4: ordered corpus repeated 100 times (**1400 exact
  records**, periodic GC), existing **16,000-item** distribution suite, and
  production pickup/equipment preparation harness all pass with the repair.
- Standalone `--unsafe-jit` re-enables compilation of the generator and restores
  SIGSEGV in the same replay test. No unsafe toggle is exposed in-game.
- Lua 5.4 and modern LuaJIT `2.0.1774896119` / `2.1.1774896198`: exact corpus
  and distribution checks pass; modern VMs report generation mode `default`.
- The pickup harness now invokes the real final `SpawnPickup → PrepareReward →
  Generate → validation → native creation/registration` path. Campaign seed
  `664744883` was reconstructed algebraically from the reversible seed hash and
  verified against all fourteen logged seed/context pairs; it is an inferred
  fixture input, not an independently logged field. The test checks final
  generation begin/complete and identical reward contents.
- Historical-VM corpus timing was about 0.054 s for 1400 items in this container;
  this is not a Steam Deck frame-time measurement. Global JIT state is unchanged.

Reproduce with an independently built historical VM:

```sh
/path/to/luajit-2.0.4 tools/test_equipment_crash_replay.lua --unsafe-jit
/path/to/luajit-2.0.4 tools/test_equipment_crash_replay.lua
/path/to/luajit-2.0.4 tools/test_equipment_economy.lua
/path/to/luajit-2.0.4 tools/test_pickup_native_handoff.lua
python3 tools/test_checkpoint_g_integration.py
```

The first command deliberately runs the known-crashing standalone control;
execute it only in a disposable test process. Upstream VM sources/binaries are
test dependencies, not shipped game assets.

## Next native acceptance

Fully close GMod, update `astra/equipment-update`, run `bash tools/install_dev.sh`,
then start `gm_flatgrass`. Automatic build receipts should show
`stability-20260916-08`; on the current LuaJIT 2.0.4 installation both realms
should also show `equipment_generation=interpreter-legacy-jit`.

Play a sustained 30-minute mixed-combat run with ordinary weapon/wearable drops
and collection. Include SMG, Shotgun and Beam kills, equipment changes and a
rescue/staging/redeployment if reached; verify the single blue map marker and
P/E manual once. No special testkit or repeated console setup is needed.
Acceptance requires complete reward boundaries, no hard-close, and preserved
inventory/lifecycle behavior; a green headless test is insufficient.

Export with `bash tools/export_current_evidence.sh --crash --open` after the
run; if it terminates, export **before relaunching**. Upload the resulting
directory, which includes original session, mirrors, console, realm journals
and installer stamp. If a hard-close recurs despite the recorded interpreter
mode, the smallest additional discriminating evidence is the corresponding
native dump/backtrace (or OS OOM-kill record if no dump exists), alongside that
same package. The [engine crash-reporting guide](https://wiki.facepunch.com/gmod/Crash_Reporting)
distinguishes Linux native debugging from x86-64-branch crash dump locations.
Do not request the same Lua-only logs indefinitely without resolving that gap.
