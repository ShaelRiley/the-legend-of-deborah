# VPS Multiplayer Playtest — 2026-09-01

## Result

**Core multiplayer smoke gate: ACCEPTED.**

Source evidence: `LOD Multiplayer Playtest 2026-09-01 20-35-02.mp4`, a roughly 22-minute live playtest captured against the public VPS-hosted Garry's Mod server on `gm_flatgrass`.

This footage predates the RPG overhaul, so it validates the multiplayer/world/progression foundation rather than the newer RPG-specific synchronization layer.

## What the footage demonstrates

- The Legend of Deborah is publicly reachable through Garry's Mod's Internet server browser and runs from the VPS.
- At least three human-controlled clients are concurrently present in the dungeon: the recording player's first-person client plus two independently moving/firing teammate models visible together in multiple scenes.
- Multiple players move through the generated maze simultaneously without obvious positional divergence or world-state disagreement.
- Cooperative combat occurs while teammates occupy the same and different nearby maze spaces.
- Shared progression advances coherently through the existing test-harness chain:
  - Red objective/gate state;
  - Blue keycard and Blue Gate;
  - Yellow keycard and Yellow Gate;
  - Jail Key / Deborah cell;
  - Deborah rescue.
- A shared objective transition is visible when the Blue keycard is recovered and the HUD advances to `OPEN BLUE GATE`.
- The personal map remains usable during multiplayer play.
- Different player weapons are visible in the session, including SMG/shotgun/crowbar use across the run.
- Deborah rescue completes once for the party and displays the common victory state while multiple teammates remain present.
- The intermission/Victory Tetris opportunity appears after rescue.
- The game proceeds into the next generated labyrinth and returns to the Red-key objective, demonstrating successful shared level-transition continuity.
- The captured end-of-session Problems panel reports `No Lua Errors reported so far`.

## Acceptance judgement

The footage is sufficient to retire the old blocker that required proof of basic real-client cooperative play before further feature development. The core world, shared progression, level-clear, and next-level pipeline have all been exercised in live network play with multiple simultaneous clients.

No defect visible in this footage justifies a code change to the current build. Because the footage is pre-RPG, altering current multiplayer code from this older evidence would create more risk than value.

## What this footage does not, by itself, prove

These remain hardening/regression scenarios rather than blockers to continued development:

- synchronization of the newer RPG character sheet, randomized abilities, feats, class mechanics, XP, Wizard Feedback, and other post-playtest RPG systems;
- reconnect before/after deployment;
- death/respawn while another player continues combat;
- fifth-player waiting/promotion semantics;
- four-active-client stress/soak;
- long dedicated-server churn;
- exhaustive proof of individualized loot/Magic/resource isolation.

The appropriate policy is therefore: **accept the multiplayer smoke foundation, continue RPG development, and run targeted multiplayer regression on the RPG layer before release rather than repeating the old pre-RPG gate as a prerequisite for every feature.**
