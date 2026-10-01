# Music System 2

MS2 replaces the streamed MS1 soundtrack with a bundled MIDI phrase bank and local synthesis. The author's 465 MIDI stems become eight blocks, 48 arrangements, 1,402 phrases and 170,860 orchestrated notes. The game-side catalog, notes and engine total approximately 3.2 MB uncompressed; ten short synthetic fallback tones/hits add 89,466 bytes. There are no music HTTP requests, streamed recordings, remote-origin credentials or server audio transfers. Normal game/Workshop content distribution supplies the bank once.

The existing server MusicDirector still owns permission, pressure, seeded floor assignments, staging, boss selection, accepted rescue/cash receipts and private Die Logger announcements. Music remains presentation-only and cannot delay gameplay. Server Music remains Off by default. Enable it explicitly after installing this build.

## Play and operate

Fully quit GMod, update/install the repository, then start The Legend of Deborah on `gm_flatgrass`. Select **Player Menu → Options → Music**. For the listen-server host or a superadmin, On enables both the server master and the saved local preference. The host/operator checkbox reflects both states; opening Options alone changes neither. Other players control their own saved preference within the server's permission. Off is always personal and never disables another player's score.

The equivalent explicit server/listen-server console command remains:

```text
lod_music_enabled 1; lod_music 1
```

Music and its saved volume remain in Player Menu → Options. Either Off or zero volume immediately disposes playback and note caches. Effects, dialogue and essential gameplay cues remain. To inspect a running score:

```text
lod_music_status; lod_music_client_status
```

The client status reports `system=MS2`, `backend=web` or `native`, readiness, catalog revision, quality, caches, note queue/voice peaks and errors. Renderer statistics arrive asynchronously; a later status call includes the latest sample. `streamedBytes=0` describes score streaming, not the initial download of game content.

| Operator control | Behavior |
| --- | --- |
| `lod_music_enabled 0/1` | Saved server master, immediate; default 0. |
| `lod_music_set all` or a catalog set ID | Chooses eligible blocks for future dungeon plans. |
| `lod_music_universal_boss 0/1` | Uses Block A's boss arrangement when enabled. |
| `lod_music_universal_victory 0/1` | Uses Block A's fanfare when enabled. |
| `lod_music_universal_interlude 0/1` | Uses Block A's Chill for dedicated interlude selection. |
| `lod_music_post_victory auto/interlude/off` | AUTO uses the next first-floor Chill; interlude uses the current dedicated calm selection; off uses current-block T0. |
| `lod_music_reload` | Revalidates the bundled catalog for future plans. |
| `lod_music_status` | Shows catalog, configured/frozen settings, listeners and errors. |

Set/universal/post-victory changes preserve already offered and active plans. All eight core blocks contain all six authored roles; absent roles in later libraries inherit Block A. The core catalog starts with `set=all`; named subsets can be added to the compiled catalog's `sets` map. MS1 profile/import/upload commands and the external recording service are retired. Operator settings now live under `legend_of_deborah/music2/`; saved player preference and volume retain their existing names.

## Musical direction and clip bank

Read [the music-direction catalog](MS2_CATALOG.md) for role usage, instrument colors, representative compatible paths and transition circumstances. [MS2_CATALOG.json](MS2_CATALOG.json) records every phrase's source beat offset, structural energy, pulse coverage, entry/exit roots, pitch-class profile, six preferred successors and original MIDI SHA-256 lineage. [MS2_CLIPS.zip](MS2_CLIPS.zip) contains every curated phrase as a portable standard MIDI file, with conductor plus nine named instrument tracks and an index. These DAW audition/editing copies do not add to the game package.

The common musical language is D Dorian at a baseline 130 BPM. Melodic transcription artifacts are conservatively corrected to the mode and instrument registers. Duplicate detections, weak candidates and excessive polyphony are curated offline; very short drum detections survive. Combat uses pulsed interior material; Chill retains the quieter half of each authored calm arrangement and sparse percussion. Loop phrases last eight beats; fanfare uses a coherent twelve-beat authored beginning.

A composer selects cadence/energy-compatible phrases, avoids the three most recent where alternatives exist, and varies velocity, gate, tiny timing/swing, timbre and occasional acid register. Each genuine return/restarted renderer gets fresh presentation entropy, separate from gameplay/floor RNG. Every six to ten pulsed phrases it replaces the last beat's snare/tom/hat slots with a bounded fill, retaining the kick/melodic foundation.

Every layer follows one beat clock. Role changes enter on a shared bar; stairs use reversible square-root gain blending. Release tails and a quiet sustained D bridge cover phrase joins and scheduler stalls. Missed attacks are discarded rather than burst later. The countdown's effective deadline, including extensions, slowly raises tempo toward +6% maximum. Only recent combat at critical health in T3/BOSS adds +22 cents and +8% dynamics; ordinary boss/timer/staging playback retains baseline expression. The accepted victory receipt plays once, then AUTO continues upcoming Chill; late or spent receipts never replay.

## Instruments and backends

| Part | Primary synth |
| --- | --- |
| Acid | Monophonic saw-family oscillator, pitch-tracking resonant low-pass envelope. |
| Industrial | Thick detuned oscillators, saturating waveshaper, low-pass pad/rhythm-guitar articulation. |
| Strings | Detuned harmonic voices; relaxed calm attack and punchier combat attack. |
| Brass | Warm harmonic body, strong controlled envelope, roll-off against harshness. |
| Bass | Monophonic gritty harmonic body with sub oscillator. |
| Tom | Pitched synthetic membrane hit, two simultaneous voices per lane. |
| Snare | Snappy filtered noise/body hit with velocity-sensitive weight. |
| Kick | Fast pitch drop, deep body and short transient. |
| Hat | Reusable closed/open synthetic noise-metal hits; closed hat chokes open hat. |

A client-only DHTML panel hosts the ES5 composer and Web Audio renderer. It paints nothing, accepts no input, enables no arbitrary Lua execution and requests no external content. Audio is scheduled ahead on the audio clock; oscillators/filters run in the audio engine, with reusable percussion buffers and gentle master EQ/compression.

If the HTML engine lacks usable Web Audio or blocks its context, the same composer sends scheduled notes to a finite Source-native voice bank. That fallback approximates instrument colors with tiny synthesized loop tones/hits, Source pitch and envelopes; it has frame-sized timing precision and no per-note Web Audio filters. Missing fallback support/assets are reported by client status. Off and teardown stop both backends. Resource bounds are in [MUSIC_PERFORMANCE.md](MUSIC_PERFORMANCE.md).

## Rebuild

Python's standard library plus Node are sufficient; the compiler never decodes recordings or executes archive contents. The original deduplicated MIDI stems are retained under `tools/music/sources/`.

```bash
python3 tools/music/build_ms2_audio.py
python3 tools/music/build_ms2.py tools/music/sources --export-midi docs/MS2_CLIPS.zip
```

To import the original nested archive while retaining MIDI-only source copies:

```bash
python3 tools/music/build_ms2.py '/path/to/LoD MIDI Library.zip' --sources tools/music/sources --export-midi docs/MS2_CLIPS.zip
```

The compiler accepts bounded format-0/1 musical-PPQ SMFs, handles running status/sustain/tempo maps, deduplicates matching stems, rejects malformed/unsafe archives and emits AddCSLuaFile-safe note shards, catalog and portable MIDI exports. Client playback uses the compiled event data, so MIDI parsing never occurs in the hot audio loop. Compile/restart/install the same revision on server and clients; active mismatched plans fail with a diagnostic instead of changing identity.

## Verify

```bash
python3 tools/test_music_gate.py --output /tmp/ms2-gate
```

The finite source gate covers compiler reproducibility, MIDI/catalog integrity, composer/clock behavior, server/client permissions, native voice bounds, victory/logging and affected gameplay/manual regressions. For actual Web Audio rendering, install Playwright and a Chromium executable, then set `MS2_CHROMIUM` to that executable. `MS2_NODE_MODULES` may identify the Playwright module directory. The same gate then adds the offline audio suite:

```bash
MS2_CHROMIUM=/path/to/chromium python3 tools/test_music_gate.py --output /tmp/ms2-audio-gate
node tools/test_music_audio.js --browser /path/to/chromium --output /tmp/ms2-audition.wav
```

Offline audio proves actual oscillator/filter/buffer output, headroom and transport continuity; it is not native GMod/Steam Deck/co-op acceptance. See [the validation record](validation/MS2.md) for the exact evidence and next listening action. Historical MS1 documentation/evidence remains under history/validation. The live GDD amendment was rejected by Google Docs (`FAILED_PRECONDITION`); its full unapplied text is retained in [MS2_GDD_AMENDMENTS.json](validation/MS2_GDD_AMENDMENTS.json). The current explicit author direction governs MS2.
