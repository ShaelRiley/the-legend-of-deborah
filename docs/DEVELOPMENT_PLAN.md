# Development Plan — 2026-09-03 RPG Priority

The live GDD is design authority. GitHub `main` is implementation authority.

## Development order

1. Core multiplayer smoke foundation — **accepted** from the September 1 VPS playtest.
2. RPG Gates A–D / class integration — implemented and under runtime tuning.
3. Gate E Batch 1 CON Health Regeneration — **runtime accepted**.
4. Gate E Batch 2 WIS Navigation — **runtime accepted**.
5. Gate E Batch 3 INT Ammo-Regeneration Floors — **runtime accepted 2026-09-03**.
6. Gate E Batch 4 DEX exploding-dice ladder — **implemented; next runtime gate**.
7. Continue the remaining Gate E families until all 73 ordinary feats have canonical gameplay bridges and finite validators.
8. Implement all 192 authored Origin/Background/Motive perk bridges.
9. Run the full six-stat / Level 1–20 / combat-order / player-enemy RPG consistency audit.
10. Single-client balance across randomized Heroes, classes, and ability extremes.
11. Focused post-RPG VPS multiplayer regression.
12. Consolidate authority debt exposed by evidence, then implement Neil + The Brute, Gordon the Warden, final arena, map degradation, soak, and polish.

## Immediate runtime gate — Batch 4

On `gm_flatgrass` with `lod_developer_mode 1`:

1. Run `lod_rpg_gate_e_exploding_dice_validate` and require the DEX family PASS line.
2. Use a non-Rogue Hero. Run `lod_rpg_test_exploding_dice 0`; status must report `featDice=none`.
3. Run rank 1; status must report d10 only, with fresh threshold 10 and continuation threshold `max(2, 10-BoomShift)`.
4. Run rank 2; status must retain d10 and add d8, with fresh 8 and continuation `max(2, 8-BoomShift)`.
5. Run rank 3; status must retain d10+d8 and add d4, with fresh 4 and continuation `max(2, 4-BoomShift)`.
6. Fire the corresponding owned weapons and confirm natural-max fresh explosions visibly chain through the existing combat-roll feed. Confirm non-max fresh rolls do not explode.
7. Reopen P and confirm the owned-feat ledger reports current feat-enabled dice and thresholds.
8. Run `lod_rpg_validate`; require the core PASS line and no Lua errors.

## Gate E accounting after Batch 4 implementation

- 73 ordinary feats total;
- 12 mechanically implemented;
- 15 catalog/ownership-only;
- 46 not yet catalogued;
- 61 gameplay effects remain.

## Preserved constraints

`gm_flatgrass` remains the required test map; the canonical graph remains topology authority; Motion V2 remains ordinary hostile motion authority; server CombatRolls remains dice authority; Magic/resources remain personal while world progression is shared; existing d6/SUPER-d12/Rogue/classExplosionImmune rules are not duplicated or bypassed.
