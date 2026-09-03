# Development Status — 2026-09-03

## Current execution phase

**CORE MULTIPLAYER SMOKE FOUNDATION: ACCEPTED.**

**RPG OVERHAUL / GATE E: ACTIVE DEVELOPMENT.**

The live GDD is design authority; GitHub `main` is implementation authority.

## Accepted runtime foundation

The September 1 VPS multiplayer smoke remains accepted and is not a blocker to coherent RPG development. Gate E Batches 1–4 have `gm_flatgrass` runtime acceptance.

- Batch 1: CON Health Regeneration — accepted exact 11/22/33% ceilings and tested 1.20 HP/s rate.
- Batch 2: WIS Navigation — accepted Cartographer +8 replacement and Frugal Cartography 5.44 Magic/s test profile.
- Batch 3: INT Ammo-Regeneration Floors — accepted 0.33/0.55/0.66 floor fractions with unchanged family regeneration cadence.
- Batch 4: DEX Exploding-Dice Ladder — accepted family validator + core validator, additive d10/d8/d4 behavior, live Pistol d4 explosion behavior, and correct isolation of the baseline Crowbar d3 from these feat unlocks.

Batch 4 also produced useful emergent balance evidence: a full-Magic Wizard combining Arcane Surge with a Fourtunate-enabled exploding Pistol was powerful and fun in the accepted run. This is retained as intentional cross-system composition for later whole-RPG balance testing rather than treated as an immediate nerf target.

## Gate E Batch 5 — DEX Reload Cadence

Mechanically implemented and **qualitatively successful in repeated Steam Deck play**:

- Quick Reload: DEX 12, total ordinary reload-time multiplier `0.80`;
- Lightning Reload: DEX 16 + Quick Reload, replaces total multiplier with `0.60`;
- Blink Reload: DEX 18 + Lightning Reload, replaces total multiplier with `0.40`;
- the shared derived state contains one replacement `reloadTimeMultiplier` rather than stacking ranks;
- the bridge scales only deadlines authored during a confirmed Source `m_bInReload` state;
- pre-existing deadlines are absolute floors, protecting SMG overheat, AR2 timing, and unrelated weapon locks;
- Shotgun shell-by-shell reload remains engine-authored and is accelerated stage-by-stage rather than replaced;
- attack interruption terminates reload observation before firing cooldowns can be touched;
- Character Sheet truth reports the active total reload-time multiplier.

The latest playtest found Blink Reload particularly compelling with the AR2: reload downtime becomes barely perceptible, allowing almost-continuous fire, while the AR2's laser telegraph and pre-burst delay continue to impose its authored cadence. Treat this as **desirable emergent build space**, not an immediate nerf target.

The same test exposed observability defects rather than gameplay defects. The supplied RPG summary showed a heavily exercised AR2 path (51 d10 player-roll events) but zero reload-scale telemetry; the physical console export was a placeholder because GMod Lua could not read the engine-level `console.log` on Steam Deck. The logging repair therefore moves console mirroring outside the Lua sandbox and emits reload telemetry synchronously at the actual reload-scaling seam.

**Batch 5 logged closure now requires only one short rank-3 AR2 confirmation, not another complete rank-0→3 gameplay pass.**

## Gate E accounting

The authoritative completeness ledger is `docs/RPG_GATE_E_FEAT_MATRIX.md`:

- 73 ordinary feats total;
- 15 mechanically implemented;
- 14 catalog/ownership-only;
- 44 not yet catalogued;
- 58 gameplay effects remain.

## Current rule

Complete the short Batch 5 observability confirmation on `gm_flatgrass`, formally close Batch 5 if telemetry/validators agree with the already-successful gameplay evidence, then continue family-by-family through the remaining Gate E matrix. Do not resurrect the pre-RPG multiplayer smoke gate; perform a focused post-RPG multiplayer regression after the RPG layer is coherent.
