# Bestiary expansion — frozen baseline through B2

Baseline frozen against `main` at
`855b3b9709675b5b035b12c58658eb74f3037fa9` on September 23, 2026.
The live GDD remains design authority; `DEVELOPMENT_PLAN.md` records current
validation/publication evidence and sequencing. The complete phase brief is
`briefs/BESTIARY_UPDATE.md`.

## Counting contract

The baseline contains **18 gameplay-meaningful normal enemy identities**.
The whole-phase target is **63** (18 × 3.5), requiring **45 additions**.
B1 and B2 add six identities: **24/63**, or **6/45 additions**; **39 remain**.
This denominator is frozen. Subsequent checkpoints must not recount procedural
permutations or reduce the denominator to make the target easier.

A counted identity needs a stable ID, a distinguishable tactical problem,
implemented behavior and an admitted production encounter path. A test spawn or
unused definition alone does not qualify. Palette, scale, tier, Combat Level,
class, feat, affinity and equipment permutations within an identity add no count.
Counts describe implementation; they do not imply native runtime acceptance.

## Frozen roster

Paths below are relative to `gamemodes/legend_of_deborah/gamemode/lod/`.

| Counted ID | Tactical identity | Production evidence |
| --- | --- | --- |
| `shambler` | Slow durable melee pressure; holds space while allies attack. | `sh_config.lua`: archetype and ordinary templates. |
| `runner` | Fast fragile pursuit closes gaps that slow melee cannot. | `sh_config.lua`: distinct authored pursuit profile and rush/ambush templates. |
| `soldier` | Warned, committed projectile burst; break its firing line. | `sh_config.lua`, `sv_soldier_shot_contract.lua`. |
| `blitzer` | Variable suppression burst with seeded per-shot veer. | `sv_m3_enemy_config.lua`, `sv_enemy_update.lua`: firing-line admission. |
| `sniper` | Long-range single shot with firing-position selection. | `sv_enemy_update.lua`: positioning, shot and template. |
| `bioblaster` | Large slow high-damage mouth projectile, without ordinary melee. | `sv_m3_enemy_config.lua`: Bio Pressure; existing hostile behavior. |
| `deadcrab` | Dodgeable leap, face latch and committed suicide fuse. | `sv_deadcrab.lua`: nest; existing hostile behavior. |
| `watcher` | Scan support recruits nearby existing wanderers. | `sv_watcher.lua`: Surveillance, scan, encounter wrapper and wandering weight. |
| `seeker` | Roller charge, wall-impact vulnerability and range-reset retreat. | `sv_seeker.lua`, `sv_seeker_encounter.lua`: Incoming and wandering admission. |
| `climber` | Wall-lane pursuit, legal vertical movement, leap and face latch. | `sv_enemy_roster.lua`, `sv_enemy_roster_placement.lua`: Wall Hunt; shared Climber authority. |
| `nodule` | Stationary exact-cell gas pressure. | Same roster/placement authorities: Gas Pocket. |
| `flamer` | Mobile humanoid short cone with an Immolated attempt. | Same authorities: Flame Pressure; constrained wandering weight. |
| `bigcrab` | Low broad, durable body with a low-origin warned fire cone. | Same authorities: Big Crab; dedicated combat bounds/origin. |
| `sentry` | Stationary frontal projectile fire requiring alternative approach. | Same authorities: Sentry Flank and alternate-route/reward placement. |
| `razor` | Pursuit into a committed fixed-direction rotor dive. | Same authorities: Rotor Cover Break. |
| `arccaster` | Frozen ground mark followed by Raw-magic eruption. | Same authorities: Arc Control. |
| `lurker` | Validated ceiling ambusher with finite venom glob. | Same authorities: Ceiling Venom. |
| `beamsweeper` | Charged horizontal sweep with crouch, cover and rear counterplay. | Same authorities: Beam Crossing and clipped-lane placement. |

At the frozen baseline, `sv_encounter_spawn_variance.lua` supplied the unified
16-identity spawn order (B1 appends three IDs without reordering those sixteen),
stable ordinals and ceiling checks. Watcher and Seeker retain their existing
explicit production wrappers. This is a code-derived count; the older
`ENEMY_UPDATE.md` roster independently corroborates it.

Runner and Shambler are counted for their existing distinct pursuit/durability
roles, not each generated speed or HP roll. Big Crab and Flamer share an attack
package, but the Crab's authored low broad combat volume and low origin create a
different body/cover problem. Their cosmetic and numerical permutations remain
uncounted.

### Exclusions

- Neil, the Brute, Gordon the Warden, Gordon clones and Hector: named progression
  or boss encounters, preserved outside the normal-enemy denominator.
- Skeleton Hero and other event-specific actors: event content, not ordinary
  encounter-roster expansion.
- Friendly summons, player-controlled Soldier incarnations and noncombat actors.
- Deferred Heavy, dormant definitions, debug-only spawns and unimplemented ideas.
- Renamed duplicates, palette/size variants and procedural numerical rolls.

## B1 — prison control cohort

These mobile enemies specialize in controlling movement or Magic, while their
ordinary companions supply complementary pressure. Their identities do not
replace generated actor classes or affinities. No new external assets, native
projectile proliferation, private status timers or reward authority are needed.

| ID / identity | Readable action and counterplay | Ordinary composition |
| --- | --- | --- |
| `gaoler` / Gaoler | Icy-blue Vortigaunt marks a frozen radius-112 floor area at up to 720 units, warns for 1.25 seconds, then delivers Ice Magic with a canonical Held attempt. Leave the mark or interrupt the charge. | Gaoler + Runner: movement control and pursuit. |
| `silencer` / Silencer | Pale-ivory Combine elite gives a 0.9-second line warning, then fires a 540-unit/second non-homing Light bolt, range 800, with a canonical Muted attempt. Sidestep, interrupt or use cover; guns and melee remain available if Muted. | Silencer + Shambler: casting pressure behind a melee screen. |
| `repulsor` / Repulsor | Brown/gold Vortigaunt warns for 1.1 seconds before a radius-220 Earth pulse centered on its fixed commitment origin; three-second recovery. Leave the ring or use cover. Successful damage uses the existing Earth Push authority. | Repulsor + Soldier: displacement and ranged pressure. |

All three use a base hostile Magic profile of **1d6 + 2** (reference damage 5.5)
through existing actor damage, status/save, hit-report, kill, XP and drop paths.
Held and Muted are save attempts, not guaranteed control. Earth push remains
subject to the canonical post-damage and movement contracts. Production templates
use existing arena/ambush admission; B1 adds no wandering weights.

The cohort extends the shared roster attack service, physical placement checks
and deterministic encounter spawner. Existing faction unity, 96-hostile hard
ceiling, attack/projectile budgets, transition/objective protections and dungeon
lifecycle remain constraints. Bosses, finale, staging succession, Abundance and
Level-21 cash progression are unchanged by this cohort.

## B2 — prison support detail

| ID / identity | Tactical response | Ordinary composition |
| --- | --- | --- |
| `stitcher` / Stitcher | Green slave Vortigaunt channels for 1.5s to heal one injured ally by ceil(12% MaxHP), capped at 24 HP. Interrupt or break its range/cover. No revival or condition cure. | Stitcher + two Shamblers. |
| `bulwark` / Bulwark | Blue Combine elite channels for 1s, granting one ally a 6s tether with +25 percentage points of canonical physical Block, capped at 33%. Break the 240-unit tether/cover, disrupt its source, or use Magic. | Bulwark + Soldier. |
| `cantor` / Cantor | Gold Metrocop calls for 1s, focusing up to three allies on one visible Hero for 4s through ordinary targeting. Break sightlines or disrupt the caller; no damage/speed increase. | Cantor + two Runners. |

Production templates `stitcher_detail`, `bulwark_line`, `cantor_charge` enter
sector-2+ arena/ambush selection. Enrichment never duplicates the support source;
ordinary companion scaling remains. The unified spawner appends all three IDs,
preserving earlier ordinals. Reference HP/speed/threat are 35/100/3.5,
65/90/4 and 40/140/3.5 respectively. Shared physical fallback is 1d4+1, range600,
0.7s warning and 2.2s recovery. Support cooldowns after warning: 6/8/8 seconds;
ally ranges360/240/420. Support requires a visible acquired Hero within600 to
start. Candidates must be activated living ordinary hostiles, excluding self,
named bosses/clones, event Skeletons and player-controlled or friendly actors.
No enemy healing grants Hero support currency.

Selection inspects at most128 cached registry candidates, on the same physical
floor, at most two traversable graph edges away, with range and LOS checks.
A beneficial mending reservation admits only one recovery channel per recipient
and expires after the 1.5s warning plus 0.2s service grace; a later release safely
fails. Recovery sorts by lowest health ratio, then distance and stable entity ID; the
other roles use distance/ID. Affect at most1/1/3 recipients. Source and recipient
progression/status-life identities plus exact dungeon objects are captured;
rally also captures its Hero's identity. Released guard/rally use beneficial
nonstacking status entries and the shared expiry scheduler. Invalid source,
recipient, cover, range, graph/progression/campaign scope, freeze or reset retires
them; no status timer or damage resolver is duplicated. Healing uses the existing
capped LootDirector health grant. Guard adds only to the existing Block roll.
Rally feeds FactionManager target selection and ordinary route/leash constraints.

All three own canonical progression templates with class/feat eligibility, HP
growth and XP. Stitcher/Bulwark support Magic does not advertise damaging-Magic
feat capability. Their normal class defenses and physical fallback eligibility
remain. No changes to bosses, Gordon → Hector → Deborah, sole staging successor,
Abundance or cash progression. See DEVELOPMENT_PLAN.md for measured validation;
implementation count does not imply native Source acceptance.

## Next checkpoint — B3: flank and pursuit cohort

Proposed finite target **27/63**, subject to three genuinely distinct identities:
(1) a junction flanker that uses a legal alternate route around the visible
Hero's current lane; (2) a skirmisher that commits a ranged attack then retreats
to a reachable firing position; (3) an interceptor that warns before occupying
a reachable escape junction. These are proposed roles, not implemented rules.
Reconcile concrete mechanics with existing navigation, pursuit, commitment and
placement authorities; avoid teleports, through-wall knowledge, locked-gate
bypasses, compulsory damage or a director rewrite. Require different tactical
responses and actual complementary production compositions.

Preserve prior cohorts and prove bounded route work, deterministic choices,
reachable placement, cancellation and same-seed replacement safety through real
spawn/progression paths. Retain further tactical-family expansion and the whole
phase's campaign-aware director: themes, novelty memory, topology, pacing and
quantitative coverage. Finish Bestiary before Big Loot, Events and the three
audits, then human playtest. B3 is not started in B2.
