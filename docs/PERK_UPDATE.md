# Identity perk correction

Shael's requested correction is implemented on `astra/equipment-update`, following
the equipment comparison repair at `63aad1b94cb5c68d8ebe10f19587c3b243a4c906`.
Live GDD rule LOD-ID-002 and its corresponding HUMAN rules were updated in place.

- Origin, Background and Motive each independently roll one of the three perk
  families with equal probability. This was already implemented; new regression
  assertions prove every family is reachable in every slot, including three of
  the same family. Repeated exact targets continue to stack.
- New ability perks have two points: equally likely +2 to one ability or +1 to
  each of two distinct abilities. The primary ability is uniform across six;
  the split's second ability is uniform across the other five. A separate seeded
  stream prevents this addition from changing family/primary-target rolls.
- Explicit per-ability contributions feed the existing intrinsic-stat and stable
  feat-qualification authorities. No extra perk handler or equipment effect exists.
- Every visible trait title, perk title and flavor sentence now comes from the
  resolved record. The old tables remain allocation/history data, not displayed
  copy. Origin describes upbringing; Background describes prior work; Motive
  always explains the Deborah rescue. Split perks describe both talents.
- Version-1 Heroes retain their actual perk families, targets and permanent +2
  bonuses. Migration refreshes their presentation once without rerolling mechanics.

Examples from the new copy rules:

| Category and roll | Displayed title | Mechanical summary |
|---|---|---|
| Origin / favored Zombie family | Zombie Quarantine Zone | One extra primary attack die against that model family |
| Background / STR +1, DEX +1 | Freight Handler & Watch Repairer | Permanent +1 STR and +1 DEX |
| Motive / favored Revolver | Deborah's Revolver Backup | +1 direct Revolver damage per damaged target |

Validation: all 66 integrated automated suites passed. The expanded production
identity test covers deterministic generation, every family in every category,
three-of-a-kind outcomes, both stat shapes, matching snapshots, duplicate/split
aggregation, intrinsic stats, feat qualification and preservation of v1 Heroes.
Existing combat/dice, equipment and RPG regressions remain passing. Run
`python3 tools/test_checkpoint_g_integration.py`.

Native GMod presentation has not been observed in this environment. After
installing this development branch, existing Heroes should show corrected copy
in P; a fresh test campaign is required to see newly generated split stat perks.
Main and public deployment remain unchanged.
