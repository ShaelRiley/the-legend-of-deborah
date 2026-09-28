# Chill staging and music resource validation

Parent: `cdfcbb1ab8652109ba141c59b298fb03b68ae676` on
`ShaelRiley/the-legend-of-deborah`, `main`.

The final focused music gate passed **40/40 suites**, including all **805 Lua
syntax files**. This is the selected music/low-end/lifecycle regression gate,
not a rerun of the entire campaign-wide registry. The source did not change
during the gate; before/after digest:
`80cf641b3d67f52a47d7bea85cf2ee17b02726b12019b5de5584950f3f454fe8`.
Only validation records and explanatory documentation followed that run.

The first 40/40 gate is retained. Final follow-up checks additionally cover
failure-stop priority under congestion, explicit client-refresh resynchronization
and clearing failed media attempts on a new campaign. No assertions or inputs
were reduced to obtain a passing result. Prior section tests now exercise cached
native opens and the stricter declared PCM ceiling; quiet/pulse continuity,
entry rotation, spare-voice renewal and faded fallback assertions remain.

| Headless measurement: one steady voice, 120 frames in one second | Parent | Current |
| --- | ---: | ---: |
| Selection passes | 120 | 5 |
| Native volume writes | 120 | 0 |

The paired benchmark uses the actual parent/current client modules with the same
native boundary fixture. These are operation counts, not measured FPS or CPU
milliseconds. Media tests separately verify fixed chunk URLs and sizes, one
request in flight, paced/no-catch-up scheduling, deferred disk work, Off/On stale
callbacks, content verification, persistent cache validation, LRU eviction and
zero repeat downloads/hash scans/directory scans on warm reuse.

Server tests cover consent before selection, current Chill on re-enable, no
unchanged-state serialization/packets, one shared compression per plan, 1 KiB
plan pieces, budget exhaustion, packet-loss recovery and building-area Chill.
Client tests cover Chill fallback, 5 Hz steady selection/30 Hz gain limits,
zero volume, congestion, severe-overload release/recovery and bounded plan
assembly. Real ffmpeg/ffprobe ingestion verifies all seven role assets, exact
chunk reassembly, delivery preparation and frozen-metadata preservation.

Live GDD 05/06/07 amendments were applied and read back at revision
`ANLCKQmvX-ARcbbr5URtroKGNS9Fk5HkIQrIWaUGL4uxUqHAXMJTXW8xyB7bcBahans5m1NL0bzYUDQbolWk8KzWFzyg1s2wEUcVjd1lUw`.
The manual was regenerated and passed parity/document tests.

Evidence is in `music_performance/receipt.json`, `benchmark.json`,
`gdd-readback.json` and `evidence.zip`. The archive preserves both gates and the
paired benchmark scripts, baseline modules and logs. Archive SHA-256:
`060f2d7371847894af86acabc6237a75286ffd298ff57cafaf6b662c30008b5b`.

Native Garry's Mod/Steam Deck listening, memory, frame-time and network contention
remain untested. No actual hosted catalog was migrated; existing media needs
offline chunk preparation and a new campaign. No Workshop/VPS release occurred.
See `../MUSIC_PERFORMANCE.md` for the migration command and finite native gate.
