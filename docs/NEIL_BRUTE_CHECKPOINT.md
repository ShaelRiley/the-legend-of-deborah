## 2026-09-16 attack regression repair — main

The production Tick regression reproduced an attack veto tied to the defense
route. This was absent from earlier tests, which called BeginCharge directly.
Defense orders now govern destination only; hits on Neil cannot erase the
Brute's committed warning, and Neil death clears stale defense routing. The
regression follows Tick through windup, one contact hit, recovery cooldown and
surviving-Brute attack initiation. Existing interruption, wall, stair and gate
constraints remain covered. Build: `brute-attacks-20260916-01`.

# Neil and the Brute

Repository: `ShaelRiley/the-legend-of-deborah`; branch: `astra/equipment-update`.
Starting remote HEAD: `e7576355967084b9fca246022ce9a4b3a7da6148`.
Ending HEAD: the commit containing this document, verified at publication.

Authority: live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 entrypoint → 01 rule index → 05 core loop → exact HUMAN Neil/Brute rows.
The author's follow-up expressly authorizes the missing tuning; chosen values
are recorded in 07 Implementation & Tuning. Canonical spelling is Neil.

## Implemented

- Yellow Gate activates exactly one seeded first-floor Neil and one Brute.
  Both use the existing fixed locomotion hull, client-only visual scaling,
  RPG actor progression, party HP scaling, loot and death handoff.
- Green G-Man Neil carries a visible suitcase and avoids the party across
  opened graph cells and validated stairs. He never fires or heals.
- The Antlion Guard Brute trails 1–2 graph cells behind. Effective damage to
  Neil sends the Brute to the struck cell while Neil replans his escape.
- The Brute freezes its charge direction during a visible orange warning.
  The charge has finite travel, sweeps for obstacles and Hero contacts,
  cannot start on stairs, and stops at walls/closed graph edges. Wall impact
  exposes it for two seconds without destroying geometry or adding a damage
  multiplier. Death, hit stun, immobility and frozen sessions cancel charges.
- Neil's death queues one physical, team-global Black Keycard at the captured
  death position. Brute death is optional. Collection validates the actor,
  distance, stage, entity identity and dungeon seed. Duplicate and stale
  callbacks cannot grant another card.
- Black Gate is a validated fourth bridge before Core/Jail, establishes
  checkpoint 4, and releases the permitted temporary Core Jail Key. Minimap
  topology, breadcrumbs, network state, gate labels, audio and booklet follow
  the new route. Gordon and his arena are a separate unfinished checkpoint.

## Reference tuning

| Parameter | Neil | Brute |
|---|---:|---:|
| Canonical reference HP | 150 | 250 |
| Canonical tier | Typical, dungeon level | Elite, dungeon level + 1 |
| Ordinary movement | 220 units/s | 140 units/s |
| Physical charge roll | None | 4d6+6, reference 20 |
| Warning / charge time | — | 1.25 s / 1.2 s |
| Charge speed / acquisition range | — | 560 units/s / 1–760 units |
| Cooldown / wall stun | — | 3 s / 2 s |

Existing seeded variance applies to HP, damage, ordinary speed, warning,
cooldown and acquisition range. Charge speed follows the instance speed scale.
Shared combat remains authoritative for Strength, Constitution, Dodge, Block,
elements and other legitimate actor effects. Charge damage settles once per
struck Hero; it does not bypass defenses by using a second damage system.

No extra render models, particles or lights are allocated for hunt feedback.
Two hostile slots are reserved within the existing ceiling in addition to the
wanderer deficit. AI uses existing target/route refresh intervals; objective
position sends are capped at 2 Hz. Graph searches do not run every render/tick
while the escort is stationary in its valid band.

## Validation and limits

All **86 automated suites pass**. The new suite executes production planning
on ten generated seeds twice each, checks all-floor hunt reachability and the
Black bridge, pair/reservation/partial-spawn handling, defense response,
canonical stair waypoint compilation, cached escort holds, death-only card
release, stale/duplicate requests, checkpoint transitions, charge windup,
fixed direction, single contact, wall/gate collision and hit-stun cancellation.
It also transfers real server minimap packets through both client decoders.
Existing native-resource/death/pickup repairs remain included.

These are headless tests with Source boundary doubles. No native GMod client
is available here; model animation, suitcase placement, booklet pagination,
combat feel and 1–4-player runtime behavior still need acceptance. The earlier
fatal crash has **not** been proven resolved. Main, Workshop and public VPS
are not promoted by this checkpoint.

## Finite in-game gate

Close GMod, update this branch, run `./tools/install_dev.sh`, then restart on
`gm_flatgrass`. All clients need the same build because progression/minimap
packets now include the fourth gate.

Play through Yellow naturally, or after class/feat setup and labyrinth entry:

```text
lod_developer_mode 1
lod_neil_brute_testkit
lod_neil_brute_status
```

The admin-only shortcut marks the run unranked and uses ordinary transitions
through Red/Blue/Yellow. It does not grant Black/Jail, respawn the pair, or
bypass hostile reserves. Follow the map objective to Neil.

1. Chase Neil through a staircase; hit him and verify the Brute responds.
2. Bait a charge into a wall, then hit-stun another warning. Check that neither
   can resume later as a stale charge or move through geometry.
3. Kill Neil while the Brute lives; collect exactly one Black Keycard. Repeat
   next dungeon with the Brute killed first.
4. Open Black, verify checkpoint respawn/reconnect, collect the Core Jail Key,
   unlock/rescue Deborah, and confirm the next dungeon has a fresh pair.
5. Repeat with two clients, including one disconnect while a charge is warned.

If GMod force-closes, preserve `console_latest.txt`, `rpg_test_session.txt`,
the installer receipt and any native crash dump before relaunch. Retain
`NEIL_HUNT_START`, `NEIL_DEFENSE_TRIGGER`, `BRUTE_PHASE` and
`NEIL_BLACK_CARD_DROP` events alongside the existing loot/native-stage markers.
