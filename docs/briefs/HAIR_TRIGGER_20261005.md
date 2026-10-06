# Hair Trigger author correction

Author instruction: raise Hair Trigger to a 55% bonus, eliminate Rapid Fire and
Lead Storm, and make the family a single-step tree. Apply the bonus to revolver,
pistol, shotgun, SMG and AR2. Player-facing text does not distinguish firing modes.

- Keep `DEX_RATE_OF_FIRE_1`, DEX 13, no prerequisites, nonrepeatable, with
  `RateOfFireMultiplier = 1.55` through the existing shared firearm authority.
- Remove `DEX_RATE_OF_FIRE_2` and `DEX_RATE_OF_FIRE_3` from registration,
  candidates, prerequisites, mechanical ranks and Melf's eligible feat list.
- Divide stock firearm attack intervals, AR2 projectile spacing and completed
  burst-cycle intervals by 1.55. Keep genuine completion as the next-trigger floor.
  Enemy firearm projectile spacing and recovery use the same shared multiplier.
- Preserve ammunition transactions, burst counts, damage, reloads, Magic,
  SMG heat/cooling/lockout, targeting warnings and enemy telegraphs. Magnum's
  separate free-projectile burst spacing retains its existing authority.
- At canonical state ingress, collapse owned/resolved historical ranks into one
  Hair Trigger without stacking or another award. Repair unchosen retired cards
  through the existing deterministic stored-hand repair.
- Use exactly: **Increase firearm firing rate by 55%.** The character sheet,
  offers and generated manual consume the same registered text.

The live GDD's exact HUMAN row and `04 → LOD-HAIR-TRIGGER-001` are updated and
readback-verified. The catalog now has 112 ordinary feats, six fallbacks and nine
capstones. The independent live-GDD fixture retains the exact new HUMAN effect.
This correction intervenes before the pending Steam Deck optimization retest;
native cadence/feel and the sustained 40 FPS target remain separate acceptance.
