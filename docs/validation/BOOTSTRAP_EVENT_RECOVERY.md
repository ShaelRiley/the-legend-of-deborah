# Empty-map startup repair — 2026-09-28

Parent main: `019d445b76573b3b9d5f77a4c3b7a2df8c63be0e`.
The verified publication commit is identified in the delivery response.

## Reproduction and correction

The reported error was a complete-build rejection, surfaced by bootstrap's
`ErrorNoHalt`, rather than a missing map or disabled music dependency.
Campaign seed **31676**, level seed **1939356277**, reproduces
`event placement exhausted: skeleton_blockade: nil` with production progression
safety, Neil/Black Gate, Warden arena, arrival and encounter reservations loaded.
Its first progression-safe layout, attempt **9**, has **39** critical-path
cells and **zero** legal skeleton placements. Returning failure there prevented
RunManager from committing the maze and reaching staging's build wrapper.

RunManager now continues its existing deterministic layout stream after an
explicit event-placement rejection and complete cleanup. The existing global
64-layout ceiling includes earlier progression failures; it is not restarted.
Event count, identities and selection diagnostics are frozen across the logical
build. The reproduced campaign succeeds on layout **14** with the same
`skeleton_blockade,memory_terminal` selection. All safety proofs remain in force;
failed attempts do not release players or advance successful-build history.
Reported callback, graph-integrity and native-creation failures still reject
the build. Exhaustion now has a useful reason rather than a `nil` suffix.

## Source validation

- **33/33 selected suites passed; 806 Lua files passed syntax checks.**
- The new actual-startup regression executes InitPostEntity → bootstrap →
  NewCampaign → complete maze build → staging handoff. It also proves fixed
  selection/count, independent blockade reachability, deterministic regeneration,
  no history advance on failure, finite exhaustion, cleanup, native/callback
  failure classification and the existing operator event opt-out.
- **48/48 sampled full-rule dungeon builds succeeded.** This is a finite
  headless sample, not a guarantee about every seed or native engine behavior.
- The first gate was **32/33**. The old population test assumed that the whole
  build stopped after one layout's placement budget. It now injects failure on
  the final permitted progression layout and retains its exact 64-candidate,
  cleanup and unpublished-state assertions. The new regression separately
  verifies recovery across layouts and the global ceiling.
- An intermediate reproduction exposed a fixture wrapper dropping the new
  third return value. The wrapper now preserves the production retry marker.

Final source snapshot before/after the gate:
`acb7239cea036e9747fdf10fb2e71ff0912da8232290898f60b5d1711586ad6f`.
No production or test sources changed afterward; only this evidence was added.
This is the finite targeted gate, not the full campaign-wide registry.

Retained [receipt](bootstrap_event_recovery/receipt.json),
[sample facts](bootstrap_event_recovery/samples.json), and
[evidence archive](bootstrap_event_recovery/evidence.zip) include original
reproduction/failure logs, both gates and the sample scripts/logs.
Archive SHA-256:
`3f0569972ea59b63288a0ddbfd81ff9af41672de95207104543be63b5db12ffb`.

Reproduce the gate:

```bash
python3 tools/test_bootstrap_gate.py --output /tmp/lod-bootstrap-gate --workers 4 --suite-timeout 120
```

## Native acceptance still required

Fully quit GMod, update/install main using `docs/DEVELOPMENT_WORKFLOW.md`, then
start The Legend of Deborah on `gm_flatgrass`. Confirm staging appears, normal
portal deployment works and the maze is populated. The automated fixture doubles
Source entities/traces and native staging-room discovery; it cannot certify
Source rendering, physics or the installed addon. Keep `console_latest.txt` and
`rpg_summary_latest.txt` if any failure remains. No Workshop publication or VPS
deployment is included. Previous music, low-end and release gates remain open.
