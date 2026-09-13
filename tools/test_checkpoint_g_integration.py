#!/usr/bin/env python3
import os
import subprocess
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def get_lua_files():
    lua_files = []
    for dirpath in ["gamemodes", "lua", "tools"]:
        abs_dir = os.path.join(REPO_ROOT, dirpath)
        if os.path.exists(abs_dir):
            for root, _, files in os.walk(abs_dir):
                for f in files:
                    if f.endswith(".lua"):
                        lua_files.append(os.path.relpath(os.path.join(root, f), REPO_ROOT))
    return sorted(lua_files)

LUA_FILES = get_lua_files()

SUITES = [
    ("Git Diff Check", ["git", "diff", "--check"]),
    ("Lua Syntax Audit", ["python3", "tools/run_lua54.py", "--syntax"] + LUA_FILES),
    ("Checkpoint C Python Validator", ["python3", "tools/validate_checkpoint_c.py"]),
    ("Actor Core & Level Progression", ["python3", "tools/run_lua54.py", "tools/test_actor_progression.lua"]),
    ("Magic Forms & Contents Schema", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_c_headless.lua", "."]),
    ("Feats & Capstones Closure (124+9)", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_d_closure.lua"]),
    ("Human Soldier RPG & XP Progression", ["python3", "tools/run_lua54.py", "tools/test_human_soldier_progression.lua"]),
    ("Human Soldier Lifecycle & Isolation", ["python3", "tools/run_lua54.py", "tools/test_human_soldier_lifecycle.lua"]),
    ("Checkpoint E Closure & Parity", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_e_closure.lua"]),
    ("Soldier P-Sheet & Renderer Contract", ["python3", "tools/run_lua54.py", "tools/test_soldier_character_sheet.lua"]),
    ("Checkpoint F Run-End & Leaderboard", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_f_closure.lua"]),
    ("Status & Element Matrix", ["python3", "tools/run_lua54.py", "tools/test_status_elements.lua"]),
    ("Protected: Deadeye Stabilization", ["python3", "tools/run_lua54.py", "tools/test_deadeye_stabilization.lua"]),
    ("Protected: Crowbar Mechanics", ["python3", "tools/run_lua54.py", "tools/test_gate_e_crowbar.lua"]),
    ("Protected: Pusher Feat & Impulse", ["python3", "tools/run_lua54.py", "tools/test_gate_e_pusher.lua"]),
    ("Protected: Map Movement & Navigation", ["python3", "tools/run_lua54.py", "tools/test_map_movement.lua"]),
    ("Protected: Quantum Cost Seam", ["python3", "tools/run_lua54.py", "tools/test_quantum.lua"]),
    ("Protected: Strafe Movement", ["python3", "tools/run_lua54.py", "tools/test_strafe.lua"]),
    ("Protected: Backpedal Movement", ["python3", "tools/run_lua54.py", "tools/test_backpedal.lua"]),
    ("Protected: Winning Personality", ["python3", "tools/run_lua54.py", "tools/test_winning_personality.lua"]),
    ("Protected: Deadcrab Dispatch", ["python3", "tools/run_lua54.py", "tools/test_deadcrab_dispatch.lua"]),
    ("Protected: Dev Ingress", ["python3", "tools/run_lua54.py", "tools/test_dev_ingress.lua"]),
    ("Protected: Control Magic", ["python3", "tools/run_lua54.py", "tools/test_gate_e_control_magic.lua"]),
    ("Protected: Magic Recovery", ["python3", "tools/run_lua54.py", "tools/test_gate_e_magic_recovery.lua"]),
    ("Protected: Behavioral Regressions Gate", ["python3", "tools/run_lua54.py", "tools/test_checkpoint_g_protected_regressions.lua"]),
]

def main():
    print("=== CHECKPOINT G INTEGRATED AUTOMATED RPG VALIDATION GATE ===")
    print(f"Repository Root: {REPO_ROOT}")
    print(f"Registered Test Suites: {len(SUITES)}\n")

    results = []
    failed_any = False

    for idx, (name, cmd) in enumerate(SUITES, 1):
        res = subprocess.run(cmd, cwd=REPO_ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        passed = (res.returncode == 0)
        status_str = "PASS" if passed else "FAIL"
        results.append((idx, name, status_str, res.returncode, res.stdout, res.stderr))
        print(f"[{status_str}] {idx:2d}/{len(SUITES)} - {name}")
        if not passed:
            failed_any = True
            print(f"  --> ERROR output for '{name}':")
            if res.stdout:
                print("STDOUT:\n" + res.stdout.strip())
            if res.stderr:
                print("STDERR:\n" + res.stderr.strip())
            print("-" * 60)

    print("\n" + "=" * 60)
    print("CHECKPOINT G SUITE MATRIX SUMMARY:")
    print("=" * 60)
    for idx, name, status_str, code, _, _ in results:
        print(f"  [{status_str}] {idx:2d}. {name:<45} (exit code {code})")
    print("=" * 60)

    if failed_any:
        print("\n[FAIL] CHECKPOINT_G_AUTOMATED_GATE_FAILED — One or more test suites failed.")
        sys.exit(1)
    else:
        print(f"\nCHECKPOINT_G_AUTOMATED_GATE_PASS — All {len(SUITES)} test suites verified cleanly with 0 failures.")
        sys.exit(0)

if __name__ == "__main__":
    main()
