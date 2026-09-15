# Hermit starter-weapon crash repair

## Evidence and diagnosis

The supplied 2026-09-15 session reaches class selection and feat confirmation,
then ends at sequence 122 / 22.275 seconds. The console has no Lua traceback,
orderly shutdown, or recoverable error after that point. The tester identifies
walking into the Hermit's starter weapon as the force-close action. Runtime
identity reports a complete `stability-20260915-01` module set mounted from clean
commit `e7576355967084b9fca246022ce9a4b3a7da6148` on 32-bit x86 GMod.

That evidence establishes a native process termination at the starter handoff,
but not a unique native root cause. The old handoff executed `Player:Give` and
all resulting `WeaponEquip` hooks synchronously inside Source's solid-trigger
Touch/StartTouch traversal. In the same acquisition frame, the client created a
second weapon model, changed its model scale, took over the camera and manually
ran bone setup/drawing. The physical solid trigger was also model-scaled. These
operations were optional native-risk surfaces around the one required grant.

The live GDD revision
`ANLCKQlxr6BOnzNQTV1Tc7vkIbIFiL_9edTMt0V_lsdaxkEAOzGKmkVzNg9ABc-CN90ZQa-lde6e1WsyaNA7MD2UUl8TFbnEndyh2fTZIA`
was checked through tabs 00, 01 and 06. It requires one identity-bound Level-1
starter firearm, but does not require the duplicate client model or camera cut.

The first repair candidate, `stability-20260915-02`, successfully moved the
handoff out of Touch and removed the optional model/camera surfaces, but a fresh
native run still force-closed. Its durable session trace ends with:

```text
STAGING_STARTER_STAGE stage=begin weapon=weapon_smg1
STAGING_STARTER_STAGE stage=before_native_give weapon=weapon_smg1
```

There is no `after_native_give`. This falsifies Touch traversal and the removed
celebration rendering as sufficient explanations. It confines the remaining
fault to synchronous `Player:Give` work: native construction plus callbacks the
engine publishes before `Give` returns. The project had multiple `WeaponEquip`
hooks that immediately inspected or mutated the fresh weapon. In particular,
the SMG capacity hook called `GetClass`, rewrote `weapon.Primary`, and queried
clip/ammo state synchronously for the exact `weapon_smg1` in the trace.

## Repair

- Touch/StartTouch now reserves one pending claim and schedules the complete
  grant transaction for the next tick, after native trigger traversal unwinds.
- Invalid/dead players or failed grants clear the reservation and leave the
  pickup available for a safe retry; duplicate touches cannot duplicate grants.
- Successful pickup removal also occurs only in the deferred transaction.
- The solid trigger uses the weapon model's native scale.
- The fanfare and `STARTER ACQUIRED` HUD message remain, but the celebration no
  longer creates/scales/draws a clientside weapon model or overrides the view.
- `STAGING_STARTER_STAGE` records `before_native_give`, `after_native_give`,
  clip/ammo, run-record, sound, equipment and completion boundaries. If a native
  fault remains, the last durable stage narrows the next investigation.
- All project `WeaponEquip` hooks now only enqueue a zero-delay callback. Weapon
  validation, `GetClass`, instance tables, inventory state and ammo operations
  happen after native construction has returned to the event loop.
- The starter transaction sets a narrow admission guard around `Player:Give`, so
  the project's capacity policy accepts that already-reserved grant without
  interrogating its half-constructed weapon. The guard is always cleared.
- Lua errors returned from the native grant boundary are recorded as
  `native_give_lua_error` and leave the pickup available for retry.
- Runtime module receipts advance to `stability-20260915-03`, so fresh evidence
  can distinguish this candidate from both crashing builds.

## Validation and acceptance

`python3 tools/test_checkpoint_g_integration.py` passes all 94 registered suites.
The native-resource regression directly proves the grant and removal do not run
inside touch, duplicate touches settle once, a failed grant can retry, the solid
pickup does not scale, and the acknowledgement creates no native model/camera
hook. The new settlement regression loads the real SMG capacity hook with an
unsettled weapon that fails on synchronous `GetClass` or `Primary` access; the
hook queues work untouched, then applies the 25/75 accounting after settlement.
The equipment runtime suite also proves starter admission and procedural record
creation are deferred beyond the native `Give` stack. Lua syntax and
`git diff --check` pass.

Headless tests cannot prove a Source native fault is gone. For the finite native
gate: close GMod, update `astra/equipment-update`, run `bash tools/install_dev.sh`,
restart `gm_flatgrass`, choose a class/feat and collect the Hermit's weapon once.
The console must show `build=stability-20260915-03`, `missing=none`, and the game
must remain open with the firearm, correct clip/ammo, fanfare and HUD confirmation.
The detailed session should end that handoff with
`STAGING_STARTER_STAGE stage=complete`. Preserve the console, detailed session
and native dump before relaunch if a force-close recurs.
