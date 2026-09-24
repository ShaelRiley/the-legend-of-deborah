# Bestiary expansion — frozen baseline through B18

Baseline frozen against `main` at
`855b3b9709675b5b035b12c58658eb74f3037fa9` on September 23, 2026.
The live GDD remains design authority; `DEVELOPMENT_PLAN.md` records current
validation/publication evidence and sequencing. The complete phase brief is
`briefs/BESTIARY_UPDATE.md`.

## Counting contract

The baseline contains **18 gameplay-meaningful normal enemy identities**.
The whole-phase target is **63** (18 × 3.5), requiring **45 additions**.
B1–B18 add forty-three identities: **61/63**, or **43/45 additions**; **2 remain**.
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

## B3 — flank and pursuit cohort

| ID / identity | Tactical response | Ordinary composition |
| --- | --- | --- |
| `pincer` / Pincer | Purple Combine soldier signals with split chevrons, then takes a legal alternate route around the observed Hero lane. Watch the side passage, change lanes or interrupt it. | Pincer + Soldier. |
| `harrier` / Harrier | Cyan Metrocop commits one physical projectile, then withdraws toward reachable cover or greater separation. Dodge, close the gap or deny its escape. Backward chevrons identify withdrawal. | Harrier + Shambler. |
| `waylayer` / Waylayer | Amber Combine elite marks a reachable escape junction for one second, walks there and holds briefly. Change exits, beat it to the junction or interrupt. Cross/square is an intention, not damage. | Waylayer + Runner. |

Templates `pincer_detail`, `harrier_screen`, `waylayer_cutoff` enter sector-2+
arena/ambush selection, with one specialist per composition. Physical admission
requires a local legal cycle or two-leg lateral pocket, retreat edge or nearby
junction respectively;
unsuitable candidates retain the existing budget-safe ordinary replacement.
All three append unified spawn ordinals and own explicit canonical progression
profiles, usable physical feats, HP growth, XP and ordinary reward settlement.
No new wandering weight, reinforcement bodies, target authority or director.

All use shared physical 1d6+2 fire. Reference HP/speed/range/shot warning/recovery/
threat: Pincer40/180/520/0.65s/2.5s/3.5; Harrier30/190/720/0.85s/3s/3.5;
Waylayer55/145/520/0.8s/2.8s/4. Pincer tactical warning0.6s; Waylayer warning1s
and hold1.5s. Fixed route deadline = readiness + clamp(route distance/current
canonical effective movement speed +1s + hold,6s,16s), without extension.
Failed-plan cadence2s; active commitments end/cancel into an8s cooldown, leaving
a real ordinary-fire window. Search bounds32 nodes/depth4, at most8 candidate route validations.
Sorted choices consume no other random stream. Harrier retreats only after an
actual projectile release; interrupted or budget-refused fire cannot trigger it.

Pincer prefers a short alternate graph route. If none is clear, a visible Hero
within two legal edges can trigger a two-leg flank inside the source cell:
nominal sideways96, endpoint observed position + forward48 + sideways96, both
clamped by canonical CellFloorPoint. Require at least64 lateral departure and32
forward closing, plus full hull clearance. Waylayer targets an escape junction
adjacent to the observed Hero cell.

Only a visible acquired Hero starts a plan; observed position is frozen. Routes
never update from hidden movement. Reuse Navigator graph traversal/waypoints and
MotionV2 locomotion, with fresh legal-edge and scaled native hull validation.
Exact run, graph, progression, campaign, source and Hero incarnation bindings,
interruption and finite expiry retire stale route/attack work. No safe/objective/
transition cell, closed-gate bypass, teleport or private damage/status/reward path.
Held cancels routes, not ordinary physical fire. Already emitted bullets retain
their finite trajectory through source hit-stun/Held, with exact life/dungeon
retirement. Full/reduced presentation retains finite glyphs and the junction marker.

Progression tuples STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; HP die;
baseXP; morale: Pincer11/16/10/10/10/9;20/80/0;d8;45;5.
Harrier9/16/9/11/11/10;15/85/0;d6;45;4.
Waylayer13/12/13/11/12/10;65/35/0;d10;55;6. All usesMagic=false.
Generic physical attack feats remain supported; Soldier-only firearm/reload
capabilities are not advertised by these roster projectiles.

See DEVELOPMENT_PLAN.md for measured results. This is implementation progress,
not native Source acceptance. Prior cohorts, bosses, finale/succession, Abundance
and Level-21 cash progression remain regression constraints.

## B4 — self-defense and reaction cohort

| ID / identity | Tactical response and counterplay | Ordinary composition |
| --- | --- | --- |
| `pavise` / Pavise | Steel-blue Combine elite warns0.65s, then anchors a fixed-facing2.5s self-guard. Its forward60-degree half-angle adds25 percentage points to canonical physical Block, capped33%. It cannot move or fire during the stance. Flank, use Magic, interrupt or wait. Shield and ground arc show direction. | Pavise + Runner. |
| `repriser` / Repriser | Rose Metrocop responds to actual HP loss from a direct hostile Hero attack with one1s warned straight physical shot. A hooked arrow announces it. Sidestep, break cover or interrupt again; never reflects damage. | Repriser + Soldier. |
| `redliner` / Redliner | Rust-red Combine soldier switches from ranged fire to one wounded lunge when a direct Hero hit leaves it at<=40% MaxHP. Bounded pursuit reaches400-unit range, then a1s warning freezes the lunge direction. Sidestep/obstruct/interrupt, then exploit3s stationary recovery. Healing to>=60% rearms a later episode. Jagged chevron/lane and open recovery bars distinguish its states. | Redliner + Shambler. |

Templates `pavise_advance`, `repriser_detail`, `redliner_pressure` enter sector2+
arena/ambush selection. Enrichment retains one specialist with ordinary companion
scaling; safe/objective/transition exclusions, physical clearance, threat and
hostile budgets remain. IDs append unified spawn ordinals; no added wandering
weight, bodies, director, class requirement or cosmetic counting.

All ordinary shots and reactions use physical1d6+2, reference5.5. Reference
HP/speed/ordinary range/warning/recovery/threat: Pavise65/110/600/0.7s/2.4s/4;
Repriser40/145/600/0.7s/2.4s/3.5; Redliner50/170/600/0.7s/2.4s/3.5.
Models Combine elite/Metrocop/Combine soldier; RGB165,190,215 /230,100,180 /
215,65,45. No damaging-Magic capability or forced elemental affinity.

Progression STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; HP die;
baseXP; morale: Pavise14/8/15/10/12/9;80/20/0;d10;55;7.
Repriser11/14/11/12/12/10;40/60/0;d8;50;5.
Redliner14/15/10/6/9/8;55/45/0;d8;50;6. All usesMagic=false. Shared
progression/class/usable-feat/HP/XP/loot remains authoritative.

Pavise cooldown6s after completion/interruption, acquisition600, failed scan0.3s.
Repriser pending allowance2s for triggering hit-stun, reaction warning1s, cooldown5s
from arm. Redliner pending2s, ordinary legal approach at most4s, lunge warning1s,
existing dive780 units/s for0.65s, recovery3s after attempt/forfeit/interruption.
All deadlines are finite and nonextending. Reactions use the existing roster
service and locomotion; no private status clock or recurring per-enemy hook.
Actual positive native HP loss arms a response only after shared mitigation.
Passive/status/reactive/environmental damage cannot start reaction loops. Lethal,
blocked and zero-loss hits cannot arm; duplicate post callbacks cannot extend
commitments. Trigger-owned late shotgun/Magic/crowbar hit-stun is identified by
the committed event and adopted inside the unchanged2s pending deadline; another
attack cancels. Recovery remains stationary for its original3s despite further
hits; neither shortening nor repeated extension is allowed.

Exact run/graph/progression/campaign and source/Hero progression/status-life
identity binds guard, pending reactions, ordinary attacks and projectiles. Invalid
life, same-seed replacement, freeze/failure/clear or expiry retires stale work.
Held prevents guard/lunge; Muted leaves physical fire available. Released bullets
retain finite flight through ordinary source interruption, while life/dungeon
replacement still retires them. Directional protection adds to the existing one
Block roll with its ordinary exclusions/cap; no second damage or reward settlement.
Canonical morale and class defenses remain unchanged.

See DEVELOPMENT_PLAN.md for measured automated results and retained native gaps.
All previous cohorts, bosses, finale/succession, Abundance and cash progression
remain regression constraints. Implementation does not imply Source acceptance.

## Next checkpoint — B5: projectile-pattern cohort

Proposed finite target **33/63**, subject to three genuinely distinct production
identities: a clearly warned bounded ricochet, a delayed return-path shot, and a
split-lane volley with a readable safe lane. These are proposed tactical problems,
not authored mechanics. Reconcile existing projectile/geometry/damage and actor
lifetimes before choosing identities/tuning. Distinguish them from Blitzer,
Sniper, ordinary roster bullets and cosmetic or numerical permutations; preserve
cover, dodgeable tells and bounded projectile/trace/dice work. No homing through
walls, unavoidable damage or extra entity bodies.

Complete only B5 next, retaining further tactical-family expansion and the
whole-phase campaign-aware director: themes, novelty memory, topology, pacing and
quantitative coverage. Finish Bestiary before Big Loot, Events and the three
audits, then human playtest. Native acceptance does not block that phase order.

## B5 — projectile-pattern cohort

| ID / identity | Tactical response | Ordinary composition |
| --- | --- | --- |
| `caromer` / Caromer | Cyan Combine soldier warns the complete path, including one possible wall bank. Sidestep, then watch the reflected lane. New cover absorbs; unsuitable bank geometry gives a straight shot. | Caromer + Shambler. |
| `reeler` / Reeler | Amber Metrocop sends a warned shot beyond the observed Hero position, pauses at its endpoint for 0.75s, then retraces the frozen line. Dodge and wait for the return; cover consumes either leg. | Reeler + Runner. |
| `forker` / Forker | Mint Combine elite warns two parallel lanes with a broad central gap. Stay in that gap or leave both lanes; no hidden center projectile. Offset cover denies the whole volley. | Forker + Soldier. |

Templates `caromer_screen`, `reeler_chase`, `forker_crossfire` enter sector-2+
arena/ambush selection, one specialist per composition, ordinary companion
scaling, no wandering weights. Unified spawning appends the three IDs without
reordering old ordinals. Each has canonical generated classes, usable physical
feats, HP growth, XP and ordinary single reward settlement.

Reference HP/speed/target range/warning/recovery/threat:
Caromer40/125/720/1.1s/3s/3.5; Reeler40/145/600/1.1s/3.5s/3.5;
Forker55/110/600/1.2s/3.2s/4. All use shared physical1d6+2.
Progression rows in STR/DEX/CON/INT/WIS/CHA order; Fighter/Rogue/Wizard weights;
progression hit die; base XP; morale:
Caromer11/13/11/12/10/9;40/60/0;d8;50;5.
Reeler10/15/10/12/11/10;25/75/0;d8;50;5.
Forker13/11/13/10/12/9;65/35/0;d10;55;6.
No offensive Magic capability or new stat/damage multipliers.

Caromer speed620, first leg up to900, total path<=1100, suitable vertical bank
normal abs(z)<=0.25, minimum first/reflected legs96. Exactly one matching
warned-surface reflection; missing/changed/new/second cover cannot create another
bank. Reeler speed480, outbound min(640, observed distance+96), pause0.75s,
then exact return to launch point. Forker speed600, offsets±64, parallel lanes
up to640; 128-unit centerline separation with radius2 projectile hulls.
Geometry clips paths four units short of ordinary cover; bank restarts four
units off its matched surface and probes at most two units into that endpoint.

Shared `EnemyRoster` retains the projectile list,0.025s service,0.05s maximum
step and64-shot ceiling; two-slot volleys are atomic. `sv_enemy_patterns.lua`
is trajectory policy only. At most4 planning hull traces plus2 offset-release
checks per commitment, at most1 sweep per moving shot per service, no catch-up
loops, new native projectile bodies, entity scans or RNG calls. Hard expiry is
summed path length/speed+pause+0.2s; warning release grace0.2s; failed geometry
retries after0.5s. One shared attack/dice contract and target ledger give at most
one damage packet per Hero across both volley lanes. Incoming direction uses the
actual swept segment origin, not the shooter's later position.

B4's exact-life capture/validation is promoted to the roster and reused by both
cohorts, preserving its contract. Source/Hero progression and status-life plus
exact run/graph/progression/campaign scope retire stale charges and shots,
including same-seed rebuilds. Pre-release hit-stun, lost acquisition/cover,
Intimidated or fleeing cancels; Held/Muted permit physical fire. Emitted shots
survive ordinary interruption and lost acquisition, but retire on life/dungeon
replacement, death/removal, freeze/failure/clear and expiry. Dead valid actors
also clear their pending attack when removed from the active registry.

Client snapshots show exact frozen paths, an actual bank diamond, return arrow,
parallel gap and paused-return diamond. Existing two-bit projectile type3 carries
B5 shots without expanding the wire layout. Geometry remains in reduced effects;
warning and packet deadlines hide stale tells. No extra rendering scan.

See the current plan for measured validation and retained native checks. This
checkpoint does not complete the whole Bestiary update or its campaign-aware
director ecology. Next: B6 trap-and-escape cohort, target36/63 only for distinct
validated production identities; candidate mechanics are proposals until authored.


## B6 — trap-and-escape cohort

| ID / identity | Tactical response | Ordinary composition |
| --- | --- | --- |
| `wirewright` / Wirewright | Amber Combine soldier channels a warned, finite low tripwire across the observed Hero cell. Jump above its height, skirt either endpoint, wait, interrupt or destroy the source. | Wirewright + Runner. |
| `snarer` / Snarer | Blue Vortigaunt lays an Ice proximity circle. After arming, first entry begins a separate fixed snap countdown. Bait and leave, interrupt, mute or destroy; the snap uses canonical Ice/Held. | Snarer + Soldier. |
| `cordon` / Cordon | Orange floor turret is itself the destructible node. A warned annular physical pulse leaves a safe center and outside. Step inward/outward, use cover, interrupt or destroy to open the approach. | Cordon + Shambler. |

Templates `wirewright_chase`, `snarer_detail`, `cordon_screen` enter sector2+
arena/ambush production, one specialist per composition, ordinary companion
scaling and no wandering weights. Append unified spawn identities. Reject
safe/objective/transition cells and obstructed native hulls; Cordon additionally
requires two traversable same-floor exits and clear side pockets. Keep the
ordinary budget-safe replacement for unsuitable placement.

All use EnemyRoster's existing attack scheduler and canonical combat/status/
Block/Dodge/progression/XP/loot paths. The source channels without moving while
its trap exists; interruption, source displacement beyond32, death, removal,
freeze/failure/clear, source/primary-Hero life or progression replacement and
exact run/graph/progression/campaign replacement retire work. Captured incidental
Hero lives are revalidated separately. No late join/revival inherits an unseen
warning; no spawned bodies/props, extra trap rewards or private status timers.
Held does not prohibit these attacks; Muted prohibits Snarer's Magic. Released
B5 projectiles still survive ordinary interruption. A pulse killing its original
target does not truncate other already-admitted Heroes; source invalidation
still terminates settlement immediately.

Tuning (HP/speed/acquisition range/warning/base recovery/threat): Wirewright
40/125/600/1.25s/3s/3.5; Snarer35/110/600/1s/3.5s/3.5; Cordon55/0/600/1.5s/4s/4.
All use1d6+2 with canonical actor scaling; Snarer is Ice Magic. Recovery retains
canonical rate-of-fire scaling. Invalid planning/capacity retries after0.5s,
with mobile repositioning after unsuitable geometry.

Wire length224, radius14 in XY, floor-relative feet height−4..48, armed5s;
one hit per captured Hero and swept crossing after arming only. Crossing during
the warning never retroactively damages; jumps above48 and endpoints remain
safe. Snare radius72/height72, armed6s, fixed1.25s countdown after first proximity;
trigger only when countdown+0.2s grace fits existing expiry. Cordon inner80/
outer160/height72, one pulse, warning+0.2s hard expiry. Circle lower floor tolerance
−4. Late arming or snap service beyond0.2s cancels, with no catch-up damage.
One trap per source,16 pending/live total,32 captured Hero records maximum
(ordinary party1–4), existing25ms service; no world/target discovery after commit.

Wire centers on the observed Hero cell; Snarer clamps observed XY to64 units
from its cell center; Cordon freezes its own XY. Only the source cell or one
traversable same-floor neighbor is eligible. Floor+3 markers, source initial
floor tolerance24, observed Hero tolerance72. Require native ground at the wire
center/endpoints or circle center on admission and every service; missing or
opened false-floor support cancels. At most3 support traces per trap per service,
plus one LOS trace per geometrically eligible captured Hero. Clearance uses
standard16×72 standing hull and escape offsets64/104/100 respectively. Shared
navigation/geometry checks keep effects in their exact cells and respect cover,
locked edges and transitions. Sweeps exceeding256 units discard the teleport
segment. The visible capsule/end posts, snare teeth/countdown and unfilled double
ring match server geometry at full/reduced effects, use finite deadlines and
2400-unit culling; no new render hook/particles/lights.

Progression (STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; growth die;
base XP; morale): Wirewright10/13/11/14/11/9;35/65/0;d8;50;5.
Snarer8/10/10/14/16/10;10/15/75;d8;50;4, actual offensive Magic eligibility.
Cordon12/8/15/12/13/7;70/30/0;d10;55;7. No private scaling or reward authority.

The live GDD rule is LOD-BESTIARY-B6-001 in03/05/07. Automated validation and
pending native acceptance are recorded separately in DEVELOPMENT_PLAN.md.

## B7 — melee spacing-and-commitment cohort

| ID / identity | Tactical response | Ordinary composition |
| --- | --- | --- |
| `reaper` / Reaper | Green zombie freezes a wide frontal semicircle for 1.1s, then sweeps once. Retreat, circle behind, use cover or interrupt. | Reaper + Soldier. |
| `drubber` / Drubber | Ochre fast zombie marks two nested narrow sectors: short strike after 1s, farther strike 0.85s later along the same frozen direction. Sidestep and respect the second beat. | Drubber + Runner. |
| `fencer` / Fencer | Pale-violet Metrocop backsteps within a fixed 0.6s, then warns 0.9s before a narrow thrust from the frozen retreat endpoint. Avoid chasing directly; sidestep, obstruct or interrupt. | Fencer + Shambler. |

Sector2+ arena/ambush templates retain one specialist, ordinary companion
scaling, legal physical placement, safe/objective/transition exclusions, bounded
fallback and the existing hostile ceiling. Append ordinals; add no wandering
weights, director rewrite or new bodies. Models zombie/classic, zombie/fast and
police; RGB135,190,125 /220,160,70 /195,155,235. Existing assets only.

All use physical melee1d6+2 through canonical damage, Block, Dodge, feats,
XP and loot. A beat shares one roll across at most32 captured Hero incarnations,
with one settlement each. Drubber's second beat is a separate attack. Frozen
tells do not track hidden or moving Heroes; late joins/revivals cannot inherit
a warning. Bind exact source/primary-Hero progression/status-life and run, graph,
progression, campaign. Same-seed replacement, removal, death, freeze/failure/clear,
attack prohibition, hit-stun, morale flight and invalid geometry retire work.
Held permits stationary strikes but forbids Fencer's backstep; Muted permits
physical melee. One pulse's lethal primary hit cannot skip other admitted Heroes.

Reference HP/speed/acquisition/warning/recovery/threat: Reaper55/140/144/1.1s/
2.5s/3.5; Drubber60/125/112/1s/2.8s/4; Fencer35/180/144/0.9s after retreat/
2.5s/3.5. Reaper radius144,half-angle90; Drubber112 then184,half-angle30,
0.85s between beats; Fencer nominal retreat80 (minimum64,maximum4 lateral),
thrust240 and half-width24. Feet-height tolerance−4..72; current LOS and exact
cell prevent wall/floor leakage. Beat grace0.2s; missed deadlines forfeit.
Stationary recovery is fixed, unaffected by rate-of-fire, and further hits cannot
shorten or extend it. Failed preflight retries/repositions after0.5s.

Movement remains HostileMotionV2 with ordinary canonical effective speed,
50ms maximum movement step and shared25ms service. Validate full remaining
retreat with scaled16×72 hull (size0.33..1.33), same legal cell, canonical
CellFloorPoint and native floor support. At most one planning/service hull plus
two support probes; source/endpoint floor+16 to−12 relative to actor origin,
normal.z>=0.7,within4 of canonical floor. Source starts at floor+2±4; stationary
drift>4 cancels. A stalled/slow retreat must reach within4 by0.6s or forfeit;
no teleport, catch-up loop, independent movement/control/damage/reward owner.
Full/reduced ground tells and countdowns cull at2400 units.

Progression STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; HP die;
baseXP;morale: Reaper14/10/13/8/10/8;75/25/0;d10;55;6.
Drubber15/8/14/7/10/8;85/15/0;d10;55;7.
Fencer10/16/9/12/11/10;20/80/0;d8;50;5. All usesMagic=false, with
canonical usable physical feats, independent seeded generation and rewards.

Counts describe implementation, not native acceptance. See DEVELOPMENT_PLAN.md
for measured gates and retained Source checks.

## B8 — volatile-and-remains cohort

| ID / identity | Tactical response | Ordinary composition |
| --- | --- | --- |
| `afterburst` / Afterburst | Rust-orange zombie leaves a frozen radius128 warning on legitimate defeat; one physical burst after0.8s. Retreat or use cover before collecting the ordinary drop. | Afterburst + Soldier. |
| `carrion` / Carrion | Injured green fast zombie exclusively claims a nearby corpse and channels a visible stationary0.6s feeding tether. Interrupt, separate, obstruct, or prioritize it before its escorts. | Carrion + two Shamblers. |

Both retain ordinary narrow warned physical melee. Sector2+ arena/ambush,
singleton specialists, ordinary companion enrichment, canonical generated
class/usable feats/HP/XP, unified appended ordinals and safe/objective/transition/
hull admission. No wandering weights, director rewrite or new native bodies.

**Post-defeat ownership:** only `lod_hostile:OnKilled` seals a receipt after its
existing death claim. Deferred `HostileDeathPresentation:Add` opens that exact
receipt, retaining the ordinary one-second corpse and scheduled loot conversion.
No native mutations or retained DamageInfo in the lethal callback. Opening must
occur within0.1s of sealing; otherwise the new gameplay effect forfeits and normal
presentation/rewards continue. Clear dead statuses once and bind a distinct corpse
status-life token. Exact source entity/receipt/progression/corpse record plus
run/graph/progression/campaign epoch/seed/run ID retire stale work. Positive HP,
removal, life replacement, same-seed rebuild, freeze/failure/clear, displacement
or invalid supported geometry cancels gameplay. Ordinary living-source damage
contracts remain unchanged; only the sealed burst enters shared packet assembly.

Burst freezes position and at most32 eligible Hero incarnations, uses one shared
physical1d6+2 contract and at most one hit per Hero, current LOS, same cell and
feet-height−4..72. No monster damage or corpse chains. Late joins/revivals never
inherit warnings. The0.8s deadline has0.1s grace; missed service forfeits. Native
corpse Draw explicitly renders the full/reduced circle and bar despite the living
attack draw branch being skipped; conservative bounds include the radius128 tell.

Carrion candidates are selected only on real corpse opening from at most128
cached registry entries, then proximity/EntIndex order. Range240,same supported
legal cell,current corpse LOS; a visible acquired Hero within600 and its exact
incarnation bind the channel. One irrevocable claim per corpse,one pending feed
per source,cooldown6s from commitment. No retry after interruption. Source drift
beyond4,hit-stun,attack prohibition,morale or lost ownership cancels. Held/Muted
permit stationary feeding. Heal min(30,ceil(MaxHP*0.20)) through existing capped
LootDirector health grant; never cure,revive,grant support currency or XP.
Consume before native callbacks,hide the corpse and cancel any unspent burst;
ordinary loot remains at its scheduled time. LootDirector rechecks the defeated
receipt identity around its existing handoff; old same-seed graph/actor lifetimes
cannot issue new drops. Gameplay cancellation alone does not revoke earned loot.

At most96 active gameplay receipts,with ordinary presentation/rewards as the
cap fallback. Shared roster service and shared corpse scheduler remain the only
schedulers; no corpse scans,private status clock,reinforcement bodies or props.
Semantic full/reduced circle/tether/crossed jaws/countdown cull at2400 units.

Reference HP/speed/range/melee warning/recovery/threat: Afterburst50/105/112/
0.9s/2.5s/3.5;Carrion45/155/112/0.8s/2.2s/4. Living physical1d6+2,narrow30-degree
half-angle radius112,one beat,0.2s melee grace and existing fixed stationary
recovery. Feeding grace0.1s. Floor support and source drift use B7's canonical
floor+2±4,normal.z>=0.7 and exact nonprotected nontransition cell checks.
Models zombie/classic and zombie/fast;RGB215,115,65 and160,190,85.
Progression STR/DEX/CON/INT/WIS/CHA;Fighter/Rogue/Wizard weights;hit die;baseXP;
morale: Afterburst13/8/12/7/9/8;85/15/0;d10;50;6.
Carrion12/14/11/8/10/8;50/50/0;d8;50;5. Both usesMagic=false.

See DEVELOPMENT_PLAN.md for fresh automated evidence and retained native gaps.

## B9 — tether and projected cover

| Identity | Distinct tactical problem and counterplay | Production composition |
| --- | --- | --- |
| `towline` / Towline | Teal Metrocop warns a frozen narrow tether lane, then deals one physical hit with a short inward pull. Sidestep, close inside minimum range, break cover, leave the cell, interrupt or brace. | Towline + Runner. |
| `screenwright` / Screenwright | Blue Combine engineer warns then channels a passable, fixed guard screen protecting a captured group against attacks crossing its finite front. Flank, cross, use Magic, interrupt the exposed engineer or wait. | Screenwright + Soldier. |

Live GDD03/05/07,LOD-BESTIARY-B9-001 records author-delegated design/tuning.
The proposed solid deployable cover was narrowed to a projected Block screen:
it cannot obstruct routes or create another native collision/entity authority.
It differs from Bulwark's moving single-recipient guard and Pavise's self-stance.
Towline uses neither Climber/Deadcrab attachment nor a movement/status lock.
Canonical magic Walls and progression/event gates remain unchanged.

**Shared authorities and bounds:** EnemyRoster owns one finite commitment per
source on its existing25ms service. Capture exact source/primary Hero status-life
and progression plus run object,graph/progression objects,seed,campaign epoch/
seed/run ID. Screen recipients also bind exact incarnations. Source death/removal,
life replacement,displacement,support loss,hit-stun,attack prohibition,morale
flight,freeze/failure/clear or same-seed replacement retires work. Held and Muted
permit these stationary physical actions. Missed release beyond0.2s grace forfeits;
stationary recovery is fixed and repeated interruption cannot extend it.

Towline1.2s warning freezes a lane with half-width24 and endpoint overshoot24;
minimum target range96. Require the Hero's feet within4 units of the supported
floor and exact legal cell. One physical1d6+2 packet uses shared actor damage/
Block/Dodge. Only positive final HP loss on the surviving original Hero permits
one inward Pushback call: authored48,ordinary save/modifiers/immunity,maximum64
after modifiers,source standoff64. Pushback's opt-in maxTravel/validatePath seam
preserves all ordinary callers and its native movement authority. The constrained
pull requires both its normal sweep and full target collision hull clear,plus
support samples at<=16-unit intervals (at most5 points). Any obstruction or unsafe
path forfeits movement,without wall crush. Reentrant damage cannot repeat the
hit or drag a replaced actor. No velocity injection or private control lock.

Screenwright1s warning,3s active screen; center64 toward frozen observed Hero,
half-width80,height96. Source and plane anchors require support in the same legal
nonobjective/nontransition cell. Source drift<=4. Deployment checks both100-unit
lateral supported,hull-clear pockets at actual commitment facing and again at
release. At most16 warned/active screens,one per source; at most128 cached
HostileRegistry entries examined once,nearest three eligible ordinary allies
captured by distance then entity ID. Source excluded; no recurring scans. At use,
revalidate source,recipient incarnation,range240,current side,support and cover.
A finite front-to-back attack segment crossing adds25 percentage points to the
single canonical physical Block roll. Screens do not stack with each other;
Bulwark/Pavise/equipment still aggregate under33%. Magic and every existing Block
exclusion remain intact. No status pool,shield HP,entities,XP or drop channel.
No suitable cohort/capacity gives ordinary finite physical fallback fire,whose
warning/projectile bind the exact captured lives and scope.

Reference HP/speed/acquisition/warning/recovery/threat: Towline40/135/320/1.2s/
3s/3.5; Screenwright50/110/600/1s/4s/4. Screen fallback1d4+1(reference3.5),Towline
1d6+2(reference5.5). Failed admission retry/advance0.5s. STR/DEX/CON/INT/WIS/CHA;
Fighter/Rogue/Wizard weights;hit die;baseXP;morale:
Towline12/12/11/8/10/9;60/40/0;d8;50;6.
Screenwright10/10/13/12/11/10;80/20/0;d10;60;7. Both usesMagic=false.
RGB70,200,185 and100,155,230. Stock Metrocop/Combine models and spatial audio.
Full/reduced corridor/chevrons,open screen slats and countdown share fixed geometry
and expiry;2400-unit cull. Native render extents352/640 include fallback beams.

**Production:** sector2+ arena/ambush,one specialist; ordinary companions scale.
Append stable spawn ordinals; preserve cap/retry/fallback and protected geometry.
Initial512-plan sample: Towline34 planned/32 legal/7 early; Screenwright23/9/3
failed required25/20/5 exposure. Two Soldiers and a graph-cycle guard were too
restrictive for passable cover. Author-delegated revision uses one Soldier and
legal same-level exit/two in-cell lateral pockets. Revised512 plans/4941
encounters/32 mazes/parties1–4/dungeons1–5: Towline34/32/7,Screenwright32/32/8;
all prior thresholds pass. Behavioral,production and native-Draw presentation
harnesses pass; latest integration evidence is in DEVELOPMENT_PLAN.md.

**Native acceptance still pending:** actual Hero displacement,save feedback,
collision/gates/false floors,screen comprehension and shot origin attribution,
source interruption,death/revival/disconnect,freeze/reset/same-seed replacement,
full/reduced effects,audio,1–4-player networking/rewards and encounter balance.
No Source observation,performance acceptance,VPS deployment or Workshop update
is claimed. Native entities/collision/HP/render/network boundaries remain doubles.

## B10 — mobile-hazard cohort

| Identity | Distinct tactical problem and counterplay | Production composition |
| --- | --- | --- |
| `censer` / Censer | Amber Combine carries a warned danger circle along a frozen short approach. Leave its advertised route, take cover or interrupt; no homing. | Censer + Soldier. |
| `trailmaker` / Trailmaker | Green Metrocop retreats along a frozen route, leaving finite warned patches only at reached points. Leave the trail or interrupt instead of chasing straight through it. | Trailmaker + Runner. |

Live GDD03/05/07, LOD-BESTIARY-B10-001 records author-delegated mechanics and
implementation tuning. These are moving-zone and trailing-route commitments,
not Nodule's stationary cell gas, Repulsor's fixed displacement pulse, B6's
stationary traps, ordinary pursuit or reward-bearing summons. Both use physical
1d6+2 (reference5.5), one shared attack roll and at most one settlement per
captured Hero across the entire commitment. Block, Dodge, actor damage,
progression, statuses, HP, XP and drops retain their canonical owners.

**Commitment:** observe one acquired visible same-cell Hero; freeze a144-unit
straight route toward it for Censer or away for Trailmaker. Warn1.2s without
movement or damage. MotionV2 then travels at the actor's current canonical speed,
with a fixed1.8s movement deadline. Censer's radius64 danger follows actual source
position and ends at arrival/deadline. Trailmaker places at most three radius44
patches at start/midpoint/end only as those positions are reached; each has an
additional0.8s warning and1.2s active lifetime, clipped to ready+3.8s. It holds at
the endpoint while patches expire. No teleport to catch up, hidden retarget,
continuous damage, status rider, solid trap, native spawned entity or reward.

**Geometry/lifetime:** one EnemyRoster commitment and existing25ms service; at
most16 mobile sources and32 captured Hero lives per source, no recurring player
or world scan. Exact source/primary Hero status-life and progression plus exact
run, graph/progression, level seed and campaign epoch/seed/run ID bind the action.
Late join/revival cannot inherit a warning. Death/removal/replacement, failure,
clear/freeze, source hit-stun, attack prohibition, morale flight or Held cancels
movement and all patches. Muted permits physical attacks. Source displacement
beyond4 units from its last serviced position cancels. Primary-Hero death ends
future service; already admitted same-service hits remain party-order independent.
Reentrant callbacks cannot repeat or transfer damage.

Stay in one legal supported nonobjective/nontransition cell. Full scaled native
hull preflight and remaining-route support probes at<=24-unit intervals precede
movement. Start/mid/end each require two112-unit lateral escape routes, swept
with the Hero hull and five support probes per side (<=22.4-unit spacing).
Full route/escape geometry checks at0.1s cadence and again before damage fail
closed on gates, walls or opened false floors. Review caught and repaired an
interior lateral-floor gap missed by endpoint-only support. Target height -4..72,
exact physical cell and current LOS bound contact. Warning release grace0.2s;
a released service gap>0.2s forfeits instead of catching up. Fixed3.5s stationary
recovery begins once; further interruption cannot extend it. Failed admission
retries/repositions after0.5s.

**Tuning:** reference HP/speed/range/warning/recovery/threat Censer45/120/320/
1.2s/3.5s/3.5; Trailmaker35/150/320/1.2s/3.5s/3.5. STR/DEX/CON/INT/WIS/CHA;
Fighter/Rogue/Wizard weights; hit die; baseXP; morale:
Censer13/9/13/8/10/8;75/25/0;d10;55;6.
Trailmaker10/15/10/12/11/9;30/70/0;d8;50;5. Both usesMagic=false.
Stock models/combine_soldier.mdl and models/police.mdl; RGB220,150,60 and
130,195,85. Reuse spatial stock sound. Full/reduced capsule, actual moving ring,
dashed patch plans, arming/live circles and countdowns retain finite server
expiry; cull2400, conservative horizontal native render bounds208.

**Production/evidence:** sector2+ arena/ambush singleton specialists, scaled
ordinary companions; stable appended spawn ordinals42/43, ceilings/retry/fallback
and RNG scopes preserved. Conservative placement tests144-unit cardinal route,
1.33-scale hull, same-level legal exit and lateral pockets; runtime rechecks the
actual observed direction/support. Initial512-plan sample: Censer40 planned/39
legal/9 early, Trailmaker27/27/7; retained Waylayer19/17/4 failed25/20/5 after pool
dilution. One additional Waylayer selection ticket restores prior exposure,
without changing its mechanics or admission. Revised512 plans/4927 encounters/
32 mazes/parties1–4/dungeons1–5: Censer35/34/8, Trailmaker25/25/6,
Waylayer53/45/12; every retained threshold passes. Real actor generation/replay,
usable feats/classes, HP/XP once, spawning/variance, idempotence, caps, retries,
fallback, interleaved AI/service/MotionV2 and native-Draw boundary tests pass.
See DEVELOPMENT_PLAN.md for the canonical integration result.

**Native acceptance pending:** actual collision/support around gates, magic Walls
and false floors; moving warning/ring and individual patch clarity; source
interruptions/statuses; death/revival/disconnect and same-seed rebuild; full/reduced
effects/audio;1–4-player balance/networking, native HP/rewards and performance.
Automated native entity/collision/HP/render/network doubles are not Source
observation or acceptance. No VPS deployment or Workshop publication.

## Next checkpoint — B11: perception cohort

Provisional bounded two-identity perception cohort: a sound-cued hunter and a
visibility-conditioned stalker. These are proposals, not authored mechanics.
Reconcile FactionManager acquisition, invisibility, LOS, existing sound/combat
signals, MotionV2 and finite life-bound commitments before choosing identities.
Distinguish them from Watcher recruitment, Lurker ambush, Pincer routing and
ordinary pursuit. Require readable warnings, exploitable counterplay and bounded
cached/event-driven work; no hidden omniscience, compulsory camera behavior,
permanent invisibility, new targeting authority or extra summoned bodies.
Substitute a comparably bounded identity if needed. Target47/63 only for two
validated meaningful production identities. Preserve remaining roster breadth
and whole-phase campaign-aware director ecology; do not begin Big Loot or Events.

## B11 — perception cohort

| Identity | Readable tactical response | Production composition |
| --- | --- | --- |
| `listener` / Listener | Amber Metrocop hears actual non-crouching footsteps in its own room. Paired rings and a dashed route announce a harmless investigation toward the frozen sound position. Crouch/stay quiet, or change course after the cue. It needs fresh hearing and ordinary sight to begin a close melee strike. | Listener + Soldier. |
| `shy` / Shy | Violet fast zombie records a directly visible Hero, then approaches that frozen position only while no eligible nearby Hero has geometric LOS to it. A crossed eye marks the route. Maintain a sightline, have a teammate watch, interrupt or reposition. Camera direction is irrelevant; the body stays visible. Close visible Heroes can trigger ordinary warned melee. | Shy + Soldier. |

Investigations warn **0.8s**, move at most **128 units** within a fixed **1.4s**
window, and never deal damage. A fresh sensory observation and separate **0.9s**
fixed melee warning precede physical **1d6+2** through the existing narrow112-unit,
30-degree-half-angle melee authority. Completion/interruption uses fixed **1.8s**
stationary recovery. Late release beyond0.2s or a released-service gap over0.2s
forfeits movement, never catches up. Actual canonical effective MotionV2 speed
applies; no raw speed override. A useful approach must cover at least32 units;
failed admission retries after0.5s.

FactionManager owns event receipts and sensory candidate selection. Sound range
320/same cell, receipt TTL1.5s, coalescing0.2s, cap32; reject zero volume,
crouching, concealed and ineligible actors. No generic audio interception, gunfire
hearing or private Sixth Sense leak. Only post-activation/unconsumed and
post-interruption receipts can initiate. Shy sight acquisition320/same cell,
memory2s; any eligible same-floor Hero within480 with ordinary geometric LOS
counts as a witness. Idle selection, Hero-list cache and active witness checks
run at0.1s; at most32 Heroes inspected, oversized parties fail closed for unseen
movement. At most16 simultaneous investigations, served by the existing25ms
roster scheduler; no per-enemy timer or world scan.

Memories/commitments use exact source/Hero progression and status-life plus
run/graph/progression/level seed/campaign epoch/campaign seed/run ID. Footsteps
also bind Hero life and dungeon. The existing invisibility-forget seam clears
sound receipts, remembered sight and directed intent immediately. Source
interruption discards memory. Source/target death, removal, replacement,
freeze/failure/clear, drift>4, invalid support/hull or expiry retires investigation.
Held prevents/cancels investigation; a previously committed stationary melee
retains the accepted Held rule. Muted permits these physical actions. Morale
retires sensory work while retaining canonical flee locomotion: review caught
and repaired an early-return ordering defect, with an explicit dispatch regression.

Production templates `listener_detail` and `shy_pressure` enter sector2+
arena/ambush paths, one specialist plus ordinary Soldier enrichment. Append
unified spawn ordinals44/45. Require a legal same-floor exit and96-unit lateral
clearances, exclude safe/objective/transition cells, retain ceiling/retries/
budget-safe fallback. Runtime validates the actual scaled16x16x72 hull
(SizeScale0.33..1.33), every<=24-unit support step and legal same-cell geometry.
No locked-gate, magic-Wall, void or stale-route bypass; no alternate graph route,
extra bodies, new rewards, invisibility grant or hidden live-position pursuit.

Reference HP/speed/range/warning/recovery/threat:
Listener40/165/112/0.9s/1.8s/3.5; Shy50/180/112/0.9s/1.8s/3.5.
STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; HP die; baseXP; morale:
Listener10/15/10/11/14/9;25/75/0;d8;50;5.
Shy14/14/12/6/12/8;60/40/0;d10;55;6. Both usesMagic=false.
Models models/police.mdl and models/zombie/fast.mdl;
RGB235,195,100 and175,150,230. Stock spatial warning/pain/death/step cues.
Full/reduced dashed routes, paired rings/crossed eye, countdown and solid melee
sector remain semantically identical; native render bounds160, cull2400.

Pool dilution required measured selection-ticket repairs, not weaker exposure
thresholds. Exact trials, final weights and the unchanged512-plan sample are in
[the B11 validation record](validation/BESTIARY_B11.md). Final4952 encounters:
Listener43 planned/41 legal/6 early; Shy33/30/5; every earlier threshold passes.
Canonical manual155 chapters/31 chunks. Static/automated evidence is distinct
from native Source observation and acceptance; see DEVELOPMENT_PLAN.md.

## B12 — condition-interaction cohort

| ID / identity | Readable action and counterplay | Composition |
| --- | --- | --- |
| `absolver` / Absolver | Pale-cyan slave Vortigaunt channels a crossed-diamond tether for1.5s, curing one captured negative condition on an ally. Interrupt, mute, separate or break cover. No HP recovery/revival/self-cure. | Absolver + two Shamblers. |
| `exactor` / Exactor | Crimson Combine elite marks an ailing Hero's frozen position for1.25s. Leave the radius64 circle, cure the captured Bleeding/Immolated/Poisoned ailment, break sight or interrupt. One physical1d6+2 hit consumes that ailment only after positive HP loss on the surviving same life. | Exactor + Flamer. |

Absolver extends EnemySupport, including ordinary recipient eligibility, cached
128-candidate selection, same-floor/two-traversable-edge/range/LOS constraints.
Player-controlled Soldiers, bosses/clones, event Skeletons, self, dormant/dead and
friendly actors are excluded. Selection sorts distance then stable entity ID;
RPGStatusElements selects the lexically first live nonbeneficial condition.
Its nonstacking beneficial `support_cleansing` reservation uses canonical1.7s
expiry; one reserved recipient and at most16 simultaneous cleansing channels.
Support range360, warning1.5s, cooldown6s, scan0.3s, service0.1s, maximum service
gap0.25s, release grace0.2s. Source drift tolerance8. Capture recipient floor,
source/recipient and initiating Hero progression/status-life plus exact dungeon
scope. Hero LOS/range600 is acquisition-only; its life/acquisition eligibility
stays bound, and ally tether LOS/range stays mandatory throughout. Held permits
stationary support; Muted, morale, attack prohibition or hit-stun cancels it.

Exactor extends EnemyRoster's existing25ms service and uses canonical damage,
Block/Dodge, native HP, XP/drop authorities. One exact condition entry, one Hero,
one strike; no status application, AoE bystanders or hidden retarget. Source/
Hero life/progression, run/graph/progression, level seed, campaign epoch/seed/run
ID bind the mark. Source drift4, max16 marks, gap0.25s, release grace0.2s,
range360, fixed recovery3s. Ground support and two96-unit lateral escape routes
are revalidated at0.2s cadence and release, with<=24-unit support probes and the
Hero's actual native collision hull. Same legal cell and height−4..72 gate impact.
Held/Muted permit the stationary physical strike; morale/interruptions cancel.
No eligible ailment uses an ordinary warned physical shot with exact life,
release deadline and existing projectile cap. Failed geometry retries after0.5s.

Both use canonical `FirstNegative`/`ClearExpected`: natural expiry or removal/
reapplication cancels, while extension of the same status entry remains valid.
ClearExpected never consumes a replacement condition. Claim before callbacks;
reservation/source ownership checks preserve another cleanser's winning claim.
Zero/blocked/dodged/lethal damage cannot consume Exactor's captured condition.
Post-damage source/target death/removal/replacement aborts the cure. Freeze,
failure/clear and same-seed graph replacement retire commitments. No private
status scheduler, stat theft, summoned bodies or new reward authority.

Reference HP/speed/range/fallback warning/recovery/threat:
Absolver40/105/600/0.7s/2.2s/3.5 (fallback1d4+1);
Exactor50/130/360/1.25s/3s/4 (1d6+2).
STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; HP die; baseXP; morale:
Absolver10/10/12/12/15/10;80/20/0;d8;50;6, usesMagic=true/offensiveMagic=false.
Exactor14/12/12/10/11/9;65/35/0;d10;55;6, usesMagic=false.
Stock models `models/vortigaunt_slave.mdl` and `models/combine_super_soldier.mdl`;
RGB170,240,225 and230,95,115. Stock spatial cues, semantic crossed diamonds,
tether/mark and countdowns retain full/reduced clarity, cull2400, render bounds424.

Templates `absolver_detail` and `exactor_pressure`, sector2+ arena/ambush,
singleton specialists, appended spawn ordinals46/47; safe/objective/transition
exclusions, same-floor exit and100-unit lateral admission for Exactor. Physical
runtime support remains distinct from prebuild admission. Unchanged hostile
ceiling, ordinary companion enrichment, cap/retry/budget-safe fallback.

All forty sampled identities pass unchanged25/20/5 exposure gates in512 plans,
4944 encounters,32 mazes, parties1–4/dungeons1–5: Absolver27/25/12;
Exactor29/28/8 (planned/legal/early). Six measured +1 template tickets restore
exposure: Arc Caster, Absolver, Exactor, Silencer, Wirewright, Drubber. Full failed
and final counts: [B12 exposure](validation/BESTIARY_B12_EXPOSURE.md).
Canonical manual156 chapters/31 chunks. See [validation](validation/BESTIARY_B12.md)
and DEVELOPMENT_PLAN.md for final integrated evidence and native limitations.

## B13 — party-spacing pressure cohort

| Counted ID | Tactical identity | Production composition |
| --- | --- | --- |
| `outrider` / Outrider | Amber antlion warns a fixed narrow melee strike against an isolated Hero. Regroup with a visible nearby teammate, sidestep the wedge, retreat or interrupt. Solo play retains the whole warning. | Outrider + Soldier. |
| `conductor` / Conductor | Pale-blue Vortigaunt marks exactly two nearby Heroes' frozen positions with linked radius64 circles. Separate, leave either circle, break sight, mute or interrupt to cancel both strikes. Without a pair, it fires a warned Raw projectile. | Conductor + Shambler. |

FactionManager owns bounded cooperative queries using its existing cached Hero
roster; EnemyRoster owns commitments/service, ordinary pursuit, frozen melee and
canonical physical/Raw Magic damage. No new target selector, private resource,
status, reward, scheduler or native body. Cooperative eligibility uses living
acquirable Heroes, same-floor geometry and LOS; camera orientation is irrelevant.
Outrider considers protection within192. Conductor chooses the closest eligible
second Hero (stable entity ID breaks ties) within160 of the canonical primary,
both in the source's legal supported cell and visible to source and each other.

Outrider approaches within144, then uses the shared112-unit,60-degree single
melee sector with a1.1s warning and2.4s recovery. Only its captured Hero is a
recipient. Regrouping cancels; it does not convert to an unannounced fallback.
Conductor freezes two radius64 marks, warns1.4s and attempts one Raw Magic1d6+2
hit per captured Hero using one shared roll; recovery3.5s. Leaving either mark,
separating beyond160, concealment or lost LOS cancels the entire link. Both
recipients qualify before settlement so a lethal first hit alone cannot suppress
an already admitted second; source or recipient replacement during callbacks
still prevents stale settlement. No chained third victim or condition rider.

Capture exact source/participant progression and canonical status-life plus
run/graph/progression/level-seed/campaign epoch/seed/run ID. Fixed0.2s release
grace,0.25s maximum service gap and4-unit source drift; no late catch-up, re-aim or
warning inheritance after revival/join. Maximum32 cached Hero candidates,
16 simultaneous spacing commitments, failed-admission retry/reposition0.5s.
Both preflight source/target support and two96-unit lateral escape routes
per marked Hero using actual Hero collision hulls and support samples at most24 apart.
Geometry checks are bounded and repeat before release. Same-cell/height/cover
requirements prevent through-floor or mandatory-boundary attacks.

Held permits these stationary actions; Muted permits Outrider but prevents or
cancels Conductor Magic. Hit-stun, attack prohibition, morale flight, source or
participant loss/replacement, freeze/failure/clear and same-seed rebuild cancel.
Fixed stationary recovery never extends under repeated interruption. Emitted
solo bolts retain canonical projectile service and exact-life ownership; only
the originally warned Hero can take that bolt's damage, so late joins cannot
inherit its warning. Ordinary interruption preserves an already emitted bolt.

Reference HP/speed/threat: Outrider45/170/3.5; Conductor40/110/4.
STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; HP die; XP; morale:
Outrider14/15/11/6/12/8;45/55/0;d10;55;6, usesMagic=false.
Conductor10/12/12/12/14/10;0/0/100;d8;50;6, usesMagic/offensiveMagic=true.
Both attack1d6+2 (physical melee versus Raw Magic). Conductor range360.
Stock models `models/antlion.mdl` / `models/vortigaunt.mdl`;
RGB225,170,80 /150,190,250. Finite full/reduced warnings retain the melee wedge
and isolation glyph or paired circles/link/countdown. Stock positional audio.

Templates `outrider_detail` / `conductor_pressure`, sector2+ arena/ambush;
singleton specialists, appended spawn ordinals48/49, existing ceiling, companion
enrichment, deterministic RNG and fallback paths. Both reject safe/objective/
transition cells and require same-floor exit/lateral admission pockets. Runtime
physical support remains distinct from prebuild admission.

Design authority: live GDD03/05/07 `LOD-BESTIARY-B13-001`. Validation and measured
exposure are recorded in [B13 evidence](validation/BESTIARY_B13.md) and
[B13 exposure](validation/BESTIARY_B13_EXPOSURE.md); implementation counts do not
imply native Source acceptance.

## B14 — resource-pressure cohort

| Counted ID | Tactical identity | Production composition |
| --- | --- | --- |
| `siphoner` / Siphoner | Violet Stalker warns a frozen ground mark. Positive final HP damage on the surviving captured Hero drains up to12 Magic; it gains none. Leave the circle, break sight, mute or interrupt. | Siphoner + Runner. |
| `accumulator` / Accumulator | Gold slave Vortigaunt pays for warned Raw marks from its canonical Magic pool. When insufficient, it exposes itself during an interruptible self-recharge instead of attacking. Deny the recharge or exploit the stationary window. | Accumulator + Soldier. |

Both marks use radius64, range360, warning1.25s and canonical Raw Magic1d6+2.
Ordinary defenses and Arcane Shield resolve before Siphoner's rider; zero,
negated or lethal damage never drains. Loss is min(12,current Magic), not HP,
voluntary spending, an extra shield-break event, transfer or permanent loss.
Accumulator pays base40 through OffensiveMagicCost/Quantum rounding at release;
missing a released mark does not refund its cost. Insufficient current Magic
at release cancels damage. Below affordability at admission, it channels2s for
min(45,100-current Magic), with no attack. Normal regeneration continues through
the shared scheduler. Recovery is3.5s for Siphoner,2.5s for either Accumulator action.

Generated Magic effects use canonical seams: pre-debit full-Magic snapshot,
Feedback Loop's six-continuation restoration cap and one paid-cast observer.
Accumulator may generate Aura Burst; its ordinary supplemental aura is distinct
from the captured mark and can reach nearby unmarked Heroes. Drain and recharge
cannot trigger that aura. Only the exact warned Hero receives mark damage/drain.
No new resource pool, acquisition authority, body, status owner or recurring timer.

Bind source/Hero progression, canonical status-life and pool references, plus
run/graph/progression/level-seed/campaign epoch/seed/run ID. Claim before native
sync, dice, damage and observer callbacks. Replacement lives cannot inherit a
warning or settlement; newer attacks are not erased. Claimed callback failures
retire by deadline. Fixed release grace0.2s, service gap limit0.25s, source drift4,
maximum16 resource commitments, failed admission retry/reposition0.5s. Support
and actual Hero-hull escape follow the existing condition geometry: two96-unit
lateral paths, samples24 apart, checks at most every0.2s plus release. Source and
mark occupy one legal supported cell; gate/objective/transition exclusions remain.
Recharge requires source support and the captured living visible Hero within360.
Held permits stationary action; Muted, morale flight, attack prohibition,
hit-stun, cover loss, displacement, death/removal, freeze/failure/clear and rebuild
cancel commitments. Repeated interruption cannot extend fixed recovery.

Reference HP/speed/threat: Siphoner35/125/3.5; Accumulator50/100/4.
STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; HP die; XP; morale:
Siphoner8/12/10/14/15/10;0/0/100;d8;50;4.
Accumulator10/10/13/14/14/9;0/0/100;d10;55;6.
Both usesMagic=true and physicalAttack=false. Siphoner offensiveMagic=false;
Accumulator offensiveMagic=true/discreteMagic=true. Explicit template capabilities
prevent inert physical feats and restrict Quantum/Aura eligibility to paid casts;
prior actors retain their existing rules. Models `models/stalker.mdl` and
`models/vortigaunt_slave.mdl`, RGB185/115/235 and235/205/95. Stock spatial audio,
drain funnel/attack lightning/recharge battery glyphs, finite countdowns and frozen
marks in full/reduced modes; distance cull2400, horizontal render bounds428.

Templates `siphoner_pressure`/`accumulator_detail`, sector2+ arena/ambush,
append-only spawn ordinals50/51, singleton specialists, canonical enrichment,
ceiling/threat/placement/fallback and rewards. All44 sampled identities pass
unchanged25/20/5 exposure gates across512 plans/32 mazes/parties1–4/dungeons1–5,
4943 encounters: Siphoner45/43/9; Accumulator46/42/9 planned/legal/early.
Eleven trials and final26 broad+30 sector2-only B14 ticket additions (including
initial4 per new template) are preserved in [exposure](validation/BESTIARY_B14_EXPOSURE.md).
Manual158 chapters/31 chunks. Design: live GDD03/05/07 `LOD-BESTIARY-B14-001`.
Validation: [B14 evidence](validation/BESTIARY_B14.md); no native acceptance implied.

## B15 — careless-fire interaction cohort

| Counted ID | Tactical identity | Production composition |
| --- | --- | --- |
| `fusilier` / Fusilier | Copper Combine soldier freezes a narrow firing lane for1.25s. The first body intercepts its physical shot, including a captured ordinary hostile. Sidestep, use an enemy as cover, interrupt or break sight. | Fusilier + Shambler. |
| `bombardier` / Bombardier | Ochre Combine elite freezes a radius72 ground blast for1.6s. Captured Heroes and ordinary enemies can be hit; lure companions into the circle and leave. Body-blocking cannot absorb the whole area attack; solid cover protects. | Bombardier + Runner. |

The new interaction is intentional allied interception versus allied splash,
not a renamed projectile pattern or numeric variant. Both deal physical1d6+2
through existing dice, mitigation, HP/death and reward paths. Range360;
Fusilier recovery3s, Bombardier3.5s. Source+48 to frozen observed Hero center
forms the Fusilier lane, traced with radius4 against actual bodies/world.
The first uncaptured/replacement/excluded body harmlessly absorbs the shot;
no piercing or retargeting. Blast containment uses the frozen Hero ground point,
radius72 and vertical-4..72, with cover traced from mark+24. One shared roll and
at most one native settlement per captured recipient. The original Hero can
leave the mark without canceling it, allowing bait; losing that Hero life before
release cancels. No source self-hit.

Faction unity has one narrowly owned exception for these exact attack packets;
other attacks retain existing protection. No general infighting, new hostile
target selection, aura/status spillover, allegiance change or synthetic Hero kill
credit. Named bosses/clones, event Skeletons, friendly summons and human-controlled
Soldiers cannot be friendly-fire recipients. Ordinary defeated enemies retain
canonical earned-contribution XP/drop settlement and enemy-attacker attribution;
these packets create no Hero killing-blow credit or new contribution ledger.

EnemyRoster owns the commitments and shared service. Source/primary and every
recipient bind exact progression/status-life and run/graph/progression/seed/
campaign scope before the warning. Capture at most32 cached Heroes and128 cached
hostiles; fail closed on overflow. At most16 crossfire commitments. Source drift4,
fixed release grace0.2s, service-gap limit0.25s, geometry cadence0.2s and failed
admission retry/reposition0.5s. Source/mark support, same legal cell, actual Hero
hulls and two96-unit lateral escapes with support samples<=24 keep solo dodge
space explicit. Claim before callbacks; replacing actors/attacks cannot inherit
or erase settlement. A claimed failure expires at the original deadline.
Held and Muted allow stationary physical attacks; hit-stun, morale and attack
prohibition cancel. Recovery is stationary, finite and nonextending.

Sector2+ arena/ambush templates `fusilier_screen` and `bombardier_pressure` preserve
singleton specialists, ordinary companion enrichment, deterministic streams,
ceilings/threat and fallback. Append ordinals52/53; explicit progression registry
55 ordinary+4 named bosses. Same-floor exit/lateral admission excludes safe,
objective, transition and gate cells. No new wandering weights or entity bodies.

Reference HP/speed/threat: Fusilier45/125/3.5; Bombardier55/100/4. Stock models
Combine soldier/elite; RGB225/135/75 and210/175/80. STR/DEX/CON/INT/WIS/CHA;
Fighter/Rogue/Wizard weights; HP die; XP; morale:
Fusilier12/13/12/10/11/9;60/40/0;d8;50;5.
Bombardier14/10/14/10/10/8;80/20/0;d10;55;6. Both usesMagic=false;
ordinary physical feats, no Soldier-specific gun capabilities. Full/reduced
warnings preserve the frozen lane/body brackets or blast/fragment glyph and
countdown, finite network expiry, cull2400 and conservative500 horizontal bounds.
No emitters, dynamic lights or model bodies. Stock positional charge sound.

Live GDD03/05/07 `LOD-BESTIARY-B15-001` holds the authored design and tuning.
Automated evidence and measured production exposure are recorded in
[validation](validation/BESTIARY_B15.md) and
[exposure](validation/BESTIARY_B15_EXPOSURE.md). Boundary doubles do not establish
native Source observation or acceptance. Preserve prior cohorts and the complete
campaign/finale/succession/Abundance/Level21 regression constraints.

## B16 — movement-discipline cohort

| Counted ID | Tactical identity | Production composition |
| --- | --- | --- |
| `halter` / Halter | Amber Combine elite demands **STOP** through a visible tether. Remain below25% of legitimate walk speed during the final0.4s judgment. | Halter + Soldier. |
| `pacer` / Pacer | Cyan Metrocop demands **KEEP MOVING**. Sustain at least25% of legitimate walk speed during the final0.4s judgment. | Pacer + Runner. |

Gap review found action discipline absent from the55-identity roster. These
opposite sustained locomotion requirements are distinct from frozen floor marks,
perception acquisition, guard stances and on-hit retaliation. A Hero can move
out of an ordinary mark and stop; Pacer instead requires continued locomotion.
Halter creates an intentional pause against companion pressure. Both remain
interruptible and cancel when cover, range or the legal room relationship breaks.

Warning1.6s includes1.2s preparation and0.4s judgment. Every canonical FinishMove
observation in the judgment window is considered; any violation permits one
physical1d6+2 packet at release. At least0.3s of distinct observed coverage is
required, with no sample gap>0.15s and a final sample within0.1s of release.
Canonical DodgeMovement owns voluntary speed and legitimate class/status-adjusted
walk targets. No new speed calculation, camera/input test, movement override,
position-history pursuit or forced-movement penalty. Unknown/stale motion,
non-walk movement, forced movement (including a sample from before force expiry),
or a Hero unable to move voluntarily cancels. Ordinary Block/Dodge/HP/death/XP/loot
remain authoritative. No status, extra body, private resource or permanent loss.

One exact reservation per Hero spans both modes, preventing contradictory orders.
At most16 live commitments use the existing roster Think service. Source/target
bind exact progression/status-life plus run/graph/progression/seed/campaign scope.
Range360, source drift4, fixed0.2s release grace,0.25s service gap,0.2s geometry
cadence,0.1s aim-snapshot replication,0.5s failed-admission retry/reposition,
3s stationary recovery. Runtime validates current supported legal same-cell
positions and two96-unit movement options with the Hero's actual hull, support
samples<=24. Source Held/Muted permit stationary physical actions; morale,
intimidation and hit-stun cancel. Claim before native callbacks; the shared
packet guard validates actual recipient/attacker/inflictor and one admission
before/after mitigation, without granting faction exceptions. Failed/reentrant
callbacks cannot repeat damage, transfer warnings, erase newer attacks or hold
reservations/recovery beyond their original deadlines.

Sector2+ arena/ambush singleton templates `halter_detail` and `pacer_chase`,
append ordinals54/55; explicit progression registry57 normal+4 named bosses.
Placement excludes safe/objective/transition/gate cells and requires a legal
same-floor exit/lateral room. Preserve independent RNG, threat/entity caps,
ordinary companion enrichment and budget-safe fallback. No wandering additions.

Reference HP/speed/threat:45/110/3.5 and35/145/3.5. Stock Combine elite/Metrocop;
RGB235/145/85 and90/215/225. STR/DEX/CON/INT/WIS/CHA;
Fighter/Rogue/Wizard weights; HP die; XP; morale:
Halter12/11/12/12/12/9;65/35/0;d8;50;5.
Pacer10/15/10/12/12/9;35/65/0;d8;50;5. Both usesMagic=false with usable ordinary
physical feats. Stock positional charge/pain/death/footstep sounds. Full/reduced
warnings retain STOP/KEEP MOVING text, octagonal pause/double-chevron glyphs,
tether from server-visible snapshots, PREPARE/JUDGMENT countdown, final-window
emphasis, finite expiry/cull2400 and conservative500 bounds. No client tracking
of replacement entities. Canonical manual160 chapters/32 chunks.

Live GDD03/05/07 `LOD-BESTIARY-B16-001` authored and read back before implementation;
final evidence and continuation synchronized in00/01/03/05/07. See
[validation](validation/BESTIARY_B16.md) and
[exposure](validation/BESTIARY_B16_EXPOSURE.md). Counts describe production
implementation, not native Source observation or acceptance.

## B17 — companion-interaction cohort

| Counted ID | Tactical identity | Production composition |
| --- | --- | --- |
| `interposer` / Interposer | Warns a frozen route into the firing line between one ally and Hero, then holds its actual body there briefly. Change angle, flank, use piercing/area attacks, interrupt or defeat it. No Block bonus, immunity or redirected damage. | Interposer + Soldier. |
| `mourner` / Mourner | Places a visible finite oath on one ally. That ally's legitimate defeat during the armed oath starts a separate fully warned shot against the original Hero. Prioritize Mourner, break the tether, wait out the oath or trigger then evade. | Mourner + Shambler. |

The targeted gap review found proactive bodyguard positioning and visible
ally-death kill-order pressure absent from the57-identity roster. Interposer
protects an ally with its ordinary physical body, unlike Pincer's flank,
Waylayer's junction occupation or Screenwright's projected Block. Mourner
responds to a preselected ally's defeat, unlike Repriser's own-hit reaction or
Afterburst's own death. Both add a production tactical decision without bodies,
private HP/status/resource pools, permanent loss or broad faction exceptions.

EnemyRoster owns finite commitments and shared service; EnemySupport owns
ordinary-ally eligibility; EnemyRemains supplies exact-life legitimate defeat
receipts; MotionV2 owns movement; existing combat/status/HP/XP/loot settle outcomes.
One ward reservation per ally spans both roles, cap16 commitments including
fallback shots. Selection examines at most128 cached registry entries and sorts
by distance then stable entity ID. Exclude self, either B17 identity, named
bosses/clones, events, summons and players. Capture exact source/Hero/ward
progression and status-life plus run/graph/progression/seed/campaign ownership.

Interposer warns0.8s, moves32–160 units toward a frozen point64 units from its
ally toward the observed Hero (ally–Hero separation160–360), then holds2s.
Movement ends at readiness+1.8s; hold cannot exceed readiness+3.8s. Actual actor
hull/endpoint separation and support samples<=24 validate its route. Destination
never follows unseen motion. No attack or automatic protection occurs while
moving/holding. Mourner warns0.8s, then watches its ward for3s. Only a valid
sealed/open corpse receipt matching the captured ward's living life/progression,
sealed in that armed interval and observed within0.25s, may trigger once.
The receipt and ordinary corpse reward remain unconsumed. No killer retargeting.

With no eligible ward, both use the same ordinary full1.2s physical firing-lane
warning as Mourner retaliation. The lane freezes at shot onset; first real
body/world collision absorbs it, and only the captured Hero may take one
physical1d6+2 attempt. No B15 allied-fire permit. Actual Hero-hull96-unit lateral
paths/support are checked; cover, evasion and interruption cancel or evade.
Ordinary Block/Dodge/HP/rewards remain authoritative. Exact guarded native
packets, one claim before callbacks and current lifetime/geometry checks prevent
replay, replacement-life transfer or newer-attack/token erasure.

Hero range360; ward range240/drift32; stationary source drift4; service gap0.25s;
geometry cadence0.2s plus release; visible ward snapshots0.1s; shot release
grace0.2s; failed-admission retry/reposition0.5s; fixed3s stationary recovery.
Held prevents bodyguard movement but permits stationary physical actions; Muted
permits both; morale/hit-stun/attack prohibition cancel. Death/removal/life
replacement, cover/support/range/legal-cell failure, freeze/reset and stalled
service retire work without catch-up movement or damage.

Singleton templates `interposer_detail`/`mourner_detail` use sector2+ arena/ambush
admission, legal exits/lateral space, safe/objective/transition/gate exclusions
and ordinary budget-safe replacement. Append spawn ordinals56/57; registry59
normal+4 named bosses. No new wandering weights. Reference HP/speed/threat:
65/140/4 and40/115/3.5. Stock Combine elite RGB125/175/225 and Metrocop
RGB195/125/215. STR/DEX/CON/INT/WIS/CHA; Fighter/Rogue/Wizard weights; HP die;
baseXP; morale: Interposer14/11/14/10/12/9;75/25/0;d10;55;6.
Mourner10/12/11/13/12/10;40/60/0;d8;50;5. Both usesMagic=false with usable
ordinary physical feats. Stock positional cues. Full/reduced route/body shield,
oath/broken-oath and fixed lane glyphs retain literal BODYGUARD/OATH/RETALIATION/
SHOT and countdowns; finite server snapshots, cull2400 and conservative500 bounds.
Manual161 chapters/32 chunks preserves all prior content.

Live GDD03/05/07 `LOD-BESTIARY-B17-001` was authored and read back before
implementation. Final validation/exposure and native gaps are recorded in
[validation](validation/BESTIARY_B17.md) and
[exposure](validation/BESTIARY_B17_EXPOSURE.md). Counts describe production
implementation, not native Source observation or acceptance.

## Historical B18 selection gate — now implemented

Select and author the next coherent pair through targeted ledger/shared-authority
review. Target61/63 only after both meaningful identities pass production gates.
Four additions remain after B17; no cosmetic/affinity/boss/event/summon inflation.
Preserve exact wards and finite bodyguard/oath/retaliation ownership, all prior
cohorts and complete campaign/finale/succession/Abundance/Level21. Whole-phase
campaign-aware encounter themes, novelty memory, topology, pacing and quantitative
coverage remain within Bestiary before Big Loot or Events.

## B18 — prison-edict cohort

| ID / identity | Tactical response | Ordinary composition |
| --- | --- | --- |
| `censor` / Censor | Warns a brief cease-fire. A new canonical attack during its watch triggers a **new full warning**, then a fixed physical shot. Stop attacking briefly, interrupt, break sight or deliberately trigger and evade. | Censor + Shambler. |
| `surveyor` / Surveyor | Marks a threatened disc with a visibly displaced refuge. Enter the refuge, leave the outer ring, break sight or interrupt/mute the caster before its single Raw strike. | Surveyor + Soldier. |

Censor observes the existing `RPGAbilityRules:CommitAttack` seam, used by firearms,
crowbar, ordinary Magic, Magic Forms and Wand. It does not inspect buttons or
react to passive damage, previously released projectiles, failed inputs or
other equipment actions outside that seam. Preparation0.8s, watch2.4s; one new
commit in that interval starts a separate1.2s shot warning. A stale observation
older than0.25s cannot trigger retaliation. Watch-end processing grace0.2s
allows an on-time event to reach the next service tick without extending the
armed interval. Failed/refunded Forms/Wand discard their captured order/life
receipt; successful casts cannot transfer it to a new warning. The original captured Hero remains
the only possible victim; the first body/world cover absorbs the frozen lane.
Actual Hero-hull96-unit lateral paths on both sides preserve evasion.

Surveyor freezes a radius144 disc at the observed Hero's feet and a radius48
refuge displaced96 units perpendicular to the source-to-Hero line. Deterministic
positive-then-negative orientation selection consumes no RNG. Both a supported
Hero-hull route to the refuge center and a160-unit opposite outer escape must
exist; all route samples (at most8 segments, spacing<=24) stay in the same legal
cell. Marks never track. After1.6s, only the original Hero still inside the outer
disc and outside the refuge may receive one Raw Magic1d6+2 packet. Current
support/route ambiguity, forced movement or inability to move voluntarily cancels
rather than imposing unavoidable damage. The refuge is offset, so it demands a
directional route choice rather than duplicating Cordon's concentric annulus.

Both extend EnemyRoster commitments/shared service, canonical life/status/
combat/HP/reward authorities and guarded native packet validation. Hero order
ownership is shared with Halter/Pacer; no opposing demands overlap. Exact source
and Hero progression/status lives plus run, graph, progression, seed and campaign
bind all work. Maximum16 B18 commitments, range360, source drift4, service gap0.25s,
geometry refresh0.2s plus release validation, release grace0.2s, recovery3s and
failed admission/reposition0.5s. Claim before callbacks; replacement tokens,
attacks or lives cannot inherit damage, be erased, replay or extend recovery.
Censor's stationary physical actions permit Held/Muted; Surveyor requires Magic
eligibility. Morale, hit-stun and attack prohibition cancel both. Visibility,
legal support, range, lifecycle, freeze/reset and missed service remain gates.

Censor: Combine soldier RGB210/170/110, referenceHP45 speed115 threat3.5;
STR/DEX/CON/INT/WIS/CHA11/12/12/13/12/10, Fighter/Rogue/Wizard50/50/0, HPd8,
baseXP50, morale5, usesMagic=false. Surveyor: Vortigaunt RGB110/215/190,
referenceHP40 speed100 threat4; abilities9/11/11/15/14/10, weights0/0/100,
HPd8, baseXP55, morale5, usesMagic=true/Raw. Both damage1d6+2 reference5.5;
canonical class/usable feats/HP growth/defenses/XP/drops remain authoritative.
No private resource pools, forced control, extra bodies or external assets.

Singleton templates `censor_detail` and `surveyor_detail` enter sector2+
arena/ambush selection. Append ordinals58/59; preserve prior spawn order,
enrichment, seeded streams, threat/hostile ceilings and same-body legal fallback.
Safe/objective/transition/gate cells are excluded; same-floor exit and lateral
room are required, with Surveyor refuge/outer-escape placement clearance.
Full/reduced rendering uses finite source/aim/refuge/phase/deadline snapshots,
literal CEASE FIRE/RETALIATION and REFUGE/LEAVE RING instructions and countdowns.

Implemented and statically validated: **61/63** normal identities,
frozen baseline18, **43/45 additions**, **2 remain**. Tests, measured exposure and
native limitations are recorded in `validation/BESTIARY_B18.md` and the current
DEVELOPMENT_PLAN checkpoint. Automated boundary doubles are not Source acceptance.

## Next checkpoint — B19: final roster breadth

Select and author the final coherent pair through targeted remaining-niche
review; target63/63 only when both qualify as meaningful production identities.
Preserve B18 attack-observation timing, full retaliatory warning, shared Hero
orders, displaced-refuge access/escape, exact packet/life ownership and all prior
cohort/campaign regressions. Completing the count does not finish Bestiary:
campaign-aware encounter themes, novelty memory, topology, pacing and quantitative
coverage remain before Big Loot or Events. Do not begin the next phase early.
