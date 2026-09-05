# Development Plan — 2026-09-05 RPG Priority

The live GDD is design authority. GitHub `main` is implementation authority.

## Development order

1. Core multiplayer smoke foundation — **accepted** from the September 1 VPS playtest.
2. RPG Gates A–D / class integration — implemented and under runtime tuning.
3. Gate E Batch 1 CON Health Regeneration — **runtime accepted**.
4. Gate E Batch 2 WIS Navigation — **runtime accepted**.
5. Gate E Batch 3 INT Ammo-Regeneration Floors — **runtime accepted 2026-09-03**.
6. Gate E Batch 4 DEX exploding-dice ladder — **runtime accepted 2026-09-03**.
7. Gate E Batch 5 DEX reload cadence — **runtime accepted 2026-09-03**.
8. Gate E Batch 6 DEX rate-of-fire cadence — **runtime accepted 2026-09-05**.
9. Continue the remaining Gate E families until all 73 ordinary feats have canonical gameplay bridges and finite validators.
10. Implement all 192 authored Origin/Background/Motive perk bridges.
11. Run the full six-stat / Level 1–20 / combat-order / player-enemy RPG consistency audit.
12. Single-client balance across randomized Heroes, classes, ability extremes, and emergent cross-system builds.
13. Focused post-RPG VPS multiplayer regression.
14. Consolidate authority debt exposed by evidence, then implement Neil + The Brute, Gordon the Warden, final arena, map degradation, soak, and polish.

## Runtime evidence protocol

All runtime gates use `docs/TEST_LOGGING.md`.

- Run `./tools/install_dev.sh` after pulling; this maintains exactly one external Steam Deck mirror of the engine `console.log` into the canonical data directory.
- Start Garry's Mod fresh when beginning a distinct gate so `-condebug -conclearlog` gives a clean engine console.
- End the gate with `lod_rpg_test_finish <short-test-label>`.
- Canonical upload directory: `/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/`.
- Default physical evidence package: `console_latest.txt` + `rpg_summary_latest.txt`.
- Add `rpg_session_latest.txt` for timing/event-order or unexplained combat/RPG behavior.
- `rpg_archive_latest.txt` is bounded rolling cross-session history and is uploaded only when specifically requested.
- Screenshots remain appropriate for visual/rendering/layout defects; logs are preferred for console text and runtime mechanics.

## Batch 6 acceptance note

DEX Rate-of-Fire Cadence is closed. The final `gm_flatgrass` acceptance pass used Lead Storm at rank 3 and produced exactly five completed AR2 bursts / fifteen rounds, with `rate_of_fire_sessions=5`, `rate_of_fire_confirmed_attacks=5`, and `rate_of_fire_scale_events=5`. The last accepted event was `weapon_ar2/primary 0.880s->0.677s via ar2_burst_complete` at multiplier `1.30`; the summary recorded authored `0.88s`, scaled `0.6769230769s`, saved `0.2030769231s`, zero deadline misses, `TEST_END batch6-ar2-round-authority`, and final core RPG validation PASS.

The acceptance investigation established the canonical AR2 cadence seam. AR2 activation may originate through server `StartCommand` as well as the client activation receiver, so the bridge now wraps the final authoritative `BeginAR2Burst` method after synchronous gamemode loading and confirms each successful round through the final authoritative `FireAR2Round` method. The cadence benefit is committed only after a complete three-round burst. This preserves the targeting laser, pre-burst delay, and internal 0.09s shot spacing while shortening only the next primary-attack opportunity.

Hair Trigger / Rapid Fire / Lead Storm are ordinary-firearm-primary feats only. They do not accelerate melee, reloads, Magic cooldowns, enemy telegraphs, SMG overheat recovery, secondary attacks, or authored burst-internal spacing.

## Batch 5 acceptance note

DEX Reload Cadence is closed. The final `gm_flatgrass` acceptance pass at rank 3 produced `scaledExtensions=3` on `weapon_ar2`, with the final observed reload deadline compressed from about `1.55s` to `0.62s` at multiplier `0.40`. The RPG summary recorded `reload_scale_events=3`, `last_reload_weapon=weapon_ar2`, `last_reload_multiplier=0.4`, `TEST_END batch5-clock-fix`, and final core validation PASS.

The acceptance investigation corrected a systemic timing bug: public Garry's Mod weapon timing accessors are the absolute `CurTime()` authority. Raw Source `FIELD_TIME` values from internal/save fields are CurTime-relative and are translated only at that boundary. This keeps reload scaling numerically coherent while preserving every pre-existing lockout floor.

Repeated play found Blink Reload + AR2 creates almost-continuous fire because reload downtime becomes nearly imperceptible. Preserve this. The AR2's laser telegraph and delay before each burst remain meaningful authored costs, so the reload feat creates a distinct high-DEX build payoff rather than erasing the weapon's identity.

## Immediate Gate E work

Proceed to the next coherent family in `docs/RPG_GATE_E_FEAT_MATRIX.md`. Before implementation, re-read the exact live-GDD definitions for that family and use the narrowest existing canonical gameplay seam. Every family must receive:

1. exact authored definitions/prerequisites/rank semantics;
2. one canonical runtime authority rather than duplicated special cases;
3. Character Sheet/runtime truth where applicable;
4. a finite family validator/testkit;
5. static validation before push;
6. a short `gm_flatgrass` runtime acceptance pass with the standard evidence package.

The next obvious candidate is the DEX authored-burst-size family (`DEX_BURSTER_1` / `DEX_BURSTER_2` / `DEX_BURSTER_3`), but implementation must begin by re-reading its exact live-GDD semantics rather than inferring numbers from the ledger.

## Batch 4 acceptance note

The accepted Batch 4 live test corrected one earlier handoff statement: the **baseline Crowbar is d3, not d8**. It correctly remained outside Perfect Ten / Eight Is Enough / Fourtunate; Rogue mastery is the broader rule that may explode eligible d3 actor-owned damage dice. The same run showed a strong but desirable Wizard full-Magic Arcane Surge + exploding-Pistol composition, retained for later balance evaluation.

## Gate E accounting after Batch 6 acceptance

- 73 ordinary feats total;
- 18 mechanically implemented;
- 13 catalog/ownership-only;
- 42 not yet catalogued;
- 55 gameplay effects remain.

## Preserved constraints

`gm_flatgrass` remains the required test map; the canonical graph remains topology authority; Motion V2 remains ordinary hostile motion authority; server CombatRolls remains dice authority; Magic/resources remain personal while world progression is shared. Reload cadence changes only genuine reload timing. Rate-of-Fire cadence changes only ordinary firearm primary-attack opportunity timing and must not become a generic attack-cooldown, melee, reload, overheat, telegraph, burst-spacing, secondary-fire, or Magic-cooldown modifier.
