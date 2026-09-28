#!/usr/bin/env python3
"""Finite skeleton animation gate; reuse the canonical evidence runner."""
import test_checkpoint_g_integration as matrix

FILES = {
    "test_skeleton_animation.lua", "test_skeleton_hero.lua", "test_fallen_heroes.lua",
    "test_enemy_roster.lua", "test_enemy_update.lua", "validate_spot03_razor.lua",
    "test_event_skeleton_lifecycle.lua", "test_staging_event_spawn.lua",
    "test_hostile_death_handoff.lua", "test_bestiary_b29_dispatch.lua",
    "test_native_resource_lifecycle.lua", "test_monster_defenses.lua", "test_warden_health.lua",
}

if __name__ == "__main__":
    selected = [(name, command) for name, command in matrix.SUITES
                if name in {"Git Diff Check", "Lua Syntax Audit"}
                or any(part.rsplit("/", 1)[-1] in FILES for part in command)]
    covered = {part.rsplit("/", 1)[-1] for _, command in selected for part in command}
    assert FILES <= covered, f"Unregistered selected suites: {FILES - covered}"
    matrix.SUITES = selected
    print("SKELETON ANIMATION TARGETED REGRESSIONS (not the full repository matrix)", flush=True)
    raise SystemExit(matrix.main())
