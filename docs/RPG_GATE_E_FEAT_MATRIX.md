# Gate E Ordinary Feat Implementation Matrix

Source: exact live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, reload/rate-of-fire family definitions reverified at revision `ANLCKQlypm6azjpK6CFPntqCTeHdrbGj3gqHEw0WMaFrgcSu7eSm7HUSUAFdcdeUI3ZMHjp4d1773GjsBEDij7b2tiy_3WSTap-s_Ky9YQ`.

This is the Gate E completeness ledger. The live GDD remains design authority for every exact number, prerequisite, eligibility rule, and effect. The ledger intentionally stays compact so status cannot drift away from implementation.

**73 ordinary feats total: 18 mechanically implemented, 13 catalog/ownership-only, 42 not yet catalogued. 55 gameplay effects remain.** The six neutral fallback cards and nine Level-20 class capstones are separate catalogs.

| Feat ID / name | Family | Current status | Implementation note |
|---|---|---|---|
| `CON_REGEN_11`<br>Second Wind | CON / Health regeneration | Implemented + validator | Batch 1 runtime accepted: FeatEffectSystem health-regeneration ceiling/rate authority. |
| `CON_REGEN_22`<br>Rapid Recovery | CON / Health regeneration | Implemented + validator | Batch 1 runtime accepted: FeatEffectSystem health-regeneration ceiling/rate authority. |
| `CON_REGEN_33`<br>Unbroken | CON / Health regeneration | Implemented + validator | Batch 1 runtime accepted: FeatEffectSystem health-regeneration ceiling/rate authority. |
| `DEX_EXPLODE_D10`<br>Perfect Ten | DEX / Damage-die explosion access | Implemented + validator | Batch 4 runtime accepted: additive d10→d8→d4 access through AbilityRules/CombatRolls; natural-max fresh threshold, BoomShift continuation, Rogue redundancy exclusion, classExplosionImmune absolute. |
| `DEX_EXPLODE_D8`<br>Eight Is Enough | DEX / Damage-die explosion access | Implemented + validator | Batch 4 runtime accepted: additive d10→d8→d4 access through AbilityRules/CombatRolls. Baseline Crowbar remains authored d3 and is not enabled by this ladder. |
| `DEX_EXPLODE_D4`<br>Fourtunate | DEX / Damage-die explosion access | Implemented + validator | Batch 4 runtime accepted: live Pistol d4 Boomchain behavior observed; Wizard Arcane Surge + exploding Pistol retained as positive emergent composition. |
| `DEX_FAST_RELOAD`<br>Quick Reload | DEX / Reload cadence | Implemented + validator | Batch 5 runtime accepted: replacement ReloadTimeMultiplier 0.80 at confirmed Source reload state; pre-existing lockouts are absolute floors. |
| `DEX_FAST_RELOAD_2`<br>Lightning Reload | DEX / Reload cadence | Implemented + validator | Batch 5 runtime accepted: replaces Quick Reload with total multiplier 0.60; same reload-only authority/exclusions. |
| `DEX_FAST_RELOAD_3`<br>Blink Reload | DEX / Reload cadence | Implemented + validator | Batch 5 runtime accepted: replaces lower ranks with total multiplier 0.40; overheat/tells/Magic/internal burst timing remain outside the bridge. |
| `INT_AMMO_FLOOR_44`<br>Field Supply | INT / Ammo regeneration floor | Implemented + validator | Batch 3 runtime accepted: canonical owned-family ammo-regeneration floor; cadence/capacity unchanged. |
| `INT_AMMO_FLOOR_55`<br>Deep Reserves | INT / Ammo regeneration floor | Implemented + validator | Batch 3 runtime accepted: canonical owned-family ammo-regeneration floor; cadence/capacity unchanged. |
| `INT_AMMO_FLOOR_66`<br>War Stock | INT / Ammo regeneration floor | Implemented + validator | Batch 3 runtime accepted: canonical owned-family ammo-regeneration floor; cadence/capacity unchanged. |
| `DEX_RATE_OF_FIRE_1`<br>Hair Trigger | DEX / Fire cadence | Implemented + validator | Batch 6 runtime accepted: DEX 13, total RateOfFireMultiplier 1.10; ordinary firearm primary-attack interval authority only. |
| `DEX_RATE_OF_FIRE_2`<br>Rapid Fire | DEX / Fire cadence | Implemented + validator | Batch 6 runtime accepted: DEX 15 + Hair Trigger; replaces lower rank with total RateOfFireMultiplier 1.20. |
| `DEX_RATE_OF_FIRE_3`<br>Lead Storm | DEX / Fire cadence | Implemented + validator | Batch 6 runtime accepted: DEX 17 + Rapid Fire; total RateOfFireMultiplier 1.30. Final AR2 proof: 5/5 completed bursts scaled 0.880s→0.677s through `ar2_burst_complete`; laser and burst-internal spacing remained outside cadence authority. |
| `DEX_BURSTER_1`<br>Extra Round | DEX / Authored burst size | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `DEX_BURSTER_2`<br>Extended Volley | DEX / Authored burst size | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `DEX_BURSTER_3`<br>Full Barrage | DEX / Authored burst size | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `DEX_DOUBLE_JUMP`<br>Double Jump | DEX / Mobility | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `DEX_SHRINK`<br>Little Guy | DEX / Target scale | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `STR_CROWBAR_D6`<br>Bash | STR / Crowbar | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `STR_CROWBAR_D12`<br>Walloper | STR / Crowbar | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `STR_CROWBAR_CRUSH`<br>Wrecking Bar | STR / Crowbar | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `STR_HERO_OF_LEGEND`<br>Hero of Legend | STR / Crowbar pulse | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `STR_KNOCKBACK_1`<br>Pusher | STR / Pusher | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `STR_KNOCKBACK_2`<br>Shover | STR / Pusher | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `STR_KNOCKBACK_3`<br>Space Hog | STR / Pusher | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `STR_MELEE_REACH`<br>Long Reach | STR / Melee reach | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CON_STEADFAST`<br>Hard to Move | CON / Control resistance | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `CON_BLAST_PROOF`<br>Blast-Proof | CON / Explosion defense | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CON_BIG_GUY`<br>Big Guy | CON / Target scale | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CON_NOT_YET`<br>Not Yet | CON / Lethal interceptor | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CON_RUSSIAN_ASSET`<br>Russian Asset | CON / Tetris | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `DEX_SMG_COLD_HANDS_1`<br>Cold Hands | DEX / SMG heat | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `DEX_SMG_COLD_HANDS_2`<br>Ice in the Veins | DEX / SMG heat | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `DEX_SMG_COLD_HANDS_3`<br>Absolute Zero | DEX / SMG heat | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `DEX_AR2_SNAP`<br>Snap Targeting | DEX / AR2 | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `DEX_MAGNUM_DEADEYE`<br>Deadeye | DEX / Magnum | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `INT_MANA_BARRIER_1`<br>Mana Barrier | INT / HP-to-Magic diversion | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `INT_MANA_BARRIER_2`<br>Arcane Aegis | INT / HP-to-Magic diversion | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `INT_MANA_BARRIER_3`<br>Mystic Bastion | INT / HP-to-Magic diversion | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `INT_MANA_SPRING`<br>Mana Spring | INT / Magic regeneration | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `INT_FEEDBACK_LOOP`<br>Feedback Loop | INT / Magic continuation | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `INT_ARC_RECOVERY`<br>Arc Recovery | INT / Magic kill recovery | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `INT_CALCULATED_LUCK`<br>Calculated Luck | INT / Luck Ring | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `WIS_SURVEYOR`<br>Surveyor | WIS / Navigation | Implemented + validator | Batch 2 runtime accepted: canonical breadcrumb/map-drain authority. |
| `WIS_CARTOGRAPHER`<br>Cartographer | WIS / Navigation | Implemented + validator | Batch 2 runtime accepted: canonical breadcrumb/map-drain authority. |
| `WIS_FRUGAL_MAP`<br>Frugal Cartography | WIS / Navigation | Implemented + validator | Batch 2 runtime accepted: canonical breadcrumb/map-drain authority. |
| `WIS_SPELLWARD`<br>Spellward | WIS / Magic saves | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `WIS_SIXTH_SENSE`<br>Sixth Sense | WIS / Perception | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `WIS_SPELLBREAKER`<br>Spellbreaker | WIS / Magic saves | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `WIS_SPELLBANE`<br>Spellbane | WIS / Magic saves | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `WIS_FORCEFUL_MAGIC`<br>Force Multiplier | WIS / Magic push | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `WIS_ATTUNEMENT`<br>Attunement | WIS / Elemental weakness | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_HITSTUN_1`<br>Unnerving Presence | CHA / Hit stun | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `CHA_HITSTUN_2`<br>Dazing Presence | CHA / Hit stun | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_HITSTUN_3`<br>Overwhelming Presence | CHA / Hit stun | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_NERVE_1`<br>Iron Nerve | CHA / Morale defense | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_NERVE_2`<br>Unbreakable Nerve | CHA / Morale defense | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_MENACE_1`<br>Menacing | CHA / Morale offense | Catalog/ownership only | Definition/ownership present; gameplay bridge still pending. |
| `CHA_MENACE_2`<br>Dreadful | CHA / Morale offense | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_MENACE_3`<br>Terrifying | CHA / Morale offense | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_PANIC`<br>Panic Is Contagious | CHA / Morale cascade | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_SPOT_1`<br>Point It Out | CHA / Spotting | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_SPOT_2`<br>Rally the Hunt | CHA / Spotting | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CHA_SPOT_3`<br>Command the Hunt | CHA / Spotting | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CROSS_METEOR_STRIKE`<br>Meteor Strike | Cross-ability | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CROSS_TINY_TERROR`<br>Tiny Terror | Cross-ability | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CROSS_BIG_SCARY`<br>Big Scary | Cross-ability | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CROSS_CRUSH_PANIC`<br>Crash the Party | Cross-ability | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CROSS_BOOM_BATTERY`<br>Boom Battery | Cross-ability | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CROSS_FORCE_OF_WILL`<br>Force of Will | Cross-ability | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |
| `CROSS_LUCKY_BOOM`<br>Lucky Break | Cross-ability | Not yet catalogued | Not yet catalogued/bridged; exact live-GDD definition remains authoritative. |

## Batch rule

A row may advance to **Implemented + validator** only when its effect reaches the canonical gameplay seam, authored prerequisites/rank semantics are enforced, Character Sheet/runtime truth is exposed, and a finite developer validator covers the bridge. Static implementation is not runtime acceptance.
