# Music System 3 — long-form source score

Eight authored blocks and 48 arrangements now use 157 genuine sixteen-bar source passages and eight twelve-beat victory fanfares. They are compiled directly from 465 original MIDI stems, not concatenated or tiled short recordings. The canonical note export, source hashes, motif fingerprints and exact source windows are in MS2_CATALOG.json, MS2_CLIPS.zip and MS3_16_BAR_AUDIT.json. Historical MS2 filenames are retained for installation compatibility.

## Play and operate

Fully quit GMod, update/install the source, start The Legend of Deborah on `gm_flatgrass`, and select Player Menu → Options → Music. The listen-server host/superadmin may enable the server master through that checkbox; other players control their saved personal preference within server permission. Opening Options changes neither. Off and zero volume immediately dispose playback. Console equivalents: `lod_music_enabled 1; lod_music 1`. Diagnostics: `lod_music_status; lod_music_client_status`.

The existing server MusicDirector still owns permission, danger, frozen physical-floor plans, staging, bosses, accepted rescue/cash receipts and private new-block Die Logger announcements. Server music defaults Off; saved personal volume defaults 0.55. There is no soundtrack hosting dependency, HTTP audio request or audio transfer on the music metadata channel. Effects, dialogue and gameplay cues retain their own controls.

## Musical structure

Ordinary passages contain 64 beats on the shared 130 BPM D-Dorian clock, approximately 29.54 seconds before release. A fresh ordinary selection plays once, with successor ranking using block-specific motif overlap, mapped role handoffs, source adjacency, cadence and energy. The recent-three exclusion prevents excessive reuse where alternatives exist. The resident whole passage loops only when selected again or a replacement cannot be prepared; no short phrase is repeated to counterfeit sixteen bars. Heard choices, not speculative preparations, enter musical history.

Foreground source voices remain intact. Acid and Brass compete less, Industrial and Strings support rather than obscure the motif, and Bass/Kick preserve their original pulse. For 29 passages with weak preferred outgoing motif/cadence matches, one final-bar tom/snare/hat turnaround replaces those slots using material from the same source block and role. Melody, harmony, bass and kick are untouched. These are prearranged recorded endings, not an extra live drum layer or a compulsory fill at every transition. They neither extend time nor force an unprepared successor. The audit records every removed and inserted event.

Role/boss/stair demands remain responsive: capable clients enter on an eight-beat boundary, native compatibility on a four-beat boundary, rather than waiting sixteen bars. Actual rescue/cash victory remains once-only, twelve beats, followed by the authorized Chill. A non-phrase interrupt gets a short release; ordinary phrase joins preserve natural tails. Reversing stairs reuses existing lanes and their square-root gain weights. Recent critical T3/BOSS combat retains the bounded +8% expression; no time stretching, live MIDI synthesis or pitch shifting is introduced.

The author's linked arrangement guide could not be retrieved in full; the current source-based orchestration must not be represented as verified application of that guide. Motif detection is heuristic. Perceptual quality remains an explicit native listening gate.

## Nine virtual instruments

Pinned external Surge XT 1.3.4 renders the score offline. Project-owned patches supply Acid, Industrial, Strings, Brass, Bass, Tom, Snare, Kick and Hat (closed/open patches share one logical instrument). Factory presets/wavetables are not loaded. Acid retains resonant filter motion, strings their softer calm attack, brass its controlled synth envelope, and bass/kick their low-end separation. Instrument gains, 27 Hz high-pass/11.5 kHz low-pass conditioning, 44.1 kHz stereo and the 550 ms release allowance are unchanged. Every rendered file is Vorbis-decoded and measured by the authoring gate.

## Playback architecture

Capable clients report `backend=surge-sample-clock`: the hidden input-free DHTML control plane schedules AudioBuffer sources on the audio clock. A sixteen-bar recording retains one full decoded body plus a short clean attack buffer, not a second two-period waveform. Its first attack uses the clean prefix; the main source begins at the matching sample and offset. Later resident passes loop the same body with exactly one preceding release folded into its prefix. An actual successor receives the outgoing tail once. No periodic fade, reopen or JavaScript-timed restart is needed for resident loops.

The AudioContext requests 44.1 kHz. Admission uses the actual context rate, so a platform choosing another rate cannot bypass the 32 MiB PCM ceiling. Memory or delayed decode leaves healthy resident music intact. Reference ownership includes short attack sources and is cleared on cancellation, lane retirement and Off. Peak headroom remains shared, with bounded within-arrangement RMS matching and the saved volume control.

Older/unsupported HTML uses the mutually exclusive `surge-rendered` native backend and the same local recordings. It retains bounded asynchronous `sound.PlayFile` preparation, channel gain and late-frame recovery. It is not sample-accurate playback. Long resident loops no longer fail solely because their duration exceeds the former eight-second short-phrase hold window. Backend capability or decode failure is diagnosed; no live synthesis fallback is added.

## Build and verification

Ordinary gates need Python, Node, Lua test dependencies and the committed bank, not Surge:

```bash
python3 tools/test_music_gate.py --output /tmp/ms3-music
python3 tools/test_checkpoint_g_integration.py --output /tmp/ms3-integration
node tools/test_music_audio.js
```

Full authoring requires the pinned external Surge build described in tools/music/surge/README.md:

```bash
python3 tools/music/install_ms3_score.py
python3 tools/music/build_ms2_audio.py
python3 tools/music/build_ms2_surge.py --surge-module /path/to/external/build/src/surge-python --jobs 4
python3 tools/test_ms3_audio.py --bank
```

Never publish an intermediate catalog with stale recordings. Catalog, notes, render manifest, exact Ogg set, source hashes, clip lengths and patch/renderer provenance must agree. Native GMod/Steam Deck continuity, balance and frame time remain unaccepted until the author hears the exact build. Local acceptance precedes Workshop publication and matching VPS deployment; this source checkpoint performs neither.
