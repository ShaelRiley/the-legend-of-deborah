# Monster class and elemental identity

Development branch: `astra/equipment-update`; starting remote HEAD:
`201aebc9e109861ddde21170f542118973c13849`.

The author requested subtle class coloring and elemental affinity for one third
of monsters. Live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
03 LOD-ELEM-001/002 and 07 govern this checkpoint. The exact HUMAN enemy-spawn
paragraph now specifies one in three in place of its obsolete 50% probability.

| Class | Appearance |
| --- | --- |
| Fighter | Existing archetype color |
| Rogue | Slight green tint |
| Wizard | Slight violet tint |

Class modulation composes with existing archetype paint and restores the previous
render state. A separate soft glow uses the established six elemental colors.
An aimed caption states the element, matching resistance and opposing weakness;
it does not reveal the class, level or HP information gated by Omniscience.

Each generated monster independently rolls affinity once from a separate stream
derived from its spawn seed. On success it uniformly selects one of six elements.
This includes boss templates and human Soldier incarnations. Existing explicit
entity element overrides retain precedence. Two thirds are untyped on average;
small encounters do not enforce a fixed quota. Class, tier, abilities, HP and feat
rolls remain unchanged. Typed and untyped incarnations cannot reroll on admission.
Hero progression is kept separate from disposable Soldier state.

Earth opposes Electric, Fire opposes Ice, and Dark opposes Light. Matching hits
use the existing -11% through -88% resistance ladder; opposing hits use the +11%
through +88% weakness ladder. Each uses one uniform eight-outcome roll. Other
elements and Raw remain neutral unless another explicit rule applies. Existing
weakness hit-stun, knockback, Attunement and equipment rules retain their authority.

The aura draws up to three depth-tested sprites per visible monster within 1600
units, or two static sprites in reduced-effects mode. It introduces no dynamic
lights, particle emitters, extra entities, per-frame monster scans or new messages.
Class and element use existing NW2 replication on attachment. Cloaking hides both
glow and text; death/retirement clears the glow, and Soldier retirement clears both
identity fields.

Validation: `tools/test_monster_identity.lua` exercises production generation,
the 6-by-6 damage matrix at all eight ladder outcomes, Raw neutrality, AI/Human
Soldier parity, duplicate attachment, retirement/Hero isolation, restored render
state, bounded/reduced aura, distance and actual Watcher cloak visibility. Its
12,000-seed sample contains 3,997 typed monsters with all six elements represented.
Sixty complete generated profiles match the old generation path after excluding
the new affinity fields. All 79 integrated automated suites pass, including this
new suite and the existing progression, combat, equipment and lifecycle regressions.

Native acceptance remains pending. In an ordinary `gm_flatgrass` run, inspect
class colors and an elemental monster, then compare matching and opposing Magic.
Confirm a cloaked Watcher has no visible aura or aimed element caption. This work
provides no new evidence resolving the previous forced-close crashes. Preserve
`console_latest.txt` and `rpg_summary_latest.txt` before restarting after a crash;
retain the detailed session when event ordering is needed.
