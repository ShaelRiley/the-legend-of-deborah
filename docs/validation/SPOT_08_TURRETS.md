# SPOT-08 — Gordon arena turrets

## Scope and design reconciliation

Actual parent: `35c43bc8bac86e5ea108b9f96e9d5ab6a94bf542`, tree
`7701bd9cf27ed7c6488e0ea9554e76bb9fb7a07f`. The initial checkout matched the authentic
commit object and all 2,137 tracked entries. The isolated source-export branch
is infrastructure only and must never enter gameplay ancestry.

Live GDD navigation was 00 → 01 → required 03/05/06/07. SPOT-08 rules and tuning
were reconciled in 05/07 before gameplay code under the author's design delegation.
The [finite gate](SPOT_08_TURRETS_GATE.md) was defined before implementation.
SPOT-06/07 rules are preserved, not duplicated. No SPOT-09 or feat rebalance.

## Implemented contract

Turret count is `min(4, floor(DungeonLevel / 5))`: none at levels 1–4, one at
5–9, two at 10–14, three at 15–19, four at 20 onward. Ordinary Sentry progression
continues after the finite corner cap. A separately seeded four-corner permutation
consumes no existing encounter/actor-generation random stream. Party size does not
change count. Only one admission attempt per selected corner; occupied, unsafe,
failed or capacity-denied slots are skipped, not replaced or retried. Destroyed
or retired actors do not respawn on phase change, death, return or reconnect.

`sv_warden_turrets.lua` extends Warden ownership and EnemyRoster combat, rather
than introducing another damage, movement, status, reward or scheduling authority.
Native actors are ordinary destructible Sentries with normal generated stats,
class/affinity, HP, defenses, physical 2d6+2, status, XP and drops. Bodies reserve
space under the existing 96-hostile ceiling and preserve the 64-roamer limit.
Turret bullets count against BOTH EnemyRoster's 64-projectile ceiling and Gordon's
16-live-hazard ceiling, reciprocally enforced when boss/clone ordnance is admitted.

Selected lower-court corner pockets use canonical Motion floor seating. Native
hull/support checks, exact generated-cell lookup, entry protection, the connected
court/gallery graph and both actual stair travel lanes must pass before and after
normal spawn/variance/Motion settlement. No relocation into a different legal cell
is accepted as a corner. The normal generator's goal Y is interior (4..Height-3);
no speculative global navigation or Motion change was required.

West-side seats face east and east-side seats face west. Standard range 1050 and
110-degree cone leave a lateral approach. Initial admission waits 1.2 seconds plus
0.2 per one-based slot; each stationary physical shot then warns at least 0.75s.
Aim is frozen, source drift over four units cancels, service gap over 0.25s or
release more than 0.2s late forfeits. Ordinary stun/morale/attack prohibition cancel
unreleased fire; Held/Muted retain ordinary physical eligibility. Released bullets
remain nonhoming at 950 units/s with original finite range-derived expiry. They do
not disappear merely because their source takes ordinary hit-stun.

Exact root/native owner, run, graph, progression, level, seed, campaign and canonical
source/target progression/status lives bind every commitment. Court/gallery-only
living deployed Hero eligibility reuses faction/invisibility and physical sight.
At most 32 captured Hero incarnations may intercept that warned shot; new joins or
replacement lives receive no inherited shot. Invisibility denies acquisition, not
ordinary released interception. Alcove protection remains bilateral, including
attributed proxies. The native damage bridge claims before callbacks and checks
its original receipt even if ownership is stripped during the collision query.

No eligible living court Heroes, freeze, failure/wipe, reset, changed scope or
Gordon's defeat retires pending/live turret attacks. No-target waiting retains
surviving HP and consumed slots. Logical retirement precedes native deletion;
exact-body deletion runs outside the lethal stack, explicitly before Hector's
deferred reveal, and cannot remove a newer life/owner. Existing network warning
and bullet presentation are reused; stale/dead/expired turret warning geometry
is hidden in both full and reduced effects. No new Think hook, per-turret timer,
client model, native projectile, world scan or boss progression/reward rule.

## Evidence and its limits

First complete local preflight: **250 focused production assertions, 52/52 selected
suites and 736 Lua syntax files**, with no source changes during the gate. Its
before/after source SHA256 was
`3fce1c409f15c85f0a5cd1fc83f3f4fb1648224870b5a5679fd0788547ca6889`.
That hash predates this documentation close-out. The final frozen local/independent
source hashes, exact candidate/published tree, actual child/parent, full tracked
manifest, patch and independent run belong in the external delivery receipt.
This avoids self-referential commit/hash claims in the source being verified.

The selected gate retains all 50 SPOT-07 suites and adds the SPOT-08 harness and
ordinary EnemyRoster regression. B29 runs `--runtime`, NOT its additional twenty-seed
exposure sweep. The focused harness executes production admission, Sentry
Begin/Attack/Release, shared projectile service, guarded native damage dispatch,
client Sentry warning drawing and Hector's deferred handoff. Native engine calls
(physics, entities, network, clock, renderer) are bounded doubles; Hector's Spawn
boundary is observed in that ordering test and independently covered by the
selected Hector suites. Assertion counts include repeated setup guards; they are
not counts of unique user-visible scenarios. No full campaign-matrix claim.

[Attempt provenance](SPOT_08_ATTEMPTS.txt) preserves two actual focused production
failures: nearest-cell fallback accepted the upper void; ownership loss during
collision bypassed the turret packet guard. Both were corrected and rerun. Other
focused passes and the separate source-export infrastructure failure remain
recorded. Do not retrospectively call the failed attempts passes.

## Native acceptance remains open

Fully restart GMod on `gm_flatgrass`; in ordinary threshold-arena play, use
`lod_warden_status` to compare desired/admitted/alive/skipped counts with visible
corners. Confirm safe arrival, both stairs/gallery routes, full/reduced warnings,
shot dodge/flank/destruction, no respawn on co-op return, and no turret fire after
Gordon death or during Hector reveal. Capture `console_latest.txt` and
`rpg_summary_latest.txt`, plus a brief visual/listening report. No dedicated Razor
retest is required. Native collision/model seating, feel, audio, prediction,
multiplayer latency and performance are not proven by headless tests.

Manual source and HTML/in-game renderings are synchronized. No Workshop or VPS
operation is part of SPOT-08. Local acceptance → Workshop item 3791535712 parity
→ matching VPS remains the release order. Earlier native gates remain open.
