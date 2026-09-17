# Current weapon identity — aura, muzzle, two tints

The 2026-09-17 author request retires all procedural surface patterns. The four
patch assets and their generator are removed. Native material-region mappings
protect control surfaces and independently tint A/B while preserving base and
normal textures. Unknown or single-gun-material meshes retain their canonical
finish. Inspect native topology with `lod_weapon_regions`; Source runtime
acceptance is still pending. Muzzle size, duration and spoke family now vary
visibly with the immutable descriptor. The 128-material ceiling, scoped restoration,
world draw budgets, prediction deduplication and native hands remain protected.
See [integrated checkpoint](INTEGRATED_REFRESH_20260917.md).

The following preserves the superseded pattern checkpoint as historical evidence.

# Previous weapon surface presentation

The current author direction replaces the geometric gun fittings and changes
Ice flavor from Watery to **Wintery**. The live GDD (00 entrypoint → 01 index →
90 equipment and 07 tuning; 06 UI preservation) was read and the four affected
rule paragraphs were updated and verified. Combat rules are unchanged.

- Shared immutable roll descriptor remains version 1, at most 480 characters.
  Every stored property and magnitude contributes to the stable finish hash.
- One safe gun material slot is treated; hand/arm/glove/glass surfaces and
  external skins are excluded. Original base textures remain in the shader.
  Four 64×64 mipmapped RGBA VTF detail maps have approximately 15% marked texels;
  the remaining neutral-grey field preserves the stock surface. No whole-model
  material or color override is used. Unknown models retain the stock texture.
- A pool of at most 128 stock-surface/finish materials survives map cleanup and
  Lua refresh. Item count does not allocate new materials. Per-draw tint and
  detail scale vary with the frozen roll. Viewmodel overrides restore in the
  paired post hook and PostRender fallback. Pickups use their existing draw
  method. Settled third-person weapons use one owned RenderOverride around
  their actual native DrawModel call; an existing override is respected.
  Restore after errors, map cleanup, shutdown and refresh; no additional model
  draw, model entity, mesh, particle emitter, light or collision change.
- Aura is one reduced/two normal depth-tested stock glow sprites, with a 1200
  unit range and four/eight world draws per frame. Muzzle color observes the
  native shot: one server message per weapon/tick coalesces shotgun pellets;
  local prediction is deduplicated. Flashes fade over 0.075 seconds. The stock
  first-person flash may remain beneath the elemental accent; supported player
  muzzle events use the elemental replacement. No damage callback is replaced.
- New generation uses Wintery, Wintery Warding and Wintery Frailty. ItemName
  projects older frozen names to Wintery without editing stored DFT records.
  The historical crash fixture remains verbatim; its replay permits only this
  authorized display-word substitution, with all numeric signatures intact.

## Verification

All 102 integrated suites pass, including real production style compilation,
2,500 distinct sampled roll fingerprints, all 60 properties, copy selection,
material/hand preservation, resource ceilings, cleanup/error paths, visibility,
shot coalescing, manual payload parity, native grant and shotgun regressions.
The actual historical LuaJIT 2.0.4 VM passes the 14-reward corpus 100 times;
`Equipment:Generate` retains its scoped legacy-JIT workaround.

Native rendering cannot be exercised in this container. On gm_flatgrass, equip
and fire two different elemental guns, reload/swap them and collect a gun drop.
Confirm clean silhouettes, stock hands, partial finish, aura and muzzle hue;
check a second player's held gun during the same ordinary co-op session.
The finite visual gate is no floating fittings, no all-over replacement/hand
color leak, no stuck override after swaps, and an element-colored shot accent.
Use `lod_reduced_effects 1` to confirm restrained presentation when desired.
This candidate is not a claim of runtime acceptance or live deployment.

API contracts: [native entity draw override](https://wiki.facepunch.com/gmod/ENTITY:RenderOverride),
[paired viewmodel drawing](https://wiki.facepunch.com/gmod/GM:PreDrawViewModel),
[post-shot observer](https://wiki.facepunch.com/gmod/GM:PostEntityFireBullets).
