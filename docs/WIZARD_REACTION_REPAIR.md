# Wizard reactions and total-first DIE-LOGGER — 2026-09-14

Base: `ac82bda8c0f1552b6fbeeacd8b1215561187997d`, `hybrid/antigravity`.
Shael requested new effects rather than recreating the old aesthetic. Mechanics
remain governed by the live GDD, navigated 00 → 01 → 03; no balance changes.

## Changes

- Arcane Diversion: inward cyan/teal motes, a brief crystalline catch sound,
  an independent first-person label showing HP saved and Magic lost, and the
  existing small Magic-number highlight. The logger shows damage remaining after
  diversion, incoming damage, prevented HP and actual Magic loss. This is explicitly
  the diversion stage; a subsequent lethal-defense intercept can still change HP loss.
- Feedback: blue electric return filament with impact motes, a distinct discharge,
  and a first-person damage-total label. NPC retaliation against a human uses
  `ENEMY FEEDBACK!`. The path uses the actual captured attacker position.
- Both reactions use one existing major-FX transport and one new client renderer.
  Removed the old broadcast beam/sound path and the separate three-NW2-variable
  Diversion observer. Level-up and dice-explosion presentation cannot suppress the
  Wizard reaction layer. These are recipient-local cues, not globally broadcast
  particles or added world entities.
- At most two short reaction records exist per client; lifetime 0.80 seconds.
  Reduced-effects mode lowers mote/motion work. Shield packets are capped at ten
  per second, sounds have independent short throttles, and the logger retains every
  authoritative diversion. A presentation transport failure cannot abort defense.
- Shared damage sentences now lead with `(TOTAL) DAMAGE`, followed by actor,
  recipient, source, formula and all rolled values/continuations. Feedback also
  retains its actual CON-per-die reduction in the shared breakdown. Old saved
  sentences remain readable with their original semantic spans.

Example: `(4) DAMAGE — Wizard → Soldier, via Feedback; 2d4+2 [rolls 2, 2 + 2 bonus = 6 rolled; CON -1/die: 1 + 1 = 4; resolved 4]`.

## Evidence

Integrated gate: **55/55**, including project Lua syntax, diff check, feat gate
(approved 150 entries; zero blank descriptions), and a new production-path test:
defense transaction → scheduled Feedback → actual formula/CON resolution → one
packet each → client receive → distinct sound requests and world/HUD drawing.
The test also covers coexistence with level-up, flood bounds, expiry, map cleanup,
and failed presentation transport preserving the defense result.

Static success does not prove Source audibility, occlusion or mix quality. No main
promotion or live deployment. Fully quit GMod before pulling/installing: the existing
major-FX packet now includes the reaction's world endpoints.

## Shael's next integrated playtest

Steam launch options: `-condebug -conclearlog`. Run `bash tools/install_dev.sh` after
pulling so the single console mirror is active. Fresh `gm_flatgrass` campaign:

`lod_developer_mode 1; lod_rpg_test_mark wizard_reactions_start`

Optional presentation-only preview (changes no character resources or gameplay):

`lod_rpg_major_fx_test diversion; lod_rpg_major_fx_test feedback`

Play a Wizard with Magic available, take ordinary enemy hits, and compare shield
absorption and successful Feedback with the logger. Feedback is probabilistic;
it does not fire on every hit. Continue the integrated combat, feats, death/Tetris,
Soldier/multiplayer and level-transition test. End with:

`lod_rpg_test_finish wizard_reactions; lod_rpg_test_upload_status`

Upload `console_latest.txt`, `rpg_summary_latest.txt`, `rpg_session_latest.txt` and
`die_logger_history.json` from:

`/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`

Logger history auto-saves every two seconds and on shutdown. If an effect is still
missing or unclear, include a short video with audio; logs alone cannot establish
what Shael actually saw or heard. If disconnected, preserve these files before
starting another server session; the session/summary exports are already periodic.
