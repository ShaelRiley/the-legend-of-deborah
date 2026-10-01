# MS2 resource and lifecycle budgets

MS2 replaces MS1's continuous audio delivery/cache/decoder work with local note scheduling. Score metadata uses the existing paced, permission-gated server channel; audio never crosses it. The 3.2 MB uncompressed event/engine bank is ordinary game content, not streamed media. The Source-native fallback bank is 89,466 bytes.

| Resource | Bound / policy |
| --- | --- |
| Desired floor layers | Two; one shared beat grid, reversible gain weights. |
| Retiring layers | Two newest tails; ordinary retirement 1.2 seconds. Older excess layers receive a short soft release. |
| Web Audio note voices | 24 admitted at musical event time; 16 reduced quality, plus short releases and at most four tonal bridges. |
| Per-lane instrument voices | Acid 1, industrial 3, strings 3, brass 2, bass 1, tom 2, snare 1, kick 1, hat 1. |
| Web scheduling | 25 ms tick, 650 ms lookahead, at most 2,048 queued events. |
| Tempo grid | Quarter-note anchors, twelve seconds planned ahead; fewer than 40 anchors in normal use. |
| Note pages / arrangements | Eight-page and four-arrangement Lua LRUs; JavaScript prunes unreferenced arrangement data. |
| Clip / arrangement admission | At most 2,048 notes per clip and 256 clips per arrangement. Core maximum is 274 notes per clip. |
| Native scheduling | At most 1,024 queued attacks, 512 per bridge batch, 64 admissions per game frame; discard attacks over 150 ms late. |
| Native sound identifiers | Fixed reusable slots per instrument/open-hat plus one bridge identifier per catalog block; never allocate a sound ID per note/phrase. |
| Native active notes | At most 24, or 16 reduced quality, plus bridges and short release tails. |
| Server metadata | At most 4 KiB per music tick globally; plan pieces at most 1 KiB; existing 0.5 ms service budget. |
| Frame pressure | Smoothed frame time over 35 ms selects reduced orchestration; recover after five stable seconds. Playback continues. |
| Permission/zero volume | Dispose DHTML, voices, event queues, page/arrangement payloads and music demand; retain saved preferences and spent victory receipts. |

Pitch/dynamics lifts are limited to confirmed critical combat. Tempo slews at at most 0.3% of base BPM per second and caps at +6%. Fills replace occupied rhythmic slots rather than stacking another kit. Global note limits release a quieter optional voice while favoring bass/kick foundation. Closed hats choke open hats.

The primary path reuses periodic waves and five percussion buffers. It performs no runtime FFT, waveform scan, MIDI decode, sample-by-sample JavaScript mix or network request. AudioNode cleanup follows source endings; stopping disconnects lanes and closes the owned context. Native fallback reuses finite generated samples and Source patches; only a bounded due queue runs per frame. Late notes never become a catch-up burst.

A quiet D bridge and release tails maintain continuity while normal sequencing joins phrases and musical roles. A truly stalled scheduler resynchronizes to a future grid point while retaining that bridge. Resource-reduction behavior is covered by the source gate and actual offline audio renderer. These bounds do not establish Steam Deck FPS or Source/DHTML runtime audibility; the native listening gate remains open.
