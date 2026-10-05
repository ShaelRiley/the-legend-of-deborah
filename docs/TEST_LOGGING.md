# Current Steam Deck native capture repair

The first verified capture recorded no frames while waiting for batching; it is
an unmeasured result. The repaired `lod_perf_start 180` bounds preparation to
30 seconds, preserves blocked-renderer diagnostics and requests one existing
server population snapshot automatically. It mirrors that full snapshot into
client DATA and embeds it in the performance report. Return
performance_client_latest.txt + console_latest.txt; locating a separate
population_latest.txt is not required. Follow the same-configuration, fully
restarted [finite retest](validation/STEAM_DECK_20261005_NATIVE_REPAIR.md).
Native >=40 FPS and presentation/gameplay acceptance remain pending.

---

# SPOT-14 Time Management gate

Use `python3 tools/test_spot14_gate.py --output /outside/source/empty-dir --suite-timeout 120 --workers 2`.
Retains all 85 SPOT13 selections and adds ordinary campaign-clock and actual SPOT14
integration suites (87 total). Focused attempt08 passes258 production assertions;
final aggregate/source/publication facts belong in the delivery receipt. Do not treat
preparation, failed fixtures or prior interrupted gates as passes. Evidence and
limits: [SPOT14 validation](validation/SPOT_14_TIME_MANAGEMENT.md).

On the exact restarted gm_flatgrass build, a deployed living INT17 holder adds three
minutes. A real death/return should remove/restore only that allowance while time
remains. Check another holder and Hourglass time remain intact. The existing admin
`lod_campaign_clock_status` prints both effective remaining time and party allowance;
`TIME_MANAGEMENT_CHANGED` records signed delta, current allowance and effective
remaining time. No event is emitted for an unchanged allowance. Return the usual
console_latest.txt + rpg_summary_latest.txt and short exact-build observation.
Detailed session only for timing; no dedicated Razor retest. Native timing/co-op,
full campaign and full Gate-B identity acceptance remain open. No Workshop/VPS action.

---

# SPOT-12 Spellbook availability gate

Use `python3 tools/test_spot12_gate.py --output /outside/source/empty-dir --suite-timeout 120 --workers 2`.
Retains all 79 SPOT-11 selections and adds production Spellbook Paint/snapshot/
state/layout, actual mouse-binding/casting, inventory refresh and minigame UI
regressions. Pre-closeout: 83/83 suites, 1441 new focused assertions, 745 Lua syntax
checks; minimum computed text contrast 5.119:1. Final frozen/independent receipts
supply exact hashes and publication identity. Earlier width failure and interrupted
57-suite run are preserved in SPOT_12_ATTEMPTS.tar.xz; neither is a full pass.
No full campaign matrix, full Gate-B identity or native visual/font/co-op pass.

For native acceptance, use the exact installed build on gm_flatgrass, open I during
normal play and check full state backdrops, literal reasons, independent selection
outline and binding legibility as Magic/cooldown/held-throwable state changes.
Return console_latest.txt + rpg_summary_latest.txt and a short observation; detailed
session only for timing. No dedicated Razor test; no Workshop/VPS operation here.

---

SPOT-11 final frozen gate: `python3 tools/test_spot11_gate.py --output <outside-source-empty-directory> --suite-timeout 120 --workers 2`.
The explicit bounded runner allowance preserves all assertions; the earlier
independent 45-second Skeleton blockade timeout remains a failed 78/79 gate,
not a performance acceptance or pass. See validation/SPOT_11_DRAFTS.md.

# Runtime Test Logging

The Legend of Deborah keeps its runtime evidence in Garry's Mod's proven writable/uploadable data directory:

`garrysmod/data/legend_of_deborah/`

On Shael's Steam Deck this is:

`/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`

The upload-facing files are **ordinary physical `.txt` files**, not checkout symlinks.

## SPOT-11 — four-choice ordinary feat drafts

Run `python3 tools/test_spot11_gate.py --output <empty directory outside the repository>`.
It selects 79 suites, retains all 72 D-J selections, and checks all Lua source;
this is not full campaign or native acceptance. See
[implementation, attempts and native procedure](validation/SPOT_11_DRAFTS.md).
On the exact restarted gm_flatgrass build, a new ordinary hand should show four
legal distinct choices where the pool permits; choose the fourth and verify one
committed result. A previously pending trio must not reroll across reopen, death,
rejoin or role change. Test readable wide/narrow scrolling during ordinary play.
Human Soldiers remain automatic/read-only; capstones remain three. Supply the
usual console_latest.txt + rpg_summary_latest.txt and short observation. No extra
Razor test and no Workshop/VPS action are prerequisites for the next spot bullet.

## SPOT-09 Damsel's Revenge — arena and rescue

The finite source gate is `python3 tools/test_spot09_gate.py --output <empty directory outside the repository>`.
It selects 59 suites and checks all Lua files; it is not native acceptance or the
complete campaign matrix. See [SPOT-09 evidence and limits](validation/SPOT_09_REVENGE.md).
After a full restart on gm_flatgrass, use the normal item in an active Gordon court.
An admin with existing developer mode enabled may use `lod_damsel_revenge_testkit`
for an explicitly unranked three-unit setup; it changes no boss, jail, timer or rescue.
Confirm stationary gun/visible slit/real shots and then normal rescue and the owner-only
at-feet pickup during victory. At Level 20, she must stop before Hector and wait for
normal Deborah rescue. Capture console_latest.txt and rpg_summary_latest.txt plus a
visual/listening report. ARM/DROP events use DAMSEL_REVENGE_ARMED and
DAMSEL_REVENGE_DROPPED; finite allocation failure uses DAMSEL_REVENGE_DROP_FAILED,
with *_ERROR for caught adapter failures. Injected *_ERROR lines in automated
boundary tests are deliberate asserted cases, not native gameplay reports.

## SPOT-08 turret acceptance — ordinary arena play

The finite source gate is `python3 tools/test_spot08_gate.py --output <empty directory outside the repository>`.
It selects 52 suites; it is not native acceptance or the complete campaign matrix.
See [SPOT-08 evidence and limits](validation/SPOT_08_TURRETS.md).

After a full restart, observe a threshold Gordon arena during ordinary play and
run `lod_warden_status`. The existing output adds living/desired turrets plus
admitted/skipped counts; the existing RPG test log records WARDEN_TURRETS_ADMITTED
with desired/admitted/skipped, level and seed. A skipped unsafe slot is an explicit
refusal, not permission to replace it or force a spawn. Confirm safe entry and
both gallery stairs, finite readable warnings, dodge/flank/destruction and cleanup
before Hector. Pair the usual console/summary files with a brief visual/listening
report; collect co-op lifecycle evidence when playing co-op. No dedicated Razor
retest or Workshop/VPS operation is a prerequisite for continuing the spot queue.

## Population acceptance — release-mode evidence

From B28, `population_latest.txt` is the bounded, automatic population census in
`garrysmod/data/legend_of_deborah/`. Pair it with `console_latest.txt` for population
failures. It captures first-ready state, gate changes,30-second heartbeats and
shutdown, with at most64 records. It reports actual living actors separately from
planned and spawned encounter counts, native admission failures, line/hull probe
disagreement and installed-versus-mounted source fingerprints. `lod_population_evidence`
is an optional immediate read-only capture, not a prerequisite.

This observer remains active with `lod_developer_mode 0`. The older detailed RPG
logger does not: a staging-only RPG summary after switching to release mode is not
evidence that the user never entered the dungeon. The installer records an atomic
41-file SHA256 manifest (eight files in B28, 34 in B29); missing/mismatched source is explicitly unverified.
No population observation enables cheats, spawns monsters or changes campaign RNG.

## B29 arrival and opening evidence

`b29-entry-safety` extends the same automatic release observer. Each entry snapshot
reports the sanctuary cells; live AI/damage/spawn function bindings; safety/admission
counters; and per-deployed Hero depth, high-water, completed contacts, current cap,
respite, nearby living hostiles and source counts, admitted members and currently
engaged targets. Nearby observation includes sanctuary occupants; a safe Hero's
zero engaged count must not conceal a mob nearby. Locality is graph/gate-aware,
not a through-wall Euclidean-radius claim. B29 source manifest verification covered
34 files including client boundary, native dispatch, movement and combat seams;
the October 5 performance pass adds six rendering files for a total of 40.

Deployment timestamps are recorded after actual SetPos, not generation. Exit and
first-attack offsets are relative to that deployment. First attack means the first
positive incoming hostile damage attempt passing entry admission before canonical
defenses; it is not necessarily HP loss or the beginning of an animation. Reconnect
retains progression but starts new diagnostic deployment offsets. `entry_progress`
records serial changes on the existing10-second poll; heartbeat30s and ring64 remain.
No observation changes RNG, admission or lifecycle. This is bounded sampling, not
an exhaustive combat trace: short events can occur between records.

For B29 use the same-session **console_latest.txt + population_latest.txt**. Check
installed SHA/dirty label, GAME-mounted verification (34 files in B29, 40 now),
map/seed/build identity, entry version and elapsed/deployment timing before
attributing any count. B27's keycard-only logs cannot diagnose the later B28
arrival-mobbing report. A read-only `lod_population_evidence` remains optional;
normal play already records release data. Native expectations and finite headless
bounds are in `validation/BESTIARY_B29.md`.

## Steam Deck rendered-frame evidence

The October 5 performance candidate extends the existing saved Reduced Effects
option. After deploying on gm_flatgrass, one batch captures three minutes of
loaded play without changing resolution, graphics settings, sync or frame limits:

`lod_reduced_effects 1; lod_perf_start 180`

The client waits for wall preparation and three seconds of warmup, then records
rendered frame intervals, active-play FPS/median/p95/p99/max, >25/50/100ms counts,
five-second pacing windows, actual viewport/settings, mounted renderer source
hashes and start/end resources. Sampling is bounded and opt-in; there is no idle
frame hook or per-frame disk write. `lod_perf_stop` ends a capture early. This
command observes gameplay; it does not spawn actors, enable cheats or alter RNG.

Return **performance_client_latest.txt + console_latest.txt + population_latest.txt**
from the same canonical data directory, plus the Proton version and confirmation
of windowed Arch Linux Desktop mode. Lua KB is not process/GPU memory. A short,
inactive, fallback, source-mismatched or settings-changing capture requires that
context when assessing performance; aggregate average FPS alone is insufficient.
See [implementation evidence and exact pull/install instructions](validation/STEAM_DECK_20261005.md).
40 FPS target: native validation pending.

## SPOT-07 Fake Gordon observation acceptance

Use `validation/SPOT_07_TELLS.md` on a fully restarted GMod process. Provide the
exact installed/mounted revision, a visual report/clip and same-session console
and available RPG summary. Compare two deployed Heroes with different current
Wisdom observing the same clone: fractional range, cover/height, cloak, all
phases, real/fake reaction and full/reduced effects. Recognition is private and
cosmetic; verify unchanged stun/follow-up duration and cleanup after role/death,
rejoin, PVS loss and reset. Do not confuse disabled-release RPG logging with no
activity, or developer clone exposure with ordinary population/pacing evidence.

## SPOT-04 audio acceptance

Use the compact listening procedure in `validation/SPOT_04_ENEMY_AUDIO.md` on a
fresh GMod process. The evidence is console_latest.txt + rpg_summary_latest.txt
plus the tester's living/dead/other-living/reset/Beam listening report or clip.
Headless StopSound/CSoundPatch assertions and a generic RPG validator do not
establish audible playback or silence. The current 40-file population manifest
remains a population fingerprint, not exhaustive proof of all SPOT-04 audio
modules; retain the exact installed checkout SHA and use a fresh installation.

## SPOT-05 Die Logger acceptance

Use `validation/SPOT_05_DIE_LOGGER.md` for the compact normal-play procedure.
Fully restart the exact local candidate, watch the lower-right event tail and
press L to compare the same sentence, dice, ordered parts and semantic identity
colors. History lasts longer than the HUD; it does not receive different events.
Passive Magic refill/reaching 100 should be silent in both views, while actual
spends/diversion/proc restoration, Health Regeneration and meaningful dice remain.
Observe available status/defense/life events opportunistically, not by requiring
rare rolls or forced enemy exposure. Multiplayer/private-recipient behavior
requires native multiplayer evidence and is not established by a headless pass.

Default upload: **console_latest.txt + rpg_summary_latest.txt**, plus a short
readability report or screenshot/clip of a discrepancy. Detailed RPG session
records are only needed for a specific ordering investigation. The existing
release-mode detailed-logger limitations remain; absent detailed records are not
proof that combat did not happen. Neither logs nor a generic validator alone
establish visible HUD/history parity, sound or Source transport acceptance.

## Primary evidence package

### `console_latest.txt` — exact Garry's Mod console mirror

- Engine source: `garrysmod/console.log`, produced by Steam launch options `-condebug -conclearlog`.
- Physical destination: `garrysmod/data/legend_of_deborah/console_latest.txt`.
- Steam Deck implementation: `tools/install_dev.sh` starts one lightweight external mirror process because Garry's Mod Lua cannot reliably read the engine-level console file through its sandbox. Re-running the installer replaces the prior mirror rather than accumulating watchers.
- Refresh: the mirror checks the engine console every 0.5 seconds and atomically replaces the destination whenever it changes.
- Retention: `-conclearlog` clears the engine source on every fresh Garry's Mod application launch, so the mirrored upload file naturally follows the current application session rather than growing forever.
- Purpose: Lua errors, validator output, console commands, engine warnings, printed runtime status, load failures.
- Send after: every runtime gate unless explicitly told otherwise.

### `rpg_summary_latest.txt` — compact current-session RPG evidence

- Source: `rpg_test_summary.txt`.
- Physical destination: `garrysmod/data/legend_of_deborah/rpg_summary_latest.txt`.
- Retention: overwritten, never appended. The source refreshes automatically every 10 seconds, at `lod_rpg_test_finish`, and during shutdown; each write republishes the physical upload copy.
- Purpose: latest player profiles, event counts, dice/explosion aggregates, test markers, core RPG validation result, reload-scaling summary.
- Send after: every RPG/Gate E runtime gate, normally paired with `console_latest.txt`.

### `rpg_session_latest.txt` — detailed current RPG server session

- Source: `rpg_test_session.txt`.
- Physical destination: `garrysmod/data/legend_of_deborah/rpg_session_latest.txt`.
- Retention: source is overwritten at each RPG logger/server session. It compacts only above 8 MiB, retaining the newest 4 MiB; the summary continues to aggregate the whole active session.
- Purpose: event ordering, individual rolls, damage resolution, profile changes, XP attribution, marks, and reload-scale events emitted at the actual scaling seam.
- Send after: timing bugs, event-order bugs, unexplained combat/RPG behavior, or whenever the summary lacks enough detail.

## Rolling history

### `rpg_archive_latest.txt` — bounded multi-session RPG archive

- Source: `rpg_test_log.txt`.
- Physical destination: `garrysmod/data/legend_of_deborah/rpg_archive_latest.txt`.
- Retention: rolling history. The source compacts above 4 MiB and retains the newest 2 MiB. `lod_rpg_test_log_reset` remains a manual hard reset when a completely clean archive is specifically useful.
- Purpose: comparing recent server sessions and finding intermittent regressions across restart boundaries.
- Send after: only when specifically requested.

The original `rpg_test_*.txt` files remain internal telemetry sources for compatibility. The `*_latest.txt` files are the canonical **upload package**.

## Standard test protocol

1. Run `./tools/install_dev.sh` after pulling a new build. This also refreshes the single console-mirror watcher.
2. Start Garry's Mod fresh for a clean engine console when beginning a distinct runtime gate.
3. Run the requested finite validator/test commands and exercise the mechanic.
4. Add a marker with `lod_rpg_test_mark <short note>` when a moment is worth correlating with detailed telemetry.
5. Run `lod_rpg_validate`.
6. End with `lod_rpg_test_finish <short-test-label>`. This records the final marker/profile/validator evidence and republishes the RPG upload copies.
7. Run `lod_rpg_test_upload_status` when verifying the evidence pipeline itself or when requested.
8. Upload **`console_latest.txt` + `rpg_summary_latest.txt` by default**. Add `rpg_session_latest.txt` when detailed timing/event order matters. Upload `rpg_archive_latest.txt` only when requested.

`lod_rpg_test_export_now <label>` forces an immediate RPG republish if a test was interrupted. The engine console mirror is independent and does not require this command.

Screenshots remain useful for visual/layout/rendering defects. Logs replace screenshots for console text, validator output, event sequencing, combat-roll evidence, and most runtime diagnostics.


## SPOT-15 Soldier F3 menu

Finite gate: `python3 tools/test_spot15_gate.py --output /absolute/empty/evidence-dir
--suite-timeout 120 --workers 2` (one command). All87 SPOT-14 selections remain;
server/client production boundaries and Feather revival bring the selection to90.
Pre-closeout gate01 passed90/90, syntax751; focused196 server +229 client assertions.
The final frozen and independent gate receipts identify the exact published source.
Retain raw failures and source manifests; SPOT_15_ATTEMPTS.tar.xz/HISTORY.md states
where full earlier source copies do or do not exist. No retroactive passes.

Exact installed gm_flatgrass observation: living/waiting Soldier F3 and hint; queue
return versus spectate-only; native equipment retirement and saved-Hero revival;
remaining twenty-second Soldier death delay; ordinary Hero choices; no pause.
Capture console_latest.txt + rpg_summary_latest.txt with the exact build and a short
note. Native input/layout/fonts/co-op and timing are open, not established by the
headless gate. Preserve SPOT-14 clock and SPOT-13 unread/drag observations. No Razor
retest. Local acceptance -> Workshop parity -> matching VPS; no release operation.


## Authored modular boss diagnostics

`lod_boss_status` reports current identity, phase, exact encounter serial, primary death receipt and actor/object/hazard counts. In an explicitly unranked developer test session, `lod_developer_mode 1; lod_boss_test_level 14` builds the selected authored dungeon; deploy normally, then `lod_boss_testkit; lod_boss_status`. Test levels are restricted to 1–20 and never bypass a module’s completion law. `lod_warden_status` remains the Gordon-specific diagnostic.

Boss logs use `BOSS_` events with identity/serial/phase. Preserve failed allocation, cancellation, lifetime rejection and module error evidence. Capture canonical `console_latest.txt` plus `rpg_summary_latest.txt`, adding the session log only for ambiguous ordering. See `BOSS_PRODUCTION_ACCEPTANCE.md`; native results remain distinct from headless source gates.
