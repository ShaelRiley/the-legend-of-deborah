# Sol stabilization checkpoint

This branch was created as a Sol-owned stabilization line directly above accepted `main` (`26dae92ac9f920447886fdd9f2e4bda5b8590424`) after removing Antigravity/Gemini from the active implementation loop.

## Accepted stabilization scope

- Universal Deadeye preserves stable feat ID `DEX_MAGNUM_DEADEYE`, requires DEX 15, uses the shared 0.50-second Aim hold, applies x2 to ordinary supported weapon transactions and x3 to Magnum transactions, and preserves one-transaction consumption/cancellation semantics.
- Development installation quarantines the known stale `ag002re_test.lua` runtime autorun contaminant, removes its phase marker, and enables developer tools through the dev-checkout marker rather than launch-option mutation.
- Bio Blaster live hostile instances receive the canonical stored-class dispatcher through the narrow runtime bridge.
- `tools/export_current_evidence.sh` validates the console mirror, verifies current RPG marker evidence, and exports physical evidence files to a deterministic Downloads directory.

## Runtime acceptance — 2026-09-10

Accepted on `gm_flatgrass` from the clean Sol stabilization build.

- Human Deadeye behavior gate: PASS across baseline Pistol/Magnum and Deadeye Crowbar, Pistol, Magnum, SMG, Shotgun, AR2, and Frag semantics.
- `lod_deadeye_aim_validate`: PASS; definition reports DEX 15, hold 0.50, ordinary x2, Magnum x3, universal Aim authority.
- `lod_rpg_validate`: PASS.
- Current RPG summary/session contain `sol_deadeye_stable` and `TEST_END sol_deadeye_stable` markers with repeated RPG validation PASS.
- Developer tools: PASS (`default=0 enabled=true toolsLoaded=true modules=8`).
- Bio Blaster dispatch bridge: PASS (`canonical=true live=3 bridged=3`).
- No recurrence of the prior `_RunBioBlasterTick` nil-method runtime error was observed.

**Stabilization disposition: PASS. Safe for fast-forward promotion to `main` after final diff/bookkeeping review.**
