# Runtime Test Logging

The Legend of Deborah uses one engine console capture plus three RPG observability artifacts. The first three entries below are the normal playtest workflow; the rolling archive is retained for deeper cross-session diagnosis.

## Primary evidence package

### `console_latest.log` — exact Garry's Mod console

- Source: Garry's Mod `garrysmod/console.log` through the checkout convenience symlink.
- Required Steam launch options: `-condebug -conclearlog`.
- Retention: **overwritten on every fresh Garry's Mod application launch** by `-conclearlog`.
- Purpose: Lua errors, validator output, console commands, engine warnings, printed runtime status, load failures.
- Send after: every runtime gate unless the test is purely visual and no console evidence is relevant.

### `rpg_summary_latest.log` — compact current-session RPG evidence

- Source: `garrysmod/data/legend_of_deborah/rpg_test_summary.txt`.
- Retention: **overwritten**, never appended. It refreshes automatically every 10 seconds while RPG telemetry is active, on `lod_rpg_test_finish`, and during normal shutdown.
- Purpose: latest player profiles, event counts, dice/explosion aggregates, test markers, core RPG validation result, reload-scaling summary.
- Send after: every RPG/Gate E runtime gate. This is normally paired with `console_latest.log`.

### `rpg_session_latest.log` — detailed current RPG server session

- Source: `garrysmod/data/legend_of_deborah/rpg_test_session.txt`.
- Retention: **overwritten at each RPG logger/server session**. To prevent pathological growth, it compacts only if it exceeds 8 MiB, retaining the newest 4 MiB. The in-memory summary continues to aggregate the whole active session.
- Purpose: event ordering, individual rolls, damage resolution, profile changes, XP attribution, marks, reload-scale events.
- Send after: timing bugs, event-order bugs, unexplained combat/RPG behavior, or whenever the summary lacks enough detail.

## Rolling history

### `rpg_archive_latest.log` — bounded multi-session RPG archive

- Source: `garrysmod/data/legend_of_deborah/rpg_test_log.txt`.
- Retention: rolling history. It compacts above 4 MiB and retains the newest 2 MiB. `lod_rpg_test_log_reset` remains a manual hard reset when a completely clean archive is specifically useful.
- Purpose: comparing recent server sessions and finding intermittent regressions that crossed a restart boundary.
- Send after: only when specifically requested for cross-session investigation.

## Standard test protocol

1. Start Garry's Mod fresh for a clean `console_latest.log` when beginning a distinct runtime gate.
2. Run the requested finite validator/test commands and exercise the mechanic.
3. Add a marker at an important moment with `lod_rpg_test_mark <short note>` when useful.
4. End the test with `lod_rpg_test_finish <short-test-label>`. This records a final marker, captures current player profiles, runs the core RPG validator silently into telemetry, writes the summary immediately, applies retention bounds, and prints the upload recommendation.
5. Upload **`console_latest.log` + `rpg_summary_latest.log` by default**. Add `rpg_session_latest.log` when detailed timing/event order matters. Upload `rpg_archive_latest.log` only when requested.

`lod_rpg_test_logs_status` prints current sizes and retention policy in-game.

Screenshots remain useful for visual/layout/rendering defects. Logs replace screenshots for console text, validator output, event sequencing, combat-roll evidence, and most runtime diagnostics.
