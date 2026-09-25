#!/usr/bin/env python3
"""Frozen, finite B29 regression gate. Not the complete canonical matrix.

Writes receipts outside the checkout by default. A failed invocation is retained;
use a different --output directory for a rerun. No gameplay files are generated.
"""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time

from test_checkpoint_g_integration import REPO_ROOT, SUITES

ROOT = Path(REPO_ROOT)
EXTRA = [
    "Bestiary B29 Full Build & Opening Safety",
    "Bestiary B29 Native Dispatch & Withdrawal",
    "Bestiary B29 Bilateral Combat Seams",
    "September 22 Navigation Recovery",
    "Watcher Scan Dispatch",
    "Protected: Dev Ingress",
    "Release Include & Registration Wiring",
    "Canonical Manual & Portable Menu",
    "Canonical Manual Server Transport",
    "Manual Source & Reader Navigation",
    "Dungeon Transition Inventory",
    "Human Soldier RPG & XP Progression",
    "Human Soldier Lifecycle & Isolation",
    "Shared Native DamageInfo Lifetime",
    "Hector Encounter, Native Death & Level-20 Rescue Gate",
    "Hector Canonical Actor Health & Defenses",
    "Bestiary B3 Flank Pursuit & Production Progression",
    "Bestiary B11 Perception & Exact Lifetimes",
    "Great Crate Stock Gates & Lifecycle",
    "Damsel Campaign & Endless Progression",
]

def snapshot() -> dict[str, str]:
    rows = {}
    for directory in ("gamemodes", "lua", "tools", "materials", "models", "sound", "docs/manual"):
        for p in sorted((ROOT / directory).rglob("*")):
            if p.is_file() and "__pycache__" not in p.parts and p.suffix != ".pyc":
                rows[p.relative_to(ROOT).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    return rows

def digest(rows: dict[str, str]) -> str:
    return hashlib.sha256("".join(f"{k}\t{rows[k]}\n" for k in sorted(rows)).encode()).hexdigest()

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT.parent / "b29-evidence")
    parser.add_argument("--jobs", type=int, default=3, choices=range(1, 5))
    args = parser.parse_args()
    out = args.output.resolve()
    if out.exists() and any(out.iterdir()):
        parser.error("Output directory is not empty; preserve it and choose a new directory.")
    out.mkdir(parents=True, exist_ok=True)
    canonical = dict(SUITES)
    prior = json.loads((ROOT / "docs/validation/BESTIARY_B28_CHECKS.json").read_text())
    commands = []
    for record in prior["checks"]:
        commands.append((record["name"], canonical[record["name"]] if record["name"] in canonical else record["command"]))
    for name in EXTRA:
        if name not in canonical:
            raise RuntimeError(f"Missing canonical suite: {name}")
        if name not in {n for n, _ in commands}:
            commands.append((name, canonical[name]))
    before = snapshot()
    (out / "source_manifest.json").write_text(json.dumps(before, indent=2) + "\n")
    def run(item: tuple[int, tuple[str, list[str]]]) -> dict:
        ordinal, (name, command) = item
        stem = f"{ordinal:02d}-" + re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
        started = time.monotonic()
        try:
            result = subprocess.run(command, cwd=ROOT, capture_output=True, timeout=420, check=False)
            stdout, stderr, code = result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired as exc:
            stdout, stderr, code = exc.stdout or b"", (exc.stderr or b"") + b"\nTIMEOUT: 420 seconds\n", 124
        (out / (stem + ".stdout.txt")).write_bytes(stdout)
        (out / (stem + ".stderr.txt")).write_bytes(stderr)
        row = dict(ordinal=ordinal, name=name, command=command, returncode=code,
                   seconds=round(time.monotonic()-started, 3),
                   stdout_sha256=hashlib.sha256(stdout).hexdigest(),
                   stderr_sha256=hashlib.sha256(stderr).hexdigest(), log_prefix=stem)
        print(f"{'PASS' if code == 0 else 'FAIL'} {ordinal}/{len(commands)} {name} ({row['seconds']}s)", flush=True)
        return row
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = [pool.submit(run, item) for item in enumerate(commands, 1)]
        for future in as_completed(futures):
            results.append(future.result())
    after = snapshot()
    changed = sorted(k for k in before.keys() | after.keys() if before.get(k) != after.get(k))
    report = dict(baseline="fc8951840a69e52a0dd4d73ac309480a9b958b98",
                  scope="frozen selected regression gate; native boundaries doubled; not the full canonical matrix",
                  registered_canonical_checks=len(SUITES), selected_checks=len(commands),
                  passed=sum(r['returncode'] == 0 for r in results),
                  failed=sum(r['returncode'] != 0 for r in results),
                  frozen_gameplay_asset_tool_manual_files=len(before),
                  source_snapshot_sha256=digest(before), after_snapshot_sha256=digest(after),
                  changed_during_gate=changed, checks=sorted(results, key=lambda r: r['ordinal']))
    (out / "BESTIARY_B29_CHECKS.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k:v for k,v in report.items() if k != "checks"}, indent=2), flush=True)
    return 1 if report['failed'] or changed else 0

if __name__ == "__main__":
    sys.exit(main())
