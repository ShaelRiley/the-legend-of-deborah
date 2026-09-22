Resume development of **The Legend of Deborah** from the latest GitHub `main`.

You have **high-level game-design and implementation authority**. Make reasonable technical, tuning, UX, asset-selection, naming, and balancing decisions without stopping for minor ambiguities. Prefer coherent working systems over literal but brittle implementations.

## Authority and working method

1. **Inspect the current implementation before modifying it.** Do not assume the older GDD perfectly describes the present game.
2. These instructions **supersede conflicting older GDD rules**, particularly the old three-life/game-over model.
3. Preserve the systems that are already working: server-authoritative progression, procedural labyrinth generation, Level 1–20 damsel progression, Level-20 Deborah culmination, Level 21+ `SECURE THE BAG`, $DEB/DFT economy, equipment generation, multiplayer synchronization, staging area, and Source-era presentation unless explicitly changed below.
4. Keep the GDD synchronized with substantive design changes made during this pass.
5. Favor **data-driven, reusable architecture**. Do not implement ten bespoke versions of the same mechanic when one generalized system will support them.
6. Reuse existing LoD UI, audio, particle, status, input, item-property, safe-cell, maze-graph, and server-validation systems wherever practical.
7. Use only bundled/original/base-game-compatible assets. References to Zelda, Mario, Mortal Kombat, etc. describe mechanical or tonal inspiration; do not import copyrighted third-party assets.
8. Implement in dependency order. Validate each major subsystem before stacking dependent features on top of it.
9. Avoid unnecessary rewrites of stable systems.
10. When several reasonable solutions exist, choose the one that is simplest to maintain and clearest to players.

---

# PRIORITY 1 — Replace the game-over/lives model

The present elimination system is too punitive. Replace it with a retention-oriented **Hero / Soldier / Spectator queue system**.

## Zero-life behavior

When a Hero loses their final life:

- Do **not** end or reset the dungeon.
- Move them into an explicit post-elimination state.
- Clearly present three choices:

### WAIT FOR RESURRECTION

Remain in the **Hero Queue**.

The player may spectate while waiting to be restored by a valid resurrection source such as a Feather of Resurrection or other existing extra-life/revival mechanic.

### BEGIN A NEW HERO

Abandon the eliminated character and create a **new Level-1 Hero** in the **current dungeon**.

The new character:

- starts at Level 1;
- receives appropriate fresh-character equipment/resources;
- enters through the current dungeon's active staging/checkpoint flow;
- does not reset maze geometry, enemies, objectives, gates, timer, damsel state, or other players;
- retains account/server-level currencies and ownership that are intentionally outside character progression;
- receives a new procedural Hero identity as appropriate.

### JOIN THE SOLDIERS

Enter the **Soldier Queue** and participate as an enemy Soldier.

A player who has exhausted their Hero lives may choose Soldier play even when fewer than four Heroes are active.

Eliminated players may move between the Hero and Soldier queues without destroying their eligibility to return as a Hero. Build the state transitions so reconnects, death, team switching, and resurrection cannot duplicate lives, items, $DEB, DFTs, or character state.

Use existing GMod team/spectator mechanisms where they are reliable instead of inventing unnecessary infrastructure.

## Dungeon reset rule

**Hero elimination and total-party death no longer reset the dungeon.**

A failed dungeon is automatically reset only when its countdown timer reaches zero.

Successful level completion still performs its normal level transition/rebuild.

Therefore, even if every current Hero dies, the dungeon remains available until timeout: players can spectate, play Soldiers, be resurrected, or begin new Level-1 Heroes.

Remove obsolete assumptions that campaign continuation depends upon a fixed ten-model player roster.

Expand the eligible Hero model pool where suitable. Character identity remains a gameplay/presentation feature, but exhaustion of unique models must never terminate a run.

Update wipe detection, reconnect logic, leaderboards, staging logic, lives HUD, and documentation accordingly.

---

# PRIORITY 2 — Navigation, collision, persistence and critical bug fixes

Address these before adding substantial new content.

### Enemy and summon navigation

- Fix enemies and summons becoming stuck on stairs.
- Fix Climbers. They are effectively absent and have been observed stuck inside walls.
- Improve spawn validation and route placement rather than merely teleporting obviously broken enemies after the fact.
- Preserve the logical maze graph as the authoritative high-level navigation model.

### Summon presentation

Summoned rolling actors should visibly **roll along the floor**, not translate like sliding props or remain embedded halfway through the surface.

Correct:

- model origin/ground offset;
- rotational motion;
- collision;
- slope/stair behavior.

### Black gate

Once the black gate is open, it must remain reliably traversable by late-arriving Heroes.

Ensure:

- collision is actually disabled/removed;
- visual state matches mechanical state;
- late joins receive the correct gate state;
- players receive obvious visual affordance that the opening is traversable.

### DFT creation

Audit every pathway that announces or awards a DFT.

There appears to be a bug where the game says a DFT was created but none actually exists.

Server authority must guarantee:

**successful DFT award → real persistent DFT object/state → correct UI feedback**

Never announce success before the authoritative transaction succeeds.

### Ambient-loop cleanup

Arc Casters and Beam Sweepers sometimes leave their ambient loops playing after death.

All looping entity-owned sounds must terminate on:

- death;
- removal;
- level cleanup;
- regeneration;
- disconnect where applicable.

### Crowbar and pistol loot

Fix the regular loot pool so Crowbars and Pistols can appear normally alongside other eligible weapons.

### Staging-area shadow

Find and remove the rapid flickering shadow over/near the portal and Hermit. Determine whether it is caused by a duplicated light, projected texture, overlapping shadow caster, model, or particle rather than masking the symptom.

### Damsels

Fix:

- incorrect procedural color shading;
- the stray blue bauble/artifact;
- duplicate gifts.

Every damsel in the canonical Level 1–20 roster must have a **unique gift or service**.

---

# PRIORITY 3 — Progression, attributes and combat balance

## XP curve

Heroes currently level too quickly.

**Double the XP required to reach each subsequent level.**

Preserve existing accumulated XP semantics as sanely as possible.

## INT

Make Intelligence materially affect magic regeneration.

The difference between a low-INT and high-INT character should be obvious during ordinary play.

Bias the change toward **buffing high INT**, not making low INT miserable.

Use a readable bounded curve rather than a tiny linear modifier.

## DEX

Likewise make Dexterity's movement benefit conspicuous.

High-DEX Heroes should unmistakably feel quicker and more agile, without permitting pathological Source movement speeds or maze skips.

Centralize movement derivation so UI and mechanics report the same values.

## Item-granted abilities are real abilities

An equipped item must actually grant every gameplay feature written on it even when the Hero lacks the corresponding feat.

Examples:

- Bloodletting trousers really grant their bleed proc.
- Regeneration equipment really regenerates.
- Status riders really proc.
- Triggered properties really trigger.

Create a unified **effective capability** layer combining:

`class + feats + equipment + statuses + temporary effects`

Character Sheet text must correspond to actual authoritative behavior.

## Monster scaling

Difficulty is still too flat.

Starting with dungeon Level 3, every **3 dungeon levels** increase the base level of each monster grade by +1:

- basic;
- elite;
- champion.

Raise the per-dungeon monster-level hard cap in parallel so the new scaling is not silently clipped.

Keep entity counts within established performance ceilings; scale quality/composition before reckless population growth.

---

# PRIORITY 4 — Readability, UI and feedback

## Debbie Statue

Improve the Equipment / DFT / Sell / Fuse interfaces substantially.

Goals:

- immediately intelligible;
- fewer ambiguous states;
- stronger hierarchy;
- better item comparison;
- obvious drag/drop targets;
- obvious pending transaction;
- obvious result;
- clear confirmation/cancellation;
- Source/LoD visual language rather than generic glossy UI.

Add:

**SELL ALL UNEQUIPPED**

It must:

- clearly show what will be sold;
- never sell equipped items;
- respect unsellable/DFT-created restrictions;
- execute server-authoritatively;
- avoid double-selling or stale inventory references.

Improve the readability of currently equipped-item statistics and comparisons.

## Player look-at identity

Looking at another player should show, without overlap:

`[Steam/user name]`
`[health]`
`as [Hero character name]`

Use the procedural Hero name—not merely the player model/avatar name.

Apply the existing die-logger/player color system intelligently and maintain high contrast.

## Map/minimap

- Establish a sensible **minimum physical/UI map size** so it remains readable on 4K and large displays.
- Heroes should see other Hero players who are on their **current floor**.
- Do not reveal teammates on other floors as though they occupy the current plane.

## Character Sheet feat text

Rewrite **every feat description** for clarity and mechanical accuracy.

Target diction: a well-edited **Magic: The Gathering card**.

Requirements:

- concise;
- declarative;
- mechanically exact;
- minimal jargon;
- explicit trigger, cost, target, effect, duration and limitation where relevant;
- no text that promises behavior the code does not provide.

---

# PRIORITY 5 — Combat feedback and boss polish

## Universal enemy death treatment

As enemies die, rapidly interpolate their appearance:

`normal model → solid red silhouette/glow → normal → red`

with a brief smooth pulsing/flicker before disappearance.

Keep it performant and readable with many simultaneous enemies.

Add a **very short Enemy Defeated cue**, comparable in duration to the hit-confirm cue.

Do not create audio clutter: coalesce rapid simultaneous kills and use sensible concurrency limits.

Audit other major gameplay events and add audiovisual confirmation where the player currently receives inadequate feedback. Follow the principle:

**one mechanic, one recognizable cue**

## Gordon / existing boss behavior

Audit the present Gordon/Neil boss implementation before changing names or creating duplicate entities.

During the boss's first invisible phase, if the boss has gone a meaningful interval without taking damage, make the encounter more legible:

- temporarily stop ordinary attacks;
- audibly taunt;
- perform exaggerated taunting/dancing poses;
- use a short original villainous laugh evocative of an old 8-bit game-over taunt;
- thereby expose/reveal the encounter state to confused new players.

Add an appropriate hurt/recoil pose to Neil wherever the active Neil actor is used.

### Crowbar stun exploit

Players can currently stand beside Gordon and indefinitely hit-stun him with the crowbar.

Fix this **without removing gun hit-stun behavior**.

Use a robust boss-specific melee solution—for example diminishing melee stagger, temporary melee-stagger immunity, a close-range escape/counter, or a combination—while keeping crowbar hits worthwhile.

## Gordon clones

Every four dungeon levels, add one **Fake Gordon Clone** to the Gordon encounter:

- Level 4: 1 clone
- Level 8: 2
- Level 12: 3
- Level 16+: 4 maximum

Maximum encounter:
**1 real Gordon + 4 clones**

Clones:

- visually and behaviorally resemble Gordon;
- have no boss health bar;
- have 1/3 of real Gordon's HP;
- preferentially spread apart;
- prefer different Heroes/angles rather than dog-piling one target;
- remain server authoritative.

---

# PRIORITY 6 — Existing ability revisions

## Cloud Step I

Buff Cloud Step I:

- reduce magic cost;
- second jump receives roughly **2× the current vertical impulse**;
- directional input during the second jump adds a modest horizontal boost in that direction;
- add a unique brief sound;
- add a distinct particle effect.

Keep traversal safe against unintended wall-top/maze bypasses.

Later author clarification: preserve fun, emergent tactical movement. Use invisible
walls above the crates to prevent jumping over maze boundaries; do not limit jump
height or damp movement for containment. Preserve legal upper-floor paths and stairs.

## Piercing attacks

The **.357 Magnum** and **Beam** magic form must always pierce targets along their full valid trajectory.

A target reaching 0 HP must never terminate the trace.

Every valid actor intersecting the line can be hit, subject to sensible safeguards against double-hitting the same entity in one shot.

## Monster defenses

Arcane Diversion / Feedback / damage-reduction defenses are currently too opaque and too difficult to overcome.

Rebalance them so players can:

- pierce them somewhat more readily;
- suppress them for longer when successfully broken;
- leak meaningful damage through under appropriate conditions.

Most importantly, communicate:

1. that the attack was resisted;
2. **why**;
3. what category of attack or tactic would work better.

Do not let players repeatedly fire ineffective attacks without intelligible feedback.

---

# PRIORITY 7 — New procedural equipment and consumables

All of these participate in the existing procedural item system: rarity, quality, affixes, elemental/status riders, valuation, naming, sell value, etc.

Their innate powers make them stronger than generic items, so adjust procedural values/rarity accordingly.

Where multiple items use arrow-key sequences, build **one reusable input-combination ability framework**, not separate key listeners per item.

## Summon Card — throwable

On activation, player chooses an eligible other Hero.

- Throw/LMB: teleport that Hero to a validated nearby square.
- Consume/RMB: teleport them to the user's current square or nearest safe equivalent.

Never teleport someone:

- inside geometry;
- behind an unopened progression gate they could not legitimately reach;
- into a fatal/stuck position;
- outside valid labyrinth space.

Use the existing safe-cell/unstuck graph logic.

## Feather of Resurrection

Consumable.

Revives one eligible zero-life Hero waiting in the Hero Queue with exactly **1 life**.

Server authoritative.

## Gloves of the Fighting Streets

Arrow-key techniques while equipped:

`LEFT, DOWN, RIGHT`
→ projectile fireball attack

`RIGHT, DOWN, RIGHT`
→ rising immolating uppercut affecting enemies in the local square/area

Both cost magic.

Procedural variants may alter element/status properties.

## Crown of Psychic Crushing

Arrow combination activates **Psychic Crush** against the nearest valid enemy.

- automatic target acquisition;
- magical attack;
- `2d8 + WIS bonus`;
- target saves for half damage;
- costs magic.

Provide clear target and save feedback.

## Ring of Invisibility

Arrow sequence activates Invisibility.

- costs magic;
- applies the canonical `Invisible` actor state;
- ordinary enemies cannot acquire/attack an invisible Hero;
- define sane break/end conditions consistent with the existing status framework.

## Hat of the Thunder God

`UP, DOWN, UP`

Launch the Hero several blocks forward in a straight-line lightning charge.

- electric damage;
- stun potential;
- collision-safe;
- never phase through locked progression geometry;
- unmistakable audio/visual telegraph.

## Boots of the Heavy Plumber

Landing on an enemy from above performs a stomp attack.

After a valid stomp:

- deal damage;
- give the Hero a safe bounce away/upward;
- prevent repeated collision spam from applying impossible multihits.

## Tanuki's Ring

Standing completely still for **2 continuous seconds** activates `Statue`.

While Statue:

- apply a stone appearance;
- enemies neither see nor target the Hero;
- Hero takes no direct or ambient/AOE damage;
- Hero is effectively invulnerable.

Movement immediately ends Statue.

Add a brief original transformation sound/visual treatment evocative of a playful retro transformation without copying third-party assets.

Prevent trivial exploits such as retaining Statue while being forcibly propelled around.

## Wand

New weapon category.

- Wizards: normal use.
- Rogues: use requires the existing appropriate success roll.
- Other classes: cannot use.
- Uses Beam-form behavior.
- Fixed finite charges.
- Cannot be reloaded.
- Procedurally generated elemental/status rider.

Make remaining charges conspicuous.

## Boots of the Moon

Reduce player gravity while equipped.

Keep movement controllable and prevent obvious maze-boundary exploits.

## Magic Hourglass

Rare consumable.

Adds **2d4 minutes** to the current dungeon timer.

Server-authoritative roll and timer update.

---

# PRIORITY 8 — Stakeholders and Heroes of Legend

Fix the Stakeholders board so it actually shows **all qualifying $DEB holders**, not only the current top player.

Requirements:

- 10 players per page;
- deterministic ordering;
- pagination;
- active/current-session players included;
- in-progress games reflected rather than waiting for completed-run persistence.

Likewise, **Heroes of Legend** should display qualifying runs **while they are in progress**, clearly distinguishing live/in-progress results from completed ones if necessary.

Do not let transient duplicate records appear because the same run later completes.

---

# PRIORITY 9 — Modular procedural Events system

Build a future-facing server-authoritative **Dungeon Events framework**.

This should be extensible through registered event definitions rather than hard-coded generation branches.

Each dungeon receives:

**1d4 events**

General invariants:

- no event archetype repeats within the same dungeon;
- deterministic from dungeon seed where appropriate;
- event placement must pass generation validation;
- events must never make the labyrinth impossible;
- clean up completely on dungeon teardown;
- support individualized rewards where required;
- support late joins/reconnect synchronization.

At minimum support these placement classes:

### REWARD

Optional discoveries, often hidden in side branches.

### BLOCKADE

Placed on a route Heroes must traverse and must be resolved before progression.

### HAZARD

Environmental complication placed only where it cannot permanently invalidate the route.

### UTILITY

Persistent dungeon affordances such as warp links or vending machines.

---

# DFT treasure chest event

Rare DFT treasure chests may appear in a dungeon.

Treat one chest event as capable of spawning **1–2 chests** so the event archetype itself still obeys the no-repeat rule.

Each chest:

- contains one DFT;
- normally requires one expendable **Chest Key**;
- Chest Keys enter the normal procedural drop system.

Rogues may instead attempt to pick the lock once per chest.

Use the same success probability currently associated with their appropriate magic-item/use-device capability.

Failure consumes that lockpick attempt but does not necessarily consume an actual key.

Make DFT award atomic and verifiable.

---

# Game Master event

The **Game Master** may appear in a hidden optional alcove.

He looks suspiciously like the grinning Staging Area Hermit.

The implication that he may secretly be **Hector the Director** should remain suggestive until Level 20.

When encountered, he offers one challenge for a DFT.

The player gets **one attempt**.

If the player loses, the Game Master vanishes.

Build the minigames through a shared lightweight VGUI/minigame shell rather than seven unrelated UI systems.

Possible challenges:

### Equipment Quiz

Personal favorite; prioritize polish.

Show one real piece of equipment the player is actually wearing plus two plausible phonies.

The player must identify their own item **without opening/peeking at inventory or equipment UI during the challenge**.

If incorrect, the Game Master steals the real item in question.

If correct: DFT.

### Blackjack

Beat the Game Master → DFT.

### Poker

Resolve a short, self-contained poker-hand challenge → DFT.

### One-Move Chess

Present a valid mate-in-one puzzle → DFT.

### Tetris

Clear a small predetermined board condition → DFT.

### Flappy Neil

Lightweight minigame:

- Neil is a green-tinted G-Man carrying his suitcase;
- shipping-container obstacles;
- SPACE flaps the suitcase;
- one concise challenge;
- success → DFT.

### Super Neilio Bros.

Lightweight short procedural platform challenge:

- Plumber Neil;
- green-tinted G-Man appearance;
- suitcase retained as part of the visual joke;
- one short level;
- success → DFT.

### Bat Hunt

A compact target-clearing challenge inspired mechanically by the supplied Bat Hunt reference.

Success → DFT.

These games need to be **fun, quick and reliable**, not independent game-development projects. Favor clean 2D/VGUI or constrained in-world implementations over expensive bespoke systems.

---

# Additional dungeon events

## Slot machine

Optional machine where a player wagers real in-game **$DEB** and may win real $DEB.

Use transparent server-authoritative odds and safe transaction ordering.

## Bribe blockade

The Game Master or equivalent obstacle demands equipment/items worth at least **X $DEB**.

Only generate this blockade if the generator can establish that the party has a realistically satisfiable route to payment.

Do not create unwinnable progression states.

## Locked chest

General locked loot chest requiring:

- Chest Key, or
- one Rogue lockpick attempt.

## Skeleton of a Hero

Blockade miniboss.

Generate the skeleton substantially like a Hero:

- normal Hero class/stat/feat framework;
- dungeon-appropriate level;
- AI controlled;
- hostile;
- may have unusual colors or bonus properties.

Name from the normal Hero naming generator, prefixed:

`Skeleton of [Hero Name]`

Example:
`Skeleton of Paulie "Two Times" Malone`

Give the AI enough awareness to actually use its generated Hero abilities rather than merely owning inert statistics.

## Vending machine

Accepts $DEB and dispenses simple consumables such as chips or soda.

## Warp holes

Primarily on later levels.

Using one opens or links a corresponding hole on another appropriate dungeon floor, establishing a **permanent Hero traversal shortcut** for that dungeon.

Validate both endpoints against:

- locked progression;
- safe cells;
- objective sequence;
- stuck risk.

## Hazard example: false floor

A floor gives way and drops Heroes to a valid lower level.

Never place it where falling would:

- bypass required progression illegitimately;
- strand the Hero;
- make the dungeon unsolvable.

---

# PRIORITY 10 — Level-20 true finale: Hector the Director

Integrate this with the established damsel progression:

- Levels 1–19: damsel arc.
- Level 20: Deborah.
- Level 21+: `SECURE THE BAG`.

On Level 20, defeating **Gordon the Warden is no longer the final combat encounter.**

After Gordon dies but **before Deborah can be rescued**, reveal:

# HECTOR THE DIRECTOR

Hector is the apparent true identity or higher form associated with the suspicious Game Master/Hermit mythology.

## Presentation

Hector appears beyond/over the **Flattywood** sign.

He is enormous.

Only his upper body needs to be visible; exploit scale and framing rather than trying to make a full giant humanoid navigate the map.

He should occupy a large portion of the horizon/screen and read immediately as a deliberately extravagant final boss.

## Combat

This is primarily a ranged spectacle fight.

Hector:

- attacks with missiles, bombs and other readable projectiles;
- wields a titanic crowbar;
- fires corrupted **Villain of Lore** blasts—his evil analogue of Hero of Legend attacks;
- telegraphs dangerous attacks;
- remains damageable from the players' combat space;
- escalates without simply becoming a giant HP sponge.

Use the existing projectile/status/combat systems where possible.

Design an arena and attack grammar that work for 1–4 players and do not require giant-model navigation.

## Victory

Only after Hector is defeated may Deborah be rescued.

Then play a proper campaign-finale sequence:

- Deborah is saved;
- damsels celebrate;
- surviving Heroes receive celebratory presentation;
- Deborah gives the Heroes affectionate cheek-kiss celebration beats where technically/presentationally practical;
- communicate that the finite rescue story has been won.

After the finale, transition into the established endless arcade campaign:

**SECURE THE BAG**

Level 21+ continues indefinitely.

---

# ARCHITECTURAL EFFICIENCY REQUIREMENTS

Where practical, implement these reusable systems rather than scattered special cases:

1. **EffectiveCapabilities**
   Resolves feats + equipment + temporary statuses into actual mechanics.
2. **InputComboManager**
   Handles arrow-sequence item abilities, timing windows, UI feedback and conflicts.
3. **SafeTeleport / SafeCellResolver**
   Used by Summon Card, unstuck, warp holes and related relocation.
4. **EventDirector + EventRegistry**
   Seeded selection, uniqueness, placement class, validation, persistence and cleanup.
5. **GameMasterChallenge framework**
   Shared VGUI shell, one-attempt resolution, reward transaction and input locking.
6. **Boss telegraph/feedback helpers**
   Reuse status, particles, audio concurrency and combat feedback instead of bespoke loops.
7. **AtomicReward service**
   Particularly for $DEB, DFT, chest rewards and minigame payouts.
8. **Central procedural item registry**
   New special equipment should be definitions feeding existing generation, not isolated ad-hoc entities.
9. **Live leaderboard snapshot layer**
   Allows Stakeholders and Heroes of Legend to consume both persisted records and in-progress authoritative session state without duplication.

Prefer server-authoritative state transitions and thin client presentation.

---

# VALIDATION

Do not merely implement these features. Exercise them.

At minimum perform targeted automated/static/runtime validation where possible for:

### Lives / teams

- final-life death;
- Hero Queue;
- Soldier Queue;
- switching queues;
- starting a new Level-1 Hero;
- resurrection;
- reconnect;
- all Heroes simultaneously eliminated;
- dungeon remaining alive until timer zero;
- no duplication of items/currency/lives.

### Navigation

- stairs;
- Climbers;
- summoned rolling actors;
- open black gate;
- safe teleport destinations.

### DFT

- direct awards;
- treasure chest;
- Game Master win;
- DFT creation actually succeeding;
- no false success messages.

### Equipment

- item-granted abilities without matching feats;
- combo abilities;
- Sell All Unequipped;
- unsellable DFT-created equipment protection;
- item stat display.

### Combat

- Gordon crowbar exploit;
- gun stagger still functioning;
- fake Gordon scaling;
- Magnum piercing multiple targets;
- Beam piercing multiple targets;
- Arcane Diversion/Feedback readability;
- enemy death cues without audio spam.

### Events

Generate many seeded dungeons and verify:

- 1d4 events;
- no duplicate archetypes;
- blocker validity;
- no impossible routes;
- no unsafe warp/false-floor destinations;
- correct cleanup.

### Level 20

Validate the full chain:

`Gordon → Hector → Deborah → finale → Level 21 SECURE THE BAG`

Deborah must not be rescuable before Hector dies.

---

# DOCUMENTATION AND DELIVERY

Update the GDD wherever these changes invalidate its old rules, especially:

- lives/game-over;
- player identities/models;
- Soldier/Hero queues;
- resurrection;
- events;
- new items;
- monster scaling;
- boss progression;
- Level-20 Hector finale;
- endless-mode transition.

Keep implementation comments concise and architectural rather than narrating obvious code.

Review the resulting diff for:

- duplicated logic;
- abandoned old game-over paths;
- stale UI text;
- inconsistent documentation;
- exploitable client-authoritative transactions;
- unnecessary performance cost.

Run the project's available validation/test tooling and fix regressions attributable to this pass.

Then:

1. commit the completed cohesive build;
2. push it to **GitHub `main`**;
3. report:
   - commit SHA;
   - major systems implemented;
   - important tuning decisions;
   - tests/validation performed;
   - anything intentionally deferred or requiring live multiplayer verification.

You have permission to make the necessary game-design decisions and **push the build to GitHub** without returning for approval.