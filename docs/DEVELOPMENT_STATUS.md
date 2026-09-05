# Development Status — 2026-09-05

## Current execution phase

**CORE MULTIPLAYER SMOKE FOUNDATION: ACCEPTED.**

**RPG OVERHAUL / GATE E: ACTIVE DEVELOPMENT.**

The live GDD is design authority; GitHub `main` is implementation authority.

## Accepted runtime foundation

The September 1 VPS multiplayer smoke remains accepted and is not a blocker to coherent RPG development. Gate E Batches 1–8 now have `gm_flatgrass` runtime acceptance. Batch 9 is implemented and awaiting its finite runtime gate.

- Batch 1: CON Health Regeneration — accepted exact 11/22/33% ceilings and tested 1.20 HP/s rate.
- Batch 2: WIS Navigation — accepted Cartographer +8 replacement and Frugal Cartography 5.44 Magic/s test profile.
- Batch 3: INT Ammo-Regeneration Floors — accepted 0.33/0.55/0.66 floor fractions with unchanged family regeneration cadence.
- Batch 4: DEX Exploding-Dice Ladder — accepted family validator + core validator, additive d10/d8/d4 behavior, live Pistol d4 explosion behavior, and correct isolation of the baseline Crowbar d3 from these feat unlocks.
- Batch 5: DEX Reload Cadence — accepted 0.80/0.60/0.40 replacement ladder and live rank-3 AR2 deadline compression.
- Batch 6: DEX Rate of Fire — accepted 1.10/1.20/1.30 replacement ladder and final AR2 burst transaction authority.
- Batch 7: DEX Authored Burst Size — accepted +1/+2/+3 replacement ladder and six-projectile AR2 completion from exactly one ammo.
- Batch 8: DEX SMG Heat — accepted baseline 6-shot overheat and seeded rank-3 18-shot result with 6 suppressed + 12 heat, threshold 12, and fixed 2.0-second lock.

Batch 4 also produced useful emergent balance evidence: a full-Magic Wizard combining Arcane Surge with a Fourtunate-enabled exploding Pistol was powerful and fun in the accepted run. This is retained as intentional cross-system composition for later whole-RPG balance testing rather than treated as an immediate nerf target.

## Gate E Batch 5 — DEX Reload Cadence — ACCEPTED 2026-09-03

Quick Reload / Lightning Reload / Blink Reload are runtime accepted:

- Quick Reload: DEX 12, total ordinary reload-time multiplier `0.80`;
- Lightning Reload: DEX 16 + Quick Reload, replaces total multiplier with `0.60`;
- Blink Reload: DEX 18 + Lightning Reload, replaces total multiplier with `0.40`;
- the shared derived state contains one replacement `reloadTimeMultiplier` rather than stacking ranks;
- only genuine reload-authored deadlines are compressed;
- pre-existing deadlines remain absolute floors, protecting SMG overheat, AR2 targeting/burst timing, and unrelated weapon locks;
- Shotgun shell-by-shell reload remains engine-authored and is accelerated stage-by-stage rather than replaced;
- attack interruption terminates reload observation before firing cooldowns can be touched;
- Character Sheet truth reports the active total reload-time multiplier.

The final Steam Deck acceptance run on `gm_flatgrass` produced:

- `reloadRank=3 multiplier=0.40`;
- `active=weapon_ar2`;
- `scaledExtensions=3`;
- final AR2 player reload deadline `1.55s -> 0.62s`;
- summary `reload_scale_events=3`;
- `last_reload_weapon=weapon_ar2`;
- `last_reload_multiplier=0.4`;
- authored `1.5516667s`, scaled `0.6206667s`, saved `0.9310000s`;
- `TEST_END batch5-clock-fix`;
- final `lod_rpg_validate` PASS.

The investigation also corrected the underlying timing boundary: Garry's Mod public weapon deadline APIs are authoritative absolute `CurTime()` values, while Source `FIELD_TIME` values exposed through raw save/internal fields are CurTime-relative and must be translated only at that raw boundary. This systemic clock correction replaced the earlier invalid comparison that had caused legitimate reload extensions to be rejected.

Blink Reload + AR2 remains positive emergent build space. Reload downtime can become nearly imperceptible, while the AR2 laser telegraph, burst spacing, and pre-burst delay continue to impose the weapon's authored cadence. Preserve this unless broader whole-RPG balance evidence later demonstrates a problem.

## Gate E Batch 9 — Four Singleton Families — IMPLEMENTED

Spring Heel, Deadeye, Long Reach, and Russian Asset now have exact live-GDD definitions, canonical runtime bridges, combined validation, and a finite baseline/feat testkit. Snap Targeting remains blocked on a real authority contradiction: its ×0.80 timing rule with a 0.50-second floor cannot be applied to the current 0.45-second base tell without making the feat slower.

## Gate E accounting

The authoritative completeness ledger is `docs/RPG_GATE_E_FEAT_MATRIX.md`:

- within the historical 73-row migration ledger, 28 mechanically implemented;
- 10 catalog/ownership-only;
- 35 not yet catalogued;
- 45 gameplay effects remain;
- the expanded live GDD requires a full row reconciliation before the ledger can again claim an exhaustive current total.

## Current rule

Run Batch 9's finite combined `gm_flatgrass` acceptance pass. If it passes, close these four singleton families and reconcile the expanded live feat catalog before selecting the next coherent implementation batch. Do not resurrect the pre-RPG multiplayer smoke gate; perform a focused post-RPG multiplayer regression after the RPG layer is coherent.
