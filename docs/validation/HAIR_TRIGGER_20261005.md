# Hair Trigger finite source checkpoint

Parent: `bbd1c19a755ba99427c647ef9d01307cf9ea24a5` (all five parent CI workflows passed).
Author scope: [single-rank 55% correction](../briefs/HAIR_TRIGGER_20261005.md).

Hair Trigger is the sole rate-of-fire feat at DEX 13, with no prerequisites and
`RateOfFireMultiplier=1.55`. Revolver, pistol, shotgun, SMG and AR2 use that shared
multiplier. AR2 projectile spacing and genuinely completed burst cycles both
receive it, including current native and legacy fixed-spacing bases. Finite Hero
bursts still spend exactly one round. Reloads, heat/cooling/overheat, targeting
warnings, damage and burst count retain their authorities. AI firearm spacing
and recovery use the same actor resolver.

Rapid Fire/Lead Storm are absent from registration, rank/prerequisite graphs,
Melf's permitted feats and future drafts. Canonical ingress collapses historical
ownership and resolved choices to one Hair Trigger without stacking or another
award; unchosen retired offers use existing deterministic stored-hand repair.
The current catalog has 112 ordinary feats, six fallbacks and nine capstones.
The card and generated manual say: **Increase firearm firing rate by 55%.**

## Finite verification

All **19/19** selected checks pass on unchanged source; **878/878** Lua files parse.
The new Hair Trigger suite contains 108 focused assertions and executes the final
production actor resolver, stock-shot observer, AR2 wrapper/service, Hero ammo,
historical ownership/draft repair and mixed-base compatibility. Its inherited
Soldier fixture separately passes 988 existing production assertions. The native
AI Soldier service verifies scaled projectile spacing and recovery with the
production Hair Trigger registration and resolver. All six protected regression
families pass. Additional checks cover the final rebalance, four-card drafts,
Hero/Soldier snapshots and lifecycle, boss resources, inventory, manual byte
parity and development installer manifest.

This is a focused source gate, not the complete campaign matrix or native GMod
acceptance. The initial selected run exposed precomputed test snapshots marked
with the previous catalog revision; those snapshots now use the current revision,
while genuine legacy migration fixtures retain their old revision. No game-state
migration guard was relaxed. The final gate is the linked 19/19 receipt.

The live GDD exact HUMAN Hair Trigger row, removal of the two retired rows and
normalized `04 → LOD-HAIR-TRIGGER-001` are readback-verified at revision
`ANLCKQmUlHpIXlUgqqjCRjeDq_RX5wfx7ceBkFwsdpnj5ZxQkzwWH2SxmdIiMnmRGrSLjqw2kDKEAZWGg9e2Cg8ohbKLMunfHqqeJwdRdA`.
The neighboring Extra Round row and complete tab topology remain intact. The
independent GDD fixture preserves the exact authored new effect.

Tested snapshot digest:
`825ecdce65bdc313bd510ac2524c7381f8a5e3cee78b17568e979f545e940254`.
It covers all tracked/untracked source before adding this report, the receipt and
log archive; those three post-gate evidence files are the only snapshot exclusions.
All per-suite stdout/stderr hashes in the [receipt](HAIR_TRIGGER_20261005.json)
are verified against the [archived logs](HAIR_TRIGGER_20261005_logs.tar.gz).

Native firing feel remains pending. The accepted native wall renderer and current
overlay optimization are preserved. Continue the already requested fully restarted
gm_flatgrass capture with `lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180`.
Sustained 40 FPS remains open; no new native FPS claim or Workshop/VPS deployment.
