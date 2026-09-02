# RPG Overhaul Implementation Gates

Design authority: the live **The Legend of Deborah — Garry's Mod Game Design Document**. GitHub `main` remains implementation authority.

## Architecture map

| New system | Existing authority it must extend | Current module/status |
|---|---|---|
| CharacterProgressionSystem | RunManager player/campaign lifecycle | Gate C deterministic Levels 1-20, XP, growth, stored hit dice, and HP recomputation |
| AbilityRules | Existing combat dice, Magic, movement, HP authorities | Gate D server-authoritative semantic bridges |
| FeatDirector | CharacterProgressionSystem progression state | Gate C ordinary-feat cadence and fixed Level-20 class-capstone trios |
| FeatEffectSystem | Existing combat/pushback/loot/Magic/weapon authorities | Gate E batches 1–3: CON Health Regeneration, WIS Navigation, and INT Ammo-Regeneration Floors |
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

## Gate E — ordinary feat effects

### Batch 1: CON Health Regeneration

Implemented from the exact live-GDD definitions:

- `CON_REGEN_11` / Second Wind: CON 12, 11% MaxHP ceiling;
- `CON_REGEN_22` / Rapid Recovery: CON 14 + Second Wind, replaces the ceiling with 22%;
- `CON_REGEN_33` / Unbroken: CON 16 + Rapid Recovery, replaces the ceiling with 33%;
- one FeatEffectSystem-derived profile selects the highest owned rank rather than stacking ceilings;
- effective damage restarts the shared 5.0-second damage-free clock at the final gamemode damage seam;
- active regeneration restores `1.0% MaxHP/second × ConRegenMultiplier`, never exceeds the selected ceiling, and never restores Tetris overfill;
- one bounded 0.25-second timer visits only injured tracked feat owners; there is no all-entity Think scan;
- the Character Sheet reports the active ceiling and current CON-scaled rate;
- prerequisites, rank metadata, next-rank weighting, and exact locked-draft legality are enforced;
- `lod_rpg_gate_e_regen_validate`, `lod_rpg_gate_e_regen_status`, and `lod_rpg_test_regen <0-3>` provide finite validation and acceleration.

The full 73-entry inventory is preserved in `docs/RPG_GATE_E_FEAT_MATRIX.md`. The exact six-stat baseline, including the now-authored CHA target-priority tie-break rule, is preserved in `docs/RPG_GDD_RULES_BASELINE.md`.

### Batch 1 runtime acceptance — PASSED 2026-09-02

Steam Deck `gm_flatgrass` evidence confirmed both Gate E and core RPG validators passing. Second Wind stopped at 11/100 HP, Rapid Recovery at 22/100, and Unbroken at 33/100. Each rank reported the expected 1.20 HP/s for the tested CON profile, and the higher ceiling replaced rather than stacked with lower ranks. No Lua error was visible in the supplied console evidence.

### Batch 2: WIS Navigation

Implemented from the exact live-GDD definitions:

- `WIS_SURVEYOR` / Surveyor: WIS 12, adds +4 BreadcrumbCells after the normal WIS formula;
- `WIS_CARTOGRAPHER` / Cartographer: WIS 16 + Surveyor, replaces +4 with +8 total;
- `WIS_FRUGAL_MAP` / Frugal Cartography: WIS 14, multiplies post-WIS minimap drain by 0.85 with a final 3.0 Magic/second floor;
- the canonical WIS breadcrumb value is extended once before the existing 2–24 final clamp and NW2 synchronization;
- the canonical map-drain order is now centralized as base drain × WIS utility multiplier × Feat multiplier, then the authored floor;
- MinimapMagic consumes that final rate while retaining its absolute no-regeneration-while-open rule;
- the Character Sheet reports live breadcrumb cells and final Magic drain whenever a navigation Feat is active;
- `lod_rpg_gate_e_navigation_validate`, `lod_rpg_gate_e_navigation_status`, and `lod_rpg_test_navigation <0-3>` provide finite validation and acceleration.

### Batch 2 runtime acceptance — PASSED 2026-09-02

Steam Deck `gm_flatgrass` evidence confirmed the WIS Navigation validator. The tested Hero
reported WIS 12 / modifier +1 and Cartographer's replacing +8 bonus for 16 BreadcrumbCells;
the minimap visibly rendered 16 of 17 traversed cells. With Frugal Cartography active, the
status and MinimapMagic authority both reported 5.44 Magic/second: `100/15 × 0.96 × 0.85`.
The map remained open, the breadcrumb trail was longer, and no Lua error was visible.

### Batch 3: INT Ammo-Regeneration Floors

Implemented from the exact live-GDD definitions:

- `INT_AMMO_FLOOR_44` / Field Supply: INT 12, sets each owned eligible ordinary-firearm
  recovery ceiling to `ceil(capacity × 0.44)`;
- `INT_AMMO_FLOOR_55` / Deep Reserves: INT 16 + Field Supply, replaces the fraction with
  `0.55`;
- `INT_AMMO_FLOOR_66` / War Stock: INT 18 + Deep Reserves, replaces the fraction with
  `0.66` while ordinary pickups can still reach full capacity;
- the final loaded shared ammunition authority now owns both canonical family capacities and
  the feat-derived ceiling calculation, so no older balance-pass floor can override it;
- recovery retains its existing three-second no-fire delay and existing per-round cadence;
  the feat changes neither timing nor capacity, cannot create unowned weapons, and excludes
  Grenades and AR2 secondary ammunition;
- the Character Sheet and finite status command show each currently owned eligible family's
  live total, capacity, ceiling, and unchanged round interval;
- `lod_rpg_gate_e_ammo_validate`, `lod_rpg_gate_e_ammo_status`, and
  `lod_rpg_test_ammo_floor <0-3>` provide finite validation and safe rank acceleration.

### Batch 3 runtime gate

1. Start `gm_flatgrass` with `lod_developer_mode 1`; complete staging and deploy with an
   eligible ordinary firearm (the Shotgun is sufficient).
2. Run `lod_rpg_gate_e_ammo_validate`; require `INT Ammo-Regen feat family PASS — 3/3 ranks,
   ceilings, cadence preserved`.
3. Run `lod_rpg_test_ammo_floor 0`, then `lod_rpg_gate_e_ammo_status`; for a Shotgun require
   the baseline `floor=7` and its ordinary `12.86s` round interval.
4. Run ranks `1`, `2`, and `3`, checking the Shotgun ceiling becomes respectively `10/21`,
   `12/21`, and `14/21`, while the interval remains `12.86s` every time. The same rank-3
   status should show Pistol `36/54`, SMG `50/75`, AR2 `40/60`, and Magnum `12/18` if owned.
5. Empty an owned family below its shown ceiling, wait through the normal no-fire delay, and
   confirm it gains rounds only at its unchanged interval then stops exactly at the shown
   ceiling. Confirm ordinary pickups may still exceed that ceiling up to full capacity.
6. Open P and require its `Ammo Regen` line to match the status output. Re-run rank `0` and
   require the line to disappear and the baseline ceiling to return.
7. Re-run `lod_rpg_validate`; require the core PASS line and no Lua errors.

Gate E remains open after this batch. Proceed family-by-family until every matrix row has an implemented bridge and validator.
