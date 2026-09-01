# RPG Overhaul Implementation Gates

Design authority: the live **The Legend of Deborah — Garry's Mod Game Design Document**. GitHub `main` remains implementation authority.

## Architecture map

| New system | Existing authority it must extend | Current module/status |
|---|---|---|
| CharacterProgressionSystem | RunManager player/campaign lifecycle | Gate C deterministic Levels 1-20, XP, growth, stored hit dice, and HP recomputation |
| AbilityRules | Existing combat dice, Magic, movement, HP authorities | Gate D server-authoritative semantic bridges |
| FeatDirector | CharacterProgressionSystem progression state | Gate C ordinary-feat cadence and fixed Level-20 class-capstone trios |
| FeatEffectSystem | Existing combat/pushback/loot/Magic/weapon authorities | pending |
| IdentityGenerationSystem | RunManager RosterSeed lifecycle + independent deterministic substreams | Gate B exact 64/64/64 identity and 64-entry name catalogs |
| IdentityPerkSystem | Existing semantic combat/navigation/loot/encounter events | Gate B immutable perk ownership/display; later semantic effect bridges pending |
| CharacterSheetUI | Existing Field Manual visual language | Gate C P-key progression ledger and choice surface |
| PlayerCharacterText | Existing HUD/feed/player-message surfaces | canonical formatter adopted by RPG combat feed; remaining surfaces pending |
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

## Gate C — Levels 1-20 progression math

Implemented as a server-authoritative extension of each Gate B Hero:

- the exact 20-level Hero XP table, with sequential processing for multi-level gains;
- Primary, both-Secondary, and all-ability growth on their authored schedules, plus alternating
  per-Level Fighter Training in STR/CON;
- exactly one deterministic, permanently stored class progression hit-die result for each gained
  Level 2-20, including natural-6 recursive explosion for Wizard d6 rolls;
- StartingHP 100, dynamic CON-per-Level recomputation from the stored rolls, minimum +1 HP per
  gained Level, MaxHP clamping, and no implicit healing when the ceiling rises;
- stored three-card ordinary drafts at Levels `1, 3, 6, 9, 12, 15, 18`, with the earliest
  unresolved draft presented first and no reopening/reconnect/death reroll path;
- the exact fixed trio of authored Level-20 capstones for each class, stored and selected separately
  from ordinary feats;
- Character Sheet campaign, HP-roll, owned-feat, pending-draft, and capstone ledgers;
- developer-only `lod_rpg_gate_c_level <level>` acceleration, which marks the campaign unranked,
  and `lod_rpg_gate_c_validate` deterministic-state validation.

Gate C establishes ordinary-feat acquisition cadence using the already-authoritative Gate B legal
catalog. Full ordinary feat-family/rank content and semantic gameplay bridges remain Gate E work;
combat/class integration remains Gate D work.

### Gate C runtime gate

1. Start a fresh `gm_flatgrass` run with `lod_developer_mode 1`; complete Class and Level-1 feat.
2. Run `lod_rpg_gate_c_level 3`, open P, and confirm stored L2/L3 HP rolls plus a Level-3 draft.
3. Note all three Level-3 cards, close/reopen P, and confirm the same cards and seed; select one.
4. Accelerate through Levels 6, 10, and 18, resolving each newly earned draft; then run
   `lod_rpg_gate_c_level 20` and select one class capstone from the fixed trio.
5. Reopen P and confirm Level 20 / XP 48000, nineteen stored hit-die entries, seven committed
   ordinary feats, the selected capstone, current abilities, and current MaxHP.
6. Run `lod_rpg_gate_c_validate` and require `Gate C validation PASS`; then enter the maze and
   confirm ordinary movement, combat, death/respawn, and staging remain functional.

Do not begin Gate D until this gate passes.

## Gate D — ability and class gameplay integration

Implemented by extending the existing combat, Magic, movement, minimap, pushback, staging, and
RunManager authorities rather than introducing parallel systems:

- STR scales ordinary physical gun, melee, and explosive damage exactly once after
  dice aggregation; One-Person Army applies its authored additional physical multiplier;
- DEX scales server-owned bullet spread and movement speed, and Boomshift changes continuation
  thresholds without changing a fresh non-Rogue explosion threshold;
- positive CON resistance reduces each positive damage-die contribution by up to three while
  preserving a minimum result of one per die;
- INT scales the existing Magic regeneration authority, with regeneration still hard-disabled while
  the map is open; WIS scales Magic damage, utility drain, and canonical breadcrumb visibility;
- CHA scales the existing hit-stun duration authority for attacker infliction and defender resistance;
- Rogue actor-owned damage dice use the shared dice authority, including exact ordinary, d6, and
  SUPER-d12 fresh/continuation rules; Loaded Dice, Now You See Me, and Ace capstone bridges are live;
- Wizard post-resolution HP-to-Magic diversion spends the existing Magic pool, including Archmage,
  Mana Engine, and Living Aegis parameters, without replacing final engine HP resolution;
- hostile effective-damage ledgers exclude overkill, award the authored 40-percent killing-blow and
  60-percent largest-remainder contribution pools, and enforce replacement-wanderer XP budgets;
- authored rescue XP is awarded to every Hero that deployed into the completed dungeon, including an
  eliminated Hero awaiting the next-level comeback;
- Fighter pushback/wall-slam capstone parameters, Rogue capstones, and Wizard capstones are connected
  only at their existing semantic authorities; ordinary feat-family effects remain deferred to Gate E;
- developer-only lod_rpg_gate_d_status and lod_rpg_gate_d_validate expose the resolved profile and
  perform finite threshold, diversion, attribution, authority, Magic, MaxHP, and breadcrumb checks.

### Gate D runtime gate

1. Start a fresh gm_flatgrass run with lod_developer_mode 1, complete Class and Level-1 feat, deploy,
   and confirm no new Lua errors.
2. Run lod_rpg_gate_d_status and verify the displayed ability/class multipliers match the Character
   Sheet; observe movement or aim, combat damage, Magic regeneration, and map drain behavior.
3. Exercise the selected class path: Fighter physical/pushback behavior, Rogue damage-die explosions,
   or Wizard incoming-damage diversion. Confirm each RPG modifier appears only once in the combat feed.
4. Kill one hostile after two Heroes contribute damage when possible, and confirm XP changes on the
   Character Sheet; finish a dungeon and confirm rescue XP only for eligible deployed Heroes,
   including an eliminated Hero awaiting the next-level comeback.
5. At Level 20, exercise the selected class capstone and confirm its corresponding semantic behavior.
6. Run lod_rpg_gate_d_validate and require one Gate D validation PASS line, then verify ordinary
   movement, combat, death/respawn, Magic, minimap, staging, and maze progression remain functional.

Do not begin Gate E until Gate D passes runtime approval.
