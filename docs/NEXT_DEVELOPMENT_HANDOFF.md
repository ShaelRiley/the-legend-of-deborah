# Resume The Legend of Deborah — SPOT-02 Climbers

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
SPOT-01's parent is B29 `20f6ecc82a6bf132b7c4d7f9d145b50aff0d945d`.
Resolve/fetch the current remote main before edits; the delivery receipt supplies
the verified SPOT-01 commit. Preserve newer and uncommitted work.

## Orientation

Read AGENTS.md, the current DEVELOPMENT_PLAN.md, briefs/SPOT_UPDATES.md and
validation/SPOT_01_PLAYER_IDENTITY.md. GDD ID:
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
Follow live 00 → 01 → only the relevant subsystem. Current queue authority is
`LOD-SPOT`; SPOT-01 rules/tuning are in 06/07.

## Banked checkpoint

SPOT-01 implements only the player target readout: stock nickname/health-percent
suppression; `Username as Character Name` plus `current/max HP`; shared semantic
colors; green/full, yellow/>50%, orange/>25%, red/≤25% HP suffix; UTF-8-safe
single-line truncation; visible human Soldiers use the active Soldier role.
The existing HUD owner is reused with no new network messages or entity scans.

Fresh tests: 50/50 standalone production-callback checks, production/test Lua
syntax. Baseline: 8 passed/42 failed. Full repository integration and native
GMod rendering, trace behavior and health replication were not run here. Check
non-100 maximum HP, long names, both roles, walls, menus and concealment locally.
The player-facing guide is docs/PLAYER_TARGET_READOUT.md; the bundled generated
in-game manual was not regenerated in this connector-only checkpoint.

## One next action

Complete **SPOT-02: diagnose and repair absent Climbers** as its own pushable
checkpoint. The author has never seen one. Inspect the current release pipeline
through eligibility, weighted selection, admission/caps, legal placement,
movement and actual presentation. Start with sv_climber.lua and its actual call
sites in encounter/roaming authorities, using current B28/B29 release diagnostics.
Use a focused regression that reproduces the demonstrated failure; distinguish
successful debug spawning, release admission and native sightings. Preserve
sanctuary, graduated pressure, population variety, caps and accepted art.
SPOT-03 Manhack types is the following separate bullet, not part of this commit.

## Remaining queue and constraints

All sixteen remaining bullet requirements are preserved in briefs/SPOT_UPDATES.md.
The existing-feat audit must produce proposals for Shael's approval before balance
changes. The separately requested four-choice draft and Time Management feat are
authorized. Design details not yet resolved stay explicit until their checkpoint.

Preserve local acceptance → Workshop publication/parity → matching VPS. B29 native
acceptance is pending. Preserve P1–P4 and the unchanged deferred September 28–
October 4 Low-End PC Optimization → Big Loot → Event System → comprehensive audit.
The previous B29 handoff is retained verbatim at
history/NEXT_DEVELOPMENT_HANDOFF_B29_20f6ecc.md.

At actual context pressure, close and push the current coherent slice, report the
verified remote SHA and native limits, and provide a self-contained handoff asking
Shael to start a new conversation. Do not start a second unbanked feature first.
