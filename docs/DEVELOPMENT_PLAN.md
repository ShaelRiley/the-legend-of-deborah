# Development Plan — 2026-09-03 RPG Priority

The live GDD is design authority. GitHub `main` is implementation authority.

## Development order

1. Core multiplayer smoke foundation — **accepted** from the September 1 VPS playtest.
2. RPG Gates A–D / class integration — implemented and under runtime tuning.
3. Gate E Batch 1 CON Health Regeneration — **runtime accepted**.
4. Gate E Batch 2 WIS Navigation — **runtime accepted**.
5. Gate E Batch 3 INT Ammo-Regeneration Floors — **runtime accepted 2026-09-03**.
6. Gate E Batch 4 DEX exploding-dice ladder — **runtime accepted 2026-09-03**.
7. Gate E Batch 5 DEX reload cadence — **gameplay behavior successful; short logged-closure confirmation next**.
8. Continue the remaining Gate E families until all 73 ordinary feats have canonical gameplay bridges and finite validators.
9. Implement all 192 authored Origin/Background/Motive perk bridges.
10. Run the full six-stat / Level 1–20 / combat-order / player-enemy RPG consistency audit.
11. Single-client balance across randomized Heroes, classes, ability extremes, and emergent cross-system builds.
12. Focused post-RPG VPS multiplayer regression.
13. Consolidate authority debt exposed by evidence, then implement Neil + The Brute, Gordon the Warden, final arena, map degradation, soak, and polish.

## Runtime evidence protocol

All runtime gates use `docs/TEST_LOGGING.md`.

- Run `./tools/install_dev.sh` after pulling; this now maintains exactly one external Steam Deck mirror of the engine `console.log` into the canonical data directory.
- Start Garry's Mod fresh when beginning a distinct gate so `-condebug -conclearlog` gives a clean engine console.
- End the gate with `lod_rpg_test_finish <short-test-label>`.
- Canonical upload directory: `/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`.
- Default physical evidence package: `console_latest.txt` + `rpg_summary_latest.txt`.
- Add `rpg_session_latest.txt` for timing/event-order or unexplained combat/RPG behavior.
- `rpg_archive_latest.txt` is bounded rolling cross-session history and is uploaded only when specifically requested.
- Screenshots remain appropriate for visual/rendering/layout defects; logs are preferred for console text and runtime mechanics.

## Immediate runtime gate — Batch 5 logged closure

Full reload gameplay testing has already been repeated successfully. The next pass exists only to confirm repaired observability, so do **not** repeat the whole rank ladder.

On a fresh `gm_flatgrass` run with `lod_developer_mode 1`:

1. Run `lod_rpg_test_upload_status`; `console_latest.txt` should exist as the external engine-console mirror rather than a Lua-generated placeholder.
2. Run `lod_rpg_gate_e_reload_validate`; require the DEX Reload family PASS line.
3. Configure `lod_rpg_test_reload 3` and use the AR2 normally. Reload it at least once while Blink Reload is active.
4. Run `lod_rpg_gate_e_reload_status`; require multiplier `0.40`, `scaledExtensions > 0`, and a `last=` entry identifying an AR2 reload deadline that was compressed.
5. Run `lod_rpg_validate`; require core PASS and no Lua errors.
6. Run `lod_rpg_test_finish batch5-reload-telemetry`, then `lod_rpg_test_upload_status`.
7. Upload `console_latest.txt`, `rpg_summary_latest.txt`, and—for this instrumentation confirmation only—`rpg_session_latest.txt` from the canonical data directory.
8. Require summary evidence of `reload_scale_events > 0`, `last_reload_weapon=weapon_ar2`, a `TEST_END batch5-reload-telemetry` mark, and `last_rpg_validate=PASS`. Once those agree with the already-successful play evidence, formally runtime-accept Batch 5.

## Batch 5 balance note

Repeated play found Blink Reload + AR2 creates almost-continuous fire because reload downtime becomes nearly imperceptible. Preserve this. The AR2's laser telegraph and delay before each burst remain meaningful authored costs, so the reload feat creates a distinct high-DEX build payoff rather than simply erasing the weapon's identity.

## Batch 4 acceptance note

The accepted Batch 4 live test corrected one earlier handoff statement: the **baseline Crowbar is d3, not d8**. It correctly remained outside Perfect Ten / Eight Is Enough / Fourtunate; Rogue mastery is the broader rule that may explode eligible d3 actor-owned damage dice. The same run showed a strong but desirable Wizard full-Magic Arcane Surge + exploding-Pistol composition, retained for later balance evaluation.

## Gate E accounting after Batch 5 implementation

- 73 ordinary feats total;
- 15 mechanically implemented;
- 14 catalog/ownership-only;
- 44 not yet catalogued;
- 58 gameplay effects remain.

## Preserved constraints

`gm_flatgrass` remains the required test map; the canonical graph remains topology authority; Motion V2 remains ordinary hostile motion authority; server CombatRolls remains dice authority; Magic/resources remain personal while world progression is shared. Batch 5 changes only genuine reload timing: it must not become a generic attack-cooldown, overheat, telegraph, burst-spacing, or Magic-cooldown modifier.
