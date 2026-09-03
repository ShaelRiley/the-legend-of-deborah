# Development Status — 2026-09-03

## Current execution phase

**CORE MULTIPLAYER SMOKE FOUNDATION: ACCEPTED.**

**RPG OVERHAUL / GATE E: ACTIVE DEVELOPMENT.**

The live GDD is design authority; GitHub `main` is implementation authority.

## Accepted runtime foundation

The September 1 VPS multiplayer smoke remains accepted and is not a blocker to coherent RPG development. Gate E Batch 1 (CON Health Regeneration), Batch 2 (WIS Navigation), and Batch 3 (INT Ammo-Regeneration Floors) have now all received `gm_flatgrass` runtime acceptance.

Batch 3 acceptance evidence on 2026-09-03:

- rank 0: floor fraction `0.33`; Magnum `6/18`, Pistol `18/54`;
- rank 2: floor fraction `0.55`; Magnum `10/18`, Pistol `30/54`;
- rank 3: floor fraction `0.66`; Magnum `12/18`, Pistol `36/54`;
- Magnum interval remained `30.00s` and Pistol interval `3.33s` across ranks;
- core RPG validator passed (`schemas=11`, `classes=3`, `abilities=6`, `featSlots=7`, gameplay enabled);
- no Lua error was reported in the accepted runtime evidence.

## Gate E Batch 4 — DEX Exploding-Dice Ladder

Implemented in code and awaiting the finite Steam Deck runtime gate:

- `DEX_EXPLODE_D10` / Perfect Ten;
- `DEX_EXPLODE_D8` / Eight Is Enough;
- `DEX_EXPLODE_D4` / Fourtunate;
- additive unlocks retain earlier die sizes instead of replacing them;
- fresh feat-enabled d10/d8/d4 dice explode only on their natural maximum;
- continuation thresholds remain `max(2, sides - BoomShift)` at the existing Gate D authority;
- all three feats are excluded from Rogue offers as redundant with Rogue mastery;
- `classExplosionImmune=true` remains absolute;
- the universal 32-die chain cap and non-damage-die isolation remain intact;
- later-acquired legal weapon capability is recognized from live/persisted ownership rather than only the advanced starter choice;
- Character Sheet owned-feat truth includes the currently enabled die sizes and fresh/continuation thresholds;
- finite commands: `lod_rpg_gate_e_exploding_dice_validate`, `lod_rpg_gate_e_exploding_dice_status`, `lod_rpg_test_exploding_dice <0-3>`.

## Gate E accounting

The authoritative completeness ledger is `docs/RPG_GATE_E_FEAT_MATRIX.md`:

- 73 ordinary feats total;
- 12 mechanically implemented;
- 15 catalog/ownership-only;
- 46 not yet catalogued;
- 61 gameplay effects remain.

## Current rule

Complete Batch 4 runtime acceptance on `gm_flatgrass`, then continue family-by-family through the remaining Gate E matrix. Do not resurrect the pre-RPG multiplayer smoke gate; perform a focused post-RPG multiplayer regression after the RPG layer is coherent.
