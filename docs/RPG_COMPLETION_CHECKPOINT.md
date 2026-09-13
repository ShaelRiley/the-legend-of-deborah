# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-13
**Development branch:** `hybrid/antigravity`
**Accepted main reference:** `f7da934b33d250e4d7e032f6d66f404d0f80f4ac`
**Canonical GDD:** `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`  
**GDD revision:** `ANLCKQmjFx3fTZxP09CRHVOO_fgMiaXVXqAh6lf_by1mKt0ExbMSE6x7KN8nMl4VxCrNKupQ0i-Q_x77o7aZgX6sumGBgseGHr39gD8Y6Q`

## Current preservation point

Checkpoints A, B, C, and D are statically and deterministically complete; integrated Garry's Mod runtime acceptance remains pending.

### Checkpoint E — Human Soldier Queue Hardening & Authority Realignment (AG-007R2 Repair)

Task **AG-007R2** hardened the Soldier queue lifecycle and authority against canonical design laws:

- **Central Queue Eligibility Authority:** Established `RunManager:IsHeroRevivalQueueEligible(plyOrIdentity)` as the single central authority for queue eligibility. All same-dungeon revival selection (`Loot:_OldestEliminatedTeammate`) and revival execution (`RunManager:ReviveIdentity`) enforce this predicate.
- **ReturnToHeroQueue Safety:** `RunManager:ReturnToHeroQueue(ply)` explicitly rejects active Hero callers (`ps.lives > 0` and `not ps.eliminated`), mutating zero state. For active Soldiers or `SOLDIER_RESPAWN_WAIT`, it retires the Soldier, clears wait states, preserves original `ps.eliminatedSince`, and restores queue eligibility.
- **ReviveIdentity Invariant Enforcement:** `RunManager:ReviveIdentity(identity)` validates `IsHeroRevivalQueueEligible` before mutating any lives or elimination variables. Calling `ReviveIdentity` on an active Soldier or player in `SOLDIER_RESPAWN_WAIT` returns `false` without side effects (does not forcibly retire active Soldiers).
- **Canonical AI Soldier Authority:** Human-controlled Soldier RPG generation derives directly from `LOD.Config.Encounter.Archetypes.soldier` (`baseHP=35`, `model="models/combine_soldier.mdl"`), eliminating hardcoded surrogate values.
- **ESC Seam & Client UI:** Integrated `cl_soldier_queue_ui.lua` providing client prompt integration and backing concommand `"lod_soldier_return_hero_queue"`.
- **Validation & Runtime Status:** Headless deterministic validator `tools/test_human_soldier_lifecycle.lua` passes all AG-007R2 safety and invariant checks with 0 discrepancies. Genuine Garry's Mod engine runtime execution was **BLOCKED** headlessly due to missing host 32-bit system dependencies (`libgconf-2.so.4` required by Awesomium/client.so).

Checkpoint E remains **OPEN** pending remaining inventory-proxy item grab behavior and subsequent Checkpoint-E requirements.

## Next work

Await Checkpoint E inventory-proxy and subsequent directives from Sol.
