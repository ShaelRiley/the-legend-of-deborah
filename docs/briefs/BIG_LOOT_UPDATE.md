Resume development of **The Legend of Deborah** from current GitHub `main` and complete the next major bounded development gate: **THE BIG LOOT UPDATE — Equipment Expansion + Procedural Item Ecology Overhaul**.

**Repository:** `ShaelRiley/the-legend-of-deborah`

**Live GDD:** Google Doc ID `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`

## Authorization

You have high-level game-design and implementation authority for this checkpoint.

You are authorized to:

* inspect and modify equipment, inventory, item generation, loot generation, weapons, wearables, consumables, item effects, stats, tags, affinities, statuses, procedural generation, pickup/drop logic, reward placement, UI/UX, presentation, naming, lore, economy, sell/fuse systems, player progression interactions, testing, documentation, and supporting architecture;
* make reasonable game-design, tuning, naming, balance, and implementation decisions without stopping for routine approval;
* create procedurally recolored, rescaled, recontextualized, or otherwise procedurally revisualized equipment and item variants using **only assets already available to the project/base game or already lawfully bundled with the project**;
* recombine existing combat mechanics, statuses, elemental systems, equipment authorities, abilities, projectiles, defenses, movement systems, resources, currencies, class mechanics, affix/tag systems, interaction systems, and procedural systems in novel ways;
* introduce new equipment effects and item mechanics where they can be implemented cleanly through existing authoritative systems;
* refactor existing equipment, inventory, loot, item-definition, procedural-item, sell/fuse, and reward architecture where this materially improves maintainability, determinism, variety, legibility, multiplayer safety, or emergent gameplay;
* amend the live GDD wherever substantive design decisions become canonical;
* add or revise automated tests, sampling tools, validation suites, and developer diagnostics;
* use focused parallel delegation where useful;
* commit and push the completed bounded checkpoint directly to `main` after validation.

Resolve ordinary ambiguities yourself.

Prefer decisive implementation over extended speculative design discussion.

**Do not deploy to the VPS or publish to Steam Workshop.**

Never force-push, rewrite public history, overwrite newer remote work, expose secrets, or discard intervening changes.

---

# 1. Recover efficiently

Before editing:

1. Verify current remote `main` and preserve any intervening work.
2. Read `AGENTS.md`.
3. Read the newest checkpoint in `docs/DEVELOPMENT_PLAN.md`.
4. Inspect the **actual currently implemented item and equipment landscape**, including:

   * equipment slots;
   * procedural equipment generation;
   * weapons;
   * wearables;
   * shields;
   * rings;
   * gloves;
   * head/body/legs/feet items;
   * consumables;
   * throwable/potion behavior;
   * handcrafted or named special items;
   * item tags/affixes;
   * elemental/status interactions;
   * item-value calculations;
   * inventory capacity;
   * equipment UI;
   * Character Sheet interactions where relevant;
   * pickup/drop authorities;
   * individualized loot;
   * static loot;
   * enemy drops;
   * reward branches;
   * DFT/$DEB interactions;
   * Debbie Statue sell/fuse behavior;
   * item-based environmental interactions such as value-gated or equipment-sensitive obstacles;
   * persistence across death, level transitions, disconnect/reconnect, and late joins.
5. Inspect the current LootDirector or equivalent authorities and all relevant automated tests.
6. Consult the relevant **live GDD** sections before making canonical design decisions. Treat the current repository and live GDD as authoritative over older prompts, snapshots, obsolete item lists, or prior assumptions.
7. Preserve completed work. Do not redo recent equipment checkpoints merely to reorganize them.
8. Establish the actual baseline number of presently implemented, gameplay-meaningful item/equipment identities before calculating the expansion target.

Produce a compact internal taxonomy of the existing item landscape before designing additions.

---

# 2. Expand meaningful equipment and item variety by 250%

For this checkpoint, **“expand Big Loot by 250%” means increase the present gameplay-meaningful authored item/equipment vocabulary to approximately 3.5× its baseline size**.

If, for example, the repository presently contains 20 mechanically meaningful item identities or effect-bearing bases, target approximately 70 after this pass.

Use sound judgment when establishing the baseline.

## What counts

A new item, equipment identity, item family member, or stable procedural archetype counts when a player can reasonably perceive it as creating a **meaningfully different decision** because it changes one or more dimensions such as:

* offensive behavior;
* defensive behavior;
* movement;
* resource economy;
* spellcasting;
* status application;
* status resistance;
* elemental interaction;
* attack form;
* targeting;
* positioning;
* risk/reward;
* healing;
* recovery;
* inventory management;
* item value;
* class interaction;
* team interaction;
* exploration;
* loot acquisition;
* equipment synergy;
* drawback;
* conditional power;
* death/life behavior;
* fuse/sell decision;
* environmental interaction;
* tactical utility.

## What does not count

Do **not** inflate the target with:

* pure recolors;
* cosmetic-only model swaps;
* trivial rarity labels;
* statistically indistinguishable duplicates;
* ordinary random numerical rolls;
* the same item with +1%, +2%, +3% values;
* permutations generated automatically from identical mechanics;
* renamed copies;
* every possible affix combination;
* every possible procedural color combination.

Procedural variation is welcome, but the 3.5× target concerns the game's **meaningful design vocabulary**, not its combinatorial SKU count.

Visual differentiation may use existing models, procedural recoloring, scale variation where collision permits, item tint regions, existing particles, materials, effects, icons, sounds, labels, attachments, or combinations thereof.

**Introduce no unnecessary external visual dependencies.**

---

# 3. Design loot as an ecology, not a spreadsheet

Approach equipment and items as artifacts of the recursive prison rather than as a flat catalog of bonuses.

The labyrinth should appear to manufacture, corrupt, salvage, combine, repurpose, or accumulate equipment according to some strange internal logic.

Ask questions such as:

* What weapons would emerge from a prison built from shipping containers, Combine remnants, scavenged human technology, anomalous magic, and repeated reconstruction?
* What equipment would survivors improvise after hundreds of recursive expeditions?
* What would a magical corruption do to an otherwise ordinary firearm, glove, boot, shield, ring, helmet, or piece of armor?
* Which items might have been left by previous heroes?
* Which objects feel like Warden equipment repurposed by players?
* Which equipment would naturally belong to scavengers, soldiers, occultists, prisoners, couriers, miners, medics, guards, hunters, thieves, or failed rescuers?
* What might a damaged, unstable, overcharged, parasitic, blessed, cursed, jury-rigged, veteran, counterfeit, prototype, ceremonial, or fused version of an item do?
* Which existing mechanics are presently underexploited by equipment?
* Which statuses, elemental interactions, spell forms, movement mechanics, class features, melee systems, projectile behaviors, defenses, resource systems, death rules, or environmental interactions could support equipment niches that currently do not exist?

Names, models, tinting, particles, descriptions, and behavior should communicate enough that players gradually learn the material culture of the labyrinth without requiring exposition.

Favor **systemic combinations** over bespoke one-off scripting.

A good new item should create new decisions with surprisingly little unique code.

---

# 4. Fill mechanical niches opportunistically

First inspect the actual current catalog and construct a compact internal matrix of existing equipment roles.

Then identify missing or underrepresented niches.

Potential niches include—but are not limited to:

* high-risk/high-output weaponry;
* low-damage utility weaponry;
* precision equipment;
* crowd-control equipment;
* status-specialist equipment;
* elemental-specialist equipment;
* mobility gear;
* jump/fall equipment;
* positioning tools;
* melee-enhancing gear;
* ranged-enhancing gear;
* magic-enhancing gear;
* defensive shields;
* reactive defenses;
* conditional armor;
* glass-cannon equipment;
* health-for-power exchanges;
* ammunition-economy equipment;
* consumable amplification;
* throwable amplification;
* potion interactions;
* low-health equipment;
* full-health equipment;
* kill-trigger equipment;
* hit-trigger equipment;
* dodge/movement-trigger equipment;
* back-attack interactions;
* block interactions;
* critical or precision interactions where supported;
* status resistance;
* status conversion;
* status retaliation;
* elemental resistance;
* elemental conversion;
* element-combination equipment;
* equipment that rewards changing weapons;
* equipment that rewards commitment to one weapon;
* exploration gear;
* reward-branch gear;
* treasure-finding or loot-modifying effects, if safely bounded;
* teammate-support equipment;
* solo-survivor equipment;
* resurrection/life interactions;
* anti-boss equipment that remains useful outside bosses;
* class-synergy items that do not become mandatory;
* unusual rings;
* unusual gloves;
* unusual footwear;
* unusual headgear;
* unusual body armor;
* unusual legwear;
* unusual shields;
* unusual consumables;
* anomalous utility items;
* items with meaningful drawbacks;
* items that alter established mechanics rather than merely increasing numbers.

Do not mechanically implement every idea merely because it appears above.

Use the actual game systems to select the strongest, clearest, most maintainable possibilities.

Prefer equipment whose existence creates **new builds, combinations, tactics, and decisions**.

---

# 5. Preserve readable itemization

Variety must not become loot sludge.

Every mechanically significant item should retain:

* a recognizable presentation using available assets;
* a concise, intelligible name;
* a clear slot/category;
* understandable mechanical effects;
* readable positive and negative modifiers;
* consistent terminology;
* sane collision/world presentation;
* multiplayer-safe server-authoritative behavior;
* reliable persistence;
* reasonable network/performance cost;
* a defensible rarity/value;
* a clear reason why a player might equip, carry, sell, fuse, consume, or discard it.

The player should be able to understand what an item is **before needing a spreadsheet**.

Avoid effects whose meaningful behavior is invisible until an obscure circumstance occurs.

Avoid excessive immunity.

Avoid items that completely invalidate entire enemy families, classes, spells, weapons, or other equipment categories.

Prefer:

* resistance;
* conditional mitigation;
* altered behavior;
* tradeoffs;
* synergies;
* soft counters;
* positional advantages;
* resource exchanges;

over absolute negation.

No individual item should become a mathematically mandatory choice for a class or slot.

Powerful items may be powerful; they should achieve that through **identity**, not merely inflated universal numbers.

---

# 6. Build equipment families where appropriate

Some existing and new items should belong to recognizable **families**.

A family may share:

* base model;
* visual language;
* manufacturing origin;
* mechanical motif;
* elemental theme;
* status theme;
* risk/reward logic;
* slot-spanning synergy;
* provenance or lore;
* procedural generation vocabulary.

For example, one equipment family might plausibly contain:

* a weapon;
* gloves;
* boots;
* a ring;
* armor;
* a consumable;

that independently function but share a mechanical philosophy.

Another family might remain entirely within one equipment category.

Do not mechanically turn the game into a conventional MMO set-bonus system unless the existing architecture naturally supports a particularly elegant version.

Explicit multi-piece synergies may be used sparingly where they create interesting decisions, but ordinary items should remain useful without completing a set.

Some items should remain singular and strange.

Mechanically meaningful item identities should have stable names or stable archetype identities so players can learn and discuss them.

Pure cosmetic procedural variation may exist within those identities.

---

# 7. Overhaul the Loot Director after the catalog expansion

Once the enlarged item vocabulary exists, substantially upgrade item selection, placement, rewards, and procedural loot composition.

The principal objective is:

> **Maximize emergent buildcraft and discovery while minimizing perceived loot repetition and worthless clutter.**

Do not solve variety by placing every item into one global weighted table.

Do not create a shower of interchangeable junk.

Instead create a layered **procedural loot ecology**.

The Loot Director should reason about:

* campaign level;
* sector;
* encounter difficulty;
* branch risk;
* objective significance;
* player class;
* player equipment;
* owned item categories;
* inventory capacity;
* current health/resources;
* recent loot history;
* recent slot history;
* item-family history;
* item rarity;
* item value;
* progression state;
* existing build direction;
* player need;
* novelty;
* duplicate usefulness;
* multiplayer individualized state;
* deterministic seed state.

Context should influence probability without collapsing procedural surprise into deterministic “smart loot.”

---

# 8. Introduce procedural loot identities

Each generated level, sector, reward branch, treasure cache, or other substantial reward context should be capable of acquiring one or more **loot motifs**.

Examples of possible motif dimensions include:

* scavenged;
* military;
* medical;
* occult;
* elemental;
* industrial;
* improvised;
* defensive;
* mobility-heavy;
* ranged;
* melee;
* arcane;
* consumable-rich;
* armor-rich;
* weapon-rich;
* anomalous;
* unstable;
* high-risk/high-value;
* poverty/scarcity;
* abandoned stockpile;
* elite cache;
* Warden-derived;
* failed-expedition relics;
* unusually mundane;
* unusually strange.

These are **procedural grammars**, not fixed authored levels.

A loot motif may influence:

* item-family prevalence;
* slot prevalence;
* mechanical tags;
* rarity distribution;
* effect-package availability;
* procedural visual treatment;
* cache composition;
* reward-branch identity;
* sell value;
* fuse attractiveness;
* consumable frequency;
* weapon/equipment ratio;
* curated anomalies.

Motifs should be recognizable in retrospect without becoming deterministic.

A player might later remember:

> “That was the run where I kept finding all that weird mobility gear.”

or:

> “That floor was basically an abandoned armory.”

Another campaign should tell different stories.

---

# 9. Use weighted exclusion, memory, and novelty pressure

The Loot Director should explicitly reason about recent item history.

Implement or improve mechanisms such as:

* recent-item suppression;
* recent-family suppression;
* recent-slot suppression;
* recent-effect suppression;
* recent-motif suppression;
* novelty bonuses;
* duplicate penalties;
* duplicate conversion where appropriate;
* recurrence cooldowns;
* campaign-level appearance accounting;
* controlled rare-item scheduling;
* anti-streak logic;
* item-diversity scoring;
* family-diversity scoring;
* build-aware weighting that avoids simply handing the player exactly what they already use.

A player should not repeatedly find essentially the same boots, ring, firearm, shield, or effect package merely because its base weight is high.

Randomness should possess **memory**.

That memory must remain deterministic under equivalent seed/state conditions.

---

# 10. Balance novelty against catalog visibility

We want meaningful variety without creating an enormous catalog that players never actually encounter.

Across a substantial campaign:

* most common item families should appear;
* most uncommon families should receive reasonable exposure;
* rare, exceptional, or exotic items may remain genuinely rare;
* one level need not expose anything close to the full catalog;
* consecutive levels should often produce meaningfully different reward stories;
* item families absent for several levels may gain controlled reappearance pressure;
* some generated levels may deliberately omit common categories;
* different players in multiplayer may legitimately develop very different equipment stories.

Think in terms of **campaign-level exposure**, not universal per-level coverage.

Rare items should be rare because their appearance is exciting, not because broken weighting makes them effectively nonexistent.

Common items should be common without becoming visual or mechanical wallpaper.

---

# 11. Loot should have mechanical syntax

Equipment should create a combinatorial language.

Items should interact intelligibly with:

* other equipped items;
* weapons;
* spell forms;
* statuses;
* elements;
* class abilities;
* movement;
* blocking;
* back attacks;
* consumables;
* health state;
* ammunition state;
* enemy behaviors;
* teammate actions;
* exploration decisions.

Examples of useful mechanical syntax:

* one item applies a condition and another exploits it;
* boots create positional opportunities that gloves reward;
* a shield enables a counterattack style;
* a weapon becomes powerful when paired with a resource-management item;
* armor encourages fighting at a specific range;
* a ring alters how a spell form behaves;
* a consumable temporarily changes an equipment interaction;
* one item rewards rapidly changing tactics;
* another rewards deliberate specialization;
* powerful benefits carry interesting drawbacks;
* an item useful alone becomes surprising in combination with another system.

Avoid building hundreds of microscopic additive bonuses.

Prefer **interaction effects** over spreadsheet accretion.

Those interactions are where emergent buildcraft lives.

---

# 12. Exploit maze, encounter, and progression context

Loot generation and placement must reason about the actual generated game context.

Where practical, consider information such as:

* sector;
* graph distance;
* dead ends;
* loops;
* vertical branches;
* optional reward branches;
* chokepoints;
* arenas;
* objective rooms;
* recent encounters;
* upcoming encounters;
* boss proximity;
* route risk;
* expected backtracking;
* checkpoint distance;
* environmental hazards;
* blockade/bribe opportunities;
* treasure-room context;
* current progression stage.

Then prefer rewards whose placement feels authored.

Examples:

* mobility equipment belongs naturally in difficult optional vertical branches;
* unusually valuable items justify high-risk detours;
* a pre-boss cache should be useful without trivializing the Warden;
* equipment that helps with a tactical pressure may appear before or after that pressure according to intentional pacing;
* weird specialist gear belongs more naturally in optional treasure branches than as constant mandatory-route clutter;
* recovery resources should remain distinguishable from build-defining treasure;
* major exploration achievements should have a meaningful chance to yield equipment worth considering.

Do not place an item merely because an empty spawn point exists.

---

# 13. Create reward pacing, not uniform loot rain

Runs should breathe economically as well as tactically.

The director should be able to produce:

* modest sustain;
* ordinary scavenging;
* anticipatory supplies;
* post-fight recovery;
* small surprises;
* rare jackpot moments;
* dangerous optional treasure;
* unusually sparse stretches;
* major objective rewards;
* curated special-item opportunities;
* occasional equipment-rich sectors;
* occasional consumable-rich sectors;
* occasional scarcity.

Avoid metronomic reward spacing.

Avoid giving every fight an equally interesting prize.

Avoid drowning the player in constant inventory decisions.

Reward intensity should form procedural **phrases**.

An empty corridor can make the next strange object more interesting.

A difficult optional branch should sometimes produce a reward memorable enough to justify the risk.

---

# 14. Preserve determinism and server authority

All new item selection, item generation, effect packages, affixes, rarity, motifs, cache composition, drop decisions, sell/fuse outcomes, and progression-sensitive equipment behavior must remain compatible with the game's deterministic campaign/level-seed architecture where applicable.

Given equivalent game version, campaign seed, relevant player identity, and relevant gameplay state, loot outcomes should remain reproducible enough for debugging.

Maintain server authority for:

* item generation;
* procedural stats/effects;
* item identity;
* ownership;
* pickup eligibility;
* inventory state;
* equipped state;
* mechanical effects;
* drops;
* consumption;
* destruction;
* selling;
* fusion;
* currency awards;
* persistence;
* progression-relevant item interactions.

Do not introduce client-trusting inventory or equipment logic.

Never allow drag/drop UI state alone to become gameplay authority.

All value-sensitive transactions must remain atomic and server-authoritative.

---

# 15. Respect performance, networking, and inventory ceilings

Variety must not come from uncontrolled entity proliferation, networking spam, or enormous replicated tables.

Prefer:

* data-driven definitions;
* shared effect authorities;
* compact network state;
* deterministic regeneration of presentational data;
* lazy world entity creation where appropriate;
* existing pickup authorities;
* pooled/shared code paths;
* bounded inventories;
* stable identifiers;

over bespoke Think loops or hundreds of independent scripted systems.

Do not materially worsen multiplayer bandwidth or server frame time merely to produce more loot.

Where many item identities can share one implementation with data-driven configuration, prefer that architecture.

World items should clean up correctly with level teardown and campaign reset.

---

# 16. Refactor toward data-driven item definitions

If the present architecture would otherwise require large amounts of duplicated item code, introduce or improve a centralized item-definition/family/effect system.

Item definitions should be able to express, where appropriate:

* stable ID;
* display name;
* family;
* category;
* equipment slot;
* base model;
* visual treatment;
* procedural tint regions;
* rarity;
* value;
* sell behavior;
* fuse behavior;
* mechanical tags;
* effect packages;
* stat modifiers;
* conditional modifiers;
* drawbacks;
* class affinities;
* weapon affinities;
* elemental interactions;
* status interactions;
* movement interactions;
* combat triggers;
* defensive triggers;
* resource interactions;
* stacking/exclusivity rules;
* campaign introduction weighting;
* level weighting;
* loot motif affinities;
* topology/context affinities;
* incompatibilities;
* synergies;
* drop eligibility;
* reward-branch eligibility;
* unique/rare restrictions;
* duplicate handling;
* presentation text;
* diagnostic metadata.

Do not overengineer abstractions that the current codebase does not need.

The objective is a robust vocabulary from which the procedural systems can create equipment stories—not an enterprise inventory framework.

Prefer composable effect packages where several items can safely reuse established mechanics.

---

# 17. Add loot and equipment diagnostics

Provide developer-visible diagnostics sufficient to understand generated itemization.

At minimum, make it possible to inspect or log useful information about a generated level/campaign such as:

* chosen loot motif(s);
* eligible item families;
* generated static loot;
* reward-branch rewards;
* notable enemy-drop results in aggregate;
* slot distribution;
* family distribution;
* rarity distribution;
* item-value distribution;
* duplicate suppression;
* novelty decisions;
* pity/support decisions;
* special/rare item appearances;
* equipment-generation seeds or stable identifiers where useful;
* sell/fuse results where relevant;
* per-player individualized loot divergence;
* resource-economy interaction.

Prefer concise structured summaries over noisy per-item logging.

Extend existing debug tooling where appropriate rather than creating redundant systems.

A developer should be able to answer:

> “Why did this campaign keep producing this category?”

without reverse-engineering the RNG manually.

---

# 18. Validate item diversity quantitatively

Add automated validation around the enlarged item system and upgraded Loot Director.

Use a large deterministic seed/campaign sample sufficient to expose systemic repetition, broken rarity, runaway power, unreachable items, and distribution pathologies.

Measure useful indicators such as:

* family appearance frequency;
* named/mechanical item appearance frequency;
* slot distribution;
* rarity distribution;
* value distribution;
* consecutive duplicate rate;
* near-duplicate rate;
* consecutive-level overlap;
* motif distribution;
* campaign catalog coverage;
* rare-item frequency;
* build-category coverage;
* reward-branch quality;
* static-loot composition;
* individualized multiplayer divergence;
* inventory-cap compliance;
* deterministic reproducibility;
* progression-band compliance;
* sell/fuse sanity;
* resource-economy bounds.

Do not mechanically optimize for a single diversity metric.

Use metrics to detect obvious pathologies.

Include automated tests proving, where applicable:

* identical seeds and relevant state reproduce equivalent loot ecology;
* differing seeds materially vary loot ecology;
* no undefined item ID can be generated;
* no item can equip into an illegal slot;
* mechanical effects correspond to the authoritative equipped state;
* unequipping removes effects correctly;
* death/respawn does not duplicate or erase persistent equipment incorrectly;
* disconnect/reconnect cannot duplicate, reroll, or restore spent items;
* late joins receive only intended equipment/resource treatment;
* individualized drops cannot be stolen by another player;
* inventory capacity is mechanically authoritative and matches the UI;
* sell operations are atomic;
* fuse operations are atomic;
* failed transactions cannot consume the source item without granting the result;
* destroyed/trash items cannot reappear through stale state;
* duplicate suppression does not make common essentials inaccessible;
* rare items actually occur over sufficiently large campaign samples;
* no ordinary family dominates campaigns absent deliberate motif weighting;
* the expanded meaningful catalog actually appears over campaign-scale samples;
* resource-support loot remains sufficient for ordinary progression;
* item-value logic remains bounded enough for item-value-dependent systems;
* no procedurally generated combination creates invalid numeric state, NaN, absurd overflow, negative capacity, impossible durability, or other malformed state.

If existing fuzz/property-style tests can efficiently exercise generated equipment combinations, extend them.

---

# 19. Protect gameplay guarantees

Preserve:

* maze solvability;
* progression ordering;
* objective accessibility;
* keycard/gate logic;
* Warden progression;
* damsel progression;
* post-Deborah cash progression;
* item-value blockade solvability;
* resource viability;
* multiplayer state isolation;
* individualized loot;
* lives/respawn behavior;
* class authorities;
* combat authorities;
* equipment-slot authorities;
* inventory-capacity authorities;
* status systems;
* elemental systems;
* spell systems;
* deterministic campaign structure;
* active-entity performance ceilings;
* sell/fuse atomicity;
* $DEB/DFT integrity;
* equipment UI correctness;
* Character Sheet correctness;
* server authority.

Do not destabilize unrelated completed systems merely to create novelty.

Do not permit procedural equipment to generate an unsolvable progression dependency.

Do not let a rare item become necessary for ordinary progression.

Do not silently invalidate existing named special items; integrate them into the new vocabulary with deliberate rarity and role.

---

# 20. Canonicalize the resulting item ecology

After implementation, update the relevant live GDD sections.

Document the **implemented** system, including:

* final equipment/item taxonomy;
* meaningful families;
* important named items;
* stable procedural archetypes;
* effect-package architecture;
* slot philosophy;
* loot motifs;
* Loot Director selection hierarchy;
* novelty/repetition suppression;
* campaign exposure philosophy;
* reward pacing;
* contextual/topological placement;
* deterministic behavior;
* individualized multiplayer behavior;
* rarity philosophy;
* item-value philosophy;
* sell/fuse integration;
* important tuning constants;
* diagnostics;
* quantitative validation expectations.

Amend the live document surgically.

Preserve useful existing material and supersede obsolete rules explicitly where necessary.

Do not fill the GDD with every discarded brainstorm.

The GDD should describe the **system that actually ships after this checkpoint**.

Also update `docs/DEVELOPMENT_PLAN.md` with a durable checkpoint recording:

* baseline discovered;
* meaningful-catalog expansion achieved;
* architectural changes;
* test coverage;
* validation results;
* known limitations;
* deferred work;
* final commit.

---

# 21. Definition of done

This checkpoint is complete when:

1. The gameplay-meaningful equipment/item vocabulary is approximately **3.5× the baseline discovered at checkpoint start**, without counting trivial cosmetic/statistical permutations.
2. New items reuse existing available visual resources while presenting distinct, learnable mechanical identities.
3. Every major equipment slot has substantially richer meaningful choice unless a deliberate design reason argues otherwise.
4. The enlarged catalog exercises substantially more of the game's combat, status, elemental, movement, resource, class, exploration, and progression landscape.
5. Items form useful families and systemic relationships rather than existing as isolated stat sticks.
6. The Loot Director has advanced from ordinary weighted drops toward a **campaign-aware procedural loot ecology**.
7. Generated levels/sectors/reward contexts can acquire recognizable but nondeterministic loot motifs.
8. Recent item/family/slot/effect history actively suppresses monotonous repetition.
9. Maze topology, encounter context, risk, objectives, and progression materially inform important reward placement.
10. Equipment combinations create emergent buildcraft without producing obvious mandatory universal best-in-slot choices.
11. Loot remains legible; inventory management does not devolve into undifferentiated junk processing.
12. Sell, fuse, destroy, pickup, equip, unequip, persistence, death, reconnect, and individualized ownership authorities remain correct.
13. Campaign-scale automated sampling demonstrates strong meaningful-catalog exposure, sensible rarity, bounded value, and substantially reduced repetition.
14. Existing deterministic, progression, multiplayer, combat, economy, and performance guarantees remain intact.
15. Relevant automated suites pass.
16. Run any additional focused validation needed for touched systems.
17. The live GDD accurately describes the implemented item ecology.
18. `docs/DEVELOPMENT_PLAN.md` contains a durable checkpoint.
19. Working tree is clean except for intentionally excluded local material.
20. The work is committed with a clear commit message.
21. Push non-forced to `main`.
22. Fetch/verify the remote afterward and report the verified remote HEAD containing the completed checkpoint.

If an existing unrelated test is already known to fail, distinguish it clearly from regressions introduced by this work and do not conceal it.

Do not deploy to the VPS.

Do not publish to Steam Workshop.

---

# Guiding principle

**Emergent buildcraft is the highest-order item-design criterion.**

Do not merely create more loot.

Create a sufficiently rich **procedural material culture** that the same combat, class, maze, and progression framework can produce radically different equipment stories from campaign to campaign—while remaining legible enough that those stories feel designed rather than arbitrary.

The ideal outcome is not that players say:

> “There are lots of items.”

It is that after hundreds of drops they can still say:

> “I have never built a character quite like that before.”

And when a strange object appears on the floor, the player should still want to walk over and see what it is.
