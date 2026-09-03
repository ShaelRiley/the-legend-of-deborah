# Development Status — 2026-09-03

## Current execution phase

**CORE MULTIPLAYER SMOKE FOUNDATION: ACCEPTED.**

**RPG OVERHAUL / GATE E: ACTIVE DEVELOPMENT.**

The live GDD is design authority; GitHub `main` is implementation authority.

## Accepted runtime foundation

The September 1 VPS multiplayer smoke remains accepted and is not a blocker to coherent RPG development. Gate E Batches 1–4 now have `gm_flatgrass` runtime acceptance.

- Batch 1: CON Health Regeneration — accepted exact 11/22/33% ceilings and tested 1.20 HP/s rate.
- Batch 2: WIS Navigation — accepted Cartographer +8 replacement and Frugal Cartography 5.44 Magic/s test profile.
- Batch 3: INT Ammo-Regeneration Floors — accepted 0.33/0.55/0.66 floor fractions with unchanged family regeneration cadence.
- Batch 4: DEX Exploding-Dice Ladder — accepted family validator + core validator, additive d10/d8/d4 behavior, live Pistol d4 explosion behavior, and correct isolation of the baseline Crowbar d3 from these feat unlocks.

Batch 4 also produced useful emergent balance evidence: a full-Magic Wizard combining Arcane Surge with a Fourtunate-enabled exploding Pistol was powerful and fun in the accepted run. This is retained as intentional cross-system composition for later whole-RPG balance testing rather than treated as an immediate nerf target.

## Gate E Batch 5 — DEX Reload Cadence

Implemented in code and awaiting the finite Steam Deck runtime gate:

- Quick Reload: DEX 12, total ordinary reload-time multiplier `0.80`;
- Lightning Reload: DEX 16 + Quick Reload, replaces total multiplier with `0.60`;
- Blink Reload: DEX 18 + Lightning Reload, replaces total multiplier with `0.40`;
- the shared derived state contains one replacement `reloadTimeMultiplier` rather than stacking ranks;
- the bridge scales only deadlines authored during a confirmed Source `m_bInReload` state;
- pre-existing deadlines are absolute floors, protecting SMG overheat, AR2 timing, and unrelated weapon locks;
- Shotgun shell-by-shell reload remains engine-authored and is accelerated stage-by-stage rather than replaced;
- attack interruption terminates reload observation before firing cooldowns can be touched;
- Character Sheet truth reports the active total reload-time multiplier;
- finite commands: `lod_rpg_gate_e_reload_validate`, `lod_rpg_gate_e_reload_status`, `lod_rpg_test_reload <0-3>`, `lod_rpg_gate_e_reload_testkit [pistol|shotgun]`.

## Gate E accounting

The authoritative completeness ledger is `docs/RPG_GATE_E_FEAT_MATRIX.md`:

- 73 ordinary feats total;
- 15 mechanically implemented;
- 14 catalog/ownership-only;
- 44 not yet catalogued;
- 58 gameplay effects remain.

## Current rule

Runtime-accept Batch 5 on `gm_flatgrass`, then continue family-by-family through the remaining Gate E matrix. Do not resurrect the pre-RPG multiplayer smoke gate; perform a focused post-RPG multiplayer regression after the RPG layer is coherent.
