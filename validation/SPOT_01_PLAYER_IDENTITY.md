# SPOT-01 — player target identity

## Scope and baseline

Only the first author-requested spot bullet is implemented. Baseline main:
`20f6ecc82a6bf132b7c4d7f9d145b50aff0d945d` (B29).
Original cl_teammate_identity.lua blob:
`6633f3ce2f774b2163291862e92403b6c183e0d3`.

The old module draws nickname, HP and character on three separate rows; it does
not suppress the base target-ID callback. The replacement suppresses that
callback and draws exactly two physical rows using separate semantic spans.
All other production source remains inherited from B29.

## Fresh finite validation

Run from the repository root:

```sh
texluac -p gamemodes/legend_of_deborah/gamemode/lod/cl_teammate_identity.lua
texluac -p tools/tests/player_target_identity.lua
texlua tools/tests/player_target_identity.lua
```

Production and test syntax pass. **50 cases passed, zero failed**; actual output
is SPOT_01_PLAYER_IDENTITY.log. Against the exact original module, the same
suite reports **8 passed, 42 failed**. The baseline comparison demonstrates the
old/new draw-contract difference, not 42 independent historical engine bugs.

The suite executes the production hooks under explicit Lua/GMod stubs. It checks
stock suppression, exact text/two-row geometry, independent centering, shared
roles, HP thresholds and changing non-100 maxima, unknown/overfilled HP, safe
UTF-8 truncation at five widths, layout cache invalidation, active Soldier naming,
invalid/dead/self/nonplayer/dormant/no-draw/Veil targets, menus and hook reload.

This is a partial source workspace. A full Git clone was unavailable through the
container network. The canonical integration matrix was **not run**; prior B29
42-check evidence is inherited, not freshly rerun. Native font metrics, actual
engine eye traces and multiplayer health/max-health replication are not tested
by the stubs. No native acceptance, Workshop publication or VPS deployment claim.

## Native acceptance still required

On the matching local build, look at another Hero and a human Soldier. Confirm no
stock label or health percentage remains and exactly two lines appear. Exercise
full, above-half, half, above-quarter and quarter-or-less HP, including a maximum
other than 100; compare to that player's actual character state. Check long and
Unicode names, menus, walls, death, role changes and Veil concealment. Preserve
NPC information/Omniscience presentation. B29 safe-opening acceptance stays open.

## Documentation and publication

Live GDD 00/01 route the ordered queue; 06/07 contain SPOT-01 rules/tuning, verified
by targeted readback. Player guidance: docs/PLAYER_TARGET_READOUT.md. The bundled
generated in-game manual is unchanged, explicitly pending regeneration. Prior
plan/handoff bytes are retained in docs/history while current entrypoints route
the new queue. No queue entry implies implementation of another bullet.

Publish only this coherent change with a non-forced main update, comparing the
remote tree's changed blobs with the tested local bytes. Next: SPOT-02 Climbers.
