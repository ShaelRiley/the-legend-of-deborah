# MS3 song-first resource contracts

Full compositions are rendered offline; clients load bounded delivery chunks, not entire songs. Source MIDI parsing, source section selection and synthesis never run during gameplay. Runtime does not perform FFT, time stretch, pitch shift or soundtrack HTTP requests.

| Resource | Contract |
| --- | --- |
| Ordinary audible composition | One song lane; ordinary stair/pressure requests wait for the next song. |
| Delivery chunk | At most 64 beats; whole-bar partial end chunks; exact 44.1-kHz frame periods. |
| PCM | Unchanged 32 MiB including decode reservations, decoded bodies and saved short release buffers. |
| Cache / decode | At most four cached/load entries and two concurrent decodes. Rolling eviction only removes unreferenced buffers. |
| Voices / native channels | At most eight; actual score traversal normally needs one current and one prepared recording plus a short retiring release. |
| Encoded bank | Unchanged ceiling 60,000,000 bytes; complete bank is 59,316,556 bytes. The design-review ceiling remains 100,000,000 bytes. This is an installation size budget, not runtime PCM. |
| Per-file admission | 1 MiB; validated bundled IDs only, no arbitrary file paths or HTTP. |
| Metadata | Four client arrangement entries; plans retain existing bounded transmission. No MIDI note-page parsing on playback. |
| Dynamics | Source dynamics retained; no clip-by-clip RMS matching. Saved 0–1 volume, default 0.55; master gain 4 and shared estimated peak ceiling 0.8. |
| Late successor | Resident chunk repeats without another allocation; retry chronological successor, never burst skipped notes. |
| Off / zero volume | Immediate playback teardown and stale-callback invalidation. |

The renderer filters and voices each full source-ordered edit once. It verifies that concatenated pre-encoding delivery bodies reconstruct the exact full performance PCM. Only a terminal song chunk has the real final release; normal internal chunks have a silent pad. Compact resident looping folds the short head/release into existing tail storage, preserving the first pass without a second whole-body buffer.

Legacy timing/lifecycle/resource tests remain, plus complete-song chronology under changing requests, server-plan clip authorization, native song residency and malformed sample-period rejection. Real-browser tests exercise bounded rolling decode through complete driving and staging songs against an independently assembled decoded reference. Those tests do not establish real-time Source/DHTML frame rate, actual decoder heap, speaker audibility or subjective arrangement quality.
