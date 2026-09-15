# Reactive character HUD portrait

## Current layout correction

The latest author direction supersedes the initial lower-left placement and the
subsequent request to retain it. This follow-up builds on crash-repair candidate
`2b6029663bc83b0c6972bbdf81e9789091112e8a` on `astra/equipment-update`.

The portrait now shares the real scaled Magic bounds (including its Steam Deck
layout), sits 12 px to their right, and aligns to their bottom. Its size scales
from 64 to 128 px. The character-name/status caption wraps above it and clears the
combat-feed column; adding ailments does not displace the face. Shared Character
Sheet appearance, expressions and reduced-effects behavior are retained.

The persistent carried-weapon-name HUD hook is removed, including on Lua refresh;
full item names remain in Equipment. `CHudSecondaryAmmo` is always suppressed, so
the stock ALT FIRE readout cannot reappear on AR2/SMG. Primary ammo, Health, Magic
and the functional potion throw/drink prompts remain available. No combat inputs,
server state, statue placement or crash-handling code changes in this follow-up.

Live GDD LOD-UI-009 and the tab 07 portrait tuning row were corrected and verified
in place. All **76 integrated automated suites pass**. Existing client tests now
check portrait/caption bounds at 640×480, 1024×768, 1280×800, 1280×720, 1920×1080
and 3440×1440, all simultaneous ailments, primary-ammo preservation, secondary-ammo
suppression and removal of the old name hook on refresh. These are headless layout
checks, not Source screenshots or native-crash acceptance. Check the bottom HUD
during the already requested Soldier-kill retest; the crash cause remains unconfirmed.

## Initial portrait checkpoint (historical)

Candidate: `astra/equipment-update`, based on `903c50e7d47837c6f801dd333f8f5e40e9e045fe`.
Main remains `8978796e886cdb5505d24ed0de085265fa99bac8`; no deployment or promotion.

The author requested a Doom-inspired face that reacts to combat and chiefly
communicates the character's name or current ailments. Live GDD LOD-UI-007 now
records this HUD-specific identity-format exception and tab 07 its presentation
settings. Combat-feed and Die Log identity formatting remain unchanged.

## Behavior

The Character Sheet and HUD now use `cl_character_portrait.lua`, sharing the exact
model path, face camera, lighting and flex discovery. The sheet retains its smile.
The live face is determined at rest, winces after replicated HP loss, grins on
firearm/melee animation or Magic cast events, bobs with grounded movement, and
progressively lowers its head/pants as health decreases. Wincing overrides grinning.
No held mouse button alone starts a grin.

The HUD caption contains the procedural character name alone. Active ailments
replace it with all their names, wrapped beside the portrait. It includes Immolated,
Poisoned, Bleeding, Clumsy, Muted, Held, Reckless, Shield Shattered and Intimidated.
The old bottom-center indicator is removed. A shared registration function permits
future authored buffs to consume existing replicated state on this same surface;
this change introduces no new buff or gameplay mechanic.

The portrait sits in the lower-left above stock health/Magic, clear of the right
combat feed at 640×480 and Steam Deck dimensions. It hides/releases its model while
menus, death/observer views or intermission overlays cover gameplay. Reopening,
respawning and changing Hero/Soldier identity reset transient reactions and captions.
Models without facial flexes retain head/camera movement and full status text.

## Performance and implementation references

One retained DModelPanel per visible surface; cached bone/flex discovery on model
change; facial updates capped at 30 Hz; local state sampling at 10 Hz; wrapping
cached until text/viewport changes. Model rendering follows the normal HUD frame
rate. No new assets, render-target allocation or server messages. Reduced-effects
mode disables walking bob and rhythmic pant motion while retaining expressions
and readable status names. Actual FPS/GPU cost still requires Source measurement.

The implementation uses the documented [DModelPanel](https://wiki.facepunch.com/gmod/DModelPanel),
[manual painting](https://wiki.facepunch.com/gmod/Panel:PaintManual), and
[player animation-event](https://wiki.facepunch.com/gmod/GM:DoAnimationEvent)
interfaces. It never changes the player's world-model facial state.

## Evidence and next test

`python3 tools/test_checkpoint_g_integration.py`: **73/73 suites pass**. The new
production-client harness covers shared sheet/HUD identity, all simultaneous
conditions, future buff registration, damage priority/expiry, attack reactions,
fatigue, bob/reduced effects, cached model reuse, text width, menu reopening,
respawn/role transitions and missing model flexes. Existing wallet/equipment/enemy
and RPG regressions remain clean.

No Garry's Mod renderer is available in the headless test environment. During the
combined equipment/enemy playtest on `gm_flatgrass`, walk, fire, take damage and
check the portrait beside the current ailments. Compare its face to P/Character
Sheet and confirm the reduced-effects setting remains comfortable. A screenshot
or short clip is the useful evidence for framing, expression strength or overlap;
retain the normal console/summary logs if a Lua error occurs.
