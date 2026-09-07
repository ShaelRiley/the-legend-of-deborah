# RPG Gate E Feat Implementation Matrix

Updated: 2026-09-06  
Scope: live repository `main`; gameplay feats from the GDD — unimplemented or partially implemented feats are marked **Docs-only** or **In-progress**.

## Status summary

- **Total feat rows tracked:** 76
- **Docs-only:** 22 feats (29%)
- **In-progress:** 1 feat (1%)
- **Implemented in code:** 53 feats (70%)
- **Gameplay coverage:** ~70%

## Implementation evidence

The active modular runtime under `gamemodes/legend_of_deborah/gamemode/lod/` now includes Gate E Batch 1 feat identity/computation, Batch 2 class-combat hooks, Batch 3 hit-stun, Batch 4 movement, Batch 5 reload-speed, Batch 6 rate-of-fire, Batch 7 burst-size, Batch 8 regeneration, Batch 9 breadcrumb, Batch 10 ammo generation, Batch 11 Greater Regeneration, Batch 12 Synergistic reloading/slow/accuracy effects, Batch 13 damage-reduction armor scaling, and Batch 14 accepted Crowbar-family composition, plus the pre-existing Phase C class/ammo systems. Gate E Batch 15 Blast-Proof is wired through the central explosion-continuation authority and remains **In-progress** pending user runtime acceptance. Static status below reflects actual runtime wiring, not GDD-only documentation.

## Ordinary feats

| Feat | Base requirement | Implementation status | Implemented runtime support |
|---|---|---:|---|
| `[D] Crappy Weapon` (random weapon) | none | Implemented | Runtime weapon generation and roll modifiers |
| `[D] Big Pockets` | DEX 16 | Implemented | Ammo reserve doubling/checks |
| `[D] Crabs and Mutants` | DEX 14 | Implemented | Favored-enemy damage multiplier |
| `[D] Regenerative` | CON 16 | Implemented | Gate E Batch 8 post-damage regenerative scheduling |
| `[R|D] Greater Regeneration` | CON 17 | Implemented | Gate E Batch 11 once-per-rest spend of current/max regeneration multiplier after a reaction-eligible nearby hostile body shot |
| `[W|D] Reloading Strike` | CON 12, STR 12 | Implemented | Gate E Batch 5 melee-triggered reload effects plus Gate E Batch 12 Synergistic reload stacking |
| `[D] Defensive Reloading` | DEX 12 | Implemented | Gate E Batch 5 reload reactive effect |
| `[D] Trained Senses` | WIS 10 | Implemented | Minimap/navigation scaling |
| `[W|D] Regenerating Shell` | CON 14, STR 14 | Implemented | Gate E Batch 13 armored damage-reduction die that recovers after a 3× regeneration-cooldown damage break |
| Blast-Proof | CON 15 | In-progress | Gate E Batch 15 central incoming exploding-damage continuation suppression with per-defender 2.0-second recharge; pending runtime acceptance |
| `[W|D] Bash` | STR 12 | Implemented | Gate E Batch 14 Crowbar d6 upgrade, stacked with Walloper, Wrecking Bar, and Hero of Legend |
| `[W|D] Wrecking Bar` | STR 14, Bash | Implemented | Gate E Batch 14 Crowbar wall-crush bonus die, accepted with shared push-save telemetry |
| `[W|D] Walloper` | STR 16, Bash, Wrecking Bar | Implemented | Gate E Batch 14 Crowbar SUPER d12 upgrade and Wrecking-Bar d12 composition |
| `[R|D] Hero of Legend` | WIS 15 | Implemented | Gate E Batch 14 full-Health globally-exclusive real Crowbar projectile with WIS range, Bio-Blaster speed, Magic damage, original two-stage launch audio, translucent color-shifting visual pulse, and standard LoD hit confirm |
| `[W|D] Contusion` | STR 12 | Implemented | Gate E Batch 3 deterministic 10-second proc handling |
| `[R|D] Concussion` | STR 15, Contusion | Implemented | Gate E Batch 3 stun duration multiplier composition |
| `[D] Hold It` | DEX 16 | Implemented | Gate E Batch 3 melee reverse-hit-stun reaction |
| `[D] Parkour` | DEX 12 | Implemented | Gate E Batch 4 sprint/walk/jump movement scaling |
| `[W|D] Scooch` | STR 12 | Implemented | Gate E Batch 4 horizontal crouch-jump distance scaling |
| `[R|D] Hopping` | DEX 15 | Implemented | Gate E Batch 4 debuff-purge reaction |
| `[R|D] Full Throttle` | DEX 15 | Implemented | Gate E Batch 4 post-kill speed window |
| `[W|D] Lose It` | DEX 12 | Implemented | Gate E Batch 4 Walk-key debuff removal |
| `[W|D] Special Bullet` | DEX 10 | Docs-only | — |
| `[R|D] Gung Ho` | DEX 14, Special Bullet | Docs-only | — |
| `[W|D] Fast Shot` | DEX 12 | Docs-only | — |
| `[W|D] Shotgun Wedding` | DEX 10 | Docs-only | — |
| `[R|D] Scrapping` | DEX 12, Shotgun Wedding | Docs-only | — |
| `[W|D] Submachine Gun Sling` | DEX 12 | Docs-only | — |
| `[W|D] Sharpshooter` | DEX 10 | Docs-only | — |
| `[R|D] The Lad’s Got Talent` | DEX 13, Sharpshooter | Docs-only | — |
| `[W|D] Beam` | DEX 10 | Docs-only | — |
| `[W|D] Combat Rifle` | DEX 10 | Docs-only | — |
| `[R|D] Trouble in Paradise` | DEX 12, Beam | Docs-only | — |
| `[W|D] Heavy Artillery` | STR 12 | Docs-only | — |
| `[W|D] Grenade Bride` | STR 14, Heavy Artillery | Docs-only | — |
| `[R|D] Grenadier` | STR 16, Grenade Bride | Docs-only | — |
| `[W|D] Rockets!` | STR 12 | Docs-only | — |
| `[W|D] Smart Rockets` | STR 13, Rockets! | Docs-only | — |
| `[R|D] Rocket Man` | STR 14, Smart Rockets | Docs-only | — |
| `[W|D] Long Jump` | DEX 12, INT 12 | Docs-only | — |
| `[W|D] Air Control` | WIS 12, Long Jump | Docs-only | — |
| `[R|D] I Believe I Can Fly` | DEX 14, Air Control | Docs-only | — |
| `[D] Monstrous Regenerating` | CON 16 | Docs-only | — |
| `[W|D] Move Along` | CHA 14 | Docs-only | — |
| `[W|D] Medical Degree` | WIS 14 | Implemented | Gate E Batch 2 medic-weapon healing conversion |
| `[R|D] Emergency Mage` | INT 14, Medical Degree | Implemented | Gate E Batch 2 emergency mana restoration |
| `[W|D] That’s Mr. Soldier to You` | CHA 12 | Docs-only | — |
| `[W|D] Target Rich` | WIS 14, That’s Mr. Soldier to You | Docs-only | — |
| `[R|D] The Hunter’s Hunted` | WIS 16, Target Rich | Docs-only | — |
| `[W|D] Exploding Fireball` | INT 10 | Implemented | Gate E Batch 1 spell identity/computation |
| `[R|D] The Original Fireball` | INT 13, Exploding Fireball | Implemented | Gate E Batch 1 spell identity/computation |
| `[W|D] Rejuvenation` | WIS 10 | Implemented | Gate E Batch 1 spell identity/computation |
| `[R|D] Efficient` | WIS 13, Rejuvenation | Implemented | Gate E Batch 1 spell identity/computation |
| `[W|D] Electromagnetic Sapper` | INT 12 | Implemented | Gate E Batch 1 spell identity/computation |
| `[W|D] Rough Map` | INT 10 | Implemented | Minimap/navigation scaling |
| `[R|D] I Know I’ve Been Here Before` | WIS 12 | Implemented | Gate E Batch 9 breadcrumb consumption/restoration and retrace telemetry |
| `[W|D] Speed Reader` | INT 10 | Implemented | Gate E Batch 5 reload-time scaling |
| `[W|D] Magicka` | INT 12 | Implemented | Magic scaling |
| `[R|D] Magical Machinations` | INT 14, Magicka | Implemented | Magic scaling/threshold adjustments |
| `[R|D] KABLAM!` | INT 16, Magical Machinations | Implemented | Magic scaling/threshold adjustments |
| `[W|D] First Aid` | INT 10 | Implemented | Rejuvenation healing scaling |
| `[R|D] Medicine` | INT 13, First Aid | Implemented | Rejuvenation healing scaling |
| `[W|D] Magic Bullets` | WIS 13 | Implemented | Gate E Batch 2 aiming→magic multiplier |
| `[W|D] Dropped Hunter` | WIS 10 | Implemented | Gate E Batch 10 +1d3 bolts on Dropper pickup |
| `[W|D] Arrow Smith` | WIS 13, Dropped Hunter | Implemented | Gate E Batch 10 once-per-30s no-ammo Crossbow bolt generation |
| `[R|D] Multitasking` | WIS 16, Arrow Smith | Implemented | Gate E Batch 10 once-per-rest regenerate-one-bolt reaction below maximum bolts |
| `[W|D] Synergistic` | WIS 10 | Implemented | Gate E Batch 12 each damage source revealed as a weighted damage type with 10% same-type reload/slow/accuracy debuffs |
| `[W|D] Well Rested` | CON 10 | Implemented | Regeneration/magic/health pool scaling |
| `[R|D] Spreading the Love` | CHA 10 | Implemented | Co-op resource sharing path |
| `[W|D] Speed Caster` | WIS 10 | Implemented | Gate E Batch 5 casting cooldown scaling |
| `[W|D] Hit Point` | CON 10 | Implemented | Health pool scaling |
| `[W|D] On The Edge` | CON 12 | Implemented | Gate E Batch 2 zero-HP death-reaction delay |
| `[W|D] Hold Out` | CON 14 | Implemented | Gate E Batch 2 low-HP damage reduction |
| `[W|D] Don’t Hold Your Breath` | CON 10 | Implemented | Breath growth scaling |
| `[W|D] Pusher` | STR 10 | Implemented | Gate E Batch 14 deterministic post-damage push proc, shared with Crowbar composition and wall saves |
| `[W|D] Knock Back` | STR 12, Pusher | Implemented | Gate E Batch 14 additive push scaling with shared save semantics |
| `[W|D] Toss Around` | STR 14, Knock Back | Implemented | Gate E Batch 14 stronger additive push scaling with shared save semantics |
| `[W|D] Cannoneer` | STR 16, Toss Around | Implemented | Gate E Batch 14 global non-Shotgun firearm push and wall-crush composition |
| `[W|D] Shooting Spree` | DEX 12 | Implemented | Gate E Batch 6 firearm ROF scaling |
| `[R|D] Rapid Fire` | DEX 16, Shooting Spree | Implemented | Gate E Batch 6 stronger firearm ROF scaling |
| `[W|D] Machine Gun Molly` | DEX 14 | Implemented | Gate E Batch 7 firearm burst-size scaling |
| `[R|D] Sally Shells` | DEX 16, Machine Gun Molly | Implemented | Gate E Batch 7 stronger firearm burst-size scaling with AR2 one-ammo burst authority |

## Class feats

| Feat | Base requirement | Implementation status | Implemented runtime support |
|---|---|---:|---|
| Fighter: Health Expertise | Fighter 10 | Implemented | Class max-health scaling |
| Rogue: Regeneration Expertise | Rogue 10 | Implemented | Class regeneration scaling |
| Wizard: Magic Expertise | Wizard 10 | Implemented | Class magic scaling |
| Fighter: Second Wind | Fighter 10 | Implemented | Deterministic refill path |
| Rogue: Boom Expert | Rogue 10 | Implemented | Exploding dice threshold scaling |
| Wizard: Magicka Master | Wizard 10 | Implemented | Magic scaling |
| Fighter 20 Capstone | Fighter 20 | Implemented | Low-HP damage multiplier path |
| Rogue 20 Capstone | Rogue 20 | Implemented | Exploding dice threshold scaling |
| Wizard 20 Capstone | Wizard 20 | Implemented | Magic regeneration scaling |