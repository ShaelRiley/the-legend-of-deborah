# Music folder catalog checkpoint

Base: verified `main` `79faf3dccf4838ca306a25b0d4688f92af6fdaf7`.
The current author request specifies Chill = Tension 1, Tensions 2–4, Boss,
Fanfare, first-block defaults, simple block folders/ZIP and offline cue generation.

## Implementation

- `folder_catalog.py` prepares a complete folder/ZIP snapshot through the existing
  validator, immutable media/chunk store and game-data mirror. Natural folder
  order chooses the complete six-role default. Missing roles inherit; Chill also
  serves INTERLUDE. Legacy wire keys and legacy catalog ingestion remain compatible.
- `lod_music_catalog.py` saves VPS paths once, then provides import, check,
  rebuild-cues and status. Content-based versions and source fingerprints avoid
  repeated analysis. Rebuild retains authored overrides. Shared audio hashes
  retain consistent metadata and bounded media delivery.
- Complete batch validation precedes catalog replacement; unsafe archives,
  corrupt/unsuitable recordings and saved-set loss fail without publishing a
  partial library. Concurrent revision changes reject at commit. Immutable old
  files remain for frozen plans. Whole-library imports replace legacy profiles.
- Runtime validation requires ready cues/chunks for folder catalogs and resolves
  custom → first-block default without profile interference. Existing universal
  switches, server/client Off, lifecycle, mixing and Die Logger authorities remain.
- Published chunk and audio directories explicitly permit the nginx worker to
  traverse/read public media; private staging and operator configuration are not
  made public. This repairs TemporaryDirectory's inherited 0700 mode.
- Player manual and generated readers document the new terminology/defaults.
  `docs/MUSIC_FOLDER_IMPORT.md` contains the exact layout and operating commands.

## Finite evidence

Final `tools/test_music_gate.py --workers 4 --suite-timeout 120`: **41/41 selected
suites**, including **813 Lua syntax checks**, with no source changes during the
gate. `MUSIC_FOLDER_CHECKS.json` retains the source fingerprints and log hashes.
This is the existing bounded music/regression gate, not the full campaign matrix.

The new real-audio suite passes **80 assertions**, plus a production-Lua harness
against its actual generated catalog. It covers natural folder ordering, all-six
defaults, aliases, empty/partial later blocks, compact analyzed cues, exact chunks,
public-file permissions, idempotent folder/ZIP reimport, cue rebuild/authored
overrides, immutable old versions, catalog mirrors, invalid media and pulse class,
missing first-block roles, malicious archives, links, duplicates, size bounds,
saved-set loss, inferred non-default tempo and the documented command interface.
Production Lua proves every-role fallback, universal switches, Chill aliasing,
frozen cue snapshots, required offline readiness and default-Off server behavior.
The original ingestion, section analysis, mixer, transitions, media/resource,
player-options, boss/Hector/rescue, timeout, logging and manual regressions pass.

Attempts: the first focused run failed shared-hash metadata consistency because
subthreshold codec ripple in a quiet pad was treated as timing evidence. Grid
inference now excludes those subthreshold attacks and reuses established timing
for identical shared recordings. The next focused run passed 68 assertions; the
first aggregate passed 41/41. Final review found the concrete nginx directory
permission defect; the final aggregate above includes that repair and 12 new
public-permission assertions. Intentional malformed-media/duplicate-ZIP messages
in passing logs are rejection fixtures, not suppressed failures.

## Design and remaining gates

Live GDD was read through 00 → 01 → music rules in 05/06/07. The narrowly scoped
author-revision write failed with Google Docs HTTP 400 FAILED_PRECONDITION.
`MUSIC_FOLDER_GDD_AMENDMENTS.json` preserves the exact unapplied amendments.
The explicit current author instruction governs this checkpoint; the live GDD
is not claimed synchronized.

No actual author recordings or public HTTPS origin were supplied/configured here.
This checkpoint is source plus static/offline validation, not native audio,
network/Steam Deck performance acceptance, Workshop publication or VPS deployment.
Next: provision the HTTPS origin, import the complete library before a new
campaign, install the exact source locally and listen through staging, deployment,
stairs, boss, rescue fanfare and Chill. Capture `console_latest.txt` and
`rpg_summary_latest.txt`, with music status diagnostics if a transition fails.
Preserve local acceptance → Workshop package parity → matching VPS release order.
