# Wall placement, aiming preview and offensive starters

Continuation from `3e7a83bba01476ee39932b8b6475dcbaed5ee7ae` on `main`.
The author reports every attempted Wall cast rejected. This checkpoint repairs
reproduced rejection paths and exposes the exact remaining failure category;
native GMod acceptance is still pending.

## Placement correction

The old solver had one candidate, a 160-unit ground probe, one unit of floor
clearance, an inflexible 112-unit height, and two additional endpoint-support
requirements. Its crate clearance followed the aiming vector rather than the
struck surface normal, so grazing aims could leave the volume inside the crate.
It also treated owned weapons/cosmetic children as placement obstacles and
rejected nearly vertical aims outright. The original horizontal/open-floor
harness did not exercise those cases.

The revised authoritative solver:

- uses perpendicular surface clearance, four units of floor clearance and a
  512-unit ground probe, retaining the exposed-ground/reach check;
- fits height beneath low ceilings (48–112 units) and trims width to obstacles;
- tries up to five nearby candidates, retreating by 24 units per attempt;
- ignores the caster's held/cosmetic children and cooperative Heroes;
- handles nearly vertical aim using the character's facing direction;
- anchors to ground at the center without demanding a complete support strip
  below both magical ends, making ledges and partial floor strips usable;
- retains solid-volume rejection, enemy occupancy safety and actual line of
  effect, so fitting cannot move a Wall through solid cover/floors.

Existing Wall cost, damage, Wisdom maximum width, Wizard restriction, 10-second
lifetime, Hero passage, swept hostile movement blocking and cleanup are retained.

## Aiming feedback

While Wall is selected, the server computes the same placement used at cast
commit and sends its bounds only to that caster. A blue outline/translucent
plane means ready; red plus an explicit label means blocked. Reasons distinguish
no ground, space, gap width, ceiling, cover, Magic, cooldown, capacity, status,
throwable priority and staging. Casting still recomputes and validates placement;
clients never submit authoritative positions.

Sampling is capped at once per 0.15 seconds. Unchanged geometry/status is sent
only on a 0.5-second heartbeat. Packets expire clientside after 0.8 seconds;
selection change, death, menu coverage, cleanup and disconnect cannot leave an
orphaned visible preview. Rendering uses bounded geometry, without client props,
particles, dynamic lights or through-wall drawing. A rapid aim change can briefly
lead the server preview by network latency; the blue plane is the last verified
placement, not a promise that a moving enemy cannot invalidate the next cast.

## Starting spell rule

Wall and Summon are catalogued as utility Forms. A Level-1 grant (or an empty
random-Form inventory) excludes utility Forms even if Wizard class is already
selected. Later Wizard grants retain both. Scheduled initialization repairs an
older utility-only starter deterministically by adding/selecting a direct-damage
Form without confiscating acquired utility spells or rerolling on repeat calls.
The administrator all-Forms testkit is unchanged.

## Verification and native check

All **114** suites in `python3 tools/test_checkpoint_g_integration.py` pass,
including syntax and protected regressions. `git diff --check` is clean.

The new placement/preview test covers 84 deterministic pitch/yaw combinations,
grazing crates, tall eye position, lower ceilings, narrow ledges, owned cosmetics,
vertical aim, genuine unsupported/solid/remote rejection, exact preview/cast
bounds, private packet recipients, cadence, heartbeat, clear packets, client
render bounds, local suppression and stale expiry. Existing Wall tests retain
cost, capacity, per-target damage, status rider, floor/cover, stun and lifecycle
coverage. Three thousand preselected Wizards all begin with direct damage;
later grants include Summon 903 times and Wall 1,006 times. Legacy repair is
idempotent and retains utility ownership.

Live-GDD navigation remains 00 → 01 → 03/05/06/07 from the preceding checkpoint;
this explicit author correction supersedes the older starting-Form rule. The
canonical manual was rebuilt. No external assets/dependencies or deployment.

Native session: use a Wizard and
`lod_developer_mode 1; lod_magic_test_all`, select Wall with I, aim at a clear
corridor/gap and cast where the blue plane appears. Check a grazing crate angle,
a ledge and a genuinely blocked location; observe placement, clear reason text,
Hero passage and enemy blocking. If rejection persists, the displayed category
and a screenshot now identify the relevant trace stage. Standard mechanics
artifacts remain `console_latest.txt` + `rpg_summary_latest.txt`.
