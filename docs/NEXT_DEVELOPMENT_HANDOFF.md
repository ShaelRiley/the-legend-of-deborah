# Resume The Legend of Deborah — SPOT-08 Gordon arena turrets

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
SPOT-07 actual parent: `c9ddf8cb7d1952ce831d2fdb361c4092ebb85f7d`.
Use the delivery receipt's verified SPOT-07 child SHA, tree and independent run,
then fetch current main and preserve intervening/uncommitted work. The parent
above is historical, not the new HEAD. No source-reconstruction anchor or
infrastructure-only checkpoint branch belongs in gameplay ancestry.

## Orientation

Read AGENTS.md, docs/DEVELOPMENT_PLAN.md, docs/briefs/SPOT_UPDATES.md,
docs/validation/SPOT_07_TELLS.md, docs/validation/SPOT_07_TELLS_GATE.md,
docs/validation/SPOT_06_GORDON.md and docs/TEST_LOGGING.md. Live GDD
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`: 00 -> 01 -> required Gordon,
world/combat/lifecycle/tuning sections. Read HUMAN only for needed detail absent
from normalized rules. SPOT-07 was reconciled in 05/07 before code; do not append
duplicate SPOT-06/07 candidate rules.

## Just implemented — SPOT-07

Private Fake Gordon wink, tongue and subtly green tint within
`max(0, canonical derived wisMod / 2) * Maze.CellSize`: fractional halves retained,
inclusive 3D origin distance plus clear eye-to-body sight. Living deployed Heroes
only; zero/negative WIS, cover, cloaking and non-Hero roles receive no tell. A
teammate's Wisdom never reveals the fake for everyone. Existing Omniscience and
boss-bar/HP inference are unchanged; this is not an anti-cheat guarantee.

A separately seeded eye is selected per 2.4-second cosmetic cycle (.35-second
wink). Body modulation composes with class/status tint and restores on errors.
Actual admitted ordinary hit-stun supplies at most .35-second sideways recoil,
clamped to remaining shared stun; rejected duplicate admission never refreshes
it. Cleanup restores ordinary taunt pose or clears old archetype bone changes.
The optional fart is deliberately omitted. Full/reduced art retains every tell;
no new native actor, client model, per-actor hook or full-world render scan.

Server exact run/campaign/level/seed/graph, Warden/clone-state membership/native
owner and observer Hero/profile/shared life bind private receipts. Existing .2s
service, maximum four records per observer, fixed .4s lease; no client request
supplies eligibility. Generic root/clone/observer visual-life tokens, actual
client role/life/phase/cloak/distance/LOS, fixed expiry and stale-owner rejection
prevent lingering presentation. No permanent discovered-fake cache. Removed
unconditional fake name/ordinal labels; server-only clone membership remains.

Preflight: **130 focused production assertions, 50/50 selected suites, 734 Lua
syntax checks**, unchanged source. Final frozen local/independent tree evidence
and publication identity belong in the delivery receipt. Manual and renderings
match. This is not full campaign-matrix/native acceptance. B29 uses --runtime,
not its additional twenty-seed exposure sweep. SPOT_07_ATTEMPTS.txt preserves
partial failures, RNG correlation repair, fixture corrections and their hashes.

Preserve SPOT-06: first effective visible hit opens one nonrenewable 1.2-second
follow-up, bounded by reveal+4 seconds; no hidden/arriving ordinary stun pin,
no cloak damage immunity, no replayed shots; released ordnance keeps its fuse.
Three-second physical routing, .45s departure/fixed destination warnings with
displacement rewarning, .65s ordinary warning and four orbs remain. Taunts last
.8s with six-second shared cooldown and ordinary attack appearances between.
Shared Held/Muted/Push, later phases, clone count/HP, sixteen hazards, resupply,
native death ordering, Gordon -> Hector -> Jail Key -> rescue and rewards remain.

## Next single checkpoint — SPOT-08

Implement only the author's turret bullet: add a turret in a random corner of
Gordon's arena every five dungeon levels. Before code, reconcile exact cumulative
count/scaling, finite corner occupancy/placement, safe entry and gallery routes,
existing hostile/hazard ceilings, targeting/attack authority, warnings, cleanup
and co-op lifecycle in the live GDD under the delegated design authority. Preserve
all existing boss/progression and arrival-safety authorities. Define a finite
production gate; update canonical guidance; validate and non-force publish one
checkpoint. Do not begin Damsel's Revenge (SPOT-09) or approval-gated existing-feat
rebalances. No dedicated Razor retest is a prerequisite.

## Preserved SPOT-04 and SPOT-03 evidence

SPOT-04 source remains at historical 789d63c843206061b416f0d108e7414e6aba0763.
Client LoopAudio rejects corpse/dormant/retired/stale-build owners, reversibly
suspends living PVS owners, and cannot restart true removals/shutdown/old modules.
Native loop ownership, gas2/watcher2/fuse4 limits, volume/pitch and projectile-owned
Fuse remain. Beam warning/sweep retires only its exact owned attack across death,
removal, cancellation, timeout, reset and cleanup, outside the lethal native stack.
SND_STOP passes existing filters; living cues and death one-shots remain. Razor/
Redliner charge warning uses NPC_Manhack.ChargeAnnounce; the missing engine-start
path is removed from footsteps. Actual mounted assets/audibility remain unverified.

SPOT-04 historical broader evidence is 227 passing suites, one unchanged-parent
Color-fixture failure and two campaign-wide suites not run, not a full 230 pass.
SPOT-05 freshly reruns 74 audio, 55 Razor and 44 Climber checks. SPOT-01's separate
50-check result is inherited. Fully restart GMod for SPOT-04 lifetime fields;
never validate a mixed hot load. Audio native evidence requires a listening report
or clip plus console_latest.txt and rpg_summary_latest.txt.

Shael's third controlled Razor spawn succeeded after two legal-placement refusals;
that one actor was visible, attacked, dealt/took damage and was defeatable. No
natural Razor was noticed before the test, including past Red Gate. Reported
population: Occupation, 60 roamers, zero planned/roaming Razor, developerMode=true,
developerDense=true, all34 installed/mounted source hashes matching. This is not
release exposure/pacing evidence; no RPG validator result was recorded and blade=0
row timing remains unresolved. These uploads were summarized in the author handoff,
not independently re-read in SPOT-04 or SPOT-05. Preserve that provenance.

Move on: no dedicated Razor retest or natural sighting is prerequisite. Observe
natural appearances during ordinary play; optional `lod_razor_status;
lod_population_evidence`. Separate developer-dense from release sessions. Full
absence resolution, stairs/blades/Held/safety/co-op remain unverified. Do not
force spawns or retune density to manufacture exposure.

## Release and roadmap constraints

Preserve SPOT01–07, B28 physical queries, B29 sanctuary/graduated pressure,
population limits/Bestiary variety, accepted Crate appearance and P1–P4. No Workshop
publication, VPS deployment or VPS restart. Local acceptance → Workshop item
3791535712 package/source parity → matching VPS remains the release sequence.
No Workshop/VPS action happened in SPOT-05, SPOT-06 or SPOT-07. All earlier native gates remain open.

After the spot queue: Low-End PC Optimization, September 28–October 4, 2026 →
Big Loot → Event System → comprehensive systems audit. Before context pressure,
finish/preserve the checkpoint, verify its remote result, and supply a current
handoff instructing Shael to start a new conversation. No background development.
