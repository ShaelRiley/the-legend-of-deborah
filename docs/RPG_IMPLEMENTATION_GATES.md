# RPG Overhaul Implementation Gates

Design authority: the live **The Legend of Deborah — Garry's Mod Game Design Document**. GitHub `main` remains implementation authority.

## Gate summary

- **Gate A — scaffold:** schema, constants, deterministic seeds, state constructors, core validation.
- **Gate B — Level-1 identity/class/feat:** deterministic Hero identity, class commitment, stored three-card feat draft, Character Sheet, deployment gate.
- **Gate C — Levels 1–20:** exact XP table, growth, stored progression hit dice, MaxHP recomputation, seven ordinary feat slots, Level-20 capstones.
- **Gate D — ability/class gameplay:** STR/DEX/CON/INT/WIS/CHA bridges, Rogue damage-die mastery, Wizard diversion, Fighter/Rogue/Wizard capstones, XP attribution, core gameplay validation.
- **Gate E — ordinary feat effects:** active family-by-family implementation at canonical semantic seams.

## Runtime evidence standard

Every finite RPG runtime gate follows `docs/TEST_LOGGING.md`:

1. Pull/install the current build; the installer maintains one external engine-console mirror on Steam Deck.
2. Fresh-start Garry's Mod for a clean engine console when beginning a distinct gate.
3. Run the family validator/testkit and exercise the mechanic.
4. Use `lod_rpg_test_mark <note>` for moments worth correlating with telemetry.
5. Run `lod_rpg_validate` and then `lod_rpg_test_finish <short-test-label>`.
6. Upload **`console_latest.txt` + `rpg_summary_latest.txt` from `garrysmod/data/legend_of_deborah/` by default**. Add `rpg_session_latest.txt` for detailed timing/event order. Upload `rpg_archive_latest.txt` only for requested cross-session investigation.

The engine console is mirrored outside the GMod Lua sandbox every 0.5 seconds. The current-session RPG summary refreshes automatically every 10 seconds and at test finish. Detailed session and rolling archive files are bounded so unattended developer testing cannot grow them indefinitely.

## Gate E accepted batches

### Batch 1 — CON Health Regeneration — PASSED 2026-09-02

Second Wind / Rapid Recovery / Unbroken were runtime accepted at exact 11/22/33% replacement ceilings with the tested 1.20 HP/s CON-scaled rate and no visible Lua error.

### Batch 2 — WIS Navigation — PASSED 2026-09-02

Surveyor / Cartographer / Frugal Cartography were runtime accepted. Cartographer produced the authored replacing +8 bonus (16 BreadcrumbCells for the tested WIS profile); Frugal Cartography produced the canonical 5.44 Magic/s map drain in the accepted test and preserved no-regeneration-while-open.

### Batch 3 — INT Ammo-Regeneration Floors — PASSED 2026-09-03

Field Supply / Deep Reserves / War Stock are accepted. Runtime evidence confirmed floor fractions 0.33/0.55/0.66, expected Magnum/Pistol ceilings, unchanged 30.00s Magnum and 3.33s Pistol round intervals, core RPG validator PASS, and no reported Lua error.

### Batch 4 — DEX Exploding-Dice Ladder — PASSED 2026-09-03

Perfect Ten / Eight Is Enough / Fourtunate are runtime accepted. The finite family validator and core RPG validator both passed. Rank testing confirmed the additive d10→d8→d4 ladder and the live combat feed demonstrated the intended selectivity: a Fourtunate-enabled Pistol d4 could Boomchain, while the **baseline Crowbar remained its authored d3 and did not gain explosion permission from these three feats**. Full Rogue mastery remains broader and may explode eligible actor-owned d3 damage dice. No Lua error was visible in the supplied runtime evidence.

The accepted run also demonstrated positive emergent composition rather than a defect: a Wizard at full Magic could combine Arcane Surge's INT damage with a Fourtunate-enabled exploding Pistol. Preserve this interaction for later whole-RPG balance testing unless broader evidence shows a problem.

Batch 4 implementation remains centralized at `AbilityRules:CopyDamageProfile` / `CombatRolls:_RollExploding`: fresh d10/d8/d4 thresholds are natural 10/8/4, continuation thresholds are `max(2, sides-BoomShift)`, Rogue offers exclude redundant ladder cards, `classExplosionImmune=true` remains absolute, universal d6/SUPER-d12 rules remain untouched, and the 32-die cap remains absolute.

## Gate E Batch 5 — DEX Reload Cadence

Implemented from live-GDD revision `ANLCKQlypm6azjpK6CFPntqCTeHdrbGj3gqHEw0WMaFrgcSu7eSm7HUSUAFdcdeUI3ZMHjp4d1773GjsBEDij7b2tiy_3WSTap-s_Ky9YQ`:

- `DEX_FAST_RELOAD` / Quick Reload: DEX 12; `ReloadTimeMultiplier = 0.80`.
- `DEX_FAST_RELOAD_2` / Lightning Reload: DEX 16 + Quick Reload; replaces the total multiplier with `0.60`.
- `DEX_FAST_RELOAD_3` / Blink Reload: DEX 18 + Lightning Reload; replaces the total multiplier with `0.40`.
- one derived `reloadTimeMultiplier` value owns the active replacement rank;
- the runtime bridge observes stock Source `m_bInReload` state and compresses only deadlines newly authored by a genuine reload;
- every pre-existing weapon/player deadline is an absolute floor, so pressing Reload cannot shorten SMG overheat recovery, AR2 targeting/burst recovery, or an unrelated attack lock;
- shell-by-shell Shotgun reloads remain in one bounded observation session, allowing each authored shell-reload extension to use the multiplier without replacing the Shotgun's reload mechanism;
- attack input ends observation before a firing cooldown can be authored, preventing reload feats from becoming rate-of-fire feats;
- player viewmodel playback is accelerated only while the authoritative reload session is active and is restored afterward;
- the Character Sheet owned-feat ledger reports the current total ordinary reload-time multiplier;
- `lod_rpg_gate_e_reload_validate`, `lod_rpg_gate_e_reload_status`, `lod_rpg_test_reload <0-3>`, and `lod_rpg_gate_e_reload_testkit [pistol|shotgun]` provide finite validation/testing;
- core `lod_rpg_validate` includes the Batch 5 validator.

### Batch 5 current runtime evidence

Repeated Steam Deck play indicates the family behaves correctly across the tested ranks and weapon paths. Blink Reload with the AR2 creates a particularly strong but desirable high-DEX option: reload downtime becomes barely perceptible and permits almost-continuous fire, while the weapon's telegraphed laser and pre-burst delay retain its authored cadence. Preserve that composition for later whole-RPG balance evaluation rather than treating it as a defect.

The latest uploaded evidence exposed two **logging** defects, not a reported gameplay failure: the summary contained 51 AR2/d10 player-roll events but zero reload-scale events, and the physical console file was only an `ENGINE_CONSOLE_NOT_READABLE` placeholder because Steam Deck GMod Lua could not read the engine-level console. The repaired evidence path therefore:

- mirrors real `garrysmod/console.log` externally into physical `data/legend_of_deborah/console_latest.txt`;
- emits `RELOAD_SCALE` telemetry synchronously when the canonical reload runtime increments its actual scaling counter;
- leaves the existing finite validator and reload mechanics unchanged.

### Batch 5 short logged-closure gate

Do not repeat the complete rank ladder again. On fresh `gm_flatgrass` with `lod_developer_mode 1`:

1. Run `lod_rpg_test_upload_status` and confirm the physical console mirror is nonempty.
2. Run `lod_rpg_gate_e_reload_validate`; require `DEX Reload feat family PASS`.
3. Run `lod_rpg_test_reload 3`, use the AR2, and reload it at least once.
4. Run `lod_rpg_gate_e_reload_status`; require multiplier `0.40`, `scaledExtensions > 0`, and an AR2 `last=` scaling entry.
5. Run `lod_rpg_validate`; require core PASS and no Lua errors.
6. Run `lod_rpg_test_finish batch5-reload-telemetry`, then `lod_rpg_test_upload_status`.
7. Upload `console_latest.txt`, `rpg_summary_latest.txt`, and `rpg_session_latest.txt` from `/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`.
8. Formal acceptance requires the repaired summary/session to show reload scaling plus the final test mark/core PASS, agreeing with the already-successful gameplay evidence.

Gate E remains open after Batch 5. The completeness ledger is `docs/RPG_GATE_E_FEAT_MATRIX.md` and accounts for 73 total ordinary feats: 15 implemented, 14 catalog/ownership-only, 44 not yet catalogued, 58 gameplay effects remaining.
