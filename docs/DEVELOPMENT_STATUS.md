# Alpha 2 reconciliation — 2026-09-08

Starting main: `544702805fcf97c13f1055b1cee16ca4d3b5b3d4`.

The current canonical-vs-runtime inventory is in `RPG_GATE_E_FEAT_MATRIX.md`.
Winning Personality is runtime accepted on `06b579a3e42c744ad7e942fab9aed93e028f10c2`: screenshots show intrinsic CHA 9 → 10 → 10, permanentFeatCHA 0 → 1 → 1, Charisma families PASS, core RPG PASS and test-finish confirmation. The original long command batch was truncated by the console; keep future batches short. Uploaded console files were byte-identical and stale, so these screenshots are the acceptance evidence.

Current batch: World Walker / Globetrotter / Mind Strider (INT 13/15/17, chained) now multiply ordinary locomotion by 1.25/1.50/1.75 only while the existing server map authority permits an active map. Highest rank replaces lower ranks. Uses the existing DEX/SetupMove seam; no jump-velocity or forced-velocity edits. Existing map drain remains authoritative. Future Haste must compose at this same ordinary-locomotion seam; Haste is not implemented by this batch.

Static gate: `luatex --luaonly tools/test_map_movement.lua` passes production rank/replacement, DEX/SetupMove composition, actor isolation, close/death/access/mapless/failure/freeze/heartbeat/exhaustion and prerequisite checks. Map movement runtime acceptance is recorded below.

Map movement runtime gate accepted on `4134c3b15d90a375342c104c76749cc98e7f7275`: screenshot shows rank=3, samples=1018, peak=1.75, last=1.00, open=false, closedAfterOpen=true; map-family and core validators PASS; finish marker confirmed. Lower-rank values remain statically verified.

The same screenshot exposes an independent Deadcrab crash in sv_deadcrab.lua:362: missing `_RunDeadcrabTick`. The wrapper now directly calls its local dispatcher, while Initialize publishes that dispatcher on the instance for Motion V2. The attack state machine and tuning are unchanged. `tools/test_deadcrab_dispatch.lua` reproduces the missing-helper shape and passes fallback, non-Deadcrab, named-dispatch and frame-guard checks. Map movement regression also PASS.

Deadcrab repair runtime accepted on `641085fa8b9d85a0c2e10435661eeb07bbcdc415`: screenshot reports leaps=2, latches=2, detonations=2, lastVictims=1, lastDamage=32, result=PASS. No additional Deadcrab test is needed.

Current feat batch: W,A,S,Deborah, INT 13, adds 1.25x voluntary backward locomotion including backward diagonals. Uses the existing SetupMove pipeline after mode/DEX/map speed resolution, scaling desired horizontal input and speed caps together to preserve analog fractions. No velocity/position/jump-power writes. Excludes forward-only, pure strafe, idle, airborne/jump, ladder/noclip, swimming and dead actors. Future Haste must compose in the same pipeline; not implemented here.

Static validation: production `tools/test_backpedal.lua` PASS for ownership/removal, INT gate, backward/diagonal, analog, walk/run caps, DEX/map composition and exclusions. Existing map-movement and Deadcrab regression harnesses PASS.

W,A,S,Deborah runtime accepted on `d0111e59aeacf3491a8b29ce25016c20fbc80c06`: screenshot shows backward=973, diagonal=639, forward=620, strafe=437, peak=1.25, last=1.00, definition and core validator PASS, completion confirmed.

Current family: Strafer / Sideler / Lateral Mover, DEX 13/15/17 with predecessor requirements and replacing lateral multipliers 1.11/1.22/1.33. Resolves the ordinary capped input before modifying only its sideways component and adjusting the directional cap; forward/backward speed remains unchanged on diagonals. Composes after DEX/map/backpedal at the existing voluntary movement seam. Grounded walk movement only; no velocity writes, jump impulse, air acceleration, ladder, swimming or forced-motion changes.

Static gate: `tools/test_strafe.lua` PASS for all ranks, replacement, signed diagonals, forward-axis preservation after simulated engine speed clamp, analog fractions, jump/air/ladder/swimming exclusions, DEX/map/backpedal/sprint-cap composition, client/server caps and prerequisite gates. Existing backpedal and map-movement tests also PASS. Runtime pending.

Strafer family rank-3 runtime gate accepted on `44a441652a7fd8c2753dfa7f1531042cdfe5ed52`: screenshot shows samples=1534, diagonal=750, forwardOnly=46, peak=1.33, last=1.00, definition/core PASS and completed strafe test. Lower ranks and exact component preservation remain statically verified; no user report of diagonal feel was supplied.

Current family: Quantum Mathematics / Quantum Mechanics / Quantum Mastery, INT 13/15/17 chained, replacing offensive activation cost multipliers 0.89/0.78/0.67. Cost is max(1,ceil(ordinary offensive activation cost * multiplier)); baseline without ownership is unchanged. Existing Force Shout uses the shared cost helper for both affordability and deduction (30 baseline; 27/24/21 by rank). Utility drain, regen, diversion, cooldown and damage paths are unchanged. Candidate capability requires an available offensive activation. Canonical Form/Content casting remains Phase 2 work and must call this helper after constructing ordinary cost.

Static gate: production Force Shout test `tools/test_quantum.lua` PASS for all ranks, minimum/rounding, exact affordability, charged amount, rejected casts/cooldown, and prerequisite/capability gates. Runtime pending.

Next finite gate: pull/restart gm_flatgrass and deploy. Run `lod_developer_mode 1; lod_rpg_quantum_testkit 3`. Close console and tap RMB once to cast Force Shout. Run `lod_rpg_quantum_status; lod_rpg_validate; lod_rpg_test_finish quantum`. Expect rank=3, multiplier=0.67, casts>=1, base=30, cost=21, definition/core PASS. Send console screenshot. Alpha 2 remains incomplete and undeployed.

The history below is retained as prior evidence, not current design authority.

# Development Status — 2026-09-06

## Current execution phase

**CORE MULTIPLAYER SMOKE FOUNDATION: ACCEPTED.**

**RPG OVERHAUL / GATE E: ACTIVE DEVELOPMENT.**

The live GDD is design authority; GitHub `main` is implementation authority. The 2026-09-08 live enumeration contains 143 ordinary/cross feats, 9 class capstones, and 6 fallbacks. The active ordinary registry has 62 canonical matches and 81 omissions after Hero of Legend alias normalization. See `RPG_GATE_E_FEAT_MATRIX.md`; registry membership is not runtime acceptance.

## Accepted runtime foundation

The September 1 VPS multiplayer smoke remains accepted and is not a blocker to coherent RPG development. Gate E Batches 1–8 and 10–13 now have `gm_flatgrass` runtime acceptance. Batch 9 remains implemented and runtime-pending; Batch 14 is implemented and awaiting its finite runtime gate.

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

- Quick Reload: current prerequisite DEX 13, total ordinary reload-time multiplier `0.80`;
- Lightning Reload: current prerequisite DEX 15 + Quick Reload, replaces total multiplier with `0.60`;
- Blink Reload: current prerequisite DEX 17 + Lightning Reload, replaces total multiplier with `0.40`;
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

## Gate E Batch 10 — Charisma Utility and Presence — ACCEPTED 2026-09-06

Unnerving Presence / Dazing Presence / Overwhelming Presence now form a CHA 13/15/17 replacement ladder at the canonical hit-stun multiplier seam. Academic Achievement adds positive CHA_MOD only to passive Magic regeneration. Winning Personality substitutes CHA only for the printed ability prerequisite of `INT_` feats and preserves actual INT plus all other restrictions. All five feat rows have derived-state and Character Sheet truth, a finite validator, a combined testkit, and runtime status telemetry.

The accepted `gm_flatgrass` run passed the Charisma family validator and the full RPG validator, then reached `TEST_END batch10-charisma`. Its baseline profile reported rank 0, passive regeneration ×1.10, Academic off, and Winning Personality off. The feat profile reported rank 3 at ×1.30, Academic on with effective regeneration modifier 2 and ×1.20 regeneration, and Winning Personality on with INT-feat qualification 13. A live surviving-hostile hit recorded ordinary hit stun ×1.030 and final ×1.339, exactly `1.030 × 1.30`.

The September 6 live-GDD refresh also standardized the already-implemented Health Regeneration, WIS Navigation, Ammo-Regeneration Floor, DEX Exploding-Dice, and DEX Reload prerequisites to their current 13/15/17 values. No accepted effect magnitude or runtime seam changed.

## Gate E Batch 11 — Control and Magic Push/Recovery — RUNTIME ACCEPTED 2026-09-06

Hard to Move now applies ×0.75 to incoming ordinary hit stun and non-scripted push displacement, with an explicit `ignoreResistance` escape hatch for authored boss mechanics. Force Multiplier applies ×1.25 only to explicitly tagged `magic_push` displacement; Force Shout is the first canonical beneficiary, while ordinary physical push remains separate. Mana Spring arms whenever Magic reaches zero and applies ×1.50 to the already INT-scaled passive regeneration rate for four unsuppressed seconds; its timer pauses while the minimap or another registered regeneration-suppressing effect is active.

All three feats use current live-GDD CON 13 / WIS 15 / INT 13 qualifications, derived-state and Character Sheet truth, a finite validator, a combined baseline/feat testkit, and runtime telemetry. Static Lua validation, the dedicated pure-Lua family harness, and the 100-seed maze regression pass.

The first September 6 runtime pass accepted the baseline and proved Hard to Move ×0.75 plus Force Multiplier ×1.25 at an exact final requested Force Shout displacement of 315 units. The corrected feat-side pass then reached zero Magic and recorded `starts=1`, `activeTicks=16`, and `pausedTicks=0`, while reproducing the exact composed push of 315. The family validator and full RPG validator passed and the evidence ended at `TEST_END batch11-mana-spring-fix`. Its final `WAITING` label was a telemetry-only false negative: a second hostile's ordinary hit-stun query overwrote the designated steadfast target's global reading. Status now records and reads the designated target's own hit-stun multiplier, and the over-limit 256-byte chat instruction has been shortened.

## Gate E Batch 12 — Magic Recovery — RUNTIME ACCEPTED 2026-09-06

Feedback Loop and Arc Recovery are implemented from the current live-GDD revision:

- Feedback Loop requires INT 15 and restores exactly 1 Magic for every continuation die actually generated by an offensive Magic attack, capped at 6 restored Magic across the committed cast;
- Arc Recovery requires INT 17 and restores 5 Magic after a Magic-tagged event defeats an AI hostile, with one 2.0-second per-actor cooldown and the universal 100-Magic ceiling;
- Force Shout counts continuations from its authoritative post-Rogue/explosion damage contract and shares one Feedback Loop budget across every target of that cast;
- Arc Recovery is evaluated after actual hostile damage, so only a confirmed surviving-to-dead transition qualifies;
- Character Sheet truth, finite family/status/testkit commands, pure transition validation, and core RPG validation cover both bridges;
- all Lua parses, the dedicated Batch 12 harness passes, and the 100-seed maze regression remains stable.

The final `gm_flatgrass` run produced two actual Force Shout continuation dice and restored exactly 2 Magic through Feedback Loop. Four Magic-tagged hostile defeats restored 15 total Magic through Arc Recovery while one clustered kill was rejected by the 2.0-second cooldown. Status reported `acceptance=PASS`; the family validator and core RPG validator passed; the evidence ended at `TEST_END batch12-magic-recovery`.

## Gate E Batch 13 — Pusher Family and Shared Push Save — RUNTIME ACCEPTED 2026-09-06

Pusher / Shover / Space Hog are implemented from the current live-GDD revision:

- the STR 13/15/17 replacement ladder sets 25%/50%/75% deterministic weapon-knockback proc chances and a fixed +168-unit displacement;
- successful procs alone start the shared 0.50-second per-attacker/per-target cooldown; cooldown-blocked hits consume no random roll;
- ordinary firearms and Crowbar-family hits resolve one proc after a nonlethal damaging target-hit, while Shotgun resolves one proc per damaged target after pellet aggregation;
- every actor-to-actor push now resolves one non-exploding d20 STR save, including the exact level-proficiency and defender-size modifier, size-adjusted distance, PushImmune bypass, and defender-side post-save multipliers;
- Pusher and Shover wall slams use sealed 1d8/1d10 dice; Space Hog uses an unsealed universal SUPER d12;
- Magic-origin wall slams remain outside the family unless a later explicit bridge grants eligibility;
- Character Sheet truth, finite family/shared-save validators, runtime status/testkit commands, and a dedicated pure-Lua harness are included.

The accepted `gm_flatgrass` run reported the exact rank-3 profile (`chance=0.75`, `distance=168`, `cooldown=0.50s`, unsealed wall `1d12`), 19 eligible rolls, 10 procs, two cooldown blocks, and exactly 10 push-save rolls for those 10 procs. All 10 saves legitimately failed, eight pushes produced wall crushes for 62 total damage, status reported `result=PASS`, the core RPG validator passed, and the evidence ended at `TEST_END batch13-pusher`.

## Gate E Batch 14 — Crowbar Family — HERO REVISION IMPLEMENTED; RUNTIME ACCEPTANCE PENDING

Bash / Walloper / Wrecking Bar follow the current live-GDD revision; Hero of Legend also incorporates the subsequent user-authorized playtest revisions:

- Bash replaces the baseline Crowbar `1d3` with universal exploding `1d6` and adds one 168-unit physical push to every successful nonlethal melee hit;
- Walloper replaces Bash damage with universal SUPER `1d12` while retaining its push;
- Wrecking Bar adds one die to Crowbar-caused wall crushes, preserving the active baseline/Pusher/Shover/Space-Hog die class and explosion seal;
- Hero of Legend is gated at WIS 15. At `CurrentHP >= min(100, MaxHP)`, a committed primary swing launches one luminous crowbar from the attacker's arm when no other Hero projectile is active globally;
- the projectile travels at Bio Blaster speed (620 world units/second), has a maximum range of `max(1, WIS bonus)` 384-unit cells, and stops at the first eligible body or blocking surface after ordinary melee reach;
- pulse damage uses the current Crowbar die as non-elemental Magic damage with WIS scaling, and remains isolated from melee, firearm, Crowbar-push, wall-crush, and recursive pulse triggers;
- Bash and a successful Pusher-family proc assemble as one 336-unit request before exactly one shared STR save;
- Character Sheet truth, dedicated pulse/push/wall telemetry, a three-mode testkit, family validator, real projectile presentation, original synthesized cue, and a pure-Lua harness cover the bridge.

The initial runtime pass accepted the three physical Crowbar feats and their Pusher composition. Hero was rejected because its proxy was tiny and its damage was not perceptible in play; this revision replaces that proxy/delayed-pretrace path and awaits retest.

## Gate E accounting

The authoritative completeness ledger is `docs/RPG_GATE_E_FEAT_MATRIX.md`:

- within the historical 73-row migration ledger, 43 mechanically implemented;
- 4 catalog/ownership-only;
- 26 not yet catalogued;
- 30 gameplay effects remain;
- two additional expanded-catalog rows are mechanically implemented, for 45 total;
- the remaining expanded rows still require matrix reconciliation.

## Current rule

Run the finite Batch 14 Crowbar gate next. Batch 9 remains a separate pending runtime gate and must not be inferred from another batch's logs. Continue expanded live-catalog reconciliation alongside implementation. Do not resurrect the pre-RPG multiplayer smoke gate; perform a focused post-RPG multiplayer regression after the RPG layer is coherent.
