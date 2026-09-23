# Bestiary expansion — frozen baseline and B1

Baseline frozen against `main` at
`855b3b9709675b5b035b12c58658eb74f3037fa9` on September 23, 2026.
The live GDD remains design authority; `DEVELOPMENT_PLAN.md` records current
validation/publication evidence and sequencing. The complete phase brief is
`briefs/BESTIARY_UPDATE.md`.

## Counting contract

The baseline contains **18 gameplay-meaningful normal enemy identities**.
The whole-phase target is **63** (18 × 3.5), requiring **45 additions**.
B1 adds three identities: **21/63**, or **3/45 additions**; **42 remain**.
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

## Remaining gaps and B2 proposal

After B1, the normal roster still lacks strong ally recovery/protection roles,
linked support priorities, explicit flank/ambush behavior beyond direct pursuit,
corpse/resource interaction and richer persistent zone denial. B1 addresses soft
anti-caster and displacement pressure; it does not claim the full ecology update.

**B2 proposal: one three-enemy ally-support cohort**, with finite target **24/63**:

1. A recovery specialist whose interruptible, bounded ally heal creates a focus
   target without revival or new bodies.
2. A protection specialist that briefly guards a nearby ally, using existing
   damage modifiers and legible break/position counterplay.
3. A rally specialist that provides a bounded existing ally status, with clear
   interruptible commitment and no reinforcement spawning.

Reconcile existing shared healing, mitigation and status authorities against the
live GDD before fixing B2 names, values or content. Each must create a different
tactical response; do not count three differently colored buff casters. Admit
coherent support-plus-pressure templates through existing placement and threat
budgets; validate ally eligibility, faction, bounded targeting, interruption,
nonstacking, death and dungeon replacement. This is proposed scope only: B1 does
not implement B2.

Subsequent Bestiary checkpoints expand further tactical families before the
campaign-aware director work: themes, novelty memory, topology, pacing and
quantitative campaign coverage. The phase exits near 63 production identities
with those ecology guarantees, then proceeds to Big Loot and Event System in the
authorized order. Native visual/combat/co-op acceptance remains outstanding and
is recorded separately from automated evidence.
