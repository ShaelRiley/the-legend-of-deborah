Continue development of **The Legend of Deborah** by implementing the complete feat rebalance below in both the live game code and the canonical Game Design Document.

**Repository:** `ShaelRiley/the-legend-of-deborah`  
**Gamemode:** `legend_of_deborah`  
**Canonical GDD:** `The Legend of Deborah — Garry's Mod Game Design Document`  
Google Doc ID: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`

You have permission to update the code and GDD as necessary and to commit/push the completed, validated implementation to GitHub main. Do **not** publish to Steam Workshop or deploy to the VPS unless I separately authorize that.

## Governing instruction

Read the **current live GDD and current GitHub main first**. Do not work from an older snapshot.

The decision ledger below is authoritative and supersedes stale feat descriptions, old balance values, old tests, obsolete feat IDs, and partially completed GDD edits. This prior thread was highly iterative, so some decisions are already reflected in the GDD and some are not. Reconcile everything comprehensively rather than assuming the document is internally consistent.

Do not merely alter descriptions. Implement the actual gameplay behavior, update player-facing descriptions/manual surfaces where applicable, remove obsolete code and registrations, repair feat-draft eligibility/prerequisites, update derived-stat displays, and update tests.

Removed feat IDs in existing campaign/save state should fail safely rather than crashing or blocking progression. Do not preserve removed feats in future feat drafts simply for backward compatibility.

# FINAL FEAT BALANCE DECISIONS

## Universal three-rank proc ladder

The standard three-rank proc-chance progression is now:

**55% → 75% → 95%**

Apply this to the remaining applicable offensive proc families:

- **Venomous → Toxic → Virulent** — Poison
- **Bloodletter → Deep Wounds → Exsanguinator** — Bleeding
- **Distracting → Disorienting → Discombobulating** — Clumsy
- **Singeing → Scorching → Incendiary** — Immolated
- **Disruptor → Spellbreaker → Nullifier** — Arcane disruption  
  - This is the **INT Spellbreaker**. Do not confuse it with the removed WIS Spellbreaker.
- **Hushing → Silencing → Dead Air** — Muted
- **Snaring → Binding → Entrapping** — Held
- **Agitating → Unhinging → Maddening** — Reckless
- **Daunting → Cowing → Overawing** — Intimidation/Morale attempts
- **Pusher → Shover → Space Hog** — weapon knockback proc

For **Pusher / Shover / Space Hog**, preserve their other current push/wall-slam mechanics but change proc probability to **55% / 75% / 95%**.

Higher ranks replace lower ranks; they do not stack their probabilities.

## Removed feats

Completely remove these feats from ordinary feat generation, player-facing feat lists, AI feat selection where applicable, prerequisite graphs, derived-stat displays, and active implementation:

- **Hard to Move / CON_STEADFAST**
- **Surveyor** — replaced by the single Cartographer feat below
- **Sideler**
- **Lateral Mover**
- **Cold Hands**
- **Ice in the Veins**
- **Absolute Zero**
  - replaced by **Heat Sink**
- **Lightning Reload**
- **Blink Reload**
  - replaced by single-rank Quick Reload
- **Mana Rush**
- **Aether Drive**
  - Haste is now one rank
- **WIS Spellbreaker**
- **Spellbane**
  - replaced by one-rank Spellward
- **Iron Nerve**
- **Unbreakable Nerve**
- **Force Multiplier**
- **Calculated Luck**
- **Size Shifter** as a feat
  - its mechanic moves to an item described below

Also remove **every cross-attribute feat**. The cross-attribute feat category is retired entirely:

- Meteor Strike
- Tiny Terror
- Big Scary
- Crash the Party
- Boom Battery
- Force of Will
- Lucky Break

Remove `CROSS_*` feat registrations and any feat-pool/cross-attribute eligibility language that exists only for this category. Do not delete underlying reusable combat systems merely because one of these feats used them.

## Not Yet

**Not Yet** is no longer a lethal-damage interceptor.

New effect:

- Passive **+1 personal-life cap**.
- Baseline life cap is 4, so the ordinary result is **4 → 5**.
- Treat this as an additive cap modifier so future effects could raise the cap further.
- Acquiring the feat raises the maximum only. It does **not** immediately award a life.
- Extra-life pickups and overflow-revival behavior must use the resulting current personal-life cap.
- Remove all old once-per-dungeon 1-HP survival state, cooldown/state bookkeeping, and combat-pipeline references.

## Russian Asset

Preserve Russian Asset's existing secondary benefits:

- Tetris overfill rewards remain doubled.
- Death Tetris maximum remains **120 seconds** rather than 60.
- Existing death/victory Tetris behavior otherwise remains intact.

Add this new **primary** ability:

**Input:** LEFT → RIGHT → UP → DOWN

Accept the sequence from:
- keyboard arrow keys, and
- controller / Steam Input D-pad.

This is a Russian-Asset-specific input sequence. It may accept D-pad input even if the ordinary Special Move system has different input restrictions.

On successful activation:

- Require at least **15 Magic**.
- Spend exactly **15 Magic**.
- Open Tetris during ordinary live gameplay.
- There is **no continuing Magic drain**.
- The player may continue playing Tetris indefinitely until they voluntarily close it or an authoritative lifecycle state ends it.
- The world does **not** pause.
- Enemies continue acting and may freely attack/kill the player.
- No invulnerability, aggro suppression, time-stop, or safety state is granted.

Live-Tetris line clears heal the player immediately using Russian Asset's doubled values:

- single: **+20 HP**
- double: **+60 HP**
- triple: **+100 HP**
- quad: **+160 HP**

Live-mode healing is capped at ordinary MaxHP and cannot bank temporary overfill. Excess healing is discarded.

Death/victory Tetris retains its existing overfill semantics.

## Strafer

Retire the old three-rank movement track.

**Strafer** is now one feat at the entry-level qualification gate.

Effect:

- **+75% voluntary lateral strafe movement**
- `StrafeSpeedMultiplier = 1.75`
- Apply only to the left/right component.
- Do not multiply the entire diagonal movement vector.
- Preserve compatibility with Rogue movement and other legitimate locomotion modifiers.
- Do not affect forced movement, push, knockback, ladders, scripted relocation, etc.

Remove Sideler and Lateral Mover entirely.

## Spring Heel

Buff **Spring Heel**:

- Every voluntary jump has **3× the otherwise-current jump apex**.
- This includes ordinary jump, Wall Jump vertical takeoff, and Cloud Step's jump where applicable.
- Implement the vertical impulse correctly to produce approximately triple apex height under current gravity; do not naïvely triple velocity.
- While legitimately airborne, voluntary horizontal movement/air-control speed is **1.5×** normal.
- The 1.5× airborne movement bonus must not amplify discrete Wall Jump kicks, Cloud Step's authored directional impulse, knockback, BaseVelocity, scripted motion, conveyors, etc.
- Existing physical anti-bypass/progression geometry remains authoritative.

## Quick Reload

Retire the old reload ladder.

**Quick Reload** becomes one feat.

Effect:

- Ordinary reloads are **66% faster**.
- Canonical implementation for this design decision: `ReloadTimeMultiplier = 0.34`.
- Do not affect SMG overheat recovery, targeting telegraphs, Magic cooldowns, attack telegraphs, etc.

Remove Lightning Reload and Blink Reload.

## Heat Sink

Replace the entire Cold Hands ladder with one feat named:

**Heat Sink**

Use the old entry-level DEX qualification.

Effect:

- `SMGHeatSuppressionChance = 0.66`
- Every successfully fired SMG round independently has a **66% chance to add zero heat**.
- Preserve the former first-rank overheat-threshold benefit:
  - `SMGOverheatThreshold = 8`
- Keep normal ammo use, damage, fire rate, natural cooling, visual heat presentation, and fixed overheat lockout unchanged.
- Heat-suppression rolls remain server-authoritative and deterministic.
- Remove Cold Hands / Ice in the Veins / Absolute Zero and their rank logic.

## Quantum Mathematics track

Buff the offensive-Magic cost-reduction ladder:

- **Quantum Mathematics:** −22% cost  
  `QuantumCostMultiplier = 0.78`
- **Quantum Mechanics:** −44% cost  
  `QuantumCostMultiplier = 0.56`
- **Quantum Mastery:** −66% cost  
  `QuantumCostMultiplier = 0.34`

Preserve existing eligibility, exclusions, rounding, and minimum-cost rules.

## Mana Spring

Verify rather than redesign.

Canonical Mana Spring is simply:

**+22% passive Magic regeneration**

Implementation:

- Multiply otherwise-permitted passive Magic regeneration by **1.22 exactly once**.
- No activation.
- No zero-Magic trigger.
- No temporary duration/window.
- No cooldown.
- No Magic-cap increase.
- No active-Magic cost reduction.
- Existing states that suppress passive regeneration remain authoritative.

The current GDD may already have this correct. Do not accidentally resurrect an older Mana Spring version.

## Haste

Retire Haste as an activated/draining three-rank ability.

**Haste** is now one passive feat:

- **+33% ordinary voluntary movement speed**
- `HasteMovementMultiplier = 1.33`
- No toggle.
- No activation key.
- No Magic cost.
- No sustained drain.
- No Magic-regeneration suppression.
- It composes once with legitimate ordinary walk/run/sprint and movement modifiers.
- It does not affect jump velocity, airborne acceleration, Wall Jump, Cloud Step, Float On, Push/knockback, falling, projectiles, or forced/scripted movement.

Remove Mana Rush and Aether Drive, along with all stale Haste-drain interactions in Frugal Cartography, map viewing, Aura Burst exclusions, etc.

## Unnerving Presence track

Buff hit-stun duration multipliers:

- **Unnerving Presence:** ×2
- **Dazing Presence:** ×3
- **Overwhelming Presence:** ×4

Apply after ordinary CHA hit-stun scaling using the existing canonical ordering.

Preserve hit-stun retrigger guards, defender resistance, boss rules, anti-stunlock protections, and final hard caps.

## Cartographer

Retire Surveyor and the two-rank navigation track.

**Cartographer** is now one WIS 13 feat:

- `BreadcrumbCells += 8`

Use the existing canonical current-objective routing restrictions.

## Spellward

Retire the WIS Spellward/Spellbreaker/Spellbane rank ladder.

**Spellward** becomes a single WIS 13 feat.

Effect:

Whenever the actor makes an otherwise-legal **Magic Save**:

- roll two d20s,
- keep the higher natural result,
- then add the ordinary WIS/level modifiers,
- compare to the ordinary MagicDC.

This is ordinary **advantage**, not a +2/+4/+6 flat bonus.

It does not create a Magic Save against effects that normally provide none.

Do not alter the separate **INT Spellbreaker** feat in the Arcane Disruption proc family.

## Grand Unified Theory

Buff from one extra Form to **two**.

On acquisition:

- Immediately grant **two distinct currently-unowned class-eligible Magic Forms**.
- Use deterministic selection through the existing feat-specific RNG authority.
- Do not duplicate an owned Form.
- If exactly one eligible Form remains, grant that one.
- If none remain, the feat is ineligible and should not be offered.
- Later scheduled Form grants continue selecting from whatever remains.

Update examples/progression text that currently assumes this feat adds only one Form.

## Extracurricular Activity

Buff from one extra Content to **two**.

On acquisition:

- Immediately grant **two distinct currently-unowned Contents**.
- Deterministic selection.
- No duplicates.
- If only one remains, grant it.
- If none remain, the feat is ineligible.
- Later scheduled Content grants continue from whatever remains.

Update examples/progression text that currently assumes this feat adds only one Content.

## Feedback Loop

Completely replace the old Boom-continuation mechanic.

New **Feedback Loop**:

When the owner actually **takes HP damage**:

1. Snapshot the actual HP damage suffered by that resolved damage event after ordinary mitigation/diversion semantics have determined real health loss.
2. Roll one sealed, non-exploding **1d4-second delay**.
3. When that delay expires, refund Magic equal to **50% of that actual HP damage taken**.
4. Magic cannot exceed 100.
5. Fractional Magic is legal; do not introduce avoidable rounding loss.
6. Zero actual HP loss produces no refund.
7. Each qualifying damage event owns its own delayed refund and cannot duplicate itself through pellets/internal sub-hits after canonical aggregation.
8. Death/lifecycle handling must be explicit and safe; no stale callback may pay into a replaced actor/run/identity.

Remove the former “2 Magic per offensive-Magic continuation die, max 12 per cast” behavior and stale tests/docs.

## Arc Recovery

Make **Arc Recovery** the offensive analogue of Feedback Loop.

When the owner deals **Magic-tagged actual HP damage**:

1. Snapshot the actual HP damage dealt by that resolved target-damage event.
2. Roll one sealed, non-exploding **1d4-second delay**.
3. On expiration, refund Magic equal to **50% of actual HP damage dealt**.
4. Cap CurrentMagic at 100.
5. Fractional Magic is legal.
6. Misses, immune/zero-damage outcomes, and nonmagical damage create no refund.
7. Resolve once per canonical damaged-target event after aggregation, not once per die/pellet/internal sub-hit.
8. Delayed callbacks must validate actor identity/run/lifecycle so stale damage cannot fund a later incarnation.

Remove the old “11 Magic on Magic kill with 2-second cooldown” implementation.

## Calculated Luck

Remove **Calculated Luck** completely from the feat system.

The separate Luck Ring item/system may continue existing if otherwise canonical; this instruction removes the feat, not necessarily the item.

## Attunement

Buff **Attunement**.

Old behavior—rolling the weakness bonus twice and keeping the better result—is retired.

New behavior:

Whenever the actor's **Magic** exploits an elemental weakness:

- determine the ordinary elemental weakness bonus once;
- **double that bonus**.

Example:
- ordinary +22% weakness bonus → Attunement makes it +44%.
- ordinary +66% → +132%.

Do not double the entire final attack damage a second time; double the **weakness bonus contribution** itself.

No extra weakness-table roll is generated.

Do not duplicate hit stun, knockback, Content riders, or Magic cost.

## Abrasive Personality family

Final aura radii:

- **Abrasive Personality:** radius 1 cell — **3×3 neighborhood**
- **Narcissism:** radius 2 cells — **5×5 neighborhood**
- **Megalomania:** radius 3 cells — **7×7 neighborhood**

No rank should be described as “Cell 0” or same-cell-only.

Preserve the existing 3-second pulse cadence and CHA_MOD passive damage semantics.

## Aura Burst

**Aura Burst rank 1** now begins at:

- radius 1 cell
- full **3×3 neighborhood** centered on the caster

It is no longer same-cell-only.

For this implementation pass, do **not silently redesign Radiance or Majesty beyond what the live GDD currently says**. Implement the explicit Aura Burst rank-1 change first and preserve later-rank authored behavior unless required to repair a direct contradiction.

## Aggressive Personality

Audit this carefully in both GDD and runtime.

**Aggressive Personality has no range requirement at all.**

It is not “range zero.” It is simply range-independent.

Whenever its ordinary eligibility conditions are satisfied and the feat is ready:

- the next eligible attributable physical attack gets its existing `max(0, CHA_MOD)` flat outgoing damage contribution;
- distance from attacker to target is irrelevant;
- do not perform a radius, cell-distance, or range gate for the feat itself.

Preserve the existing sealed 1d3-second cooldown behavior and current exclusions.

Inspect implementation specifically for bugs where an authored `range = 0` / radius-zero value is interpreted as “affects nothing.” Remove that concept from Aggressive Personality. It should always function on an otherwise-eligible physical damage event.

## Size Shifter → Ring of the Size Shifter

Remove **INT_SIZE_SHIFTER / Size Shifter** from the feat pool.

Create a named wearable item:

**Ring of the Size Shifter**

Use the existing single-hand Ring equipment framework.

While equipped, it grants the former Size Shifter ability:

- Crouching gradually transforms the wearer toward **0.33× scale**.
- Full ordinary-to-minimum transition takes **3 seconds**.
- Releasing crouch smoothly reverses toward the actor's ordinary non-ring scale.
- Partial transitions reverse continuously rather than snapping/restarting.
- No Magic cost.
- Model, combat hurt presentation, camera where safe, and PushSizeScale follow the interpolated transformation as currently authored.
- Authoritative movement/collision hull, stair legality, USE reach, weapon traces, gates, and progression geometry retain the safety rules that prevent shrinking through illegal gaps or progression barriers.
- Little Guy / Big Guy or other legitimate ordinary-scale sources define the scale to which the wearer returns.

The ability exists **only while the ring is equipped**.

On unequip, death, replacement, or other lifecycle loss of the item grant:
- remove access cleanly,
- resolve/return the actor safely toward their ordinary scale,
- never leave a stale scale modifier or trap the actor in invalid geometry.

Add the item to the canonical equipment/magic-item documentation and implementation using shared equipment-effect authority rather than duplicating a private Size Shifter subsystem.

## Force Multiplier

Remove **Force Multiplier** completely.

Because all cross-attribute feats are also removed, Force of Will must not remain as a dangling prerequisite.

Do not remove the underlying shared Magic Push mechanics themselves.

## Iron Nerve

Remove:

- **Iron Nerve**
- **Unbreakable Nerve**

Do not change the underlying Morale system merely because these defensive feats are gone.

# IMPLEMENTATION REQUIREMENTS

After reconciling the design, audit the actual feat implementation comprehensively.

Specifically:

1. Locate the authoritative feat registry/catalog and ensure every retained feat matches the rules above.
2. Remove retired feat IDs from future draft candidate construction.
3. Remove or update prerequisites that reference retired feat IDs.
4. Ensure AI FeatDirector cannot select deleted feats.
5. Ensure saved/stored draft hands containing removed IDs are repaired through the existing removed-ID compatibility path rather than blocking a campaign.
6. Update derived-stat fields and Character Sheet presentation where renamed/removed mechanics are exposed.
7. Update feat descriptions/cards/manual text.
8. Remove obsolete runtime state such as old Not Yet consumed-dungeon state, Haste toggles/drains, old multi-rank Heat Sink/Quick Reload state, etc.
9. Preserve deterministic RNG separation where new delayed 1d4s or proc rolls require random streams.
10. Use sealed non-damage timing d4s for Feedback Loop/Arc Recovery delays; they never explode and do not inherit Rogue/Boom/damage-die behavior.
11. Audit delayed callbacks for run, dungeon, actor identity/incarnation, death, disconnect, reset, hot-reload, and replacement safety.
12. Do not add expensive per-frame world scans. Preserve the project's low-end/Steam Deck performance discipline.
13. Grep for stale player-facing names and obsolete percentages after implementation.

# VALIDATION

Before pushing:

- Run Lua syntax validation across the shipping tree.
- Run all existing feat/RPG/combat test suites.
- Update/add focused regression tests for every altered feat family.
- Add explicit tests proving removed feats cannot be offered.
- Test representative old/stored feat IDs through the compatibility path.
- Test the 55/75/95 proc ladders deterministically.
- Test Not Yet life-cap arithmetic with baseline cap and an additional hypothetical additive cap source.
- Test Russian Asset input recognition, 15-Magic cost, insufficient-Magic rejection, live damage vulnerability, immediate healing, no overfill, closure/lifecycle cleanup, and controller/keyboard sequence parity.
- Test Heat Sink at exactly 66%.
- Test Quick Reload at 0.34 time multiplier.
- Test Haste as passive 1.33 with zero Magic interaction.
- Test Spring Heel 3× apex and 1.5× airborne voluntary movement without multiplying discrete/forced impulses.
- Test Spellward advantage as two d20s/keep-highest on a single Magic Save.
- Test Feedback Loop and Arc Recovery delayed 50% refunds, including fractional Magic and stale-callback rejection.
- Test Grand Unified Theory / Extracurricular with 2, 1, and 0 remaining unlocks.
- Test Aggressive Personality at close and very long legal attack distances to prove there is no feat range gate.
- Test Abrasive Personality radii 1/2/3.
- Test Aura Burst rank-1 3×3 coverage.
- Test Cartographer +8.
- Test Attunement doubling the weakness **bonus**, not duplicating the full attack.
- Test Ring of the Size Shifter equip/unequip, partial crouch transformation, return-scale composition, death/reset cleanup, and geometry safety.

Finally, search the repository and GDD for stale references to:

- Hard to Move
- Sideler
- Lateral Mover
- Cold Hands
- Ice in the Veins
- Absolute Zero
- Lightning Reload
- Blink Reload
- Mana Rush
- Aether Drive
- WIS Spellbreaker
- Spellbane
- Surveyor as a feat
- Iron Nerve
- Unbreakable Nerve
- Force Multiplier
- Calculated Luck
- Size Shifter as a feat
- all `CROSS_*` feats
- old 11/22/33 proc ladders
- old 25/50/75 Pusher ladder
- old 1.22/1.44/1.66 Presence values
- old Quantum 11/22/33 values
- old Haste toggle/drain language
- old Not Yet lethal-intercept language
- old Feedback Loop Boom-refund language
- old Arc Recovery kill-refund language

Distinguish harmless historical changelog/test-fixture references from active canonical/runtime rules; do not destroy useful historical evidence just to make grep output empty.

# GDD RECONCILIATION

Update the live Google Doc in place.

The GDD was edited repeatedly during the prior balance session, and several later decisions superseded earlier ones. Treat this prompt as the final decision ledger.

Where HUMAN and normalized AI-facing tabs duplicate rules, reconcile the relevant canonical/normalized copies so future agents do not receive contradictory feat specifications.

Do not expand scope into unrelated gameplay systems.

# COMPLETION

When the implementation is stable:

1. summarize exactly which feats were changed, removed, collapsed, or migrated to equipment;
2. report tests and validation performed;
3. report any remaining native/in-game acceptance items that cannot be established headlessly;
4. update the GDD;
5. commit and push the validated code to GitHub main;
6. provide the resulting commit SHA.

Do not publish to Workshop or deploy the VPS in this task.
