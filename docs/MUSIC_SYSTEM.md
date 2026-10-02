# MS3 — song-first continuous compositions

The active score contains eight blocks, 48 arrangements, 40 complete source-ordered looping song edits and eight twelve-beat fanfares. All 465 original MIDI stems feed the canonical nine-voice router. The intact score has 181,635 notes; 182,091 portable chunk entries include sustain ties at delivery boundaries. Song edits span about 81–238 seconds. Historical `ms2` directory/API names remain for compatibility; there is one active music system.

Surge XT 1.3.4 renders each full song offline through the existing project-owned nine-instrument patches. Only afterward is its PCM split into 216 bounded ordinary delivery chunks plus eight fanfares. Player clients need no synthesizer or soundtrack connection. See `MS3_SONG_DIRECTION.md`, `MS3_SONG_AUDIT.json`, `MS3_SONG_SCORE.json` and `MS2_SURGE_BANK.json` for exact source, score and audio lineage.

## Play, controls and diagnostics

Fully quit GMod, update/install the source, start The Legend of Deborah on `gm_flatgrass`, and enable **Player Menu → Options → Music**. For the listen-server host or a superadmin, On enables the server master and saved local preference. Other players control their own preference within server permission. Opening Options changes neither setting. Off remains personal; zero volume also tears down playback.

Explicit equivalent: `lod_music_enabled 1; lod_music 1`.

Diagnostics: `lod_music_status; lod_music_client_status`. Healthy capable clients report `backend=surge-sample-clock`; older/unsupported audio contexts use `surge-rendered`, the mutually exclusive native compatibility backend. Composer statistics arrive asynchronously; repeat status when needed. Look for matching catalog/render revisions, `phrasePasses=1`, `stats.song.asset/part/completed/requested`, and audio `bufferLayout=compact-tail-loop`, PCM bytes, voices and errors. Native status retains actual channel state/position/volume, late opens, phase joins and fixed retry backoff. `streamedBytes=0` excludes initial installation of bundled content.

| Operator control | Behavior |
| --- | --- |
| `lod_music_enabled 0/1` | Saved server master; default 0. |
| `lod_music_set all` or a catalog set ID | Eligible blocks for future plans. |
| `lod_music_universal_boss 0/1` | Use Block A boss music when enabled. |
| `lod_music_universal_victory 0/1` | Use Block A fanfare when enabled. |
| `lod_music_universal_interlude 0/1` | Use Block A Chill for interlude selection. |
| `lod_music_post_victory auto/interlude/off` | Next first-floor Chill / interlude / current-block T0. |
| `lod_music_reload` | Revalidate the catalog for future plans. |
| `lod_music_status` | Frozen/configured plans, listeners and errors. |

Active/offered plans stay frozen. Missing roles in future libraries inherit Block A. Existing settings remain under `legend_of_deborah/music2/`; player preference names are unchanged. Effects/dialogue retain their own controls.

## Preserve the composition

Every retained source section plays in chronological order. The mapper no longer ranks a small set of favorite snippets, reassigns foreground voices per chunk, thins competing melodic parts, or adds transition fills. Original melodies remain subject only to the existing D-Dorian/range/polyphony/duplicate-cleanup authority. Full-song held notes, envelopes and filter motion cross storage boundaries without restarting synthesis.

Outside staging, all four-bar source cells passing the driving-beat proxy are retained. An isolated four-bar break between driving sections stays; longer non-driving runs and non-driving introductions/outros are omitted. The proxy requires kick on at least 25% plus percussion on at least 50% of beats across 75% of bars, or percussion on at least 75% of beats across all bars. Staging keeps its whole T0 arrangement, including beatless passages. Default calm maze pressure selects the block's T1 driving arrangement; post-victory calm remains intentional. Beat classification is a transparent heuristic, not perceptual or motif-quality certification.

## Song-first playback

One ordinary song lane is audible. Ordinary floor/stair and T1–T3 pressure requests become the next-song preference; the most recent available preference is admitted near the current song's final boundary. They do not interrupt the song or blend unrelated floor arrangements mid-melody. At completion, the selected composition starts from its beginning; an unchanged selection repeats the entire composition. Every accepted chunk advances to its exact chronological successor, never a randomized neighbor. A late preparation retries the missing successor after a resident chunk repeat, rather than skipping music.

Boss entry/exit, a genuine once-only victory cue, staging entry/exit, a new dungeon plan and Off remain exceptions. Ready exceptional changes use the existing short grid boundaries. Repeated same-block announcements are suppressed; Die Logger reports the composition actually beginning, which may differ from the current floor preference while a song completes. Native read requests remain restricted to clips in server-supplied matching plans.

Capable clients schedule locally decoded recordings on the audio clock. Exact sample-frame periods prevent fractional-frame drift across shortened final chunks. No per-chunk loudness normalization is used: the full performance's dynamics carry through intact. Ordinary internal chunks contain a silent release pad; only the song's last chunk has the actual terminal release. Internal chunks continue seamlessly into the next PCM body; full-song wraps retain the terminal release. The compact-tail resident loop remains a bounded emergency fallback, not the normal musical structure.

The native fallback remains mutually exclusive and frame-timed, using `sound.PlayFile` with `noplay noblock`, the existing 150-ms prepared-frame tolerance, 60-ms late-open rejection and one-second acknowledgement wait. Both paths keep healthy resident music while a successor is late. Off tears down panel, audio ownership and stale callbacks. Saved volume, default-Off permissions, fixed fourfold master gain, shared estimated peak ceiling 0.8 and qualified critical +8% expression remain. The client PCM ceiling stays 32 MiB; no full-song runtime buffer is loaded.

## Offline authoring and validation

Existing nine-voice Surge patches and their fixed instrument gains remain unchanged. Source event scheduling retains the renderer's native 32-frame block. High-/low-pass conditioning and final release shaping run once per complete song. Each chunk's pre-encoding body is a byte-exact slice of that performance; the renderer verifies their concatenated PCM hash against the full song. Ogg compression is lossy; this is not a promise that encoded file boundaries are inaudible in the native engine.

```bash
python3 tools/music/song_score.py --output build/ms3-song --stage-for-render
python3 tools/music/build_ms2_surge.py --surge-module /path/to/surge-python --jobs 4
python3 tools/test_music_gate.py --output /tmp/ms3-song-gate
python3 tools/test_checkpoint_g_integration.py --workers 4 --output /tmp/ms3-song-integration
node tools/test_music_audio.js
python3 tools/test_ms3_audio.py --bank
python3 tools/test_ms3_song_audio.py
```

Rendering needs the pinned external Surge tool, numpy/scipy and ffmpeg. Browser audio tests need Playwright and Chromium (`MS3_CHROMIUM`). Runtime tests never require a synth. The final validation receipt distinguishes static/source, actual decoding, browser-rendered samples and still-pending native GMod/Steam Deck listening/performance.

The linked arrangement video could not be retrieved. Preserving source compositions does not rely on an unverified video-specific method. The live GDD amendment was rejected with `FAILED_PRECONDITION`; exact unapplied design/tuning text is preserved in `validation/MS3_SONG_GDD_AMENDMENT.md`.
