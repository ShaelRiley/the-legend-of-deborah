# Enemy variety — combined development checkpoint

Branch: `astra/equipment-update`, based on equipment/perk candidate
`065f067ceab25a0c54dc10b9339876540d820050`.
Canonical main remains `8978796e886cdb5505d24ed0de085265fa99bac8`.
Shael explicitly authorized Enemy work alongside the Equipment playtest. Neither
main promotion nor Workshop/VPS deployment is part of this checkpoint.

## Playable changes

- **Sniper:** blue Combine silhouette carrying a crossbow; seeks the farthest
  reachable firing position inside its range and home leash. Lost LOS/range uses
  the nearest legal recovery position. Closed gates, safe cells and boss cells
  cannot become tactical shortcuts. Committed stair routes finish before replanning.
- **Crossbow:** a fixed blue warning line precedes a finite physical bolt. Moving
  aside dodges the declared line; losing target/LOS, hit-stun, intimidation, fleeing,
  frozen simulation, failed/cleared run or a changed level cancels the pending shot.
  Bullet hit-stun cancels synchronously in the shared feedback authority.
- **Natural variety:** wherever the planner already permits Firing Line, it can
  also choose Soldier + Sniper or Soldier + Blitzer. The existing planner still
  computes composition threat, party/depth enrichment, budgets and activation.
  These are encounter variants; no new wandering weights were invented.
- **Blitzer spawn fix:** the unified encounter spawner previously omitted Blitzer
  from its explicit order, silently losing requested units. Both new firing-line
  variants now materialize with stable instance ordinals and the shared cap.
- Equipment, status saves, physical attack rolls, enemy RPG progression, XP,
  ownership and procedural drops retain their shared production authorities.

## Test together

Load the development build on `gm_flatgrass`, deploy a Hero and enter an open
sector. In developer mode run one line:

```text
lod_equipment_economy_testkit; lod_enemy_update_testkit; lod_enemy_update_status
```

The equipment testkit supplies the existing D100 test gear and comparisons. The
new enemy kit adds one Sniper and one Blitzer in distinct nearby legal cells,
marks the run unranked and keeps the actual dungeon level unchanged. It preserves
the active-hostile reserve and excludes safe/objective/stair/occupied cells. If
there is insufficient room, move into a more open sector and retry only the enemy
command. Normal play also encounters the variants at existing Firing Line sites.

Watch the Sniper take distance, show a blue line, and send a visible bolt down
that line. Step aside, interrupt a later charge with a bullet, and try different
procedural weapons while checking damage/status/drop behavior. Re-run
`lod_enemy_update_status` for active counts, destination, sighting and shot count.
For problems retain `console_latest.txt` and `rpg_summary_latest.txt`; use a
screenshot for visual problems. No in-game evidence has yet been observed here.

## Validation

`python3 tools/test_checkpoint_g_integration.py`: **67/67 pass**.
The new suite executes the production selector, navigator/gate checks, Sniper
state machine, finite bolt movement/expiry, synchronous hit-stun, encounter
cost/spawn/cap and testkit. Existing equipment, perks, combat, statuses, progression
and protected regression suites pass. Source rendering, crossbow attachment,
latency, practical retreat behavior and balance remain runtime checks.

Live GDD authority: tabs 00 → 01 → 02/05/07, then the exact HUMAN Sniper and enemy
anchors. Tab 07 records the explicitly permitted Sniper values: base damage
4d8+7, warning 1.25s, post-shot reload 3s, range 2304; inherited Soldier speed 950
and shared instance variance. Bolt lifetime derives from instance range/speed.

## Remaining Enemy scope

This is the **first variety checkpoint**, not the completed Enemy milestone.
Climber, Flamer, Big Crab, Razor, Arc Caster, Sentry, Lurker and Beam Sweeper still
need their canonical implementations/placement. Neil + Brute, Gordon and the
final hunt remain unfinished; the temporary final-key shortcut is still present.
The 30-minute deadline and TIME OVER cinematic also remain outstanding.

The initial intent included Flamer, Big Crab, Razor and Arc Caster, but their exact
HUMAN descriptions do not authorize choosing the missing attack values. Per
AGENTS.md and LOD-TUNE-001/LOD-IMPL-006, isolate these gaps instead of shipping
invented numbers:

| Archetype | Authored behavior to preserve | Missing required values |
| --- | --- | --- |
| Flamer | Short cone/stream; ignition tell; interruptible; one DEX Immolated save on first HP damage per target per committed attack; constrained wandering eligibility | Damage/dice, range, cone/stream geometry, packet/attack cadence and durations, wander weight |
| Big Crab | Oversized headcrab; same flame attack and range as Flamer; encounter-only; no death children or ground fire | Shared flame values; base health and locomotion/large-size parameters not explicitly fixed |
| Razor | Manhack silhouette; cue and lineup into a committed fast dive; limited steering; encounter-only | Damage/dice, movement/range, warning/recovery/cadence and steering bounds |
| Arc Caster | Vortigaunt area mark then charged eruption; move/LOS/hit-stun counters; arena/objective only | Damage/dice, marked radius/range, charge/recovery/cadence and movement parameters |

These need authored values or explicit implementation-tuning discretion. They
were not silently added to the live GDD. The explicitly specified Climber and
other unblocked Enemy work can proceed while those gaps are resolved.
