#!/usr/bin/env python3
"""Check one ordered LOD capture. This does not certify device/scenario coverage."""
import argparse
import json
import math
from pathlib import Path


def read_capture(path):
    text = Path(path).read_text(encoding="utf-8")
    start = 0 if text.startswith("{") else text.find("\n{") + 1
    if start == 0 and not text.startswith("{"):
        raise ValueError("capture has no JSON report")
    return json.loads(text[start:])


def metrics(samples, ranges, budget_ms=25):
    selected = []
    longest = slow_ms = 0.0
    prolonged = 0
    previous = 0
    for segment in ranges:
        first, last = segment["first"], segment["last"]
        if (type(first) is not int or type(last) is not int
                or not previous < first <= last <= len(samples)):
            raise ValueError("invalid, overlapping or unordered active ranges")
        previous = last
        run = 0.0
        for ms in samples[first - 1:last]:
            selected.append(ms)
            if ms > budget_ms:
                slow_ms += ms
                run += ms
                longest = max(longest, run)
            else:
                prolonged += run >= 2000 - 1e-6
                run = 0
        prolonged += run >= 2000 - 1e-6
    if not selected:
        raise ValueError("no active frames")
    ordered = sorted(selected)
    count = len(ordered)
    tail_count = math.ceil(count * .01)
    total = math.fsum(ordered)
    return {
        "frames": count, "seconds": total / 1000, "fps": count * 1000 / total,
        "median_ms": ordered[math.ceil(count * .5) - 1],
        "p95_ms": ordered[math.ceil(count * .95) - 1],
        "p99_ms": ordered[math.ceil(count * .99) - 1], "max_ms": ordered[-1],
        "one_percent_low_fps": 1000 * tail_count / math.fsum(ordered[-tail_count:]),
        "below_budget_seconds": slow_ms / 1000,
        "longest_below_budget_seconds": longest / 1000,
        "below_budget_runs_ge2s": prolonged,
    }


def analyze(report, mode="uncapped", min_active_seconds=170, expected_commit=None):
    timeline = report.get("frame_timeline", {})
    if timeline.get("version") != "ordered-pre-render-20261021":
        raise ValueError("ordered frame evidence unavailable; old summaries cannot prove sustained FPS")
    samples = timeline.get("samples_ms")
    ranges = timeline.get("active_ranges")
    if not isinstance(samples, list) or not 1 <= len(samples) <= 65536:
        raise ValueError("invalid or unbounded frame timeline")
    if any(type(x) not in (int, float) or not math.isfinite(x) or x <= 0 for x in samples):
        raise ValueError("invalid frame interval")
    if not isinstance(ranges, list):
        raise ValueError("active ranges unavailable")
    tolerance = .25 if mode == "capped40" else 0
    budget = 25 + tolerance
    raw = metrics(samples, ranges)
    pacing = metrics(samples, ranges, budget)
    issues = []
    if report.get("reason") != "complete":
        issues.append("incomplete capture")
    if report.get("sample_limit_reached") or report.get("preparation_timed_out"):
        issues.append("sample limit or renderer preparation timeout")
    source = report.get("source", {})
    if source.get("verified") is not True or source.get("missing", 0) or source.get("mismatches", 0):
        issues.append("mounted source not verified")
    if "cpu_profile" in report or "comparison" in report:
        issues.append("profile/comparison run is diagnostic, not final gameplay acceptance")
    for name in ("start_resources", "end_resources"):
        install = report.get(name, {}).get("install", "").split()
        if not expected_commit or install != [expected_commit, "clean"]:
            issues.append("expected clean installed commit not verified: " + name)
    start = report.get("start_configuration", {})
    end = report.get("end_configuration", {})
    if report.get("configuration_changes") or start != end:
        issues.append("settings changed during capture")
    if (start.get("width"), start.get("height"), start.get("map")) != (1280, 800, "gm_flatgrass"):
        issues.append("wrong resolution or map")
    if str(start.get("mat_vsync")) != "0":
        issues.append("vsync enabled or unknown")
    try:
        limit = float(start["fps_max"])
    except (KeyError, TypeError, ValueError):
        limit = -1
    uncapped_limit = math.isfinite(limit) and (limit == 0 or limit >= 300)
    if not uncapped_limit and (mode == "uncapped" or limit != 40):
        issues.append("unverified frame limit for selected mode")
    if start.get("lod_wall_batches") != "0":
        issues.append("native cargo renderer not selected")
    tail = timeline.get("trailing_unrendered_ms")
    if type(tail) not in (int, float) or not math.isfinite(tail) or not 0 <= tail <= 31 + tolerance:
        issues.append("unrendered terminal interval exceeds spike budget or is unknown")
    if raw["seconds"] < min_active_seconds:
        issues.append("insufficient active gameplay duration")
    if raw["fps"] < 1000 / budget - 1e-9:
        issues.append("average FPS below budget")
    if raw["p95_ms"] > budget:
        issues.append("p95 exceeds frame budget")
    if raw["p99_ms"] > 31 + tolerance:
        issues.append("p99 exceeds spike budget")
    if pacing["below_budget_runs_ge2s"]:
        issues.append("continuous drop lasting at least two seconds")
    recorded = report.get("active", {})
    for key in ("frames", "fps", "median_ms", "p95_ms", "p99_ms", "one_percent_low_fps"):
        value = recorded.get(key)
        if type(value) not in (int, float) or not math.isfinite(value) or not math.isclose(value, raw[key], rel_tol=1e-7, abs_tol=1e-6):
            issues.append("recorded active summary disagrees with timeline: " + key)
    return {
        "mode": mode, "limiter_tolerance_ms": tolerance,
        "active": raw, "pacing_at_tolerated_budget": pacing,
        "capture_checks_passed": not issues, "issues": issues,
        "scope": "One capture only. Independently verify actual device/runtime, external limiter, exact build, warmup, frozen scenario, normal workload, regression observations and three repetitions of every required scenario. No hardware or whole-task acceptance is inferred.",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=Path)
    parser.add_argument("--mode", choices=("uncapped", "capped40"), default="uncapped")
    parser.add_argument("--min-active-seconds", type=float, default=170)
    parser.add_argument("--expected-commit", required=True, help="exact installed Git commit SHA")
    args = parser.parse_args()
    if not math.isfinite(args.min_active_seconds) or args.min_active_seconds <= 0:
        parser.error("minimum active seconds must be finite and positive")
    try:
        result = analyze(read_capture(args.capture), args.mode, args.min_active_seconds, args.expected_commit)
    except (ValueError, KeyError, TypeError, OSError) as exc:
        print(json.dumps({"capture_checks_passed": False, "error": str(exc)}, indent=2))
        return 2
    print(json.dumps(result, indent=2))
    return 0 if result["capture_checks_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
