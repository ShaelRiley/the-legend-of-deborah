# Current development plan

`main` is the canonical development baseline. Shael explicitly approved candidate
`87920e5ba3b27d46ff096f5a85cd41030a77f964` for promotion on 2026-09-14;
that exact commit was fast-forwarded to remote `main` without code changes.

Astra / Work is the primary implementation and senior-engineering environment.
Sol complements it with architecture, review, planning, and bounded implementation
where useful. Antigravity and `hybrid/antigravity` are retired as active development
workers/workflows. See [Development workflow](DEVELOPMENT_WORKFLOW.md).

## Current checkpoint — flat Strength and Wisdom damage

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
