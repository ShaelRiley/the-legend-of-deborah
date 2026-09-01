# RPG Overhaul Implementation Gates

Design authority: the live **The Legend of Deborah — Garry's Mod Game Design Document**. GitHub `main` remains implementation authority.

## Architecture map

| New system | Existing authority it must extend | Current module/status |
|---|---|---|
| CharacterProgressionSystem | RunManager player/campaign lifecycle | Gate B Level-1 hero state attached directly at RunManager admission |
| AbilityRules | Existing combat dice, Magic, movement, HP authorities | shared schema/constant contract only |
| FeatDirector | CharacterProgressionSystem progression state | Gate B locked Level-1 draft/selection; later levels pending |
| FeatEffectSystem | Existing combat/pushback/loot/Magic/weapon authorities | pending |
| IdentityGenerationSystem | RunManager RosterSeed lifecycle + independent deterministic substreams | Gate B exact 64/64/64 identity and 64-entry name catalogs |
| IdentityPerkSystem | Existing semantic combat/navigation/loot/encounter events | Gate B immutable perk ownership/display; later semantic effect bridges pending |
| CharacterSheetUI | Existing Field Manual visual language | Gate B P-key sheet |
| PlayerCharacterText | Existing HUD/feed/player-message surfaces | canonical formatter available; broad surface adoption pending |
| RPGThreatEvaluator | EncounterDirector projected-profile spending | bounded threat contract only |

## Gate A — boot + architecture scaffold

Implemented without changing live combat or progression behavior:

- exact GDD schema field contracts for progression, derived stats, combat-hit state, XP damage ledgers, defensive proc state, feat definitions, capstones, pending drafts, and procedural identity;
- six-ability/class/level/Magic/safety-cap constants;
- Fighter/Rogue/Wizard favored-ability and hero hit-die metadata;
- seven ordinary feat levels (`1, 3, 6, 9, 12, 15, 18`);
- isolated RPG deterministic seed helpers;
- `CharacterProgressionSystem` state constructor and pure ABILITY_MOD/Level helpers;
- developer-only `lod_rpg_validate` command and finite startup validation when developer mode is enabled.

`LOD.RPG.GameplayEnabled` remains `false` at Gate A. This is deliberate: Gate A must prove that the new architecture can load beside the existing game without changing broad gameplay.

## Runtime gate

1. Fresh-start Garry's Mod on `gm_flatgrass` with the current checkout.
2. Confirm no Lua errors during startup.
3. Confirm the staging hut appears and the procedural dungeon still builds/releases normally.
4. With developer mode enabled, run `lod_rpg_validate` and confirm a single `core RPG validation PASS` line.

Do not begin Gate B until this gate passes.

## Gate B — Level-1 hero identity, class, feat, and Character Sheet

Implemented without enabling later-level XP progression or broad feat-effect bridges:

- an independently generated per-campaign `RosterSeed`;
- immutable deterministic cooperative-hero identity packages using the live GDD's complete
  64-entry Origin, Background, Motive, masculine-name, feminine-name, surname, and nickname tables;
- presentation-sex-consistent names, unique in-campaign component allocation, the canonical
  `FIRST "NICKNAME" LAST` display, and a client-rendered model portrait;
- neutral Level-0 Hero abilities, Level-1 Primary growth, Fighter Training, identity ability
  deltas, effective scores, modifiers, StartingHP 100, and no Level-1 hit-die roll;
- one-way Fighter/Rogue/Wizard commitment followed by one stored deterministic three-card
  legal Level-1 ordinary/fallback draft and exactly one selection;
- server-authoritative portal gating until class and feat are complete;
- a non-pausing P-key Character Sheet in the Instruction Booklet artifact language;
- manual control-list synchronization and `lod_rpg_gate_b_validate`.

Ordinary feat ownership is authoritative at this gate. Broad combat/Magic/navigation feat-effect
bridges and later-level progression remain deliberately deferred to later gates.

### Gate B runtime gate

1. Fresh-start on `gm_flatgrass` and confirm no new Lua errors.
2. Observe the generated procedural name, portrait, Origin, Background, Motive, and three micro-perks.
3. Commit one Class, note the three Level-1 feat cards, close/reopen P, and confirm the same cards remain.
4. Confirm the portal denies entry before the feat choice.
5. Select one offered feat, take the Hermit's weapon, and confirm the portal deploys the Hero.
6. Reopen P and confirm identity, Level 1, Class, abilities, StartingHP 100, and selected feat.
7. Run `lod_rpg_gate_b_validate` and require `Gate B validation PASS`.
