# SPOT-10 — Second-pass feat-value review

> Decision update: Shael subsequently approved all D–J, with H amended from
> proposed 2 Magic/second to **1 Magic/second**. They are now implemented; see
> [current implementation and evidence](SPOT_10_SECOND_PASS_IMPLEMENTED.md).
> The review below is retained as the original proposal record, not current law.

## Decision register

Shael explicitly rejected A: keep the Perfect Ten → Eight Is Enough → Fourtunate
prerequisite ladder and existing cumulative die unlocks unchanged.
Shael approved B (Mind Over Matter: fixed 3.0-second cooldown), C (Frugal Cartography:
25% map-equivalent drain discount, existing floor and Haste relationship intact),
and his own Mana Spring revision (22% faster otherwise permitted passive Magic
regeneration, no empty-pool trigger or temporary window). Those three changes are
implemented in this checkpoint; native balance acceptance remains open.

**D–J below are proposals, not approved changes.** They are not in production or
in the live GDD as game law. All values below describe total highest-rank effects,
not bonuses stacked with the lower ranks. Keep existing IDs, prerequisites, ability
thresholds, actor restrictions and stored drafts unless a proposal explicitly says
otherwise. No proposal restructures the rejected explosion ladder.

## Basis and limits

Implementation baseline: `0b8321344737d11547f323c993b279de7c400d4f`.
Screened the loaded ordinary feat catalog and inspected the relevant shared consumers.
Live GDD navigation reused 00/01 and relevant 03/04 from the same unchanged initial
revision; exact HUMAN Mana Spring, Mind Over Matter, Frugal Cartography, Arc Recovery
and Feedback Loop rules were compared. The remaining proposals are grounded in the
current production definitions and consumers, not a claimed exhaustive fresh HUMAN
catalog read. Before implementing any approved D–J proposal, reconcile its exact
live rows and shared subsystem law, then update the live GDD.

The user's Mana Spring report is actual preference/playtest feedback. There is no
retrieved comprehensive personal draft/selection history. Other candidates below
are **low-payoff design hypotheses**, not measured claims that Shael never selected
them. No win rates, population pick rates or native before/after balance were measured.
Working effects can still be poor purchases; weak value is not automatically a bug.

All ordinary selections cost one slot each; a three-rank ladder costs three slots.
The seven ordinary selections by Level 20 make marginal returns consequential.

## D — Arc Recovery: a useful kill refund

- ID: `INT_ARC_RECOVERY`; INT 17, no feat prerequisite, Magic pool; Heroes,
  human Soldiers and Magic-using AI.
- Current: a qualifying AI-hostile Magic kill restores **5 Magic**, with a
  **2-second per-actor cooldown** and 100 capacity. Several kills inside that
  cooldown do not each pay a refund.
- Proposal: restore **11 Magic** instead; retain the cooldown and every current
  kill/source/actor restriction. No new refund on non-kills or assists.
- Rationale: a high-threshold kill-dependent choice should deliver a noticeable
  refund when it succeeds. This preserves its kill-economy niche alongside passive
  Mana Spring instead of making both the same effect.
- Seam: `sv_rpg_gate_e_magic_recovery.lua`, `MagicRecoveryProfile`,
  `ResolveArcRecovery`, `ApplyArcRecovery`; producers in `sv_magic.lua` and
  `sv_magic_forms.lua`.
- Gate: positive qualified kill, multiple same-window kills, cooldown boundary,
  99→100 cap, non-Magic/non-AI exclusion, exact actor/life ownership and ordinary
  feedback/refund integration. Native check: observe return during an ordinary
  multi-enemy fight without changing damage or manufacturing kill credit.

## E — Feedback Loop: double the observable refund

- ID: `INT_FEEDBACK_LOOP`; INT 15, no feat prerequisite, Magic pool; Heroes,
  human Soldiers and Magic-using AI.
- Current: **1 Magic per actual offensive-Magic continuation die, maximum 6 per
  committed cast/attack event**. Initial dice and unbridged weapon-only chains do
  not count. A cast with no continuations returns nothing.
- Proposal: **2 Magic per continuation, maximum 12 per existing eligible event**.
  This changes the amount and cap only, not eligibility or required payment.
- Rationale: keep the explosion-build identity, but make a successful proc visible
  in the resource bar. Do not flatten every conditional feat into passive regen.
- Seam: the same recovery module's `ResolveFeedbackLoop` and `ApplyFeedbackLoop`;
  actual cast contexts in `sv_magic.lua` / `sv_magic_forms.lua` own event accounting.
- Risk/gate: test single/multiple targets, piercing, multi-projectile casts, replay,
  zero-cost or charged-item attacks under their existing eligibility, resource cap,
  and Rogue/Wizard explosions. Do not duplicate a refund per victim or create an
  unbounded self-funding cast loop. Preserve all current dice-work ceilings.

## F — Recovery ladder: improve both usable health and later recovery speed

- IDs: `CON_REGEN_11` Second Wind (CON 13), `CON_REGEN_22` Rapid Recovery
  (CON 15; Second Wind), `CON_REGEN_33` Unbroken (CON 17; Rapid Recovery).
  Heroes, human Soldiers and AI.
- Current: ceiling contributions **11/22/33% MaxHP**; every rank has the same
  **1% MaxHP/second before CON scaling**, after **5 damage-free seconds**.
  Fighter's innate 33% ceiling is additive. Thus Rapid Recovery currently does
  not accelerate recovery, and a 100-MaxHP non-Fighter's first rank stops at 11 HP.
- Proposal: ceiling contributions **22/44/66%**, and highest-rank base rates
  **1/1.5/2% MaxHP/second**, still CON-scaled after the same 5-second delay.
  Cap ordinary healing at MaxHP; never restore Tetris overfill. Retain all existing
  boss/actor exclusions and no-target/frozen/lifecycle rules.
- Resulting ceilings: non-Fighter **22/44/66%**, Fighter **55/77/99%** before any
  other independently authored contribution. These are ceilings, not instant heals.
- Seam: `sv_rpg_gate_e_feats.lua`, `regenDefinition`, `HealthRegenProfile`,
  `HealthRegenPerSecond`, `_TickActor`.
- Risk/gate: the largest sustain change here and also a possible enemy buff. Test
  every rank/class, floor rounding, interrupted recovery, overfill, death/life/reset,
  hostile health and Gordon's no-target behavior. Native low-health survival and
  interrupted enemy fights must remain finite. Do not remove Hector's exclusion.

## G — Ammunition ladder: faster refill, not just a higher stopping point

- IDs: `INT_AMMO_FLOOR_44` Field Supply (INT 13), `INT_AMMO_FLOOR_55` Deep
  Reserves (INT 15; Field Supply), `INT_AMMO_FLOOR_66` War Stock (INT 17;
  Deep Reserves). Eligible player-controlled Heroes and human Soldiers.
- Current: refill ceilings **44/55/66%**, versus baseline 33%; **no acceleration
  of per-round recovery or the no-fire wait**. The final loaded shared ammo table
  keeps the original baseline per-round interval even when a feat raises the floor.
- Proposal: retain those ceilings and grant **22/44/66% faster per-round recovery**.
  Divide the existing family interval by **1.22/1.44/1.66**. Preserve the current
  no-fire delay, whole-round accounting, capacity, firing interruption and exclusions.
- Rationale: improve the time until ammunition becomes useful, not just the amount
  available after an even longer wait. No instant ammo grant on taking the feat.
- Seam: `sv_rpg_gate_e_feats.lua` plus the final loaded `sv_smg_capacity_rebalance.lua`
  `RegenFloorRounds`, `Interrupt`, `TickPlayer`; do not patch only the overwritten
  older `sv_dice_ammo.lua` implementation.
- Gate: each firearm, all ranks, clip+reserve conservation, repeated shots, next-round
  deadlines, death/rejoin, cap/floor rounding and unchanged non-regenerative Wand,
  consumable and AR2-secondary resources. Native verify a shortened refill wait.

## H — Float On: more control for less Magic

- ID: `INT_FLOAT_ON`; INT 15, no feat prerequisite, Magic pool; player-controlled
  Heroes and human Soldiers.
- Current: hold Jump at the apex, once per airborne cycle, to float for **up to
  3 seconds at 5 Magic/second**: 15 Magic for a full use.
- Proposal: **up to 6 seconds at 2 Magic/second**: 12 Magic for a full use.
  Keep apex admission, voluntary control restrictions, one airborne use, early
  release, exhaustion, landing reset and existing collision containment.
- Rationale: hovering is distinct from Cloud Step, but currently asks much more
  Magic for short-lived positioning. This is not a claim that Cloud Step strictly
  dominates it in every encounter.
- Seam: `sv_rpg_checkpoint_d_movement_feats.lua`, Float On profile and existing
  airborne/resource consumer. No new flight, extra jump or gravity authority.
- Gate: exact elapsed spending, early release, cap, no airborne rearm, low Magic,
  Moon Boots/Cloud Step/Wall Jump, ceilings/gates, forced movement and death/role.
  Native inspect controllability, aerial combat and no out-of-maze bypass.

## I — Presence ladder: a perceptible stun-length increase

- IDs: `CHA_HITSTUN_1` Unnerving Presence (CHA 13), `CHA_HITSTUN_2` Dazing
  Presence (CHA 15; prior rank), `CHA_HITSTUN_3` Overwhelming Presence
  (CHA 17; prior rank). Heroes/human Soldiers/AI only with a usable stun source.
- Current: **10/20/30%** extra inflicted duration after ordinary CHA scaling.
  The shared ordinary base is **0.30 seconds**; with other multipliers neutral,
  first rank adds **0.03 seconds** and three ranks add **0.09 seconds**.
- Proposal: **22/44/66%**, highest rank only. Keep current defender resistance,
  shared duration cap, retrigger recovery, eligible-source rules and boss deadlines.
- Rationale: preserve the control specialization while improving the reward per
  slot. The example is uncapped neutral arithmetic, not universal native timing.
- Seam: `sv_rpg_gate_e_charisma.lua`, `CharismaProfile` and `HitStunMultiplier`,
  then `sv_m3_hit_feedback.lua` `ApplyHitStun`. Update the existing 1.30 feat-only
  clamp to the approved new maximum; retain the shared final multiplier cap.
- Gate: rank replacement, neutral examples **0.366/0.432/0.498 seconds**, resistance,
  final cap, firearm/burst retrigger guards, nonqualifying sources and exact fixed
  SPOT-06 Gordon follow-up deadline. Native no stun-lock or human-control regression.

## J — Personality aura: regular pressure rather than sporadic chip damage

- IDs: `CHA_ABRASIVE_PERSONALITY_1` Abrasive Personality (CHA 13),
  `CHA_NARCISSISM_2` Narcissism (CHA 15; prior rank), `CHA_MEGALOMANIA_3`
  Megalomania (CHA 17; prior rank). Heroes, human Soldiers and AI.
- Current: positive CHA modifier as untyped passive damage every **3d4 seconds**
  (mean **7.5 seconds**); highest-rank radii **0/1/2 same-floor cells**.
  Radius zero means the current cell, not an inert feat. Glow Up may add CON.
- Proposal: **one pulse every fixed 3 seconds**, same damage/radius and exclusions.
  Wait the full initial interval; no instant pulse, catch-up burst or timing dice.
- Rationale: ranks broaden coverage but do not improve the slow pulse. A reliable
  pulse makes the existing area-pressure role easier to observe.
- Seam: `sv_rpg_checkpoint_d_personality_aura_feats.lua`,
  `CheckpointDPersonalityAuraInterval` and its existing shared scheduler.
- Risk/gate: passive enemy auras and Glow Up gain the same cadence; do not silently
  add a new LOS or targeting rule. Test current-cell inclusion, floors/factions,
  highest rank, Glow Up exactly once, no proc recursion, lifecycle/freeze and native
  escape/attrition. This is a higher-risk follow-on, not a harmless cosmetic edit.

## Suggested approval order

D, E, G and H are the closest matches to the author's request: noticeable resource
or control payoffs without restructuring their roles. F also addresses a strong
value concern, but changes both Hero and enemy sustain substantially. I and J
warrant a more cautious control/attrition pass. These are recommendations, not
claims that the proposed values have passed native balance testing.

For any approved subset, reconcile exact live GDD rows first, implement in existing
shared authorities, synchronize cards/manual, and run a finite focused gate plus
relevant accepted regressions. Preserve existing ownership and pending drafts.
