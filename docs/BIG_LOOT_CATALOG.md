# Big Loot authored catalog

## Frozen baseline and counting rule

Baseline: **45** gameplay-meaningful item/equipment identities on main
`fc166870633db5f277165d9c33ae00d82feaa81a`, counted by loading the production
catalog, before this checkpoint's additions. The 60 reusable property types are
reported separately and are **not** added to the identity count. Neither affix
combinations, roll magnitudes, name fragments, rarity tiers nor recolors count.

| Baseline category | Count | Identity scope |
| --- | ---: | --- |
| Generic wearable bases | 7 | Cap, Vest, Trousers, Boots, Ring, Gloves, Shield; distinct slot/occupancy and opportunity costs |
| Weapon bases | 7 | Pistol, Crowbar, Shotgun, SMG, Revolver, Pulse Rifle, finite-charge Wand |
| Named innate wearables | 7 | Psychic Crown, Fighting Gloves, Invisibility Ring, Thunder Hat, Heavy Plumber Boots, Tanuki Ring, Moon Boots |
| Healing and persistent poison cloud | 2 | Healing Potion, Stink Bomb |
| Damage and status bombs | 17 | Raw, Physical, six elemental bombs and nine distinct condition bombs |
| Travel and recovery utilities | 3 | Magic Hourglass, Summon Card, Resurrection Feather |
| Other utilities | 2 | Chest Key, Damsel's Revenge |
| **Total** | **45** | Existing identities remain valid and available |

The expansion contributes **113** manually authored stable archetypes:
**158 total / 45 baseline = 3.5111×**, an increase of **251.11%**.
Every archetype guarantees a unique set of two or three positive signature effects,
a fixed elemental affinity, a real drawback and an explicit tactical role.
Signature uniqueness ignores the name, base slot, affinity, drawback, rarity and
numeric roll. The catalog is authored row by row; it is not a Cartesian product.
Its novelty is in reliable, legible combinations of existing authorities, without
adding a parallel combat system or treating every random combination as an item.

## Architecture and preserved guarantees

`E.Archetypes[id]` describes `id`, `name`, canonical `base`, `slot`, thematic
`family`, `element`, guaranteed `signature`, `drawback`, `minimumRarity`,
`minLevel`, `weight`, `tags`, `motifs` and player-facing `description`.
`E.ArchetypeOrder` is stable. `E:GenerateArchetype(seed, level, id, contextId)`
uses the existing version-2 generator with an optional fifth archetype argument.
Ordinary calls preserve their existing RNG consumption and recorded outputs.

An owned record keeps its canonical `definitionId`, with only an `archetypeId`
added. Weapon-class slots, native materialization, paired glove occupancy,
inventory limits, frozen DFT records, lifecycle, appearance packet limits and
existing effect aggregation therefore remain the same. Effects require actual
equipped state, and weapon properties require the active weapon. The author-defined
signature is validated in addition to every existing version-2 record constraint.
The name and inspection description expose the stable identity, role and full
rolled properties including the penalty.

Every record retains exactly one affinity and one drawback, four to seven positive
properties by rarity, exact legal budget/value equality, bounded saturating
magnitudes, shared aggregate caps and the generator's function-local LuaJIT guard.
All weapon signatures include a rider. Guaranteed effects consume the same budget
as random effects; they add no free innate power. The remaining legal property
positions vary procedurally.

Rarity floors are Unusual, Rare or Exalted with ecology base weights 80, 35 or 9.
These weights select identities, not item rarity: the original rarity roll remains
and a profile may only raise its floor. `minLevel` is a director eligibility rule;
explicit generation is permitted at any legal level so existing fusion can find a
budget-fitting item. Revolver profiles begin at level 2, Pulse Rifle profiles at
level 3, and Held Breath at level 5. Other profiles begin at level 1.

Thematic families map to the director motifs scavenged, military, medical, occult,
elemental, industrial, mobility, defensive, unstable and expedition. The authored
rationale describes the actual existing mechanic: no ammunition grants, new attack
cadence, extra saving throws, new spell forms or traversal exceptions are implied.
All visuals use the canonical base models and existing procedural tint grammar.

## Distribution across equipment bases

| Canonical base | Added archetypes |
| --- | ---: |
| `headwear` | 10 |
| `vest` | 10 |
| `trousers` | 10 |
| `boots` | 10 |
| `ring` | 12 |
| `gloves` | 10 |
| `shield` | 10 |
| `weapon_pistol` | 6 |
| `weapon_lod_crowbar` | 6 |
| `weapon_shotgun` | 6 |
| `weapon_smg1` | 6 |
| `weapon_357` | 6 |
| `weapon_ar2` | 6 |
| `weapon_lod_wand` | 5 |

## Authored identities

Positive IDs below are guaranteed signatures; every row also guarantees the listed
affinity and negative property. Rarity names denote minimum rarity.

| Stable ID / name | Base | Family | Affinity | Guaranteed signature | Drawback | Rarity / first level | Tactical role |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `surveyors_lantern` — Surveyor's Lantern | `headwear` | scavenger | electric | `breadcrumb`, `map_efficiency` | `defense` | Unusual / 1 | Follow a longer remembered route with cheaper map use; the open frame sacrifices physical protection. |
| `triage_visor` — Triage Visor | `headwear` | medic | light | `regen_ceiling`, `save_con` | `physical` | Unusual / 1 | Recover between engagements and resist bodily conditions; its medical focus blunts physical attacks. |
| `capacitor_cowl` — Capacitor Cowl | `headwear` | occultist | electric | `charged`, `magic_regen` | `movement` | Unusual / 1 | Bank Magic for empowered casts and replenish it faster; the capacitor slows repositioning. |
| `hush_hood` — Hush Hood | `headwear` | warden | dark | `proc_muted`, `save_int` | `regen_rate` | Unusual / 1 | Silence targets while guarding your own condition saves; reduced recovery makes prolonged exchanges costly. |
| `quarry_helmet` — Quarry Helmet | `headwear` | dockworker | earth | `push_resist`, `ward_earth` | `save_dex` | Unusual / 1 | Hold position against force and Earth attacks; the rigid harness makes DEX saves worse. |
| `watchmans_lens` — Watchman's Lens | `headwear` | hunter | ice | `still`, `proc_clumsy` | `movement` | Unusual / 1 | Stop to shoot and destabilize the target; slower movement makes the firing position a commitment. |
| `dread_circlet` — Dread Circlet | `headwear` | occultist | dark | `proc_intimidated`, `ability_cha` | `defense` | Unusual / 1 | Pair intimidation attempts with CHA investment; its exposed construction increases physical danger. |
| `oathkeepers_mask` — Oathkeeper's Mask | `headwear` | pilgrim | light | `save_wis`, `ward_dark` | `magic_regen` | Unusual / 1 | Protect judgment and resist Dark damage at the cost of slower Magic recovery. |
| `cracked_crown` — Cracked Crown | `headwear` | anomaly | fire | `summon_cap`, `injured` | `save_wis` | Rare / 1 | Command another summon while turning low health into physical offense; poor WIS saves punish reckless use. |
| `dispatch_goggles` — Dispatch Goggles | `headwear` | courier | electric | `ability_int`, `movement` | `push_resist` | Unusual / 1 | Trade anchoring for a quicker, INT-led scouting build. |
| `infirmary_coat` — Infirmary Coat | `vest` | medic | light | `regen_ceiling`, `regen_rate` | `movement` | Unusual / 1 | Raise the recovery ceiling and accelerate recovery; retreat must begin early because the coat slows movement. |
| `ballast_vest` — Ballast Vest | `vest` | dockworker | earth | `defense`, `push_resist` | `magic_regen` | Unusual / 1 | Hold a physical front line without being displaced; Magic replenishes more slowly. |
| `glass_furnace` — Glass Furnace | `vest` | anomaly | fire | `magic`, `charged` | `defense` | Rare / 1 | Spend a well-filled Magic reserve on powerful spells while accepting greater physical damage. |
| `last_rescuer_coat` — Last Rescuer's Coat | `vest` | survivor | light | `injured`, `regen_ceiling` | `magic` | Unusual / 1 | Low health strengthens physical retaliation, then recovery narrows that window; spell damage pays the cost. |
| `warden_insulation` — Warden Insulation | `vest` | warden | electric | `ward_electric`, `save_con` | `movement` | Unusual / 1 | Resist Electric pressure and bodily conditions while surrendering chase speed. |
| `scavengers_apron` — Scavenger's Apron | `vest` | scavenger | earth | `ability_con`, `breadcrumb` | `save_cha` | Unusual / 1 | Survive longer detours and remember more of them; CHA saves become a liability. |
| `duelists_webbing` — Duelist's Webbing | `vest` | veteran | ice | `dodge`, `physical` | `push_resist` | Unusual / 1 | Combine evasion with physical pressure, but forced movement can break the duel. |
| `cinder_sheath` — Cinder Sheath | `vest` | occultist | fire | `ward_fire`, `proc_immolated` | `weak_ice` | Unusual / 1 | Press burning targets behind Fire resistance; Ice remains the deliberate counter. |
| `mourning_mantle` — Mourning Mantle | `vest` | pilgrim | dark | `summon_duration`, `ward_dark` | `regen_rate` | Unusual / 1 | Keep summons alive longer under Dark pressure; your own recovery is slower. |
| `hunters_brigandine` — Hunter's Brigandine | `vest` | hunter | ice | `still`, `defense` | `movement` | Unusual / 1 | Establish a protected stationary firing position at the expense of pursuit. |
| `couriers_wraps` — Courier's Wraps | `trousers` | courier | electric | `movement`, `save_dex` | `physical` | Unusual / 1 | Move and resist DEX conditions while sacrificing direct physical force. |
| `dockside_greaves` — Dockside Greaves | `trousers` | dockworker | earth | `push_resist`, `ability_str` | `save_int` | Unusual / 1 | Anchor a STR-led advance; mental conditions remain an exploitable weakness. |
| `escape_webbing` — Escape Webbing | `trousers` | survivor | ice | `dodge`, `breadcrumb` | `regen_rate` | Unusual / 1 | Evade while remembering escape routes; successful disengagement does not grant quick recovery. |
| `siege_trousers` — Siege Trousers | `trousers` | soldier | earth | `still`, `push_resist` | `magic` | Unusual / 1 | Refuse displacement while making stationary physical attacks; this stance trades away spell damage. |
| `hotwire_chaps` — Hotwire Chaps | `trousers` | anomaly | electric | `movement`, `charged` | `save_con` | Unusual / 1 | Carry a full Magic reserve into fast repositioning; bodily conditions can derail the plan. |
| `pilgrims_kilt` — Pilgrim's Kilt | `trousers` | pilgrim | light | `map_efficiency`, `save_wis` | `defense` | Unusual / 1 | Spend less on navigation and resist WIS conditions, but avoid trading physical hits. |
| `suture_leggings` — Suture Leggings | `trousers` | medic | light | `regen_rate`, `save_dex` | `magic_regen` | Unusual / 1 | Recover faster when another source permits regeneration and guard DEX saves; Magic recovery suffers. |
| `sapper_overalls` — Sapper Overalls | `trousers` | scavenger | fire | `ward_fire`, `push_out` | `save_cha` | Unusual / 1 | Shove threats away under Fire pressure; CHA conditions threaten the improvised harness. |
| `nightwatch_slacks` — Nightwatch Slacks | `trousers` | warden | dark | `proc_held`, `save_wis` | `movement` | Unusual / 1 | Pin opponents while guarding WIS saves; the wearer is slower too. |
| `bloodrun_breeches` — Bloodrun Breeches | `trousers` | veteran | fire | `injured`, `movement` | `regen_rate` | Unusual / 1 | Turn a wounded retreat into mobile physical retaliation; slower recovery prolongs both opportunity and danger. |
| `runner_relay` — Runner Relay | `boots` | courier | electric | `move_quickstep`, `magic_regen` | `physical` | Unusual / 1 | Refill the Magic used by Quickstep; accepting weaker physical blows makes escape its primary role. |
| `bulkhead_treads` — Bulkhead Treads | `boots` | dockworker | earth | `move_quickstep`, `push_resist` | `movement` | Unusual / 1 | Dash out of trouble and resist displacement, but ordinary travel is deliberately slower. |
| `smokejump_soles` — Smokejump Soles | `boots` | soldier | fire | `move_quickstep`, `ward_fire` | `weak_ice` | Unusual / 1 | Use Quickstep through Fire-heavy fights; Ice punishes this specialized escape kit. |
| `grave_stride` — Grave Stride | `boots` | occultist | dark | `move_quickstep`, `summon_duration` | `regen_rate` | Unusual / 1 | Reposition while persistent summons hold pressure; personal recovery is slower. |
| `measured_retreat` — Measured Retreat | `boots` | veteran | ice | `move_quickstep`, `still` | `defense` | Unusual / 1 | Alternate committed stationary shots with a Quickstep exit; being caught costs extra physical damage. |
| `scout_springs` — Scout Springs | `boots` | scavenger | electric | `movement`, `breadcrumb` | `save_con` | Unusual / 1 | Explore and retain a longer route memory, but guard against bodily conditions. |
| `icehook_boots` — Icehook Boots | `boots` | hunter | ice | `ward_ice`, `push_resist` | `magic_regen` | Unusual / 1 | Hold terrain against Ice and displacement; Magic reserves take longer to replenish. |
| `wounded_hare` — Wounded Hare | `boots` | survivor | light | `move_quickstep`, `injured` | `save_wis` | Unusual / 1 | Dash into or away from low-health physical opportunities; weak WIS saves make overcommitment costly. |
| `surge_sandals` — Surge Sandals | `boots` | anomaly | electric | `movement`, `proc_push` | `defense` | Unusual / 1 | Chase and repel opponents at the cost of physical protection. |
| `field_medic_steps` — Field Medic Steps | `boots` | medic | light | `movement`, `regen_ceiling` | `magic` | Unusual / 1 | Reach safety and recover beyond your ordinary ceiling; spell damage is reduced. |
| `riot_seal` — Riot Seal | `ring` | warden | earth | `move_rebuff`, `proc_reckless` | `save_cha` | Unusual / 1 | Combine Rebuff with weapon Reckless attempts; your own CHA saves become vulnerable. |
| `circuit_loop` — Circuit Loop | `ring` | occultist | electric | `move_rebuff`, `magic_regen` | `defense` | Unusual / 1 | Replenish Rebuff's resource cost while accepting less physical protection. |
| `field_triage_ring` — Field Triage Ring | `ring` | medic | light | `move_rebuff`, `regen_ceiling` | `physical` | Unusual / 1 | Create space with Rebuff, then recover; sustained physical offense is weaker. |
| `undertow_band` — Undertow Band | `ring` | anomaly | ice | `move_rebuff`, `push_out` | `weak_fire` | Unusual / 1 | Build around stronger displacement through Rebuff and ordinary Push; Fire is its counter. |
| `summoners_collateral` — Summoner's Collateral | `ring` | pilgrim | dark | `summon_cap`, `magic_regen` | `regen_rate` | Rare / 1 | Fund a larger summon group with faster Magic recovery while neglecting your own healing. |
| `blood_price` — Blood Price | `ring` | survivor | fire | `injured`, `proc_bleeding` | `defense` | Unusual / 1 | Stay wounded to empower physical strikes that can inflict Bleeding; return damage is more dangerous. |
| `stillwater_loop` — Stillwater Loop | `ring` | hunter | ice | `still`, `proc_held` | `movement` | Unusual / 1 | Pin targets with attacks from a stationary position; slower travel makes repositioning deliberate. |
| `quarantine_seal` — Quarantine Seal | `ring` | medic | earth | `proc_poisoned`, `save_con` | `magic` | Unusual / 1 | Apply Poisoned while resisting bodily conditions; direct spell offense pays the price. |
| `glass_command` — Glass Command | `ring` | occultist | dark | `summon_cap`, `magic` | `defense` | Rare / 1 | Add summon capacity and spell force with a physical-defense liability. |
| `cartographers_oath` — Cartographer's Oath | `ring` | scavenger | electric | `breadcrumb`, `save_int` | `physical` | Unusual / 1 | Navigate with longer memory and INT saves while surrendering physical output. |
| `ash_tithe` — Ash Tithe | `ring` | pilgrim | fire | `proc_immolated`, `magic_regen` | `weak_ice` | Unusual / 1 | Feed Magic recovery while weapons attempt Immolated; Ice weakness is the tithe. |
| `wardens_veto` — Warden's Veto | `ring` | warden | light | `proc_arcane_shattered`, `save_wis` | `regen_rate` | Unusual / 1 | Challenge magical protection and guard WIS saves; wearers recover health more slowly. |
| `riveters_grip` — Riveter's Grip | `gloves` | dockworker | earth | `physical`, `push_out` | `magic` | Unusual / 1 | Combine physical force and displacement, sacrificing spell damage. |
| `surgeons_grip` — Surgeon's Grip | `gloves` | medic | light | `proc_bleeding`, `regen_ceiling` | `save_str` | Unusual / 1 | Cause Bleeding and recover between operations; opposing Push contests expose a weak grip. |
| `voltage_knuckles` — Voltage Knuckles | `gloves` | anomaly | electric | `proc_clumsy`, `charged` | `defense` | Unusual / 1 | Destabilize with weapons before spending a charged Magic reserve; fragile protection demands timing. |
| `hangmans_mittens` — Hangman's Mittens | `gloves` | warden | dark | `proc_held`, `push_out` | `movement` | Unusual / 1 | Hold an opponent, then exploit displacement; the gloves make ordinary movement slower. |
| `plague_handlers` — Plague Handlers | `gloves` | occultist | earth | `proc_poisoned`, `ward_earth` | `weak_light` | Unusual / 1 | Deliver Poisoned through weapons under Earth protection; Light is the deliberate weakness. |
| `duelists_tape` — Duelist's Tape | `gloves` | veteran | ice | `ability_dex`, `physical` | `push_resist` | Unusual / 1 | Pair DEX with physical attacks but concede resistance to displacement. |
| `cinder_workers` — Cinder Workers | `gloves` | dockworker | fire | `proc_immolated`, `ability_str` | `magic_regen` | Unusual / 1 | Support STR-led burning strikes while slowing Magic replenishment. |
| `hex_catchers` — Hex Catchers | `gloves` | pilgrim | light | `save_int`, `save_wis` | `movement` | Unusual / 1 | Commit both hands to mental-condition protection and accept slower positioning. |
| `prison_breakers` — Prison Breakers | `gloves` | scavenger | electric | `proc_arcane_shattered`, `proc_push` | `defense` | Rare / 1 | Strip protection and force space with weapon riders; the hands provide no safe defensive default. |
| `last_hand` — Last Hand | `gloves` | survivor | dark | `injured`, `proc_intimidated` | `regen_rate` | Unusual / 1 | Use wounded physical pressure to threaten morale; slower recovery makes the brink last longer. |
| `bulkhead_buckler` — Bulkhead Buckler | `shield` | dockworker | earth | `block`, `push_resist` | `movement` | Unusual / 1 | Combine Block with anchoring while moving more slowly. |
| `ambulance_panel` — Ambulance Panel | `shield` | medic | light | `block`, `regen_ceiling` | `physical` | Unusual / 1 | Block during withdrawal and recover afterward; the medical panel reduces physical aggression. |
| `riot_capacitor` — Riot Capacitor | `shield` | soldier | electric | `block`, `magic_regen` | `save_dex` | Unusual / 1 | Protect against eligible hits and replenish Magic, but worsen DEX condition saves. |
| `duelists_screen` — Duelist's Screen | `shield` | veteran | ice | `block`, `dodge` | `push_resist` | Unusual / 1 | Split protection across the existing Block and Dodge authorities; forced movement remains dangerous. |
| `furnace_door` — Furnace Door | `shield` | dockworker | fire | `block`, `ward_fire` | `weak_ice` | Unusual / 1 | Block physical attacks behind Fire resistance while accepting Ice weakness. |
| `prison_mirror` — Prison Mirror | `shield` | warden | light | `block`, `proc_arcane_shattered` | `defense` | Unusual / 1 | Block or shatter an opponent's protection; an unblocked physical hit is more punishing. |
| `hermits_partition` — Hermit's Partition | `shield` | pilgrim | dark | `block`, `summon_duration` | `movement` | Unusual / 1 | Hold your own line while summons persist; relocation is slow. |
| `defiant_sign` — Defiant Sign | `shield` | survivor | earth | `block`, `injured` | `regen_rate` | Unusual / 1 | Turn Block into room for a wounded counteroffensive; recovery is intentionally slower. |
| `couriers_cover` — Courier's Cover | `shield` | courier | electric | `block`, `movement` | `magic_regen` | Unusual / 1 | Carry eligible-hit protection into a moving fight at the cost of Magic recovery. |
| `quarantine_shutter` — Quarantine Shutter | `shield` | medic | earth | `block`, `save_con` | `weak_dark` | Unusual / 1 | Guard bodily saves and Block while exposing a Dark weakness. |
| `checkpoint_whistle` — Checkpoint Whistle | `weapon_pistol` | soldier | light | `proc_intimidated`, `still` | `movement` | Unusual / 1 | Stop to apply physical pressure and morale attempts; carrying this firing posture slows movement. |
| `couriers_sidearm` — Courier's Sidearm | `weapon_pistol` | courier | electric | `proc_clumsy`, `movement` | `defense` | Unusual / 1 | Disrupt pursuit while staying mobile; its active grip leaves less physical protection. |
| `clinic_receipt` — Clinic Receipt | `weapon_pistol` | medic | light | `proc_bleeding`, `save_con` | `physical` | Unusual / 1 | Trade direct damage for Bleeding attempts and bodily-condition protection. |
| `lockkeepers_note` — Lockkeeper's Note | `weapon_pistol` | warden | dark | `proc_held`, `map_efficiency` | `magic_regen` | Unusual / 1 | Hold a pursuer while mapping an exit; Magic regenerates more slowly while held. |
| `hollow_promise` — Hollow Promise | `weapon_pistol` | anomaly | fire | `proc_reckless`, `injured` | `regen_rate` | Unusual / 1 | Wounded physical attacks carry Reckless attempts; slower healing extends the risky posture. |
| `surveyor_sidearm` — Surveyor Sidearm | `weapon_pistol` | scavenger | earth | `proc_push`, `breadcrumb` | `magic` | Unusual / 1 | Make space and remember the route while sacrificing spell damage. |
| `dockside_argument` — Dockside Argument | `weapon_lod_crowbar` | dockworker | earth | `proc_push`, `physical` | `magic_regen` | Unusual / 1 | Use close physical force to push opponents away, trading away Magic recovery. |
| `icebreakers_hook` — Icebreaker's Hook | `weapon_lod_crowbar` | hunter | ice | `proc_held`, `ability_str` | `movement` | Unusual / 1 | Pin with a STR-led close attack; slower movement makes the initial approach matter. |
| `cinder_prybar` — Cinder Prybar | `weapon_lod_crowbar` | scavenger | fire | `proc_immolated`, `injured` | `defense` | Unusual / 1 | Commit wounded physical force to burning strikes and accept a fragile counterattack window. |
| `graveyard_lever` — Graveyard Lever | `weapon_lod_crowbar` | occultist | dark | `proc_poisoned`, `summon_duration` | `save_con` | Unusual / 1 | Apply Poisoned while summons persist; bodily saves become more vulnerable in melee. |
| `wardens_eraser` — Warden's Eraser | `weapon_lod_crowbar` | warden | electric | `proc_arcane_shattered`, `physical` | `magic` | Unusual / 1 | Strip magical protection with physical pressure at the cost of direct spell strength. |
| `surgical_lever` — Surgical Lever | `weapon_lod_crowbar` | medic | light | `proc_bleeding`, `regen_rate` | `push_resist` | Unusual / 1 | Inflict Bleeding and improve already-enabled recovery; enemy displacement can break contact. |
| `eviction_notice` — Eviction Notice | `weapon_shotgun` | warden | earth | `proc_push`, `still` | `movement` | Unusual / 1 | Commit a stationary blast to displacement; slower movement makes exits worth planning. |
| `riot_lullaby` — Riot Lullaby | `weapon_shotgun` | soldier | dark | `proc_intimidated`, `defense` | `magic_regen` | Unusual / 1 | Pressure morale with a protected firing stance; Magic recovery is reduced. |
| `furnace_sneeze` — Furnace Sneeze | `weapon_shotgun` | dockworker | fire | `proc_immolated`, `ward_fire`, `physical` | `weak_ice` | Rare / 1 | Mix Fire protection and physical burning pressure; Ice counters the furnace. |
| `quarantine_bell` — Quarantine Bell | `weapon_shotgun` | medic | earth | `proc_poisoned`, `regen_ceiling` | `movement` | Unusual / 1 | Spread Poisoned attempts, then recover after disengaging; movement is slower. |
| `broken_overture` — Broken Overture | `weapon_shotgun` | anomaly | electric | `proc_arcane_shattered`, `injured` | `defense` | Unusual / 1 | Exploit wounded physical pressure to break protection while accepting dangerous return hits. |
| `tangled_exit` — Tangled Exit | `weapon_shotgun` | survivor | ice | `proc_held`, `dodge` | `physical` | Unusual / 1 | Favor holding attempts and evasion over raw physical damage when escaping close pressure. |
| `dispatch_static` — Dispatch Static | `weapon_smg1` | courier | electric | `proc_muted`, `movement` | `regen_rate` | Unusual / 1 | Move while pressuring enemy casting; health recovery is the sacrificed resource. |
| `dockyard_hail` — Dockyard Hail | `weapon_smg1` | dockworker | earth | `proc_push`, `push_resist` | `magic` | Unusual / 1 | Repel targets without giving up anchoring; direct spell damage declines. |
| `clinic_stapler` — Clinic Stapler | `weapon_smg1` | medic | light | `proc_bleeding`, `magic_regen` | `physical` | Unusual / 1 | Trade physical output for Bleeding attempts and replenished Magic. |
| `contraband_fume` — Contraband Fume | `weapon_smg1` | scavenger | dark | `proc_poisoned`, `map_efficiency` | `defense` | Unusual / 1 | Combine Poisoned pressure with cheaper route planning; physical protection is weak while held. |
| `prison_jangle` — Prison Jangle | `weapon_smg1` | warden | ice | `proc_reckless`, `proc_clumsy` | `save_cha` | Rare / 1 | Contest the opponent's control with two distinct riders while accepting weaker CHA saves. |
| `expedition_signal` — Expedition Signal | `weapon_smg1` | veteran | fire | `proc_intimidated`, `breadcrumb` | `magic_regen` | Unusual / 1 | Pressure morale while preserving a longer escape trail; Magic recovery is slower. |
| `watchtower_verdict` — Watchtower Verdict | `weapon_357` | hunter | ice | `proc_arcane_shattered`, `still` | `movement` | Unusual / 2 | Wait for a stationary physical shot that can shatter protection; carrying it slows travel. |
| `blood_debt` — Blood Debt | `weapon_357` | survivor | fire | `proc_bleeding`, `injured`, `physical` | `defense` | Rare / 2 | Commit to wounded physical punishment and Bleeding at the cost of protection. |
| `chaplains_doubt` — Chaplain's Doubt | `weapon_357` | pilgrim | light | `proc_intimidated`, `save_wis` | `magic` | Unusual / 2 | Contest morale and protect WIS saves while reducing spell damage. |
| `frozen_receipt` — Frozen Receipt | `weapon_357` | soldier | ice | `proc_held`, `ward_ice` | `weak_fire` | Unusual / 2 | Anchor control attempts behind Ice resistance; Fire remains a direct counter. |
| `arc_inspector` — Arc Inspector | `weapon_357` | occultist | electric | `proc_muted`, `charged` | `physical` | Unusual / 2 | Use Silence attempts to prepare charged spell damage rather than maximize physical shots. |
| `wreckers_clause` — Wrecker's Clause | `weapon_357` | dockworker | earth | `proc_push`, `ability_str` | `magic_regen` | Unusual / 2 | Pair displacement with STR investment; Magic recovery suffers while this tool is held. |
| `warden_protocol` — Warden Protocol | `weapon_ar2` | warden | electric | `proc_muted`, `proc_arcane_shattered` | `defense` | Rare / 3 | Pressure casting and magical protection through distinct riders while exposing physical defense. |
| `ash_docket` — Ash Docket | `weapon_ar2` | soldier | fire | `proc_immolated`, `still` | `movement` | Unusual / 3 | Plant your feet for burning physical pressure, accepting slower transit. |
| `escort_array` — Escort Array | `weapon_ar2` | veteran | light | `proc_push`, `save_wis` | `physical` | Unusual / 3 | Prioritize displacement and WIS protection over direct physical output. |
| `plague_regulator` — Plague Regulator | `weapon_ar2` | occultist | dark | `proc_poisoned`, `charged` | `regen_rate` | Unusual / 3 | Apply Poisoned pressure while retaining Magic for stronger casts; healing is slower. |
| `icebound_order` — Icebound Order | `weapon_ar2` | hunter | ice | `proc_clumsy`, `ward_ice` | `weak_fire` | Unusual / 3 | Destabilize enemies while resisting Ice; Fire targets the specialization. |
| `riot_remnant` — Riot Remnant | `weapon_ar2` | anomaly | earth | `proc_reckless`, `physical` | `save_cha` | Unusual / 3 | Pair physical pressure with Reckless attempts and accept vulnerability in CHA saves. |
| `surge_auditor` — Surge Auditor | `weapon_lod_wand` | occultist | electric | `proc_arcane_shattered`, `magic` | `defense` | Rare / 1 | Spend finite wand charges on spell force and shattering attempts; physical defense is weaker. |
| `quietus_probe` — Quietus Probe | `weapon_lod_wand` | warden | dark | `proc_muted`, `summon_cap` | `regen_rate` | Rare / 1 | Carry extra summon capacity alongside muting wand pressure; personal recovery is slower. |
| `infirmary_probe` — Infirmary Probe | `weapon_lod_wand` | medic | light | `proc_clumsy`, `regen_ceiling` | `physical` | Unusual / 1 | Use finite-charge disruption while enabling more recovery; physical attacks are reduced. |
| `cinder_beacon` — Cinder Beacon | `weapon_lod_wand` | pilgrim | fire | `proc_immolated`, `summon_duration` | `weak_ice` | Unusual / 1 | Pair burning wand pressure with lasting summons, accepting Ice weakness. |
| `held_breath` — Held Breath | `weapon_lod_wand` | anomaly | ice | `proc_held`, `charged`, `magic` | `movement` | Exalted / 5 | Hold enemies and spend charged Magic pressure from a powerful wand; movement is slower. |

## Static validation and runtime boundary

`tools/test_big_loot_catalog.lua` generates **6,780** production records across
all 113 archetypes and levels 1, 5, 20, 100 and 999. It checks the frozen baseline,
unique meaningful signatures, reproducibility, signature preservation, legal
slot/paired-item contribution, unequip cleanup, malformed metadata rejection,
exact value budgets, numeric bounds, descriptions and compact weapon appearance
encoding. Maximum sampled value was **1,867**, including doubled-budget gloves.

The existing 16,000-record procedural economy suite, recorded LuaJIT guard replay,
authoritative equipment economy runtime suite and weapon appearance suite also
passed during catalog development. Production loot exposure, motif distributions,
full transaction regressions and native acceptance are integration gates recorded
by the root checkpoint; this catalog test alone does not establish them.
