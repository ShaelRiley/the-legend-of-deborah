# Performance source fixture parity repair — October 11

Parent: `f7353f2fd4fdb85794a39845c518446e1473c5e3` on `main`.
This checkpoint changes three test fixtures only. No game, renderer, AI,
installed source manifest, graphics preference, population, tuning, asset,
Workshop or public-server change is included. No native FPS improvement is claimed.

## Confirmed failure and bounded repair

The parent low-end CI failed at `test_performance_profile.lua:191`; complete
matrix CI failed its preflight and never ran its full integration matrix.
Both preflight failures were reproduced before editing:

- The client profile fixture supplied 17 hashes while production correctly
  required 19. Add equipment inventory and spellbook to the fixture. Verify all
  19 distinct sources, and reject missing manifest entries, mismatched hashes
  and missing mounted bytes separately for every source (57 negative cases).
- The installer fixture still expected 53 rows. The installer correctly writes
  58: the union of 54 population-observer and 19 client-capture sources. Check
  exact set equality, unique paths, reviewed consumer counts and every actual
  file hash. Reject all 58 individual omissions, duplicates, same-size path
  substitutions and a hash mismatch. Keep repeat-install, symlink, VR manifest,
  atomic-file and owned-child cleanup coverage.
- The first integration attempt then exposed the older B28 fixture, still
  supplying 48 population sources. Add its six missing sources: equipment
  inventory, spellbook, Magic progression/forms, identity perks and monster
  identity. Check 54 distinct sources and 162 per-source missing-manifest,
  missing-mounted and changed-mounted-byte cases. Preserve cached hashing,
  gameplay-purity, mixed/absent manifest, ring, gate and shutdown assertions.

Production verification remains strict and unchanged. The tests now describe
its actual contract rather than weakening the contract to fit stale fixtures.

CI evidence: [low-end failure](https://github.com/ShaelRiley/the-legend-of-deborah/actions/runs/38078887853)
and [complete-matrix preflight failure](https://github.com/ShaelRiley/the-legend-of-deborah/actions/runs/38078887823).

## Final validation

- Final native-boundary preflight: 8/8 checks, including 889 Lua syntax files.
- Final complete integration matrix: **319/319** on one frozen source snapshot.
- All 638 stdout/stderr hashes and 319 suite receipts independently verified.
- Source before/after SHA256:
  `86b852e73c7db42a1f63171cee5386786e565c123e50267dd8e79cd81f2480cb`.
- All 1,563 tracked game/Lua files match the parent; sound and bundled assets
  are also unchanged. Documentation/evidence packaging follows the gate, with
  every original frozen-source file rechecked afterward.

Commands:

```bash
python3 tools/run_lua54.py tools/test_performance_profile.lua
python3 tools/test_dev_population_manifest.py
python3 tools/run_lua54.py tools/test_bestiary_b28.lua
python3 tools/test_checkpoint_g_integration.py --workers 2 --suite-timeout 600 --output /tmp/lod-perf-repair-final-matrix
```

The archive retains exact preflight commands, final receipts, raw streams,
source/production manifests, patch and independent proof. It also retains the
original failures and the interrupted diagnostic attempt (65 completed receipts).
That diagnostic was stopped after identifying the shared stale fixture to avoid
repeating the entire expensive matrix. The third test edit landed shortly
before successful session interruption; the partial run is explicitly **not**
a frozen-source acceptance proof. Only the final complete run is claimed above.

## Native performance remains open

The latest native pair still observes 24.7637 unprofiled / 34.4209 profiled active
FPS on verified installed `db51ecc024472b6b273af7f55cece5bc7b843c63`. Movement,
combat, view and population changes prevent overhead or optimization attribution.
The largest inspected client row is generated geometry (7,407.158 ms over 3,794
calls); render-phase and server AI rows overlap and are not GPU measurements.
Existing exact-view, support, mesh and callback-preserving caches remain intact.

The next diagnostic stays the stationary pair in the current development plan;
this tests-only repair requires no game update. Native sustained traversal/combat
>=40 FPS, controls and unchanged appearance/gameplay are still unaccepted. See
[the native capture and exact next action](STEAM_DECK_20261010_PROFILE_PAIR_NATIVE.md).

[Complete repair evidence](PERFORMANCE_SOURCE_FIXTURES_20261011.tar.xz).

Archive: 270,100 bytes; SHA256
`a2ef59b6436d3a3ce22af012800ba5857b54dfadc86aa28e8a5689b2162a054e`.
All 1,183 archived files independently hash-verified.
