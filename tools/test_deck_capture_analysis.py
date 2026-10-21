"""Synthetic acceptance negatives, not Steam Deck performance evidence."""
import copy
import unittest

from analyze_deck_capture import analyze as check_capture, metrics


def analyze(report, mode="uncapped"):
    return check_capture(report, mode, expected_commit="synthetic-test-sha")


def fixture(samples):
    ranges = [{"first": 1, "last": len(samples)}]
    m = metrics(samples, ranges)
    config = {"width": 1280, "height": 800, "map": "gm_flatgrass", "fps_max": "300",
              "mat_vsync": "0", "lod_wall_batches": "0"}
    return {"reason": "complete", "source": {"verified": True}, "active": m,
            "start_resources": {"install": "synthetic-test-sha clean"},
            "end_resources": {"install": "synthetic-test-sha clean"},
            "start_configuration": config, "end_configuration": config.copy(),
            "configuration_changes": [],
            "frame_timeline": {"version": "ordered-pre-render-20261021", "samples_ms": samples,
                               "active_ranges": ranges, "trailing_unrendered_ms": 1}}


class EvidenceTests(unittest.TestCase):
    def test_two_second_failure_hidden_by_good_percentiles(self):
        report = fixture([10] * 18000 + [100] * 20)
        result = analyze(report)
        self.assertLess(result["active"]["p99_ms"], 31)
        self.assertGreater(result["active"]["fps"], 40)
        self.assertFalse(result["capture_checks_passed"])
        self.assertEqual(result["active"]["below_budget_runs_ge2s"], 1)

    def test_inactive_gaps_do_not_join_drops(self):
        m = metrics([900, 5000, 1100, 25], [{"first": 1, "last": 1}, {"first": 3, "last": 4}])
        self.assertEqual(m["longest_below_budget_seconds"], 1.1)
        self.assertEqual(m["below_budget_runs_ge2s"], 0)
        self.assertAlmostEqual(m["one_percent_low_fps"], 1000 / 1100)

    def test_fixed_cap_tolerance_separate_from_uncapped(self):
        report = fixture([25.1] * 7200)
        self.assertFalse(analyze(report)["capture_checks_passed"])
        report["start_configuration"]["fps_max"] = "40"
        report["end_configuration"]["fps_max"] = "40"
        self.assertTrue(analyze(report, "capped40")["capture_checks_passed"])
        bad = fixture([25.3] * 7200)
        self.assertFalse(analyze(bad, "capped40")["capture_checks_passed"])

    def test_fast_capture_still_requires_valid_evidence(self):
        report = fixture([18.5] * 10000)
        self.assertTrue(analyze(report)["capture_checks_passed"])
        changes = [lambda r: r.update(reason="shutdown"),
                   lambda r: r.update(cpu_profile={"client": {}}),
                   lambda r: r["source"].update(verified=False),
                   lambda r: r["start_resources"].update(install="other-sha clean"),
                   lambda r: r["end_resources"].update(install="synthetic-test-sha modified"),
                   lambda r: r["frame_timeline"].update(trailing_unrendered_ms=3000),
                   lambda r: r["end_configuration"].update(width=640),
                   lambda r: r["active"].update(p99_ms=1),
                   lambda r: r["start_configuration"].update(fps_max="60")]
        for change in changes:
            bad = copy.deepcopy(report)
            change(bad)
            self.assertFalse(analyze(bad)["capture_checks_passed"])
        self.assertFalse(analyze(fixture([10] * 100))["capture_checks_passed"])

    def test_invalid_timeline_is_not_accepted(self):
        for values in ([float("nan")], [0], [-25], [], [True]):
            with self.assertRaises(ValueError):
                analyze(fixture(values) if values and values[0] != 0 else {"frame_timeline": {
                    "version": "ordered-pre-render-20261021", "samples_ms": values, "active_ranges": []}})
        for ranges in ([{"first": 2, "last": 1}], [{"first": 1, "last": 2}, {"first": 2, "last": 3}]):
            with self.assertRaises(ValueError):
                metrics([10, 10, 10], ranges)
        with self.assertRaises(ValueError):
            analyze({"active": {"fps": 100}})


if __name__ == "__main__":
    unittest.main()
