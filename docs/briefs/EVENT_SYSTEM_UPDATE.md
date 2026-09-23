Resume development of **The Legend of Deborah** from current GitHub `main` and complete the next major bounded development gate: a comprehensive **Dungeon Event Systems Expansion + Procedural Event Ecology Overhaul**.

**Repository:** `ShaelRiley/the-legend-of-deborah`

**Last verified remote HEAD at prompt construction:**
`290668078f26f13276e1af05b4ab675de8ddb165`
Commit: `Add progression-safe permanent paired warp-hole shortcuts`

Verify current remote `main` before editing and preserve any intervening work.

The existing Dungeon Event architecture is already live and production-populated. At the last verified checkpoint, known implemented production archetypes include Debbie Slots, Locked Loot Chest, Debbie Vending, rare DFT Treasure, False-floor, and permanent paired Warp-hole, organized through the existing `EventRegistry` / `EventDirector` architecture and the `REWARD`, `BLOCKADE`, `HAZARD`, and `UTILITY` placement contracts.

Treat that list as orientation only. **The repository and live GDD are authoritative. Re-establish the actual current baseline before calculating expansion targets.**

---

# Authorization

You have high-level game-design, systems-design, implementation, tuning, naming, UX, presentation, testing, documentation, and architecture authority for this checkpoint.

You are authorized to:

* inspect and modify dungeon-event systems, event selection, event placement, event lifecycle, interaction logic, economy interactions, equipment interactions, RPG/stat/status interactions, traversal utilities, hazards, blockades, NPC events, minigames, rewards, presentation, procedural generation, diagnostics, tests, and supporting shared architecture;
* make reasonable game-mechanics and tuning decisions without stopping for routine approval;
* create procedurally recolored, rescaled, recontextualized, recombined, or otherwise procedurally revisualized event props and NPC presentations using **only assets already available to the project/base game**;
* recombine existing mechanics, items, equipment, stats, statuses, elements, spells, movement authorities, economy systems, loot systems, combat systems, dialogue systems, dice systems, AI primitives, props, particles, sounds, models, and procedural systems in novel ways;
* implement new event families and individual event identities where they create genuinely distinct player decisions;
* refactor `EventRegistry`, `EventDirector`, event definitions, placement contracts, lifecycle architecture, or supporting authorities where this materially improves maintainability, determinism, transactional safety, variety, or emergent gameplay;
* integrate events with existing floor/encounter themes where such systems are present, rather than creating redundant competing procedural authorities;
* amend the live GDD wherever substantive design decisions created under this authorization become canonical;
* add or revise automated tests, deterministic sampling tools, developer previews, structured diagnostics, and validation harnesses;
* use focused parallel delegation where it accelerates independent inspection, implementation, review, or testing;
* commit and non-force-push the completed bounded checkpoint directly to `main` after validation.

Resolve ordinary ambiguities yourself.

Do not stop for routine mechanical, tuning, naming, architectural, or presentation approval.

**Do not deploy to the VPS or publish to Steam Workshop.**

Never force-push, overwrite newer remote work, expose secrets, or weaken existing release-integrity safeguards.

---

# 1. Recover efficiently

Before editing:

1. Verify current remote `main`.
2. Read `AGENTS.md`.
3. Read the newest checkpoint in `docs/DEVELOPMENT_PLAN.md`.
4. Follow the mandatory low-compute live-GDD path:

   * `00 — AI ENTRYPOINT`
   * `01 — AI RULE INDEX`
   * only the relevant subsystem tabs, expected primarily to include:

     * `05 — CORE LOOP & WORLD`
     * `06 — MULTIPLAYER, LIFECYCLE & UI`
     * `07 — IMPLEMENTATION & TUNING`
     * `90 — DEFERRED / FUTURE`
   * consult `HUMAN — Complete GDD` only for an exact anchor or authored detail explicitly left as HUMAN-DETAIL.
5. Inspect the **current implemented Dungeon Event catalog**, `EventRegistry`, `EventDirector`, placement contracts, event entity/client presentation, economy transaction authorities, equipment authorities, SafeTeleport/movement authorities, progression validation, encounter integration, deterministic RNG architecture, lifecycle/snapshot logic, preview tooling, and relevant automated tests.
6. Treat current repository implementation and live GDD as authoritative over older prompts, historical event concepts, obsolete Hut/Event-stage designs, or remembered proposals.
7. Preserve completed work. Do not repeat broad audits already completed by recent checkpoints.

Establish the actual number of presently implemented, gameplay-meaningful production event archetypes before calculating the expansion target.

Also establish the current division among:

* `REWARD`;
* `BLOCKADE`;
* `HAZARD`;
* `UTILITY`;
* common versus rare events;
* personal versus party-shared outcomes;
* persistent versus dungeon-local consequences;
* automatic versus interacted events;
* topology-affecting versus topology-neutral events.

Do not infer these from historical documentation when the current code can answer them.

---

# 2. Expand the meaningful event catalog by approximately 250%

For this checkpoint, **“expand the Dungeon Event System by 250%” means increase the current gameplay-meaningful production event catalog to approximately 3.5× its baseline size**.

At the last verified checkpoint, six production archetypes were known. If the actual baseline remains six when this work begins, target approximately **21 gameplay-meaningful production event archetypes** after this pass.

If the baseline has changed, calculate the target from the newly discovered baseline instead.

Do **not** inflate the count with cosmetic reskins, trivial numerical variants, or several names for effectively identical interactions.

An event or stable event variant counts toward the target only when a player can reasonably perceive it as a distinct procedural situation because it changes one or more meaningful dimensions such as:

* choice structure;
* resource cost;
* reward structure;
* risk;
* topology;
* movement;
* timing;
* required observation;
* skill/stat relevance;
* inventory interaction;
* equipment interaction;
* economy interaction;
* status interaction;
* combat interaction;
* player cooperation;
* information;
* traversal;
* hazard avoidance;
* puzzle/minigame logic;
* NPC interaction;
* negotiation;
* gambling;
* temporary opportunity;
* permanent dungeon-local state;
* route planning;
* resource conservation;
* tactical positioning;
* party coordination;
* reward ownership;
* environmental interpretation.

Visual differentiation may use procedural recoloring, model selection, scale, materials, existing particles, existing effects, existing sounds, existing NPCs, existing props, lighting, signage, or combinations thereof.

**Introduce no required new external visual or audio assets.**

Reuse the existing design landscape aggressively.

---

# 3. Design events as manifestations of the recursive prison

Do not approach the update as a spreadsheet of unrelated interactables.

Events should feel like strange but coherent manifestations of Deborah's recursive prison: improvised machinery, opportunists, anomalies, traps, scavenged commerce, inexplicable game-show logic, broken infrastructure, occult-seeming mechanisms, prisoners, custodians, malfunctioning systems, hidden caches, and absurd bureaucratic obstacles treated with a straight face.

Ask questions such as:

* What would scavengers or prisoners build inside this place?
* What services might someone plausibly sell to passing Heroes?
* What malfunctioning prison machinery could become useful or dangerous?
* What kind of obstacle would demand payment, equipment, observation, timing, or nerve instead of bullets?
* What strange rules might the recursive prison impose on one room?
* What does a prosperous floor look like compared with a depleted one?
* What would inhabit or operate an optional side chamber?
* What kind of event becomes interesting only because equipment, status, Magic, $DEB, DFTs, statistics, lives, movement, or topology already exist?
* Which existing systems remain underexploited outside combat?
* What event could create a memorable story with surprisingly little bespoke code?

Names, silhouettes, prompts, props, sounds, and interaction feedback should communicate enough that players gradually learn the procedural vocabulary without requiring exposition.

Favor **systemic recombination** over elaborate one-off scripting.

A good new event should produce a new decision while borrowing as much trustworthy machinery as practical.

---

# 4. Fill event niches opportunistically

First construct a compact internal matrix of the actual current event catalog and the systems each event exercises.

Then identify missing or underrepresented niches.

Potential niches include—but are not limited to:

* ordinary reward/cache;
* locked reward;
* unusual treasure;
* shop/vendor;
* healing or restorative service;
* equipment service;
* information service;
* gambling;
* wager/risk event;
* item-value bribe or toll;
* inventory sacrifice;
* optional status tradeoff;
* blessing/curse risk-reward;
* temporary buff opportunity;
* temporary debuff-for-reward;
* stat/ability interaction;
* class-favored interaction without class exclusivity;
* environmental trap;
* triggered hazard;
* timing hazard;
* moving hazard;
* deceptive but avoidable hazard;
* traversal shortcut;
* paired relocation;
* alternate-route utility;
* secret/reveal event;
* route-information event;
* puzzle;
* compact minigame;
* Game Master-style challenge;
* NPC dialogue encounter;
* service NPC;
* strange prisoner;
* Hector or another established authored NPC where current GDD supports it;
* blockade;
* skeleton/barricade-style obstruction;
* resource sink;
* resource conversion;
* optional combat challenge;
* event-triggered encounter;
* safe/recovery opportunity;
* cooperative interaction;
* solo-scaled interaction;
* party-shared decision;
* per-Hero opportunity;
* one-shot dungeon-local event;
* repeatable utility;
* persistent-account reward;
* event whose value depends strongly on another system;
* event whose meaning changes with campaign depth;
* event that becomes more attractive under scarcity;
* event that becomes more dangerous in combination with the floor's hostile ecology.

Do not mechanically implement every idea merely because it appears above.

Use the actual game systems to choose the strongest, most legible, most maintainable possibilities.

Prefer events whose existence opens **new procedural stories and new relationships between existing systems**.

---

# 5. Preserve the existing four placement contracts where possible

The current architecture recognizes:

* `REWARD`;
* `BLOCKADE`;
* `HAZARD`;
* `UTILITY`.

Treat these as valuable canonical vocabulary.

Prefer expressing new events through these contracts rather than proliferating contract types.

Add or generalize a contract only when several worthwhile events expose a real semantic gap that cannot be represented safely through the existing four. Do not invent abstractions merely for taxonomy.

Retain the current philosophical distinctions:

* optional rewards should not become hidden mandatory progression;
* utilities should remain nonblocking unless explicitly authored otherwise;
* hazards must not irreversibly strand players or break ordered progression;
* mandatory blockades must possess an independently provable resolution path;
* event placement callbacks query canonical graph state rather than becoming shadow graph-editing authorities;
* the maze/progression graph remains authoritative.

Where events require more expressive validation, extend the shared contract proofs rather than allowing individual event scripts to bypass them.

---

# 6. Preserve the exact event-count philosophy

Do not turn catalog breadth into event-density inflation.

Unless current live design explicitly supersedes it, preserve the existing **exact non-exploding 1d4 event-count model**:

* roll 1 → one event;
* roll 2 → two;
* roll 3 → three;
* roll 4 → four;
* do not truncate an unfavorable result merely because placement is inconvenient;
* do not silently substitute duplicates;
* do not reroll the count after placement failure;
* fail/retry deterministically under the established generation rules instead.

The expansion should make the **same modest number of dungeon events far more surprising**, not clutter every floor with interactables.

If rare-event semantics presently reserve the fourth slot, preserve the canonical behavior unless the larger catalog makes a well-justified GDD amendment necessary.

If rarity architecture is generalized, ensure rarity does not accidentally multiply the expected event count.

---

# 7. Build event families where appropriate

Some events should become recognizable **families** that share implementation authorities while retaining stable player-learnable identities.

A family might plausibly contain:

* a common form;
* a higher-risk form;
* a resource-specific form;
* a deeper-level form;
* an unusual or rare form.

Examples might include families of:

* caches;
* machines;
* merchants;
* blockades;
* hazards;
* anomalies;
* minigames;
* prisoners/NPCs;
* traversal devices.

Do not apply this pattern mechanically to every event.

Some events should remain singular and strange.

Mechanically meaningful variants should have stable names and learnable rules.

Pure cosmetic variation may remain procedural within those identities.

Do not count a purely cosmetic variation toward the gameplay expansion target.

---

# 8. Overhaul EventRegistry toward expressive data-driven definitions

If the enlarged catalog would otherwise require repeated boilerplate or hand-coded selection logic, extend the registry into a robust but restrained data-driven vocabulary.

Definitions should be able to express, where useful:

* stable ID;
* display name;
* family;
* contract;
* production eligibility;
* rarity;
* minimum dungeon level;
* maximum instances;
* personal versus party scope;
* claim semantics;
* repeatability;
* persistence scope;
* reward/resource type;
* cost/resource type;
* topology preference;
* progression restrictions;
* protected-cell requirements;
* optionality;
* interaction mode;
* risk class;
* event-theme affinities;
* hostile-theme affinities;
* incompatibilities;
* synergies;
* prerequisite authority;
* placement requirements;
* economic requirements;
* multiplayer requirements;
* presentation treatment;
* lifecycle behavior;
* snapshot requirements;
* developer-preview metadata.

Do not create a generic event scripting language merely because one is conceivable.

The goal is a durable vocabulary from which the procedural director can choose safely.

---

# 9. Overhaul the Event Director after catalog expansion

Once the larger event catalog exists, substantially improve event selection and placement.

The principal objective is:

> **Maximize emergent procedural stories while minimizing perceived event repetition.**

The future failure mode must not become:

> “Every dungeon has the vending machine, the chest, and one random gimmick.”

Do not solve this by throwing every event into one flat weighted table.

Create a layered procedural event ecology.

A useful conceptual hierarchy is:

**count → eligibility → family → rarity → event identity → variant → placement → settlement**

The exact implementation may differ if the current architecture suggests a cleaner solution.

---

# 10. Give dungeon levels procedural event character

Each dungeon should be capable of acquiring an event-layer **character, motif, or economy** without becoming a fixed authored level.

Possible dimensions include:

* unusually prosperous;
* depleted;
* mercantile;
* trap-heavy;
* anomaly-heavy;
* puzzle-heavy;
* obstacle-heavy;
* generous;
* predatory;
* traversal-rich;
* strange-NPC-heavy;
* high-risk/high-reward;
* suspiciously quiet;
* scarcity-driven;
* chaotic machinery;
* occult or magical contamination;
* prison-infrastructure-heavy;
* unusually little event activity punctuated by one memorable event.

These are procedural grammars, not required literal labels.

If the Bestiary/Encounter Ecology update has already introduced authoritative floor/sector themes, **integrate with those themes rather than constructing an independent competing theme engine**.

Events may:

* harmonize with a hostile theme;
* counterpoint it;
* exploit its resource pressures;
* occasionally create deliberate contrast.

For example, a punishing combat floor might plausibly contain a valuable but expensive recovery opportunity; a quiet floor might contain an ominous anomaly instead of several ordinary vendors.

Theme affinity should bias, not dictate.

---

# 11. Use weighted exclusion, campaign memory, and novelty pressure

The Event Director should explicitly reason about recent event history.

Implement mechanisms as appropriate such as:

* recent-event suppression;
* recent-family suppression;
* recent-contract suppression;
* recent-variant suppression;
* recent-theme suppression;
* novelty bonuses;
* minimum recurrence distances;
* cooldowns before signature events dominate again;
* run-level appearance accounting;
* controlled rare-event scheduling;
* anti-streak logic;
* composition-diversity scoring;
* reappearance pressure for neglected common families.

Randomness should possess **memory**.

A high-weight vendor should not appear three floors in a row merely because its base probability is high.

A signature weird event should regain its surprise value by disappearing for a while.

Preserve deterministic campaign reproducibility: campaign history used for weighting is itself authoritative deterministic state.

---

# 12. Balance novelty against event visibility

Do not create a catalog so diluted that players never learn what anything means.

Across a substantial ordinary campaign:

* most common event families should eventually appear;
* uncommon families should receive meaningful representation;
* rare events should remain meaningfully rare;
* a single dungeon should expose only a small fraction of the full catalog;
* consecutive dungeons should often feel different;
* events absent for many levels may accumulate moderate reappearance pressure;
* individual floors may deliberately omit otherwise-common families;
* signature events should recur often enough to become recognizable without becoming rote.

Think in terms of **campaign-level coverage**, not universal floor-level coverage.

A good campaign should create memories such as:

> “That was the floor where we paid that lunatic with a useless helmet because we were desperate to get through.”

or:

> “We found two good machines early, then spent five levels without seeing another one.”

or:

> “That false floor dropped us right into the part of the dungeon with the strange prisoner.”

The next campaign should tell different stories.

---

# 13. Events should possess procedural syntax

Multiple events selected for one dungeon should not feel like four unrelated entries drawn independently from a hat.

Where practical, reason about the **relationship among the selected events**.

Potential relationships include:

* resource source + resource sink;
* risk + recovery;
* hazard + valuable optional branch;
* blockade + realistically obtainable payment ecosystem;
* information + exploitable opportunity;
* merchant + scarcity;
* shortcut + dangerous optional route;
* wager + recovery;
* status risk + cure opportunity;
* strange NPC + useful service;
* challenge + reward;
* expensive utility + lucrative branch.

Avoid rigid authored combos.

Avoid hidden dependency chains.

Do not make Event A require Event B unless both are generated as one validated composite system or the required resource is independently guaranteed from ordinary reachable game state.

Interaction effects should emerge from the existing systems rather than require brittle bespoke orchestration.

---

# 14. Exploit actual maze topology

Event placement must reason about generated geometry rather than merely choosing any unreserved cell.

Where practical, classify candidate locations using information such as:

* critical versus optional route;
* dead end;
* side loop;
* corridor;
* junction;
* chokepoint;
* open cell;
* vertical level;
* vertical transition proximity;
* objective proximity;
* checkpoint proximity;
* encounter proximity;
* safe-region proximity;
* approach directions;
* retreat options;
* line of sight;
* alternate routes;
* floor identity;
* ordinary return route;
* progression-stage reachability.

Then prefer event types whose placement makes spatial sense.

Examples:

* optional treasure belongs naturally in side branches;
* vendors benefit from readable breathing space;
* blockades belong only where their resolution proof and approach economy are valid;
* hazards belong where they can be perceived, survived, and escaped;
* shortcuts matter most when they create meaningful convenience without bypassing progression;
* NPC interactions need enough physical room not to become collision nuisances;
* minigames should not occur where ordinary hostile pressure makes their interface unusable unless that pressure is deliberately part of the event;
* rewards should not occupy protected objective cells merely because they are convenient.

Do not place an event merely because a cell is technically available.

---

# 15. Treat progression solvability as inviolable

No event may break the canonical ordered progression:

* keycards;
* gates;
* Warden sequence;
* jail/rescue ordering;
* damsel/cash progression;
* required objective access;
* validated return paths;
* campaign transition.

For every `BLOCKADE`, prove that resolution is realistically available **from the earliest approachable side** without borrowing resources from behind the obstacle or behind a later progression lock.

For item-value, currency, key, equipment, stat, or other resource requirements:

* use actual available resource/equipment/economy authorities;
* prove the requirement is attainable before the event becomes mandatory;
* avoid circular dependencies;
* avoid mandatory class exclusivity;
* avoid mandatory persistent-currency expenditures without a universally viable alternative unless explicitly canonicalized;
* do not consume a unique progression-critical resource.

Optional class/stat advantages are welcome.

Mandatory progression may not depend on a randomly absent class.

For hazards and shortcuts, preserve equivalent ordered-stage reachability and ordinary legal return routes according to the established graph proofs.

---

# 16. Use the existing systems landscape aggressively

The Event Update should make more of the game matter outside ordinary enemy combat.

Look for safe opportunities to exercise systems such as:

* $DEB;
* DFTs;
* equipment;
* item value;
* wearable tags;
* consumables;
* Chest Keys;
* stats;
* class identity;
* ability checks;
* dice presentation;
* status effects;
* elemental systems;
* health;
* armor;
* ammunition;
* lives;
* movement;
* SafeTeleport;
* Magic;
* navigation;
* NPC dialogue;
* enemy encounters;
* loot generation;
* object interaction;
* map topology;
* campaign level;
* campaign history.

Do not invent parallel currencies or duplicate authorities when existing systems suffice.

A new event that needs an item transaction should use the canonical inventory transaction machinery.

A new event that needs $DEB should use the canonical persistent wallet transaction machinery.

A new event that needs relocation should use the canonical relocation/SafeTeleport authority.

A new event that starts combat should request it through the appropriate encounter/combat authority rather than spawning uncontrolled hostiles ad hoc.

A new event that applies a status should use the canonical status authority.

---

# 17. Preserve transactional and multiplayer integrity

Every new event must be designed under hostile assumptions about callbacks, reconnects, duplicated Use input, stale entities, regeneration, partial failure, and concurrent players.

Preserve or extend the existing safeguards around:

* exact Hero identity;
* Steam/account identity;
* exact player-state object;
* exact equipment life/body generation;
* deployment state;
* Hero versus Soldier role;
* alive/eliminated state;
* campaign clock;
* simulation freeze;
* current run;
* current dungeon;
* current EventDirector generation;
* native entity binding;
* interaction range;
* line of sight;
* resolving claim ownership;
* durable receipts;
* inventory replacement;
* SQL/persistent-storage settlement;
* late joins;
* reconnect hydration;
* stale callbacks;
* teardown.

Persistent or resource-changing events should be transactional and idempotent.

No reconnect, duplicated Use, failed feedback callback, entity replacement, regeneration, disconnect, or delayed callback should:

* duplicate a reward;
* duplicate a DFT;
* refund an already-delivered result incorrectly;
* debit twice;
* consume an item without delivering the promised result;
* reopen a spent one-shot event;
* allow stale settlement into a replacement dungeon;
* award one Hero's result to another.

Use staged state and rollback where appropriate.

Presentation failure must not undo a committed transaction.

---

# 18. Make party scope explicit

Every event must have a deliberate multiplayer ownership model.

Possible scopes include:

* personal claim;
* personal transaction;
* shared physical state with independent personal claims;
* party-shared resolution;
* first-interactor shared resolution;
* repeatable shared utility;
* independent per-Hero use.

Do not let scope emerge accidentally from entity state.

For each event, determine:

* who may activate it;
* who pays;
* who receives;
* whether another Hero can still use it;
* whether its physical state changes globally;
* what a late joiner sees;
* what a reconnecting player sees;
* what happens if two players interact nearly simultaneously.

Events should remain coherent from one through four Heroes.

A cooperative event may reward coordination, but ordinary campaign solvability may not require multiple simultaneous humans.

---

# 19. Preserve readable interaction and fair presentation

Variety must not become inscrutable.

Every event should retain:

* recognizable silhouette or visual treatment;
* legible proximity/Use behavior;
* concise prompts;
* readable cost before voluntary payment;
* readable reward or consequence;
* sane collision;
* stable positioning;
* correct client snapshots;
* understandable failure feedback;
* clear spent/resolved state;
* reasonable performance cost;
* a distinct player-facing identity.

Avoid events whose primary gimmick is invisible unavoidable punishment.

Surprise is acceptable; incomprehensible loss is not.

For voluntary transactions, players should understand the material cost before commitment.

For hazards, use readable physical or audiovisual tells commensurate with severity.

Prefer soft counters, observation, risk management, and choice over arbitrary immunity or hidden invalidation.

Maintain the project's sparse Source-era presentation language and the existing “one mechanic, one cue” audio philosophy.

---

# 20. Let events influence pacing without becoming clutter

Dungeon events should provide another procedural pacing layer.

Runs should contain combinations of:

* ordinary traversal;
* combat;
* temptation;
* relief;
* curiosity;
* uncertainty;
* interruption;
* risk;
* reward;
* strange social contact;
* spatial surprise.

Avoid mechanically placing every event immediately beside major encounters or objectives.

Some events should appear during quiet travel.

Some should make optional branches tempting.

Some should create tension before the player knows whether they are helpful.

Some floors should feel eventful.

Some should contain very little besides one unforgettable anomaly.

Do not make the Event Director a metronome.

The player should sometimes wonder what the labyrinth is going to do next.

---

# 21. Integrate with encounter ecology rather than competing with it

If the enlarged Bestiary/Encounter Director already exposes:

* floor themes;
* family prevalence;
* encounter intensity;
* topology classes;
* sector pacing;
* hostile pressure;
* recent-history data;

allow events to read suitably compact deterministic metadata from that authority where useful.

Examples:

* expensive healing becomes more relevant on attritional floors;
* hazardous events can be suppressed near already-severe encounter clusters;
* merchants may be more valuable in resource-starved sectors;
* traversal anomalies can complement vertically complex floors;
* event density can decrease on floors already carrying unusually intense combat stories.

Do not couple the systems so tightly that event generation becomes impossible when hostile composition changes.

The Event Director and Encounter Director should remain separate authorities with deliberate interfaces.

---

# 22. Preserve deterministic RNG isolation

All selection, variants, placement, rewards, minigames, NPC choices, transaction outcomes, and procedural presentation must remain compatible with the deterministic campaign/level-seed architecture.

Use named derived RNG streams.

Do not consume maze, encounter, loot, combat, or unrelated RNG merely because event content was added.

Adding one new event archetype should not unpredictably perturb unrelated maze geometry.

Given equivalent:

* game version;
* campaign seed;
* dungeon level;
* relevant campaign history;
* player/account state where intentionally relevant;

event generation should remain reproducible enough for debugging.

Keep server authority over:

* count;
* catalog selection;
* rarity;
* variants;
* placement;
* activation;
* claims;
* transactions;
* hazards;
* relocation;
* rewards;
* persistent settlement;
* event state.

Clients render and interact; they do not decide outcomes.

---

# 23. Preserve bounded generation and performance

Catalog breadth must not create uncontrolled search cost or entity proliferation.

Respect existing placement-attempt bounds and active-entity budgets.

Where paired/composite events require multi-cell search, keep the search deterministic and explicitly bounded.

A selected event that cannot be legally placed after its bounded proof should follow the established deterministic failure/retry behavior, not silently degrade the selected count.

Prefer:

* richer choices;
* better placement;
* procedural memory;
* family variety;
* clever use of existing systems;
* lightweight state;

over spawning large numbers of decorative entities or attaching bespoke Think loops to every event.

Use shared director ticks or event-driven callbacks where practical.

An event should not consume performance merely to look alive.

---

# 24. Add structured Event Director diagnostics

Provide developer-visible diagnostics sufficient to understand why a generated dungeon received the events it did.

At minimum, make it possible to inspect or log:

* exact 1d4 count;
* eligible catalog;
* excluded archetypes and major exclusion reason;
* chosen families;
* selected event IDs;
* rarity decisions;
* recent-history suppression;
* novelty bonuses;
* theme/motif influence;
* dungeon-level eligibility;
* placement locations;
* topology reasons;
* contract;
* personal/party scope;
* relevant progression proof;
* resource-resolution proof for mandatory blockades;
* placement rejection counts;
* notable rare events;
* event-state snapshots.

Prefer concise structured output over noisy per-frame logging.

Extend existing preview/debug infrastructure rather than creating a second developer interface.

Preserve the existing explicit unranked preview philosophy.

Useful developer tooling may include:

* full event-population preview;
* forced single-event preview;
* deterministic campaign event-history dump;
* event-distribution sampler.

Do not create cheats that silently leave campaigns ranked.

---

# 25. Validate event diversity quantitatively

Add automated validation around the enlarged event catalog and Event Director.

Use a large deterministic seed/campaign sample sufficient to detect systemic repetition.

Measure useful indicators such as:

* event-family appearance frequency;
* individual event frequency;
* contract distribution;
* rarity distribution;
* consecutive-dungeon duplicate rate;
* family recurrence;
* maximum recurrence streak;
* campaign catalog coverage;
* common-event starvation;
* rare-event clustering;
* placement rejection rate;
* deterministic build-retry rate;
* topology distribution;
* event-theme distribution;
* count-roll distribution;
* exact selected-count preservation;
* multi-event compatibility;
* mandatory-blockade resolvability.

Do not mechanically optimize for one diversity number.

Use metrics to find obvious pathologies.

Include tests that prove:

* identical seeds and relevant state reproduce event ecology;
* differing seeds materially vary event ecology;
* unrelated RNG systems remain isolated;
* only implemented production events appear;
* dungeon-level gates are respected;
* exact non-exploding 1d4 counts remain authoritative;
* rare events obey their intended scheduling;
* no illegal protected-cell placement occurs;
* no two incompatible events reserve the same physical/progression resource;
* mandatory blockades remain resolvable from the approachable side;
* hazards preserve progression and legal return;
* traversal utilities preserve objective order;
* the expanded catalog actually appears over campaign-scale samples;
* no common event dominates ordinary campaigns absent deliberate theme pressure;
* recent-history suppression materially reduces repetition;
* event selection remains varied inside themed floors rather than repeating one exact configuration.

---

# 26. Test every event as a lifecycle, not merely an interaction

For each newly added event, automated coverage should address the relevant lifecycle phases:

* deterministic selection;
* placement;
* native entity creation;
* partial-creation failure;
* activation;
* first interaction;
* invalid interaction;
* simultaneous/reentrant interaction;
* settlement;
* feedback;
* snapshot;
* late join;
* reconnect;
* event already spent/resolved;
* dungeon regeneration;
* cleanup;
* stale callbacks;
* ownership replacement;
* same-seed regeneration;
* incompatible-event coexistence.

Where persistent economy or inventory is involved, also cover:

* no-funds/no-item failure;
* full inventory;
* durable receipt;
* rollback;
* storage failure;
* retry;
* duplicate-use rejection.

Where movement is involved, also cover:

* occupancy;
* hull safety;
* unsafe contents;
* stale destination;
* movement teardown;
* exact ownership immediately before `SetPos`;
* cooldown/debounce.

Where physical geometry is involved, also cover:

* collision;
* safe teardown;
* occupied teardown;
* no entombment;
* late-join native state.

Automated doubles do not constitute native Source acceptance. Preserve that distinction.

---

# 27. Use retained future concepts selectively

The recent event roadmap has already contemplated concepts such as:

* item-value bribe `BLOCKADE`;
* skeleton/barricade-style blockades;
* Game Master minigames;
* Hector;
* further hazards;
* further utilities;
* NPC/service interactions.

Treat these as useful design territory, not a checklist.

Reconcile each retained concept against current live design and architecture before implementation.

Do not resurrect obsolete historical implementations merely because a concept name survives.

Select the strongest subset needed to produce a broad, coherent event ecology.

You may invent additional event identities under the authorization above when they better exploit the current systems landscape.

---

# 28. Protect gameplay guarantees

Preserve:

* maze solvability;
* graph integrity;
* ordered keycard/gate progression;
* objective accessibility;
* Warden progression;
* damsel/cash progression;
* loot/resource viability;
* active-hostile ceilings;
* equipment authority;
* inventory integrity;
* $DEB integrity;
* DFT integrity;
* status authority;
* Magic authority;
* lives/respawn rules;
* Hero/Soldier role separation;
* multiplayer state isolation;
* deterministic campaign structure;
* ranked/unranked integrity;
* late-join/reconnect correctness;
* event operator opt-out behavior;
* safe cleanup;
* existing event guarantees;
* existing accepted regression suites.

Do not destabilize unrelated completed systems merely to add novelty.

Do not turn optional dungeon flavor into systemic progression fragility.

---

# 29. Canonicalize the resulting event ecology

After implementation, update the relevant live GDD sections to describe the **implemented system**, not discarded brainstorming.

Document:

* final production event catalog;
* event families;
* stable event identities;
* contracts;
* rarity rules;
* dungeon-level gating;
* personal versus shared semantics;
* event-count rules;
* selection hierarchy;
* campaign memory/novelty suppression;
* event/floor-theme interaction;
* topology placement logic;
* progression proofs;
* mandatory-blockade resource guarantees;
* economy/inventory transactional expectations;
* deterministic behavior;
* important tuning constants;
* diagnostics;
* quantitative validation expectations;
* native acceptance obligations still pending.

Follow `AGENTS.md` navigation and write-discipline rules.

Record design decisions created under this explicit user authorization in the appropriate normalized GDD tabs.

Do not make unrelated GDD edits.

Update `docs/DEVELOPMENT_PLAN.md` with a concise durable checkpoint describing actual implemented truth, validation state, and the next bounded gate.

Do not paste an archaeological essay into the checkpoint.

---

# 30. Native acceptance remains epistemically distinct

Automated and headless tests can establish implementation and static validation.

They cannot establish:

* native Source collision feel;
* actual controller/Use ergonomics;
* prop readability;
* visual presentation;
* real packet delivery;
* physical timing;
* multiplayer feel;
* sound mix.

Do not claim these as runtime accepted without runtime evidence.

However, **do not block the code checkpoint or push merely because later human native acceptance remains pending**, unless current `AGENTS.md` or the live GDD explicitly requires a native gate before commit.

For the completed update, leave one compact high-yield native acceptance procedure capable of exercising a representative mixture of:

* one transaction event;
* one reward;
* one blockade;
* one hazard;
* one utility;
* one NPC/minigame if implemented;
* two simultaneous Heroes;
* late join/reconnect;
* regeneration/cleanup.

Prefer existing preview/testkit infrastructure over burdensome setup.

---

# 31. Validation gate

Run targeted static/headless tests throughout implementation.

Before final commit, run all affected event, economy, equipment, movement, progression, generation, lifecycle, and manual/document validators required by the repository.

Then run the canonical integration gate:

`python3 tools/test_checkpoint_g_integration.py`

Repair attributable failures rather than weakening tests.

Preserve existing accepted regressions.

If a legacy fixture fails because newly production-consumed behavior exposes an incomplete double, improve the fixture to model real semantics rather than bypassing the new code.

Use focused independent review where helpful to detect:

* transaction races;
* stale callbacks;
* circular resource dependencies;
* progression bypasses;
* cleanup defects;
* duplicated claims;
* event-selection bias;
* deterministic RNG contamination;
* topology mistakes.

Do not declare completion with known concrete regressions.

---

# 32. Commit and verified push

Once the complete bounded Event Systems Update satisfies its static gate:

1. inspect the final diff;
2. verify no secrets or deployment changes are included;
3. ensure documentation describes the implementation that actually exists;
4. commit with a concise descriptive message;
5. non-force-push directly to `main`;
6. fetch/verify remote `main`;
7. report the exact resulting remote commit SHA.

Do not deploy to the VPS.

Do not publish the Steam Workshop item.

Do not merely prepare a local commit when push authorization has already been granted.

If new remote work appears before push, preserve and reconcile it rather than overwriting it.

---

# 33. Definition of done

This checkpoint is complete when:

1. The gameplay-meaningful production Dungeon Event catalog is approximately **3.5× the baseline discovered at checkpoint start**.
2. New events use existing project/base-game assets while presenting distinct, learnable procedural situations.
3. Count inflation does not substitute for design variety.
4. The current 1d4 event-density philosophy remains bounded unless deliberately superseded and canonicalized.
5. The enlarged catalog exercises substantially more of the existing RPG, equipment, economy, status, movement, topology, interaction, and multiplayer design landscape.
6. Event families share authorities where appropriate without becoming superficial palette variants.
7. `EventRegistry` expresses the enlarged design cleanly without gratuitous abstraction.
8. `EventDirector` has advanced from mostly independent seeded selection toward a campaign-aware procedural event ecology.
9. Recent event/family history actively suppresses repetition.
10. Campaign-level coverage logic prevents both monotony and excessive dilution.
11. Dungeon/floor character can influence event selection without becoming deterministic.
12. Existing Encounter Director/floor-theme data is integrated where useful rather than duplicated.
13. Maze topology materially informs event placement.
14. Mandatory blockades prove achievable resolution from the approachable side without circular progression dependencies.
15. Hazards remain reversible/progression-safe.
16. Traversal utilities cannot bypass ordered progression and retain legal ordinary return paths.
17. Transactions remain server-authoritative, atomic/idempotent where needed, and safe under retries, reconnects, stale callbacks, and concurrent players.
18. Party/personal ownership semantics are explicit for every event.
19. Same-seed/relevant-state generation reproduces event ecology.
20. Different campaigns materially vary their event stories.
21. Unrelated procedural RNG remains isolated.
22. Quantitative campaign sampling demonstrates strong catalog coverage and substantially reduced repetition.
23. Event placement/search remains deterministically bounded.
24. Performance and generated-entity costs remain controlled.
25. Existing progression, multiplayer, economy, equipment, status, deterministic, and release-integrity guarantees remain intact.
26. Relevant automated suites pass.
27. `python3 tools/test_checkpoint_g_integration.py` passes with zero attributable failures.
28. The live GDD accurately describes the implemented event ecology.
29. `docs/DEVELOPMENT_PLAN.md` contains a durable current checkpoint and next gate.
30. The work is committed.
31. Remote `main` is verified to contain the resulting commit.
32. VPS deployment and Steam Workshop publication have **not** occurred.

---

# Guiding principle

**Emergent gameplay is the highest-order design criterion.**

Do not merely create more things to press E on.

Create a sufficiently rich **procedural incident ecology** that the same recursive labyrinth can surprise experienced players hundreds of times by recombining familiar systems into unfamiliar circumstances.

The ideal outcome is not that players say:

> “There are lots of random events.”

It is that they say:

> “You will not believe what happened to us on Level 11.”

The event system should make the labyrinth feel as though it has a capricious internal life of its own—while remaining deterministic, legible, fair, progression-safe, multiplayer-safe, and comprehensible enough that its strangest stories still feel authored rather than arbitrary.
