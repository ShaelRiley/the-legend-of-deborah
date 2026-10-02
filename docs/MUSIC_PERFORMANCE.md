# MS3 long-form resource budgets

The full encoded bank is capped at 60,000,000 bytes. Exact measured bytes, largest/average file, PCM peaks, decoded peaks, format and source hashes live in MS2_SURGE_BANK.json, generated from the actual rendered files. The bank contains 165 musical recordings plus one fallback bridge, all stereo 44.1 kHz Vorbis. No entire-bank decode occurs at startup.

| Resource | Bound / behavior |
| --- | --- |
| Musical passages | 157 ordinary 64-beat passages plus eight once-only 12-beat fanfares; fixed 130 BPM. |
| Wanted floor lanes | Two; at most two additional retiring lanes. |
| Resident decoded budget | 32 MiB including pending admission reservations, measured at actual AudioContext rate. |
| Long-form buffer layout | One decoded body/release plus a short clean attack prefix. Approximately 10.31 MiB at 44.1 kHz; three such allocations fit, unlike the previous three-full-period layout. |
| AudioContext | Requests 44.1 kHz; actual rate governs reservations. At 48 kHz, unavailable successor capacity preserves resident audio until space is released. |
| Decoded cache | At most four entries, subject to the stricter byte ceiling. Never evict active/pending ownership. |
| Decodes / native opens | At most two; stale native opens retain their reservation until callback. |
| Audio sources / native channels | Eight, including short attacks, natural tails, future starts and cancelled native reservations. |
| Local encoded read | At most 1 MiB, validated permitted clip path; bounded base64 handoff. This is local content, not network audio streaming. |
| Scheduling | One preparation per audible lane per pump; one-second lookahead. Sample-clock playback uses future deadlines and whole-phrase integer sample periods. |
| Late preparation | Retain healthy resident whole passage; reject stale deadline and retry on the existing phrase grid. No catch-up bursts. |
| Role / floor change | Eight-beat entry on sample-clock backend, four-beat native entry; fanfare may enter at a beat. Not a sixteen-bar response delay. |
| Gain | Master 4, saved personal 0–1 volume; bounded RMS matching; common peak ceiling 0.8; intentional floor/role envelopes only. |
| Server music service | Existing 4 KiB tick budget, 1 KiB pieces and 0.5 ms service budget; no audio bytes. |
| Off / zero volume | Stop and disconnect sources, clear buffer references and caches, cancel jobs; stale decodes cannot resurrect playback. |

The initial clean head is approximately 550 ms. Subsequent passes fold the preceding release into the same decoded body's prefix; the first head and main body have matching sample boundaries. One outgoing release is scheduled only when changing passages at their boundary. No whole-buffer copy or recurring per-sample work occurs each loop. Waveform folding/RMS measurement happens once per admitted decoded recording, not every frame.

Native compatibility continues using frame-timed local channels with the existing bounded seek/start tolerance, first-error preservation, startup deadline and fixed retry backoff. The 32 MiB reservation is a conservative PCM estimate, not a measurement of Source's private decoder heap. Long native holds reuse existing channels. The quiet D/A bridge is for a genuine failure gap, not ordinary phrase joins.

Automated gates exercise 44.1/48 kHz admission, two floors plus a successor, memory denial, delayed decode, cancellation, once-only victory, role response, source cleanup, actual recording decode, and waveform joins. These establish code/data/PCM contracts; they do not certify actual GMod mixer output, perceived smoothness or Steam Deck frame rate. Native listening remains required.
