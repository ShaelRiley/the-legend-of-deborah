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
- Runtime module receipts advance to `stability-20260915-02`, so fresh evidence
  can distinguish this candidate from the crashing build.

## Validation and acceptance

`python3 tools/test_checkpoint_g_integration.py` passes all 93 registered suites.
The native-resource regression directly proves the grant and removal do not run
inside touch, duplicate touches settle once, a failed grant can retry, the solid
pickup does not scale, and the acknowledgement creates no native model/camera
hook. Lua syntax and `git diff --check` pass.

Headless tests cannot prove a Source native fault is gone. For the finite native
gate: close GMod, update `astra/equipment-update`, run `bash tools/install_dev.sh`,
restart `gm_flatgrass`, choose a class/feat and collect the Hermit's weapon once.
The console must show `build=stability-20260915-02`, `missing=none`, and the game
must remain open with the firearm, correct clip/ammo, fanfare and HUD confirmation.
The detailed session should end that handoff with
`STAGING_STARTER_STAGE stage=complete`. Preserve the console, detailed session
and native dump before relaunch if a force-close recurs.
