# Current candidate — dungeon transition retention

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
