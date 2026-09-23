# Bestiary expansion — frozen baseline through B8

Baseline frozen against `main` at
`855b3b9709675b5b035b12c58658eb74f3037fa9` on September 23, 2026.
The live GDD remains design authority; `DEVELOPMENT_PLAN.md` records current
validation/publication evidence and sequencing. The complete phase brief is
`briefs/BESTIARY_UPDATE.md`.

## Counting contract

The baseline contains **18 gameplay-meaningful normal enemy identities**.
The whole-phase target is **63** (18 × 3.5), requiring **45 additions**.
B1–B8 add twenty-three identities: **41/63**, or **23/45 additions**; **22 remain**.
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

## Next checkpoint — B9: tether-and-cover cohort

Provisional bounded two-identity scope: a visibly warned tether/reel attacker
and a finite deployable-cover engineer. These are proposals, not authored
mechanics. Reconcile canonical Pushback/locomotion/Block, existing barriers,
Climber/Deadcrab attachments and progression geometry before choosing concrete
identities. Target43/63 only if two distinct production behaviors validate.
No private movement lock, locked-gate/void bypass, permanent route obstruction,
reward-bearing summoned bodies or unbounded props. Require breakable/escapable
commitments, legal alternate passage, source/target/run lifetimes and explicit
entity/work caps. If a proposal cannot meet those contracts, choose a comparably
bounded distinct tactical identity and record the design before implementation.
Retain remaining roster breadth and whole-phase campaign-aware director ecology;
do not begin Big Loot or Events.
