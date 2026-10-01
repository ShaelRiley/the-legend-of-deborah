# MS2 rendered playback budgets

Surge renders offline. Runtime work is metadata selection, local asynchronous phrase preparation, bounded frame-timed starts and channel gain. The server metadata channel remains paced and permission-gated; it transfers no audio. No whole-bank audio decode occurs at startup.

The runtime bank is **59,993,192 bytes (59.993 MB / 57.214 MiB)**. Its largest phrase is **63,852 bytes**; the mean is **42,770.21 bytes**. Maximum measured PCM peak is **0.620115**, and maximum decoded phrase peak is **0.609020**. No per-phrase normalization is used. Encoded/file/level values are authoritative in [MS2_SURGE_BANK.json](MS2_SURGE_BANK.json). The full bank contains **1,402 musical Ogg phrases plus one bridge**, at 44.1 kHz stereo/Vorbis quality 2. The selected encoded budget is 60,000,000 bytes; 100,000,000 bytes requires design review. Intermediate PCM stays in ignored build storage. The audition is developer evidence outside the gamemode runtime content.

| Resource | Hard bound or policy |
| --- | --- |
| Wanted physical-floor lanes | Two, on one fixed 130 BPM grid. |
| Retiring floor lanes | At most two; drop after 1.2 seconds. |
| Native channels/reservations | Eight total, including cancelled opens awaiting callbacks. |
| Asynchronous native opens | Two total, including stale reservations across Off/On. |
| Per-floor material | One current phrase, one retiring tail, at most one upcoming phrase. |
| Conservative decoded admission | 32 MiB, assuming complete stereo float32 PCM for every reserved file. Actual native decoder heap is not measured. |
| Largest phrase decoded estimate | About 2.05 MiB for twelve beats plus release; ordinary phrases about 1.43 MiB. |
| Two-floor slot allowance | Six phrase slots plus bridge, about 10 MiB conservatively; current/prepared and tails normally overlap fewer slots. |
| Composer preparation | One per audible lane per 25 ms pump; one-second lookahead. |
| Native musical start | At most one per lane per frame/boundary; reject over 60 ms late. |
| Control-message timing | Absolute deadlines converted once between the DHTML monotonic clock and native SysTime. Delayed delivery cannot extend an obsolete deadline. |
| Musical handoff | Four-beat shared bar for roles/resync; ordinary next phrase after eight beats. |
| Fanfare | One accepted twelve-beat receipt; start only if it still fits the server window. |
| Gain | Square-root floor weights, 700 ms fades, onset/tail envelopes; channel updates at most 30 Hz and only when changed. |
| Quiet bridge | One Surge-rendered D/A loop, ten percent master gain; starts only after a 150 ms gap, stops on musical recovery or eight seconds of persistent failure. |
| Failure | Three native open/duration errors or an eight-second gap tears down playback; ten-second retry backoff. |
| Lua payload cache | Four arrangement metadata entries; zero decoded note pages. |
| JavaScript metadata | Prunes arrangements unreferenced by current/retiring lanes; one pending token per audible lane. |
| Server metadata | Existing 4 KiB global tick budget, 1 KiB plan pieces, 0.5 ms service budget. |
| Frame-pressure telemetry | Existing 35 ms smoothed threshold/five-second recovery; bounded phrase playback remains the same audio bank. |
| Off/zero volume | Destroy panel; stop current/tail/bridge; cancel starts; clear payloads. Late native callbacks stop their channels and free reserved slots. |

The 550 ms release allowance finishes synth envelopes; join tails overlap naturally. Role interrupts fade the old material at the new bar. Native opening callbacks prepare only, never play a musical phrase. Both control and native timing reject overdue starts. Recovery selects a future bar instead of draining event debt. Reversing stairs changes gains on existing floor lanes.

Fixed instrument/master gains preserve level differences. The bank does no per-phrase normalization, realtime synthesis, FFT, MIDI parsing, time stretching or pitch shifting. The former live note ceilings/queues, fills, per-note mutation, +6% tempo slew and +22-cent expression are superseded. Critical combat retains +8% phrase gain with native volume clamped 0–1.

Finite tests cover 15 scheduler stalls and 15 native stalls (100 ms, 300 ms, one, four and fifteen seconds, each with ordinary/role/reversal state), delayed callbacks/control delivery, suspension, bounded preparation, repeated Off/On, channel retirement and bridge failure. These limits establish implementation/resource contracts. Native Source timing/audibility, actual decoder memory and Steam Deck frame rate remain human acceptance gates.
