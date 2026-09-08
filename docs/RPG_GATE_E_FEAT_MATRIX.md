# RPG Gate E Feat Implementation Matrix

Reconciled 2026-09-08 against live GDD modified 2026-09-08T06:07:17.109Z.
Starting main: `544702805fcf97c13f1055b1cee16ca4d3b5b3d4`.
Design: https://docs.google.com/document/d/1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY/edit

## Measured set relationship

- 143 enumerated ordinary/cross feats; 9 separate class capstones; 6 separate repeatable fallbacks: **158 total definitions**.
- Ordinary registry: **52 present, 91 missing, 0 noncanonical**, after alias normalization.
- GDD `STR_HERO_OF_LEGEND` and runtime `WIS_HERO_OF_LEGEND` are the same Hero of Legend, WIS 15. Keep the existing runtime ID for state compatibility.
- All 9 capstones and 6 fallbacks have catalog definitions; this does not establish complete runtime behavior.
- No numerical ordinary-feat count was found in the live GDD to correct. The stale 119 count was in development status.
- Enumeration includes the embedded CON_GLOW_UP row immediately following CON_POISON_PROC_3 on the same exported line.
- Counts were obtained by loading active catalog-mutating modules in production order, including the later weapon-specials Burster module, under a Lua harness. Engine hooks were stubbed; this is registry evidence, not gameplay acceptance.
- The previous 76-row matrix contained unsupported names, prerequisites, and implementation claims. It is superseded in full by this inventory; it was not evidence of extra runtime feats.

## Reconciliation matrix

| System | Live GDD | Current main at starting HEAD | Discrepancy | Required action |
|---|---|---|---|---|
| Ordinary feats | 143 entries and authored effects | 52 definitions, 91 absent; effects vary | Registry and mechanical completion gate fails | Implement missing families; audit present effects against current text |
| Winning Personality | CHA 17, permanent +1 CHA, INT-feat qualification substitution | Substitution works; +1 CHA absent | Missing permanent benefit | Repaired in this batch; runtime acceptance pending |
| Attributes / derived stats | Six universal abilities, current class/condition rules | Hero growth and consumers in sv_character_progression and sv_rpg_gate_d | Partial; no universal actor implementation | Audit each current formula and consumer after feat gate |
| Hero level / XP | Server-authoritative progression; handoff doubles thresholds | Level 1–20; XP awards and 0–48,000 threshold table wired | Slower curve not applied | Phase 2: central 2x thresholds and XP cap, focused progression tests |
| Classes / identity | Current class passives and standardized procedural identity perks | Classes wired; catalog still has obsolete authored identity descriptors | Current design differs from inherited plan | Replace obsolete identity effects with canonical normalized perk authority in RPG phase |
| Magic | Shared Hero Form/Content casting and fixed 100 Magic | Force Shout, pool/regen, Wizard diversion/Feedback and feat bridges | Partial; canonical modular casting absent | Resolve Form-count contradiction; implement shared casting after feats |
| Prerequisites / drafts | All controller types, capabilities, stable intrinsic scores, locked offers | Hero eligibility and draft path exists | Scope/availability/effect-specific restrictions require audit | Preserve locked drafts and test candidate pools per family |
| Persistence / UI | Campaign persistence, identity-safe reconnect, current P-sheet and network truth | Hero state, snapshots, P-sheet wired | Partial coverage; new systems not integrated | Test death, transition, reconnect, reset and independent multiplayer identities |
| Enemy levels | Deterministic spawn level/class/abilities/feats | LODProgressionState consumer exists; assignments found only in control-magic testkit | No production enemy state producer | Phase 2: implement spawn state and explicitly prescribed consumers; preserve other tuning |
| Neil / Brute | Post-Yellow escort/flee pair and Black Keycard | XP constants and historical identity text only; no encounter implementation found | Missing gameplay | Phase 3A after RPG acceptance |
| Gordon the Warden | Boss, arena, Jail Key progression | WardenStarted state guard; pre-Warden jail-key slice | Missing boss gameplay | Phase 3B |
| Human Soldier | Playable hostile role and role-safe RPG state | AI Soldier exists; feat actor tags alone do not provide human control | Missing playable role | Phase 3C |

## Authoritative contradictions to isolate

The live GDD says the Form catalog has six entries while Hero progression and form-unlock feat eligibility still refer to five. Resolve before that dependent implementation. The older Snap Targeting timing conflict remains unadjudicated; inspect current authored timing before implementing it. Neither issue blocks the present Winning Personality repair.

## Ordinary enumeration

“Present” means active registry membership only. Handler IDs identify the implementation seam; they do not certify completeness or runtime acceptance. Consult the live GDD for full effects, interaction rules and dynamic eligibility; requirements below are the enumerated printed requirements.

| Canonical ID | Name | Requirement | Prerequisite | Registry | Handler |
|---|---|---|---|---|---|
| CON_REGEN_11 | Second Wind | CON 13 | None | Present | health_regeneration |
| CON_POISON_PROC_1 | Venomous | CON 13 | None | Missing | — |
| CON_POISON_PROC_2 | Toxic | CON 15 | Venomous | Missing | — |
| CON_POISON_PROC_3 | Virulent | CON 17 | Toxic | Missing | — |
| CON_GLOW_UP | Glow Up | CON 17 | None | Missing | — |
| CON_REGEN_22 | Rapid Recovery | CON 15 | Second Wind | Present | health_regeneration |
| CON_REGEN_33 | Unbroken | CON 17 | Rapid Recovery | Present | health_regeneration |
| DEX_EXPLODE_D10 | Perfect Ten | DEX 13 | None | Present | dex_exploding_damage_dice |
| DEX_CLUMSY_PROC_1 | Distracting | DEX 13 | None | Missing | — |
| DEX_CLUMSY_PROC_2 | Disorienting | DEX 15 | Distracting | Missing | — |
| DEX_CLUMSY_PROC_3 | Discombobulating | DEX 17 | Disorienting | Missing | — |
| DEX_IMMOLATE_PROC_1 | Singeing | DEX 13 | None | Missing | — |
| DEX_IMMOLATE_PROC_2 | Scorching | DEX 15 | Singeing | Missing | — |
| DEX_IMMOLATE_PROC_3 | Incendiary | DEX 17 | Scorching | Missing | — |
| DEX_EXPLODE_D8 | Eight Is Enough | DEX 15 | Perfect Ten | Present | dex_exploding_damage_dice |
| DEX_EXPLODE_D4 | Fourtunate | DEX 17 | Eight Is Enough | Present | dex_exploding_damage_dice |
| DEX_FAST_RELOAD | Quick Reload | DEX 13 | None | Present | dex_reload_cadence |
| DEX_FAST_RELOAD_2 | Lightning Reload | DEX 15 | Quick Reload | Present | dex_reload_cadence |
| DEX_FAST_RELOAD_3 | Blink Reload | DEX 17 | Lightning Reload | Present | dex_reload_cadence |
| INT_AMMO_FLOOR_44 | Field Supply | INT 13 | None | Present | ammo_regeneration_floor |
| INT_ARCANE_PROC_1 | Disruptor | INT 13 | None | Missing | — |
| INT_ARCANE_PROC_2 | Spellbreaker | INT 15 | Disruptor | Missing | — |
| INT_ARCANE_PROC_3 | Nullifier | INT 17 | Spellbreaker | Missing | — |
| INT_AMMO_FLOOR_55 | Deep Reserves | INT 15 | Field Supply | Present | ammo_regeneration_floor |
| INT_AMMO_FLOOR_66 | War Stock | INT 17 | Deep Reserves | Present | ammo_regeneration_floor |
| DEX_RATE_OF_FIRE_1 | Hair Trigger | DEX 13 | None | Present | dex_rate_of_fire |
| DEX_RATE_OF_FIRE_2 | Rapid Fire | DEX 15 | Hair Trigger | Present | dex_rate_of_fire |
| DEX_RATE_OF_FIRE_3 | Lead Storm | DEX 17 | Rapid Fire | Present | dex_rate_of_fire |
| DEX_BURSTER_1 | Extra Round | DEX 13 | None | Present | dex_burst_size |
| DEX_BURSTER_2 | Extended Volley | DEX 15 | Extra Round | Present | dex_burst_size |
| DEX_BURSTER_3 | Full Barrage | DEX 17 | Extended Volley | Present | dex_burst_size |
| DEX_SPRING_HEEL | Spring Heel | DEX 13 | None | Present | spring_heel |
| DEX_WALL_JUMP | Wall Jump | DEX 15 | None | Missing | — |
| DEX_STRAFER_1 | Strafer | DEX 13 | None | Missing | — |
| DEX_SIDELER_2 | Sideler | DEX 15 | Strafer | Missing | — |
| DEX_LATERAL_MOVER_3 | Lateral Mover | DEX 17 | Sideler | Missing | — |
| DEX_SHRINK | Little Guy | DEX 15 | None | Missing | — |
| STR_CROWBAR_D6 | Bash | STR 13 | None | Present | crowbar_family |
| STR_CROWBAR_D12 | Walloper | STR 15 | Bash | Present | crowbar_family |
| STR_CROWBAR_CRUSH | Wrecking Bar | STR 17 | Walloper | Present | crowbar_family |
| STR_HERO_OF_LEGEND | Hero of Legend | STR 13 | None | Present | crowbar_family |
| STR_KNOCKBACK_1 | Pusher | STR 13 | None | Present | pusher_weapon_knockback |
| STR_KNOCKBACK_2 | Shover | STR 15 | Pusher | Present | pusher_weapon_knockback |
| STR_KNOCKBACK_3 | Space Hog | STR 17 | Shover | Present | pusher_weapon_knockback |
| STR_STEAMROLLER | Steamroller | STR 17 | None | Missing | — |
| STR_BLEED_PROC_1 | Bloodletter | STR 13 | None | Missing | — |
| STR_BLEED_PROC_2 | Deep Wounds | STR 15 | Bloodletter | Missing | — |
| STR_BLEED_PROC_3 | Exsanguinator | STR 17 | Deep Wounds | Missing | — |
| STR_MELEE_REACH | Long Reach | STR 15 | None | Present | melee_reach |
| CON_STEADFAST | Hard to Move | CON 13 | None | Present | steadfast_control_resistance |
| CON_BLAST_PROOF | Blast-Proof | CON 15 | None | Present | con_blast_proof |
| CON_BIG_GUY | Big Guy | CON 15 and STR 13 | None | Missing | — |
| CON_NOT_YET | Not Yet | CON 15 | None | Missing | — |
| CON_RUSSIAN_ASSET | Russian Asset | INT 13 | None | Present | russian_asset |
| DEX_SMG_COLD_HANDS_1 | Cold Hands | DEX 13 | None | Present | dex_smg_heat |
| DEX_SMG_COLD_HANDS_2 | Ice in the Veins | DEX 15 | Cold Hands | Present | dex_smg_heat |
| DEX_SMG_COLD_HANDS_3 | Absolute Zero | DEX 17 | Ice in the Veins | Present | dex_smg_heat |
| DEX_AR2_SNAP | Snap Targeting | DEX 15 | None | Missing | — |
| DEX_MAGNUM_DEADEYE | Deadeye | DEX 15 | None | Present | magnum_deadeye |
| INT_MANA_BARRIER_1 | Mana Barrier | INT 13 | None | Present | gate_b_feat_ownership |
| INT_MANA_BARRIER_2 | Arcane Aegis | INT 15 | Mana Barrier | Present | gate_b_feat_ownership |
| INT_MANA_BARRIER_3 | Mystic Bastion | INT 17 | Arcane Aegis | Present | gate_b_feat_ownership |
| INT_MANA_SPRING | Mana Spring | INT 13 | None | Present | mana_spring_regeneration |
| INT_CLOUD_STEP | Cloud Step | INT 13 | None | Missing | — |
| INT_FLOAT_ON | Float On | INT 15 | None | Missing | — |
| INT_SIZE_SHIFTER | Size Shifter | INT 13 | None | Missing | — |
| INT_QUANTUM_MATHEMATICS_1 | Quantum Mathematics | INT 13 | None | Missing | — |
| INT_QUANTUM_MECHANICS_2 | Quantum Mechanics | INT 15 | Quantum Mathematics | Missing | — |
| INT_QUANTUM_MASTERY_3 | Quantum Mastery | INT 17 | Quantum Mechanics | Missing | — |
| INT_MIDDLE_MANAGER | Middle Manager | INT 13 | None | Missing | — |
| INT_TASKMASTER | Taskmaster | INT 15 | Middle Manager | Missing | — |
| INT_OVERLORD | Overlord | INT 17 | Taskmaster | Missing | — |
| INT_AFTERSHOCK | Aftershock | INT 15 | None | Missing | — |
| INT_WORLD_WALKER_1 | World Walker | INT 13 | None | Missing | — |
| INT_GLOBETROTTER_2 | Globetrotter | INT 15 | World Walker | Missing | — |
| INT_MIND_STRIDER_3 | Mind Strider | INT 17 | Globetrotter | Missing | — |
| INT_GRAND_UNIFIED_THEORY | Grand Unified Theory | INT 17 | None | Missing | — |
| INT_EXTRACURRICULAR_ACTIVITY | Extracurricular Activity | INT 17 | None | Missing | — |
| INT_POLYMORPH | Polymorph | INT 17 | None | Missing | — |
| INT_WAS_DEBORAH | W,A,S,Deborah | INT 13 | None | Missing | — |
| INT_HASTE_1 | Haste | INT 13 | None | Missing | — |
| INT_HASTE_2 | Mana Rush | INT 15 | Haste | Missing | — |
| INT_HASTE_3 | Aether Drive | INT 17 | Mana Rush | Missing | — |
| INT_FEEDBACK_LOOP | Feedback Loop | INT 15 | None | Present | magic_continuation_recovery |
| INT_ARC_RECOVERY | Arc Recovery | INT 17 | None | Present | magic_kill_recovery |
| INT_CALCULATED_LUCK | Calculated Luck | INT 15 | Luck Ring owned/equipped | Missing | — |
| WIS_SURVEYOR | Surveyor | WIS 13 | None | Present | wis_navigation |
| WIS_MUTE_PROC_1 | Hushing | WIS 13 | None | Missing | — |
| WIS_MUTE_PROC_2 | Silencing | WIS 15 | Hushing | Missing | — |
| WIS_MUTE_PROC_3 | Dead Air | WIS 17 | Silencing | Missing | — |
| WIS_HELD_PROC_1 | Snaring | WIS 13 | None | Missing | — |
| WIS_HELD_PROC_2 | Binding | WIS 15 | Snaring | Missing | — |
| WIS_HELD_PROC_3 | Entrapping | WIS 17 | Binding | Missing | — |
| WIS_RECKLESS_PROC_1 | Agitating | WIS 13 | None | Missing | — |
| WIS_RECKLESS_PROC_2 | Unhinging | WIS 15 | Agitating | Missing | — |
| WIS_RECKLESS_PROC_3 | Maddening | WIS 17 | Unhinging | Missing | — |
| WIS_CARTOGRAPHER | Cartographer | WIS 15 | Surveyor | Present | wis_navigation |
| WIS_FRUGAL_MAP | Frugal Cartography | WIS 15 | None | Present | wis_navigation |
| WIS_TRUE_FAITH | True Faith | WIS 15 | None | Missing | — |
| WIS_MIND_OVER_MATTER | Mind Over Matter | WIS 17 | True Faith | Missing | — |
| WIS_GPS | GPS | WIS 17 | None | Missing | — |
| WIS_ASTRAL_REACH | Astral Reach | WIS 15 | None | Missing | — |
| WIS_SPATIAL_AWARENESS | Spatial Awareness | WIS 15 | None | Missing | — |
| WIS_KILLER_INSTINCT | Killer Instinct | WIS 15 | None | Missing | — |
| WIS_OMNISCIENCE | Omniscience | WIS 17 | None | Missing | — |
| WIS_SPELLWARD | Spellward | WIS 13 | None | Present | gate_b_feat_ownership |
| WIS_SIXTH_SENSE | Sixth Sense | WIS 13 | None | Present | gate_b_feat_ownership |
| WIS_SPELLBREAKER | Spellbreaker | WIS 15 | Spellward | Missing | — |
| WIS_SPELLBANE | Spellbane | WIS 17 | Spellbreaker | Missing | — |
| WIS_FORCEFUL_MAGIC | Force Multiplier | WIS 15 | None | Present | forceful_magic_push |
| WIS_ATTUNEMENT | Attunement | WIS 17 | Elemental system active and actor owns an elemental Magic attack | Missing | — |
| CHA_HITSTUN_1 | Unnerving Presence | CHA 13 | None | Present | cha_hitstun_presence |
| CHA_HITSTUN_2 | Dazing Presence | CHA 15 | Unnerving Presence | Present | cha_hitstun_presence |
| CHA_HITSTUN_3 | Overwhelming Presence | CHA 17 | Dazing Presence | Present | cha_hitstun_presence |
| CHA_NERVE_1 | Iron Nerve | CHA 13 | None | Missing | — |
| CHA_NERVE_2 | Unbreakable Nerve | CHA 15 | Iron Nerve | Missing | — |
| CHA_MENACE_1 | Menacing | CHA 13 | None | Present | gate_b_feat_ownership |
| CHA_MENACE_2 | Dreadful | CHA 15 | Menacing | Missing | — |
| CHA_MENACE_3 | Terrifying | CHA 17 | Dreadful | Missing | — |
| CHA_FEAR_PROC_1 | Daunting | CHA 13 | None | Missing | — |
| CHA_FEAR_PROC_2 | Cowing | CHA 15 | Daunting | Missing | — |
| CHA_FEAR_PROC_3 | Overawing | CHA 17 | Cowing | Missing | — |
| CHA_PANIC | Panic Is Contagious | CHA 17 | Dreadful | Missing | — |
| CHA_SPOT_1 | Point It Out | CHA 13 | None | Missing | — |
| CHA_SPOT_2 | Rally the Hunt | CHA 15 | Point It Out | Missing | — |
| CHA_SPOT_3 | Command the Hunt | CHA 17 | Rally the Hunt | Missing | — |
| CHA_ABRASIVE_PERSONALITY_1 | Abrasive Personality | CHA 13 | None | Missing | — |
| CHA_NARCISSISM_2 | Narcissism | CHA 15 | Abrasive Personality | Missing | — |
| CHA_MEGALOMANIA_3 | Megalomania | CHA 17 | Narcissism | Missing | — |
| CHA_AURA_BURST_1 | Aura Burst | CHA 13 | None | Missing | — |
| CHA_RADIANCE_2 | Radiance | CHA 15 | Aura Burst | Missing | — |
| CHA_MAJESTY_3 | Majesty | CHA 17 | Radiance | Missing | — |
| CHA_ACADEMIC_ACHIEVEMENT | Academic Achievement | CHA 15 | None | Present | academic_magic_regeneration |
| CHA_SELF_ACTUALIZATION | Self-Actualization | CHA 15 | None | Missing | — |
| CHA_AGGRESSIVE_PERSONALITY | Aggressive Personality | CHA 15 | None | Missing | — |
| CHA_WINNING_PERSONALITY | Winning Personality | CHA 17 | None | Present | winning_personality_qualification |
| CROSS_METEOR_STRIKE | Meteor Strike | STR 15 and INT 15 | Bash; Cloud Step | Missing | — |
| CROSS_TINY_TERROR | Tiny Terror | DEX 15 and CHA 15 | Little Guy; Menacing | Missing | — |
| CROSS_BIG_SCARY | Big Scary | CON 15, STR 13, and CHA 15 | Big Guy; Menacing | Missing | — |
| CROSS_CRUSH_PANIC | Crash the Party | STR 17 and CHA 17 | Pusher; Dreadful | Missing | — |
| CROSS_BOOM_BATTERY | Boom Battery | DEX 15 and INT 15 | Capability: exploding_nonmagic_damage_dice | Missing | — |
| CROSS_FORCE_OF_WILL | Force of Will | STR 15 and WIS 15 | Pusher; Force Multiplier | Missing | — |
| CROSS_LUCKY_BOOM | Lucky Break | DEX 17 and INT 15 | Capability: exploding_nonmagic_damage_dice; Luck Ring owned/equipped | Missing | — |
