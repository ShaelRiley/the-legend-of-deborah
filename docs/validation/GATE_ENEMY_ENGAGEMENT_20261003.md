# Gate-reveal enemy engagement repair

## Scope and authority

Source parent: `2f4c968518ff29cb9ef206b3f9906d797b017ee1` on canonical `main`.
Author request: nearby/newly revealed enemies should enter their actual combat
routines instead of running into future positions, especially after opening a
gate; repair related demonstrated defects. Source commit/push is authorized;
Workshop publication and VPS deployment are separate and untouched.

Read current live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY` through
00 → 01 → 03/05/06/07, plus exact HUMAN Soldier/Sniper rows. B29 spatial sanctuary,
combined opening quotas, authored home/wandering leashes, perception, ordinary
telegraphs and new modular boss ownership remain constraints. No tuning values,
attack damage/cadence, population, reward or GDD rules are changed.

## Reproduced defect and repair

On the actual generated first-gate graph, a Shambler two edges from the Hero but
eight from home reserved the only opening contact. Its normal six-edge home
leash then rejected the Hero. An attack-ready Shambler beside the Hero was told
to withdraw. The old test only counted admitted AI ticks and never exercised
native acquisition or damage.

New local reservations now reuse the scheduled native target decision, then
validate that candidate through the native read-only eligibility seam. Both
Hero/home and body/home constraints apply before NEW directed reservation;
wanderers retain their own floor and acquire/retention policy. Cached dead,
inactive, invisible or displaced candidates cannot take a slot. Selection is
not rerolled: Reckless still uses one scheduled decision. Existing reservations,
primary warnings and intentional finite/infinite target holds are retained.

Stationary actors must have a present legal threat before reserving a NEW
opening contact: existing range/LOS/fixed Sentry cone, Nodule cell and stationary
ring cell, or the existing close-defense opportunity. Ordinary Cordon approach
warnings and Beam Sweeper ready-time reorientation remain unchanged. Mobile
actors may still acquire through cover and follow legal graph paths.

A changed ordinary target invalidates stale non-stair patrol/return/old-target
waypoints; a committed stair connector remains intact. Suppression retires
Soldier warning beams and Sniper pending shots through their existing owners.
The release observer no longer treats an admission hint alone as an acquired
target.

Watcher’s actual instance router previously bypassed the universal close-defense
dispatch tested by the generic hostile loop. It now shares that defense before
special retreat; active Watcher scans and Seeker primary states retain ownership.
The common motion kernel holds an actor still during its advertised close strike,
including independent retreat services; forced displacement remains distinct.

## Finite automated gate

`tools/test_gate_enemy_engagement.lua` exercises actual generated geometry/gates,
native target/route methods, native coroutine, Motion V2 and the final Soldier
burst authority. Native entities, traces, vector transforms and HP writes are
controlled engine boundaries. It covers gate/home-leash ghosts, multiple nearby
actors and Heroes, actual melee impact, full ranged warnings and frozen burst,
closed gates/cover, target changes/stairs, cloak/life validity, stale polling,
Reckless cadence, negative retry budget, stationary threats, cancellation,
readmission and exact-state/freeze ownership. Restoring the parent EntrySafety
file reproduces the failed gate assertion; that negative evidence is retained
outside the source checkout.

`tools/test_enemy_close_defense.lua` additionally drives the actual Watcher
instance router through shared damage settlement, retained scan, recovery,
stationary warning and sanctuary denial. Existing Watcher scan/hook-order,
B29, wandering, roster, boss, lifecycle and all other registered regressions stay
in the required full matrix.

Required final commands:

- `python3 tools/test_checkpoint_g_integration.py --workers 4 --output <new external evidence directory>`
- `python3 tools/test_music_gate.py --output <new external evidence directory>`
- `python3 tools/test_vr_gate.py`

The publication reply identifies the exact immutable source digest, complete
matrix receipt and verified remote SHA/CI. Focused results are not substituted
for that frozen final gate.

## Native acceptance still required

Fully quit/update/install the published source and play normally on gm_flatgrass.
Open the next gate and approach the revealed group. Eligible enemies should
begin their own readable attacks promptly; deliberately unadmitted opening
pressure may still withdraw. Check a nearby Soldier's full warning and a cornered
Watcher’s close retaliation without interrupting an already-started scan. Return
to sanctuary to confirm reciprocal safety. No native GMod/Source, visual, physics,
co-op or Steam Deck acceptance is claimed by these headless checks.

If the symptom remains, preserve `console_latest.txt` and
`population_latest.txt` from that session, plus which gate/enemy was visible;
include `rpg_summary_latest.txt` when developer logging was enabled. Earlier
boss, feat, music and hit-stun native acceptance debts remain open.
