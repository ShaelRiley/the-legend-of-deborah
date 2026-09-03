# Runtime Test Logging

The Legend of Deborah keeps its runtime evidence in Garry's Mod's proven writable/uploadable data directory:

`garrysmod/data/legend_of_deborah/`

On Shael's Steam Deck this is:

`/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`

The upload-facing files are **ordinary physical `.txt` files**, not checkout symlinks.

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
