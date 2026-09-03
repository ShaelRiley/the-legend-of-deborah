# Runtime Test Logging

The Legend of Deborah keeps its runtime evidence in Garry's Mod's proven writable/uploadable data directory:

`garrysmod/data/legend_of_deborah/`

On Shael's Steam Deck this is:

`/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`

The upload-facing files are **ordinary physical `.txt` files**, not checkout symlinks.

## Primary evidence package

### `console_latest.txt` — exact Garry's Mod console export

- Source: Source-engine `garrysmod/console.log` from `-condebug -conclearlog`; `console.txt` is accepted as an engine-variant fallback.
- Export destination: `garrysmod/data/legend_of_deborah/console_latest.txt`.
- Retention: the engine source resets on every fresh GMod application launch. The upload copy refreshes whenever the RPG summary is written and at shutdown.
- Size safety: if the engine console exceeds 8 MiB, the upload copy preserves the first 256 KiB for startup/load evidence plus the newest 6 MiB for current runtime evidence. The original engine console is never modified by this compaction.
- Purpose: Lua errors, validator output, console commands, engine warnings, printed runtime status, load failures.
- Send after: every runtime gate unless explicitly told otherwise.

### `rpg_summary_latest.txt` — compact current-session RPG evidence

- Source: `rpg_test_summary.txt`.
- Export destination: `garrysmod/data/legend_of_deborah/rpg_summary_latest.txt`.
- Retention: overwritten, never appended. The source refreshes automatically every 10 seconds, at `lod_rpg_test_finish`, and during shutdown; each write refreshes the physical upload copy.
- Purpose: latest player profiles, event counts, dice/explosion aggregates, test markers, core RPG validation result, reload-scaling summary.
- Send after: every RPG/Gate E runtime gate, normally paired with `console_latest.txt`.

### `rpg_session_latest.txt` — detailed current RPG server session

- Source: `rpg_test_session.txt`.
- Export destination: `garrysmod/data/legend_of_deborah/rpg_session_latest.txt`.
- Retention: source is overwritten at each RPG logger/server session. It compacts only above 8 MiB, retaining the newest 4 MiB; the summary continues to aggregate the whole active session.
- Purpose: event ordering, individual rolls, damage resolution, profile changes, XP attribution, marks, reload-scale events.
- Send after: timing bugs, event-order bugs, unexplained combat/RPG behavior, or whenever the summary lacks enough detail.

## Rolling history

### `rpg_archive_latest.txt` — bounded multi-session RPG archive

- Source: `rpg_test_log.txt`.
- Export destination: `garrysmod/data/legend_of_deborah/rpg_archive_latest.txt`.
- Retention: rolling history. The source compacts above 4 MiB and retains the newest 2 MiB. `lod_rpg_test_log_reset` remains a manual hard reset when a completely clean archive is specifically useful.
- Purpose: comparing recent server sessions and finding intermittent regressions across restart boundaries.
- Send after: only when specifically requested.

The original `rpg_test_*.txt` files remain the internal telemetry sources for compatibility. The `*_latest.txt` files are the canonical **upload package**.

## Standard test protocol

1. Start Garry's Mod fresh for a clean engine console when beginning a distinct runtime gate.
2. Run the requested finite validator/test commands and exercise the mechanic.
3. Add a marker at an important moment with `lod_rpg_test_mark <short note>` when useful.
4. Run `lod_rpg_validate`.
5. End the test with `lod_rpg_test_finish <short-test-label>`. The summary write automatically republishes all upload-facing `.txt` files into `data/legend_of_deborah/`.
6. Run `lod_rpg_test_upload_status` if you want to confirm filenames and sizes.
7. Upload **`console_latest.txt` + `rpg_summary_latest.txt` by default**. Add `rpg_session_latest.txt` when detailed timing/event order matters. Upload `rpg_archive_latest.txt` only when requested.

`lod_rpg_test_export_now <label>` forces an immediate republish if a test was interrupted or you want a fresh evidence snapshot without ending the test.

Screenshots remain useful for visual/layout/rendering defects. Logs replace screenshots for console text, validator output, event sequencing, combat-roll evidence, and most runtime diagnostics.
