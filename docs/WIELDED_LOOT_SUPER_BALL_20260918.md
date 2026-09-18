# Wielded colors, starter-family loot and Super Ball — 2026-09-18

Continuation from `d7fe92a` on `main`, implementing the author's explicit
held-color correction, ordinary procedural pistol/crowbar drops and new Form.
Live GDD 00 → 01 → 03/07 were reviewed. The explicit current request extends
the catalog; existing Cone, Watermelon and newer balance remain authoritative.

## Held rendering repair

The user reports that pickup colors do not carry into wielded presentation.
The previous renderer incorrectly treated `render.EnableClipping`'s prior
boolean as evidence of an occupied custom clip stack, skipping all three color
passes when enabled. It now draws with either prior state and restores that
state afterward. Zero/default render flags and nested stock-model paths are
also accepted. One protected region and the two existing stat-derived tint
regions remain, with source textures, aura and muzzle behavior intact.

The manual viewmodel draw suppresses GMod's automatic PostDrawViewModel pass.
It now explicitly completes that pass exactly once so native hands and effect
restoration survive. Magic/cinematic concealment is checked before drawing,
independent of hook ordering. The SMG's former global heat recolor no longer
interferes with procedural regions; heat mechanics and HUD remain unchanged.
First-person and remote-held entry points, clipping already enabled, copy
switches, protected hands, material restoration and suppressing Magic casts
are exercised by the renderer harness. Native visual acceptance is pending;
this fixes demonstrated code-path defects, not a claim of observed native output.

References: [clipping state contract](https://wiki.facepunch.com/gmod/render.EnableClipping),
[viewmodel suppression contract](https://wiki.facepunch.com/gmod/GM:PreDrawViewModel),
[base GMod hand completion](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/cl_init.lua).

## Ordinary weapon loot

Pistol and crowbar join Shotgun/SMG from Dungeon 1. Magnum/AR2 retain Dungeon
2/3 admission. Both missing-family selection and duplicate selection use that
same eligible pool. Merely expanding the pool was insufficient: starter
ownership would still suppress these two families while other guns were
missing. Half the rolls now select a random eligible variant; the other half
retain the missing-family preference, falling back to the eligible pool.
The central tuning is `Equipment.WeaponLoot.variantChance = .5`.

Across 2,400 Dungeon-1 seeds with starter pistol/crowbar owned, weapon-family
selections included 322 pistols and 325 crowbars. Across 2,400 Dungeon-3 seeds
with every family owned, the counts were 400 and 399. Tests also exercise the
real ordinary reward converter, procedural properties, collection, equipping
and appearance stamping. Existing conversion into wearables remains intact;
these counts describe weapon-family selection, not all enemy kills. Existing
owned items are never rerolled and pickup does not force an equipment swap.

## Super Ball

A ninth learnable/selectable Form uses GMod's actual `sprites/sent_ball` visual
and `garrysmod/balloon_pop_cute.wav` bounce sound. Its server entity shares the
existing magic projectile lifecycle; it does not spawn the edible sandbox toy.
Source: [Facepunch's bouncing ball](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/entities/sent_ball.lua).

Initial tuning: 32 base Magic; 2d6 per eligible contact; speed 900; gravity 260;
radius 8; six-second lifetime; at most 32 collisions and six enemy-hit attempts;
.3-second same-target contact lockout; two active per caster, 32 globally. A
seeded perturbation after reflection produces chaotic but outward-facing
ricochets. Geometry can return it to a previous target or send it into another.

Each tick uses at most four swept solid-mask hull traces. Unused corner travel
is discarded rather than moving through geometry. Embedded/sky hits retire it.
A separate shared line-of-effect check rejects floor/wall-obstructed targets;
open shafts remain valid. Damage, Wisdom, gear, statuses, attribution, cast
cost/recovery and logs use existing authorities and the shared cast context.
The 128-die work budget remains shared across the entire ball. Content riders
are attempted once per damaged target per cast, while later contacts can still
deal damage. Lifetime/range are fixed; Wisdom affects damage, not persistence.

Removal clears the per-caster capacity readout; cleanup covers expiry, hit and
bounce caps, caster death/disconnect, staged/failed/frozen/cleared state, changed
level seed, map cleanup and shutdown. No native physics callbacks, timers,
particle systems, dynamic lights or additional dependencies are introduced.
The Spellbook uses two rows for all nine Forms, with the ball capacity state
visible, and the canonical manual plus generated copies are updated.

## Validation and finite runtime gate

`python3 tools/test_checkpoint_g_integration.py`: all **111 suites pass**.
Includes production held-render entry points, 4,800 deterministic loot samples,
real acquisition/equipping, analytic corridor/body ricochet simulation, repeat
and multiple-target contacts, Content deduplication, affordability/cap rejection,
solid-floor/open-shaft checks and owner/level/entity cleanup. Existing crash
replay and all-LuaJIT generator safety tests still pass. `git diff --check` passes.

Next native action: play one fresh maze with two players, equip rolled pistol
and crowbar copies and switch/fire/reload/swing while the teammate observes;
cast Super Ball between enemies in a corridor, then reset with a ball in flight.
Confirm held tints/hands, repeated/multiple hits, bounce feel and cleanup. The
world/viewmodel rendering and ball feel still require GMod/Steam Deck observation.
No server deployment or Workshop publication is part of this checkpoint.
