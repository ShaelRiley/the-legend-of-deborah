# The Legend of Deborah

**The Legend of Deborah** is a procedural cooperative survival-maze gamemode for Garry's Mod, developed and runtime-tested on `gm_flatgrass`.

Current baseline: **Shael-approved RPG candidate on main**, promoted from `87920e5ba3b27d46ff096f5a85cd41030a77f964` on 2026-09-14. Astra / Work leads implementation; Sol complements review, architecture, planning and bounded implementation. Antigravity and the hybrid workflow are retired. See [current status](docs/DEVELOPMENT_STATUS.md), [development plan](docs/DEVELOPMENT_PLAN.md), and [workflow](docs/DEVELOPMENT_WORKFLOW.md). Public-server and Workshop deployment remain separate from this promotion.

The [Game Design Document](https://docs.google.com/document/d/1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY/edit) is the design authority. This repository's `main` branch is the implementation authority.

<details>
<summary>Historical pre-RPG implementation and optimization checkpoint</summary>

The following records the former Milestone 3 baseline, not current RPG scope or acceptance.

## Implemented and runtime-validated

- Deterministic multi-floor labyrinth generation, visible floors, walls, stairs, and static collision.
- Three-keycard progression through red, blue, and yellow security gates.
- Encounter and wandering-hostile systems with Shamblers, Runners, Soldiers, Deadcrabs, and Bio Blasters.
- Motion V2 graph-authoritative hostile locomotion and stair traversal.
- Player firearms, shotgun pellets, hostile melee, Soldier bursts, Bio Blaster projectiles, hit feedback, and generated-cover blocking.
- On-request chunked minimap networking with live gate-aware reachability.
- Lives, death presentation, respawn countdown, developer acceleration, and placeholder loot lifecycle.
- Procedural midnight sky and the production loading screen.

Placeholder loot remains deliberately inert pending the GDD's production loot/economy milestone.

## Low-end optimization checkpoint

Validated Steam Deck baseline before wall optimization:

| Metric | Baseline |
| --- | ---: |
| Generation | 0.142 s |
| Geometry | 4.010 s |
| Total | 4.152 s |
| Server entities | 2,861 |

Observed after the wall architecture replacement:

| Metric | Optimized |
| --- | ---: |
| Geometry | ~0.335 s |
| Total | ~0.770 s |
| Server entities | ~865 |

The optimized renderer uses merged authoritative server collision, a compressed wall manifest, and approximately 1,600–1,800 batched client-only container models.

Additional completed optimizations:

- Placeholder loot expires after 20 seconds, is capped at 24 markers, and uses one cleanup timer.
- Missed bullets use bounded candidate queries instead of scanning every hostile.
- Enemy bolts avoid their secondary ray query unless near a player.
- Generated-cover decisions are cached per damage event.
- Wanderer target and route refreshes use deterministic phase offsets.
- Invariant Motion V2 suppression setters are cached.
- Five recurring hostile scans share the authoritative hostile registry.
- Per-hit damage-audit formatting is opt-in and disabled by default.
- Open-minimap reachability, routes, floor indexing, and canonical serialization are cached.
- Hostile deaths share one adaptive scheduler instead of ten timers per death.
- Distant gate bodies, keycards, and unreadable progression labels are culled.
- Developer modules default off in production; the infinite-ammo testkit timer exists only while armed.

</details>

## Developer mode

Developer tools are disabled by default on a fresh installation. Set `lod_developer_mode 1` and fully restart GMod to load the server audit/test modules. Existing archived development installations retain their saved value.

Frequently used focused diagnostics:

| Command | Purpose |
| --- | --- |
| `lod_phase0_perf` | Phase Zero cache and registry counters |
| `lod_placeholder_loot_status` | Placeholder marker cap and lifetime |
| `lod_saverestore_status` | Transient combat-state save exclusions |
| `lod_wander_schedule_status` | Wanderer target/route phase distribution |
| `lod_motion_suppression_status` | Cached Motion V2 suppression setters |
| `lod_m3_damage_audit_status` | Damage-audit production state |
| `lod_hostile_registry_status` | Registry parity and consolidated hot hooks |
| `lod_minimap_cache_status` | Client minimap BFS/cache reuse |
| `lod_death_scheduler_status` | Shared death scheduler state |
| `lod_progression_render_status` | Gate/keycard draw and cull counts |
| `lod_developer_tools_status` | Release default, module gating, and testkit hook state |

Some composite `lod_m1_audit` floor-support or wall-top failures are known diagnostic false positives. Visible geometry, collision, traversal, focused diagnostics, and Lua errors remain authoritative.

## Runtime workflow

After pulling a code change, fully quit GMod before relaunching; Lua hot reload is not an authoritative test path.

```bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin main && git switch main && git pull --ff-only origin main && bash tools/install_dev.sh
```

The required development map is `gm_flatgrass`.
