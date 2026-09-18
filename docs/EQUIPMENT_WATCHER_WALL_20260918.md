# Equipment toggle, Watcher scan dispatch and Wizard Wall

Author-directed continuation from `c6bd155e53027f184afda3a572505a2f13c0957f`
(on `main`; the base SHA is recorded by Git). Implemented/static evidence is
separate from native GMod acceptance. No server deployment is part of this change.

## Changes

- Equipment has a named sibling tab and a shared O-key/console toggle. Focused
  popup input now reaches that toggle; one debounce prevents closing/reopening
  from a duplicated press. Rebinding changes the tab caption, world binding and
  menu binding. Text editing/key binding does not trigger page navigation.
- Watcher dispatch no longer mistakes a mutable stored SENT `_BehaviourTick` for
  the Watcher controller merely because an installation flag remains set.
  Dependency installation is ordered; instances bind the actual scan/handoff
  functions. Generic late entity hooks cannot divert a Watcher into pursuit.
  Scan holding uses the scan resolver's exact LOS. A cornered Watcher with no
  escape segment can scan at close range instead of waiting indefinitely.
  Existing 1.25-second scan, alert, interrupt and retreat authorities remain.
- Wall is a first-class **Wizard-only** Form. Ownership grants, selection,
  reconnect/class migration, feat eligibility and final casting agree about
  class restrictions. Non-Wizard ownership is replaced through the existing
  deterministic migration pattern. Wall appears in the Spellbook and manual.
- `lod_magic_test_all` grants the invoking admin every class-legal Form and all
  six Contents, refills Magic to 100, resets cast cooldown, syncs presentation,
  and marks the campaign unranked. Requires `lod_developer_mode 1`. A Wizard
  receives all ten Forms; other classes receive eight (no Summon or Wall).

## Wall tuning and geometry

35 base Magic, 2d6 contact damage using normal WIS/equipment/element resolution;
10-second lifetime. At most one damage attempt per target per second; a Content
rider is attempted only once per damaged target per cast. The ordinary 128-die
cast work cap remains authoritative. Surviving damaged enemies receive the
canonical hit-stun response with a 2.5 Form multiplier: 0.75 seconds at the
normal 0.30-second baseline, also respecting existing ability scaling and
retrigger protection. Ordinary hit/shotgun stun tuning is unchanged.

Maximum width is `192 + 96 × SpatialBonusCells`, capped at 1,152 units.
SpatialBonusCells is the existing minimum-one WIS bonus with Astral Reach.
Aimed placement reaches 240 units; height 112, thickness 12, minimum width 48.
Axis-aligned faces fit the container maze and match native box collision exactly.
Full-height sweeps trim both ends to nearby crates/obstacles; support and volume
checks reject solid embedding, ceilings and unsupported ends. Heroes may occupy
and walk through the plane. Enemy occupancy still constrains placement, and
human Soldier opponents collide. Collision changes follow role replication on
both realms, per the [Source collision hook contract](https://wiki.facepunch.com/gmod/GM:ShouldCollide).

The graph-driven Motion V2 mover also sweeps its hull against active Walls;
ordinary SetPos locomotion cannot bypass the barrier or tunnel through at high
speed. Specialized charge/climb/push paths already use solid hull traces.

Contact is checked within 24 units of the bounds at 10 Hz, with actual solid
line-of-effect from the appropriate face; no magical damage through a solid
floor. There is one finite entity per Wall, no physics simulation, periodic
network broadcast, clientside damage, particle owner or auxiliary timer. Global
cap 16. Expiration, death, disconnect, staging, level seed/run changes,
failure/clear/freeze, map cleanup and shutdown retire the entity and capacity.
Transparent Content-colored planes/bands and an expiry fade show its footprint.

## Evidence

`python3 tools/test_checkpoint_g_integration.py`: **all 113 suites pass**,
including the complete Lua syntax audit and existing protected regressions.
`git diff --check`: clean.

New/expanded production harnesses cover:

- delayed SENT registration followed by a late generic controller overwrite;
  real Watcher scan start, midpoint, completion/escape, LOS and stun cancellation;
- focused equipment popup toggling, same-press debounce and rebind dispatch;
- analytic swept-AABB gap fitting, Wisdom size cap, Hero occupancy, enemy safety;
- real Motion V2 high-speed sweep blocking, with legal around/over/Hero passage;
- Wall shared cost, repeat damage/rider limit, cover/floor rejection, open geometry,
  one-Wall capacity, expiration and lifecycle cleanup;
- actual shared stun factor and unchanged ordinary stun duration;
- production Hero/Soldier collision policy in both argument orders;
- test-command permissions, owner-specific grants/sync, repeated grants and
  Wizard-only ownership/selection/cast enforcement;
- all existing class, loot, equipment, summon, Watermelon and Super Ball suites.

Live GDD navigation: 00 → 01 → 03/05/06/07. The explicit author directions
supersede older six-Form/menu wording. No routine live-GDD edits were made.

## One native test session

Choose a **Wizard** on `gm_flatgrass`. In your player console as listen-host/admin:

`lod_developer_mode 1; lod_magic_test_all`

Press I to select any Form/Content; rerun the command whenever a refill is useful.
For Wall, aim into a gap between crates and cast. Walk through it with a Hero;
observe enemies blocked and repeatedly flinching, Content-colored rendering and
expiration. Check a second Hero sees the same geometry and can also pass. O must
open and close Equipment, including after visiting another menu tab. Encounter
(or use the existing Watcher testkit for) a Watcher and observe scan → flash →
retreat; `lod_watcher_dispatch_status` / `lod_watcher_handoff_status` expose state.
Native visuals, collision prediction and combat feel remain pending, not accepted
by these headless tests. Use `console_latest.txt` + `rpg_summary_latest.txt` if a
runtime defect remains; add a screenshot for placement/presentation defects.
