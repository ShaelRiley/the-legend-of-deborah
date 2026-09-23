Resume development of **The Legend of Deborah** from current GitHub `main` and complete the next bounded development gate: a major **Bestiary Expansion + Encounter Ecology Overhaul**.

**Repository:** `ShaelRiley/the-legend-of-deborah`

## Authorization

You have high-level game-design and implementation authority for this checkpoint.

You are authorized to:

* inspect and modify gameplay systems, encounter systems, enemy AI, tuning, procedural generation, presentation, names, lore, spawning logic, testing, documentation, and supporting architecture;
* make reasonable design decisions without stopping for routine approval;
* create procedurally recolored, rescaled, recontextualized, or otherwise procedurally revisualized enemy variants using **only assets already available to the project/base game**;
* recombine existing combat mechanics, attacks, status effects, movement behaviors, equipment interactions, elemental systems, abilities, AI primitives, and procedural systems in novel ways;
* refactor existing enemy/director architecture where this materially improves maintainability, determinism, variety, or emergent gameplay;
* amend the live GDD wherever substantive design decisions become canonical;
* add or revise automated tests and developer diagnostics;
* commit and push the completed bounded checkpoint directly to `main` after validation.

Resolve ordinary ambiguities yourself.

**Do not deploy to the VPS or publish to Steam Workshop.**

Never force-push or overwrite newer remote work.

---

# 1. Recover efficiently

Before editing:

1. Verify current remote `main`.
2. Read `AGENTS.md`.
3. Read the newest checkpoint in `docs/DEVELOPMENT_PLAN.md`.
4. Inspect the **current implemented enemy roster**, enemy authorities, status/combat systems, procedural encounter director, and the relevant live GDD material.
5. Treat the current repository and live GDD as authoritative over older prompts or obsolete roster descriptions.
6. Preserve completed work. Do not repeat broad audits that recent checkpoints have already completed.

Establish the actual number of presently implemented, gameplay-meaningful normal enemy types/variants before calculating the expansion target.

---

# 2. Expand the bestiary by 250%

For this checkpoint, **“expand the bestiary by 250%” means increase the current gameplay-meaningful normal-enemy roster to approximately 3.5× its present size**.

Example: if 8 meaningful enemy types presently ship, target approximately 28 after this pass.

Do **not** inflate the count with trivial palette swaps.

A variant counts toward the target only when a player can reasonably perceive it as a distinct tactical problem because it changes one or more meaningful dimensions such as:

* movement or pursuit behavior;
* attack selection;
* engagement range;
* positioning logic;
* durability profile;
* vulnerability;
* resistance;
* status application;
* elemental interaction;
* target priority;
* group behavior;
* reinforcement behavior;
* ambush behavior;
* death behavior;
* resource pressure;
* terrain preference;
* verticality;
* encounter role;
* relationship to another enemy type.

Visual differentiation may use procedural recoloring, tint regions, scale variation, existing particles, existing materials, existing effects, existing sounds, existing models, or combinations thereof.

**Introduce no new external visual assets.**

Reuse the existing design landscape aggressively.

---

# 3. Design monsters as an ecology, not a spreadsheet

Approach new enemies as believable manifestations of the recursive prison.

Imagine that the labyrinth has an ecology, occupational structure, corruption process, or mythology of its own.

Ask questions such as:

* What happens when an existing creature adapts to upper catwalks?
* What would inhabit deep, enclosed sectors rather than open junctions?
* Which creatures would plausibly guard machinery, treasure, prisoners, gates, or vertical passages?
* What might be a diseased, armored, volatile, territorial, predatory, parasitic, magically altered, veteran, juvenile, degraded, or specialized form of an existing creature?
* Which enemies would naturally hunt in pairs, packs, screens, escorts, ambush cells, firing teams, or mixed symbioses?
* Which existing game systems are presently underexploited by enemies?
* Which statuses, resistances, elemental mechanics, movement systems, projectiles, melee logic, hazards, vertical behaviors, or combat authorities can support a monster niche that currently does not exist?

Names and visuals should communicate enough that players gradually learn the ecology without requiring exposition.

Favor **systemic combinations** over bespoke one-off scripting.

A good new enemy should create new decisions with surprisingly little unique code.

---

# 4. Fill tactical niches opportunistically

First inspect the actual current roster and construct a compact internal matrix of existing tactical roles.

Then identify missing or underrepresented niches.

Potential niches include—but are not limited to:

* slow area denial;
* fragile ranged harassment;
* suppressive fire;
* aggressive flanking;
* retreat-and-reengage behavior;
* pack hunting;
* shield/guard behavior;
* healer/support;
* buffer/debuffer;
* status specialist;
* elemental specialist;
* anti-caster pressure;
* anti-ranged pressure;
* anti-melee pressure;
* ambush predator;
* pursuit predator;
* territorial defender;
* stationary/semi-stationary hazard;
* mobile hazard;
* suicide/volatile enemy;
* summoner;
* commander;
* escort/bodyguard;
* sniper;
* artillery;
* bruiser;
* glass cannon;
* swarm unit;
* elite veteran;
* scavenger;
* corpse interaction;
* vertical attacker;
* ceiling/high-ground attacker;
* low-profile attacker;
* chokepoint controller;
* open-room specialist;
* darkness/visibility pressure;
* sound-driven threat;
* resource-taxing threat;
* enemies that become substantially more dangerous in combination with particular allies.

Do not mechanically implement every idea merely because it appears above.

Use the existing systems to select the strongest, most legible, most maintainable possibilities.

Prefer enemies whose existence opens **new encounter compositions**.

---

# 5. Preserve readable combat

Variety must not become noise.

Every enemy should retain:

* recognizable silhouette/presentation using existing assets;
* readable attack tells;
* comprehensible damage/status feedback;
* sane collision;
* reliable navigation;
* multiplayer-safe authoritative behavior;
* reasonable performance cost;
* a clear tactical identity.

Avoid enemies whose gimmick is effectively invisible until the player takes unavoidable damage.

Avoid excessive immunity systems.

Prefer resistance, positional advantage, altered behavior, or soft counters over hard invalidation of player builds.

No individual enemy should demand a specific class unless it appears only in compositions where the party has reasonable alternative answers.

---

# 6. Build families where appropriate

Some current enemies should become **families**.

A family may share a model, locomotion authority, or core AI while branching into recognizable ecological variants.

For example, one base creature might plausibly produce:

* a common form;
* a fast hunting form;
* a defensive form;
* a status-bearing form;
* a rare elite form.

Do not apply this pattern mechanically to every archetype.

Some creatures should remain unique.

Variant generation may be partly procedural, but **mechanically meaningful variants should have stable identities and names** so players can learn them.

Pure cosmetic variation can remain procedural within those identities.

---

# 7. Overhaul the Encounter Director after the roster expansion

Once the enlarged roster exists, substantially overhaul enemy placement and composition.

The principal objective is:

> **Maximize emergent gameplay while minimizing perceived repetition.**

The present failure mode—repeatedly seeing the same common enemies on every floor—must disappear.

Do not solve this by simply throwing every enemy into one global weighted table.

Instead create a layered procedural ecology.

---

# 8. Introduce procedural floor identities

Each generated level/floor/sector should be capable of acquiring one or more **encounter themes** or ecological motifs.

Examples of thematic dimensions:

* infestation;
* occupation;
* hunting ground;
* fortified sector;
* abandoned/degraded zone;
* ranged-control territory;
* melee-heavy warrens;
* magical corruption;
* elemental contamination;
* vertical predator territory;
* scavenger territory;
* elite patrol zone;
* swarm zone;
* sparse but dangerous zone;
* high-ambush zone;
* mixed contested-feeling ecology;
* unusually quiet floor punctuated by severe encounters.

These are **procedural grammars**, not fixed authored levels.

A theme should influence:

* enemy-family prevalence;
* encounter-template availability;
* squad composition;
* density;
* reinforcement probability;
* elite probability;
* environmental positioning;
* pacing;
* occasional visual treatment where existing systems permit it.

Themes should be recognizable in retrospect without becoming deterministic.

---

# 9. Use weighted exclusion, memory, and novelty pressure

The director should explicitly reason about recent encounter history.

Implement mechanisms such as:

* recent-enemy suppression;
* recent-family suppression;
* recent-template suppression;
* recent-theme suppression;
* novelty bonuses;
* minimum recurrence distances;
* cooldowns before dominant archetypes can dominate again;
* run-level appearance accounting;
* controlled rare-enemy scheduling;
* anti-streak logic;
* composition-diversity scoring.

A player should not repeatedly encounter the same tactical composition simply because it has a high base weight.

Randomness should possess **memory**.

---

# 10. Balance novelty against roster visibility

We want meaningful variety, but not a bestiary so diluted that most monsters are rarely seen.

Across a normal substantial campaign:

* most common and uncommon enemy families should appear;
* rare/specialist variants may remain meaningfully rare;
* a single level need not expose anything close to the full roster;
* consecutive levels should often feel substantially different;
* enemies absent for several levels should gain some reappearance pressure where appropriate;
* individual floors may deliberately omit otherwise-common families.

Think in terms of **campaign-level coverage** rather than forcing universal level-level coverage.

A good run should create memories such as:

> “That was the floor full of those awful climbing things.”

or

> “That level had barely any zombies, but those ranged patrols were brutal.”

The next campaign should tell different stories.

---

# 11. Encounters should have tactical syntax

Every generated encounter should have an intelligible tactical proposition.

Examples:

* screen + artillery;
* bruiser + harassers;
* ambusher + pursuit unit;
* ranged line + flanker;
* swarm + support unit;
* elite + disposable escorts;
* area denial + enemies that force movement;
* slow tank + fast opportunists;
* crossfire;
* staggered reinforcement;
* bait enemy concealing an ambush;
* predator pack distributed across connected rooms.

Avoid “one of everything.”

Composition should produce **interaction effects** between enemies.

Those interactions are where emergent gameplay lives.

---

# 12. Exploit maze topology

Encounter generation must reason about actual generated geometry.

Where practical, classify encounter spaces using information such as:

* corridor length;
* junction degree;
* blind corners;
* vertical transitions;
* elevated platforms;
* multi-entry arenas;
* dead ends;
* loops;
* chokepoints;
* open cells;
* approach directions;
* retreat options;
* nearby encounters;
* objective proximity.

Then prefer enemies and compositions that make those spaces tactically interesting.

Examples:

* flankers belong where alternate routes exist;
* ranged units need viable sightlines;
* ambushers benefit from occluded approaches;
* swarms need maneuvering room;
* area denial becomes meaningful at chokepoints;
* vertical attackers belong where height actually matters.

Do not place an enemy merely because a cell is technically available.

---

# 13. Create macro-pacing, not uniform pressure

Runs should breathe.

The director should produce:

* quiet traversal;
* low-intensity probes;
* surprising spikes;
* sustained engagements;
* recovery segments;
* threatening optional branches;
* memorable objective fights;
* occasional gauntlets;
* occasional eerily sparse sectors.

Avoid a metronomic sequence of similarly sized fights.

Intensity should form procedural **phrases**.

The player should sometimes wonder why a corridor is empty.

---

# 14. Preserve determinism and server authority

All new enemy selection, variants, themes, compositions, and placement decisions must remain compatible with the game's deterministic campaign/level-seed architecture.

Given equivalent game version, seed, and relevant state, encounter planning should remain reproducible enough for debugging.

Maintain server authority for:

* encounter generation;
* enemy type/variant selection;
* activation;
* combat;
* status effects;
* drops;
* progression-relevant state.

Do not introduce client-trusting combat logic.

---

# 15. Performance and entity ceilings

Variety must not come from uncontrolled entity proliferation.

Respect existing active-hostile ceilings and performance budgets.

Prefer:

* richer compositions;
* smarter placement;
* timing;
* reinforcements;
* roles;
* behaviors;
* interactions;

over simply increasing simultaneous enemy count.

Reuse shared authorities rather than multiplying expensive Think loops.

Where several variants can share one implementation with data-driven configuration, prefer that architecture.

---

# 16. Refactor toward data-driven enemy definitions

If the present architecture would otherwise require large amounts of duplicated enemy code, introduce or improve a centralized definition/family system.

Enemy definitions should be able to express, where appropriate:

* family;
* display name;
* visual treatment;
* HP/durability;
* speed;
* attack package;
* behavior flags;
* encounter roles;
* threat cost;
* preferred topology;
* sector/theme affinities;
* rarity;
* campaign introduction weighting;
* status interactions;
* resistances/vulnerabilities;
* elite eligibility;
* drop modifiers;
* director incompatibilities or synergies.

Do not overengineer abstractions that the current codebase does not need.

The goal is a robust vocabulary from which the procedural director can compose encounters.

---

# 17. Add director diagnostics

Provide developer-visible diagnostics sufficient to understand generated ecology.

At minimum, make it possible to inspect or log a generated level's:

* chosen theme(s);
* roster subset;
* encounter templates;
* enemy compositions;
* threat expenditure;
* novelty/repetition decisions;
* family distribution;
* notable rare encounters.

Prefer concise structured output over noisy per-enemy logging.

Where appropriate, extend existing debug visualization instead of creating redundant systems.

---

# 18. Validate diversity quantitatively

Add automated validation around the new director.

Use a large deterministic seed sample sufficient to catch systemic repetition.

Measure useful indicators such as:

* enemy-family appearance frequency;
* individual variant frequency;
* consecutive encounter duplication;
* consecutive-level roster overlap;
* theme distribution;
* template distribution;
* maximum recurrence streak;
* campaign roster coverage;
* threat-budget compliance;
* active-hostile ceilings;
* reproducibility for identical seeds.

Do not optimize mechanically for a single diversity statistic; use metrics to detect obvious pathologies.

Include tests that prove:

* identical seeds reproduce encounter ecology;
* differing seeds materially vary encounter ecology;
* no forbidden/unimplemented enemy appears;
* placement restrictions remain valid;
* threat budgets remain bounded;
* the expanded roster actually appears over campaign-scale samples;
* no single basic archetype dominates ordinary campaigns absent a deliberate themed floor;
* themed floors remain internally diverse rather than repeating one encounter verbatim.

---

# 19. Protect gameplay guarantees

Preserve:

* maze solvability;
* progression ordering;
* objective accessibility;
* keycard/gate logic;
* Warden progression;
* damsel/cash progression;
* loot/resource viability;
* multiplayer state isolation;
* enemy faction unity;
* lives/respawn behavior;
* equipment and class authorities;
* status systems;
* deterministic campaign structure;
* active-hostile performance ceilings.

Do not destabilize unrelated completed systems merely to create novelty.

---

# 20. Canonicalize the resulting ecology

Update the relevant live GDD sections after implementation.

Document:

* final roster/families;
* important variants;
* tactical roles;
* thematic/ecological logic;
* procedural floor-theme system;
* encounter-selection hierarchy;
* novelty/repetition suppression;
* campaign coverage philosophy;
* deterministic behavior;
* important tuning constants;
* diagnostics and validation expectations.

The GDD should describe the **implemented system**, not speculative discarded concepts.

---

# 21. Definition of done

This checkpoint is complete when:

1. The gameplay-meaningful normal bestiary is approximately **3.5× the baseline roster discovered at checkpoint start**.
2. New enemies reuse existing visual assets while presenting distinct, learnable tactical identities.
3. The expanded roster demonstrably exercises substantially more of the existing combat/status/movement/design landscape.
4. The Encounter Director has been upgraded from basic weighted composition toward a campaign-aware procedural ecology.
5. Levels can acquire recognizable but nondeterministic enemy themes.
6. Recent encounter/enemy history actively suppresses repetition.
7. Maze topology materially informs enemy placement.
8. Generated encounters exhibit coherent tactical syntax rather than random mixtures.
9. Campaign-scale automated sampling demonstrates strong roster coverage and substantially reduced repetition.
10. Existing deterministic, progression, multiplayer, and performance guarantees remain intact.
11. Relevant automated suites pass.
12. The live GDD and development checkpoint documentation accurately describe the implemented design.
13. The work is committed.
14. Remote `main` is verified to contain the resulting commit.

## Guiding principle

**Emergent gameplay is the highest-order design criterion.**

Do not merely create more monsters.

Create a sufficiently rich **procedural ecology** that the same maze-generation framework can produce radically different tactical stories from run to run—while remaining legible enough that those stories feel authored rather than arbitrary.

The ideal outcome is not that players say:

> “There are lots of enemy types.”

It is that after hundreds of encounters they can still say:

> “I have never had a run quite like that one.”
