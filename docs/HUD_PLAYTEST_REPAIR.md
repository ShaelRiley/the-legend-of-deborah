# Transparent gameplay HUD and complete damage-roll readouts

Starting branch: `hybrid/antigravity` at `2f11f0eae6508d791f274adc9293f704fa3e617c`.

Shael's runtime feedback supersedes the prior paper treatment for live gameplay.
Player Sheet, Spellbook and retained DIE-LOGGER keep their accepted paper styling.
The live feed, objective, run/life/keycard readouts, Magic, announcements and
feedback notices use transparent text with a fine shadow. Magic uses stock
`HudNumbers` in the existing health-adjacent suit slot. The HUD feed occupies at
most six text rows; oversized entries explicitly point to their complete retained
record with L. Menus and HUD retain the same semantic roles with contrast adapted
to their backgrounds. Font-aware wrapping prevents menu/HUD cache contamination.

## Dice-reporting repairs

- Shared arithmetic now shows every recorded die, independent chain starts,
  continuation thresholds, contribution adjustments, bonuses and rolled subtotal.
  The damage total remains in parentheses, separate from that subtotal. Available
  per-die CON reductions and resolved damage are included without rerunning RNG.
- Exploded firearm misses previously emitted a cue without a record. Deferred
  settlement now emits exactly one zero-damage record with the complete roll.
- Fully reduced Magic damage previously returned before emitting its roll. It now
  retains the arithmetic and continuation cue even when applied damage is zero.
- Magnum piercing now carries values, independent starts, thresholds and work-cap
  metadata into the next body's contract. Earlier dice and fresh bonus chains stay
  distinguishable in its actual production damage message.
- Hostile cached attack contracts retain thresholds. Hero of Legend uses the shared
  roll formatter. Deferred shotgun summaries preserve each target's own resistance
  snapshot and report hits even after the target entity has been removed.
- Nickname-only observer events receive the identity role; longer known identities
  take precedence over nested shorter names. HUD colors are luminous blue/red for
  Steam/character identity, violet for dice, and amber for continuation/results.

Example: `1d10! (27) [rolls 10@10+ > 10@10+ > 7@10+ = 27 rolled]`.
`>` means continuation, `+` separates independent dice, `@N+` is the actual
threshold, and `=>` shows an adjusted contribution. Reduced damage can differ
from the rolled subtotal; neither is substituted for the other.

## Bomb presentation

BOMB replicates its Form identity and renders a black round body, neck, bent fuse,
ember and three small sparks. It does not draw the old grenade-shaped model or
create a laser trail/dynamic light. This uses native render primitives and existing
materials; no asset downloads are required. Its server launch, gravity, trace hull,
range, impact timing, damage and cost remain unchanged. The fuse is cosmetic and
is not a new timed-detonation mechanic.

## Validation / next finite gate

The existing focused feedback and AG-011 suites exercise the production exploded
miss, zero-damage Magic and Magnum piercing paths, per-target shotgun reporting,
wire/history semantic parity, HUD draw calls at 1280x800 / 1920x1080 / 1024x768,
and the bomb's actual shared/server/client entry points. They prove no paper/panel
draw calls on the gameplay HUD and no bomb trail/light allocation. Final gate: **27/27 Checkpoint-G suites PASS**, including all **363 Lua files**
passing syntax and the whitespace check.

No Source-runtime appearance or audio acceptance is claimed. Fully restart GMod,
start `gm_flatgrass`, inspect unobstructed objectives/Magic while fighting, compare
an exploded roll in the live feed and L history, and throw BOMB. Return the usual
`console_latest.txt` and `rpg_summary_latest.txt`; add a screenshot of any residual
layout or dice-detail defect and session detail if timing is implicated.

Live GDD consulted: 00, 01, 03, 06; document
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`. The current user instruction
controls the HUD/menu visual distinction. Other milestone requirements are not
silently claimed complete. No main promotion or public deployment is included.
