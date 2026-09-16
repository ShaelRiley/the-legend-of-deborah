# September 16 crash and map repair

Branch: `astra/equipment-update`. Baseline: `65fed6c63ed6f4c1acf1f3bbe8c27104f21d0939`.
Remote main remains `8978796e886cdb5505d24ed0de085265fa99bac8`.
Candidate runtime identity: `stability-20260916-07`. No live deployment.

Design authority: live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 05 (world/staging) and 06 (lifecycle/UI), plus the author's explicit
single-blue-player-marker correction. No game-law or loot tuning changes.

## Runtime evidence and limits

The uploaded original `rpg_test_session(20260916-000753).txt` contains 1465 events.
Its periodic summary stops at 1386 and omits the crash-adjacent tail. At 405.285,
Beam kills Shambler #1018; XP and death presentation complete. At 406.305:
`loot_enter → loot_hidden → handoff_begin → category_resolved weapon → reward_prepare`.
There is no subsequent `entity_create` or Lua traceback for this transaction.
Preparation calls the procedural equipment generator and validator, which use
ordinary Lua data, before any pickup model or native entity creation. This narrows
the recorded boundary; it does **not** establish that preparation caused the
process termination, distinguish client/server/native failure, or rule out an
earlier engine corruption. No native dump was supplied. The hard-close remains
unattributed and release blocking; do not label it fixed or runtime accepted.

Both realms report build `stability-20260915-06`, receipts `missing=none`, engine
2026.05.08, architecture x86. The installer stamp is the older `09fe056…`; the
installer writes this stamp once, while its addon symlink tracks later checkout
changes. It is not proof that the running source was exactly that old commit.
Fresh installation after pulling will refresh the stamp. Client counts rose from
1341 during construction to about 2400 entities, with 45 cached meshes; Lua heap
fluctuates rather than growing monotonically. These are not native process-memory
measurements and do not prove an OOM. Unknown third-party entity-base errors also
appear (`mortar_box_base`, `bonbon01`), with no evidence tying them to the crash.

## Confirmed defects repaired

- The second player marker was an independent PostDrawHUD overlay using base
  `MC.Width`. The canonical renderer uses expanded `Map.gridWidth` for boss-space
  maps, so the overlay drifts in both axes and clamps extended cells incorrectly.
  The canonical marker is now blue with its dark outline; the overlay is retired
  (including hot-refresh cleanup). Gold route/objective graphics are unchanged.
- `CampaignTimeout:Start` and `RestoreHibernate` called `ConVar:SetBool` on the
  engine-owned `sv_hibernate_think`. GMod rejects this and aborts the deployment
  callback after setting the deadline. Both now use the console command API.
  The timer test now rejects native ConVar setters, reproducing the actual error
  instead of treating the engine variable as a Lua-created ConVar.
  API reference: https://wiki.facepunch.com/gmod/ConVar:SetBool

## Crash evidence improvements

- Record seed, context key, level, requested family and generation begin/complete
  before native pickup creation. Add a separate preparation-completed boundary.
  A failed preparation still exits before `ents.Create`.
- Copy loot boundaries into the existing bounded on-disk stability journal, even
  when verbose RPG logging is unavailable. Keep resource/build snapshots there
  too, including owned wall-model and loot-entity counts and LuaJIT version.
- `bash tools/export_current_evidence.sh --crash --open` works after termination,
  without an acceptance marker or running watcher. It copies the original final
  session, periodic mirrors, console, realm journals and installation stamp into
  a fresh crash directory and preserves earlier exports. No live files are edited.

## Validation

- Integrated gate: **101 suites pass**, including all Lua syntax/loading checks,
  shotgun aggregation, pickup/native ownership, shared damage lifetime, manual
  entry/transport, death/respawn/transition, and hook/timer/receiver wiring checks.
- New actual-HUD regression: exactly one blue marker and outline on widths
  21/29/37, extended cells, several floors, movement, refresh and access closure.
- Actual timer regression: engine-owned setter rejection, start-once, empty-server
  expiry/reconnect, cleanup, restore and canonical campaign restart.
- Actual pickup regression: captured inputs reproduce the identical reward;
  injected generator failure never reaches native creation.
- Equipment distribution/stress suite also passes under standalone LuaJIT
  2.1.1774896198 via Lupa, as well as the Lua 5.4 integration runner: 16,000 generated
  items. This is an additional interpreter check, **not** the installed x86 GMod
  engine/JIT, graphics driver, addons or native crash reproduction.
- Crash-export regression: no marker/watcher/game needed, exact original tail
  retained, consecutive exports do not overwrite each other.
- Shell syntax and `git diff --check` pass. No GMod runtime is installed here.

## Next finite native gate

Close GMod completely; pull this development branch and rerun `bash tools/install_dev.sh`.
On `gm_flatgrass`, deploy from the Hermit, confirm the countdown announcement and
one correctly positioned blue M-map marker, then fight for at least ten minutes,
including several Shambler/Soldier kills and weapon/wearable drops and pickups.
Use Shotgun and Beam so the prior death/loot boundary is exercised. Traverse a
stair while checking the marker; die and respawn once. Required result: no
force-close, no staging timer exception, complete reward boundary pairs, one
blue player marker. Re-prove P/E manual access during this run.

If it closes again, export with `--crash --open` before relaunching. Supply that
folder and any native crash dump the engine creates; original session plus realm
journals are essential because the periodic summary missed the final 79 events
in this upload. A native stack may be required to resolve the remaining crash.
Do not promote based on static success alone.
