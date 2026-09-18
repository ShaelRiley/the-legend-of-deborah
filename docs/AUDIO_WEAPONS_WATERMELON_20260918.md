# Audio, weapon regions and Watermelon — 2026-09-18

Author-directed continuation on `main` from `6aba7b0`. The current source and
live GDD combat/tuning navigation were reviewed; the explicit request adds
Watermelon and replaces the former single-material visual fallback. Preserve
Cone, the integrated refresh and the all-LuaJIT equipment-generator safeguard.

## Implemented

- All LoD client CSoundPatch loops now have one strong owner, finite renewable
  leases, nearest-source group caps and cleanup on removal, level end, staging,
  map cleanup, shutdown and module refresh. Gas: at most two, volume .18;
  Watchers: two, .22; bomb fuses: four, .12. Staging suppression does not alter
  player volume settings. Flamer/BigCrab release used an unowned looping fire
  asset; it now emits the finite stock ignition sound. These are concrete
  stacking paths found in source; native audio acceptance is still outstanding.
- The Hermit's gift uses the existing original discovery musical motif through
  the common priority/volume/cleanup lane. Removed the pitched button sequence.
- Six stock weapon families have explicit control/A/B region definitions.
  Real separate native materials still use their configured submaterials.
  Single-material stock meshes use three complementary clipped draws of the
  same mesh, preserving source texture detail and hand materials. Gun regions
  follow animated muzzle attachments; missing attachments and crowbar use the
  longest model axis. There are no replacement models or decorative textures.
  Element chooses Tint A; mechanical trait family chooses Tint B; frozen roll
  identity varies shades deterministically. Aura and muzzle behavior survive.
- Watermelon is the eighth first-class Form: 24 base Magic, 3d6, .85s shared cast
  recovery, speed 580, maximum travel 960, base radius 144 plus normal WIS radius
  scaling. It is learnable by ordinary Form grants, with normal Content,
  equipment, cost, cooldown, attribution, logging and status integration. The
  stock watermelon model retains its rind, follows the normal lob and uses a
  swept 14-unit hull. One covered AoE resolves per impact; repeated callbacks
  cannot repeat damage. Damage is server-authoritative; 18 rind/flesh/seed
  fragments (8 reduced-effects) are cosmetic and fade within .9s. No debris
  entities, emitters, timers, dynamic lights or external assets are added.
- Updated both forms/equipment manual entries and generated offline/client
  manual copies. Updated schema/grant tests for eight Forms, seven non-Summon
  Forms available outside Wizard.

## Automated acceptance

Run `python3 tools/test_checkpoint_g_integration.py`: all 109 suites pass.
New/extended coverage includes 1,000 loop renewals, nearest caps, lease expiry,
entity loss, staging, game end, reload/GC, all six weapon families in c/v/w
meshes, complementary spatial regions, hand preservation, clip-state and
material cleanup after exceptions, existing external skins, Hermit cue routing,
Watermelon grant/selection/cost/cooldown, cover, impact idempotence, swept hull,
owner/level cleanup, all seven Content signatures and both effect quality modes.
Existing tests retain the equipment-generator compatibility guard and recorded
crash reward replay. No native GMod executable is available in this workspace.

## Finite native acceptance

1. Fresh launch and maze deployment; confirm the preceding generator-crash fix
   still holds. Fight multiple gas/flame/Watcher enemies, throw several bombs,
   then die, clear/reset the level and disconnect. No old hiss/fire loop should
   remain or grow across levels. Check another client independently.
2. Receive the Hermit weapon: hear one matching discovery motif, with normal
   music-volume handling; verify it stops cleanly on cleanup.
3. Inspect all six weapon families in first person, a teammate's hands and on
   pickups. Confirm two colored regions and an unchanged canonical section;
   reload, fire and swing crowbar to check animated placement and hand rendering.
   Check Windows and Linux/Steam Deck clip rendering and frame cost. The fallback
   uses three native draw passes within 1,200 units, maximum two owned clip planes;
   existing external skins or active external clipping retain safe native drawing.
4. Learn/select Watermelon and throw raw and elemental versions near/far, beside
   walls, above solid floors and through open stairs. Observe one splash, readable
   melon fragments, correct Magic spending/statuses and another client's effects.
   Repeat with reduced effects, death, level reset and an in-flight owner disconnect.

Camera composition and other runtime acceptance of the preceding integrated
refresh remain separate; this checkpoint does not claim native visual approval,
server deployment or Workshop publication.

Engine rendering references: [clip-plane contract](https://wiki.facepunch.com/gmod/render.PushCustomClipPlane),
[restore the prior clipping state](https://wiki.facepunch.com/gmod/render.EnableClipping),
[viewmodel draw suppression](https://wiki.facepunch.com/gmod/GM:PreDrawViewModel).
