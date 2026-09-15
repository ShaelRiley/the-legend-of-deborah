# Elemental magic and equipment inventory checkpoint

Development branch: `astra/equipment-update`. Starting remote HEAD:
`5ad31f9fa64ed722e3fad4912c6a105317a877e8`.

The live GDD (document `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`)
03 LOD-FX-001, 06 LOD-UI-008/009 and tab 07 record the author's new direction.

## Changes

- Original elemental choreography across Blast, Beam, Bomb, Missile, Bolt and
  Summon: fire plumes/embers, earth fragments, ice shards, branching electricity,
  inward dark spirals, light rays/stars, and raw force streaks. Detonations add
  hot cores, expanding lobes and smoke. Summon charge contacts inherit Content.
- Exact existing server area geometry, 40% fills and opaque outer boundaries
  remain authoritative. Beam retains its cyan core and resolved endpoint.
  No damage, saves, timing, radius or travel changes.
- Bolt/Missile look like enchanted comets. Bomb keeps its accepted black iron
  shell and burning fuse. Summon keeps its stable model/hull with an elemental
  aura. Projectile and summon rendering no longer allocate recurring lights.
- Impacts last 0.9 seconds, area indicators 1.15 seconds. At most 48 cast records,
  four area indicators and twelve detailed bursts; reduced effects lowers
  accents from twelve to four. No new emitters/models/timers; sound is throttled.
- The weapon name returns beneath the face, with two bounded lines and full
  text on Equipment. Status names remain above, ALT FIRE remains hidden.
- Drag the active weapon to an empty bag tile to stow it; drag/select it again
  to wield it. Native gun, magazine, reserve ammo and procedural item persist.
  An inert empty-hands adapter contributes no bonuses. Ownership, life, role,
  stale active class and request rate remain server checked. Menu stays open.
- Bag shows unequipped guns/wearables and consumable stacks, with at least three
  tile rows and a free row after occupied rows. Small displays scroll the grid.
- Ordinary useful drops add wearable weight 8 and consumable weight 6 alongside
  existing ammo/health/armor/weapon/life weights. These are relative weights,
  not percentages. Existing 0.563 useful chance, dry-streak/guaranteed paths,
  optional 35% weapon/cache-to-wearable conversion, 80/20 Healing Potion/Stink
  Bomb mix and separate rare DFT roll remain. All wearables use the same
  depth-scaled generator and owner-checked collection.

## Verification and next runtime check

`python3 tools/test_checkpoint_g_integration.py`: 77 suites pass. Tests include
all six forms and seven content signatures, real FX message dispatch, reduced
work, expiry, burst/sound limits, actual stow/re-equip with magazine preservation,
invalid role/life/stale requests, ordinary category reachability, wearable family
coverage, collection replay rejection, VGUI drag/snapshot behavior and HUD layout
from 640×480 through ultrawide. Source rendering and listening remain untested.

In an ordinary run, cast the available spells, use Equipment to stow and re-equip
your gun, and check natural drops while fighting. For immediate gear variety use
`lod_equipment_economy_testkit` after deployment (marks the run unranked).

Previous portal/Soldier native crash causes remain unconfirmed. Their candidate
repairs, granite Deborah and diagnostic stages are preserved. Keep the newest
console/session files if a forced close recurs. No main promotion or public
server deployment was performed.
