# Current checkpoint — low-end PC / Steam Deck client optimization

The author's slowdown report promotes the planned low-end work. This checkpoint
extends main `3d60d6f730b56abbf3df5de68bb8d71002d44d96` with immutable container
palette/material caches, conservative rear-camera static-geometry rejection,
pass-local floor material reuse and an Options checkbox for the existing saved
Reduced Effects preference. Skeletons, events, loot, enemy population/AI,
geometry/collision, music defaults and all gameplay rules are unchanged.
The full gate also repairs a nil-target guard in the fallen-Hero damage wrapper
and missing native API doubles in an older protected-regression harness.

Read `validation/LOW_END_PC_20260928.md` for paired operation counts, cache/camera
safety cases and the exact-source native procedure. Three new low-end checks and
six retained music/options checks extend the complete canonical gate to 285
suites. Retain the initial 279/285 run (four timeouts and two repaired regressions);
the final complete run uses a 600-second per-suite headless allowance with no
reduced inputs or assertions. The immutable local/independent receipts, not old checkpoint
counts below, establish this candidate's aggregate result and published identity.
Publication requires both gates and an exact-parent non-forced main update.

Next is ordinary Steam Deck play on the installed source: the efficiency changes
are automatic; Reduced Effects is an optional saved choice in Options. Native
FPS/frame time and visual acceptance are not measured by headless tests. Preserve
all previous native gates and local acceptance → Workshop parity → matching VPS.
No Workshop/VPS deployment belongs to this source checkpoint. Historical sections
below remain evidence, not instructions to repeat completed work.

---

# Current checkpoint — live GDD reconciliation complete; native acceptance next

The author's express approval to amend the GDD closes the Big Loot, Big Event,
Music and Big Skeleton synchronization backlog against gameplay main
`2847f416b8d152a24ac4d282cc012e73ddb131d7`. Recent SPOT, audit, cleanup and
equipment/faction repairs are represented; obsolete deferrals and music
implementation-pending/default-On statements are corrected. The newer modular
boss design remains intact and is not claimed implemented by this checkpoint.

Read live GDD 00 → 01 → the relevant normalized rule. Big Loot's active catalog
is now in 05; HUMAN retains all 113 exact authored identity rows. Exact duplicate
passages were consolidated into canonical references to resolve apparent size
pressure, with every retained rule verified. All ten tab texts match the expected
edit, and native date elements and tab topology are preserved.

See `validation/GDD_SYNC_20260928.md` and its JSON receipt. Earlier failed-write
notes below are historical; do not replay their old insertion payloads. This
checkpoint changes documentation only. Gameplay/source-test evidence and all
pending native acceptance remain unchanged. Next: the finite Big Skeleton local
gate below, then existing native gates; retain local acceptance → Workshop parity
→ matching VPS. No Workshop publication or VPS deployment occurred.

---

# Prior checkpoint — Big Skeleton source; native acceptance next

Author-directed design and implementation extends verified main
`f0b7a66d0e87c18ad18b45a6449b613b7f8ee11d`. Skeleton Blockade remains registered
after Bribe removal; a separate 65% priority draw and two-dungeon drought cap
now make it frequent without changing exact 1d4 density or the rare slot.
Accepted Hero and human-Soldier deaths independently create hostile AI copies
of their current builds, using shared combat and lifecycle authorities.

See `BIG_SKELETON_UPDATE.md` for behavior, explicit AI-action scope and the
finite local gate. `validation/BIG_SKELETON_UPDATE.md` records 52/52 targeted
regressions, 798 Lua syntax checks, final lifetime hardening checks, frequency
samples and retained logs. Native appearance/combat/co-op acceptance is pending.
Google again rejected the guarded GDD write; final proposed 05/06/07 amendments
are preserved in `validation/BIG_SKELETON_GDD_AMENDMENTS.json`. Earlier GDD
synchronization debt and native gates remain independent.

Next action on exact local source, `gm_flatgrass`:
`lod_developer_mode 1; lod_event_preview_generate skeleton_blockade`.
Then follow the short fallen-player test in the implementation note. Preserve
local acceptance → Workshop parity → matching VPS; no deployment is claimed.
Evidence: `console_latest.txt` + `rpg_summary_latest.txt`.

---

# Prior checkpoint — Music System source; streaming defaults OFF

The author-promoted Music System extends verified main
`c5ece210be12077c321264ad4abb81821fe8d9a5`. `lod_music_enabled 0`
is the default; only the server may permit streams. Existing player Music Off
also wins. Live GDD 00→01→05/06/07 and the Options anchor govern six roles,
optional interlude, inheritance/universal themes, sets, frozen floor plans,
spatial/pressure mixing, accepted-victory continuity and private Die Logger starts.

See `MUSIC_SYSTEM.md` for implementation, bounded HTTPS ingestion/upload, original
separate default assets, operator commands and the finite native gate. Source
verification results are recorded in `validation/MUSIC_SYSTEM.md`. Native audio,
UI, network and performance acceptance remain pending; no public HTTPS origin,
Workshop update or VPS deployment is claimed. The required default-Off GDD edit
and provisional tuning write failed with HTTP 400 FAILED_PRECONDITION; fresh
readback is unchanged. Exact amendments: `validation/MUSIC_GDD_AMENDMENTS.json`.
Earlier Big Loot/Event synchronization debt remains independent.

Next: provision/audition the default profile on an operator-controlled HTTPS
origin, install the exact source locally, start a new campaign and run the short
native music gate. Maintain local acceptance → Workshop parity → matching VPS.

---

# Current checkpoint — Big Event System source validated; native acceptance next

The author-promoted `briefs/EVENT_SYSTEM_UPDATE.md` extends verified main
`1685774415ea8bbd82abf931999a29ae7ba25f10`. Frozen active baseline8, additions20,
production total28 (3.5×); removed Bribe stays removed. Exact1d4 density, shared
rare fourth slot, existing progression proofs and source-only publication remain.

See `EVENT_SYSTEM_EXPANSION.md` for catalog, shared settlement, family/identity
ecology, successful-build campaign memory, topology preferences and a compact
native procedure. All **274/274 suites and 784 Lua syntax files pass**, including
six new gates; the source remained unchanged throughout the full matrix. See
`validation/BIG_EVENT_UPDATE.md` and its complete receipt/evidence archive.
Native Source physics/input/presentation/network/co-op acceptance remains pending.

Live GDD00→01→05/06/07/90 read successfully. Google rejected the revision-guarded
write with `FAILED_PRECONDITION`; fresh readback confirmed no mutation. Exact
six-tab changes remain in `validation/big_event/gdd_amendments.json`. This is an
explicit synchronization blocker, not a completed GDD update. Prior Big Loot
amendments remain independently outstanding. No Workshop/VPS action.

Next after verified source publication: exact-build local `gm_flatgrass` event
acceptance, retaining earlier accepted behavior and pending gates. Capture
`console_latest.txt` + `rpg_summary_latest.txt`. Apply the pending live GDD changes
when editing is restored; unrelated deferred roadmap work is not included.

---

# Current checkpoint — Big Loot source validated; live GDD synchronization blocked

Author-promoted Big Loot extends verified baseline
`fc166870633db5f277165d9c33ae00d82feaa81a`. Final gameplay/test commit:
`4f9ec7928f4a44107066da3095937655db806941`. This closeout adds documentation/evidence only; the delivery
response supplies the fetched, verified final remote HEAD.

Frozen baseline **45**, added **113**, total **158 (3.5111×)** meaningful identities.
Stable effect packages, campaign motifs/history, contextual/topological rewards,
late optional treasure, inventory pressure and immutable source receipts extend
existing authorities. Native weapon restoration and atomic sell/fuse are repaired.
See `BIG_LOOT_CATALOG.md`, `BIG_LOOT_ECOLOGY.md` and
`validation/BIG_LOOT_UPDATE.md` for architecture, constants and exact evidence.

Complete finite matrix: **268/268**, **774 Lua syntax files**, unchanged source.
32×20 campaigns with two owners expose all 113 additions; mean 106.516 / minimum 100
per owner-campaign, 92.75% fewer immediate repeats and 35.94% less adjacent-level
overlap versus history-disabled control. All 15,422 support nodes preserved.
Sampling uses empty bags/native doubles; native gameplay and balance are unaccepted.

**Outstanding:** Google Docs rejects live GDD edits with HTTP 400
`FAILED_PRECONDITION`; fresh reads confirm no mutation. Exact seven-tab amendments
and 113 authored rows are saved in `validation/big_loot/gdd_amendments.json`.
Apply/read back after editing is restored. No live synchronization or complete
end-to-end closure is claimed. Native `gm_flatgrass` pickup/equipment/economy,
lifecycle and co-op acceptance follows verified publication, preserving all prior
acceptance constraints. No Workshop/VPS action. Earlier Big Loot deferrals are
superseded by this explicit author request; unrelated roadmap work stays deferred.

---

# Current checkpoint — stalled cleanup reconstructed; native acceptance next

September 27 author-requested recovery extends verified main
`aa102cc31951d34937ebaa106314cfcfdb855a2f` without repeating the prior systems audit.
See `validation/CLEANUP_RECOVERY_20260927.md` for repaired loot/campaign/staging,
party scaling, jump/death lifecycle, warp diagnostics and isolated Bribe fixtures.
The complete gate retains all 262 earlier suites and adds two production tests
(264 entries; 767 Lua syntax files). Final pass/tree/publication evidence belongs
to the delivery receipt, not a source-preparation assumption here.

Next after verified publication: exact-build local `gm_flatgrass` acceptance.
Preserve existing regressions and local acceptance -> Workshop parity -> matching
VPS. No deployment or deferred-roadmap work is included. Older headers below are
historical where this checkpoint supersedes them.

---

# Current checkpoint — September 27 systems audit complete

The author's audit request supersedes earlier deferrals. Source and validation
repairs are published through `864cdf36854c3671926a9473221c74b7ca727fa5` on main;
this closeout changes documentation only. Read `validation/SYSTEMS_AUDIT_20260927.md`
for findings, exact tree/source digest, coverage and the retained failed attempts.

The complete expanded matrix passes **262/262**, including **765 Lua syntax
checks**, with identical source before/after. The original matrix was 228/235.
Minimap cache/request/lifecycle ownership, Muted potion input, duplicate equipment
sync and stale validation contracts are repaired. No automated failure remains.

Next finite gate: exact-build local gm_flatgrass acceptance, including Muted potion
use and map reopening after rebuild/respawn. Retain all previous SPOT,
Soldier/Reckless, stair, stomp, arrow-input, B28/B29 and Crate acceptance constraints.
Native input/network/physics/rendering and co-op acceptance remain open; headless
results do not establish them. Preserve local acceptance -> Workshop parity ->
matching VPS. No Workshop/VPS deployment occurred during this audit. Historical
sequencing below is superseded where it conflicts with this checkpoint.

---

# Current overlay — Heavy Plumber and arrow-input equipment repairs

September 27 author-requested spot fixes preserve main baseline
`38adbce415ae6dd388c28a450bb9cd3b7a8248d2` and all Soldier/Reckless, standing-stair
and SPOT-17 work. Read `docs/validation/EQUIPMENT_STOMP_CONTACT_20260927.md` and
`docs/validation/EQUIPMENT_ARROW_INPUT_20260927.md`; fetch current main and use the
external delivery receipt for exact published commits/tree and independent gate.
First-impact stomp geometry and bounded ordered input transport extend their
existing authorities without changing attack costs, damage or recipes. Native
acceptance remains pending. No Workshop/VPS actions, full campaign-matrix pass,
SPOT-18 or deferred-roadmap work is claimed. Historical sections follow.

---

# Author-reported stair ceiling repair — native acceptance next

### Current author-requested spot repair — Soldier / Hero and Reckless damage (September 27, 2026)

The standing-stair repair remains preserved. The new unnumbered damage repair follows current combat roles rather than engine player class and respects attacker-only Reckless in native damage and real attack geometry. See `docs/validation/FACTION_RECKLESS_DAMAGE.md` and the external publication receipt for exact child/tree and headless results. Native acceptance remains pending; no Workshop/VPS action. This is not a new scheduled SPOT-18 or a restart of the deferred roadmap.


September 27: the rear crossover lip now retracts 16 units, sharing its 48-unit
width with the rail opening. Upright stair-step clearance increases from 80 to
96 units; the existing standing hull, solid floors, treads and no-jump upper
circulation remain. See validation/STAIR_HEADROOM_20260927.md for the failed
baseline, finite regression and native limits. Final aggregate results and exact
publication identity belong to the delivery receipt.

After verified publication, update the local install and walk a fresh stair up,
down and around its upper landing without crouching or jumping. This repair does
not accept SPOT-17 or any earlier native debt, start deferred roadmap work, or
authorize Workshop/VPS deployment. Earlier headers below remain historical.

---

# SPOT-17 source complete — spot queue complete; native acceptance next

Human Soldiers now use the AI Soldier's configured base speed (currently 140),
without ordinary sprint or grounded jump. Existing class/DEX/status/Haste and
directional effects remain; granted airborne movement feats remain off-commitment.
An accepted rifle attack roots voluntary movement through warning, all rounds and
actual cadence-adjusted recovery. Gravity/forced motion remain; current-life,
weapon, role and dungeon cancellation cannot carry a root into another body.
Dodge cannot reuse a pre-commitment motion sample. Heroes and AI retain their rules.

Live GDD 06/07 SPOT-17 delegated movement/tuning supplements were written and read
back before production changes. The existing source/attack/movement/control/Dodge
and client projection seams are reused. No recurring timer or movement owner added.
See validation/SPOT_17_MOVEMENT_GATE.md. The frozen contract retains all 93 earlier
selections plus two focused production tests (95 selected; 756 Lua syntax files).
Final local/independent results and publication identity belong to the external
receipt, not a pre-publication assumption. Native Source prediction/physics,
cooperative enemy readability and earlier acceptance debts remain open.

SPOT01–17 now have source implementations. After verified publication, the next
action is exact-build local gm_flatgrass acceptance, particularly Soldier movement,
rifle commitment and F3-to-Hero recovery. Use console_latest.txt and
rpg_summary_latest.txt plus a short observation; detailed session only for disputed
timing. No dedicated Razor retest. Preserve all previous approved work. No Workshop
or VPS action is authorized; retain local acceptance -> Workshop parity -> matching
VPS. Deferred roadmap work is not automatically authorized by completing this queue.
Earlier headers below are historical where superseded by this one.

---

# SPOT-16 source complete — SPOT-17 next after verified publication

Human Soldiers now receive an incarnation-bound Pulse Rifle with INFINITE ammo,
committed three-round baseline bursts and preserved burst/rate/aim authorities.
Zero clip/reserve works without cartridges, reload or a refill service. Stale
body/role/dungeon/weapon work cancels; Hero finite ammo and SPOT-15 lifecycle remain.
No Soldier movement, jumping or attack-rooting changes are included.

Live GDD 06/07 already contained the recovered SPOT-16 rules; no duplicate amendment.
Focused attempt 07 passes 988 server + 32 client assertions. The final frozen-source
contract is 93 selected suites (all prior 90 plus two focused suites and the existing
burst-cleanup regression), with 753 Lua syntax checks. Final local/independent
results and publication identity are supplied by the external delivery receipt.
See validation/SPOT_16_SOLDIER_RIFLE.md for honest attempt history and native limits.

After verified publication, implement only SPOT-17: Soldier committed-attack rooting
and movement restrictions approximating AI Soldiers. Reconcile the live GDD before
code; preserve readable, consistent enemies for human Heroes. No deferred roadmap,
Workshop publication or VPS restart is authorized. Preserve SPOT01–16, Float On at
1 Magic/s, B28/B29, approved Crate and P1–P4. Earlier sequencing below is historical
where superseded by this header.

---

# SPOT-15 source complete — SPOT-16 next

The author-directed Soldier F3 team menu is implemented. Live/waiting Soldiers can
return to the Hero queue or spectate only; the saved Hero, genuine death delay,
server authority and ordinary Hero choices are preserved. The actual revived Hero
spawn now uses the existing slot authority. Pre-closeout: 90/90 selected suites,
425 focused assertions and 751 Lua syntax checks. Final frozen-source and independent
publication facts belong to the delivery receipt. Native input/co-op/font/timing
acceptance remains open. See validation/SPOT_15_SOLDIER_MENU.md.

Next, implement only SPOT-16: human Soldier pulse rifle, three-round bursts and
infinite ammo in place of the SMG. Reconcile current main and relevant GDD before
code. Do not batch SPOT-17 movement restrictions or deferred roadmap work. Preserve
SPOT01–15, B28/B29, approved Crate, P1–P4 and local acceptance -> Workshop -> VPS.
No Workshop/VPS action authorized. Earlier sequencing below is historical where
superseded by this header.

---

# Active roadmap — author-directed spot updates

## Current checkpoint — SPOT-14 Time Management

Actual gameplay parent: `3b4df50fe001dd0dc7e2d7df9e3339a6bcceff13`.
Time Management is an ordinary, one-rank INT 17 cooperative-Hero feat. Living,
completed deployed holders add their positive effective INT modifier in minutes,
once per identity. The existing deadline gains or loses only the difference in
current party allowance. Death, disconnect and Soldier/spectator transitions remove
allowance; return restores it only before expiry. Hourglass time remains independent.
Same-dungeon internal build holds retain established non-growing allowance without
refunding elapsed time; real lifecycle losses still win. Old expiry precedes gains,
rescue and Hourglass debit. Rescue/new campaign reset to the ordinary paused clock.

[Implementation, raw attempts and limits](validation/SPOT_14_TIME_MANAGEMENT.md):
focused attempt 08 passed **258 production assertions**. The finite final contract is
**87 selected suites**, retaining all 85 SPOT13 selections and adding ordinary-clock
and SPOT14 integration tests. Exact final local/independent receipts and non-forced
child/tree/run belong in the external delivery receipt, not an unrun pre-publication
claim here. Live GDD 04/05/06/07, canonical manual and both generated readers align.
Native timing, co-op/rejoin, appearance/font and balance acceptance remain open.

**Next single bullet after verified publication: SPOT-15 — human Soldiers may open
the team menu with F3 at any time to return to the Hero queue or spectate, with a
visible hint.** Reconcile current role/queue/control/UI authority before code. Do not
implement SPOT16/17 or deferred roadmap in that checkpoint. Preserve SPOT01-14,
Float On at 1 Magic/s, B28/B29, Crate/P1-P4 and local acceptance -> Workshop parity
-> matching VPS. No Workshop/VPS operation is authorized.

## Previous checkpoint — SPOT-13 unread-update markers

Actual gameplay parent: `795dd444144e4e733dea58e56b4302bcb648f1ba`.
Character, Spellbook and Equipment now mark meaningful unseen updates with a
static exclamation above their existing navigation buttons. Inventory is the
bag inside Equipment, not a new page. First sync is quiet; only the exact updated
page's post-child paint acknowledges it. Sibling/loading/blocked/stale pages and
drag-deferred inventory cannot clear unseen content. Ordered snapshot envelopes
reject stale data; ordinary resync/floor changes preserve unread state, while
campaign/profile/life changes retire it. Routine resources remain quiet.

[Implementation, attempts and limits](validation/SPOT_13_UNREAD.md): final focused
production test **317 assertions passed**. The finite aggregate contract is **85
selected suites**, retaining all 83 SPOT-12 selections; final local/independent
results and verified non-forced child/tree/run are in the external delivery
receipt, not assumed from this pre-publication source document. Live GDD 06/07,
canonical manual and both generated readers align. Failed attempts remain raw.
Native rendering/font/network/co-op and full campaign acceptance remain open.

**Next single bullet after verified publication: SPOT-14 — Time Management,
prerequisite INT 17.** Reconcile exact time units, presence, stacking and
join/leave anti-exploit rules in the live GDD before dependent code. No SPOT14
implementation or deferred roadmap work belongs in SPOT13. Preserve SPOT01-12,
Float On at 1 Magic/s, B28/B29, Crate/P1-P4 and local acceptance -> Workshop parity
-> matching VPS. No Workshop/VPS operation is authorized.

## Previous checkpoint — SPOT-12 Spellbook availability surfaces

Actual gameplay parent: `8b2e936f83f9740f40082fd0c3d04dc3feafde01`.
Cards now tint their entire backdrop and border from the existing blue/red/gold/
muted availability state. Dark selection outlines and matching hover accents do
not mask warnings. Literal labels, costs, descriptions, Magic authority and all
configuration/casting rules remain; long descriptions use an existing small-font
fallback. Live GDD 06/07 and both canonical manual readers align.

[Evidence and limits](validation/SPOT_12_SPELLBOOK.md): **83/83 selected pre-closeout
suites, 1441 new focused assertions, 745 Lua syntax checks**, unchanged source;
minimum computed card-text contrast 5.119:1. All 79 SPOT-11 selections retained.
Final frozen local/independent hashes and non-forced main publication are in the
delivery receipt. The first focused width failure and interrupted 57-suite gate
remain honest incomplete/failed evidence. Native appearance/co-op acceptance and
the full campaign matrix are not claimed.

**Next single bullet: SPOT-13 — unread-update markers for Spellbook, Character
Sheet and Inventory, clearing only the corresponding viewed update.** Reconcile
live notification/snapshot ownership before code. Do not start SPOT14 or deferred
roadmap work here. Preserve Float On at 1 Magic/s, SPOT01-11, B28/B29, Crate/P1-P4
and local acceptance -> Workshop parity -> matching VPS. No deployment authorized.

## Previous checkpoint — SPOT-11 four-choice ordinary feat drafts

Actual gameplay parent: `85db2ed5ce287e7dbd96197676af4799922a6bf6`.
New ordinary hands target four distinct eligible offers, legal neutral fallbacks
only. Genuine smaller pools remain smaller; zero eligible choices are an explicit
resolved no-award slot, not a fabricated perk or staging soft-lock. Existing valid
stored hands, including legacy trios, retain their IDs/order/seed/result. Human
heroes choose once; AI/human Soldiers automatically consider the entire hand.
Capstone trios and Magic choices are unchanged. Four-card sheets use responsive
2x2 or single-column layouts. Live rules and both manual readers align.

[Evidence and limits](validation/SPOT_11_DRAFTS.md): pre-closeout **79/79 selected
suites, 1055 new focused assertions, 744 Lua syntax checks**, unchanged source.
All 72 D-J selections are retained. Final frozen local/independent identity and
verified non-forced publication belong in the delivery receipt. Earlier 71/72,
78/79, interrupted launches and focused fixture failures are preserved.
Native acceptance and the full campaign matrix are not claimed.

**Next single bullet: SPOT-12 — Spellbook card/backdrop availability colors.**
Reconcile live UI/accessibility law before code; do not start SPOT14 or deferred
roadmap work inside this checkpoint. Preserve Float On at 1 Magic/s and all
SPOT01-10, B28/B29, accepted Crate appearance, P1-P4 and release gates.
No Workshop or VPS operation is authorized.

## Previous checkpoint — SPOT-10 D–J approved and implemented

From actual main parent `7e2495ccfba3009f8190bd619ea229a8e65da094`.
Shael approved D–J, amending Float On to **1 Magic/second** for up to six seconds.
Arc Recovery 11; Feedback Loop 2/continuation, cap12; Recovery ceilings22/44/66%
at base rates1/1.5/2%MaxHP/s; ammo refill22/44/66%faster at unchanged floors;
Presence22/44/66%; aura fixed3seconds. Existing IDs/prerequisites, rejected A and
prior B/C/Mana Spring remain. Live GDD03/04/exact HUMAN and cards/manual align.

[Implementation and limits](validation/SPOT_10_SECOND_PASS_IMPLEMENTED.md):
**72/72 selected suites, 765 focused D–J assertions, 742 Lua syntax checks**,
unchanged source. All earlier64 selections retained. These are source gates,
not a full campaign matrix or native balance/control/co-op acceptance. Earlier
63/64 and71/72 attempts remain in the provenance record. Final frozen local/
independent identity and verified publication belong in the external receipt.

**Next independent bullet: SPOT-11 — four-choice feat drafts.** Reconcile live
draft law, eligibility/small pools, stored pending hands, authoritative one-choice
commit and UI before implementing. Do not begin SPOT12/SPOT14 or deferred work
inside this checkpoint. Preserve native/release gates; no Workshop/VPS operation.

## Previous checkpoint — SPOT-10 first approved corrections and second-pass review

From actual main parent `0b8321344737d11547f323c993b279de7c400d4f`.
A is rejected; its explosion ladder stays. B (fixed 3-second Mind Over Matter),
C (25% Frugal discount with existing map floor/Haste composition) and the author's
Mana Spring revision (flat 22% faster permitted passive regeneration) are implemented.
Live GDD 04/exact HUMAN rules, cards and both manual readers are aligned.

[Evidence](validation/SPOT_10_APPROVED.md): first local aggregate **64/64 selected
suites, 129 focused assertions, 741 Lua syntax checks**, unchanged source; retained
SPOT09 regressions, not the full campaign matrix. Final frozen local/independent
identity and verified publication belong in the delivery receipt. Native balance,
resource feel and co-op acceptance remain open.

**Next: author decisions on [second-pass proposals D–J](validation/SPOT_10_SECOND_PASS.md).**
These focus low-payoff effects, not relaxed prerequisite ladders; no comprehensive
personal pick-rate telemetry is claimed. D–J are not approved or implemented.
Do not fold SPOT11, SPOT14 or the deferred roadmap into this checkpoint.
Preserve all earlier native/release gates; no Workshop/VPS action.

## Previous checkpoint — SPOT-09 Damsel's Revenge

From actual main parent `9b89fdd2cfb1eed7d4d9cb1e172b5d02f44a2d86`.
One finite consumable arms the stationary jailed Damsel with a frozen procedural
Pistol, SMG or Pulse Rifle. Shared source-bound payment, canonical physical dice,
exact real-Gordon targeting, visible jail firing slit, encounter lifetime and
normal rescue authorize one owner-only at-feet gun pickup during existing victory.
No Hero ability/feat inheritance, Hector fire, new reward authority or free ammo.

The [finite gate](validation/SPOT_09_REVENGE_GATE.md) passes **477 focused numbered
assertions plus 512 seeded reward cases, 59/59 selected suites and 740 Lua syntax
checks**, unchanged source. See [implementation and limits](validation/SPOT_09_REVENGE.md)
and [preserved attempts](validation/SPOT_09_ATTEMPTS.txt). The first aggregate was
58/59 due to escaped-HTML test matching; that failure remains a failure. Final
frozen local/independent hashes and publication identity belong in the delivery
receipt. Native gun/port/animation/audio/pickup/co-op/performance acceptance remains
open; this is not a full campaign matrix. Manual and both renderings match.

Next single bullet: **SPOT-10 — evidence-backed feat proposals only**. Audit current
live design and implementation, identify obsolete/weak/redundant feats and present
specific changes with rationale and tests for Shael's approval. Do not implement
any rebalance without explicit approval by proposal. Do not fold SPOT-11 four-choice
drafts or SPOT-14 Time Management into this audit. Preserve SPOT-01–09, B28/B29,
accepted Crate appearance and P1–P4. No Workshop or VPS actions.

## Previous checkpoint — SPOT-08 Gordon arena turrets

From actual main parent `35c43bc8bac86e5ea108b9f96e9d5ab6a94bf542`.
Cumulative ordinary Sentry corner turrets at D5/10/15/20, capped at four with
ordinary monster progression thereafter. Separately seeded corners, one safe
admission attempt per slot, no delayed fallback/replacement/respawn. Exact-cell
native hull/support and stair/gallery checks preserve arrival and routes. Shared
96-hostile, 64-roamer, 64-projectile and 16-Gordon-hazard ceilings remain.

Production EnemyRoster owns fixed warned physical fire, bounded captured Hero
lives and guarded native damage. Exact owner/run/life retirement prevents stale
shots across wipes, rebuilds, co-op replacement and Gordon-to-Hector handoff.
Native body removal occurs outside the lethal stack, explicitly before Hector's
reveal. No SPOT-06/07, boss progression, reward or feat-balance changes.

The [predefined finite gate](validation/SPOT_08_TURRETS_GATE.md) first passed
**250 focused assertions, 52/52 selected suites and 736 Lua syntax checks** on
unchanged source. See [implementation and limits](validation/SPOT_08_TURRETS.md)
and [preserved failures](validation/SPOT_08_ATTEMPTS.txt). Final frozen local and
independent hashes, published child/parent/tree and run ID are in the delivery
receipt. Manual and renderings match. This is not full campaign-matrix or native
collision/visual/audio/co-op/performance acceptance. No Workshop/VPS actions.

Historical next action at SPOT-08 close-out: **SPOT-09 — Damsel's Revenge consumable**. Read the exact
queue request and reconcile its item grant/use, jailed Damsel gun/combat, Gordon
ownership, co-op, rescue drop and cleanup contract in the live GDD before code.
Do not fold existing-feat rebalances into it. Preserve SPOT-01–08 and B28/B29.

## Previous checkpoint — SPOT-07 Fake Gordon tells

From actual main parent `c9ddf8cb7d1952ce831d2fdb361c4092ebb85f7d`.
Only a living deployed Hero with positive canonical Wisdom receives private,
short-lived fake recognition within half the Wisdom bonus in squares. Fractional
3D distance and clear sight govern wink/tongue/tint and shared-stun-bound recoil.
Global fake-name/ordinal labels are removed; optional fart is omitted. No shared
control/damage/HP change or extension of SPOT-06's fixed follow-up is introduced.

The [predefined finite gate](validation/SPOT_07_TELLS_GATE.md) first passed
**130 focused production assertions, 50/50 selected suites and 734 Lua syntax
checks**, unchanged source. Final frozen-tree local/independent source checks,
publication SHA/parent/tree and run ID belong in the delivery receipt. Canonical
manual and both renderings are synchronized. See [validation](validation/SPOT_07_TELLS.md)
and preserved attempt provenance; this is not full campaign-matrix or native
visual/co-op/performance acceptance. No Workshop/VPS actions.

Next single development bullet: **SPOT-08 — Gordon arena turrets**. Reconcile the
author's every-five-dungeon-level scaling/corner occupancy in the live GDD before
code. Do not begin SPOT-09 or existing-feat rebalances in that checkpoint. Preserve
SPOT-01–07, B28/B29, accepted Crate appearance, P1–P4 and all native/release gates.

## Previous checkpoint — SPOT-06 Gordon phase one

Recovered from the stalled SPOT-06 thread on September 26, 2026, from exact
published parent `664762a55d096c628ed5a2faff6da6c97c16cf03`, tree
`9faba937d888b33079719aa9b20d719fc01fbbd7`. A full tracked-file source snapshot
and original Git commit were verified before editing. The stalled thread's live
GDD 05/07 candidate design was already present and is preserved.

Phase one now owns a fixed 1.2-second first-effective-visible-hit opportunity,
never refreshed and bounded by reveal+4.0 seconds. Released ordnance keeps its
fuse; unreleased shots cancel. The existing Warden service enforces deadlines
outside stunned AI wrappers. Invisible physical travel, fixed .45-second
arrival/departure cues, displacement rewarning and the .65-second ordinary attack
warning replace ambiguous disappearance. Short contextual taunts share a
6-second encounter cooldown and require ordinary attack appearances between them.
Shared controls and all later phases/progression remain authoritative.

The finite [gate](validation/SPOT_06_GORDON_GATE.md) was defined before code.
Local source validation: **116/116 focused production assertions, 47/47 selected
suites and 733 Lua-file syntax checks**; no source mutation during the gate.
The exact frozen candidate is independently gated before publication; published
parent/tree/SHA and the independent run belong in the delivery receipt, not a
self-referential source-file hash. See [validation](validation/SPOT_06_GORDON.md)
for attempts, limits and the native checklist. This is not a full campaign matrix
or native timing, rendering, audio, collision or cooperative acceptance.

Next single development bullet: **SPOT-07 — Fake Gordon tells**. Do not fold
SPOT-08 turrets, SPOT-09 Damsel's Revenge or existing-feat rebalances into it.
No Workshop/VPS operation or native force-spawn test is part of SPOT-06.

## Previous checkpoint — SPOT-05 canonical Die Logger audit

The September 25 author-directed [spot queue](briefs/SPOT_UPDATES.md) precedes the
scheduled roadmap. One bullet equals one independently validated, non-forced
push. High-level design authority is delegated; existing-feat rebalances remain
approval-gated. SPOT-05 changes presentation/event reporting, not gameplay balance.

The canonical server stream now removes routine passive Magic/full-cap noise,
restores omitted defense/status/duration/recovery/Morale/HP-growth dice and
meaningful outcomes, and uses one event serial for the union of combat
participants and eligible nearby listeners. Private progression remains private.
Life observers bind exact Hero/run ownership; human Soldiers do not display the
dormant Hero name. Both client views retain identical semantic records and order,
with bounded history and ordered long-dice parts. The GDD's explicit passive-Magic
exception and the canonical manual are reconciled.

Final local evidence: **76/76 focused assertions, 38/38 selected suites,
732 Lua-file syntax**, including manual content/transport and unchanged source
during the gate. Its frozen-tree independent result and published child SHA
belong to the delivery receipt. See [SPOT-05 validation](validation/SPOT_05_DIE_LOGGER.md), the stored
receipt and preserved initial attempts. This is not a full campaign-matrix pass
or native rendering/multiplayer acceptance. B29 uses its recorded-layout runtime
mode; the extra 20-seed exposure sweep is not claimed.

SPOT-04 audio remains implemented and native-unaccepted. Its historical gate is
227 passing suites, one unchanged-parent Color-fixture failure and two omitted
campaign suites, not a full 230-suite pass. Fresh SPOT-05 regressions pass
SPOT-04 74/74, Razor 55/55 and Climber 44/44; the separate SPOT-01 50-check result
is inherited from SPOT-04. Earlier validation records are not rewritten.

Shael's one controlled Razor proves only that instance's visibility/basic combat.
Its Occupation/60-roamer upload was developer-dense, not natural release exposure.
**No dedicated Razor retest or natural sighting is prerequisite.** Collect natural
sightings opportunistically; keep the documented native limits and provenance.

## Existing release gates — unchanged

Preserve B28 physical-query repairs, B29 safe arrival/graduated opening,
author-approved Crate visuals, and completed P1–P4 optimization/evidence.
B29's historical 42 selected headless passes remain distinct from the fresh
integration results recorded above and from native acceptance. Its safe-arrival,
controlled-departure and inhabited-exploration native checks remain open.

The established sequence remains focused fatal-crash/game-ending-bug repairs,
local playtest/acceptance of the exact candidate, Steam Workshop item 3791535712
publication with package/source parity, then matching VPS deployment with backup,
rollback and service/listing/connectivity checks. This commit does not publish
the Workshop or change/restart the VPS. Obtain local evidence before those gates.

## Scheduled work — unchanged

| Order | Deferred work | Preserved scope |
| --- | --- | --- |
| 1 | Low-End PC Optimization, September 28–October 4, 2026 | Preserve P1–P4; resume measured active-scan profiling. Native dense frame-time/texture-residency acceptance remains pending. |
| 2 | [Big Loot](briefs/BIG_LOOT_UPDATE.md) | Existing meaningful baseline/approximately 3.5× target; preserve inventory, persistence, sell/fuse and wallet transactions. |
| 3 | [Event System](briefs/EVENT_SYSTEM_UPDATE.md) | Existing meaningful baseline/approximately 3.5× target; preserve exactly non-exploding 1d4 count, deterministic ownership, placement and solvability. |
| 4 | Comprehensive systems integration and emergence audit | Generation through encounters, combat/status, equipment/loot, events/rewards, progression/lifecycle/UI; deterministic, transaction and interaction contracts. |

## Checkpoint practice and preserved history

Read AGENTS → this current section → active brief; live GDD 00 → 01 → relevant
subsystem rules only. State the finite scope, implement at the existing authority,
run targeted checks and the available applicable integration gate, and distinguish
fresh, inherited and unavailable validation. Normally the canonical gate is
`python3 tools/test_checkpoint_g_integration.py`. Never substitute a headless pass
for native acceptance. Update player guidance, live GDD, evidence and handoff;
verify pushed source hashes and preserve newer/uncommitted work without force.

The entire previous development plan, including all historical acceptance records,
Crate constraints, detailed roadmap and checkpoint policies, is retained byte for
byte as [the B29 plan archive](history/DEVELOPMENT_PLAN_B29_20f6ecc.md). Only its
old active-queue precedence is superseded by the new author request. Historical
relative paths in that verbatim archive retain their original `docs/` context.
