# Runtime Test Logging

The Legend of Deborah keeps its runtime evidence in Garry's Mod's proven writable/uploadable data directory:

`garrysmod/data/legend_of_deborah/`

On Shael's Steam Deck this is:

`/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`

The upload-facing files are **ordinary physical `.txt` files**, not checkout symlinks.

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
34-file SHA256 manifest (eight files in B28); missing/mismatched source is explicitly unverified.
No population observation enables cheats, spawns monsters or changes campaign RNG.

## B29 arrival and opening evidence

`b29-entry-safety` extends the same automatic release observer. Each entry snapshot
reports the sanctuary cells; live AI/damage/spawn function bindings; safety/admission
counters; and per-deployed Hero depth, high-water, completed contacts, current cap,
respite, nearby living hostiles and source counts, admitted members and currently
engaged targets. Nearby observation includes sanctuary occupants; a safe Hero's
zero engaged count must not conceal a mob nearby. Locality is graph/gate-aware,
not a through-wall Euclidean-radius claim. Source manifest verification now covers
34 files including client boundary, native dispatch, movement and combat seams.

Deployment timestamps are recorded after actual SetPos, not generation. Exit and
first-attack offsets are relative to that deployment. First attack means the first
positive incoming hostile damage attempt passing entry admission before canonical
defenses; it is not necessarily HP loss or the beginning of an animation. Reconnect
retains progression but starts new diagnostic deployment offsets. `entry_progress`
records serial changes on the existing10-second poll; heartbeat30s and ring64 remain.
No observation changes RNG, admission or lifecycle. This is bounded sampling, not
an exhaustive combat trace: short events can occur between records.

For B29 use the same-session **console_latest.txt + population_latest.txt**. Check
installed SHA/dirty label,34-file GAME-mounted verification, map/seed/build identity,
entry version and elapsed/deployment timing before attributing any count. B27's
keycard-only logs cannot diagnose the later B28 arrival-mobbing report. A read-only
`lod_population_evidence` remains optional; normal play already records release data.
Native expectations and finite headless bounds are in `validation/BESTIARY_B29.md`.

## SPOT-04 audio acceptance

Use the compact listening procedure in `validation/SPOT_04_ENEMY_AUDIO.md` on a
fresh GMod process. The evidence is console_latest.txt + rpg_summary_latest.txt
plus the tester's living/dead/other-living/reset/Beam listening report or clip.
Headless StopSound/CSoundPatch assertions and a generic RPG validator do not
establish audible playback or silence. The existing 34-file population manifest
remains a population fingerprint, not exhaustive proof of all SPOT-04 audio
modules; retain the exact installed checkout SHA and use a fresh installation.

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
