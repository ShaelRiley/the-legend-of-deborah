# RPG Overhaul Implementation Gates

Design authority: the live **The Legend of Deborah — Garry's Mod Game Design Document**. GitHub `main` remains implementation authority.

## Gate summary

- **Gate A — scaffold:** schema, constants, deterministic seeds, state constructors, core validation.
- **Gate B — Level-1 identity/class/feat:** deterministic Hero identity, class commitment, stored three-card feat draft, Character Sheet, deployment gate.
- **Gate C — Levels 1–20:** exact XP table, growth, stored progression hit dice, MaxHP recomputation, seven ordinary feat slots, Level-20 capstones.
- **Gate D — ability/class gameplay:** STR/DEX/CON/INT/WIS/CHA bridges, Rogue damage-die mastery, Wizard diversion, Fighter/Rogue/Wizard capstones, XP attribution, core gameplay validation.
- **Gate E — ordinary feat effects:** active family-by-family implementation at canonical semantic seams.

## Gate E accepted batches

### Batch 1 — CON Health Regeneration — PASSED 2026-09-02

Second Wind / Rapid Recovery / Unbroken were runtime accepted at exact 11/22/33% replacement ceilings with the tested 1.20 HP/s CON-scaled rate and no visible Lua error.

### Batch 2 — WIS Navigation — PASSED 2026-09-02

Surveyor / Cartographer / Frugal Cartography were runtime accepted. Cartographer produced the authored replacing +8 bonus (16 BreadcrumbCells for the tested WIS profile); Frugal Cartography produced the canonical 5.44 Magic/s map drain in the accepted test and preserved no-regeneration-while-open.

### Batch 3 — INT Ammo-Regeneration Floors — PASSED 2026-09-03

Field Supply / Deep Reserves / War Stock are accepted. Runtime evidence confirmed floor fractions 0.33/0.55/0.66, expected Magnum/Pistol ceilings, unchanged 30.00s Magnum and 3.33s Pistol round intervals, core RPG validator PASS, and no reported Lua error.

## Gate E Batch 4 — DEX Exploding-Dice Ladder

Implemented from the current live GDD:

- `DEX_EXPLODE_D10` / Perfect Ten: DEX 12; ordinary actor-owned d10 damage dice; fresh natural 10; continuation `max(2, 10-BoomShift)`.
- `DEX_EXPLODE_D8` / Eight Is Enough: DEX 14 + Perfect Ten; adds d8 while retaining d10; fresh natural 8; continuation `max(2, 8-BoomShift)`.
- `DEX_EXPLODE_D4` / Fourtunate: DEX 16 + Eight Is Enough; adds d4 while retaining d10+d8; fresh natural 4; continuation `max(2, 4-BoomShift)`.
- all three are unavailable to Rogues because Rogue mastery already supplies the broader effect;
- capability follows actual legal actor damage capability, including later-acquired/persisted player weapons, rather than only the initial advanced starter;
- one derived `featExplodingDamageDice` table represents the active feat-enabled die sizes;
- `AbilityRules:CopyDamageProfile` is the permission seam and existing `CombatRolls:_RollExploding` remains the only bounded chain executor;
- universal d6/SUPER-d12, authored explosions, Rogue mastery, and BoomShift remain at existing authorities;
- `classExplosionImmune=true` is checked before feat permission and remains absolute;
- progression/health/count/utility dice never enter the damage-profile feat seam;
- the Character Sheet owned-feat ledger reports current enabled die sizes plus fresh/continuation thresholds;
- core validation now includes the Batch 4 finite validator.

### Batch 4 runtime gate

1. Fresh-start `gm_flatgrass` with `lod_developer_mode 1`; use a Fighter or Wizard.
2. Run `lod_rpg_gate_e_exploding_dice_validate`; require `DEX Exploding-Dice feat family PASS`.
3. Run `lod_rpg_test_exploding_dice 0` then status; require `featDice=none`.
4. Run ranks 1, 2, 3 in order and status after each. Require d10; then d10+d8; then d10+d8+d4. Fresh thresholds must remain 10/8/4; continuation thresholds must equal each side minus current BoomShift with floor 2.
5. Exercise corresponding owned weapons and confirm fresh natural maximums can chain while fresh non-maximum rolls do not.
6. Open P and confirm current feat-enabled exploding dice/thresholds appear in the owned-feat ledger.
7. Run `lod_rpg_validate`; require core PASS and no Lua errors.

Gate E remains open after Batch 4. The completeness ledger is `docs/RPG_GATE_E_FEAT_MATRIX.md` and currently accounts for 73 total ordinary feats: 12 implemented, 15 catalog/ownership-only, 46 not yet catalogued, 61 gameplay effects remaining.
