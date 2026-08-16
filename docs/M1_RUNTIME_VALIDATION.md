# Milestone 1 — Garry's Mod runtime validation

This is the target-runtime acceptance pass for the Labyrinth foundation. The production GDD remains authoritative.

## Install the live development checkout

From the repository root on Steam Deck/Desktop Linux:

```bash
./tools/install_dev.sh
```

The script locates the normal Steam Garry's Mod installation and symlinks the repository into `garrysmod/addons/the-legend-of-deborah-dev`. Because the repository itself contains `gamemodes/legend_of_deborah`, edits become visible to the development install without maintaining a second source copy.

If Garry's Mod lives somewhere nonstandard:

```bash
GMOD_GARRYSMOD_DIR="/path/to/GarrysMod/garrysmod" ./tools/install_dev.sh
```

## Start the target environment

Use `gm_flatgrass` and gamemode `legend_of_deborah`. During development, enabling the developer console and `-condebug` is recommended so the complete startup/audit output is preserved in `garrysmod/console.txt`.

The gamemode should build and validate the current level automatically. Do not treat a partially generated maze as playable; startup/build failure is a test failure.

## First command

Run:

```text
lod_m1_audit
```

The command performs server-side checks for:

- required mounted model validity;
- deterministic graph validation data;
- generation, geometry-build, and total build time;
- generated entity composition;
- start-position player-hull clearance;
- ordinary cell-center player-hull clearance;
- unobstructed centerline traversal across non-transition open graph edges;
- teammate no-collide state;
- vertical layer/wall-top separation and stair step-rise invariants.

It prints a concise report and writes the full JSON record to `garrysmod/data/legend_of_deborah/`.

A single audit uses the GDD's <=10-second worst-case generation target as a hard timing gate and reports the <=5-second typical target separately. The typical target must ultimately be judged across representative seeds, not one lucky build.

## Visual graph inspection

Run:

```text
lod_debug_graph
lod_validation
```

The graph overlay should correspond to the physical maze. Vertical graph edges appear distinctly from horizontal edges.

## Regeneration sample

Run several fresh builds:

```text
lod_regenerate
lod_m1_audit
```

`lod_regenerate` intentionally marks the development campaign unranked. That is correct release-integrity behavior.

## Manual traversal acceptance

For representative two-, three-, and rare four-layer layouts:

- traverse every mandatory staircase in both directions;
- sprint, crouch, and jump through ordinary corridors;
- verify no abstractly open connection is physically blocked;
- verify stair apertures do not snag the standing or crouched player hull;
- attempt to reach container/wall tops by ordinary movement;
- attempt to leave the graph by jumping, dropping, or exploiting upper-floor edges;
- verify elevated walkways do not permit accidental arbitrary drops;
- verify the outside of the maze cannot be used as a progression shortcut;
- regenerate while a player is present and confirm the player is safely held/released;
- with 2–4 players, confirm teammates do not body-block one another and spawn without overlap failure;
- with a fifth connection, confirm the extra user cannot free-roam scout.

Any reproducible wall-top, outside-maze, arbitrary-drop, or blocked-open-edge bypass is Milestone-1-blocking.

## Performance evidence

For each representative seed, record the `lod_m1_audit` JSON and startup console output. Milestone 1 should not be closed until actual Garry's Mod measurements establish that generation is normally <=5 seconds and remains <=10 seconds in worst-case supported tests, or the builder has been optimized further.
