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
| Native musical start | At most one per lane per frame/boundary. Prepared phrases may fast-seek past up to 150 ms elapsed time; reject files arriving over 60 ms after deadline and frames over 150 ms late. |
| Native acknowledgement | At most one pending token per lane; one-second bounded result wait through the DHTML queue, independent of audio-start eligibility. |
| Control-message timing | Absolute deadlines converted once between the DHTML monotonic clock and native SysTime. Delayed delivery cannot extend an obsolete deadline. |
| Musical handoff | Four-beat shared bar for roles; ordinary eight-beat passes, four successful passes (14.77 seconds) per fresh phrase choice. Held recovery keeps that lane's eight-beat phase. |
| Fanfare | One accepted twelve-beat receipt; start only if it still fits the server window. |
| Gain | Fourfold (+12.04 dB) phrase master, saved 0–1 player volume, square-root floor weights, 700 ms floor fades and 120 ms role cutoff. Routine starts/releases retain constant gain. Updates at most 30 Hz and only when changed. |
| Shared score headroom | Looping arrangements reserve maximum full peak + maximum tail peak throughout playback; fanfare reserves full peak. Offline phase-appropriate peak × actual written gain stays at most 0.8, including tails/bridge and paced writes. Decrease before increase; no routine overlap pumping. |
| Late replacement | Reuse the existing same-role channel for at most two complete eight-beat repeats within eight seconds. Fast-seek past the Ogg tail; no extra opens, callbacks, queues or channels. Reject late replacement and retry at the next complete phrase boundary. Never hold an obsolete role or fanfare. |
| Quiet bridge | One Surge-rendered D/A loop, ten percent player volume without the fourfold phrase boost; also headroom-limited. Starts only after a 150 ms gap, stops on musical recovery or eight seconds of persistent failure. |
| Failure | Three native open/duration errors or an eight-second gap tears down playback; fixed ten-second retry backoff. Preserve the first native cause, including expected/actual duration when mismatched. |
| Startup | Five-second deadline for the current initializing panel only; cleared on readiness or teardown. An expired former deadline cannot delay recovery. |
| Lua payload cache | Four arrangement metadata entries; zero decoded note pages. |
| JavaScript metadata | Prunes arrangements unreferenced by current/retiring lanes; one pending token per audible lane. |
| Server metadata | Existing 4 KiB global tick budget, 1 KiB plan pieces, 0.5 ms service budget. |
| Frame-pressure telemetry | Existing 35 ms smoothed threshold/five-second recovery; bounded phrase playback remains the same audio bank. |
| Off/zero volume | Destroy panel; stop current/tail/bridge; cancel starts; clear payloads. Late native callbacks stop their channels and free reserved slots. |

The 550 ms release allowance finishes synth envelopes; routine joins overlap tails at constant gain. Offline tail bounds cover the last 150 ms of musical time as well as the release. Role interrupts fade old material at the new bar. Native opening callbacks prepare only. A short frame hitch or held repeat uses the existing nonblocking local channel's fast SetTime path, with no decode-to-position or runtime waveform processing. The original phrase grid determines each join; there is no routine onset/end envelope. Larger delays recover at a future valid boundary instead of draining event debt. Reversing stairs changes gains on existing floor lanes. Actual native state/position/volume queries occur only for the explicit diagnostic command, over at most eight channels.

Fixed instrument/master gains preserve level differences. The bank does no per-phrase normalization, realtime synthesis, FFT, MIDI parsing, time stretching or pitch shifting. The former live note ceilings/queues, fills, per-note mutation, +6% tempo slew and +22-cent expression are superseded. Critical combat retains +8% phrase gain within the shared peak ceiling. Native channel volume may exceed 1: the official [SetVolume API](https://wiki.facepunch.com/gmod/IGModAudioChannel:SetVolume) explicitly supports amplification (its example uses 3 for 300%). The saved player-volume control remains 0–1.

The gain guard adds a few arithmetic passes over at most eight records, two offline peak numbers per clip and 48 arrangement bounds calculated once at configuration. No encoded audio bytes, decoded-PCM allowance, open reservations or server work are added. All native volume writes are checked in the resource harness, including older paced gains during stair reversals, quiet-bridge overlap and natural tails. This conservatively estimates the score's sample-peak sum; it does not measure Source mixer output or unrelated effects. `--refresh-join-metadata` decodes the committed bank without rendering or re-encoding audio.

Finite tests cover 15 scheduler stalls and 15 native-open stalls (100 ms, 300 ms, one, four and fifteen seconds, each with ordinary/role/reversal state), delayed callbacks/control delivery, suspension, bounded preparation, repeated Off/On, channel retirement and bridge failure. Additional cases cover delayed 300 ms native acknowledgements and 32 successive two-floor 100 ms prepared-frame hitches, original-epoch/fast-seek recovery, the 150 ms upper boundary and late-open rejection. These limits establish implementation/resource contracts. Native Source seeking/continuity, actual decoder memory and Steam Deck frame rate remain human acceptance gates.
