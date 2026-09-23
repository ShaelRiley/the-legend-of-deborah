# Current checkpoint — Tanuki's Ring

Built on independently verified remote main
`c29e372617380de753c1b11547891dbea75d496e`; clean working tree, no newer work
replaced. Followed live GDD 00 → 01 → relevant 03/06/07/90. The retained
September 22 P7 author brief delegates missing implementation/balancing and GDD
synchronization. Recorded and read back `LOD-TANUKI-RING-001` in 03/06/07/90 and
HUMAN after a fresh protected-control-aware document read.

The minimum-Rare, one-hand **Tanuki's Ring** grants passive **Statue** after two
continuous seconds of server-observed stillness on solid non-actor ground.
No arrow recipe, Magic spending, cooldown or fixed duration. Innate allowance
is floor(50 x quality / 100); the existing independent 1/8 innate wearable pool
includes the ring without changing original seven-family RNG or frozen records.
Ordinary equipment ownership, occupancy, inventory and derived grants apply.

Canonical status authority owns the positive, source-bound Statue state outside
the curable negative-condition registry. Its damage gate runs before native
Dodge/Block, mitigation, Magic diversion, status observation and attribution.
Valid Statue takes no direct, ambient, AOE or damaging-status HP loss. Incoming
hits do not end it; existing ailments keep their clocks and recovery rolls.
Scripted death and campaign TIME OVER remain authoritative. Canonical Invisible
sources own enemy acquisition; the shared bounded pursuit cleanup now serves both
Statue and Veil. Damage factions are unchanged, and unrelated concealment survives
Statue cleanup. Human observers see the stone body.

Normal SetupMove samples the wait and FinishMove confirms actual position and
velocity before activation. Require deployed, living, walking Hero, ready graph,
no vehicle, moving/actor support, dash or forced displacement. Maximum sample gap
0.25s, maximum drift1 unit from the initial anchor, maximum velocity/base velocity
1 unit/s. Missing observations reset instead of crediting idle time. Movement,
jump/crouch, attack/use input, any Magic/technique/item-use attempt and effective
outgoing HP damage reset the full wait; looking around alone is permitted. Shared
input suppressors notify Statue before removing Held/weapon/Magic keys, so blocked
attempts cannot preserve invulnerability. Actual motion is rechecked at every
damage/acquisition decision, and safe teleport retires the state before moving.
No motion clamp, extra jump, wall traversal or per-item timer was added.

Wait and activation bind the exact item and hand slot, Hero state/identity/life,
run/seed/graph. Source mutation, same-tick remove/re-equip, death/respawn/disconnect,
role/staging/freeze/failure/level changes and map cleanup invalidate both. Expected
source tokens reject stale callbacks. Source-owned stone material restores its
prior value without overwriting an intervening external material change. Shared
Invisible maintenance also retires invalid protection without new recurring scans.
The HUD's existing beneficial-condition path shows STATUE. An original generated
0.24-second four-note cue and 0.3-second procedural stone flourish accompany the
bundled granite material. No third-party assets. Item descriptions and both manual
readers explain activation and breaks. `lod_tanuki_testkit` equips the ring,
preserves displaced inventory and marks the run unranked without refilling Magic.

Validation: **132 integrated suites pass, zero failures**; Lua syntax, generated
manual and whitespace gates pass. The focused suite exercises real equipment
ownership/rewards, exact two-second timing, free activation, real GM damage denial
before defense spending, an actual scheduled Immolated tick with unchanged HP,
Magic and ailment clock, canonical enemy target loss, input/physics breaks,
source-safe concealment/material cleanup and lifecycle rejection. Existing Ring,
Gloves, Hat, Boots, Quickstep, LuaJIT/crash replay, overhead barriers, rescue and
Hero/Soldier queues remain passing. Original audio is reproducible mono PCM,
bounded in duration/size and within the existing 6-bit cue transport. First
integrated run:131/132; only the audio test's fixed59-cue expectation failed after
the new60th cue. Updated that catalog expectation and retained all behavior checks.
Focused Statue/audio checks and the final integrated run pass. Final review then
moved technique cancellation after the existing session guard so a stale callback
cannot cancel a fresh Statue; the new assertion and all six equipment-move family
suites pass on that final tree. These results are
automated/headless evidence, not native Source acceptance.

Native gate pending: as a developer-mode admin on gm_flatgrass, run
`lod_tanuki_testkit`. Stop on solid ground for two seconds; verify stone appearance,
STATUE HUD, one brief chime/flourish, target loss and no HP/Magic loss from enemy
hits or ambient/AOE damage. Move or attack: protection must end immediately, with
a fresh two-second wait. Check forced push, moving support, ring removal, death,
dungeon transition and another player's view. Capture console_latest.txt and
rpg_summary_latest.txt. Check stone material restoration and co-op audiovisual
readability; the stock pickup representation remains provisional. No VPS or Steam
Workshop deployment; prior native acceptance obligations remain open.

Next bounded P7 checkpoint: **Wand weapon category**. Reconcile the retained
Wizard/Rogue/class restrictions, Beam delivery, finite charges/no reload and
procedural element/Content/status brief with live GDD and the existing weapon,
Magic, item identity and resource authorities before implementation. Define finite
ownership/class/resource/delivery/lifecycle checks; preserve accepted movement,
overhead barriers, rescue progression and Hero/Soldier queues. Do not re-audit
completed checkpoints without new contradictory evidence.

---

# Previous checkpoint — Boots of the Heavy Plumber

Built on verified remote `61f5577f3d7c1a19c2eb7797a6ed3cb2b5950920`.
Clean local main matched remote; no newer work was overwritten. Read AGENTS.md
and live GDD 00 → 01 → relevant 03/06/07/90. The Boots' exact author brief is
retained in `docs/SEPTEMBER22_MASTER_BRIEF.md`, including express authority for
missing design/balancing and GDD synchronization. Recorded and read back
`LOD-HEAVY-PLUMBER-001` in normalized 03/06/07/90 and HUMAN. This is an automatic
landing attack, not an added directional recipe.

Minimum-Rare feet-slot Boots grant **Heavy Stomp: 2d6 + STR physical contact damage,
no Magic cost, one attempt per airborne excursion, 0.65-second minimum interval**.
The independent 1/8 innate reward pool now includes Boots; original seven-family
RNG, frozen records and normal item economics remain intact. Innate allowance is
floor(50 x quality / 100). Definition grants and passive descriptions use the
existing equipment registry without permanent feat ownership or input listeners.

The ordinary SetupMove authority samples an armed Hero's movement; FinishMove
checks actual first-hit native swept-hull contact. Arming requires equipped Boots
and server-observed solid non-actor ground. Require downward speed at least120,
upward contact normal >=0.7, feet above the collision top before movement and
within3 units at contact. Samples expire after0.1s and reject displacement >128.
No target scan or per-item recurring timer. The bounce belongs to the same
excursion; actor standing, contact spam and midair item swaps cannot rearm it.

The canonical combat-roll module now exposes an innate physical-contact adapter,
using existing actor dice, STR/CON, class/gear modifiers, native Dodge/Block,
status observation, attribution, XP and combat feed. It does not cast Magic or
impersonate the held weapon. Native firearm hit feedback excludes that explicit
contact tag, avoiding an accidental gun-stun while holding a firearm. A committed
stomp reveals Veil. Muted and holding a throwable do not disable this physical
ability; voluntary movement denial does. No built-in element, Content rider,
extra stun or displacement of the victim was introduced.

Safe travel validates projected full-footprint generated support, exact cells,
normal/Warden/jail transitions, void/stair/hazard rejection and the standing hull's
upward clearance. Native overhead geometry bounds a nominal56-unit rebound with
4-unit margin and minimum8-unit clearance; launch speed uses actual server/player
gravity. Preserve horizontal momentum, ordinary Source gravity/collision and all
accepted movement/overhead barriers. No teleport, old jump-height clamp, extra
Dodge, invulnerability or fall-damage exemption. Unsafe bounce preflight consumes
that contact's latch but produces no stomp or bounce. A valid defended contact
still self-bounces once. Damage reactions revalidate the actor before rebound.

Exact source/feet slot, Hero identity/state/life and run/seed/graph bind arming to
landing through shared equipment and safe-travel authorities. Removal/replacement,
role/death/staging/freeze, forced displacement, teleport and stale commands cannot
revive an old descent. Only a fresh solid-ground observation rearms after
invalidation. Shared safe relocation explicitly retires the airborne record.
The shared impact cue, feedback feed, item text and both manual readers describe
the passive. `lod_heavy_plumber_testkit` equips Boots, preserves displaced gear
and marks the run unranked without changing Magic.

Validation: all **131 integrated suites pass, zero failures**. The focused suite
executes real item generation/grants, graph locks, source binding, contact resolver,
physical combat and rebound preflight with native trace/entity boundaries. It
covers ownership/value/rewards, no resource spending, actual top contact versus
side/upward/slow/covered/ally/dead contact, ceiling clipping, unsafe footprints,
locked-edge corner and swept crossings, one-per-flight/cooldown, held throwable,
Muted/Held, source mutation and stale identity/life/role/run/graph/teleport rejection.
Existing Hat, Ring, Gloves, Quickstep, LuaJIT/crash replay, overhead movement,
rescue and Hero/Soldier queues pass unchanged. The first integrated run passed
131/131. An added held-throwable focused case then exposed an incomplete native
weapon double (missing SetNW2String); reused the existing actor Give fixture and
reran it without weakening assertions. Final integrated run verifies the complete
tree; syntax and whitespace gates pass. These are automated/headless results,
not native Source acceptance. Movement-hook placement was checked against the
[official FinishMove documentation](https://wiki.facepunch.com/gmod/GM:FinishMove).

Native gate pending: as a developer-mode admin on gm_flatgrass, run
`lod_heavy_plumber_testkit`; touch solid ground, then drop onto a living enemy
from a ledge or suitable jump. Confirm one physical hit, unchanged Magic and a
short upward rebound; landing on an actor again must not repeat it before touching
solid non-actor ground. Check a low ceiling, an ally, side contact and removing
the Boots during descent. With another player, verify damage attribution and
bounce/impact readability; check death and dungeon transition cleanup. Capture
console_latest.txt and rpg_summary_latest.txt. Stock pickup remains provisional.
No VPS or Steam Workshop deployment; earlier native acceptance obligations remain.

Next bounded P7 checkpoint: Tanuki's Ring. Reconcile the retained two-second
stationary Statue/invulnerability brief with live GDD and canonical perception,
status/damage and movement/lifecycle authorities. Define finite activation,
movement-break, damage denial, acquisition, equipment removal and stale-state
checks before implementation. Preserve accepted movement/overhead barriers,
rescue progression and Hero/Soldier queues; do not repeat completed audits.

---

# Previous checkpoint — Hat of the Thunder God

Built on independently verified remote `c821113b33358460ea3b537f77e109dd18e0f089`.
The working tree was clean and remote main contained no newer work. Followed
live GDD 00 → 01 → relevant 03/06/07/90, with exact HUMAN hit-stun detail.
The retained September 22 master brief explicitly authors UP DOWN UP lightning
travel and delegates remaining design/balancing/GDD synchronization. Recorded
`LOD-THUNDER-HAT-001` in 03/06/07/90 and HUMAN, read back the contract in 07.

The minimum-Rare head-slot item grants **Thunder Charge: UP DOWN UP; 24 base
offensive Magic; six-second cooldown**. A quarter-second warning precedes up to
three blocks (1152 units) of straight movement at 1440 units/second, at most
0.8 seconds. Aim is frozen at activation. The existing dispatcher owns input,
grants, cost modifiers, one resource/cooldown commit and Veil reveal. Preflight
failure is free; a committed miss or cancellation does not refund Magic.

Extended canonical safe travel with continuous flat-floor support and full-hull
sweeps. Exact cells, generated-floor center/corner support, harmful/wet-space
rejection and the existing normal/Warden/jail traversal authority are checked
before every movement step. Probes are at most 16 units apart; runtime lookahead
is at most 32 units. A clipped activation needs at least 32 safe units. Standing
footprint checks remain conservative even when crouched. Stairs, voids, walls,
actors, closed locks and unsafe floors stop the charge. Source still owns gravity
and collision through the ordinary SetupMove dash seam; no SetPos, flight,
invulnerability, new Dodge or forced-motion exemption was added.

First opposing body contact deals one canonical 2d8 + WIS electric Magic packet,
including its normal Morale rider, regardless of procedural item affinity.
The shared Magic post-damage stun seam now accepts an authored form multiplier;
this move requests ordinary eligible hit-stun, including elemental weakness,
CHA, immunity and retrigger limits. It cannot stun on zero effective HP damage
or death. Existing wall stun remains unchanged. Allies stop travel unharmed.

Delayed attacks now bind the source's actual equipped slot as well as paired
occupancy. Thunder also binds Hero identity/life/state, run/seed/graph and safe
travel eligibility. Removal/re-equipping within one tick, source replacement,
role/death/respawn/staging/level change, freeze, forced movement, air travel,
Held/Muted or teleport ends the charge. Shared dash cancellation clears horizontal
charge momentum and replicated feedback; stale cancellation cannot stop a fresh
charge. Quickstep retains its accepted expiry and ordinary movement behavior.

The existing independent 1/8 innate reward pool adds the Hat; original seven-family
RNG draws and frozen records are unchanged. The quality-scaled 60-point innate
allowance uses normal value/sale/recreation. Stock pickup remains provisional.
A dedicated bounded visual packet draws a depth-tested blue warning path and
short trail, with sound and no extra entities, particles or dynamic lights.
Reduced effects retains the same two draw primitives. The canonical manual and
both readers include the Hat. `lod_thunder_hat_testkit` equips it, preserves the
displaced item, fills Magic and marks the run unranked.

Validation: all **130 integrated suites pass, zero failures**, including unchanged
crash replay/LuaJIT, movement/overhead barriers, safe travel, rescue progression,
Hero/Soldier queues, earlier combos, Ring, manual and release wiring. Focused
production checks cover generated ownership/economics, actual recipe/cost/cooldown,
warning/frozen direction/range, native and graph barriers, support/hazards,
electric damage, eligible/immune/retrigger/defended/lethal stun, ally exclusion,
source/lifecycle rejection, stale cancellation and client packet/draw budgets.
The first focused run exposed a cyclic charge/combat context during shared damage
copying; removed the back-reference before commit and reran successfully. Initial
integrated run passed 130/130; final integrated run verifies the complete tree.
Lua syntax and whitespace gates pass. These are automated/headless results;
native Source acceptance remains pending.

Native gate: on gm_flatgrass, developer-mode admin runs `lod_thunder_hat_testkit`,
then UP DOWN UP on a flat corridor. Confirm one 24-base-Magic spend, warning,
straight travel and six-second cooldown; then charge at a wall/closed gate, an
enemy and an ally. Check one electric hit with eligible stun, no ally damage,
no unsafe-floor/locked-edge traversal and cancellation when removing the Hat,
dying or changing dungeon. Another player verifies warning/audio/trail readability.
Capture console_latest.txt and rpg_summary_latest.txt; screenshots only for visual
defects. No VPS or Steam Workshop deployment; prior native obligations remain.

Next bounded P7 checkpoint: Boots of the Heavy Plumber. Reconcile the retained
stomp/bounce brief with live GDD and shared landing/contact/damage/safe movement
before choosing delegated tuning. Finite gate: equipped source, valid downward
contact, one damage event, safe bounded bounce, spam prevention and stale lifecycle
rejection. Preserve accepted movement/overhead barriers, rescue and Hero/Soldier
queues. Do not restart prior completed audits.

---

# Previous checkpoint — Ring of Invisibility

Built on verified remote `5d3f837223f433f8b07705cfc4c9dd832e553c8d`.
Fresh main checkout; no newer remote work was present. The recovered local Gloves
commit was not reapplied. Read AGENTS.md, the checkpoint and live GDD 00 → 01 →
relevant 03/06/07/90 rules, then exact Invisible/HUMAN fallback. The live GDD had
no ring contract. `docs/SEPTEMBER22_MASTER_BRIEF.md` explicitly delegates the
ring's break/end conditions and P7 design/balancing/GDD synchronization. Exercised
that delegation in `LOD-INVISIBILITY-RING-001`, written and read back in 03/06/07/90
and HUMAN. No unrelated design rules were changed.

Ring of Invisibility is a minimum-Rare procedural single-hand item granting
**Veil: LEFT UP LEFT; fixed 20 Magic; maximum 12 seconds; 20-second cooldown**.
Its quality-scaled 50-point innate allowance participates in ordinary item value,
sale and recreation. The independent 1/8 innate reward pool now contains Crown,
Gloves and Ring; the original seven-family stream and frozen records are intact.
Two rings expose one recipe; paired gloves displace rings under normal occupancy.
The shared dispatcher validates grants, status, resources and preflight before
committing once. Active Veil cannot refresh or spend again.

Canonical perception now supports individually owned invisibility sources,
composing with its existing permanent/timed state. Veil binds source record/slot,
Hero state/identity/life, run, level seed and graph. Removal/moving/replacement,
death/disconnect/respawn/role/staging/level transition, failure/freeze or expiry
ends that source only; stale callbacks cannot clear a newer activation. Existing
perception maintenance owns expiry, with no new per-item recurring timer.

AI acquisition and directed attack adapters consult canonical Invisible, including
wanderer retention, Watcher scans, Soldier windups, roster/Climber, Brute and
Warden paths. Activation drops existing target/pursuit knowledge. Faction/damage
eligibility stays distinct: released shots, committed area hazards and manually
aimed human Soldiers can still hurt the Hero. Warden homing loses the concealed
target without deleting the projectile. Sixth Sense retains its authorized halo
pass. Client body/held-weapon concealment reads the replicated deadline.

Attack input (including dry/blocked attempts), Magic on any bound button, offensive
item techniques, throw attempts and effective incoming/outgoing HP damage reveal.
Movement, reloading, menu access and drinking alone do not reveal. Ending neither
refunds Magic nor resets cooldown. Activation/end feedback uses the shared RPG
feed; the canonical manual and both readers document the item.

Validation: all **129 integrated suites pass, zero failures**, including unchanged
exact crash replay, LuaJIT, movement/overhead barriers, rescue, Hero/Soldier queue,
Feather, safe travel, earlier combos, manual and release wiring. Focused production
checks cover ownership, ordinary generated rewards/value, one-hand grants, cost,
status denial, actual recipes, target-versus-damage membership, reveal/expiry,
source composition, item/identity/life/role/run/graph rejection and stale cleanup.
Extended existing sniper and render/input checks cover windup cancellation, body
concealment, Sixth Sense halo permission and held-gun draw suppression. Initial
integrated run passed 121/129: eight dependent fixtures lacked the new faction
acquisition method. Their common fixture now loads the production faction module
while retaining its existing actor-membership double; no acceptance assertions
were relaxed. Lua syntax and whitespace gates pass. These are automated/headless
checks, not native Source acceptance.

Native gate pending: on gm_flatgrass as a developer-mode admin, run
`lod_invisibility_testkit`, then LEFT UP LEFT. It equips one ring, fills Magic,
preserves displaced items and marks the run unranked. Confirm exactly 20 spent,
loss of directed AI pursuit, 12-second expiry and 20-second cooldown; attack,
remove the ring and take a released shot/hazard to check reveal. With another
player, inspect body/held-gun disappearance/restoration, Sixth Sense and manually
aimed human-Soldier damage. Check death/respawn and dungeon transition cleanup.
Capture console_latest.txt and rpg_summary_latest.txt; screenshots only for
appearance defects. Stock pickup model remains provisional.

Next bounded P7 checkpoint: Hat of the Thunder God. Reconcile its retained
UP DOWN UP lightning-charge brief with live GDD, shared movement/collision,
electrical damage/status and safe-travel authorities before choosing delegated
values. Finite gate: equipped source, single resource commit, wall/gate/floor-safe
path, enemy/ally hit handling and stale lifecycle rejection. Preserve accepted
movement and overhead barriers, rescue progression and Hero/Soldier queue behavior.
Earlier native acceptance obligations remain open. No VPS or Workshop deployment.

---

# Previous checkpoint — Gloves of the Fighting Streets

Built on verified remote `1a7d351b33bde23c3c792623dcb5e33b8c85f0b1`.
No newer remote work was present. Read AGENTS.md, the current checkpoint and
live GDD 00/01, relevant 03/06/07/90 rules. The live GDD lacked the named glove
contract; the retained September 22 master brief explicitly supplies both recipes
and delegates balancing/design decisions and GDD synchronization. Added and read
back `LOD-FIGHTING-STREETS-001` in 03/07/90, with the same contract appended to
HUMAN. No repetition of the completed Feather audit was required.

The minimum-Rare v2 paired gloves occupy both hands once, with doubled ordinary
glove affix opportunity plus a quality-scaled 80-point innate allowance. Existing
frozen items and the original seven-family generation stream remain unchanged;
the independent 1/8 innate reward pool now selects Crown or Gloves. Inventory,
affinity, naming, value, sale and recreation use the existing item authorities.

- Ember Fist: LEFT DOWN RIGHT; 12 base Magic; two-second cooldown; one straight
  1200-unit/second projectile, maximum 1920 units and 1.6 seconds. Direct hit
  deals 2d6 plus canonical WIS Magic with the gloves' sealed affinity and its
  existing Content rider. No splash or piercing. The native swept hull starts
  at the shoot origin; blocked placement or failed entity creation spends nothing.
- Cinder Rise: RIGHT DOWN RIGHT; 18 base Magic; four-second cooldown; current
  graph square with line of effect. Deals 2d8 plus canonical WIS Magic using
  the gloves' affinity, then canonical Immolated on a surviving damaged target
  subject to its ordinary save. Rising elemental presentation does not relocate
  the Hero. A successfully committed empty shot/area spends Magic.

Both use the existing combo dispatcher, offensive cost modifiers (no Content
surcharge), shared damage/dice/equipment/defense/status/feed authorities and
bounded work. No new Spellbook Form, input listener or permanent feat. Rebuff
shares Ember Fist's recipe but requires a ring displaced by the paired gloves;
only currently equipped grants compete. Delayed impacts reject changed Hero,
life, run, level, graph, source record, equipped occupancy or active role, and
expire without refund. Only one technique projectile per caster can be active.
The canonical manual and both generated readers now explain both techniques.

Validation: production-path tests cover generated rarity/value/paired slots,
natural reward families, descriptions, actual combo recognition, projectile
Initialize/Think/impact, blocked/failed launch, no-splash misses, cooldown and
Magic commit, shared elemental damage and Immolated save/application, cover and
local-square exclusion, source/life/role/run/graph/expiry rejection, and the
Rebuff collision. Initial fixture runs exposed missing entity/faction doubles
and an incorrect test assumption that Held prevents stationary casting; the
fixture now follows the existing shared rule. A ring-swap fixture also exposed
that the runtime testkit needed explicit occupied-slot acceptance; displaced
items remain in the bag. No production rule was changed to satisfy these tests.
All 128 integrated suites pass with zero failures, including unchanged exact
crash replay, LuaJIT, movement/overhead barriers, Feather/queue, safe travel,
Crown/Quickstep/Rebuff, manual and release-wiring regressions. Lua syntax and git
whitespace checks pass. Automated checks are not native Source acceptance.

Native gate remains pending: on gm_flatgrass as a developer-mode admin, run
`lod_fighting_streets_testkit`. It equips one generated pair, fills Magic and
marks the run unranked; displaced rings remain owned. Use both displayed recipes
against an exposed enemy, then cover/adjacent-square exclusions. Check Magic,
shared damage/save feedback, two-hand occupancy and cancellation after stowing.
With another player, confirm ally exclusion and shared projectile/strike visuals.
Capture console_latest.txt and rpg_summary_latest.txt; add screenshots only for
appearance defects. The pickup uses the existing stock equipment-box placeholder.

Next bounded P7 checkpoint: Ring of Invisibility through the shared equipment
combo and canonical Invisible/target-acquisition authorities. Reconcile live
GDD break/end rules and missing delegated tuning before implementing. Then
remaining P7 items precede events/minigames and Hector/finale. Preserve all
accepted movement, overhead barriers, rescue and queue behavior. Feather,
Crown, responsive-sheet and safe-travel native acceptance remain pending.
No VPS or Workshop deployment performed.

---

# Previous checkpoint — Feather of Resurrection and canonical revival

Built on verified remote `8e132f9fb0a0228e271c9e4d8ec29b444432b3d7`.
Recovered that published tree in a fresh main checkout; no surviving unpushed
Feather implementation was found. Live GDD 00/01 then relevant 06/07/90 rules
were read. Existing `LOD-RESURRECTION-FEATHER-001` in 06/07 already specifies
the behavior and tuning from the interrupted session; no GDD changes were needed.

Feather of Resurrection occupies the canonical finite Throwable slot, stacks to
three and uses either mouse button. The existing oldest-eligible elimination
timestamp/ordinal selector excludes Soldier control, Soldier respawn waits and
ordinary positive-life respawns. `RunManager:ReviveIdentity` validates eligibility
before invoking an optional synchronous debit, then restores exactly one life.
No eligible target, invalid owner, inactive item, timeout or failed debit spends
anything. Success spends one Feather, no Magic, and applies the 0.6-second cooldown.
Queue return preserves the original elimination timestamp. Full Hero slots defer
admission; reconnect does not grant another life. Identity, progression and surviving
inventory remain unchanged; this does not create gear, wallet value or claims.

The shared deferred revival callback now spawns an alive former-Soldier spectator
through normal Hero spawning, and rejects changed run, graph, level, identity,
body serial, death, Soldier state or disconnected player. Summon Card drops keep
their original independent draw. Feather draws 1/8 of eligible potion opportunities
that did not select a Card, using resurrection-feather-v1 (7/64 overall). Other
conversion/affix streams and authored non-eligible rewards remain unchanged.
The pale newspaper charm is a stock-model placeholder pending native appearance
acceptance. The canonical manual source and both readers document Cards/Feathers.

Targeted production checks pass queue ordering, both controls, debit failure,
empty queue, Soldier exclusion/return, slot/reconnect handling, stale callbacks,
inventory references, cooldown/no-Magic spending, stack exhaustion and seeded
natural rewards. Initial fixture execution lacked the Source CreateConVar boundary;
that double was supplied. The first integrated run passed 126/127: the old final
drop-mix test required a healing share predating Feathers. Its category thresholds
now account for the 49/64 remaining ordinary pool and explicitly require natural
Cards and Feathers, retaining the native reward-creation failure checks.
Final integrated regression: all 127 suites pass with zero failures, including
unchanged recorded crash replay, LuaJIT, Hero/Soldier lifecycle, safe travel,
manual synchronization and release-wiring gates. Changed Lua syntax and git
whitespace checks pass. These are headless/static checks, not Source acceptance.

Native multiplayer/appearance acceptance remains pending. On gm_flatgrass, as a
developer-mode admin, run `lod_feather_testkit` with an eliminated teammate in the
Hero Queue. Use either mouse button: one Feather spent, one restored life and a
normal Hero body. Repeat with no eligible teammate, then with Soldier control and
return to the queue; only the eligible queue use succeeds. The testkit marks the
run unranked. Capture console_latest.txt and rpg_summary_latest.txt; screenshots
are only needed for appearance defects. No VPS or Workshop deployment performed.

Next bounded P7 checkpoint: Gloves of the Fighting Streets through the existing
equipment-combo and shared combat authorities. Reconcile its live-GDD attack and
cost rules first; the finite gate is both authored recipes with equipped ownership,
resource commit, authoritative hit/status handling and lifecycle rejection. Remaining
P7 items precede event/minigame and Hector/finale work. Preserve the accepted movement,
overhead barriers, rescue progression and queue semantics; native Crown, responsive
Character Sheet and safe-travel acceptance remain pending.

---

# Previous checkpoint — safe Hero relocation and Summon Card

Built on verified remote `5bbc6088eaafb9f6d8314dee3fe349b20fb441ea`.
`LOD.SafeTeleport` now owns exact graph-cell membership, unlocked-route checks,
standing-hull clearance and generated-floor support for Hero relocation. It calls
the live navigator, retaining progression, Warden and jail locks. Destination
checks reject voids, stair-transition cells, unsupported footprint corners,
occupied hulls, water/slime and damage triggers. It revalidates both Heroes and
the landing at commit, then clears carried velocity and dash/forced-motion state.
Existing normal movement, spawn/deployment and Magic summons are unchanged.

Summon Card uses the canonical finite throwable inventory, held adapter and
LMB/RMB controls. LMB selects another deployed Hero for an adjacent safe square;
RMB selects one for the current square or nearest safe equivalent. The server
owns the target list and position. A one-shot 15-second selection binds owner,
target, identity state, life, run, level, graph and held record. Failures/cancel
spend nothing; success consumes one card and no Magic. Stack cap is three and
the ordinary 0.6-second cooldown applies. New eligible potion opportunities use
an independent 1/8 card draw; existing conversion/affix streams and authored
non-eligible rewards remain intact. The stock clipboard provides the visual.

Live GDD navigation used 00/01, relevant 05/06/07 and deferred item rules in 90,
reconciled with the superseding September 22 master brief. New rule
`LOD-SAFE-TRAVEL-001` is written and read back in tabs 06 and 07, including the
candidate search, collision tolerances, lifetime, stack, cooldown and drop tuning.

`tools/test_summon_card.lua` exercises production navigation including the real
Warden/jail wrapper, hull/support/hazard failures, oversized Heroes, stale life,
level, graph, identity, inventory and control state; net bounds/replay; precise
spending, cooldown, velocity reset, no Magic cost, deterministic natural rewards
and atomic stack overflow. The actual client picker is checked at small/large
viewport boundaries, with intact names, target/nonce requests, cancellation,
expiry and page/death close. Initial tests caught a missing Source boundary
double and an item slot registration error; both were corrected. Headless checks
are not native Source collision or visual acceptance.

Validation: targeted server and picker checks pass. All 126 integrated suites
pass with zero failures, including unchanged crash-replay, JIT, movement,
progression, queue, inventory and release-wiring regressions.
Native acceptance remains pending: on `gm_flatgrass`, with two deployed Heroes,
run `lod_summon_card_testkit` as a developer-mode admin, then use LMB/RMB and
check occupied landing fallback, closed gates and stale/dead target cancellation.
The command marks the run unranked. Capture `console_latest.txt` and
`rpg_summary_latest.txt`; add a screenshot only for picker/visual defects.

Next bounded P7 checkpoint: Feather of Resurrection through canonical Hero
Queue/life admission, with exactly one restored life and atomic consumption;
then remaining P7 items before event/minigame and Hector/finale work. Preserve
movement, overhead barriers, rescue progression and queue semantics. Native
responsive-sheet and Crown acceptance is still pending. No deployment performed.

---

# Current checkpoint — recovered equipment and responsive feat selection

Recovery published as `62141883fa4b888c6e29a47812d06de3c6cdda4f`, directly
on top of `af10212ebdce87bc7f5ddda31bb1e16e823c2f77`. The surviving local
`4ea6edb095d7337240e984c552b4192d5fd91177` was clean and retained; its exact
file tree (`c356fd7c3e3072eebec3b8e46fbce26ebb1c1836`) was published through
the GitHub connector because command-line Git had no write credentials. No
reconstruction, reset or discard was needed. All 124 recovered integrated suites
passed again, including targeted Crown/combo, Quickstep/Rebuff and unchanged
recorded crash-replay checks. The full September 22 main chain is preserved.

The next bounded checkpoint repairs the Character Sheet selection surface.
Ordinary feats and capstones now share one responsive renderer: one to three
columns with a 280-pixel preferred minimum card width, 12-pixel gaps and measured
row heights. Full names, eligibility and canonical descriptions remain intact.
Short Choose Feat / Choose Capstone buttons retain full-name tooltips and the
original feat ID/earned-level request contracts. Resolved and read-only cards
remain inert. Owned-feat text still comes from the canonical server snapshot.

Below 900 pixels of body width the main sheet columns stack, preventing narrow
identity and draft panels. Section headings wrap and contribute their actual
height. The header uses its short title when measured text would clip.
Screen-size changes rebuild the existing snapshot without requesting a
new hand. Same-identity snapshot refreshes retain the scroll position; a new
identity starts at the top, and stale layout callbacks cannot affect newer frames.
No gameplay, eligibility, draft RNG, feat text or server choice behavior changed.

Live GDD navigation: 00, 01, then relevant rules in 03/04/06/07; recovery matches
LOD-EQUIPMENT-COMBO-001, and presentation retains LOD-FEAT-CARDS-001 and the
LOD-UI shared-menu rules. No design-law correction or manual rewrite is needed.
The existing edited manual and feat catalog remain unchanged.

New production-path coverage builds real Hero snapshots and verifies ordinary,
owned and capstone descriptions against their registered authorities. It opens
the actual Character Sheet for all 150 registered descriptions (135 ordinary,
9 capstones, 6 fallbacks) at 640x480, 800x600, 980x720, 1024x768, 1280x800 and
1920x1080; checks card/section bounds, nonoverlap and intact text; exercises exact
choice messages, resolved/read-only states, refresh/resize and identity changes.
An initial test selector confused identically named ordinary-test and capstone
cards; it now selects the actual draft by its action control. Assertions remain
intact. All 125 integrated suites pass with zero failures: the recovered 124
plus the new Character Sheet suite. The final header-fit refinement also passes
the targeted six-resolution suite after the integrated run.

Native GMod font metrics, visual scrolling/selection and multiplayer acceptance
remain pending; the headless VGUI boundary is not native rendering evidence.
Next tranche: canonical safe-cell / safe-teleport resolution and its blocker,
occupied-hull and level/life-change gates, then Summon Card and remaining P7
items. Event/minigame dependencies and Hector/finale follow that equipment work.
Keep full movement, overhead barriers, rescue progression and queue semantics.
Shadow flicker remains unreproduced/nonblocking. No VPS or Workshop deployment.

---

# Current checkpoint — shared combo abilities and Psychic Crown

Built on verified remote `af10212ebdce87bc7f5ddda31bb1e16e823c2f77`.
The existing keyboard/mirror listener and three-bit transport feed one server
ability dispatcher. Only equipped grants compete; bounded suffix matching supports
up to eight tokens, selects the longest completed recipe then registry order,
and attempts just one move. Timeout, reset, capability changes, Hero/life/run/level
changes invalidate input. Resource/cooldown commit follows successful preflight.
Quickstep/Rebuff retain their original handlers, restrictions and costs.

Crown of Psychic Crushing is an innate head item, minimum Rare, with a quality-scaled
50-point innate value plus ordinary procedural affix value. DOWN UP DOWN costs
18 Magic with four-second cooldown; the nearest visible hostile within two graph
edges receives 2d8 plus canonical WIS Magic and a shared WIS save for half. Graph
locks, cover, shared equipment/class/element/damage/defense and attribution stay
canonical. No valid target spends nothing. The feed names target and save/DC;
a brief impact marks the selected target. No permanent feat mutation.

New world wearable rewards choose the current innate pool at 1/8 probability using
an independent named seed stream. The original seven-family generator stream and
frozen generic economics remain exact. Innate items require v2 validation. The
first full run passed 122/124: extending the original random-family list broke the
recorded crash corpus and JIT compatibility replay. Corrected production reward
selection; both old fixtures pass unchanged. An initial implementation typo in the
innate value helper caused recursion and was fixed before integration. New fixture
runs initially lacked Source game/net boundaries; corrected those doubles.

Targeted production checks pass 300 generated Crowns, natural reward admission,
price/rarity, effective ownership, shared WIS damage/save feedback, actual graph
locks/cover, no-target/no-Magic/Muting/cooldown rejection, stale life sessions,
unowned recipe collisions and four-token suffixes. Quickstep/Rebuff and the real
client input adapter pass. Live GDD 03/06/07 records LOD-EQUIPMENT-COMBO-001;
manual source and readers rebuilt. Final full regression: all 124 registered suites
pass with zero failures.
Native multiplayer targeting, visual/sound and combat acceptance remain pending.

Next: author-prioritized Character Sheet feat selection readability and snapshot
coverage, then shared safe travel before Summon Card; remaining P7 wearables/consumables,
then events/minigames and finale. Shadow flicker remains unreproduced/nonblocking.
Full-strength movement and invisible overhead collision remain regression constraints.
No VPS deployment or Workshop publication.

---

# Current checkpoint — readable, less oppressive monster defenses

Built on verified remote `e004e9a1999da5f895281a7e24f0027a4b46a503`, preserving
full-strength Cloud Step and invisible overhead walls. Enemy-side AI and possessed
Soldiers use the same canonical derived/damage/status systems with CON reduction
capped at 1 per die, Arcane Diversion capped at 30% without whole-HP rounding,
and Feedback capped at 15% with a two-second cooldown. Hero rules remain intact.

Enemy shield breaks receive +4 DC and last 1.5 times their rolled duration, at
least 24 seconds. A break or defeat cancels deferred Feedback from the same hit.
Attacker-facing feed messages identify Constitution, Arcane Shield, Feedback,
failed/successful breaks, True Faith and Mind Over Matter, with a relevant tactic.
Existing semantic feedback families and 1.5-second per-reason throttles avoid spam;
a shield-break success has its own key so an earlier resistance message cannot hide it.
Other immunity, Dodge/Block, element, equipment, save and Hero feat rules remain.

Targeted production checks cover AI/Soldier parity, unchanged Hero caps/rounding,
small-hit leakage, Magic affordability, Poison, 24/45-second break windows, attacker
messages, same-hit break/death cancellation and the actual Mind Over Matter recovery.
The first Fighter regression failed its old enemy-CON expectations; those explicit
enemy results now reflect the authorized cap while its Hero/pure arithmetic matrix
is retained. A new fixture's nonexistent status Get accessor was corrected to the
production Has return contract. The first full run passed 122/123: an obsolete
source-text assertion expected one universal Arcane clamp. It now recognizes the
role-specific clamp, and the existing runtime validator covers both roles.
Its standalone fixture now loads real shared tuning rather than an incomplete
RPG table; the targeted Checkpoint C runtime and source validators pass.
Final full regression: all 123 registered suites pass with zero failures.
Live GDD 02/03/07 and the rebuilt manual record LOD-ENEMY-DEFENSE-001.
Native multiplayer damage feel and feedback readability remain pending.

Next: Priority 7 shared equipment/input-combo/safe-travel systems, then event and
minigame dependencies before the finale. Shadow flicker remains unreproduced and
nonblocking. No VPS deployment or Workshop publication.

---

# Current checkpoint — free Cloud Step movement and invisible overhead walls

Built on verified remote `d2faa8497732468e8c5167d29a72cfe54713d04d`.
The author's later direction replaces the unpushed apex-clamp prototype: preserve
full expressive movement and contain the maze using invisible walls above crates.
Cloud Step costs 3 Magic, targets twice the former vertical takeoff impulse and
adds a normalized 120-unit boost in the held direction while preserving horizontal
momentum. Spring Heel and subsequent Wall Jumps retain full strength at any altitude.
The ordinary locomotion cap remains separate. Wall Jump priority, once-per-airborne
state, shared capabilities, movement restrictions and Meteor Strike remain intact.
An original 130 ms cue and eight-sprite 0.35-second cloud ring identify success.

Existing invisible merged wall boxes extend through overhead void to world Z 16384.
Lower columns stop beneath legal upper-floor crossings and the gallery overlook;
merge keys include top height. Closed gates and the jail door extend their own
collision upward; opening clears the entire column. Visual sizes remain authored,
with no additional VPhysics, per-frame traces, lights or recurring timers.

The earlier clamp prototype passed 121 suites but was superseded before any main
push. The revised production checks preserve full jump combinations and verify
walls at five vault heights, 4,759 legal crossings and 38 stairs over eight generated
seeds, split-height merging, gallery openings, and complete gate/jail opening.
An initial gallery fixture incorrectly retained a Cell inside WardenVoid; corrected
to match the real arena topology. Peak wall count in those seeds: 616 merged boxes.
Full revised regression: all 122 registered suites pass with zero failures. Manual/catalog/readers rebuilt.
Live GDD 04/05/07 records LOD-CLOUD-STEP-003 and LOD-WORLD-OVERHEAD-001.
Native collision, traversal and audiovisual acceptance remain pending.

Next: monster defense readability/rebalancing, then shared equipment/input/travel
before event/minigame and finale dependencies. Shadow flicker is unreproduced and
nonblocking. No VPS deployment or Workshop publication.

---

# Current checkpoint — full-trajectory Magnum and Beam

Built on verified remote `4520bedf744b5bf72f027d1ab9a7be71f6062593`.
Both attacks now continue beyond the previous eight/four target limits through
living opponents, corpses and friendly combat bodies to their fixed range/world
endpoint. The first Magnum impact is captured before an earlier callback can
kill/remove it. Shared factions still govern damage; each actor is hit at most
once. Generated-geometry obstruction, cumulative Magnum Boomchains, Aim scaling
and the shared attack-event dice budget remain intact.

The shared 128-target safeguard exceeds supported simultaneous actors, with a
512-iteration guard for malformed traces. Magnum range no longer extends after
each body. The manual already describes the full-line behavior; live GDD 03/07
records the correction and authorized safeguards as LOD-PIERCING-002.

Validation: production trajectory tests pass fourteen bodies, lethal first
callback, dead intermediate body, fixed range, wall stop and repeated-entity
guard. All 121 registered integrated suites pass with zero failures. Native aligned
multiplayer actors and generated-wall acceptance remain pending.

Next: Cloud Step and monster defense readability/rebalancing, then the shared
equipment/input/travel systems. Shadow flicker remains unreproduced/nonblocking.
No deployment or Workshop publication.

---

# Current checkpoint — Gordon/Neil feedback and Fake Gordon Clones

Built on verified remote `eccb286d4a7341c0b044d1dd2d79be0d74888192`.
Gordon's first phase reveals a two-second taunt after twelve damage-free seconds
while cloaked, with a sixteen-second repeat gate and interruption on damage.
An original bounded square-wave laugh and procedural arm/torso pose identify it.
Neil receives a 0.4-second recoil pose on actual damage. Death clears these poses.

The actual procedural Crowbar tags its shared stagger request as melee. Gordon and
clones accept melee stagger once every three seconds; damage and firearm stun
remain intact. All three installed stun wrappers now forward the form multiplier
and source kind, preserving Wall's intended stun as well as the new melee gate.

Dungeon Levels 4/8/12/16 add 1/2/3/4 Fake Gordon Clones, capped at four. Each uses
the existing actor/phase/damage/navigation authorities at floor(real MaxHP / 3),
minimum 1. Legal distinct court cells, individual route seeds, separation scoring
and target offsets distribute the actors. Pending spawn reservations persist;
creation is idempotent and dead clones are not replenished. Main and clones share
sixteen hazards with unique IDs. Only the real boss owns the HUD and Jail Key;
clone death retires its ordnance, and real-boss death retires all clone attacks.
Two client props are reused for all actors, including differing clone phases.

Validation: all 121 integrated suites pass with zero failures. Expanded production
boss tests additionally pass clone thresholds, exact HP and legal spawn cells,
independent phase execution, shared caps/IDs, separate Hero targeting, pending
reservations, death/HUD isolation, taunt interruption and the installed stun wrapper
chain. Ordered real-boss health, Neil/Brute, Wall and audio regressions also pass.
Manual source/readers rebuilt; live GDD 03/07 records LOD-GORDON-EXPANSION-001.
Native multiplayer boss, animation and sound acceptance remains pending.

Next: Priority 6 Cloud Step, guaranteed full-trajectory Magnum/Beam piercing and
monster defense readability/rebalancing, then shared equipment/input/travel systems
before the event and finale framework. No public deployment or Workshop publication.

---

# Current checkpoint — enemy death pulse and defeat cue

Built on GitHub main `efb2a4c2ef68f5b142c42ebece6d041c56de2410`.
Dead hostile bodies smoothly interpolate normal → red silhouette → normal → red
through their existing one-second presentation. A single replicated timestamp
replaces repeated server hide/show updates. Cloaked Gordon corpses become visible.
The shared scheduler, deferred native mutations, one-time loot handoff and level-seed
isolation are preserved. The 60 ms original defeat cue is coalesced per listener
with a 120 ms cooldown; it never overlaps itself during simultaneous kills.

Validation: production death handoff/batching and interpolation bounds, audio
lifecycle/coalescing, deterministic audio assets, monster identity and changed-file
Lua syntax checks pass. This follows the complete 121-suite pass on the parent UI
checkpoint. Native silhouette appearance and audible mix remain unobserved.
Live GDD 03/07 records the presentation and tuning under LOD-DEATH-PULSE-001.

Next: finish Priority 5 Gordon/Neil feedback, melee stagger protection and clones;
then Priority 6 Cloud Step, full-trajectory piercing and monster defenses.
The staging shadow remains unreproduced/nonblocking. No deployment is included.

---

# Current checkpoint — Debbie review and feat card text

Built on verified GitHub main `5d0d0f5f51636d8267de5ad2f7565338519462c8`.
The recovery and navigation checkpoints remain intact. The author cannot currently
reproduce the staging shadow flicker; it is unreproduced and nonblocking. Existing
DFT rollback/award, black-gate, audio-owner cleanup and damsel roster checks remain
regression constraints; this pass found no contradictory evidence requiring a rewrite.

Debbie now displays item statistics and displaced equipped-item comparisons inside
exchange cards. Source/pile targets, numbered review steps, pending state, explicit
sale/fusion consequences and a local CLEAR PILE action clarify the transaction.
Pending exchanges cannot be cleared or confirmed twice. Sell All visually protects
equipped rows as well as enforcing the existing authoritative transaction rules.

All 135 ordinary feats, nine capstones and six fallback feats have edited card text.
One presentation module populates the existing catalog descriptions after registration;
character sheet, offers and manual keep their existing shared consumers. Ranked values
come from mechanical parameters. A comparison against the previous catalog confirms
all 150 descriptions changed and every other catalog field stayed identical. Manual
source, HTML and distributed client chunks were rebuilt.

Live GDD 00 → 01 → 04/06 governs this checkpoint. LOD-FEAT-CARDS-001 and
LOD-DEBBIE-READABILITY-001 record the authorized presentation revisions. The first
complete run passed 120/121 suites: the release audit's verbatim Spatial Awareness
expectation rejected the edited text. The fixture retains the old authored row and
records an explicit presentation override; the targeted release audit then passed.
Final complete regression: all 121 registered suites pass with zero failures.

Next: Priority 5 enemy-death feedback and Gordon/Neil boss polish, then Cloud Step,
full-trajectory piercing and enemy-defense readability before dependent equipment and
events. Native GMod visual/multiplayer acceptance remains pending. No VPS deployment
or Workshop publication is authorized by this checkpoint.

---

# Current checkpoint — committed stair travel and Climber placement

Developed from verified remote main `2ea2c4a3c0ca13df24f9a2563a1551c7e8d17c6f`,
which durably contains the September 22 recovery checkpoint above `4942c43`.
The recovery tree passed all 120 registered suites with zero failures.

Summons now complete the authored stair flight before periodic replanning,
charging or retreat can replace it. Climbers retain unfinished wall routes,
retry blocked routes after 0.8 seconds, and spawn directly in a validated wall
lane preserved by shared spawn settlement. Local humanoid pursuit reserves the
actual container half-width plus hull clearance instead of entering the wall.
The canonical maze graph and movement authority remain in use.

Validation: all 121 integrated suites pass with zero failures. The new navigation
suite executes the production waypoint compiler, motion kernel and summon route
refresh across four stair orientations in both directions. It checks monotonic
route progress, completion, landing elevation, charge exclusion, container hull
clearance and Climber spawn settlement. Roster tests verify wall-route retention.
Live GDD 00 → 01 → 05/07; tab 07 records LOD-NAV-20260922.
Native GMod stair/collision/render acceptance remains pending; static tests are
not a claim of observed multiplayer behavior.

Next: complete the remaining Priority 2 audit (DFT announcements/persistence,
black-gate collision, ambient-owner cleanup, staging flickering shadow and unique
damsel services), then Priority 4 UI/feat wording and subsequent combat/content
work in SEPTEMBER22_MASTER_BRIEF.md. Existing tests cover DFT rollback, gate
routing, loop leases, ordinary pistol/crowbar loot and the damsel roster; do not
rewrite those systems absent contradictory evidence. The native staging shadow
cause is not yet established. Later combat, items, events and Hector remain open.
No public-server deployment or Workshop publication is included.

---

# Current checkpoint — progression, sales and live rankings

Second checkpoint in the active ten-priority brief: doubled Hero XP thresholds,
stronger bounded INT/DEX curves, three-dungeon monster scaling, a 520-unit ordinary
movement cap, atomic Sell All Unequipped, persisted/live Stakeholders and live
Heroes of Legend. Procedural look-at identity and same-floor Hero map markers
improve multiplayer readability. Open gates reassert collision removal; rolling
summons use travel-driven rotation and model ground offset; damsel materials retain
source shading and the stray blue brooch sphere is removed. DFT collection reports
success only after storage accepts the token.

GDD 00 → 01 → 02/06/07 and HUMAN amendment LOD-PROGRESSION-002 govern these changes.
Existing earned Hero levels survive the XP threshold change. Ordinary movement
bonuses combine before the safety cap; special movement remains independently
validated. Bulk sale rejects the complete transaction if a reviewed item becomes
equipped; DFT-created and protected gear remain excluded.

Validation: targeted Lua movement, actor progression/Warden HP, wallet UI,
look-at UI, minimap, snapshot, protected regressions and real SQLite economy
checks pass. SQLite tests cover twelve-item sale, newly equipped selection,
DFT exclusion, rollback, exact payout and replay. Leaderboard tests cover live
participants, immutable completed storage and completion without duplication.
Recovery validation: all 120 registered suites passed together with zero failures.
Additional production-path regressions prove worn Bloodletting and regeneration
on a featless non-Fighter, removal on unequip, and all-or-nothing rejection when
inventory changes inside the sale transaction (equipped/protected/removed). Native GMod
multiplayer, lighting, stairs, summon rotation and 4K visual acceptance are pending.

Shared item capabilities are verified through the existing Equipment.Contributions,
derived-state, attack-snapshot and status/regeneration pathways; no parallel feat
system was added. Recovery preserves local commit c9d96c6 above remote 4942c43.
The complete author brief is preserved in SEPTEMBER22_MASTER_BRIEF.md.

Next: finish Priority 2 navigation/stairs/Climber/summon and persistence/cleanup
checks before combat/piercing/defense revisions, procedural items/events and Hector.
Those later requirements remain incomplete; follow the preserved brief in order.
No public-server deployment or Workshop publication is included.

---

# Current checkpoint — persistent dungeon and Hero queues

Active author brief: implement the ten-priority retention, combat, equipment,
events and Hector expansion from main. Completed first checkpoint: final-life
choices, new Level-1 Hero in the same dungeon, persistent queue selection,
model reuse and removal of total-party-wipe failure. Account claims stay outside
the replaced character. F3 reopens the choices. Live GDD 00 → 01 → 06 and the
HUMAN opening amendment record LOD-RETENTION-001; this supersedes old wipe law.

Validation: all 120 registered suites covered successfully (118 passed the
full run; corrected obsolete closure assertions and syntax rechecked separately).
Manual source/readers and new replacement/lifecycle tests pass.

Next: critical navigation/collision/DFT defects, then shared progression and
capabilities, equipment/events, and Hector. This checkpoint does not claim those
remaining requirements implemented. Native GMod multiplayer acceptance pending.

---

# Current candidate — damsel progression, endless cash and audio cleanup

Current author direction replaces repeat-Deborah rescues with the finite 20-damsel
arc, followed by endless cash objectives. The candidate also addresses staging
equipment access, Poison diversion, Climber clearance, Arc Caster recovery,
Nodule combat bounds, ambient loop ownership and gold allied summons.

See [DAMSEL_PROGRESSION_AND_AUDIO.md](DAMSEL_PROGRESSION_AND_AUDIO.md) for the
roster, reward/persistence rules, audio decisions, regression coverage and finite
native playtest commands. GDD navigation used 00 → 01 → 02/03/05/06/07. Beam
Sweepers retain their authored stationary role. The current request supplies the
new roster, rewards, palette and endless-mode design discretion.

Validation: `python3 tools/test_checkpoint_g_integration.py` passes all 120
suites with zero failures; staged diff whitespace checks pass. Native Garry's Mod
audiovisual/multiplayer acceptance is pending a fresh build playtest.
Do not deploy the public server or publish Workshop as part of this checkpoint.

---

# Previous candidate — auxiliary mouse Magic dispatch repair

Author-reported M3/M4/M5 casts repeated RMB's Form on `6e136b3`. The installed
Wizard feedback wrapper dropped the requested button for every class. Forward
that argument through both wrapper paths; keep the existing cast resolver and
full-Magic snapshot/error cleanup. No rules or tuning change. Current author
direction governs independent bindings; live GDD 00 → 01 → 03/06 preserves the
shared Magic authority (older single-Form UI wording is superseded by that direction).

The expanded mouse-binding regression reproduced the failure before the fix
(`fighter M3 must cast beam, not RMB`) and now passes all 78 eligible
class/Form/auxiliary-button combinations through the real network receiver,
installed Wizard wrapper and cast transaction. Terminal world effects are
doubled; costs, cooldowns, binding ownership, unbound/invalid request rejection,
RMB/legacy requests and snapshot cleanup remain real. All 116 integrated suites
pass with zero failures. Native acceptance: on `gm_flatgrass`, assign four different Forms to
RMB/M3/M4/M5 and cast each; Wall retains hold-to-aim/release-to-place. No public
server deployment or Workshop publication is included.

# Previous candidate — integrated equipment, exchanges and Magic

Author-directed six-part continuation preserves `402ecb2` and extends the server
inventory/SQLite/UI/Magic authorities: four Debbie drag-and-drop actions, durable
DFT exclusions and fusion recreation inheritance, authoritative capacity snapshots,
feet-hull Wall placement with Wisdom duration, server-rolled Watermelon bounces,
and persisted RMB/M3/M4/M5 bindings. Wall now holds to aim and releases to cast;
idle selection shows no guide. All 116 automated suites pass. See
[implementation, tuning and native acceptance](EQUIPMENT_MAGIC_INTEGRATION_20260918.md).
Native multiplayer acceptance remains pending; no server deployment is included.

# Previous candidate — Equipment access, real capacity and Debbie exchange

Author-directed continuation from `cace700`: O matches P/I menu input mechanics;
the inventory displays actual equipment capacity and separate consumable stacks;
Debbie has prominent carried-equipment and DFT pages, drag/drop sell/fuse piles,
atomic equipped-item exchange and enforced DFT-recreation exclusion.
All 114 automated suites pass. See [implementation and native check](EQUIPMENT_EXCHANGE_REPAIR_20260918.md).
Native menu/drop feel and multiplayer visual acceptance remain pending.
No server deployment is included.

# Previous candidate — usable Wall placement, aiming preview, offensive starters

Author-directed repair from `3e7a83b`: forgiving bounded Wall fitting, an owner-only
server-calculated aiming preview with rejection reasons, and direct-damage first
Forms for every Wizard. Wall and Summon remain available through later grants.
All 114 automated suites pass, including 84 aiming cases and 3,000 Wizard starts.
See [correction, evidence and finite native check](WALL_PLACEMENT_REPAIR_20260918.md).
Native placement/preview feel remains pending. No server deployment is included.

# Previous candidate — Equipment O toggle, Watcher scan and Wizard Wall

The 2026-09-18 author-directed continuation from `c6bd155` fixes focused Equipment
toggling and Watcher dispatch, adds the tenth Form (Wizard-only Wall, Heroes pass
through) and an admin all-Forms test command. All 113 automated suites pass.
See [implementation, tuning, evidence and native session](EQUIPMENT_WATCHER_WALL_20260918.md).
Native Wall rendering/collision and Watcher scan/retreat acceptance remain pending.
No server deployment or Workshop publication is included.

# Previous candidate — wielded colors, ordinary pistol/crowbar loot, Super Ball

The 2026-09-18 author-directed continuation from `d7fe92a` repairs the held
render path and hand completion, adds starter-family variants to ordinary
Dungeon-1 loot, and integrates Super Ball as the ninth Form. All 111 automated
suites pass, including 4,800 loot samples and geometric ricochet/lifecycle tests.
See [implementation, tuning, evidence and one native action](WIELDED_LOOT_SUPER_BALL_20260918.md).
Native wielded colors, multiplayer presentation and bounce feel remain pending.
Prior crash safeguards and newer gameplay systems are preserved; no deployment
or Workshop publication is included.

# Previous candidate — audio ownership, weapon regions and Watermelon

The 2026-09-18 author-directed pass is implemented from `6aba7b0` on `main`.
See [changes, tuning and finite native acceptance](AUDIO_WEAPONS_WATERMELON_20260918.md).
Looping ambience has finite ownership; the Hermit shares the original musical
cue lane; six stock weapons have three real color regions; Watermelon is an
integrated eighth magic Form. All 109 automated suites pass. Native GMod sound,
animated region placement and multiplayer visual acceptance remain pending.
The prior maze-deployment crash repair is preserved. No deployment or Workshop
publication is included.

# Previous candidate — maze-deployment generator crash repair

`generator-jit-20260917-01`, developed on `main` from `eb20c8f`.
The supplied x64 minidump identifies Equipment.Generate during initial maze
loot allocation and reports LuaJIT 2.1.0-beta3 with the old safeguard skipped.
The recorded reward corpus independently segfaults on upstream 2.1.0-beta3
with generator compilation enabled. Extend the function-only interpreter
safeguard to every LuaJIT; preserve loot determinism and the integrated refresh.
The generator now has its own loaded-component receipt. All 108 suites pass.
See [evidence and the single deployment acceptance action](GENERATOR_CRASH_REPAIR_20260917.md).
Native acceptance remains pending; no deployment or Workshop publication.

# Previous candidate — integrated gameplay refresh

The 2026-09-17 author-directed 26-part pass is implemented on `main` from
`aeaa6b3e24a53b9578be35cae2238f916eebb9e0`. See
[the checkpoint and finite native checklist](INTEGRATED_REFRESH_20260917.md).
All 107 integrated suites pass, including 512 deterministic encounter plans,
real SQLite sale/fusion rollback, Haste input, status remedies/procs, vertical
Magic cover, derived UI, observer range and identity presentation. Native
GMod composition, stock material topology, feel and multiplayer acceptance
remain pending. No server deployment or Workshop publication is included.
The newer geometry/full-update repair below remains a regression constraint.

# Previous candidate — client geometry initialization repair

`geometry-init-20260916-01`, developed directly on `main` from verified
`0ef180ae886fd91b8a5e9ebbd6502c084de63f17`.

The reported repeated GetBoxMins error is reproduced by notifying transmission
before SetupDataTables supplies the client accessors. The previous full-update
harness assumed these accessors already existed and missed this lifecycle order.
Static-box transmission recovery now only restores membership and schedules a
bounds refresh. Bounds and all four affected entity render paths wait for their
required accessors; incomplete entities remain registered and recover on the
next ready frame without another Initialize or transmission notification.

Live GDD: 00/01 and 07 client presentation/reconnection authority. Routine
implementation correction; no design or tuning changes. Finite automated gate:
actual notification/render hooks with absent and individually missing accessors,
deferred bounds retry, full-update recovery and genuine removal; integrated gate.
Validation: the expanded regression fails with the reported GetBoxMins error on
the prior implementation and passes with this repair. All 104 integrated suites
pass, including the Lua syntax audit.
Native gate remains pending: join the updated server, then perform one client
full update and verify floors/gates remain visible with no recurring Lua errors.
No server installation or Workshop publication is included.

# Previous candidate — collapse restart, camera and client recovery

`collapse-recovery-20260916-01`, developed directly on `main` from verified
`4e0aad2497aa5a20172a4b1493c826bf6151b9ad`, preserving the newer server listing,
loading artwork and client branding delivery commits.

Collapse completion starts server-owned deadlines: automatic new campaign after
20 seconds; fresh E press allowed after 5 seconds. Periodic aftermath snapshots
show both countdowns. The existing epoch-guarded restart transaction owns manual
and automatic requests. Server hibernation ownership lasts until restart, so an
empty server cannot strand an already-started aftermath.

The camera now faces the native Flattywood sign from its opposite side, pitched
40 degrees down with FOV110, horizontal stand-off 1.6 times prison radius and
a 160,000-unit far plane covering the distant skybox sign.
Stock BSP sign geometry/skybox conversion was inspected; 4:3 visible-frame tests
cover the prison footprint and full sign height. Native composition remains a
visual acceptance gate.

Source full updates may call OnRemove(true) without a subsequent Initialize.
Floor, gate, keycard and jail-door render registries now retain that membership
and recover it on NotifyShouldTransmit. A production draw-hook regression proves
reappearance after temporary invalidity and genuine removal without ghost draws.
No every-frame entity scans or network polling are added.

Live GDD: 00/01, 05 LOD-TIMER-001, 06 lifecycle and 07 tuning. The explicit new
restart/camera direction is recorded in 05/07. Finite gate: timer deadline/race,
manual key lockout, empty-server auto restart, camera projection and full-update
render recovery. All 104 integrated suites pass. GMod check: trigger a collapse,
inspect the sign/prison framing, let the countdown restart unaided; verify the
five-second E shortcut and client cl_fullupdate recovery in a separate run.
No server installation or Workshop publication is included.

# Previous candidate — Brute attack restoration

`brute-attacks-20260916-01`, developed on `main` from verified
`15387a51366b6f7e2343736a9cb2519d24afdc25`.

Reproduced: the ordinary Brute Tick refused attacks while a Neil defense order
existed; hits on Neil cancelled the Brute's telegraph; Neil's death could leave
that defense order permanently set while the Brute continued pursuit. Defense
routing now permits the authored charge. Further damage to Neil replans routing
without cancelling a committed Brute attack. Neil death clears obsolete defense
routing and refreshes survivor pursuit. Charge damage/timing, ordinary hit stun,
control cancellation, stairs, gates and wall-impact vulnerability are retained.

Live GDD: entrypoint/index, 05 LOD-OBJ-002 / LOD-ENEMY-003, exact HUMAN Neil/Brute
paragraphs, and 07 existing charge/hunt tuning. No design or tuning changes.
Finite automated gate: reproduce the old failure through ordinary Tick; prove
warning, one charge hit, cooldown and attacks after Neil's death; reuse existing
charge/wall/stair/control tests and the integrated gate.
Validation: all 103 integrated suites pass; the new ordinary-Tick regression
failed against the prior build and passes with this correction.
Finite GMod gate: damage Neil, let the Brute finish his warning, and confirm a
charge; kill Neil first and confirm the surviving Brute can still attack.
Native GMod acceptance remains pending; no server deployment is included.

# Previous candidate — dungeon transition retention

`dungeon-return-20260916-01`, developed directly on `main` after promoting the
accepted weapon build `fdea1ac0bc1e69765cff7e629a7590f85eeef5a2`.

Successful rescue resets the collapse clock to 30:00 and pauses it through
intermission, generation and staging. The next dungeon's first Hero deployment
starts its deadline; an expired rescue still loses before rewards. Native Hero
inventory snapshots reject Soldier and pending respawn bodies. Restoring owned
weapons bypasses new-item capacity admission with scoped exception cleanup.
Equipment records, slots and stacks remain bound to the same Hero state.

Finite automated gate: real completion/advancement/build/deferred-spawn test with
a full bag, exact weapon/clips/ammo/active selection, stored rolls and consumables,
Soldier retirement, overlapping builds and failed-Give cleanup; timer regression
for reset, paused staging, next start and deadline race; integrated suite.
Validation: all 103 integrated suites pass, including the new transition harness.
Finite GMod gate: complete one dungeon with carried gear, wait in next staging,
confirm 30:00 and retained weapons/items, then deploy and confirm countdown.
Native GMod acceptance of these transition fixes remains pending. No server
installation or Workshop publication is included.

# Accepted weapon visuals — promoted to main

Author request: remove procedural cosmetic gun attachments; represent stored
properties with tint, partial procedural textures, radiant aura and muzzle color.
Use **Wintery** as the Ice flavor adjective. Candidate runtime identity:
`weapon-surfaces-20260916-01`, based on verified remote main/dev
`55c48d5152a3847c9b93f8078b85fc6ded95d7f3`.

Implementation uses sparse bundled detail maps over the native gun texture,
scoped gun-only submaterials, bounded soft sprites and observed native shots.
No attachment geometry or extra model entities. Frozen records are preserved;
legacy Watery names migrate only when displayed. The live GDD tuning/economy
rules and generated canonical manual now reflect the author correction.
All 102 integrated suites pass; the historical LuaJIT 2.0.4 crash replay still
passes 1,400 exact rewards (with the authorized adjective substitution).
See `docs/WEAPON_SURFACES.md` for implementation boundaries and the visual gate.
Shael accepted the weapon visuals on 2026-09-16. Verified main was fast-forwarded
to `fdea1ac0bc1e69765cff7e629a7590f85eeef5a2`. The equipment branch is closed;
all subsequent work is on main unless Shael explicitly directs otherwise.

# Previous stabilization candidate

Candidate `stability-20260916-08` repairs a **reproduced native LuaJIT 2.0.4
equipment-generation SIGSEGV**. The new 3960-event original session ends during
wearable generation after an SMG Deadcrab kill; its mirror omits 53 final events.
Both realms load 07 on x86 LuaJIT 2.0.4. The exact reward corpus crashes a
standalone historical 2.0.4 VM with compilation enabled and passes when only
`Equipment:Generate` and its closures are interpreted. Apply that scoped
workaround on legacy LuaJIT; keep global JIT, deterministic item contents and
all gameplay systems intact. Modern 2.0/2.1 tests alone missed this defect.

All **102 integrated suites pass**, plus historical-VM exact-corpus, 16,000-item
distribution and production pickup/preparation tests. Re-enabling generator
compilation restores SIGSEGV in the standalone regression control. This proves
the defect/workaround outside GMod; **fresh x86 GMod acceptance remains required**
before attributing the user's termination conclusively or promoting the build.
See `docs/GENERATOR_CRASH_REPAIR_20260916.md` for evidence, reproduction and the
single sustained-playtest gate. Preserve the map/timer and earlier stabilization
repairs in `docs/CRASH_MAP_REPAIR_20260916.md` and
`docs/RELEASE_STABILITY_20260915.md`. No main promotion or live deployment.

# Current development plan

`main` is the canonical development baseline. Shael explicitly approved candidate
`87920e5ba3b27d46ff096f5a85cd41030a77f964` for promotion on 2026-09-14;
that exact commit was fast-forwarded to remote `main` without code changes.

Astra / Work is the primary implementation and senior-engineering environment.
Sol complements it with architecture, review, planning, and bounded implementation
where useful. Antigravity and `hybrid/antigravity` are retired as active development
workers/workflows. See [Development workflow](DEVELOPMENT_WORKFLOW.md).

## Current checkpoint — native manual payload transport

The 2026-09-15 native console proves why both manual entry points appeared inert:
`cl_instruction_manual.lua` aborted on startup because the client could not
include `lod/manual/manifest.lua`. The earlier lifecycle regression exercised a
local filesystem double and therefore proved the reader after initialization,
not the actual server-to-client delivery prerequisite that failed in GMod.

The client no longer includes the generated manifest or HTML chunks. The server
loads the one canonical generated document, compresses it once, and streams it
on demand in ordered messages capped at 60,000 bytes. P → Manual and staging E
now create the visible frame immediately, request the same payload, validate and
reassemble it, and cache it for subsequent openings. A failed or malformed
transfer leaves a visible retry control rather than an absent reader. Runtime
identity is `stability-20260915-04` and now requires `manual` and
`manual_reader` receipts. All 95 integrated suites pass, including production
client-launch and server-transport regressions. Native GMod acceptance remains
pending; no main promotion or public deployment is included. See
[Canonical instruction manual](INSTRUCTION_MANUAL.md).

## Previous checkpoint — Hermit starter-weapon crash repair

The first 2026-09-15 force-close report ended without a Lua traceback immediately
after class/feat setup. Candidate `stability-20260915-02` moved the whole starter
transaction beyond Touch and added durable breadcrumbs. A subsequent native test
still force-closed and proves that candidate did not resolve the defect: the last
stage is `before_native_give` for `weapon_smg1`, with no `after_native_give`.
The remaining native seam is therefore synchronous `Player:Give`, including the
project's `WeaponEquip` and pickup-policy callbacks fired from that call.

Every project `WeaponEquip` hook now performs zero synchronous weapon/player
inspection or mutation and schedules its complete work for the next tick. This
includes SMG capacity, shotgun capacity/seventh-shell, AR2 balance, procedural
equipment recording and grenade rejection. The protected one-time starter grant
also bypasses the project's capacity callback without interrogating the
half-constructed weapon. The native grant is protected against Lua errors and
retains the existing stage breadcrumbs. Runtime identity is now
`stability-20260915-03`. All 94 integrated suites pass, including a real SMG-hook
regression that throws on any access before simulated native settlement. Native
GMod acceptance remains pending; no main promotion or public deployment is
included.
See [Hermit starter crash repair](HERMIT_STARTER_CRASH_REPAIR.md).

## Previous checkpoint — Hero respawn loadout retention

The author explicitly corrected the older death-loss rule: consuming a Hero life
must not empty that Hero's run inventory. `PlayerDeath` now captures the native
loadout at the authoritative death seam even though Source already reports the
victim as dead. The saved state includes ordinary weapon classes, both magazine
values, reserve ammunition, armor and the actively wielded ordinary weapon.
Respawn restores that snapshot and reselects the wielded weapon.

The identity-owned equipment bag is no longer replaced on death, so equipped
wearables, stored items and grenade-slot potions survive unchanged, including
final-life elimination followed by a later campaign revival. Human Soldier deaths
remain isolated and cannot overwrite the stored Hero loadout. The manual now
teaches the corrected retention rule. Deterministic lifecycle coverage exercises
death capture through the real hook and the subsequent spawn restore. Native
Garry's Mod multiplayer acceptance remains pending; no main promotion or public
deployment is included.

## Previous checkpoint — manual launch and HUD layout repair

The portable reader had installed its JavaScript-to-Lua bridge before Chromium
loaded the manual document, contrary to the DHTML lifecycle contract. A document
replacement could therefore discard every callback and leave the launched reader
nonfunctional. Bridge installation and bookmark restoration now happen from
`OnDocumentReady`; both staging E and Player Menu continue to use that one reader.

The campaign clock has its own upper-left row below the run/card block instead of
sharing the objective's upper-right band. The status portrait stays bottom-aligned
with the stock HP/Magic row, even when a weapon is equipped, and the wielded weapon
name is now centered vertically to the portrait's right. All 93 integrated suites
pass, including engine-lifecycle and six-viewport layout regressions. Native
Garry's Mod input/rendering acceptance remains pending; no main promotion or
public deployment is included.

## Previous checkpoint — wearable and potion drop repair

The final campaign-assistance override had retained an older category table and
enemy-spawn routine, shadowing the Equipment Update logic loaded earlier. Natural
enemy loot could therefore produce procedural weapon records but never select a
wearable category; it also omitted the equipment-eligible identity needed for
wearable conversion and the Healing Potion/Stink Bomb split. The final authority
now preserves the authored 75% useful band and relative wearable 24, consumable
12 and weapon 12 weights at every campaign-assistance depth. All seven wearable
families and both throwable consumables reach world pickups.

Prepared rewards are validated before native entity creation, generator errors
are contained at that boundary, pickup naming no longer dereferences unchecked
consumable records, and loot pickups retain native model scale rather than
requesting a collision-adjacent scale mutation. All 93 integrated automated
suites pass. Native Garry's Mod collection and force-close acceptance remain
pending; no public deployment or main promotion is included. See
[wearable drop repair](WEARABLE_DROP_REPAIR.md).

## Previous checkpoint — canonical illustrated instruction manual

The author requested a revised console-booklet-style guide and one canonical
in-game reader shared by staging E and the portable P → Manual tab. The reader
now loads independently of the physical book, remembers its page and scroll,
and uses the shared menu lifecycle. The guide covers the current continuation,
with original Deborah and antagonist art plus the complete feat/equipment
reference. See [manual authority, evidence, and native check](INSTRUCTION_MANUAL.md).
Native Garry's Mod rendering/input acceptance and the existing crash release hold
remain pending. No public deployment is included.

## Previous checkpoint — campaign clock and TIME OVER

Implements the author's explicit 2026-09-15 continuation over `af5b4f7` on
`astra/equipment-update`: one 1,800-second campaign clock, first-Hero portal
commit start, continuous cross-level timing, global destruction cinematic,
persistent aftermath and canonical E restart. The handoff supersedes the live
GDD's older per-dungeon timer and rescue exemption. All 90 integrated automated
suites pass; Source camera/physics/audio and multiplayer acceptance remain pending.
The existing native-crash release hold remains open. See
[TIME OVER checkpoint and one integrated playtest](CAMPAIGN_TIMEOUT.md).

## Previous checkpoint — complete ordinary enemy roster

Implements all nine missing v1 ordinary enemies over development baseline
`90477d7acc61091710c9ba18e49f1920073b1bc0`: Climber, Nodule, Flamer, Big Crab,
Sentry, Razor, Arc Caster, Lurker and Beam Sweeper. Existing ordinary enemies and
Neil/Brute/Gordon remain intact. Fix model-unsupported Sniper activity requests
and retreat animation selection at the shared activity/Motion V2 authorities.
Author-approved tuning is recorded in live GDD 07; the manual teaches the roster.
All 89 automated suites pass. Native visual/co-op acceptance and the fatal-crash
release hold remain open. Heavy remains explicitly deferred beyond v1.
See [roster, validation and finite test](ENEMY_UPDATE.md).

## Previous checkpoint — Gordon the Warden

Implements Gordon over development baseline
`253af3b273f53d5c6910931fc4c5d738f8418be8`, on `astra/equipment-update`.
The two-level arena, three combat phases, protected co-op entry/respawn,
ordered party health scaling and death-only center Jail Key replace the temporary
Core shortcut. Author-approved tuning is in live GDD 07. All 88 automated suites
pass. Gordon uses a seeded stock male citizen with a heavy build and procedural
pig mask, requiring no external model download. The adaptive
soundtrack remains dependent on its unshipped MusicDirector/suite system;
Gordon publishes its tension hooks and supplies entrance/phase/victory cues.
Native visual/co-op acceptance and the fatal-crash release hold remain open.
See [implementation, dependencies and finite playtest](WARDEN_CHECKPOINT.md).

## Previous checkpoint — Neil and the Brute

Implements the post-Yellow hunt over development baseline
`e7576355967084b9fca246022ce9a4b3a7da6148`, on `astra/equipment-update`.
Neil uses legal multi-floor escape routes; the Brute escorts him, responds to
damage, and has a committed charge with wall-stun counterplay. Neil alone
releases the physical Black Keycard. The fourth gate establishes checkpoint 4
before the explicitly permitted temporary Core Jail Key. Gordon remains next.
The author's follow-up approved choosing the missing encounter tuning; values
are recorded in live GDD 07. All 86 automated suites pass; native combat feel,
multiplayer acceptance and the outstanding fatal-crash gate are not yet accepted.
See [implementation and finite playtest](NEIL_BRUTE_CHECKPOINT.md).

## Previous checkpoint — native crash audit repair candidate

Audit of dev HEAD `d59d2df2274cd11fb6311b7c3d89bef2a6b8ed9e` completed;
all 366 production sources match remote content. Latest detailed log again
ends at `loot_enter` (Shambler #1272), without the preceding candidate's new
loot/profile markers. Actual loaded build and native fault remain unproven.

Direct hostile-to-LootDirector handoff replaces the load-order class patch and
native placeholder fallback. Remove twelve additional unnecessary activation
calls, defer starter-pickup retirement beyond touch, bound/reclaim native mesh
and afterimage caches, and unwind mirror render state after Lua errors.
Installer/build receipts now identify loaded components and resource trends.
All 85 automated suites pass. Main/public release remains held for fresh native
acceptance. See [native audit, evidence and acceptance](NATIVE_CRASH_AUDIT_20260915.md).

## Previous checkpoint — consistent GPS and loot crash candidate

Starting dev HEAD `a671934496c51a2306e7e5634642e3bbfcee781c` on
`astra/equipment-update`. GPS retains its voice, WIS 17 gate and G toggle,
but triggers after 1 second stationary and repeats after phrase duration plus
4 seconds. Two-cell same-floor proximity uses the existing faction opponent
registry, including human Soldiers and enemies behind walls. Movement, combat
input, staging/death/spectating and lost ownership cancel speech and reset the
idle trigger. Shared voice tokens/durations, one channel and generation checks
prevent delayed file opens or timers reviving canceled speech. No random wait,
new pathfinder or enemy replication. Missing routes retry at most once a second.
Live GDD 04 and the exact HUMAN GPS row are reconciled.

Crash evidence: `rpg_test_session(20260915-151547).txt` reaches sequence 308,
time 142.245, Soldier #1174 at `loot_enter`, without `loot_complete`. Its death
callback and corpse presentation completed; a separate nonlethal Bio Blaster
hit and client feedback also completed. The periodically copied summary is
older (sequence 263), so use the full session for event order. These logs show
the older percentage-stat build, not acceptance evidence for the flat-stat patch.
There is no native stack trace; the exact crash cause remains unconfirmed.

The loot path called Activate after an anim pickup's SetModelScale. Facepunch
explicitly documents potential collision-rebuild crashes for that combination:
https://wiki.facepunch.com/gmod/Entity:SetModelScale
Remove unnecessary activation from real pickups and the fallback decoration.
Arm touch collection next tick, after metadata/transmission registration; defer
successful pickup removal beyond touch traversal. Keep automatic collection and
existing grant idempotence. Add bounded LOOT_NATIVE_STAGE breadcrumbs around
handoff/category selection, model validation, spawn and registration. Profile
logs now include the new flat STR/WIS bonuses; summaries retain legacy fields
for older evidence. This is a repair candidate, not a proven native-crash fix.

All 84 automated suites pass. New tests exercise production GPS cadence and
async cancellation plus real pickup initialization/registration with simulated
spawn overlap and duplicate touches. Headless checks cannot validate native
collision behavior or audible timing. Next finite native gate: play normally,
stand still in a safe corridor to hear GPS, and collect a killed Soldier's drop.
If force-close recurs, preserve console_latest.txt and rpg_test_session.txt before
relaunch. No main promotion or public deployment.

## Previous checkpoint — flat Strength and Wisdom damage

Starting dev HEAD `2a098bc73080ba69bd3653da412730058c34a422` on
`astra/equipment-update`. Author rebalance replaces percentage STR/WIS damage
with the effective ability modifier as one flat addition per resolved attack
contract per target. Live GDD 02/03 now replace the superseded full-positive-STR
penetration rule. Only physical Fighter attacks protect ceil(max(STR_MOD,0)/2)
from CON. The remaining modifier joins the first positive damage contribution
before its usual CON subtraction and minimum-1 floor; the protected portion is
added afterward. Other original contributions retain per-die CON, and existing
separate flat bonuses retain their treatment. No positive contribution means
no invented hit. WIS uses the same flat addition without Fighter penetration;
wisScaled=false keeps its existing exemption. Negative modifiers have no bypass.

STR 20 adds 5, with 3 protected for a Fighter. A base roll of 1 against CON
reduction 3 resolves to 4 for that Fighter, versus 3 for another class or a
WIS 20 magic attack, before later modifiers. Exploding chains and shotgun shares
do not multiply the number of additions. Existing aim/backstab multiples,
capstones, equipment, element resistance and downstream defenses still apply.
Committed attacks preserve firing-time STR/WIS and class. Killer Instinct now
shares the pure base arithmetic without changing combat telemetry. Class cards,
Character Sheet tooltips/passive text and developer status reflect flat bonuses.

All 82 automated suites pass, including real shared damage dispatch, flat/odd/
negative modifiers, low/zero dice, WIS, class isolation, explosions, shotgun
shares, aim/backstab stacks, committed stats, gear/elements and Hero/AI/Soldier
parity. The all-class staging snapshot regression remains green. Next finite
native gate: play the high-STR Fighter again and check low physical rolls against
a CON-resistant enemy; inspect the STR tooltip and damage log. Actual in-game
balance acceptance remains pending. No main promotion or deployment.

## Previous checkpoint — procedural weapon visual identity

Starting dev HEAD `5125fb03310529f5319b7c3755ee21da09161654` on
`astra/equipment-update`. Author direction permits a broad visual system. Live
GDD 07 now records the grammar and performance limits. Shared appearance data
projects all 60 catalog properties, magnitudes, quality, rarity and seed into
stable fittings, labeled glyphs, magnitude bars, penalty fractures, a dominant
element core and procedural machining/finish. Receiver plates have brushed,
ceramic, carbon-weave or hammered detailing; stat and rider silhouettes use
anvils, fins, coils, plates, lenses, crests, buds, fangs, shards and cages.
First-person, visible third-person active weapons, owner-visible world pickups
and inventory share the grammar. Equipment details and the canonical booklet
teach the visual key; exact values remain on the item sheet. Conditional marks
use existing HP/Magic/movement state. No gameplay or animation authority changes.

A versioned compact descriptor is stamped only when the selected immutable
record changes. Same-family copy selection updates appearance; merely collecting
a copy does not. DFT recreation preserves the frozen appearance. No weapon/hand
material mutations, extra entities, emitters, dynamic lights or entity scans.
Weak caches, fixed materials, near/distant detail tiers and per-frame world caps
bound work; reduced effects keep meaningful marks while stopping the pulse.
Attachment-less melee viewmodels follow the hand bone when available.

All 82 automated suites pass. The new validator covers every property/shape,
2,500 distinct sampled appearance fingerprints, deterministic frozen/reordered
records, malformed payloads, actual copy selection, unchanged sends, renderer
quality/distance/frame limits, balanced render contexts and cache cleanup.
Largest sampled wire descriptor: 78 bytes, under the 480-character ceiling.
These checks cannot establish native aesthetic quality. Next finite in-game
gate: inspect two same-family guns, equip each, and compare their element core,
rider fittings, glyphs, hand/sight clearance and the Equipment Visual Key.
Viewmodel attachment positioning, surface lighting and readability need native
visual acceptance. No main promotion or deployment.

## Previous checkpoint — Fighter feat-draft delivery blocker

Starting dev HEAD `0902ab038902c763d94ed28be9c95995ad370458` on
`astra/equipment-update`. Fresh evidence: `console_latest(20260915-143951).txt`
and `rpg_session_latest(20260915-143950).txt`. Fighter commits at session time
18.030, followed by repeated snapshot failures at sv_character_progression.lua
1609: bad argument #6 to format (no value). The class description introduced
in the loot/class checkpoint contained an unescaped literal percent in a
string.format template. Draft generation succeeded, but the deferred snapshot
producer failed, leaving the client without its offers and staging correctly
blocked on the uncommitted feat. Escape the percent; no eligibility, draft,
class balance or portal rule changes.

The production snapshot test now covers Fighter, Rogue and Wizard from class
commit through three delivered choices, stable refresh, feat commit and the
actual IsDeploymentEligible predicate used by the portal. It reproduced the
exact logged formatting failure before repair. The prior test exercised Rogue
and missed the Fighter-specific template. The same console also identifies an
independent statue timer error from invoking client-only SetupBones on the
server. Guard that call; a server-realm test verifies pose selection, frozen
sequence/cycle and scowl finish without that method.

All 81 automated suites pass after repair. Native acceptance remains pending:
pull/install, restart, choose Fighter and confirm the three feats appear; choose
one, collect the starter and enter the portal. Existing valid offers are retained
on refresh. No live GDD correction is needed for these implementation defects.
No main promotion/deployment; earlier native-crash diagnosis remains unconfirmed.

## Previous checkpoint — four working Wall Jumps

Starting dev HEAD `e22fd90c8ab96d5ccb2790963a4cac8961c97348` on
`astra/equipment-update`. The user reported Wall Jump had no effect. Its brush-only
trace and HitWorld-only acceptance excluded the labyrinth's `lod_static_box`
collision architecture. Use MASK_PLAYERSOLID with the actual standing/crouched
hull and accept map world, generated static boxes, gates and jail doors. Reject
actors, props, cosmetics, embedded starts, floors and ceilings.

Wall Jump now permits four successful kicks before landing, each on a fresh
jump press. Set ordinary vertical takeoff and the existing 160-unit outward
normal speed so falling/inward momentum cannot cancel the jump; preserve
horizontal tangential velocity. Spring Heel scales only vertical takeoff. The
shared feed reports the used count. Cloud Step stays independent and lower
priority; failures do not spend uses. Ground contact resets the counter, including
when a landing jump press precedes Think. Death/actor lifecycle resets remain.

Live GDD 04 LOD-FEAT-005 and the exact HUMAN DEX_WALL_JUMP row are updated, as are
the feat description and exact-row test fixture. All 81 automated suites pass.
The expanded movement suite exercises input, generated-wall probes, four/fifth
kick behavior, crouch, falling/inward velocity, ground/death reset, Cloud Step,
Spring Heel and invalid/held cases. Native acceptance remains pending: with Wall
Jump owned, jump alongside a labyrinth wall and release/repress Jump for each
kick; the feed should count 1/4 through 4/4 before landing restores the allowance.
No main promotion or deployment; previous crash diagnostics remain.

## Previous checkpoint — ordinary loot, carried copies and class combat

Author direction is reconciled in live GDD 03 LOD-CBT-007, 06 inventory/DFT rules
and LOD-UI-010, and 07 tuning. Starting dev HEAD:
`5892fe2a68bd239d4977f64b0b66304f4fdd5e0d` on `astra/equipment-update`.

Ordinary useful-drop chance is 75% (90% at the existing dry-streak threshold).
Wearables, guns and consumables have increased category weights; all seven
wearable families are reachable. Auto pickup stores distinct rolls, including
multiple copies of a weapon family, without replacing equipped gear. Copies
share the family's existing ammunition. Dragging in/out works across snapshot
arrival, and any unequipped item can be trashed. Full bags preserve the drop.
Equipment remains through mazes/reconnects and is cleared at Hero death. DFTs
are separate persistent rewards minted only during rescue settlement, retaining
transactional rollback/replay protection and the eight-token cap.

Pickup comparison is deprecated in favor of large full names. Drops and
Omniscience use bounded near-look selection with line of sight and cloak guards.
Rogues add one damage multiple and bypass CON resistance from the rear; Fighters
add positive STR modifier percentage points to shield Block under the shared
33% cap. Debbie is frozen client/server, 1.2 scale, with stone wings and soft
blue/gold light, preserving the granite Deborah pose and staging placement.

All 81 automated suites pass, including SQLite rollback, actual acquisition,
copy selection/ammo, all-family loot, trash/death, snapshot/drag protection,
backstab multipliers, shield gating, near-look visibility and bounded statue FX.
The field manual and class UI describe the revised rules. In-game acceptance is
pending. Next finite gate: collect two same-family guns and a wearable, drag
them in/out, trash a stored copy, and verify the equipped roll/ammunition remain
correct. The crash diagnostics are retained; this pass provides no fresh native
crash evidence. No main promotion or deployment.

## Previous checkpoint — Fighter Strength bypasses Constitution resistance

The author buffed every Fighter-class actor's positive Strength damage bonus:
calculate that bonus from the physical roll before CON reduction, while base
damage still receives the existing per-die resistance. If U is the unreduced
aggregate, R the reduced aggregate and S the STR multiplier above 1, resolve
R + U × (S − 1). Keep the existing behavior for penalties, non-Fighters and Magic.
Apply authored scale, capstone, shotgun shares, gear, elements and subsequent
defenses normally. The class flag follows committed equipment snapshots; class
choice and Character Sheet text explain the benefit. Live GDD 02 LOD-CLS-006 and
03 LOD-CBT-006 contain the author's correction. Starting dev HEAD:
`574c032ca3e1c7411f91c57732871fc430215469` on `astra/equipment-update`.
`tools/test_fighter_strength.lua` tests the real derived-state and damage paths,
class/actor parity, low and exploding dice, flat bonuses, penalties, scaling,
shotgun shares, elemental/gear defenses and committed attack identity. All 80
automated regression suites pass; the identity-perk expectation now includes the
Fighter bypass while preserving its single flat favored-weapon bonus.
Native acceptance remains pending: attack a resistant enemy as a Fighter and
compare the final damage with the die readout. Existing crash diagnostics remain;
this balance change provides no new native-crash evidence. No main promotion or deployment.

## Previous checkpoint — monster class and elemental identity

The author's monster-readability request adds subtle class modulation: Fighter
keeps its archetype paint, Rogue adds pale green, Wizard adds pale violet.
An independent seeded one-in-three roll assigns one of the six existing elements
to generated monsters, including human-controlled Soldier incarnations. Matching
resistance and reciprocal weakness use the shared damage ladders. Separate
depth-tested elemental motes and aimed element words respect cloaking and reduced
effects. No dynamic lights, emitters, added entities or monster-list scans.
Live GDD 03 LOD-ELEM-002, 07 and the exact HUMAN spawn paragraph reconcile the
former 50% rule with the author's one-third direction. Automated validation and
the finite native playtest are recorded in [Monster identity](MONSTER_IDENTITY.md).
Next runtime gate: meet ordinary enemies, compare class tints and elemental cues,
then hit a typed monster with matching and opposing Magic. Prior native crash
causes remain unresolved; preserve existing diagnostics. No main promotion or deployment.

## Previous checkpoint — Size Shifter wall-entrapment repair

The player reported becoming stuck in a wall with Size Shifter. The old code
changed native model scale without an explicit movement-hull authority, and
routine derived-stat sync briefly restored baseline size before reapplying the
current transformation. Shared client/server movement now installs ordinary
standing/crouched hulls; server size changes preserve those hulls and reject
blocked growth. A blocked transition retains its progress and resumes smoothly
when clear. Derived-stat sync applies the current size once, without the baseline
snap. The live INT_SIZE_SHIFTER rule already requires legal ordinary movement;
no GDD redesign was needed. All 78 automated suites pass. Native runtime
acceptance remains pending: crouch, move along a wall/corner, then release crouch;
repeat below a low ceiling. See [Size Shifter repair](SIZE_SHIFTER_REPAIR.md).

## Previous checkpoint — elemental magic and equipment inventory

The latest author request restores the procedural weapon name below the HUD face,
adds weapon stow/re-equip with empty inventory tiles, and mixes wearables/potions
into ordinary enemy drops. Six Forms now share original elemental impact
choreography; detonation cores/lobes/smoke supplement the existing accurate area
indicators. Bolt/Missile use enchanted comet visuals; Summon has an elemental
aura and contact effects. Work is bounded and supports reduced effects.
Live GDD 03 LOD-FX-001, 06 LOD-UI-008/009 and 07 record the current direction.
77 automated suites pass. GMod visual/interaction acceptance remains pending.
Next gate: ordinary gm_flatgrass run, cast equipped spells, stow/re-equip a gun
through Equipment, and collect mixed ordinary enemy drops. Preserve prior native
crash diagnostics; this checkpoint supplies no new evidence resolving that crash.
See [magic and inventory checkpoint](MAGIC_INVENTORY_CHECKPOINT.md).
No main promotion or deployment.

## Previous checkpoint — labyrinth-entry crash candidate and granite Deborah

The fresh staging playtest force-closed on reported labyrinth entry. Its 139-event
session ends after successful DFT recreation, without combat, death or a native
fault trace. The portal now queues its native teleport/pickup work outside the
input callback, coalesces duplicate Use requests, and cancels stale player/run
state. Bounded deployment-stage logs identify the next failure boundary.
The statue is beyond the portal opposite the Hermit, offset from its approach,
with the configured Deborah model, gray granite, frozen folded-arm idle selection
and scowl flexes. Live GDD LOD-UI-009 records the revised presentation direction.
All 76 automated suites pass; native crash resolution and statue visual acceptance
remain pending. Next gate: fresh-start gm_flatgrass, inspect the statue and enter
the labyrinth normally. See [entry-crash evidence](LABYRINTH_ENTRY_REPAIR.md).
No main promotion or deployment.

## Previous checkpoint — status portrait beside Magic

The author's latest HUD direction explicitly supersedes the earlier face-position
hold. The portrait now sits immediately right of the scaled Magic readout, aligned
to its bottom, with the character-name/status caption wrapped above it. Remove
the persistent carried-weapon name and always suppress stock secondary-ammo/ALT
FIRE; retain primary ammo, Equipment item names and functional Magic/potion prompts.
Live GDD LOD-UI-009 and tab 07 record the correction. All 76 integrated suites pass,
including responsive layout checks at 640×480, Steam Deck, 4:3, 16:9 and ultrawide.
Source visual acceptance remains pending. See [portrait checkpoint update](STATUS_PORTRAIT_CHECKPOINT.md).

The preceding native crash remains unresolved: no fresh playtest evidence was
provided. Preserve its repair/diagnostic candidate and finite Soldier-kill retest
below. No main promotion or deployment.

## Open runtime checkpoint — Soldier crash investigation and wallet repair

The 2026-09-15 playtest force-closed. The full log records a successful Raw Bolt
hit followed by a lethal AR2 hit on the same Soldier; it ends before death/XP
completion. The native fault is not established. Repair the independently
reproduced wallet SQL-quoting defect, defer native corpse mutations out of the
death callback, guard duplicate kill settlement and add bounded death-stage
diagnostics. All 76 integrated automated suites pass. Source crash resolution
remains pending: repeat only Bolt → AR2 Soldier kill on a fresh application start.
See [evidence, repair and finite gate](CRASH_REPAIR_2026_09_15.md). No main
promotion or deployment; retain the combined candidate's feature scope.

## Previous checkpoint — Equipment tab, filled Magic areas and rear statue

The author's follow-up presentation direction is implemented on the same combined
`astra/equipment-update` candidate under live GDD LOD-UI-009. Equipment is now a
first-class sibling tab with its own frame; Magic areas have solid outer boundaries
and approximately 40%-opaque interiors; the Deborah statue is behind the Hermit
and uses the portal/manual prompt style. The author's subsequent correction
explicitly retains the existing face HUD position. All 75 integrated automated
suites pass; Source visual acceptance is pending. See
[presentation checkpoint](PRESENTATION_POLISH.md).

## Previous checkpoint — visual equipment inventory

The author's CRPG equipment direction is implemented on the combined
`astra/equipment-update` candidate under live GDD LOD-UI-008. A left body map and
right icon grid support compatible drag/drop and click-to-equip, paired gloves,
weapon selection and consumable stacks. Owner snapshots preserve the window and
active drag; stale requests cannot remove a replacement item. All 74 integrated
automated suites pass; Source visual acceptance remains pending.
See [equipment inventory checkpoint](EQUIPMENT_INVENTORY_UI.md).

## Previous checkpoint — reactive character status portrait

The author's Doom-inspired HUD direction is implemented on the same combined
`astra/equipment-update` candidate. The live GDD LOD-UI-007 records the local HUD's
character-name-only exception, shared Character Sheet face, status replacement and
reactive expressions; tab 07 records cosmetic timing/layout choices.
See [portrait checkpoint](STATUS_PORTRAIT_CHECKPOINT.md) for implementation and the
finite visual gate. This preserves the equipment, enemy, wallet and Wizard changes
below. All 73 integrated automated suites pass; Source visual acceptance is pending.

## Previous checkpoint — persistent $DEB / DFT economy and Wizard balance

Shael accepted all [proposed wallet/DFT defaults](DEB_DFT_PROPOSAL.md) on 2026-09-15
and requested completion. The live GDD now records LOD-ECON-001 and the Wizard
changes in normalized tabs 02/03/06 and their HUMAN counterparts.

The combined `astra/equipment-update` candidate contains server-local transactional
wallets, rescue contribution allocation, persistent lifetime score, once-per-server
Combat Level 1/5/10/20 DFTs, rare drops, eight-slot collections and pending milestones,
and free once-per-token-per-run recreation or permanent sale at the staging statue.
Wizards gain one distinct starting Content; Summon is Wizard-only with base cost 12.
See [current evidence and finite runtime gate](CRYPTO_CHECKPOINT.md).
All 72 integrated automated suites pass. Source multiplayer/restart acceptance
remains pending; do not equate automated checks with a live-server acceptance.

The same candidate preserves the equipment, perk, enemy, recurring-staging, Hermit
and leaderboard changes for one combined playtest. The low-end/distant-player
[performance checkpoint](PERFORMANCE_CHECKPOINT.md) also remains intact: equipment
snapshot coalescing/deltas, retained pickup layouts and unchanged-stat caching.
Source FPS/RAM and real-network performance acceptance remain pending.

## Next scope

Shael's Equipment handoff explicitly promotes Equipment implementation ahead of
public deployment. Work is isolated on `astra/equipment-update`; main remains the
accepted RPG baseline. Workshop and public VPS are held until Equipment and Enemy
are both complete, followed by separately authorized deployment.

Shael's 2026-09-15 direction expands the approved first equipment catalog into a
unified procedural weapon/wearable economy and explicitly authorizes its missing
formulas. Live GDD LOD-EQUIP-016 owns the new 60-property catalog, budget/rarity
curves, active-weapon contributions, statuses and acquisition behavior. Earlier
LOD-EQUIP-015 Block, Throwable and Special Move semantics remain in force.
See [economy rules and handoff](PROCEDURAL_ITEM_ECONOMY.md) and
[checkpoint](EQUIPMENT_CHECKPOINT.md). Equipment runtime acceptance remains pending. The later explicit user direction
authorizes Enemy development alongside the Equipment playtest; main promotion
still requires appropriate runtime acceptance.

The subsequent 2026-09-15 completion assessment found and repaired a real
Equipment blocker: full procedural pickup records exceeded the engine's
NW2String limit, breaking comparison data. Owner-checked inspection messages now
carry the complete record, with production server/client transport tests; all
66 integrated suites pass. See [completion assessment](EQUIPMENT_ASSESSMENT.md).
The subsequent user direction explicitly supersedes the conditional Enemy hold.
Equipment and Enemy can now be tested together on the same development branch.

Preserve accepted RPG behavior and the current workflow. Do not restart the old
hybrid/Antigravity process. The broader Instruction Booklet reconciliation and
outstanding RPG multiplayer release validation remain required before deployment.

## Combined Equipment / Enemy checkpoint

Shael explicitly requested Enemy variety while testing Equipment. The first
combined checkpoint adds the Sniper graph-retreat/crossbow controller, Sniper and
Blitzer variants of eligible Firing Line encounters, and repairs the unified
spawner's missing Blitzer entry. Existing equipment and perk changes are retained.
See [Enemy update checkpoint](ENEMY_UPDATE.md) for the finite playtest and remaining
scope. All 67 integrated suites pass; this is a development-branch candidate,
not in-game acceptance or completion of the full Enemy milestone.

Continue the missing canonical enemies and final hunt/boss/timer work. The live
GDD leaves required attack tuning unresolved for Flamer, Big Crab, Razor and Arc
Caster; do not fabricate those numbers. Sniper tuning is explicitly delegated and
is recorded in tab 07. Authored Climber behavior and the remaining explicitly
specified work can continue independently of those gaps.

## History

The subsequent user-requested [identity perk correction](PERK_UPDATE.md) is a
bounded detour on the same Equipment development branch. Independent category
rolls and duplicate stacking are retained and explicitly tested; new ability
perks support +2 or +1/+1, and every visible title/flavor follows the resolved
mechanics. Existing Heroes keep their permanent rolls. All 66 integrated suites
pass; Equipment runtime acceptance remains pending.

The [pre-promotion plan](DEVELOPMENT_PLAN_HISTORICAL_2026_09_14.md) preserves earlier
checkpoint sequencing and candidate handoffs. It is historical evidence, not the
current task queue. [Development status](DEVELOPMENT_STATUS.md) records promotion
and validation. The live GDD remains design authority.
