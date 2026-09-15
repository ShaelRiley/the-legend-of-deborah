# Gordon the Warden — development checkpoint

Development branch: `astra/equipment-update`. Starting remote HEAD:
`253af3b273f53d5c6910931fc4c5d738f8418be8`.
Canonical main remains `8978796e886cdb5505d24ed0de085265fa99bac8`.

The author's explicit direction authorizes missing tuning for Gordon. The live
[GDD](https://docs.google.com/document/d/1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY)
was read through 00 → 01 → 05/06 → the exact HUMAN Gordon section; chosen values
are recorded in 07. Earlier requests and the native-crash release hold remain in force.

## Encounter

Black Gate now leads to Gordon, replacing the temporary Core Jail Key. The final
corridor connects to a protected entry alcove, a 3×3 lower court, an eight-cell
upper gallery with an open center, two ordinary stair routes, and a perimeter
jail. Existing graph, floor, wall, navigation and minimap authorities build the
extension. No arena teleporter or detached navigation graph is introduced.

The first living Hero entering the court commits the encounter. Its rear gate
closes, the title/HP bar appears and an entrance sting plays. Eligible returning
Heroes can use that gate to enter the protected alcove. Ordinary respawn timing
and lives remain authoritative. No boss HP/phase reset occurs between deaths;
regeneration pauses when no Hero occupies the court.

| Phase | Threshold | Behavior |
| --- | --- | --- |
| Vanishing volleys | Above 60% | Three seconds cloaked relocation; 0.65-second visible warning; four gently homing, swept orbs 0.22 seconds apart. 2d6+2 Raw magic; speed 460; eight-second lifetime. |
| Toilet bomber | At 60% | Visible toilet rider leaves one bomb every 1.6 seconds. Three-second fuse, 180-unit radius, 3d6+2 physical blast, blocked by solid geometry. |
| Crowbar berserker | At 25% | All ordnance and cloaking retire. Crowbar pursuit only: 2d4+3 physical, base range 95, 0.3-second warning and 0.85-second cooldown. |

Ordinary hit-stun/control rules interrupt wind-ups. Fuses and projectile travel
run outside the NextBot behavior callback, so hit stun cannot suspend a bomb.
Shared combat rolls own every attack and defenses; a bomb rolls once for all
victims. Party size never increases damage. Existing instance variation applies.

Health construction is 1,000 reference HP → Champion D+2 / d20 / CON / other RPG
modifiers → deterministic size and 0.94–1.06 health variation → 1/1.2/1.4/1.6
party HP multiplier. The pre-existing 500 value is XP and remains unchanged.

Each Hero identity gets one allocation per dungeon: +25 HP capped at MaxHP,
up to 30 rounds per owned firearm family within normal clip/reserve caps, and
one Healing Potion if inventory space permits. Death/reconnect cannot repeat it.
The alcove prevents incoming damage and attacking Gordon directly from safety.

Death defers native cleanup beyond damage handling, clears remaining court
hostiles and hazards, opens the rear gate, and releases one recoverable Jail Key
at the lower court center. Collecting it, using the jail door and touching Deborah
remain separate required actions. Deborah cheers/claps after the door opens.
An ordinary same-batch party wipe still wins. Rescue uses the existing celebration.

## Assets and sound integration

Gordon uses a level-seeded random stock male citizen (`male_01` through
`male_09` in `models/Humans/Group01`). Cached client bone scales broaden his
pelvis, torso and thighs. A head-attached pink pig mask has a protruding snout,
paired nostrils, dark eye apertures and triangular ears, drawn with built-in
spheres and quads. It disappears during cloaking and stays through all visible
phases. Client render bounds include the heavier silhouette and ears.

No external Gordon model, Workshop subscription, downloaded texture or mask
entity is required. Appearance selection uses its own seeded stream and does
not change combat rolls. Server collision, encounter logic and tuning are
preserved. Reduced effects lowers mask tessellation.

The toilet and crowbar use reusable, nonphysical client models, created outside
render callbacks. There are no native grenade entities, extra dynamic lights,
physics-driven toilets or per-frame model allocations. Sixteen Lua hazards and
five snapshots/second cap the new recurring work. Cloaking suppresses rendering
and ordinary near-look identification while retaining the entity's network
identity; server-side SetNoDraw would remove it from client networking, per the
[engine documentation](https://wiki.facepunch.com/gmod/Entity:SetNoDraw).

Gordon publishes `LOD_EncounterMusicPressure("warden", 2/3/0)` for commitment,
desperation and victory. **Audible adaptive scoring remains dependent on the
unshipped MusicDirector/soundtrack suite system.** This checkpoint provides
entrance/phase/victory cues and adds no separate looping boss track.

## Verification and next native action

**88 automated suites pass.** New production-path checks cover 24 valid arena
seeds, graph integrity and gate/jail separation, extended floors and both stair
apertures, ordered health scaling across levels/party sizes, four-shot volleys,
phase cancellation, independent bomb fuses, shared blast rolls and target
defenses, resupply receipts, preserved HP/phase, center-key identity/recovery,
ordinary wipe precedence and stale callbacks.

After installing the development build, deploy a
Hero on `gm_flatgrass`, then run:

```text
lod_developer_mode 1; lod_warden_testkit; lod_warden_status
```

The explicit test shortcut marks the run unranked, opens the approach and places
you in the alcove. Step into the court to commit. It cannot reset an existing
fight, award a second boss or bypass the Jail Key/rescue sequence.

Finite native gate: observe all three phases and both arena floors, die/respawn
without a boss reset, then defeat Gordon and complete key → door → Deborah.
For co-op, verify a second eligible Hero can enter/rejoin through the rear gate.
Check toilet seating, crowbar pose, projectile readability, gallery visibility,
Deborah's cheer, the heavier citizen silhouette and pig-mask fit. These remain unobserved here.

**This is not native-crash acceptance.** No Garry's Mod runtime is available in
this environment. Main, Workshop release and live VPS are not updated. Preserve
`console_latest.txt` + `rpg_summary_latest.txt`; include `rpg_session_latest.txt`
if phase timing, death order or another forced close needs investigation.
