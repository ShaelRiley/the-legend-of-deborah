# MS3 — sixteen-bar source score and rendered playback

The score contains **eight Music Blocks, 48 arrangements, 157 genuine sixteen-bar passages and eight twelve-beat fanfares**. All 465 original MIDI stems feed the canonical mapper. The final score has **121,557 notes**, in D Dorian on a 130-BPM grid, arranged for the nine existing Surge instruments. No ordinary clip is manufactured by tiling an old two-bar phrase.

Catalog `ms3-s16-e5961c1e5e7bf8cd` pairs with rendered bank `ms2-surge-1d9386ddd67218a5`. The historical `ms2` directory/API names remain for compatibility; they do not identify a second active music system. Project-owned patches in **Surge XT 1.3.4** render the score offline into bundled stereo Ogg Vorbis files. Players require no synthesizer, browser music service or external soundtrack server.

The unchanged server MusicDirector owns permission, danger, frozen physical-floor assignments, staging, bosses, accepted rescue/cash receipts and private new-block Die Logger announcements. Server Music defaults Off. Audio bytes never travel on the gameplay metadata channel.

## Play, controls and diagnostics

Fully quit GMod, update/install the source, start The Legend of Deborah on `gm_flatgrass`, and enable **Player Menu → Options → Music**. For the listen-server host or a superadmin, On enables the server master and saved local preference. Other players control their own preference within server permission. Opening Options changes neither setting. Off remains personal; zero volume also tears down playback.

Explicit equivalent: `lod_music_enabled 1; lod_music 1`.

Diagnostics: `lod_music_status; lod_music_client_status`. Healthy capable clients report `backend=surge-sample-clock`; older/unsupported audio contexts use `surge-rendered`, the mutually exclusive native compatibility backend. Composer statistics arrive asynchronously; repeat status when needed. Look for matching catalog/render revisions, `phrasePasses=1`, and audio `bufferLayout=compact-tail-loop`, PCM bytes, voices and errors. Native status retains actual channel state/position/volume, late opens, phase joins and fixed retry backoff. `streamedBytes=0` excludes initial installation of bundled content.

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

## Arrangement and motifs

The [source catalog](MS2_CATALOG.md), [machine catalog](MS2_CATALOG.json), [full audit](MS3_16_BAR_AUDIT.json) and [portable MIDI clips](MS2_CLIPS.zip) record contiguous source windows, hashes, motifs and edit decisions. The mapper ranks recurring five-onset interval/rhythm fingerprints by block specificity. This is a transparent curation heuristic, not human semantic motif recognition or listening approval.

Each passage retains its selected foreground voice across the complete source window. Competing Acid/Brass attacks are reduced, Industrial/Strings support is subordinated, bass/kick remain intact, and calm hats are thinned. Same-pitch overlapping gates are shortened at the next original retrigger, preventing ambiguous MIDI note-offs without moving attacks or pitches. The shared source router retains D-Dorian cleanup, instrument ranges and polyphony bounds.

Source adjacency, motif overlap, pitch-class compatibility, entry/exit roots and energy rank successors. Role changes also use the mapped role handoff. No immediate self-selection occurs when alternatives exist; recent-three exclusion applies where enough alternatives exist. Only a heard choice is committed to history.

Thirty-nine source-derived one-bar percussion candidates are retained in the audit. Seven selected weak, non-adjacent combat/boss exits contain a baked final-bar tom/snare/hat replacement, leaving all melody, bass and kick untouched. These sparse exit fills are part of the rendered clip, not a live overlay, and can recur if that entire clip must be held. Fills are not compulsory at every transition and do not conceal arbitrary late file starts.

The requested arrangement video could not be retrieved in full; its specific method has **not** been verified or claimed as applied.

## Long-form playback

An ordinary clip plays **once for 64 beats (about 29.54 seconds)** before a fresh choice. A healthy resident clip loops only when its successor is not ready. The sample-clock backend starts prepared recordings at future audio-clock deadlines and retains release tails without routine fade-out/fade-in. Role and stair changes keep short musical-boundary responsiveness: eight-beat boundaries on sample-clock playback and four-beat bars on native compatibility playback, with existing preparation lead. A boss change does not wait for the end of sixteen bars. Victory remains one accepted twelve-beat cue followed by configured calm behavior.

The compact loop stores one decoded recording plus its short release, not multiple copies of the complete passage. Let P be the sample-rounded musical period and T the decoded release length. Keep the dry first P samples, save the release separately, and reuse the recording's tail region for head[0:T] + release. A source beginning at zero then loops over [T,P+T), exactly P samples per repeat. At an ordinary handoff, stop at the full-period boundary and play the saved release while the successor begins. No JavaScript callback is required at resident loop edges. Explicit 44.1-kHz context creation keeps admission bounded; unsupported higher-rate contexts use native playback instead.

The sample-clock path measures RMS during one bounded decode pass and matches neighboring same-role clips within ±3 dB, with one conservative headroom reserve. It never synthesizes notes, stretches time or shifts pitch. The native fallback prepares `sound.PlayFile` channels with `noplay noblock`; callbacks prepare only. Its existing 150-ms prepared-frame seek tolerance, 60-ms late-open rejection and one-second acknowledgement wait remain separate. A healthy current lane can continue while a new role is unready, rather than creating silence; it does not postpone a ready role change. Persistent actual gaps/errors still enter bounded recovery.

Both backends retain saved player volume (0–1, default 0.55), fourfold phrase master gain, square-root floor blending, shared estimated peak ceiling 0.8 and +8% gain only for qualified critical T3/BOSS combat. The gain reserve prevents routine overlap pumping; role/floor/volume changes may deliberately ramp. Reversing stairs reuses active lanes. Off destroys audio ownership and invalidates stale callbacks. Neither measured headroom nor browser rendering certifies the Source mixer or unrelated effects.

## Existing nine-instrument workstation

[Project patches](../tools/music/surge/patches.json) define nine logical parts and ten physical patches; closed/open hats share one logical part. Factory patches and wavetables are not loaded.

| Part | Existing Surge character and arrangement role |
| --- | --- |
| Acid | Mono saw/square, glide, resonant moving filter; foreground motif when selected. |
| Industrial | Dark detuned VA rhythm/harmony, reduced attacks under foreground. |
| Strings | Held harmonic support or full source foreground where string-led. |
| Brass | Filtered synthetic stabs/answers; avoid continuous competing lead. |
| Bass | Mono saw/square/sub foundation; authored contour retained. |
| Tom | Electronic sine body and downward pitch envelope; source punctuation. |
| Snare | Noise plus pitched body; source groove and replacement fills. |
| Kick | Deep sine body and fast transient; authored pulse retained. |
| Hat | Synthetic high-pass noise/metal, choking closed/open envelopes. |

Surge schedules source events within its native 32-frame block (0.726 ms at 44.1 kHz). Fixed instrument gains and 27-Hz high-pass / 11.5-kHz low-pass conditioning remain unchanged. No offline per-clip normalization or heavy compression was introduced. Timbre and motif balance still need native listening.

## Build and validate

Ordinary verification requires Python, Node and the existing Lua dependencies, not Surge:

```bash
python3 tools/music/build_ms2_audio.py
python3 tools/test_music_gate.py --output /tmp/ms3-gate
python3 tools/test_checkpoint_g_integration.py --workers 4 --output /tmp/ms3-integration
node tools/test_music_audio.js
python3 tools/test_ms3_audio.py --bank
```

The last two commands additionally require ffmpeg/numpy and Chromium/Playwright respectively. Full offline authoring uses the [pinned external Surge build](../tools/music/surge/README.md), then:

```bash
python3 tools/music/remap_ms3_sixteen_bar.py --mapped-exits --stage-for-render --output build/ms3-longform
python3 tools/music/build_ms2_surge.py --surge-module /path/to/surge-python --jobs 4
```

Staging a catalog is not a playable update: matching recordings, `render.lua`, MIDI export and manifests must be regenerated together. The full builder validates and then removes obsolete phrase recordings. `build_ms2.py` remains the shared low-level curator/exporter and legacy compiler; use the new mapper for the current long-form score.

[Bank manifest](MS2_SURGE_BANK.json), [resource bounds](MUSIC_PERFORMANCE.md) and [long-form evidence](validation/MS3_LONGFORM.md) distinguish implementation from native acceptance. Google rejected the new tuning insertion with `FAILED_PRECONDITION`; the [unapplied amendment](validation/MS3_LONGFORM_GDD_AMENDMENT.md) is preserved. No Workshop or VPS action is included.
