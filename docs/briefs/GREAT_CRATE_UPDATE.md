Resume development of **The Legend of Deborah** from current GitHub `main` and complete the next major bounded development gate: **THE GREAT CRATE UPDATE — Container Restoration + Procedural Branding + Floor Presentation Overhaul**.

**Repository:** `ShaelRiley/the-legend-of-deborah`

**Live GDD:** Google Doc ID `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`

This update is primarily a **world-presentation and rendering-architecture pass**. Its purpose is to restore the stronger visual identity of the original Half-Life 2 shipping-container maze while solving the material, branding, coloration, clipping, flooring, and performance problems that previously made that approach untenable.

The desired outcome is a labyrinth that once again looks unmistakably like a vast improvised freight-container complex—but now has a clean procedural material architecture capable of supporting the game's much richer visual systems.

---

## Authorization

You have high-level game-design, art-direction, rendering, materials, procedural-generation, implementation, tuning, UX, performance, testing, documentation, and supporting architecture authority for this checkpoint.

You are authorized to:

* inspect and modify container models, materials, textures, decals, overlays, procedural coloration, floor geometry, floor materials, catwalk presentation, maze rendering, sector/floor visual language, relevant procedural-generation authorities, asset-loading code, client rendering, networking, diagnostics, tests, and documentation;
* restore a previously used base Half-Life 2 shipping-container model if inspection confirms it is still the strongest canonical visual foundation;
* create or derive neutral project materials and textures from assets already available to the project/base game where necessary to remove unwanted baked branding while preserving useful physical detail;
* mirror, clone, reconstruct, desaturate, rebalance, or otherwise nondestructively adapt the original container texture where that is the most reliable way to produce a clean neutral hull;
* replace that technique with a technically superior method if inspection reveals one;
* change the implementation method used for container logos/"sprays" entirely if necessary;
* revise floor models, materials, geometry organization, visual variation, and localized catwalk construction;
* make reasonable aesthetic, technical, performance, and implementation decisions without stopping for routine approval;
* refactor redundant visual authorities where this produces a cleaner material pipeline;
* add development preview tools, diagnostics, automated tests, and quantitative performance validation;
* amend the live GDD wherever substantive design decisions become canonical;
* commit and non-force-push the completed bounded checkpoint directly to `main` after validation.

Resolve ordinary ambiguities yourself.

**Do not deploy to the VPS or publish to Steam Workshop.**

Never force-push, overwrite newer remote work, expose secrets, or discard intervening development.

---

# 1. Recover efficiently

Before editing:

1. Verify current remote `main`.
2. Read `AGENTS.md`.
3. Read the newest checkpoint in `docs/DEVELOPMENT_PLAN.md`.
4. Read `docs/NEXT_DEVELOPMENT_HANDOFF.md`.
5. Follow the repository's current low-compute GDD navigation rules.
6. Inspect the current maze/container implementation rather than assuming historical architecture still applies.
7. Identify:

   * the current canonical container model;
   * the older Half-Life 2 container model previously used;
   * every material/submaterial used by that older model;
   * the exact source of the persistent **NP / Northern Petrol** mark;
   * whether that mark exists in diffuse/albedo only or is also represented in bump, normal, specular, detail, or other material channels;
   * the current procedural hull-color authority;
   * the current brand/"spray" placement mechanism;
   * current floor geometry, floor material selection, UV/material behavior, collision, and render cost;
   * any existing floor/catwalk visual authorities;
   * any tests or debug tooling already associated with these systems.
8. Inspect the existing **256-brand shipping-container asset archive** and its manifest rather than regenerating equivalent artwork.
9. Preserve all completed systems that are unrelated to this presentation overhaul.

Do not begin by replacing large systems speculatively.

First establish exactly why the older container failed under the present procedural rendering pipeline.

---

# 2. Restore the classic Half-Life 2 container silhouette

The preferred visual direction is to return to the **older, recognizable Half-Life 2 shipping-container model** that previously defined the labyrinth.

Its proportions, construction, and Source-era industrial character better support the intended visual identity than the current generic solution.

Restore that model as the canonical maze-wall container **unless technical inspection discovers a concrete blocker that cannot reasonably be solved**.

Do not retain the current container merely because its materials happen to be easier to recolor.

The update exists specifically to solve the harder material problem correctly.

Centralize the resulting canonical model path through the existing configuration/data authority.

Do not scatter raw model paths through generation code.

---

# 3. Remove the baked Northern Petrol identity from the base container

The stock container's major historical problem is the persistent **NP / Northern Petrol** branding.

That branding must no longer be an intrinsic property of every container.

The restored base container should look like a plausible **unbranded freight container** before procedural coloration or project branding is applied.

Preferred strategy:

1. Inspect the original texture and UV layout.
2. Determine the exact region containing the unwanted mark.
3. Reconstruct that region from adjacent clean corrugated-metal information while retaining:

   * corrugation;
   * seams;
   * rivets;
   * welds;
   * grime;
   * abrasion;
   * weathering;
   * material roughness/value structure;
   * any useful depth cues.
4. If the opposite or neighboring region contains equivalent clean geometry, **mirroring or cloning clean texture information into the branded region is explicitly authorized**.
5. Correct the result manually or procedurally where obvious repetition would reveal the repair.

Do **not** solve this by simply blurring the logo, painting a flat rectangle over it, or otherwise creating an obvious dead patch.

The removal should become visually invisible during ordinary play.

If the logo contaminates more than the diffuse texture, clean the relevant supporting channels as well.

---

# 4. Northern Petrol may still exist procedurally

Removing the stock NP logo does **not** mean Northern Petrol must disappear from the game's fictional corporate ecology.

The procedural brand library already contains a Northern Petrol identity.

Therefore:

> **Northern Petrol should appear only when the procedural brand system actually selects Northern Petrol—not because Valve baked it permanently into the underlying prop.**

This distinction is important.

The base container is neutral.

The procedural corporate identity is authoritative.

---

# 5. Create a genuinely neutral hull material

The second major weakness of the historical container was procedural coloration.

The old hull retained enough baked coloration that dynamic tinting produced muddy, biased, or otherwise inaccurate colors.

Correct this at the material level.

The neutralized container texture should:

* preserve useful luminance variation;
* preserve corrugation and surface wear;
* preserve dirt and age;
* preserve the recognizability of the original Source container;
* contain essentially no meaningful baked hue;
* maintain equal or near-equal RGB relationships wherever color is not intentionally required;
* provide enough brightness headroom that runtime multiplication does not crush saturated procedural colors into darkness.

Do not simply make the container visually flat gray.

The goal is:

> **neutral chroma, preserved material character.**

A white-to-mid-gray weathered metal base is preferable to a dark neutral base if the runtime tinting architecture uses multiplicative coloration and therefore needs luminance headroom.

Test the final neutral material under:

* red;
* blue;
* yellow;
* green;
* orange;
* purple;
* cyan;
* white/light gray;
* dark gray;
* muted earth tones.

Procedural hue should remain recognizably faithful in every case.

---

# 6. Establish one explicit container material stack

After this update, container appearance should have a clear hierarchy.

Prefer an architecture conceptually equivalent to:

1. **Model geometry**
2. **Neutral physical hull**
3. **Procedural gameplay coloration**
4. **Procedural company branding**
5. **Optional restrained environmental wear / secondary markings**

Do not allow multiple independent systems to fight over the same material channel.

Container color remains gameplay-significant.

Corporate branding remains primarily atmospheric/worldbuilding information.

The corporate layer must therefore never destroy or substantially obscure the procedural gameplay-color layer.

Where existing floor/sector/quadrant coloration already has an authoritative design, integrate with it rather than creating another competing color system.

---

# 7. Preserve the 256-brand corporate ecology

Continue using the existing archive of **256 fictional shipping-container brands**.

Preserve its core procedural philosophy:

> **One ordinary generated labyrinth should present one coherent apparent container company rather than randomly mixing unrelated brands crate-by-crate.**

The brand should be deterministic from the relevant campaign/level procedural state under the currently canonical rule.

Do not invent a second brand library.

Do not regenerate the existing art merely to standardize implementation.

Use the manifest and existing metadata where useful.

The labyrinth should feel like one inexplicable industrial facility, freight consignment, contractor site, warehouse complex, or logistics operation—not a collage.

If current canonical design has deliberately evolved the brand-selection scope from campaign-wide to level-wide, obey the current GDD/repository authority; preserve coherence within whatever scope is authoritative.

---

# 8. Replace the old "spray" implementation if necessary

The current branding implementation frequently cuts off parts of the graphic.

This is unacceptable.

The implementation method itself is not sacred.

Do not preserve a decal/spray architecture merely because it already exists.

Inspect whether the clipping comes from:

* projected decal bounds;
* Source decal wrapping;
* incorrect world scale;
* UV discontinuities;
* face edges;
* model rotation;
* bounding calculations;
* material projection;
* alpha boundaries;
* insufficient inset;
* applying the image to geometry whose usable surface is smaller than assumed.

Then choose the most robust rendering method.

Potentially valid solutions include:

* a controlled transparent quad anchored to a known local-space face;
* a project-defined model overlay;
* a secondary material layer;
* a dedicated placard surface;
* another inexpensive Source-compatible approach.

Choose the lowest-complexity solution that provides mathematically reliable placement and acceptable performance.

---

# 9. Branding must always fit

The complete company graphic must remain visible.

That means:

* emblem;
* company name;
* slogan/text;
* framing elements;
* any intended registration marks;

must all remain inside the usable container face.

**Never crop the brand intentionally as a normal presentation style.**

Implement proper aspect-preserving fitting.

For each supported branded face, define a reliable local-space **branding safe area**.

Then scale the branding image using the equivalent of:

`scale = min(safeWidth / imageWidth, safeHeight / imageHeight)`

with an additional visual safety margin.

Requirements:

* preserve aspect ratio;
* center reliably;
* maintain a consistent inset from container edges;
* never extend across an adjacent face accidentally;
* never lose the first or final letters of a company name;
* never lose the slogan;
* never clip the logo;
* never stretch the image to fill the region;
* never distort corporate marks merely to use additional space.

Transparent unused area is preferable to cropping.

If a particular asset has unusually large internal transparent padding, preprocessing or metadata may compute its effective alpha/content bounds and fit accordingly, provided **no visible artwork is removed**.

---

# 10. Treat the logo and text as one authored composition

Do not separately place the logo, company name, and slogan unless inspection proves that the current asset format explicitly requires this.

The existing branding images were authored as complete compositions.

Treat each company image as one visual unit.

The player should see:

> emblem + name + text

together.

Do not create situations where the icon survives but half the company name is missing.

---

# 11. Establish explicit brand anchors on the container

Do not infer branding placement from arbitrary world-space projection.

Define reusable local-space anchors for the restored container model.

At minimum, establish safe anchors for the principal long container faces.

Where visually successful and inexpensive, equivalent branding may appear on both long sides.

Door/end branding may be supported only if it has a separately validated safe region.

Anchors should define appropriate information such as:

* local origin;
* local face normal;
* maximum width;
* maximum height;
* orientation;
* small surface offset to prevent z-fighting.

The branding transform should follow the container entity's position and rotation exactly.

Do not recalculate the placement from arbitrary traces after generation when a deterministic local transform can provide a stronger guarantee.

---

# 12. Avoid z-fighting and projection artifacts

The brand should visually belong to the painted container rather than shimmer above it.

Validate:

* no z-fighting;
* no flickering at distance;
* no decal leakage around corners;
* no backside rendering;
* no obvious floating several inches off the wall;
* no excessive mip blur;
* no disappearance at ordinary maze-viewing distances;
* no broken translucency sorting.

Use only the minimum geometric/material offset required for stable rendering.

---

# 13. Preserve brand legibility under every procedural hull color

The brand archive was designed to remain readable across varied container colors.

Preserve that capability.

Do not introduce a blending mode that causes:

* white branding to vanish on light containers;
* dark branding to vanish on dark containers;
* procedural tint to recolor the branding into illegibility;
* alpha to become contaminated by hull tint;
* slogans to disappear at reasonable gameplay distance.

The hull color and branding layer should remain logically independent.

If the current blending architecture multiplies them together destructively, change the architecture.

---

# 14. Reconsider the floor from first principles

The current floor presentation is visually unsatisfactory.

Treat this update as authority to redesign it.

The floor should feel:

* intentional;
* industrial;
* tactile;
* Source-era;
* visually quieter than the container walls;
* structurally plausible;
* pleasant enough to spend long play sessions looking at;
* free of conspicuous texture discontinuities;
* free of cheap checkerboard repetition.

The floor should support the maze rather than look like temporary developer geometry.

---

# 15. Canonical floor direction: seamless industrial concrete

Use **solid industrial concrete / cast-concrete slab** as the standard maze floor direction.

Prefer:

* medium-dark neutral concrete;
* believable aggregate;
* subtle wear;
* occasional staining;
* restrained cracks;
* occasional repairs or patching;
* enough surface texture to catch lighting;
* no large baked visual feature that repeats obviously every cell.

The floor should not carry strong saturated colors that compete with procedural container coloration.

The walls provide most navigational color.

The floor provides material coherence.

---

# 16. Variation should look geological/architectural, not tiled

Do not randomly assign visibly different concrete materials to every cell.

That produces procedural checkerboarding rather than natural variation.

Prefer one of these approaches:

* one coherent base floor material with sparse crack/stain/patch variation;
* one floor-wide material identity selected per generated Z-level;
* large contiguous regions sharing a variant;
* restrained detail overlays whose placement does not create obvious grid boundaries.

Potential concrete identities may include:

* relatively clean cast concrete;
* weathered concrete;
* hairline-cracked concrete;
* patched industrial concrete;
* stained loading-floor concrete.

The exact count is not important.

Visual continuity is.

---

# 17. Eliminate visible floor seams

The traversable floor should read as one constructed surface rather than hundreds of independent square plates.

Inspect whether present seams arise from:

* small geometry gaps;
* z discrepancies;
* prop borders;
* texture boundaries;
* reset UV origins;
* mismatched materials;
* overlapping coplanar surfaces;
* lighting discontinuities.

Correct the actual cause.

Where practical, merge or group adjacent floor construction into larger spans instead of treating each logical maze cell as a visibly independent tile.

Where geometry cannot reasonably be merged, use a tileable material and deterministic texture alignment so adjacent pieces visually continue.

Physical maze topology may remain cell-based internally.

The player should not perceive the implementation grid every time they look down.

---

# 18. Preserve collision reliability

Floor polish must not create new movement bugs.

Protect:

* ordinary walking;
* sprinting;
* crouching;
* jumping;
* dropped-item placement;
* enemy movement;
* corpses/ragdolls;
* event placement;
* equipment/loot spawning;
* vertical transitions;
* unstuck logic.

Do not introduce tiny floor lips capable of snagging players.

Do not create micro-gaps.

Do not create overlapping collision planes that produce vibration or unpredictable physics.

Visual continuity and collision continuity should agree.

---

# 19. Use catwalks selectively, not ubiquitously

A transparent/open catwalk maze would be visually exciting because players could look vertically through the labyrinth and occasionally see teammates, enemies, loot, or architecture on other levels.

However, making **every floor** transparent would substantially expand sightlines and could force the client to render large quantities of otherwise occluded upper/lower maze geometry.

Therefore:

> **Do not make the entire labyrinth floor transparent.**

Instead use localized see-through industrial catwalks where vertical visibility creates genuine spectacle.

Excellent candidates include:

* short bridges;
* major vertical-transition spaces;
* atria;
* overlooks;
* upper walkways beside ramps;
* special encounter spaces;
* selected intersections where another traversable level passes directly beneath;
* rare scenic procedural set pieces.

These should be memorable punctuation rather than the baseline floor.

---

# 20. Prefer perforated/grated catwalks over translucent glass

Where a see-through catwalk is used, prefer a believable industrial **metal grate / perforated deck** using the cheapest visually acceptable Source rendering technique.

Prefer alpha-tested or geometry-based openings over broad semitransparent glass if practical.

The intention is:

* players can look through;
* players above and below can occasionally see one another;
* the maze gains vertical spectacle;

without imposing unnecessary blending/overdraw cost across the entire level.

Every catwalk must retain safe collision and any necessary railings.

---

# 21. Preserve occlusion as a performance feature

One advantage of solid floors and container walls is that they naturally limit how much of the multilevel maze can be seen simultaneously.

Treat that as valuable.

Do not accidentally convert the maze into one enormous mutually visible render volume.

The low-end-PC audit remains a later dedicated phase, but this update must not knowingly create a render architecture that is intrinsically hostile to low-end hardware.

Localized vertical vistas are desirable.

Universal vertical visibility is not.

---

# 22. Make vertical glimpses intentional

Where catwalks or openings expose other levels, compose those moments deliberately.

A player looking down through a grate should plausibly see:

* another corridor;
* a teammate;
* enemies moving below;
* a strange event room;
* container roofs/walls;
* lighting from another level.

Avoid openings that primarily reveal:

* void;
* Flatgrass;
* unfinished undersides;
* clipping;
* temporary support geometry;
* obvious generation artifacts.

If a floor can be viewed from below, give its underside a credible industrial presentation.

---

# 23. Preserve the maze's Source-era aesthetic

This update should not make the labyrinth look like a modern Unreal/Unity asset pack.

Retain the peculiar appeal of Garry's Mod and Half-Life 2:

* weathered industrial surfaces;
* blunt construction;
* containers;
* concrete;
* metal;
* utilitarian signage;
* slightly oppressive lighting;
* improbable but physically understandable architecture.

Polish should make the game's visual language **more coherent**, not less Source-like.

---

# 24. Make procedural coloration cleaner and more useful

Once the neutral hull works correctly, review the actual procedural color palette.

Use the improved material response to ensure colors are:

* distinguishable;
* attractive;
* reasonably saturated;
* not fluorescent unless deliberately required;
* readable under current labyrinth lighting;
* complementary to brand marks;
* sufficiently different across gameplay-significant categories.

Do not compensate for a broken base texture by selecting extreme colors.

Fix the material first.

Then tune the palette.

---

# 25. Preserve deterministic visual generation

Everything procedurally selected by this system should remain deterministic under the appropriate seed authority.

That includes, where applicable:

* corporate brand;
* container tint;
* floor material family;
* cosmetic crack/stain variation;
* localized catwalk selection;
* other nonessential environment variation.

Do not contaminate unrelated RNG streams.

The same seed and equivalent relevant state should reproduce equivalent visual structure.

---

# 26. Preserve server authority without networking cosmetic noise

Do not network large visual tables per container.

Where a visual decision can be reproduced client-side from compact authoritative state, do so.

Prefer transmitting or deriving compact information such as:

* brand ID;
* palette/color ID;
* floor-style ID;
* deterministic variation seed;

rather than serializing complete material descriptions.

Do not create one network message per container when the same dungeon-level visual state can be shared once.

---

# 27. Avoid expensive per-container behavior

The labyrinth may contain a large number of shipping-container entities.

Therefore this architecture must scale primarily through shared materials/data rather than bespoke runtime logic attached to every wall.

Avoid:

* per-container `Think` hooks;
* repeated expensive traces;
* dynamic projected textures per container;
* unnecessary render targets;
* large unique material instances where one shared instance would suffice;
* redundant networked state;
* unnecessary translucent surfaces;
* rebuilding materials every frame.

A container should be visually interesting while remaining computationally boring.

---

# 28. Reuse one brand material whenever possible

Because a coherent dungeon normally uses one company identity at a time, exploit that coherence.

If the rendering architecture permits, reuse one loaded/materialized brand texture across all applicable containers in that dungeon scope.

Likewise, reuse shared hull materials and tint logic rather than materializing hundreds of functionally identical resources.

The procedural variety is between generated worlds.

It does not require hundreds of unique simultaneous shader states.

---

# 29. Add a container visual preview/debug mode

Provide a focused developer tool for inspecting the new system without traversing an entire generated level.

Prefer extending existing debug/preview infrastructure.

The preview should make it easy to inspect:

* canonical restored model;
* neutral untinted hull;
* procedural hull colors;
* multiple representative brands;
* brand safe-area placement;
* both long sides;
* door/end behavior if supported;
* floor materials;
* one representative catwalk;
* lighting behavior.

A useful preview should allow a developer to rotate or move around the assets quickly.

Do not require a full campaign to debug a decal.

---

# 30. Add structured diagnostics

Provide concise diagnostics capable of reporting the active:

* canonical container model;
* hull material;
* relevant submaterial mappings;
* procedural tint;
* brand ID;
* company name where metadata is available;
* brand material;
* branding-anchor dimensions;
* floor style;
* catwalk style/selection;
* significant material fallback.

Do not spam one log line per container during normal generation.

Prefer one structured visual-summary report per generated level.

---

# 31. Validate all 256 brands against the placement contract

The brand-placement rule should be mathematical rather than anecdotal.

Add automated or offline validation proving every one of the 256 brand assets satisfies the branding-safe-area contract.

At minimum validate:

* expected file exists;
* readable material path can be derived;
* canvas/aspect metadata is sane;
* calculated presentation bounds fit inside the safe region;
* no generated scale is zero/negative/NaN;
* all visible content is retained;
* deterministic brand lookup maps only to valid IDs.

If practical, generate a developer contact sheet or equivalent test artifact showing a representative sample—or all brands—on standardized container-color backgrounds.

Do not require human inspection of all 256 assets merely to establish basic fit correctness.

---

# 32. Validate procedural tint independently

Test the neutral container against a representative palette.

Automated/static validation should catch:

* invalid material paths;
* missing texture files;
* color values outside legal bounds;
* malformed vector/color state;
* missing neutral material;
* unsupported model/material mappings.

Native acceptance should then establish whether the resulting colors actually look correct in Source lighting.

Do not claim aesthetic runtime acceptance from a headless test.

---

# 33. Validate floor continuity

Add static/generation checks where practical for:

* coplanarity;
* overlapping floor pieces;
* gaps;
* invalid material assignment;
* impossible floor extents;
* unsupported floor styles;
* catwalk placement outside valid traversal cells;
* rails/barriers where required by the existing traversal contract;
* no progression-critical hole created by cosmetic variation.

Use deterministic seed samples.

The floor makeover must not weaken maze solvability.

---

# 34. Profile the visual cost

Measure the before/after cost sufficiently to catch obvious regressions.

Pay particular attention to:

* material count;
* draw-call growth;
* translucent/alpha-tested surfaces;
* container count;
* visible container count;
* catwalk visibility;
* client frame time in dense multilevel areas;
* memory consumed by the branding library;
* whether all 256 textures are being loaded unnecessarily at once.

Prefer lazy/on-demand loading of the selected branding material where the engine permits it.

Do not load 256 high-resolution branding textures simultaneously merely because the archive exists.

---

# 35. Protect all gameplay guarantees

This is a presentation overhaul.

Preserve:

* logical maze topology;
* collision;
* progression ordering;
* keycards/gates;
* Warden progression;
* damsel progression;
* post-Deborah systems;
* enemy navigation;
* encounter placement;
* event placement;
* loot placement;
* player movement;
* wall-top exploit protection;
* vertical-transition safety;
* multiplayer state;
* deterministic generation;
* current class/equipment/status systems;
* current performance/entity ceilings.

Do not allow cosmetic geometry to become a gameplay bypass.

Do not destabilize completed systems merely to improve appearance.

---

# 36. Canonicalize the resulting environment architecture

After implementation, update the relevant live GDD sections with implemented truth.

Document:

* canonical container model;
* neutral hull-material strategy;
* stock NP-logo removal strategy;
* procedural coloration architecture;
* brand composition pipeline;
* 256-brand library integration;
* brand-selection scope;
* brand safe-area/fitting rule;
* floor visual direction;
* floor variation rules;
* catwalk policy;
* deterministic visual-state rules;
* performance constraints;
* relevant diagnostics;
* validation expectations.

The GDD should describe the implemented architecture, not abandoned experiments.

Update `docs/DEVELOPMENT_PLAN.md` with a concise durable checkpoint describing the completed state and next bounded gate.

---

# 37. Native acceptance remains distinct

Headless/static tests can establish:

* deterministic selection;
* asset availability;
* bounds calculations;
* material mappings;
* topology safety;
* performance-oriented architecture;
* generation invariants.

They cannot establish:

* whether the restored container actually looks good;
* whether neutralization preserved the original texture character;
* whether procedural colors look natural under Source lighting;
* whether brand marks visually sit on the hull correctly;
* whether mipmapping makes slogans unreadable;
* whether z-fighting occurs;
* whether floor seams remain perceptible;
* whether concrete repetition is aesthetically annoying;
* whether catwalk vistas feel impressive;
* whether low-angle or long-distance views expose rendering artifacts.

Leave one compact high-yield native visual acceptance procedure covering these issues.

Do not falsely mark native acceptance as complete without runtime evidence.

---

# 38. Validation gate

Run targeted checks throughout implementation.

Before final commit:

1. run all affected material, generation, procedural-visual, geometry, deterministic, and asset-validation tests;
2. run representative deterministic seed samples;
3. validate all 256 branding assets against the fit contract;
4. validate representative tint combinations;
5. validate floor/catwalk topology invariants;
6. run the repository's canonical integration gate required by current `AGENTS.md`;
7. inspect attributable warnings/errors;
8. repair regressions rather than weakening tests.

Where a failure exposes obsolete visual architecture, update the implementation and tests to describe intended current behavior.

Do not conceal regressions as accepted legacy behavior unless they genuinely predate this work and are already documented as such.

---

# 39. Bank the work in significant bounded checkpoints if necessary

This is a substantial update.

If completing it monolithically risks losing work to execution/runtime constraints, divide it into **significant but bankable checkpoints**.

A sensible decomposition is:

### C1 — Container Restoration

* restore canonical HL2 container;
* remove intrinsic NP branding;
* establish neutral hull;
* prove procedural tinting.

### C2 — Branding Architecture

* replace unreliable spray placement;
* establish safe anchors;
* guarantee full-image fit;
* integrate 256-brand selection;
* add brand validation/preview.

### C3 — Floor & Catwalk Overhaul

* replace unattractive floor presentation;
* eliminate visible seams;
* establish concrete variation;
* introduce localized performance-safe catwalk vistas.

### C4 — Integration & Validation

* rendering/performance review;
* deterministic validation;
* diagnostics;
* documentation;
* native-acceptance procedure;
* final integration gate.

If the repository's active roadmap assigns different checkpoint names/numbers, use the repository convention.

Each banked checkpoint must preserve intervening remote work and use non-forced pushes.

Do not split work into trivial microcommits simply to increase checkpoint count.

---

# 40. Commit and verified push

Once the bounded Great Crate Update, or the currently authorized bankable checkpoint within it, satisfies its validation gate:

1. inspect the final diff;
2. ensure no secrets or deployment artifacts are included;
3. ensure documentation reflects implemented truth;
4. commit with a concise descriptive message;
5. non-force-push directly to `main`;
6. fetch/verify remote `main`;
7. report the exact verified remote SHA.

If newer remote work appears, preserve and reconcile it.

**Do not deploy to the VPS.**

**Do not publish to Steam Workshop.**

---

# 41. Definition of done

The Great Crate Update is complete when:

1. The older, visually preferable Half-Life 2 shipping-container model is again the canonical labyrinth wall model unless a documented insurmountable technical blocker was discovered.
2. The stock NP/Northern Petrol logo is no longer intrinsically visible on every container.
3. Surface repair preserves believable corrugation, grime, wear, and physical detail.
4. The base hull is chromatically neutral enough for reliable procedural recoloring.
5. Procedural colors render cleanly rather than inheriting muddy baked coloration.
6. Northern Petrol can still appear legitimately through the procedural brand library when selected.
7. The existing 256-brand library remains the authoritative corporate-brand asset set.
8. Brand selection remains coherent within the canonical dungeon/campaign scope.
9. Every brand is rendered as one complete composition.
10. Logos, company names, slogans, and other intended text are never normally cropped.
11. Brand placement uses deterministic validated safe areas.
12. Branding does not leak over container edges.
13. Branding does not z-fight or visibly float.
14. Branding remains legible across the procedural container-color palette.
15. The floor has been replaced or materially improved into a coherent industrial-concrete presentation.
16. Normal floors no longer exhibit conspicuous tile seams or arbitrary checkerboarding.
17. Concrete variation appears natural and restrained.
18. Ordinary floor collision remains smooth and reliable.
19. Selective see-through catwalks/industrial grates provide occasional vertical views where useful.
20. Transparent/open flooring is not used so extensively that the maze loses occlusion or incurs unnecessary rendering cost.
21. Vertical sightlines reveal intentional architecture rather than voids or unfinished geometry.
22. The new architecture creates no wall-top, drop, progression, event, encounter, or collision bypass.
23. Visual generation remains deterministic.
24. Networking remains compact.
25. No expensive per-container Think/render architecture has been introduced unnecessarily.
26. The branding library is not all loaded simultaneously without need.
27. A focused preview/debug workflow exists.
28. Structured environment diagnostics exist.
29. Automated validation covers brand fit, deterministic visual selection, floor safety, and relevant material invariants.
30. Relevant integration suites pass.
31. The live GDD accurately describes the implemented container, branding, floor, and catwalk architecture.
32. `docs/DEVELOPMENT_PLAN.md` contains a durable checkpoint.
33. The work is committed.
34. Remote `main` is verified to contain the resulting commit.
35. VPS deployment and Steam Workshop publication have **not** occurred.

---

# Guiding principle

**The labyrinth should look procedurally different without ever looking procedurally assembled.**

The containers are not merely walls.

They are the architectural vocabulary of *The Legend of Deborah*.

Restore the peculiar visual power of the original Half-Life 2 freight-container maze, but remove the accidents inherited from the stock asset: permanent branding, hue contamination, clipped decals, ugly floors, and conspicuous construction seams.

The ideal result is that players stop perceiving "maze tiles" and instead perceive an impossible industrial place:

* a coherent freight complex;
* owned by some strangely plausible corporation;
* built from old painted steel;
* weathered but readable;
* crossed by concrete decks and occasional grated catwalks;
* vertically layered enough that a player might glimpse a teammate several stories above or an enemy moving below;
* procedurally colored and branded differently from another campaign;
* yet visually coherent enough that it seems somebody actually built it.

The desired reaction is not:

> “They changed the crate texture.”

It is:

> **“This place looks real enough that I want to know who built it.”**
