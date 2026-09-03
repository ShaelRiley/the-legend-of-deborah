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

### Batch 5 — DEX Reload Cadence — PASSED 2026-09-03

Quick Reload / Lightning Reload / Blink Reload are runtime accepted from live-GDD revision `ANLCKQlypm6azjpK6CFPntqCTeHdrbGj3gqHEw0WMaFrgcSu7eSm7HUSUAFdcdeUI3ZMHjp4d1773GjsBEDij7b2tiy_3WSTap-s_Ky9YQ`:

- `DEX_FAST_RELOAD` / Quick Reload: DEX 12; `ReloadTimeMultiplier = 0.80`.
- `DEX_FAST_RELOAD_2` / Lightning Reload: DEX 16 + Quick Reload; replaces the total multiplier with `0.60`.
- `DEX_FAST_RELOAD_3` / Blink Reload: DEX 18 + Lightning Reload; replaces the total multiplier with `0.40`.
- one derived `reloadTimeMultiplier` value owns the active replacement rank;
- only deadlines newly authored by a genuine reload may be compressed;
- every pre-existing weapon/player deadline remains an absolute floor, protecting SMG overheat recovery, AR2 targeting/burst timing, and unrelated attack locks;
- Shotgun shell reloads remain engine-authored and are accelerated stage-by-stage;
- attack input ends observation before a firing cooldown can be captured;
- player viewmodel playback is accelerated only during the authoritative reload session and restored afterward;
- Character Sheet/runtime truth exposes the current total multiplier;
- finite family/status/testkit commands remain available and core `lod_rpg_validate` covers the bridge.

Final Steam Deck `gm_flatgrass` acceptance evidence:

- rank 3 active with multiplier `0.40`;
- active weapon `weapon_ar2`;
- `scaledExtensions=3`;
- final status `last=weapon_ar2/player 1.55s->0.62s`;
- summary `reload_scale_events=3`;
- `last_reload_weapon=weapon_ar2`;
- `last_reload_multiplier=0.4`;
- authored `1.5516667s`, scaled `0.6206667s`, saved `0.9310000s`;
- `TEST_END batch5-clock-fix` and final core RPG validation PASS.

The acceptance investigation found and repaired a systemic Source/GMod clock-boundary error. Garry's Mod public weapon timing accessors are authoritative absolute `CurTime()` values. Raw Source `FIELD_TIME` internals/save fields are CurTime-relative and are translated only at that low-level boundary. This keeps genuine reload scaling coherent without allowing unrelated lockouts to be shortened.

Blink Reload + AR2 is deliberately retained as positive emergent high-DEX build space: reload downtime can become nearly imperceptible while the AR2's laser telegraph, pre-burst delay, and burst-internal spacing remain authored costs.

Gate E remains open after Batch 5. The completeness ledger is `docs/RPG_GATE_E_FEAT_MATRIX.md` and accounts for 73 total ordinary feats: 15 implemented, 14 catalog/ownership-only, 44 not yet catalogued, 58 gameplay effects remaining.
