# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-12
**Development branch:** `hybrid/antigravity`
**Accepted main reference:** `f7da934b33d250e4d7e032f6d66f404d0f80f4ac`
**Canonical GDD:** `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`  
**GDD revision:** `ANLCKQmjFx3fTZxP09CRHVOO_fgMiaXVXqAh6lf_by1mKt0ExbMSE6x7KN8nMl4VxCrNKupQ0i-Q_x77o7aZgX6sumGBgseGHr39gD8Y6Q`

## Current preservation point

Checkpoints A, B, C, and D are statically and deterministically complete; integrated Garry's Mod runtime acceptance remains pending.

### Checkpoint E — Human Soldier Lifecycle & Queue Realignment (AG-007R Repair)

Task **AG-007R** successfully repaired AG-007 against canonical Phase-20 design laws:

- **Hero Queue vs. Active Soldier Distinction:** Reaching 0 Hero lives enters the player into `RETURN_TO_HERO_QUEUE` (restricted spectator) without auto-attaching a Soldier. Becoming an active Soldier requires explicit action (`RunManager:JoinSoldierRole` / `lod_join_human_soldier`).
- **Hero State Isolation:** Playing as a Soldier does not mutate Hero XP, level, lives, feats, spells, Form Magic, or original elimination timestamp.
- **Revival Exclusion & Missed Revivals:** Active Soldier controllers are excluded from same-dungeon Extra Life revival (`Loot:_OldestEliminatedTeammate` skips active Soldiers). Revivals occurring during active Soldier control are missed (not banked) and do not forcibly eject the Soldier.
- **Return to Hero Queue:** Canonical `RunManager:ReturnToHeroQueue(ply)` / `lod_return_to_hero_queue` action retires/despawns the active Soldier, frees the Soldier slot, discards incarnation-local Soldier progress, returns the player to restricted Hero spectating, preserves the original `ps.eliminatedSince` timestamp, and restores future revival eligibility.
- **Overflow Revival Selection:** `Loot:_OldestEliminatedTeammate` selects the oldest eligible eliminated Hero in the queue using `ps.eliminatedSince` with deterministic ordinal tie-break. Removed stale non-Hero fallback.
- **Soldier Death 20s Disposable Lifecycle:** Soldier death consumes 0 Hero lives, retires the Soldier incarnation, enforces an exact 20-second replacement delay (`ps.respawnAt = CurTime() + 20`), and attaches a fresh Soldier incarnation with 0 SoldierXP upon re-entry.
- **Production Queue Defect Fixed:** Repaired `RunManager:PromoteWaitingSpectators()` so promotion slots are consumed ONLY when an actual successful Hero restoration occurs.
- **Cooperative Party Wipe Integrity:** Active Human Soldiers do not prevent true cooperative party wipe evaluation when all Heroes are eliminated (`EvaluateWipe`).
- **Level Boundary Integration:** `AdvanceLevel()` retires all active Soldiers and applies canonical Hero comeback rules.
- **Deterministic & Fresh Runtime Validation:** `tools/test_human_soldier_lifecycle.lua` passes all 20 assertions (A thru T) with 0 discrepancies. Fresh Garry's Mod runtime evidence with marker `AG-007R` generated on `gm_flatgrass` and verified.

Checkpoint E remains **OPEN** pending remaining inventory-proxy item grab behavior and subsequent Checkpoint-E requirements.

## Next work

Await Checkpoint E inventory-proxy and subsequent directives from Sol.
