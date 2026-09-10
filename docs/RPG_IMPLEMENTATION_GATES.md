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

- `DEX_FAST_RELOAD` / Quick Reload: current live-GDD prerequisite DEX 13; `ReloadTimeMultiplier = 0.80`.
- `DEX_FAST_RELOAD_2` / Lightning Reload: current prerequisite DEX 15 + Quick Reload; replaces the total multiplier with `0.60`.
- `DEX_FAST_RELOAD_3` / Blink Reload: current prerequisite DEX 17 + Lightning Reload; replaces the total multiplier with `0.40`.
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

### Batch 6 — DEX Rate-of-Fire Cadence — PASSED 2026-09-05

Hair Trigger / Rapid Fire / Lead Storm are runtime accepted from the same live-GDD authority:

- `DEX_RATE_OF_FIRE_1` / Hair Trigger: DEX 13; total `RateOfFireMultiplier = 1.10`.
- `DEX_RATE_OF_FIRE_2` / Rapid Fire: DEX 15 + Hair Trigger; replaces the total multiplier with `1.20`.
- `DEX_RATE_OF_FIRE_3` / Lead Storm: DEX 17 + Rapid Fire; replaces the total multiplier with `1.30`.
- applicability is ordinary firearm primary attacks only;
- reload time, Magic cooldowns, enemy telegraphs, secondary attacks, SMG overheat recovery, and authored burst-internal spacing remain outside the family;
- AR2 uses its custom burst authority instead of generic stock `IN_ATTACK` cadence;
- every successful AR2 burst starts one player-local cadence transaction at the authoritative `BeginAR2Burst` seam;
- every successful round is confirmed at the authoritative `FireAR2Round` seam;
- only a completed three-round burst earns the shortened next-trigger opportunity;
- the targeting laser, pre-burst delay, and 0.09s internal shot spacing are absolute preserved costs;
- ordinary stock firearms continue through the generic post-shot deadline observer;
- Character Sheet/runtime truth exposes the current total multiplier;
- finite family/status/testkit commands remain available and core `lod_rpg_validate` covers the bridge.

Final Steam Deck `gm_flatgrass` acceptance evidence:

- startup confirmed the custom AR2 transaction bridge plus final `BeginAR2Burst` and `FireAR2Round` authority wrappers were armed;
- rank 3 active at multiplier `1.30`;
- exactly 5 AR2 bursts / 15 rounds;
- console `scaledAttacks=5`;
- final status `last=weapon_ar2/primary 0.880s->0.677s via ar2_burst_complete`;
- summary `rate_of_fire_sessions=5`;
- summary `rate_of_fire_confirmed_attacks=5`;
- summary `rate_of_fire_scale_events=5`;
- `last_rate_of_fire_weapon=weapon_ar2`;
- `last_rate_of_fire_multiplier=1.3`;
- authored `0.88s`, scaled `0.67692307692307s`, saved `0.20307692307692s`;
- `rate_of_fire_deadline_misses=0`;
- `TEST_END batch6-ar2-round-authority` and final core RPG validation PASS.

Batch 6's investigation established a broader implementation rule: custom weapon mechanics must bridge from their final authoritative transaction seams, not from generic input hooks or assumed stock weapon timing. This is especially important for future authored burst-size, AR2 targeting, and SMG-heat feat families.

### Batch 7 — DEX Authored Burst Size — PASSED 2026-09-05

Extra Round / Extended Volley / Full Barrage are runtime accepted. The replacing ladder grants +1/+2/+3 total projectiles only to attacks already authored as `multiFireBurst`. AR2 therefore resolves 4/5/6 projectiles instead of its authored 3 while consuming exactly one AR2 ammo unit for the entire committed trigger burst. Magnum chamber-5/chamber-6 authored burst states inherit their existing spacing, damage, Aim-State, SUPER-d12, and free-projectile ammunition semantics; ordinary Magnum shots, Shotgun pellets, exploding dice, penetration, and unrelated extra-projectile procs remain excluded.

Final `gm_flatgrass` acceptance proved Full Barrage from exactly one AR2 ammo: clip `1→0`, all `6/6` projectiles completed, `completed=1`, `aborted=0`, and core RPG validation PASS. Runtime authority revision `gate_e_ar2_one_ammo_per_burst_v2` reported `beginWrapped=true`, `fireWrapped=true`, `baseConfigOneAmmo=true`, and `resultAdapter=true`.

### Batch 8 — DEX SMG Heat — PASSED 2026-09-05

Cold Hands / Ice in the Veins / Absolute Zero are implemented from live-GDD Google revision `364`:

- DEX 13/15/17 with the exact prerequisite chain;
- replacing total `SMGHeatSuppressionChance` values 0.11/0.22/0.33;
- replacing `SMGOverheatThreshold` values 8/10/12 versus baseline 6;
- one deterministic, server-authoritative roll from the dedicated per-player/per-level `smg-heat:v1` substream for every successfully fired SMG round;
- a suppressed round consumes ammunition and attacks normally but adds 0 rather than +1 heat;
- existing SMG damage, ammunition, Rate-of-Fire composition, 0.25-second sub-threshold cooling cadence, heat feedback stages, and fixed 2.0-second overheat lock remain unchanged;
- actual heat remains networked while the existing absolute tint/audio stages and overheat-smoke cue remain unchanged;
- Character Sheet/runtime status, event telemetry, deterministic family validation, and a seeded finite acceptance kit are included.

Final `gm_flatgrass` acceptance established both sides of the deterministic contract: baseline overheated after exactly 6 shots with 0 suppressed + 6 heat, while Absolute Zero overheated after exactly 18 shots with 6 suppressed + 12 heat at threshold 12. The fixed lock was 2.0 seconds, the seeded acceptance result passed, the staging audit reported `misplaced=0`, and the family plus core validators passed.

### Batch 9 — Four Singleton Families — IMPLEMENTED; RUNTIME ACCEPTANCE PENDING

Spring Heel / Deadeye / Long Reach / Russian Asset are implemented from live-GDD revision `ANLCKQlqd7CuK8mqO8bD6YLSczpkCCbzvF_CuSWwh7tZahxeualxoHhhteJPwzEODy4h7eRO3dVCIqKnCRDqh7Khd3tSntD1CNYK-SRLVg`:

- `DEX_SPRING_HEEL`: DEX 13; voluntary ordinary ground-jump takeoff impulse is multiplied by `sqrt(2)` to produce 2.0× ballistic apex height without touching Push, falls, ladders, stairs, scripted relocation, or blocking geometry;
- `DEX_MAGNUM_DEADEYE`: DEX 15 with no Magnum prerequisite; enables Aim State for all standard player weapons (0.50 sec stillness); ordinary aimed transaction ×2, Magnum aimed transaction ×3 (supersedes the old 0.35s behavior);
- `STR_MELEE_REACH`: STR 15 plus melee access; the existing Crowbar TraceHull extends from 96 to 120 units while the same wall/gate/floor collision mask remains authoritative;
- `CON_RUSSIAN_ASSET`: stable save-compatible ID with current INT 13 qualification; both Tetris reward paths use ×2 overfill rewards, death Tetris uses a 120-second rather than 60-second hard cap, and the 20-second mandatory respawn and victory windows are unchanged;
- one combined baseline/feat testkit and status command exercise all four bridges in a finite pass;
- `DEX_AR2_SNAP` is deliberately deferred because the live ×0.80 rule with a 0.50-second floor conflicts with the current 0.45-second base AR2 tell and would otherwise make the feat slower.

Gate E remains open. After Batch 14, the historical 73-row migration ledger contains 43 mechanically implemented entries, 4 catalog/ownership-only entries, 26 not-yet-catalogued entries, and 30 effects remaining. Two additional expanded-catalog rows are mechanically implemented, bringing the total to 45; the remaining rows from the live 119-row catalog still require reconciliation.

### Batch 10 — Charisma Utility and Presence — RUNTIME ACCEPTED 2026-09-06

Unnerving Presence / Dazing Presence / Overwhelming Presence, Academic Achievement, and Winning Personality are implemented from live-GDD revision `ANLCKQlapECu8CFLXSznFQ2lgvQ8M8VlvQhJ6jUmVhQbn2lCBBwIhl7vSnqoITG_UgVn6lRA023z123S2E8aBALkwBAko20hUtbYAf053Q`:

- the hit-stun ladder uses CHA 13/15/17 and replacing feat multipliers 1.10/1.20/1.30 after the continuous attacker/defender CHA calculation;
- existing retrigger, anti-stunlock, weapon, resistance, and hard-cap authorities remain in place;
- Academic Achievement uses CHA 15 and adds only `max(0, CHA_MOD)` to the passive Magic-regeneration modifier calculation;
- Winning Personality uses CHA 17 and substitutes `max(INT, CHA)` only for printed ability checks on `INT_` feats, preserving actual INT, cross-feat requirements, prerequisites, class exclusions, capabilities, and other restrictions;
- Character Sheet snapshots, a finite validator, combined testkit, and live status telemetry expose all three bridges.

The same authority refresh corrected the prerequisite thresholds of already-built Health Regeneration, WIS Navigation, Ammo-Regeneration Floor, DEX Exploding-Dice, and DEX Reload families to the current live-GDD values. Their accepted gameplay magnitudes and canonical runtime seams are unchanged.

The final `gm_flatgrass` run passed both the family and full RPG validators and reached `TEST_END batch10-charisma`. Baseline/feat status proved the rank-0→rank-3 ×1.30 transition, Academic's effective-regeneration modifier contribution, and Winning Personality's INT-feat score substitution. A live hit on a surviving hostile recorded the exact composed hit-stun result `1.030 × 1.30 = 1.339`.

### Batch 11 — Control and Magic Push/Recovery — PASSED 2026-09-06

Hard to Move / Force Multiplier / Mana Spring are implemented from live-GDD revision `ANLCKQmcBBEnzsnYbFvdzzXmHJB2gAgkhunV5P2pczqttiFNGF1lfRGWUVzYRmO9v_2DdQF2Dpg8w6Ms2v9KI5U5b6HhpuEYa3gnaXvXDA`:

- `CON_STEADFAST`: CON 13; incoming ordinary hit stun and non-scripted push displacement ×0.75, with explicit authored resistance bypass support;
- `WIS_FORCEFUL_MAGIC`: WIS 15 plus a Magic-push capability; explicitly tagged `magic_push` displacement ×1.25, initially bridged at Force Shout without leaking into ordinary physical push;
- `INT_MANA_SPRING`: INT 13 plus a Magic pool; reaching zero arms ×1.50 already-INT-scaled passive Magic regeneration for four unsuppressed seconds, pausing both regeneration and the feat timer during minimap/registered sustained suppression;
- the push authority records authored distance and each ordered multiplier, and now also honors the existing defender-side Fighter capstone multiplier;
- Character Sheet snapshots, exact pure-state validation, a baseline/feat testkit, and live hit-stun/push/Mana telemetry are included;
- all Lua parses, the dedicated Batch 11 harness passes, and the 100-seed maze regression passes.

The first live pass proved baseline behavior plus Hard to Move and Force Multiplier composition (`336 × 1.25 × 0.75 = 315`). The corrected feat-side pass reached zero Magic and recorded one Mana Spring start, 16 active ticks, zero paused ticks, and the same exact 315-unit composed push. The family validator and full RPG validator passed and the run ended at `TEST_END batch11-mana-spring-fix`. A later hit-stun query against a different hostile caused the status line's global resistance field to report `x1.00`; this was a telemetry-only false negative and the status command now reads the designated test target's own `x0.75` result.

### Batch 12 — Magic Recovery — PASSED 2026-09-06

Feedback Loop / Arc Recovery are implemented from the current live-GDD revision:

- `INT_FEEDBACK_LOOP`: INT 15 plus Magic capability; each continuation die actually generated by offensive Magic restores 1 Magic, with one six-Magic budget shared by the whole committed cast;
- `INT_ARC_RECOVERY`: INT 17 plus Magic capability; a confirmed AI-hostile kill from Magic-tagged damage restores 5 Magic through a 2.0-second per-actor cooldown, never above 100;
- the Force Shout authority consumes continuation counts from its canonical resolved damage contracts and evaluates kill recovery only after actual damage;
- weapon Boomchains remain isolated, initial Magic dice do not count, multi-target casts do not reset the Feedback Loop cap, and clustered kills respect one Arc Recovery cooldown;
- Character Sheet/runtime truth, a combined testkit/status command, a finite family validator, and core RPG validation cover the bridge.

Static proof: all Lua parses, `tools/test_gate_e_magic_recovery.lua` passes, and the 100-seed maze regression remains `failures=0` with hash `1736216640`.

Final runtime proof: two actual Force Shout continuation dice restored exactly 2 Magic through Feedback Loop; four Magic-tagged hostile defeats restored 15 total Magic through Arc Recovery; one clustered kill was rejected by its cooldown; status reported `acceptance=PASS`; both validators passed; and the evidence ended at `TEST_END batch12-magic-recovery`.

### Batch 13 — Pusher Family and Shared Push Save — RUNTIME ACCEPTED 2026-09-06

Pusher / Shover / Space Hog and their required push infrastructure are implemented from live-GDD revision `ANLCKQmcBBEnzsnYbFvdzzXmHJB2gAgkhunV5P2pczqttiFNGF1lfRGWUVzYRmO9v_2DdQF2Dpg8w6Ms2v9KI5U5b6HhpuEYa3gnaXvXDA`:

- STR 13/15/17 plus the exact prerequisite chain; higher ranks replace rather than stack;
- deterministic 25%/50%/75% ordinary-weapon proc chances, fixed +168 units, and a 0.50-second per-attacker/per-target cooldown started only by successful procs;
- exactly one proc per resolved nonlethal target-hit, including one per damaged Shotgun target after pellet aggregation rather than per pellet or damage die;
- one shared non-exploding d20 STR push save for every actor-to-actor push, with exact DC/save proficiency terms, defender-size save modifier, size-adjusted travel, PushImmune, and post-save defender multipliers;
- Pusher 1d8 and Shover 1d10 wall-slam dice are `classExplosionImmune`; Space Hog upgrades to an unsealed universal SUPER d12;
- unbridged Magic pushes retain the baseline wall-slam die even when the caster owns this physical-weapon family;
- Character Sheet truth, dedicated RNG state, telemetry, finite family/shared-save validators, and a combined testkit/status command cover the bridge.

Static proof: all Lua parses, `tools/test_gate_e_pusher.lua` passes, prior Batch 11/12 harnesses remain green, and the 100-seed maze regression remains `failures=0` with hash `1736216640`.

Final runtime proof: rank 3 reported `chance=0.75`, `distance=168`, `cooldown=0.50s`, and unsealed wall `1d12`; 19 rolls produced 10 procs and two cooldown blocks; those 10 procs produced exactly 10 shared STR saves; eight wall crushes dealt 62 total damage; status reported `result=PASS`; core validation passed; and the evidence ended at `TEST_END batch13-pusher`.

### Batch 14 — Crowbar Family — HERO REVISION IMPLEMENTED; RUNTIME ACCEPTANCE PENDING

Bash / Walloper / Wrecking Bar are implemented from live-GDD revision `ANLCKQmcBBEnzsnYbFvdzzXmHJB2gAgkhunV5P2pczqttiFNGF1lfRGWUVzYRmO9v_2DdQF2Dpg8w6Ms2v9KI5U5b6HhpuEYa3gnaXvXDA`; Hero of Legend includes the subsequent user-authorized playtest revisions:

- `STR_CROWBAR_D6`: STR 13; replaces baseline Crowbar `1d3` with universal exploding `1d6` and gives each successful nonlethal melee hit one authored 168-unit physical push;
- `STR_CROWBAR_D12`: STR 15 plus Bash; replaces `1d6` with universal SUPER `1d12` and retains the authored push;
- `STR_CROWBAR_CRUSH`: STR 17 plus Walloper; adds one die to each Crowbar-caused wall crush, producing `2d3`, sealed `2d8`/`2d10`, or universal SUPER `2d12` before any Fighter-capstone bonus die;
- `WIS_HERO_OF_LEGEND`: WIS 15; at `CurrentHP >= min(100, MaxHP)`, a committed primary swing launches one glowing Crowbar model from the attacker's arm only when no other Hero projectile is active globally;
- the genuine server-swept projectile travels at Bio Blaster speed (620 world units/second) for `max(1, WIS bonus)` 384-unit cells, stops at the first blocking geometry, prop, or eligible body beyond melee reach, and applies one current Crowbar-die non-elemental Magic damage event;
- the projectile costs no ammunition or Magic and is neither melee nor firearm contact; it cannot push, wall-crush, pierce bodies, or recursively emit;
- Bash 168 plus a successful Pusher-family 168 proc becomes one 336-unit request before exactly one shared STR save;
- the custom and legacy Crowbar damage routes share the same d3/d6/d12 profile authority, while the production custom Crowbar owns pulse commit timing;
- Character Sheet/runtime truth, entity-owned crowbar presentation, an original synthesized launch cue, finite family/shared-wall validators, isolated three-mode testkit, and dedicated telemetry cover the bridge.

The first runtime pass accepted Bash, Walloper, Wrecking Bar, and push/save composition, but rejected Hero presentation and apparent collision damage: the old client proxy appeared as a tiny yellow indicator even though telemetry recorded hits. The revised real-entity projectile requires a fresh runtime acceptance pass.
