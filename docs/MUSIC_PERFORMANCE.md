# MS3 long-form playback budgets

Surge renders offline. Runtime work is selection, asynchronous local decode/preparation, audio-clock scheduling (or bounded native compatibility) and gain. There is no whole-bank startup decode, MIDI parsing, oscillator synthesis, FFT, time stretch, pitch shift or soundtrack HTTP traffic.

The current bank is **46,853,341 bytes (46.853 MB / 44.683 MiB)**: **165 musical recordings plus one ambient bridge**, stereo 44.1 kHz / Vorbis quality 2. The largest file is **333,786 bytes**. Exact durations, peaks, RMS, hashes and renderer/patch/toolchain identity are in [MS2_SURGE_BANK.json](MS2_SURGE_BANK.json). The unchanged package ceiling is 60,000,000 bytes; 100,000,000 bytes requires design review. Intermediate WAVs remain build artifacts, not shipped game content.

| Resource | Bound / policy |
| --- | --- |
| Wanted floor lanes | Two on a shared fixed 130-BPM grid. |
| Retiring lanes | At most two, released after 1.2 seconds. |
| Audio sources / native channels | Eight, including tails and native stale-open reservations. |
| Concurrent decoding / native opens | Two. |
| PCM admission | 32 MiB; includes browser decoded buffer, saved short tail and outstanding reservations. Native complete-stereo-float estimate remains conservative, not measured decoder heap. |
| Browser cache | At most four entries; the byte bound is tighter for real sixteen-bar clips. |
| Long-form layout | One P+T decoded buffer plus T saved tail. No duplicate full-period buffer. |
| Three full long clips | Stress gate peaks at 32,427,776 bytes including decode reservations, below 33,554,432. A fourth live long clip is refused until references retire; resident audio continues. |
| Sample rate | Request 44.1 kHz; a higher-rate context uses the native compatibility backend. |
| Encoded local file | At most 1 MiB; base64 transport at most 1,400,000 characters. Current largest recording is 333,786 bytes. |
| Composer | One preparation per audible lane per 25-ms pump, one-second lookahead, one pending token per lane. |
| Ordinary material | One 64-beat pass per fresh selection; whole-period resident repeats only when needed. |
| Role / stair change | Short shared boundaries: eight beats for sample-clock, four beats for native; do not wait sixteen bars. |
| Sample-clock preparation | At least 50 ms ahead; retain current audio if that deadline is missed. |
| Native start | Prepared frame delay at most 150 ms with fast seek; file-open arrival tolerance 60 ms. Larger delays resynchronize, never drain missed attacks. |
| Native acknowledgement | Separate one-second result-message wait. |
| Fanfare | Twelve beats, once per accepted receipt; never held as a loop. |
| Gain | Fourfold phrase master × saved volume, square-root floor weights, bounded ±3-dB same-role RMS matching in browser only; critical gain remains +8% within headroom. |
| Peak guard | Common estimated score ceiling 0.8 including tails and floor envelopes; arrangement full+tail bounds prevent routine join pumping. Native decreases precede increases. |
| Healthy late successor | Keep resident music with no extra decode/source per repeat. This is not an eight-second limit on otherwise healthy music. |
| Genuine failure | Existing three native open/duration errors or eight-second actual gap triggers teardown and fixed ten-second retry. Preserve first failure cause. |
| Native ambient bridge | One existing quiet Surge D/A loop for a genuine gap, headroom-limited; stop on recovery or eight-second persistent gap. Not a percussion bridge. |
| Startup | Five-second deadline only for the currently initializing panel; cleared on readiness/teardown. |
| Lua metadata | Four arrangement entries, zero decoded note pages. Server metadata retains 4-KiB tick / 1-KiB pieces / 0.5-ms service bounds. |
| Off / zero volume | Stop audio, destroy panel/context, clear ownership/cache; late callbacks release rather than play. |

The browser loop preserves its first dry body and folds head+release into tail storage in place. Loop points run on the audio thread. Ordinary handoffs append the separately saved release exactly once. Reaping ended sources clears their buffer references before cache eviction. Admission counts decode reservations before starting work. This avoids the old roughly three-full-buffer requirement per phrase; it does not expand the 32-MiB limit. Runtime allocations outside tracked PCM and actual Source/native memory still require hardware observation.

Seven authored exit fills are baked percussion replacements, not extra runtime sources. Native compatibility retains nonblocking local channel preparation and its existing frame/seek limitations; only the sample-clock path claims audio-clock scheduling. Both preserve healthy current music while a successor is late. Low-end quality/pressure telemetry, saved Options and game server behavior are unchanged.

Finite gates include source/MIDI/hash parity, 15 composer stall cases, 15 native-open stall cases, repeated Off/On, stale callbacks, pending reservations, role/stair reversal, three resident real-size long buffers, fourth-buffer refusal/recovery and a 48-kHz capability fallback. Real browser tests compare synthetic and decoded Surge output to an independent overlap-add reference at sixteen-bar loop and successor boundaries; full-bank decoding checks every recording. Native GMod/Steam Deck audibility, perceptual continuity, actual heap and frame rate remain separate acceptance gates.
