# Development Plan — 2026-09-03 RPG Priority

The live GDD is design authority. GitHub `main` is implementation authority.

## Development order

1. Core multiplayer smoke foundation — **accepted** from the September 1 VPS playtest.
2. RPG Gates A–D / class integration — implemented and under runtime tuning.
3. Gate E Batch 1 CON Health Regeneration — **runtime accepted**.
4. Gate E Batch 2 WIS Navigation — **runtime accepted**.
5. Gate E Batch 3 INT Ammo-Regeneration Floors — **runtime accepted 2026-09-03**.
6. Gate E Batch 4 DEX exploding-dice ladder — **runtime accepted 2026-09-03**.
7. Gate E Batch 5 DEX reload cadence — **implemented; next runtime gate**.
8. Continue the remaining Gate E families until all 73 ordinary feats have canonical gameplay bridges and finite validators.
9. Implement all 192 authored Origin/Background/Motive perk bridges.
10. Run the full six-stat / Level 1–20 / combat-order / player-enemy RPG consistency audit.
11. Single-client balance across randomized Heroes, classes, ability extremes, and emergent cross-system builds.
12. Focused post-RPG VPS multiplayer regression.
13. Consolidate authority debt exposed by evidence, then implement Neil + The Brute, Gordon the Warden, final arena, map degradation, soak, and polish.

## Immediate runtime gate — Batch 5

On `gm_flatgrass` with `lod_developer_mode 1`:

1. Run `lod_rpg_gate_e_reload_validate`; require the DEX Reload family PASS line.
2. Run `lod_rpg_test_reload 0`, `lod_rpg_gate_e_reload_testkit pistol`, then press R for a baseline reload.
3. Repeat with ranks 1, 2, and 3; status must report multipliers 0.80, 0.60, and 0.40. `scaledExtensions` must increase after real reloads and `last=` must show an authored deadline compressed by the active multiplier.
4. At rank 3, run `lod_rpg_gate_e_reload_testkit shotgun`; confirm shell-by-shell reload speeds up while normal fire-to-interrupt behavior remains intact.
5. Overheat the SMG, press R during the fixed 2.0-second recovery, and confirm Reload does not shorten it. Confirm AR2 targeting tell/internal burst timing remains unchanged.
6. Reopen P and confirm the owned reload feat reports the same total reload-time multiplier.
7. Run `lod_rpg_validate`; require the core PASS line and no Lua errors.

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
